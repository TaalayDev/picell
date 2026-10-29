import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:mcp_server/mcp_server.dart';
import 'package:picell/data.dart';
import 'package:picell/data/repo/template_api_repo.dart';
import 'package:picell/mcp/mcp_commands.dart';
import 'package:picell/mcp/mcp_connection.dart';
import 'package:picell/pixel/providers/pixel_controller_provider.dart';
import 'package:picell/pixel/tools.dart';
import 'package:picell/providers/editor_workspace_provider.dart';
import 'package:picell/providers/projects_provider.dart';
import 'package:picell/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RealHttpOverrides extends HttpOverrides {}

class MemoryRepo implements ProjectRepo {
  final projects = <int, Project>{};
  bool failSave = false;
  Completer<void>? saveGate;
  @override
  Stream<List<Project>> fetchProjects() => Stream.value(projects.values.toList());
  @override
  Future<Project?> fetchProject(int id) async => projects[id];
  @override
  Future<void> updateProject(Project project) async {
    await saveGate?.future;
    if (failSave) throw StateError('disk failure');
    projects[project.id] = project;
  }

  @override
  Future<void> updateLayer(int projectId, int frameId, Layer layer) async {}
  @override
  Future<void> updateProjectSelection(int projectId, {required int frameId, required int layerId}) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class Templates implements TemplateAPIRepo {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestProjects extends Projects {
  TestProjects(this.repo);
  final MemoryRepo repo;
  @override
  Stream<List<Project>> build() => repo.fetchProjects();
  @override
  Future<Project?> getProject(int id) => repo.fetchProject(id);
  @override
  Future<Project> addProject(Project incoming, {String source = 'blank'}) async {
    final id = repo.projects.length + 1;
    final p = incoming.copyWith(id: id, states: [
      const AnimationStateModel(id: 1, name: 'Animation', frameRate: 24)
    ], frames: [
      AnimationFrame(id: 1, stateId: 1, name: 'Frame 1', duration: 100, layers: [
        Layer(layerId: 1, id: 'layer-$id', name: 'Layer 1', pixels: Uint32List(incoming.width * incoming.height))
      ])
    ]);
    repo.projects[id] = p;
    return p;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryRepo repo;
  late ProviderContainer container;
  late McpCommands commands;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    repo = MemoryRepo();
    container = ProviderContainer(overrides: [
      projectRepo.overrideWithValue(repo),
      templateAPIRepoProvider.overrideWithValue(Templates()),
      projectsProvider.overrideWith(() => TestProjects(repo)),
    ]);
    commands =
        McpCommands(container, onOpen: (p) async => container.read(editorWorkspaceProvider.notifier).openProject(p));
  });
  tearDown(() async {
    repo.failSave = false;
    await commands.close();
    container.dispose();
  });

  Future<Map<String, dynamic>> create() async =>
      (await commands.call('create_project', {'name': 'Sprite', 'width': 2, 'height': 2, 'operationId': 'create-1'}))
          .structuredContent!;
  Map<String, dynamic> target(Map<String, dynamic> p) => {
        'projectId': p['projectId'],
        'frameId': 1,
        'layerId': 'layer-${p['projectId']}',
        'expectedRevision': p['revision'],
      };

  test('create deduplicates retries and rejects reused IDs with different arguments', () async {
    final first = await create();
    expect((await create())['projectId'], first['projectId']);
    expect(repo.projects.length, 1);
    final conflict =
        await commands.call('create_project', {'name': 'Other', 'width': 2, 'height': 2, 'operationId': 'create-1'});
    expect(conflict.structuredContent!['code'], 'operation_conflict');
  });

  test('explicit patch ignores eraser, is atomic, undoable, previewed and persisted', () async {
    var p = await create();
    final project = repo.projects[1]!;
    final controller = container.read(pixelDrawControllerProvider(project).notifier);
    controller.setCurrentTool(PixelTool.eraser);
    p = (await commands.call('get_project', {'projectId': 1})).structuredContent!;
    final invalid = await commands.call('set_pixels', {
      ...target(p),
      'pixels': [
        {'x': 0, 'y': 0, 'color': '#FFFF0000'},
        {'x': 10, 'y': 0, 'color': '#FF00FF00'},
      ]
    });
    expect(invalid.isError, true);
    expect(controller.currentLayer.pixels, [0, 0, 0, 0]);
    expect(controller.canUndo, false);
    final patched = await commands.call('set_pixels', {
      ...target(p),
      'pixels': [
        {'x': 0, 'y': 0, 'color': '#FFFF0000'},
        {'x': 1, 'y': 1, 'color': '#FF00FF00'},
      ]
    });
    expect(patched.isError, isNot(true), reason: '${patched.structuredContent}');
    p = patched.structuredContent!;
    expect(controller.currentLayer.pixels, [0xffff0000, 0, 0, 0xff00ff00]);
    expect(controller.undoStackSize, 1);
    final preview = await commands.call('get_preview', {'projectId': 1});
    final png = img.decodePng(base64Decode((preview.content.last as ImageContent).data!))!;
    expect(png.getPixel(0, 0).r, 255);
    expect(png.getPixel(1, 1).g, 255);
    p = (await commands.call('undo', {'projectId': 1, 'expectedRevision': p['revision']})).structuredContent!;
    expect(controller.currentLayer.pixels, [0, 0, 0, 0]);
    p = (await commands.call('redo', {'projectId': 1, 'expectedRevision': p['revision']})).structuredContent!;
    expect(controller.currentLayer.pixels.first, 0xffff0000);
    expect((await commands.call('save_project', {'projectId': 1})).structuredContent!['saved'], true);
    expect(repo.projects[1]!.frames.first.layers.first.pixels.first, 0xffff0000);
  });

  test('stale UI revisions, locked layers and active drawing reject writes', () async {
    var p = await create();
    final controller = container.read(pixelDrawControllerProvider(repo.projects[1]!).notifier);
    controller.setCurrentTool(PixelTool.eraser);
    var result = await commands.call('fill_region', {...target(p), 'x': 0, 'y': 0, 'color': '#FF112233'});
    expect(result.structuredContent!['code'], 'stale_revision');
    controller.updateLayer(controller.currentLayer.copyWith(isLocked: true));
    p = (await commands.call('get_project', {'projectId': 1})).structuredContent!;
    result = await commands.call('fill_region', {...target(p), 'x': 0, 'y': 0, 'color': '#FF112233'});
    expect(result.structuredContent!['code'], 'locked_layer');
    controller.updateLayer(controller.currentLayer.copyWith(isLocked: false));
    controller.startBatchDrawing();
    p = (await commands.call('get_project', {'projectId': 1})).structuredContent!;
    result = await commands.call('fill_region', {...target(p), 'x': 0, 'y': 0, 'color': '#FF112233'});
    expect(result.structuredContent!['code'], 'editor_busy');
    controller.cancelBatchDrawing();
  });

  test('apply_gradient paints exact colors, validates and undoes', () async {
    var p = await create();
    final controller = container.read(pixelDrawControllerProvider(repo.projects[1]!).notifier);
    final bad = await commands.call('apply_gradient', {
      ...target(p),
      'startX': 0,
      'startY': 1,
      'endX': 2,
      'endY': 1,
      'colors': ['#FF000000', 'red'],
    });
    expect(bad.structuredContent!['code'], 'invalid_arguments');
    final badType = await commands.call('apply_gradient', {
      ...target(p),
      'startX': 0,
      'startY': 1,
      'endX': 2,
      'endY': 1,
      'colors': ['#FF000000'],
      'type': 'spiral',
    });
    expect(badType.structuredContent!['code'], 'invalid_arguments');
    expect(controller.currentLayer.pixels, [0, 0, 0, 0]);

    final ok = await commands.call('apply_gradient', {
      ...target(p),
      'startX': 0,
      'startY': 1,
      'endX': 2,
      'endY': 1,
      'colors': ['#FF000000', '#FFFFFFFF'],
    });
    expect(ok.isError, isNot(true), reason: '${ok.structuredContent}');
    p = ok.structuredContent!;
    expect(controller.currentLayer.pixels, [0xff000000, 0xffffffff, 0xff000000, 0xffffffff]);
    p = (await commands.call('undo', {'projectId': 1, 'expectedRevision': p['revision']})).structuredContent!;
    expect(controller.currentLayer.pixels, [0, 0, 0, 0]);
  });

  test('apply_gradient contiguous target and smooth steps', () async {
    var p = await create();
    p = (await commands.call('set_pixels', {
      ...target(p),
      'pixels': [
        {'x': 1, 'y': 0, 'color': '#FF00FF00'},
        {'x': 1, 'y': 1, 'color': '#FF00FF00'},
      ]
    }))
        .structuredContent!;
    final controller = container.read(pixelDrawControllerProvider(repo.projects[1]!).notifier);
    final ok = await commands.call('apply_gradient', {
      ...target(p),
      'startX': 0.5,
      'startY': 0.5,
      'endX': 0.5,
      'endY': 2,
      'colors': ['#FFFF0000', '#FF0000FF'],
      'steps': 0,
      'target': 'contiguous',
    });
    expect(ok.isError, isNot(true), reason: '${ok.structuredContent}');
    final px = controller.currentLayer.pixels;
    expect(px[1], 0xff00ff00, reason: 'other colour area untouched');
    expect(px[3], 0xff00ff00);
    expect(px[0], 0xffff0000);
    expect(px[2] & 0xff, greaterThan(0), reason: 'smooth blend towards blue');
  });

  test('save failure is reported and can be retried', () async {
    final p = await create();
    await commands.call('fill_region', {...target(p), 'x': 0, 'y': 0, 'color': '#FF112233'});
    repo.failSave = true;
    final saved = await commands.call('save_project', {'projectId': 1});
    expect(saved.structuredContent!['code'], 'save_failed');
    repo.failSave = false;
    // A failed flush must retain a snapshot for the retry.
    expect((await commands.call('save_project', {'projectId': 1})).structuredContent!['saved'], true);
    expect(repo.projects[1]!.frames.first.layers.first.pixels.first, 0xff112233);
  });

  test('save reports newer UI edits as pending while a write is in flight', () async {
    final p = await create();
    await commands.call('set_pixels', {
      ...target(p),
      'pixels': [
        {'x': 0, 'y': 0, 'color': '#FF112233'},
      ]
    });
    repo.saveGate = Completer<void>();
    final saving = commands.call('save_project', {'projectId': 1});
    await Future<void>.delayed(Duration.zero);
    final controller = container.read(pixelDrawControllerProvider(repo.projects[1]!).notifier);
    controller.applyAutomationPixels(Uint32List.fromList([0xff445566, 0, 0, 0]));
    repo.saveGate!.complete();
    expect((await saving).structuredContent!['saved'], false);
    repo.saveGate = null;
    expect((await commands.call('save_project', {'projectId': 1})).structuredContent!['saved'], true);
    expect(repo.projects[1]!.frames.first.layers.first.pixels.first, 0xff445566);
  });

  test('reopening uses the pinned editor and reconnect reads saved pixels', () async {
    var p = await create();
    await commands.call('open_project', {'projectId': 1});
    p = (await commands.call('set_pixels', {
      ...target(p),
      'pixels': [
        {'x': 0, 'y': 0, 'color': '#FF112233'},
      ]
    }))
        .structuredContent!;
    final original = container.read(editorWorkspaceProvider).tabs.single.project;
    container.read(editorWorkspaceProvider.notifier).clear();
    // Simulate a separately loaded database snapshot being opened through UI.
    container.read(editorWorkspaceProvider.notifier).startWorkspace(original.copyWith(name: 'Reloaded snapshot'));
    expect(identical(container.read(editorWorkspaceProvider).tabs.single.project, original), true);
    await commands.close();
    container.read(editorWorkspaceProvider.notifier).clear();
    commands =
        McpCommands(container, onOpen: (p) async => container.read(editorWorkspaceProvider.notifier).openProject(p));
    final preview = await commands.call('get_preview', {'projectId': 1});
    final png = img.decodePng(base64Decode((preview.content.last as ImageContent).data!))!;
    expect(png.getPixel(0, 0).r, 0x11);
    expect(png.getPixel(0, 0).g, 0x22);
    expect(png.getPixel(0, 0).b, 0x33);
  });

  test('a command that never finishes times out and releases the queue', () async {
    await create();
    await commands.close();
    final hang = Completer<void>();
    commands = McpCommands(container, onOpen: (_) => hang.future, commandTimeout: const Duration(milliseconds: 50));
    final stuck = await commands.call('open_project', {'projectId': 1});
    expect(stuck.structuredContent!['code'], 'timeout');
    final next = await commands.call('get_project', {'projectId': 1});
    expect(next.isError, isNot(true));
    hang.complete();
  });

  test('real HTTP transport requires token and supports tool discovery', () async {
    final connection = McpConnection(commands);
    await connection.start();
    expect(connection.running, true, reason: connection.error);
    final client = HttpOverrides.runWithHttpOverrides(() => HttpClient(), RealHttpOverrides());
    Future<({int status, String body, String? session})> request(Map<String, dynamic> body,
        {bool auth = true, String? session}) async {
      final req = await client.postUrl(Uri.parse(McpConnection.endpoint));
      req.headers.contentType = ContentType.json;
      req.headers.set('Accept', 'application/json, text/event-stream');
      if (auth) req.headers.set('Authorization', 'Bearer ${connection.token}');
      if (session != null) req.headers.set('mcp-session-id', session);
      req.write(jsonEncode(body));
      final response = await req.close();
      return (
        status: response.statusCode,
        body: await utf8.decoder.bind(response).join(),
        session: response.headers.value('mcp-session-id')
      );
    }

    try {
      expect(
          (await request({'jsonrpc': '2.0', 'id': 1, 'method': 'initialize', 'params': {}}, auth: false)).status, 401);
      final init = await request({
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'initialize',
        'params': {
          'protocolVersion': '2025-11-25',
          'capabilities': {},
          'clientInfo': {'name': 'test', 'version': '1'},
        }
      });
      expect(init.status, 200, reason: init.body);
      final listing =
          await request({'jsonrpc': '2.0', 'id': 3, 'method': 'tools/list', 'params': {}}, session: init.session);
      expect(listing.status, 200, reason: listing.body);
      expect(listing.body, contains('create_project'));
      expect(listing.body, contains('set_pixels'));
      final created = await request({
        'jsonrpc': '2.0',
        'id': 4,
        'method': 'tools/call',
        'params': {
          'name': 'create_project',
          'arguments': {'name': 'HTTP sprite', 'width': 2, 'height': 2, 'operationId': 'http-create'},
        }
      }, session: init.session);
      expect(created.status, 200, reason: created.body);
      expect(created.body, contains('HTTP sprite'));
      expect(repo.projects.length, 1);
    } finally {
      client.close(force: true);
      expect(await connection.stop(), true);
      connection.dispose();
    }
  });
}
