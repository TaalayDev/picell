import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../data.dart';
import '../../../l10n/strings.dart';

/// Confirms deleting a project. For a project that is synced to the cloud it
/// offers to delete the community copy too (off by default).
class DeleteProjectDialog extends StatefulWidget {
  const DeleteProjectDialog({super.key, required this.project});

  final Project project;

  /// Null when cancelled; otherwise whether to delete the cloud copy too.
  static Future<({bool deleteCloud})?> show(BuildContext context, Project project) {
    return showDialog<({bool deleteCloud})>(
      context: context,
      builder: (_) => DeleteProjectDialog(project: project),
    );
  }

  @override
  State<DeleteProjectDialog> createState() => _DeleteProjectDialogState();
}

class _DeleteProjectDialogState extends State<DeleteProjectDialog> {
  bool _deleteCloud = false;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final theme = Theme.of(context);
    final synced = widget.project.isCloudSynced && widget.project.remoteId != null;

    return AlertDialog(
      title: Text(
        s.deleteProject,
        style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.error),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.areYouSureWantToDeleteProject, style: theme.textTheme.bodyMedium),
            if (synced) ...[
              const SizedBox(height: 12),
              CheckboxListTile(
                key: const ValueKey('delete-project-cloud-too'),
                value: _deleteCloud,
                onChanged: (value) => setState(() => _deleteCloud = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(s.deleteAlsoFromCloud),
                subtitle: Text(s.deleteAlsoFromCloudHint),
              ),
              if (!_deleteCloud)
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
                          s.syncedCloudDeleteWarning,
                          style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop((deleteCloud: synced && _deleteCloud)),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(s.delete),
        ),
      ],
    );
  }
}
