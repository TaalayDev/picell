import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../core.dart';
import '../../../data.dart';
import 'project_menu_button.dart';
import 'project_thumbnail.dart';

/// Compact ~56px-tall list row for a project — used by the desktop sidebar
/// and the mobile "My Projects" section so both share one list-card style
/// instead of the full grid card ([ProjectCard]) at those narrow widths.
class SidebarProjectListItem extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;
  final Function(Project)? onDeleteProject;
  final Function(Project)? onEditProject;
  final Function(Project)? onUploadProject;
  final Function(Project)? onUpdateProject;
  final Function(Project)? onDeleteCloudProject;

  const SidebarProjectListItem({
    super.key,
    required this.project,
    this.onTap,
    this.onDeleteProject,
    this.onEditProject,
    this.onUploadProject,
    this.onUpdateProject,
    this.onDeleteCloudProject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 40,
                height: 40,
                // Cover, not contain: at icon size a letterboxed non-square
                // thumbnail would shrink to an illegible sliver — cropping
                // reads better, the same tradeoff every OS file manager
                // makes for list-view vs. grid-view icons.
                child: ProjectThumbnailWidget(project: project, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (project.isCloudSynced) ...[
                        const SizedBox(width: 4),
                        Icon(Feather.cloud, size: 12, color: theme.colorScheme.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${project.width}×${project.height} · ${formatLastEdited(context, project.editedAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 28,
              height: 28,
              child: ProjectMenuButton(
                project: project,
                onTapProject: onTap == null ? null : (_) => onTap!(),
                onDeleteProject: onDeleteProject,
                onEditProject: onEditProject,
                onUploadProject: onUploadProject,
                onUpdateProject: onUpdateProject,
                onDeleteCloudProject: onDeleteCloudProject,
                iconSize: 16,
                buttonSize: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
