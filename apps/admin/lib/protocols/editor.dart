import 'dart:convert';

import 'package:experiment_models/experiment_models.dart';
import 'package:flutter/material.dart';
import 'package:protocol_engine/protocol_engine.dart';

import 'repository.dart';

Json newTask() => {
  'id': newUuid(),
  'prompt': 'Describe the movement',
  'repetitions': 1,
  'practice_repetitions': 0,
  'posture': 'seated',
  'hand': 'dominant',
  'device_role': 'personal',
  'task_type': 'genuine',
  'preparation': null,
  'duration_seconds': null,
};
Json newSession() => {
  'id': newUuid(),
  'title': 'New session',
  'instructions': null,
  'tasks': [newTask()],
};
Json newProtocolDocument() => {
  'schema_version': 1,
  'requested_hz': 100,
  'sessions': [newSession()],
  'order_metadata': <String, Object?>{},
};

class ProtocolEditor extends StatefulWidget {
  final ProtocolVersion version;
  final ProtocolRepository repository;
  final ValueChanged<ProtocolVersion> onSaved;
  const ProtocolEditor({
    super.key,
    required this.version,
    required this.repository,
    required this.onSaved,
  });
  @override
  State<ProtocolEditor> createState() => _ProtocolEditorState();
}

class _ProtocolEditorState extends State<ProtocolEditor> {
  late Json document;
  late ProtocolVersion base;
  bool busy = false;
  List<String> errors = [];
  bool get editable => base.status == ProtocolStatus.draft && !busy;
  List<Object?> get sessions => document['sessions'] as List<Object?>;
  @override
  void initState() {
    super.initState();
    base = widget.version;
    document = asJson(jsonDecode(jsonEncode(base.document)));
  }

  void change(Json target, String key, Object? value) {
    target[key] = value;
  }

  Widget field(
    Json target,
    String key,
    String label, {
    bool numeric = false,
    bool optional = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextFormField(
      key: ValueKey('${target['id'] ?? 'protocol'}:$key'),
      initialValue: target[key]?.toString() ?? '',
      enabled: editable,
      decoration: InputDecoration(labelText: label),
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      onChanged: (value) => change(
        target,
        key,
        value.trim().isEmpty && optional
            ? null
            : numeric
            ? num.tryParse(value) ?? value
            : value,
      ),
    ),
  );
  Widget choice(Json target, String key, String label, List<String> values) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: DropdownButtonFormField<String>(
          key: ValueKey('${target['id']}:$key'),
          initialValue: target[key] as String?,
          decoration: InputDecoration(labelText: label),
          items: [
            for (final value in values)
              DropdownMenuItem(
                value: value,
                child: Text(value.replaceAll('_', ' ')),
              ),
          ],
          onChanged: editable ? (value) => change(target, key, value) : null,
        ),
      );
  void move(List<Object?> values, int index, int direction) {
    setState(() {
      final value = values.removeAt(index);
      values.insert(index + direction, value);
    });
  }

