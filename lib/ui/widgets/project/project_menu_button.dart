import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../data.dart';
import '../../../l10n/strings.dart';
import '../dialogs/rename_project_dialog.dart';

/// Shared project-actions popup menu (rename/edit/sync/delete) plus its
/// confirmation dialogs. Used by both [ProjectCard] (grid) and
/// [SidebarProjectListItem] (compact list) so this logic only exists once.
class ProjectMenuButton extends StatelessWidget {
  final Project project;
  final Function(Project)? onTapProject;
  final Function(Project)? onDeleteProject;
  final Function(Project)? onEditProject;
  final Function(Project)? onUploadProject;
  final Function(Project)? onUpdateProject;
  final Function(Project)? onDeleteCloudProject;
  final double iconSize;
  final double buttonSize;

  const ProjectMenuButton({
    super.key,
    required this.project,
    this.onTapProject,
    this.onDeleteProject,
    this.onEditProject,
    this.onUploadProject,
    this.onUpdateProject,
    this.onDeleteCloudProject,
    this.iconSize = 20,
    this.buttonSize = 25,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Feather.more_vertical, size: iconSize),
      style: IconButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size(buttonSize, buttonSize),
        iconSize: iconSize,
      ),
      itemBuilder: (context) => _buildMenuItems(context),
      onSelected: (value) => _handleMenuAction(context, value),
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
      items.add(
        PopupMenuItem(
          value: 'update',
          child: Row(
            children: [
              const Icon(Feather.upload_cloud),
              const SizedBox(width: 8),
              Text(Strings.of(context).resyncWithCloud),
            ],
          ),
        ),
      );
    } else if (project.remoteId == null) {
      // Local-only project — offer first-time upload
      items.add(
        PopupMenuItem(
          value: 'upload',
          child: Row(
            children: [
              const Icon(Feather.upload),
              const SizedBox(width: 8),
              Text(Strings.of(context).syncToCloud),
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
                  border:
                      Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Feather.alert_triangle,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        Strings.of(context).syncedCloudDeleteWarning,
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
        title: Text(Strings.of(context).removeFromCloud),
        content: Text(Strings.of(context).removeFromCloudMessage),
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
              onDeleteCloudProject?.call(project);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text(Strings.of(context).removeFromCloud),
          ),
        ],
      ),
    );
  }
}
