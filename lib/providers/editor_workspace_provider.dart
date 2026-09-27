import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/models/project_model.dart';

class ProjectEditorTab {
  const ProjectEditorTab({
    required this.project,
    this.hasUnsavedChanges = false,
  });

  final Project project;
  final bool hasUnsavedChanges;

  int get projectId => project.id;

  ProjectEditorTab copyWith({
    Project? project,
    bool? hasUnsavedChanges,
  }) {
    return ProjectEditorTab(
      project: project ?? this.project,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }
}

class EditorWorkspaceState {
  const EditorWorkspaceState({
    this.tabs = const [],
    this.activeProjectId,
  });

  final List<ProjectEditorTab> tabs;
  final int? activeProjectId;

  int get activeIndex => tabs.indexWhere((tab) => tab.projectId == activeProjectId);

  EditorWorkspaceState copyWith({
    List<ProjectEditorTab>? tabs,
    int? activeProjectId,
    bool clearActiveProject = false,
  }) {
    return EditorWorkspaceState(
      tabs: tabs ?? this.tabs,
      activeProjectId: clearActiveProject ? null : (activeProjectId ?? this.activeProjectId),
    );
  }
}

class EditorWorkspaceNotifier extends StateNotifier<EditorWorkspaceState> {
  EditorWorkspaceNotifier() : super(const EditorWorkspaceState());

  void startWorkspace(Project project) {
    state = EditorWorkspaceState(
      tabs: [ProjectEditorTab(project: project)],
      activeProjectId: project.id,
    );
  }

  void openProject(Project project) {
    final existing = state.tabs.indexWhere(
      (tab) => tab.projectId == project.id,
    );
    if (existing >= 0) {
      state = state.copyWith(activeProjectId: project.id);
      return;
    }

    state = state.copyWith(
      tabs: [...state.tabs, ProjectEditorTab(project: project)],
      activeProjectId: project.id,
    );
  }

  void activateProject(int projectId) {
    if (state.tabs.any((tab) => tab.projectId == projectId)) {
      state = state.copyWith(activeProjectId: projectId);
    }
  }

  void activateRelative(int offset) {
    if (state.tabs.length < 2 || offset == 0) return;
    final currentIndex = state.activeIndex < 0 ? 0 : state.activeIndex;
    final nextIndex = (currentIndex + offset) % state.tabs.length;
    final normalizedIndex = nextIndex < 0 ? nextIndex + state.tabs.length : nextIndex;
    activateProject(state.tabs[normalizedIndex].projectId);
  }

  void activateAtIndex(int index) {
    if (index < 0 || index >= state.tabs.length) return;
    activateProject(state.tabs[index].projectId);
  }

  void updateProject(Project project) {
    final index = state.tabs.indexWhere((tab) => tab.projectId == project.id);
    if (index < 0) return;

    final tabs = List<ProjectEditorTab>.from(state.tabs);
    tabs[index] = tabs[index].copyWith(project: project);
    state = state.copyWith(tabs: tabs);
  }

  void setUnsavedChanges(int projectId, bool hasUnsavedChanges) {
    if (!mounted) return;
    final index = state.tabs.indexWhere((tab) => tab.projectId == projectId);
    if (index < 0 || state.tabs[index].hasUnsavedChanges == hasUnsavedChanges) {
      return;
    }

    final tabs = List<ProjectEditorTab>.from(state.tabs);
    tabs[index] = tabs[index].copyWith(
      hasUnsavedChanges: hasUnsavedChanges,
    );
    state = state.copyWith(tabs: tabs);
  }

  void closeProject(int projectId) {
    final closingIndex = state.tabs.indexWhere(
      (tab) => tab.projectId == projectId,
    );
    if (closingIndex < 0) return;

    final nextTabs = [
      for (final tab in state.tabs)
        if (tab.projectId != projectId) tab,
    ];

    if (nextTabs.isEmpty) {
      state = const EditorWorkspaceState();
      return;
    }

    var nextActiveId = state.activeProjectId;
    if (state.activeProjectId == projectId) {
      final nextIndex = closingIndex.clamp(0, nextTabs.length - 1);
      nextActiveId = nextTabs[nextIndex].projectId;
    }

    state = state.copyWith(
      tabs: nextTabs,
      activeProjectId: nextActiveId,
    );
  }

  void reorderTabs(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.tabs.length) return;
    if (newIndex < 0 || newIndex > state.tabs.length) return;

    final tabs = List<ProjectEditorTab>.from(state.tabs);
    if (oldIndex < newIndex) newIndex -= 1;
    final tab = tabs.removeAt(oldIndex);
    tabs.insert(newIndex, tab);
    state = state.copyWith(tabs: tabs);
  }

  void clear() => state = const EditorWorkspaceState();
}

final editorWorkspaceProvider = StateNotifierProvider.autoDispose<EditorWorkspaceNotifier, EditorWorkspaceState>(
  (ref) => EditorWorkspaceNotifier(),
);
