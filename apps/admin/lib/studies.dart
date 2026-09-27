import 'dart:async';

import 'package:experiment_models/experiment_models.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class StudyRepository {
  Future<List<Study>> list();
  Future<void> create(String name);
}

final class SupabaseStudyRepository implements StudyRepository {
  final SupabaseClient client;
  SupabaseStudyRepository(this.client);
  @override
  Future<List<Study>> list() async =>
      (await client.from('studies').select().order('created_at'))
          .map((row) => Study.fromJson(row))
          .toList();
  @override
  Future<void> create(String name) async {
    await client.rpc<String>(
      'create_study',
      params: {'study_name': name.trim()},
    );
  }
}

class StudyList extends StatefulWidget {
  final StudyRepository repository;
  final void Function(Study)? onOpen;
  const StudyList({super.key, required this.repository, this.onOpen});
  @override
  State<StudyList> createState() => _StudyListState();
}

class _StudyListState extends State<StudyList> {
  final name = TextEditingController();
  List<Study> studies = [];
  bool busy = true;
  String? error;
  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> load() async {
    try {
      final rows = await widget.repository.list();
      if (mounted) setState(() => studies = rows);
    } catch (_) {
      if (mounted)
        setState(() => error = 'Studies could not be loaded. Please retry.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> create() async {
    if (busy || name.text.trim().isEmpty) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repository.create(name.text);
      name.clear();
      await load();
    } catch (_) {
      if (mounted)
        setState(() {
          error = 'The study could not be created.';
          busy = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text('Studies', style: Theme.of(context).textTheme.headlineMedium),
      if (error != null) Text(error!),
      if (busy) const LinearProgressIndicator(),
      for (final study in studies)
        Card(
          child: ListTile(
            title: Text(study.name),
            onTap: widget.onOpen == null ? null : () => widget.onOpen!(study),
          ),
        ),
      TextField(
        controller: name,
        decoration: const InputDecoration(labelText: 'New study name'),
        maxLength: 200,
      ),
      FilledButton(
        onPressed: busy ? null : create,
        child: const Text('Create study'),
      ),
      TextButton(onPressed: busy ? null : load, child: const Text('Refresh')),
    ],
  );
}
