import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collector_mobile/collection/controller.dart';
import 'package:collector_mobile/collection/services.dart';
import 'package:collector_mobile/main.dart';
import 'package:experiment_models/experiment_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol_engine/protocol_engine.dart';

DemoEnrollmentGateway gateway() => DemoEnrollmentGateway(
  asJson(
    jsonDecode(
      File('../../protocols/example_protocol.json').readAsStringSync(),
    ),
  ),
);
Future<void> countdown(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pump();
}

final class ControlledCapture implements TrialCapture {
  int starts = 0, stops = 0;
  final saved = Completer<void>();
  Completer<void>? starting;
  Completer<void>? health;
  int healthChecks = 0, aborts = 0;
  bool failHealth = false;
  @override
  Future<void> checkRecording() async {
    healthChecks++;
    if (failHealth) throw StateError('Native write failed');
    await health?.future;
  }

  @override
  Future<void> start(TrialPlan plan, Hand hand) async {
    starts++;
    await starting?.future;
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> save() => saved.future;

  @override
  Future<void> abort() async {
    aborts++;
  }
}

void main() {
  Future<CollectionController> recordingFlow(
    WidgetTester tester,
    ControlledCapture capture,
  ) async {
    final flow = CollectionController(
      enrollmentGateway: gateway(),
      capture: capture,
    );
    await flow.enroll('DEMO2026');
    await flow.selectSession(flow.availableSessions.single);
    await tester.pumpWidget(CollectorApp(controller: flow));
    flow.start();
    await countdown(tester);
    return flow;
  }

  testWidgets('native failure leaves recording and repeats the same trial', (
    tester,
  ) async {
    final capture = ControlledCapture()..failHealth = true;
    final flow = await recordingFlow(tester, capture);
    final id = flow.current.id;
    await tester.pump(const Duration(seconds: 1));
    expect(flow.page, CollectionPage.failed);
    expect(find.text('Recording'), findsNothing);
    expect(find.text('Saved'), findsNothing);
    expect(capture.aborts, 1);
    expect(capture.stops, 0);
    await tester.pump(const Duration(seconds: 2));
    expect(capture.healthChecks, 1);
    await flow.retry();
    expect(flow.page, CollectionPage.instructions);
    expect(flow.current.id, id);
  });

  testWidgets('health checks do not overlap and stalled replies fail safely', (
    tester,
  ) async {
    final capture = ControlledCapture()..health = Completer<void>();
    final flow = await recordingFlow(tester, capture);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 4));
    expect(capture.healthChecks, 1);
    expect(flow.page, CollectionPage.recording);
    await tester.pump(const Duration(seconds: 1));
    expect(flow.page, CollectionPage.failed);
    capture.health!.complete();
    await tester.pump();
    expect(flow.page, CollectionPage.failed);
  });

  testWidgets('late health failure cannot invalidate a saved trial', (
    tester,
  ) async {
    final capture = ControlledCapture()..health = Completer<void>();
    final flow = await recordingFlow(tester, capture);
    await tester.pump(const Duration(seconds: 1));
    capture.saved.complete();
    await flow.stop();
    capture.health!.completeError(StateError('Old response'));
    await tester.pump();
    expect(flow.page, CollectionPage.saved);
    expect(capture.aborts, 0);
  });

  testWidgets('late health failure cannot interrupt a new attempt', (
    tester,
  ) async {
    final capture = ControlledCapture()..health = Completer<void>();
    final flow = await recordingFlow(tester, capture);
    await tester.pump(const Duration(seconds: 1));
    final oldHealth = capture.health!;
    await flow.interrupt();
    await flow.retry();
    capture.health = null;
    flow.start();
    await countdown(tester);
    oldHealth.completeError(StateError('Old response'));
    await tester.pump();
    expect(flow.page, CollectionPage.recording);
    expect(capture.starts, 2);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a full offline demo session follows the protocol queue', (
    tester,
  ) async {
    final capture = DemoTrialCapture();
    final flow = CollectionController(
      enrollmentGateway: gateway(),
      capture: capture,
      demo: true,
    );
    await tester.pumpWidget(CollectorApp(controller: flow));
    await tester.enterText(find.byType(TextField), 'DEMO2026');
    await tester.tap(find.text('Open study'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Motion session'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Ready — start'));
      flow.start();
      await countdown(tester);
      expect(flow.page, CollectionPage.recording);
      await tester.tap(find.text('Stop recording'));
      await tester.pumpAndSettle();
      expect(find.text('Demonstration complete'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Session complete'), findsOneWidget);
    expect(capture.savedTrialIds, hasLength(5));
    expect(find.textContaining('00000000-'), findsNothing);
    await tester.tap(find.text('Back to study'));
    await tester.pumpAndSettle();
    expect(flow.page, CollectionPage.overview);
    await tester.tap(find.text('Motion session'));
    await tester.pumpAndSettle();
    expect(flow.page, CollectionPage.instructions);
    expect(flow.error, isNull);
  });
  testWidgets(
    'double taps cannot duplicate capture and saved waits for persistence',
    (tester) async {
      final capture = ControlledCapture();
      final flow = CollectionController(
        enrollmentGateway: gateway(),
        capture: capture,
      );
      await flow.enroll('collector://enroll?token=DEMO2026');
      await flow.selectSession(
        ProtocolDefinition.fromJson(flow.enrollment!.version.document)
            .sessions
            .single,
      );
      await tester.pumpWidget(CollectorApp(controller: flow));
      flow.start();
      flow.start();
      await countdown(tester);
      expect(capture.starts, 1);
      final stop = flow.stop();
      unawaited(flow.stop());
      await tester.pump();
      expect(capture.stops, 1);
      expect(flow.page, CollectionPage.saving);
      expect(find.text('Saved'), findsNothing);
      capture.saved.complete();
      await stop;
      await tester.pump();
      expect(flow.page, CollectionPage.saved);
    },
  );
  testWidgets('interruption fences a delayed native start until it settles', (
    tester,
  ) async {
    final capture = ControlledCapture()..starting = Completer<void>();
    final flow = CollectionController(
      enrollmentGateway: gateway(),
      capture: capture,
    );
    await flow.enroll('DEMO2026');
    await flow.selectSession(flow.availableSessions.single);
    await tester.pumpWidget(CollectorApp(controller: flow));
    flow.start();
    await countdown(tester);
    expect(flow.busy, isTrue);
    expect(flow.allowsSync, isFalse);
    flow.setForeground(false);
    await flow.interrupt();
    expect(flow.busy, isTrue);
    await flow.retry();
    expect(flow.page, CollectionPage.failed);
    capture.starting!.complete();
    await tester.pump();
    expect(flow.busy, isFalse);
    expect(flow.allowsSync, isFalse);
    flow.setForeground(true);
    await flow.retry();
    expect(flow.page, CollectionPage.instructions);
    expect(flow.allowsSync, isTrue);
    expect(capture.starts, 1);
  });

  testWidgets('disposal lets a local commit finish before closing storage', (
    tester,
  ) async {
    var closed = false;
    final capture = ControlledCapture();
    final flow = CollectionController(
      enrollmentGateway: gateway(),
      capture: capture,
      onClose: () async {
        closed = true;
      },
    );
    await flow.enroll('DEMO2026');
    await flow.selectSession(flow.availableSessions.single);
    await tester.pumpWidget(CollectorApp(controller: flow));
    flow.start();
    await countdown(tester);
    final stopping = flow.stop();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    expect(closed, isFalse);
    capture.saved.complete();
    await stopping;
    await tester.pump();
    expect(closed, isTrue);
  });

  testWidgets('save failure never shows saved confirmation', (tester) async {
    final capture = ControlledCapture();
    final flow = CollectionController(
      enrollmentGateway: gateway(),
      capture: capture,
    );
    await flow.enroll('DEMO2026');
    await flow.selectSession(
      ProtocolDefinition.fromJson(flow.enrollment!.version.document)
          .sessions
          .single,
    );
    await tester.pumpWidget(CollectorApp(controller: flow));
    flow.start();
    await countdown(tester);
    final stop = flow.stop();
    capture.saved.completeError(StateError('disk full'));
    await stop;
    await tester.pump();
    expect(flow.page, CollectionPage.failed);
    expect(find.text('Saved'), findsNothing);
  });
  testWidgets('small screen and large text remain scrollable and accessible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const CollectorApp());
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
    final semantics = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    semantics.dispose();
  });
}
