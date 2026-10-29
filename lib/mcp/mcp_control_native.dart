import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/editor_workspace_provider.dart';
import '../ui/screens/editor_workspace_screen.dart';
import 'mcp_commands.dart';
import 'mcp_connection.dart';

class McpControl extends StatefulWidget {
  const McpControl({super.key, required this.child, required this.navigatorKey});
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  @override
  State<McpControl> createState() => _McpControlState();
}

class _McpControlState extends State<McpControl> {
  McpConnection? _connection;
  bool _panelOpen = false;
  bool get supported => Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  McpConnection _makeConnection() {
    final container = ProviderScope.containerOf(context, listen: false);
    return McpConnection(McpCommands(container, onOpen: (project) async {
      final open = EditorWorkspacePresence.openProject;
      if (open != null) {
        await open(project);
      } else {
        widget.navigatorKey.currentState!.push(MaterialPageRoute<void>(
          builder: (_) => EditorWorkspaceScreen(initialProject: project),
        ));
        // A background window renders no frames; don't hold the command queue.
        await WidgetsBinding.instance.endOfFrame.timeout(const Duration(milliseconds: 500), onTimeout: () {});
      }
    }));
  }

  Future<void> _showPanel() async {
    if (_panelOpen) return;
    setState(() {
      _panelOpen = true;
    });
    final connection = _connection ??= _makeConnection();
    await showDialog<void>(
      context: widget.navigatorKey.currentState!.overlay!.context,
      builder: (context) => ListenableBuilder(
        listenable: connection,
        builder: (context, _) => AlertDialog(
          title: const Text('AI connection (MCP)'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(connection.running ? 'Running on this computer' : 'Stopped'),
                const SizedBox(height: 12),
                const Text(
                  'A connected assistant can create and edit local pixel-art projects. Keep the token private.',
                ),
                if (connection.running) ...[
                  const SizedBox(height: 12),
                  const SelectableText(McpConnection.endpoint),
                  const Text('Send this header with every request:'),
                  SelectableText('Authorization: Bearer ${connection.token}'),
                  TextButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy connection details'),
                    onPressed: () => Clipboard.setData(
                      ClipboardData(text: 'URL: ${McpConnection.endpoint}\nAuthorization: Bearer ${connection.token}'),
                    ),
                  ),
                ],
                if (connection.error != null) ...[
                  const SizedBox(height: 12),
                  Text(connection.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            FilledButton(
              onPressed: connection.busy
                  ? null
                  : () async {
                      if (connection.running) {
                        if (await connection.stop() && mounted) {
                          setState(() {
                            _connection = null;
                          });
                          if (context.mounted) Navigator.pop(context);
                          connection.dispose();
                        }
                      } else {
                        await connection.start();
                        if (mounted) setState(() {});
                      }
                    },
              child: Text(
                connection.busy
                    ? 'Please wait…'
                    : connection.running
                        ? 'Stop and save'
                        : 'Start connection',
              ),
            ),
          ],
        ),
      ),
    );
    if (mounted) {
      setState(() {
        _panelOpen = false;
      });
    }
  }

  @override
  void dispose() {
    final connection = _connection;
    if (connection != null) unawaited(connection.stop().whenComplete(connection.dispose));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!supported) return widget.child;
    return Overlay.wrap(
      child: Stack(
        children: [
          widget.child,
          Positioned(
            right: 12,
            bottom: 12,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: 'mcp-connection',
                tooltip: 'AI connection (MCP)',
                onPressed: _panelOpen ? null : _showPanel,
                child: Icon(_connection?.running == true ? Icons.link : Icons.link_off),
              ),
            ),
          )
        ],
      ),
    );
  }
}
