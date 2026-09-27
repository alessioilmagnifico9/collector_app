import 'dart:async';

import 'package:experiment_models/experiment_models.dart';
import 'package:flutter/material.dart';

import 'editor.dart';
import 'repository.dart';

class ProtocolManager extends StatefulWidget {
  final Study study;
  final ProtocolRepository repository;
  const ProtocolManager({
    super.key,
    required this.study,
    required this.repository,
  });
  @override
  State<ProtocolManager> createState() => _ProtocolManagerState();
}

class _ProtocolManagerState extends State<ProtocolManager> {
  final name = TextEditingController();
  List<Protocol> protocols = [];
  List<ProtocolVersion> versions = [];
  Protocol? selected;
  ProtocolVersion? editing;
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
      final rows = await widget.repository.protocols(widget.study.id);
      if (mounted) setState(() => protocols = rows);
    } catch (_) {
      if (mounted) setState(() => error = 'Protocols could not be loaded.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> open(Protocol protocol) async {
    setState(() {
      busy = true;
      error = null;
      editing = null;
    });
    try {
      final rows = await widget.repository.versions(protocol.id);
      if (mounted)
        setState(() {
          selected = protocol;
          versions = rows;
        });
    } catch (_) {
      if (mounted)
        setState(() => error = 'Version history could not be loaded.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> create({ProtocolVersion? source}) async {
    if (busy || source == null && name.text.trim().isEmpty) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final version = await widget.repository.create(
        widget.study.id,
        source == null ? name.text.trim() : selected!.name,
        source?.document ?? newProtocolDocument(),
        sourceId: source?.id,
      );
      await load();
      final protocol = protocols.firstWhere((p) => p.id == version.protocolId);
      await open(protocol);
      if (mounted) setState(() => editing = version);
    } catch (_) {
      if (mounted)
        setState(() {
          busy = false;
          error =
              'Draft creation failed. Check your permissions and connection.';
        });
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text('Protocols', style: Theme.of(context).textTheme.headlineMedium),
      if (busy) const LinearProgressIndicator(),
      if (error != null) Text(error!),
      for (final protocol in protocols)
        ListTile(
          title: Text(protocol.name),
          selected: selected?.id == protocol.id,
          onTap: busy ? null : () => open(protocol),
        ),
      TextField(
        controller: name,
        decoration: const InputDecoration(labelText: 'New protocol name'),
        maxLength: 200,
      ),
      FilledButton(
        onPressed: busy ? null : () => create(),
        child: const Text('Create protocol draft'),
      ),
      for (final version in versions)
        ListTile(
          title: Text('Version ${version.version} · ${version.status.name}'),
          subtitle: Text(version.createdAt.toLocal().toString()),
          onTap: busy ? null : () => setState(() => editing = version),
          trailing: TextButton(
            onPressed: busy ? null : () => create(source: version),
            child: const Text('New draft from this version'),
          ),
        ),
      if (editing != null)
        ProtocolEditor(
          key: ValueKey(editing!.id),
          version: editing!,
          repository: widget.repository,
          onSaved: (version) => setState(() {
            editing = version;
            versions = [
              for (final old in versions)
                if (old.id == version.id) version else old,
            ];
          }),
        ),
    ],
  );
}
