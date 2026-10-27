import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
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
    final pv = context.pv;

    return ProjectContextMenuRegion(
      project: project,
      onTapProject: onTap == null ? null : (_) => onTap!(),
      onDeleteProject: onDeleteProject,
      onEditProject: onEditProject,
      onUploadProject: onUploadProject,
      onUpdateProject: onUpdateProject,
      onDeleteCloudProject: onDeleteCloudProject,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 32,
                  height: 32,
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
                            style: pv.body(size: 14, weight: FontWeight.w600),
                          ),
                        ),
                        if (project.isCloudSynced) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.cloud_done_outlined, size: 14, color: pv.ok),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${project.width}×${project.height} · ${formatLastEdited(context, project.editedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: pv.body(size: 12, color: pv.textSecondary, weight: FontWeight.w400),
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
      ),
    );
  }
}
