import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:mcp_server/mcp_server.dart' as mcp;

import '../data/models/project_model.dart';
import '../pixel/pixel_canvas_state.dart';
import '../pixel/pixel_utils.dart';
import '../pixel/providers/pixel_controller_provider.dart';
import '../pixel/services/drawing_service.dart';
import '../pixel/services/effect_stack_service.dart';
import '../providers/editor_workspace_provider.dart';
import '../providers/projects_provider.dart';
import '../providers/providers.dart';
import 'package:flutter/painting.dart';

class McpCommandError implements Exception {
  const McpCommandError(this.code, this.message);
  final String code;
  final String message;
}

int mcpInt(Map<String, dynamic> args, String key, {int min = 0, int max = 0x7fffffff}) {
  final value = args[key];
  if (value is! int || value < min || value > max) {
    throw McpCommandError('invalid_arguments', '$key must be an integer in $min..$max');
  }
  return value;
}

String mcpString(Map<String, dynamic> args, String key, {int max = 120}) {
  final value = args[key];
  if (value is! String || value.trim().isEmpty || value.length > max) {
    throw McpCommandError('invalid_arguments', '$key must be a nonempty string, at most $max characters');
  }
  return value.trim();
}

int mcpColor(Object? value) {
  if (value is! String || !RegExp(r'^#[0-9a-fA-F]{8}$').hasMatch(value)) {
    throw const McpCommandError('invalid_arguments', 'Colors must use #AARRGGBB');
  }
  return int.parse(value.substring(1), radix: 16);
}

/// A pinned editor session shares the very same provider as an open workspace.
class _Session {
  _Session(this.project, this.subscription);
  final Project project;
  final ProviderSubscription<PixelCanvasState> subscription;
  int revision = 0;
}

class McpCommands {
  McpCommands(this.container, {required this.onOpen, this.commandTimeout = const Duration(seconds: 20)});
  final ProviderContainer container;
  final Future<void> Function(Project project) onOpen;
  final Duration commandTimeout;
  final _sessions = <int, _Session>{};
  final _created = <String, ({String signature, Project project})>{};
  Future<void> _tail = Future.value();
  int _pending = 0;
  bool _closed = false;

  static const tools = {
    'list_projects': 'List local projects with pagination.',
    'get_project': 'Inspect live project frames, layers and revision.',
    'create_project': 'Create a local pixel-art project. operationId deduplicates retries for this connection.',
    'open_project': 'Open or activate a pixel-art project in the workspace.',
    'get_preview': 'Return the live composite as a PNG image.',
    'set_pixels': 'Atomically replace explicit pixels, including transparent pixels. Ignores UI tool and selection.',
    'fill_region': 'Flood fill a layer from x,y. Ignores UI tool and selection.',
    'save_project': 'Flush pending local project changes to storage.',
    'undo': 'Undo one editor operation.',
    'redo': 'Redo one editor operation.',
  };

  static Map<String, dynamic> schema(String name) {
    const integer = {'type': 'integer', 'minimum': 0};
    const color = {'type': 'string', 'pattern': r'^#[0-9a-fA-F]{8}$'};
    final properties = <String, dynamic>{};
    final required = <String>[];
    void field(String key, Map<String, dynamic> spec, [bool mandatory = true]) {
      properties[key] = spec;
      if (mandatory) required.add(key);
    }

    if (name == 'list_projects') {
      field('offset', integer, false);
      field('limit', {'type': 'integer', 'minimum': 1, 'maximum': 100}, false);
    } else if (name == 'create_project') {
      field('name', {'type': 'string', 'minLength': 1, 'maxLength': 120});
      for (final key in ['width', 'height']) {
        field(key, {'type': 'integer', 'minimum': 1, 'maximum': 512});
      }
      field('operationId', {'type': 'string', 'minLength': 1, 'maxLength': 120});
    } else {
      field('projectId', integer);
      if (['set_pixels', 'fill_region', 'undo', 'redo'].contains(name)) {
        field('expectedRevision', integer);
      }
      if (['set_pixels', 'fill_region'].contains(name)) {
        field('frameId', integer);
        field('layerId', {'type': 'string', 'minLength': 1});
      }
      if (name == 'get_preview') field('frameId', integer, false);
      if (name == 'set_pixels') {
        field('pixels', {
          'type': 'array',
          'minItems': 1,
          'maxItems': 65536,
          'items': {
            'type': 'object',
            'additionalProperties': false,
            'properties': {'x': integer, 'y': integer, 'color': color},
            'required': ['x', 'y', 'color']
          },
        });
      }
      if (name == 'fill_region') {
        field('x', integer);
        field('y', integer);
        field('color', color);
      }
    }
    return {'type': 'object', 'properties': properties, 'required': required, 'additionalProperties': false};
  }

