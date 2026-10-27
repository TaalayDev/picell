import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/database/project_database.dart';
import 'package:picell/data/models/project_model.dart';
import 'package:picell/pixel/tileset/tileset_generator.dart';
import 'package:picell/pixel/tileset/tileset_project.dart';

Project blank() =>
    Project(id: 1, name: 'Before', width: 16, height: 16, createdAt: DateTime(2026), editedAt: DateTime(2026));
TilesetDocument document() {
  final settings = TilesetSettings(variations: 1);
  return TilesetDocument(
      name: 'Library Tiles',
      settings: settings,
      tiles: generatePlatformTileset(settings),
      columns: 2,
      rows: 1,
      cells: [1, 0]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('project adapter preserves identity, document pixels and RGBA thumbnail', () {
    final doc = document();
    final result = projectWithTileset((project: blank(), document: doc));
    expect(result.id, 1);
    expect(result.createdAt, DateTime(2026));
    expect(result.type, ProjectType.proceduralTileset);
    expect(result.width, 32);
    expect(result.height, 16);
    expect(result.thumbnail!.length, 32 * 16 * 4);
    final pixels = doc.tiles.firstWhere((t) => t.mask == 0).pixels;
    final pixel = pixels[5 * 16 + 5];
    const offset = (5 * 32 + 5) * 4;
    expect(
        result.thumbnail!.sublist(offset, offset + 4), [pixel >> 16 & 255, pixel >> 8 & 255, pixel & 255, pixel >> 24]);
    expect(result.thumbnail!.sublist((5 * 32 + 20) * 4, (5 * 32 + 20) * 4 + 4), [0, 0, 0, 0]);
    final restored = Project.fromJson(jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>);
    expect(restored.tilesetData, result.tilesetData);
    expect(restored.type, ProjectType.proceduralTileset);
    expect(restored.copyWith(name: 'Copy').tilesetData, result.tilesetData);
    expect(restored.copyWith(clearTilesetData: true).tilesetData, isNull);
  });

  test('database creates, updates, lists and duplicates tileset documents without frames', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final source = projectWithTileset((project: blank(), document: document()));
    final created = await db.insertProject(source);
    final loaded = await db.getProject(created.id);
    expect(loaded!.tilesetData, source.tilesetData);
    expect(loaded.type, ProjectType.proceduralTileset);
    expect(loaded.frames, isEmpty);
    final changed = loaded.copyWith(name: 'Renamed');
    await db.updateProject(changed);
    expect((await db.getProject(created.id))!.name, 'Renamed');
    final copy = await db.insertProject(changed.copyWith(id: 0));
    expect(copy.id, isNot(created.id));
    expect((await db.getProject(copy.id))!.tilesetData, source.tilesetData);
    final listed = await db.getAllProjects().first;
    expect(listed.length, 2);
    expect(listed.every((p) => p.tilesetData == source.tilesetData), isTrue);
  });

  test('v10 migration preserves existing projects and adds nullable tileset data', () async {
    final temp = await Directory.systemTemp.createTemp('pv_tileset_migration_');
    addTearDown(() => temp.delete(recursive: true));
    final file = File('${temp.path}/migration.sqlite');
    final old = AppDatabase.forTesting(NativeDatabase(file));
    final existing = await old.insertProject(blank().copyWith(name: 'Existing Art', tilemapData: '{"legacy":true}'));
    // Build the actual v10 projects-table layout from the current schema,
    // preserving all existing tables, constraints and project rows.
    await old.customStatement('ALTER TABLE projects_table DROP COLUMN tileset_data');
    await old.customStatement('PRAGMA user_version = 10');
    await old.close();
    final upgraded = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(upgraded.close);
    final loaded = await upgraded.getProject(existing.id);
    expect(loaded!.name, 'Existing Art');
    expect(loaded.tilemapData, '{"legacy":true}');
    expect(loaded.tilesetData, isNull);
    final generated = projectWithTileset((project: loaded, document: document()));
    await upgraded.updateProject(generated);
    expect((await upgraded.getProject(existing.id))!.tilesetData, generated.tilesetData);
  });
}
