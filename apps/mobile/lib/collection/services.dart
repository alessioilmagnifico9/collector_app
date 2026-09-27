import 'package:experiment_models/experiment_models.dart';
import 'package:protocol_engine/protocol_engine.dart';

final class Enrollment {
  final Study study;
  final Participant participant;
  final Protocol protocol;
  final ProtocolVersion version;
  const Enrollment(this.study, this.participant, this.protocol, this.version);
  factory Enrollment.fromJson(Json json) {
    final result = Enrollment(
      Study.fromJson(asJson(json['study'])),
      Participant.fromJson(asJson(json['participant'])),
      Protocol.fromJson(asJson(json['protocol'])),
      ProtocolVersion.fromJson(asJson(json['version'])),
    );
    if (result.study.id != result.participant.studyId ||
        result.study.id != result.protocol.studyId ||
        result.protocol.id != result.version.protocolId ||
        result.version.status != ProtocolStatus.published) {
      throw const FormatException('Enrollment identities do not match.');
    }
    ProtocolDefinition.fromJson(result.version.document);
    return result;
  }
  Json toJson() => {
    'study': study.toJson(),
    'participant': participant.toJson(),
    'protocol': protocol.toJson(),
    'version': version.toJson(),
  };
}

abstract interface class EnrollmentGateway {
  Future<Enrollment> enroll(String codeOrToken);
}

abstract interface class CachedEnrollmentGateway implements EnrollmentGateway {
  bool get hasSavedEnrollment;
  Future<Enrollment> resume();
  Future<Enrollment> refresh();
}

abstract interface class TrialCapture {
  Future<void> start(TrialPlan plan, Hand hand);

  /// Throws if the native attempt has failed or is no longer recording.
  Future<void> checkRecording();

  /// Completes when native callbacks stop and the raw file is closed.
  Future<void> stop();

  /// Completes only when the trial is safely persisted locally.
  Future<void> save();
  Future<void> abort();
}

abstract interface class SessionTrialCapture implements TrialCapture {
  void prepareSession(PinnedSession session);
}

abstract interface class CollectionSessionStore {
  Future<List<SessionDefinition>> definitions(Enrollment enrollment);
  Future<(PinnedSession, int)> open(
    Enrollment enrollment,
    SessionDefinition definition,
  );
}

final class UnconfiguredTrialCapture implements TrialCapture {
  @override
  Future<void> checkRecording() async =>
      throw StateError('Recording is unavailable.');
  @override
  Future<void> start(TrialPlan plan, Hand hand) async =>
      throw StateError('Recording is unavailable.');
  @override
  Future<void> stop() async => throw StateError('Recording is unavailable.');
  @override
  Future<void> save() async => throw StateError('Recording is unavailable.');
  @override
  Future<void> abort() async {}
}

/// Explicit demo adapter. Never selected implicitly when live configuration fails.
final class DemoEnrollmentGateway implements EnrollmentGateway {
  final Enrollment enrollment;
  DemoEnrollmentGateway(Json document) : enrollment = _create(document);
  static Enrollment _create(Json document) {
    final now = DateTime.utc(2026, 9, 23);
    final study = Study(
      id: '00000000-0000-4000-8000-000000000001',
      name: 'Motion study demonstration',
      createdAt: now,
    );
    final person = Participant(
      id: '00000000-0000-4000-8000-000000000003',
      studyId: study.id,
      sex: Sex.notReported,
      dominantHand: Hand.right,
      createdAt: now,
    );
    final protocol = Protocol(
      id: '00000000-0000-4000-8000-000000000004',
      studyId: study.id,
      name: 'Demonstration',
      createdAt: now,
    );
    final version = publishVersion(
      ProtocolVersion(
        id: '00000000-0000-4000-8000-000000000005',
        protocolId: protocol.id,
        version: 1,
        schemaVersion: 1,
        status: ProtocolStatus.draft,
        document: document,
        createdAt: now,
      ),
      now,
    );
    return Enrollment(study, person, protocol, version);
  }

  @override
  Future<Enrollment> enroll(String codeOrToken) async {
    final input = codeOrToken.trim();
    final uri = Uri.tryParse(input);
    final code = uri?.scheme == 'collector' && uri?.host == 'enroll'
        ? uri?.queryParameters['token']
        : input;
    if (code?.toUpperCase() != 'DEMO2026')
      throw const FormatException('Enrollment not found.');
    return enrollment;
  }
}

final class UnconfiguredEnrollmentGateway implements EnrollmentGateway {
  @override
  Future<Enrollment> enroll(String codeOrToken) async =>
      throw StateError('Enrollment service is not configured.');
}

final class DemoTrialCapture implements TrialCapture {
  TrialPlan? _active;
  final Set<String> savedTrialIds = {};
  @override
  Future<void> checkRecording() async {
    if (_active == null) throw StateError('No trial is recording.');
  }

  @override
  Future<void> start(TrialPlan plan, Hand hand) async {
    if (_active != null) throw StateError('A trial is already recording.');
    _active = plan;
  }

  @override
  Future<void> stop() async {
    if (_active == null) throw StateError('No trial is recording.');
  }

  @override
  Future<void> save() async {
    final active = _active;
    if (active == null) throw StateError('No trial is recording.');
    savedTrialIds.add(active.id);
    _active = null;
  }

  @override
  Future<void> abort() async {
    _active = null;
  }
}
