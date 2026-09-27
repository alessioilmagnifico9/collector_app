import 'dart:async';

import 'package:collector_admin/auth/researcher_auth.dart';
import 'package:collector_admin/main.dart';
import 'package:collector_admin/studies.dart';
import 'package:experiment_models/experiment_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class FakeAuth implements ResearcherAuth {
  final events = StreamController<bool>.broadcast();
  final pending = Completer<void>();
  int requests = 0;
  @override
  bool signedIn = false;
  @override
  Stream<bool> get changes => events.stream;
  @override
  Future<void> signIn(String email, String password) async {
    requests++;
    await pending.future;
    signedIn = true;
    events.add(true);
  }

  @override
  Future<void> signOut() async {
    signedIn = false;
    events.add(false);
  }
}

final class FakeStudies implements StudyRepository {
  @override
  Future<List<Study>> list() async => [];
  @override
  Future<void> create(String name) async {}
}

void main() {
  testWidgets('researcher auth guards dashboard and duplicate sign-in', (
    tester,
  ) async {
    final auth = FakeAuth();
    addTearDown(auth.events.close);
    await tester.pumpWidget(CollectorApp(auth: auth, studies: FakeStudies()));
    expect(find.text('Studies'), findsNothing);
    await tester.enterText(
      find.byType(TextField).first,
      'researcher@example.invalid',
    );
    await tester.enterText(find.byType(TextField).last, 'test-only-password');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(auth.requests, 1);
    auth.pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Studies'), findsOneWidget);
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Researcher sign-in'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      isEmpty,
    );
  });
  testWidgets(
    'failed authentication never opens studies or exposes backend errors',
    (tester) async {
      final auth = FakeAuth();
      addTearDown(auth.events.close);
      await tester.pumpWidget(CollectorApp(auth: auth, studies: FakeStudies()));
      await tester.tap(find.text('Sign in'));
      auth.pending.completeError(StateError('sensitive backend response'));
      await tester.pumpAndSettle();
      expect(find.text('Studies'), findsNothing);
      expect(find.textContaining('sensitive backend'), findsNothing);
      expect(find.textContaining('Check your details'), findsOneWidget);
    },
  );
}
