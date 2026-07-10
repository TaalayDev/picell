import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../config/constants.dart';

import '../../data/models/subscription_model.dart';
import '../../data/models/project_api_models.dart';
import '../../data/models/project_model.dart';
import '../../l10n/strings.dart';
import '../../data.dart';
import '../../core.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ad/interstitial_ad_controller.dart';
import '../../providers/project_upload_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/community_projects_providers.dart';
import '../../providers/providers.dart';
import '../../providers/subscription_provider.dart';
import '../widgets/dialogs/auth_dialog.dart';
import '../widgets/animated_pro_button.dart';
import '../widgets/animated_background.dart';
import '../widgets/community_project_card.dart' hide CheckerboardPainter;
import '../widgets/dialogs/delete_account_dialog.dart';
import '../widgets/dialogs/project_upload_dialog.dart' hide CheckerboardPainter;
import '../widgets/dialogs/feedback_prompt_dialog.dart';
import '../widgets/discovery/discovery_carousel.dart';
import '../widgets/drop_target_overlay.dart';
import '../widgets/project/sidebar_project_list_item.dart';
import '../widgets/subscription/subscription_menu.dart';
import '../widgets/theme_selector.dart';
import '../widgets.dart';
import '../widgets/theme_selector_sheet.dart';
import 'feedback_screen.dart';
import 'subscription_screen.dart';
import 'about_screen.dart';
import '../../app/routing/flagship_page_route.dart';
import 'pixel_canvas_screen.dart';
import 'project_detail_screen.dart' hide CheckerboardPainter;

