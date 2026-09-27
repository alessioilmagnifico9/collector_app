import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:experiment_models/experiment_models.dart';
import 'package:protocol_engine/protocol_engine.dart';

import 'services.dart';

import 'package:experiment_models/recording.dart';

enum CollectionPage {
  enrollment,
  overview,
  instructions,
  countdown,
  recording,
  saving,
  saved,
  completed,
  failed,
}

final class CollectionController extends ChangeNotifier {
  final EnrollmentGateway enrollmentGateway;
  final TrialCapture capture;
  final CollectionSessionStore? sessionStore;
  final bool demo;
  final void Function()? onSyncRequested;
  final Future<void> Function()? onClose;
  bool foreground = true;
  bool get allowsSync =>
      foreground &&
      !_disposed &&
      !busy &&
      !{
        CollectionPage.countdown,
        CollectionPage.recording,
        CollectionPage.saving,
      }.contains(page);
  void setForeground(bool value) {
    foreground = value;
    if (value) onSyncRequested?.call();
  }

  final recording = RecordingMachine();
  CollectionController({
    required this.enrollmentGateway,
    required this.capture,
    this.sessionStore,
    this.demo = false,
    this.onSyncRequested,
    this.onClose,
  });
  CollectionPage page = CollectionPage.enrollment;
  Enrollment? enrollment;
  PinnedSession? session;
  List<SessionDefinition> availableSessions = [];
  bool busy = false;
  String? error;
  int index = 0, countdown = 3;
  Hand selectedHand = Hand.right;
  Timer? _timer;
  Timer? _healthTimer;
  int _healthGeneration = 0;
  bool _disposed = false;
  bool _starting = false;
  Completer<void>? _startDone, _saveDone;
  TrialPlan get current => session!.queue[index];
  bool get canResume =>
      enrollmentGateway is CachedEnrollmentGateway &&
      (enrollmentGateway as CachedEnrollmentGateway).hasSavedEnrollment;
  void _notify() {
    if (!_disposed) {
      notifyListeners();
      if (allowsSync) onSyncRequested?.call();
    }
  }

  Future<void> enroll(String input) async {
    if (busy || page != CollectionPage.enrollment) return;
    busy = true;
    error = null;
    _notify();
    try {
      enrollment = input.isEmpty && canResume
          ? await (enrollmentGateway as CachedEnrollmentGateway).resume()
          : await enrollmentGateway.enroll(input);
      if (_disposed) return;
      availableSessions =
          await sessionStore?.definitions(enrollment!) ??
          ProtocolDefinition.fromJson(enrollment!.version.document).sessions;
      selectedHand = enrollment!.participant.dominantHand == Hand.left
          ? Hand.left
          : Hand.right;
      page = CollectionPage.overview;
    } catch (_) {
      error = 'We could not open your study. Check your code or contact your researcher.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> refreshStudy() async {
    if (busy || page != CollectionPage.overview || !canResume) return;
    busy = true;
    error = null;
    _notify();
    try {
      enrollment = await (enrollmentGateway as CachedEnrollmentGateway)
          .refresh();
      availableSessions =
          await sessionStore?.definitions(enrollment!) ??
          ProtocolDefinition.fromJson(enrollment!.version.document).sessions;
    } catch (_) {
      error = 'The study could not be refreshed. You can continue with the tasks already saved on this phone.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> selectSession(SessionDefinition definition) async {
    if (page != CollectionPage.overview || busy) return;
    busy = true;
    error = null;
    _notify();
    final enrolled = enrollment!;
    try {
      final store = sessionStore;
      if (store != null) {
        final restored = await store.open(enrolled, definition);
        session = restored.$1;
        index = restored.$2;
      } else {
        session = startSession(
          version: enrolled.version,
          protocol: enrolled.protocol,
          participant: enrolled.participant,
          sessionDefinitionId: definition.id,
          now: DateTime.now().toUtc(),
        );
        index = 0;
      }
      if (_disposed) return;
      final recorder = capture;
      if (recorder is SessionTrialCapture) recorder.prepareSession(session!);
      if (recording.state != RecordingState.ready)
        recording.moveTo(RecordingState.ready);
      page = index == session!.queue.length
          ? CollectionPage.completed
          : CollectionPage.instructions;
    } catch (_) {
      error = 'We could not open this session safely. Please contact your researcher.';
    } finally {
      busy = false;
      _notify();
    }
  }

  Hand get actualHand => current.resolveHand(
    enrollment!.participant.dominantHand,
    selected: selectedHand,
  );
  void chooseHand(Hand hand) {
    if (page != CollectionPage.instructions ||
        (hand != Hand.left && hand != Hand.right))
      return;
    selectedHand = hand;
    _notify();
  }

  void start() {
    if (page != CollectionPage.instructions || busy) return;
    recording.moveTo(RecordingState.countdown);
    page = CollectionPage.countdown;
    countdown = 3;
    _notify();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      countdown--;
      if (countdown == 0) {
        timer.cancel();
        unawaited(_begin());
      } else {
        _notify();
      }
    });
  }

