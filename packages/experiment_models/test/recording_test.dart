import 'package:experiment_models/recording.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final path = [
    RecordingState.ready,
    RecordingState.countdown,
    RecordingState.recording,
    RecordingState.stopping,
    RecordingState.validating,
    RecordingState.saved,
  ];
  RecordingMachine reach(RecordingState state) {
    final m = RecordingMachine();
    if (state == RecordingState.idle) return m;
    if (state == RecordingState.failed) {
      m.moveTo(RecordingState.ready);
      m.moveTo(state);
      return m;
    }
    for (final step in path) {
      m.moveTo(step);
      if (step == state) break;
    }
    return m;
  }

  test('every valid and invalid state pair is guarded', () {
    for (final from in RecordingState.values) {
      for (final to in RecordingState.values) {
        final machine = reach(from);
        if (RecordingMachine.transitions[from]!.contains(to)) {
          machine.moveTo(to);
          expect(machine.state, to);
        } else {
          expect(
            () => machine.moveTo(to),
            throwsStateError,
            reason: '$from -> $to',
          );
          expect(machine.state, from);
        }
      }
    }
  });
  test('process death invalidates transient states and unverified saves', () {
    for (final state in [
      RecordingState.countdown,
      RecordingState.recording,
      RecordingState.stopping,
      RecordingState.validating,
    ]) {
      expect(
        RecordingMachine.restore(state, locallySafe: true).state,
        RecordingState.failed,
      );
    }
    expect(
      RecordingMachine.restore(RecordingState.saved, locallySafe: false).state,
      RecordingState.failed,
    );
    expect(
      RecordingMachine.restore(RecordingState.saved, locallySafe: true).state,
      RecordingState.saved,
    );
    expect(
      RecordingMachine.restore(RecordingState.ready, locallySafe: false).state,
      RecordingState.ready,
    );
  });
}
