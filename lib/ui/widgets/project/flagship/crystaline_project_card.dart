import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:picell/data.dart';

import '../../../../core.dart';
import '../../../../l10n/strings.dart';
import '../../dialogs/rename_project_dialog.dart';
import '../project_thumbnail.dart';

/// Crystaline flagship card.
/// Features: deep amethyst bg, animated gradient border rotation,
/// periodic shimmer sweep, crystal facet lines on thumbnail, sparkle tap feedback.
class CrystalineProjectCard extends HookWidget {
  final Project project;
  final Function(Project)? onTapProject;
  final Function(Project)? onDeleteProject;
  final Function(Project)? onEditProject;
  final Function(Project)? onUploadProject;
  final Function(Project)? onUpdateProject;
  final Function(Project)? onDeleteCloudProject;

  const CrystalineProjectCard({
    super.key,
    required this.project,
    this.onTapProject,
    this.onDeleteProject,
    this.onEditProject,
    this.onUploadProject,
    this.onUpdateProject,
    this.onDeleteCloudProject,
  });

  static const _amethyst = Color(0xFF9B59B6);
  static const _light = Color(0xFFE8D5FF);
  static const _bg = Color(0xFF1A0D2E);

  @override
  Widget build(BuildContext context) {
    final borderRotation = useAnimationController(
      duration: const Duration(seconds: 6),
    )..repeat();

    final shimmerController = useAnimationController(
      duration: const Duration(seconds: 5),
    )..repeat(reverse: false);

    final sparkleController = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );

    return GestureDetector(
      onTapDown: (_) => sparkleController.forward(from: 0),
      onTapUp: (_) => onTapProject?.call(project),
      child: AnimatedBuilder(
        animation: Listenable.merge([borderRotation, shimmerController]),
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _amethyst.withValues(alpha: 0.4),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Rotating gradient border
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CustomPaint(
                      painter: _RotatingGradientBorderPainter(
                        angle: borderRotation.value * 2 * math.pi,
                        color1: _amethyst,
                        color2: _light,
                        borderWidth: 1.5,
                        radius: 12,
                      ),
                    ),
                  ),
                ),
                // Interior — NOT Positioned so Stack gets a natural size
                Padding(
                  padding: const EdgeInsets.all(1.5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Container(color: _bg, child: child),
                  ),
                ),
                // Shimmer sweep
                if (shimmerController.value < 0.3)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _ShimmerPainter(
                            progress: shimmerController.value / 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Sparkles on tap
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: sparkleController,
                      builder: (_, __) => sparkleController.value > 0
                          ? CustomPaint(
                              painter: _SparklePainter(
                                progress: sparkleController.value,
                                seed: project.id.hashCode,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () => onTapProject?.call(project),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _light,
                          fontSize: MediaQuery.sizeOf(context).adaptiveValue(
                            11.0,
                            {ScreenSize.md: 13.0, ScreenSize.lg: 14.0},
                          ),
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                    if (project.isCloudSynced)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: _amethyst.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _amethyst.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          '◈ sync',
                          style: TextStyle(
                            color: _light.withValues(alpha: 0.8),
                            fontSize: 8,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    PopupMenuButton<String>(
                      icon: Icon(Feather.more_vertical,
                          size: 16,
                          color: _light.withValues(alpha: 0.7)),
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

                // ── Thumbnail with facet lines ────────────────────────────
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: project.width / project.height,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ProjectThumbnailWidget(project: project),
                      ),
                    ),
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _CrystalFacetPainter(
                              seed: project.id.hashCode,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Chips ─────────────────────────────────────────────────
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _CrystalChip(label: '${project.width}×${project.height}'),
                    _CrystalChip(
                        label: _formatLastEdited(context, project.editedAt)),
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

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CrystalChip extends StatelessWidget {
  final String label;
  const _CrystalChip({required this.label});

  static const _amethyst = Color(0xFF9B59B6);
  static const _light = Color(0xFFE8D5FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _amethyst.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _amethyst.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _light,
          fontSize: 10,
          letterSpacing: 0.4,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }
}

// ── Painters ─────────────────────────────────────────────────────────────────

class _RotatingGradientBorderPainter extends CustomPainter {
  final double angle;
  final Color color1, color2;
  final double borderWidth;
  final double radius;

  _RotatingGradientBorderPainter({
    required this.angle,
    required this.color1,
    required this.color2,
    required this.borderWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [color1, color2, color1],
        transform: GradientRotation(angle),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            borderWidth / 2, borderWidth / 2, size.width - borderWidth, size.height - borderWidth),
        Radius.circular(radius),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RotatingGradientBorderPainter old) => old.angle != angle;
}

class _ShimmerPainter extends CustomPainter {
  final double progress; // 0..1

  _ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final x = -size.width * 0.5 + size.width * 1.5 * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0, 0.5, 1],
      ).createShader(Rect.fromLTWH(x - 40, 0, 80, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}

class _SparklePainter extends CustomPainter {
  final double progress;
  final int seed;

  _SparklePainter({required this.progress, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final paint = Paint()..style = PaintingStyle.fill;
    final opacity = math.sin(progress * math.pi);
    for (int i = 0; i < 6; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 2.0 + rng.nextDouble() * 3.0;
      final color = rng.nextBool()
          ? const Color(0xFFE8D5FF)
          : const Color(0xFFFFFFAA);
      paint.color = color.withValues(alpha: opacity * 0.9);
      _drawSparkle(canvas, Offset(x, y), r, paint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double r, Paint paint) {
    // 4-pointed star
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final angle = i * math.pi / 2;
      final outer = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      final inner1 = center +
          Offset(math.cos(angle + math.pi / 4) * r * 0.3,
              math.sin(angle + math.pi / 4) * r * 0.3);
      if (i == 0) {
        path.moveTo(outer.dx, outer.dy);
      } else {
        path.lineTo(outer.dx, outer.dy);
      }
      path.lineTo(inner1.dx, inner1.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.progress != progress;
}

class _CrystalFacetPainter extends CustomPainter {
  final int seed;
  _CrystalFacetPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final paint = Paint()
      ..color = const Color(0xFFE8D5FF).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Draw 2–3 diagonal facet lines
    for (int i = 0; i < 3; i++) {
      final x1 = rng.nextDouble() * size.width;
      final y1 = 0.0;
      final x2 = rng.nextDouble() * size.width;
      final y2 = size.height;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
