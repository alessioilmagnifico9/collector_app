enum RecordingState {
  idle,
  ready,
  countdown,
  recording,
  stopping,
  validating,
  saved,
  failed,
}

/// Independent of widgets, sensors, storage, and network connectivity.
final class RecordingMachine {
  RecordingState _state;
  RecordingState get state => _state;
  RecordingMachine() : _state = RecordingState.idle;

  static const transitions = <RecordingState, Set<RecordingState>>{
    RecordingState.idle: {RecordingState.ready},
    RecordingState.ready: {RecordingState.countdown, RecordingState.failed},
    RecordingState.countdown: {RecordingState.recording, RecordingState.failed},
    RecordingState.recording: {RecordingState.stopping, RecordingState.failed},
    RecordingState.stopping: {RecordingState.validating, RecordingState.failed},
    RecordingState.validating: {RecordingState.saved, RecordingState.failed},
    RecordingState.saved: {RecordingState.ready},
    RecordingState.failed: {RecordingState.ready},
  };

  void moveTo(RecordingState next) {
    if (!transitions[_state]!.contains(next))
      throw StateError(
        'Invalid recording transition: ${_state.name} → ${next.name}.',
      );
    _state = next;
  }

  /// A callback stream cannot resume after process death. Only verified local
  /// persistence can restore Saved; partial trials require recovery or repetition.
  factory RecordingMachine.restore(
    RecordingState previous, {
    required bool locallySafe,
  }) {
    final machine = RecordingMachine();
    machine._state = switch (previous) {
      RecordingState.idle => RecordingState.idle,
      RecordingState.ready => RecordingState.ready,
      RecordingState.saved when locallySafe => RecordingState.saved,
      _ => RecordingState.failed,
    };
    return machine;
  }
}
