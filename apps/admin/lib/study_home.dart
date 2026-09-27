import 'package:experiment_models/experiment_models.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'participants.dart';
import 'dashboard/dashboard.dart';
import 'dashboard/repository.dart';
import 'export/export_screen.dart';
import 'studies.dart';
import 'protocols/manager.dart';
import 'protocols/repository.dart';

/// Lives inside the auth gate so expiry/sign-out disposes sensitive study screens.
class StudyHome extends StatefulWidget {
  final StudyRepository repository;
  final SupabaseClient? client;
  const StudyHome({super.key, required this.repository, this.client});
  @override
  State<StudyHome> createState() => _StudyHomeState();
}

class _StudyHomeState extends State<StudyHome> {
  Study? selected;
  @override
  Widget build(BuildContext context) {
    final study = selected;
    if (study == null)
      return StudyList(
        repository: widget.repository,
        onOpen: widget.client == null
            ? null
            : (value) => setState(() => selected = value),
      );
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          ListTile(
            leading: IconButton(
              onPressed: () => setState(() => selected = null),
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to studies',
            ),
            title: Text(study.name),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Progress'),
              Tab(text: 'Protocols'),
              Tab(text: 'Participants'),
              Tab(text: 'Export'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ResearchDashboard(
                  study: study,
                  repository: SupabaseDashboardRepository(widget.client!),
                ),
                ProtocolManager(
                  study: study,
                  repository: SupabaseProtocolRepository(widget.client!),
                ),
                ParticipantManager(
                  study: study,
                  repository: SupabaseParticipantRepository(widget.client!),
                ),
                DatasetExportScreen(
                  study: study,
                  repository: SupabaseDashboardRepository(widget.client!),
                  downloads: SupabaseRawDownloadRepository(widget.client!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
