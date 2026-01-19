// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_database.dart';

// ignore_for_file: type=lint
class $ProjectsTableTable extends ProjectsTable
    with TableInfo<$ProjectsTableTable, ProjectsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
      'width', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _thumbnailMeta =
      const VerificationMeta('thumbnail');
  @override
  late final GeneratedColumn<Uint8List> thumbnail = GeneratedColumn<Uint8List>(
      'thumbnail', aliasedName, true,
      type: DriftSqlType.blob, requiredDuringInsert: false);
  static const VerificationMeta _isCloudSyncedMeta =
      const VerificationMeta('isCloudSynced');
  @override
  late final GeneratedColumn<bool> isCloudSynced = GeneratedColumn<bool>(
      'is_cloud_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_cloud_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _remoteIdMeta =
      const VerificationMeta('remoteId');
  @override
  late final GeneratedColumn<int> remoteId = GeneratedColumn<int>(
      'remote_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _editedAtMeta =
      const VerificationMeta('editedAt');
  @override
  late final GeneratedColumn<DateTime> editedAt = GeneratedColumn<DateTime>(
      'edited_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _projectTypeMeta =
      const VerificationMeta('projectType');
  @override
  late final GeneratedColumn<String> projectType = GeneratedColumn<String>(
      'project_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pixelArt'));
  static const VerificationMeta _tileWidthMeta =
      const VerificationMeta('tileWidth');
  @override
  late final GeneratedColumn<int> tileWidth = GeneratedColumn<int>(
      'tile_width', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _tileHeightMeta =
      const VerificationMeta('tileHeight');
  @override
  late final GeneratedColumn<int> tileHeight = GeneratedColumn<int>(
      'tile_height', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _gridColumnsMeta =
      const VerificationMeta('gridColumns');
  @override
  late final GeneratedColumn<int> gridColumns = GeneratedColumn<int>(
      'grid_columns', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _gridRowsMeta =
      const VerificationMeta('gridRows');
  @override
  late final GeneratedColumn<int> gridRows = GeneratedColumn<int>(
      'grid_rows', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _tilemapDataMeta =
      const VerificationMeta('tilemapData');
  @override
  late final GeneratedColumn<String> tilemapData = GeneratedColumn<String>(
      'tilemap_data', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        width,
        height,
        thumbnail,
        isCloudSynced,
        remoteId,
        createdAt,
        editedAt,
        projectType,
        tileWidth,
        tileHeight,
        gridColumns,
        gridRows,
        tilemapData
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects_table';
  @override
  VerificationContext validateIntegrity(Insertable<ProjectsTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('thumbnail')) {
      context.handle(_thumbnailMeta,
          thumbnail.isAcceptableOrUnknown(data['thumbnail']!, _thumbnailMeta));
    }
    if (data.containsKey('is_cloud_synced')) {
      context.handle(
          _isCloudSyncedMeta,
          isCloudSynced.isAcceptableOrUnknown(
              data['is_cloud_synced']!, _isCloudSyncedMeta));
    }
    if (data.containsKey('remote_id')) {
      context.handle(_remoteIdMeta,
          remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('edited_at')) {
      context.handle(_editedAtMeta,
          editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta));
    } else if (isInserting) {
      context.missing(_editedAtMeta);
    }
    if (data.containsKey('project_type')) {
      context.handle(
          _projectTypeMeta,
          projectType.isAcceptableOrUnknown(
              data['project_type']!, _projectTypeMeta));
    }
    if (data.containsKey('tile_width')) {
      context.handle(_tileWidthMeta,
          tileWidth.isAcceptableOrUnknown(data['tile_width']!, _tileWidthMeta));
    }
    if (data.containsKey('tile_height')) {
      context.handle(
          _tileHeightMeta,
          tileHeight.isAcceptableOrUnknown(
              data['tile_height']!, _tileHeightMeta));
    }
    if (data.containsKey('grid_columns')) {
      context.handle(
          _gridColumnsMeta,
          gridColumns.isAcceptableOrUnknown(
              data['grid_columns']!, _gridColumnsMeta));
    }
    if (data.containsKey('grid_rows')) {
      context.handle(_gridRowsMeta,
          gridRows.isAcceptableOrUnknown(data['grid_rows']!, _gridRowsMeta));
    }
    if (data.containsKey('tilemap_data')) {
      context.handle(
          _tilemapDataMeta,
          tilemapData.isAcceptableOrUnknown(
              data['tilemap_data']!, _tilemapDataMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectsTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}width'])!,
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height'])!,
      thumbnail: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}thumbnail']),
      isCloudSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_cloud_synced'])!,
      remoteId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}remote_id']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      editedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}edited_at'])!,
      projectType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_type'])!,
      tileWidth: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tile_width']),
      tileHeight: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tile_height']),
      gridColumns: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}grid_columns']),
      gridRows: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}grid_rows']),
      tilemapData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tilemap_data']),
    );
  }

  @override
  $ProjectsTableTable createAlias(String alias) {
    return $ProjectsTableTable(attachedDatabase, alias);
  }
}