class ProjectsScreen extends HookConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider).theme;
    final projects = ref.watch(projectsProvider);
    final overlayLoader = useState<OverlayEntry?>(null);

    final showBadge = useState(false);
    final subscription = ref.watch(subscriptionStateProvider);

    final reviewService = ref.watch(inAppReviewProvider);

    final authState = ref.watch(authProvider);
    final showProfileIcon = authState.isSignedIn;

    final currentTheme = ref.watch(themeProvider).theme;

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkAndShowReviewDialog(context, ref);
      });

      return () {
        if (overlayLoader.value?.mounted == true) {
          overlayLoader.value?.remove();
        }
      };
    }, []);

    useEffect(() {
      if (ref.read(localStorageProvider).feedbackPromptNeverAskAgain) {
        return null;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(const Duration(seconds: 5));
        final count = await reviewService.getSessionCount();
        if ((count == 2 || count % 5 == 0) && context.mounted) {
          FeedbackPromptDialog.show(context, () {
            _navigateToFeedback(context, ref);
          });
        }
      });
    }, []);

    final isDesktop = MediaQuery.sizeOf(context).width >= 800;
    final flagship = currentTheme.flagship;

    // ── Desktop layout ─────────────────────────────────────────────────────
    if (isDesktop) {
      return DropTargetOverlay(
        onFilesDropped: (results) => _handleDroppedFiles(context, ref, results),
        acceptedTypes: const [
          DroppedFileType.image,
          DroppedFileType.aseprite,
          DroppedFileType.project,
        ],
        child: AnimatedBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Row(
              children: [
                _DesktopSidebar(
                  theme: currentTheme,
                  subscription: subscription,
                  projects: projects,
                  onTapProject: (project) => _openProject(context, ref, project, overlayLoader),
                  onDeleteProject: (project) => ref.read(projectsProvider.notifier).deleteProject(project),
                  onEditProject: (project) =>
                      ref.read(projectsProvider.notifier).renameProject(project.id, project.name),
                  onUploadProject: (project) => _onUploadProject(context, ref, project, authState),
                  onUpdateProject: (project) => _onUpdateProject(context, ref, project, authState),
                  onDeleteCloudProject: (project) => _onDeleteCloudProject(context, ref, project, authState),
                  onRetryProjects: () => ref.refresh(projectsProvider),
                  onNewProject: () => _navigateToNewProject(context, ref, subscription),
                  onImport: () async {
                    final error = await ref.read(projectsProvider.notifier).importProject(context);
                    if (error != null && context.mounted) {
                      showTopFlushbar(
                        context,
                        message: Text(Strings.of(context).invalidFileContent),
                      );
                    }
                  },
                  onFeedback: () => _navigateToFeedback(context, ref),
                  onAbout: () => showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: ClipRRect(
                        clipBehavior: Clip.antiAlias,
                        borderRadius: BorderRadius.circular(16),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: const AboutScreen(),
                        ),
                      ),
                    ),
                  ),
                  onTheme: () => ThemeSelectorBottomSheet.show(context),
                  onPro: () => _showSubscriptionScreen(context),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _DesktopContentHeader(theme: currentTheme, flagship: flagship),
                      if (!subscription.isPro && showBadge.value)
                        SubscriptionPromoBanner(onDismiss: () => showBadge.value = false),
                      Expanded(
                        child: CloudProjectsView(
                          theme: theme,
                          subscription: subscription,
                          leadingSlivers: const [
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                                child: DiscoveryCarousel(height: 220),
                              ),
                            ),
                          ],
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

    // ── Mobile layout ──────────────────────────────────────────────────────
    return DropTargetOverlay(
      onFilesDropped: (results) => _handleDroppedFiles(context, ref, results),
      acceptedTypes: const [
        DroppedFileType.image,
        DroppedFileType.aseprite,
        DroppedFileType.project,
      ],
      child: AnimatedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Row(
              children: [
                const SizedBox(width: 16),
                TextButton.icon(
                  label: const Icon(Feather.file),
                  onPressed: () async {
                    final error = await ref.read(projectsProvider.notifier).importProject(context);
                    if (error != null) {
                      switch (error) {
                        default:
                          showTopFlushbar(
                            context,
                            message: Text(Strings.of(context).invalidFileContent),
                          );
                          break;
                      }
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  label: const Icon(Feather.info),
                  onPressed: () {
                    if (kIsWeb || Platform.isMacOS || Platform.isWindows) {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: ClipRRect(
                            clipBehavior: Clip.antiAlias,
                            borderRadius: BorderRadius.circular(16),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: const AboutScreen(),
                            ),
                          ),
                        ),
                      );

                      return;
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
            leadingWidth: 200,
            actions: [
              if (!subscription.isPro && !showBadge.value) ...[
                AnimatedProButton(
                  onTap: () => _showSubscriptionScreen(context),
                  theme: theme,
                ),
                const SizedBox(width: 8),
              ],
              const KofiSupportButton(compact: true),
              const SizedBox(width: 4),
              IconButton(
                tooltip: Strings.of(context).chooseTheme,
                icon: Icon(
                  Icons.palette_outlined,
                  color: currentTheme.activeIcon,
                ),
                onPressed: () => ThemeSelectorBottomSheet.show(context),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: showProfileIcon
                    ? PopupMenuButton<String>(
                        icon: authState.apiUser?.avatarUrl != null
                            ? CircleAvatar(
                                backgroundImage: authState.apiUser?.avatarUrl != null
                                    ? NetworkImage(authState.apiUser!.avatarUrl!)
                                    : const AssetImage('assets/images/default_avatar.png'),
                                radius: 15,
                              )
                            : const Icon(Feather.user),
                        offset: const Offset(0, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.3),
                        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                        onSelected: (value) {
                          if (value == 'delete_account') {
                            DeleteAccountDialog.show(
                              context,
                              onSuccess: () {},
                            );
                          } else if (value == 'logout') {
                            ref.read(authProvider.notifier).signOut();
                          }
                        },
                        itemBuilder: (context) => [
                          if (authState.apiUser?.displayName != null)
                            PopupMenuItem(
                              enabled: false,
                              height: 56,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (authState.apiUser?.displayName != null)
                                    Text(
                                      authState.apiUser!.displayName!,
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          if (authState.apiUser?.displayName != null) const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'logout',
                            height: 48,
                            child: Row(
                              children: [
                                Icon(
                                  Feather.log_out,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  Strings.of(context).logout,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'delete_account',
                            height: 48,
                            child: Row(
                              children: [
                                Icon(
                                  Feather.trash_2,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  Strings.of(context).deleteAccount,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : IconButton(
                        tooltip: Strings.of(context).feedback,
                        icon: Icon(
                          Icons.feedback_outlined,
                          color: currentTheme.activeIcon,
                        ),
                        onPressed: () => _navigateToFeedback(context, ref),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToNewProject(context, ref, subscription),
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            extendedPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            label: Text(Strings.of(context).newProject),
            icon: const Icon(Feather.plus),
            tooltip: Strings.of(context).createNewProjectTooltip,
          ),
          body: Column(
            children: [
              if (!subscription.isPro && showBadge.value) ...[
                SubscriptionPromoBanner(
                  onDismiss: () {
                    showBadge.value = false;
                  },
                ),
              ],
              // Single scrolling page: compact "My Projects" list, then the
              // discovery carousel, then the community feed — no more
              // Local/Community tabs.
              Expanded(
                child: CloudProjectsView(
                  theme: theme,
                  subscription: subscription,
                  leadingSlivers: [
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 320,
                        child: _CompactProjectsList(
                          projects: projects,
                          onCreateNew: () => _navigateToNewProject(context, ref, subscription),
                          onTapProject: (project) => _openProject(context, ref, project, overlayLoader),
                          onDeleteProject: (project) => ref.read(projectsProvider.notifier).deleteProject(project),
                          onEditProject: (project) =>
                              ref.read(projectsProvider.notifier).renameProject(project.id, project.name),
                          onUploadProject: (project) => _onUploadProject(context, ref, project, authState),
                          onUpdateProject: (project) => _onUpdateProject(context, ref, project, authState),
                          onDeleteCloudProject: (project) => _onDeleteCloudProject(context, ref, project, authState),
                          onRetry: () => ref.refresh(projectsProvider),
                          showNewButton: true,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: DiscoveryCarousel(height: 180, showArrows: false),
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

  void _handleDroppedFiles(
    BuildContext context,
    WidgetRef ref,
    List<DroppedFileResult> results,
  ) async {
    final dropHandler = DropHandlerService();

    for (final result in results) {
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
              final newProject = await ref.read(projectsProvider.notifier).addProject(result.project!);
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
              final newProject = await ref.read(projectsProvider.notifier).addProject(project);
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
    if (kIsWeb || Platform.isMacOS || Platform.isWindows) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: ClipRRect(
            clipBehavior: Clip.antiAlias,
            borderRadius: BorderRadius.circular(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: const FeedbackScreen(),
            ),
          ),
        ),
      );

      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FeedbackScreen(),
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
        })>(
      context: context,
      builder: (BuildContext context) => NewProjectDialog(
        subscription: subscription,
      ),
    );

    if (result != null && context.mounted) {
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
      );

      final loader = showLoader(
        context,
        loadingText: Strings.of(context).creatingProject,
      );
      final newProject = await ref.read(projectsProvider.notifier).addProject(project);

      if (context.mounted) {
        loader.remove();

        Navigator.of(context).push(
          FlagshipPageRoute(
            context: context,
            builder: (context) => PixelCanvasScreen(project: newProject),
          ),
        );
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
          builder: (context) => PixelCanvasScreen(project: projectToOpen!),
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

  Future<void> _onDeleteCloudProject(
    BuildContext context,
    WidgetRef ref,
    Project project,
    AuthState authState,
  ) async {
    if (!authState.isSignedIn) {
      showTopFlushbar(
        context,
        message: Text(Strings.of(context).pleaseSignInToRemoveCloudProjects),
      );
      return;
    }

    if (!project.isCloudSynced || project.remoteId == null) {
      showTopFlushbar(
        context,
        message: Text(Strings.of(context).projectNotSyncedToCloud),
      );
      return;
    }

    try {
      final loader = showLoader(
        context,
        loadingText: Strings.of(context).removingFromCloud,
      );

      await ref.read(projectUploadProvider.notifier).deleteCloudProject(
            localProject: project,
          );

      if (context.mounted) {
        loader.remove();
        showTopFlushbar(
          context,
          message: Text(Strings.of(context).projectRemovedFromCloudSuccessfully),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showTopFlushbar(
          context,
          message: Text(Strings.of(context).failedToRemoveFromCloud(e.toString())),
        );
      }
    }
  }
}

// ── Desktop widgets ────────────────────────────────────────────────────────

class _DesktopSidebar extends StatelessWidget {
  final AppTheme theme;
  final UserSubscription subscription;
  final AsyncValue<List<Project>> projects;
  final void Function(Project) onTapProject;
  final void Function(Project) onDeleteProject;
  final void Function(Project) onEditProject;
  final void Function(Project) onUploadProject;
  final void Function(Project) onUpdateProject;
  final void Function(Project) onDeleteCloudProject;
  final VoidCallback onRetryProjects;
  final VoidCallback onNewProject;
  final VoidCallback onImport;
  final VoidCallback onFeedback;
  final VoidCallback onAbout;
  final VoidCallback onTheme;
  final VoidCallback onPro;

  const _DesktopSidebar({
    required this.theme,
    required this.subscription,
    required this.projects,
    required this.onTapProject,
    required this.onDeleteProject,
    required this.onEditProject,
    required this.onUploadProject,
    required this.onUpdateProject,
    required this.onDeleteCloudProject,
    required this.onRetryProjects,
    required this.onNewProject,
    required this.onImport,
    required this.onFeedback,
    required this.onAbout,
    required this.onTheme,
    required this.onPro,
  });

  @override
  Widget build(BuildContext context) {
    final flagship = theme.flagship;

    return Container(
      width: 272,
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(right: BorderSide(color: theme.divider, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(flagship),
          Divider(color: theme.divider, height: 1),

          // ── New Project ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: FilledButton.icon(
              onPressed: onNewProject,
              icon: const Icon(Feather.plus, size: 15),
              label: Text(Strings.of(context).newProject),
              style: FilledButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: theme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          // ── My Projects (compact list) ─────────────────────────────
          Expanded(
            child: _CompactProjectsList(
              projects: projects,
              onCreateNew: onNewProject,
              onTapProject: onTapProject,
              onDeleteProject: onDeleteProject,
              onEditProject: onEditProject,
              onUploadProject: onUploadProject,
              onUpdateProject: onUpdateProject,
              onDeleteCloudProject: onDeleteCloudProject,
              onRetry: onRetryProjects,
            ),
          ),

          // ── Bottom actions ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: theme.divider, height: 1),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                _NavItem(
                  icon: Feather.file,
                  label: Strings.of(context).importFile,
                  selected: false,
                  theme: theme,
                  flagship: flagship,
                  onTap: onImport,
                ),
                _NavItem(
                  icon: Icons.palette_outlined,
                  label: Strings.of(context).theme,
                  selected: false,
                  theme: theme,
                  flagship: flagship,
                  onTap: onTheme,
                ),
                _NavItem(
                  icon: Feather.info,
                  label: Strings.of(context).about,
                  selected: false,
                  theme: theme,
                  flagship: flagship,
                  onTap: onAbout,
                ),
                if (!subscription.isPro)
                  _NavItem(
                    icon: MaterialCommunityIcons.crown,
                    label: Strings.of(context).getPro,
                    selected: false,
                    theme: theme,
                    flagship: flagship,
                    onTap: onPro,
                    accentColor: Colors.orange,
                  ),
                _NavItem(
                  icon: Icons.feedback_outlined,
                  label: Strings.of(context).feedback,
                  selected: false,
                  theme: theme,
                  flagship: flagship,
                  onTap: onFeedback,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: KofiSupportButton(),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeader(FlagshipConfig? flagship) {
    final hasFlagship = flagship != null && flagship.isFlagship;
    return Stack(
      children: [
        // Flagship gradient tint
        if (hasFlagship && flagship.appBarGradient != null)
          Positioned.fill(
            child: Opacity(
              opacity: 0.18,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: flagship.appBarGradient),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Picell',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final AppTheme theme;
  final FlagshipConfig? flagship;
  final VoidCallback onTap;
  final Color? accentColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.theme,
    required this.flagship,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = accentColor ?? theme.primaryColor;
    final iconColor = selected ? activeColor : theme.textSecondary;

    final iconWidget = Icon(icon, size: 18, color: iconColor);

    // Optional glow for flagship active items
    final displayIcon = (flagship != null && flagship!.enableIconGlow && selected)
        ? DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: (flagship!.iconGlowColor ?? activeColor).withValues(alpha: 0.55),
                  blurRadius: flagship!.iconGlowRadius * 0.7,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: iconWidget,
          )
        : iconWidget;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            displayIcon,
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? activeColor : theme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Static header above the discovery carousel + community feed. Used to
/// branch between "My Projects"/"Community" per the active tab — now always
/// just "Discover", since "My Projects" lives permanently in the sidebar and
/// there's no tab to switch away from it.
class _DesktopContentHeader extends StatelessWidget {
  final AppTheme theme;
  final FlagshipConfig? flagship;

  const _DesktopContentHeader({
    required this.theme,
    required this.flagship,
  });

  @override
  Widget build(BuildContext context) {
    final hasFlagshipGradient = flagship != null && flagship!.appBarGradient != null;
    final titleColor = hasFlagshipGradient ? Colors.white : theme.textPrimary;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: hasFlagshipGradient
          ? BoxDecoration(
              gradient: flagship!.appBarGradient,
              border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1)),
            )
          : BoxDecoration(
              color: theme.surface.withValues(alpha: 0.85),
              border: Border(bottom: BorderSide(color: theme.divider, width: 1)),
            ),
      child: Row(
        children: [
          Text(
            'Discover',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: titleColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Compact "My Projects" list — shared by the desktop sidebar and the ─────
// ── mobile "My Projects" section. ───────────────────────────────────────────

/// Name filter + recently-edited-first sort for the compact project list.
/// (Full sort options existed here before the sidebar/mobile-list redesign;
/// dropped to just "recent" since there's no room for a sort menu at this
/// width — see [_CompactProjectsList].)
List<Project> _filterRecentProjects(List<Project> source, String query) {
  final trimmed = query.trim().toLowerCase();
  final result =
      trimmed.isEmpty ? List<Project>.of(source) : source.where((p) => p.name.toLowerCase().contains(trimmed)).toList();

  result.sort((a, b) => b.editedAt.compareTo(a.editedAt));
  return result;
}

/// Compact "My Projects" list (search toggle + [SidebarProjectListItem]s).
/// Used both in the desktop sidebar (wrapped in `Expanded`, fills the
/// remaining sidebar height) and above the mobile community feed (wrapped
/// in a fixed-height `SizedBox`, scrolls internally within that box).
class _CompactProjectsList extends HookWidget {
  final AsyncValue<List<Project>> projects;
  final VoidCallback onCreateNew;
  final void Function(Project) onTapProject;
  final void Function(Project) onDeleteProject;
  final void Function(Project) onEditProject;
  final void Function(Project) onUploadProject;
  final void Function(Project) onUpdateProject;
  final void Function(Project) onDeleteCloudProject;
  final VoidCallback onRetry;

  /// Mobile shows a quick "+ New" text button next to the title (the FAB is
  /// further away); the desktop sidebar already has a prominent "New
  /// Project" button just below, so it skips this to avoid duplication.
  final bool showNewButton;

  const _CompactProjectsList({
    required this.projects,
    required this.onCreateNew,
    required this.onTapProject,
    required this.onDeleteProject,
    required this.onEditProject,
    required this.onUploadProject,
    required this.onUpdateProject,
    required this.onDeleteCloudProject,
    required this.onRetry,
    this.showNewButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final query = useState('');
    final showSearch = useState(false);
    final colorScheme = Theme.of(context).colorScheme;

    useEffect(() {
      void listener() => query.value = searchController.text;
      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);

    return projects.when(
      data: (allProjects) {
        final filtered = _filterRecentProjects(allProjects, query.value);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 6, 4),
              child: Row(
                children: [
                  Expanded(
                    child: showSearch.value
                        ? TextField(
                            controller: searchController,
                            autofocus: true,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: Strings.of(context).search,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              Text(
                                Strings.of(context).myProjects,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '(${allProjects.length})',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                              ),
                            ],
                          ),
                  ),
                  if (showNewButton && !showSearch.value)
                    TextButton.icon(
                      onPressed: onCreateNew,
                      icon: const Icon(Feather.plus, size: 14),
                      label: Text(Strings.of(context).create),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                    ),
                  IconButton(
                    icon: Icon(showSearch.value ? Feather.x : Feather.search, size: 16),
                    onPressed: () {
                      showSearch.value = !showSearch.value;
                      if (!showSearch.value) searchController.clear();
                    },
                  ),
                ],
              ),
            ),
            if (allProjects.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
                child: Column(
                  children: [
                    Icon(
                      Feather.folder,
                      size: 28,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(Strings.of(context).noProjectsYet, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    TextButton(onPressed: onCreateNew, child: Text(Strings.of(context).createOne)),
                  ],
                ),
              )
            else if (filtered.isEmpty)
              Expanded(child: _NoSearchResults(query: query.value))
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final project = filtered[index];
                    return SidebarProjectListItem(
                      key: ValueKey(project.id),
                      project: project,
                      onTap: () => onTapProject(project),
                      onDeleteProject: onDeleteProject,
                      onEditProject: onEditProject,
                      onUploadProject: onUploadProject,
                      onUpdateProject: onUpdateProject,
                      onDeleteCloudProject: onDeleteCloudProject,
                    );
                  },
                ),
              ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Strings.of(context).anErrorOccurred,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: Text(Strings.of(context).tryAgain)),
          ],
        ),
      ),
    );
  }
}

class _NoSearchResults extends StatelessWidget {
  final String query;

  const _NoSearchResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Feather.search,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No projects match "$query"',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// "Support on Ko-fi" link. The full variant is a warm gradient pill used at
/// the bottom of the desktop sidebar; [compact] renders just a tinted coffee
/// icon for the crowded mobile app bar. Ko-fi's brand red is used for both so
/// the button reads as external support, not another app action.
class KofiSupportButton extends StatelessWidget {
  final bool compact;

  const KofiSupportButton({super.key, this.compact = false});

  static const _kofiRed = Color(0xFFFF5E5B);

  void _open() => launchUrlString(Constants.kofiUrl);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        tooltip: Strings.of(context).supportOnKofi,
        icon: const Icon(MaterialCommunityIcons.coffee_outline, color: _kofiRed),
        style: IconButton.styleFrom(
          backgroundColor: _kofiRed.withValues(alpha: 0.12),
        ),
        onPressed: _open,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kofiRed, Color(0xFFFF8C69)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _kofiRed.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(MaterialCommunityIcons.coffee, size: 17, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Support on Ko-fi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Cloud / Community tab ──────────────────────────────────────────────────

class CloudProjectsView extends HookConsumerWidget {
  final AppTheme theme;
  final UserSubscription subscription;

  /// Extra slivers rendered above the search bar — the discovery carousel
  /// on both platforms, plus (on mobile) the compact "My Projects" section.
  /// Kept as a parameter rather than a separate "no chrome" widget variant
  /// so this single scroll view can host everything above the community
  /// feed without nesting one scrollable inside another.
  final List<Widget> leadingSlivers;

  const CloudProjectsView({
    super.key,
    required this.theme,
    required this.subscription,
    this.leadingSlivers = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityState = ref.watch(communityProjectsProvider);
    final searchController = useTextEditingController();
    final scrollController = useScrollController();
    final showSearch = useState(false);
    final selectedSort = useState('recent');

    // Handle infinite scroll
    useEffect(() {
      void onScroll() {
        if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
          ref.read(communityProjectsProvider.notifier).loadMore();
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        ...leadingSlivers,

        // Search and Sort Bar
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: showSearch.value
                      ? TextField(
                          controller: searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: Strings.of(context).searchProjects,
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onSubmitted: (value) {
                            ref.read(communityProjectsProvider.notifier).searchProjects(value);
                          },
                        )
                      : Text(
                          Strings.of(context).discoverAmazingPixelArt,
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    showSearch.value ? Icons.close : Icons.search,
                    color: theme.activeIcon,
                  ),
                  onPressed: () {
                    showSearch.value = !showSearch.value;
                    if (!showSearch.value) {
                      searchController.clear();
                      ref.read(communityProjectsProvider.notifier).searchProjects('');
                    }
                  },
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.sort, color: theme.activeIcon),
                  tooltip: Strings.of(context).sortBy,
                  onSelected: (value) {
                    selectedSort.value = value;
                    ref.read(communityProjectsProvider.notifier).setSortOrder(value);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'recent', child: Text(Strings.of(context).mostRecent)),
                    PopupMenuItem(value: 'popular', child: Text(Strings.of(context).mostPopular)),
                    PopupMenuItem(value: 'views', child: Text(Strings.of(context).mostViewed)),
                    PopupMenuItem(value: 'likes', child: Text(Strings.of(context).mostLiked)),
                    PopupMenuItem(value: 'title', child: Text(Strings.of(context).titleAZ)),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: theme.activeIcon),
                  onPressed: () => ref.read(communityProjectsProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
        ),

        // Filter chips
        if (communityState.popularTags.isNotEmpty)
          SliverToBoxAdapter(child: _buildFilterChips(context, ref, communityState, theme)),

        // Featured projects section
        SliverToBoxAdapter(child: _buildFeaturedSection(context, ref, theme)),

        // Main projects grid
        ..._buildProjectsGridSlivers(
          context,
          ref,
          communityState,
          theme,
          subscription,
        ),
      ],
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    WidgetRef ref,
    CommunityProjectsState state,
    AppTheme theme,
  ) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.popularTags.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(Strings.of(context).all),
                selected: state.filters.tags.isEmpty,
                selectedColor: theme.primaryColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: state.filters.tags.isEmpty ? theme.primaryColor : theme.textPrimary,
                ),
                iconTheme: IconThemeData(
                  color: state.filters.tags.isEmpty ? theme.primaryColor : theme.textPrimary,
                ),
                onSelected: (selected) {
                  if (selected) {
                    ref.read(communityProjectsProvider.notifier).clearFilters();
                  }
                },
              ),
            );
          }

          final tag = state.popularTags[index - 1];
          final isSelected = state.filters.tags.contains(tag.slug);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(tag.name),
              selected: isSelected,
              selectedColor: theme.primaryColor.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? theme.primaryColor : theme.textPrimary,
              ),
              iconTheme: IconThemeData(
                color: isSelected ? theme.primaryColor : theme.textPrimary,
              ),
              onSelected: (selected) {
                final newTags = List<String>.from(state.filters.tags);
                if (selected) {
                  newTags.add(tag.slug);
                } else {
                  newTags.remove(tag.slug);
                }
                ref.read(communityProjectsProvider.notifier).filterByTags(newTags);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedSection(
    BuildContext context,
    WidgetRef ref,
    AppTheme theme,
  ) {
    final featuredProjects = ref.watch(featuredProjectsProvider);

    return featuredProjects.when(
      data: (projects) {
        if (projects.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.star, color: theme.warning, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    Strings.of(context).featuredProjects,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    child: CommunityProjectCard(
                      project: projects[index],
                      isFeatured: true,
                      onTap: () => _openProjectDetail(context, ref, projects[index], subscription),
                      onLike: (project) => ref.read(communityProjectsProvider.notifier).toggleLike(project),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  /// Returns the sliver(s) for the main community grid — loading/error/empty
  /// states each fill the remaining viewport, and the populated state is a
  /// [SliverMasonryGrid] whose column count reacts to the sliver's own
  /// cross-axis extent (via [SliverLayoutBuilder]) rather than the full
  /// screen width, so it stays correct when this view sits beside a sidebar.
  List<Widget> _buildProjectsGridSlivers(
    BuildContext context,
    WidgetRef ref,
    CommunityProjectsState state,
    AppTheme theme,
    UserSubscription subscription,
  ) {
    if (state.isLoading && state.projects.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (state.error != null && state.projects.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Feather.alert_circle,
                  size: 64,
                  color: theme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  Strings.of(context).errorLoadingProjects,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.error!,
                  style: TextStyle(color: theme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(Strings.of(context).tryAgain),
                  onPressed: () => ref.read(communityProjectsProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (state.projects.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Feather.search,
                  size: 64,
                  color: theme.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No projects found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search or filters',
                  style: TextStyle(color: theme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.crossAxisExtent;
            // More granular than before so typical desktop content widths
            // (screen minus the ~272px sidebar) land on 5-6 smaller cards
            // per row instead of maxing out at 3-5.
            final crossAxisCount = switch (width) {
              < 500 => 2,
              < 800 => 3,
              < 1000 => 4,
              < 1300 => 5,
              _ => 6,
            };

            return SliverMasonryGrid.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childCount: state.projects.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.projects.length) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final project = state.projects[index];
                return CommunityProjectCard(
                  key: ValueKey(project.id),
                  project: project,
                  onTap: () => _openProjectDetail(context, ref, project, subscription),
                  onLike: (project) => ref.read(communityProjectsProvider.notifier).toggleLike(project),
                  onUserTap: (username) {
                    ref.read(communityProjectsProvider.notifier).filterByUser(username);
                  },
                );
              },
            );
          },
        ),
      ),
    ];
  }

  void _openProjectDetail(
    BuildContext context,
    WidgetRef ref,
    ApiProject project,
    UserSubscription subscription,
  ) async {
    if (Random().nextInt(10) < 2 && !subscription.isPro) {
      await ref.read(interstitialAdProvider.notifier).showAdIfLoaded(() {});
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(project: project),
      ),
    );
  }
}
