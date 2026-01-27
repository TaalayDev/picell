import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

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
import '../widgets/app_icon.dart';
import '../widgets/dialogs/auth_dialog.dart';
import '../widgets/animated_pro_button.dart';
import '../widgets/animated_background.dart';
import '../widgets/community_project_card.dart' hide CheckerboardPainter;
import '../widgets/dialogs/delete_account_dialog.dart';
import '../widgets/dialogs/project_upload_dialog.dart' hide CheckerboardPainter;
import '../widgets/dialogs/feedback_prompt_dialog.dart';
import '../widgets/drop_target_overlay.dart';
import '../widgets/project/adaprive_project_grid.dart';
import '../widgets/subscription/subscription_menu.dart';
import '../widgets/theme_selector.dart';
import '../widgets.dart';
import '../widgets/theme_selector_sheet.dart';
import 'feedback_screen.dart';
import 'subscription_screen.dart';
import 'about_screen.dart';
import 'pixel_canvas_screen.dart';
import 'project_detail_screen.dart' hide CheckerboardPainter;
import 'tilemap_screen.dart';
import '../../features/node_tile_creator/ui/node_graph_screen.dart';

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
    final showProfileIcon = useState(false);

    final currentTheme = ref.watch(themeProvider).theme;

    final tabController = useTabController(initialLength: 2);

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

    final tabListener = useCallback(() {
      if (authState.isSignedIn && tabController.index == 1) {
        showProfileIcon.value = true;
      } else {
        showProfileIcon.value = false;
      }
    }, [authState, tabController]);

    useEffect(() {
      tabController.removeListener(tabListener);

      // Listen for tab changes
      tabController.addListener(tabListener);
      return null;
    }, [authState]);

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
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
              IconButton(
                tooltip: 'Choose Theme',
                icon: Icon(
                  Icons.palette_outlined,
                  color: currentTheme.activeIcon,
                ),
                onPressed: () => ThemeSelectorBottomSheet.show(context),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: showProfileIcon.value && authState.isSignedIn
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
                        shadowColor: Theme.of(context).shadowColor.withOpacity(0.3),
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
                        icon: const Icon(Feather.plus),
                        onPressed: () => _navigateToNewProject(context, ref, subscription),
                      ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SizedBox(
                  height: 58,
                  child: TabBar(
                    controller: tabController,
                    tabs: const [
                      Tab(
                        icon: Icon(Feather.hard_drive),
                        text: 'Local',
                      ),
                      Tab(
                        icon: Icon(Feather.cloud),
                        text: 'Cloud',
                      ),
                    ],
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToFeedback(context, ref),
            backgroundColor: Theme.of(context).colorScheme.primary,
            label: const Text('Feedback'),
            icon: const AppIcon(AppIcons.user_voice),
            tooltip: 'Leave Feedback',
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
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: [
                    // Local Projects Tab
                    _buildLocalProjectsTab(
                      context,
                      ref,
                      projects,
                      subscription,
                      overlayLoader,
                      authState,
                    ),

                    // Cloud Projects Tab
                    _buildCloudProjectsTab(context, ref, theme, subscription),
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
          message: Text(result.errorMessage ?? 'Failed to process ${result.fileName}'),
        );
        continue;
      }

      switch (result.type) {
        case DroppedFileType.project:
        case DroppedFileType.aseprite:
          if (result.project != null) {
            final loader = showLoader(
              context,
              loadingText: 'Importing ${result.fileName}...',
            );

            try {
              final newProject = await ref.read(projectsProvider.notifier).addProject(result.project!);
              if (context.mounted) {
                loader.remove();
                showTopFlushbar(
                  context,
                  message: Text('Imported "${result.project!.name}" successfully'),
                );
              }
            } catch (e) {
              if (context.mounted) {
                loader.remove();
                showTopFlushbar(
                  context,
                  message: Text('Failed to import: $e'),
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
              loadingText: 'Importing ${result.fileName}...',
            );

            try {
              final newProject = await ref.read(projectsProvider.notifier).addProject(project);
              if (context.mounted) {
                loader.remove();
                showTopFlushbar(
                  context,
                  message: Text('Imported "${project.name}" successfully'),
                );
              }
            } catch (e) {
              if (context.mounted) {
                loader.remove();
                showTopFlushbar(
                  context,
                  message: Text('Failed to import: $e'),
                );
              }
            }
          }
          break;

        case DroppedFileType.unknown:
          showTopFlushbar(
            context,
            message: Text('Unsupported file type: ${result.fileName}'),
          );
          break;
      }
    }
  }

  Widget _buildLocalProjectsTab(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<Project>> projects,
    UserSubscription subscription,
    ValueNotifier<OverlayEntry?> overlayLoader,
    AuthState authState,
  ) {
    return projects.when(
      data: (projects) => AdaptiveProjectGrid(
        projects: projects,
        onCreateNew: () => _navigateToNewProject(context, ref, subscription),
        onTapProject: (project) {
          _openProject(context, ref, project.id, overlayLoader);
        },
        onDeleteProject: (project) {
          ref.read(projectsProvider.notifier).deleteProject(project);
        },
        onEditProject: (project) {
          ref.read(projectsProvider.notifier).renameProject(project.id, project.name);
        },
        onUploadProject: (project) {
          _onUploadProject(context, ref, project, authState);
        },
        onUpdateProject: (project) {
          _onUpdateProject(context, ref, project, authState);
        },
        onDeleteCloudProject: (project) {
          _onDeleteCloudProject(context, ref, project, authState);
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Feather.alert_circle,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              Strings.of(context).anErrorOccurred,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Feather.refresh_cw, color: Theme.of(context).colorScheme.onPrimary),
              label: Text(Strings.of(context).tryAgain),
              onPressed: () => ref.refresh(projectsProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudProjectsTab(
    BuildContext context,
    WidgetRef ref,
    AppTheme theme,
    UserSubscription subscription,
  ) {
    return CloudProjectsView(
      theme: theme,
      subscription: subscription,
    );
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

        // Navigate to appropriate editor based on project type
        if (newProject.type == ProjectType.tileGenerator || newProject.type == ProjectType.tilemap) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TileMapScreen(project: newProject),
            ),
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PixelCanvasScreen(project: newProject),
            ),
          );
        }
      }
    }
  }

  void _openProject(
    BuildContext context,
    WidgetRef ref,
    int projectId,
    ValueNotifier<OverlayEntry?> loader,
  ) async {
    loader.value = showLoader(
      context,
      loadingText: Strings.of(context).openingProject,
    );

    final project = await ref.read(projectsProvider.notifier).getProject(projectId);

    if (project != null && context.mounted) {
      // Navigate to appropriate editor based on project type
      if (project.type == ProjectType.tileGenerator || project.type == ProjectType.tilemap) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TileMapScreen(project: project),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PixelCanvasScreen(project: project),
          ),
        );
      }
    }

    loader.value?.remove();
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
    if (authState.isSignedIn) {
      ProjectUploadDialog.show(context, project);
    } else {
      final auth = await AuthDialog.show(context);
      if (!context.mounted) return;
      if (auth == true) {
        ProjectUploadDialog.show(context, project);
      } else {
        showTopFlushbar(
          context,
          message: const Text('Please sign in to upload projects'),
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
    if (!authState.isSignedIn) {
      showTopFlushbar(
        context,
        message: const Text('Please sign in to update projects'),
      );
      return;
    }

    if (!project.isCloudSynced || project.remoteId == null) {
      showTopFlushbar(
        context,
        message: const Text('Project is not synced to cloud'),
      );
      return;
    }

    showTopFlushbar(
      context,
      message: const Text('Syncing project to cloud...'),
    );

    ref.read(projectUploadProvider.notifier).updateProject(localProject: project);
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
        message: const Text('Please sign in to remove cloud projects'),
      );
      return;
    }

    if (!project.isCloudSynced || project.remoteId == null) {
      showTopFlushbar(
        context,
        message: const Text('Project is not synced to cloud'),
      );
      return;
    }

    try {
      final loader = showLoader(
        context,
        loadingText: 'Removing from cloud...',
      );

      await ref.read(projectUploadProvider.notifier).deleteCloudProject(
            localProject: project,
          );

      if (context.mounted) {
        loader.remove();
        showTopFlushbar(
          context,
          message: const Text('Project removed from cloud successfully'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showTopFlushbar(
          context,
          message: Text('Failed to remove from cloud: $e'),
        );
      }
    }
  }
}

class CloudProjectsView extends HookConsumerWidget {
  final AppTheme theme;
  final UserSubscription subscription;

  const CloudProjectsView({
    super.key,
    required this.theme,
    required this.subscription,
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

    return Column(
      children: [
        // Search and Sort Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
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
                          hintText: 'Search projects...',
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
                        'Discover amazing pixel art',
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
                tooltip: 'Sort by',
                onSelected: (value) {
                  selectedSort.value = value;
                  ref.read(communityProjectsProvider.notifier).setSortOrder(value);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'recent', child: Text('Most Recent')),
                  const PopupMenuItem(value: 'popular', child: Text('Most Popular')),
                  const PopupMenuItem(value: 'views', child: Text('Most Viewed')),
                  const PopupMenuItem(value: 'likes', child: Text('Most Liked')),
                  const PopupMenuItem(value: 'title', child: Text('Title A-Z')),
                ],
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: theme.activeIcon),
                onPressed: () => ref.read(communityProjectsProvider.notifier).refresh(),
              ),
            ],
          ),
        ),

        // Filter chips
        if (communityState.popularTags.isNotEmpty) _buildFilterChips(context, ref, communityState, theme),

        // Featured projects section
        _buildFeaturedSection(context, ref, theme),

        // Main projects grid
        Expanded(
          child: _buildProjectsGrid(
            context,
            ref,
            communityState,
            scrollController,
            theme,
            subscription,
          ),
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
                label: const Text('All'),
                selected: state.filters.tags.isEmpty,
                selectedColor: theme.primaryColor.withOpacity(0.2),
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
              selectedColor: theme.primaryColor.withOpacity(0.2),
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
                    'Featured Projects',
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

  Widget _buildProjectsGrid(
    BuildContext context,
    WidgetRef ref,
    CommunityProjectsState state,
    ScrollController scrollController,
    AppTheme theme,
    UserSubscription subscription,
  ) {
    if (state.isLoading && state.projects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final adLoaded = ref.watch(interstitialAdProvider);

    if (state.error != null && state.projects.isEmpty) {
      return Center(
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
              'Error loading projects',
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
              label: const Text('Try Again'),
              onPressed: () => ref.read(communityProjectsProvider.notifier).refresh(),
            ),
          ],
        ),
      );
    }

    if (state.projects.isEmpty) {
      return Center(
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
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width < 600 ? 2 : (width < 1200 ? 3 : 5);

        return MasonryGridView.count(
          controller: scrollController,
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          padding: const EdgeInsets.all(16),
          itemCount: state.projects.length + (state.isLoadingMore ? 1 : 0),
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
    );
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