class ProjectsTableData extends DataClass
    implements Insertable<ProjectsTableData> {
  final int id;
  final String name;
  final int width;
  final int height;
  final Uint8List? thumbnail;
  final bool isCloudSynced;
  final int? remoteId;
  final DateTime createdAt;
  final DateTime editedAt;
  final String projectType;
  final int? tileWidth;
  final int? tileHeight;
  final int? gridColumns;
  final int? gridRows;
  final String? tilemapData;
  const ProjectsTableData(
      {required this.id,
      required this.name,
      required this.width,
      required this.height,
      this.thumbnail,
      required this.isCloudSynced,
      this.remoteId,
      required this.createdAt,
      required this.editedAt,
      required this.projectType,
      this.tileWidth,
      this.tileHeight,
      this.gridColumns,
      this.gridRows,
      this.tilemapData});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['width'] = Variable<int>(width);
    map['height'] = Variable<int>(height);
    if (!nullToAbsent || thumbnail != null) {
      map['thumbnail'] = Variable<Uint8List>(thumbnail);
    }
    map['is_cloud_synced'] = Variable<bool>(isCloudSynced);
    if (!nullToAbsent || remoteId != null) {
      map['remote_id'] = Variable<int>(remoteId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['edited_at'] = Variable<DateTime>(editedAt);
    map['project_type'] = Variable<String>(projectType);
    if (!nullToAbsent || tileWidth != null) {
      map['tile_width'] = Variable<int>(tileWidth);
    }
    if (!nullToAbsent || tileHeight != null) {
      map['tile_height'] = Variable<int>(tileHeight);
    }
    if (!nullToAbsent || gridColumns != null) {
      map['grid_columns'] = Variable<int>(gridColumns);
    }
    if (!nullToAbsent || gridRows != null) {
      map['grid_rows'] = Variable<int>(gridRows);
    }
    if (!nullToAbsent || tilemapData != null) {
      map['tilemap_data'] = Variable<String>(tilemapData);
    }
    return map;
  }

  ProjectsTableCompanion toCompanion(bool nullToAbsent) {
    return ProjectsTableCompanion(
      id: Value(id),
      name: Value(name),
      width: Value(width),
      height: Value(height),
      thumbnail: thumbnail == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnail),
      isCloudSynced: Value(isCloudSynced),
      remoteId: remoteId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteId),
      createdAt: Value(createdAt),
      editedAt: Value(editedAt),
      projectType: Value(projectType),
      tileWidth: tileWidth == null && nullToAbsent
          ? const Value.absent()
          : Value(tileWidth),
      tileHeight: tileHeight == null && nullToAbsent
          ? const Value.absent()
          : Value(tileHeight),
      gridColumns: gridColumns == null && nullToAbsent
          ? const Value.absent()
          : Value(gridColumns),
      gridRows: gridRows == null && nullToAbsent
          ? const Value.absent()
          : Value(gridRows),
      tilemapData: tilemapData == null && nullToAbsent
          ? const Value.absent()
          : Value(tilemapData),
    );
  }

  factory ProjectsTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectsTableData(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      width: serializer.fromJson<int>(json['width']),
      height: serializer.fromJson<int>(json['height']),
      thumbnail: serializer.fromJson<Uint8List?>(json['thumbnail']),
      isCloudSynced: serializer.fromJson<bool>(json['isCloudSynced']),
      remoteId: serializer.fromJson<int?>(json['remoteId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      editedAt: serializer.fromJson<DateTime>(json['editedAt']),
      projectType: serializer.fromJson<String>(json['projectType']),
      tileWidth: serializer.fromJson<int?>(json['tileWidth']),
      tileHeight: serializer.fromJson<int?>(json['tileHeight']),
      gridColumns: serializer.fromJson<int?>(json['gridColumns']),
      gridRows: serializer.fromJson<int?>(json['gridRows']),
      tilemapData: serializer.fromJson<String?>(json['tilemapData']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'width': serializer.toJson<int>(width),
      'height': serializer.toJson<int>(height),
      'thumbnail': serializer.toJson<Uint8List?>(thumbnail),
      'isCloudSynced': serializer.toJson<bool>(isCloudSynced),
      'remoteId': serializer.toJson<int?>(remoteId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'editedAt': serializer.toJson<DateTime>(editedAt),
      'projectType': serializer.toJson<String>(projectType),
      'tileWidth': serializer.toJson<int?>(tileWidth),
      'tileHeight': serializer.toJson<int?>(tileHeight),
      'gridColumns': serializer.toJson<int?>(gridColumns),
      'gridRows': serializer.toJson<int?>(gridRows),
      'tilemapData': serializer.toJson<String?>(tilemapData),
    };
  }

  ProjectsTableData copyWith(
          {int? id,
          String? name,
          int? width,
          int? height,
          Value<Uint8List?> thumbnail = const Value.absent(),
          bool? isCloudSynced,
          Value<int?> remoteId = const Value.absent(),
          DateTime? createdAt,
          DateTime? editedAt,
          String? projectType,
          Value<int?> tileWidth = const Value.absent(),
          Value<int?> tileHeight = const Value.absent(),
          Value<int?> gridColumns = const Value.absent(),
          Value<int?> gridRows = const Value.absent(),
          Value<String?> tilemapData = const Value.absent()}) =>
      ProjectsTableData(
        id: id ?? this.id,
        name: name ?? this.name,
        width: width ?? this.width,
        height: height ?? this.height,
        thumbnail: thumbnail.present ? thumbnail.value : this.thumbnail,
        isCloudSynced: isCloudSynced ?? this.isCloudSynced,
        remoteId: remoteId.present ? remoteId.value : this.remoteId,
        createdAt: createdAt ?? this.createdAt,
        editedAt: editedAt ?? this.editedAt,
        projectType: projectType ?? this.projectType,
        tileWidth: tileWidth.present ? tileWidth.value : this.tileWidth,
        tileHeight: tileHeight.present ? tileHeight.value : this.tileHeight,
        gridColumns: gridColumns.present ? gridColumns.value : this.gridColumns,
        gridRows: gridRows.present ? gridRows.value : this.gridRows,
        tilemapData: tilemapData.present ? tilemapData.value : this.tilemapData,
      );
  ProjectsTableData copyWithCompanion(ProjectsTableCompanion data) {
    return ProjectsTableData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      thumbnail: data.thumbnail.present ? data.thumbnail.value : this.thumbnail,
      isCloudSynced: data.isCloudSynced.present
          ? data.isCloudSynced.value
          : this.isCloudSynced,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      projectType:
          data.projectType.present ? data.projectType.value : this.projectType,
      tileWidth: data.tileWidth.present ? data.tileWidth.value : this.tileWidth,
      tileHeight:
          data.tileHeight.present ? data.tileHeight.value : this.tileHeight,
      gridColumns:
          data.gridColumns.present ? data.gridColumns.value : this.gridColumns,
      gridRows: data.gridRows.present ? data.gridRows.value : this.gridRows,
      tilemapData:
          data.tilemapData.present ? data.tilemapData.value : this.tilemapData,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsTableData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('isCloudSynced: $isCloudSynced, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('projectType: $projectType, ')
          ..write('tileWidth: $tileWidth, ')
          ..write('tileHeight: $tileHeight, ')
          ..write('gridColumns: $gridColumns, ')
          ..write('gridRows: $gridRows, ')
          ..write('tilemapData: $tilemapData')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      width,
      height,
      $driftBlobEquality.hash(thumbnail),
      isCloudSynced,
      remoteId,
      createdAt,
      editedAt,
      projectType,
      tileWidth,
      tileHeight,
      gridColumns,
      gridRows,
      tilemapData);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectsTableData &&
          other.id == this.id &&
          other.name == this.name &&
          other.width == this.width &&
          other.height == this.height &&
          $driftBlobEquality.equals(other.thumbnail, this.thumbnail) &&
          other.isCloudSynced == this.isCloudSynced &&
          other.remoteId == this.remoteId &&
          other.createdAt == this.createdAt &&
          other.editedAt == this.editedAt &&
          other.projectType == this.projectType &&
          other.tileWidth == this.tileWidth &&
          other.tileHeight == this.tileHeight &&
          other.gridColumns == this.gridColumns &&
          other.gridRows == this.gridRows &&
          other.tilemapData == this.tilemapData);
}

class ProjectsTableCompanion extends UpdateCompanion<ProjectsTableData> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> width;
  final Value<int> height;
  final Value<Uint8List?> thumbnail;
  final Value<bool> isCloudSynced;
  final Value<int?> remoteId;
  final Value<DateTime> createdAt;
  final Value<DateTime> editedAt;
  final Value<String> projectType;
  final Value<int?> tileWidth;
  final Value<int?> tileHeight;
  final Value<int?> gridColumns;
  final Value<int?> gridRows;
  final Value<String?> tilemapData;
  const ProjectsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.thumbnail = const Value.absent(),
    this.isCloudSynced = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.projectType = const Value.absent(),
    this.tileWidth = const Value.absent(),
    this.tileHeight = const Value.absent(),
    this.gridColumns = const Value.absent(),
    this.gridRows = const Value.absent(),
    this.tilemapData = const Value.absent(),
  });
  ProjectsTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int width,
    required int height,
    this.thumbnail = const Value.absent(),
    this.isCloudSynced = const Value.absent(),
    this.remoteId = const Value.absent(),
    required DateTime createdAt,
    required DateTime editedAt,
    this.projectType = const Value.absent(),
    this.tileWidth = const Value.absent(),
    this.tileHeight = const Value.absent(),
    this.gridColumns = const Value.absent(),
    this.gridRows = const Value.absent(),
    this.tilemapData = const Value.absent(),
  })  : name = Value(name),
        width = Value(width),
        height = Value(height),
        createdAt = Value(createdAt),
        editedAt = Value(editedAt);
  static Insertable<ProjectsTableData> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? width,
    Expression<int>? height,
    Expression<Uint8List>? thumbnail,
    Expression<bool>? isCloudSynced,
    Expression<int>? remoteId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? editedAt,
    Expression<String>? projectType,
    Expression<int>? tileWidth,
    Expression<int>? tileHeight,
    Expression<int>? gridColumns,
    Expression<int>? gridRows,
    Expression<String>? tilemapData,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (thumbnail != null) 'thumbnail': thumbnail,
      if (isCloudSynced != null) 'is_cloud_synced': isCloudSynced,
      if (remoteId != null) 'remote_id': remoteId,
      if (createdAt != null) 'created_at': createdAt,
      if (editedAt != null) 'edited_at': editedAt,
      if (projectType != null) 'project_type': projectType,
      if (tileWidth != null) 'tile_width': tileWidth,
      if (tileHeight != null) 'tile_height': tileHeight,
      if (gridColumns != null) 'grid_columns': gridColumns,
      if (gridRows != null) 'grid_rows': gridRows,
      if (tilemapData != null) 'tilemap_data': tilemapData,
    });
  }

  ProjectsTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int>? width,
      Value<int>? height,
      Value<Uint8List?>? thumbnail,
      Value<bool>? isCloudSynced,
      Value<int?>? remoteId,
      Value<DateTime>? createdAt,
      Value<DateTime>? editedAt,
      Value<String>? projectType,
      Value<int?>? tileWidth,
      Value<int?>? tileHeight,
      Value<int?>? gridColumns,
      Value<int?>? gridRows,
      Value<String?>? tilemapData}) {
    return ProjectsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
      thumbnail: thumbnail ?? this.thumbnail,
      isCloudSynced: isCloudSynced ?? this.isCloudSynced,
      remoteId: remoteId ?? this.remoteId,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      projectType: projectType ?? this.projectType,
      tileWidth: tileWidth ?? this.tileWidth,
      tileHeight: tileHeight ?? this.tileHeight,
      gridColumns: gridColumns ?? this.gridColumns,
      gridRows: gridRows ?? this.gridRows,
      tilemapData: tilemapData ?? this.tilemapData,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (thumbnail.present) {
      map['thumbnail'] = Variable<Uint8List>(thumbnail.value);
    }
    if (isCloudSynced.present) {
      map['is_cloud_synced'] = Variable<bool>(isCloudSynced.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<int>(remoteId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<DateTime>(editedAt.value);
    }
    if (projectType.present) {
      map['project_type'] = Variable<String>(projectType.value);
    }
    if (tileWidth.present) {
      map['tile_width'] = Variable<int>(tileWidth.value);
    }
    if (tileHeight.present) {
      map['tile_height'] = Variable<int>(tileHeight.value);
    }
    if (gridColumns.present) {
      map['grid_columns'] = Variable<int>(gridColumns.value);
    }
    if (gridRows.present) {
      map['grid_rows'] = Variable<int>(gridRows.value);
    }
    if (tilemapData.present) {
      map['tilemap_data'] = Variable<String>(tilemapData.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('thumbnail: $thumbnail, ')
          ..write('isCloudSynced: $isCloudSynced, ')
          ..write('remoteId: $remoteId, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('projectType: $projectType, ')
          ..write('tileWidth: $tileWidth, ')
          ..write('tileHeight: $tileHeight, ')
          ..write('gridColumns: $gridColumns, ')
          ..write('gridRows: $gridRows, ')
          ..write('tilemapData: $tilemapData')
          ..write(')'))
        .toString();
  }
}

class $AnimationStateTableTable extends AnimationStateTable
    with TableInfo<$AnimationStateTableTable, AnimationStateTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnimationStateTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
      'project_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES projects_table (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _frameRateMeta =
      const VerificationMeta('frameRate');
  @override
  late final GeneratedColumn<int> frameRate = GeneratedColumn<int>(
      'frame_rate', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _editedAtMeta =
      const VerificationMeta('editedAt');
  @override
  late final GeneratedColumn<DateTime> editedAt = GeneratedColumn<DateTime>(
      'edited_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, projectId, name, frameRate, createdAt, editedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'animation_state_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<AnimationStateTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('frame_rate')) {
      context.handle(_frameRateMeta,
          frameRate.isAcceptableOrUnknown(data['frame_rate']!, _frameRateMeta));
    } else if (isInserting) {
      context.missing(_frameRateMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('edited_at')) {
      context.handle(_editedAtMeta,
          editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta));
    } else if (isInserting) {
      context.missing(_editedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnimationStateTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnimationStateTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      frameRate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}frame_rate'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      editedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}edited_at'])!,
    );
  }

  @override
  $AnimationStateTableTable createAlias(String alias) {
    return $AnimationStateTableTable(attachedDatabase, alias);
  }
}

