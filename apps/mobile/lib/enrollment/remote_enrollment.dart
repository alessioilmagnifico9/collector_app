import 'dart:async';
import 'dart:convert';

import 'package:experiment_models/experiment_models.dart';
import 'package:http/http.dart' as http;

import '../collection/services.dart';
import '../storage/local_database.dart' show LocalDatabase;

final class RemoteEnrollmentGateway implements CachedEnrollmentGateway {
  final LocalDatabase database;
  final PhysicalDevice device;
  final Uri? endpoint;
  final String? publicKey;
  final http.Client client;
  final Duration requestTimeout;
  Enrollment? _cached;
  String? _deviceToken;
  RemoteEnrollmentGateway({
    required this.database,
    required this.device,
    required this.endpoint,
    required this.publicKey,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 30),
  }) : client = client ?? http.Client();

  Future<Json> _request(Json body, {String? token}) async {
    final url = endpoint;
    if (url == null || publicKey == null || publicKey!.isEmpty)
      throw StateError('Enrollment is not configured.');
    final abort = Completer<void>();
    final timer = Timer(requestTimeout, abort.complete);
    try {
      final request =
          http.AbortableRequest('POST', url, abortTrigger: abort.future)
            ..followRedirects = false
            ..headers.addAll({
              'apikey': publicKey!,
              'content-type': 'application/json',
              if (token != null) 'authorization': 'Bearer $token',
            })
            ..body = jsonEncode(body);
      final response = await (() async => http.Response.fromStream(
        await client.send(request),
      ))().timeout(requestTimeout);
      if (response.statusCode != 200)
        throw StateError('Enrollment request failed.');
      return asJson(jsonDecode(response.body));
    } finally {
      timer.cancel();
      if (!abort.isCompleted) abort.complete();
    }
  }

  @override
  bool get hasSavedEnrollment => _cached != null;
  String? get deviceToken => _deviceToken;
  Future<void> initialize() async {
    final row = await database
        .select(database.savedEnrollment)
        .getSingleOrNull();
    if (row != null) {
      _cached = Enrollment.fromJson(asJson(jsonDecode(row.payload)));
      _deviceToken = row.deviceToken;
    }
  }

  @override
  Future<Enrollment> enroll(String codeOrToken) async {
    final result = await _request({
      'action': 'enroll',
      'credential': codeOrToken.trim(),
      'device': device.toJson(),
    });
    final enrollment = Enrollment.fromJson(result);
    final token = stringField(result, 'device_token');
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(token))
      throw const FormatException('Invalid device credential.');
    await database.transaction(() async {
      await database.cacheParticipant(enrollment.participant);
      await database.cacheProtocol(enrollment.version);
      await database.customStatement(
        'INSERT INTO enrollment_grants(participant_id, device_token) VALUES(?, ?) ON CONFLICT(participant_id) DO UPDATE SET device_token=excluded.device_token',
        [enrollment.participant.id, token],
      );
      await database.customStatement(
        'INSERT INTO saved_enrollment(slot, payload, device_token) VALUES(1, ?, ?) ON CONFLICT(slot) DO UPDATE SET payload=excluded.payload, device_token=excluded.device_token',
        [jsonEncode(enrollment.toJson()), token],
      );
    });
    _cached = enrollment;
    _deviceToken = token;
    return enrollment;
  }

  @override
  Future<Enrollment> resume() async {
    final saved = _cached;
    if (saved == null) throw StateError('No study is saved on this phone.');
    return saved;
  }

  @override
  Future<Enrollment> refresh() async {
    final previous = await resume();
    if (endpoint == null || _deviceToken == null)
      throw StateError('Study refresh is unavailable.');
    final updated = Enrollment.fromJson(
      await _request({'action': 'refresh'}, token: _deviceToken),
    );
    if (updated.participant.id != previous.participant.id ||
        updated.study.id != previous.study.id ||
        updated.protocol.id != previous.protocol.id)
      throw StateError('Refresh changed enrollment identity.');
    await database.transaction(() async {
      await database.cacheProtocol(updated.version);
      await database.cacheParticipant(updated.participant);
      await database.customStatement(
        'UPDATE saved_enrollment SET payload=? WHERE slot=1',
        [jsonEncode(updated.toJson())],
      );
    });
    _cached = updated;
    return updated;
  }
}
