import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../data.dart';
import '../../pixel/effects/effects.dart';

part 'project_database.g.dart';

extension ListIntX on List<int> {
  int max() {
    return reduce((value, element) => value > element ? value : element);
  }
}

class ProjectsTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get width => integer()();
  IntColumn get height => integer()();
  BlobColumn get thumbnail => blob().nullable()();
  BoolColumn get isCloudSynced => boolean().withDefault(const Constant(false))();
  IntColumn get remoteId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get editedAt => dateTime()();
  // version 6 - tilemap support
  TextColumn get projectType => text().withDefault(const Constant('pixelArt'))();
  IntColumn get tileWidth => integer().nullable()();
  IntColumn get tileHeight => integer().nullable()();
  IntColumn get gridColumns => integer().nullable()();
  IntColumn get gridRows => integer().nullable()();
  // version 7 - tilemap state data
  TextColumn get tilemapData => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class LayersTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId => integer().references(ProjectsTable, #id)();
  IntColumn get frameId => integer().references(FramesTable, #id)();
  TextColumn get layerId => text().withLength(min: 1, max: 100)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  BlobColumn get pixels => blob()();
  BoolColumn get isVisible => boolean().withDefault(const Constant(true))();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  RealColumn get opacity => real().withDefault(const Constant(1.0))();
  IntColumn get order => integer()();
  // version 4
  TextColumn get effects => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class AnimationStateTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId => integer().references(ProjectsTable, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get frameRate => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get editedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class FramesTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId => integer().references(ProjectsTable, #id)();
  IntColumn get stateId => integer().references(AnimationStateTable, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get duration => integer()();
  IntColumn get order => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get editedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [ProjectsTable, FramesTable, LayersTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());
  static final AppDatabase instance = AppDatabase._();

  factory AppDatabase() => instance;

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.createTable(framesTable);
          await migrator.alterTable(TableMigration(
            layersTable,
            newColumns: [layersTable.frameId],
          ));
          await migrator.alterTable(TableMigration(
            layersTable,
            newColumns: [layersTable.order],
          ));
        }
        if (from < 3) {
          await _from2To3(migrator);
        }
        if (from < 4) {
          await migrator.alterTable(TableMigration(
            layersTable,
            newColumns: [layersTable.effects],
          ));
        }
        if (from < 5) {
          await migrator.alterTable(TableMigration(
            projectsTable,
            newColumns: [projectsTable.isCloudSynced, projectsTable.remoteId],
          ));
        }
        if (from < 6) {
          await migrator.alterTable(TableMigration(
            projectsTable,
            newColumns: [
              projectsTable.projectType,
              projectsTable.tileWidth,
              projectsTable.tileHeight,
              projectsTable.gridColumns,
              projectsTable.gridRows,
            ],
          ));
        }
        if (from < 7) {
          await migrator.alterTable(TableMigration(
            projectsTable,
            newColumns: [projectsTable.tilemapData],
          ));
        }
      },
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: kReleaseMode ? 'pixelverse.db' : 'pixelverse_dev.db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
        onResult: (result) {
          if (result.missingFeatures.isNotEmpty) {
            debugPrint(
              'Using ${result.chosenImplementation} due to unsupported '
              'browser features: ${result.missingFeatures}',
            );
          }
        },
      ),
    );
  }

  Future<void> _from2To3(Migrator migrator) async {
    await customStatement('PRAGMA foreign_keys = OFF');
    await migrator.createTable(animationStateTable);

    final projectStates = <int, int>{};

    final projects = await select(projectsTable).get();
    for (final project in projects) {
      final id = await into(animationStateTable).insert(
        AnimationStateTableCompanion(
          projectId: Value(project.id),
          name: const Value('Animation'),
          frameRate: const Value(24),
          createdAt: Value(DateTime.now()),
          editedAt: Value(DateTime.now()),
        ),
      );

      projectStates[project.id] = id;
    }

    await customStatement('''
      ALTER TABLE ${framesTable.actualTableName} ADD COLUMN state_id INTEGER NOT NULL REFERENCES ${animationStateTable.actualTableName}(id) ON DELETE CASCADE ON UPDATE CASCADE DEFAULT ${projectStates.values.first};
    ''');

    for (final project in projectStates.entries) {
      final frames = await (select(framesTable)..where((tbl) => tbl.projectId.equals(project.key))).get();
      for (final frame in frames) {
        await update(framesTable).replace(FramesTableCompanion(
          id: Value(frame.id),
          projectId: Value(frame.projectId),
          name: Value(frame.name),
          duration: Value(frame.duration),
          stateId: Value(project.value),
          order: Value(frame.order),
          createdAt: Value(frame.createdAt),
          editedAt: Value(frame.editedAt),
        ));
      }
    }

    await customStatement('PRAGMA foreign_keys = ON;');
  }

  Stream<List<Project>> getAllProjects() async* {
    final query = select(projectsTable).join([
      leftOuterJoin(
        animationStateTable,
        animationStateTable.projectId.equalsExp(projectsTable.id),
      ),
      leftOuterJoin(
        framesTable,
        framesTable.projectId.equalsExp(projectsTable.id),
      ),
      leftOuterJoin(
        layersTable,
        layersTable.frameId.equalsExp(framesTable.id),
      ),
    ])
      ..orderBy([
        OrderingTerm(
          expression: projectsTable.editedAt,
          mode: OrderingMode.desc,
        ),
        OrderingTerm(
          expression: animationStateTable.id,
          mode: OrderingMode.asc,
        ),
        OrderingTerm(expression: framesTable.order, mode: OrderingMode.asc),
        OrderingTerm(expression: layersTable.order, mode: OrderingMode.asc),
      ]);

    yield* query.watch().map((rows) {
      final projects = <int, Project>{};
      final states = <int, AnimationStateModel>{};
      final frames = <int, AnimationFrame>{};

      for (final row in rows) {
        final projectRow = row.readTable(projectsTable);
        final stateRow = row.readTableOrNull(animationStateTable);
        final frameRow = row.readTableOrNull(framesTable);
        final layerRow = row.readTableOrNull(layersTable);

        var project = projects[projectRow.id];
        if (project == null) {
          project = Project(
            id: projectRow.id,
            name: projectRow.name,
            width: projectRow.width,
            height: projectRow.height,
            thumbnail: projectRow.thumbnail,
            isCloudSynced: projectRow.isCloudSynced,
            remoteId: projectRow.remoteId,
            createdAt: projectRow.createdAt,
            editedAt: projectRow.editedAt,
            type: _parseProjectType(projectRow.projectType),
            tileWidth: projectRow.tileWidth,
            tileHeight: projectRow.tileHeight,
            tilemapData: projectRow.tilemapData,
            frames: [],
            states: [],
          );
          projects[projectRow.id] = project;
        }

        if (stateRow != null) {
          var state = states[stateRow.id];
          if (state == null) {
            state = AnimationStateModel(
              id: stateRow.id,
              name: stateRow.name,
              frameRate: stateRow.frameRate,
            );
            states[stateRow.id] = state;
            project.states.add(state);
          }
        }

        if (frameRow != null) {
          var frame = frames[frameRow.id];
          if (frame == null) {
            frame = AnimationFrame(
              id: frameRow.id,
              stateId: frameRow.stateId,
              name: frameRow.name,
              duration: frameRow.duration,
              createdAt: frameRow.createdAt,
              editedAt: frameRow.editedAt,
              layers: [],
            );
            frames[frameRow.id] = frame;
            project.frames.add(frame);
          }

          if (layerRow != null) {
            final layer = Layer(
              layerId: layerRow.id,
              id: layerRow.layerId,
              name: layerRow.name,
              pixels: layerRow.pixels.buffer.asUint32List(),
              isVisible: layerRow.isVisible,
              isLocked: layerRow.isLocked,
              opacity: layerRow.opacity,
              effects: _decodeEffects(layerRow.effects),
              order: layerRow.order,
            );
            frame.layers.add(layer);
          }
        }
      }

      return projects.values.toList();
    });
  }

  Future<Project?> getProject(int projectId) async {
    final query = select(projectsTable).join([
      leftOuterJoin(
        animationStateTable,
        animationStateTable.projectId.equalsExp(projectsTable.id),
      ),
      leftOuterJoin(
        framesTable,
        framesTable.projectId.equalsExp(projectsTable.id),
      ),
      leftOuterJoin(
        layersTable,
        layersTable.projectId.equalsExp(projectsTable.id),
      ),
    ])
      ..orderBy([
        OrderingTerm(
          expression: animationStateTable.id,
          mode: OrderingMode.asc,
        ),
        OrderingTerm(expression: framesTable.order, mode: OrderingMode.asc),
        OrderingTerm(expression: layersTable.order, mode: OrderingMode.asc),
      ])
      ..where(projectsTable.id.equals(projectId));

    final rows = await query.get();

    if (rows.isEmpty) {
      return null;
    }

    final projectMap = <int, Project>{};
    final frameMap = <int, AnimationFrame>{};
    final stateMap = <int, AnimationStateModel>{};

    for (final row in rows) {
      final project = row.readTable(projectsTable);
      final state = row.readTableOrNull(animationStateTable);
      final frame = row.readTableOrNull(framesTable);
      final layer = row.readTableOrNull(layersTable);

      if (!projectMap.containsKey(project.id)) {
        projectMap[project.id] = Project(
          id: project.id,
          name: project.name,
          width: project.width,
          height: project.height,
          thumbnail: project.thumbnail,
          createdAt: project.createdAt,
          editedAt: project.editedAt,
          isCloudSynced: project.isCloudSynced,
          remoteId: project.remoteId,
          type: _parseProjectType(project.projectType),
          tileWidth: project.tileWidth,
          tileHeight: project.tileHeight,
          tilemapData: project.tilemapData,
          states: [],
          frames: [],
        );
      }

      if (state != null && !stateMap.containsKey(state.id)) {
        stateMap[state.id] = AnimationStateModel(
          id: state.id,
          name: state.name,
          frameRate: state.frameRate,
        );
        projectMap[project.id]!.states.add(stateMap[state.id]!);
      }

      if (frame != null) {
        if (!frameMap.containsKey(frame.id)) {
          frameMap[frame.id] = AnimationFrame(
            id: frame.id,
            stateId: frame.stateId,
            name: frame.name,
            duration: frame.duration,
            createdAt: frame.createdAt,
            editedAt: frame.editedAt,
            layers: [],
          );
          projectMap[project.id]!.frames.add(frameMap[frame.id]!);
        }

        final containsLayer = frameMap[frame.id]!.layers.any((element) => element.layerId == layer?.id);
        if (layer != null && layer.frameId == frame.id && !containsLayer) {
          frameMap[frame.id]!.layers.add(Layer(
                layerId: layer.id,
                id: layer.layerId,
                name: layer.name,
                pixels: layer.pixels.buffer.asUint32List(),
                isVisible: layer.isVisible,
                isLocked: layer.isLocked,
                opacity: layer.opacity,
                order: layer.order,
                effects: _decodeEffects(layer.effects),
              ));
        }
      }
    }

    return projectMap[projectId];
  }

  Future<Project> getProjectByRemoteId(int remoteId) async {
    final query = select(projectsTable)..where((tbl) => tbl.remoteId.equals(remoteId));

    final projectRow = await query.getSingleOrNull();
    if (projectRow == null) {
      throw Exception('Project with remote ID $remoteId not found');
    }

    return Project(
      id: projectRow.id,
      name: projectRow.name,
      width: projectRow.width,
      height: projectRow.height,
      thumbnail: projectRow.thumbnail,
      createdAt: projectRow.createdAt,
      editedAt: projectRow.editedAt,
      isCloudSynced: projectRow.isCloudSynced,
      remoteId: projectRow.remoteId,
      type: _parseProjectType(projectRow.projectType),
      tileWidth: projectRow.tileWidth,
      tileHeight: projectRow.tileHeight,
      tilemapData: projectRow.tilemapData,
    );
  }

  Future<Project> insertProject(Project project) async {
    final projectId = await into(projectsTable).insert(ProjectsTableCompanion(
      name: Value(project.name),
      width: Value(project.width),
      height: Value(project.height),
      thumbnail: Value(project.thumbnail),
      createdAt: Value(project.createdAt),
      editedAt: Value(project.editedAt),
      isCloudSynced: Value(project.isCloudSynced),
      remoteId: Value(project.remoteId),
      projectType: Value(_projectTypeToString(project.type)),
      tileWidth: Value(project.tileWidth),
      tileHeight: Value(project.tileHeight),
      tilemapData: Value(project.tilemapData),
    ));

    final states = <AnimationStateModel>[];
    final stateIds = <int, int>{};
    for (final state in project.states) {
      final stateId = await into(animationStateTable).insert(
        AnimationStateTableCompanion(
          projectId: Value(projectId),
          name: Value(state.name),
          frameRate: Value(state.frameRate),
          createdAt: Value(DateTime.now()),
          editedAt: Value(DateTime.now()),
        ),
      );
      states.add(state.copyWith(id: stateId));
      if (state.id != 0) stateIds[state.id] = stateId;
    }

    final frames = <AnimationFrame>[];
    for (final frame in project.frames) {
      final frameId = await into(framesTable).insert(FramesTableCompanion(
        projectId: Value(projectId),
        stateId: Value(stateIds[frame.stateId] ?? frame.stateId),
        name: Value(frame.name),
        duration: Value(frame.duration),
        createdAt: Value(frame.createdAt),
        editedAt: Value(frame.editedAt),
        order: Value(frame.order),
      ));

      final layers = <Layer>[];
      for (final layer in frame.layers) {
        final layerId = await into(layersTable).insert(LayersTableCompanion(
          projectId: Value(projectId),
          layerId: Value(layer.id),
          frameId: Value(frameId),
          name: Value(layer.name),
          pixels: Value(layer.pixels.buffer.asUint8List()),
          isVisible: Value(layer.isVisible),
          isLocked: Value(layer.isLocked),
          opacity: Value(layer.opacity),
          order: Value(layer.order),
          effects: Value(_encodeEffects(layer.effects)),
        ));
        layers.add(layer.copyWith(layerId: layerId));
      }

      frames.add(frame.copyWith(id: frameId, layers: layers));
    }

    return project.copyWith(id: projectId, frames: frames);
  }

  Future<void> updateProject(Project project) async {
    await update(projectsTable).replace(ProjectsTableCompanion(
      id: Value(project.id),
      name: Value(project.name),
      width: Value(project.width),
      height: Value(project.height),
      thumbnail: Value(project.thumbnail),
      createdAt: Value(project.createdAt),
      editedAt: Value(project.editedAt),
      isCloudSynced: Value(project.isCloudSynced),
      remoteId: Value(project.remoteId),
      projectType: Value(project.type == ProjectType.tilemap ? 'tileGenerator' : project.type.name),
      tileWidth: Value(project.tileWidth),
      tileHeight: Value(project.tileHeight),
      tilemapData: Value(project.tilemapData),
    ));

    for (final state in project.states) {
      if (state.id == 0) {
        await into(animationStateTable).insert(AnimationStateTableCompanion(
          projectId: Value(project.id),
          name: Value(state.name),
          frameRate: Value(state.frameRate),
          createdAt: Value(DateTime.now()),
          editedAt: Value(DateTime.now()),
        ));
      } else {
        await update(animationStateTable).replace(AnimationStateTableCompanion(
          id: Value(state.id),
          projectId: Value(project.id),
          name: Value(state.name),
          frameRate: Value(state.frameRate),
          createdAt: Value(DateTime.now()),
          editedAt: Value(DateTime.now()),
        ));
      }
    }

    for (final frame in project.frames) {
      if (frame.id == 0) {
        final frameId = await into(framesTable).insert(FramesTableCompanion(
          projectId: Value(project.id),
          stateId: Value(frame.stateId),
          name: Value(frame.name),
          duration: Value(frame.duration),
          createdAt: Value(frame.createdAt),
          editedAt: Value(frame.editedAt),
        ));

        for (final layer in frame.layers) {
          await into(layersTable).insert(LayersTableCompanion(
            projectId: Value(project.id),
            frameId: Value(frameId),
            layerId: Value(layer.id),
            name: Value(layer.name),
            pixels: Value(layer.pixels.buffer.asUint8List()),
            isVisible: Value(layer.isVisible),
            isLocked: Value(layer.isLocked),
            opacity: Value(layer.opacity),
            order: Value(layer.order),
            effects: Value(_encodeEffects(layer.effects)),
          ));
        }
      } else {
        await update(framesTable).replace(FramesTableCompanion(
          id: Value(frame.id),
          projectId: Value(project.id),
          stateId: Value(frame.stateId),
          name: Value(frame.name),
          duration: Value(frame.duration),
          createdAt: Value(frame.createdAt),
          editedAt: Value(frame.editedAt),
          order: Value(frame.order),
        ));

        for (final layer in frame.layers) {
          if (layer.layerId == 0) {
            await into(layersTable).insert(LayersTableCompanion(
              projectId: Value(project.id),
              frameId: Value(frame.id),
              layerId: Value(layer.id),
              name: Value(layer.name),
              pixels: Value(layer.pixels.buffer.asUint8List()),
              isVisible: Value(layer.isVisible),
              isLocked: Value(layer.isLocked),
              opacity: Value(layer.opacity),
              order: Value(layer.order),
            ));
          } else {
            await update(layersTable).replace(LayersTableCompanion(
              id: Value(layer.layerId),
              projectId: Value(project.id),
              frameId: Value(frame.id),
              layerId: Value(layer.id),
              name: Value(layer.name),
              pixels: Value(layer.pixels.buffer.asUint8List()),
              isVisible: Value(layer.isVisible),
              isLocked: Value(layer.isLocked),
              opacity: Value(layer.opacity),
              order: Value(layer.order),
              effects: Value(_encodeEffects(layer.effects)),
            ));
          }
        }
      }
    }
  }

  Future<void> deleteProject(int projectId) async {
    await (delete(projectsTable)..where((tbl) => tbl.id.equals(projectId))).go();
    await (delete(animationStateTable)..where((tbl) => tbl.projectId.equals(projectId))).go();
    await (delete(framesTable)..where((tbl) => tbl.projectId.equals(projectId))).go();
    await (delete(layersTable)..where((tbl) => tbl.projectId.equals(projectId))).go();
  }

  Future<void> renameProject(int projectId, String name) async {
    (update(projectsTable)
      ..where((tbl) => tbl.id.equals(projectId))
      ..write(ProjectsTableCompanion(name: Value(name))));
  }

  Future<void> markProjectAsSynced(int projectId, int? remoteProjectId) async {
    await (update(projectsTable)..where((tbl) => tbl.id.equals(projectId))).write(ProjectsTableCompanion(
      isCloudSynced: const Value(true),
      remoteId: Value(remoteProjectId),
    ));
  }

  Future<void> markProjectAsUnsynced(int projectId) async {
    await (update(projectsTable)..where((tbl) => tbl.id.equals(projectId))).write(const ProjectsTableCompanion(
      isCloudSynced: Value(false),
      remoteId: Value(null),
    ));
  }

  Future<AnimationStateModel> insertState(
    int projectId,
    AnimationStateModel state,
  ) async {
    final stateId = await into(animationStateTable).insert(
      AnimationStateTableCompanion(
        projectId: Value(projectId),
        name: Value(state.name),
        frameRate: Value(state.frameRate),
        createdAt: Value(DateTime.now()),
        editedAt: Value(DateTime.now()),
      ),
    );

    return state.copyWith(id: stateId);
  }

  Future<void> updateState(int projectId, AnimationStateModel state) async {
    await update(animationStateTable).replace(
      AnimationStateTableCompanion(
        id: Value(state.id),
        projectId: Value(projectId),
        name: Value(state.name),
        frameRate: Value(state.frameRate),
        createdAt: Value(DateTime.now()),
        editedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteState(int stateId) async {
    await (delete(animationStateTable)..where((tbl) => tbl.id.equals(stateId))).go();
    await (delete(framesTable)..where((tbl) => tbl.stateId.equals(stateId))).go();
  }

  Future<AnimationFrame> insertFrame(
    int projectId,
    AnimationFrame frame,
  ) async {
    final frameId = await into(framesTable).insert(FramesTableCompanion(
      projectId: Value(projectId),
      name: Value(frame.name),
      stateId: Value(frame.stateId),
      duration: Value(frame.duration),
      createdAt: Value(frame.createdAt),
      editedAt: Value(frame.editedAt),
      order: Value(frame.order),
    ));

    final layers = <Layer>[];
    for (final (index, layer) in frame.layers.indexed) {
      final layerId = await into(layersTable).insert(LayersTableCompanion(
        projectId: Value(projectId),
        layerId: Value(layer.id),
        frameId: Value(frameId),
        name: Value(layer.name),
        pixels: Value(layer.pixels.buffer.asUint8List()),
        isVisible: Value(layer.isVisible),
        isLocked: Value(layer.isLocked),
        opacity: Value(layer.opacity),
        order: Value(layer.order),
        effects: Value(_encodeEffects(layer.effects)),
      ));
      layers.add(layer.copyWith(layerId: layerId));
    }

    return frame.copyWith(id: frameId, layers: layers);
  }

  Future<void> updateFrame(int projectId, AnimationFrame frame) async {
    await update(framesTable).replace(FramesTableCompanion(
      id: Value(frame.id),
      projectId: Value(projectId),
      stateId: Value(frame.stateId),
      name: Value(frame.name),
      duration: Value(frame.duration),
      createdAt: Value(frame.createdAt),
      editedAt: Value(frame.editedAt),
      order: Value(frame.order),
    ));

    for (final layer in frame.layers) {
      if (layer.layerId == 0) {
        await into(layersTable).insert(LayersTableCompanion(
          projectId: Value(projectId),
          frameId: Value(frame.id),
          layerId: Value(layer.id),
          name: Value(layer.name),
          pixels: Value(layer.pixels.buffer.asUint8List()),
          isVisible: Value(layer.isVisible),
          isLocked: Value(layer.isLocked),
          opacity: Value(layer.opacity),
          order: Value(layer.order),
          effects: Value(_encodeEffects(layer.effects)),
        ));
      } else {
        await update(layersTable).replace(LayersTableCompanion(
          id: Value(layer.layerId),
          projectId: Value(projectId),
          frameId: Value(frame.id),
          layerId: Value(layer.id),
          name: Value(layer.name),
          pixels: Value(layer.pixels.buffer.asUint8List()),
          isVisible: Value(layer.isVisible),
          isLocked: Value(layer.isLocked),
          opacity: Value(layer.opacity),
          order: Value(layer.order),
          effects: Value(_encodeEffects(layer.effects)),
        ));
      }
    }
  }

  Future<void> deleteFrame(int frameId) async {
    await (delete(framesTable)..where((tbl) => tbl.id.equals(frameId))).go();
    await (delete(layersTable)..where((tbl) => tbl.frameId.equals(frameId))).go();
  }

  Future<Layer> insertLayer(int projectId, int frameId, Layer layer) async {
    final layerId = await into(layersTable).insert(LayersTableCompanion(
      layerId: Value(layer.id),
      projectId: Value(projectId),
      frameId: Value(frameId),
      name: Value(layer.name),
      pixels: Value(layer.pixels.buffer.asUint8List()),
      isVisible: Value(layer.isVisible),
      isLocked: Value(layer.isLocked),
      opacity: Value(layer.opacity),
      order: Value(layer.order),
      effects: Value(_encodeEffects(layer.effects)),
    ));

    return layer.copyWith(layerId: layerId);
  }

  Future<void> updateLayer(int projectId, int frameId, Layer layer) async {
    await update(layersTable).replace(LayersTableCompanion(
      id: Value(layer.layerId),
      layerId: Value(layer.id),
      projectId: Value(projectId),
      frameId: Value(frameId),
      name: Value(layer.name),
      pixels: Value(layer.pixels.buffer.asUint8List()),
      isVisible: Value(layer.isVisible),
      isLocked: Value(layer.isLocked),
      opacity: Value(layer.opacity),
      order: Value(layer.order),
      effects: Value(_encodeEffects(layer.effects)),
    ));
  }

  Future<void> deleteLayer(int layerId) async {
    await (delete(layersTable)..where((tbl) => tbl.id.equals(layerId))).go();
  }

  List<Effect> _decodeEffects(String? effects) {
    if (effects == null) return [];
    try {
      final decoded = jsonDecode(effects) as List;
      return decoded
          .map((e) {
            return EffectsManager.effectFromJson(e);
          })
          .whereType<Effect>()
          .toList();
    } catch (e) {
      debugPrint('Error decoding effects: $e');
      return [];
    }
  }

  String _encodeEffects(List<Effect> effects) {
    return jsonEncode(effects.map((e) {
      return {
        'type': e.type.name,
        'parameters': e.parameters,
      };
    }).toList());
  }

  /// Parse project type from database string, handling legacy 'tilemap' values
  ProjectType _parseProjectType(String? typeString) {
    if (typeString == null) return ProjectType.pixelArt;
    if (typeString == 'tilemap') return ProjectType.tileGenerator;
    return ProjectType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => ProjectType.pixelArt,
    );
  }

  /// Convert project type to database string
  String _projectTypeToString(ProjectType type) {
    // Always save as tileGenerator, never as deprecated tilemap
    if (type == ProjectType.tilemap) return 'tileGenerator';
    return type.name;
  }
}
