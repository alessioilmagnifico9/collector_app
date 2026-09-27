import 'package:collector_admin/participants.dart';
import 'package:experiment_models/experiment_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

const id = '00000000-0000-4000-8000-000000000001';

class FakeParticipants implements ParticipantRepository {
  int creates = 0;
  @override
  Future<Json> enrollmentFor(String participantId) async {
    expect(participantId, id);
    return {
      'code': 'ABCD234567',
      'qr_payload': 'collector://enroll?token=ABCD234567',
    };
  }

  @override
  Future<List<Participant>> list(String studyId) async => [
    Participant(
      id: id,
      studyId: id,
      sex: Sex.notReported,
      dominantHand: Hand.right,
      createdAt: DateTime.utc(2026),
    ),
  ];
  @override
  Future<List<Json>> publishedProtocols(String studyId) async => [
    {'id': id, 'name': 'Pilot protocol'},
  ];
  @override
  Future<Json> create(
    String studyId,
    String protocolId,
    Sex sex,
    Hand hand,
  ) async {
    creates++;
    expect(studyId, id);
    expect(protocolId, id);
    expect(sex, Sex.notReported);
    expect(hand, Hand.right);
    return {
      'code': 'ABCD234567',
      'qr_payload': 'collector://enroll?token=${'a' * 64}',
    };
  }
}

void main() {
  testWidgets('researcher creates a pseudonymous enrollment with code and QR', (
    tester,
  ) async {
    final repository = FakeParticipants();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParticipantManager(
            study: Study(id: id, name: 'Pilot', createdAt: DateTime.utc(2026)),
            repository: repository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show code / QR'));
    await tester.pumpAndSettle();
    expect(find.text('ABCD234567'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(repository.creates, 0);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create participant and enrollment code'));
    await tester.pumpAndSettle();
    expect(repository.creates, 1);
    expect(find.text('ABCD234567'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
  });
}
