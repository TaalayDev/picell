import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:picell/data.dart';

import '../../../../core.dart';
import '../../../../l10n/strings.dart';
import '../../dialogs/rename_project_dialog.dart';
import '../project_thumbnail.dart';

/// Cosmic flagship card.
/// Features: animated nebula border, soft starfield, orbital highlight,
/// glassy cosmic chips, and a polished sci-fi header.
class CosmicProjectCard extends HookWidget {
  final Project project;
  final Function(Project)? onTapProject;
  final Function(Project)? onDeleteProject;
  final Function(Project)? onEditProject;
  final Function(Project)? onUploadProject;
  final Function(Project)? onUpdateProject;
  final Function(Project)? onDeleteCloudProject;

  const CosmicProjectCard({
    super.key,
    required this.project,
    this.onTapProject,
    this.onDeleteProject,
    this.onEditProject,
    this.onUploadProject,
    this.onUpdateProject,
    this.onDeleteCloudProject,
  });

  static const _space = Color(0xFF0F1230);
  static const _space2 = Color(0xFF171B44);
  static const _orange = Color(0xFFFF6B35);
  static const _cyan = Color(0xFF00D9FF);
  static const _violet = Color(0xFF7A6BFF);
  static const _text = Color(0xFFEAF2FF);

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 9),
    );

    useEffect(() {
      controller.repeat();
      return null;
    }, const []);

    final t = useAnimation(controller);
    final glowColor = Color.lerp(_orange, _cyan, (math.sin(t * 2 * math.pi) + 1) * 0.5)!;
    final borderColor = Color.lerp(_violet, _cyan, (math.cos(t * 2 * math.pi) + 1) * 0.5)!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _orange.withValues(alpha: 0.90),
            borderColor.withValues(alpha: 0.95),
            _violet.withValues(alpha: 0.92),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.22),
            blurRadius: 22,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(1.4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.5),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_space, _space2],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CosmicShellPainter(progress: t, seed: project.id),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onTapProject?.call(project),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  _orange.withValues(alpha: 0.9),
                                  _cyan.withValues(alpha: 0.9),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _cyan.withValues(alpha: 0.18),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              MaterialCommunityIcons.star_four_points_outline,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: MediaQuery.sizeOf(context).adaptiveValue(
                                    const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                      color: _text,
                                    ),
                                    {
                                      ScreenSize.md: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: _text,
                                      ),
                                    },
                                  )!,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  project.frames.length > 1
                                      ? '${project.frames.length} frames in orbit'
                                      : 'Single-frame pixel project',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _text.withValues(alpha: 0.72),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (project.isCloudSynced)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: _cyan.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: _cyan.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                'SYNC',
                                style: TextStyle(
                                  color: _cyan.withValues(alpha: 0.95),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                ),
                              ),
                            ),
                          _CosmicPopupMenu(
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
                      const SizedBox(height: 12),
                      Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: project.width / project.height,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ProjectThumbnailWidget(project: project),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 11,
                                    color: _orange,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'COSMIC',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _CosmicChip(
                            icon: Feather.grid,
                            label: '${project.width}×${project.height}',
                          ),
                          _CosmicChip(
                            icon: Feather.clock,
                            label: _formatLastEdited(context, project.editedAt),
                          ),
                          if (project.frames.length > 1)
                            _CosmicChip(
                              icon: MaterialCommunityIcons.movie_open_outline,
                              label: '${project.frames.length} frames',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
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

class _CosmicChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CosmicChip({required this.icon, required this.label});

  static const _cyan = Color(0xFF00D9FF);
  static const _text = Color(0xFFEAF2FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: _cyan.withValues(alpha: 0.10),
        border: Border.all(color: _cyan.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: _cyan.withValues(alpha: 0.95)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: _text,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CosmicPopupMenu extends StatelessWidget {
  final Project project;
  final Function(Project)? onTapProject;
  final Function(Project)? onDeleteProject;
  final Function(Project)? onEditProject;
  final Function(Project)? onUploadProject;
  final Function(Project)? onUpdateProject;
  final Function(Project)? onDeleteCloudProject;

  const _CosmicPopupMenu({
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
      icon: Icon(
        Feather.more_vertical,
        size: 18,
        color: Colors.white.withValues(alpha: 0.78),
      ),
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(24, 24),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              const Icon(Feather.edit_2, size: 16),
              const SizedBox(width: 8),
              Text(Strings.of(context).rename),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Feather.edit, size: 16),
              const SizedBox(width: 8),
              Text(Strings.of(context).edit),
            ],
          ),
        ),
        if (project.isCloudSynced)
          const PopupMenuItem(
            value: 'update',
            child: Row(
              children: [
                Icon(Feather.upload_cloud, size: 16),
                SizedBox(width: 8),
                Text('Resync'),
              ],
            ),
          )
        else if (project.remoteId == null)
          const PopupMenuItem(
            value: 'upload',
            child: Row(
              children: [
                Icon(Feather.upload, size: 16),
                SizedBox(width: 8),
                Text('Sync to cloud'),
              ],
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Feather.trash_2, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                Strings.of(context).delete,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onTapProject?.call(project);
          case 'rename':
            showDialog(
              context: context,
              builder: (_) => RenameProjectDialog(
                onRename: (name) => onEditProject?.call(
                  project.copyWith(name: name),
                ),
              ),
            );
          case 'upload':
            onUploadProject?.call(project);
          case 'update':
            onUpdateProject?.call(project);
          case 'delete':
            onDeleteProject?.call(project);
        }
      },
    );
  }
}