class AnimationStateTableData extends DataClass
    implements Insertable<AnimationStateTableData> {
  final int id;
  final int projectId;
  final String name;
  final int frameRate;
  final DateTime createdAt;
  final DateTime editedAt;
  const AnimationStateTableData(
      {required this.id,
      required this.projectId,
      required this.name,
      required this.frameRate,
      required this.createdAt,
      required this.editedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    map['name'] = Variable<String>(name);
    map['frame_rate'] = Variable<int>(frameRate);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['edited_at'] = Variable<DateTime>(editedAt);
    return map;
  }

  AnimationStateTableCompanion toCompanion(bool nullToAbsent) {
    return AnimationStateTableCompanion(
      id: Value(id),
      projectId: Value(projectId),
      name: Value(name),
      frameRate: Value(frameRate),
      createdAt: Value(createdAt),
      editedAt: Value(editedAt),
    );
  }

  factory AnimationStateTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnimationStateTableData(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      name: serializer.fromJson<String>(json['name']),
      frameRate: serializer.fromJson<int>(json['frameRate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      editedAt: serializer.fromJson<DateTime>(json['editedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int>(projectId),
      'name': serializer.toJson<String>(name),
      'frameRate': serializer.toJson<int>(frameRate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'editedAt': serializer.toJson<DateTime>(editedAt),
    };
  }

  AnimationStateTableData copyWith(
          {int? id,
          int? projectId,
          String? name,
          int? frameRate,
          DateTime? createdAt,
          DateTime? editedAt}) =>
      AnimationStateTableData(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        name: name ?? this.name,
        frameRate: frameRate ?? this.frameRate,
        createdAt: createdAt ?? this.createdAt,
        editedAt: editedAt ?? this.editedAt,
      );
  AnimationStateTableData copyWithCompanion(AnimationStateTableCompanion data) {
    return AnimationStateTableData(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      name: data.name.present ? data.name.value : this.name,
      frameRate: data.frameRate.present ? data.frameRate.value : this.frameRate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnimationStateTableData(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('frameRate: $frameRate, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, projectId, name, frameRate, createdAt, editedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnimationStateTableData &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.name == this.name &&
          other.frameRate == this.frameRate &&
          other.createdAt == this.createdAt &&
          other.editedAt == this.editedAt);
}

class AnimationStateTableCompanion
    extends UpdateCompanion<AnimationStateTableData> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<String> name;
  final Value<int> frameRate;
  final Value<DateTime> createdAt;
  final Value<DateTime> editedAt;
  const AnimationStateTableCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.name = const Value.absent(),
    this.frameRate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.editedAt = const Value.absent(),
  });
  AnimationStateTableCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    required String name,
    required int frameRate,
    required DateTime createdAt,
    required DateTime editedAt,
  })  : projectId = Value(projectId),
        name = Value(name),
        frameRate = Value(frameRate),
        createdAt = Value(createdAt),
        editedAt = Value(editedAt);
  static Insertable<AnimationStateTableData> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<String>? name,
    Expression<int>? frameRate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? editedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (name != null) 'name': name,
      if (frameRate != null) 'frame_rate': frameRate,
      if (createdAt != null) 'created_at': createdAt,
      if (editedAt != null) 'edited_at': editedAt,
    });
  }

  AnimationStateTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? projectId,
      Value<String>? name,
      Value<int>? frameRate,
      Value<DateTime>? createdAt,
      Value<DateTime>? editedAt}) {
    return AnimationStateTableCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      frameRate: frameRate ?? this.frameRate,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (frameRate.present) {
      map['frame_rate'] = Variable<int>(frameRate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<DateTime>(editedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnimationStateTableCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('frameRate: $frameRate, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt')
          ..write(')'))
        .toString();
  }
}

class $FramesTableTable extends FramesTable
    with TableInfo<$FramesTableTable, FramesTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FramesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
      'project_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES projects_table (id)'));
  static const VerificationMeta _stateIdMeta =
      const VerificationMeta('stateId');
  @override
  late final GeneratedColumn<int> stateId = GeneratedColumn<int>(
      'state_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES animation_state_table (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
      'order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _editedAtMeta =
      const VerificationMeta('editedAt');
  @override
  late final GeneratedColumn<DateTime> editedAt = GeneratedColumn<DateTime>(
      'edited_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, projectId, stateId, name, duration, order, createdAt, editedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'frames_table';
  @override
  VerificationContext validateIntegrity(Insertable<FramesTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('state_id')) {
      context.handle(_stateIdMeta,
          stateId.isAcceptableOrUnknown(data['state_id']!, _stateIdMeta));
    } else if (isInserting) {
      context.missing(_stateIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    } else if (isInserting) {
      context.missing(_durationMeta);
    }
    if (data.containsKey('order')) {
      context.handle(
          _orderMeta, order.isAcceptableOrUnknown(data['order']!, _orderMeta));
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('edited_at')) {
      context.handle(_editedAtMeta,
          editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta));
    } else if (isInserting) {
      context.missing(_editedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FramesTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FramesTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_id'])!,
      stateId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}state_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration'])!,
      order: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      editedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}edited_at'])!,
    );
  }

  @override
  $FramesTableTable createAlias(String alias) {
    return $FramesTableTable(attachedDatabase, alias);
  }
}

