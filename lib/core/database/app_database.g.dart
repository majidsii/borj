// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TaskRowsTable extends TaskRows with TableInfo<$TaskRowsTable, TaskRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNumberMeta = const VerificationMeta(
    'displayNumber',
  );
  @override
  late final GeneratedColumn<int> displayNumber = GeneratedColumn<int>(
    'display_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionInStatusMeta = const VerificationMeta(
    'positionInStatus',
  );
  @override
  late final GeneratedColumn<int> positionInStatus = GeneratedColumn<int>(
    'position_in_status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startAtUtcMeta = const VerificationMeta(
    'startAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> startAtUtc = GeneratedColumn<DateTime>(
    'start_at_utc',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueAtUtcMeta = const VerificationMeta(
    'dueAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> dueAtUtc = GeneratedColumn<DateTime>(
    'due_at_utc',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimatedDurationMinutesMeta =
      const VerificationMeta('estimatedDurationMinutes');
  @override
  late final GeneratedColumn<int> estimatedDurationMinutes =
      GeneratedColumn<int>(
        'estimated_duration_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtUtcMeta = const VerificationMeta(
    'completedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> completedAtUtc =
      GeneratedColumn<DateTime>(
        'completed_at_utc',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _canceledAtUtcMeta = const VerificationMeta(
    'canceledAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> canceledAtUtc =
      GeneratedColumn<DateTime>(
        'canceled_at_utc',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayNumber,
    title,
    description,
    priority,
    status,
    positionInStatus,
    startAtUtc,
    dueAtUtc,
    estimatedDurationMinutes,
    createdAtUtc,
    updatedAtUtc,
    completedAtUtc,
    canceledAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_number')) {
      context.handle(
        _displayNumberMeta,
        displayNumber.isAcceptableOrUnknown(
          data['display_number']!,
          _displayNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNumberMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('position_in_status')) {
      context.handle(
        _positionInStatusMeta,
        positionInStatus.isAcceptableOrUnknown(
          data['position_in_status']!,
          _positionInStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_positionInStatusMeta);
    }
    if (data.containsKey('start_at_utc')) {
      context.handle(
        _startAtUtcMeta,
        startAtUtc.isAcceptableOrUnknown(
          data['start_at_utc']!,
          _startAtUtcMeta,
        ),
      );
    }
    if (data.containsKey('due_at_utc')) {
      context.handle(
        _dueAtUtcMeta,
        dueAtUtc.isAcceptableOrUnknown(data['due_at_utc']!, _dueAtUtcMeta),
      );
    }
    if (data.containsKey('estimated_duration_minutes')) {
      context.handle(
        _estimatedDurationMinutesMeta,
        estimatedDurationMinutes.isAcceptableOrUnknown(
          data['estimated_duration_minutes']!,
          _estimatedDurationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    if (data.containsKey('completed_at_utc')) {
      context.handle(
        _completedAtUtcMeta,
        completedAtUtc.isAcceptableOrUnknown(
          data['completed_at_utc']!,
          _completedAtUtcMeta,
        ),
      );
    }
    if (data.containsKey('canceled_at_utc')) {
      context.handle(
        _canceledAtUtcMeta,
        canceledAtUtc.isAcceptableOrUnknown(
          data['canceled_at_utc']!,
          _canceledAtUtcMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_number'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      positionInStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_in_status'],
      )!,
      startAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_at_utc'],
      ),
      dueAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_at_utc'],
      ),
      estimatedDurationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_duration_minutes'],
      ),
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
      completedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at_utc'],
      ),
      canceledAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}canceled_at_utc'],
      ),
    );
  }

  @override
  $TaskRowsTable createAlias(String alias) {
    return $TaskRowsTable(attachedDatabase, alias);
  }
}

class TaskRow extends DataClass implements Insertable<TaskRow> {
  final String id;
  final int displayNumber;
  final String title;
  final String? description;
  final int priority;
  final String status;
  final int positionInStatus;
  final DateTime? startAtUtc;
  final DateTime? dueAtUtc;
  final int? estimatedDurationMinutes;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final DateTime? completedAtUtc;
  final DateTime? canceledAtUtc;
  const TaskRow({
    required this.id,
    required this.displayNumber,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    required this.positionInStatus,
    this.startAtUtc,
    this.dueAtUtc,
    this.estimatedDurationMinutes,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.completedAtUtc,
    this.canceledAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_number'] = Variable<int>(displayNumber);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['priority'] = Variable<int>(priority);
    map['status'] = Variable<String>(status);
    map['position_in_status'] = Variable<int>(positionInStatus);
    if (!nullToAbsent || startAtUtc != null) {
      map['start_at_utc'] = Variable<DateTime>(startAtUtc);
    }
    if (!nullToAbsent || dueAtUtc != null) {
      map['due_at_utc'] = Variable<DateTime>(dueAtUtc);
    }
    if (!nullToAbsent || estimatedDurationMinutes != null) {
      map['estimated_duration_minutes'] = Variable<int>(
        estimatedDurationMinutes,
      );
    }
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    if (!nullToAbsent || completedAtUtc != null) {
      map['completed_at_utc'] = Variable<DateTime>(completedAtUtc);
    }
    if (!nullToAbsent || canceledAtUtc != null) {
      map['canceled_at_utc'] = Variable<DateTime>(canceledAtUtc);
    }
    return map;
  }

  TaskRowsCompanion toCompanion(bool nullToAbsent) {
    return TaskRowsCompanion(
      id: Value(id),
      displayNumber: Value(displayNumber),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      priority: Value(priority),
      status: Value(status),
      positionInStatus: Value(positionInStatus),
      startAtUtc: startAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(startAtUtc),
      dueAtUtc: dueAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAtUtc),
      estimatedDurationMinutes: estimatedDurationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedDurationMinutes),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
      completedAtUtc: completedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAtUtc),
      canceledAtUtc: canceledAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(canceledAtUtc),
    );
  }

  factory TaskRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRow(
      id: serializer.fromJson<String>(json['id']),
      displayNumber: serializer.fromJson<int>(json['displayNumber']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      priority: serializer.fromJson<int>(json['priority']),
      status: serializer.fromJson<String>(json['status']),
      positionInStatus: serializer.fromJson<int>(json['positionInStatus']),
      startAtUtc: serializer.fromJson<DateTime?>(json['startAtUtc']),
      dueAtUtc: serializer.fromJson<DateTime?>(json['dueAtUtc']),
      estimatedDurationMinutes: serializer.fromJson<int?>(
        json['estimatedDurationMinutes'],
      ),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
      completedAtUtc: serializer.fromJson<DateTime?>(json['completedAtUtc']),
      canceledAtUtc: serializer.fromJson<DateTime?>(json['canceledAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayNumber': serializer.toJson<int>(displayNumber),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'priority': serializer.toJson<int>(priority),
      'status': serializer.toJson<String>(status),
      'positionInStatus': serializer.toJson<int>(positionInStatus),
      'startAtUtc': serializer.toJson<DateTime?>(startAtUtc),
      'dueAtUtc': serializer.toJson<DateTime?>(dueAtUtc),
      'estimatedDurationMinutes': serializer.toJson<int?>(
        estimatedDurationMinutes,
      ),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
      'completedAtUtc': serializer.toJson<DateTime?>(completedAtUtc),
      'canceledAtUtc': serializer.toJson<DateTime?>(canceledAtUtc),
    };
  }

  TaskRow copyWith({
    String? id,
    int? displayNumber,
    String? title,
    Value<String?> description = const Value.absent(),
    int? priority,
    String? status,
    int? positionInStatus,
    Value<DateTime?> startAtUtc = const Value.absent(),
    Value<DateTime?> dueAtUtc = const Value.absent(),
    Value<int?> estimatedDurationMinutes = const Value.absent(),
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
    Value<DateTime?> completedAtUtc = const Value.absent(),
    Value<DateTime?> canceledAtUtc = const Value.absent(),
  }) => TaskRow(
    id: id ?? this.id,
    displayNumber: displayNumber ?? this.displayNumber,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    positionInStatus: positionInStatus ?? this.positionInStatus,
    startAtUtc: startAtUtc.present ? startAtUtc.value : this.startAtUtc,
    dueAtUtc: dueAtUtc.present ? dueAtUtc.value : this.dueAtUtc,
    estimatedDurationMinutes: estimatedDurationMinutes.present
        ? estimatedDurationMinutes.value
        : this.estimatedDurationMinutes,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    completedAtUtc: completedAtUtc.present
        ? completedAtUtc.value
        : this.completedAtUtc,
    canceledAtUtc: canceledAtUtc.present
        ? canceledAtUtc.value
        : this.canceledAtUtc,
  );
  TaskRow copyWithCompanion(TaskRowsCompanion data) {
    return TaskRow(
      id: data.id.present ? data.id.value : this.id,
      displayNumber: data.displayNumber.present
          ? data.displayNumber.value
          : this.displayNumber,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      positionInStatus: data.positionInStatus.present
          ? data.positionInStatus.value
          : this.positionInStatus,
      startAtUtc: data.startAtUtc.present
          ? data.startAtUtc.value
          : this.startAtUtc,
      dueAtUtc: data.dueAtUtc.present ? data.dueAtUtc.value : this.dueAtUtc,
      estimatedDurationMinutes: data.estimatedDurationMinutes.present
          ? data.estimatedDurationMinutes.value
          : this.estimatedDurationMinutes,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
      completedAtUtc: data.completedAtUtc.present
          ? data.completedAtUtc.value
          : this.completedAtUtc,
      canceledAtUtc: data.canceledAtUtc.present
          ? data.canceledAtUtc.value
          : this.canceledAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRow(')
          ..write('id: $id, ')
          ..write('displayNumber: $displayNumber, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('positionInStatus: $positionInStatus, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('dueAtUtc: $dueAtUtc, ')
          ..write('estimatedDurationMinutes: $estimatedDurationMinutes, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('completedAtUtc: $completedAtUtc, ')
          ..write('canceledAtUtc: $canceledAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayNumber,
    title,
    description,
    priority,
    status,
    positionInStatus,
    startAtUtc,
    dueAtUtc,
    estimatedDurationMinutes,
    createdAtUtc,
    updatedAtUtc,
    completedAtUtc,
    canceledAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRow &&
          other.id == this.id &&
          other.displayNumber == this.displayNumber &&
          other.title == this.title &&
          other.description == this.description &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.positionInStatus == this.positionInStatus &&
          other.startAtUtc == this.startAtUtc &&
          other.dueAtUtc == this.dueAtUtc &&
          other.estimatedDurationMinutes == this.estimatedDurationMinutes &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc &&
          other.completedAtUtc == this.completedAtUtc &&
          other.canceledAtUtc == this.canceledAtUtc);
}

class TaskRowsCompanion extends UpdateCompanion<TaskRow> {
  final Value<String> id;
  final Value<int> displayNumber;
  final Value<String> title;
  final Value<String?> description;
  final Value<int> priority;
  final Value<String> status;
  final Value<int> positionInStatus;
  final Value<DateTime?> startAtUtc;
  final Value<DateTime?> dueAtUtc;
  final Value<int?> estimatedDurationMinutes;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<DateTime?> completedAtUtc;
  final Value<DateTime?> canceledAtUtc;
  final Value<int> rowid;
  const TaskRowsCompanion({
    this.id = const Value.absent(),
    this.displayNumber = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.positionInStatus = const Value.absent(),
    this.startAtUtc = const Value.absent(),
    this.dueAtUtc = const Value.absent(),
    this.estimatedDurationMinutes = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.completedAtUtc = const Value.absent(),
    this.canceledAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskRowsCompanion.insert({
    required String id,
    required int displayNumber,
    required String title,
    this.description = const Value.absent(),
    required int priority,
    required String status,
    required int positionInStatus,
    this.startAtUtc = const Value.absent(),
    this.dueAtUtc = const Value.absent(),
    this.estimatedDurationMinutes = const Value.absent(),
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.completedAtUtc = const Value.absent(),
    this.canceledAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayNumber = Value(displayNumber),
       title = Value(title),
       priority = Value(priority),
       status = Value(status),
       positionInStatus = Value(positionInStatus),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<TaskRow> custom({
    Expression<String>? id,
    Expression<int>? displayNumber,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? priority,
    Expression<String>? status,
    Expression<int>? positionInStatus,
    Expression<DateTime>? startAtUtc,
    Expression<DateTime>? dueAtUtc,
    Expression<int>? estimatedDurationMinutes,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<DateTime>? completedAtUtc,
    Expression<DateTime>? canceledAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayNumber != null) 'display_number': displayNumber,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (positionInStatus != null) 'position_in_status': positionInStatus,
      if (startAtUtc != null) 'start_at_utc': startAtUtc,
      if (dueAtUtc != null) 'due_at_utc': dueAtUtc,
      if (estimatedDurationMinutes != null)
        'estimated_duration_minutes': estimatedDurationMinutes,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (completedAtUtc != null) 'completed_at_utc': completedAtUtc,
      if (canceledAtUtc != null) 'canceled_at_utc': canceledAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskRowsCompanion copyWith({
    Value<String>? id,
    Value<int>? displayNumber,
    Value<String>? title,
    Value<String?>? description,
    Value<int>? priority,
    Value<String>? status,
    Value<int>? positionInStatus,
    Value<DateTime?>? startAtUtc,
    Value<DateTime?>? dueAtUtc,
    Value<int?>? estimatedDurationMinutes,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<DateTime?>? completedAtUtc,
    Value<DateTime?>? canceledAtUtc,
    Value<int>? rowid,
  }) {
    return TaskRowsCompanion(
      id: id ?? this.id,
      displayNumber: displayNumber ?? this.displayNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      positionInStatus: positionInStatus ?? this.positionInStatus,
      startAtUtc: startAtUtc ?? this.startAtUtc,
      dueAtUtc: dueAtUtc ?? this.dueAtUtc,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      completedAtUtc: completedAtUtc ?? this.completedAtUtc,
      canceledAtUtc: canceledAtUtc ?? this.canceledAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayNumber.present) {
      map['display_number'] = Variable<int>(displayNumber.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (positionInStatus.present) {
      map['position_in_status'] = Variable<int>(positionInStatus.value);
    }
    if (startAtUtc.present) {
      map['start_at_utc'] = Variable<DateTime>(startAtUtc.value);
    }
    if (dueAtUtc.present) {
      map['due_at_utc'] = Variable<DateTime>(dueAtUtc.value);
    }
    if (estimatedDurationMinutes.present) {
      map['estimated_duration_minutes'] = Variable<int>(
        estimatedDurationMinutes.value,
      );
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (completedAtUtc.present) {
      map['completed_at_utc'] = Variable<DateTime>(completedAtUtc.value);
    }
    if (canceledAtUtc.present) {
      map['canceled_at_utc'] = Variable<DateTime>(canceledAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskRowsCompanion(')
          ..write('id: $id, ')
          ..write('displayNumber: $displayNumber, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('positionInStatus: $positionInStatus, ')
          ..write('startAtUtc: $startAtUtc, ')
          ..write('dueAtUtc: $dueAtUtc, ')
          ..write('estimatedDurationMinutes: $estimatedDurationMinutes, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('completedAtUtc: $completedAtUtc, ')
          ..write('canceledAtUtc: $canceledAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FinanceTransactionRowsTable extends FinanceTransactionRows
    with TableInfo<$FinanceTransactionRowsTable, FinanceTransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FinanceTransactionRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorUnitsMeta = const VerificationMeta(
    'amountMinorUnits',
  );
  @override
  late final GeneratedColumn<int> amountMinorUnits = GeneratedColumn<int>(
    'amount_minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('IRT'),
  );
  static const VerificationMeta _scaleMeta = const VerificationMeta('scale');
  @override
  late final GeneratedColumn<int> scale = GeneratedColumn<int>(
    'scale',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _occurredAtUtcMeta = const VerificationMeta(
    'occurredAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAtUtc =
      GeneratedColumn<DateTime>(
        'occurred_at_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    title,
    category,
    amountMinorUnits,
    currencyCode,
    scale,
    occurredAtUtc,
    createdAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'finance_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FinanceTransactionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('amount_minor_units')) {
      context.handle(
        _amountMinorUnitsMeta,
        amountMinorUnits.isAcceptableOrUnknown(
          data['amount_minor_units']!,
          _amountMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorUnitsMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('scale')) {
      context.handle(
        _scaleMeta,
        scale.isAcceptableOrUnknown(data['scale']!, _scaleMeta),
      );
    }
    if (data.containsKey('occurred_at_utc')) {
      context.handle(
        _occurredAtUtcMeta,
        occurredAtUtc.isAcceptableOrUnknown(
          data['occurred_at_utc']!,
          _occurredAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurredAtUtcMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FinanceTransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FinanceTransactionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      amountMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor_units'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      scale: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scale'],
      )!,
      occurredAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at_utc'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $FinanceTransactionRowsTable createAlias(String alias) {
    return $FinanceTransactionRowsTable(attachedDatabase, alias);
  }
}

class FinanceTransactionRow extends DataClass
    implements Insertable<FinanceTransactionRow> {
  final String id;
  final String type;
  final String title;
  final String category;
  final int amountMinorUnits;
  final String currencyCode;
  final int scale;
  final DateTime occurredAtUtc;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  const FinanceTransactionRow({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.scale,
    required this.occurredAtUtc,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    map['amount_minor_units'] = Variable<int>(amountMinorUnits);
    map['currency_code'] = Variable<String>(currencyCode);
    map['scale'] = Variable<int>(scale);
    map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  FinanceTransactionRowsCompanion toCompanion(bool nullToAbsent) {
    return FinanceTransactionRowsCompanion(
      id: Value(id),
      type: Value(type),
      title: Value(title),
      category: Value(category),
      amountMinorUnits: Value(amountMinorUnits),
      currencyCode: Value(currencyCode),
      scale: Value(scale),
      occurredAtUtc: Value(occurredAtUtc),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory FinanceTransactionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FinanceTransactionRow(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      amountMinorUnits: serializer.fromJson<int>(json['amountMinorUnits']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      scale: serializer.fromJson<int>(json['scale']),
      occurredAtUtc: serializer.fromJson<DateTime>(json['occurredAtUtc']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'amountMinorUnits': serializer.toJson<int>(amountMinorUnits),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'scale': serializer.toJson<int>(scale),
      'occurredAtUtc': serializer.toJson<DateTime>(occurredAtUtc),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  FinanceTransactionRow copyWith({
    String? id,
    String? type,
    String? title,
    String? category,
    int? amountMinorUnits,
    String? currencyCode,
    int? scale,
    DateTime? occurredAtUtc,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) => FinanceTransactionRow(
    id: id ?? this.id,
    type: type ?? this.type,
    title: title ?? this.title,
    category: category ?? this.category,
    amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
    currencyCode: currencyCode ?? this.currencyCode,
    scale: scale ?? this.scale,
    occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  FinanceTransactionRow copyWithCompanion(
    FinanceTransactionRowsCompanion data,
  ) {
    return FinanceTransactionRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      amountMinorUnits: data.amountMinorUnits.present
          ? data.amountMinorUnits.value
          : this.amountMinorUnits,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      scale: data.scale.present ? data.scale.value : this.scale,
      occurredAtUtc: data.occurredAtUtc.present
          ? data.occurredAtUtc.value
          : this.occurredAtUtc,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FinanceTransactionRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('scale: $scale, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    title,
    category,
    amountMinorUnits,
    currencyCode,
    scale,
    occurredAtUtc,
    createdAtUtc,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FinanceTransactionRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.title == this.title &&
          other.category == this.category &&
          other.amountMinorUnits == this.amountMinorUnits &&
          other.currencyCode == this.currencyCode &&
          other.scale == this.scale &&
          other.occurredAtUtc == this.occurredAtUtc &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class FinanceTransactionRowsCompanion
    extends UpdateCompanion<FinanceTransactionRow> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> title;
  final Value<String> category;
  final Value<int> amountMinorUnits;
  final Value<String> currencyCode;
  final Value<int> scale;
  final Value<DateTime> occurredAtUtc;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const FinanceTransactionRowsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.amountMinorUnits = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.scale = const Value.absent(),
    this.occurredAtUtc = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FinanceTransactionRowsCompanion.insert({
    required String id,
    required String type,
    required String title,
    required String category,
    required int amountMinorUnits,
    this.currencyCode = const Value.absent(),
    this.scale = const Value.absent(),
    required DateTime occurredAtUtc,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       title = Value(title),
       category = Value(category),
       amountMinorUnits = Value(amountMinorUnits),
       occurredAtUtc = Value(occurredAtUtc),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<FinanceTransactionRow> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? category,
    Expression<int>? amountMinorUnits,
    Expression<String>? currencyCode,
    Expression<int>? scale,
    Expression<DateTime>? occurredAtUtc,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (amountMinorUnits != null) 'amount_minor_units': amountMinorUnits,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (scale != null) 'scale': scale,
      if (occurredAtUtc != null) 'occurred_at_utc': occurredAtUtc,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FinanceTransactionRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<String>? title,
    Value<String>? category,
    Value<int>? amountMinorUnits,
    Value<String>? currencyCode,
    Value<int>? scale,
    Value<DateTime>? occurredAtUtc,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return FinanceTransactionRowsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      category: category ?? this.category,
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      currencyCode: currencyCode ?? this.currencyCode,
      scale: scale ?? this.scale,
      occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (amountMinorUnits.present) {
      map['amount_minor_units'] = Variable<int>(amountMinorUnits.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (scale.present) {
      map['scale'] = Variable<int>(scale.value);
    }
    if (occurredAtUtc.present) {
      map['occurred_at_utc'] = Variable<DateTime>(occurredAtUtc.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FinanceTransactionRowsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('scale: $scale, ')
          ..write('occurredAtUtc: $occurredAtUtc, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DebtRowsTable extends DebtRows with TableInfo<$DebtRowsTable, DebtRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DebtRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMinorUnitsMeta = const VerificationMeta(
    'totalMinorUnits',
  );
  @override
  late final GeneratedColumn<int> totalMinorUnits = GeneratedColumn<int>(
    'total_minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('IRT'),
  );
  static const VerificationMeta _scaleMeta = const VerificationMeta('scale');
  @override
  late final GeneratedColumn<int> scale = GeneratedColumn<int>(
    'scale',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtUtcMeta = const VerificationMeta(
    'archivedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAtUtc =
      GeneratedColumn<DateTime>(
        'archived_at_utc',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    totalMinorUnits,
    currencyCode,
    scale,
    createdAtUtc,
    updatedAtUtc,
    archivedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'debts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DebtRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('total_minor_units')) {
      context.handle(
        _totalMinorUnitsMeta,
        totalMinorUnits.isAcceptableOrUnknown(
          data['total_minor_units']!,
          _totalMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalMinorUnitsMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('scale')) {
      context.handle(
        _scaleMeta,
        scale.isAcceptableOrUnknown(data['scale']!, _scaleMeta),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    if (data.containsKey('archived_at_utc')) {
      context.handle(
        _archivedAtUtcMeta,
        archivedAtUtc.isAcceptableOrUnknown(
          data['archived_at_utc']!,
          _archivedAtUtcMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DebtRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DebtRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      totalMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_minor_units'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      scale: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scale'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
      archivedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at_utc'],
      ),
    );
  }

  @override
  $DebtRowsTable createAlias(String alias) {
    return $DebtRowsTable(attachedDatabase, alias);
  }
}

class DebtRow extends DataClass implements Insertable<DebtRow> {
  final String id;
  final String title;
  final int totalMinorUnits;
  final String currencyCode;
  final int scale;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final DateTime? archivedAtUtc;
  const DebtRow({
    required this.id,
    required this.title,
    required this.totalMinorUnits,
    required this.currencyCode,
    required this.scale,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.archivedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['total_minor_units'] = Variable<int>(totalMinorUnits);
    map['currency_code'] = Variable<String>(currencyCode);
    map['scale'] = Variable<int>(scale);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    if (!nullToAbsent || archivedAtUtc != null) {
      map['archived_at_utc'] = Variable<DateTime>(archivedAtUtc);
    }
    return map;
  }

  DebtRowsCompanion toCompanion(bool nullToAbsent) {
    return DebtRowsCompanion(
      id: Value(id),
      title: Value(title),
      totalMinorUnits: Value(totalMinorUnits),
      currencyCode: Value(currencyCode),
      scale: Value(scale),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
      archivedAtUtc: archivedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAtUtc),
    );
  }

  factory DebtRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DebtRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      totalMinorUnits: serializer.fromJson<int>(json['totalMinorUnits']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      scale: serializer.fromJson<int>(json['scale']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
      archivedAtUtc: serializer.fromJson<DateTime?>(json['archivedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'totalMinorUnits': serializer.toJson<int>(totalMinorUnits),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'scale': serializer.toJson<int>(scale),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
      'archivedAtUtc': serializer.toJson<DateTime?>(archivedAtUtc),
    };
  }

  DebtRow copyWith({
    String? id,
    String? title,
    int? totalMinorUnits,
    String? currencyCode,
    int? scale,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
    Value<DateTime?> archivedAtUtc = const Value.absent(),
  }) => DebtRow(
    id: id ?? this.id,
    title: title ?? this.title,
    totalMinorUnits: totalMinorUnits ?? this.totalMinorUnits,
    currencyCode: currencyCode ?? this.currencyCode,
    scale: scale ?? this.scale,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    archivedAtUtc: archivedAtUtc.present
        ? archivedAtUtc.value
        : this.archivedAtUtc,
  );
  DebtRow copyWithCompanion(DebtRowsCompanion data) {
    return DebtRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      totalMinorUnits: data.totalMinorUnits.present
          ? data.totalMinorUnits.value
          : this.totalMinorUnits,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      scale: data.scale.present ? data.scale.value : this.scale,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
      archivedAtUtc: data.archivedAtUtc.present
          ? data.archivedAtUtc.value
          : this.archivedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DebtRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('totalMinorUnits: $totalMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('scale: $scale, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('archivedAtUtc: $archivedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    totalMinorUnits,
    currencyCode,
    scale,
    createdAtUtc,
    updatedAtUtc,
    archivedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DebtRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.totalMinorUnits == this.totalMinorUnits &&
          other.currencyCode == this.currencyCode &&
          other.scale == this.scale &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc &&
          other.archivedAtUtc == this.archivedAtUtc);
}

class DebtRowsCompanion extends UpdateCompanion<DebtRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<int> totalMinorUnits;
  final Value<String> currencyCode;
  final Value<int> scale;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<DateTime?> archivedAtUtc;
  final Value<int> rowid;
  const DebtRowsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.totalMinorUnits = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.scale = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.archivedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DebtRowsCompanion.insert({
    required String id,
    required String title,
    required int totalMinorUnits,
    this.currencyCode = const Value.absent(),
    this.scale = const Value.absent(),
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.archivedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       totalMinorUnits = Value(totalMinorUnits),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<DebtRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? totalMinorUnits,
    Expression<String>? currencyCode,
    Expression<int>? scale,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<DateTime>? archivedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (totalMinorUnits != null) 'total_minor_units': totalMinorUnits,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (scale != null) 'scale': scale,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (archivedAtUtc != null) 'archived_at_utc': archivedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DebtRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<int>? totalMinorUnits,
    Value<String>? currencyCode,
    Value<int>? scale,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<DateTime?>? archivedAtUtc,
    Value<int>? rowid,
  }) {
    return DebtRowsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      totalMinorUnits: totalMinorUnits ?? this.totalMinorUnits,
      currencyCode: currencyCode ?? this.currencyCode,
      scale: scale ?? this.scale,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      archivedAtUtc: archivedAtUtc ?? this.archivedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (totalMinorUnits.present) {
      map['total_minor_units'] = Variable<int>(totalMinorUnits.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (scale.present) {
      map['scale'] = Variable<int>(scale.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (archivedAtUtc.present) {
      map['archived_at_utc'] = Variable<DateTime>(archivedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DebtRowsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('totalMinorUnits: $totalMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('scale: $scale, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('archivedAtUtc: $archivedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DebtPaymentRowsTable extends DebtPaymentRows
    with TableInfo<$DebtPaymentRowsTable, DebtPaymentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DebtPaymentRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _debtIdMeta = const VerificationMeta('debtId');
  @override
  late final GeneratedColumn<String> debtId = GeneratedColumn<String>(
    'debt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES debts (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _amountMinorUnitsMeta = const VerificationMeta(
    'amountMinorUnits',
  );
  @override
  late final GeneratedColumn<int> amountMinorUnits = GeneratedColumn<int>(
    'amount_minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidAtUtcMeta = const VerificationMeta(
    'paidAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> paidAtUtc = GeneratedColumn<DateTime>(
    'paid_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    debtId,
    amountMinorUnits,
    paidAtUtc,
    createdAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'debt_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<DebtPaymentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('debt_id')) {
      context.handle(
        _debtIdMeta,
        debtId.isAcceptableOrUnknown(data['debt_id']!, _debtIdMeta),
      );
    } else if (isInserting) {
      context.missing(_debtIdMeta);
    }
    if (data.containsKey('amount_minor_units')) {
      context.handle(
        _amountMinorUnitsMeta,
        amountMinorUnits.isAcceptableOrUnknown(
          data['amount_minor_units']!,
          _amountMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorUnitsMeta);
    }
    if (data.containsKey('paid_at_utc')) {
      context.handle(
        _paidAtUtcMeta,
        paidAtUtc.isAcceptableOrUnknown(data['paid_at_utc']!, _paidAtUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_paidAtUtcMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DebtPaymentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DebtPaymentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      debtId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}debt_id'],
      )!,
      amountMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor_units'],
      )!,
      paidAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paid_at_utc'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
    );
  }

  @override
  $DebtPaymentRowsTable createAlias(String alias) {
    return $DebtPaymentRowsTable(attachedDatabase, alias);
  }
}

class DebtPaymentRow extends DataClass implements Insertable<DebtPaymentRow> {
  final String id;
  final String debtId;
  final int amountMinorUnits;
  final DateTime paidAtUtc;
  final DateTime createdAtUtc;
  const DebtPaymentRow({
    required this.id,
    required this.debtId,
    required this.amountMinorUnits,
    required this.paidAtUtc,
    required this.createdAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['debt_id'] = Variable<String>(debtId);
    map['amount_minor_units'] = Variable<int>(amountMinorUnits);
    map['paid_at_utc'] = Variable<DateTime>(paidAtUtc);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    return map;
  }

  DebtPaymentRowsCompanion toCompanion(bool nullToAbsent) {
    return DebtPaymentRowsCompanion(
      id: Value(id),
      debtId: Value(debtId),
      amountMinorUnits: Value(amountMinorUnits),
      paidAtUtc: Value(paidAtUtc),
      createdAtUtc: Value(createdAtUtc),
    );
  }

  factory DebtPaymentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DebtPaymentRow(
      id: serializer.fromJson<String>(json['id']),
      debtId: serializer.fromJson<String>(json['debtId']),
      amountMinorUnits: serializer.fromJson<int>(json['amountMinorUnits']),
      paidAtUtc: serializer.fromJson<DateTime>(json['paidAtUtc']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'debtId': serializer.toJson<String>(debtId),
      'amountMinorUnits': serializer.toJson<int>(amountMinorUnits),
      'paidAtUtc': serializer.toJson<DateTime>(paidAtUtc),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
    };
  }

  DebtPaymentRow copyWith({
    String? id,
    String? debtId,
    int? amountMinorUnits,
    DateTime? paidAtUtc,
    DateTime? createdAtUtc,
  }) => DebtPaymentRow(
    id: id ?? this.id,
    debtId: debtId ?? this.debtId,
    amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
    paidAtUtc: paidAtUtc ?? this.paidAtUtc,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
  );
  DebtPaymentRow copyWithCompanion(DebtPaymentRowsCompanion data) {
    return DebtPaymentRow(
      id: data.id.present ? data.id.value : this.id,
      debtId: data.debtId.present ? data.debtId.value : this.debtId,
      amountMinorUnits: data.amountMinorUnits.present
          ? data.amountMinorUnits.value
          : this.amountMinorUnits,
      paidAtUtc: data.paidAtUtc.present ? data.paidAtUtc.value : this.paidAtUtc,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DebtPaymentRow(')
          ..write('id: $id, ')
          ..write('debtId: $debtId, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('paidAtUtc: $paidAtUtc, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, debtId, amountMinorUnits, paidAtUtc, createdAtUtc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DebtPaymentRow &&
          other.id == this.id &&
          other.debtId == this.debtId &&
          other.amountMinorUnits == this.amountMinorUnits &&
          other.paidAtUtc == this.paidAtUtc &&
          other.createdAtUtc == this.createdAtUtc);
}

class DebtPaymentRowsCompanion extends UpdateCompanion<DebtPaymentRow> {
  final Value<String> id;
  final Value<String> debtId;
  final Value<int> amountMinorUnits;
  final Value<DateTime> paidAtUtc;
  final Value<DateTime> createdAtUtc;
  final Value<int> rowid;
  const DebtPaymentRowsCompanion({
    this.id = const Value.absent(),
    this.debtId = const Value.absent(),
    this.amountMinorUnits = const Value.absent(),
    this.paidAtUtc = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DebtPaymentRowsCompanion.insert({
    required String id,
    required String debtId,
    required int amountMinorUnits,
    required DateTime paidAtUtc,
    required DateTime createdAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       debtId = Value(debtId),
       amountMinorUnits = Value(amountMinorUnits),
       paidAtUtc = Value(paidAtUtc),
       createdAtUtc = Value(createdAtUtc);
  static Insertable<DebtPaymentRow> custom({
    Expression<String>? id,
    Expression<String>? debtId,
    Expression<int>? amountMinorUnits,
    Expression<DateTime>? paidAtUtc,
    Expression<DateTime>? createdAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (debtId != null) 'debt_id': debtId,
      if (amountMinorUnits != null) 'amount_minor_units': amountMinorUnits,
      if (paidAtUtc != null) 'paid_at_utc': paidAtUtc,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DebtPaymentRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? debtId,
    Value<int>? amountMinorUnits,
    Value<DateTime>? paidAtUtc,
    Value<DateTime>? createdAtUtc,
    Value<int>? rowid,
  }) {
    return DebtPaymentRowsCompanion(
      id: id ?? this.id,
      debtId: debtId ?? this.debtId,
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      paidAtUtc: paidAtUtc ?? this.paidAtUtc,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (debtId.present) {
      map['debt_id'] = Variable<String>(debtId.value);
    }
    if (amountMinorUnits.present) {
      map['amount_minor_units'] = Variable<int>(amountMinorUnits.value);
    }
    if (paidAtUtc.present) {
      map['paid_at_utc'] = Variable<DateTime>(paidAtUtc.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DebtPaymentRowsCompanion(')
          ..write('id: $id, ')
          ..write('debtId: $debtId, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('paidAtUtc: $paidAtUtc, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstallmentPlanRowsTable extends InstallmentPlanRows
    with TableInfo<$InstallmentPlanRowsTable, InstallmentPlanRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstallmentPlanRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _perInstallmentMinorUnitsMeta =
      const VerificationMeta('perInstallmentMinorUnits');
  @override
  late final GeneratedColumn<int> perInstallmentMinorUnits =
      GeneratedColumn<int>(
        'per_installment_minor_units',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _installmentCountMeta = const VerificationMeta(
    'installmentCount',
  );
  @override
  late final GeneratedColumn<int> installmentCount = GeneratedColumn<int>(
    'installment_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('IRT'),
  );
  static const VerificationMeta _scaleMeta = const VerificationMeta('scale');
  @override
  late final GeneratedColumn<int> scale = GeneratedColumn<int>(
    'scale',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtUtcMeta = const VerificationMeta(
    'archivedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAtUtc =
      GeneratedColumn<DateTime>(
        'archived_at_utc',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    perInstallmentMinorUnits,
    installmentCount,
    currencyCode,
    scale,
    createdAtUtc,
    updatedAtUtc,
    archivedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installment_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstallmentPlanRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('per_installment_minor_units')) {
      context.handle(
        _perInstallmentMinorUnitsMeta,
        perInstallmentMinorUnits.isAcceptableOrUnknown(
          data['per_installment_minor_units']!,
          _perInstallmentMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_perInstallmentMinorUnitsMeta);
    }
    if (data.containsKey('installment_count')) {
      context.handle(
        _installmentCountMeta,
        installmentCount.isAcceptableOrUnknown(
          data['installment_count']!,
          _installmentCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installmentCountMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('scale')) {
      context.handle(
        _scaleMeta,
        scale.isAcceptableOrUnknown(data['scale']!, _scaleMeta),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    if (data.containsKey('archived_at_utc')) {
      context.handle(
        _archivedAtUtcMeta,
        archivedAtUtc.isAcceptableOrUnknown(
          data['archived_at_utc']!,
          _archivedAtUtcMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InstallmentPlanRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstallmentPlanRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      perInstallmentMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}per_installment_minor_units'],
      )!,
      installmentCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installment_count'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      scale: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scale'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
      archivedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at_utc'],
      ),
    );
  }

  @override
  $InstallmentPlanRowsTable createAlias(String alias) {
    return $InstallmentPlanRowsTable(attachedDatabase, alias);
  }
}

class InstallmentPlanRow extends DataClass
    implements Insertable<InstallmentPlanRow> {
  final String id;
  final String title;
  final int perInstallmentMinorUnits;
  final int installmentCount;
  final String currencyCode;
  final int scale;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final DateTime? archivedAtUtc;
  const InstallmentPlanRow({
    required this.id,
    required this.title,
    required this.perInstallmentMinorUnits,
    required this.installmentCount,
    required this.currencyCode,
    required this.scale,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    this.archivedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['per_installment_minor_units'] = Variable<int>(
      perInstallmentMinorUnits,
    );
    map['installment_count'] = Variable<int>(installmentCount);
    map['currency_code'] = Variable<String>(currencyCode);
    map['scale'] = Variable<int>(scale);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    if (!nullToAbsent || archivedAtUtc != null) {
      map['archived_at_utc'] = Variable<DateTime>(archivedAtUtc);
    }
    return map;
  }

  InstallmentPlanRowsCompanion toCompanion(bool nullToAbsent) {
    return InstallmentPlanRowsCompanion(
      id: Value(id),
      title: Value(title),
      perInstallmentMinorUnits: Value(perInstallmentMinorUnits),
      installmentCount: Value(installmentCount),
      currencyCode: Value(currencyCode),
      scale: Value(scale),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
      archivedAtUtc: archivedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAtUtc),
    );
  }

  factory InstallmentPlanRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstallmentPlanRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      perInstallmentMinorUnits: serializer.fromJson<int>(
        json['perInstallmentMinorUnits'],
      ),
      installmentCount: serializer.fromJson<int>(json['installmentCount']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      scale: serializer.fromJson<int>(json['scale']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
      archivedAtUtc: serializer.fromJson<DateTime?>(json['archivedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'perInstallmentMinorUnits': serializer.toJson<int>(
        perInstallmentMinorUnits,
      ),
      'installmentCount': serializer.toJson<int>(installmentCount),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'scale': serializer.toJson<int>(scale),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
      'archivedAtUtc': serializer.toJson<DateTime?>(archivedAtUtc),
    };
  }

  InstallmentPlanRow copyWith({
    String? id,
    String? title,
    int? perInstallmentMinorUnits,
    int? installmentCount,
    String? currencyCode,
    int? scale,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
    Value<DateTime?> archivedAtUtc = const Value.absent(),
  }) => InstallmentPlanRow(
    id: id ?? this.id,
    title: title ?? this.title,
    perInstallmentMinorUnits:
        perInstallmentMinorUnits ?? this.perInstallmentMinorUnits,
    installmentCount: installmentCount ?? this.installmentCount,
    currencyCode: currencyCode ?? this.currencyCode,
    scale: scale ?? this.scale,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    archivedAtUtc: archivedAtUtc.present
        ? archivedAtUtc.value
        : this.archivedAtUtc,
  );
  InstallmentPlanRow copyWithCompanion(InstallmentPlanRowsCompanion data) {
    return InstallmentPlanRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      perInstallmentMinorUnits: data.perInstallmentMinorUnits.present
          ? data.perInstallmentMinorUnits.value
          : this.perInstallmentMinorUnits,
      installmentCount: data.installmentCount.present
          ? data.installmentCount.value
          : this.installmentCount,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      scale: data.scale.present ? data.scale.value : this.scale,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
      archivedAtUtc: data.archivedAtUtc.present
          ? data.archivedAtUtc.value
          : this.archivedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstallmentPlanRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('perInstallmentMinorUnits: $perInstallmentMinorUnits, ')
          ..write('installmentCount: $installmentCount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('scale: $scale, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('archivedAtUtc: $archivedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    perInstallmentMinorUnits,
    installmentCount,
    currencyCode,
    scale,
    createdAtUtc,
    updatedAtUtc,
    archivedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstallmentPlanRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.perInstallmentMinorUnits == this.perInstallmentMinorUnits &&
          other.installmentCount == this.installmentCount &&
          other.currencyCode == this.currencyCode &&
          other.scale == this.scale &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc &&
          other.archivedAtUtc == this.archivedAtUtc);
}

class InstallmentPlanRowsCompanion extends UpdateCompanion<InstallmentPlanRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<int> perInstallmentMinorUnits;
  final Value<int> installmentCount;
  final Value<String> currencyCode;
  final Value<int> scale;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<DateTime?> archivedAtUtc;
  final Value<int> rowid;
  const InstallmentPlanRowsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.perInstallmentMinorUnits = const Value.absent(),
    this.installmentCount = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.scale = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.archivedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstallmentPlanRowsCompanion.insert({
    required String id,
    required String title,
    required int perInstallmentMinorUnits,
    required int installmentCount,
    this.currencyCode = const Value.absent(),
    this.scale = const Value.absent(),
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.archivedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       perInstallmentMinorUnits = Value(perInstallmentMinorUnits),
       installmentCount = Value(installmentCount),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<InstallmentPlanRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? perInstallmentMinorUnits,
    Expression<int>? installmentCount,
    Expression<String>? currencyCode,
    Expression<int>? scale,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<DateTime>? archivedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (perInstallmentMinorUnits != null)
        'per_installment_minor_units': perInstallmentMinorUnits,
      if (installmentCount != null) 'installment_count': installmentCount,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (scale != null) 'scale': scale,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (archivedAtUtc != null) 'archived_at_utc': archivedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstallmentPlanRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<int>? perInstallmentMinorUnits,
    Value<int>? installmentCount,
    Value<String>? currencyCode,
    Value<int>? scale,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<DateTime?>? archivedAtUtc,
    Value<int>? rowid,
  }) {
    return InstallmentPlanRowsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      perInstallmentMinorUnits:
          perInstallmentMinorUnits ?? this.perInstallmentMinorUnits,
      installmentCount: installmentCount ?? this.installmentCount,
      currencyCode: currencyCode ?? this.currencyCode,
      scale: scale ?? this.scale,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      archivedAtUtc: archivedAtUtc ?? this.archivedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (perInstallmentMinorUnits.present) {
      map['per_installment_minor_units'] = Variable<int>(
        perInstallmentMinorUnits.value,
      );
    }
    if (installmentCount.present) {
      map['installment_count'] = Variable<int>(installmentCount.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (scale.present) {
      map['scale'] = Variable<int>(scale.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (archivedAtUtc.present) {
      map['archived_at_utc'] = Variable<DateTime>(archivedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstallmentPlanRowsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('perInstallmentMinorUnits: $perInstallmentMinorUnits, ')
          ..write('installmentCount: $installmentCount, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('scale: $scale, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('archivedAtUtc: $archivedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InstallmentPaymentRowsTable extends InstallmentPaymentRows
    with TableInfo<$InstallmentPaymentRowsTable, InstallmentPaymentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstallmentPaymentRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES installment_plans (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _installmentNumberMeta = const VerificationMeta(
    'installmentNumber',
  );
  @override
  late final GeneratedColumn<int> installmentNumber = GeneratedColumn<int>(
    'installment_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorUnitsMeta = const VerificationMeta(
    'amountMinorUnits',
  );
  @override
  late final GeneratedColumn<int> amountMinorUnits = GeneratedColumn<int>(
    'amount_minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidAtUtcMeta = const VerificationMeta(
    'paidAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> paidAtUtc = GeneratedColumn<DateTime>(
    'paid_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    installmentNumber,
    amountMinorUnits,
    paidAtUtc,
    createdAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'installment_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<InstallmentPaymentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('installment_number')) {
      context.handle(
        _installmentNumberMeta,
        installmentNumber.isAcceptableOrUnknown(
          data['installment_number']!,
          _installmentNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installmentNumberMeta);
    }
    if (data.containsKey('amount_minor_units')) {
      context.handle(
        _amountMinorUnitsMeta,
        amountMinorUnits.isAcceptableOrUnknown(
          data['amount_minor_units']!,
          _amountMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorUnitsMeta);
    }
    if (data.containsKey('paid_at_utc')) {
      context.handle(
        _paidAtUtcMeta,
        paidAtUtc.isAcceptableOrUnknown(data['paid_at_utc']!, _paidAtUtcMeta),
      );
    } else if (isInserting) {
      context.missing(_paidAtUtcMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {planId, installmentNumber},
  ];
  @override
  InstallmentPaymentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InstallmentPaymentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      installmentNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installment_number'],
      )!,
      amountMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor_units'],
      )!,
      paidAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paid_at_utc'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
    );
  }

  @override
  $InstallmentPaymentRowsTable createAlias(String alias) {
    return $InstallmentPaymentRowsTable(attachedDatabase, alias);
  }
}

class InstallmentPaymentRow extends DataClass
    implements Insertable<InstallmentPaymentRow> {
  final String id;
  final String planId;
  final int installmentNumber;
  final int amountMinorUnits;
  final DateTime paidAtUtc;
  final DateTime createdAtUtc;
  const InstallmentPaymentRow({
    required this.id,
    required this.planId,
    required this.installmentNumber,
    required this.amountMinorUnits,
    required this.paidAtUtc,
    required this.createdAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_id'] = Variable<String>(planId);
    map['installment_number'] = Variable<int>(installmentNumber);
    map['amount_minor_units'] = Variable<int>(amountMinorUnits);
    map['paid_at_utc'] = Variable<DateTime>(paidAtUtc);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    return map;
  }

  InstallmentPaymentRowsCompanion toCompanion(bool nullToAbsent) {
    return InstallmentPaymentRowsCompanion(
      id: Value(id),
      planId: Value(planId),
      installmentNumber: Value(installmentNumber),
      amountMinorUnits: Value(amountMinorUnits),
      paidAtUtc: Value(paidAtUtc),
      createdAtUtc: Value(createdAtUtc),
    );
  }

  factory InstallmentPaymentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InstallmentPaymentRow(
      id: serializer.fromJson<String>(json['id']),
      planId: serializer.fromJson<String>(json['planId']),
      installmentNumber: serializer.fromJson<int>(json['installmentNumber']),
      amountMinorUnits: serializer.fromJson<int>(json['amountMinorUnits']),
      paidAtUtc: serializer.fromJson<DateTime>(json['paidAtUtc']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planId': serializer.toJson<String>(planId),
      'installmentNumber': serializer.toJson<int>(installmentNumber),
      'amountMinorUnits': serializer.toJson<int>(amountMinorUnits),
      'paidAtUtc': serializer.toJson<DateTime>(paidAtUtc),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
    };
  }

  InstallmentPaymentRow copyWith({
    String? id,
    String? planId,
    int? installmentNumber,
    int? amountMinorUnits,
    DateTime? paidAtUtc,
    DateTime? createdAtUtc,
  }) => InstallmentPaymentRow(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    installmentNumber: installmentNumber ?? this.installmentNumber,
    amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
    paidAtUtc: paidAtUtc ?? this.paidAtUtc,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
  );
  InstallmentPaymentRow copyWithCompanion(
    InstallmentPaymentRowsCompanion data,
  ) {
    return InstallmentPaymentRow(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      installmentNumber: data.installmentNumber.present
          ? data.installmentNumber.value
          : this.installmentNumber,
      amountMinorUnits: data.amountMinorUnits.present
          ? data.amountMinorUnits.value
          : this.amountMinorUnits,
      paidAtUtc: data.paidAtUtc.present ? data.paidAtUtc.value : this.paidAtUtc,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InstallmentPaymentRow(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('installmentNumber: $installmentNumber, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('paidAtUtc: $paidAtUtc, ')
          ..write('createdAtUtc: $createdAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planId,
    installmentNumber,
    amountMinorUnits,
    paidAtUtc,
    createdAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InstallmentPaymentRow &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.installmentNumber == this.installmentNumber &&
          other.amountMinorUnits == this.amountMinorUnits &&
          other.paidAtUtc == this.paidAtUtc &&
          other.createdAtUtc == this.createdAtUtc);
}

class InstallmentPaymentRowsCompanion
    extends UpdateCompanion<InstallmentPaymentRow> {
  final Value<String> id;
  final Value<String> planId;
  final Value<int> installmentNumber;
  final Value<int> amountMinorUnits;
  final Value<DateTime> paidAtUtc;
  final Value<DateTime> createdAtUtc;
  final Value<int> rowid;
  const InstallmentPaymentRowsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.installmentNumber = const Value.absent(),
    this.amountMinorUnits = const Value.absent(),
    this.paidAtUtc = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstallmentPaymentRowsCompanion.insert({
    required String id,
    required String planId,
    required int installmentNumber,
    required int amountMinorUnits,
    required DateTime paidAtUtc,
    required DateTime createdAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       planId = Value(planId),
       installmentNumber = Value(installmentNumber),
       amountMinorUnits = Value(amountMinorUnits),
       paidAtUtc = Value(paidAtUtc),
       createdAtUtc = Value(createdAtUtc);
  static Insertable<InstallmentPaymentRow> custom({
    Expression<String>? id,
    Expression<String>? planId,
    Expression<int>? installmentNumber,
    Expression<int>? amountMinorUnits,
    Expression<DateTime>? paidAtUtc,
    Expression<DateTime>? createdAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (installmentNumber != null) 'installment_number': installmentNumber,
      if (amountMinorUnits != null) 'amount_minor_units': amountMinorUnits,
      if (paidAtUtc != null) 'paid_at_utc': paidAtUtc,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstallmentPaymentRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? planId,
    Value<int>? installmentNumber,
    Value<int>? amountMinorUnits,
    Value<DateTime>? paidAtUtc,
    Value<DateTime>? createdAtUtc,
    Value<int>? rowid,
  }) {
    return InstallmentPaymentRowsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      paidAtUtc: paidAtUtc ?? this.paidAtUtc,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (installmentNumber.present) {
      map['installment_number'] = Variable<int>(installmentNumber.value);
    }
    if (amountMinorUnits.present) {
      map['amount_minor_units'] = Variable<int>(amountMinorUnits.value);
    }
    if (paidAtUtc.present) {
      map['paid_at_utc'] = Variable<DateTime>(paidAtUtc.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstallmentPaymentRowsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('installmentNumber: $installmentNumber, ')
          ..write('amountMinorUnits: $amountMinorUnits, ')
          ..write('paidAtUtc: $paidAtUtc, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskReminderRuleRowsTable extends TaskReminderRuleRows
    with TableInfo<$TaskReminderRuleRowsTable, TaskReminderRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskReminderRuleRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _triggerMeta = const VerificationMeta(
    'trigger',
  );
  @override
  late final GeneratedColumn<String> trigger = GeneratedColumn<String>(
    'trigger',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _privacyModeMeta = const VerificationMeta(
    'privacyMode',
  );
  @override
  late final GeneratedColumn<String> privacyMode = GeneratedColumn<String>(
    'privacy_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('full'),
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    trigger,
    enabled,
    privacyMode,
    createdAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_reminder_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskReminderRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('trigger')) {
      context.handle(
        _triggerMeta,
        trigger.isAcceptableOrUnknown(data['trigger']!, _triggerMeta),
      );
    } else if (isInserting) {
      context.missing(_triggerMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('privacy_mode')) {
      context.handle(
        _privacyModeMeta,
        privacyMode.isAcceptableOrUnknown(
          data['privacy_mode']!,
          _privacyModeMeta,
        ),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {taskId, trigger},
  ];
  @override
  TaskReminderRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskReminderRuleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      trigger: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trigger'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      privacyMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}privacy_mode'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $TaskReminderRuleRowsTable createAlias(String alias) {
    return $TaskReminderRuleRowsTable(attachedDatabase, alias);
  }
}

class TaskReminderRuleRow extends DataClass
    implements Insertable<TaskReminderRuleRow> {
  final String id;
  final String taskId;
  final String trigger;
  final bool enabled;
  final String privacyMode;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  const TaskReminderRuleRow({
    required this.id,
    required this.taskId,
    required this.trigger,
    required this.enabled,
    required this.privacyMode,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['trigger'] = Variable<String>(trigger);
    map['enabled'] = Variable<bool>(enabled);
    map['privacy_mode'] = Variable<String>(privacyMode);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  TaskReminderRuleRowsCompanion toCompanion(bool nullToAbsent) {
    return TaskReminderRuleRowsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      trigger: Value(trigger),
      enabled: Value(enabled),
      privacyMode: Value(privacyMode),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory TaskReminderRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskReminderRuleRow(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      trigger: serializer.fromJson<String>(json['trigger']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      privacyMode: serializer.fromJson<String>(json['privacyMode']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'trigger': serializer.toJson<String>(trigger),
      'enabled': serializer.toJson<bool>(enabled),
      'privacyMode': serializer.toJson<String>(privacyMode),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  TaskReminderRuleRow copyWith({
    String? id,
    String? taskId,
    String? trigger,
    bool? enabled,
    String? privacyMode,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) => TaskReminderRuleRow(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    trigger: trigger ?? this.trigger,
    enabled: enabled ?? this.enabled,
    privacyMode: privacyMode ?? this.privacyMode,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  TaskReminderRuleRow copyWithCompanion(TaskReminderRuleRowsCompanion data) {
    return TaskReminderRuleRow(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      trigger: data.trigger.present ? data.trigger.value : this.trigger,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      privacyMode: data.privacyMode.present
          ? data.privacyMode.value
          : this.privacyMode,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskReminderRuleRow(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('trigger: $trigger, ')
          ..write('enabled: $enabled, ')
          ..write('privacyMode: $privacyMode, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    trigger,
    enabled,
    privacyMode,
    createdAtUtc,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskReminderRuleRow &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.trigger == this.trigger &&
          other.enabled == this.enabled &&
          other.privacyMode == this.privacyMode &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class TaskReminderRuleRowsCompanion
    extends UpdateCompanion<TaskReminderRuleRow> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<String> trigger;
  final Value<bool> enabled;
  final Value<String> privacyMode;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const TaskReminderRuleRowsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.trigger = const Value.absent(),
    this.enabled = const Value.absent(),
    this.privacyMode = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskReminderRuleRowsCompanion.insert({
    required String id,
    required String taskId,
    required String trigger,
    this.enabled = const Value.absent(),
    this.privacyMode = const Value.absent(),
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       trigger = Value(trigger),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<TaskReminderRuleRow> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? trigger,
    Expression<bool>? enabled,
    Expression<String>? privacyMode,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (trigger != null) 'trigger': trigger,
      if (enabled != null) 'enabled': enabled,
      if (privacyMode != null) 'privacy_mode': privacyMode,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskReminderRuleRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<String>? trigger,
    Value<bool>? enabled,
    Value<String>? privacyMode,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return TaskReminderRuleRowsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      trigger: trigger ?? this.trigger,
      enabled: enabled ?? this.enabled,
      privacyMode: privacyMode ?? this.privacyMode,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (trigger.present) {
      map['trigger'] = Variable<String>(trigger.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (privacyMode.present) {
      map['privacy_mode'] = Variable<String>(privacyMode.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskReminderRuleRowsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('trigger: $trigger, ')
          ..write('enabled: $enabled, ')
          ..write('privacyMode: $privacyMode, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskRecurrenceRuleRowsTable extends TaskRecurrenceRuleRows
    with TableInfo<$TaskRecurrenceRuleRowsTable, TaskRecurrenceRuleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskRecurrenceRuleRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _ruleJsonMeta = const VerificationMeta(
    'ruleJson',
  );
  @override
  late final GeneratedColumn<String> ruleJson = GeneratedColumn<String>(
    'rule_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    ruleJson,
    createdAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_recurrence_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRecurrenceRuleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('rule_json')) {
      context.handle(
        _ruleJsonMeta,
        ruleJson.isAcceptableOrUnknown(data['rule_json']!, _ruleJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleJsonMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskRecurrenceRuleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRecurrenceRuleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      ruleJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_json'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $TaskRecurrenceRuleRowsTable createAlias(String alias) {
    return $TaskRecurrenceRuleRowsTable(attachedDatabase, alias);
  }
}

class TaskRecurrenceRuleRow extends DataClass
    implements Insertable<TaskRecurrenceRuleRow> {
  final String id;
  final String taskId;
  final String ruleJson;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  const TaskRecurrenceRuleRow({
    required this.id,
    required this.taskId,
    required this.ruleJson,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['rule_json'] = Variable<String>(ruleJson);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  TaskRecurrenceRuleRowsCompanion toCompanion(bool nullToAbsent) {
    return TaskRecurrenceRuleRowsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      ruleJson: Value(ruleJson),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory TaskRecurrenceRuleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRecurrenceRuleRow(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      ruleJson: serializer.fromJson<String>(json['ruleJson']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'ruleJson': serializer.toJson<String>(ruleJson),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  TaskRecurrenceRuleRow copyWith({
    String? id,
    String? taskId,
    String? ruleJson,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) => TaskRecurrenceRuleRow(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    ruleJson: ruleJson ?? this.ruleJson,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  TaskRecurrenceRuleRow copyWithCompanion(
    TaskRecurrenceRuleRowsCompanion data,
  ) {
    return TaskRecurrenceRuleRow(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      ruleJson: data.ruleJson.present ? data.ruleJson.value : this.ruleJson,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRecurrenceRuleRow(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('ruleJson: $ruleJson, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, taskId, ruleJson, createdAtUtc, updatedAtUtc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRecurrenceRuleRow &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.ruleJson == this.ruleJson &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class TaskRecurrenceRuleRowsCompanion
    extends UpdateCompanion<TaskRecurrenceRuleRow> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<String> ruleJson;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const TaskRecurrenceRuleRowsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.ruleJson = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskRecurrenceRuleRowsCompanion.insert({
    required String id,
    required String taskId,
    required String ruleJson,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       ruleJson = Value(ruleJson),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<TaskRecurrenceRuleRow> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? ruleJson,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (ruleJson != null) 'rule_json': ruleJson,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskRecurrenceRuleRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<String>? ruleJson,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return TaskRecurrenceRuleRowsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      ruleJson: ruleJson ?? this.ruleJson,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (ruleJson.present) {
      map['rule_json'] = Variable<String>(ruleJson.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskRecurrenceRuleRowsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('ruleJson: $ruleJson, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskRecurrenceExceptionRowsTable extends TaskRecurrenceExceptionRows
    with
        TableInfo<
          $TaskRecurrenceExceptionRowsTable,
          TaskRecurrenceExceptionRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskRecurrenceExceptionRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _originalLocalKeyMeta = const VerificationMeta(
    'originalLocalKey',
  );
  @override
  late final GeneratedColumn<String> originalLocalKey = GeneratedColumn<String>(
    'original_local_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exceptionJsonMeta = const VerificationMeta(
    'exceptionJson',
  );
  @override
  late final GeneratedColumn<String> exceptionJson = GeneratedColumn<String>(
    'exception_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    originalLocalKey,
    exceptionJson,
    createdAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_recurrence_exceptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRecurrenceExceptionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('original_local_key')) {
      context.handle(
        _originalLocalKeyMeta,
        originalLocalKey.isAcceptableOrUnknown(
          data['original_local_key']!,
          _originalLocalKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalLocalKeyMeta);
    }
    if (data.containsKey('exception_json')) {
      context.handle(
        _exceptionJsonMeta,
        exceptionJson.isAcceptableOrUnknown(
          data['exception_json']!,
          _exceptionJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exceptionJsonMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {taskId, originalLocalKey},
  ];
  @override
  TaskRecurrenceExceptionRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRecurrenceExceptionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      originalLocalKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_local_key'],
      )!,
      exceptionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exception_json'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $TaskRecurrenceExceptionRowsTable createAlias(String alias) {
    return $TaskRecurrenceExceptionRowsTable(attachedDatabase, alias);
  }
}

class TaskRecurrenceExceptionRow extends DataClass
    implements Insertable<TaskRecurrenceExceptionRow> {
  final String id;
  final String taskId;
  final String originalLocalKey;
  final String exceptionJson;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  const TaskRecurrenceExceptionRow({
    required this.id,
    required this.taskId,
    required this.originalLocalKey,
    required this.exceptionJson,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['original_local_key'] = Variable<String>(originalLocalKey);
    map['exception_json'] = Variable<String>(exceptionJson);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  TaskRecurrenceExceptionRowsCompanion toCompanion(bool nullToAbsent) {
    return TaskRecurrenceExceptionRowsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      originalLocalKey: Value(originalLocalKey),
      exceptionJson: Value(exceptionJson),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory TaskRecurrenceExceptionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRecurrenceExceptionRow(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      originalLocalKey: serializer.fromJson<String>(json['originalLocalKey']),
      exceptionJson: serializer.fromJson<String>(json['exceptionJson']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'originalLocalKey': serializer.toJson<String>(originalLocalKey),
      'exceptionJson': serializer.toJson<String>(exceptionJson),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  TaskRecurrenceExceptionRow copyWith({
    String? id,
    String? taskId,
    String? originalLocalKey,
    String? exceptionJson,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) => TaskRecurrenceExceptionRow(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    originalLocalKey: originalLocalKey ?? this.originalLocalKey,
    exceptionJson: exceptionJson ?? this.exceptionJson,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  TaskRecurrenceExceptionRow copyWithCompanion(
    TaskRecurrenceExceptionRowsCompanion data,
  ) {
    return TaskRecurrenceExceptionRow(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      originalLocalKey: data.originalLocalKey.present
          ? data.originalLocalKey.value
          : this.originalLocalKey,
      exceptionJson: data.exceptionJson.present
          ? data.exceptionJson.value
          : this.exceptionJson,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRecurrenceExceptionRow(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('originalLocalKey: $originalLocalKey, ')
          ..write('exceptionJson: $exceptionJson, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    originalLocalKey,
    exceptionJson,
    createdAtUtc,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRecurrenceExceptionRow &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.originalLocalKey == this.originalLocalKey &&
          other.exceptionJson == this.exceptionJson &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class TaskRecurrenceExceptionRowsCompanion
    extends UpdateCompanion<TaskRecurrenceExceptionRow> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<String> originalLocalKey;
  final Value<String> exceptionJson;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const TaskRecurrenceExceptionRowsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.originalLocalKey = const Value.absent(),
    this.exceptionJson = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskRecurrenceExceptionRowsCompanion.insert({
    required String id,
    required String taskId,
    required String originalLocalKey,
    required String exceptionJson,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       originalLocalKey = Value(originalLocalKey),
       exceptionJson = Value(exceptionJson),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<TaskRecurrenceExceptionRow> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? originalLocalKey,
    Expression<String>? exceptionJson,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (originalLocalKey != null) 'original_local_key': originalLocalKey,
      if (exceptionJson != null) 'exception_json': exceptionJson,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskRecurrenceExceptionRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<String>? originalLocalKey,
    Value<String>? exceptionJson,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return TaskRecurrenceExceptionRowsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      originalLocalKey: originalLocalKey ?? this.originalLocalKey,
      exceptionJson: exceptionJson ?? this.exceptionJson,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (originalLocalKey.present) {
      map['original_local_key'] = Variable<String>(originalLocalKey.value);
    }
    if (exceptionJson.present) {
      map['exception_json'] = Variable<String>(exceptionJson.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskRecurrenceExceptionRowsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('originalLocalKey: $originalLocalKey, ')
          ..write('exceptionJson: $exceptionJson, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskOccurrenceCompletionRowsTable extends TaskOccurrenceCompletionRows
    with
        TableInfo<
          $TaskOccurrenceCompletionRowsTable,
          TaskOccurrenceCompletionRow
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskOccurrenceCompletionRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _originalLocalKeyMeta = const VerificationMeta(
    'originalLocalKey',
  );
  @override
  late final GeneratedColumn<String> originalLocalKey = GeneratedColumn<String>(
    'original_local_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtUtcMeta = const VerificationMeta(
    'completedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> completedAtUtc =
      GeneratedColumn<DateTime>(
        'completed_at_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    taskId,
    originalLocalKey,
    completedAtUtc,
    createdAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_occurrence_completions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskOccurrenceCompletionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('original_local_key')) {
      context.handle(
        _originalLocalKeyMeta,
        originalLocalKey.isAcceptableOrUnknown(
          data['original_local_key']!,
          _originalLocalKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalLocalKeyMeta);
    }
    if (data.containsKey('completed_at_utc')) {
      context.handle(
        _completedAtUtcMeta,
        completedAtUtc.isAcceptableOrUnknown(
          data['completed_at_utc']!,
          _completedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completedAtUtcMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId, originalLocalKey};
  @override
  TaskOccurrenceCompletionRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskOccurrenceCompletionRow(
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      originalLocalKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_local_key'],
      )!,
      completedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at_utc'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $TaskOccurrenceCompletionRowsTable createAlias(String alias) {
    return $TaskOccurrenceCompletionRowsTable(attachedDatabase, alias);
  }
}

class TaskOccurrenceCompletionRow extends DataClass
    implements Insertable<TaskOccurrenceCompletionRow> {
  final String taskId;
  final String originalLocalKey;
  final DateTime completedAtUtc;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  const TaskOccurrenceCompletionRow({
    required this.taskId,
    required this.originalLocalKey,
    required this.completedAtUtc,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['original_local_key'] = Variable<String>(originalLocalKey);
    map['completed_at_utc'] = Variable<DateTime>(completedAtUtc);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  TaskOccurrenceCompletionRowsCompanion toCompanion(bool nullToAbsent) {
    return TaskOccurrenceCompletionRowsCompanion(
      taskId: Value(taskId),
      originalLocalKey: Value(originalLocalKey),
      completedAtUtc: Value(completedAtUtc),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory TaskOccurrenceCompletionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskOccurrenceCompletionRow(
      taskId: serializer.fromJson<String>(json['taskId']),
      originalLocalKey: serializer.fromJson<String>(json['originalLocalKey']),
      completedAtUtc: serializer.fromJson<DateTime>(json['completedAtUtc']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'originalLocalKey': serializer.toJson<String>(originalLocalKey),
      'completedAtUtc': serializer.toJson<DateTime>(completedAtUtc),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  TaskOccurrenceCompletionRow copyWith({
    String? taskId,
    String? originalLocalKey,
    DateTime? completedAtUtc,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) => TaskOccurrenceCompletionRow(
    taskId: taskId ?? this.taskId,
    originalLocalKey: originalLocalKey ?? this.originalLocalKey,
    completedAtUtc: completedAtUtc ?? this.completedAtUtc,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  TaskOccurrenceCompletionRow copyWithCompanion(
    TaskOccurrenceCompletionRowsCompanion data,
  ) {
    return TaskOccurrenceCompletionRow(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      originalLocalKey: data.originalLocalKey.present
          ? data.originalLocalKey.value
          : this.originalLocalKey,
      completedAtUtc: data.completedAtUtc.present
          ? data.completedAtUtc.value
          : this.completedAtUtc,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskOccurrenceCompletionRow(')
          ..write('taskId: $taskId, ')
          ..write('originalLocalKey: $originalLocalKey, ')
          ..write('completedAtUtc: $completedAtUtc, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    taskId,
    originalLocalKey,
    completedAtUtc,
    createdAtUtc,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskOccurrenceCompletionRow &&
          other.taskId == this.taskId &&
          other.originalLocalKey == this.originalLocalKey &&
          other.completedAtUtc == this.completedAtUtc &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class TaskOccurrenceCompletionRowsCompanion
    extends UpdateCompanion<TaskOccurrenceCompletionRow> {
  final Value<String> taskId;
  final Value<String> originalLocalKey;
  final Value<DateTime> completedAtUtc;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const TaskOccurrenceCompletionRowsCompanion({
    this.taskId = const Value.absent(),
    this.originalLocalKey = const Value.absent(),
    this.completedAtUtc = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskOccurrenceCompletionRowsCompanion.insert({
    required String taskId,
    required String originalLocalKey,
    required DateTime completedAtUtc,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId),
       originalLocalKey = Value(originalLocalKey),
       completedAtUtc = Value(completedAtUtc),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<TaskOccurrenceCompletionRow> custom({
    Expression<String>? taskId,
    Expression<String>? originalLocalKey,
    Expression<DateTime>? completedAtUtc,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (originalLocalKey != null) 'original_local_key': originalLocalKey,
      if (completedAtUtc != null) 'completed_at_utc': completedAtUtc,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskOccurrenceCompletionRowsCompanion copyWith({
    Value<String>? taskId,
    Value<String>? originalLocalKey,
    Value<DateTime>? completedAtUtc,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return TaskOccurrenceCompletionRowsCompanion(
      taskId: taskId ?? this.taskId,
      originalLocalKey: originalLocalKey ?? this.originalLocalKey,
      completedAtUtc: completedAtUtc ?? this.completedAtUtc,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (originalLocalKey.present) {
      map['original_local_key'] = Variable<String>(originalLocalKey.value);
    }
    if (completedAtUtc.present) {
      map['completed_at_utc'] = Variable<DateTime>(completedAtUtc.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskOccurrenceCompletionRowsCompanion(')
          ..write('taskId: $taskId, ')
          ..write('originalLocalKey: $originalLocalKey, ')
          ..write('completedAtUtc: $completedAtUtc, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskTimeEntryRowsTable extends TaskTimeEntryRows
    with TableInfo<$TaskTimeEntryRowsTable, TaskTimeEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskTimeEntryRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtUtcMeta = const VerificationMeta(
    'startedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> startedAtUtc = GeneratedColumn<DateTime>(
    'started_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastResumedAtUtcMeta = const VerificationMeta(
    'lastResumedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> lastResumedAtUtc =
      GeneratedColumn<DateTime>(
        'last_resumed_at_utc',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _endedAtUtcMeta = const VerificationMeta(
    'endedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> endedAtUtc = GeneratedColumn<DateTime>(
    'ended_at_utc',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accumulatedSecondsMeta =
      const VerificationMeta('accumulatedSeconds');
  @override
  late final GeneratedColumn<int> accumulatedSeconds = GeneratedColumn<int>(
    'accumulated_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeSlotMeta = const VerificationMeta(
    'activeSlot',
  );
  @override
  late final GeneratedColumn<int> activeSlot = GeneratedColumn<int>(
    'active_slot',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    source,
    state,
    startedAtUtc,
    lastResumedAtUtc,
    endedAtUtc,
    accumulatedSeconds,
    activeSlot,
    note,
    createdAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_time_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskTimeEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('started_at_utc')) {
      context.handle(
        _startedAtUtcMeta,
        startedAtUtc.isAcceptableOrUnknown(
          data['started_at_utc']!,
          _startedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtUtcMeta);
    }
    if (data.containsKey('last_resumed_at_utc')) {
      context.handle(
        _lastResumedAtUtcMeta,
        lastResumedAtUtc.isAcceptableOrUnknown(
          data['last_resumed_at_utc']!,
          _lastResumedAtUtcMeta,
        ),
      );
    }
    if (data.containsKey('ended_at_utc')) {
      context.handle(
        _endedAtUtcMeta,
        endedAtUtc.isAcceptableOrUnknown(
          data['ended_at_utc']!,
          _endedAtUtcMeta,
        ),
      );
    }
    if (data.containsKey('accumulated_seconds')) {
      context.handle(
        _accumulatedSecondsMeta,
        accumulatedSeconds.isAcceptableOrUnknown(
          data['accumulated_seconds']!,
          _accumulatedSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accumulatedSecondsMeta);
    }
    if (data.containsKey('active_slot')) {
      context.handle(
        _activeSlotMeta,
        activeSlot.isAcceptableOrUnknown(data['active_slot']!, _activeSlotMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskTimeEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskTimeEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      startedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at_utc'],
      )!,
      lastResumedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_resumed_at_utc'],
      ),
      endedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at_utc'],
      ),
      accumulatedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}accumulated_seconds'],
      )!,
      activeSlot: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}active_slot'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $TaskTimeEntryRowsTable createAlias(String alias) {
    return $TaskTimeEntryRowsTable(attachedDatabase, alias);
  }
}

class TaskTimeEntryRow extends DataClass
    implements Insertable<TaskTimeEntryRow> {
  final String id;
  final String taskId;
  final String source;
  final String state;
  final DateTime startedAtUtc;
  final DateTime? lastResumedAtUtc;
  final DateTime? endedAtUtc;
  final int accumulatedSeconds;
  final int? activeSlot;
  final String? note;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  const TaskTimeEntryRow({
    required this.id,
    required this.taskId,
    required this.source,
    required this.state,
    required this.startedAtUtc,
    this.lastResumedAtUtc,
    this.endedAtUtc,
    required this.accumulatedSeconds,
    this.activeSlot,
    this.note,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_id'] = Variable<String>(taskId);
    map['source'] = Variable<String>(source);
    map['state'] = Variable<String>(state);
    map['started_at_utc'] = Variable<DateTime>(startedAtUtc);
    if (!nullToAbsent || lastResumedAtUtc != null) {
      map['last_resumed_at_utc'] = Variable<DateTime>(lastResumedAtUtc);
    }
    if (!nullToAbsent || endedAtUtc != null) {
      map['ended_at_utc'] = Variable<DateTime>(endedAtUtc);
    }
    map['accumulated_seconds'] = Variable<int>(accumulatedSeconds);
    if (!nullToAbsent || activeSlot != null) {
      map['active_slot'] = Variable<int>(activeSlot);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  TaskTimeEntryRowsCompanion toCompanion(bool nullToAbsent) {
    return TaskTimeEntryRowsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      source: Value(source),
      state: Value(state),
      startedAtUtc: Value(startedAtUtc),
      lastResumedAtUtc: lastResumedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(lastResumedAtUtc),
      endedAtUtc: endedAtUtc == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAtUtc),
      accumulatedSeconds: Value(accumulatedSeconds),
      activeSlot: activeSlot == null && nullToAbsent
          ? const Value.absent()
          : Value(activeSlot),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory TaskTimeEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskTimeEntryRow(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String>(json['taskId']),
      source: serializer.fromJson<String>(json['source']),
      state: serializer.fromJson<String>(json['state']),
      startedAtUtc: serializer.fromJson<DateTime>(json['startedAtUtc']),
      lastResumedAtUtc: serializer.fromJson<DateTime?>(
        json['lastResumedAtUtc'],
      ),
      endedAtUtc: serializer.fromJson<DateTime?>(json['endedAtUtc']),
      accumulatedSeconds: serializer.fromJson<int>(json['accumulatedSeconds']),
      activeSlot: serializer.fromJson<int?>(json['activeSlot']),
      note: serializer.fromJson<String?>(json['note']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String>(taskId),
      'source': serializer.toJson<String>(source),
      'state': serializer.toJson<String>(state),
      'startedAtUtc': serializer.toJson<DateTime>(startedAtUtc),
      'lastResumedAtUtc': serializer.toJson<DateTime?>(lastResumedAtUtc),
      'endedAtUtc': serializer.toJson<DateTime?>(endedAtUtc),
      'accumulatedSeconds': serializer.toJson<int>(accumulatedSeconds),
      'activeSlot': serializer.toJson<int?>(activeSlot),
      'note': serializer.toJson<String?>(note),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  TaskTimeEntryRow copyWith({
    String? id,
    String? taskId,
    String? source,
    String? state,
    DateTime? startedAtUtc,
    Value<DateTime?> lastResumedAtUtc = const Value.absent(),
    Value<DateTime?> endedAtUtc = const Value.absent(),
    int? accumulatedSeconds,
    Value<int?> activeSlot = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) => TaskTimeEntryRow(
    id: id ?? this.id,
    taskId: taskId ?? this.taskId,
    source: source ?? this.source,
    state: state ?? this.state,
    startedAtUtc: startedAtUtc ?? this.startedAtUtc,
    lastResumedAtUtc: lastResumedAtUtc.present
        ? lastResumedAtUtc.value
        : this.lastResumedAtUtc,
    endedAtUtc: endedAtUtc.present ? endedAtUtc.value : this.endedAtUtc,
    accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
    activeSlot: activeSlot.present ? activeSlot.value : this.activeSlot,
    note: note.present ? note.value : this.note,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  TaskTimeEntryRow copyWithCompanion(TaskTimeEntryRowsCompanion data) {
    return TaskTimeEntryRow(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      source: data.source.present ? data.source.value : this.source,
      state: data.state.present ? data.state.value : this.state,
      startedAtUtc: data.startedAtUtc.present
          ? data.startedAtUtc.value
          : this.startedAtUtc,
      lastResumedAtUtc: data.lastResumedAtUtc.present
          ? data.lastResumedAtUtc.value
          : this.lastResumedAtUtc,
      endedAtUtc: data.endedAtUtc.present
          ? data.endedAtUtc.value
          : this.endedAtUtc,
      accumulatedSeconds: data.accumulatedSeconds.present
          ? data.accumulatedSeconds.value
          : this.accumulatedSeconds,
      activeSlot: data.activeSlot.present
          ? data.activeSlot.value
          : this.activeSlot,
      note: data.note.present ? data.note.value : this.note,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskTimeEntryRow(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('source: $source, ')
          ..write('state: $state, ')
          ..write('startedAtUtc: $startedAtUtc, ')
          ..write('lastResumedAtUtc: $lastResumedAtUtc, ')
          ..write('endedAtUtc: $endedAtUtc, ')
          ..write('accumulatedSeconds: $accumulatedSeconds, ')
          ..write('activeSlot: $activeSlot, ')
          ..write('note: $note, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    source,
    state,
    startedAtUtc,
    lastResumedAtUtc,
    endedAtUtc,
    accumulatedSeconds,
    activeSlot,
    note,
    createdAtUtc,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskTimeEntryRow &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.source == this.source &&
          other.state == this.state &&
          other.startedAtUtc == this.startedAtUtc &&
          other.lastResumedAtUtc == this.lastResumedAtUtc &&
          other.endedAtUtc == this.endedAtUtc &&
          other.accumulatedSeconds == this.accumulatedSeconds &&
          other.activeSlot == this.activeSlot &&
          other.note == this.note &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class TaskTimeEntryRowsCompanion extends UpdateCompanion<TaskTimeEntryRow> {
  final Value<String> id;
  final Value<String> taskId;
  final Value<String> source;
  final Value<String> state;
  final Value<DateTime> startedAtUtc;
  final Value<DateTime?> lastResumedAtUtc;
  final Value<DateTime?> endedAtUtc;
  final Value<int> accumulatedSeconds;
  final Value<int?> activeSlot;
  final Value<String?> note;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const TaskTimeEntryRowsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.source = const Value.absent(),
    this.state = const Value.absent(),
    this.startedAtUtc = const Value.absent(),
    this.lastResumedAtUtc = const Value.absent(),
    this.endedAtUtc = const Value.absent(),
    this.accumulatedSeconds = const Value.absent(),
    this.activeSlot = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskTimeEntryRowsCompanion.insert({
    required String id,
    required String taskId,
    required String source,
    required String state,
    required DateTime startedAtUtc,
    this.lastResumedAtUtc = const Value.absent(),
    this.endedAtUtc = const Value.absent(),
    required int accumulatedSeconds,
    this.activeSlot = const Value.absent(),
    this.note = const Value.absent(),
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskId = Value(taskId),
       source = Value(source),
       state = Value(state),
       startedAtUtc = Value(startedAtUtc),
       accumulatedSeconds = Value(accumulatedSeconds),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<TaskTimeEntryRow> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? source,
    Expression<String>? state,
    Expression<DateTime>? startedAtUtc,
    Expression<DateTime>? lastResumedAtUtc,
    Expression<DateTime>? endedAtUtc,
    Expression<int>? accumulatedSeconds,
    Expression<int>? activeSlot,
    Expression<String>? note,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (source != null) 'source': source,
      if (state != null) 'state': state,
      if (startedAtUtc != null) 'started_at_utc': startedAtUtc,
      if (lastResumedAtUtc != null) 'last_resumed_at_utc': lastResumedAtUtc,
      if (endedAtUtc != null) 'ended_at_utc': endedAtUtc,
      if (accumulatedSeconds != null) 'accumulated_seconds': accumulatedSeconds,
      if (activeSlot != null) 'active_slot': activeSlot,
      if (note != null) 'note': note,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskTimeEntryRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? taskId,
    Value<String>? source,
    Value<String>? state,
    Value<DateTime>? startedAtUtc,
    Value<DateTime?>? lastResumedAtUtc,
    Value<DateTime?>? endedAtUtc,
    Value<int>? accumulatedSeconds,
    Value<int?>? activeSlot,
    Value<String?>? note,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return TaskTimeEntryRowsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      source: source ?? this.source,
      state: state ?? this.state,
      startedAtUtc: startedAtUtc ?? this.startedAtUtc,
      lastResumedAtUtc: lastResumedAtUtc ?? this.lastResumedAtUtc,
      endedAtUtc: endedAtUtc ?? this.endedAtUtc,
      accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
      activeSlot: activeSlot ?? this.activeSlot,
      note: note ?? this.note,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (startedAtUtc.present) {
      map['started_at_utc'] = Variable<DateTime>(startedAtUtc.value);
    }
    if (lastResumedAtUtc.present) {
      map['last_resumed_at_utc'] = Variable<DateTime>(lastResumedAtUtc.value);
    }
    if (endedAtUtc.present) {
      map['ended_at_utc'] = Variable<DateTime>(endedAtUtc.value);
    }
    if (accumulatedSeconds.present) {
      map['accumulated_seconds'] = Variable<int>(accumulatedSeconds.value);
    }
    if (activeSlot.present) {
      map['active_slot'] = Variable<int>(activeSlot.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskTimeEntryRowsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('source: $source, ')
          ..write('state: $state, ')
          ..write('startedAtUtc: $startedAtUtc, ')
          ..write('lastResumedAtUtc: $lastResumedAtUtc, ')
          ..write('endedAtUtc: $endedAtUtc, ')
          ..write('accumulatedSeconds: $accumulatedSeconds, ')
          ..write('activeSlot: $activeSlot, ')
          ..write('note: $note, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskTemplateRowsTable extends TaskTemplateRows
    with TableInfo<$TaskTemplateRowsTable, TaskTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskTemplateRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateKindMeta = const VerificationMeta(
    'templateKind',
  );
  @override
  late final GeneratedColumn<String> templateKind = GeneratedColumn<String>(
    'template_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _systemKeyMeta = const VerificationMeta(
    'systemKey',
  );
  @override
  late final GeneratedColumn<String> systemKey = GeneratedColumn<String>(
    'system_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _templateNameMeta = const VerificationMeta(
    'templateName',
  );
  @override
  late final GeneratedColumn<String> templateName = GeneratedColumn<String>(
    'template_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _initialTaskTitleMeta = const VerificationMeta(
    'initialTaskTitle',
  );
  @override
  late final GeneratedColumn<String> initialTaskTitle = GeneratedColumn<String>(
    'initial_task_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estimatedDurationMinutesMeta =
      const VerificationMeta('estimatedDurationMinutes');
  @override
  late final GeneratedColumn<int> estimatedDurationMinutes =
      GeneratedColumn<int>(
        'estimated_duration_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _reminderDefaultsJsonMeta =
      const VerificationMeta('reminderDefaultsJson');
  @override
  late final GeneratedColumn<String> reminderDefaultsJson =
      GeneratedColumn<String>(
        'reminder_defaults_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _recurrenceDefaultJsonMeta =
      const VerificationMeta('recurrenceDefaultJson');
  @override
  late final GeneratedColumn<String> recurrenceDefaultJson =
      GeneratedColumn<String>(
        'recurrence_default_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
    'hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateKind,
    systemKey,
    templateName,
    initialTaskTitle,
    description,
    priority,
    estimatedDurationMinutes,
    reminderDefaultsJson,
    recurrenceDefaultJson,
    hidden,
    displayOrder,
    createdAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskTemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_kind')) {
      context.handle(
        _templateKindMeta,
        templateKind.isAcceptableOrUnknown(
          data['template_kind']!,
          _templateKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateKindMeta);
    }
    if (data.containsKey('system_key')) {
      context.handle(
        _systemKeyMeta,
        systemKey.isAcceptableOrUnknown(data['system_key']!, _systemKeyMeta),
      );
    }
    if (data.containsKey('template_name')) {
      context.handle(
        _templateNameMeta,
        templateName.isAcceptableOrUnknown(
          data['template_name']!,
          _templateNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_templateNameMeta);
    }
    if (data.containsKey('initial_task_title')) {
      context.handle(
        _initialTaskTitleMeta,
        initialTaskTitle.isAcceptableOrUnknown(
          data['initial_task_title']!,
          _initialTaskTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initialTaskTitleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('estimated_duration_minutes')) {
      context.handle(
        _estimatedDurationMinutesMeta,
        estimatedDurationMinutes.isAcceptableOrUnknown(
          data['estimated_duration_minutes']!,
          _estimatedDurationMinutesMeta,
        ),
      );
    }
    if (data.containsKey('reminder_defaults_json')) {
      context.handle(
        _reminderDefaultsJsonMeta,
        reminderDefaultsJson.isAcceptableOrUnknown(
          data['reminder_defaults_json']!,
          _reminderDefaultsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reminderDefaultsJsonMeta);
    }
    if (data.containsKey('recurrence_default_json')) {
      context.handle(
        _recurrenceDefaultJsonMeta,
        recurrenceDefaultJson.isAcceptableOrUnknown(
          data['recurrence_default_json']!,
          _recurrenceDefaultJsonMeta,
        ),
      );
    }
    if (data.containsKey('hidden')) {
      context.handle(
        _hiddenMeta,
        hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta),
      );
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayOrderMeta);
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {templateKind, displayOrder},
  ];
  @override
  TaskTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskTemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      templateKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_kind'],
      )!,
      systemKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system_key'],
      ),
      templateName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_name'],
      )!,
      initialTaskTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}initial_task_title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      estimatedDurationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_duration_minutes'],
      ),
      reminderDefaultsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_defaults_json'],
      )!,
      recurrenceDefaultJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_default_json'],
      ),
      hidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}hidden'],
      )!,
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $TaskTemplateRowsTable createAlias(String alias) {
    return $TaskTemplateRowsTable(attachedDatabase, alias);
  }
}

class TaskTemplateRow extends DataClass implements Insertable<TaskTemplateRow> {
  final String id;
  final String templateKind;
  final String? systemKey;
  final String templateName;
  final String initialTaskTitle;
  final String? description;
  final int priority;
  final int? estimatedDurationMinutes;
  final String reminderDefaultsJson;
  final String? recurrenceDefaultJson;
  final bool hidden;
  final int displayOrder;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  const TaskTemplateRow({
    required this.id,
    required this.templateKind,
    this.systemKey,
    required this.templateName,
    required this.initialTaskTitle,
    this.description,
    required this.priority,
    this.estimatedDurationMinutes,
    required this.reminderDefaultsJson,
    this.recurrenceDefaultJson,
    required this.hidden,
    required this.displayOrder,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['template_kind'] = Variable<String>(templateKind);
    if (!nullToAbsent || systemKey != null) {
      map['system_key'] = Variable<String>(systemKey);
    }
    map['template_name'] = Variable<String>(templateName);
    map['initial_task_title'] = Variable<String>(initialTaskTitle);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || estimatedDurationMinutes != null) {
      map['estimated_duration_minutes'] = Variable<int>(
        estimatedDurationMinutes,
      );
    }
    map['reminder_defaults_json'] = Variable<String>(reminderDefaultsJson);
    if (!nullToAbsent || recurrenceDefaultJson != null) {
      map['recurrence_default_json'] = Variable<String>(recurrenceDefaultJson);
    }
    map['hidden'] = Variable<bool>(hidden);
    map['display_order'] = Variable<int>(displayOrder);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  TaskTemplateRowsCompanion toCompanion(bool nullToAbsent) {
    return TaskTemplateRowsCompanion(
      id: Value(id),
      templateKind: Value(templateKind),
      systemKey: systemKey == null && nullToAbsent
          ? const Value.absent()
          : Value(systemKey),
      templateName: Value(templateName),
      initialTaskTitle: Value(initialTaskTitle),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      priority: Value(priority),
      estimatedDurationMinutes: estimatedDurationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedDurationMinutes),
      reminderDefaultsJson: Value(reminderDefaultsJson),
      recurrenceDefaultJson: recurrenceDefaultJson == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceDefaultJson),
      hidden: Value(hidden),
      displayOrder: Value(displayOrder),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory TaskTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskTemplateRow(
      id: serializer.fromJson<String>(json['id']),
      templateKind: serializer.fromJson<String>(json['templateKind']),
      systemKey: serializer.fromJson<String?>(json['systemKey']),
      templateName: serializer.fromJson<String>(json['templateName']),
      initialTaskTitle: serializer.fromJson<String>(json['initialTaskTitle']),
      description: serializer.fromJson<String?>(json['description']),
      priority: serializer.fromJson<int>(json['priority']),
      estimatedDurationMinutes: serializer.fromJson<int?>(
        json['estimatedDurationMinutes'],
      ),
      reminderDefaultsJson: serializer.fromJson<String>(
        json['reminderDefaultsJson'],
      ),
      recurrenceDefaultJson: serializer.fromJson<String?>(
        json['recurrenceDefaultJson'],
      ),
      hidden: serializer.fromJson<bool>(json['hidden']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'templateKind': serializer.toJson<String>(templateKind),
      'systemKey': serializer.toJson<String?>(systemKey),
      'templateName': serializer.toJson<String>(templateName),
      'initialTaskTitle': serializer.toJson<String>(initialTaskTitle),
      'description': serializer.toJson<String?>(description),
      'priority': serializer.toJson<int>(priority),
      'estimatedDurationMinutes': serializer.toJson<int?>(
        estimatedDurationMinutes,
      ),
      'reminderDefaultsJson': serializer.toJson<String>(reminderDefaultsJson),
      'recurrenceDefaultJson': serializer.toJson<String?>(
        recurrenceDefaultJson,
      ),
      'hidden': serializer.toJson<bool>(hidden),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  TaskTemplateRow copyWith({
    String? id,
    String? templateKind,
    Value<String?> systemKey = const Value.absent(),
    String? templateName,
    String? initialTaskTitle,
    Value<String?> description = const Value.absent(),
    int? priority,
    Value<int?> estimatedDurationMinutes = const Value.absent(),
    String? reminderDefaultsJson,
    Value<String?> recurrenceDefaultJson = const Value.absent(),
    bool? hidden,
    int? displayOrder,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) => TaskTemplateRow(
    id: id ?? this.id,
    templateKind: templateKind ?? this.templateKind,
    systemKey: systemKey.present ? systemKey.value : this.systemKey,
    templateName: templateName ?? this.templateName,
    initialTaskTitle: initialTaskTitle ?? this.initialTaskTitle,
    description: description.present ? description.value : this.description,
    priority: priority ?? this.priority,
    estimatedDurationMinutes: estimatedDurationMinutes.present
        ? estimatedDurationMinutes.value
        : this.estimatedDurationMinutes,
    reminderDefaultsJson: reminderDefaultsJson ?? this.reminderDefaultsJson,
    recurrenceDefaultJson: recurrenceDefaultJson.present
        ? recurrenceDefaultJson.value
        : this.recurrenceDefaultJson,
    hidden: hidden ?? this.hidden,
    displayOrder: displayOrder ?? this.displayOrder,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  TaskTemplateRow copyWithCompanion(TaskTemplateRowsCompanion data) {
    return TaskTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      templateKind: data.templateKind.present
          ? data.templateKind.value
          : this.templateKind,
      systemKey: data.systemKey.present ? data.systemKey.value : this.systemKey,
      templateName: data.templateName.present
          ? data.templateName.value
          : this.templateName,
      initialTaskTitle: data.initialTaskTitle.present
          ? data.initialTaskTitle.value
          : this.initialTaskTitle,
      description: data.description.present
          ? data.description.value
          : this.description,
      priority: data.priority.present ? data.priority.value : this.priority,
      estimatedDurationMinutes: data.estimatedDurationMinutes.present
          ? data.estimatedDurationMinutes.value
          : this.estimatedDurationMinutes,
      reminderDefaultsJson: data.reminderDefaultsJson.present
          ? data.reminderDefaultsJson.value
          : this.reminderDefaultsJson,
      recurrenceDefaultJson: data.recurrenceDefaultJson.present
          ? data.recurrenceDefaultJson.value
          : this.recurrenceDefaultJson,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskTemplateRow(')
          ..write('id: $id, ')
          ..write('templateKind: $templateKind, ')
          ..write('systemKey: $systemKey, ')
          ..write('templateName: $templateName, ')
          ..write('initialTaskTitle: $initialTaskTitle, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('estimatedDurationMinutes: $estimatedDurationMinutes, ')
          ..write('reminderDefaultsJson: $reminderDefaultsJson, ')
          ..write('recurrenceDefaultJson: $recurrenceDefaultJson, ')
          ..write('hidden: $hidden, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    templateKind,
    systemKey,
    templateName,
    initialTaskTitle,
    description,
    priority,
    estimatedDurationMinutes,
    reminderDefaultsJson,
    recurrenceDefaultJson,
    hidden,
    displayOrder,
    createdAtUtc,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskTemplateRow &&
          other.id == this.id &&
          other.templateKind == this.templateKind &&
          other.systemKey == this.systemKey &&
          other.templateName == this.templateName &&
          other.initialTaskTitle == this.initialTaskTitle &&
          other.description == this.description &&
          other.priority == this.priority &&
          other.estimatedDurationMinutes == this.estimatedDurationMinutes &&
          other.reminderDefaultsJson == this.reminderDefaultsJson &&
          other.recurrenceDefaultJson == this.recurrenceDefaultJson &&
          other.hidden == this.hidden &&
          other.displayOrder == this.displayOrder &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class TaskTemplateRowsCompanion extends UpdateCompanion<TaskTemplateRow> {
  final Value<String> id;
  final Value<String> templateKind;
  final Value<String?> systemKey;
  final Value<String> templateName;
  final Value<String> initialTaskTitle;
  final Value<String?> description;
  final Value<int> priority;
  final Value<int?> estimatedDurationMinutes;
  final Value<String> reminderDefaultsJson;
  final Value<String?> recurrenceDefaultJson;
  final Value<bool> hidden;
  final Value<int> displayOrder;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const TaskTemplateRowsCompanion({
    this.id = const Value.absent(),
    this.templateKind = const Value.absent(),
    this.systemKey = const Value.absent(),
    this.templateName = const Value.absent(),
    this.initialTaskTitle = const Value.absent(),
    this.description = const Value.absent(),
    this.priority = const Value.absent(),
    this.estimatedDurationMinutes = const Value.absent(),
    this.reminderDefaultsJson = const Value.absent(),
    this.recurrenceDefaultJson = const Value.absent(),
    this.hidden = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskTemplateRowsCompanion.insert({
    required String id,
    required String templateKind,
    this.systemKey = const Value.absent(),
    required String templateName,
    required String initialTaskTitle,
    this.description = const Value.absent(),
    required int priority,
    this.estimatedDurationMinutes = const Value.absent(),
    required String reminderDefaultsJson,
    this.recurrenceDefaultJson = const Value.absent(),
    this.hidden = const Value.absent(),
    required int displayOrder,
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       templateKind = Value(templateKind),
       templateName = Value(templateName),
       initialTaskTitle = Value(initialTaskTitle),
       priority = Value(priority),
       reminderDefaultsJson = Value(reminderDefaultsJson),
       displayOrder = Value(displayOrder),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<TaskTemplateRow> custom({
    Expression<String>? id,
    Expression<String>? templateKind,
    Expression<String>? systemKey,
    Expression<String>? templateName,
    Expression<String>? initialTaskTitle,
    Expression<String>? description,
    Expression<int>? priority,
    Expression<int>? estimatedDurationMinutes,
    Expression<String>? reminderDefaultsJson,
    Expression<String>? recurrenceDefaultJson,
    Expression<bool>? hidden,
    Expression<int>? displayOrder,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateKind != null) 'template_kind': templateKind,
      if (systemKey != null) 'system_key': systemKey,
      if (templateName != null) 'template_name': templateName,
      if (initialTaskTitle != null) 'initial_task_title': initialTaskTitle,
      if (description != null) 'description': description,
      if (priority != null) 'priority': priority,
      if (estimatedDurationMinutes != null)
        'estimated_duration_minutes': estimatedDurationMinutes,
      if (reminderDefaultsJson != null)
        'reminder_defaults_json': reminderDefaultsJson,
      if (recurrenceDefaultJson != null)
        'recurrence_default_json': recurrenceDefaultJson,
      if (hidden != null) 'hidden': hidden,
      if (displayOrder != null) 'display_order': displayOrder,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskTemplateRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? templateKind,
    Value<String?>? systemKey,
    Value<String>? templateName,
    Value<String>? initialTaskTitle,
    Value<String?>? description,
    Value<int>? priority,
    Value<int?>? estimatedDurationMinutes,
    Value<String>? reminderDefaultsJson,
    Value<String?>? recurrenceDefaultJson,
    Value<bool>? hidden,
    Value<int>? displayOrder,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return TaskTemplateRowsCompanion(
      id: id ?? this.id,
      templateKind: templateKind ?? this.templateKind,
      systemKey: systemKey ?? this.systemKey,
      templateName: templateName ?? this.templateName,
      initialTaskTitle: initialTaskTitle ?? this.initialTaskTitle,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      reminderDefaultsJson: reminderDefaultsJson ?? this.reminderDefaultsJson,
      recurrenceDefaultJson:
          recurrenceDefaultJson ?? this.recurrenceDefaultJson,
      hidden: hidden ?? this.hidden,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (templateKind.present) {
      map['template_kind'] = Variable<String>(templateKind.value);
    }
    if (systemKey.present) {
      map['system_key'] = Variable<String>(systemKey.value);
    }
    if (templateName.present) {
      map['template_name'] = Variable<String>(templateName.value);
    }
    if (initialTaskTitle.present) {
      map['initial_task_title'] = Variable<String>(initialTaskTitle.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (estimatedDurationMinutes.present) {
      map['estimated_duration_minutes'] = Variable<int>(
        estimatedDurationMinutes.value,
      );
    }
    if (reminderDefaultsJson.present) {
      map['reminder_defaults_json'] = Variable<String>(
        reminderDefaultsJson.value,
      );
    }
    if (recurrenceDefaultJson.present) {
      map['recurrence_default_json'] = Variable<String>(
        recurrenceDefaultJson.value,
      );
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskTemplateRowsCompanion(')
          ..write('id: $id, ')
          ..write('templateKind: $templateKind, ')
          ..write('systemKey: $systemKey, ')
          ..write('templateName: $templateName, ')
          ..write('initialTaskTitle: $initialTaskTitle, ')
          ..write('description: $description, ')
          ..write('priority: $priority, ')
          ..write('estimatedDurationMinutes: $estimatedDurationMinutes, ')
          ..write('reminderDefaultsJson: $reminderDefaultsJson, ')
          ..write('recurrenceDefaultJson: $recurrenceDefaultJson, ')
          ..write('hidden: $hidden, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotificationScheduleRowsTable extends NotificationScheduleRows
    with TableInfo<$NotificationScheduleRowsTable, NotificationScheduleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotificationScheduleRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  @override
  late final GeneratedColumn<String> scheduleId = GeneratedColumn<String>(
    'schedule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerTypeMeta = const VerificationMeta(
    'ownerType',
  );
  @override
  late final GeneratedColumn<String> ownerType = GeneratedColumn<String>(
    'owner_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledAtUtcMeta = const VerificationMeta(
    'scheduledAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledAtUtc =
      GeneratedColumn<DateTime>(
        'scheduled_at_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _privacyModeMeta = const VerificationMeta(
    'privacyMode',
  );
  @override
  late final GeneratedColumn<String> privacyMode = GeneratedColumn<String>(
    'privacy_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('full'),
  );
  static const VerificationMeta _createdAtUtcMeta = const VerificationMeta(
    'createdAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> createdAtUtc = GeneratedColumn<DateTime>(
    'created_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMeta = const VerificationMeta(
    'updatedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAtUtc = GeneratedColumn<DateTime>(
    'updated_at_utc',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    scheduleId,
    ownerType,
    ownerId,
    title,
    body,
    scheduledAtUtc,
    payloadJson,
    privacyMode,
    createdAtUtc,
    updatedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notification_schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotificationScheduleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('schedule_id')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['schedule_id']!, _scheduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scheduleIdMeta);
    }
    if (data.containsKey('owner_type')) {
      context.handle(
        _ownerTypeMeta,
        ownerType.isAcceptableOrUnknown(data['owner_type']!, _ownerTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerTypeMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('scheduled_at_utc')) {
      context.handle(
        _scheduledAtUtcMeta,
        scheduledAtUtc.isAcceptableOrUnknown(
          data['scheduled_at_utc']!,
          _scheduledAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledAtUtcMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('privacy_mode')) {
      context.handle(
        _privacyModeMeta,
        privacyMode.isAcceptableOrUnknown(
          data['privacy_mode']!,
          _privacyModeMeta,
        ),
      );
    }
    if (data.containsKey('created_at_utc')) {
      context.handle(
        _createdAtUtcMeta,
        createdAtUtc.isAcceptableOrUnknown(
          data['created_at_utc']!,
          _createdAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMeta);
    }
    if (data.containsKey('updated_at_utc')) {
      context.handle(
        _updatedAtUtcMeta,
        updatedAtUtc.isAcceptableOrUnknown(
          data['updated_at_utc']!,
          _updatedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scheduleId};
  @override
  NotificationScheduleRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotificationScheduleRow(
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_id'],
      )!,
      ownerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_type'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      scheduledAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_at_utc'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      privacyMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}privacy_mode'],
      )!,
      createdAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at_utc'],
      )!,
      updatedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at_utc'],
      )!,
    );
  }

  @override
  $NotificationScheduleRowsTable createAlias(String alias) {
    return $NotificationScheduleRowsTable(attachedDatabase, alias);
  }
}

class NotificationScheduleRow extends DataClass
    implements Insertable<NotificationScheduleRow> {
  final String scheduleId;
  final String ownerType;
  final String ownerId;
  final String title;
  final String body;
  final DateTime scheduledAtUtc;
  final String payloadJson;
  final String privacyMode;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  const NotificationScheduleRow({
    required this.scheduleId,
    required this.ownerType,
    required this.ownerId,
    required this.title,
    required this.body,
    required this.scheduledAtUtc,
    required this.payloadJson,
    required this.privacyMode,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['schedule_id'] = Variable<String>(scheduleId);
    map['owner_type'] = Variable<String>(ownerType);
    map['owner_id'] = Variable<String>(ownerId);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    map['scheduled_at_utc'] = Variable<DateTime>(scheduledAtUtc);
    map['payload_json'] = Variable<String>(payloadJson);
    map['privacy_mode'] = Variable<String>(privacyMode);
    map['created_at_utc'] = Variable<DateTime>(createdAtUtc);
    map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc);
    return map;
  }

  NotificationScheduleRowsCompanion toCompanion(bool nullToAbsent) {
    return NotificationScheduleRowsCompanion(
      scheduleId: Value(scheduleId),
      ownerType: Value(ownerType),
      ownerId: Value(ownerId),
      title: Value(title),
      body: Value(body),
      scheduledAtUtc: Value(scheduledAtUtc),
      payloadJson: Value(payloadJson),
      privacyMode: Value(privacyMode),
      createdAtUtc: Value(createdAtUtc),
      updatedAtUtc: Value(updatedAtUtc),
    );
  }

  factory NotificationScheduleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotificationScheduleRow(
      scheduleId: serializer.fromJson<String>(json['scheduleId']),
      ownerType: serializer.fromJson<String>(json['ownerType']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      scheduledAtUtc: serializer.fromJson<DateTime>(json['scheduledAtUtc']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      privacyMode: serializer.fromJson<String>(json['privacyMode']),
      createdAtUtc: serializer.fromJson<DateTime>(json['createdAtUtc']),
      updatedAtUtc: serializer.fromJson<DateTime>(json['updatedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scheduleId': serializer.toJson<String>(scheduleId),
      'ownerType': serializer.toJson<String>(ownerType),
      'ownerId': serializer.toJson<String>(ownerId),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'scheduledAtUtc': serializer.toJson<DateTime>(scheduledAtUtc),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'privacyMode': serializer.toJson<String>(privacyMode),
      'createdAtUtc': serializer.toJson<DateTime>(createdAtUtc),
      'updatedAtUtc': serializer.toJson<DateTime>(updatedAtUtc),
    };
  }

  NotificationScheduleRow copyWith({
    String? scheduleId,
    String? ownerType,
    String? ownerId,
    String? title,
    String? body,
    DateTime? scheduledAtUtc,
    String? payloadJson,
    String? privacyMode,
    DateTime? createdAtUtc,
    DateTime? updatedAtUtc,
  }) => NotificationScheduleRow(
    scheduleId: scheduleId ?? this.scheduleId,
    ownerType: ownerType ?? this.ownerType,
    ownerId: ownerId ?? this.ownerId,
    title: title ?? this.title,
    body: body ?? this.body,
    scheduledAtUtc: scheduledAtUtc ?? this.scheduledAtUtc,
    payloadJson: payloadJson ?? this.payloadJson,
    privacyMode: privacyMode ?? this.privacyMode,
    createdAtUtc: createdAtUtc ?? this.createdAtUtc,
    updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
  );
  NotificationScheduleRow copyWithCompanion(
    NotificationScheduleRowsCompanion data,
  ) {
    return NotificationScheduleRow(
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      ownerType: data.ownerType.present ? data.ownerType.value : this.ownerType,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      scheduledAtUtc: data.scheduledAtUtc.present
          ? data.scheduledAtUtc.value
          : this.scheduledAtUtc,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      privacyMode: data.privacyMode.present
          ? data.privacyMode.value
          : this.privacyMode,
      createdAtUtc: data.createdAtUtc.present
          ? data.createdAtUtc.value
          : this.createdAtUtc,
      updatedAtUtc: data.updatedAtUtc.present
          ? data.updatedAtUtc.value
          : this.updatedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotificationScheduleRow(')
          ..write('scheduleId: $scheduleId, ')
          ..write('ownerType: $ownerType, ')
          ..write('ownerId: $ownerId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('scheduledAtUtc: $scheduledAtUtc, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('privacyMode: $privacyMode, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    scheduleId,
    ownerType,
    ownerId,
    title,
    body,
    scheduledAtUtc,
    payloadJson,
    privacyMode,
    createdAtUtc,
    updatedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotificationScheduleRow &&
          other.scheduleId == this.scheduleId &&
          other.ownerType == this.ownerType &&
          other.ownerId == this.ownerId &&
          other.title == this.title &&
          other.body == this.body &&
          other.scheduledAtUtc == this.scheduledAtUtc &&
          other.payloadJson == this.payloadJson &&
          other.privacyMode == this.privacyMode &&
          other.createdAtUtc == this.createdAtUtc &&
          other.updatedAtUtc == this.updatedAtUtc);
}

class NotificationScheduleRowsCompanion
    extends UpdateCompanion<NotificationScheduleRow> {
  final Value<String> scheduleId;
  final Value<String> ownerType;
  final Value<String> ownerId;
  final Value<String> title;
  final Value<String> body;
  final Value<DateTime> scheduledAtUtc;
  final Value<String> payloadJson;
  final Value<String> privacyMode;
  final Value<DateTime> createdAtUtc;
  final Value<DateTime> updatedAtUtc;
  final Value<int> rowid;
  const NotificationScheduleRowsCompanion({
    this.scheduleId = const Value.absent(),
    this.ownerType = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.scheduledAtUtc = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.privacyMode = const Value.absent(),
    this.createdAtUtc = const Value.absent(),
    this.updatedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotificationScheduleRowsCompanion.insert({
    required String scheduleId,
    required String ownerType,
    required String ownerId,
    required String title,
    required String body,
    required DateTime scheduledAtUtc,
    this.payloadJson = const Value.absent(),
    this.privacyMode = const Value.absent(),
    required DateTime createdAtUtc,
    required DateTime updatedAtUtc,
    this.rowid = const Value.absent(),
  }) : scheduleId = Value(scheduleId),
       ownerType = Value(ownerType),
       ownerId = Value(ownerId),
       title = Value(title),
       body = Value(body),
       scheduledAtUtc = Value(scheduledAtUtc),
       createdAtUtc = Value(createdAtUtc),
       updatedAtUtc = Value(updatedAtUtc);
  static Insertable<NotificationScheduleRow> custom({
    Expression<String>? scheduleId,
    Expression<String>? ownerType,
    Expression<String>? ownerId,
    Expression<String>? title,
    Expression<String>? body,
    Expression<DateTime>? scheduledAtUtc,
    Expression<String>? payloadJson,
    Expression<String>? privacyMode,
    Expression<DateTime>? createdAtUtc,
    Expression<DateTime>? updatedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (ownerType != null) 'owner_type': ownerType,
      if (ownerId != null) 'owner_id': ownerId,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (scheduledAtUtc != null) 'scheduled_at_utc': scheduledAtUtc,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (privacyMode != null) 'privacy_mode': privacyMode,
      if (createdAtUtc != null) 'created_at_utc': createdAtUtc,
      if (updatedAtUtc != null) 'updated_at_utc': updatedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotificationScheduleRowsCompanion copyWith({
    Value<String>? scheduleId,
    Value<String>? ownerType,
    Value<String>? ownerId,
    Value<String>? title,
    Value<String>? body,
    Value<DateTime>? scheduledAtUtc,
    Value<String>? payloadJson,
    Value<String>? privacyMode,
    Value<DateTime>? createdAtUtc,
    Value<DateTime>? updatedAtUtc,
    Value<int>? rowid,
  }) {
    return NotificationScheduleRowsCompanion(
      scheduleId: scheduleId ?? this.scheduleId,
      ownerType: ownerType ?? this.ownerType,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      body: body ?? this.body,
      scheduledAtUtc: scheduledAtUtc ?? this.scheduledAtUtc,
      payloadJson: payloadJson ?? this.payloadJson,
      privacyMode: privacyMode ?? this.privacyMode,
      createdAtUtc: createdAtUtc ?? this.createdAtUtc,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scheduleId.present) {
      map['schedule_id'] = Variable<String>(scheduleId.value);
    }
    if (ownerType.present) {
      map['owner_type'] = Variable<String>(ownerType.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (scheduledAtUtc.present) {
      map['scheduled_at_utc'] = Variable<DateTime>(scheduledAtUtc.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (privacyMode.present) {
      map['privacy_mode'] = Variable<String>(privacyMode.value);
    }
    if (createdAtUtc.present) {
      map['created_at_utc'] = Variable<DateTime>(createdAtUtc.value);
    }
    if (updatedAtUtc.present) {
      map['updated_at_utc'] = Variable<DateTime>(updatedAtUtc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotificationScheduleRowsCompanion(')
          ..write('scheduleId: $scheduleId, ')
          ..write('ownerType: $ownerType, ')
          ..write('ownerId: $ownerId, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('scheduledAtUtc: $scheduledAtUtc, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('privacyMode: $privacyMode, ')
          ..write('createdAtUtc: $createdAtUtc, ')
          ..write('updatedAtUtc: $updatedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LegacyImportRowsTable extends LegacyImportRows
    with TableInfo<$LegacyImportRowsTable, LegacyImportRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LegacyImportRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceKindMeta = const VerificationMeta(
    'sourceKind',
  );
  @override
  late final GeneratedColumn<String> sourceKind = GeneratedColumn<String>(
    'source_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _v1IdMeta = const VerificationMeta('v1Id');
  @override
  late final GeneratedColumn<String> v1Id = GeneratedColumn<String>(
    'v1_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _v2IdMeta = const VerificationMeta('v2Id');
  @override
  late final GeneratedColumn<String> v2Id = GeneratedColumn<String>(
    'v2_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtUtcMeta = const VerificationMeta(
    'importedAtUtc',
  );
  @override
  late final GeneratedColumn<DateTime> importedAtUtc =
      GeneratedColumn<DateTime>(
        'imported_at_utc',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _sourceSha256Meta = const VerificationMeta(
    'sourceSha256',
  );
  @override
  late final GeneratedColumn<String> sourceSha256 = GeneratedColumn<String>(
    'source_sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceKind,
    entityType,
    v1Id,
    v2Id,
    importedAtUtc,
    sourceSha256,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'legacy_imports';
  @override
  VerificationContext validateIntegrity(
    Insertable<LegacyImportRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_kind')) {
      context.handle(
        _sourceKindMeta,
        sourceKind.isAcceptableOrUnknown(data['source_kind']!, _sourceKindMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceKindMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('v1_id')) {
      context.handle(
        _v1IdMeta,
        v1Id.isAcceptableOrUnknown(data['v1_id']!, _v1IdMeta),
      );
    } else if (isInserting) {
      context.missing(_v1IdMeta);
    }
    if (data.containsKey('v2_id')) {
      context.handle(
        _v2IdMeta,
        v2Id.isAcceptableOrUnknown(data['v2_id']!, _v2IdMeta),
      );
    } else if (isInserting) {
      context.missing(_v2IdMeta);
    }
    if (data.containsKey('imported_at_utc')) {
      context.handle(
        _importedAtUtcMeta,
        importedAtUtc.isAcceptableOrUnknown(
          data['imported_at_utc']!,
          _importedAtUtcMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_importedAtUtcMeta);
    }
    if (data.containsKey('source_sha256')) {
      context.handle(
        _sourceSha256Meta,
        sourceSha256.isAcceptableOrUnknown(
          data['source_sha256']!,
          _sourceSha256Meta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceSha256Meta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityType, v1Id};
  @override
  LegacyImportRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LegacyImportRow(
      sourceKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_kind'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      v1Id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}v1_id'],
      )!,
      v2Id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}v2_id'],
      )!,
      importedAtUtc: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at_utc'],
      )!,
      sourceSha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_sha256'],
      )!,
    );
  }

  @override
  $LegacyImportRowsTable createAlias(String alias) {
    return $LegacyImportRowsTable(attachedDatabase, alias);
  }
}

class LegacyImportRow extends DataClass implements Insertable<LegacyImportRow> {
  final String sourceKind;
  final String entityType;
  final String v1Id;
  final String v2Id;
  final DateTime importedAtUtc;
  final String sourceSha256;
  const LegacyImportRow({
    required this.sourceKind,
    required this.entityType,
    required this.v1Id,
    required this.v2Id,
    required this.importedAtUtc,
    required this.sourceSha256,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_kind'] = Variable<String>(sourceKind);
    map['entity_type'] = Variable<String>(entityType);
    map['v1_id'] = Variable<String>(v1Id);
    map['v2_id'] = Variable<String>(v2Id);
    map['imported_at_utc'] = Variable<DateTime>(importedAtUtc);
    map['source_sha256'] = Variable<String>(sourceSha256);
    return map;
  }

  LegacyImportRowsCompanion toCompanion(bool nullToAbsent) {
    return LegacyImportRowsCompanion(
      sourceKind: Value(sourceKind),
      entityType: Value(entityType),
      v1Id: Value(v1Id),
      v2Id: Value(v2Id),
      importedAtUtc: Value(importedAtUtc),
      sourceSha256: Value(sourceSha256),
    );
  }

  factory LegacyImportRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LegacyImportRow(
      sourceKind: serializer.fromJson<String>(json['sourceKind']),
      entityType: serializer.fromJson<String>(json['entityType']),
      v1Id: serializer.fromJson<String>(json['v1Id']),
      v2Id: serializer.fromJson<String>(json['v2Id']),
      importedAtUtc: serializer.fromJson<DateTime>(json['importedAtUtc']),
      sourceSha256: serializer.fromJson<String>(json['sourceSha256']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sourceKind': serializer.toJson<String>(sourceKind),
      'entityType': serializer.toJson<String>(entityType),
      'v1Id': serializer.toJson<String>(v1Id),
      'v2Id': serializer.toJson<String>(v2Id),
      'importedAtUtc': serializer.toJson<DateTime>(importedAtUtc),
      'sourceSha256': serializer.toJson<String>(sourceSha256),
    };
  }

  LegacyImportRow copyWith({
    String? sourceKind,
    String? entityType,
    String? v1Id,
    String? v2Id,
    DateTime? importedAtUtc,
    String? sourceSha256,
  }) => LegacyImportRow(
    sourceKind: sourceKind ?? this.sourceKind,
    entityType: entityType ?? this.entityType,
    v1Id: v1Id ?? this.v1Id,
    v2Id: v2Id ?? this.v2Id,
    importedAtUtc: importedAtUtc ?? this.importedAtUtc,
    sourceSha256: sourceSha256 ?? this.sourceSha256,
  );
  LegacyImportRow copyWithCompanion(LegacyImportRowsCompanion data) {
    return LegacyImportRow(
      sourceKind: data.sourceKind.present
          ? data.sourceKind.value
          : this.sourceKind,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      v1Id: data.v1Id.present ? data.v1Id.value : this.v1Id,
      v2Id: data.v2Id.present ? data.v2Id.value : this.v2Id,
      importedAtUtc: data.importedAtUtc.present
          ? data.importedAtUtc.value
          : this.importedAtUtc,
      sourceSha256: data.sourceSha256.present
          ? data.sourceSha256.value
          : this.sourceSha256,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LegacyImportRow(')
          ..write('sourceKind: $sourceKind, ')
          ..write('entityType: $entityType, ')
          ..write('v1Id: $v1Id, ')
          ..write('v2Id: $v2Id, ')
          ..write('importedAtUtc: $importedAtUtc, ')
          ..write('sourceSha256: $sourceSha256')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sourceKind,
    entityType,
    v1Id,
    v2Id,
    importedAtUtc,
    sourceSha256,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LegacyImportRow &&
          other.sourceKind == this.sourceKind &&
          other.entityType == this.entityType &&
          other.v1Id == this.v1Id &&
          other.v2Id == this.v2Id &&
          other.importedAtUtc == this.importedAtUtc &&
          other.sourceSha256 == this.sourceSha256);
}

class LegacyImportRowsCompanion extends UpdateCompanion<LegacyImportRow> {
  final Value<String> sourceKind;
  final Value<String> entityType;
  final Value<String> v1Id;
  final Value<String> v2Id;
  final Value<DateTime> importedAtUtc;
  final Value<String> sourceSha256;
  final Value<int> rowid;
  const LegacyImportRowsCompanion({
    this.sourceKind = const Value.absent(),
    this.entityType = const Value.absent(),
    this.v1Id = const Value.absent(),
    this.v2Id = const Value.absent(),
    this.importedAtUtc = const Value.absent(),
    this.sourceSha256 = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LegacyImportRowsCompanion.insert({
    required String sourceKind,
    required String entityType,
    required String v1Id,
    required String v2Id,
    required DateTime importedAtUtc,
    required String sourceSha256,
    this.rowid = const Value.absent(),
  }) : sourceKind = Value(sourceKind),
       entityType = Value(entityType),
       v1Id = Value(v1Id),
       v2Id = Value(v2Id),
       importedAtUtc = Value(importedAtUtc),
       sourceSha256 = Value(sourceSha256);
  static Insertable<LegacyImportRow> custom({
    Expression<String>? sourceKind,
    Expression<String>? entityType,
    Expression<String>? v1Id,
    Expression<String>? v2Id,
    Expression<DateTime>? importedAtUtc,
    Expression<String>? sourceSha256,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceKind != null) 'source_kind': sourceKind,
      if (entityType != null) 'entity_type': entityType,
      if (v1Id != null) 'v1_id': v1Id,
      if (v2Id != null) 'v2_id': v2Id,
      if (importedAtUtc != null) 'imported_at_utc': importedAtUtc,
      if (sourceSha256 != null) 'source_sha256': sourceSha256,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LegacyImportRowsCompanion copyWith({
    Value<String>? sourceKind,
    Value<String>? entityType,
    Value<String>? v1Id,
    Value<String>? v2Id,
    Value<DateTime>? importedAtUtc,
    Value<String>? sourceSha256,
    Value<int>? rowid,
  }) {
    return LegacyImportRowsCompanion(
      sourceKind: sourceKind ?? this.sourceKind,
      entityType: entityType ?? this.entityType,
      v1Id: v1Id ?? this.v1Id,
      v2Id: v2Id ?? this.v2Id,
      importedAtUtc: importedAtUtc ?? this.importedAtUtc,
      sourceSha256: sourceSha256 ?? this.sourceSha256,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceKind.present) {
      map['source_kind'] = Variable<String>(sourceKind.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (v1Id.present) {
      map['v1_id'] = Variable<String>(v1Id.value);
    }
    if (v2Id.present) {
      map['v2_id'] = Variable<String>(v2Id.value);
    }
    if (importedAtUtc.present) {
      map['imported_at_utc'] = Variable<DateTime>(importedAtUtc.value);
    }
    if (sourceSha256.present) {
      map['source_sha256'] = Variable<String>(sourceSha256.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LegacyImportRowsCompanion(')
          ..write('sourceKind: $sourceKind, ')
          ..write('entityType: $entityType, ')
          ..write('v1Id: $v1Id, ')
          ..write('v2Id: $v2Id, ')
          ..write('importedAtUtc: $importedAtUtc, ')
          ..write('sourceSha256: $sourceSha256, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TaskRowsTable taskRows = $TaskRowsTable(this);
  late final $FinanceTransactionRowsTable financeTransactionRows =
      $FinanceTransactionRowsTable(this);
  late final $DebtRowsTable debtRows = $DebtRowsTable(this);
  late final $DebtPaymentRowsTable debtPaymentRows = $DebtPaymentRowsTable(
    this,
  );
  late final $InstallmentPlanRowsTable installmentPlanRows =
      $InstallmentPlanRowsTable(this);
  late final $InstallmentPaymentRowsTable installmentPaymentRows =
      $InstallmentPaymentRowsTable(this);
  late final $TaskReminderRuleRowsTable taskReminderRuleRows =
      $TaskReminderRuleRowsTable(this);
  late final $TaskRecurrenceRuleRowsTable taskRecurrenceRuleRows =
      $TaskRecurrenceRuleRowsTable(this);
  late final $TaskRecurrenceExceptionRowsTable taskRecurrenceExceptionRows =
      $TaskRecurrenceExceptionRowsTable(this);
  late final $TaskOccurrenceCompletionRowsTable taskOccurrenceCompletionRows =
      $TaskOccurrenceCompletionRowsTable(this);
  late final $TaskTimeEntryRowsTable taskTimeEntryRows =
      $TaskTimeEntryRowsTable(this);
  late final $TaskTemplateRowsTable taskTemplateRows = $TaskTemplateRowsTable(
    this,
  );
  late final $NotificationScheduleRowsTable notificationScheduleRows =
      $NotificationScheduleRowsTable(this);
  late final $LegacyImportRowsTable legacyImportRows = $LegacyImportRowsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    taskRows,
    financeTransactionRows,
    debtRows,
    debtPaymentRows,
    installmentPlanRows,
    installmentPaymentRows,
    taskReminderRuleRows,
    taskRecurrenceRuleRows,
    taskRecurrenceExceptionRows,
    taskOccurrenceCompletionRows,
    taskTimeEntryRows,
    taskTemplateRows,
    notificationScheduleRows,
    legacyImportRows,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'debts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('debt_payments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'installment_plans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('installment_payments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_reminder_rules', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_recurrence_rules', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('task_recurrence_exceptions', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('task_occurrence_completions', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_time_entries', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$TaskRowsTableCreateCompanionBuilder =
    TaskRowsCompanion Function({
      required String id,
      required int displayNumber,
      required String title,
      Value<String?> description,
      required int priority,
      required String status,
      required int positionInStatus,
      Value<DateTime?> startAtUtc,
      Value<DateTime?> dueAtUtc,
      Value<int?> estimatedDurationMinutes,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<DateTime?> completedAtUtc,
      Value<DateTime?> canceledAtUtc,
      Value<int> rowid,
    });
typedef $$TaskRowsTableUpdateCompanionBuilder =
    TaskRowsCompanion Function({
      Value<String> id,
      Value<int> displayNumber,
      Value<String> title,
      Value<String?> description,
      Value<int> priority,
      Value<String> status,
      Value<int> positionInStatus,
      Value<DateTime?> startAtUtc,
      Value<DateTime?> dueAtUtc,
      Value<int?> estimatedDurationMinutes,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<DateTime?> completedAtUtc,
      Value<DateTime?> canceledAtUtc,
      Value<int> rowid,
    });

final class $$TaskRowsTableReferences
    extends BaseReferences<_$AppDatabase, $TaskRowsTable, TaskRow> {
  $$TaskRowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $TaskReminderRuleRowsTable,
    List<TaskReminderRuleRow>
  >
  _taskReminderRuleRowsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.taskReminderRuleRows,
        aliasName: 'tasks__id__task_reminder_rules__task_id',
      );

  $$TaskReminderRuleRowsTableProcessedTableManager
  get taskReminderRuleRowsRefs {
    final manager = $$TaskReminderRuleRowsTableTableManager(
      $_db,
      $_db.taskReminderRuleRows,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _taskReminderRuleRowsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $TaskRecurrenceRuleRowsTable,
    List<TaskRecurrenceRuleRow>
  >
  _taskRecurrenceRuleRowsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.taskRecurrenceRuleRows,
        aliasName: 'tasks__id__task_recurrence_rules__task_id',
      );

  $$TaskRecurrenceRuleRowsTableProcessedTableManager
  get taskRecurrenceRuleRowsRefs {
    final manager = $$TaskRecurrenceRuleRowsTableTableManager(
      $_db,
      $_db.taskRecurrenceRuleRows,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _taskRecurrenceRuleRowsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $TaskRecurrenceExceptionRowsTable,
    List<TaskRecurrenceExceptionRow>
  >
  _taskRecurrenceExceptionRowsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.taskRecurrenceExceptionRows,
        aliasName: 'tasks__id__task_recurrence_exceptions__task_id',
      );

  $$TaskRecurrenceExceptionRowsTableProcessedTableManager
  get taskRecurrenceExceptionRowsRefs {
    final manager = $$TaskRecurrenceExceptionRowsTableTableManager(
      $_db,
      $_db.taskRecurrenceExceptionRows,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _taskRecurrenceExceptionRowsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $TaskOccurrenceCompletionRowsTable,
    List<TaskOccurrenceCompletionRow>
  >
  _taskOccurrenceCompletionRowsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.taskOccurrenceCompletionRows,
        aliasName: 'tasks__id__task_occurrence_completions__task_id',
      );

  $$TaskOccurrenceCompletionRowsTableProcessedTableManager
  get taskOccurrenceCompletionRowsRefs {
    final manager = $$TaskOccurrenceCompletionRowsTableTableManager(
      $_db,
      $_db.taskOccurrenceCompletionRows,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _taskOccurrenceCompletionRowsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskTimeEntryRowsTable, List<TaskTimeEntryRow>>
  _taskTimeEntryRowsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.taskTimeEntryRows,
        aliasName: 'tasks__id__task_time_entries__task_id',
      );

  $$TaskTimeEntryRowsTableProcessedTableManager get taskTimeEntryRowsRefs {
    final manager = $$TaskTimeEntryRowsTableTableManager(
      $_db,
      $_db.taskTimeEntryRows,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _taskTimeEntryRowsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TaskRowsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskRowsTable> {
  $$TaskRowsTableFilterComposer({
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

  ColumnFilters<int> get displayNumber => $composableBuilder(
    column: $table.displayNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionInStatus => $composableBuilder(
    column: $table.positionInStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueAtUtc => $composableBuilder(
    column: $table.dueAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatedDurationMinutes => $composableBuilder(
    column: $table.estimatedDurationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAtUtc => $composableBuilder(
    column: $table.completedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get canceledAtUtc => $composableBuilder(
    column: $table.canceledAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> taskReminderRuleRowsRefs(
    Expression<bool> Function($$TaskReminderRuleRowsTableFilterComposer f) f,
  ) {
    final $$TaskReminderRuleRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskReminderRuleRows,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskReminderRuleRowsTableFilterComposer(
            $db: $db,
            $table: $db.taskReminderRuleRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskRecurrenceRuleRowsRefs(
    Expression<bool> Function($$TaskRecurrenceRuleRowsTableFilterComposer f) f,
  ) {
    final $$TaskRecurrenceRuleRowsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.taskRecurrenceRuleRows,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TaskRecurrenceRuleRowsTableFilterComposer(
                $db: $db,
                $table: $db.taskRecurrenceRuleRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> taskRecurrenceExceptionRowsRefs(
    Expression<bool> Function(
      $$TaskRecurrenceExceptionRowsTableFilterComposer f,
    )
    f,
  ) {
    final $$TaskRecurrenceExceptionRowsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.taskRecurrenceExceptionRows,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TaskRecurrenceExceptionRowsTableFilterComposer(
                $db: $db,
                $table: $db.taskRecurrenceExceptionRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> taskOccurrenceCompletionRowsRefs(
    Expression<bool> Function(
      $$TaskOccurrenceCompletionRowsTableFilterComposer f,
    )
    f,
  ) {
    final $$TaskOccurrenceCompletionRowsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.taskOccurrenceCompletionRows,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TaskOccurrenceCompletionRowsTableFilterComposer(
                $db: $db,
                $table: $db.taskOccurrenceCompletionRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> taskTimeEntryRowsRefs(
    Expression<bool> Function($$TaskTimeEntryRowsTableFilterComposer f) f,
  ) {
    final $$TaskTimeEntryRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTimeEntryRows,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTimeEntryRowsTableFilterComposer(
            $db: $db,
            $table: $db.taskTimeEntryRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TaskRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskRowsTable> {
  $$TaskRowsTableOrderingComposer({
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

  ColumnOrderings<int> get displayNumber => $composableBuilder(
    column: $table.displayNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionInStatus => $composableBuilder(
    column: $table.positionInStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueAtUtc => $composableBuilder(
    column: $table.dueAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedDurationMinutes => $composableBuilder(
    column: $table.estimatedDurationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAtUtc => $composableBuilder(
    column: $table.completedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get canceledAtUtc => $composableBuilder(
    column: $table.canceledAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskRowsTable> {
  $$TaskRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get displayNumber => $composableBuilder(
    column: $table.displayNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get positionInStatus => $composableBuilder(
    column: $table.positionInStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startAtUtc => $composableBuilder(
    column: $table.startAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueAtUtc =>
      $composableBuilder(column: $table.dueAtUtc, builder: (column) => column);

  GeneratedColumn<int> get estimatedDurationMinutes => $composableBuilder(
    column: $table.estimatedDurationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAtUtc => $composableBuilder(
    column: $table.completedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get canceledAtUtc => $composableBuilder(
    column: $table.canceledAtUtc,
    builder: (column) => column,
  );

  Expression<T> taskReminderRuleRowsRefs<T extends Object>(
    Expression<T> Function($$TaskReminderRuleRowsTableAnnotationComposer a) f,
  ) {
    final $$TaskReminderRuleRowsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.taskReminderRuleRows,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TaskReminderRuleRowsTableAnnotationComposer(
                $db: $db,
                $table: $db.taskReminderRuleRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> taskRecurrenceRuleRowsRefs<T extends Object>(
    Expression<T> Function($$TaskRecurrenceRuleRowsTableAnnotationComposer a) f,
  ) {
    final $$TaskRecurrenceRuleRowsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.taskRecurrenceRuleRows,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TaskRecurrenceRuleRowsTableAnnotationComposer(
                $db: $db,
                $table: $db.taskRecurrenceRuleRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> taskRecurrenceExceptionRowsRefs<T extends Object>(
    Expression<T> Function(
      $$TaskRecurrenceExceptionRowsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$TaskRecurrenceExceptionRowsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.taskRecurrenceExceptionRows,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TaskRecurrenceExceptionRowsTableAnnotationComposer(
                $db: $db,
                $table: $db.taskRecurrenceExceptionRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> taskOccurrenceCompletionRowsRefs<T extends Object>(
    Expression<T> Function(
      $$TaskOccurrenceCompletionRowsTableAnnotationComposer a,
    )
    f,
  ) {
    final $$TaskOccurrenceCompletionRowsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.taskOccurrenceCompletionRows,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TaskOccurrenceCompletionRowsTableAnnotationComposer(
                $db: $db,
                $table: $db.taskOccurrenceCompletionRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> taskTimeEntryRowsRefs<T extends Object>(
    Expression<T> Function($$TaskTimeEntryRowsTableAnnotationComposer a) f,
  ) {
    final $$TaskTimeEntryRowsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.taskTimeEntryRows,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TaskTimeEntryRowsTableAnnotationComposer(
                $db: $db,
                $table: $db.taskTimeEntryRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TaskRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskRowsTable,
          TaskRow,
          $$TaskRowsTableFilterComposer,
          $$TaskRowsTableOrderingComposer,
          $$TaskRowsTableAnnotationComposer,
          $$TaskRowsTableCreateCompanionBuilder,
          $$TaskRowsTableUpdateCompanionBuilder,
          (TaskRow, $$TaskRowsTableReferences),
          TaskRow,
          PrefetchHooks Function({
            bool taskReminderRuleRowsRefs,
            bool taskRecurrenceRuleRowsRefs,
            bool taskRecurrenceExceptionRowsRefs,
            bool taskOccurrenceCompletionRowsRefs,
            bool taskTimeEntryRowsRefs,
          })
        > {
  $$TaskRowsTableTableManager(_$AppDatabase db, $TaskRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> displayNumber = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> positionInStatus = const Value.absent(),
                Value<DateTime?> startAtUtc = const Value.absent(),
                Value<DateTime?> dueAtUtc = const Value.absent(),
                Value<int?> estimatedDurationMinutes = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<DateTime?> completedAtUtc = const Value.absent(),
                Value<DateTime?> canceledAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRowsCompanion(
                id: id,
                displayNumber: displayNumber,
                title: title,
                description: description,
                priority: priority,
                status: status,
                positionInStatus: positionInStatus,
                startAtUtc: startAtUtc,
                dueAtUtc: dueAtUtc,
                estimatedDurationMinutes: estimatedDurationMinutes,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                completedAtUtc: completedAtUtc,
                canceledAtUtc: canceledAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int displayNumber,
                required String title,
                Value<String?> description = const Value.absent(),
                required int priority,
                required String status,
                required int positionInStatus,
                Value<DateTime?> startAtUtc = const Value.absent(),
                Value<DateTime?> dueAtUtc = const Value.absent(),
                Value<int?> estimatedDurationMinutes = const Value.absent(),
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<DateTime?> completedAtUtc = const Value.absent(),
                Value<DateTime?> canceledAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRowsCompanion.insert(
                id: id,
                displayNumber: displayNumber,
                title: title,
                description: description,
                priority: priority,
                status: status,
                positionInStatus: positionInStatus,
                startAtUtc: startAtUtc,
                dueAtUtc: dueAtUtc,
                estimatedDurationMinutes: estimatedDurationMinutes,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                completedAtUtc: completedAtUtc,
                canceledAtUtc: canceledAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                taskReminderRuleRowsRefs = false,
                taskRecurrenceRuleRowsRefs = false,
                taskRecurrenceExceptionRowsRefs = false,
                taskOccurrenceCompletionRowsRefs = false,
                taskTimeEntryRowsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (taskReminderRuleRowsRefs) db.taskReminderRuleRows,
                    if (taskRecurrenceRuleRowsRefs) db.taskRecurrenceRuleRows,
                    if (taskRecurrenceExceptionRowsRefs)
                      db.taskRecurrenceExceptionRows,
                    if (taskOccurrenceCompletionRowsRefs)
                      db.taskOccurrenceCompletionRows,
                    if (taskTimeEntryRowsRefs) db.taskTimeEntryRows,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (taskReminderRuleRowsRefs)
                        await $_getPrefetchedData<
                          TaskRow,
                          $TaskRowsTable,
                          TaskReminderRuleRow
                        >(
                          currentTable: table,
                          referencedTable: $$TaskRowsTableReferences
                              ._taskReminderRuleRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TaskRowsTableReferences(
                                db,
                                table,
                                p0,
                              ).taskReminderRuleRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskRecurrenceRuleRowsRefs)
                        await $_getPrefetchedData<
                          TaskRow,
                          $TaskRowsTable,
                          TaskRecurrenceRuleRow
                        >(
                          currentTable: table,
                          referencedTable: $$TaskRowsTableReferences
                              ._taskRecurrenceRuleRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TaskRowsTableReferences(
                                db,
                                table,
                                p0,
                              ).taskRecurrenceRuleRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskRecurrenceExceptionRowsRefs)
                        await $_getPrefetchedData<
                          TaskRow,
                          $TaskRowsTable,
                          TaskRecurrenceExceptionRow
                        >(
                          currentTable: table,
                          referencedTable: $$TaskRowsTableReferences
                              ._taskRecurrenceExceptionRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TaskRowsTableReferences(
                                db,
                                table,
                                p0,
                              ).taskRecurrenceExceptionRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskOccurrenceCompletionRowsRefs)
                        await $_getPrefetchedData<
                          TaskRow,
                          $TaskRowsTable,
                          TaskOccurrenceCompletionRow
                        >(
                          currentTable: table,
                          referencedTable: $$TaskRowsTableReferences
                              ._taskOccurrenceCompletionRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TaskRowsTableReferences(
                                db,
                                table,
                                p0,
                              ).taskOccurrenceCompletionRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskTimeEntryRowsRefs)
                        await $_getPrefetchedData<
                          TaskRow,
                          $TaskRowsTable,
                          TaskTimeEntryRow
                        >(
                          currentTable: table,
                          referencedTable: $$TaskRowsTableReferences
                              ._taskTimeEntryRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TaskRowsTableReferences(
                                db,
                                table,
                                p0,
                              ).taskTimeEntryRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskId == item.id,
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

typedef $$TaskRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskRowsTable,
      TaskRow,
      $$TaskRowsTableFilterComposer,
      $$TaskRowsTableOrderingComposer,
      $$TaskRowsTableAnnotationComposer,
      $$TaskRowsTableCreateCompanionBuilder,
      $$TaskRowsTableUpdateCompanionBuilder,
      (TaskRow, $$TaskRowsTableReferences),
      TaskRow,
      PrefetchHooks Function({
        bool taskReminderRuleRowsRefs,
        bool taskRecurrenceRuleRowsRefs,
        bool taskRecurrenceExceptionRowsRefs,
        bool taskOccurrenceCompletionRowsRefs,
        bool taskTimeEntryRowsRefs,
      })
    >;
typedef $$FinanceTransactionRowsTableCreateCompanionBuilder =
    FinanceTransactionRowsCompanion Function({
      required String id,
      required String type,
      required String title,
      required String category,
      required int amountMinorUnits,
      Value<String> currencyCode,
      Value<int> scale,
      required DateTime occurredAtUtc,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$FinanceTransactionRowsTableUpdateCompanionBuilder =
    FinanceTransactionRowsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<String> title,
      Value<String> category,
      Value<int> amountMinorUnits,
      Value<String> currencyCode,
      Value<int> scale,
      Value<DateTime> occurredAtUtc,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

class $$FinanceTransactionRowsTableFilterComposer
    extends Composer<_$AppDatabase, $FinanceTransactionRowsTable> {
  $$FinanceTransactionRowsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FinanceTransactionRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $FinanceTransactionRowsTable> {
  $$FinanceTransactionRowsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FinanceTransactionRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FinanceTransactionRowsTable> {
  $$FinanceTransactionRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scale =>
      $composableBuilder(column: $table.scale, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAtUtc => $composableBuilder(
    column: $table.occurredAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );
}

class $$FinanceTransactionRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FinanceTransactionRowsTable,
          FinanceTransactionRow,
          $$FinanceTransactionRowsTableFilterComposer,
          $$FinanceTransactionRowsTableOrderingComposer,
          $$FinanceTransactionRowsTableAnnotationComposer,
          $$FinanceTransactionRowsTableCreateCompanionBuilder,
          $$FinanceTransactionRowsTableUpdateCompanionBuilder,
          (
            FinanceTransactionRow,
            BaseReferences<
              _$AppDatabase,
              $FinanceTransactionRowsTable,
              FinanceTransactionRow
            >,
          ),
          FinanceTransactionRow,
          PrefetchHooks Function()
        > {
  $$FinanceTransactionRowsTableTableManager(
    _$AppDatabase db,
    $FinanceTransactionRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FinanceTransactionRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$FinanceTransactionRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$FinanceTransactionRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> amountMinorUnits = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> scale = const Value.absent(),
                Value<DateTime> occurredAtUtc = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FinanceTransactionRowsCompanion(
                id: id,
                type: type,
                title: title,
                category: category,
                amountMinorUnits: amountMinorUnits,
                currencyCode: currencyCode,
                scale: scale,
                occurredAtUtc: occurredAtUtc,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required String title,
                required String category,
                required int amountMinorUnits,
                Value<String> currencyCode = const Value.absent(),
                Value<int> scale = const Value.absent(),
                required DateTime occurredAtUtc,
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => FinanceTransactionRowsCompanion.insert(
                id: id,
                type: type,
                title: title,
                category: category,
                amountMinorUnits: amountMinorUnits,
                currencyCode: currencyCode,
                scale: scale,
                occurredAtUtc: occurredAtUtc,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FinanceTransactionRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FinanceTransactionRowsTable,
      FinanceTransactionRow,
      $$FinanceTransactionRowsTableFilterComposer,
      $$FinanceTransactionRowsTableOrderingComposer,
      $$FinanceTransactionRowsTableAnnotationComposer,
      $$FinanceTransactionRowsTableCreateCompanionBuilder,
      $$FinanceTransactionRowsTableUpdateCompanionBuilder,
      (
        FinanceTransactionRow,
        BaseReferences<
          _$AppDatabase,
          $FinanceTransactionRowsTable,
          FinanceTransactionRow
        >,
      ),
      FinanceTransactionRow,
      PrefetchHooks Function()
    >;
typedef $$DebtRowsTableCreateCompanionBuilder =
    DebtRowsCompanion Function({
      required String id,
      required String title,
      required int totalMinorUnits,
      Value<String> currencyCode,
      Value<int> scale,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<DateTime?> archivedAtUtc,
      Value<int> rowid,
    });
typedef $$DebtRowsTableUpdateCompanionBuilder =
    DebtRowsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<int> totalMinorUnits,
      Value<String> currencyCode,
      Value<int> scale,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<DateTime?> archivedAtUtc,
      Value<int> rowid,
    });

final class $$DebtRowsTableReferences
    extends BaseReferences<_$AppDatabase, $DebtRowsTable, DebtRow> {
  $$DebtRowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DebtPaymentRowsTable, List<DebtPaymentRow>>
  _debtPaymentRowsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.debtPaymentRows,
    aliasName: 'debts__id__debt_payments__debt_id',
  );

  $$DebtPaymentRowsTableProcessedTableManager get debtPaymentRowsRefs {
    final manager = $$DebtPaymentRowsTableTableManager(
      $_db,
      $_db.debtPaymentRows,
    ).filter((f) => f.debtId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _debtPaymentRowsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DebtRowsTableFilterComposer
    extends Composer<_$AppDatabase, $DebtRowsTable> {
  $$DebtRowsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalMinorUnits => $composableBuilder(
    column: $table.totalMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAtUtc => $composableBuilder(
    column: $table.archivedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> debtPaymentRowsRefs(
    Expression<bool> Function($$DebtPaymentRowsTableFilterComposer f) f,
  ) {
    final $$DebtPaymentRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.debtPaymentRows,
      getReferencedColumn: (t) => t.debtId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtPaymentRowsTableFilterComposer(
            $db: $db,
            $table: $db.debtPaymentRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DebtRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $DebtRowsTable> {
  $$DebtRowsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalMinorUnits => $composableBuilder(
    column: $table.totalMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAtUtc => $composableBuilder(
    column: $table.archivedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DebtRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DebtRowsTable> {
  $$DebtRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get totalMinorUnits => $composableBuilder(
    column: $table.totalMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scale =>
      $composableBuilder(column: $table.scale, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get archivedAtUtc => $composableBuilder(
    column: $table.archivedAtUtc,
    builder: (column) => column,
  );

  Expression<T> debtPaymentRowsRefs<T extends Object>(
    Expression<T> Function($$DebtPaymentRowsTableAnnotationComposer a) f,
  ) {
    final $$DebtPaymentRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.debtPaymentRows,
      getReferencedColumn: (t) => t.debtId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtPaymentRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.debtPaymentRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DebtRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DebtRowsTable,
          DebtRow,
          $$DebtRowsTableFilterComposer,
          $$DebtRowsTableOrderingComposer,
          $$DebtRowsTableAnnotationComposer,
          $$DebtRowsTableCreateCompanionBuilder,
          $$DebtRowsTableUpdateCompanionBuilder,
          (DebtRow, $$DebtRowsTableReferences),
          DebtRow,
          PrefetchHooks Function({bool debtPaymentRowsRefs})
        > {
  $$DebtRowsTableTableManager(_$AppDatabase db, $DebtRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DebtRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DebtRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DebtRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> totalMinorUnits = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> scale = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<DateTime?> archivedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DebtRowsCompanion(
                id: id,
                title: title,
                totalMinorUnits: totalMinorUnits,
                currencyCode: currencyCode,
                scale: scale,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                archivedAtUtc: archivedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required int totalMinorUnits,
                Value<String> currencyCode = const Value.absent(),
                Value<int> scale = const Value.absent(),
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<DateTime?> archivedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DebtRowsCompanion.insert(
                id: id,
                title: title,
                totalMinorUnits: totalMinorUnits,
                currencyCode: currencyCode,
                scale: scale,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                archivedAtUtc: archivedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DebtRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({debtPaymentRowsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (debtPaymentRowsRefs) db.debtPaymentRows,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (debtPaymentRowsRefs)
                    await $_getPrefetchedData<
                      DebtRow,
                      $DebtRowsTable,
                      DebtPaymentRow
                    >(
                      currentTable: table,
                      referencedTable: $$DebtRowsTableReferences
                          ._debtPaymentRowsRefsTable(db),
                      managerFromTypedResult: (p0) => $$DebtRowsTableReferences(
                        db,
                        table,
                        p0,
                      ).debtPaymentRowsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.debtId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DebtRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DebtRowsTable,
      DebtRow,
      $$DebtRowsTableFilterComposer,
      $$DebtRowsTableOrderingComposer,
      $$DebtRowsTableAnnotationComposer,
      $$DebtRowsTableCreateCompanionBuilder,
      $$DebtRowsTableUpdateCompanionBuilder,
      (DebtRow, $$DebtRowsTableReferences),
      DebtRow,
      PrefetchHooks Function({bool debtPaymentRowsRefs})
    >;
typedef $$DebtPaymentRowsTableCreateCompanionBuilder =
    DebtPaymentRowsCompanion Function({
      required String id,
      required String debtId,
      required int amountMinorUnits,
      required DateTime paidAtUtc,
      required DateTime createdAtUtc,
      Value<int> rowid,
    });
typedef $$DebtPaymentRowsTableUpdateCompanionBuilder =
    DebtPaymentRowsCompanion Function({
      Value<String> id,
      Value<String> debtId,
      Value<int> amountMinorUnits,
      Value<DateTime> paidAtUtc,
      Value<DateTime> createdAtUtc,
      Value<int> rowid,
    });

final class $$DebtPaymentRowsTableReferences
    extends
        BaseReferences<_$AppDatabase, $DebtPaymentRowsTable, DebtPaymentRow> {
  $$DebtPaymentRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DebtRowsTable _debtIdTable(_$AppDatabase db) =>
      db.debtRows.createAlias('debt_payments__debt_id__debts__id');

  $$DebtRowsTableProcessedTableManager get debtId {
    final $_column = $_itemColumn<String>('debt_id')!;

    final manager = $$DebtRowsTableTableManager(
      $_db,
      $_db.debtRows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_debtIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DebtPaymentRowsTableFilterComposer
    extends Composer<_$AppDatabase, $DebtPaymentRowsTable> {
  $$DebtPaymentRowsTableFilterComposer({
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

  ColumnFilters<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paidAtUtc => $composableBuilder(
    column: $table.paidAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$DebtRowsTableFilterComposer get debtId {
    final $$DebtRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.debtId,
      referencedTable: $db.debtRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtRowsTableFilterComposer(
            $db: $db,
            $table: $db.debtRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DebtPaymentRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $DebtPaymentRowsTable> {
  $$DebtPaymentRowsTableOrderingComposer({
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

  ColumnOrderings<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paidAtUtc => $composableBuilder(
    column: $table.paidAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$DebtRowsTableOrderingComposer get debtId {
    final $$DebtRowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.debtId,
      referencedTable: $db.debtRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtRowsTableOrderingComposer(
            $db: $db,
            $table: $db.debtRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DebtPaymentRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DebtPaymentRowsTable> {
  $$DebtPaymentRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get paidAtUtc =>
      $composableBuilder(column: $table.paidAtUtc, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  $$DebtRowsTableAnnotationComposer get debtId {
    final $$DebtRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.debtId,
      referencedTable: $db.debtRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DebtRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.debtRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DebtPaymentRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DebtPaymentRowsTable,
          DebtPaymentRow,
          $$DebtPaymentRowsTableFilterComposer,
          $$DebtPaymentRowsTableOrderingComposer,
          $$DebtPaymentRowsTableAnnotationComposer,
          $$DebtPaymentRowsTableCreateCompanionBuilder,
          $$DebtPaymentRowsTableUpdateCompanionBuilder,
          (DebtPaymentRow, $$DebtPaymentRowsTableReferences),
          DebtPaymentRow,
          PrefetchHooks Function({bool debtId})
        > {
  $$DebtPaymentRowsTableTableManager(
    _$AppDatabase db,
    $DebtPaymentRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DebtPaymentRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DebtPaymentRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DebtPaymentRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> debtId = const Value.absent(),
                Value<int> amountMinorUnits = const Value.absent(),
                Value<DateTime> paidAtUtc = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DebtPaymentRowsCompanion(
                id: id,
                debtId: debtId,
                amountMinorUnits: amountMinorUnits,
                paidAtUtc: paidAtUtc,
                createdAtUtc: createdAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String debtId,
                required int amountMinorUnits,
                required DateTime paidAtUtc,
                required DateTime createdAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => DebtPaymentRowsCompanion.insert(
                id: id,
                debtId: debtId,
                amountMinorUnits: amountMinorUnits,
                paidAtUtc: paidAtUtc,
                createdAtUtc: createdAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DebtPaymentRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({debtId = false}) {
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
                    if (debtId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.debtId,
                                referencedTable:
                                    $$DebtPaymentRowsTableReferences
                                        ._debtIdTable(db),
                                referencedColumn:
                                    $$DebtPaymentRowsTableReferences
                                        ._debtIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$DebtPaymentRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DebtPaymentRowsTable,
      DebtPaymentRow,
      $$DebtPaymentRowsTableFilterComposer,
      $$DebtPaymentRowsTableOrderingComposer,
      $$DebtPaymentRowsTableAnnotationComposer,
      $$DebtPaymentRowsTableCreateCompanionBuilder,
      $$DebtPaymentRowsTableUpdateCompanionBuilder,
      (DebtPaymentRow, $$DebtPaymentRowsTableReferences),
      DebtPaymentRow,
      PrefetchHooks Function({bool debtId})
    >;
typedef $$InstallmentPlanRowsTableCreateCompanionBuilder =
    InstallmentPlanRowsCompanion Function({
      required String id,
      required String title,
      required int perInstallmentMinorUnits,
      required int installmentCount,
      Value<String> currencyCode,
      Value<int> scale,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<DateTime?> archivedAtUtc,
      Value<int> rowid,
    });
typedef $$InstallmentPlanRowsTableUpdateCompanionBuilder =
    InstallmentPlanRowsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<int> perInstallmentMinorUnits,
      Value<int> installmentCount,
      Value<String> currencyCode,
      Value<int> scale,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<DateTime?> archivedAtUtc,
      Value<int> rowid,
    });

final class $$InstallmentPlanRowsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $InstallmentPlanRowsTable,
          InstallmentPlanRow
        > {
  $$InstallmentPlanRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $InstallmentPaymentRowsTable,
    List<InstallmentPaymentRow>
  >
  _installmentPaymentRowsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.installmentPaymentRows,
        aliasName: 'installment_plans__id__installment_payments__plan_id',
      );

  $$InstallmentPaymentRowsTableProcessedTableManager
  get installmentPaymentRowsRefs {
    final manager = $$InstallmentPaymentRowsTableTableManager(
      $_db,
      $_db.installmentPaymentRows,
    ).filter((f) => f.planId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _installmentPaymentRowsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InstallmentPlanRowsTableFilterComposer
    extends Composer<_$AppDatabase, $InstallmentPlanRowsTable> {
  $$InstallmentPlanRowsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get perInstallmentMinorUnits => $composableBuilder(
    column: $table.perInstallmentMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get installmentCount => $composableBuilder(
    column: $table.installmentCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAtUtc => $composableBuilder(
    column: $table.archivedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> installmentPaymentRowsRefs(
    Expression<bool> Function($$InstallmentPaymentRowsTableFilterComposer f) f,
  ) {
    final $$InstallmentPaymentRowsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.installmentPaymentRows,
          getReferencedColumn: (t) => t.planId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InstallmentPaymentRowsTableFilterComposer(
                $db: $db,
                $table: $db.installmentPaymentRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$InstallmentPlanRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $InstallmentPlanRowsTable> {
  $$InstallmentPlanRowsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get perInstallmentMinorUnits => $composableBuilder(
    column: $table.perInstallmentMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get installmentCount => $composableBuilder(
    column: $table.installmentCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAtUtc => $composableBuilder(
    column: $table.archivedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InstallmentPlanRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstallmentPlanRowsTable> {
  $$InstallmentPlanRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get perInstallmentMinorUnits => $composableBuilder(
    column: $table.perInstallmentMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get installmentCount => $composableBuilder(
    column: $table.installmentCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scale =>
      $composableBuilder(column: $table.scale, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get archivedAtUtc => $composableBuilder(
    column: $table.archivedAtUtc,
    builder: (column) => column,
  );

  Expression<T> installmentPaymentRowsRefs<T extends Object>(
    Expression<T> Function($$InstallmentPaymentRowsTableAnnotationComposer a) f,
  ) {
    final $$InstallmentPaymentRowsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.installmentPaymentRows,
          getReferencedColumn: (t) => t.planId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InstallmentPaymentRowsTableAnnotationComposer(
                $db: $db,
                $table: $db.installmentPaymentRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$InstallmentPlanRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstallmentPlanRowsTable,
          InstallmentPlanRow,
          $$InstallmentPlanRowsTableFilterComposer,
          $$InstallmentPlanRowsTableOrderingComposer,
          $$InstallmentPlanRowsTableAnnotationComposer,
          $$InstallmentPlanRowsTableCreateCompanionBuilder,
          $$InstallmentPlanRowsTableUpdateCompanionBuilder,
          (InstallmentPlanRow, $$InstallmentPlanRowsTableReferences),
          InstallmentPlanRow,
          PrefetchHooks Function({bool installmentPaymentRowsRefs})
        > {
  $$InstallmentPlanRowsTableTableManager(
    _$AppDatabase db,
    $InstallmentPlanRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstallmentPlanRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstallmentPlanRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InstallmentPlanRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> perInstallmentMinorUnits = const Value.absent(),
                Value<int> installmentCount = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> scale = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<DateTime?> archivedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstallmentPlanRowsCompanion(
                id: id,
                title: title,
                perInstallmentMinorUnits: perInstallmentMinorUnits,
                installmentCount: installmentCount,
                currencyCode: currencyCode,
                scale: scale,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                archivedAtUtc: archivedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required int perInstallmentMinorUnits,
                required int installmentCount,
                Value<String> currencyCode = const Value.absent(),
                Value<int> scale = const Value.absent(),
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<DateTime?> archivedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstallmentPlanRowsCompanion.insert(
                id: id,
                title: title,
                perInstallmentMinorUnits: perInstallmentMinorUnits,
                installmentCount: installmentCount,
                currencyCode: currencyCode,
                scale: scale,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                archivedAtUtc: archivedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InstallmentPlanRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({installmentPaymentRowsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (installmentPaymentRowsRefs) db.installmentPaymentRows,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (installmentPaymentRowsRefs)
                    await $_getPrefetchedData<
                      InstallmentPlanRow,
                      $InstallmentPlanRowsTable,
                      InstallmentPaymentRow
                    >(
                      currentTable: table,
                      referencedTable: $$InstallmentPlanRowsTableReferences
                          ._installmentPaymentRowsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$InstallmentPlanRowsTableReferences(
                            db,
                            table,
                            p0,
                          ).installmentPaymentRowsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.planId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$InstallmentPlanRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstallmentPlanRowsTable,
      InstallmentPlanRow,
      $$InstallmentPlanRowsTableFilterComposer,
      $$InstallmentPlanRowsTableOrderingComposer,
      $$InstallmentPlanRowsTableAnnotationComposer,
      $$InstallmentPlanRowsTableCreateCompanionBuilder,
      $$InstallmentPlanRowsTableUpdateCompanionBuilder,
      (InstallmentPlanRow, $$InstallmentPlanRowsTableReferences),
      InstallmentPlanRow,
      PrefetchHooks Function({bool installmentPaymentRowsRefs})
    >;
typedef $$InstallmentPaymentRowsTableCreateCompanionBuilder =
    InstallmentPaymentRowsCompanion Function({
      required String id,
      required String planId,
      required int installmentNumber,
      required int amountMinorUnits,
      required DateTime paidAtUtc,
      required DateTime createdAtUtc,
      Value<int> rowid,
    });
typedef $$InstallmentPaymentRowsTableUpdateCompanionBuilder =
    InstallmentPaymentRowsCompanion Function({
      Value<String> id,
      Value<String> planId,
      Value<int> installmentNumber,
      Value<int> amountMinorUnits,
      Value<DateTime> paidAtUtc,
      Value<DateTime> createdAtUtc,
      Value<int> rowid,
    });

final class $$InstallmentPaymentRowsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $InstallmentPaymentRowsTable,
          InstallmentPaymentRow
        > {
  $$InstallmentPaymentRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $InstallmentPlanRowsTable _planIdTable(_$AppDatabase db) => db
      .installmentPlanRows
      .createAlias('installment_payments__plan_id__installment_plans__id');

  $$InstallmentPlanRowsTableProcessedTableManager get planId {
    final $_column = $_itemColumn<String>('plan_id')!;

    final manager = $$InstallmentPlanRowsTableTableManager(
      $_db,
      $_db.installmentPlanRows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InstallmentPaymentRowsTableFilterComposer
    extends Composer<_$AppDatabase, $InstallmentPaymentRowsTable> {
  $$InstallmentPaymentRowsTableFilterComposer({
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

  ColumnFilters<int> get installmentNumber => $composableBuilder(
    column: $table.installmentNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get paidAtUtc => $composableBuilder(
    column: $table.paidAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$InstallmentPlanRowsTableFilterComposer get planId {
    final $$InstallmentPlanRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.installmentPlanRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstallmentPlanRowsTableFilterComposer(
            $db: $db,
            $table: $db.installmentPlanRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InstallmentPaymentRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $InstallmentPaymentRowsTable> {
  $$InstallmentPaymentRowsTableOrderingComposer({
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

  ColumnOrderings<int> get installmentNumber => $composableBuilder(
    column: $table.installmentNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paidAtUtc => $composableBuilder(
    column: $table.paidAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$InstallmentPlanRowsTableOrderingComposer get planId {
    final $$InstallmentPlanRowsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.planId,
          referencedTable: $db.installmentPlanRows,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InstallmentPlanRowsTableOrderingComposer(
                $db: $db,
                $table: $db.installmentPlanRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$InstallmentPaymentRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstallmentPaymentRowsTable> {
  $$InstallmentPaymentRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get installmentNumber => $composableBuilder(
    column: $table.installmentNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountMinorUnits => $composableBuilder(
    column: $table.amountMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get paidAtUtc =>
      $composableBuilder(column: $table.paidAtUtc, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  $$InstallmentPlanRowsTableAnnotationComposer get planId {
    final $$InstallmentPlanRowsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.planId,
          referencedTable: $db.installmentPlanRows,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$InstallmentPlanRowsTableAnnotationComposer(
                $db: $db,
                $table: $db.installmentPlanRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$InstallmentPaymentRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstallmentPaymentRowsTable,
          InstallmentPaymentRow,
          $$InstallmentPaymentRowsTableFilterComposer,
          $$InstallmentPaymentRowsTableOrderingComposer,
          $$InstallmentPaymentRowsTableAnnotationComposer,
          $$InstallmentPaymentRowsTableCreateCompanionBuilder,
          $$InstallmentPaymentRowsTableUpdateCompanionBuilder,
          (InstallmentPaymentRow, $$InstallmentPaymentRowsTableReferences),
          InstallmentPaymentRow,
          PrefetchHooks Function({bool planId})
        > {
  $$InstallmentPaymentRowsTableTableManager(
    _$AppDatabase db,
    $InstallmentPaymentRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstallmentPaymentRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$InstallmentPaymentRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$InstallmentPaymentRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<int> installmentNumber = const Value.absent(),
                Value<int> amountMinorUnits = const Value.absent(),
                Value<DateTime> paidAtUtc = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstallmentPaymentRowsCompanion(
                id: id,
                planId: planId,
                installmentNumber: installmentNumber,
                amountMinorUnits: amountMinorUnits,
                paidAtUtc: paidAtUtc,
                createdAtUtc: createdAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String planId,
                required int installmentNumber,
                required int amountMinorUnits,
                required DateTime paidAtUtc,
                required DateTime createdAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => InstallmentPaymentRowsCompanion.insert(
                id: id,
                planId: planId,
                installmentNumber: installmentNumber,
                amountMinorUnits: amountMinorUnits,
                paidAtUtc: paidAtUtc,
                createdAtUtc: createdAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$InstallmentPaymentRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({planId = false}) {
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
                    if (planId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.planId,
                                referencedTable:
                                    $$InstallmentPaymentRowsTableReferences
                                        ._planIdTable(db),
                                referencedColumn:
                                    $$InstallmentPaymentRowsTableReferences
                                        ._planIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$InstallmentPaymentRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstallmentPaymentRowsTable,
      InstallmentPaymentRow,
      $$InstallmentPaymentRowsTableFilterComposer,
      $$InstallmentPaymentRowsTableOrderingComposer,
      $$InstallmentPaymentRowsTableAnnotationComposer,
      $$InstallmentPaymentRowsTableCreateCompanionBuilder,
      $$InstallmentPaymentRowsTableUpdateCompanionBuilder,
      (InstallmentPaymentRow, $$InstallmentPaymentRowsTableReferences),
      InstallmentPaymentRow,
      PrefetchHooks Function({bool planId})
    >;
typedef $$TaskReminderRuleRowsTableCreateCompanionBuilder =
    TaskReminderRuleRowsCompanion Function({
      required String id,
      required String taskId,
      required String trigger,
      Value<bool> enabled,
      Value<String> privacyMode,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$TaskReminderRuleRowsTableUpdateCompanionBuilder =
    TaskReminderRuleRowsCompanion Function({
      Value<String> id,
      Value<String> taskId,
      Value<String> trigger,
      Value<bool> enabled,
      Value<String> privacyMode,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

final class $$TaskReminderRuleRowsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TaskReminderRuleRowsTable,
          TaskReminderRuleRow
        > {
  $$TaskReminderRuleRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TaskRowsTable _taskIdTable(_$AppDatabase db) =>
      db.taskRows.createAlias('task_reminder_rules__task_id__tasks__id');

  $$TaskRowsTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TaskRowsTableTableManager(
      $_db,
      $_db.taskRows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskReminderRuleRowsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskReminderRuleRowsTable> {
  $$TaskReminderRuleRowsTableFilterComposer({
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

  ColumnFilters<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get privacyMode => $composableBuilder(
    column: $table.privacyMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$TaskRowsTableFilterComposer get taskId {
    final $$TaskRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRowsTableFilterComposer(
            $db: $db,
            $table: $db.taskRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskReminderRuleRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskReminderRuleRowsTable> {
  $$TaskReminderRuleRowsTableOrderingComposer({
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

  ColumnOrderings<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get privacyMode => $composableBuilder(
    column: $table.privacyMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$TaskRowsTableOrderingComposer get taskId {
    final $$TaskRowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRowsTableOrderingComposer(
            $db: $db,
            $table: $db.taskRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskReminderRuleRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskReminderRuleRowsTable> {
  $$TaskReminderRuleRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get trigger =>
      $composableBuilder(column: $table.trigger, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get privacyMode => $composableBuilder(
    column: $table.privacyMode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  $$TaskRowsTableAnnotationComposer get taskId {
    final $$TaskRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskReminderRuleRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskReminderRuleRowsTable,
          TaskReminderRuleRow,
          $$TaskReminderRuleRowsTableFilterComposer,
          $$TaskReminderRuleRowsTableOrderingComposer,
          $$TaskReminderRuleRowsTableAnnotationComposer,
          $$TaskReminderRuleRowsTableCreateCompanionBuilder,
          $$TaskReminderRuleRowsTableUpdateCompanionBuilder,
          (TaskReminderRuleRow, $$TaskReminderRuleRowsTableReferences),
          TaskReminderRuleRow,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskReminderRuleRowsTableTableManager(
    _$AppDatabase db,
    $TaskReminderRuleRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskReminderRuleRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskReminderRuleRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TaskReminderRuleRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> trigger = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String> privacyMode = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskReminderRuleRowsCompanion(
                id: id,
                taskId: taskId,
                trigger: trigger,
                enabled: enabled,
                privacyMode: privacyMode,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required String trigger,
                Value<bool> enabled = const Value.absent(),
                Value<String> privacyMode = const Value.absent(),
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => TaskReminderRuleRowsCompanion.insert(
                id: id,
                taskId: taskId,
                trigger: trigger,
                enabled: enabled,
                privacyMode: privacyMode,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskReminderRuleRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
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
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable:
                                    $$TaskReminderRuleRowsTableReferences
                                        ._taskIdTable(db),
                                referencedColumn:
                                    $$TaskReminderRuleRowsTableReferences
                                        ._taskIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$TaskReminderRuleRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskReminderRuleRowsTable,
      TaskReminderRuleRow,
      $$TaskReminderRuleRowsTableFilterComposer,
      $$TaskReminderRuleRowsTableOrderingComposer,
      $$TaskReminderRuleRowsTableAnnotationComposer,
      $$TaskReminderRuleRowsTableCreateCompanionBuilder,
      $$TaskReminderRuleRowsTableUpdateCompanionBuilder,
      (TaskReminderRuleRow, $$TaskReminderRuleRowsTableReferences),
      TaskReminderRuleRow,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$TaskRecurrenceRuleRowsTableCreateCompanionBuilder =
    TaskRecurrenceRuleRowsCompanion Function({
      required String id,
      required String taskId,
      required String ruleJson,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$TaskRecurrenceRuleRowsTableUpdateCompanionBuilder =
    TaskRecurrenceRuleRowsCompanion Function({
      Value<String> id,
      Value<String> taskId,
      Value<String> ruleJson,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

final class $$TaskRecurrenceRuleRowsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TaskRecurrenceRuleRowsTable,
          TaskRecurrenceRuleRow
        > {
  $$TaskRecurrenceRuleRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TaskRowsTable _taskIdTable(_$AppDatabase db) =>
      db.taskRows.createAlias('task_recurrence_rules__task_id__tasks__id');

  $$TaskRowsTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TaskRowsTableTableManager(
      $_db,
      $_db.taskRows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskRecurrenceRuleRowsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskRecurrenceRuleRowsTable> {
  $$TaskRecurrenceRuleRowsTableFilterComposer({
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

  ColumnFilters<String> get ruleJson => $composableBuilder(
    column: $table.ruleJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$TaskRowsTableFilterComposer get taskId {
    final $$TaskRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRowsTableFilterComposer(
            $db: $db,
            $table: $db.taskRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRecurrenceRuleRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskRecurrenceRuleRowsTable> {
  $$TaskRecurrenceRuleRowsTableOrderingComposer({
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

  ColumnOrderings<String> get ruleJson => $composableBuilder(
    column: $table.ruleJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$TaskRowsTableOrderingComposer get taskId {
    final $$TaskRowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRowsTableOrderingComposer(
            $db: $db,
            $table: $db.taskRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRecurrenceRuleRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskRecurrenceRuleRowsTable> {
  $$TaskRecurrenceRuleRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ruleJson =>
      $composableBuilder(column: $table.ruleJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  $$TaskRowsTableAnnotationComposer get taskId {
    final $$TaskRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRecurrenceRuleRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskRecurrenceRuleRowsTable,
          TaskRecurrenceRuleRow,
          $$TaskRecurrenceRuleRowsTableFilterComposer,
          $$TaskRecurrenceRuleRowsTableOrderingComposer,
          $$TaskRecurrenceRuleRowsTableAnnotationComposer,
          $$TaskRecurrenceRuleRowsTableCreateCompanionBuilder,
          $$TaskRecurrenceRuleRowsTableUpdateCompanionBuilder,
          (TaskRecurrenceRuleRow, $$TaskRecurrenceRuleRowsTableReferences),
          TaskRecurrenceRuleRow,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskRecurrenceRuleRowsTableTableManager(
    _$AppDatabase db,
    $TaskRecurrenceRuleRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskRecurrenceRuleRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TaskRecurrenceRuleRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TaskRecurrenceRuleRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> ruleJson = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRecurrenceRuleRowsCompanion(
                id: id,
                taskId: taskId,
                ruleJson: ruleJson,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required String ruleJson,
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => TaskRecurrenceRuleRowsCompanion.insert(
                id: id,
                taskId: taskId,
                ruleJson: ruleJson,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskRecurrenceRuleRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
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
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable:
                                    $$TaskRecurrenceRuleRowsTableReferences
                                        ._taskIdTable(db),
                                referencedColumn:
                                    $$TaskRecurrenceRuleRowsTableReferences
                                        ._taskIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$TaskRecurrenceRuleRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskRecurrenceRuleRowsTable,
      TaskRecurrenceRuleRow,
      $$TaskRecurrenceRuleRowsTableFilterComposer,
      $$TaskRecurrenceRuleRowsTableOrderingComposer,
      $$TaskRecurrenceRuleRowsTableAnnotationComposer,
      $$TaskRecurrenceRuleRowsTableCreateCompanionBuilder,
      $$TaskRecurrenceRuleRowsTableUpdateCompanionBuilder,
      (TaskRecurrenceRuleRow, $$TaskRecurrenceRuleRowsTableReferences),
      TaskRecurrenceRuleRow,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$TaskRecurrenceExceptionRowsTableCreateCompanionBuilder =
    TaskRecurrenceExceptionRowsCompanion Function({
      required String id,
      required String taskId,
      required String originalLocalKey,
      required String exceptionJson,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$TaskRecurrenceExceptionRowsTableUpdateCompanionBuilder =
    TaskRecurrenceExceptionRowsCompanion Function({
      Value<String> id,
      Value<String> taskId,
      Value<String> originalLocalKey,
      Value<String> exceptionJson,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

final class $$TaskRecurrenceExceptionRowsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TaskRecurrenceExceptionRowsTable,
          TaskRecurrenceExceptionRow
        > {
  $$TaskRecurrenceExceptionRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TaskRowsTable _taskIdTable(_$AppDatabase db) =>
      db.taskRows.createAlias('task_recurrence_exceptions__task_id__tasks__id');

  $$TaskRowsTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TaskRowsTableTableManager(
      $_db,
      $_db.taskRows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskRecurrenceExceptionRowsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskRecurrenceExceptionRowsTable> {
  $$TaskRecurrenceExceptionRowsTableFilterComposer({
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

  ColumnFilters<String> get originalLocalKey => $composableBuilder(
    column: $table.originalLocalKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exceptionJson => $composableBuilder(
    column: $table.exceptionJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$TaskRowsTableFilterComposer get taskId {
    final $$TaskRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRowsTableFilterComposer(
            $db: $db,
            $table: $db.taskRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRecurrenceExceptionRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskRecurrenceExceptionRowsTable> {
  $$TaskRecurrenceExceptionRowsTableOrderingComposer({
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

  ColumnOrderings<String> get originalLocalKey => $composableBuilder(
    column: $table.originalLocalKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exceptionJson => $composableBuilder(
    column: $table.exceptionJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$TaskRowsTableOrderingComposer get taskId {
    final $$TaskRowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRowsTableOrderingComposer(
            $db: $db,
            $table: $db.taskRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRecurrenceExceptionRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskRecurrenceExceptionRowsTable> {
  $$TaskRecurrenceExceptionRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get originalLocalKey => $composableBuilder(
    column: $table.originalLocalKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exceptionJson => $composableBuilder(
    column: $table.exceptionJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  $$TaskRowsTableAnnotationComposer get taskId {
    final $$TaskRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRecurrenceExceptionRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskRecurrenceExceptionRowsTable,
          TaskRecurrenceExceptionRow,
          $$TaskRecurrenceExceptionRowsTableFilterComposer,
          $$TaskRecurrenceExceptionRowsTableOrderingComposer,
          $$TaskRecurrenceExceptionRowsTableAnnotationComposer,
          $$TaskRecurrenceExceptionRowsTableCreateCompanionBuilder,
          $$TaskRecurrenceExceptionRowsTableUpdateCompanionBuilder,
          (
            TaskRecurrenceExceptionRow,
            $$TaskRecurrenceExceptionRowsTableReferences,
          ),
          TaskRecurrenceExceptionRow,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskRecurrenceExceptionRowsTableTableManager(
    _$AppDatabase db,
    $TaskRecurrenceExceptionRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskRecurrenceExceptionRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TaskRecurrenceExceptionRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TaskRecurrenceExceptionRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> originalLocalKey = const Value.absent(),
                Value<String> exceptionJson = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRecurrenceExceptionRowsCompanion(
                id: id,
                taskId: taskId,
                originalLocalKey: originalLocalKey,
                exceptionJson: exceptionJson,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required String originalLocalKey,
                required String exceptionJson,
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => TaskRecurrenceExceptionRowsCompanion.insert(
                id: id,
                taskId: taskId,
                originalLocalKey: originalLocalKey,
                exceptionJson: exceptionJson,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskRecurrenceExceptionRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
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
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable:
                                    $$TaskRecurrenceExceptionRowsTableReferences
                                        ._taskIdTable(db),
                                referencedColumn:
                                    $$TaskRecurrenceExceptionRowsTableReferences
                                        ._taskIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$TaskRecurrenceExceptionRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskRecurrenceExceptionRowsTable,
      TaskRecurrenceExceptionRow,
      $$TaskRecurrenceExceptionRowsTableFilterComposer,
      $$TaskRecurrenceExceptionRowsTableOrderingComposer,
      $$TaskRecurrenceExceptionRowsTableAnnotationComposer,
      $$TaskRecurrenceExceptionRowsTableCreateCompanionBuilder,
      $$TaskRecurrenceExceptionRowsTableUpdateCompanionBuilder,
      (
        TaskRecurrenceExceptionRow,
        $$TaskRecurrenceExceptionRowsTableReferences,
      ),
      TaskRecurrenceExceptionRow,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$TaskOccurrenceCompletionRowsTableCreateCompanionBuilder =
    TaskOccurrenceCompletionRowsCompanion Function({
      required String taskId,
      required String originalLocalKey,
      required DateTime completedAtUtc,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$TaskOccurrenceCompletionRowsTableUpdateCompanionBuilder =
    TaskOccurrenceCompletionRowsCompanion Function({
      Value<String> taskId,
      Value<String> originalLocalKey,
      Value<DateTime> completedAtUtc,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

final class $$TaskOccurrenceCompletionRowsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TaskOccurrenceCompletionRowsTable,
          TaskOccurrenceCompletionRow
        > {
  $$TaskOccurrenceCompletionRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TaskRowsTable _taskIdTable(_$AppDatabase db) => db.taskRows
      .createAlias('task_occurrence_completions__task_id__tasks__id');

  $$TaskRowsTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TaskRowsTableTableManager(
      $_db,
      $_db.taskRows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskOccurrenceCompletionRowsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskOccurrenceCompletionRowsTable> {
  $$TaskOccurrenceCompletionRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get originalLocalKey => $composableBuilder(
    column: $table.originalLocalKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAtUtc => $composableBuilder(
    column: $table.completedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$TaskRowsTableFilterComposer get taskId {
    final $$TaskRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRowsTableFilterComposer(
            $db: $db,
            $table: $db.taskRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskOccurrenceCompletionRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskOccurrenceCompletionRowsTable> {
  $$TaskOccurrenceCompletionRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get originalLocalKey => $composableBuilder(
    column: $table.originalLocalKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAtUtc => $composableBuilder(
    column: $table.completedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$TaskRowsTableOrderingComposer get taskId {
    final $$TaskRowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRowsTableOrderingComposer(
            $db: $db,
            $table: $db.taskRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskOccurrenceCompletionRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskOccurrenceCompletionRowsTable> {
  $$TaskOccurrenceCompletionRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get originalLocalKey => $composableBuilder(
    column: $table.originalLocalKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAtUtc => $composableBuilder(
    column: $table.completedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  $$TaskRowsTableAnnotationComposer get taskId {
    final $$TaskRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskOccurrenceCompletionRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskOccurrenceCompletionRowsTable,
          TaskOccurrenceCompletionRow,
          $$TaskOccurrenceCompletionRowsTableFilterComposer,
          $$TaskOccurrenceCompletionRowsTableOrderingComposer,
          $$TaskOccurrenceCompletionRowsTableAnnotationComposer,
          $$TaskOccurrenceCompletionRowsTableCreateCompanionBuilder,
          $$TaskOccurrenceCompletionRowsTableUpdateCompanionBuilder,
          (
            TaskOccurrenceCompletionRow,
            $$TaskOccurrenceCompletionRowsTableReferences,
          ),
          TaskOccurrenceCompletionRow,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskOccurrenceCompletionRowsTableTableManager(
    _$AppDatabase db,
    $TaskOccurrenceCompletionRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskOccurrenceCompletionRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TaskOccurrenceCompletionRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TaskOccurrenceCompletionRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> taskId = const Value.absent(),
                Value<String> originalLocalKey = const Value.absent(),
                Value<DateTime> completedAtUtc = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskOccurrenceCompletionRowsCompanion(
                taskId: taskId,
                originalLocalKey: originalLocalKey,
                completedAtUtc: completedAtUtc,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String taskId,
                required String originalLocalKey,
                required DateTime completedAtUtc,
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => TaskOccurrenceCompletionRowsCompanion.insert(
                taskId: taskId,
                originalLocalKey: originalLocalKey,
                completedAtUtc: completedAtUtc,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskOccurrenceCompletionRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
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
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable:
                                    $$TaskOccurrenceCompletionRowsTableReferences
                                        ._taskIdTable(db),
                                referencedColumn:
                                    $$TaskOccurrenceCompletionRowsTableReferences
                                        ._taskIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$TaskOccurrenceCompletionRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskOccurrenceCompletionRowsTable,
      TaskOccurrenceCompletionRow,
      $$TaskOccurrenceCompletionRowsTableFilterComposer,
      $$TaskOccurrenceCompletionRowsTableOrderingComposer,
      $$TaskOccurrenceCompletionRowsTableAnnotationComposer,
      $$TaskOccurrenceCompletionRowsTableCreateCompanionBuilder,
      $$TaskOccurrenceCompletionRowsTableUpdateCompanionBuilder,
      (
        TaskOccurrenceCompletionRow,
        $$TaskOccurrenceCompletionRowsTableReferences,
      ),
      TaskOccurrenceCompletionRow,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$TaskTimeEntryRowsTableCreateCompanionBuilder =
    TaskTimeEntryRowsCompanion Function({
      required String id,
      required String taskId,
      required String source,
      required String state,
      required DateTime startedAtUtc,
      Value<DateTime?> lastResumedAtUtc,
      Value<DateTime?> endedAtUtc,
      required int accumulatedSeconds,
      Value<int?> activeSlot,
      Value<String?> note,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$TaskTimeEntryRowsTableUpdateCompanionBuilder =
    TaskTimeEntryRowsCompanion Function({
      Value<String> id,
      Value<String> taskId,
      Value<String> source,
      Value<String> state,
      Value<DateTime> startedAtUtc,
      Value<DateTime?> lastResumedAtUtc,
      Value<DateTime?> endedAtUtc,
      Value<int> accumulatedSeconds,
      Value<int?> activeSlot,
      Value<String?> note,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

final class $$TaskTimeEntryRowsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TaskTimeEntryRowsTable,
          TaskTimeEntryRow
        > {
  $$TaskTimeEntryRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TaskRowsTable _taskIdTable(_$AppDatabase db) =>
      db.taskRows.createAlias('task_time_entries__task_id__tasks__id');

  $$TaskRowsTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TaskRowsTableTableManager(
      $_db,
      $_db.taskRows,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskTimeEntryRowsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskTimeEntryRowsTable> {
  $$TaskTimeEntryRowsTableFilterComposer({
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

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAtUtc => $composableBuilder(
    column: $table.startedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastResumedAtUtc => $composableBuilder(
    column: $table.lastResumedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAtUtc => $composableBuilder(
    column: $table.endedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get accumulatedSeconds => $composableBuilder(
    column: $table.accumulatedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activeSlot => $composableBuilder(
    column: $table.activeSlot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  $$TaskRowsTableFilterComposer get taskId {
    final $$TaskRowsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRowsTableFilterComposer(
            $db: $db,
            $table: $db.taskRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskTimeEntryRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskTimeEntryRowsTable> {
  $$TaskTimeEntryRowsTableOrderingComposer({
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

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAtUtc => $composableBuilder(
    column: $table.startedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastResumedAtUtc => $composableBuilder(
    column: $table.lastResumedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAtUtc => $composableBuilder(
    column: $table.endedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get accumulatedSeconds => $composableBuilder(
    column: $table.accumulatedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activeSlot => $composableBuilder(
    column: $table.activeSlot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$TaskRowsTableOrderingComposer get taskId {
    final $$TaskRowsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRowsTableOrderingComposer(
            $db: $db,
            $table: $db.taskRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskTimeEntryRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskTimeEntryRowsTable> {
  $$TaskTimeEntryRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAtUtc => $composableBuilder(
    column: $table.startedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastResumedAtUtc => $composableBuilder(
    column: $table.lastResumedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get endedAtUtc => $composableBuilder(
    column: $table.endedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<int> get accumulatedSeconds => $composableBuilder(
    column: $table.accumulatedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get activeSlot => $composableBuilder(
    column: $table.activeSlot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );

  $$TaskRowsTableAnnotationComposer get taskId {
    final $$TaskRowsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.taskRows,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRowsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskRows,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskTimeEntryRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskTimeEntryRowsTable,
          TaskTimeEntryRow,
          $$TaskTimeEntryRowsTableFilterComposer,
          $$TaskTimeEntryRowsTableOrderingComposer,
          $$TaskTimeEntryRowsTableAnnotationComposer,
          $$TaskTimeEntryRowsTableCreateCompanionBuilder,
          $$TaskTimeEntryRowsTableUpdateCompanionBuilder,
          (TaskTimeEntryRow, $$TaskTimeEntryRowsTableReferences),
          TaskTimeEntryRow,
          PrefetchHooks Function({bool taskId})
        > {
  $$TaskTimeEntryRowsTableTableManager(
    _$AppDatabase db,
    $TaskTimeEntryRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskTimeEntryRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskTimeEntryRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskTimeEntryRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<DateTime> startedAtUtc = const Value.absent(),
                Value<DateTime?> lastResumedAtUtc = const Value.absent(),
                Value<DateTime?> endedAtUtc = const Value.absent(),
                Value<int> accumulatedSeconds = const Value.absent(),
                Value<int?> activeSlot = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskTimeEntryRowsCompanion(
                id: id,
                taskId: taskId,
                source: source,
                state: state,
                startedAtUtc: startedAtUtc,
                lastResumedAtUtc: lastResumedAtUtc,
                endedAtUtc: endedAtUtc,
                accumulatedSeconds: accumulatedSeconds,
                activeSlot: activeSlot,
                note: note,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskId,
                required String source,
                required String state,
                required DateTime startedAtUtc,
                Value<DateTime?> lastResumedAtUtc = const Value.absent(),
                Value<DateTime?> endedAtUtc = const Value.absent(),
                required int accumulatedSeconds,
                Value<int?> activeSlot = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => TaskTimeEntryRowsCompanion.insert(
                id: id,
                taskId: taskId,
                source: source,
                state: state,
                startedAtUtc: startedAtUtc,
                lastResumedAtUtc: lastResumedAtUtc,
                endedAtUtc: endedAtUtc,
                accumulatedSeconds: accumulatedSeconds,
                activeSlot: activeSlot,
                note: note,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskTimeEntryRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
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
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable:
                                    $$TaskTimeEntryRowsTableReferences
                                        ._taskIdTable(db),
                                referencedColumn:
                                    $$TaskTimeEntryRowsTableReferences
                                        ._taskIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$TaskTimeEntryRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskTimeEntryRowsTable,
      TaskTimeEntryRow,
      $$TaskTimeEntryRowsTableFilterComposer,
      $$TaskTimeEntryRowsTableOrderingComposer,
      $$TaskTimeEntryRowsTableAnnotationComposer,
      $$TaskTimeEntryRowsTableCreateCompanionBuilder,
      $$TaskTimeEntryRowsTableUpdateCompanionBuilder,
      (TaskTimeEntryRow, $$TaskTimeEntryRowsTableReferences),
      TaskTimeEntryRow,
      PrefetchHooks Function({bool taskId})
    >;
typedef $$TaskTemplateRowsTableCreateCompanionBuilder =
    TaskTemplateRowsCompanion Function({
      required String id,
      required String templateKind,
      Value<String?> systemKey,
      required String templateName,
      required String initialTaskTitle,
      Value<String?> description,
      required int priority,
      Value<int?> estimatedDurationMinutes,
      required String reminderDefaultsJson,
      Value<String?> recurrenceDefaultJson,
      Value<bool> hidden,
      required int displayOrder,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$TaskTemplateRowsTableUpdateCompanionBuilder =
    TaskTemplateRowsCompanion Function({
      Value<String> id,
      Value<String> templateKind,
      Value<String?> systemKey,
      Value<String> templateName,
      Value<String> initialTaskTitle,
      Value<String?> description,
      Value<int> priority,
      Value<int?> estimatedDurationMinutes,
      Value<String> reminderDefaultsJson,
      Value<String?> recurrenceDefaultJson,
      Value<bool> hidden,
      Value<int> displayOrder,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

class $$TaskTemplateRowsTableFilterComposer
    extends Composer<_$AppDatabase, $TaskTemplateRowsTable> {
  $$TaskTemplateRowsTableFilterComposer({
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

  ColumnFilters<String> get templateKind => $composableBuilder(
    column: $table.templateKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get systemKey => $composableBuilder(
    column: $table.systemKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateName => $composableBuilder(
    column: $table.templateName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get initialTaskTitle => $composableBuilder(
    column: $table.initialTaskTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatedDurationMinutes => $composableBuilder(
    column: $table.estimatedDurationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderDefaultsJson => $composableBuilder(
    column: $table.reminderDefaultsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceDefaultJson => $composableBuilder(
    column: $table.recurrenceDefaultJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskTemplateRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $TaskTemplateRowsTable> {
  $$TaskTemplateRowsTableOrderingComposer({
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

  ColumnOrderings<String> get templateKind => $composableBuilder(
    column: $table.templateKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get systemKey => $composableBuilder(
    column: $table.systemKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateName => $composableBuilder(
    column: $table.templateName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get initialTaskTitle => $composableBuilder(
    column: $table.initialTaskTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedDurationMinutes => $composableBuilder(
    column: $table.estimatedDurationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderDefaultsJson => $composableBuilder(
    column: $table.reminderDefaultsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceDefaultJson => $composableBuilder(
    column: $table.recurrenceDefaultJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hidden => $composableBuilder(
    column: $table.hidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskTemplateRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TaskTemplateRowsTable> {
  $$TaskTemplateRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get templateKind => $composableBuilder(
    column: $table.templateKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get systemKey =>
      $composableBuilder(column: $table.systemKey, builder: (column) => column);

  GeneratedColumn<String> get templateName => $composableBuilder(
    column: $table.templateName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get initialTaskTitle => $composableBuilder(
    column: $table.initialTaskTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get estimatedDurationMinutes => $composableBuilder(
    column: $table.estimatedDurationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderDefaultsJson => $composableBuilder(
    column: $table.reminderDefaultsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceDefaultJson => $composableBuilder(
    column: $table.recurrenceDefaultJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hidden =>
      $composableBuilder(column: $table.hidden, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );
}

class $$TaskTemplateRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TaskTemplateRowsTable,
          TaskTemplateRow,
          $$TaskTemplateRowsTableFilterComposer,
          $$TaskTemplateRowsTableOrderingComposer,
          $$TaskTemplateRowsTableAnnotationComposer,
          $$TaskTemplateRowsTableCreateCompanionBuilder,
          $$TaskTemplateRowsTableUpdateCompanionBuilder,
          (
            TaskTemplateRow,
            BaseReferences<
              _$AppDatabase,
              $TaskTemplateRowsTable,
              TaskTemplateRow
            >,
          ),
          TaskTemplateRow,
          PrefetchHooks Function()
        > {
  $$TaskTemplateRowsTableTableManager(
    _$AppDatabase db,
    $TaskTemplateRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskTemplateRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskTemplateRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskTemplateRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> templateKind = const Value.absent(),
                Value<String?> systemKey = const Value.absent(),
                Value<String> templateName = const Value.absent(),
                Value<String> initialTaskTitle = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int?> estimatedDurationMinutes = const Value.absent(),
                Value<String> reminderDefaultsJson = const Value.absent(),
                Value<String?> recurrenceDefaultJson = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskTemplateRowsCompanion(
                id: id,
                templateKind: templateKind,
                systemKey: systemKey,
                templateName: templateName,
                initialTaskTitle: initialTaskTitle,
                description: description,
                priority: priority,
                estimatedDurationMinutes: estimatedDurationMinutes,
                reminderDefaultsJson: reminderDefaultsJson,
                recurrenceDefaultJson: recurrenceDefaultJson,
                hidden: hidden,
                displayOrder: displayOrder,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String templateKind,
                Value<String?> systemKey = const Value.absent(),
                required String templateName,
                required String initialTaskTitle,
                Value<String?> description = const Value.absent(),
                required int priority,
                Value<int?> estimatedDurationMinutes = const Value.absent(),
                required String reminderDefaultsJson,
                Value<String?> recurrenceDefaultJson = const Value.absent(),
                Value<bool> hidden = const Value.absent(),
                required int displayOrder,
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => TaskTemplateRowsCompanion.insert(
                id: id,
                templateKind: templateKind,
                systemKey: systemKey,
                templateName: templateName,
                initialTaskTitle: initialTaskTitle,
                description: description,
                priority: priority,
                estimatedDurationMinutes: estimatedDurationMinutes,
                reminderDefaultsJson: reminderDefaultsJson,
                recurrenceDefaultJson: recurrenceDefaultJson,
                hidden: hidden,
                displayOrder: displayOrder,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskTemplateRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TaskTemplateRowsTable,
      TaskTemplateRow,
      $$TaskTemplateRowsTableFilterComposer,
      $$TaskTemplateRowsTableOrderingComposer,
      $$TaskTemplateRowsTableAnnotationComposer,
      $$TaskTemplateRowsTableCreateCompanionBuilder,
      $$TaskTemplateRowsTableUpdateCompanionBuilder,
      (
        TaskTemplateRow,
        BaseReferences<_$AppDatabase, $TaskTemplateRowsTable, TaskTemplateRow>,
      ),
      TaskTemplateRow,
      PrefetchHooks Function()
    >;
typedef $$NotificationScheduleRowsTableCreateCompanionBuilder =
    NotificationScheduleRowsCompanion Function({
      required String scheduleId,
      required String ownerType,
      required String ownerId,
      required String title,
      required String body,
      required DateTime scheduledAtUtc,
      Value<String> payloadJson,
      Value<String> privacyMode,
      required DateTime createdAtUtc,
      required DateTime updatedAtUtc,
      Value<int> rowid,
    });
typedef $$NotificationScheduleRowsTableUpdateCompanionBuilder =
    NotificationScheduleRowsCompanion Function({
      Value<String> scheduleId,
      Value<String> ownerType,
      Value<String> ownerId,
      Value<String> title,
      Value<String> body,
      Value<DateTime> scheduledAtUtc,
      Value<String> payloadJson,
      Value<String> privacyMode,
      Value<DateTime> createdAtUtc,
      Value<DateTime> updatedAtUtc,
      Value<int> rowid,
    });

class $$NotificationScheduleRowsTableFilterComposer
    extends Composer<_$AppDatabase, $NotificationScheduleRowsTable> {
  $$NotificationScheduleRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerType => $composableBuilder(
    column: $table.ownerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledAtUtc => $composableBuilder(
    column: $table.scheduledAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get privacyMode => $composableBuilder(
    column: $table.privacyMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotificationScheduleRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotificationScheduleRowsTable> {
  $$NotificationScheduleRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerType => $composableBuilder(
    column: $table.ownerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledAtUtc => $composableBuilder(
    column: $table.scheduledAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get privacyMode => $composableBuilder(
    column: $table.privacyMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotificationScheduleRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotificationScheduleRowsTable> {
  $$NotificationScheduleRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scheduleId => $composableBuilder(
    column: $table.scheduleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerType =>
      $composableBuilder(column: $table.ownerType, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduledAtUtc => $composableBuilder(
    column: $table.scheduledAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get privacyMode => $composableBuilder(
    column: $table.privacyMode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAtUtc => $composableBuilder(
    column: $table.createdAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAtUtc => $composableBuilder(
    column: $table.updatedAtUtc,
    builder: (column) => column,
  );
}

class $$NotificationScheduleRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotificationScheduleRowsTable,
          NotificationScheduleRow,
          $$NotificationScheduleRowsTableFilterComposer,
          $$NotificationScheduleRowsTableOrderingComposer,
          $$NotificationScheduleRowsTableAnnotationComposer,
          $$NotificationScheduleRowsTableCreateCompanionBuilder,
          $$NotificationScheduleRowsTableUpdateCompanionBuilder,
          (
            NotificationScheduleRow,
            BaseReferences<
              _$AppDatabase,
              $NotificationScheduleRowsTable,
              NotificationScheduleRow
            >,
          ),
          NotificationScheduleRow,
          PrefetchHooks Function()
        > {
  $$NotificationScheduleRowsTableTableManager(
    _$AppDatabase db,
    $NotificationScheduleRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotificationScheduleRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$NotificationScheduleRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$NotificationScheduleRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> scheduleId = const Value.absent(),
                Value<String> ownerType = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> scheduledAtUtc = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> privacyMode = const Value.absent(),
                Value<DateTime> createdAtUtc = const Value.absent(),
                Value<DateTime> updatedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NotificationScheduleRowsCompanion(
                scheduleId: scheduleId,
                ownerType: ownerType,
                ownerId: ownerId,
                title: title,
                body: body,
                scheduledAtUtc: scheduledAtUtc,
                payloadJson: payloadJson,
                privacyMode: privacyMode,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scheduleId,
                required String ownerType,
                required String ownerId,
                required String title,
                required String body,
                required DateTime scheduledAtUtc,
                Value<String> payloadJson = const Value.absent(),
                Value<String> privacyMode = const Value.absent(),
                required DateTime createdAtUtc,
                required DateTime updatedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => NotificationScheduleRowsCompanion.insert(
                scheduleId: scheduleId,
                ownerType: ownerType,
                ownerId: ownerId,
                title: title,
                body: body,
                scheduledAtUtc: scheduledAtUtc,
                payloadJson: payloadJson,
                privacyMode: privacyMode,
                createdAtUtc: createdAtUtc,
                updatedAtUtc: updatedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotificationScheduleRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotificationScheduleRowsTable,
      NotificationScheduleRow,
      $$NotificationScheduleRowsTableFilterComposer,
      $$NotificationScheduleRowsTableOrderingComposer,
      $$NotificationScheduleRowsTableAnnotationComposer,
      $$NotificationScheduleRowsTableCreateCompanionBuilder,
      $$NotificationScheduleRowsTableUpdateCompanionBuilder,
      (
        NotificationScheduleRow,
        BaseReferences<
          _$AppDatabase,
          $NotificationScheduleRowsTable,
          NotificationScheduleRow
        >,
      ),
      NotificationScheduleRow,
      PrefetchHooks Function()
    >;
typedef $$LegacyImportRowsTableCreateCompanionBuilder =
    LegacyImportRowsCompanion Function({
      required String sourceKind,
      required String entityType,
      required String v1Id,
      required String v2Id,
      required DateTime importedAtUtc,
      required String sourceSha256,
      Value<int> rowid,
    });
typedef $$LegacyImportRowsTableUpdateCompanionBuilder =
    LegacyImportRowsCompanion Function({
      Value<String> sourceKind,
      Value<String> entityType,
      Value<String> v1Id,
      Value<String> v2Id,
      Value<DateTime> importedAtUtc,
      Value<String> sourceSha256,
      Value<int> rowid,
    });

class $$LegacyImportRowsTableFilterComposer
    extends Composer<_$AppDatabase, $LegacyImportRowsTable> {
  $$LegacyImportRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sourceKind => $composableBuilder(
    column: $table.sourceKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get v1Id => $composableBuilder(
    column: $table.v1Id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get v2Id => $composableBuilder(
    column: $table.v2Id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAtUtc => $composableBuilder(
    column: $table.importedAtUtc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceSha256 => $composableBuilder(
    column: $table.sourceSha256,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LegacyImportRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $LegacyImportRowsTable> {
  $$LegacyImportRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sourceKind => $composableBuilder(
    column: $table.sourceKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get v1Id => $composableBuilder(
    column: $table.v1Id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get v2Id => $composableBuilder(
    column: $table.v2Id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAtUtc => $composableBuilder(
    column: $table.importedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceSha256 => $composableBuilder(
    column: $table.sourceSha256,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LegacyImportRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LegacyImportRowsTable> {
  $$LegacyImportRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sourceKind => $composableBuilder(
    column: $table.sourceKind,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get v1Id =>
      $composableBuilder(column: $table.v1Id, builder: (column) => column);

  GeneratedColumn<String> get v2Id =>
      $composableBuilder(column: $table.v2Id, builder: (column) => column);

  GeneratedColumn<DateTime> get importedAtUtc => $composableBuilder(
    column: $table.importedAtUtc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceSha256 => $composableBuilder(
    column: $table.sourceSha256,
    builder: (column) => column,
  );
}

class $$LegacyImportRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LegacyImportRowsTable,
          LegacyImportRow,
          $$LegacyImportRowsTableFilterComposer,
          $$LegacyImportRowsTableOrderingComposer,
          $$LegacyImportRowsTableAnnotationComposer,
          $$LegacyImportRowsTableCreateCompanionBuilder,
          $$LegacyImportRowsTableUpdateCompanionBuilder,
          (
            LegacyImportRow,
            BaseReferences<
              _$AppDatabase,
              $LegacyImportRowsTable,
              LegacyImportRow
            >,
          ),
          LegacyImportRow,
          PrefetchHooks Function()
        > {
  $$LegacyImportRowsTableTableManager(
    _$AppDatabase db,
    $LegacyImportRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LegacyImportRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LegacyImportRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LegacyImportRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sourceKind = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> v1Id = const Value.absent(),
                Value<String> v2Id = const Value.absent(),
                Value<DateTime> importedAtUtc = const Value.absent(),
                Value<String> sourceSha256 = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LegacyImportRowsCompanion(
                sourceKind: sourceKind,
                entityType: entityType,
                v1Id: v1Id,
                v2Id: v2Id,
                importedAtUtc: importedAtUtc,
                sourceSha256: sourceSha256,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sourceKind,
                required String entityType,
                required String v1Id,
                required String v2Id,
                required DateTime importedAtUtc,
                required String sourceSha256,
                Value<int> rowid = const Value.absent(),
              }) => LegacyImportRowsCompanion.insert(
                sourceKind: sourceKind,
                entityType: entityType,
                v1Id: v1Id,
                v2Id: v2Id,
                importedAtUtc: importedAtUtc,
                sourceSha256: sourceSha256,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LegacyImportRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LegacyImportRowsTable,
      LegacyImportRow,
      $$LegacyImportRowsTableFilterComposer,
      $$LegacyImportRowsTableOrderingComposer,
      $$LegacyImportRowsTableAnnotationComposer,
      $$LegacyImportRowsTableCreateCompanionBuilder,
      $$LegacyImportRowsTableUpdateCompanionBuilder,
      (
        LegacyImportRow,
        BaseReferences<_$AppDatabase, $LegacyImportRowsTable, LegacyImportRow>,
      ),
      LegacyImportRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TaskRowsTableTableManager get taskRows =>
      $$TaskRowsTableTableManager(_db, _db.taskRows);
  $$FinanceTransactionRowsTableTableManager get financeTransactionRows =>
      $$FinanceTransactionRowsTableTableManager(
        _db,
        _db.financeTransactionRows,
      );
  $$DebtRowsTableTableManager get debtRows =>
      $$DebtRowsTableTableManager(_db, _db.debtRows);
  $$DebtPaymentRowsTableTableManager get debtPaymentRows =>
      $$DebtPaymentRowsTableTableManager(_db, _db.debtPaymentRows);
  $$InstallmentPlanRowsTableTableManager get installmentPlanRows =>
      $$InstallmentPlanRowsTableTableManager(_db, _db.installmentPlanRows);
  $$InstallmentPaymentRowsTableTableManager get installmentPaymentRows =>
      $$InstallmentPaymentRowsTableTableManager(
        _db,
        _db.installmentPaymentRows,
      );
  $$TaskReminderRuleRowsTableTableManager get taskReminderRuleRows =>
      $$TaskReminderRuleRowsTableTableManager(_db, _db.taskReminderRuleRows);
  $$TaskRecurrenceRuleRowsTableTableManager get taskRecurrenceRuleRows =>
      $$TaskRecurrenceRuleRowsTableTableManager(
        _db,
        _db.taskRecurrenceRuleRows,
      );
  $$TaskRecurrenceExceptionRowsTableTableManager
  get taskRecurrenceExceptionRows =>
      $$TaskRecurrenceExceptionRowsTableTableManager(
        _db,
        _db.taskRecurrenceExceptionRows,
      );
  $$TaskOccurrenceCompletionRowsTableTableManager
  get taskOccurrenceCompletionRows =>
      $$TaskOccurrenceCompletionRowsTableTableManager(
        _db,
        _db.taskOccurrenceCompletionRows,
      );
  $$TaskTimeEntryRowsTableTableManager get taskTimeEntryRows =>
      $$TaskTimeEntryRowsTableTableManager(_db, _db.taskTimeEntryRows);
  $$TaskTemplateRowsTableTableManager get taskTemplateRows =>
      $$TaskTemplateRowsTableTableManager(_db, _db.taskTemplateRows);
  $$NotificationScheduleRowsTableTableManager get notificationScheduleRows =>
      $$NotificationScheduleRowsTableTableManager(
        _db,
        _db.notificationScheduleRows,
      );
  $$LegacyImportRowsTableTableManager get legacyImportRows =>
      $$LegacyImportRowsTableTableManager(_db, _db.legacyImportRows);
}
