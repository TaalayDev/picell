import 'dart:ui';
import 'package:uuid/uuid.dart';

/// Represents a connection point on a node
class NodeSocket {
  final String id;
  final String nodeId;
  final String name;
  final SocketType type;

  NodeSocket({
    required this.id,
    required this.nodeId,
    required this.name,
    required this.type,
  });
}

enum SocketType {
  color,
  float,
  vector2,
  image, // The pixel buffer
}

/// Represents a connection between two nodes
class NodeConnection {
  final String id;
  final String outputNodeId;
  final String outputSocketId;
  final String inputNodeId;
  final String inputSocketId;

  NodeConnection({
    String? id,
    required this.outputNodeId,
    required this.outputSocketId,
    required this.inputNodeId,
    required this.inputSocketId,
  }) : id = id ?? const Uuid().v4();
}

/// Abstract base class for all nodes
abstract class NodeData {
  final String id;
  String name;
  Offset position;

  List<NodeSocket> get inputs;
  List<NodeSocket> get outputs;

  NodeData({
    String? id,
    required this.name,
    this.position = const Offset(100, 100),
  }) : id = id ?? const Uuid().v4();

  /// Evaluate the node to produce a result
  /// [context] provides access to upstream values
  Future<dynamic> evaluate(NodeEvaluationContext context);
}

/// Context passed during evaluation to resolve inputs
/// Context passed during evaluation to resolve inputs
class NodeEvaluationContext {
  final NodeGraph graph;
  final int width;
  final int height;
  final Map<String, dynamic> _cache = {};

  NodeEvaluationContext(this.graph, {this.width = 32, this.height = 32});

  /// Get the value from a specific input socket of a node
  Future<dynamic> getInput(String nodeId, String socketName) async {
    // 1. Find the input socket on the node
    final node = graph.nodes.firstWhere((n) => n.id == nodeId);
    final inputSocket = node.inputs.firstWhere((s) => s.name == socketName,
        orElse: () => throw Exception('Socket $socketName not found on node $nodeId'));

    // 2. Find a connection to this socket
    final connection = graph.connections.firstWhere(
      (c) => c.inputNodeId == nodeId && c.inputSocketId == inputSocket.id,
      orElse: () => throw Exception('No connection found for ${node.name}.$socketName'),
    );

    // 3. Evaluate the output node
    // Check cache first (primitive cycle detection could be added here)
    if (_cache.containsKey(connection.outputNodeId)) {
      return _cache[connection.outputNodeId];
    }

    final outputNode = graph.nodes.firstWhere((n) => n.id == connection.outputNodeId);
    final result = await outputNode.evaluate(this);

    // Cache the result
    _cache[connection.outputNodeId] = result;

    return result;
  }
}

/// The entire graph container
class NodeGraph {
  final String id;
  final List<NodeData> nodes;
  final List<NodeConnection> connections;

  NodeGraph({
    String? id,
    this.nodes = const [],
    this.connections = const [],
  }) : id = id ?? const Uuid().v4();

  NodeGraph copyWith({
    List<NodeData>? nodes,
    List<NodeConnection>? connections,
  }) {
    return NodeGraph(
      id: id,
      nodes: nodes ?? this.nodes,
      connections: connections ?? this.connections,
    );
  }
}
