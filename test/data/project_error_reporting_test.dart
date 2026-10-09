import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/core/utils/queue_manager.dart';
import 'package:picell/data.dart';

class FailingProjectDatabase implements AppDatabase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Storage unavailable');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('project opening errors remain visible to callers', () async {
    final repo = ProjectLocalRepo(FailingProjectDatabase(), QueueManager());
    await expectLater(repo.fetchProject(1), throwsStateError);
  });

  test(
      'failed frame, layer and animation creation complete rather than hanging',
      () async {
    final queue = QueueManager();
    final repo = ProjectLocalRepo(FailingProjectDatabase(), queue);
    await expectLater(
      repo
          .createFrame(
              1,
              AnimationFrame(
                  id: 0,
                  name: 'Frame',
                  stateId: 1,
                  duration: 100,
                  layers: const []))
          .timeout(const Duration(seconds: 2)),
      throwsStateError,
    );
    await expectLater(
      repo
          .createLayer(
              1,
              1,
              Layer(
                  layerId: 0,
                  id: 'layer',
                  name: 'Layer',
                  pixels: Uint32List(1)))
          .timeout(const Duration(seconds: 2)),
      throwsStateError,
    );
    await expectLater(
      repo
          .createState(
              1,
              const AnimationStateModel(
                  id: 0, name: 'Animation', frameRate: 24))
          .timeout(const Duration(seconds: 2)),
      throwsStateError,
    );
    var continued = false;
    await queue.add(() async {
      continued = true;
    });
    expect(continued, isTrue);
  });
}
