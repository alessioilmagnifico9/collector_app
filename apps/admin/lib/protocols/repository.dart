import 'package:experiment_models/experiment_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ProtocolRepository {
  Future<List<Protocol>> protocols(String studyId);
  Future<List<ProtocolVersion>> versions(String protocolId);
  Future<ProtocolVersion> create(
    String studyId,
    String name,
    Json document, {
    String? sourceId,
  });
  Future<ProtocolVersion> save(
    ProtocolVersion expected,
    Json document, {
    bool publish = false,
  });
}

final class SupabaseProtocolRepository implements ProtocolRepository {
  final SupabaseClient client;
  SupabaseProtocolRepository(this.client);
  @override
  Future<List<Protocol>> protocols(String studyId) async =>
      (await client
              .from('protocols')
              .select()
              .eq('study_id', studyId)
              .order('created_at'))
          .map((v) => Protocol.fromJson(v))
          .toList();
  @override
  Future<List<ProtocolVersion>> versions(String protocolId) async =>
      (await client
              .from('protocol_versions')
              .select()
              .eq('protocol_id', protocolId)
              .order('version', ascending: false))
          .map((v) => ProtocolVersion.fromJson(v))
          .toList();
  @override
  Future<ProtocolVersion> create(
    String studyId,
    String name,
    Json document, {
    String? sourceId,
  }) async => ProtocolVersion.fromJson(
    asJson(
      await client.rpc<Object?>(
        'create_protocol_draft',
        params: {
          'study_uuid': studyId,
          'protocol_name': name,
          'document': document,
          'source_uuid': sourceId,
        },
      ),
    ),
  );
  @override
  Future<ProtocolVersion> save(
    ProtocolVersion expected,
    Json document, {
    bool publish = false,
  }) async => ProtocolVersion.fromJson(
    asJson(
      await client.rpc<Object?>(
        'save_protocol_draft',
        params: {
          'version_uuid': expected.id,
          'expected_document': expected.document,
          'document': document,
          'publish': publish,
        },
      ),
    ),
  );
}
