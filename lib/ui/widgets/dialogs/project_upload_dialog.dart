import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../data.dart';
import '../../../providers/project_upload_provider.dart';
import '../project/project_thumbnail.dart';

class ProjectUploadDialog extends HookConsumerWidget {
  final Project project;
  final bool isUpdate;

  const ProjectUploadDialog({
    super.key,
    required this.project,
    this.isUpdate = false,
  });

  static Future<T?> show<T>(
    BuildContext context,
    Project project, {
    bool isUpdate = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProjectUploadDialog(
        project: project,
        isUpdate: isUpdate,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController(text: project.name);
    final descriptionController = useTextEditingController();
    final isPublic = useState(!isUpdate || true); // Default to public for new projects
    final selectedTags = useState<List<String>>([]);
    final isUploading = useState(false);

    final uploadState = ref.watch(projectUploadProvider);
    final popularTags = ref.watch(popularProjectTagsProvider);

    // Handle upload state changes
    useEffect(() {
      if (uploadState.isSuccess && !isUploading.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context).pop(true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isUpdate ? 'Project updated successfully!' : 'Project uploaded successfully!',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      }
      return null;
    }, [uploadState.isSuccess]);

    // Handle upload errors
    useEffect(() {
      if (uploadState.error != null && !isUploading.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(uploadState.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      }
      return null;
    }, [uploadState.error]);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isUpdate ? Feather.upload_cloud : Feather.upload,
            size: 24,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(isUpdate ? 'Update Project' : 'Upload Project', style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project preview
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    // Checkerboard background
                    CustomPaint(
                      painter: CheckerboardPainter(
                        cellSize: 8,
                        color1: Colors.grey.shade100,
                        color2: Colors.grey.shade50,
                      ),
                      size: const Size.fromHeight(150),
                    ),
                    // Project thumbnail
                    Center(
                      child: AspectRatio(
                        aspectRatio: project.width / project.height,
                        child: ProjectThumbnailWidget(project: project),
                      ),
                    ),
                    // Sync status overlay
                    if (project.isCloudSynced)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Feather.cloud,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Synced',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Title field
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Feather.type),
                ),
                maxLength: 100,
              ),

              const SizedBox(height: 16),

              // Description field
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Feather.file_text),
                ),
                maxLines: 3,
                maxLength: 500,
              ),

              const SizedBox(height: 16),

              // Public/Private toggle
              Row(
                children: [
                  const Icon(Feather.globe),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Make this project public',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  Switch(
                    value: isPublic.value,
                    onChanged: (value) {
                      isPublic.value = value;
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                    activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ],
              ),

              if (!isPublic.value) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Feather.lock, size: 16, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Private projects are only visible to you',
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

              const SizedBox(height: 20),

              // Tags section
              Text(
                'Tags',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              popularTags.when(
                data: (tags) => _buildTagsSelector(
                  context,
                  tags,
                  selectedTags,
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Text(
                  'Failed to load tags',
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ),

              const SizedBox(height: 16),

              // Selected tags display
              if (selectedTags.value.isNotEmpty) ...[
                Text(
                  'Selected Tags:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedTags.value.map((tag) {
                    return Chip(
                      label: Text('#$tag'),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        selectedTags.value = selectedTags.value.where((t) => t != tag).toList();
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Project info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project Info',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Size: ${project.width} × ${project.height}'),
                        Text('Frames: ${project.frames.length}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Layers: ${project.frames.first.layers.length}'),
                        if (project.isCloudSynced && project.remoteId != null) Text('Cloud ID: ${project.remoteId}'),
                      ],
                    ),
                  ],
                ),
              ),

              // Upload progress
              if (uploadState.isUploading) ...[
                const SizedBox(height: 20),
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: uploadState.uploadProgress,
                      backgroundColor: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(uploadState.uploadProgress * 100).toInt()}% ${uploadState.isUpdating ? 'Updating' : 'Uploading'}...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: uploadState.isUploading
              ? null
              : () {
                  Navigator.of(context).pop(false);
                },
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: uploadState.isUploading
              ? null
              : () {
                  _handleUpload(
                    context,
                    ref,
                    titleController.text.trim(),
                    descriptionController.text.trim(),
                    isPublic.value,
                    selectedTags.value,
                    isUploading,
                  );
                },
          icon: Icon(
            uploadState.isUploading ? Icons.hourglass_empty : (isUpdate ? Feather.upload_cloud : Feather.upload),
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          label: Text(
            uploadState.isUploading
                ? (uploadState.isUpdating ? 'Updating...' : 'Uploading...')
                : (isUpdate ? 'Update' : 'Upload'),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSelector(
    BuildContext context,
    List<dynamic> tags,
    ValueNotifier<List<String>> selectedTags,
  ) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 150),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.take(20).map((tag) {
            final tagName = tag.name as String;
            final isSelected = selectedTags.value.contains(tagName);

            return FilterChip(
              label: Text('#$tagName'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  if (selectedTags.value.length < 5) {
                    selectedTags.value = [...selectedTags.value, tagName];
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Maximum 5 tags allowed'),
                      ),
                    );
                  }
                } else {
                  selectedTags.value = selectedTags.value.where((t) => t != tagName).toList();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _handleUpload(
    BuildContext context,
    WidgetRef ref,
    String title,
    String description,
    bool isPublic,
    List<String> tags,
    ValueNotifier<bool> isUploading,
  ) {
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    isUploading.value = true;

    ref
        .read(projectUploadProvider.notifier)
        .uploadProject(
          localProject: project,
          title: title,
          description: description.isEmpty ? null : description,
          isPublic: isPublic,
          tags: tags,
        )
        .then((_) {
      isUploading.value = false;
    }).catchError((error) {
      isUploading.value = false;
    });
  }
}

class CheckerboardPainter extends CustomPainter {
  final double cellSize;
  final Color color1;
  final Color color2;

  CheckerboardPainter({
    required this.cellSize,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rows = (size.height / cellSize).ceil();
    final cols = (size.width / cellSize).ceil();

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final color = (row + col) % 2 == 0 ? color1 : color2;
        paint.color = color;

        canvas.drawRect(
          Rect.fromLTWH(
            col * cellSize,
            row * cellSize,
            cellSize,
            cellSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
