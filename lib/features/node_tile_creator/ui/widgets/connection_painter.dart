import 'package:flutter/material.dart';
import '../../models/node_graph_model.dart';

class ConnectionPainter extends CustomPainter {
  final List<NodeConnection> connections;
  final List<NodeData> nodes;

  ConnectionPainter({required this.connections, required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final connection in connections) {
      final inputNode = nodes.where((n) => n.id == connection.inputNodeId).firstOrNull;
      final outputNode = nodes.where((n) => n.id == connection.outputNodeId).firstOrNull;

      if (inputNode == null || outputNode == null) continue;

      final inputSocketIndex = inputNode.inputs.indexWhere((s) => s.id == connection.inputSocketId);
      final outputSocketIndex = outputNode.outputs.indexWhere((s) => s.id == connection.outputSocketId);

      if (inputSocketIndex == -1 || outputSocketIndex == -1) continue;

      // Node dimensions (must match NodeWidget)
      const double nodeWidth = 180.0;
      const double headerHeight = 36.0;
      const double previewHeight = 52.0; // 40 + 6*2 margin
      const double socketRowHeight = 20.0;
      const double socketPadding = 10.0;

      // Output socket position (Right side of source node)
      final start = Offset(
        outputNode.position.dx + nodeWidth - 5,
        outputNode.position.dy +
            headerHeight +
            previewHeight +
            socketPadding +
            (outputSocketIndex * socketRowHeight) +
            5,
      );

      // Input socket position (Left side of target node)
      final end = Offset(
        inputNode.position.dx + 5,
        inputNode.position.dy + headerHeight + previewHeight + socketPadding + (inputSocketIndex * socketRowHeight) + 5,
      );

      // Create gradient
      final gradient = LinearGradient(
        colors: [
          _getSocketColor(outputNode.outputs[outputSocketIndex].type),
          _getSocketColor(inputNode.inputs[inputSocketIndex].type),
        ],
      );

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = gradient.createShader(Rect.fromPoints(start, end));

      // Glow effect
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
        ..shader = gradient.createShader(Rect.fromPoints(start, end));

      final path = Path();
      path.moveTo(start.dx, start.dy);

      final dx = (end.dx - start.dx).abs();
      final controlOffset = dx * 0.5;

      path.cubicTo(
        start.dx + controlOffset,
        start.dy,
        end.dx - controlOffset,
        end.dy,
        end.dx,
        end.dy,
      );

      // Draw glow first
      canvas.drawPath(path, glowPaint);
      // Draw main line
      canvas.drawPath(path, paint);
    }
  }

  Color _getSocketColor(SocketType type) {
    switch (type) {
      case SocketType.color:
        return Colors.amber;
      case SocketType.float:
        return Colors.grey;
      case SocketType.image:
        return Colors.blue;
      default:
        return Colors.white;
    }
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) {
    return true;
  }
}