  Future<mcp.CallToolResult> call(String name, Map<String, dynamic> args) async {
    if (_closed || _pending >= 8) return _error('busy', 'Connection stopped or command queue full');
    _pending++;
    final previous = _tail;
    final done = Completer<void>();
    _tail = done.future;
    try {
      await previous;
      final spec = schema(name);
      if (!tools.containsKey(name) || args.keys.any((key) => !(spec['properties'] as Map).containsKey(key))) {
        throw const McpCommandError('invalid_arguments', 'Unknown tool or argument');
      }
      // Commands are serialized, so one that never finishes would block every
      // later call. Give up on it before the transport's own request timeout.
      return await _execute(name, args).timeout(commandTimeout,
          onTimeout: () => throw const McpCommandError(
              'timeout', 'The editor did not finish in time; bring PixelVerse to the front and retry'));
    } on McpCommandError catch (error) {
      return _error(error.code, error.message);
    } catch (_) {
      return _error('operation_failed', 'The editor could not complete this action');
    } finally {
      _pending--;
      done.complete();
    }
  }

  mcp.CallToolResult _error(String code, String message) => mcp.CallToolResult(
        isError: true,
        content: [
          mcp.TextContent(text: jsonEncode({'code': code, 'message': message}))
        ],
        structuredContent: {'code': code, 'message': message},
      );

  mcp.CallToolResult _result(Map<String, dynamic> data, [List<mcp.Content> extra = const []]) => mcp.CallToolResult(
        content: [mcp.TextContent(text: jsonEncode(data)), ...extra],
        structuredContent: data,
      );

  Future<_Session> _session(int id) async {
    final cached = _sessions[id];
    if (cached != null) return cached;
    if (_sessions.length >= 16) {
      throw const McpCommandError('limit_reached', 'At most 16 projects can be controlled per connection');
    }
    Project? project;
    for (final tab in container.read(editorWorkspaceProvider).tabs) {
      if (tab.projectId == id) project = tab.project;
    }
    project ??= await container.read(projectsProvider.notifier).getProject(id);
    if (project == null) throw const McpCommandError('not_found', 'Project not found');
    if (project.type != ProjectType.pixelArt) {
      throw const McpCommandError('unsupported_operation', 'MCP editing currently supports pixel-art projects');
    }
    if (project.width > 512 || project.height > 512) {
      throw const McpCommandError('unsupported_operation', 'MCP canvases are limited to 512×512');
    }
    final provider = pixelDrawControllerProvider(project);
    late _Session session;
    final subscription = container.listen(provider, (_, __) {
      session.revision++;
    });
    session = _Session(project, subscription);
    _sessions[id] = session;
    container.read(editorWorkspaceProvider.notifier).pinAutomationProject(project);
    return session;
  }

  PixelCanvasState _state(_Session s) => container.read(pixelDrawControllerProvider(s.project));
  PixelDrawController _controller(_Session s) => container.read(pixelDrawControllerProvider(s.project).notifier);

  Map<String, dynamic> _describe(_Session s) {
    final state = _state(s);
    return {
      'projectId': s.project.id,
      'name': s.project.name,
      'width': state.width,
      'height': state.height,
      'revision': s.revision,
      'canUndo': state.canUndo,
      'canRedo': state.canRedo,
      'frames': [
        for (final frame in state.frames)
          {
            'frameId': frame.id,
            'name': frame.name,
            'duration': frame.duration,
            'layers': [
              for (final layer in frame.layers)
                {
                  'layerId': layer.id,
                  'name': layer.name,
                  'locked': layer.isLocked,
                  'visible': layer.isVisible,
                  'opacity': layer.opacity,
                }
            ],
          }
      ],
    };
  }

