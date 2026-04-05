import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:picell/data.dart';

import '../../../../core.dart';
import '../../../../l10n/strings.dart';
import '../../dialogs/rename_project_dialog.dart';
import '../project_thumbnail.dart';

/// RetroWave flagship project card.
/// Features: sharp corners, hot-pink border with glow, CRT scanlines overlay,
/// animated gradient border, monospace typography, L-shaped corner accents.
class RetroWaveProjectCard extends HookWidget {
  final Project project;
  final Function(Project)? onTapProject;
  final Function(Project)? onDeleteProject;
  final Function(Project)? onEditProject;
  final Function(Project)? onUploadProject;
  final Function(Project)? onUpdateProject;
  final Function(Project)? onDeleteCloudProject;

  const RetroWaveProjectCard({
    super.key,
    required this.project,
    this.onTapProject,
    this.onDeleteProject,
    this.onEditProject,
    this.onUploadProject,
    this.onUpdateProject,
    this.onDeleteCloudProject,
  });

  static const _pink = Color(0xFFFF0080);
  static const _cyan = Color(0xFF00FFFF);
  static const _purple = Color(0xFFBF5FFF);
  static const _bg = Color(0xFF0A0A1A);

  @override
  Widget build(BuildContext context) {
    final borderAnim = useAnimationController(
      duration: const Duration(seconds: 4),
    )..repeat();

    return AnimatedBuilder(
      animation: borderAnim,
      builder: (context, child) {
        final t = borderAnim.value;
        // Rotate gradient hue: pink → purple → cyan → pink
        final borderColors = [
          Color.lerp(_pink, _purple, math.sin(t * math.pi) * 0.5 + 0.5)!,
          Color.lerp(_purple, _cyan, math.sin((t + 0.33) * math.pi) * 0.5 + 0.5)!,
          Color.lerp(_cyan, _pink, math.sin((t + 0.66) * math.pi) * 0.5 + 0.5)!,
        ];

        // gradient acts as the neon border; color and gradient cannot coexist
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: borderColors,
            ),
            boxShadow: [
              BoxShadow(
                color: _pink.withValues(alpha: 0.35),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(1.5), // border thickness
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(3),
            ),
            child: child,
          ),
        );
      },
      child: _CardContent(
        project: project,
        onTapProject: onTapProject,
        onDeleteProject: onDeleteProject,
        onEditProject: onEditProject,
        onUploadProject: onUploadProject,
        onUpdateProject: onUpdateProject,
        onDeleteCloudProject: onDeleteCloudProject,
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final Project project;
  final Function(Project)? onTapProject;
  final Function(Project)? onDeleteProject;
  final Function(Project)? onEditProject;
  final Function(Project)? onUploadProject;
  final Function(Project)? onUpdateProject;
  final Function(Project)? onDeleteCloudProject;

  const _CardContent({
    required this.project,
    this.onTapProject,
    this.onDeleteProject,
    this.onEditProject,
    this.onUploadProject,
    this.onUpdateProject,
    this.onDeleteCloudProject,
  });

  static const _pink = Color(0xFFFF0080);
  static const _cyan = Color(0xFF00FFFF);
  static const _bg = Color(0xFF0A0A1A);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(3),
      onTap: () => onTapProject?.call(project),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Row(
              children: [
                // Terminal prompt prefix
                const Text(
                  '>_ ',
                  style: TextStyle(
                    color: _cyan,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    project.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _pink,
                      fontSize: MediaQuery.sizeOf(context).adaptiveValue(
                        11.0,
                        {ScreenSize.md: 13.0, ScreenSize.lg: 14.0},
                      ),
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                if (project.isCloudSynced)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: _cyan.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      'SYNCED',
                      style: TextStyle(
                        color: _cyan,
                        fontSize: 8,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                _PopupMenu(
                  project: project,
                  onTapProject: onTapProject,
                  onDeleteProject: onDeleteProject,
                  onEditProject: onEditProject,
                  onUploadProject: onUploadProject,
                  onUpdateProject: onUpdateProject,
                  onDeleteCloudProject: onDeleteCloudProject,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Thumbnail with scanlines + corner accents ───────────────────
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: project.width / project.height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: ProjectThumbnailWidget(project: project),
                  ),
                ),
                // Scanlines overlay
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: CustomPaint(painter: _ScanlinesPainter()),
                  ),
                ),
                // Corner accents
                Positioned(top: 4, left: 4, child: _CornerAccent(color: _cyan)),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Transform.flip(flipX: true, child: _CornerAccent(color: _cyan)),
                ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Transform.flip(flipY: true, child: _CornerAccent(color: _cyan)),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Transform.flip(
                    flipX: true,
                    flipY: true,
                    child: _CornerAccent(color: _cyan),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Info chips ──────────────────────────────────────────────────
            Row(
              children: [
                _TerminalChip(
                  label: '${project.width}x${project.height}',
                  icon: Feather.grid,
                ),
                const SizedBox(width: 8),
                _TerminalChip(
                  label: _formatLastEdited(context, project.editedAt),
                  icon: Feather.clock,
                ),
              ],
            ),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  String _formatLastEdited(BuildContext context, DateTime lastEdited) {
    final diff = DateTime.now().difference(lastEdited);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return Strings.of(context).justNow;
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _TerminalChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _TerminalChip({required this.label, required this.icon});

  static const _cyan = Color(0xFF00FFFF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: _cyan.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: _cyan.withValues(alpha: 0.8)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: _cyan,
              fontSize: 10,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerAccent extends StatelessWidget {
  final Color color;
  const _CornerAccent({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(12, 12),
      painter: _CornerPainter(color: color),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) => old.color != color;
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinesPainter _) => false;
}

// ── Popup menu (reused across all flagship cards) ────────────────────────────

class _PopupMenu extends StatelessWidget {
  final Project project;
  final Function(Project)? onTapProject;
  final Function(Project)? onDeleteProject;
  final Function(Project)? onEditProject;
  final Function(Project)? onUploadProject;
  final Function(Project)? onUpdateProject;
  final Function(Project)? onDeleteCloudProject;

  const _PopupMenu({
    required this.project,
    this.onTapProject,
    this.onDeleteProject,
    this.onEditProject,
    this.onUploadProject,
    this.onUpdateProject,
    this.onDeleteCloudProject,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Feather.more_vertical, size: 18),
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(24, 24),
      ),
      itemBuilder: (_) => [
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
      ],
      onSelected: (value) => _handle(context, value),
    );
  }

  void _handle(BuildContext context, String value) {
    switch (value) {
      case 'edit':
        onTapProject?.call(project);
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
}
