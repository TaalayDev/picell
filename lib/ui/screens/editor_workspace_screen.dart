import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/models/project_model.dart';
import '../../l10n/strings.dart';
import '../../pixel/providers/pixel_canvas_provider.dart';
import '../../providers/editor_workspace_provider.dart';
import '../../providers/projects_provider.dart';
import '../widgets/project_tabs_bar.dart';
import '../widgets/project_tab_launcher.dart';
import '../widgets/project_workspace_shortcuts.dart';
import 'pixel_canvas_screen.dart';

class EditorWorkspaceScreen extends ConsumerStatefulWidget {
  const EditorWorkspaceScreen({
    super.key,
    required this.initialProject,
  });

  final Project initialProject;

  @override
  ConsumerState<EditorWorkspaceScreen> createState() =>
      _EditorWorkspaceScreenState();
}

class _EditorWorkspaceScreenState extends ConsumerState<EditorWorkspaceScreen> {
  static const _maxResidentEditors = 4;

  final Set<int> _residentProjectIds = {};
  final List<int> _recentProjectIds = [];
  bool _isChangingResidency = false;
  int? _loadingProjectId;

  @override
  void initState() {
    super.initState();
    _residentProjectIds.add(widget.initialProject.id);
    _recentProjectIds.add(widget.initialProject.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(editorWorkspaceProvider.notifier)
          .startWorkspace(widget.initialProject);
    });
  }

  Future<void> _showProjectPicker() async {
    final selected = await ProjectTabLauncher.show(context);
    if (selected == null || !mounted) return;

    var project = selected;
    if (project.frames.isEmpty || project.frames.first.layers.isEmpty) {
      final loaded =
          await ref.read(projectsProvider.notifier).getProject(project.id);
      if (loaded == null || !mounted) return;
      project = loaded;
    }

    await _openProject(project);
  }

  void _markRecentlyUsed(int projectId) {
    _recentProjectIds
      ..remove(projectId)
      ..add(projectId);
  }

  void _showPersistenceError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(Strings.of(context).anErrorOccurred)),
    );
  }

  Future<bool> _ensureResident(ProjectEditorTab tab) async {
    if (_residentProjectIds.contains(tab.projectId)) {
      _markRecentlyUsed(tab.projectId);
      return true;
    }

    if (_residentProjectIds.length >= _maxResidentEditors) {
      final workspace = ref.read(editorWorkspaceProvider);
      final victimId = _recentProjectIds.firstWhere(
        (projectId) => projectId != workspace.activeProjectId,
        orElse: () => _recentProjectIds.first,
      );
      final victim = workspace.tabs.firstWhere(
        (candidate) => candidate.projectId == victimId,
      );
      final saved = await ref
          .read(pixelCanvasNotifierProvider(victim.project).notifier)
          .flushPendingProjectSave();
      if (!mounted) return false;
      if (!saved) {
        _showPersistenceError();
        return false;
      }

      setState(() {
        _residentProjectIds.remove(victimId);
        _recentProjectIds.remove(victimId);
      });
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return false;
    }

    final latest =
        await ref.read(projectsProvider.notifier).getProject(tab.projectId);
    if (!mounted) return false;
    if (latest == null) {
      _showPersistenceError();
      return false;
    }

    ref.read(editorWorkspaceProvider.notifier).updateProject(latest);
    setState(() {
      _residentProjectIds.add(tab.projectId);
      _markRecentlyUsed(tab.projectId);
    });
    return true;
  }

  Future<void> _activateProject(int projectId) async {
    final workspace = ref.read(editorWorkspaceProvider);
    final tab =
        workspace.tabs.where((tab) => tab.projectId == projectId).firstOrNull;
    if (tab == null) return;

    if (_residentProjectIds.contains(projectId)) {
      _markRecentlyUsed(projectId);
      ref.read(editorWorkspaceProvider.notifier).activateProject(projectId);
      return;
    }
    if (_isChangingResidency) return;

    _isChangingResidency = true;
    setState(() => _loadingProjectId = projectId);
    try {
      if (await _ensureResident(tab) && mounted) {
        ref.read(editorWorkspaceProvider.notifier).activateProject(projectId);
      }
    } finally {
      _isChangingResidency = false;
      if (mounted) setState(() => _loadingProjectId = null);
    }
  }

  Future<void> _activateRelative(int offset) async {
    final workspace = ref.read(editorWorkspaceProvider);
    if (workspace.tabs.length < 2 || offset == 0) return;
    final currentIndex = workspace.activeIndex < 0 ? 0 : workspace.activeIndex;
    final targetIndex = (currentIndex + offset) % workspace.tabs.length;
    await _activateProject(workspace.tabs[targetIndex].projectId);
  }

  Future<void> _openProject(Project project) async {
    var projectToOpen = project;
    if (projectToOpen.id <= 0) {
      projectToOpen =
          await ref.read(projectsProvider.notifier).addProject(projectToOpen);
      if (!mounted) return;
    }

    final workspace = ref.read(editorWorkspaceProvider);
    final existing = workspace.tabs
        .where((tab) => tab.projectId == projectToOpen.id)
        .firstOrNull;
    if (existing != null) {
      await _activateProject(projectToOpen.id);
      return;
    }
    if (_isChangingResidency) return;

    _isChangingResidency = true;
    try {
      if (_residentProjectIds.length >= _maxResidentEditors) {
        final victimId = _recentProjectIds.firstWhere(
          (projectId) => projectId != workspace.activeProjectId,
          orElse: () => _recentProjectIds.first,
        );
        final victim = workspace.tabs.firstWhere(
          (tab) => tab.projectId == victimId,
        );
        final saved = await ref
            .read(pixelCanvasNotifierProvider(victim.project).notifier)
            .flushPendingProjectSave();
        if (!mounted) return;
        if (!saved) {
          _showPersistenceError();
          return;
        }
        setState(() {
          _residentProjectIds.remove(victimId);
          _recentProjectIds.remove(victimId);
        });
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
      }

      ref.read(editorWorkspaceProvider.notifier).openProject(projectToOpen);
      setState(() {
        _residentProjectIds.add(projectToOpen.id);
        _markRecentlyUsed(projectToOpen.id);
      });
    } finally {
      _isChangingResidency = false;
    }
  }

  Future<void> _closeProject(int projectId) async {
    final workspace = ref.read(editorWorkspaceProvider);
    final tab = workspace.tabs
        .where((candidate) => candidate.projectId == projectId)
        .firstOrNull;
    if (tab != null && _residentProjectIds.contains(projectId)) {
      final saved = await ref
          .read(pixelCanvasNotifierProvider(tab.project).notifier)
          .flushPendingProjectSave();
      if (!mounted) return;
      if (!saved) {
        _showPersistenceError();
        return;
      }
    }

    final closesLastTab = workspace.tabs.length == 1;
    ref.read(editorWorkspaceProvider.notifier).closeProject(projectId);
    _residentProjectIds.remove(projectId);
    _recentProjectIds.remove(projectId);

    final nextProjectId = ref.read(editorWorkspaceProvider).activeProjectId;
    if (nextProjectId != null && !_residentProjectIds.contains(nextProjectId)) {
      await _activateProject(nextProjectId);
    }

    if (closesLastTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).maybePop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(editorWorkspaceProvider);
    final workspaceNotifier = ref.read(editorWorkspaceProvider.notifier);
    final activeIndex = workspace.activeIndex;

    return ProjectWorkspaceShortcuts(
      onNextTab: () => _activateRelative(1),
      onPreviousTab: () => _activateRelative(-1),
      onActivateTab: (index) {
        if (index < workspace.tabs.length) {
          _activateProject(workspace.tabs[index].projectId);
        }
      },
      onCloseCurrentTab: () {
        final projectId = workspace.activeProjectId;
        if (projectId != null) _closeProject(projectId);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              ProjectTabsBar(
                state: workspace,
                onProjectSelected: _activateProject,
                onProjectClosed: (projectId) => _closeProject(projectId),
                onProjectReordered: workspaceNotifier.reorderTabs,
                onOpenProject: _showProjectPicker,
                onShowProjects: () => Navigator.of(context).maybePop(),
                loadingProjectId: _loadingProjectId,
              ),
              Expanded(
                child: activeIndex < 0
                    ? const SizedBox.shrink()
                    : IndexedStack(
                        index: activeIndex,
                        children: [
                          for (final tab in workspace.tabs)
                            if (_residentProjectIds.contains(tab.projectId))
                              PixelCanvasScreen(
                                key: ValueKey(
                                  'project-editor-${tab.projectId}',
                                ),
                                project: tab.project,
                                isActive:
                                    tab.projectId == workspace.activeProjectId,
                                onOpenProject: _openProject,
                              )
                            else
                              SizedBox.shrink(
                                key: ValueKey(
                                  'unloaded-project-${tab.projectId}',
                                ),
                              ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