class _CosmicShellPainter extends CustomPainter {
  final double progress;
  final int seed;

  const _CosmicShellPainter({required this.progress, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final nebula = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFF6B35).withValues(alpha: 0.08),
          const Color(0xFF7A6BFF).withValues(alpha: 0.06),
          const Color(0xFF00D9FF).withValues(alpha: 0.08),
        ],
      ).createShader(rect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      nebula,
    );

    final starPaint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(seed);
    for (int i = 0; i < 18; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 0.5 + rng.nextDouble() * 1.2;
      final twinkle = (math.sin(progress * 2 * math.pi + i * 0.7) + 1) * 0.5;
      starPaint.color = Color.lerp(
        const Color(0xFFFF6B35).withValues(alpha: 0.18),
        const Color(0xFF00D9FF).withValues(alpha: 0.22),
        twinkle,
      )!;
      canvas.drawCircle(Offset(x, y), r, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CosmicShellPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.seed != seed;
  }
}

class _OrbitOverlayPainter extends CustomPainter {
  final double progress;
  final int seed;

  const _OrbitOverlayPainter({required this.progress, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final shade = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.black.withValues(alpha: 0.06),
          Colors.transparent,
          const Color(0xFF00D9FF).withValues(alpha: 0.06),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, shade);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF00D9FF).withValues(alpha: 0.18);

    final orbitRect = Rect.fromCenter(
      center: Offset(size.width * 0.72, size.height * 0.28),
      width: size.width * 0.40,
      height: size.height * 0.22,
    );
    canvas.drawOval(orbitRect, ringPaint);

    final orbitRect2 = Rect.fromCenter(
      center: Offset(size.width * 0.30, size.height * 0.76),
      width: size.width * 0.30,
      height: size.height * 0.16,
    );
    ringPaint.color = const Color(0xFFFF6B35).withValues(alpha: 0.16);
    canvas.drawOval(orbitRect2, ringPaint);

    final cometPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..color = const Color(0xFF00D9FF).withValues(alpha: 0.55);

    final a = progress * 2 * math.pi;
    final cx = orbitRect.center.dx + math.cos(a) * orbitRect.width * 0.5;
    final cy = orbitRect.center.dy + math.sin(a) * orbitRect.height * 0.5;
    canvas.drawCircle(Offset(cx, cy), 3.5, cometPaint);

    final rng = math.Random(seed * 13 + 7);
    final starPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 14; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final twinkle = (math.sin(progress * 2 * math.pi + i) + 1) * 0.5;
      starPaint.color = Colors.white.withValues(alpha: 0.10 + twinkle * 0.15);
      canvas.drawCircle(Offset(x, y), 0.6 + rng.nextDouble() * 1.1, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitOverlayPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.seed != seed;
  }
}