  Future<mcp.CallToolResult> _execute(String name, Map<String, dynamic> args) async {
    if (name == 'list_projects') {
      final offset = args.containsKey('offset') ? mcpInt(args, 'offset') : 0;
      final limit = args.containsKey('limit') ? mcpInt(args, 'limit', min: 1, max: 100) : 50;
      final projects = await container.read(projectRepo).fetchProjects().first;
      return _result({
        'projects': [
          for (final p in projects.skip(offset).take(limit))
            {
              'projectId': p.id,
              'name': p.name,
              'width': p.width,
              'height': p.height,
              'type': p.type.name,
            }
        ],
        'total': projects.length
      });
    }
    if (name == 'create_project') {
      final title = mcpString(args, 'name');
      final width = mcpInt(args, 'width', min: 1, max: 512);
      final height = mcpInt(args, 'height', min: 1, max: 512);
      final operationId = mcpString(args, 'operationId');
      final signature = jsonEncode([title, width, height]);
      final existing = _created[operationId];
      if (existing != null && existing.signature != signature) {
        throw const McpCommandError('operation_conflict', 'operationId already used with different arguments');
      }
      if (existing == null && _created.length >= 256) {
        throw const McpCommandError('limit_reached', 'Creation limit reached; restart the connection');
      }
      if (existing == null && _sessions.length >= 16) {
        throw const McpCommandError('limit_reached', 'Stop and restart the connection before creating more projects');
      }
      final now = DateTime.now();
      final project = existing?.project ??
          await container.read(projectsProvider.notifier).addProject(
                Project(id: 0, name: title, width: width, height: height, createdAt: now, editedAt: now),
                source: 'mcp',
              );
      _created[operationId] = (signature: signature, project: project);
      return _result(_describe(await _session(project.id)));
    }
    final session = await _session(mcpInt(args, 'projectId'));
    final controller = _controller(session);
    if (name == 'get_project') return _result(_describe(session));
    if (name == 'open_project') {
      await onOpen(session.project);
      if (container.read(editorWorkspaceProvider).activeProjectId != session.project.id) {
        throw const McpCommandError(
            'editor_busy', 'The workspace could not activate the project; retry when it is idle');
      }
      return _result(_describe(session));
    }
    if (name == 'save_project') {
      if (!await controller.flushPendingProjectSave()) {
        throw const McpCommandError('save_failed', 'Local persistence failed; changes remain in the editor');
      }
      return _result({..._describe(session), 'saved': !controller.hasPendingProjectSave});
    }
    if (name == 'get_preview') {
      final state = _state(session);
      final frameId = args.containsKey('frameId') ? mcpInt(args, 'frameId') : state.currentFrame.id;
      final frames = state.frames.where((frame) => frame.id == frameId);
      if (frames.isEmpty) throw const McpCommandError('not_found', 'Frame not found');
      final pixels =
          PixelUtils.mergeLayersPixels(width: state.width, height: state.height, layers: frames.first.layers);
      final image = img.Image(width: state.width, height: state.height, numChannels: 4);
      for (var i = 0; i < pixels.length; i++) {
        final c = pixels[i];
        image.setPixelRgba(i % state.width, i ~/ state.width, (c >> 16) & 255, (c >> 8) & 255, c & 255, c >> 24);
      }
      return _result({'projectId': session.project.id, 'frameId': frameId, 'revision': session.revision},
          [mcp.ImageContent(data: base64Encode(img.encodePng(image)), mimeType: 'image/png')]);
    }
    if (mcpInt(args, 'expectedRevision') != session.revision) {
      throw const McpCommandError('stale_revision', 'Read get_project again before editing');
    }
    if (controller.automationBusy || _state(session).selectionState != null) {
      throw const McpCommandError('editor_busy', 'Finish the current gesture and clear the selection before editing');
    }
    if (name == 'undo' || name == 'redo') {
      if (name == 'undo') {
        controller.undo();
      } else {
        controller.redo();
      }
      return _result(_describe(session));
    }
    final state = _state(session);
    final frameId = mcpInt(args, 'frameId');
    final layerId = mcpString(args, 'layerId');
    final frames = state.frames.where((frame) => frame.id == frameId);
    if (frames.isEmpty) throw const McpCommandError('not_found', 'Frame not found');
    final frame = frames.first;
    final layerIndex = frame.layers.indexWhere((layer) => layer.id == layerId);
    if (layerIndex < 0) throw const McpCommandError('not_found', 'Layer not found');
    final layer = frame.layers[layerIndex];
    if (layer.isLocked) throw const McpCommandError('locked_layer', 'Layer is locked');
    if (EffectStackService.isProcedural(layer)) {
      throw const McpCommandError('unsupported_operation', 'Cannot paint a procedural layer');
    }
    final pixels = Uint32List.fromList(layer.pixels);
    if (name == 'set_pixels') {
      final patch = args['pixels'];
      if (patch is! List || patch.isEmpty || patch.length > 65536) {
        throw const McpCommandError('invalid_arguments', 'pixels must contain 1..65536 entries');
      }
      for (final entry in patch) {
        if (entry is! Map<String, dynamic> || entry.keys.any((key) => !['x', 'y', 'color'].contains(key))) {
          throw const McpCommandError('invalid_arguments', 'Each pixel needs x, y, color');
        }
        final x = mcpInt(entry, 'x', max: state.width - 1);
        final y = mcpInt(entry, 'y', max: state.height - 1);
        pixels[y * state.width + x] = mcpColor(entry['color']);
      }
    } else {
      final x = mcpInt(args, 'x', max: state.width - 1);
      final y = mcpInt(args, 'y', max: state.height - 1);
      final filled = DrawingService().floodFill(
          pixels: pixels,
          x: x,
          y: y,
          width: state.width,
          height: state.height,
          fillColor: Color(mcpColor(args['color'])));
      pixels.setAll(0, filled);
    }
    controller.selectAnimationState(frame.stateId);
    controller.selectFrame(frameId);
    controller.selectLayer(layerIndex);
    controller.applyAutomationPixels(pixels);
    return _result({..._describe(session), 'saved': false});
  }

  Future<void> close() async {
    _closed = true;
    await _tail;
    for (final session in _sessions.values) {
      if (!await _controller(session).flushPendingProjectSave()) {
        throw const McpCommandError('save_failed', 'Could not save; keep the connection open and retry');
      }
      if (_controller(session).hasPendingProjectSave) {
        throw const McpCommandError(
            'editor_busy', 'New edits arrived while saving; retry stopping when the editor is idle');
      }
    }
    for (final session in _sessions.values) {
      container.read(editorWorkspaceProvider.notifier).unpinAutomationProject(session.project.id);
      session.subscription.close();
    }
    _sessions.clear();
  }
}
