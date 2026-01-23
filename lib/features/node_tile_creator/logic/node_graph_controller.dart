import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/node_graph_model.dart';
import '../models/nodes.dart';
import '../ui/widgets/live_preview.dart';

final nodeGraphProvider = StateNotifierProvider<NodeGraphController, NodeGraph>((ref) {
  return NodeGraphController(ref);
});

class NodeGraphController extends StateNotifier<NodeGraph> {
  final Ref _ref;
  int _previewSize = 32;

  int get previewSize => _previewSize;

  NodeGraphController(this._ref) : super(NodeGraph()) {
    // initialize with a default output node
    addNode(OutputNode(position: const Offset(500, 300)), triggerPreview: false);
  }

  void setPreviewSize(int size) {
    if (_previewSize != size) {
      _previewSize = size;
      _triggerPreviewRefresh();
    }
  }

  void _triggerPreviewRefresh() {
    _ref.read(previewTriggerProvider.notifier).state++;
  }

  void addNode(NodeData node, {bool triggerPreview = true}) {
    state = state.copyWith(nodes: [...state.nodes, node]);
    if (triggerPreview) _triggerPreviewRefresh();
  }

  void removeNode(String nodeId) {
    state = state.copyWith(
      nodes: state.nodes.where((n) => n.id != nodeId).toList(),
      connections: state.connections.where((c) => c.inputNodeId != nodeId && c.outputNodeId != nodeId).toList(),
    );
    _triggerPreviewRefresh();
  }

  void updateNodePosition(String nodeId, Offset newPosition) {
    // Just update position without triggering full state change
    final node = state.nodes.firstWhere((n) => n.id == nodeId);
    node.position = newPosition;
    // Minimal state update for UI repaint only
    state = state.copyWith(nodes: state.nodes);
  }

  void addConnection(String outputNodeId, String outputSocketId, String inputNodeId, String inputSocketId) {
    // Remove existing connection to the same input socket (one input per socket)
    final newConnections = state.connections.where((c) => c.inputSocketId != inputSocketId).toList();

    newConnections.add(NodeConnection(
      outputNodeId: outputNodeId,
      outputSocketId: outputSocketId,
      inputNodeId: inputNodeId,
      inputSocketId: inputSocketId,
    ));

    state = state.copyWith(connections: newConnections);
    _triggerPreviewRefresh();
  }

  void removeConnection(String connectionId) {
    state = state.copyWith(
      connections: state.connections.where((c) => c.id != connectionId).toList(),
    );
    _triggerPreviewRefresh();
  }

  Future<void> evaluate() async {
    try {
      final outputNode = state.nodes.firstWhere((n) => n is OutputNode);
      final context = NodeEvaluationContext(state);
      final result = await outputNode.evaluate(context);
      print('Graph Result: $result');
    } catch (e) {
      print('Evaluation Error: $e');
    }
  }

  /// Trigger state update when a node property changes
  void updateNodeProperty(String nodeId) {
    // Force state update by creating a new list
    state = state.copyWith(nodes: [...state.nodes]);
    _triggerPreviewRefresh();
  }

  /// Evaluate and return TileData for preview
  Future<TileData?> evaluateForPreview() async {
    try {
      final outputNode = state.nodes.firstWhere((n) => n is OutputNode);
      final context = NodeEvaluationContext(state, width: _previewSize, height: _previewSize);
      final result = await outputNode.evaluate(context);
      if (result is TileData) {
        return result;
      }
      return null;
    } catch (e) {
      print('Preview Evaluation Error: $e');
      return null;
    }
  }
}
