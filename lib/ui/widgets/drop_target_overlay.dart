import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../core/services/drop_handler_service.dart';

/// Callback when files are successfully dropped
typedef OnFilesDropped = void Function(List<DroppedFileResult> results);

/// A widget that wraps content and provides drag-and-drop functionality
class DropTargetOverlay extends StatefulWidget {
  const DropTargetOverlay({
    super.key,
    required this.child,
    required this.onFilesDropped,
    this.acceptedTypes = const [
      DroppedFileType.image,
      DroppedFileType.aseprite,
      DroppedFileType.project,
    ],
    this.enabled = true,
    this.overlayColor,
    this.overlayIcon,
    this.overlayText,
  });

  final Widget child;
  final OnFilesDropped onFilesDropped;
  final List<DroppedFileType> acceptedTypes;
  final bool enabled;
  final Color? overlayColor;
  final IconData? overlayIcon;
  final String? overlayText;

  @override
  State<DropTargetOverlay> createState() => _DropTargetOverlayState();
}

class _DropTargetOverlayState extends State<DropTargetOverlay> {
  bool _isDragging = false;
  bool _isProcessing = false;
  final DropHandlerService _dropHandler = DropHandlerService();

  String get _defaultOverlayText {
    final types = <String>[];
    if (widget.acceptedTypes.contains(DroppedFileType.image)) {
      types.add('images');
    }
    if (widget.acceptedTypes.contains(DroppedFileType.aseprite)) {
      types.add('Aseprite files');
    }
    if (widget.acceptedTypes.contains(DroppedFileType.project)) {
      types.add('projects');
    }
    return 'Drop ${types.join(', ')} here';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return DropTarget(
      onDragEntered: (details) {
        setState(() => _isDragging = true);
      },
      onDragExited: (details) {
        setState(() => _isDragging = false);
      },
      onDragDone: (details) async {
        setState(() {
          _isDragging = false;
          _isProcessing = true;
        });

        try {
          final filePaths = details.files.map((f) => f.path).toList();
          final results = await _dropHandler.processDroppedFiles(filePaths);

          // Filter results by accepted types
          final filteredResults = results.where((r) {
            return widget.acceptedTypes.contains(r.type) || r.type == DroppedFileType.unknown;
          }).toList();

          if (filteredResults.isNotEmpty) {
            widget.onFilesDropped(filteredResults);
          }
        } finally {
          if (mounted) {
            setState(() => _isProcessing = false);
          }
        }
      },
      child: Stack(
        children: [
          widget.child,
          if (_isDragging || _isProcessing)
            Positioned.fill(
              child: _buildOverlay(context),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final overlayColor = widget.overlayColor ?? theme.colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: overlayColor.withOpacity(_isDragging ? 0.15 : 0.1),
        border: Border.all(
          color: overlayColor.withOpacity(_isDragging ? 0.8 : 0.5),
          width: 3,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Center(
        child: _isProcessing
            ? _buildProcessingIndicator(context, overlayColor)
            : _buildDropIndicator(context, overlayColor),
      ),
    );
  }

  Widget _buildDropIndicator(BuildContext context, Color color) {
    return AnimatedScale(
      scale: _isDragging ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.overlayIcon ?? Feather.download,
              size: 64,
              color: color,
            ),
            const SizedBox(height: 16),
            Text(
              widget.overlayText ?? _defaultOverlayText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getSupportedExtensions(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator(BuildContext context, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Processing files...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  String _getSupportedExtensions() {
    final extensions = <String>[];

    if (widget.acceptedTypes.contains(DroppedFileType.image)) {
      extensions.addAll(DropHandlerService.imageExtensions);
    }
    if (widget.acceptedTypes.contains(DroppedFileType.aseprite)) {
      extensions.addAll(DropHandlerService.asepriteExtensions);
    }
    if (widget.acceptedTypes.contains(DroppedFileType.project)) {
      extensions.add(DropHandlerService.projectExtension);
    }

    return 'Supported: ${extensions.map((e) => '.$e').join(', ')}';
  }
}

/// A simpler drop target for use in canvas screens
class CanvasDropTarget extends StatefulWidget {
  const CanvasDropTarget({
    super.key,
    required this.child,
    required this.onImageDropped,
    this.onAsepriteDropped,
    this.enabled = true,
  });

  final Widget child;
  final void Function(DroppedFileResult result) onImageDropped;
  final void Function(DroppedFileResult result)? onAsepriteDropped;
  final bool enabled;

  @override
  State<CanvasDropTarget> createState() => _CanvasDropTargetState();
}

class _CanvasDropTargetState extends State<CanvasDropTarget> {
  bool _isDragging = false;
  final DropHandlerService _dropHandler = DropHandlerService();

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return DropTarget(
      onDragEntered: (details) {
        setState(() => _isDragging = true);
      },
      onDragExited: (details) {
        setState(() => _isDragging = false);
      },
      onDragDone: (details) async {
        setState(() => _isDragging = false);

        if (details.files.isEmpty) return;

        // Process only the first file for canvas
        final result = await _dropHandler.processDroppedFile(details.files.first.path);

        if (!mounted) return;

        if (result.type == DroppedFileType.image && result.isSuccess) {
          widget.onImageDropped(result);
        } else if (result.type == DroppedFileType.aseprite && result.isSuccess) {
          widget.onAsepriteDropped?.call(result);
        } else if (!result.isSuccess) {
          _showError(context, result.errorMessage ?? 'Failed to process file');
        }
      },
      child: Stack(
        children: [
          widget.child,
          if (_isDragging)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Feather.image,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Drop to import as layer',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
