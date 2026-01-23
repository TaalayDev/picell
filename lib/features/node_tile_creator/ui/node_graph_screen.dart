import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../app/theme/theme.dart';
import '../../../ui/widgets/animated_background.dart';
import '../../../ui/widgets/theme_selector.dart';
import '../logic/node_graph_controller.dart';
import '../models/node_graph_model.dart';
import '../models/nodes.dart';

import 'widgets/connection_painter.dart';
import 'widgets/node_widget.dart';
import 'widgets/properties_panel.dart';
import 'widgets/live_preview.dart';

// Provider to track the currently selected node for properties editing
final selectedNodeProvider = StateProvider<String?>((ref) => null);

class NodeGraphScreen extends HookConsumerWidget {
  const NodeGraphScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graph = ref.watch(nodeGraphProvider);
    final controller = ref.read(nodeGraphProvider.notifier);
    final selectedNodeId = ref.watch(selectedNodeProvider);
    final theme = ref.watch(themeProvider).theme;

    // Transform for zoom and pan
    final transformationController = useTransformationController();

    return AnimatedBackground(
      enableAnimation: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            // Left Panel - Node Palette
            _buildNodePalette(context, controller, theme),

            // Main Canvas Area
            Expanded(
              child: Column(
                children: [
                  // Top Toolbar
                  _buildToolbar(context, controller, theme),

                  // Canvas with nodes
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.divider.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: InteractiveViewer(
                          transformationController: transformationController,
                          boundaryMargin: const EdgeInsets.all(double.infinity),
                          minScale: 0.1,
                          maxScale: 3.0,
                          child: SizedBox(
                            width: 3000,
                            height: 3000,
                            child: Stack(
                              children: [
                                // Grid background
                                CustomPaint(
                                  size: const Size(3000, 3000),
                                  painter: _GridPainter(
                                    gridColor: theme.gridLine,
                                    backgroundColor: theme.canvasBackground,
                                  ),
                                ),

                                // Connections
                                CustomPaint(
                                  size: const Size(3000, 3000),
                                  painter: ConnectionPainter(
                                    connections: graph.connections,
                                    nodes: graph.nodes,
                                  ),
                                ),

                                // Nodes
                                ...graph.nodes.map((node) {
                                  final isSelected = selectedNodeId == node.id;
                                  return Positioned(
                                    left: node.position.dx,
                                    top: node.position.dy,
                                    child: GestureDetector(
                                      onTap: () {
                                        ref.read(selectedNodeProvider.notifier).state = node.id;
                                      },
                                      child: NodeWidget(
                                        node: node,
                                        isSelected: isSelected,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Right Panel - Properties + Preview
            _buildRightPanel(context, ref, graph, selectedNodeId, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildNodePalette(BuildContext context, NodeGraphController controller, AppTheme theme) {
    final nodeTypes = [
      _NodeTypeInfo('Color', Icons.palette, theme.accentColor, () => ColorNode()),
      _NodeTypeInfo('Noise', Icons.grain, theme.primaryColor, () => NoiseNode()),
      _NodeTypeInfo('Shape', Icons.crop_square, theme.success, () => ShapeNode()),
      _NodeTypeInfo('Mix', Icons.merge_type, theme.warning, () => MixNode()),
    ];

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.surface.withOpacity(0.95),
                theme.surface.withOpacity(0.85),
              ],
            ),
            border: Border(
              right: BorderSide(color: theme.divider.withOpacity(0.5)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withOpacity(0.15),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor.withOpacity(0.3),
                            theme.accentColor.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: Icon(Icons.widgets_outlined, color: theme.primaryColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Node Palette',
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Drag to canvas',
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: theme.divider.withOpacity(0.3)),

              // Node type list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: nodeTypes.length,
                  itemBuilder: (context, index) {
                    final nodeType = nodeTypes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildNodeTypeCard(context, nodeType, controller, theme),
                    );
                  },
                ),
              ),

              // Output node info
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withOpacity(0.08),
                      theme.accentColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.divider.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.output, color: theme.primaryColor, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Output node is always present',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNodeTypeCard(
    BuildContext context,
    _NodeTypeInfo nodeType,
    NodeGraphController controller,
    AppTheme theme,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          controller.addNode(nodeType.createNode());
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                nodeType.color.withOpacity(0.12),
                nodeType.color.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: nodeType.color.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: nodeType.color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      nodeType.color.withOpacity(0.25),
                      nodeType.color.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: nodeType.color.withOpacity(0.15),
                      blurRadius: 6,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: Icon(nodeType.icon, color: nodeType.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nodeType.name,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      'Click to add',
                      style: TextStyle(
                        color: theme.textDisabled,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: nodeType.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.add, color: nodeType.color, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, NodeGraphController controller, AppTheme theme) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.toolbarColor.withOpacity(0.9),
                theme.surface.withOpacity(0.85),
              ],
            ),
            border: Border(
              bottom: BorderSide(color: theme.divider.withOpacity(0.3)),
            ),
          ),
          child: Row(
            children: [
              // Back button
              Container(
                decoration: BoxDecoration(
                  color: theme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  color: theme.textSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back',
                ),
              ),
              const SizedBox(width: 16),

              // Title with accent
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withOpacity(0.1),
                      theme.accentColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hub_outlined, color: theme.primaryColor, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Node Tile Creator',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Zoom controls hint
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.surfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.divider.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mouse_outlined, size: 14, color: theme.textDisabled),
                    const SizedBox(width: 8),
                    Text(
                      'Scroll to zoom • Drag to pan',
                      style: TextStyle(
                        color: theme.textDisabled,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Evaluate button with glow
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: theme.success.withOpacity(0.3),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                  ],
                ),
                child: FilledButton.icon(
                  onPressed: () {
                    controller.evaluate();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: theme.success, size: 18),
                            const SizedBox(width: 8),
                            const Text('Graph evaluated! Check preview.'),
                          ],
                        ),
                        backgroundColor: theme.surface,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Run', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanel(
    BuildContext context,
    WidgetRef ref,
    NodeGraph graph,
    String? selectedNodeId,
    AppTheme theme,
  ) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.surface.withOpacity(0.95),
                theme.surface.withOpacity(0.85),
              ],
            ),
            border: Border(
              left: BorderSide(color: theme.divider.withOpacity(0.5)),
            ),
          ),
          child: Column(
            children: [
              // Live Preview Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.accentColor.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.preview_outlined, color: theme.accentColor, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Live Preview',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.success,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: theme.success.withOpacity(0.5),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: theme.success,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Live Preview Widget
              Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.canvasBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.divider.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(11)),
                  child: LivePreviewWidget(),
                ),
              ),

              const SizedBox(height: 12),
              Divider(height: 1, color: theme.divider.withOpacity(0.3)),

              // Properties Panel Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.tune, color: theme.primaryColor, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Properties',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    if (selectedNodeId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Node Selected',
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Properties Panel (when node selected)
              Expanded(
                child: selectedNodeId != null
                    ? PropertiesPanel(
                        node: graph.nodes.firstWhere(
                          (n) => n.id == selectedNodeId,
                          orElse: () => graph.nodes.first,
                        ),
                        onClose: () {
                          ref.read(selectedNodeProvider.notifier).state = null;
                        },
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.surfaceVariant.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.touch_app_outlined,
                                color: theme.textDisabled,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No Node Selected',
                              style: TextStyle(
                                color: theme.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap a node to edit its properties',
                              style: TextStyle(
                                color: theme.textDisabled,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NodeTypeInfo {
  final String name;
  final IconData icon;
  final Color color;
  final NodeData Function() createNode;

  _NodeTypeInfo(this.name, this.icon, this.color, this.createNode);
}

class _GridPainter extends CustomPainter {
  final Color gridColor;
  final Color backgroundColor;

  _GridPainter({
    required this.gridColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = backgroundColor,
    );

    final paint = Paint()
      ..color = gridColor.withOpacity(0.15)
      ..strokeWidth = 1;

    const gridSize = 50.0;

    // Draw grid lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw major grid lines (every 5 cells)
    final majorPaint = Paint()
      ..color = gridColor.withOpacity(0.25)
      ..strokeWidth = 1.5;

    const majorGridSize = gridSize * 5;
    for (double x = 0; x <= size.width; x += majorGridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), majorPaint);
    }
    for (double y = 0; y <= size.height; y += majorGridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), majorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.gridColor != gridColor || oldDelegate.backgroundColor != backgroundColor;
}

// Helper to use TransformationController with hooks
TransformationController useTransformationController() {
  return use(const _TransformationControllerHook());
}

class _TransformationControllerHook extends Hook<TransformationController> {
  const _TransformationControllerHook();

  @override
  _TransformationControllerHookState createState() => _TransformationControllerHookState();
}

class _TransformationControllerHookState extends HookState<TransformationController, _TransformationControllerHook> {
  late final TransformationController _controller;

  @override
  void initHook() {
    super.initHook();
    _controller = TransformationController();
  }

  @override
  TransformationController build(BuildContext context) => _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
