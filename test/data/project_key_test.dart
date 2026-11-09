import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data.dart';
import 'package:picell/data/database/project_database.dart';

Project _project({bool isExample = false, String? key}) => Project(
      id: 0,
      name: 'P',
      width: 2,
      height: 1,
      createdAt: DateTime(2026),
      editedAt: DateTime(2026),
      projectKey: key,
      isExample: isExample,
      states: const [AnimationStateModel(id: 0, name: 'Idle', frameRate: 12)],
    );

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('every stored project gets its own key, even when one is passed in', () async {
    final a = await db.insertProject(_project(key: 'copied-from-elsewhere'));
    final b = await db.insertProject(_project());
    expect(a.projectKey, isNotNull);
    expect(a.projectKey, isNot('copied-from-elsewhere'));
    expect(b.projectKey, isNot(a.projectKey));
    expect((await db.getProject(a.id))!.projectKey, a.projectKey);
  });

  test('key and example flag survive updates', () async {
    final stored = await db.insertProject(_project(isExample: true));
    await db.updateProject(stored.copyWith(name: 'Renamed'));
    final loaded = (await db.getProject(stored.id))!;
    expect(loaded.name, 'Renamed');
    expect(loaded.projectKey, stored.projectKey);
    expect(loaded.isExample, isTrue);
    expect((await db.insertProject(_project())).isExample, isFalse);
  });

  test('migration backfills a key for existing projects only', () async {
    final stored = await db.insertProject(_project());
    await db.customStatement('UPDATE projects_table SET project_key = NULL');
    await db.backfillProjectKeys();
    final first = (await db.getProject(stored.id))!.projectKey;
    expect(first, isNotNull);
    await db.backfillProjectKeys();
    expect((await db.getProject(stored.id))!.projectKey, first);
  });

  test('binary export does not carry the key or example flag', () {
    final copy = Project.fromBytes(_project(isExample: true, key: 'k').toBytes());
    expect(copy.projectKey, isNull);
    expect(copy.isExample, isFalse);
  });
}
