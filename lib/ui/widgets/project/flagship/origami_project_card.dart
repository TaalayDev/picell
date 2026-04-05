import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:picell/data.dart';

import '../../../../core.dart';
import '../../../../l10n/strings.dart';
import '../../dialogs/rename_project_dialog.dart';
import '../project_thumbnail.dart';

/// Origami flagship card.
/// Features: flat paper aesthetic, no elevation, sharp corners,
/// fold-shadow in bottom-right corner, dashed fold line, 3D tilt on tap.
class OrigamiProjectCard extends HookWidget {
  final Project project;
  final Function(Project)? onTapProject;
  final Function(Project)? onDeleteProject;
  final Function(Project)? onEditProject;
  final Function(Project)? onUploadProject;
  final Function(Project)? onUpdateProject;
  final Function(Project)? onDeleteCloudProject;

  const OrigamiProjectCard({
    super.key,
    required this.project,
    this.onTapProject,
    this.onDeleteProject,
    this.onEditProject,
    this.onUploadProject,
    this.onUpdateProject,
    this.onDeleteCloudProject,
  });

  static const _paper = Color(0xFFFAFAF8);
  static const _ink = Color(0xFF1A1A1A);
  static const _inkLight = Color(0xFF666666);
  static const _foldShadow = Color(0xFFD0CFC8);
  static const _accent = Color(0xFF7C9A85); // muted sage

  @override
  Widget build(BuildContext context) {
    final tiltController = useAnimationController(
      duration: const Duration(milliseconds: 400),
    );
    final tilt = Tween<double>(begin: 0, end: 0.06).animate(
      CurvedAnimation(parent: tiltController, curve: Curves.easeInOutCubic),
    );

    return GestureDetector(
      onTapDown: (_) => tiltController.forward(),
      onTapUp: (_) {
        tiltController.reverse();
        onTapProject?.call(project);
      },
      onTapCancel: () => tiltController.reverse(),
      child: AnimatedBuilder(
        animation: tilt,
        builder: (context, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(tilt.value),
            child: child,
          );
        },
        child: Container(
          decoration: const BoxDecoration(
            color: _paper,
            borderRadius: BorderRadius.zero,
          ),
          child: Stack(
            children: [
              // Fold shadow decoration (bottom-right corner)
              Positioned.fill(
                child: CustomPaint(
                  painter: _FoldShadowPainter(shadowColor: _foldShadow),
                ),
              ),
              _CardContent(
                project: project,
                onEditProject: onEditProject,
                onDeleteProject: onDeleteProject,
                onUploadProject: onUploadProject,
                onUpdateProject: onUpdateProject,
                onDeleteCloudProject: onDeleteCloudProject,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final Project project;
  final Function(Project)? onEditProject;
  final Function(Project)? onDeleteProject;
  final Function(Project)? onUploadProject;
  final Function(Project)? onUpdateProject;
  final Function(Project)? onDeleteCloudProject;

  const _CardContent({
    required this.project,
    this.onEditProject,
    this.onDeleteProject,
    this.onUploadProject,
    this.onUpdateProject,
    this.onDeleteCloudProject,
  });

  static const _ink = Color(0xFF1A1A1A);
  static const _inkLight = Color(0xFF666666);
  static const _accent = Color(0xFF7C9A85);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: MediaQuery.sizeOf(context).adaptiveValue(
                      12.0,
                      {ScreenSize.md: 14.0, ScreenSize.lg: 15.0},
                    ),
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (project.isCloudSynced)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Feather.cloud, size: 14, color: _inkLight),
                ),
              PopupMenuButton<String>(
                icon: const Icon(Feather.more_vertical, size: 16, color: _inkLight),
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(22, 22),
                ),
                itemBuilder: (_) => _buildMenuItems(context),
                onSelected: (v) => _handle(context, v),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Thumbnail (no border radius) ─────────────────────────────────
          AspectRatio(
            aspectRatio: project.width / project.height,
            child: ProjectThumbnailWidget(project: project),
          ),

          // ── Dashed fold line ──────────────────────────────────────────────
          const SizedBox(height: 10),
          SizedBox(
            height: 1,
            width: double.infinity,
            child: CustomPaint(
              painter: _DashedLinePainter(color: _inkLight.withValues(alpha: 0.3)),
            ),
          ),
          const SizedBox(height: 8),

          // ── Info row — flat text, no chips ───────────────────────────────
          Row(
            children: [
              Text(
                '${project.width}×${project.height}',
                style: const TextStyle(
                  color: _accent,
                  fontSize: 10,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatLastEdited(context, project.editedAt),
                style: const TextStyle(
                  color: _inkLight,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) => [
        PopupMenuItem(
          value: 'rename',
          child: Row(children: [
            const Icon(Feather.edit_2, size: 16),
            const SizedBox(width: 8),
            Text(Strings.of(context).rename),
          ]),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            const Icon(Feather.edit, size: 16),
            const SizedBox(width: 8),
            Text(Strings.of(context).edit),
          ]),
        ),
        if (project.isCloudSynced)
          const PopupMenuItem(
            value: 'update',
            child: Row(children: [
              Icon(Feather.upload_cloud, size: 16),
              SizedBox(width: 8),
              Text('Resync'),
            ]),
          )
        else if (project.remoteId == null)
          const PopupMenuItem(
            value: 'upload',
            child: Row(children: [
              Icon(Feather.upload, size: 16),
              SizedBox(width: 8),
              Text('Sync to cloud'),
            ]),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            const Icon(Feather.trash_2, size: 16, color: Colors.red),
            const SizedBox(width: 8),
            Text(Strings.of(context).delete,
                style: const TextStyle(color: Colors.red)),
          ]),
        ),
      ];

  void _handle(BuildContext context, String value) {
    switch (value) {
      case 'rename':
        showDialog(
          context: context,
          builder: (_) => RenameProjectDialog(
            onRename: (name) => onEditProject?.call(project.copyWith(name: name)),
          ),
        );
      case 'delete':
        onDeleteProject?.call(project);
      case 'upload':
        onUploadProject?.call(project);
      case 'update':
        onUpdateProject?.call(project);
    }
  }

  String _formatLastEdited(BuildContext context, DateTime lastEdited) {
    final diff = DateTime.now().difference(lastEdited);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return Strings.of(context).justNow;
  }
}

// ── Painters ─────────────────────────────────────────────────────────────────

class _FoldShadowPainter extends CustomPainter {
  final Color shadowColor;
  _FoldShadowPainter({required this.shadowColor});

  @override
  void paint(Canvas canvas, Size size) {
    const foldSize = 20.0;
    // Clipped triangle at bottom-right
    final path = Path()
      ..moveTo(size.width - foldSize, size.height)
      ..lineTo(size.width, size.height - foldSize)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = shadowColor);

    // Diagonal fold line
    final linePaint = Paint()
      ..color = shadowColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width - foldSize, size.height),
      Offset(size.width, size.height - foldSize),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashWidth = 6.0;
    const gap = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
