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
    final tagSearchController = useTextEditingController();
    final isPublic = useState(true);
    final selectedTags = useState<List<String>>([]);
    final tagSearchResults = useState<List<dynamic>>([]);
    final isUploading = useState(false);

    final uploadState = ref.watch(projectUploadProvider);
    final popularTags = ref.watch(popularProjectTagsProvider);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    useEffect(() {
      if (uploadState.isSuccess && !isUploading.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            Navigator.of(context).pop(true);
          }
        });
      }
      return null;
    }, [uploadState.isSuccess]);

    useEffect(() {
      if (uploadState.error != null && isUploading.value) {
        isUploading.value = false;
      }
      return null;
    }, [uploadState.error]);

    final allTags = popularTags.valueOrNull ?? [];
    final List<dynamic> displayTags = tagSearchResults.value.isNotEmpty
        ? tagSearchResults.value
        : allTags;

    void onTagSearch(String query) {
      if (query.isEmpty) {
        tagSearchResults.value = [];
        return;
      }
      tagSearchResults.value = allTags
          .where((t) => t.name.toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────
            _DialogHeader(
              isUpdate: isUpdate,
              project: project,
              cs: cs,
              theme: theme,
            ),

            // ── Scrollable body ───────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error banner
                    if (uploadState.error != null)
                      _ErrorBanner(
                        error: uploadState.error!,
                        onDismiss: () => ref.read(projectUploadProvider.notifier).clearError(),
                      ),

                    // Title
                    _SectionLabel('Details', theme: theme),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        hintText: 'Give your project a name',
                        prefixIcon: const Icon(Feather.type, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        counterStyle: theme.textTheme.labelSmall,
                      ),
                      maxLength: 100,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Tell the community about this project (optional)',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 48),
                          child: Icon(Feather.align_left, size: 18),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        counterStyle: theme.textTheme.labelSmall,
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      maxLength: 500,
                    ),

                    const SizedBox(height: 4),

                    // Visibility
                    _SectionLabel('Visibility', theme: theme),
                    const SizedBox(height: 8),
                    _VisibilityToggle(
                      isPublic: isPublic.value,
                      onChanged: (v) => isPublic.value = v,
                      cs: cs,
                      theme: theme,
                    ),

                    const SizedBox(height: 20),

                    // Tags
                    Row(
                      children: [
                        _SectionLabel('Tags', theme: theme),
                        const SizedBox(width: 6),
                        Text(
                          '(${selectedTags.value.length}/5)',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: tagSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search tags…',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: onTagSearch,
                    ),
                    const SizedBox(height: 10),
                    popularTags.when(
                      data: (_) => _TagsGrid(
                        tags: displayTags,
                        selectedTags: selectedTags,
                        cs: cs,
                        theme: theme,
                      ),
                      loading: () => const SizedBox(
                        height: 40,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (_, __) => Text(
                        'Failed to load tags',
                        style: TextStyle(color: cs.error, fontSize: 12),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Project info chip row
                    _ProjectInfoRow(project: project, theme: theme, cs: cs),

                    // Cloud management section (for synced projects)
                    if (project.isCloudSynced && project.remoteId != null) ...[
                      const SizedBox(height: 16),
                      _SectionDivider(),
                      const SizedBox(height: 12),
                      _CloudManagementSection(
                        project: project,
                        isPublic: isPublic,
                        onTakeDown: () => _handleTakeDown(context, ref),
                        cs: cs,
                        theme: theme,
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Progress ──────────────────────────────────────────────
            if (uploadState.isUploading)
              _UploadProgress(
                progress: uploadState.uploadProgress,
                isUpdating: uploadState.isUpdating,
                theme: theme,
                cs: cs,
              ),

            // ── Actions ───────────────────────────────────────────────
            _DialogActions(
              isUploading: uploadState.isUploading,
              isUpdate: isUpdate,
              isSynced: project.isCloudSynced,
              onCancel: () => Navigator.of(context).pop(false),
              onSubmit: () => _handleUpload(
                context,
                ref,
                titleController.text.trim(),
                descriptionController.text.trim(),
                isPublic.value,
                selectedTags.value,
                isUploading,
              ),
              cs: cs,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpload(
    BuildContext context,
    WidgetRef ref,
    String title,
    String description,
    bool isPublic,
    List<String> tags,
    ValueNotifier<bool> isUploading,
  ) async {
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    isUploading.value = true;
    await ref.read(projectUploadProvider.notifier).uploadProject(
      localProject: project,
      title: title,
      description: description.isEmpty ? null : description,
      isPublic: isPublic,
      tags: tags,
    );
    isUploading.value = false;
  }

  Future<void> _handleTakeDown(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove from Cloud?'),
        content: const Text(
          'This will remove the project from the community. Your local copy will remain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(projectUploadProvider.notifier).deleteCloudProject(
        localProject: project,
      );
      if (context.mounted) Navigator.of(context).pop(true);
    } catch (_) {}
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final bool isUpdate;
  final Project project;
  final ColorScheme cs;
  final ThemeData theme;

  const _DialogHeader({
    required this.isUpdate,
    required this.project,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Checkerboard bg
        SizedBox(
          height: 180,
          width: double.infinity,
          child: CustomPaint(
            painter: CheckerboardPainter(
              cellSize: 10,
              color1: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              color2: cs.surfaceContainer.withValues(alpha: 0.6),
            ),
          ),
        ),
        // Gradient overlay (bottom fade)
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  cs.surface.withValues(alpha: 0.85),
                ],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
        ),
        // Project thumbnail centered
        SizedBox(
          height: 180,
          width: double.infinity,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140, maxWidth: 280),
              child: AspectRatio(
                aspectRatio: project.width / project.height,
                child: ProjectThumbnailWidget(project: project),
              ),
            ),
          ),
        ),
        // Close button
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: cs.surface.withValues(alpha: 0.8),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(false),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.close, size: 18, color: cs.onSurface),
              ),
            ),
          ),
        ),
        // Synced badge
        if (project.isCloudSynced)
          Positioned(
            top: 10,
            left: 12,
            child: _SyncedBadge(cs: cs),
          ),
        // Title row at bottom of header
        Positioned(
          left: 20,
          right: 20,
          bottom: 10,
          child: Row(
            children: [
              Icon(
                isUpdate ? Feather.upload_cloud : Feather.upload,
                size: 18,
                color: cs.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isUpdate ? 'Update Project' : 'Publish to Community',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SyncedBadge extends StatelessWidget {
  final ColorScheme cs;
  const _SyncedBadge({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Feather.cloud, size: 11, color: Colors.white),
          SizedBox(width: 4),
          Text('Synced', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final ThemeData theme;
  const _SectionLabel(this.text, {required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Theme.of(context).dividerColor);
  }
}

class _VisibilityToggle extends StatelessWidget {
  final bool isPublic;
  final ValueChanged<bool> onChanged;
  final ColorScheme cs;
  final ThemeData theme;

  const _VisibilityToggle({
    required this.isPublic,
    required this.onChanged,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(child: _VisibilityOption(
            icon: Feather.globe,
            label: 'Public',
            subtitle: 'Visible to everyone',
            selected: isPublic,
            onTap: () => onChanged(true),
            cs: cs,
            theme: theme,
          )),
          Container(width: 1, height: 60, color: cs.outlineVariant.withValues(alpha: 0.4)),
          Expanded(child: _VisibilityOption(
            icon: Feather.lock,
            label: 'Private',
            subtitle: 'Only visible to you',
            selected: !isPublic,
            onTap: () => onChanged(false),
            cs: cs,
            theme: theme,
          )),
        ],
      ),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;
  final ThemeData theme;

  const _VisibilityOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.45),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, size: 14, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

class _TagsGrid extends StatelessWidget {
  final List<dynamic> tags;
  final ValueNotifier<List<String>> selectedTags;
  final ColorScheme cs;
  final ThemeData theme;

  const _TagsGrid({
    required this.tags,
    required this.selectedTags,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final displayTags = tags.take(24).toList();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: displayTags.map((tag) {
        final name = tag.name as String;
        final isSelected = selectedTags.value.contains(name);
        return _TagChip(
          name: name,
          isSelected: isSelected,
          onTap: () {
            if (isSelected) {
              selectedTags.value = selectedTags.value.where((t) => t != name).toList();
            } else {
              if (selectedTags.value.length >= 5) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Maximum 5 tags allowed'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              selectedTags.value = [...selectedTags.value, name];
            }
          },
          cs: cs,
          theme: theme,
        );
      }).toList(),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme cs;
  final ThemeData theme;

  const _TagChip({
    required this.name,
    required this.isSelected,
    required this.onTap,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          '#$name',
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.75),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ProjectInfoRow extends StatelessWidget {
  final Project project;
  final ThemeData theme;
  final ColorScheme cs;

  const _ProjectInfoRow({required this.project, required this.theme, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _InfoChip(icon: Feather.grid, label: '${project.width}×${project.height}', theme: theme, cs: cs),
          _InfoDot(cs: cs),
          _InfoChip(icon: Feather.film, label: '${project.frames.length} frame${project.frames.length == 1 ? '' : 's'}', theme: theme, cs: cs),
          _InfoDot(cs: cs),
          _InfoChip(
            icon: Feather.layers,
            label: '${project.frames.first.layers.length} layer${project.frames.first.layers.length == 1 ? '' : 's'}',
            theme: theme,
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeData theme;
  final ColorScheme cs;

  const _InfoChip({required this.icon, required this.label, required this.theme, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: cs.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.65))),
      ],
    );
  }
}

class _InfoDot extends StatelessWidget {
  final ColorScheme cs;
  const _InfoDot({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: BoxDecoration(
        color: cs.onSurface.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _CloudManagementSection extends StatelessWidget {
  final Project project;
  final ValueNotifier<bool> isPublic;
  final VoidCallback onTakeDown;
  final ColorScheme cs;
  final ThemeData theme;

  const _CloudManagementSection({
    required this.project,
    required this.isPublic,
    required this.onTakeDown,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Feather.cloud, size: 13, color: cs.onSurface.withValues(alpha: 0.55)),
            const SizedBox(width: 6),
            Text(
              'CLOUD MANAGEMENT',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(color: cs.outlineVariant),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(
                  isPublic.value ? Feather.lock : Feather.globe,
                  size: 15,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
                label: Text(
                  isPublic.value ? 'Make Private' : 'Make Public',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                onPressed: () => isPublic.value = !isPublic.value,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: BorderSide(color: cs.error.withValues(alpha: 0.4)),
                  foregroundColor: cs.error,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(Feather.cloud_off, size: 15, color: cs.error),
                label: Text(
                  'Remove',
                  style: theme.textTheme.labelMedium?.copyWith(color: cs.error),
                ),
                onPressed: onTakeDown,
              ),
            ),
          ],
        ),
        if (project.remoteId != null) ...[
          const SizedBox(height: 6),
          Text(
            'Cloud ID: ${project.remoteId}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ],
    );
  }
}

class _UploadProgress extends StatelessWidget {
  final double progress;
  final bool isUpdating;
  final ThemeData theme;
  final ColorScheme cs;

  const _UploadProgress({
    required this.progress,
    required this.isUpdating,
    required this.theme,
    required this.cs,
  });

  String get _label {
    if (progress < 0.15) return isUpdating ? 'Preparing update…' : 'Preparing project…';
    if (progress < 0.4) return 'Generating thumbnail…';
    if (progress < 0.85) return isUpdating ? 'Updating on cloud…' : 'Uploading to cloud…';
    if (progress < 1.0) return 'Finalizing…';
    return isUpdating ? 'Updated!' : 'Published!';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress > 0 ? progress : null,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _label,
                style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.75)),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).toInt()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: cs.outlineVariant.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.error, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Feather.alert_circle, size: 15, color: cs.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: cs.onErrorContainer, fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(Icons.close, size: 15, color: cs.onErrorContainer),
          ),
        ],
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  final bool isUploading;
  final bool isUpdate;
  final bool isSynced;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final ColorScheme cs;
  final ThemeData theme;

  const _DialogActions({
    required this.isUploading,
    required this.isUpdate,
    required this.isSynced,
    required this.onCancel,
    required this.onSubmit,
    required this.cs,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: isUploading ? null : onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel'),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: isUploading ? null : onSubmit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: isUploading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.onPrimary,
                    ),
                  )
                : Icon(
                    isUpdate ? Feather.upload_cloud : Feather.upload,
                    size: 16,
                  ),
            label: Text(
              isUploading
                  ? (isUpdate ? 'Updating…' : 'Publishing…')
                  : (isUpdate ? 'Update' : 'Publish'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
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
        paint.color = (row + col) % 2 == 0 ? color1 : color2;
        canvas.drawRect(
          Rect.fromLTWH(col * cellSize, row * cellSize, cellSize, cellSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