  Future<void> save({bool publish = false}) async {
    if (!editable) return;
    final problems = validateProtocol(document);
    if (publish && problems.isNotEmpty) {
      setState(() => errors = problems);
      return;
    }
    setState(() {
      busy = true;
      errors = [];
    });
    try {
      final result = await widget.repository.save(
        base,
        document,
        publish: publish,
      );
      if (mounted) {
        setState(() => base = result);
        widget.onSaved(result);
      }
    } catch (_) {
      if (mounted)
        setState(
          () => errors = [
            'The draft could not be saved. It may have changed in another editor, or your permissions/connection may have changed. Reload the version before retrying.',
          ],
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> preview() async {
    final problems = validateProtocol(document);
    if (problems.isNotEmpty) {
      setState(() => errors = problems);
      return;
    }
    final definition = ProtocolDefinition.fromJson(document);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Participant preview'),
        content: SizedBox(
          width: 560,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final session in definition.sessions) ...[
                Text(
                  session.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (session.instructions != null) Text(session.instructions!),
                for (final plan in generateTrialQueue(session))
                  ListTile(
                    title: Text(plan.task.prompt),
                    subtitle: Text(
                      '${plan.taskType.name} ${plan.repetition} · ${plan.task.hand.name} hand · ${plan.task.posture.name} · ${wireName(plan.task.deviceRole)}${plan.task.preparation == null ? '' : '\n${plan.task.preparation}'}',
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close preview'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Version ${base.version} · ${base.status.name}',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      if (!editable && !busy)
        const Text(
          'Published versions are immutable. Create a new draft to make changes.',
        ),
      for (final error in errors)
        Text(
          error,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      field(
        document,
        'requested_hz',
        'Requested sampling rate (Hz)',
        numeric: true,
      ),
      for (var s = 0; s < sessions.length; s++)
        sessionForm(asJson(sessions[s]), s),
      if (editable)
        OutlinedButton(
          onPressed: () => setState(() => sessions.add(newSession())),
          child: const Text('Add session'),
        ),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: busy
                ? null
                : () => setState(
                    () => errors = validateProtocol(document).isEmpty
                        ? ['Protocol is valid.']
                        : validateProtocol(document),
                  ),
            child: const Text('Validate'),
          ),
          OutlinedButton(
            onPressed: busy ? null : preview,
            child: const Text('Preview participant flow'),
          ),
          if (base.status == ProtocolStatus.draft) ...[
            FilledButton(
              onPressed: busy ? null : () => save(),
              child: const Text('Save draft'),
            ),
            FilledButton(
              onPressed: busy ? null : () => save(publish: true),
              child: const Text('Publish version'),
            ),
          ],
        ],
      ),
    ],
  );
  Widget sessionForm(Json session, int index) {
    final tasks = session['tasks'] as List<Object?>;
    return Card(
      key: ValueKey(session['id']),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Session ${index + 1}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            field(session, 'title', 'Session title'),
            field(
              session,
              'instructions',
              'Session instructions (optional)',
              optional: true,
            ),
            if (editable)
              Wrap(
                children: [
                  if (index > 0)
                    TextButton(
                      onPressed: () => move(sessions, index, -1),
                      child: const Text('Move session up'),
                    ),
                  if (index + 1 < sessions.length)
                    TextButton(
                      onPressed: () => move(sessions, index, 1),
                      child: const Text('Move session down'),
                    ),
                  TextButton(
                    onPressed: () => setState(() => sessions.removeAt(index)),
                    child: const Text('Remove session'),
                  ),
                ],
              ),
            for (var t = 0; t < tasks.length; t++)
              taskForm(asJson(tasks[t]), tasks, t),
            if (editable)
              OutlinedButton(
                onPressed: () => setState(() => tasks.add(newTask())),
                child: const Text('Add task'),
              ),
          ],
        ),
      ),
    );
  }

  Widget taskForm(Json task, List<Object?> tasks, int index) => ExpansionTile(
    key: ValueKey(task['id']),
    initiallyExpanded: true,
    title: Text('Task ${index + 1}'),
    childrenPadding: const EdgeInsets.all(8),
    children: [
      SelectableText('Task ID: ${task['id']}'),
      field(task, 'prompt', 'Participant prompt'),
      field(task, 'preparation', 'Preparation (optional)', optional: true),
      field(task, 'repetitions', 'Repetitions', numeric: true),
      field(
        task,
        'practice_repetitions',
        'Practice repetitions',
        numeric: true,
      ),
      field(
        task,
        'duration_seconds',
        'Automatic stop in seconds (blank for manual)',
        numeric: true,
        optional: true,
      ),
      choice(task, 'posture', 'Posture', Posture.values.map(wireName).toList()),
      choice(task, 'hand', 'Required hand', Hand.values.map(wireName).toList()),
      choice(
        task,
        'device_role',
        'Phone',
        DeviceRole.values.map(wireName).toList(),
      ),
      choice(
        task,
        'task_type',
        'Task type',
        TaskType.values.map(wireName).toList(),
      ),
      if (editable)
        Wrap(
          children: [
            if (index > 0)
              TextButton(
                onPressed: () => move(tasks, index, -1),
                child: const Text('Move task up'),
              ),
            if (index + 1 < tasks.length)
              TextButton(
                onPressed: () => move(tasks, index, 1),
                child: const Text('Move task down'),
              ),
            TextButton(
              onPressed: () => setState(() {
                final copy = asJson(jsonDecode(jsonEncode(task)));
                copy['id'] = newUuid();
                tasks.insert(index + 1, copy);
              }),
              child: const Text('Duplicate task'),
            ),
            TextButton(
              onPressed: () => setState(() => tasks.removeAt(index)),
              child: const Text('Remove task'),
            ),
          ],
        ),
    ],
  );
}