class FramesTableData extends DataClass implements Insertable<FramesTableData> {
  final int id;
  final int projectId;
  final int stateId;
  final String name;
  final int duration;
  final int order;
  final DateTime createdAt;
  final DateTime editedAt;
  const FramesTableData(
      {required this.id,
      required this.projectId,
      required this.stateId,
      required this.name,
      required this.duration,
      required this.order,
      required this.createdAt,
      required this.editedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    map['state_id'] = Variable<int>(stateId);
    map['name'] = Variable<String>(name);
    map['duration'] = Variable<int>(duration);
    map['order'] = Variable<int>(order);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['edited_at'] = Variable<DateTime>(editedAt);
    return map;
  }

  FramesTableCompanion toCompanion(bool nullToAbsent) {
    return FramesTableCompanion(
      id: Value(id),
      projectId: Value(projectId),
      stateId: Value(stateId),
      name: Value(name),
      duration: Value(duration),
      order: Value(order),
      createdAt: Value(createdAt),
      editedAt: Value(editedAt),
    );
  }

  factory FramesTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FramesTableData(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      stateId: serializer.fromJson<int>(json['stateId']),
      name: serializer.fromJson<String>(json['name']),
      duration: serializer.fromJson<int>(json['duration']),
      order: serializer.fromJson<int>(json['order']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      editedAt: serializer.fromJson<DateTime>(json['editedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int>(projectId),
      'stateId': serializer.toJson<int>(stateId),
      'name': serializer.toJson<String>(name),
      'duration': serializer.toJson<int>(duration),
      'order': serializer.toJson<int>(order),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'editedAt': serializer.toJson<DateTime>(editedAt),
    };
  }

  FramesTableData copyWith(
          {int? id,
          int? projectId,
          int? stateId,
          String? name,
          int? duration,
          int? order,
          DateTime? createdAt,
          DateTime? editedAt}) =>
      FramesTableData(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        stateId: stateId ?? this.stateId,
        name: name ?? this.name,
        duration: duration ?? this.duration,
        order: order ?? this.order,
        createdAt: createdAt ?? this.createdAt,
        editedAt: editedAt ?? this.editedAt,
      );
  FramesTableData copyWithCompanion(FramesTableCompanion data) {
    return FramesTableData(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      stateId: data.stateId.present ? data.stateId.value : this.stateId,
      name: data.name.present ? data.name.value : this.name,
      duration: data.duration.present ? data.duration.value : this.duration,
      order: data.order.present ? data.order.value : this.order,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FramesTableData(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('stateId: $stateId, ')
          ..write('name: $name, ')
          ..write('duration: $duration, ')
          ..write('order: $order, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, projectId, stateId, name, duration, order, createdAt, editedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FramesTableData &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.stateId == this.stateId &&
          other.name == this.name &&
          other.duration == this.duration &&
          other.order == this.order &&
          other.createdAt == this.createdAt &&
          other.editedAt == this.editedAt);
}

class FramesTableCompanion extends UpdateCompanion<FramesTableData> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<int> stateId;
  final Value<String> name;
  final Value<int> duration;
  final Value<int> order;
  final Value<DateTime> createdAt;
  final Value<DateTime> editedAt;
  const FramesTableCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.stateId = const Value.absent(),
    this.name = const Value.absent(),
    this.duration = const Value.absent(),
    this.order = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.editedAt = const Value.absent(),
  });
  FramesTableCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    required int stateId,
    required String name,
    required int duration,
    required int order,
    required DateTime createdAt,
    required DateTime editedAt,
  })  : projectId = Value(projectId),
        stateId = Value(stateId),
        name = Value(name),
        duration = Value(duration),
        order = Value(order),
        createdAt = Value(createdAt),
        editedAt = Value(editedAt);
  static Insertable<FramesTableData> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<int>? stateId,
    Expression<String>? name,
    Expression<int>? duration,
    Expression<int>? order,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? editedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (stateId != null) 'state_id': stateId,
      if (name != null) 'name': name,
      if (duration != null) 'duration': duration,
      if (order != null) 'order': order,
      if (createdAt != null) 'created_at': createdAt,
      if (editedAt != null) 'edited_at': editedAt,
    });
  }

  FramesTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? projectId,
      Value<int>? stateId,
      Value<String>? name,
      Value<int>? duration,
      Value<int>? order,
      Value<DateTime>? createdAt,
      Value<DateTime>? editedAt}) {
    return FramesTableCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      stateId: stateId ?? this.stateId,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (stateId.present) {
      map['state_id'] = Variable<int>(stateId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<DateTime>(editedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FramesTableCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('stateId: $stateId, ')
          ..write('name: $name, ')
          ..write('duration: $duration, ')
          ..write('order: $order, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt')
          ..write(')'))
        .toString();
  }
}

class $LayersTableTable extends LayersTable
    with TableInfo<$LayersTableTable, LayersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LayersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
      'project_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES projects_table (id)'));
  static const VerificationMeta _frameIdMeta =
      const VerificationMeta('frameId');
  @override
  late final GeneratedColumn<int> frameId = GeneratedColumn<int>(
      'frame_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES frames_table (id)'));
  static const VerificationMeta _layerIdMeta =
      const VerificationMeta('layerId');
  @override
  late final GeneratedColumn<String> layerId = GeneratedColumn<String>(
      'layer_id', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _pixelsMeta = const VerificationMeta('pixels');
  @override
  late final GeneratedColumn<Uint8List> pixels = GeneratedColumn<Uint8List>(
      'pixels', aliasedName, false,
      type: DriftSqlType.blob, requiredDuringInsert: true);
  static const VerificationMeta _isVisibleMeta =
      const VerificationMeta('isVisible');
  @override
  late final GeneratedColumn<bool> isVisible = GeneratedColumn<bool>(
      'is_visible', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_visible" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _isLockedMeta =
      const VerificationMeta('isLocked');
  @override
  late final GeneratedColumn<bool> isLocked = GeneratedColumn<bool>(
      'is_locked', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_locked" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _opacityMeta =
      const VerificationMeta('opacity');
  @override
  late final GeneratedColumn<double> opacity = GeneratedColumn<double>(
      'opacity', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _orderMeta = const VerificationMeta('order');
  @override
  late final GeneratedColumn<int> order = GeneratedColumn<int>(
      'order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _effectsMeta =
      const VerificationMeta('effects');
  @override
  late final GeneratedColumn<String> effects = GeneratedColumn<String>(
      'effects', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        frameId,
        layerId,
        name,
        pixels,
        isVisible,
        isLocked,
        opacity,
        order,
        effects
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'layers_table';
  @override
  VerificationContext validateIntegrity(Insertable<LayersTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('frame_id')) {
      context.handle(_frameIdMeta,
          frameId.isAcceptableOrUnknown(data['frame_id']!, _frameIdMeta));
    } else if (isInserting) {
      context.missing(_frameIdMeta);
    }
    if (data.containsKey('layer_id')) {
      context.handle(_layerIdMeta,
          layerId.isAcceptableOrUnknown(data['layer_id']!, _layerIdMeta));
    } else if (isInserting) {
      context.missing(_layerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('pixels')) {
      context.handle(_pixelsMeta,
          pixels.isAcceptableOrUnknown(data['pixels']!, _pixelsMeta));
    } else if (isInserting) {
      context.missing(_pixelsMeta);
    }
    if (data.containsKey('is_visible')) {
      context.handle(_isVisibleMeta,
          isVisible.isAcceptableOrUnknown(data['is_visible']!, _isVisibleMeta));
    }
    if (data.containsKey('is_locked')) {
      context.handle(_isLockedMeta,
          isLocked.isAcceptableOrUnknown(data['is_locked']!, _isLockedMeta));
    }
    if (data.containsKey('opacity')) {
      context.handle(_opacityMeta,
          opacity.isAcceptableOrUnknown(data['opacity']!, _opacityMeta));
    }
    if (data.containsKey('order')) {
      context.handle(
          _orderMeta, order.isAcceptableOrUnknown(data['order']!, _orderMeta));
    } else if (isInserting) {
      context.missing(_orderMeta);
    }
    if (data.containsKey('effects')) {
      context.handle(_effectsMeta,
          effects.isAcceptableOrUnknown(data['effects']!, _effectsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LayersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LayersTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_id'])!,
      frameId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}frame_id'])!,
      layerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}layer_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      pixels: attachedDatabase.typeMapping
          .read(DriftSqlType.blob, data['${effectivePrefix}pixels'])!,
      isVisible: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_visible'])!,
      isLocked: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_locked'])!,
      opacity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}opacity'])!,
      order: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order'])!,
      effects: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}effects']),
    );
  }

  @override
  $LayersTableTable createAlias(String alias) {
    return $LayersTableTable(attachedDatabase, alias);
  }
}

class LayersTableData extends DataClass implements Insertable<LayersTableData> {
  final int id;
  final int projectId;
  final int frameId;
  final String layerId;
  final String name;
  final Uint8List pixels;
  final bool isVisible;
  final bool isLocked;
  final double opacity;
  final int order;
  final String? effects;
  const LayersTableData(
      {required this.id,
      required this.projectId,
      required this.frameId,
      required this.layerId,
      required this.name,
      required this.pixels,
      required this.isVisible,
      required this.isLocked,
      required this.opacity,
      required this.order,
      this.effects});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    map['frame_id'] = Variable<int>(frameId);
    map['layer_id'] = Variable<String>(layerId);
    map['name'] = Variable<String>(name);
    map['pixels'] = Variable<Uint8List>(pixels);
    map['is_visible'] = Variable<bool>(isVisible);
    map['is_locked'] = Variable<bool>(isLocked);
    map['opacity'] = Variable<double>(opacity);
    map['order'] = Variable<int>(order);
    if (!nullToAbsent || effects != null) {
      map['effects'] = Variable<String>(effects);
    }
    return map;
  }

  LayersTableCompanion toCompanion(bool nullToAbsent) {
    return LayersTableCompanion(
      id: Value(id),
      projectId: Value(projectId),
      frameId: Value(frameId),
      layerId: Value(layerId),
      name: Value(name),
      pixels: Value(pixels),
      isVisible: Value(isVisible),
      isLocked: Value(isLocked),
      opacity: Value(opacity),
      order: Value(order),
      effects: effects == null && nullToAbsent
          ? const Value.absent()
          : Value(effects),
    );
  }

  factory LayersTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LayersTableData(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      frameId: serializer.fromJson<int>(json['frameId']),
      layerId: serializer.fromJson<String>(json['layerId']),
      name: serializer.fromJson<String>(json['name']),
      pixels: serializer.fromJson<Uint8List>(json['pixels']),
      isVisible: serializer.fromJson<bool>(json['isVisible']),
      isLocked: serializer.fromJson<bool>(json['isLocked']),
      opacity: serializer.fromJson<double>(json['opacity']),
      order: serializer.fromJson<int>(json['order']),
      effects: serializer.fromJson<String?>(json['effects']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int>(projectId),
      'frameId': serializer.toJson<int>(frameId),
      'layerId': serializer.toJson<String>(layerId),
      'name': serializer.toJson<String>(name),
      'pixels': serializer.toJson<Uint8List>(pixels),
      'isVisible': serializer.toJson<bool>(isVisible),
      'isLocked': serializer.toJson<bool>(isLocked),
      'opacity': serializer.toJson<double>(opacity),
      'order': serializer.toJson<int>(order),
      'effects': serializer.toJson<String?>(effects),
    };
  }

  LayersTableData copyWith(
          {int? id,
          int? projectId,
          int? frameId,
          String? layerId,
          String? name,
          Uint8List? pixels,
          bool? isVisible,
          bool? isLocked,
          double? opacity,
          int? order,
          Value<String?> effects = const Value.absent()}) =>
      LayersTableData(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        frameId: frameId ?? this.frameId,
        layerId: layerId ?? this.layerId,
        name: name ?? this.name,
        pixels: pixels ?? this.pixels,
        isVisible: isVisible ?? this.isVisible,
        isLocked: isLocked ?? this.isLocked,
        opacity: opacity ?? this.opacity,
        order: order ?? this.order,
        effects: effects.present ? effects.value : this.effects,
      );
  LayersTableData copyWithCompanion(LayersTableCompanion data) {
    return LayersTableData(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      frameId: data.frameId.present ? data.frameId.value : this.frameId,
      layerId: data.layerId.present ? data.layerId.value : this.layerId,
      name: data.name.present ? data.name.value : this.name,
      pixels: data.pixels.present ? data.pixels.value : this.pixels,
      isVisible: data.isVisible.present ? data.isVisible.value : this.isVisible,
      isLocked: data.isLocked.present ? data.isLocked.value : this.isLocked,
      opacity: data.opacity.present ? data.opacity.value : this.opacity,
      order: data.order.present ? data.order.value : this.order,
      effects: data.effects.present ? data.effects.value : this.effects,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LayersTableData(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('frameId: $frameId, ')
          ..write('layerId: $layerId, ')
          ..write('name: $name, ')
          ..write('pixels: $pixels, ')
          ..write('isVisible: $isVisible, ')
          ..write('isLocked: $isLocked, ')
          ..write('opacity: $opacity, ')
          ..write('order: $order, ')
          ..write('effects: $effects')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      projectId,
      frameId,
      layerId,
      name,
      $driftBlobEquality.hash(pixels),
      isVisible,
      isLocked,
      opacity,
      order,
      effects);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LayersTableData &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.frameId == this.frameId &&
          other.layerId == this.layerId &&
          other.name == this.name &&
          $driftBlobEquality.equals(other.pixels, this.pixels) &&
          other.isVisible == this.isVisible &&
          other.isLocked == this.isLocked &&
          other.opacity == this.opacity &&
          other.order == this.order &&
          other.effects == this.effects);
}

class LayersTableCompanion extends UpdateCompanion<LayersTableData> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<int> frameId;
  final Value<String> layerId;
  final Value<String> name;
  final Value<Uint8List> pixels;
  final Value<bool> isVisible;
  final Value<bool> isLocked;
  final Value<double> opacity;
  final Value<int> order;
  final Value<String?> effects;
  const LayersTableCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.frameId = const Value.absent(),
    this.layerId = const Value.absent(),
    this.name = const Value.absent(),
    this.pixels = const Value.absent(),
    this.isVisible = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.opacity = const Value.absent(),
    this.order = const Value.absent(),
    this.effects = const Value.absent(),
  });
  LayersTableCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    required int frameId,
    required String layerId,
    required String name,
    required Uint8List pixels,
    this.isVisible = const Value.absent(),
    this.isLocked = const Value.absent(),
    this.opacity = const Value.absent(),
    required int order,
    this.effects = const Value.absent(),
  })  : projectId = Value(projectId),
        frameId = Value(frameId),
        layerId = Value(layerId),
        name = Value(name),
        pixels = Value(pixels),
        order = Value(order);
  static Insertable<LayersTableData> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<int>? frameId,
    Expression<String>? layerId,
    Expression<String>? name,
    Expression<Uint8List>? pixels,
    Expression<bool>? isVisible,
    Expression<bool>? isLocked,
    Expression<double>? opacity,
    Expression<int>? order,
    Expression<String>? effects,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (frameId != null) 'frame_id': frameId,
      if (layerId != null) 'layer_id': layerId,
      if (name != null) 'name': name,
      if (pixels != null) 'pixels': pixels,
      if (isVisible != null) 'is_visible': isVisible,
      if (isLocked != null) 'is_locked': isLocked,
      if (opacity != null) 'opacity': opacity,
      if (order != null) 'order': order,
      if (effects != null) 'effects': effects,
    });
  }

  LayersTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? projectId,
      Value<int>? frameId,
      Value<String>? layerId,
      Value<String>? name,
      Value<Uint8List>? pixels,
      Value<bool>? isVisible,
      Value<bool>? isLocked,
      Value<double>? opacity,
      Value<int>? order,
      Value<String?>? effects}) {
    return LayersTableCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      frameId: frameId ?? this.frameId,
      layerId: layerId ?? this.layerId,
      name: name ?? this.name,
      pixels: pixels ?? this.pixels,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
      opacity: opacity ?? this.opacity,
      order: order ?? this.order,
      effects: effects ?? this.effects,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (frameId.present) {
      map['frame_id'] = Variable<int>(frameId.value);
    }
    if (layerId.present) {
      map['layer_id'] = Variable<String>(layerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (pixels.present) {
      map['pixels'] = Variable<Uint8List>(pixels.value);
    }
    if (isVisible.present) {
      map['is_visible'] = Variable<bool>(isVisible.value);
    }
    if (isLocked.present) {
      map['is_locked'] = Variable<bool>(isLocked.value);
    }
    if (opacity.present) {
      map['opacity'] = Variable<double>(opacity.value);
    }
    if (order.present) {
      map['order'] = Variable<int>(order.value);
    }
    if (effects.present) {
      map['effects'] = Variable<String>(effects.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LayersTableCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('frameId: $frameId, ')
          ..write('layerId: $layerId, ')
          ..write('name: $name, ')
          ..write('pixels: $pixels, ')
          ..write('isVisible: $isVisible, ')
          ..write('isLocked: $isLocked, ')
          ..write('opacity: $opacity, ')
          ..write('order: $order, ')
          ..write('effects: $effects')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProjectsTableTable projectsTable = $ProjectsTableTable(this);
  late final $AnimationStateTableTable animationStateTable =
      $AnimationStateTableTable(this);
  late final $FramesTableTable framesTable = $FramesTableTable(this);
  late final $LayersTableTable layersTable = $LayersTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [projectsTable, animationStateTable, framesTable, layersTable];
}

typedef $$ProjectsTableTableCreateCompanionBuilder = ProjectsTableCompanion
    Function({
  Value<int> id,
  required String name,
  required int width,
  required int height,
  Value<Uint8List?> thumbnail,
  Value<bool> isCloudSynced,
  Value<int?> remoteId,
  required DateTime createdAt,
  required DateTime editedAt,
  Value<String> projectType,
  Value<int?> tileWidth,
  Value<int?> tileHeight,
  Value<int?> gridColumns,
  Value<int?> gridRows,
  Value<String?> tilemapData,
});
typedef $$ProjectsTableTableUpdateCompanionBuilder = ProjectsTableCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<int> width,
  Value<int> height,
  Value<Uint8List?> thumbnail,
  Value<bool> isCloudSynced,
  Value<int?> remoteId,
  Value<DateTime> createdAt,
  Value<DateTime> editedAt,
  Value<String> projectType,
  Value<int?> tileWidth,
  Value<int?> tileHeight,
  Value<int?> gridColumns,
  Value<int?> gridRows,
  Value<String?> tilemapData,
});

final class $$ProjectsTableTableReferences extends BaseReferences<_$AppDatabase,
    $ProjectsTableTable, ProjectsTableData> {
  $$ProjectsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AnimationStateTableTable,
      List<AnimationStateTableData>> _animationStateTableRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.animationStateTable,
          aliasName: $_aliasNameGenerator(
              db.projectsTable.id, db.animationStateTable.projectId));

  $$AnimationStateTableTableProcessedTableManager get animationStateTableRefs {
    final manager =
        $$AnimationStateTableTableTableManager($_db, $_db.animationStateTable)
            .filter((f) => f.projectId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_animationStateTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$FramesTableTable, List<FramesTableData>>
      _framesTableRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.framesTable,
              aliasName: $_aliasNameGenerator(
                  db.projectsTable.id, db.framesTable.projectId));

  $$FramesTableTableProcessedTableManager get framesTableRefs {
    final manager = $$FramesTableTableTableManager($_db, $_db.framesTable)
        .filter((f) => f.projectId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_framesTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$LayersTableTable, List<LayersTableData>>
      _layersTableRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.layersTable,
              aliasName: $_aliasNameGenerator(
                  db.projectsTable.id, db.layersTable.projectId));

  $$LayersTableTableProcessedTableManager get layersTableRefs {
    final manager = $$LayersTableTableTableManager($_db, $_db.layersTable)
        .filter((f) => f.projectId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_layersTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProjectsTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $ProjectsTableTable> {
  $$ProjectsTableTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get width => $state.composableBuilder(
      column: $state.table.width,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get height => $state.composableBuilder(
      column: $state.table.height,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<Uint8List> get thumbnail => $state.composableBuilder(
      column: $state.table.thumbnail,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isCloudSynced => $state.composableBuilder(
      column: $state.table.isCloudSynced,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get remoteId => $state.composableBuilder(
      column: $state.table.remoteId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get editedAt => $state.composableBuilder(
      column: $state.table.editedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get projectType => $state.composableBuilder(
      column: $state.table.projectType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get tileWidth => $state.composableBuilder(
      column: $state.table.tileWidth,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get tileHeight => $state.composableBuilder(
      column: $state.table.tileHeight,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get gridColumns => $state.composableBuilder(
      column: $state.table.gridColumns,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get gridRows => $state.composableBuilder(
      column: $state.table.gridRows,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tilemapData => $state.composableBuilder(
      column: $state.table.tilemapData,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter animationStateTableRefs(
      ComposableFilter Function($$AnimationStateTableTableFilterComposer f) f) {
    final $$AnimationStateTableTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.animationStateTable,
            getReferencedColumn: (t) => t.projectId,
            builder: (joinBuilder, parentComposers) =>
                $$AnimationStateTableTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.animationStateTable,
                    joinBuilder,
                    parentComposers)));
    return f(composer);
  }

  ComposableFilter framesTableRefs(
      ComposableFilter Function($$FramesTableTableFilterComposer f) f) {
    final $$FramesTableTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.framesTable,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder, parentComposers) =>
            $$FramesTableTableFilterComposer(ComposerState($state.db,
                $state.db.framesTable, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter layersTableRefs(
      ComposableFilter Function($$LayersTableTableFilterComposer f) f) {
    final $$LayersTableTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.layersTable,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder, parentComposers) =>
            $$LayersTableTableFilterComposer(ComposerState($state.db,
                $state.db.layersTable, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$ProjectsTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $ProjectsTableTable> {
  $$ProjectsTableTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get width => $state.composableBuilder(
      column: $state.table.width,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get height => $state.composableBuilder(
      column: $state.table.height,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<Uint8List> get thumbnail => $state.composableBuilder(
      column: $state.table.thumbnail,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isCloudSynced => $state.composableBuilder(
      column: $state.table.isCloudSynced,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get remoteId => $state.composableBuilder(
      column: $state.table.remoteId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get editedAt => $state.composableBuilder(
      column: $state.table.editedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get projectType => $state.composableBuilder(
      column: $state.table.projectType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get tileWidth => $state.composableBuilder(
      column: $state.table.tileWidth,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get tileHeight => $state.composableBuilder(
      column: $state.table.tileHeight,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get gridColumns => $state.composableBuilder(
      column: $state.table.gridColumns,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get gridRows => $state.composableBuilder(
      column: $state.table.gridRows,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tilemapData => $state.composableBuilder(
      column: $state.table.tilemapData,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$ProjectsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProjectsTableTable,
    ProjectsTableData,
    $$ProjectsTableTableFilterComposer,
    $$ProjectsTableTableOrderingComposer,
    $$ProjectsTableTableCreateCompanionBuilder,
    $$ProjectsTableTableUpdateCompanionBuilder,
    (ProjectsTableData, $$ProjectsTableTableReferences),
    ProjectsTableData,
    PrefetchHooks Function(
        {bool animationStateTableRefs,
        bool framesTableRefs,
        bool layersTableRefs})> {
  $$ProjectsTableTableTableManager(_$AppDatabase db, $ProjectsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$ProjectsTableTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$ProjectsTableTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> width = const Value.absent(),
            Value<int> height = const Value.absent(),
            Value<Uint8List?> thumbnail = const Value.absent(),
            Value<bool> isCloudSynced = const Value.absent(),
            Value<int?> remoteId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> editedAt = const Value.absent(),
            Value<String> projectType = const Value.absent(),
            Value<int?> tileWidth = const Value.absent(),
            Value<int?> tileHeight = const Value.absent(),
            Value<int?> gridColumns = const Value.absent(),
            Value<int?> gridRows = const Value.absent(),
            Value<String?> tilemapData = const Value.absent(),
          }) =>
              ProjectsTableCompanion(
            id: id,
            name: name,
            width: width,
            height: height,
            thumbnail: thumbnail,
            isCloudSynced: isCloudSynced,
            remoteId: remoteId,
            createdAt: createdAt,
            editedAt: editedAt,
            projectType: projectType,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            gridColumns: gridColumns,
            gridRows: gridRows,
            tilemapData: tilemapData,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required int width,
            required int height,
            Value<Uint8List?> thumbnail = const Value.absent(),
            Value<bool> isCloudSynced = const Value.absent(),
            Value<int?> remoteId = const Value.absent(),
            required DateTime createdAt,
            required DateTime editedAt,
            Value<String> projectType = const Value.absent(),
            Value<int?> tileWidth = const Value.absent(),
            Value<int?> tileHeight = const Value.absent(),
            Value<int?> gridColumns = const Value.absent(),
            Value<int?> gridRows = const Value.absent(),
            Value<String?> tilemapData = const Value.absent(),
          }) =>
              ProjectsTableCompanion.insert(
            id: id,
            name: name,
            width: width,
            height: height,
            thumbnail: thumbnail,
            isCloudSynced: isCloudSynced,
            remoteId: remoteId,
            createdAt: createdAt,
            editedAt: editedAt,
            projectType: projectType,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
            gridColumns: gridColumns,
            gridRows: gridRows,
            tilemapData: tilemapData,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ProjectsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {animationStateTableRefs = false,
              framesTableRefs = false,
              layersTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (animationStateTableRefs) db.animationStateTable,
                if (framesTableRefs) db.framesTable,
                if (layersTableRefs) db.layersTable
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (animationStateTableRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$ProjectsTableTableReferences
                            ._animationStateTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProjectsTableTableReferences(db, table, p0)
                                .animationStateTableRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.projectId == item.id),
                        typedResults: items),
                  if (framesTableRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$ProjectsTableTableReferences
                            ._framesTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProjectsTableTableReferences(db, table, p0)
                                .framesTableRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.projectId == item.id),
                        typedResults: items),
                  if (layersTableRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$ProjectsTableTableReferences
                            ._layersTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProjectsTableTableReferences(db, table, p0)
                                .layersTableRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.projectId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProjectsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProjectsTableTable,
    ProjectsTableData,
    $$ProjectsTableTableFilterComposer,
    $$ProjectsTableTableOrderingComposer,
    $$ProjectsTableTableCreateCompanionBuilder,
    $$ProjectsTableTableUpdateCompanionBuilder,
    (ProjectsTableData, $$ProjectsTableTableReferences),
    ProjectsTableData,
    PrefetchHooks Function(
        {bool animationStateTableRefs,
        bool framesTableRefs,
        bool layersTableRefs})>;
typedef $$AnimationStateTableTableCreateCompanionBuilder
    = AnimationStateTableCompanion Function({
  Value<int> id,
  required int projectId,
  required String name,
  required int frameRate,
  required DateTime createdAt,
  required DateTime editedAt,
});
typedef $$AnimationStateTableTableUpdateCompanionBuilder
    = AnimationStateTableCompanion Function({
  Value<int> id,
  Value<int> projectId,
  Value<String> name,
  Value<int> frameRate,
  Value<DateTime> createdAt,
  Value<DateTime> editedAt,
});

final class $$AnimationStateTableTableReferences extends BaseReferences<
    _$AppDatabase, $AnimationStateTableTable, AnimationStateTableData> {
  $$AnimationStateTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTableTable _projectIdTable(_$AppDatabase db) =>
      db.projectsTable.createAlias($_aliasNameGenerator(
          db.animationStateTable.projectId, db.projectsTable.id));

  $$ProjectsTableTableProcessedTableManager? get projectId {
    if ($_item.projectId == null) return null;
    final manager = $$ProjectsTableTableTableManager($_db, $_db.projectsTable)
        .filter((f) => f.id($_item.projectId!));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$FramesTableTable, List<FramesTableData>>
      _framesTableRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.framesTable,
              aliasName: $_aliasNameGenerator(
                  db.animationStateTable.id, db.framesTable.stateId));

  $$FramesTableTableProcessedTableManager get framesTableRefs {
    final manager = $$FramesTableTableTableManager($_db, $_db.framesTable)
        .filter((f) => f.stateId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_framesTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AnimationStateTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $AnimationStateTableTable> {
  $$AnimationStateTableTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get frameRate => $state.composableBuilder(
      column: $state.table.frameRate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get editedAt => $state.composableBuilder(
      column: $state.table.editedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ProjectsTableTableFilterComposer get projectId {
    final $$ProjectsTableTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $state.db.projectsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProjectsTableTableFilterComposer(ComposerState($state.db,
                $state.db.projectsTable, joinBuilder, parentComposers)));
    return composer;
  }

  ComposableFilter framesTableRefs(
      ComposableFilter Function($$FramesTableTableFilterComposer f) f) {
    final $$FramesTableTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.framesTable,
        getReferencedColumn: (t) => t.stateId,
        builder: (joinBuilder, parentComposers) =>
            $$FramesTableTableFilterComposer(ComposerState($state.db,
                $state.db.framesTable, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$AnimationStateTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $AnimationStateTableTable> {
  $$AnimationStateTableTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get frameRate => $state.composableBuilder(
      column: $state.table.frameRate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get editedAt => $state.composableBuilder(
      column: $state.table.editedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ProjectsTableTableOrderingComposer get projectId {
    final $$ProjectsTableTableOrderingComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.projectId,
            referencedTable: $state.db.projectsTable,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$ProjectsTableTableOrderingComposer(ComposerState($state.db,
                    $state.db.projectsTable, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$AnimationStateTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AnimationStateTableTable,
    AnimationStateTableData,
    $$AnimationStateTableTableFilterComposer,
    $$AnimationStateTableTableOrderingComposer,
    $$AnimationStateTableTableCreateCompanionBuilder,
    $$AnimationStateTableTableUpdateCompanionBuilder,
    (AnimationStateTableData, $$AnimationStateTableTableReferences),
    AnimationStateTableData,
    PrefetchHooks Function({bool projectId, bool framesTableRefs})> {
  $$AnimationStateTableTableTableManager(
      _$AppDatabase db, $AnimationStateTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$AnimationStateTableTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$AnimationStateTableTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> projectId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> frameRate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> editedAt = const Value.absent(),
          }) =>
              AnimationStateTableCompanion(
            id: id,
            projectId: projectId,
            name: name,
            frameRate: frameRate,
            createdAt: createdAt,
            editedAt: editedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int projectId,
            required String name,
            required int frameRate,
            required DateTime createdAt,
            required DateTime editedAt,
          }) =>
              AnimationStateTableCompanion.insert(
            id: id,
            projectId: projectId,
            name: name,
            frameRate: frameRate,
            createdAt: createdAt,
            editedAt: editedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AnimationStateTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {projectId = false, framesTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (framesTableRefs) db.framesTable],
              addJoins: <
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
                      dynamic>>(state) {
                if (projectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.projectId,
                    referencedTable: $$AnimationStateTableTableReferences
                        ._projectIdTable(db),
                    referencedColumn: $$AnimationStateTableTableReferences
                        ._projectIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (framesTableRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$AnimationStateTableTableReferences
                            ._framesTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AnimationStateTableTableReferences(db, table, p0)
                                .framesTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.stateId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AnimationStateTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AnimationStateTableTable,
    AnimationStateTableData,
    $$AnimationStateTableTableFilterComposer,
    $$AnimationStateTableTableOrderingComposer,
    $$AnimationStateTableTableCreateCompanionBuilder,
    $$AnimationStateTableTableUpdateCompanionBuilder,
    (AnimationStateTableData, $$AnimationStateTableTableReferences),
    AnimationStateTableData,
    PrefetchHooks Function({bool projectId, bool framesTableRefs})>;
typedef $$FramesTableTableCreateCompanionBuilder = FramesTableCompanion
    Function({
  Value<int> id,
  required int projectId,
  required int stateId,
  required String name,
  required int duration,
  required int order,
  required DateTime createdAt,
  required DateTime editedAt,
});
typedef $$FramesTableTableUpdateCompanionBuilder = FramesTableCompanion
    Function({
  Value<int> id,
  Value<int> projectId,
  Value<int> stateId,
  Value<String> name,
  Value<int> duration,
  Value<int> order,
  Value<DateTime> createdAt,
  Value<DateTime> editedAt,
});

final class $$FramesTableTableReferences
    extends BaseReferences<_$AppDatabase, $FramesTableTable, FramesTableData> {
  $$FramesTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTableTable _projectIdTable(_$AppDatabase db) =>
      db.projectsTable.createAlias(
          $_aliasNameGenerator(db.framesTable.projectId, db.projectsTable.id));

  $$ProjectsTableTableProcessedTableManager? get projectId {
    if ($_item.projectId == null) return null;
    final manager = $$ProjectsTableTableTableManager($_db, $_db.projectsTable)
        .filter((f) => f.id($_item.projectId!));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AnimationStateTableTable _stateIdTable(_$AppDatabase db) =>
      db.animationStateTable.createAlias($_aliasNameGenerator(
          db.framesTable.stateId, db.animationStateTable.id));

  $$AnimationStateTableTableProcessedTableManager? get stateId {
    if ($_item.stateId == null) return null;
    final manager =
        $$AnimationStateTableTableTableManager($_db, $_db.animationStateTable)
            .filter((f) => f.id($_item.stateId!));
    final item = $_typedResult.readTableOrNull(_stateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$LayersTableTable, List<LayersTableData>>
      _layersTableRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.layersTable,
          aliasName:
              $_aliasNameGenerator(db.framesTable.id, db.layersTable.frameId));

  $$LayersTableTableProcessedTableManager get layersTableRefs {
    final manager = $$LayersTableTableTableManager($_db, $_db.layersTable)
        .filter((f) => f.frameId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_layersTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$FramesTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $FramesTableTable> {
  $$FramesTableTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get duration => $state.composableBuilder(
      column: $state.table.duration,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get editedAt => $state.composableBuilder(
      column: $state.table.editedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ProjectsTableTableFilterComposer get projectId {
    final $$ProjectsTableTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $state.db.projectsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProjectsTableTableFilterComposer(ComposerState($state.db,
                $state.db.projectsTable, joinBuilder, parentComposers)));
    return composer;
  }

  $$AnimationStateTableTableFilterComposer get stateId {
    final $$AnimationStateTableTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.stateId,
            referencedTable: $state.db.animationStateTable,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$AnimationStateTableTableFilterComposer(ComposerState(
                    $state.db,
                    $state.db.animationStateTable,
                    joinBuilder,
                    parentComposers)));
    return composer;
  }

  ComposableFilter layersTableRefs(
      ComposableFilter Function($$LayersTableTableFilterComposer f) f) {
    final $$LayersTableTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.layersTable,
        getReferencedColumn: (t) => t.frameId,
        builder: (joinBuilder, parentComposers) =>
            $$LayersTableTableFilterComposer(ComposerState($state.db,
                $state.db.layersTable, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$FramesTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $FramesTableTable> {
  $$FramesTableTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get duration => $state.composableBuilder(
      column: $state.table.duration,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get editedAt => $state.composableBuilder(
      column: $state.table.editedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ProjectsTableTableOrderingComposer get projectId {
    final $$ProjectsTableTableOrderingComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.projectId,
            referencedTable: $state.db.projectsTable,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$ProjectsTableTableOrderingComposer(ComposerState($state.db,
                    $state.db.projectsTable, joinBuilder, parentComposers)));
    return composer;
  }

  $$AnimationStateTableTableOrderingComposer get stateId {
    final $$AnimationStateTableTableOrderingComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.stateId,
            referencedTable: $state.db.animationStateTable,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$AnimationStateTableTableOrderingComposer(ComposerState(
                    $state.db,
                    $state.db.animationStateTable,
                    joinBuilder,
                    parentComposers)));
    return composer;
  }
}

class $$FramesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FramesTableTable,
    FramesTableData,
    $$FramesTableTableFilterComposer,
    $$FramesTableTableOrderingComposer,
    $$FramesTableTableCreateCompanionBuilder,
    $$FramesTableTableUpdateCompanionBuilder,
    (FramesTableData, $$FramesTableTableReferences),
    FramesTableData,
    PrefetchHooks Function(
        {bool projectId, bool stateId, bool layersTableRefs})> {
  $$FramesTableTableTableManager(_$AppDatabase db, $FramesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$FramesTableTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$FramesTableTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> projectId = const Value.absent(),
            Value<int> stateId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> duration = const Value.absent(),
            Value<int> order = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> editedAt = const Value.absent(),
          }) =>
              FramesTableCompanion(
            id: id,
            projectId: projectId,
            stateId: stateId,
            name: name,
            duration: duration,
            order: order,
            createdAt: createdAt,
            editedAt: editedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int projectId,
            required int stateId,
            required String name,
            required int duration,
            required int order,
            required DateTime createdAt,
            required DateTime editedAt,
          }) =>
              FramesTableCompanion.insert(
            id: id,
            projectId: projectId,
            stateId: stateId,
            name: name,
            duration: duration,
            order: order,
            createdAt: createdAt,
            editedAt: editedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$FramesTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {projectId = false, stateId = false, layersTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (layersTableRefs) db.layersTable],
              addJoins: <
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
                      dynamic>>(state) {
                if (projectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.projectId,
                    referencedTable:
                        $$FramesTableTableReferences._projectIdTable(db),
                    referencedColumn:
                        $$FramesTableTableReferences._projectIdTable(db).id,
                  ) as T;
                }
                if (stateId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.stateId,
                    referencedTable:
                        $$FramesTableTableReferences._stateIdTable(db),
                    referencedColumn:
                        $$FramesTableTableReferences._stateIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (layersTableRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$FramesTableTableReferences
                            ._layersTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$FramesTableTableReferences(db, table, p0)
                                .layersTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.frameId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$FramesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $FramesTableTable,
    FramesTableData,
    $$FramesTableTableFilterComposer,
    $$FramesTableTableOrderingComposer,
    $$FramesTableTableCreateCompanionBuilder,
    $$FramesTableTableUpdateCompanionBuilder,
    (FramesTableData, $$FramesTableTableReferences),
    FramesTableData,
    PrefetchHooks Function(
        {bool projectId, bool stateId, bool layersTableRefs})>;
typedef $$LayersTableTableCreateCompanionBuilder = LayersTableCompanion
    Function({
  Value<int> id,
  required int projectId,
  required int frameId,
  required String layerId,
  required String name,
  required Uint8List pixels,
  Value<bool> isVisible,
  Value<bool> isLocked,
  Value<double> opacity,
  required int order,
  Value<String?> effects,
});
typedef $$LayersTableTableUpdateCompanionBuilder = LayersTableCompanion
    Function({
  Value<int> id,
  Value<int> projectId,
  Value<int> frameId,
  Value<String> layerId,
  Value<String> name,
  Value<Uint8List> pixels,
  Value<bool> isVisible,
  Value<bool> isLocked,
  Value<double> opacity,
  Value<int> order,
  Value<String?> effects,
});

final class $$LayersTableTableReferences
    extends BaseReferences<_$AppDatabase, $LayersTableTable, LayersTableData> {
  $$LayersTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTableTable _projectIdTable(_$AppDatabase db) =>
      db.projectsTable.createAlias(
          $_aliasNameGenerator(db.layersTable.projectId, db.projectsTable.id));

  $$ProjectsTableTableProcessedTableManager? get projectId {
    if ($_item.projectId == null) return null;
    final manager = $$ProjectsTableTableTableManager($_db, $_db.projectsTable)
        .filter((f) => f.id($_item.projectId!));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $FramesTableTable _frameIdTable(_$AppDatabase db) =>
      db.framesTable.createAlias(
          $_aliasNameGenerator(db.layersTable.frameId, db.framesTable.id));

  $$FramesTableTableProcessedTableManager? get frameId {
    if ($_item.frameId == null) return null;
    final manager = $$FramesTableTableTableManager($_db, $_db.framesTable)
        .filter((f) => f.id($_item.frameId!));
    final item = $_typedResult.readTableOrNull(_frameIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$LayersTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LayersTableTable> {
  $$LayersTableTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get layerId => $state.composableBuilder(
      column: $state.table.layerId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<Uint8List> get pixels => $state.composableBuilder(
      column: $state.table.pixels,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isVisible => $state.composableBuilder(
      column: $state.table.isVisible,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isLocked => $state.composableBuilder(
      column: $state.table.isLocked,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get opacity => $state.composableBuilder(
      column: $state.table.opacity,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get effects => $state.composableBuilder(
      column: $state.table.effects,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$ProjectsTableTableFilterComposer get projectId {
    final $$ProjectsTableTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $state.db.projectsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$ProjectsTableTableFilterComposer(ComposerState($state.db,
                $state.db.projectsTable, joinBuilder, parentComposers)));
    return composer;
  }

  $$FramesTableTableFilterComposer get frameId {
    final $$FramesTableTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.frameId,
        referencedTable: $state.db.framesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$FramesTableTableFilterComposer(ComposerState($state.db,
                $state.db.framesTable, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$LayersTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LayersTableTable> {
  $$LayersTableTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get layerId => $state.composableBuilder(
      column: $state.table.layerId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<Uint8List> get pixels => $state.composableBuilder(
      column: $state.table.pixels,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isVisible => $state.composableBuilder(
      column: $state.table.isVisible,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isLocked => $state.composableBuilder(
      column: $state.table.isLocked,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get opacity => $state.composableBuilder(
      column: $state.table.opacity,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get order => $state.composableBuilder(
      column: $state.table.order,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get effects => $state.composableBuilder(
      column: $state.table.effects,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$ProjectsTableTableOrderingComposer get projectId {
    final $$ProjectsTableTableOrderingComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.projectId,
            referencedTable: $state.db.projectsTable,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder, parentComposers) =>
                $$ProjectsTableTableOrderingComposer(ComposerState($state.db,
                    $state.db.projectsTable, joinBuilder, parentComposers)));
    return composer;
  }

  $$FramesTableTableOrderingComposer get frameId {
    final $$FramesTableTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.frameId,
        referencedTable: $state.db.framesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$FramesTableTableOrderingComposer(ComposerState($state.db,
                $state.db.framesTable, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$LayersTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LayersTableTable,
    LayersTableData,
    $$LayersTableTableFilterComposer,
    $$LayersTableTableOrderingComposer,
    $$LayersTableTableCreateCompanionBuilder,
    $$LayersTableTableUpdateCompanionBuilder,
    (LayersTableData, $$LayersTableTableReferences),
    LayersTableData,
    PrefetchHooks Function({bool projectId, bool frameId})> {
  $$LayersTableTableTableManager(_$AppDatabase db, $LayersTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$LayersTableTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$LayersTableTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> projectId = const Value.absent(),
            Value<int> frameId = const Value.absent(),
            Value<String> layerId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<Uint8List> pixels = const Value.absent(),
            Value<bool> isVisible = const Value.absent(),
            Value<bool> isLocked = const Value.absent(),
            Value<double> opacity = const Value.absent(),
            Value<int> order = const Value.absent(),
            Value<String?> effects = const Value.absent(),
          }) =>
              LayersTableCompanion(
            id: id,
            projectId: projectId,
            frameId: frameId,
            layerId: layerId,
            name: name,
            pixels: pixels,
            isVisible: isVisible,
            isLocked: isLocked,
            opacity: opacity,
            order: order,
            effects: effects,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int projectId,
            required int frameId,
            required String layerId,
            required String name,
            required Uint8List pixels,
            Value<bool> isVisible = const Value.absent(),
            Value<bool> isLocked = const Value.absent(),
            Value<double> opacity = const Value.absent(),
            required int order,
            Value<String?> effects = const Value.absent(),
          }) =>
              LayersTableCompanion.insert(
            id: id,
            projectId: projectId,
            frameId: frameId,
            layerId: layerId,
            name: name,
            pixels: pixels,
            isVisible: isVisible,
            isLocked: isLocked,
            opacity: opacity,
            order: order,
            effects: effects,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$LayersTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({projectId = false, frameId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (projectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.projectId,
                    referencedTable:
                        $$LayersTableTableReferences._projectIdTable(db),
                    referencedColumn:
                        $$LayersTableTableReferences._projectIdTable(db).id,
                  ) as T;
                }
                if (frameId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.frameId,
                    referencedTable:
                        $$LayersTableTableReferences._frameIdTable(db),
                    referencedColumn:
                        $$LayersTableTableReferences._frameIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$LayersTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LayersTableTable,
    LayersTableData,
    $$LayersTableTableFilterComposer,
    $$LayersTableTableOrderingComposer,
    $$LayersTableTableCreateCompanionBuilder,
    $$LayersTableTableUpdateCompanionBuilder,
    (LayersTableData, $$LayersTableTableReferences),
    LayersTableData,
    PrefetchHooks Function({bool projectId, bool frameId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProjectsTableTableTableManager get projectsTable =>
      $$ProjectsTableTableTableManager(_db, _db.projectsTable);
  $$AnimationStateTableTableTableManager get animationStateTable =>
      $$AnimationStateTableTableTableManager(_db, _db.animationStateTable);
  $$FramesTableTableTableManager get framesTable =>
      $$FramesTableTableTableManager(_db, _db.framesTable);
  $$LayersTableTableTableManager get layersTable =>
      $$LayersTableTableTableManager(_db, _db.layersTable);
}
