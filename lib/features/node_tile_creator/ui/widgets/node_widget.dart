import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/node_graph_controller.dart';
import '../../models/node_graph_model.dart';
import '../../models/nodes.dart';

class NodeWidget extends ConsumerWidget {
  final NodeData node;
  final bool isSelected;

  const NodeWidget({
    super.key,
    required this.node,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodeColor = _getNodeColor();

    return GestureDetector(
      onPanUpdate: (details) {
        ref.read(nodeGraphProvider.notifier).updateNodePosition(
              node.id,
              node.position + details.delta,
            );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 180,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2d2d44),
              Color(0xFF1e1e2e),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? nodeColor : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? nodeColor.withOpacity(0.3) : Colors.black.withOpacity(0.4),
              blurRadius: isSelected ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    nodeColor.withOpacity(0.3),
                    nodeColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: nodeColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(_getNodeIcon(), size: 14, color: nodeColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      node.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (node is! OutputNode)
                    GestureDetector(
                      onTap: () {
                        ref.read(nodeGraphProvider.notifier).removeNode(node.id);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Visual Preview
            _buildPreview(),

            // Sockets
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Inputs
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: node.inputs.map((socket) => _buildSocket(socket, isInput: true)).toList(),
                  ),
                  // Outputs
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: node.outputs.map((socket) => _buildSocket(socket, isInput: false)).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (node is ColorNode) {
      final colorNode = node as ColorNode;
      return Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorNode.color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: colorNode.color.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: -2,
            ),
          ],
        ),
      );
    } else if (node is NoiseNode) {
      final noiseNode = node as NoiseNode;
      return Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: CustomPaint(
            size: const Size(double.infinity, 40),
            painter: _NoisePreviewPainter(scale: noiseNode.scale, seed: noiseNode.seed),
          ),
        ),
      );
    } else if (node is ShapeNode) {
      final shapeNode = node as ShapeNode;
      return Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Center(
          child: Icon(
            _getShapeIcon(shapeNode.shapeType),
            color: Colors.green.withOpacity(0.7),
            size: 24,
          ),
        ),
      );
    } else if (node is OutputNode) {
      return Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.2),
              Colors.purple.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: const Center(
          child: Text(
            'TILE OUTPUT',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSocket(NodeSocket socket, {required bool isInput}) {
    Color color;
    switch (socket.type) {
      case SocketType.color:
        color = Colors.amber;
        break;
      case SocketType.float:
        color = Colors.grey;
        break;
      case SocketType.image:
        color = Colors.blue;
        break;
      default:
        color = Colors.white;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isInput) ...[
            _SocketCircle(color: color, isInput: true, socket: socket),
            const SizedBox(width: 6),
            Text(
              socket.name,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
            ),
          ] else ...[
            Text(
              socket.name,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11),
            ),
            const SizedBox(width: 6),
            _SocketCircle(color: color, isInput: false, socket: socket),
          ],
        ],
      ),
    );
  }

  IconData _getShapeIcon(ShapeType type) {
    switch (type) {
      case ShapeType.circle:
        return Icons.circle;
      case ShapeType.square:
        return Icons.square;
      case ShapeType.diamond:
        return Icons.diamond;
    }
  }

  Color _getNodeColor() {
    if (node is ColorNode) return Colors.amber;
    if (node is NoiseNode) return Colors.purple;
    if (node is ShapeNode) return Colors.green;
    if (node is MixNode) return Colors.cyan;
    if (node is OutputNode) return Colors.blue;
    return Colors.grey;
  }

  IconData _getNodeIcon() {
    if (node is ColorNode) return Icons.palette;
    if (node is NoiseNode) return Icons.grain;
    if (node is ShapeNode) return Icons.crop_square;
    if (node is MixNode) return Icons.merge_type;
    if (node is OutputNode) return Icons.output;
    return Icons.widgets;
  }
}

class _SocketCircle extends ConsumerWidget {
  final Color color;
  final bool isInput;
  final NodeSocket socket;

  const _SocketCircle({required this.color, required this.isInput, required this.socket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<NodeSocket>(
      onWillAcceptWithDetails: (details) {
        final incoming = details.data;
        return incoming.nodeId != socket.nodeId && incoming.type == socket.type;
      },
      onAcceptWithDetails: (details) {
        final incoming = details.data;
        if (isInput) {
          ref.read(nodeGraphProvider.notifier).addConnection(
                incoming.nodeId,
                incoming.id,
                socket.nodeId,
                socket.id,
              );
        } else {
          ref.read(nodeGraphProvider.notifier).addConnection(
                socket.nodeId,
                socket.id,
                incoming.nodeId,
                incoming.id,
              );
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Draggable<NodeSocket>(
          data: socket,
          feedback: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: isHovering ? 14 : 10,
            height: isHovering ? 14 : 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isHovering ? Colors.white : color.withOpacity(0.5),
                width: isHovering ? 2 : 1,
              ),
              boxShadow: isHovering ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)] : null,
            ),
          ),
        );
      },
    );
  }
}

class _NoisePreviewPainter extends CustomPainter {
  final double scale;
  final double seed;

  _NoisePreviewPainter({required this.scale, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final pixelSize = 4.0;

    for (double x = 0; x < size.width; x += pixelSize) {
      for (double y = 0; y < size.height; y += pixelSize) {
        final noise = _pseudoNoise(x * scale + seed, y * scale + seed);
        final gray = (noise * 255).toInt();
        paint.color = Color.fromARGB(255, gray, gray ~/ 2 + 128, gray);
        canvas.drawRect(
          Rect.fromLTWH(x, y, pixelSize, pixelSize),
          paint,
        );
      }
    }
  }

  double _pseudoNoise(double x, double y) {
    final n = (x * 12.9898 + y * 78.233).toInt();
    final h = ((n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff);
    return (h % 256) / 255.0;
  }

  @override
  bool shouldRepaint(covariant _NoisePreviewPainter oldDelegate) {
    return oldDelegate.scale != scale || oldDelegate.seed != seed;
  }
}
