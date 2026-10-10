import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../data/models/project_api_models.dart';
import '../../l10n/strings.dart';
import '../../config/constants.dart';
import '../../core.dart';
import '../../providers/community_projects_providers.dart';
import '../../providers/projects_provider.dart';
import '../../providers/providers.dart';
import '../../providers/auth_provider.dart';
import '../widgets/animated_background.dart';
import '../widgets/community_project_actions.dart';
import '../widgets/community_project_card.dart';
import '../widgets/painter/checkboard_painter.dart';
import '../widgets/theme_selector.dart';

class ProjectDetailScreen extends HookConsumerWidget {
  final ApiProject project;

  /// Rendered inside a dialog window (wide screens) instead of a full route.
  final bool asDialog;

  /// Projects shown alongside [project] in the list it was opened from.
  /// When it has more than one entry the screen offers previous / next.
  final List<ApiProject> siblings;

  /// Hero tag of the card [project] was opened from, if any.
  final String? heroTag;

  /// Width from which the detail view is presented as a dialog window.
  static const double wideBreakpoint = 900;

  const ProjectDetailScreen({
    super.key,
    required this.project,
    this.asDialog = false,
    this.siblings = const [],
    this.heroTag,
  });

  /// Opens [project]: a dialog window on wide screens, a pushed route on
  /// phones and narrow tablets. Both are [PageRoute]s so the thumbnail
  /// [Hero] flies from the card.
  static Future<void> show(
    BuildContext context,
    ApiProject project, {
    List<ApiProject> siblings = const [],
    String? heroTag,
  }) {
    if (MediaQuery.sizeOf(context).width >= wideBreakpoint) {
      return Navigator.of(context).push<void>(
        PageRouteBuilder<void>(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          pageBuilder: (_, __, ___) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: ProjectDetailScreen(
                  project: project,
                  asDialog: true,
                  siblings: siblings,
                  heroTag: heroTag,
                ),
              ),
            ),
          ),
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(curved), child: child),
            );
          },
        ),
      );
    }
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ProjectDetailScreen(project: project, siblings: siblings, heroTag: heroTag),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider).theme;
    final scrollController = useScrollController();
    final showAppBar = useState(true);

    // The project currently shown; changes when stepping through siblings.
    final selected = useState(project);
    final shown = selected.value;

    final projectDetail = ref.watch(communityProjectProvider(shown.id, includeData: true));
    final currentProject = projectDetail.valueOrNull ?? shown;

    final siblingIndex = siblings.indexWhere((p) => p.id == shown.id);
    void goTo(int index) {
      selected.value = siblings[index];
      if (scrollController.hasClients) scrollController.jumpTo(0);
    }

    final nav = _PreviewNav(
      // Only the originally tapped project has a card to fly back to.
      heroTag: shown.id == project.id ? heroTag : null,
      onPrev: siblingIndex > 0 ? () => goTo(siblingIndex - 1) : null,
      onNext: siblingIndex >= 0 && siblingIndex < siblings.length - 1 ? () => goTo(siblingIndex + 1) : null,
      position: siblingIndex >= 0 && siblings.length > 1 ? siblingIndex + 1 : null,
      total: siblings.length,
    );

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= ProjectDetailScreen.wideBreakpoint;
    final isMobile = screenWidth < 600;

    useEffect(() {
      if (isMobile) {
        void onScroll() {
          final isScrolled = scrollController.offset > 200;
          if (isScrolled != !showAppBar.value) {
            showAppBar.value = !isScrolled;
          }
        }

        scrollController.addListener(onScroll);
        return () => scrollController.removeListener(onScroll);
      }
      return null;
    }, [scrollController, isMobile]);

    // Keyboard: ←/→ step through siblings, Esc closes.
    Widget withKeyboard(Widget child) => CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowLeft): () => nav.onPrev?.call(),
            const SingleActivator(LogicalKeyboardKey.arrowRight): () => nav.onNext?.call(),
            const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).maybePop(),
          },
          child: Focus(autofocus: true, child: child),
        );

    if (asDialog) {
      final maxHeight = MediaQuery.sizeOf(context).height - 48;
      return withKeyboard(
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: theme.surface,
            child: SizedBox(
              height: maxHeight < 820 ? maxHeight : 820,
              child: _buildWideBody(context, ref, theme, currentProject, nav),
            ),
          ),
        ),
      );
    }

    return AnimatedBackground(
      child: Builder(builder: (context) {
        if (isWide) {
          return withKeyboard(_buildWideLayout(context, ref, theme, currentProject, nav));
        } else if (!isMobile) {
          return _buildTabletLayout(context, ref, theme, currentProject, nav);
        } else {
          return _buildMobileLayout(context, ref, theme, scrollController, showAppBar, currentProject, nav);
        }
      }),
    );
  }

  static const double _tabletMaxWidth = 760;

  /// Optimistic like; the notifier rolls the UI back on failure, we tell the
  /// user why the heart flipped back.
  Future<void> _toggleLike(BuildContext context, WidgetRef ref, ApiProject project) async {
    final failureMessage = Strings.of(context).error;
    final ok = await ref.read(communityProjectsProvider.notifier).toggleLike(project);
    if (!ok && context.mounted) AppNotification.error(context, failureMessage);
  }

  /// True when the signed-in user owns [project].
  bool _isAuthor(WidgetRef ref, ApiProject project) {
    final auth = ref.watch(authProvider);
    return auth.isSignedIn && auth.apiUser != null && auth.apiUser?.id == project.userId;
  }

  /// Wide screens: canvas on the left, details / author / actions in a side
  /// panel. Shown inside a dialog window via [ProjectDetailScreen.show], and
  /// as a plain full-screen page if the route is built directly at this width.
  Widget _buildWideLayout(
    BuildContext context,
    WidgetRef ref,
    AppTheme theme,
    ApiProject currentProject,
    _PreviewNav nav,
  ) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: theme.toolbarColor.withValues(alpha: 0.8),
        title: Text(
          currentProject.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: theme.textPrimary, fontSize: 20),
        ),
        actions: [
          _buildQuickActions(context, ref, currentProject, theme, isDesktop: true),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildWideBody(context, ref, theme, currentProject, nav),
    );
  }

  Widget _buildWideBody(
    BuildContext context,
    WidgetRef ref,
    AppTheme theme,
    ApiProject currentProject,
    _PreviewNav nav,
  ) {
    final sideWidth = MediaQuery.sizeOf(context).width < 1100 ? 340.0 : 400.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _buildPreviewPanel(
              nav: nav,
              context,
              ref,
              currentProject,
              theme,
              padding: const EdgeInsets.all(32),
              cellSize: 12,
            ),
          ),
        ),
        Container(
          width: sideWidth,
          decoration: BoxDecoration(
            color: theme.surface.withValues(alpha: 0.8),
            border: Border(left: BorderSide(color: theme.divider)),
          ),
          child: Column(
            children: [
              if (asDialog)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
                  child: Row(
                    children: [
                      const Spacer(),
                      _buildQuickActions(context, ref, currentProject, theme, isDesktop: true),
                      IconButton(
                        icon: Icon(Icons.close, color: theme.activeIcon),
                        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, asDialog ? 8 : 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLoadStatus(context, ref, currentProject, theme),
                      _buildProjectInfo(context, ref, currentProject, theme),
                      const SizedBox(height: 20),
                      _buildAuthorInfo(context, ref, currentProject, theme),
                      const SizedBox(height: 20),
                      _buildProjectActions(context, ref, currentProject, theme, isDesktop: true),
                      const SizedBox(height: 24),
                      if (currentProject.tags.isNotEmpty) ...[
                        _buildTags(context, currentProject, theme),
                        const SizedBox(height: 24),
                      ],
                      _buildRelatedProjects(context, ref, currentProject, theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tablet (600–900): pinned app bar, preview card, then one column of
  /// details, author and actions.
  Widget _buildTabletLayout(
    BuildContext context,
    WidgetRef ref,
    AppTheme theme,
    ApiProject currentProject,
    _PreviewNav nav,
  ) {
    final size = MediaQuery.sizeOf(context);
    final previewHeight = (size.height * 0.45).clamp(280.0, 520.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: theme.toolbarColor.withValues(alpha: 0.8),
            title: Text(
              currentProject.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: theme.textPrimary, fontSize: 18),
            ),
            actions: [
              _buildQuickActions(context, ref, currentProject, theme, isTablet: true),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _tabletMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLoadStatus(context, ref, currentProject, theme),
                      _buildPreviewPanel(
                          nav: nav,
                          context,
                          ref,
                          currentProject,
                          theme,
                          height: previewHeight,
                          padding: const EdgeInsets.all(28),
                          cellSize: 10),
                      const SizedBox(height: 24),
                      _buildProjectInfo(context, ref, currentProject, theme, isTablet: true),
                      const SizedBox(height: 20),
                      _buildAuthorInfo(context, ref, currentProject, theme, isTablet: true),
                      const SizedBox(height: 16),
                      _buildProjectActions(context, ref, currentProject, theme, isTablet: true),
                      const SizedBox(height: 24),
                      if (currentProject.tags.isNotEmpty) ...[
                        _buildTags(context, currentProject, theme, isTablet: true),
                        const SizedBox(height: 24),
                      ],
                      _buildRelatedProjects(context, ref, currentProject, theme, isTablet: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile: collapsing preview header whose height adapts to the viewport
  /// (so landscape phones aren't swallowed by it), single-column content and
  /// a sticky like / download bar for non-authors.
  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    AppTheme theme,
    ScrollController scrollController,
    ValueNotifier<bool> showAppBar,
    ApiProject currentProject,
    _PreviewNav nav,
  ) {
    final media = MediaQuery.of(context);
    final headerHeight = (media.size.height * 0.42).clamp(240.0, 360.0);
    final isAuthor = _isAuthor(ref, currentProject);

    return Scaffold(
      backgroundColor: Colors.transparent,
      bottomNavigationBar: isAuthor ? null : _buildMobileActionBar(context, ref, currentProject, theme),
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: headerHeight,
            floating: false,
            pinned: true,
            backgroundColor: theme.toolbarColor.withValues(alpha: 0.6),
            flexibleSpace: FlexibleSpaceBar(
              title: showAppBar.value
                  ? null
                  : Text(
                      currentProject.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: theme.textPrimary, fontSize: 16),
                    ),
              background: _buildPreviewPanel(
                nav: nav,
                context,
                ref,
                currentProject,
                theme,
                framed: false,
                padding: EdgeInsets.fromLTRB(
                  20,
                  media.padding.top + kToolbarHeight,
                  20,
                  20,
                ),
                cellSize: 8,
              ),
            ),
            actions: [
              _buildQuickActions(context, ref, currentProject, theme),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLoadStatus(context, ref, currentProject, theme),
                  _buildProjectInfo(context, ref, currentProject, theme),
                  const SizedBox(height: 20),
                  _buildAuthorInfo(context, ref, currentProject, theme),
                  const SizedBox(height: 20),
                  // Non-authors get the sticky bottom bar instead.
                  if (isAuthor) ...[
                    _buildProjectActions(context, ref, currentProject, theme),
                    const SizedBox(height: 20),
                  ],
                  if (currentProject.tags.isNotEmpty) ...[
                    _buildTags(context, currentProject, theme),
                    const SizedBox(height: 20),
                  ],
                  _buildRelatedProjects(context, ref, currentProject, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Progress / error strip for the full-detail fetch. The screen renders
  /// from the summary it was opened with, so without this a failed or
  /// not-found fetch would look like a successful load.
  Widget _buildLoadStatus(
    BuildContext context,
    WidgetRef ref,
    ApiProject project,
    AppTheme theme,
  ) {
    final provider = communityProjectProvider(project.id, includeData: true);
    final detail = ref.watch(provider);

    if (detail.isLoading && !detail.hasValue) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: LinearProgressIndicator(minHeight: 2),
      );
    }
    if (detail.hasError && !detail.hasValue) {
      final s = Strings.of(context);
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(
          color: theme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                detail.error.toString().replaceFirst('Exception: ', ''),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: theme.textPrimary, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(provider),
              child: Text(s.tryAgain),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMobileActionBar(
    BuildContext context,
    WidgetRef ref,
    ApiProject project,
    AppTheme theme,
  ) {
    final isDownloaded = ref.watch(isProjectDownloadedProvider(project.id));
    final localProject = ref.watch(localProjectByRemoteIdProvider(project.id));
    final liked = project.isLiked == true;
    const buttonSize = Size(0, 46);

    return Material(
      color: theme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _toggleLike(context, ref, project),
                icon: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                ),
                label: Text(formatCount(project.likeCount)),
                style: OutlinedButton.styleFrom(
                  minimumSize: buttonSize,
                  foregroundColor: liked ? Colors.red : theme.textPrimary,
                  backgroundColor: liked ? Colors.red.withValues(alpha: 0.1) : null,
                  side: BorderSide(
                    color: liked ? Colors.red.withValues(alpha: 0.4) : theme.divider,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isDownloaded) ...[
                OutlinedButton.icon(
                  onPressed: () => remixCommunityProject(context, ref, project, localProject),
                  icon: const Icon(Icons.call_split, size: 20),
                  label: Text(Strings.of(context).remixProject),
                  style: OutlinedButton.styleFrom(
                    minimumSize: buttonSize,
                    foregroundColor: theme.textPrimary,
                    side: BorderSide(color: theme.divider),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: isDownloaded
                      ? () => openDownloadedProject(context, ref, localProject)
                      : () => downloadCommunityProject(context, ref, project),
                  icon: Icon(
                    isDownloaded ? Icons.folder_open : Icons.download,
                    size: 20,
                  ),
                  label: Text(
                    isDownloaded ? Strings.of(context).openProject : Strings.of(context).download,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: buttonSize,
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteProject(
    BuildContext context,
    WidgetRef ref,
    ApiProject currentProject,
  ) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(Strings.of(context).deletingProject),
            ],
          ),
        ),
      );

      final result = await ref.read(communityProjectsProvider.notifier).deleteProject(currentProject);
      if (!context.mounted) return;

      if (result) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        AppNotification.success(
          context,
          Strings.of(context).projectDeletedSuccessfully,
        );
      } else {
        Navigator.of(context).pop(); // Hide loading
        AppNotification.error(
          context,
          Strings.of(context).failedToDeleteProject,
        );
      }
    } catch (e) {
      // Hide loading
      if (context.mounted) {
        Navigator.of(context).pop();
        AppNotification.error(
          context,
          Strings.of(context).failedToDeleteProjectWithError(e.toString()),
        );
      }
    }
  }

  Widget _buildQuickActions(
    BuildContext context,
    WidgetRef ref,
    ApiProject currentProject,
    AppTheme theme, {
    bool isDesktop = false,
    bool isTablet = false,
  }) {
    final authState = ref.watch(authProvider);
    final isAuthor =
        authState.isSignedIn && authState.apiUser != null && (authState.apiUser?.id == currentProject.userId);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Like button (hidden for author's own project)
        if (!isAuthor) ...[
          IconButton(
            icon: Icon(
              currentProject.isLiked == true ? Icons.favorite : Icons.favorite_border,
              color: currentProject.isLiked == true ? Colors.red : theme.activeIcon,
            ),
            onPressed: () {
              _toggleLike(context, ref, currentProject);
            },
            tooltip: currentProject.isLiked == true ? Strings.of(context).unlike : Strings.of(context).like,
          ),
        ],

        // Share button
        IconButton(
          icon: Icon(Icons.share, color: theme.activeIcon),
          onPressed: () => shareCommunityProject(context, currentProject),
          tooltip: Strings.of(context).share,
        ),

        // Copy link button
        IconButton(
          icon: Icon(Icons.link, color: theme.activeIcon),
          onPressed: () => _copyProjectLink(context, currentProject),
          tooltip: Strings.of(context).copyLink,
        ),

        // Report (hidden for the author's own project)
        if (!isAuthor)
          IconButton(
            icon: Icon(Icons.flag_outlined, color: theme.activeIcon),
            onPressed: () => _reportProject(context, ref, currentProject),
            tooltip: Strings.of(context).report,
          ),

        // Author controls
        if (isAuthor) ...[
          // Visibility toggle button
          IconButton(
            icon: Icon(
              currentProject.isPublic ? Icons.public : Icons.lock,
              color: currentProject.isPublic ? theme.success : theme.warning,
            ),
            onPressed: () => _toggleVisibility(context, ref, currentProject),
            tooltip: currentProject.isPublic ? Strings.of(context).makePrivate : Strings.of(context).makePublic,
          ),

          // Delete button
          IconButton(
            icon: Icon(Icons.delete, color: theme.error),
            onPressed: () async {
              final result = await _showDeleteDialog(context, ref, currentProject);
              if (result == true) {
                _deleteProject(context, ref, currentProject);
              }
            },
            tooltip: Strings.of(context).deleteProject,
          ),
        ],

        // More options
        // PopupMenuButton<String>(
        //   icon: Icon(Icons.more_vert, color: theme.activeIcon),
        //   tooltip: 'More Options',
        //   itemBuilder: (context) => [
        //     if (!isAuthor) ...[
        //       const PopupMenuItem(
        //         value: 'download',
        //         child: Row(
        //           children: [
        //             Icon(Icons.download),
        //             SizedBox(width: 8),
        //             Text('Download'),
        //           ],
        //         ),
        //       ),
        //       const PopupMenuItem(
        //         value: 'save',
        //         child: Row(
        //           children: [
        //             Icon(Icons.bookmark_border),
        //             SizedBox(width: 8),
        //             Text('Save to Favorites'),
        //           ],
        //         ),
        //       ),
        //       const PopupMenuItem(
        //         value: 'follow',
        //         child: Row(
        //           children: [
        //             Icon(Icons.person_add),
        //             SizedBox(width: 8),
        //             Text('Follow Artist'),
        //           ],
        //         ),
        //       ),
        //       const PopupMenuDivider(),
        //       const PopupMenuItem(
        //         value: 'report',
        //         child: Row(
        //           children: [
        //             Icon(Icons.flag, color: Colors.orange),
        //             SizedBox(width: 8),
        //             Text('Report'),
        //           ],
        //         ),
        //       ),
        //     ] else ...[
        //       const PopupMenuItem(
        //         value: 'edit',
        //         child: Row(
        //           children: [
        //             Icon(Icons.edit),
        //             SizedBox(width: 8),
        //             Text('Edit Project'),
        //           ],
        //         ),
        //       ),
        //       const PopupMenuItem(
        //         value: 'analytics',
        //         child: Row(
        //           children: [
        //             Icon(Icons.analytics),
        //             SizedBox(width: 8),
        //             Text('View Analytics'),
        //           ],
        //         ),
        //       ),
        //       const PopupMenuDivider(),
        //       PopupMenuItem(
        //         value: 'visibility',
        //         child: Row(
        //           children: [
        //             Icon(currentProject.isPublic ? Icons.lock : Icons.public),
        //             const SizedBox(width: 8),
        //             Text(currentProject.isPublic ? 'Make Private' : 'Make Public'),
        //           ],
        //         ),
        //       ),
        //       const PopupMenuItem(
        //         value: 'delete',
        //         child: Row(
        //           children: [
        //             Icon(Icons.delete, color: Colors.red),
        //             SizedBox(width: 8),
        //             Text('Delete Project', style: TextStyle(color: Colors.red)),
        //           ],
        //         ),
        //       ),
        //     ],
        //   ],
        //   onSelected: (value) async {
        //     switch (value) {
        //       case 'download':
        //         downloadCommunityProject(context, ref, currentProject);
        //         break;
        //       case 'save':
        //         _saveToFavorites(context, ref, currentProject);
        //         break;
        //       case 'follow':
        //         _followArtist(context, ref, currentProject);
        //         break;
        //       case 'report':
        //         _showReportDialog(context);
        //         break;
        //       case 'edit':
        //         _editProject(context, ref, currentProject);
        //         break;
        //       case 'analytics':
        //         _showAnalytics(context, ref, currentProject);
        //         break;
        //       case 'visibility':
        //         _toggleVisibility(context, ref, currentProject);
        //         break;
        //       case 'delete':
        //         final result = await _showDeleteDialog(context, ref, currentProject);
        //         if (result == true) {
        //           _deleteProject(context, ref, currentProject);
        //         }
        //         break;
        //     }
        //   },
        // ),
      ],
    );
  }

  /// Shared preview used by every breakpoint: the pixel canvas centred on a
  /// checkerboard, tap-to-zoom, size + zoom hint, and the featured badge.
  Widget _buildPreviewPanel(
    BuildContext context,
    WidgetRef ref,
    ApiProject project,
    AppTheme theme, {
    double? height,
    EdgeInsets padding = const EdgeInsets.all(24),
    double cellSize = 10,
    bool framed = true,
    _PreviewNav? nav,
  }) {
    final s = Strings.of(context);
    final heroTag = nav?.heroTag;
    final token = ref.read(localStorageProvider).token;
    final headers = (token != null && token.isNotEmpty) ? {'Authorization': 'Bearer $token'} : null;

    final canvas = DecoratedBox(
      decoration: BoxDecoration(
        color: theme.canvasBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: CheckerboardPainter(
                cellSize: cellSize,
                color1: Colors.grey.shade100,
                color2: Colors.grey.shade50,
              ),
            ),
            CachedNetworkImage(
              imageUrl: project.thumbnailUrl,
              httpHeaders: headers,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              ),
              errorWidget: (context, url, error) => Icon(
                Icons.broken_image_outlined,
                color: theme.error,
                size: 48,
              ),
            ),
          ],
        ),
      ),
    );

    return Container(
      height: height,
      decoration: framed
          ? BoxDecoration(
              color: theme.surface.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.surface,
                  theme.surface.withValues(alpha: 0.0),
                ],
              ),
            ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: padding,
            child: Center(
              child: GestureDetector(
                onTap: () => _openFullscreenPreview(context, project, headers),
                child: AspectRatio(
                  aspectRatio: project.width / project.height,
                  child: heroTag == null ? canvas : Hero(tag: heroTag, child: canvas),
                ),
              ),
            ),
          ),
          if (project.isFeatured)
            Positioned(
              top: framed ? 16 : MediaQuery.paddingOf(context).top + 8,
              left: 16,
              child: _buildFeaturedBadge(context, theme),
            ),
          if (nav?.onPrev != null)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _NavArrow(icon: Icons.chevron_left, tooltip: s.previousProject, onTap: nav!.onPrev!),
              ),
            ),
          if (nav?.onNext != null)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _NavArrow(icon: Icons.chevron_right, tooltip: s.nextProject, onTap: nav!.onNext!),
              ),
            ),
          if (nav?.position != null)
            Positioned(
              left: 12,
              bottom: 12,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${nav!.position} / ${nav.total}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 12,
            bottom: 12,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.zoom_out_map, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${project.width}×${project.height}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullscreenPreview(
    BuildContext context,
    ApiProject project,
    Map<String, String>? headers,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (_, __, ___) => _FullscreenPreview(project: project, httpHeaders: headers),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Widget _buildFeaturedBadge(BuildContext context, AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.warning,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            Strings.of(context).featured,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectInfo(
    BuildContext context,
    WidgetRef ref,
    ApiProject currentProject,
    AppTheme theme, {
    bool isDesktop = false,
    bool isTablet = false,
  }) {
    final titleSize = isDesktop ? 28.0 : (isTablet ? 24.0 : 20.0);
    final descriptionSize = isDesktop ? 18.0 : (isTablet ? 16.0 : 14.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentProject.title,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),

        if (currentProject.description != null && currentProject.description!.isNotEmpty) ...[
          SizedBox(height: isDesktop ? 16 : 12),
          Text(
            currentProject.description!,
            style: TextStyle(
              fontSize: descriptionSize,
              color: theme.textSecondary,
              height: 1.5,
            ),
          ),
        ],

        SizedBox(height: isDesktop ? 20 : 16),

        // Project dimensions and stats
        if (isDesktop || isTablet) ...[
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildInfoCard(
                      context,
                      icon: Feather.grid,
                      label: Strings.of(context).size,
                      value: '${currentProject.width} × ${currentProject.height}',
                      color: theme.primaryColor,
                      isLarge: isDesktop,
                    ),
                    _buildInfoCard(
                      context,
                      icon: Icons.visibility,
                      label: Strings.of(context).views,
                      value: formatCount(currentProject.viewCount),
                      color: theme.accentColor,
                      isLarge: isDesktop,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildInfoCard(
                      context,
                      icon: Icons.download,
                      label: Strings.of(context).downloads,
                      value: formatCount(currentProject.downloadCount),
                      color: theme.success,
                      isLarge: isDesktop,
                    ),
                    if (currentProject.publishedAt != null)
                      _buildInfoCard(
                        context,
                        icon: Feather.clock,
                        label: Strings.of(context).published,
                        value: formatRelativeDate(context, currentProject.publishedAt!),
                        color: theme.textSecondary,
                        isLarge: isDesktop,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildInfoCard(
                context,
                icon: Feather.grid,
                label: Strings.of(context).size,
                value: '${currentProject.width} × ${currentProject.height}',
                color: theme.primaryColor,
              ),
              _buildInfoCard(
                context,
                icon: Icons.visibility,
                label: Strings.of(context).views,
                value: formatCount(currentProject.viewCount),
                color: theme.accentColor,
              ),
              _buildInfoCard(
                context,
                icon: Icons.download,
                label: Strings.of(context).downloads,
                value: formatCount(currentProject.downloadCount),
                color: theme.success,
              ),
              if (currentProject.publishedAt != null)
                _buildInfoCard(
                  context,
                  icon: Feather.clock,
                  label: Strings.of(context).published,
                  value: formatRelativeDate(context, currentProject.publishedAt!),
                  color: theme.textSecondary,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isLarge = false,
  }) {
    final iconSize = isLarge ? 14.0 : 14.0;
    final labelSize = isLarge ? 12.0 : 11.0;
    final valueSize = isLarge ? 14.0 : 13.0;
    final padding = isLarge ? 12.0 : 8.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.75),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isLarge ? 16 : 12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          SizedBox(width: isLarge ? 12 : 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: labelSize,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: valueSize,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorInfo(
    BuildContext context,
    WidgetRef ref,
    ApiProject currentProject,
    AppTheme theme, {
    bool isDesktop = false,
    bool isTablet = false,
  }) {
    final avatarRadius = isDesktop ? 28.0 : (isTablet ? 26.0 : 24.0);
    final nameSize = isDesktop ? 18.0 : (isTablet ? 16.0 : 16.0);
    final usernameSize = isDesktop ? 16.0 : (isTablet ? 14.0 : 14.0);
    final padding = isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0);

    final username = currentProject.username;
    final radius = BorderRadius.circular(isDesktop ? 20 : 16);

    // Tapping the author shows their projects in the community grid.
    return Material(
      color: theme.surface,
      elevation: 1,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: username == null
            ? null
            : () {
                ref.read(communityProjectsProvider.notifier).filterByUser(username);
                Navigator.of(context).pop();
              },
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: theme.primaryColor,
                backgroundImage: (currentProject.avatarUrl?.isNotEmpty ?? false)
                    ? CachedNetworkImageProvider(currentProject.avatarUrl!)
                    : null,
                child: (currentProject.avatarUrl?.isNotEmpty ?? false)
                    ? null
                    : Text(
                        (currentProject.displayName ?? currentProject.username ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          color: theme.onPrimary,
                          fontSize: avatarRadius * 0.7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              SizedBox(width: isDesktop ? 20 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentProject.displayName ?? currentProject.username ?? Strings.of(context).unknownArtist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: nameSize,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                    if (currentProject.username != null) ...[
                      SizedBox(height: isDesktop ? 6 : 4),
                      Text(
                        '@${currentProject.username}',
                        style: TextStyle(
                          fontSize: usernameSize,
                          color: theme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (username != null) Icon(Icons.chevron_right, color: theme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectActions(
    BuildContext context,
    WidgetRef ref,
    ApiProject currentProject,
    AppTheme theme, {
    bool isDesktop = false,
    bool isTablet = false,
  }) {
    final authState = ref.watch(authProvider);
    final isAuthor = authState.isSignedIn && authState.user != null && (authState.apiUser?.id == currentProject.userId);

    final isDownloaded = ref.watch(isProjectDownloadedProvider(currentProject.id));
    final localProject = ref.watch(localProjectByRemoteIdProvider(currentProject.id));

    if (isAuthor) {
      // Author controls
      if (isDesktop) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _editProject(context, ref, currentProject),
                icon: const Icon(Icons.edit),
                label: Text(Strings.of(context).editProject),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleVisibility(context, ref, currentProject),
                    icon: Icon(currentProject.isPublic ? Icons.public : Icons.lock),
                    label: Text(currentProject.isPublic ? Strings.of(context).public : Strings.of(context).private),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: currentProject.isPublic ? theme.success : theme.warning,
                      ),
                      foregroundColor: currentProject.isPublic ? theme.success : theme.warning,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAnalytics(context, ref, currentProject),
                    icon: const Icon(Icons.analytics),
                    label: Text(Strings.of(context).analytics),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      } else {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _editProject(context, ref, currentProject),
                icon: const Icon(Icons.edit),
                label: Text(Strings.of(context).editProject),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.onPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleVisibility(context, ref, currentProject),
                    icon: Icon(currentProject.isPublic ? Icons.public : Icons.lock),
                    label: Text(currentProject.isPublic ? Strings.of(context).public : Strings.of(context).private),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: currentProject.isPublic ? theme.success : theme.warning,
                      ),
                      foregroundColor: currentProject.isPublic ? theme.success : theme.warning,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAnalytics(context, ref, currentProject),
                    icon: const Icon(Icons.analytics),
                    label: Text(Strings.of(context).stats),
                  ),
                ),
              ],
            ),
          ],
        );
      }
    } else {
      // Non-author controls (like/comment/download)
      if (isDesktop) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _toggleLike(context, ref, currentProject);
                },
                icon: Icon(
                  currentProject.isLiked == true ? Icons.favorite : Icons.favorite_border,
                  color: currentProject.isLiked == true ? Colors.red : null,
                ),
                label: Text(Strings.of(context).likeCountLabel(formatCount(currentProject.likeCount))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentProject.isLiked == true ? Colors.red.withValues(alpha: 0.1) : theme.surface,
                  foregroundColor: currentProject.isLiked == true ? Colors.red : theme.textPrimary,
                  side: BorderSide(
                    color: currentProject.isLiked == true ? Colors.red.withValues(alpha: 0.3) : theme.divider,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (isDownloaded) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => openDownloadedProject(context, ref, localProject),
                  icon: const Icon(Icons.folder_open),
                  label: Text(Strings.of(context).openProject),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => remixCommunityProject(context, ref, currentProject, localProject),
                  icon: const Icon(Icons.call_split),
                  label: Text(Strings.of(context).remixProject),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => downloadCommunityProject(context, ref, currentProject),
                  icon: const Icon(Icons.download),
                  label: Text(Strings.of(context).download),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        );
      } else {
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _toggleLike(context, ref, currentProject);
                    },
                    icon: Icon(
                      currentProject.isLiked == true ? Icons.favorite : Icons.favorite_border,
                      color: currentProject.isLiked == true ? Colors.red : null,
                    ),
                    label: Text(formatCount(currentProject.likeCount)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          currentProject.isLiked == true ? Colors.red.withValues(alpha: 0.1) : theme.surface,
                      foregroundColor: currentProject.isLiked == true ? Colors.red : theme.textPrimary,
                      side: BorderSide(
                        color: currentProject.isLiked == true ? Colors.red.withValues(alpha: 0.3) : theme.divider,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isDownloaded) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    openDownloadedProject(context, ref, localProject);
                  },
                  icon: const Icon(Icons.folder_open),
                  label: Text(Strings.of(context).openProject),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => remixCommunityProject(context, ref, currentProject, localProject),
                  icon: const Icon(Icons.call_split),
                  label: Text(Strings.of(context).remixProject),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => downloadCommunityProject(context, ref, currentProject),
                  icon: const Icon(Icons.download),
                  label: Text(Strings.of(context).downloadProject),
                ),
              ),
            ],
          ],
        );
      }
    }
  }

  Widget _buildTags(
    BuildContext context,
    ApiProject currentProject,
    AppTheme theme, {
    bool isDesktop = false,
    bool isTablet = false,
  }) {
    final titleSize = isDesktop ? 20.0 : (isTablet ? 18.0 : 18.0);
    final tagSize = isDesktop ? 14.0 : (isTablet ? 12.0 : 12.0);
    final tagPadding = isDesktop ? 16.0 : (isTablet ? 14.0 : 12.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Strings.of(context).tags,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        Wrap(
          spacing: isDesktop ? 12 : 8,
          runSpacing: isDesktop ? 12 : 8,
          children: currentProject.tags.map((tag) {
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: tagPadding,
                vertical: tagPadding * 0.5,
              ),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '#$tag',
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: tagSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// "Forked from" chip, "Forks" carousel, and "More by this author"
  /// carousel — surfaces the fork lineage recorded when a downloaded
  /// project is uploaded as a new project, and lets people discover other
  /// work from the same tree/author without leaving the detail screen.
  Widget _buildRelatedProjects(
    BuildContext context,
    WidgetRef ref,
    ApiProject currentProject,
    AppTheme theme, {
    bool isDesktop = false,
    bool isTablet = false,
  }) {
    final titleSize = isDesktop ? 20.0 : (isTablet ? 18.0 : 18.0);
    final sectionGap = isDesktop ? 24.0 : 16.0;

    Widget sectionTitle(String text, IconData icon) {
      return Row(
        children: [
          Icon(icon, size: titleSize - 2, color: theme.textPrimary),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
        ],
      );
    }

    // [section] keeps hero tags unique when a project is in several lists.
    Widget projectCarousel(String section, List<ApiProject> projects) {
      return SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final p = projects[index];
            return Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              child: CommunityProjectCard(
                project: p,
                heroTag: '$section-${p.id}',
                onTap: () => ProjectDetailScreen.show(
                  context,
                  p,
                  siblings: projects,
                  heroTag: '$section-${p.id}',
                ),
              ),
            );
          },
        ),
      );
    }

    final children = <Widget>[];

    if (currentProject.parentProjectId != null) {
      final parent = ref.watch(communityProjectProvider(currentProject.parentProjectId!)).valueOrNull;
      if (parent != null) {
        children.add(
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => ProjectDetailScreen.show(context, parent),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.surfaceVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Feather.git_branch, size: 16, color: theme.textSecondary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(color: theme.textSecondary, fontSize: 13),
                        children: [
                          TextSpan(text: Strings.of(context).forkedFrom),
                          TextSpan(
                            text: parent.title,
                            style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w600),
                          ),
                          if ((parent.displayName ?? parent.username) != null)
                            TextSpan(text: Strings.of(context).byUser((parent.displayName ?? parent.username)!)),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        children.add(SizedBox(height: sectionGap));
      }
    }

    if (currentProject.forkCount > 0) {
      final forks = ref.watch(projectForksProvider(currentProject.id)).valueOrNull ?? [];
      if (forks.isNotEmpty) {
        children.addAll([
          sectionTitle(Strings.of(context).forksCount(currentProject.forkCount), Feather.git_branch),
          SizedBox(height: isDesktop ? 16 : 12),
          projectCarousel('forks', forks),
          SizedBox(height: sectionGap),
        ]);
      }
    }

    if (currentProject.username != null) {
      final authorProjects = (ref.watch(userProjectsProvider(currentProject.username!)).valueOrNull ?? [])
          .where((p) => p.id != currentProject.id)
          .toList();
      if (authorProjects.isNotEmpty) {
        children.addAll([
          sectionTitle(
            Strings.of(context).moreByUser(
              currentProject.displayName ?? currentProject.username!,
            ),
            Feather.user,
          ),
          SizedBox(height: isDesktop ? 16 : 12),
          projectCarousel('author', authorProjects),
        ]);
      }
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  /// Runs a save with a blocking spinner. Returns null on success, otherwise
  /// the failure message to show.
  Future<String?> _saveChanges(
    BuildContext context,
    WidgetRef ref,
    ApiProject project, {
    String? title,
    String? description,
    List<String>? tags,
    bool? isPublic,
  }) async {
    final fallback = Strings.of(context).error;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    String? failure;
    try {
      final ok = await ref.read(communityProjectsProvider.notifier).updateProjectInfo(
            project,
            title: title,
            description: description,
            tags: tags,
            isPublic: isPublic,
          );
      if (!ok) failure = fallback;
    } catch (e) {
      failure = e.toString().replaceFirst('Exception: ', '');
    }

    if (context.mounted) Navigator.of(context).pop();
    return failure;
  }

  Future<void> _toggleVisibility(
    BuildContext context,
    WidgetRef ref,
    ApiProject currentProject,
  ) async {
    final s = Strings.of(context);
    final makePublic = !currentProject.isPublic;
    final accent = makePublic ? Colors.green : Colors.orange;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(makePublic ? s.makeProjectPublic : s.makeProjectPrivate),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(makePublic ? s.makeProjectPublicMessage : s.makeProjectPrivateMessage),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(makePublic ? Icons.public : Icons.lock, color: accent, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      makePublic ? s.projectWillBePublic : s.projectWillBePrivate,
                      style: TextStyle(
                        color: accent.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(makePublic ? s.makePublic : s.makePrivate),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final failure = await _saveChanges(context, ref, currentProject, isPublic: makePublic);
    if (!context.mounted) return;

    if (failure == null) {
      AppNotification.info(
        context,
        makePublic ? s.projectIsNowPublic : s.projectIsNowPrivate,
      );
    } else {
      AppNotification.error(context, s.failedToUpdateVisibility(failure));
    }
  }

  Future<void> _reportProject(
    BuildContext context,
    WidgetRef ref,
    ApiProject project,
  ) async {
    final s = Strings.of(context);
    final details = await showDialog<String>(
      context: context,
      builder: (_) => const _ReportDialog(),
    );
    if (details == null || !context.mounted) return;

    try {
      final response = await ref.read(projectAPIRepoProvider).reportProject(project.id, details: details);
      if (!context.mounted) return;
      if (response.success) {
        AppNotification.info(context, s.reportThanks);
      } else {
        AppNotification.error(context, response.error ?? s.error);
      }
    } catch (e) {
      if (context.mounted) AppNotification.error(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<bool?> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    ApiProject currentProject,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => _DeleteProjectDialog(title: currentProject.title),
    );
  }

  Future<void> _editProject(
    BuildContext context,
    WidgetRef ref,
    ApiProject currentProject,
  ) async {
    final result = await showDialog<_ProjectEdits>(
      context: context,
      builder: (context) => _EditProjectDialog(project: currentProject),
    );
    if (result == null || !context.mounted) return;

    final failure = await _saveChanges(
      context,
      ref,
      currentProject,
      title: result.title,
      description: result.description,
      tags: result.tags,
    );
    if (failure != null && context.mounted) {
      AppNotification.error(context, failure);
    }
  }

  /// Shows the stats the API actually provides for this project.
  void _showAnalytics(
    BuildContext context,
    WidgetRef ref,
    ApiProject currentProject,
  ) {
    final s = Strings.of(context);
    final theme = ref.read(themeProvider).theme;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.projectAnalytics,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildAnalyticsCard(
                          s.views, formatCount(currentProject.viewCount), Icons.visibility, Colors.blue),
                      _buildAnalyticsCard(
                          s.totalLikes, formatCount(currentProject.likeCount), Icons.favorite, Colors.red),
                      _buildAnalyticsCard(
                          s.comments, formatCount(currentProject.commentCount), Icons.comment, Colors.green),
                      _buildAnalyticsCard(
                          s.downloads, formatCount(currentProject.downloadCount), Icons.download, Colors.orange),
                      _buildAnalyticsCard(
                          s.forks, formatCount(currentProject.forkCount), Feather.git_branch, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        currentProject.isPublic ? Icons.public : Icons.lock,
                        size: 18,
                        color: currentProject.isPublic ? theme.success : theme.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(currentProject.isPublic ? s.public : s.private),
                      if (currentProject.publishedAt != null) ...[
                        const SizedBox(width: 16),
                        Icon(Feather.clock, size: 16, color: theme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          formatRelativeDate(context, currentProject.publishedAt!),
                          style: TextStyle(color: theme.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _copyProjectLink(BuildContext context, ApiProject currentProject) {
    final link = Constants.projectUrl(currentProject.id);
    Clipboard.setData(ClipboardData(text: link));
    AppNotification.info(
      context,
      Strings.of(context).projectLinkCopied,
      duration: const Duration(seconds: 2),
    );
  }
}

/// What the preview panel needs to step through sibling projects and fly
/// from the originating card.
class _PreviewNav {
  const _PreviewNav({this.heroTag, this.onPrev, this.onNext, this.position, this.total = 0});

  final String? heroTag;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final int? position;
  final int total;
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return AlertDialog(
      title: Text(s.reportProject),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.reportProjectMessage),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: s.description,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(s.cancel)),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(s.report),
        ),
      ],
    );
  }
}

class _ProjectEdits {
  const _ProjectEdits({
    required this.title,
    required this.description,
    required this.tags,
  });

  final String title;
  final String description;
  final List<String> tags;
}

class _EditProjectDialog extends StatefulWidget {
  const _EditProjectDialog({required this.project});

  final ApiProject project;

  @override
  State<_EditProjectDialog> createState() => _EditProjectDialogState();
}

class _EditProjectDialogState extends State<_EditProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _tags;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.project.title);
    _description = TextEditingController(text: widget.project.description ?? '');
    _tags = TextEditingController(text: widget.project.tags.join(', '));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _tags.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final tags = <String>{
      for (final raw in _tags.text.split(','))
        if (raw.trim().replaceFirst('#', '').trim().isNotEmpty) raw.trim().replaceFirst('#', '').trim(),
    }.toList();
    Navigator.of(context).pop(_ProjectEdits(
      title: _title.text.trim(),
      description: _description.text.trim(),
      tags: tags,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return AlertDialog(
      title: Text(s.editProject),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: s.title,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? s.projectNameRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _description,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: s.description,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tags,
                  decoration: InputDecoration(
                    labelText: s.tags,
                    hintText: 'pixel, sprite, character',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.cancel),
        ),
        ElevatedButton(onPressed: _submit, child: Text(s.save)),
      ],
    );
  }
}

/// Delete confirmation that only enables the destructive button once the
/// project title has been typed exactly.
class _DeleteProjectDialog extends StatefulWidget {
  const _DeleteProjectDialog({required this.title});

  final String title;

  @override
  State<_DeleteProjectDialog> createState() => _DeleteProjectDialogState();
}

class _DeleteProjectDialogState extends State<_DeleteProjectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _matches => _controller.text.trim() == widget.title.trim();

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return AlertDialog(
      title: Text(s.deleteProject),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.deleteProjectCannotBeUndone),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.thisWillPermanentlyDelete,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.deleteProjectConsequences,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                s.typeProjectTitleToConfirmDeletion(widget.title),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: s.enterProjectTitle,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(s.cancel),
        ),
        TextButton(
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text(s.deleteForever),
        ),
      ],
    );
  }
}

/// Pinch-to-zoom view of the project thumbnail with nearest-neighbour
/// sampling so individual pixels stay crisp. Tap anywhere or the close
/// button to dismiss.
class _FullscreenPreview extends StatelessWidget {
  const _FullscreenPreview({required this.project, this.httpHeaders});

  final ApiProject project;
  final Map<String, String>? httpHeaders;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: SafeArea(
              child: Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 16,
                  child: AspectRatio(
                    aspectRatio: project.width / project.height,
                    child: CachedNetworkImage(
                      imageUrl: project.thumbnailUrl,
                      httpHeaders: httpHeaders,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                      errorWidget: (context, url, error) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white70,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
