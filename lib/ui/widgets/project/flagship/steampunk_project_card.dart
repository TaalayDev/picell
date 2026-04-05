import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:picell/data.dart';

import '../../../../core.dart';
import '../../../../l10n/strings.dart';
import '../../dialogs/rename_project_dialog.dart';
import '../project_thumbnail.dart';

/// Steampunk flagship card.
/// Features: dark copper bg, rivet corners, brass name plate,
/// animated steam puffs on hover, gear accent next to name.
class SteampunkProjectCard extends HookWidget {
  final Project project;
  final Function(Project)? onTapProject;
  final Function(Project)? onDeleteProject;
  final Function(Project)? onEditProject;
  final Function(Project)? onUploadProject;
  final Function(Project)? onUpdateProject;
  final Function(Project)? onDeleteCloudProject;

  const SteampunkProjectCard({
    super.key,
    required this.project,
    this.onTapProject,
    this.onDeleteProject,
    this.onEditProject,
    this.onUploadProject,
    this.onUpdateProject,
    this.onDeleteCloudProject,
  });

  static const _copper = Color(0xFFB87333);
  static const _brass = Color(0xFF8B6914);
  static const _bg = Color(0xFF2C1810);
  static const _bgLight = Color(0xFF3D2B1F);

  @override
  Widget build(BuildContext context) {
    final steamController = useAnimationController(
      duration: const Duration(milliseconds: 2000),
    );
    final hoverController = useAnimationController(
      duration: const Duration(milliseconds: 200),
    );

    return MouseRegion(
      onEnter: (_) {
        hoverController.forward();
        steamController.repeat();
      },
      onExit: (_) {
        hoverController.reverse();
        steamController.stop();
        steamController.reset();
      },
      child: AnimatedBuilder(
        animation: hoverController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _copper, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: _copper.withValues(
                      alpha: 0.2 + hoverController.value * 0.25),
                  blurRadius: 10 + hoverController.value * 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: child,
          );
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: () => onTapProject?.call(project),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Brass name plate ─────────────────────────────────────
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _brass.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                            color: _copper.withValues(alpha: 0.6), width: 1),
                      ),
                      child: Row(
                        children: [
                          // Gear icon
                          CustomPaint(
                            size: const Size(14, 14),
                            painter: _GearPainter(color: _copper),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              project.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _copper,
                                fontSize: MediaQuery.sizeOf(context).adaptiveValue(
                                  11.0,
                                  {ScreenSize.md: 13.0, ScreenSize.lg: 14.0},
                                ),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          if (project.isCloudSynced)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: _copper.withValues(alpha: 0.5)),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                '⚙ SYNC',
                                style: TextStyle(
                                  color: _copper.withValues(alpha: 0.8),
                                  fontSize: 8,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          PopupMenuButton<String>(
                            icon: Icon(Feather.more_vertical,
                                size: 16, color: _copper),
                            style: IconButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(22, 22),
                            ),
                            itemBuilder: (_) => _buildMenuItems(context),
                            onSelected: (v) => _handle(context, v),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Thumbnail with rivet corners ─────────────────────────
                    Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: project.width / project.height,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                  color: _copper.withValues(alpha: 0.5),
                                  width: 1.5),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: ProjectThumbnailWidget(project: project),
                            ),
                          ),
                        ),
                        // Rivets at corners
                        ..._rivetPositions.map(
                          (pos) => Positioned(
                            top: pos[0],
                            left: pos[1],
                            right: pos[2],
                            bottom: pos[3],
                            child: _Rivet(color: _copper),
                          ),
                        ),
                        // Steam puffs (animated on hover)
                        Positioned(
                          top: 4,
                          left: 8,
                          child: AnimatedBuilder(
                            animation: steamController,
                            builder: (_, __) => CustomPaint(
                              size: const Size(30, 20),
                              painter: _SteamPainter(
                                  progress: steamController.value),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ── Info chips ──────────────────────────────────────────
                    Row(
                      children: [
                        _BrassChip(
                          label: '${project.width}×${project.height}',
                        ),
                        const SizedBox(width: 6),
                        _BrassChip(
                          label: _formatLastEdited(context, project.editedAt),
                        ),
                      ],
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

  static const _rivetPositions = [
    [3.0, 3.0, null, null],   // top-left
    [3.0, null, 3.0, null],   // top-right
    [null, 3.0, null, 3.0],   // bottom-left
    [null, null, 3.0, 3.0],   // bottom-right
  ];

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
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return Strings.of(context).justNow;
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _Rivet extends StatelessWidget {
  final Color color;
  const _Rivet({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 2,
            spreadRadius: 0.5,
          ),
        ],
      ),
    );
  }
}

class _BrassChip extends StatelessWidget {
  final String label;
  const _BrassChip({required this.label});

  static const _copper = Color(0xFFB87333);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: _copper.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _copper.withValues(alpha: 0.9),
          fontSize: 10,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _GearPainter extends CustomPainter {
  final Color color;
  _GearPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width * 0.45;
    final innerR = size.width * 0.28;
    const teeth = 8;

    final path = Path();
    for (int i = 0; i < teeth; i++) {
      final angleOuter = (i / teeth) * 2 * math.pi;
      final angleInner = ((i + 0.5) / teeth) * 2 * math.pi;
      final outer = center + Offset(math.cos(angleOuter) * outerR, math.sin(angleOuter) * outerR);
      final inner = center + Offset(math.cos(angleInner) * innerR, math.sin(angleInner) * innerR);
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawCircle(center, innerR * 0.5, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _SteamPainter extends CustomPainter {
  final double progress;
  _SteamPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: (1 - progress) * 0.35)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int i = 0; i < 3; i++) {
      final x = size.width * (0.2 + i * 0.3);
      final y = size.height * (1 - progress) - i * 4.0;
      final radius = 3.0 + progress * 5 + i * 2.0;
      if (y > -radius) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SteamPainter old) => old.progress != progress;
}
