part of '../projects_screen.dart';

/// Project workflows shared by the mobile and desktop layouts.
mixin _ProjectsScreenActions {
  void _handleDroppedFiles(
    BuildContext context,
    WidgetRef ref,
    List<DroppedFileResult> results,
  ) async {
    final dropHandler = DropHandlerService();

    for (final result in results) {
      if (!context.mounted) return;
      if (!result.isSuccess) {
        showTopFlushbar(
          context,
          message: Text(result.errorMessage ?? Strings.of(context).failedToProcessFile(result.fileName)),
        );
        continue;
      }

      switch (result.type) {
        case DroppedFileType.project:
        case DroppedFileType.aseprite:
          if (result.project != null) {
            final loader = showLoader(
              context,
              loadingText: Strings.of(context).importingFile(result.fileName),
            );

            try {
              await ref
                  .read(projectsProvider.notifier)
                  .addProject(result.project!, source: result.type == DroppedFileType.aseprite ? 'aseprite' : 'pxv');
              if (context.mounted) {
                loader.remove();
                showTopFlushbar(
                  context,
                  message: Text(Strings.of(context).importedProjectSuccessfully(result.project!.name)),
                );
              }
            } catch (e) {
              if (context.mounted) {
                loader.remove();
                showTopFlushbar(
                  context,
                  message: Text(Strings.of(context).failedToImport(e.toString())),
                );
              }
            }
          }
          break;

        case DroppedFileType.image:
          if (result.image != null) {
            final project = dropHandler.imageToProject(result.image!, result.fileName);
            final loader = showLoader(
              context,
              loadingText: Strings.of(context).importingFile(result.fileName),
            );

            try {
              await ref.read(projectsProvider.notifier).addProject(project, source: 'image');
              if (context.mounted) {
                loader.remove();
                showTopFlushbar(
                  context,
                  message: Text(Strings.of(context).importedProjectSuccessfully(project.name)),
                );
              }
            } catch (e) {
              if (context.mounted) {
                loader.remove();
                showTopFlushbar(
                  context,
                  message: Text(Strings.of(context).failedToImport(e.toString())),
                );
              }
            }
          }
          break;

        case DroppedFileType.unknown:
          showTopFlushbar(
            context,
            message: Text(Strings.of(context).unsupportedFileType(result.fileName)),
          );
          break;
      }
    }
  }

  void _showSubscriptionScreen(BuildContext context) {
    SubscriptionOfferScreen.show(context);
  }

  void _navigateToFeedback(BuildContext context, WidgetRef ref) {
    FeedbackScreen.show(context);
  }

  /// Creates an empty square canvas of [size] and opens it right away.
  Future<void> _quickCreateProject(BuildContext context, WidgetRef ref, int size) async {
    final now = DateTime.now();
    final project = Project(
      id: 0,
      name: Strings.of(context).untitledProject,
      width: size,
      height: size,
      createdAt: now,
      editedAt: now,
    );
    final loader = showLoader(context, loadingText: Strings.of(context).creatingProject);
    final newProject = await ref.read(projectsProvider.notifier).addProject(project, source: 'blank');
    if (!context.mounted) return;
    loader.remove();
    Navigator.of(context).push(
      FlagshipPageRoute(
        context: context,
        builder: (context) => EditorWorkspaceScreen(initialProject: newProject),
      ),
    );
  }

  void _navigateToNewProject(
    BuildContext context,
    WidgetRef ref,
    UserSubscription subscription,
  ) async {
    final result = await showDialog<
        ({
          String name,
          int width,
          int height,
          ProjectType type,
          int? tileWidth,
          int? tileHeight,
          int? gridColumns,
          int? gridRows,
          Template? template,
        })>(
      context: context,
      builder: (BuildContext context) => NewProjectDialog(
        subscription: subscription,
      ),
    );

    if (result != null && context.mounted) {
      final template = result.template;
      final project = Project(
        id: 0,
        name: result.name,
        width: result.width,
        height: result.height,
        type: result.type,
        tileWidth: result.tileWidth,
        tileHeight: result.tileHeight,
        gridColumns: result.gridColumns,
        gridRows: result.gridRows,
        createdAt: DateTime.now(),
        editedAt: DateTime.now(),
        // Seed the first layer with the template; `addProject` persists
        // projects that already carry states and frames as-is.
        states: template == null ? const [] : const [AnimationStateModel(id: 0, name: 'Animation', frameRate: 24)],
        frames: template == null
            ? const []
            : [
                AnimationFrame(
                  id: 0,
                  stateId: 0,
                  name: 'Frame 1',
                  duration: 100,
                  layers: [
                    for (final (index, part)
                        in (template.builderParts.isEmpty ? [template] : template.builderParts).indexed)
                      Layer(
                        layerId: 0,
                        id: const Uuid().v4(),
                        name: part.name,
                        pixels: Uint32List.fromList(part.pixels),
                        order: index,
                      ),
                  ],
                ),
              ],
      );

      final loader = showLoader(
        context,
        loadingText: Strings.of(context).creatingProject,
      );
      final newProject = await ref
          .read(projectsProvider.notifier)
          .addProject(project, source: template == null ? 'blank' : 'template');

      if (context.mounted) {
        loader.remove();

        Navigator.of(context).push(
          FlagshipPageRoute(
            context: context,
            builder: (context) => EditorWorkspaceScreen(initialProject: newProject),
          ),
        );
      }
    }
  }

  /// Creates a project from the layered "Simple Hero" template and opens it
  /// straight in the bone rig editor, with the skeleton and animations set up.
  Future<void> _openBoneRigExample(BuildContext context, WidgetRef ref) async {
    final strings = Strings.of(context);
    final navigator = Navigator.of(context);
    final loader = showLoader(context, loadingText: strings.creatingProject);
    try {
      final templates = await ref.read(templateServiceProvider).loadAssetTemplates();
      final template = templates.firstWhere((t) => t.tags.contains('rig') && t.tags.contains('example'));
      final layers =
          template.layers.isEmpty ? [TemplateLayer(name: template.name, pixels: template.pixels)] : template.layers;
      final project = Project(
        id: 0,
        name: template.name,
        width: template.width,
        height: template.height,
        createdAt: DateTime.now(),
        editedAt: DateTime.now(),
        states: const [AnimationStateModel(id: 0, name: 'Animation', frameRate: 24)],
        frames: [
          AnimationFrame(
            id: 0,
            stateId: 0,
            name: 'Frame 1',
            duration: 100,
            layers: [
              for (final (index, layer) in layers.indexed)
                Layer(
                  layerId: 0,
                  id: const Uuid().v4(),
                  name: layer.name,
                  pixels: Uint32List.fromList(layer.pixels),
                  order: index,
                  isVisible: layer.isVisible,
                  isLocked: layer.isLocked,
                  opacity: layer.opacity,
                ),
            ],
          ),
        ],
      );
      final newProject = await ref.read(projectsProvider.notifier).addProject(project, source: 'template');
      loader.remove();
      if (!context.mounted) return;
      navigator.push(
        FlagshipPageRoute(
          context: context,
          builder: (context) => EditorWorkspaceScreen(initialProject: newProject, openBoneRigExample: true),
        ),
      );
    } catch (e) {
      loader.remove();
      if (context.mounted) {
        showTopFlushbar(context, message: Text(strings.failedToImport(e.toString())));
      }
    }
  }

  void _openProject(
    BuildContext context,
    WidgetRef ref,
    Project project,
    ValueNotifier<OverlayEntry?> loader,
  ) async {
    Project? projectToOpen = project;

    // Local projects grid already holds full project data. Re-fetching large
    // projects duplicates all layer pixel buffers right before the editor
    // mounts, which causes a visible open-time stall for existing projects.
    // Only hit the database if this entry somehow lacks frame/layer payloads.
    if (!_hasProjectCanvasData(project)) {
      loader.value = showLoader(
        context,
        loadingText: Strings.of(context).openingProject,
      );
      projectToOpen = await _resolveFullProject(ref, project);
    }

    if (projectToOpen != null && context.mounted) {
      Navigator.of(context).push(
        FlagshipPageRoute(
          context: context,
          builder: (context) => EditorWorkspaceScreen(initialProject: projectToOpen!),
        ),
      );
    }

    loader.value?.remove();
  }

  bool _hasProjectCanvasData(Project project) {
    return project.frames.isNotEmpty && project.frames.first.layers.isNotEmpty;
  }

  Future<Project?> _resolveFullProject(WidgetRef ref, Project project) async {
    if (_hasProjectCanvasData(project)) {
      return project;
    }

    return ref.read(projectsProvider.notifier).getProject(project.id);
  }

  Future<void> checkAndShowReviewDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final reviewService = ref.read(inAppReviewProvider);
    final shouldRequest = await reviewService.shouldRequestReview();

    if (shouldRequest && context.mounted) {
      Future.delayed(const Duration(seconds: 1), () {
        if (context.mounted) {
          reviewService.requestReview();
        }
      });
    }
  }

  Future<void> _onUploadProject(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AuthState authState,
  ) async {
    final fullProject = await _resolveFullProject(ref, project);
    if (fullProject == null || !context.mounted) {
      return;
    }

    if (authState.isSignedIn) {
      ProjectUploadDialog.show(context, fullProject);
    } else {
      final auth = await AuthDialog.show(context);
      if (!context.mounted) return;
      if (auth == true) {
        ProjectUploadDialog.show(context, fullProject);
      } else {
        showTopFlushbar(
          context,
          message: Text(Strings.of(context).pleaseSignInToUploadProjects),
        );
      }
    }
  }

  Future<void> _onUpdateProject(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AuthState authState,
  ) async {
    final fullProject = await _resolveFullProject(ref, project);
    if (fullProject == null || !context.mounted) {
      return;
    }

    if (!authState.isSignedIn) {
      showTopFlushbar(
        context,
        message: Text(Strings.of(context).pleaseSignInToUpdateProjects),
      );
      return;
    }

    if (!fullProject.isCloudSynced || fullProject.remoteId == null) {
      showTopFlushbar(
        context,
        message: Text(Strings.of(context).projectNotSyncedToCloud),
      );
      return;
    }

    // Open the upload dialog in update mode so the user can also change
    // visibility, tags, description, or take it down.
    ProjectUploadDialog.show(context, fullProject, isUpdate: true);
  }

  /// Confirms, then deletes the project locally and, if the user ticked it,
  /// in the cloud first. A failed cloud delete keeps the local project, so
  /// nothing is lost and the user can try again.
  Future<void> _onDeleteProject(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AuthState authState,
  ) async {
    final choice = await DeleteProjectDialog.show(context, project);
    if (choice == null || !context.mounted) return;

    if (choice.deleteCloud) {
      final removed = await _onDeleteCloudProject(context, ref, project, authState, announce: false);
      if (!removed) return;
    }
    await ref.read(projectsProvider.notifier).deleteProject(project);
  }

  /// Returns whether the cloud copy was removed.
  Future<bool> _onDeleteCloudProject(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AuthState authState, {
    bool announce = true,
  }) async {
    if (!authState.isSignedIn) {
      showTopFlushbar(
        context,
        message: Text(Strings.of(context).pleaseSignInToRemoveCloudProjects),
      );
      return false;
    }

    if (!project.isCloudSynced || project.remoteId == null) {
      showTopFlushbar(
        context,
        message: Text(Strings.of(context).projectNotSyncedToCloud),
      );
      return false;
    }

    final loader = showLoader(
      context,
      loadingText: Strings.of(context).removingFromCloud,
    );
    try {
      await ref.read(projectUploadProvider.notifier).deleteCloudProject(
            localProject: project,
          );
      if (announce && context.mounted) {
        showTopFlushbar(
          context,
          message: Text(Strings.of(context).projectRemovedFromCloudSuccessfully),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        showTopFlushbar(
          context,
          message: Text(Strings.of(context).failedToRemoveFromCloud(e.toString())),
        );
      }
      return false;
    } finally {
      // Removed on failure too; it used to stay on screen after an error.
      loader.remove();
    }
  }
}
