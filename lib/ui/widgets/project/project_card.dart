import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../core.dart';
import '../../../data.dart';
import 'project_menu_button.dart';
import 'project_thumbnail.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final Function(Project)? onTapProject;
  final Function(Project)? onDeleteProject;
  final Function(Project)? onEditProject;
  final Function(Project)? onUploadProject;
  final Function(Project)? onUpdateProject;
  final Function(Project)? onDeleteCloudProject;

  const ProjectCard({
    super.key,
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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          onTapProject?.call(project);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (kIsWeb || !Platform.isAndroid) const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.name,
                            style: MediaQuery.sizeOf(context).adaptiveValue(
                              Theme.of(context).textTheme.titleSmall,
                              {
                                ScreenSize.md: Theme.of(context).textTheme.titleMedium,
                                ScreenSize.lg: Theme.of(context).textTheme.titleMedium,
                                ScreenSize.xl: Theme.of(context).textTheme.titleMedium,
                              },
                            )?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Cloud sync indicator
                        if (project.isCloudSynced) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Feather.cloud,
                                  size: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Synced',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ProjectMenuButton(
                    project: project,
                    onTapProject: onTapProject,
                    onDeleteProject: onDeleteProject,
                    onEditProject: onEditProject,
                    onUploadProject: onUploadProject,
                    onUpdateProject: onUpdateProject,
                    onDeleteCloudProject: onDeleteCloudProject,
                  ),
                  if (kIsWeb || !Platform.isAndroid) const SizedBox(width: 8),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    AspectRatio(
                      // Clamped so a very tall or very wide canvas doesn't
                      // blow out the grid's row heights; the thumbnail itself
                      // is letterboxed (BoxFit.contain) so it never distorts.
                      aspectRatio: (project.width / project.height).clamp(0.65, 1.6),
                      child: ProjectThumbnailWidget(
                        project: project,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip(
                          context,
                          icon: Feather.grid,
                          label: '${project.width}x${project.height}',
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        _buildInfoChip(
                          context,
                          icon: Feather.clock,
                          label: formatLastEdited(context, project.editedAt),
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
