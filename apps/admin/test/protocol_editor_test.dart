import 'package:collector_admin/protocols/editor.dart';
import 'package:collector_admin/protocols/repository.dart';
import 'package:experiment_models/experiment_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol_engine/protocol_engine.dart';

class FakeProtocols implements ProtocolRepository {
  int saves = 0;
  Json? saved;
  @override
  Future<List<Protocol>> protocols(String studyId) async => [];
  @override
  Future<List<ProtocolVersion>> versions(String protocolId) async => [];
  @override
  Future<ProtocolVersion> create(
    String studyId,
    String name,
    Json document, {
    String? sourceId,
  }) async => throw UnimplementedError();
  @override
  Future<ProtocolVersion> save(
    ProtocolVersion expected,
    Json document, {
    bool publish = false,
  }) async {
    saves++;
    saved = document;
    final draft = editDraft(expected, document);
    return publish ? publishVersion(draft, DateTime.utc(2026)) : draft;
  }
}

void main() {
  testWidgets(
    'protocol forms edit, duplicate, validate, preview and publish immutable versions',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 2500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = FakeProtocols();
      final draft = ProtocolVersion(
        id: newUuid(),
        protocolId: newUuid(),
        version: 1,
        schemaVersion: 1,
        status: ProtocolStatus.draft,
        document: newProtocolDocument(),
        createdAt: DateTime.utc(2026),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProtocolEditor(
                version: draft,
                repository: repository,
                onSaved: (_) {},
              ),
            ),
          ),
        ),
      );
      final prompt = find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField &&
            widget.initialValue == 'Describe the movement',
      );
      await tester.enterText(prompt, 'Draw a square');
      await tester.tap(find.text('Duplicate task'));
      await tester.pumpAndSettle();
      expect(find.text('Task 2'), findsOneWidget);
      await tester.ensureVisible(find.text('Publish version'));
      await tester.tap(find.text('Publish version'));
      await tester.pumpAndSettle();
      expect(repository.saves, 1);
      final definition = ProtocolDefinition.fromJson(repository.saved!);
      expect(definition.sessions.single.tasks.map((task) => task.prompt), [
        'Draw a square',
        'Draw a square',
      ]);
      expect(
        definition.sessions.single.tasks.map((task) => task.id).toSet(),
        hasLength(2),
      );
      expect(find.text('Publish version'), findsNothing);
      await tester.ensureVisible(find.text('Preview participant flow'));
      await tester.tap(find.text('Preview participant flow'));
      await tester.pumpAndSettle();
      expect(find.text('Participant preview'), findsOneWidget);
    },
  );
  testWidgets('invalid nested values prevent publication', (tester) async {
    final repository = FakeProtocols();
    final doc = newProtocolDocument();
    asJson(
      (asJson((doc['sessions'] as List).single)['tasks'] as List).single,
    )['repetitions'] = 0;
    final draft = ProtocolVersion(
      id: newUuid(),
      protocolId: newUuid(),
      version: 1,
      schemaVersion: 1,
      status: ProtocolStatus.draft,
      document: doc,
      createdAt: DateTime.utc(2026),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProtocolEditor(
              version: draft,
              repository: repository,
              onSaved: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Publish version'));
    await tester.tap(find.text('Publish version'));
    await tester.pumpAndSettle();
    expect(repository.saves, 0);
    expect(find.textContaining('repetitions must be'), findsOneWidget);
  });
}
