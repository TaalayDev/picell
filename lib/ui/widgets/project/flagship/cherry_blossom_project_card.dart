import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:picell/data.dart';

import '../../../../core.dart';
import '../../../../l10n/strings.dart';
import '../../dialogs/rename_project_dialog.dart';
import '../project_thumbnail.dart';

/// CherryBlossom flagship card.
/// Features: soft rounded corners, petal border decorations,
/// warm vignette on thumbnail, animated petals on hover.
class CherryBlossomProjectCard extends HookWidget {
  final Project project;
  final Function(Project)? onTapProject;
  final Function(Project)? onDeleteProject;
  final Function(Project)? onEditProject;
  final Function(Project)? onUploadProject;
  final Function(Project)? onUpdateProject;
  final Function(Project)? onDeleteCloudProject;

  const CherryBlossomProjectCard({
    super.key,
    required this.project,
    this.onTapProject,
    this.onDeleteProject,
    this.onEditProject,
    this.onUploadProject,
    this.onUpdateProject,
    this.onDeleteCloudProject,
  });

  static const _sakura = Color(0xFFFFB7C5);
  static const _darkRose = Color(0xFF9C4A6E);
  static const _bg = Color(0xFFFFFBFC);

  @override
  Widget build(BuildContext context) {
    final hoverController = useAnimationController(
      duration: const Duration(milliseconds: 200),
    );
    final petalController = useAnimationController(
      duration: const Duration(milliseconds: 1200),
    );

    // Seed confetti positions from project id
    final rng = math.Random(project.id.hashCode);
    final staticPetals = List.generate(
      3,
      (i) => _PetalPos(
        x: 0.5 + (i * 0.25),
        y: rng.nextDouble() * 0.2,
        angle: rng.nextDouble() * math.pi,
        size: 7 + rng.nextDouble() * 5,
      ),
    );

    return MouseRegion(
      onEnter: (_) {
        hoverController.forward();
        petalController.forward(from: 0);
      },
      onExit: (_) => hoverController.reverse(),
      child: AnimatedBuilder(
        animation: hoverController,
        builder: (context, child) {
          final elevation = lerpDouble(3.0, 8.0, hoverController.value);
          final translateY = lerpDouble(0.0, -3.0, hoverController.value);
          return Transform.translate(
            offset: Offset(0, translateY),
            child: Container(
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _sakura.withValues(alpha: 0.5),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _sakura.withValues(alpha: 0.25 + hoverController.value * 0.2),
                    blurRadius: elevation,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => onTapProject?.call(project),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _darkRose,
                          fontSize: MediaQuery.sizeOf(context).adaptiveValue(
                            12.0,
                            {ScreenSize.md: 14.0, ScreenSize.lg: 15.0},
                          ),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    if (project.isCloudSynced)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: _sakura.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _sakura.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Feather.cloud, size: 10, color: _darkRose),
                            const SizedBox(width: 3),
                            Text(
                              'synced',
                              style: TextStyle(
                                color: _darkRose,
                                fontSize: 9,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    PopupMenuButton<String>(
                      icon: Icon(Feather.more_vertical, size: 18, color: _darkRose),
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(24, 24),
                      ),
                      itemBuilder: (_) => _buildMenuItems(context),
                      onSelected: (v) => _handle(context, v),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Thumbnail + petal decorations ───────────────────────────
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: project.width / project.height,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          children: [
                            ProjectThumbnailWidget(project: project),
                            // Warm vignette
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 0.8,
                                    colors: [
                                      Colors.transparent,
                                      _sakura.withValues(alpha: 0.15),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Static petal decorations in top-right area
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _StaticPetalPainter(petals: staticPetals),
                        ),
                      ),
                    ),
                    // Animated petals on hover
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: petalController,
                          builder: (_, __) => CustomPaint(
                            painter: _AnimatedPetalPainter(
                              progress: petalController.value,
                              petals: staticPetals,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Chips ───────────────────────────────────────────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _SakuraChip(label: '${project.width}×${project.height}'),
                    _SakuraChip(
                      label: _formatLastEdited(context, project.editedAt),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return Strings.of(context).justNow;
  }
}

double lerpDouble(double a, double b, double t) => a + (b - a) * t;

class _PetalPos {
  final double x, y, angle, size;
  _PetalPos({required this.x, required this.y, required this.angle, required this.size});
}

class _SakuraChip extends StatelessWidget {
  final String label;
  const _SakuraChip({required this.label});

  static const _sakura = Color(0xFFFFB7C5);
  static const _darkRose = Color(0xFF9C4A6E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _sakura.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _sakura.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✿ ', style: TextStyle(fontSize: 8, color: _sakura)),
          Text(
            label,
            style: const TextStyle(
              color: _darkRose,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticPetalPainter extends CustomPainter {
  final List<_PetalPos> petals;
  _StaticPetalPainter({required this.petals});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFB7C5).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    for (final p in petals) {
      canvas.save();
      canvas.translate(p.x * size.width, p.y * size.height);
      canvas.rotate(p.angle);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _AnimatedPetalPainter extends CustomPainter {
  final double progress;
  final List<_PetalPos> petals;
  _AnimatedPetalPainter({required this.progress, required this.petals});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    for (int i = 0; i < petals.length; i++) {
      final p = petals[i];
      final offset = progress * size.height * 0.3;
      final opacity = (math.sin(progress * math.pi)).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = const Color(0xFFFFB7C5).withValues(alpha: opacity * 0.6)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(
        p.x * size.width + math.sin(progress * math.pi + i) * 8,
        p.y * size.height + offset,
      );
      canvas.rotate(p.angle + progress * math.pi * 0.5);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_AnimatedPetalPainter old) => old.progress != progress;
}
