import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../core.dart';
import '../../../data.dart';
import '../../../l10n/strings.dart';
import '../dialogs/rename_project_dialog.dart';
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
                  PopupMenuButton(
                    icon: const Icon(Feather.more_vertical),
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(25, 25),
                      iconSize: 20,
                    ),
                    itemBuilder: (context) {
                      return _buildMenuItems(context);
                    },
                    onSelected: (value) {
                      _handleMenuAction(context, value);
                    },
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
                      aspectRatio: project.width / project.height,
                      child: ProjectThumbnailWidget(project: project),
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
                          label: _formatLastEdited(context, project.editedAt),
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

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final items = <PopupMenuEntry<String>>[];

    // Rename option (always available)
    items.add(
      PopupMenuItem(
        value: 'rename',
        child: Row(
          children: [
            const Icon(Feather.edit_2),
            const SizedBox(width: 8),
            Text(Strings.of(context).rename),
          ],
        ),
      ),
    );

    // Edit option (always available)
    items.add(
      PopupMenuItem(
        value: 'edit',
        child: Row(
          children: [
            const Icon(Feather.edit),
            const SizedBox(width: 8),
            Text(Strings.of(context).edit),
          ],
        ),
      ),
    );

    // Cloud-related options
    if (project.isCloudSynced) {
      // Update cloud project
      items.add(
        const PopupMenuItem(
          value: 'update',
          child: Row(
            children: [
              Icon(Feather.upload_cloud),
              SizedBox(width: 8),
              Text('Resync with cloud'),
            ],
          ),
        ),
      );
    } else if (project.remoteId == null) {
      // Upload to cloud
      items.add(
        const PopupMenuItem(
          value: 'upload',
          child: Row(
            children: [
              Icon(Feather.upload),
              SizedBox(width: 8),
              Text('Sync to cloud'),
            ],
          ),
        ),
      );
    }

    // Separator
    items.add(const PopupMenuDivider());

    // Delete local project
    items.add(
      PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            const Icon(Feather.trash_2, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              Strings.of(context).delete,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );

    return items;
  }

  void _handleMenuAction(BuildContext context, String value) {
    switch (value) {
      case 'edit':
        onTapProject?.call(project);
        break;
      case 'rename':
        showDialog(
          context: context,
          builder: (context) => RenameProjectDialog(
            onRename: (name) {
              onEditProject?.call(
                project.copyWith(name: name),
              );
            },
          ),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
      case 'upload':
        onUploadProject?.call(project);
        break;
      case 'update':
        onUpdateProject?.call(project);
        break;
      case 'delete_cloud':
        _showDeleteCloudConfirmation(context);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          Strings.of(context).deleteProject,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Strings.of(context).areYouSureWantToDeleteProject,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            if (project.isCloudSynced) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Feather.alert_triangle, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This project is synced to the cloud. Deleting locally will not affect the cloud version.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(Strings.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDeleteProject?.call(project);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(Strings.of(context).delete),
          ),
        ],
      ),
    );
  }

  void _showDeleteCloudConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Cloud'),
        content: const Text(
          'This will remove the project from the cloud and make it local-only. '
          'Your local copy will remain unchanged. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDeleteCloudProject?.call(project);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Remove from Cloud'),
          ),
        ],
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

  String _formatLastEdited(BuildContext context, DateTime lastEdited) {
    final now = DateTime.now();
    final difference = now.difference(lastEdited);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return Strings.of(context).justNow;
    }
  }
}
