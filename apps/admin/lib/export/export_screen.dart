import 'dart:async';
import 'dart:typed_data';

import 'package:experiment_models/experiment_models.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

import '../dashboard/repository.dart';
import 'download.dart';
import 'bundle.dart';
import 'source.dart';

abstract interface class RawDownloadRepository {
  Future<String> authorize(String trialId);
}

final class SupabaseRawDownloadRepository implements RawDownloadRepository {
  final SupabaseClient client;
  SupabaseRawDownloadRepository(this.client);
  @override
  Future<String> authorize(String trialId) async {
    final response = await client.functions.invoke(
      'collector',
      body: {'action': 'download_trial', 'trial_id': trialId},
    );
    if (response.status != 200) throw StateError('Download unavailable');
    final url = stringField(asJson(response.data), 'download_url');
    final uri = Uri.parse(url);
    if (uri.scheme != 'https' ||
        !uri.host.endsWith('.r2.cloudflarestorage.com') ||
        uri.userInfo.isNotEmpty)
      throw StateError('Untrusted download URL');
    return url;
  }
}

class DatasetExportScreen extends StatefulWidget {
  final Study study;
  final DashboardRepository repository;
  final RawDownloadRepository downloads;
  final void Function(String, String) save;
  final void Function(Uint8List, String) saveBundle;
  final ExportSource? source;
  const DatasetExportScreen({
    super.key,
    required this.study,
    required this.repository,
    required this.downloads,
    this.save = saveMetadata,
    this.saveBundle = saveArchive,
    this.source,
  });
  @override
  State<DatasetExportScreen> createState() => _DatasetExportScreenState();
}

class _DatasetExportScreenState extends State<DatasetExportScreen> {
  ExportPlan? plan;
  bool loading = true, busy = false;
  String? message, error;
  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    if (busy) return;
    setState(() {
      loading = true;
      error = null;
      plan = null;
      message = null;
    });
    try {
      final result = ExportPlan(await widget.repository.load(widget.study.id));
      // Validate the full manifest before presenting any downloads.
      result.entries;
      if (mounted) setState(() => plan = result);
    } catch (_) {
      if (mounted)
        setState(
          () => error = 'Files could not be loaded. Check your study access and connection, then refresh.',
        );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void saveJson(bool streaming) {
    try {
      final current = plan!;
      widget.save(
        streaming ? current.streamingPlan : current.metadata,
        'study-${widget.study.id}-${streaming ? "download-plan" : "metadata"}.json',
      );
      setState(
        () => message = streaming
            ? 'Download plan saved. Run scripts/download_dataset.py with this plan; see docs/export.md.'
            : 'Metadata exported from the displayed snapshot.',
      );
    } catch (_) {
      setState(() => message = 'Export could not be saved. Please retry.');
    }
  }

  Future<void> download(List<ExportEntry> entries, String name) async {
    if (busy || loading) return;
    final current = plan!;
    setState(() {
      busy = true;
      message = 'Downloading and verifying ${entries.length} files…';
    });
    try {
      final result = await buildBundle(
        current,
        entries,
        widget.source ?? AuthorizedExportSource(widget.downloads.authorize),
      );
      if (!mounted) return;
      widget.saveBundle(
        result.bytes,
        '$name${result.failed.isEmpty ? "" : "-PARTIAL"}.zip',
      );
      setState(
        () => message = result.failed.isEmpty
            ? '${result.saved} verified files prepared for download. Extract the ZIP to create the readable folders.'
            : 'PARTIAL export: ${result.saved} files saved, ${result.failed.length} failed. See export-report.json in the ZIP and retry this part.',
      );
    } catch (_) {
      if (mounted)
        setState(
          () => message = 'Archive failed. No complete export was produced. Retry or use the streaming download plan.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = plan;
    final parts = current?.parts ?? [];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '${widget.study.name} · Dataset export',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const Text(
          'Only server-received data is shown. Raw files become downloadable after remote verification. Refresh creates a new snapshot.',
        ),
        TextButton(
          onPressed: loading || busy ? null : load,
          child: const Text('Refresh files'),
        ),
        if (loading || busy) const LinearProgressIndicator(),
        if (error != null) Text(error!),
        if (message != null) Text(message!),
        if (current != null) ...[
          FilledButton(
            onPressed: busy ? null : () => saveJson(false),
            child: const Text('Export metadata JSON'),
          ),
          TextButton(
            onPressed: busy ? null : () => saveJson(true),
            child: const Text('Save streaming download plan'),
          ),
          Text('${current.entries.length} verified raw files'),
          if (current.snapshot.files.isEmpty)
            const Text('No files received yet.'),
          const Text(
            'ZIP parts contain original gzip files, the displayed metadata snapshot, a path manifest and an export report. Each part is limited to 32 MiB of raw files and 200 files. Download every part for the complete verified selection. Files larger than 32 MiB require the streaming tool. Links are authorized on demand and expire after 15 minutes.',
          ),
          if (current.entries.any((e) => e.file.sizeBytes > maxArchiveBytes))
            const Text(
              'Some files exceed the browser limit. Use the streaming download plan to include them.',
            ),
          for (var i = 0; i < parts.length; i++)
            TextButton(
              onPressed: busy
                  ? null
                  : () => download(parts[i], 'dataset-part-${i + 1}'),
              child: Text(
                'Download ZIP part ${i + 1} of ${parts.length} (${parts[i].length} files)',
              ),
            ),
          for (final file in current.snapshot.files)
            Builder(
              builder: (context) {
                final trial = current.snapshot.trials.firstWhere(
                  (t) => t.id == file.trialId,
                );
                final entry = current.entries
                    .where((e) => e.file.id == file.id)
                    .firstOrNull;
                return ExpansionTile(
                  title: Text(
                    '${current.snapshot.names.participant(trial.participantId).displayLabel} · ${current.snapshot.names.trialLabel(trial)}',
                  ),
                  subtitle: Text(
                    '${current.snapshot.names.sessionLabel(current.snapshot.names.session(trial))} · ${file.syncStatus.name} · ${file.sizeBytes} bytes',
                  ),
                  trailing: IconButton(
                    tooltip: 'Download verified raw file',
                    onPressed:
                        busy ||
                            entry == null ||
                            file.sizeBytes > maxArchiveBytes
                        ? null
                        : () => download([entry], 'recording-${trial.id}'),
                    icon: const Icon(Icons.download),
                  ),
                  children: [
                    SelectableText(
                      'Trial UUID ${trial.id}\nDevice UUID ${trial.physicalDeviceId}\nProtocol version UUID ${trial.protocolVersionId}\nR2 ${file.objectKey}\nSHA-256 ${file.sha256}',
                    ),
                    if (entry != null)
                      SelectableText('Path inside ZIP: ${entry.path}'),
                  ],
                );
              },
            ),
        ],
      ],
    );
  }
}
