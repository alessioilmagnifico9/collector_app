import 'dart:convert';
import 'dart:io';

import 'package:experiment_models/experiment_models.dart';
import 'package:protocol_engine/protocol_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Json example() => asJson(
    jsonDecode(
      File('../../protocols/example_protocol.json').readAsStringSync(),
    ),
  );
  final now = DateTime.utc(2026, 9, 23);
  final studyId = newUuid(), protocolId = newUuid();
  final person = Participant(
    id: newUuid(),
    studyId: studyId,
    sex: Sex.notReported,
    dominantHand: Hand.right,
    createdAt: now,
  );
  final protocol = Protocol(
    id: protocolId,
    studyId: studyId,
    name: 'Example',
    createdAt: now,
  );
  ProtocolVersion draft() => ProtocolVersion(
    id: newUuid(),
    protocolId: protocolId,
    version: 1,
    schemaVersion: 1,
    status: ProtocolStatus.draft,
    document: example(),
    createdAt: now,
  );

  test('example parses, validates and serializes canonically', () {
    expect(validateProtocol(example()), isEmpty);
    final parsed = ProtocolDefinition.fromJson(example());
    expect(
      ProtocolDefinition.fromJson(parsed.toJson()).toJson(),
      parsed.toJson(),
    );
  });
  test(
    'queue preserves order, practice and repetition metadata with unique IDs',
    () {
      final definition = ProtocolDefinition.fromJson(example());
      final queue = generateTrialQueue(definition.sessions.single);
      expect(queue, hasLength(5));
      expect(queue.map((q) => q.repetition), [1, 1, 2, 1, 2]);
      expect(queue.first.taskType, TaskType.practice);
      expect(queue[1].taskType, TaskType.genuine);
      expect(queue.first.resolveHand(Hand.right), Hand.right);
      expect(queue.last.resolveHand(Hand.right), Hand.left);
      expect(queue.map((q) => q.id).toSet(), hasLength(5));
      expect(() => queue.clear(), throwsUnsupportedError);
    },
  );
  test('ambidextrous participants must explicitly select an actual hand', () {
    final task = generateTrialQueue(
      ProtocolDefinition.fromJson(example()).sessions.single,
    ).first;
    expect(() => task.resolveHand(Hand.either), throwsStateError);
    expect(task.resolveHand(Hand.either, selected: Hand.left), Hand.left);
  });
  test('invalid nested protocols return actionable locations', () {
    final json = example();
    final sessions = json['sessions'] as List<Object?>;
    final tasks = asJson(sessions.first)['tasks'] as List<Object?>;
    asJson(tasks.first)['repetitions'] = 0;
    expect(
      validateProtocol(json).single,
      contains('sessions[0]: tasks[0]: repetitions'),
    );
    expect(
      validateProtocol({...example(), 'requested_hz': double.nan}),
      isNotEmpty,
    );
    expect(validateProtocol({...example(), 'unknown': true}), isNotEmpty);
    expect(
      validateProtocol({...example(), 'sessions': <Object?>[]}),
      isNotEmpty,
    );
    tasks.add(tasks.first);
    asJson(tasks.first)['repetitions'] = 1;
    expect(validateProtocol(json).single, contains('unique'));
  });
  test('publication validates and published versions cannot be edited', () {
    final published = publishVersion(draft(), now);
    expect(() => editDraft(published, example()), throwsStateError);
    expect(() => publishVersion(published, now), throwsStateError);
    final next = duplicateVersion(published, nextVersion: 2, now: now);
    expect(next.id, isNot(published.id));
    expect(next.status, ProtocolStatus.draft);
    expect(
      () => publishVersion(editDraft(next, {}), now),
      throwsFormatException,
    );
  });
  test(
    'cached session retains exact version and trial IDs after new publication',
    () {
      final version = publishVersion(draft(), now);
      final session = startSession(
        version: version,
        protocol: protocol,
        participant: person,
        sessionDefinitionId: ProtocolDefinition.fromJson(version.document)
            .sessions
            .single
            .id,
        now: now,
      );
      final next = publishVersion(
        duplicateVersion(version, nextVersion: 2, now: now),
        now,
      );
      final restored = PinnedSession.fromJson(
        asJson(jsonDecode(jsonEncode(session.toJson()))),
      );
      expect(restored.version.id, version.id);
      expect(restored.version.id, isNot(next.id));
      expect(restored.queue.map((t) => t.id), session.queue.map((t) => t.id));
      final corrupt = asJson(jsonDecode(jsonEncode(session.toJson())));
      (corrupt['queue'] as List<Object?>).removeLast();
      expect(() => PinnedSession.fromJson(corrupt), throwsFormatException);
      expect(
        () => PinnedSession(
          session: session.session,
          version: next,
          queue: session.queue,
        ),
        throwsStateError,
      );
    },
  );
  test('session cannot cross study boundary or use a draft', () {
    final version = draft();
    final id = ProtocolDefinition.fromJson(version.document).sessions.single.id;
    expect(
      () => startSession(
        version: version,
        protocol: protocol,
        participant: person,
        sessionDefinitionId: id,
        now: now,
      ),
      throwsStateError,
    );
    final other = Protocol(
      id: protocolId,
      studyId: newUuid(),
      name: 'Other',
      createdAt: now,
    );
    expect(
      () => startSession(
        version: publishVersion(version, now),
        protocol: other,
        participant: person,
        sessionDefinitionId: id,
        now: now,
      ),
      throwsStateError,
    );
  });
}
