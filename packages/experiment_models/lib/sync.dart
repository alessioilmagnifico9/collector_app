import 'experiment_models.dart';

final class SyncMachine {
  SyncStatus _status;
  SyncStatus get status => _status;
  SyncMachine(this._status);
  static const transitions = <SyncStatus, Set<SyncStatus>>{
    SyncStatus.local: {SyncStatus.queued},
    SyncStatus.queued: {SyncStatus.uploading},
    SyncStatus.uploading: {
      SyncStatus.synced,
      SyncStatus.failed,
      SyncStatus.queued,
    },
    SyncStatus.failed: {SyncStatus.queued},
    SyncStatus.synced: {},
  };
  void moveTo(SyncStatus next) {
    if (!transitions[_status]!.contains(next))
      throw StateError(
        'Invalid sync transition: ${_status.name} → ${next.name}.',
      );
    _status = next;
  }
}
