import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data.dart';
import 'package:picell/data/database/project_database.dart';

void main() {
  late AppDatabase db;
  late Project project;

  Layer layer(String name, int pixel, {int order = 0}) =>
      Layer(layerId: 0, id: name, name: name, pixels: Uint32List.fromList([pixel, 0]), order: order);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    project = await db.insertProject(Project(
      id: 0,
      name: 'P',
      width: 2,
      height: 1,
      createdAt: DateTime(2026),
      editedAt: DateTime(2026),
      states: const [AnimationStateModel(id: 0, name: 'Idle', frameRate: 12)],
      frames: [
        AnimationFrame(
          id: 0,
          name: 'A',
          stateId: 0,
          duration: 100,
          createdAt: DateTime(2026),
          editedAt: DateTime(2026),
          layers: [layer('a1', 1), layer('a2', 2, order: 1)],
        ),
        AnimationFrame(
          id: 0,
          name: 'B',
          stateId: 0,
          duration: 120,
          order: 1,
          createdAt: DateTime(2026),
          editedAt: DateTime(2026),
          layers: [layer('b1', 3)],
        ),
      ],
    ));
  });

  tearDown(() => db.close());

  Future<Project> load() async => (await db.getProject(project.id))!;

  test('a deleted frame comes back with its layers under the same ids', () async {
    final frame = project.frames.firstWhere((f) => f.name == 'B');
    await db.deleteFrame(frame.id);

    // The regular save can't bring it back: it only updates existing rows.
    await db.updateProject(project);
    expect((await load()).frames.map((f) => f.name), ['A']);

    await db.upsertFrame(project.id, frame);
    final restored = (await load()).frames.firstWhere((f) => f.id == frame.id);
    expect(restored.name, 'B');
    expect(restored.duration, 120);
    expect(restored.layers.map((l) => l.layerId), frame.layers.map((l) => l.layerId));
    expect(restored.layers.single.pixels, [3, 0]);
  });

  test('a deleted layer comes back under the same id', () async {
    final frame = project.frames.firstWhere((f) => f.name == 'A');
    final removed = frame.layers.last;
    await db.deleteLayer(removed.layerId);
    expect((await load()).frames.firstWhere((f) => f.id == frame.id).layers.length, 1);

    await db.upsertLayer(project.id, frame.id, removed);
    final layers = (await load()).frames.firstWhere((f) => f.id == frame.id).layers;
    expect(layers.map((l) => l.layerId), frame.layers.map((l) => l.layerId));
    expect(layers.last.pixels, [2, 0]);
  });

  test('upserting an existing frame overwrites it instead of duplicating it', () async {
    final frame = project.frames.firstWhere((f) => f.name == 'A');
    await db.upsertFrame(project.id, frame.copyWith(name: 'A2', duration: 300));

    final frames = (await load()).frames;
    expect(frames.length, 2);
    final updated = frames.firstWhere((f) => f.id == frame.id);
    expect(updated.name, 'A2');
    expect(updated.duration, 300);
    expect(updated.layers.length, 2);
  });
}
