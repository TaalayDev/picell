import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data.dart';
import 'package:picell/data/database/project_database.dart';

void main() {
  test('the bundled Friendly Robot loads and is stored as a free example', () async {
    final bytes = File('assets/data/FriendlyRobot.pxv').readAsBytesSync();
    final loaded = Project.fromBytes(bytes);
    expect(loaded.frames, isNotEmpty);
    expect(loaded.isExample, isFalse);
    expect(loaded.projectKey, isNull);

    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final now = DateTime.now();
    final stored = await db.insertProject(loaded.copyWith(id: 0, createdAt: now, editedAt: now, isExample: true));
    final reopened = (await db.getProject(stored.id))!;
    expect(reopened.isExample, isTrue);
    expect(reopened.projectKey, isNotNull);
    expect(reopened.frames.length, loaded.frames.length);
    expect(reopened.name, loaded.name);
  });
}