  Future<void> _begin() async {
    if (_disposed || page != CollectionPage.countdown) return;
    busy = true;
    _starting = true;
    _startDone = Completer<void>();
    try {
      await capture.start(current, actualHand);
      if (_disposed || page != CollectionPage.countdown) {
        await capture.abort();
        return;
      }
      recording.moveTo(RecordingState.recording);
      page = CollectionPage.recording;
      _monitorRecording();
      final seconds = current.task.durationSeconds;
      if (seconds != null)
        _timer = Timer(
          Duration(milliseconds: (seconds * 1000).round()),
          () => unawaited(stop()),
        );
    } catch (_) {
      _failRecording();
      page = CollectionPage.failed;
      error = 'Recording could not start. Please try again.';
    } finally {
      _starting = false;
      _startDone?.complete();
      _startDone = null;
      busy = false;
      _notify();
    }
  }

  Future<void> stop() async {
    if (page != CollectionPage.recording || busy) return;
    _cancelHealthCheck();
    _timer?.cancel();
    busy = true;
    _saveDone = Completer<void>();
    recording.moveTo(RecordingState.stopping);
    page = CollectionPage.saving;
    _notify();
    try {
      await capture.stop();
      recording.moveTo(RecordingState.validating);
      await capture.save();
      recording.moveTo(RecordingState.saved);
      if (!_disposed) page = CollectionPage.saved;
    } catch (_) {
      _failRecording();
      page = CollectionPage.failed;
      error = 'This recording could not be saved. Please ask your researcher for help.';
    } finally {
      _saveDone?.complete();
      _saveDone = null;
      busy = false;
      _notify();
    }
  }

  void next() {
    if (page != CollectionPage.saved || busy) return;
    index++;
    if (index < session!.queue.length) recording.moveTo(RecordingState.ready);
    page = index == session!.queue.length
        ? CollectionPage.completed
        : CollectionPage.instructions;
    _notify();
  }

  Future<void> interrupt() async {
    if (!{CollectionPage.countdown, CollectionPage.recording}.contains(page))
      return;
    _cancelHealthCheck();
    _timer?.cancel();
    _failRecording();
    page = CollectionPage.failed;
    error = 'Recording was interrupted. Please repeat this task.';
    busy = true;
    _notify();
    try {
      await capture.abort();
    } catch (_) {
      error = 'Please contact your researcher before continuing.';
    } finally {
      busy = _starting;
      _notify();
    }
  }

  Future<void> retry() async {
    if (page != CollectionPage.failed || busy) return;
    busy = true;
    try {
      await capture.abort();
      recording.moveTo(RecordingState.ready);
      page = CollectionPage.instructions;
      error = null;
    } catch (_) {
      error = 'Please contact your researcher before continuing.';
    } finally {
      busy = false;
      _notify();
    }
  }

  void returnToStudy() {
    if (busy || page != CollectionPage.completed) return;
    page = CollectionPage.overview;
    session = null;
    index = 0;
    error = null;
    _notify();
  }

  void changeParticipant() {
    if (busy ||
        !{CollectionPage.overview, CollectionPage.completed}.contains(page))
      return;
    page = CollectionPage.enrollment;
    enrollment = null;
    session = null;
    availableSessions = [];
    index = 0;
    error = null;
    _notify();
  }

  void _failRecording() {
    if (RecordingMachine.transitions[recording.state]!.contains(
      RecordingState.failed,
    ))
      recording.moveTo(RecordingState.failed);
  }

  void _cancelHealthCheck() {
    _healthGeneration++;
    _healthTimer?.cancel();
    _healthTimer = null;
  }

  void _monitorRecording() {
    _cancelHealthCheck();
    final generation = _healthGeneration;
    var checking = false;
    _healthTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (checking || _disposed || page != CollectionPage.recording) return;
      checking = true;
      try {
        await capture.checkRecording().timeout(const Duration(seconds: 5));
      } catch (_) {
        if (!_disposed &&
            generation == _healthGeneration &&
            page == CollectionPage.recording) {
          await interrupt();
        }
      } finally {
        checking = false;
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelHealthCheck();
    _timer?.cancel();
    unawaited(() async {
      try {
        await capture.abort();
      } catch (_) {}
      await _startDone?.future;
      await _saveDone?.future;
      await onClose?.call();
    }());
    super.dispose();
  }
}
