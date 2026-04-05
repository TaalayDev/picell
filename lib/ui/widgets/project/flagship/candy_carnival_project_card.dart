import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:picell/data.dart';

import '../../../../core.dart';
import '../../../../l10n/strings.dart';
import '../../dialogs/rename_project_dialog.dart';
import '../project_thumbnail.dart';

/// CandyCarnival flagship card.
/// Features: pill shapes, animated candy-stripe border, confetti scatter,
/// elastic bounce on tap, rainbow gradient title.
class CandyCarnivalProjectCard extends HookWidget {
  final Project project;
  final Function(Project)? onTapProject;
  final Function(Project)? onDeleteProject;
  final Function(Project)? onEditProject;
  final Function(Project)? onUploadProject;
  final Function(Project)? onUpdateProject;
  final Function(Project)? onDeleteCloudProject;

  const CandyCarnivalProjectCard({
    super.key,
    required this.project,
    this.onTapProject,
    this.onDeleteProject,
    this.onEditProject,
    this.onUploadProject,
    this.onUpdateProject,
    this.onDeleteCloudProject,
  });

  static const _pink = Color(0xFFFF6EB4);
  static const _mint = Color(0xFF00E5CC);
  static const _yellow = Color(0xFFFFD166);
  static const _bg = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final tapController = useAnimationController(
      duration: const Duration(milliseconds: 500),
    );
    final stripeAnim = useAnimationController(
      duration: const Duration(seconds: 3),
    )..repeat();

    final scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: tapController, curve: Curves.elasticOut),
    );

    // Confetti items seeded by project.id hashCode
    final rng = math.Random(project.id.hashCode);
    final confettiItems = List.generate(
      8,
      (_) => _ConfettiItem(
        x: rng.nextDouble(),
        y: rng.nextDouble() * 0.35,
        size: 4 + rng.nextDouble() * 5,
        color: [_pink, _mint, _yellow, const Color(0xFFAE81FF)][rng.nextInt(4)],
        isCircle: rng.nextBool(),
        angle: rng.nextDouble() * math.pi,
      ),
    );

    return GestureDetector(
      onTapDown: (_) => tapController.forward(),
      onTapUp: (_) {
        tapController.reverse();
        onTapProject?.call(project);
      },
      onTapCancel: () => tapController.reverse(),
      child: ScaleTransition(
        scale: scale,
        child: AnimatedBuilder(
          animation: stripeAnim,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _pink.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Candy stripe border (painted as background)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CandyStripeBorderPainter(
                          progress: stripeAnim.value,
                          color1: _pink,
                          color2: _mint,
                          radius: 24,
                          borderWidth: 2.5,
                        ),
                      ),
                    ),
                    // White interior
                    Positioned(
                      top: 2.5,
                      left: 2.5,
                      right: 2.5,
                      bottom: 2.5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                    child!,
                  ],
                ),
              ),
            );
          },
          child: _CardBody(
            project: project,
            confettiItems: confettiItems,
            onEditProject: onEditProject,
            onDeleteProject: onDeleteProject,
            onUploadProject: onUploadProject,
            onUpdateProject: onUpdateProject,
            onDeleteCloudProject: onDeleteCloudProject,
          ),
        ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  final Project project;
  final List<_ConfettiItem> confettiItems;
  final Function(Project)? onEditProject;
  final Function(Project)? onDeleteProject;
  final Function(Project)? onUploadProject;
  final Function(Project)? onUpdateProject;
  final Function(Project)? onDeleteCloudProject;

  const _CardBody({
    required this.project,
    required this.confettiItems,
    this.onEditProject,
    this.onDeleteProject,
    this.onUploadProject,
    this.onUpdateProject,
    this.onDeleteCloudProject,
  });

  static const _pink = Color(0xFFFF6EB4);
  static const _mint = Color(0xFF00E5CC);
  static const _yellow = Color(0xFFFFD166);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [_pink, Color(0xFFAE81FF), _mint],
                  ).createShader(bounds),
                  child: Text(
                    project.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white, // masked by shader
                      fontSize: MediaQuery.sizeOf(context).adaptiveValue(
                        13.0,
                        {ScreenSize.md: 15.0, ScreenSize.lg: 16.0},
                      ),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Feather.more_vertical, size: 18, color: _pink),
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(28, 28),
                ),
                itemBuilder: (_) => _buildMenuItems(context),
                onSelected: (v) => _handle(context, v),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Thumbnail + confetti ─────────────────────────────────────────
          Stack(
            children: [
              AspectRatio(
                aspectRatio: project.width / project.height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ProjectThumbnailWidget(project: project),
                ),
              ),
              // Confetti overlay in top area
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ConfettiPainter(items: confettiItems),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Chips ────────────────────────────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _CandyChip(
                label: '${project.width}×${project.height}',
                color: _pink,
              ),
              _CandyChip(
                label: _formatLastEdited(context, project.editedAt),
                color: _mint,
              ),
              if (project.isCloudSynced) _CandyChip(label: '☁ synced', color: _yellow),
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
            Text(Strings.of(context).delete, style: const TextStyle(color: Colors.red)),
          ]),
        ),
      ];

  void _handle(BuildContext context, String value) {
    switch (value) {
      case 'edit':
        // handled by GestureDetector above
        break;
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

class _CandyChip extends StatelessWidget {
  final String label;
  final Color color;

  const _CandyChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _ConfettiItem {
  final double x, y, size, angle;
  final Color color;
  final bool isCircle;

  _ConfettiItem({
    required this.x,
    required this.y,
    required this.size,
    required this.angle,
    required this.color,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiItem> items;
  _ConfettiPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in items) {
      final paint = Paint()
        ..color = item.color.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;
      final center = Offset(item.x * size.width, item.y * size.height);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(item.angle);
      if (item.isCircle) {
        canvas.drawCircle(Offset.zero, item.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: item.size, height: item.size * 0.5),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter _) => false;
}

class _CandyStripeBorderPainter extends CustomPainter {
  final double progress;
  final Color color1, color2;
  final double radius;
  final double borderWidth;

  _CandyStripeBorderPainter({
    required this.progress,
    required this.color1,
    required this.color2,
    required this.radius,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    // Draw alternating color stripes around the border path
    final path = Path()..addRRect(rect);
    final pathMetrics = path.computeMetrics().first;
    final totalLength = pathMetrics.length;
    const stripeLength = 16.0;
    int stripe = (progress * totalLength / stripeLength).floor();

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.butt;

    double pos = (progress * totalLength) % stripeLength;
    while (pos < totalLength) {
      final isEven = (stripe % 2) == 0;
      paint.color = isEven ? color1 : color2;
      final end = (pos + stripeLength).clamp(0.0, totalLength);
      final segment = pathMetrics.extractPath(pos, end);
      canvas.drawPath(segment, paint);
      pos += stripeLength;
      stripe++;
    }
  }

  @override
  bool shouldRepaint(_CandyStripeBorderPainter old) => old.progress != progress;
}
