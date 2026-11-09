import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/core/utils/copy_name.dart';
import 'package:picell/data.dart';
import 'package:picell/data/database/project_database.dart';

void main() {
  test('copyName never stacks prefixes or exceeds the limit', () {
    expect(copyName('Frame 1'), 'Copy of Frame 1');
    expect(copyName('Copy of Frame 1'), 'Copy of Frame 1');
    expect(copyName('x' * 200).length, kMaxNameLength);
  });

  test('migration collapses stacked copy names in frames and layers', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final project = await db.insertProject(Project(
      id: 0,
      name: 'P',
      width: 2,
      height: 1,
      createdAt: DateTime(2026),
      editedAt: DateTime(2026),
      states: const [AnimationStateModel(id: 0, name: 'Idle', frameRate: 12)],
      frames: const [],
    ));
    final stateId = (await db.select(db.animationStateTable).get()).first.id;
    final long = '${'Copy of ' * 12}Frame 1';
    await db.customStatement(
      'INSERT INTO frames_table (project_id, state_id, name, duration, "order", created_at, edited_at) '
      "VALUES (${project.id}, $stateId, '$long', 100, 0, 0, 0), "
      "(${project.id}, $stateId, 'Copy of Frame 1', 100, 1, 0, 0), "
      "(${project.id}, $stateId, '${'y' * 130}', 100, 2, 0, 0)",
    );

    await db.normalizeCopyNamesForMigration();

    final names = (await db.select(db.framesTable).get()).map((f) => f.name).toList();
    expect(names, ['Copy of Frame 1', 'Copy of Frame 1', 'y' * 100]);
  });
}
