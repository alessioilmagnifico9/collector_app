import 'dart:async';

import 'package:experiment_models/experiment_models.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ParticipantRepository {
  Future<List<Json>> publishedProtocols(String studyId);
  Future<List<Participant>> list(String studyId);
  Future<Json> enrollmentFor(String participantId);
  Future<Json> create(String studyId, String protocolId, Sex sex, Hand hand);
}

final class SupabaseParticipantRepository implements ParticipantRepository {
  final SupabaseClient client;
  SupabaseParticipantRepository(this.client);
  @override
  Future<List<Json>> publishedProtocols(String studyId) async => await client
      .from('protocols')
      .select('id,name')
      .eq('study_id', studyId)
      .not('active_version_id', 'is', null)
      .order('name');
  @override
  Future<List<Participant>> list(String studyId) async =>
      (await client
              .from('participants')
              .select()
              .eq('study_id', studyId)
              .order('created_at'))
          .map((row) => Participant.fromJson(row))
          .toList();
  @override
  Future<Json> enrollmentFor(String participantId) async {
    final result = await client.functions.invoke(
      'collector',
      body: {'action': 'retrieve_enrollment', 'participant_id': participantId},
    );
    if (result.status != 200) throw StateError('Enrollment retrieval failed.');
    return asJson(result.data);
  }

  @override
  Future<Json> create(
    String studyId,
    String protocolId,
    Sex sex,
    Hand hand,
  ) async {
    final result = await client.functions.invoke(
      'collector',
      body: {
        'action': 'create_participant',
        'study_id': studyId,
        'protocol_id': protocolId,
        'sex': wireName(sex),
        'dominant_hand': wireName(hand),
      },
    );
    if (result.status != 200) throw StateError('Participant creation failed.');
    return asJson(result.data);
  }
}

class ParticipantManager extends StatefulWidget {
  final Study study;
  final ParticipantRepository repository;
  const ParticipantManager({
    super.key,
    required this.study,
    required this.repository,
  });
  @override
  State<ParticipantManager> createState() => _ParticipantManagerState();
}

class _ParticipantManagerState extends State<ParticipantManager> {
  List<Participant> participants = [];
  List<Json> protocols = [];
  String? protocolId, error;
  Sex sex = Sex.notReported;
  Hand hand = Hand.right;
  bool busy = true;
  Json? enrollment;
  @override
  void initState() {
    super.initState();
    unawaited(refresh());
  }

  Future<void> refresh() async {
    try {
      final loaded = await widget.repository.list(widget.study.id);
      final versions = await widget.repository.publishedProtocols(
        widget.study.id,
      );
      if (mounted)
        setState(() {
          participants = loaded;
          protocols = versions;
          protocolId ??= versions.isEmpty
              ? null
              : stringField(versions.first, 'id');
        });
    } catch (_) {
      if (mounted) setState(() => error = 'Participants could not be loaded.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> create() async {
    if (busy || protocolId == null) return;
    setState(() {
      busy = true;
      error = null;
      enrollment = null;
    });
    try {
      final result = await widget.repository.create(
        widget.study.id,
        protocolId!,
        sex,
        hand,
      );
      if (mounted) setState(() => enrollment = result);
      await refresh();
    } catch (_) {
      if (mounted)
        setState(() {
          busy = false;
          error = 'Participant creation failed. Check your study permissions and connection.';
        });
    }
  }

  Future<void> showEnrollment(Participant person) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
      enrollment = null;
    });
    try {
      final result = await widget.repository.enrollmentFor(person.id);
      if (!mounted) return;
      setState(() => busy = false);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Participant enrollment'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Keep this code private. For older participants, this replaces the original typed code; existing QR codes still work.',
                ),
                SelectableText(stringField(result, 'code')),
                SizedBox(
                  width: 220,
                  height: 220,
                  child: QrImageView(
                    data: stringField(result, 'qr_payload'),
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (mounted)
        setState(
          () => error = 'Enrollment code could not be loaded. Check your permissions and connection.',
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(
        '${participants.length} participants',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      if (busy) const LinearProgressIndicator(),
      if (error != null) Text(error!),
      if (protocols.isEmpty && !busy)
        const Text('Publish a protocol before enrolling participants.'),
      DropdownButtonFormField<String>(
        initialValue: protocolId,
        decoration: const InputDecoration(labelText: 'Protocol'),
        items: [
          for (final protocol in protocols)
            DropdownMenuItem(
              value: stringField(protocol, 'id'),
              child: Text(stringField(protocol, 'name')),
            ),
        ],
        onChanged: busy ? null : (v) => setState(() => protocolId = v),
      ),
      DropdownButtonFormField<Sex>(
        initialValue: sex,
        decoration: const InputDecoration(labelText: 'Sex'),
        items: [
          for (final value in Sex.values)
            DropdownMenuItem(
              value: value,
              child: Text(
                value == Sex.notReported ? 'Not reported' : value.name,
              ),
            ),
        ],
        onChanged: busy ? null : (v) => setState(() => sex = v!),
      ),
      DropdownButtonFormField<Hand>(
        initialValue: hand,
        decoration: const InputDecoration(labelText: 'Dominant hand'),
        items: [
          for (final value in [Hand.left, Hand.right, Hand.either])
            DropdownMenuItem(value: value, child: Text(value.name)),
        ],
        onChanged: busy ? null : (v) => setState(() => hand = v!),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: busy || protocolId == null ? null : create,
        child: const Text('Create participant and enrollment code'),
      ),
      if (enrollment != null) ...[
        const SizedBox(height: 16),
        const Text(
          'Give this code to the participant. You can reopen it from the participant list; keep it private.',
        ),
        SelectableText(
          stringField(enrollment!, 'code'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Center(
          child: QrImageView(
            data: stringField(enrollment!, 'qr_payload'),
            size: 220,
            backgroundColor: Colors.white,
          ),
        ),
      ],
      for (final person in participants)
        ListTile(
          title: Text(person.displayLabel),
          trailing: TextButton(
            onPressed: busy ? null : () => showEnrollment(person),
            child: const Text('Show code / QR'),
          ),
          subtitle: Text(
            '${person.sex.name} · ${person.dominantHand.name} hand · UUID ${person.id}',
          ),
        ),
    ],
  );
}
