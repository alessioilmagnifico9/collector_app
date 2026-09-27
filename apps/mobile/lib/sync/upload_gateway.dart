import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:experiment_models/experiment_models.dart';
import 'package:http/http.dart' as http;

final class UploadBundle {
  final Json session;
  final Trial trial;
  final TrialFile file;
  final String compressedPath, deviceToken;
  const UploadBundle({
    required this.session,
    required this.trial,
    required this.file,
    required this.compressedPath,
    required this.deviceToken,
  });
}

final class UploadAuthorization {
  final Uri? url;
  final Map<String, String> headers;
  const UploadAuthorization({this.url, this.headers = const {}});
}

abstract interface class UploadGateway {
  Future<UploadAuthorization> authorize(UploadBundle bundle);
  Future<void> upload(UploadAuthorization authorization, File file);
  Future<TrialFile> finalize(UploadBundle bundle);
}

class _FileRequest extends http.BaseRequest with http.Abortable {
  final File file;
  @override
  final Future<void> abortTrigger;
  _FileRequest(Uri url, this.file, this.abortTrigger) : super('PUT', url);
  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(file.openRead());
  }
}

final class RemoteUploadGateway implements UploadGateway {
  final Uri endpoint;
  final String publicKey;
  final http.Client client;
  final Duration requestTimeout;
  RemoteUploadGateway({
    required this.endpoint,
    required this.publicKey,
    http.Client? client,
    this.requestTimeout = const Duration(minutes: 3),
  }) : client = client ?? http.Client();
  Future<T> _bounded<T>(Future<T> Function(Future<void>) action) async {
    final abort = Completer<void>();
    final timer = Timer(requestTimeout, abort.complete);
    try {
      return await action(abort.future).timeout(requestTimeout);
    } finally {
      timer.cancel();
      if (!abort.isCompleted) abort.complete();
    }
  }

  Future<Json> _request(String token, Json body) => _bounded((abort) async {
    final request = http.AbortableRequest('POST', endpoint, abortTrigger: abort)
      ..followRedirects = false
      ..headers.addAll({
        'apikey': publicKey,
        'authorization': 'Bearer $token',
        'content-type': 'application/json',
      })
      ..body = jsonEncode(body);
    final response = await http.Response.fromStream(await client.send(request));
    if (response.statusCode != 200)
      throw StateError('Synchronization request failed.');
    return asJson(jsonDecode(response.body));
  });

  @override
  Future<UploadAuthorization> authorize(UploadBundle bundle) async {
    final response = await _request(bundle.deviceToken, {
      'action': 'prepare_upload',
      'session': bundle.session,
      'trial': bundle.trial.toJson(),
      'file': bundle.file.toJson(),
    });
    final manifest = TrialFile.fromJson(asJson(response['manifest']));
    _match(bundle.file, manifest);
    if (response['upload_required'] == false)
      return const UploadAuthorization();
    final url = Uri.parse(stringField(response, 'url'));
    if (url.scheme != 'https' ||
        !url.host.endsWith('.r2.cloudflarestorage.com') ||
        url.userInfo.isNotEmpty)
      throw StateError('Untrusted upload URL.');
    final headers = asJson(response['headers'])
        .map((key, value) => MapEntry(key, value as String));
    if (headers['if-none-match'] != '*' ||
        headers['content-type'] != 'application/gzip' ||
        headers['content-length'] != '${bundle.file.sizeBytes}')
      throw StateError('Invalid upload authorization.');
    return UploadAuthorization(url: url, headers: headers);
  }

  @override
  Future<void> upload(UploadAuthorization authorization, File file) async {
    if (authorization.url == null) return;
    await _bounded((abort) async {
      final request = _FileRequest(authorization.url!, file, abort)
        ..followRedirects = false
        ..contentLength = await file.length();
      request.headers.addAll(authorization.headers);
      final response = await client.send(request);
      await response.stream.drain<void>();
      if (![200, 201, 204, 412].contains(response.statusCode))
        throw StateError('Raw upload failed.');
    });
  }

  @override
  Future<TrialFile> finalize(UploadBundle bundle) async {
    final response = await _request(bundle.deviceToken, {
      'action': 'finalize_upload',
      'trial_id': bundle.trial.id,
    });
    final manifest = TrialFile.fromJson(asJson(response['manifest']));
    _match(bundle.file, manifest);
    if (response['verified'] != true ||
        manifest.syncStatus != SyncStatus.synced)
      throw StateError('Remote verification is incomplete.');
    return manifest;
  }

  void _match(TrialFile expected, TrialFile actual) {
    if (expected.id != actual.id ||
        expected.trialId != actual.trialId ||
        expected.sha256 != actual.sha256 ||
        expected.sizeBytes != actual.sizeBytes ||
        expected.objectKey != actual.objectKey ||
        expected.contentType != actual.contentType)
      throw StateError('Remote file manifest differs from local data.');
  }
}
