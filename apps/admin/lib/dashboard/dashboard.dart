import 'dart:async';

import 'package:experiment_models/experiment_models.dart';
import 'package:flutter/material.dart';

import 'repository.dart';

class ResearchDashboard extends StatefulWidget {
  final Study study;
  final DashboardRepository repository;
  const ResearchDashboard({
    super.key,
    required this.study,
    required this.repository,
  });
  @override
  State<ResearchDashboard> createState() => _ResearchDashboardState();
}

class _ResearchDashboardState extends State<ResearchDashboard> {
  StudyDataset? data;
  bool busy = true;
  String? error;
  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final value = await widget.repository.load(widget.study.id);
      if (mounted) setState(() => data = value);
    } catch (_) {
      if (mounted)
        setState(() {
          data = null;
          error = 'Progress could not be loaded. Check your connection and study access.';
        });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = data;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          spacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Study progress',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            TextButton(
              onPressed: busy ? null : load,
              child: const Text('Refresh progress'),
            ),
          ],
        ),
        const Text(
          'Only data received by the server is shown. Phones that are offline may have additional safely saved recordings. Codes and QR enrollment are available when creating a participant in the Participants tab.',
        ),
        if (busy) const LinearProgressIndicator(),
        if (error != null) Text(error!),
        if (snapshot != null) ...[
          Text(
            '${snapshot.participants.length} participants · ${snapshot.sessions.length} sessions · ${snapshot.trials.length} trials',
          ),
          Text(
            '${snapshot.files.where((f) => f.syncStatus != SyncStatus.synced).length} pending or failed uploads',
          ),
          for (final person in snapshot.participants)
            Card(
              child: ExpansionTile(
                title: Text(person.displayLabel),
                subtitle: Text(
                  '${snapshot.sessions.where((s) => s.participantId == person.id).length} sessions received',
                ),
                children: [
                  for (final session in snapshot.sessions.where(
                    (s) => s.participantId == person.id,
                  ))
                    ExpansionTile(
                      title: Text(snapshot.names.sessionLabel(session)),
                      subtitle: Text(
                        '${snapshot.synced(session)}/${snapshot.expected(session)} verified · protocol v${snapshot.version(session).version} · ${session.completedAt == null ? 'Incomplete' : 'Complete'}',
                      ),
                      children: [
                        SelectableText(
                          'Session ${session.id} · version ${session.protocolVersionId}',
                        ),
                        for (final trial in snapshot.sessionTrials(session))
                          ListTile(
                            title: Text(snapshot.names.trialLabel(trial)),
                            subtitle: SelectableText(
                              [
                                '${snapshot.trialFile(trial)?.syncStatus.name ?? 'pending'} · ${trial.handUsed.name} · ${trial.posture.name}',
                                'Trial ${trial.id} · device ${trial.physicalDeviceId}',
                                'Duration ${trial.quality.durationSeconds.toStringAsFixed(2)} s',
                                ...snapshot.warnings(trial),
                              ].join('\n'),
                            ),
                            leading: Icon(
                              snapshot.warnings(trial).isEmpty
                                  ? Icons.check_circle_outline
                                  : Icons.warning_amber,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          Text('Devices', style: Theme.of(context).textTheme.headlineSmall),
          for (final device in snapshot.devices)
            ExpansionTile(
              title: Text('${device.manufacturer} ${device.model}'),
              subtitle: Text(
                '${device.os} ${device.osVersion} · app ${device.appVersion}',
              ),
              children: [
                SelectableText(device.id),
                for (final sensor in device.sensors)
                  ListTile(
                    title: Text('${sensor.sensorType.name} · ${sensor.name}'),
                    subtitle: Text(
                      'Vendor: ${sensor.vendor ?? 'unavailable'} · requested ${sensor.requestedHz} Hz · range ${sensor.maximumRange ?? 'unavailable'} · resolution ${sensor.resolution ?? 'unavailable'}',
                    ),
                  ),
              ],
            ),
        ],
      ],
    );
  }
}
