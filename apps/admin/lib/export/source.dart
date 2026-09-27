import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'bundle.dart';

final class AuthorizedExportSource implements ExportSource {
  final Future<String> Function(String) authorize;
  final http.Client Function() clientFactory;
  final Duration timeout;
  AuthorizedExportSource(
    this.authorize, {
    this.clientFactory = http.Client.new,
    this.timeout = const Duration(minutes: 2),
  });
  @override
  Future<Uint8List> read(ExportEntry entry) async {
    final url = await authorize(entry.trial.id)
        .timeout(const Duration(seconds: 30));
    final client = clientFactory();
    final abort = Completer<void>();
    try {
      return await (() async {
        final request = http.AbortableRequest(
          'GET',
          Uri.parse(url),
          abortTrigger: abort.future,
        )..followRedirects = false;
        final response = await client.send(request);
        if (response.statusCode != 200 ||
            (response.contentLength != null &&
                response.contentLength != entry.file.sizeBytes)) {
          throw StateError('Download failed');
        }
        final bytes = BytesBuilder(copy: false);
        await for (final chunk in response.stream) {
          if (bytes.length + chunk.length > entry.file.sizeBytes ||
              bytes.length + chunk.length > maxArchiveBytes) {
            throw StateError('Download exceeds expected size');
          }
          bytes.add(chunk);
        }
        return bytes.takeBytes();
      })().timeout(timeout);
    } finally {
      if (!abort.isCompleted) abort.complete();
      client.close();
    }
  }
}
