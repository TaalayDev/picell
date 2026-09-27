import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/project_model.dart';
import 'package:picell/providers/editor_workspace_provider.dart';

void main() {
  Project project(int id, String name) => Project(
        id: id,
        name: name,
        width: 16,
        height: 16,
        createdAt: DateTime(2026),
        editedAt: DateTime(2026),
      );

  group('EditorWorkspaceNotifier', () {
    test('starts a fresh workspace with its initial project', () {
      final notifier = EditorWorkspaceNotifier();
      notifier.openProject(project(2, 'Stale'));

      notifier.startWorkspace(project(1, 'First'));

      expect(notifier.state.tabs.map((tab) => tab.projectId), [1]);
      expect(notifier.state.activeProjectId, 1);
    });

    test('opens projects and activates an existing tab without duplicating it',
        () {
      final notifier = EditorWorkspaceNotifier();
      final first = project(1, 'First');
      final second = project(2, 'Second');

      notifier.openProject(first);
      notifier.openProject(second);
      notifier.openProject(first);

      expect(notifier.state.tabs.map((tab) => tab.projectId), [1, 2]);
      expect(notifier.state.activeProjectId, 1);
      expect(notifier.state.activeIndex, 0);
    });

    test('closing the active tab selects its nearest neighbor', () {
      final notifier = EditorWorkspaceNotifier();
      notifier.openProject(project(1, 'First'));
      notifier.openProject(project(2, 'Second'));
      notifier.openProject(project(3, 'Third'));

      notifier.activateProject(2);
      notifier.closeProject(2);

      expect(notifier.state.tabs.map((tab) => tab.projectId), [1, 3]);
      expect(notifier.state.activeProjectId, 3);
    });

    test('closing the last tab clears the workspace', () {
      final notifier = EditorWorkspaceNotifier();
      notifier.openProject(project(1, 'First'));

      notifier.closeProject(1);

      expect(notifier.state.tabs, isEmpty);
      expect(notifier.state.activeProjectId, isNull);
      expect(notifier.state.activeIndex, -1);
    });

    test('reorders tabs without changing the active project', () {
      final notifier = EditorWorkspaceNotifier();
      notifier.openProject(project(1, 'First'));
      notifier.openProject(project(2, 'Second'));
      notifier.openProject(project(3, 'Third'));

      notifier.reorderTabs(2, 0);

      expect(notifier.state.tabs.map((tab) => tab.projectId), [3, 1, 2]);
      expect(notifier.state.activeProjectId, 3);
    });

    test('tracks unsaved changes for a project tab', () {
      final notifier = EditorWorkspaceNotifier();
      notifier.openProject(project(1, 'First'));

      notifier.setUnsavedChanges(1, true);
      expect(notifier.state.tabs.single.hasUnsavedChanges, isTrue);

      notifier.setUnsavedChanges(1, false);
      expect(notifier.state.tabs.single.hasUnsavedChanges, isFalse);
    });

    test('cycles tabs in both directions and wraps at the edges', () {
      final notifier = EditorWorkspaceNotifier();
      notifier.openProject(project(1, 'First'));
      notifier.openProject(project(2, 'Second'));
      notifier.openProject(project(3, 'Third'));

      notifier.activateRelative(1);
      expect(notifier.state.activeProjectId, 1);

      notifier.activateRelative(-1);
      expect(notifier.state.activeProjectId, 3);
    });

    test('activates a tab by its visual index', () {
      final notifier = EditorWorkspaceNotifier();
      notifier.openProject(project(1, 'First'));
      notifier.openProject(project(2, 'Second'));

      notifier.activateAtIndex(0);
      expect(notifier.state.activeProjectId, 1);

      notifier.activateAtIndex(9);
      expect(notifier.state.activeProjectId, 1);
    });

    test('replaces a project snapshot without changing tab state', () {
      final notifier = EditorWorkspaceNotifier();
      notifier.openProject(project(1, 'First'));
      notifier.setUnsavedChanges(1, true);

      notifier.updateProject(project(1, 'Updated'));

      expect(notifier.state.tabs.single.project.name, 'Updated');
      expect(notifier.state.tabs.single.hasUnsavedChanges, isTrue);
      expect(notifier.state.activeProjectId, 1);
    });
  });
}
