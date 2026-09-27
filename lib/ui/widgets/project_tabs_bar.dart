import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../providers/editor_workspace_provider.dart';

class ProjectTabsBar extends StatelessWidget {
  const ProjectTabsBar({
    super.key,
    required this.state,
    required this.onProjectSelected,
    required this.onProjectClosed,
    required this.onProjectReordered,
    required this.onOpenProject,
    required this.onShowProjects,
    this.loadingProjectId,
  });

  final EditorWorkspaceState state;
  final ValueChanged<int> onProjectSelected;
  final ValueChanged<int> onProjectClosed;
  final void Function(int oldIndex, int newIndex) onProjectReordered;
  final VoidCallback onOpenProject;
  final VoidCallback onShowProjects;
  final int? loadingProjectId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = Strings.of(context);

    return Material(
      color: colors.surfaceContainerHighest,
      child: SizedBox(
        key: const ValueKey('project-tabs-bar'),
        height: 32,
        child: Row(
          children: [
            IconButton(
              key: const ValueKey('project-tabs-home'),
              tooltip: strings.projects,
              onPressed: onShowProjects,
              icon: const Icon(Icons.grid_view_outlined, size: 19),
            ),
            VerticalDivider(
              width: 1,
              color: colors.outlineVariant.withValues(alpha: 0.45),
            ),
            Expanded(
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                buildDefaultDragHandles: false,
                onReorder: onProjectReordered,
                itemCount: state.tabs.length,
                itemBuilder: (context, index) {
                  final tab = state.tabs[index];
                  final selected = tab.projectId == state.activeProjectId;
                  return ReorderableDragStartListener(
                    key: ValueKey('project-tab-${tab.projectId}'),
                    index: index,
                    child: _ProjectTab(
                      title: tab.project.name,
                      selected: selected,
                      isLoading: loadingProjectId == tab.projectId,
                      hasUnsavedChanges: tab.hasUnsavedChanges,
                      onTap: () => onProjectSelected(tab.projectId),
                      onClose: () => onProjectClosed(tab.projectId),
                    ),
                  );
                },
              ),
            ),
            VerticalDivider(
              width: 1,
              color: colors.outlineVariant.withValues(alpha: 0.45),
            ),
            IconButton(
              key: const ValueKey('project-tabs-add'),
              tooltip: strings.openProject,
              onPressed: onOpenProject,
              icon: const Icon(Icons.add, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectTab extends StatelessWidget {
  const _ProjectTab({
    required this.title,
    required this.selected,
    required this.isLoading,
    required this.hasUnsavedChanges,
    required this.onTap,
    required this.onClose,
  });

  final String title;
  final bool selected;
  final bool isLoading;
  final bool hasUnsavedChanges;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = selected ? colors.onSurface : colors.onSurfaceVariant;

    return Material(
      color: selected ? colors.surface : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
          padding: const EdgeInsets.only(left: 14, right: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? colors.primary : Colors.transparent,
                width: 2,
              ),
              right: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  key: const ValueKey('project-tab-loading'),
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                )
              else
                Icon(Icons.image_outlined, size: 16, color: foreground),
              const SizedBox(width: 7),
              if (hasUnsavedChanges) ...[
                Semantics(
                  label: 'Unsaved changes',
                  child: Container(
                    key: const ValueKey('project-tab-unsaved'),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: foreground,
                        fontWeight: selected ? FontWeight.w600 : null,
                      ),
                ),
              ),
              const SizedBox(width: 3),
              IconButton(
                tooltip: Strings.of(context).close,
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
