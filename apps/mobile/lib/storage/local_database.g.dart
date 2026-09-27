// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $CachedParticipantsTable extends CachedParticipants
    with TableInfo<$CachedParticipantsTable, CachedParticipant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedParticipantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_participants';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedParticipant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedParticipant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedParticipant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $CachedParticipantsTable createAlias(String alias) {
    return $CachedParticipantsTable(attachedDatabase, alias);
  }
}

class CachedParticipant extends DataClass
    implements Insertable<CachedParticipant> {
  final String id;
  final String payload;
  const CachedParticipant({required this.id, required this.payload});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  CachedParticipantsCompanion toCompanion(bool nullToAbsent) {
    return CachedParticipantsCompanion(id: Value(id), payload: Value(payload));
  }

  factory CachedParticipant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedParticipant(
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
    };
  }

  CachedParticipant copyWith({String? id, String? payload}) =>
      CachedParticipant(id: id ?? this.id, payload: payload ?? this.payload);
  CachedParticipant copyWithCompanion(CachedParticipantsCompanion data) {
    return CachedParticipant(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedParticipant(')
          ..write('id: $id, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedParticipant &&
          other.id == this.id &&
          other.payload == this.payload);
}

class CachedParticipantsCompanion extends UpdateCompanion<CachedParticipant> {
  final Value<String> id;
  final Value<String> payload;
  final Value<int> rowid;
  const CachedParticipantsCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedParticipantsCompanion.insert({
    required String id,
    required String payload,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload);
  static Insertable<CachedParticipant> custom({
    Expression<String>? id,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedParticipantsCompanion copyWith({
    Value<String>? id,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return CachedParticipantsCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedParticipantsCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedProtocolsTable extends CachedProtocols
    with TableInfo<$CachedProtocolsTable, CachedProtocol> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedProtocolsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_protocols';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedProtocol> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedProtocol map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedProtocol(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $CachedProtocolsTable createAlias(String alias) {
    return $CachedProtocolsTable(attachedDatabase, alias);
  }
}

class CachedProtocol extends DataClass implements Insertable<CachedProtocol> {
  final String id;
  final String payload;
  const CachedProtocol({required this.id, required this.payload});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  CachedProtocolsCompanion toCompanion(bool nullToAbsent) {
    return CachedProtocolsCompanion(id: Value(id), payload: Value(payload));
  }

  factory CachedProtocol.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedProtocol(
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
    };
  }

  CachedProtocol copyWith({String? id, String? payload}) =>
      CachedProtocol(id: id ?? this.id, payload: payload ?? this.payload);
  CachedProtocol copyWithCompanion(CachedProtocolsCompanion data) {
    return CachedProtocol(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedProtocol(')
          ..write('id: $id, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedProtocol &&
          other.id == this.id &&
          other.payload == this.payload);
}

class CachedProtocolsCompanion extends UpdateCompanion<CachedProtocol> {
  final Value<String> id;
  final Value<String> payload;
  final Value<int> rowid;
  const CachedProtocolsCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedProtocolsCompanion.insert({
    required String id,
    required String payload,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload);
  static Insertable<CachedProtocol> custom({
    Expression<String>? id,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedProtocolsCompanion copyWith({
    Value<String>? id,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return CachedProtocolsCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedProtocolsCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredSessionsTable extends StoredSessions
    with TableInfo<$StoredSessionsTable, StoredSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _participantIdMeta = const VerificationMeta(
    'participantId',
  );
  @override
  late final GeneratedColumn<String> participantId = GeneratedColumn<String>(
    'participant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cached_participants (id)',
    ),
  );
  static const VerificationMeta _protocolVersionIdMeta = const VerificationMeta(
    'protocolVersionId',
  );
  @override
  late final GeneratedColumn<String> protocolVersionId =
      GeneratedColumn<String>(
        'protocol_version_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES cached_protocols (id)',
        ),
      );
  static const VerificationMeta _snapshotMeta = const VerificationMeta(
    'snapshot',
  );
  @override
  late final GeneratedColumn<String> snapshot = GeneratedColumn<String>(
    'snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nextIndexMeta = const VerificationMeta(
    'nextIndex',
  );
  @override
  late final GeneratedColumn<int> nextIndex = GeneratedColumn<int>(
    'next_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    participantId,
    protocolVersionId,
    snapshot,
    nextIndex,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('participant_id')) {
      context.handle(
        _participantIdMeta,
        participantId.isAcceptableOrUnknown(
          data['participant_id']!,
          _participantIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_participantIdMeta);
    }
    if (data.containsKey('protocol_version_id')) {
      context.handle(
        _protocolVersionIdMeta,
        protocolVersionId.isAcceptableOrUnknown(
          data['protocol_version_id']!,
          _protocolVersionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_protocolVersionIdMeta);
    }
    if (data.containsKey('snapshot')) {
      context.handle(
        _snapshotMeta,
        snapshot.isAcceptableOrUnknown(data['snapshot']!, _snapshotMeta),
      );
    } else if (isInserting) {
      context.missing(_snapshotMeta);
    }
    if (data.containsKey('next_index')) {
      context.handle(
        _nextIndexMeta,
        nextIndex.isAcceptableOrUnknown(data['next_index']!, _nextIndexMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      participantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participant_id'],
      )!,
      protocolVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}protocol_version_id'],
      )!,
      snapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot'],
      )!,
      nextIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_index'],
      )!,
    );
  }

  @override
  $StoredSessionsTable createAlias(String alias) {
    return $StoredSessionsTable(attachedDatabase, alias);
  }
}

class StoredSession extends DataClass implements Insertable<StoredSession> {
  final String id;
  final String participantId;
  final String protocolVersionId;
  final String snapshot;
  final int nextIndex;
  const StoredSession({
    required this.id,
    required this.participantId,
    required this.protocolVersionId,
    required this.snapshot,
    required this.nextIndex,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['participant_id'] = Variable<String>(participantId);
    map['protocol_version_id'] = Variable<String>(protocolVersionId);
    map['snapshot'] = Variable<String>(snapshot);
    map['next_index'] = Variable<int>(nextIndex);
    return map;
  }

  StoredSessionsCompanion toCompanion(bool nullToAbsent) {
    return StoredSessionsCompanion(
      id: Value(id),
      participantId: Value(participantId),
      protocolVersionId: Value(protocolVersionId),
      snapshot: Value(snapshot),
      nextIndex: Value(nextIndex),
    );
  }

  factory StoredSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredSession(
      id: serializer.fromJson<String>(json['id']),
      participantId: serializer.fromJson<String>(json['participantId']),
      protocolVersionId: serializer.fromJson<String>(json['protocolVersionId']),
      snapshot: serializer.fromJson<String>(json['snapshot']),
      nextIndex: serializer.fromJson<int>(json['nextIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'participantId': serializer.toJson<String>(participantId),
      'protocolVersionId': serializer.toJson<String>(protocolVersionId),
      'snapshot': serializer.toJson<String>(snapshot),
      'nextIndex': serializer.toJson<int>(nextIndex),
    };
  }

  StoredSession copyWith({
    String? id,
    String? participantId,
    String? protocolVersionId,
    String? snapshot,
    int? nextIndex,
  }) => StoredSession(
    id: id ?? this.id,
    participantId: participantId ?? this.participantId,
    protocolVersionId: protocolVersionId ?? this.protocolVersionId,
    snapshot: snapshot ?? this.snapshot,
    nextIndex: nextIndex ?? this.nextIndex,
  );
  StoredSession copyWithCompanion(StoredSessionsCompanion data) {
    return StoredSession(
      id: data.id.present ? data.id.value : this.id,
      participantId: data.participantId.present
          ? data.participantId.value
          : this.participantId,
      protocolVersionId: data.protocolVersionId.present
          ? data.protocolVersionId.value
          : this.protocolVersionId,
      snapshot: data.snapshot.present ? data.snapshot.value : this.snapshot,
      nextIndex: data.nextIndex.present ? data.nextIndex.value : this.nextIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredSession(')
          ..write('id: $id, ')
          ..write('participantId: $participantId, ')
          ..write('protocolVersionId: $protocolVersionId, ')
          ..write('snapshot: $snapshot, ')
          ..write('nextIndex: $nextIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, participantId, protocolVersionId, snapshot, nextIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredSession &&
          other.id == this.id &&
          other.participantId == this.participantId &&
          other.protocolVersionId == this.protocolVersionId &&
          other.snapshot == this.snapshot &&
          other.nextIndex == this.nextIndex);
}

class StoredSessionsCompanion extends UpdateCompanion<StoredSession> {
  final Value<String> id;
  final Value<String> participantId;
  final Value<String> protocolVersionId;
  final Value<String> snapshot;
  final Value<int> nextIndex;
  final Value<int> rowid;
  const StoredSessionsCompanion({
    this.id = const Value.absent(),
    this.participantId = const Value.absent(),
    this.protocolVersionId = const Value.absent(),
    this.snapshot = const Value.absent(),
    this.nextIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredSessionsCompanion.insert({
    required String id,
    required String participantId,
    required String protocolVersionId,
    required String snapshot,
    this.nextIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       participantId = Value(participantId),
       protocolVersionId = Value(protocolVersionId),
       snapshot = Value(snapshot);
  static Insertable<StoredSession> custom({
    Expression<String>? id,
    Expression<String>? participantId,
    Expression<String>? protocolVersionId,
    Expression<String>? snapshot,
    Expression<int>? nextIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (participantId != null) 'participant_id': participantId,
      if (protocolVersionId != null) 'protocol_version_id': protocolVersionId,
      if (snapshot != null) 'snapshot': snapshot,
      if (nextIndex != null) 'next_index': nextIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredSessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? participantId,
    Value<String>? protocolVersionId,
    Value<String>? snapshot,
    Value<int>? nextIndex,
    Value<int>? rowid,
  }) {
    return StoredSessionsCompanion(
      id: id ?? this.id,
      participantId: participantId ?? this.participantId,
      protocolVersionId: protocolVersionId ?? this.protocolVersionId,
      snapshot: snapshot ?? this.snapshot,
      nextIndex: nextIndex ?? this.nextIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (participantId.present) {
      map['participant_id'] = Variable<String>(participantId.value);
    }
    if (protocolVersionId.present) {
      map['protocol_version_id'] = Variable<String>(protocolVersionId.value);
    }
    if (snapshot.present) {
      map['snapshot'] = Variable<String>(snapshot.value);
    }
    if (nextIndex.present) {
      map['next_index'] = Variable<int>(nextIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredSessionsCompanion(')
          ..write('id: $id, ')
          ..write('participantId: $participantId, ')
          ..write('protocolVersionId: $protocolVersionId, ')
          ..write('snapshot: $snapshot, ')
          ..write('nextIndex: $nextIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhysicalDevicesTable extends PhysicalDevices
    with TableInfo<$PhysicalDevicesTable, PhysicalDevice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhysicalDevicesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'physical_devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhysicalDevice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PhysicalDevice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhysicalDevice(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $PhysicalDevicesTable createAlias(String alias) {
    return $PhysicalDevicesTable(attachedDatabase, alias);
  }
}

class PhysicalDevice extends DataClass implements Insertable<PhysicalDevice> {
  final String id;
  final String payload;
  const PhysicalDevice({required this.id, required this.payload});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  PhysicalDevicesCompanion toCompanion(bool nullToAbsent) {
    return PhysicalDevicesCompanion(id: Value(id), payload: Value(payload));
  }

  factory PhysicalDevice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhysicalDevice(
      id: serializer.fromJson<String>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'payload': serializer.toJson<String>(payload),
    };
  }

  PhysicalDevice copyWith({String? id, String? payload}) =>
      PhysicalDevice(id: id ?? this.id, payload: payload ?? this.payload);
  PhysicalDevice copyWithCompanion(PhysicalDevicesCompanion data) {
    return PhysicalDevice(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhysicalDevice(')
          ..write('id: $id, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhysicalDevice &&
          other.id == this.id &&
          other.payload == this.payload);
}

class PhysicalDevicesCompanion extends UpdateCompanion<PhysicalDevice> {
  final Value<String> id;
  final Value<String> payload;
  final Value<int> rowid;
  const PhysicalDevicesCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhysicalDevicesCompanion.insert({
    required String id,
    required String payload,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       payload = Value(payload);
  static Insertable<PhysicalDevice> custom({
    Expression<String>? id,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhysicalDevicesCompanion copyWith({
    Value<String>? id,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return PhysicalDevicesCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhysicalDevicesCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredTrialsTable extends StoredTrials
    with TableInfo<$StoredTrialsTable, StoredTrial> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredTrialsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stored_sessions (id)',
    ),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES physical_devices (id)',
    ),
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _filePayloadMeta = const VerificationMeta(
    'filePayload',
  );
  @override
  late final GeneratedColumn<String> filePayload = GeneratedColumn<String>(
    'file_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawPathMeta = const VerificationMeta(
    'rawPath',
  );
  @override
  late final GeneratedColumn<String> rawPath = GeneratedColumn<String>(
    'raw_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _compressedPathMeta = const VerificationMeta(
    'compressedPath',
  );
  @override
  late final GeneratedColumn<String> compressedPath = GeneratedColumn<String>(
    'compressed_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    deviceId,
    payload,
    filePayload,
    rawPath,
    compressedPath,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_trials';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredTrial> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('file_payload')) {
      context.handle(
        _filePayloadMeta,
        filePayload.isAcceptableOrUnknown(
          data['file_payload']!,
          _filePayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_filePayloadMeta);
    }
    if (data.containsKey('raw_path')) {
      context.handle(
        _rawPathMeta,
        rawPath.isAcceptableOrUnknown(data['raw_path']!, _rawPathMeta),
      );
    } else if (isInserting) {
      context.missing(_rawPathMeta);
    }
    if (data.containsKey('compressed_path')) {
      context.handle(
        _compressedPathMeta,
        compressedPath.isAcceptableOrUnknown(
          data['compressed_path']!,
          _compressedPathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_compressedPathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredTrial map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredTrial(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      filePayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_payload'],
      )!,
      rawPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_path'],
      )!,
      compressedPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}compressed_path'],
      )!,
    );
  }

  @override
  $StoredTrialsTable createAlias(String alias) {
    return $StoredTrialsTable(attachedDatabase, alias);
  }
}

class StoredTrial extends DataClass implements Insertable<StoredTrial> {
  final String id;
  final String sessionId;
  final String deviceId;
  final String payload;
  final String filePayload;
  final String rawPath;
  final String compressedPath;
  const StoredTrial({
    required this.id,
    required this.sessionId,
    required this.deviceId,
    required this.payload,
    required this.filePayload,
    required this.rawPath,
    required this.compressedPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['session_id'] = Variable<String>(sessionId);
    map['device_id'] = Variable<String>(deviceId);
    map['payload'] = Variable<String>(payload);
    map['file_payload'] = Variable<String>(filePayload);
    map['raw_path'] = Variable<String>(rawPath);
    map['compressed_path'] = Variable<String>(compressedPath);
    return map;
  }

  StoredTrialsCompanion toCompanion(bool nullToAbsent) {
    return StoredTrialsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      deviceId: Value(deviceId),
      payload: Value(payload),
      filePayload: Value(filePayload),
      rawPath: Value(rawPath),
      compressedPath: Value(compressedPath),
    );
  }

  factory StoredTrial.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredTrial(
      id: serializer.fromJson<String>(json['id']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      payload: serializer.fromJson<String>(json['payload']),
      filePayload: serializer.fromJson<String>(json['filePayload']),
      rawPath: serializer.fromJson<String>(json['rawPath']),
      compressedPath: serializer.fromJson<String>(json['compressedPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sessionId': serializer.toJson<String>(sessionId),
      'deviceId': serializer.toJson<String>(deviceId),
      'payload': serializer.toJson<String>(payload),
      'filePayload': serializer.toJson<String>(filePayload),
      'rawPath': serializer.toJson<String>(rawPath),
      'compressedPath': serializer.toJson<String>(compressedPath),
    };
  }

  StoredTrial copyWith({
    String? id,
    String? sessionId,
    String? deviceId,
    String? payload,
    String? filePayload,
    String? rawPath,
    String? compressedPath,
  }) => StoredTrial(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    deviceId: deviceId ?? this.deviceId,
    payload: payload ?? this.payload,
    filePayload: filePayload ?? this.filePayload,
    rawPath: rawPath ?? this.rawPath,
    compressedPath: compressedPath ?? this.compressedPath,
  );
  StoredTrial copyWithCompanion(StoredTrialsCompanion data) {
    return StoredTrial(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      payload: data.payload.present ? data.payload.value : this.payload,
      filePayload: data.filePayload.present
          ? data.filePayload.value
          : this.filePayload,
      rawPath: data.rawPath.present ? data.rawPath.value : this.rawPath,
      compressedPath: data.compressedPath.present
          ? data.compressedPath.value
          : this.compressedPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredTrial(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('deviceId: $deviceId, ')
          ..write('payload: $payload, ')
          ..write('filePayload: $filePayload, ')
          ..write('rawPath: $rawPath, ')
          ..write('compressedPath: $compressedPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    deviceId,
    payload,
    filePayload,
    rawPath,
    compressedPath,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredTrial &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.deviceId == this.deviceId &&
          other.payload == this.payload &&
          other.filePayload == this.filePayload &&
          other.rawPath == this.rawPath &&
          other.compressedPath == this.compressedPath);
}

class StoredTrialsCompanion extends UpdateCompanion<StoredTrial> {
  final Value<String> id;
  final Value<String> sessionId;
  final Value<String> deviceId;
  final Value<String> payload;
  final Value<String> filePayload;
  final Value<String> rawPath;
  final Value<String> compressedPath;
  final Value<int> rowid;
  const StoredTrialsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.payload = const Value.absent(),
    this.filePayload = const Value.absent(),
    this.rawPath = const Value.absent(),
    this.compressedPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredTrialsCompanion.insert({
    required String id,
    required String sessionId,
    required String deviceId,
    required String payload,
    required String filePayload,
    required String rawPath,
    required String compressedPath,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionId = Value(sessionId),
       deviceId = Value(deviceId),
       payload = Value(payload),
       filePayload = Value(filePayload),
       rawPath = Value(rawPath),
       compressedPath = Value(compressedPath);
  static Insertable<StoredTrial> custom({
    Expression<String>? id,
    Expression<String>? sessionId,
    Expression<String>? deviceId,
    Expression<String>? payload,
    Expression<String>? filePayload,
    Expression<String>? rawPath,
    Expression<String>? compressedPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (deviceId != null) 'device_id': deviceId,
      if (payload != null) 'payload': payload,
      if (filePayload != null) 'file_payload': filePayload,
      if (rawPath != null) 'raw_path': rawPath,
      if (compressedPath != null) 'compressed_path': compressedPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredTrialsCompanion copyWith({
    Value<String>? id,
    Value<String>? sessionId,
    Value<String>? deviceId,
    Value<String>? payload,
    Value<String>? filePayload,
    Value<String>? rawPath,
    Value<String>? compressedPath,
    Value<int>? rowid,
  }) {
    return StoredTrialsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      deviceId: deviceId ?? this.deviceId,
      payload: payload ?? this.payload,
      filePayload: filePayload ?? this.filePayload,
      rawPath: rawPath ?? this.rawPath,
      compressedPath: compressedPath ?? this.compressedPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (filePayload.present) {
      map['file_payload'] = Variable<String>(filePayload.value);
    }
    if (rawPath.present) {
      map['raw_path'] = Variable<String>(rawPath.value);
    }
    if (compressedPath.present) {
      map['compressed_path'] = Variable<String>(compressedPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredTrialsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('deviceId: $deviceId, ')
          ..write('payload: $payload, ')
          ..write('filePayload: $filePayload, ')
          ..write('rawPath: $rawPath, ')
          ..write('compressedPath: $compressedPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _trialIdMeta = const VerificationMeta(
    'trialId',
  );
  @override
  late final GeneratedColumn<String> trialId = GeneratedColumn<String>(
    'trial_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stored_trials (id)',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    check: () =>
        status.isIn(['local', 'queued', 'uploading', 'synced', 'failed']),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _leaseExpiresAtMeta = const VerificationMeta(
    'leaseExpiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> leaseExpiresAt =
      GeneratedColumn<DateTime>(
        'lease_expires_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    trialId,
    status,
    attempts,
    nextAttemptAt,
    leaseExpiresAt,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('trial_id')) {
      context.handle(
        _trialIdMeta,
        trialId.isAcceptableOrUnknown(data['trial_id']!, _trialIdMeta),
      );
    } else if (isInserting) {
      context.missing(_trialIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextAttemptAtMeta);
    }
    if (data.containsKey('lease_expires_at')) {
      context.handle(
        _leaseExpiresAtMeta,
        leaseExpiresAt.isAcceptableOrUnknown(
          data['lease_expires_at']!,
          _leaseExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {trialId};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      trialId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trial_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      leaseExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}lease_expires_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final String trialId;
  final String status;
  final int attempts;
  final DateTime nextAttemptAt;
  final DateTime? leaseExpiresAt;
  final String? lastError;
  const SyncQueueData({
    required this.trialId,
    required this.status,
    required this.attempts,
    required this.nextAttemptAt,
    this.leaseExpiresAt,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trial_id'] = Variable<String>(trialId);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    if (!nullToAbsent || leaseExpiresAt != null) {
      map['lease_expires_at'] = Variable<DateTime>(leaseExpiresAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      trialId: Value(trialId),
      status: Value(status),
      attempts: Value(attempts),
      nextAttemptAt: Value(nextAttemptAt),
      leaseExpiresAt: leaseExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(leaseExpiresAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      trialId: serializer.fromJson<String>(json['trialId']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime>(json['nextAttemptAt']),
      leaseExpiresAt: serializer.fromJson<DateTime?>(json['leaseExpiresAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'trialId': serializer.toJson<String>(trialId),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime>(nextAttemptAt),
      'leaseExpiresAt': serializer.toJson<DateTime?>(leaseExpiresAt),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncQueueData copyWith({
    String? trialId,
    String? status,
    int? attempts,
    DateTime? nextAttemptAt,
    Value<DateTime?> leaseExpiresAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
  }) => SyncQueueData(
    trialId: trialId ?? this.trialId,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    leaseExpiresAt: leaseExpiresAt.present
        ? leaseExpiresAt.value
        : this.leaseExpiresAt,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      trialId: data.trialId.present ? data.trialId.value : this.trialId,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      leaseExpiresAt: data.leaseExpiresAt.present
          ? data.leaseExpiresAt.value
          : this.leaseExpiresAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('trialId: $trialId, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('leaseExpiresAt: $leaseExpiresAt, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    trialId,
    status,
    attempts,
    nextAttemptAt,
    leaseExpiresAt,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.trialId == this.trialId &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.leaseExpiresAt == this.leaseExpiresAt &&
          other.lastError == this.lastError);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<String> trialId;
  final Value<String> status;
  final Value<int> attempts;
  final Value<DateTime> nextAttemptAt;
  final Value<DateTime?> leaseExpiresAt;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.trialId = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.leaseExpiresAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String trialId,
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    required DateTime nextAttemptAt,
    this.leaseExpiresAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : trialId = Value(trialId),
       nextAttemptAt = Value(nextAttemptAt);
  static Insertable<SyncQueueData> custom({
    Expression<String>? trialId,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAt,
    Expression<DateTime>? leaseExpiresAt,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (trialId != null) 'trial_id': trialId,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (leaseExpiresAt != null) 'lease_expires_at': leaseExpiresAt,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith({
    Value<String>? trialId,
    Value<String>? status,
    Value<int>? attempts,
    Value<DateTime>? nextAttemptAt,
    Value<DateTime?>? leaseExpiresAt,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return SyncQueueCompanion(
      trialId: trialId ?? this.trialId,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      leaseExpiresAt: leaseExpiresAt ?? this.leaseExpiresAt,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (trialId.present) {
      map['trial_id'] = Variable<String>(trialId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (leaseExpiresAt.present) {
      map['lease_expires_at'] = Variable<DateTime>(leaseExpiresAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('trialId: $trialId, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('leaseExpiresAt: $leaseExpiresAt, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavedEnrollmentTable extends SavedEnrollment
    with TableInfo<$SavedEnrollmentTable, SavedEnrollmentData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavedEnrollmentTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<int> slot = GeneratedColumn<int>(
    'slot',
    aliasedName,
    false,
    check: () => slot.equals(1),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceTokenMeta = const VerificationMeta(
    'deviceToken',
  );
  @override
  late final GeneratedColumn<String> deviceToken = GeneratedColumn<String>(
    'device_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [slot, payload, deviceToken];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'saved_enrollment';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavedEnrollmentData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('device_token')) {
      context.handle(
        _deviceTokenMeta,
        deviceToken.isAcceptableOrUnknown(
          data['device_token']!,
          _deviceTokenMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deviceTokenMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {slot};
  @override
  SavedEnrollmentData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavedEnrollmentData(
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}slot'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      deviceToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_token'],
      )!,
    );
  }

  @override
  $SavedEnrollmentTable createAlias(String alias) {
    return $SavedEnrollmentTable(attachedDatabase, alias);
  }
}

class SavedEnrollmentData extends DataClass
    implements Insertable<SavedEnrollmentData> {
  final int slot;
  final String payload;
  final String deviceToken;
  const SavedEnrollmentData({
    required this.slot,
    required this.payload,
    required this.deviceToken,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['slot'] = Variable<int>(slot);
    map['payload'] = Variable<String>(payload);
    map['device_token'] = Variable<String>(deviceToken);
    return map;
  }

  SavedEnrollmentCompanion toCompanion(bool nullToAbsent) {
    return SavedEnrollmentCompanion(
      slot: Value(slot),
      payload: Value(payload),
      deviceToken: Value(deviceToken),
    );
  }

  factory SavedEnrollmentData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavedEnrollmentData(
      slot: serializer.fromJson<int>(json['slot']),
      payload: serializer.fromJson<String>(json['payload']),
      deviceToken: serializer.fromJson<String>(json['deviceToken']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'slot': serializer.toJson<int>(slot),
      'payload': serializer.toJson<String>(payload),
      'deviceToken': serializer.toJson<String>(deviceToken),
    };
  }

  SavedEnrollmentData copyWith({
    int? slot,
    String? payload,
    String? deviceToken,
  }) => SavedEnrollmentData(
    slot: slot ?? this.slot,
    payload: payload ?? this.payload,
    deviceToken: deviceToken ?? this.deviceToken,
  );
  SavedEnrollmentData copyWithCompanion(SavedEnrollmentCompanion data) {
    return SavedEnrollmentData(
      slot: data.slot.present ? data.slot.value : this.slot,
      payload: data.payload.present ? data.payload.value : this.payload,
      deviceToken: data.deviceToken.present
          ? data.deviceToken.value
          : this.deviceToken,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavedEnrollmentData(')
          ..write('slot: $slot, ')
          ..write('payload: $payload, ')
          ..write('deviceToken: $deviceToken')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(slot, payload, deviceToken);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavedEnrollmentData &&
          other.slot == this.slot &&
          other.payload == this.payload &&
          other.deviceToken == this.deviceToken);
}

class SavedEnrollmentCompanion extends UpdateCompanion<SavedEnrollmentData> {
  final Value<int> slot;
  final Value<String> payload;
  final Value<String> deviceToken;
  const SavedEnrollmentCompanion({
    this.slot = const Value.absent(),
    this.payload = const Value.absent(),
    this.deviceToken = const Value.absent(),
  });
  SavedEnrollmentCompanion.insert({
    this.slot = const Value.absent(),
    required String payload,
    required String deviceToken,
  }) : payload = Value(payload),
       deviceToken = Value(deviceToken);
  static Insertable<SavedEnrollmentData> custom({
    Expression<int>? slot,
    Expression<String>? payload,
    Expression<String>? deviceToken,
  }) {
    return RawValuesInsertable({
      if (slot != null) 'slot': slot,
      if (payload != null) 'payload': payload,
      if (deviceToken != null) 'device_token': deviceToken,
    });
  }

  SavedEnrollmentCompanion copyWith({
    Value<int>? slot,
    Value<String>? payload,
    Value<String>? deviceToken,
  }) {
    return SavedEnrollmentCompanion(
      slot: slot ?? this.slot,
      payload: payload ?? this.payload,
      deviceToken: deviceToken ?? this.deviceToken,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (slot.present) {
      map['slot'] = Variable<int>(slot.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (deviceToken.present) {
      map['device_token'] = Variable<String>(deviceToken.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavedEnrollmentCompanion(')
          ..write('slot: $slot, ')
          ..write('payload: $payload, ')
          ..write('deviceToken: $deviceToken')
          ..write(')'))
        .toString();
  }
}

class $EnrollmentGrantsTable extends EnrollmentGrants
    with TableInfo<$EnrollmentGrantsTable, EnrollmentGrant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnrollmentGrantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _participantIdMeta = const VerificationMeta(
    'participantId',
  );
  @override
  late final GeneratedColumn<String> participantId = GeneratedColumn<String>(
    'participant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES cached_participants (id)',
    ),
  );
  static const VerificationMeta _deviceTokenMeta = const VerificationMeta(
    'deviceToken',
  );
  @override
  late final GeneratedColumn<String> deviceToken = GeneratedColumn<String>(
    'device_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [participantId, deviceToken];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'enrollment_grants';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnrollmentGrant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('participant_id')) {
      context.handle(
        _participantIdMeta,
        participantId.isAcceptableOrUnknown(
          data['participant_id']!,
          _participantIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_participantIdMeta);
    }
    if (data.containsKey('device_token')) {
      context.handle(
        _deviceTokenMeta,
        deviceToken.isAcceptableOrUnknown(
          data['device_token']!,
          _deviceTokenMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deviceTokenMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {participantId};
  @override
  EnrollmentGrant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnrollmentGrant(
      participantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participant_id'],
      )!,
      deviceToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_token'],
      )!,
    );
  }

  @override
  $EnrollmentGrantsTable createAlias(String alias) {
    return $EnrollmentGrantsTable(attachedDatabase, alias);
  }
}

class EnrollmentGrant extends DataClass implements Insertable<EnrollmentGrant> {
  final String participantId;
  final String deviceToken;
  const EnrollmentGrant({
    required this.participantId,
    required this.deviceToken,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['participant_id'] = Variable<String>(participantId);
    map['device_token'] = Variable<String>(deviceToken);
    return map;
  }

  EnrollmentGrantsCompanion toCompanion(bool nullToAbsent) {
    return EnrollmentGrantsCompanion(
      participantId: Value(participantId),
      deviceToken: Value(deviceToken),
    );
  }

  factory EnrollmentGrant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnrollmentGrant(
      participantId: serializer.fromJson<String>(json['participantId']),
      deviceToken: serializer.fromJson<String>(json['deviceToken']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'participantId': serializer.toJson<String>(participantId),
      'deviceToken': serializer.toJson<String>(deviceToken),
    };
  }

  EnrollmentGrant copyWith({String? participantId, String? deviceToken}) =>
      EnrollmentGrant(
        participantId: participantId ?? this.participantId,
        deviceToken: deviceToken ?? this.deviceToken,
      );
  EnrollmentGrant copyWithCompanion(EnrollmentGrantsCompanion data) {
    return EnrollmentGrant(
      participantId: data.participantId.present
          ? data.participantId.value
          : this.participantId,
      deviceToken: data.deviceToken.present
          ? data.deviceToken.value
          : this.deviceToken,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnrollmentGrant(')
          ..write('participantId: $participantId, ')
          ..write('deviceToken: $deviceToken')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(participantId, deviceToken);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnrollmentGrant &&
          other.participantId == this.participantId &&
          other.deviceToken == this.deviceToken);
}

class EnrollmentGrantsCompanion extends UpdateCompanion<EnrollmentGrant> {
  final Value<String> participantId;
  final Value<String> deviceToken;
  final Value<int> rowid;
  const EnrollmentGrantsCompanion({
    this.participantId = const Value.absent(),
    this.deviceToken = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EnrollmentGrantsCompanion.insert({
    required String participantId,
    required String deviceToken,
    this.rowid = const Value.absent(),
  }) : participantId = Value(participantId),
       deviceToken = Value(deviceToken);
  static Insertable<EnrollmentGrant> custom({
    Expression<String>? participantId,
    Expression<String>? deviceToken,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (participantId != null) 'participant_id': participantId,
      if (deviceToken != null) 'device_token': deviceToken,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EnrollmentGrantsCompanion copyWith({
    Value<String>? participantId,
    Value<String>? deviceToken,
    Value<int>? rowid,
  }) {
    return EnrollmentGrantsCompanion(
      participantId: participantId ?? this.participantId,
      deviceToken: deviceToken ?? this.deviceToken,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (participantId.present) {
      map['participant_id'] = Variable<String>(participantId.value);
    }
    if (deviceToken.present) {
      map['device_token'] = Variable<String>(deviceToken.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnrollmentGrantsCompanion(')
          ..write('participantId: $participantId, ')
          ..write('deviceToken: $deviceToken, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $CachedParticipantsTable cachedParticipants =
      $CachedParticipantsTable(this);
  late final $CachedProtocolsTable cachedProtocols = $CachedProtocolsTable(
    this,
  );
  late final $StoredSessionsTable storedSessions = $StoredSessionsTable(this);
  late final $PhysicalDevicesTable physicalDevices = $PhysicalDevicesTable(
    this,
  );
  late final $StoredTrialsTable storedTrials = $StoredTrialsTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $SavedEnrollmentTable savedEnrollment = $SavedEnrollmentTable(
    this,
  );
  late final $EnrollmentGrantsTable enrollmentGrants = $EnrollmentGrantsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedParticipants,
    cachedProtocols,
    storedSessions,
    physicalDevices,
    storedTrials,
    syncQueue,
    savedEnrollment,
    enrollmentGrants,
  ];
}

typedef $$CachedParticipantsTableCreateCompanionBuilder =
    CachedParticipantsCompanion Function({
      required String id,
      required String payload,
      Value<int> rowid,
    });
typedef $$CachedParticipantsTableUpdateCompanionBuilder =
    CachedParticipantsCompanion Function({
      Value<String> id,
      Value<String> payload,
      Value<int> rowid,
    });

final class $$CachedParticipantsTableReferences
    extends
        BaseReferences<
          _$LocalDatabase,
          $CachedParticipantsTable,
          CachedParticipant
        > {
  $$CachedParticipantsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$StoredSessionsTable, List<StoredSession>>
  _storedSessionsRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.storedSessions,
    aliasName: 'cached_participants__id__stored_sessions__participant_id',
  );

  $$StoredSessionsTableProcessedTableManager get storedSessionsRefs {
    final manager = $$StoredSessionsTableTableManager(
      $_db,
      $_db.storedSessions,
    ).filter((f) => f.participantId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_storedSessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$EnrollmentGrantsTable, List<EnrollmentGrant>>
  _enrollmentGrantsRefsTable(_$LocalDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.enrollmentGrants,
        aliasName: 'cached_participants__id__enrollment_grants__participant_id',
      );

  $$EnrollmentGrantsTableProcessedTableManager get enrollmentGrantsRefs {
    final manager = $$EnrollmentGrantsTableTableManager(
      $_db,
      $_db.enrollmentGrants,
    ).filter((f) => f.participantId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _enrollmentGrantsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CachedParticipantsTableFilterComposer
    extends Composer<_$LocalDatabase, $CachedParticipantsTable> {
  $$CachedParticipantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> storedSessionsRefs(
    Expression<bool> Function($$StoredSessionsTableFilterComposer f) f,
  ) {
    final $$StoredSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storedSessions,
      getReferencedColumn: (t) => t.participantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredSessionsTableFilterComposer(
            $db: $db,
            $table: $db.storedSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> enrollmentGrantsRefs(
    Expression<bool> Function($$EnrollmentGrantsTableFilterComposer f) f,
  ) {
    final $$EnrollmentGrantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.enrollmentGrants,
      getReferencedColumn: (t) => t.participantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EnrollmentGrantsTableFilterComposer(
            $db: $db,
            $table: $db.enrollmentGrants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CachedParticipantsTableOrderingComposer
    extends Composer<_$LocalDatabase, $CachedParticipantsTable> {
  $$CachedParticipantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedParticipantsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CachedParticipantsTable> {
  $$CachedParticipantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  Expression<T> storedSessionsRefs<T extends Object>(
    Expression<T> Function($$StoredSessionsTableAnnotationComposer a) f,
  ) {
    final $$StoredSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storedSessions,
      getReferencedColumn: (t) => t.participantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> enrollmentGrantsRefs<T extends Object>(
    Expression<T> Function($$EnrollmentGrantsTableAnnotationComposer a) f,
  ) {
    final $$EnrollmentGrantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.enrollmentGrants,
      getReferencedColumn: (t) => t.participantId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EnrollmentGrantsTableAnnotationComposer(
            $db: $db,
            $table: $db.enrollmentGrants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CachedParticipantsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $CachedParticipantsTable,
          CachedParticipant,
          $$CachedParticipantsTableFilterComposer,
          $$CachedParticipantsTableOrderingComposer,
          $$CachedParticipantsTableAnnotationComposer,
          $$CachedParticipantsTableCreateCompanionBuilder,
          $$CachedParticipantsTableUpdateCompanionBuilder,
          (CachedParticipant, $$CachedParticipantsTableReferences),
          CachedParticipant,
          PrefetchHooks Function({
            bool storedSessionsRefs,
            bool enrollmentGrantsRefs,
          })
        > {
  $$CachedParticipantsTableTableManager(
    _$LocalDatabase db,
    $CachedParticipantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedParticipantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedParticipantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedParticipantsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedParticipantsCompanion(
                id: id,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => CachedParticipantsCompanion.insert(
                id: id,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedParticipantsTable, CachedParticipant>(
                    table,
                  ),
                  $$CachedParticipantsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({storedSessionsRefs = false, enrollmentGrantsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (storedSessionsRefs) db.storedSessions,
                    if (enrollmentGrantsRefs) db.enrollmentGrants,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (storedSessionsRefs)
                        await $_getPrefetchedData<
                          CachedParticipant,
                          $CachedParticipantsTable,
                          StoredSession
                        >(
                          currentTable: table,
                          referencedTable: $$CachedParticipantsTableReferences
                              ._storedSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CachedParticipantsTableReferences(
                                db,
                                table,
                                p0,
                              ).storedSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.participantId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (enrollmentGrantsRefs)
                        await $_getPrefetchedData<
                          CachedParticipant,
                          $CachedParticipantsTable,
                          EnrollmentGrant
                        >(
                          currentTable: table,
                          referencedTable: $$CachedParticipantsTableReferences
                              ._enrollmentGrantsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CachedParticipantsTableReferences(
                                db,
                                table,
                                p0,
                              ).enrollmentGrantsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.participantId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CachedParticipantsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $CachedParticipantsTable,
      CachedParticipant,
      $$CachedParticipantsTableFilterComposer,
      $$CachedParticipantsTableOrderingComposer,
      $$CachedParticipantsTableAnnotationComposer,
      $$CachedParticipantsTableCreateCompanionBuilder,
      $$CachedParticipantsTableUpdateCompanionBuilder,
      (CachedParticipant, $$CachedParticipantsTableReferences),
      CachedParticipant,
      PrefetchHooks Function({
        bool storedSessionsRefs,
        bool enrollmentGrantsRefs,
      })
    >;
typedef $$CachedProtocolsTableCreateCompanionBuilder =
    CachedProtocolsCompanion Function({
      required String id,
      required String payload,
      Value<int> rowid,
    });
typedef $$CachedProtocolsTableUpdateCompanionBuilder =
    CachedProtocolsCompanion Function({
      Value<String> id,
      Value<String> payload,
      Value<int> rowid,
    });

final class $$CachedProtocolsTableReferences
    extends
        BaseReferences<_$LocalDatabase, $CachedProtocolsTable, CachedProtocol> {
  $$CachedProtocolsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$StoredSessionsTable, List<StoredSession>>
  _storedSessionsRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.storedSessions,
    aliasName: 'cached_protocols__id__stored_sessions__protocol_version_id',
  );

  $$StoredSessionsTableProcessedTableManager get storedSessionsRefs {
    final manager = $$StoredSessionsTableTableManager($_db, $_db.storedSessions)
        .filter(
          (f) => f.protocolVersionId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_storedSessionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CachedProtocolsTableFilterComposer
    extends Composer<_$LocalDatabase, $CachedProtocolsTable> {
  $$CachedProtocolsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> storedSessionsRefs(
    Expression<bool> Function($$StoredSessionsTableFilterComposer f) f,
  ) {
    final $$StoredSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storedSessions,
      getReferencedColumn: (t) => t.protocolVersionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredSessionsTableFilterComposer(
            $db: $db,
            $table: $db.storedSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CachedProtocolsTableOrderingComposer
    extends Composer<_$LocalDatabase, $CachedProtocolsTable> {
  $$CachedProtocolsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedProtocolsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $CachedProtocolsTable> {
  $$CachedProtocolsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  Expression<T> storedSessionsRefs<T extends Object>(
    Expression<T> Function($$StoredSessionsTableAnnotationComposer a) f,
  ) {
    final $$StoredSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storedSessions,
      getReferencedColumn: (t) => t.protocolVersionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CachedProtocolsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $CachedProtocolsTable,
          CachedProtocol,
          $$CachedProtocolsTableFilterComposer,
          $$CachedProtocolsTableOrderingComposer,
          $$CachedProtocolsTableAnnotationComposer,
          $$CachedProtocolsTableCreateCompanionBuilder,
          $$CachedProtocolsTableUpdateCompanionBuilder,
          (CachedProtocol, $$CachedProtocolsTableReferences),
          CachedProtocol,
          PrefetchHooks Function({bool storedSessionsRefs})
        > {
  $$CachedProtocolsTableTableManager(
    _$LocalDatabase db,
    $CachedProtocolsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedProtocolsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedProtocolsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedProtocolsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedProtocolsCompanion(
                id: id,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => CachedProtocolsCompanion.insert(
                id: id,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedProtocolsTable, CachedProtocol>(table),
                  $$CachedProtocolsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({storedSessionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (storedSessionsRefs) db.storedSessions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (storedSessionsRefs)
                    await $_getPrefetchedData<
                      CachedProtocol,
                      $CachedProtocolsTable,
                      StoredSession
                    >(
                      currentTable: table,
                      referencedTable: $$CachedProtocolsTableReferences
                          ._storedSessionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CachedProtocolsTableReferences(
                            db,
                            table,
                            p0,
                          ).storedSessionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.protocolVersionId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CachedProtocolsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $CachedProtocolsTable,
      CachedProtocol,
      $$CachedProtocolsTableFilterComposer,
      $$CachedProtocolsTableOrderingComposer,
      $$CachedProtocolsTableAnnotationComposer,
      $$CachedProtocolsTableCreateCompanionBuilder,
      $$CachedProtocolsTableUpdateCompanionBuilder,
      (CachedProtocol, $$CachedProtocolsTableReferences),
      CachedProtocol,
      PrefetchHooks Function({bool storedSessionsRefs})
    >;
typedef $$StoredSessionsTableCreateCompanionBuilder =
    StoredSessionsCompanion Function({
      required String id,
      required String participantId,
      required String protocolVersionId,
      required String snapshot,
      Value<int> nextIndex,
      Value<int> rowid,
    });
typedef $$StoredSessionsTableUpdateCompanionBuilder =
    StoredSessionsCompanion Function({
      Value<String> id,
      Value<String> participantId,
      Value<String> protocolVersionId,
      Value<String> snapshot,
      Value<int> nextIndex,
      Value<int> rowid,
    });

final class $$StoredSessionsTableReferences
    extends
        BaseReferences<_$LocalDatabase, $StoredSessionsTable, StoredSession> {
  $$StoredSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CachedParticipantsTable _participantIdTable(_$LocalDatabase db) => db
      .cachedParticipants
      .createAlias('stored_sessions__participant_id__cached_participants__id');

  $$CachedParticipantsTableProcessedTableManager get participantId {
    final $_column = $_itemColumn<String>('participant_id')!;

    final manager = $$CachedParticipantsTableTableManager(
      $_db,
      $_db.cachedParticipants,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_participantIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CachedProtocolsTable _protocolVersionIdTable(_$LocalDatabase db) =>
      db.cachedProtocols.createAlias(
        'stored_sessions__protocol_version_id__cached_protocols__id',
      );

  $$CachedProtocolsTableProcessedTableManager get protocolVersionId {
    final $_column = $_itemColumn<String>('protocol_version_id')!;

    final manager = $$CachedProtocolsTableTableManager(
      $_db,
      $_db.cachedProtocols,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_protocolVersionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$StoredTrialsTable, List<StoredTrial>>
  _storedTrialsRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.storedTrials,
    aliasName: 'stored_sessions__id__stored_trials__session_id',
  );

  $$StoredTrialsTableProcessedTableManager get storedTrialsRefs {
    final manager = $$StoredTrialsTableTableManager(
      $_db,
      $_db.storedTrials,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_storedTrialsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StoredSessionsTableFilterComposer
    extends Composer<_$LocalDatabase, $StoredSessionsTable> {
  $$StoredSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextIndex => $composableBuilder(
    column: $table.nextIndex,
    builder: (column) => ColumnFilters(column),
  );

  $$CachedParticipantsTableFilterComposer get participantId {
    final $$CachedParticipantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.participantId,
      referencedTable: $db.cachedParticipants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedParticipantsTableFilterComposer(
            $db: $db,
            $table: $db.cachedParticipants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CachedProtocolsTableFilterComposer get protocolVersionId {
    final $$CachedProtocolsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.protocolVersionId,
      referencedTable: $db.cachedProtocols,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedProtocolsTableFilterComposer(
            $db: $db,
            $table: $db.cachedProtocols,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> storedTrialsRefs(
    Expression<bool> Function($$StoredTrialsTableFilterComposer f) f,
  ) {
    final $$StoredTrialsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storedTrials,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredTrialsTableFilterComposer(
            $db: $db,
            $table: $db.storedTrials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoredSessionsTableOrderingComposer
    extends Composer<_$LocalDatabase, $StoredSessionsTable> {
  $$StoredSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextIndex => $composableBuilder(
    column: $table.nextIndex,
    builder: (column) => ColumnOrderings(column),
  );

  $$CachedParticipantsTableOrderingComposer get participantId {
    final $$CachedParticipantsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.participantId,
      referencedTable: $db.cachedParticipants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedParticipantsTableOrderingComposer(
            $db: $db,
            $table: $db.cachedParticipants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CachedProtocolsTableOrderingComposer get protocolVersionId {
    final $$CachedProtocolsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.protocolVersionId,
      referencedTable: $db.cachedProtocols,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedProtocolsTableOrderingComposer(
            $db: $db,
            $table: $db.cachedProtocols,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredSessionsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $StoredSessionsTable> {
  $$StoredSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get snapshot =>
      $composableBuilder(column: $table.snapshot, builder: (column) => column);

  GeneratedColumn<int> get nextIndex =>
      $composableBuilder(column: $table.nextIndex, builder: (column) => column);

  $$CachedParticipantsTableAnnotationComposer get participantId {
    final $$CachedParticipantsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.participantId,
          referencedTable: $db.cachedParticipants,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CachedParticipantsTableAnnotationComposer(
                $db: $db,
                $table: $db.cachedParticipants,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$CachedProtocolsTableAnnotationComposer get protocolVersionId {
    final $$CachedProtocolsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.protocolVersionId,
      referencedTable: $db.cachedProtocols,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedProtocolsTableAnnotationComposer(
            $db: $db,
            $table: $db.cachedProtocols,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> storedTrialsRefs<T extends Object>(
    Expression<T> Function($$StoredTrialsTableAnnotationComposer a) f,
  ) {
    final $$StoredTrialsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storedTrials,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredTrialsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedTrials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoredSessionsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $StoredSessionsTable,
          StoredSession,
          $$StoredSessionsTableFilterComposer,
          $$StoredSessionsTableOrderingComposer,
          $$StoredSessionsTableAnnotationComposer,
          $$StoredSessionsTableCreateCompanionBuilder,
          $$StoredSessionsTableUpdateCompanionBuilder,
          (StoredSession, $$StoredSessionsTableReferences),
          StoredSession,
          PrefetchHooks Function({
            bool participantId,
            bool protocolVersionId,
            bool storedTrialsRefs,
          })
        > {
  $$StoredSessionsTableTableManager(
    _$LocalDatabase db,
    $StoredSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> participantId = const Value.absent(),
                Value<String> protocolVersionId = const Value.absent(),
                Value<String> snapshot = const Value.absent(),
                Value<int> nextIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredSessionsCompanion(
                id: id,
                participantId: participantId,
                protocolVersionId: protocolVersionId,
                snapshot: snapshot,
                nextIndex: nextIndex,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String participantId,
                required String protocolVersionId,
                required String snapshot,
                Value<int> nextIndex = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredSessionsCompanion.insert(
                id: id,
                participantId: participantId,
                protocolVersionId: protocolVersionId,
                snapshot: snapshot,
                nextIndex: nextIndex,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoredSessionsTable, StoredSession>(table),
                  $$StoredSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                participantId = false,
                protocolVersionId = false,
                storedTrialsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (storedTrialsRefs) db.storedTrials,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (participantId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.participantId,
                            referencedTable: $$StoredSessionsTableReferences
                                ._participantIdTable(db),
                            referencedColumn: $$StoredSessionsTableReferences
                                ._participantIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (protocolVersionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.protocolVersionId,
                            referencedTable: $$StoredSessionsTableReferences
                                ._protocolVersionIdTable(db),
                            referencedColumn: $$StoredSessionsTableReferences
                                ._protocolVersionIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (storedTrialsRefs)
                        await $_getPrefetchedData<
                          StoredSession,
                          $StoredSessionsTable,
                          StoredTrial
                        >(
                          currentTable: table,
                          referencedTable: $$StoredSessionsTableReferences
                              ._storedTrialsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoredSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).storedTrialsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StoredSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $StoredSessionsTable,
      StoredSession,
      $$StoredSessionsTableFilterComposer,
      $$StoredSessionsTableOrderingComposer,
      $$StoredSessionsTableAnnotationComposer,
      $$StoredSessionsTableCreateCompanionBuilder,
      $$StoredSessionsTableUpdateCompanionBuilder,
      (StoredSession, $$StoredSessionsTableReferences),
      StoredSession,
      PrefetchHooks Function({
        bool participantId,
        bool protocolVersionId,
        bool storedTrialsRefs,
      })
    >;
typedef $$PhysicalDevicesTableCreateCompanionBuilder =
    PhysicalDevicesCompanion Function({
      required String id,
      required String payload,
      Value<int> rowid,
    });
typedef $$PhysicalDevicesTableUpdateCompanionBuilder =
    PhysicalDevicesCompanion Function({
      Value<String> id,
      Value<String> payload,
      Value<int> rowid,
    });

final class $$PhysicalDevicesTableReferences
    extends
        BaseReferences<_$LocalDatabase, $PhysicalDevicesTable, PhysicalDevice> {
  $$PhysicalDevicesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$StoredTrialsTable, List<StoredTrial>>
  _storedTrialsRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.storedTrials,
    aliasName: 'physical_devices__id__stored_trials__device_id',
  );

  $$StoredTrialsTableProcessedTableManager get storedTrialsRefs {
    final manager = $$StoredTrialsTableTableManager(
      $_db,
      $_db.storedTrials,
    ).filter((f) => f.deviceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_storedTrialsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PhysicalDevicesTableFilterComposer
    extends Composer<_$LocalDatabase, $PhysicalDevicesTable> {
  $$PhysicalDevicesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> storedTrialsRefs(
    Expression<bool> Function($$StoredTrialsTableFilterComposer f) f,
  ) {
    final $$StoredTrialsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storedTrials,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredTrialsTableFilterComposer(
            $db: $db,
            $table: $db.storedTrials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PhysicalDevicesTableOrderingComposer
    extends Composer<_$LocalDatabase, $PhysicalDevicesTable> {
  $$PhysicalDevicesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhysicalDevicesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $PhysicalDevicesTable> {
  $$PhysicalDevicesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  Expression<T> storedTrialsRefs<T extends Object>(
    Expression<T> Function($$StoredTrialsTableAnnotationComposer a) f,
  ) {
    final $$StoredTrialsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storedTrials,
      getReferencedColumn: (t) => t.deviceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredTrialsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedTrials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PhysicalDevicesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $PhysicalDevicesTable,
          PhysicalDevice,
          $$PhysicalDevicesTableFilterComposer,
          $$PhysicalDevicesTableOrderingComposer,
          $$PhysicalDevicesTableAnnotationComposer,
          $$PhysicalDevicesTableCreateCompanionBuilder,
          $$PhysicalDevicesTableUpdateCompanionBuilder,
          (PhysicalDevice, $$PhysicalDevicesTableReferences),
          PhysicalDevice,
          PrefetchHooks Function({bool storedTrialsRefs})
        > {
  $$PhysicalDevicesTableTableManager(
    _$LocalDatabase db,
    $PhysicalDevicesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhysicalDevicesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhysicalDevicesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhysicalDevicesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhysicalDevicesCompanion(
                id: id,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => PhysicalDevicesCompanion.insert(
                id: id,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PhysicalDevicesTable, PhysicalDevice>(table),
                  $$PhysicalDevicesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({storedTrialsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (storedTrialsRefs) db.storedTrials],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (storedTrialsRefs)
                    await $_getPrefetchedData<
                      PhysicalDevice,
                      $PhysicalDevicesTable,
                      StoredTrial
                    >(
                      currentTable: table,
                      referencedTable: $$PhysicalDevicesTableReferences
                          ._storedTrialsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PhysicalDevicesTableReferences(
                            db,
                            table,
                            p0,
                          ).storedTrialsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.deviceId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PhysicalDevicesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $PhysicalDevicesTable,
      PhysicalDevice,
      $$PhysicalDevicesTableFilterComposer,
      $$PhysicalDevicesTableOrderingComposer,
      $$PhysicalDevicesTableAnnotationComposer,
      $$PhysicalDevicesTableCreateCompanionBuilder,
      $$PhysicalDevicesTableUpdateCompanionBuilder,
      (PhysicalDevice, $$PhysicalDevicesTableReferences),
      PhysicalDevice,
      PrefetchHooks Function({bool storedTrialsRefs})
    >;
typedef $$StoredTrialsTableCreateCompanionBuilder =
    StoredTrialsCompanion Function({
      required String id,
      required String sessionId,
      required String deviceId,
      required String payload,
      required String filePayload,
      required String rawPath,
      required String compressedPath,
      Value<int> rowid,
    });
typedef $$StoredTrialsTableUpdateCompanionBuilder =
    StoredTrialsCompanion Function({
      Value<String> id,
      Value<String> sessionId,
      Value<String> deviceId,
      Value<String> payload,
      Value<String> filePayload,
      Value<String> rawPath,
      Value<String> compressedPath,
      Value<int> rowid,
    });

final class $$StoredTrialsTableReferences
    extends BaseReferences<_$LocalDatabase, $StoredTrialsTable, StoredTrial> {
  $$StoredTrialsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StoredSessionsTable _sessionIdTable(_$LocalDatabase db) => db
      .storedSessions
      .createAlias('stored_trials__session_id__stored_sessions__id');

  $$StoredSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$StoredSessionsTableTableManager(
      $_db,
      $_db.storedSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PhysicalDevicesTable _deviceIdTable(_$LocalDatabase db) => db
      .physicalDevices
      .createAlias('stored_trials__device_id__physical_devices__id');

  $$PhysicalDevicesTableProcessedTableManager get deviceId {
    final $_column = $_itemColumn<String>('device_id')!;

    final manager = $$PhysicalDevicesTableTableManager(
      $_db,
      $_db.physicalDevices,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deviceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SyncQueueTable, List<SyncQueueData>>
  _syncQueueRefsTable(_$LocalDatabase db) => MultiTypedResultKey.fromTable(
    db.syncQueue,
    aliasName: 'stored_trials__id__sync_queue__trial_id',
  );

  $$SyncQueueTableProcessedTableManager get syncQueueRefs {
    final manager = $$SyncQueueTableTableManager(
      $_db,
      $_db.syncQueue,
    ).filter((f) => f.trialId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_syncQueueRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StoredTrialsTableFilterComposer
    extends Composer<_$LocalDatabase, $StoredTrialsTable> {
  $$StoredTrialsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePayload => $composableBuilder(
    column: $table.filePayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawPath => $composableBuilder(
    column: $table.rawPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get compressedPath => $composableBuilder(
    column: $table.compressedPath,
    builder: (column) => ColumnFilters(column),
  );

  $$StoredSessionsTableFilterComposer get sessionId {
    final $$StoredSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.storedSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredSessionsTableFilterComposer(
            $db: $db,
            $table: $db.storedSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PhysicalDevicesTableFilterComposer get deviceId {
    final $$PhysicalDevicesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.physicalDevices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhysicalDevicesTableFilterComposer(
            $db: $db,
            $table: $db.physicalDevices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> syncQueueRefs(
    Expression<bool> Function($$SyncQueueTableFilterComposer f) f,
  ) {
    final $$SyncQueueTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncQueue,
      getReferencedColumn: (t) => t.trialId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncQueueTableFilterComposer(
            $db: $db,
            $table: $db.syncQueue,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoredTrialsTableOrderingComposer
    extends Composer<_$LocalDatabase, $StoredTrialsTable> {
  $$StoredTrialsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePayload => $composableBuilder(
    column: $table.filePayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawPath => $composableBuilder(
    column: $table.rawPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get compressedPath => $composableBuilder(
    column: $table.compressedPath,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoredSessionsTableOrderingComposer get sessionId {
    final $$StoredSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.storedSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.storedSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PhysicalDevicesTableOrderingComposer get deviceId {
    final $$PhysicalDevicesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.physicalDevices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhysicalDevicesTableOrderingComposer(
            $db: $db,
            $table: $db.physicalDevices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredTrialsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $StoredTrialsTable> {
  $$StoredTrialsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get filePayload => $composableBuilder(
    column: $table.filePayload,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawPath =>
      $composableBuilder(column: $table.rawPath, builder: (column) => column);

  GeneratedColumn<String> get compressedPath => $composableBuilder(
    column: $table.compressedPath,
    builder: (column) => column,
  );

  $$StoredSessionsTableAnnotationComposer get sessionId {
    final $$StoredSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.storedSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PhysicalDevicesTableAnnotationComposer get deviceId {
    final $$PhysicalDevicesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deviceId,
      referencedTable: $db.physicalDevices,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PhysicalDevicesTableAnnotationComposer(
            $db: $db,
            $table: $db.physicalDevices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> syncQueueRefs<T extends Object>(
    Expression<T> Function($$SyncQueueTableAnnotationComposer a) f,
  ) {
    final $$SyncQueueTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncQueue,
      getReferencedColumn: (t) => t.trialId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncQueueTableAnnotationComposer(
            $db: $db,
            $table: $db.syncQueue,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoredTrialsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $StoredTrialsTable,
          StoredTrial,
          $$StoredTrialsTableFilterComposer,
          $$StoredTrialsTableOrderingComposer,
          $$StoredTrialsTableAnnotationComposer,
          $$StoredTrialsTableCreateCompanionBuilder,
          $$StoredTrialsTableUpdateCompanionBuilder,
          (StoredTrial, $$StoredTrialsTableReferences),
          StoredTrial,
          PrefetchHooks Function({
            bool sessionId,
            bool deviceId,
            bool syncQueueRefs,
          })
        > {
  $$StoredTrialsTableTableManager(_$LocalDatabase db, $StoredTrialsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredTrialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredTrialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredTrialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> filePayload = const Value.absent(),
                Value<String> rawPath = const Value.absent(),
                Value<String> compressedPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredTrialsCompanion(
                id: id,
                sessionId: sessionId,
                deviceId: deviceId,
                payload: payload,
                filePayload: filePayload,
                rawPath: rawPath,
                compressedPath: compressedPath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sessionId,
                required String deviceId,
                required String payload,
                required String filePayload,
                required String rawPath,
                required String compressedPath,
                Value<int> rowid = const Value.absent(),
              }) => StoredTrialsCompanion.insert(
                id: id,
                sessionId: sessionId,
                deviceId: deviceId,
                payload: payload,
                filePayload: filePayload,
                rawPath: rawPath,
                compressedPath: compressedPath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoredTrialsTable, StoredTrial>(table),
                  $$StoredTrialsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sessionId = false, deviceId = false, syncQueueRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (syncQueueRefs) db.syncQueue],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sessionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sessionId,
                            referencedTable: $$StoredTrialsTableReferences
                                ._sessionIdTable(db),
                            referencedColumn: $$StoredTrialsTableReferences
                                ._sessionIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (deviceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.deviceId,
                            referencedTable: $$StoredTrialsTableReferences
                                ._deviceIdTable(db),
                            referencedColumn: $$StoredTrialsTableReferences
                                ._deviceIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (syncQueueRefs)
                        await $_getPrefetchedData<
                          StoredTrial,
                          $StoredTrialsTable,
                          SyncQueueData
                        >(
                          currentTable: table,
                          referencedTable: $$StoredTrialsTableReferences
                              ._syncQueueRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoredTrialsTableReferences(
                                db,
                                table,
                                p0,
                              ).syncQueueRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.trialId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StoredTrialsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $StoredTrialsTable,
      StoredTrial,
      $$StoredTrialsTableFilterComposer,
      $$StoredTrialsTableOrderingComposer,
      $$StoredTrialsTableAnnotationComposer,
      $$StoredTrialsTableCreateCompanionBuilder,
      $$StoredTrialsTableUpdateCompanionBuilder,
      (StoredTrial, $$StoredTrialsTableReferences),
      StoredTrial,
      PrefetchHooks Function({
        bool sessionId,
        bool deviceId,
        bool syncQueueRefs,
      })
    >;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  required String trialId,
  Value<String> status,
  Value<int> attempts,
  required DateTime nextAttemptAt,
  Value<DateTime?> leaseExpiresAt,
  Value<String?> lastError,
  Value<int> rowid,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<String> trialId,
  Value<String> status,
  Value<int> attempts,
  Value<DateTime> nextAttemptAt,
  Value<DateTime?> leaseExpiresAt,
  Value<String?> lastError,
  Value<int> rowid,
});

final class $$SyncQueueTableReferences
    extends BaseReferences<_$LocalDatabase, $SyncQueueTable, SyncQueueData> {
  $$SyncQueueTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StoredTrialsTable _trialIdTable(_$LocalDatabase db) =>
      db.storedTrials.createAlias('sync_queue__trial_id__stored_trials__id');

  $$StoredTrialsTableProcessedTableManager get trialId {
    final $_column = $_itemColumn<String>('trial_id')!;

    final manager = $$StoredTrialsTableTableManager(
      $_db,
      $_db.storedTrials,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_trialIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyncQueueTableFilterComposer
    extends Composer<_$LocalDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get leaseExpiresAt => $composableBuilder(
    column: $table.leaseExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  $$StoredTrialsTableFilterComposer get trialId {
    final $$StoredTrialsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trialId,
      referencedTable: $db.storedTrials,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredTrialsTableFilterComposer(
            $db: $db,
            $table: $db.storedTrials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$LocalDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get leaseExpiresAt => $composableBuilder(
    column: $table.leaseExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoredTrialsTableOrderingComposer get trialId {
    final $$StoredTrialsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trialId,
      referencedTable: $db.storedTrials,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredTrialsTableOrderingComposer(
            $db: $db,
            $table: $db.storedTrials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$LocalDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get leaseExpiresAt => $composableBuilder(
    column: $table.leaseExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  $$StoredTrialsTableAnnotationComposer get trialId {
    final $$StoredTrialsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.trialId,
      referencedTable: $db.storedTrials,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredTrialsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedTrials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (SyncQueueData, $$SyncQueueTableReferences),
          SyncQueueData,
          PrefetchHooks Function({bool trialId})
        > {
  $$SyncQueueTableTableManager(_$LocalDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> trialId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> nextAttemptAt = const Value.absent(),
                Value<DateTime?> leaseExpiresAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion(
                trialId: trialId,
                status: status,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                leaseExpiresAt: leaseExpiresAt,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String trialId,
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                required DateTime nextAttemptAt,
                Value<DateTime?> leaseExpiresAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                trialId: trialId,
                status: status,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                leaseExpiresAt: leaseExpiresAt,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncQueueTable, SyncQueueData>(table),
                  $$SyncQueueTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({trialId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (trialId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.trialId,
                        referencedTable: $$SyncQueueTableReferences
                            ._trialIdTable(db),
                        referencedColumn: $$SyncQueueTableReferences
                            ._trialIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (SyncQueueData, $$SyncQueueTableReferences),
      SyncQueueData,
      PrefetchHooks Function({bool trialId})
    >;
typedef $$SavedEnrollmentTableCreateCompanionBuilder =
    SavedEnrollmentCompanion Function({
      Value<int> slot,
      required String payload,
      required String deviceToken,
    });
typedef $$SavedEnrollmentTableUpdateCompanionBuilder =
    SavedEnrollmentCompanion Function({
      Value<int> slot,
      Value<String> payload,
      Value<String> deviceToken,
    });

class $$SavedEnrollmentTableFilterComposer
    extends Composer<_$LocalDatabase, $SavedEnrollmentTable> {
  $$SavedEnrollmentTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceToken => $composableBuilder(
    column: $table.deviceToken,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavedEnrollmentTableOrderingComposer
    extends Composer<_$LocalDatabase, $SavedEnrollmentTable> {
  $$SavedEnrollmentTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceToken => $composableBuilder(
    column: $table.deviceToken,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavedEnrollmentTableAnnotationComposer
    extends Composer<_$LocalDatabase, $SavedEnrollmentTable> {
  $$SavedEnrollmentTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<String> get deviceToken => $composableBuilder(
    column: $table.deviceToken,
    builder: (column) => column,
  );
}

class $$SavedEnrollmentTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $SavedEnrollmentTable,
          SavedEnrollmentData,
          $$SavedEnrollmentTableFilterComposer,
          $$SavedEnrollmentTableOrderingComposer,
          $$SavedEnrollmentTableAnnotationComposer,
          $$SavedEnrollmentTableCreateCompanionBuilder,
          $$SavedEnrollmentTableUpdateCompanionBuilder,
          (
            SavedEnrollmentData,
            BaseReferences<
              _$LocalDatabase,
              $SavedEnrollmentTable,
              SavedEnrollmentData
            >,
          ),
          SavedEnrollmentData,
          PrefetchHooks Function()
        > {
  $$SavedEnrollmentTableTableManager(
    _$LocalDatabase db,
    $SavedEnrollmentTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavedEnrollmentTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavedEnrollmentTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavedEnrollmentTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> slot = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<String> deviceToken = const Value.absent(),
              }) => SavedEnrollmentCompanion(
                slot: slot,
                payload: payload,
                deviceToken: deviceToken,
              ),
          createCompanionCallback:
              ({
                Value<int> slot = const Value.absent(),
                required String payload,
                required String deviceToken,
              }) => SavedEnrollmentCompanion.insert(
                slot: slot,
                payload: payload,
                deviceToken: deviceToken,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SavedEnrollmentTable, SavedEnrollmentData>(
                    table,
                  ),
                  BaseReferences<
                    _$LocalDatabase,
                    $SavedEnrollmentTable,
                    SavedEnrollmentData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavedEnrollmentTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $SavedEnrollmentTable,
      SavedEnrollmentData,
      $$SavedEnrollmentTableFilterComposer,
      $$SavedEnrollmentTableOrderingComposer,
      $$SavedEnrollmentTableAnnotationComposer,
      $$SavedEnrollmentTableCreateCompanionBuilder,
      $$SavedEnrollmentTableUpdateCompanionBuilder,
      (
        SavedEnrollmentData,
        BaseReferences<
          _$LocalDatabase,
          $SavedEnrollmentTable,
          SavedEnrollmentData
        >,
      ),
      SavedEnrollmentData,
      PrefetchHooks Function()
    >;
typedef $$EnrollmentGrantsTableCreateCompanionBuilder =
    EnrollmentGrantsCompanion Function({
      required String participantId,
      required String deviceToken,
      Value<int> rowid,
    });
typedef $$EnrollmentGrantsTableUpdateCompanionBuilder =
    EnrollmentGrantsCompanion Function({
      Value<String> participantId,
      Value<String> deviceToken,
      Value<int> rowid,
    });

final class $$EnrollmentGrantsTableReferences
    extends
        BaseReferences<
          _$LocalDatabase,
          $EnrollmentGrantsTable,
          EnrollmentGrant
        > {
  $$EnrollmentGrantsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CachedParticipantsTable _participantIdTable(_$LocalDatabase db) =>
      db.cachedParticipants.createAlias(
        'enrollment_grants__participant_id__cached_participants__id',
      );

  $$CachedParticipantsTableProcessedTableManager get participantId {
    final $_column = $_itemColumn<String>('participant_id')!;

    final manager = $$CachedParticipantsTableTableManager(
      $_db,
      $_db.cachedParticipants,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_participantIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$EnrollmentGrantsTableFilterComposer
    extends Composer<_$LocalDatabase, $EnrollmentGrantsTable> {
  $$EnrollmentGrantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get deviceToken => $composableBuilder(
    column: $table.deviceToken,
    builder: (column) => ColumnFilters(column),
  );

  $$CachedParticipantsTableFilterComposer get participantId {
    final $$CachedParticipantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.participantId,
      referencedTable: $db.cachedParticipants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedParticipantsTableFilterComposer(
            $db: $db,
            $table: $db.cachedParticipants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EnrollmentGrantsTableOrderingComposer
    extends Composer<_$LocalDatabase, $EnrollmentGrantsTable> {
  $$EnrollmentGrantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get deviceToken => $composableBuilder(
    column: $table.deviceToken,
    builder: (column) => ColumnOrderings(column),
  );

  $$CachedParticipantsTableOrderingComposer get participantId {
    final $$CachedParticipantsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.participantId,
      referencedTable: $db.cachedParticipants,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CachedParticipantsTableOrderingComposer(
            $db: $db,
            $table: $db.cachedParticipants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EnrollmentGrantsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $EnrollmentGrantsTable> {
  $$EnrollmentGrantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get deviceToken => $composableBuilder(
    column: $table.deviceToken,
    builder: (column) => column,
  );

  $$CachedParticipantsTableAnnotationComposer get participantId {
    final $$CachedParticipantsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.participantId,
          referencedTable: $db.cachedParticipants,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CachedParticipantsTableAnnotationComposer(
                $db: $db,
                $table: $db.cachedParticipants,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$EnrollmentGrantsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $EnrollmentGrantsTable,
          EnrollmentGrant,
          $$EnrollmentGrantsTableFilterComposer,
          $$EnrollmentGrantsTableOrderingComposer,
          $$EnrollmentGrantsTableAnnotationComposer,
          $$EnrollmentGrantsTableCreateCompanionBuilder,
          $$EnrollmentGrantsTableUpdateCompanionBuilder,
          (EnrollmentGrant, $$EnrollmentGrantsTableReferences),
          EnrollmentGrant,
          PrefetchHooks Function({bool participantId})
        > {
  $$EnrollmentGrantsTableTableManager(
    _$LocalDatabase db,
    $EnrollmentGrantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnrollmentGrantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnrollmentGrantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnrollmentGrantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> participantId = const Value.absent(),
                Value<String> deviceToken = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnrollmentGrantsCompanion(
                participantId: participantId,
                deviceToken: deviceToken,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String participantId,
                required String deviceToken,
                Value<int> rowid = const Value.absent(),
              }) => EnrollmentGrantsCompanion.insert(
                participantId: participantId,
                deviceToken: deviceToken,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EnrollmentGrantsTable, EnrollmentGrant>(table),
                  $$EnrollmentGrantsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({participantId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (participantId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.participantId,
                        referencedTable: $$EnrollmentGrantsTableReferences
                            ._participantIdTable(db),
                        referencedColumn: $$EnrollmentGrantsTableReferences
                            ._participantIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$EnrollmentGrantsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $EnrollmentGrantsTable,
      EnrollmentGrant,
      $$EnrollmentGrantsTableFilterComposer,
      $$EnrollmentGrantsTableOrderingComposer,
      $$EnrollmentGrantsTableAnnotationComposer,
      $$EnrollmentGrantsTableCreateCompanionBuilder,
      $$EnrollmentGrantsTableUpdateCompanionBuilder,
      (EnrollmentGrant, $$EnrollmentGrantsTableReferences),
      EnrollmentGrant,
      PrefetchHooks Function({bool participantId})
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$CachedParticipantsTableTableManager get cachedParticipants =>
      $$CachedParticipantsTableTableManager(_db, _db.cachedParticipants);
  $$CachedProtocolsTableTableManager get cachedProtocols =>
      $$CachedProtocolsTableTableManager(_db, _db.cachedProtocols);
  $$StoredSessionsTableTableManager get storedSessions =>
      $$StoredSessionsTableTableManager(_db, _db.storedSessions);
  $$PhysicalDevicesTableTableManager get physicalDevices =>
      $$PhysicalDevicesTableTableManager(_db, _db.physicalDevices);
  $$StoredTrialsTableTableManager get storedTrials =>
      $$StoredTrialsTableTableManager(_db, _db.storedTrials);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$SavedEnrollmentTableTableManager get savedEnrollment =>
      $$SavedEnrollmentTableTableManager(_db, _db.savedEnrollment);
  $$EnrollmentGrantsTableTableManager get enrollmentGrants =>
      $$EnrollmentGrantsTableTableManager(_db, _db.enrollmentGrants);
}
