import 'package:experiment_models/experiment_models.dart';
import 'package:experiment_models/sync.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('durable sync transitions reject invalid shortcuts', () {
    for (final from in SyncStatus.values) {
      for (final to in SyncStatus.values) {
        final machine = SyncMachine(from);
        if (SyncMachine.transitions[from]!.contains(to)) {
          machine.moveTo(to);
          expect(machine.status, to);
        } else {
          expect(() => machine.moveTo(to), throwsStateError);
        }
      }
    }
  });
}
