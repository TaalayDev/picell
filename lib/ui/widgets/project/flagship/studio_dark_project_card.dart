import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:picell/data.dart';

import '../../../../l10n/strings.dart';
import '../../dialogs/rename_project_dialog.dart';
import '../project_thumbnail.dart';

/// Studio Dark flagship card.
/// Flat, minimal pro-design-tool aesthetic: hairline border, corner
/// reticle brackets, monospace metadata, a single accent color.
class StudioDarkProjectCard extends HookWidget {
  final Project project;
  final Function(Project)? onTapProject;
  final Function(Project)? onDeleteProject;
  final Function(Project)? onEditProject;
  final Function(Project)? onUploadProject;
  final Function(Project)? onUpdateProject;
  final Function(Project)? onDeleteCloudProject;

  const StudioDarkProjectCard({
    super.key,
    required this.project,
    this.onTapProject,
    this.onDeleteProject,
    this.onEditProject,
    this.onUploadProject,
    this.onUpdateProject,
    this.onDeleteCloudProject,
  });

  static const _bg = Color(0xFF131316);
  static const _border = Color(0xFF232327);
  static const _accent = Color(0xFF2F80ED);
  static const _text = Color(0xFFEDEDF0);
  static const _textMuted = Color(0xFF8B8B94);

  @override
  Widget build(BuildContext context) {
    final hovered = useState(false);

    return MouseRegion(
      onEnter: (_) => hovered.value = true,
      onExit: (_) => hovered.value = false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hovered.value ? _accent.withValues(alpha: 0.6) : _border,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _ReticleCornersPainter(color: _accent)),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onTapProject?.call(project),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: _accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              project.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.1,
                                color: _text,
                              ),
                            ),
                          ),
                          if (project.isCloudSynced)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: _accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: _accent.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'SYNC',
                                style: GoogleFonts.jetBrainsMono(
                                  color: _accent,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          _StudioPopupMenu(
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
                      AspectRatio(
                        aspectRatio: project.width / project.height,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ProjectThumbnailWidget(project: project),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _StudioMeta(text: '${project.width}×${project.height}'),
                          const SizedBox(width: 10),
                          _StudioMeta(text: _formatLastEdited(context, project.editedAt)),
                          if (project.frames.length > 1) ...[
                            const SizedBox(width: 10),
                            _StudioMeta(text: '${project.frames.length}F'),
                          ],
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
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return Strings.of(context).justNow;
  }
}

class _StudioMeta extends StatelessWidget {
  final String text;

  const _StudioMeta({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: StudioDarkProjectCard._textMuted,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _ReticleCornersPainter extends CustomPainter {
  final Color color;

  const _ReticleCornersPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: 0.5);

    const len = 8.0;
    const inset = 6.0;

    canvas.drawLine(const Offset(inset, inset), const Offset(inset + len, inset), paint);
    canvas.drawLine(const Offset(inset, inset), const Offset(inset, inset + len), paint);

    canvas.drawLine(
      Offset(size.width - inset, size.height - inset),
      Offset(size.width - inset - len, size.height - inset),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - inset, size.height - inset),
      Offset(size.width - inset, size.height - inset - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ReticleCornersPainter oldDelegate) => false;
}

class _StudioPopupMenu extends StatelessWidget {
  final Project project;
  final Function(Project)? onTapProject;
  final Function(Project)? onDeleteProject;
  final Function(Project)? onEditProject;
  final Function(Project)? onUploadProject;
  final Function(Project)? onUpdateProject;
  final Function(Project)? onDeleteCloudProject;

  const _StudioPopupMenu({
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
        color: Colors.white.withValues(alpha: 0.6),
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
