import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../data/models/project_api_models.dart';
import '../../../providers/project_download_provider.dart';
import '../../screens/pixel_canvas_screen.dart';

class ProjectDownloadDialog extends HookConsumerWidget {
  final ApiProject project;

  const ProjectDownloadDialog({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloadState = ref.watch(projectDownloadProvider);

    useEffect(() {
      // Start download when dialog opens
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(projectDownloadProvider.notifier).downloadProject(project);
      });

      return () {};
    }, []);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Feather.download, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Downloading Project',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Feather.image,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${project.width} × ${project.height}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Progress or result
            if (downloadState.isDownloading) ...[
              Text(
                'Downloading project data...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: downloadState.downloadProgress,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(downloadState.downloadProgress * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ] else if (downloadState.isSuccess) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Feather.check_circle,
                      color: Colors.green,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Download Complete!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Project saved to your local projects',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else if (downloadState.error != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Feather.alert_circle, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Download Failed',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      downloadState.error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
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
        if (downloadState.isDownloading) ...[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ] else if (downloadState.isSuccess) ...[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to the downloaded project
              if (downloadState.downloadedProject != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PixelCanvasScreen(
                      project: downloadState.downloadedProject!,
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Feather.edit),
            label: const Text('Open Project'),
          ),
        ] else if (downloadState.error != null) ...[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(projectDownloadProvider.notifier).downloadProject(project);
            },
            icon: const Icon(Feather.refresh_cw),
            label: const Text('Retry'),
          ),
        ],
      ],
    );
  }
}
