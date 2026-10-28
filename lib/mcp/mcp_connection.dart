import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mcp_server/mcp_server.dart' as mcp;

import 'mcp_commands.dart';

/// Owns one opt-in, authenticated loopback server. No network listener exists
/// until start is requested from the connection panel.
class McpConnection extends ChangeNotifier {
  McpConnection(this.commands);
  final McpCommands commands;
  mcp.Server? _server;
  mcp.ServerTransport? _transport;
  bool busy = false;
  String? token;
  String? error;
  Future<void>? _starting;
  bool get running => _server != null;
  static const port = 38475;
  static const endpoint = 'http://127.0.0.1:$port/mcp';

  Future<void> start() {
    if (_starting != null) return _starting!;
    final future = _start();
    _starting = future;
    return future.whenComplete(() {
      _starting = null;
    });
  }

  Future<void> _start() async {
    if (busy || running) return;
    busy = true;
    error = null;
    notifyListeners();
    mcp.Server? server;
    mcp.ServerTransport? transport;
    try {
      final random = Random.secure();
      final secret = base64UrlEncode(List.generate(32, (_) => random.nextInt(256)));
      server = mcp.Server(
          name: 'PixelVerse',
          version: '1.0.0',
          capabilities: const mcp.ServerCapabilities(tools: mcp.ToolsCapability()));
      for (final entry in McpCommands.tools.entries) {
        server.addTool(
            name: entry.key,
            description: entry.value,
            inputSchema: McpCommands.schema(entry.key),
            handler: (args) => commands.call(entry.key, args));
      }
      transport = await mcp.McpServer.createTransport(mcp.TransportConfig.streamableHttp(
        host: '127.0.0.1',
        port: port,
        endpoint: '/mcp',
        authToken: secret,
        isJsonResponseEnabled: true,
      )).fold((future) => future, (error) => throw error);
      server.connect(transport!);
      _server = server;
      _transport = transport;
      token = secret;
    } catch (_) {
      server?.dispose();
      transport?.close();
      error = 'Could not start MCP. Check whether port $port is already in use.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> stop() async {
    await _starting;
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await commands.close();
      _server?.dispose();
      _transport?.close();
      await _transport?.onClose;
      _server = null;
      _transport = null;
      token = null;
      return true;
    } catch (_) {
      error = 'Could not save pending changes. Retry stopping before closing the app.';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Widget teardown must release the listener even if saving failed.
    _server?.dispose();
    _transport?.close();
    _server = null;
    _transport = null;
    token = null;
    super.dispose();
  }
}
