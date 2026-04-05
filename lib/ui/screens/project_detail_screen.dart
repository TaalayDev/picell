import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../data.dart';
import '../../data/models/project_api_models.dart';
import '../../data/models/subscription_model.dart';
import '../../core.dart';
import '../../providers/ad/reward_video_ad_controller.dart';
import '../../providers/community_projects_providers.dart';
import '../../providers/projects_provider.dart';
import '../../providers/providers.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/auth_provider.dart';
import '../screens.dart';
import '../widgets/animated_background.dart';
import '../widgets/dialogs/project_donwload_dialog.dart';
import '../widgets/theme_selector.dart';
import '../widgets/dialogs/reward_dialog.dart';
import 'subscription_screen.dart';

class ProjectDetailScreen extends HookConsumerWidget {
  final ApiProject project;

  const ProjectDetailScreen({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider).theme;
    final subscription = ref.watch(subscriptionStateProvider);
    final scrollController = useScrollController();
    final showAppBar = useState(true);

    final projectDetail = ref.watch(communityProjectProvider(project.id, includeData: true));
    final comments = ref.watch(projectCommentsProvider(project.id));

    final currentProject = projectDetail.valueOrNull ?? project;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 1200;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;
    final isMobile = screenWidth < 600;

    final isAdLoaded = ref.watch(rewardVideoAdProvider);

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

    return AnimatedBackground(
      child: Builder(builder: (context) {
        if (isDesktop) {
          return _buildDesktopLayout(context, ref, theme, subscription, comments, currentProject);
        } else if (isTablet) {
          return _buildTabletLayout(
            context,
            ref,
            theme,
            subscription,
            scrollController,
            showAppBar,
            comments,
            currentProject,
          );
        } else {
          return _buildMobileLayout(
            context,
            ref,
            theme,
            subscription,
            scrollController,
            showAppBar,
            comments,
            currentProject,
          );
        }
      }),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    AppTheme theme,
    UserSubscription subscription,
    AsyncValue<List<ApiComment>> comments,
    ApiProject currentProject,
  ) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: theme.toolbarColor.withValues(alpha: 0.8),
        title: Text(
          currentProject.title,
          style: TextStyle(color: theme.textPrimary, fontSize: 20),
        ),
        actions: [
          _buildQuickActions(context, ref, currentProject, theme, isDesktop: true),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content area
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project preview
                  _buildDesktopProjectPreview(context, ref, currentProject, theme),

                  const SizedBox(height: 32),

                  // Project info
                  _buildProjectInfo(context, ref, currentProject, theme, isDesktop: true),

                  const SizedBox(height: 32),

                  // Tags
                  if (currentProject.tags.isNotEmpty) ...[
                    _buildTags(context, currentProject, theme, isDesktop: true),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ),

          // Sidebar
          Container(
            width: 400,
            decoration: BoxDecoration(
              color: theme.surface.withValues(alpha: 0.8),
              border: Border(left: BorderSide(color: theme.divider)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author info
                  _buildAuthorInfo(context, ref, currentProject, theme, isDesktop: true),

                  const SizedBox(height: 24),

                  // Project actions
                  _buildProjectActions(context, ref, currentProject, theme, isDesktop: true),

                  const SizedBox(height: 32),

                  // Comments section
                  SingleChildScrollView(
                    child: _buildCommentsSection(
                      context,
                      ref,
                      comments,
                      theme,
                      currentProject,
                      isDesktop: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    WidgetRef ref,
    AppTheme theme,
    UserSubscription subscription,
    ScrollController scrollController,
    ValueNotifier<bool> showAppBar,
    AsyncValue<List<ApiComment>> comments,
    ApiProject currentProject,
  ) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: showAppBar.value
                  ? null
                  : Text(
                      currentProject.title,
                      style: TextStyle(color: theme.textPrimary, fontSize: 18),
                    ),
              background: _buildTabletProjectPreview(context, ref, currentProject, theme),
            ),
            actions: [
              _buildQuickActions(context, ref, currentProject, theme, isTablet: true),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Project info
                        _buildProjectInfo(context, ref, currentProject, theme, isTablet: true),

                        const SizedBox(height: 24),

                        // Tags
                        if (currentProject.tags.isNotEmpty) ...[
                          _buildTags(context, currentProject, theme, isTablet: true),
                          const SizedBox(height: 24),
                        ],

                        // Comments on tablet (below main content)
                        _buildCommentsSection(context, ref, comments, theme, currentProject, isTablet: true),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Right column
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        // Author info
                        _buildAuthorInfo(context, ref, currentProject, theme, isTablet: true),

                        const SizedBox(height: 20),

                        // Project actions
                        _buildProjectActions(context, ref, currentProject, theme, isTablet: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    AppTheme theme,
    UserSubscription subscription,
    ScrollController scrollController,
    ValueNotifier<bool> showAppBar,
    AsyncValue<List<ApiComment>> comments,
    ApiProject currentProject,
  ) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            backgroundColor: theme.toolbarColor.withValues(alpha: 0.6),
            flexibleSpace: FlexibleSpaceBar(
              title: showAppBar.value
                  ? null
                  : Text(
                      currentProject.title,
                      style: TextStyle(color: theme.textPrimary, fontSize: 16),
                    ),
              background: _buildProjectPreview(context, ref, currentProject, theme),
            ),
            actions: [
              _buildQuickActions(context, ref, currentProject, theme),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project info
                  _buildProjectInfo(context, ref, currentProject, theme),

                  const SizedBox(height: 20),

                  // Author info
                  _buildAuthorInfo(context, ref, currentProject, theme),

                  const SizedBox(height: 20),

                  // Project actions
                  _buildProjectActions(context, ref, currentProject, theme),

                  const SizedBox(height: 20),

                  // Tags
                  if (currentProject.tags.isNotEmpty) ...[
                    _buildTags(context, currentProject, theme),
                    const SizedBox(height: 20),
                  ],

                  // Comments section
                  _buildCommentsSection(context, ref, comments, theme, currentProject),
                ],
              ),
            ),
          ),
        ],
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
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Deleting project...'),
            ],
          ),
        ),
      );

      final result = await ref.read(communityProjectsProvider.notifier).deleteProject(currentProject);
      if (!context.mounted) return;

      if (result) {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project deleted successfully'),
          ),
        );
      } else {
        Navigator.of(context).pop(); // Hide loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete project'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Hide loading
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete project: $e'),
            backgroundColor: Colors.red,
          ),
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
              ref.read(communityProjectsProvider.notifier).toggleLike(currentProject);
            },
            tooltip: currentProject.isLiked == true ? 'Unlike' : 'Like',
          ),
        ],

        // Share button
        IconButton(
          icon: Icon(Icons.share, color: theme.activeIcon),
          onPressed: () => _shareProject(currentProject),
          tooltip: 'Share',
        ),

        // Copy link button
        IconButton(
          icon: Icon(Icons.link, color: theme.activeIcon),
          onPressed: () => _copyProjectLink(context, currentProject),
          tooltip: 'Copy Link',
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
            tooltip: currentProject.isPublic ? 'Make Private' : 'Make Public',
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
            tooltip: 'Delete Project',
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
        //         _downloadProject(context, ref, currentProject, ref.read(subscriptionStateProvider));
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

  Widget _buildDesktopProjectPreview(
    BuildContext context,
    WidgetRef ref,
    ApiProject currentProject,
    AppTheme theme,
  ) {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: currentProject.width / currentProject.height,
              child: Container(
                margin: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: theme.canvasBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
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
                          cellSize: 12,
                          color1: Colors.grey.shade100,
                          color2: Colors.grey.shade50,
                        ),
                      ),
                      CachedNetworkImage(
                        imageUrl: currentProject.thumbnailUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            color: theme.primaryColor,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.error,
                          color: theme.error,
                          size: 64,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (currentProject.isFeatured)
            Positioned(
              top: 20,
              right: 20,
              child: _buildFeaturedBadge(theme),
            ),
        ],
      ),
    );
  }

  Widget _buildTabletProjectPreview(
    BuildContext context,
    WidgetRef ref,
    ApiProject currentProject,
    AppTheme theme,
  ) {
    return Container(
      decoration: BoxDecoration(
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
          Center(
            child: AspectRatio(
              aspectRatio: currentProject.width / currentProject.height,
              child: Container(
                margin: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: theme.canvasBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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
                          cellSize: 10,
                          color1: Colors.grey.shade100,
                          color2: Colors.grey.shade50,
                        ),
                      ),
                      CachedNetworkImage(
                        imageUrl: currentProject.thumbnailUrl,
                        httpHeaders: {
                          'Authorization': 'Bearer ${ref.read(localStorageProvider).token}',
                        },
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            color: theme.primaryColor,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.error,
                          color: theme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (currentProject.isFeatured)
            Positioned(
              top: 40,
              right: 20,
              child: _buildFeaturedBadge(theme),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectPreview(
    BuildContext context,
    WidgetRef ref,
    ApiProject currentProject,
    AppTheme theme,
  ) {
    return Container(
      decoration: BoxDecoration(
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
          Center(
            child: AspectRatio(
              aspectRatio: currentProject.width / currentProject.height,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.canvasBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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
                          cellSize: 8,
                          color1: Colors.grey.shade100,
                          color2: Colors.grey.shade50,
                        ),
                      ),
                      CachedNetworkImage(
                        imageUrl: currentProject.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            color: theme.primaryColor,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.error,
                          color: theme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (currentProject.isFeatured)
            Positioned(
              top: 40,
              right: 20,
              child: _buildFeaturedBadge(theme),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedBadge(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.warning,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 16, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Featured',
            style: TextStyle(
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
                      label: 'Size',
                      value: '${currentProject.width} × ${currentProject.height}',
                      color: theme.primaryColor,
                      isLarge: isDesktop,
                    ),
                    _buildInfoCard(
                      context,
                      icon: Icons.visibility,
                      label: 'Views',
                      value: _formatCount(currentProject.viewCount),
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
                      label: 'Downloads',
                      value: _formatCount(currentProject.downloadCount),
                      color: theme.success,
                      isLarge: isDesktop,
                    ),
                    if (currentProject.publishedAt != null)
                      _buildInfoCard(
                        context,
                        icon: Feather.clock,
                        label: 'Published',
                        value: _formatDate(currentProject.publishedAt!),
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
                label: 'Size',
                value: '${currentProject.width} × ${currentProject.height}',
                color: theme.primaryColor,
              ),
              _buildInfoCard(
                context,
                icon: Icons.visibility,
                label: 'Views',
                value: _formatCount(currentProject.viewCount),
                color: theme.accentColor,
              ),
              _buildInfoCard(
                context,
                icon: Icons.download,
                label: 'Downloads',
                value: _formatCount(currentProject.downloadCount),
                color: theme.success,
              ),
              if (currentProject.publishedAt != null)
                _buildInfoCard(
                  context,
                  icon: Feather.clock,
                  label: 'Published',
                  value: _formatDate(currentProject.publishedAt!),
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
    final iconSize = isLarge ? 14.0 : 12.0;
    final labelSize = isLarge ? 12.0 : 10.0;
    final valueSize = isLarge ? 14.0 : 10.0;
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

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: isDesktop ? 6 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: theme.primaryColor,
            child: Text(
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        currentProject.displayName ?? currentProject.username ?? 'Unknown Artist',
                        style: TextStyle(
                          fontSize: nameSize,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.verified,
                      size: nameSize,
                      color: theme.primaryColor,
                    ),
                  ],
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
        ],
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

    final isDownloaded = ref.watch(isProjectDownloadedProvider(project.id));
    final localProject = ref.watch(localProjectByRemoteIdProvider(project.id));

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
                label: const Text('Edit Project'),
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
                    label: Text(currentProject.isPublic ? 'Public' : 'Private'),
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
                    label: const Text('Analytics'),
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
                label: const Text('Edit Project'),
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
                    label: Text(currentProject.isPublic ? 'Public' : 'Private'),
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
                    label: const Text('Stats'),
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
                  ref.read(communityProjectsProvider.notifier).toggleLike(currentProject);
                },
                icon: Icon(
                  currentProject.isLiked == true ? Icons.favorite : Icons.favorite_border,
                  color: currentProject.isLiked == true ? Colors.red : null,
                ),
                label: Text('${_formatCount(currentProject.likeCount)} Likes'),
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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Scroll to comments
                },
                icon: const Icon(Icons.comment_outlined),
                label: Text('${_formatCount(currentProject.commentCount)} Comments'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _downloadProject(context, ref, currentProject, ref.read(subscriptionStateProvider)),
                icon: const Icon(Icons.download),
                label: const Text('Download'),
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
                      ref.read(communityProjectsProvider.notifier).toggleLike(currentProject);
                    },
                    icon: Icon(
                      currentProject.isLiked == true ? Icons.favorite : Icons.favorite_border,
                      color: currentProject.isLiked == true ? Colors.red : null,
                    ),
                    label: Text('${_formatCount(currentProject.likeCount)}'),
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
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Show comments or scroll to comments
                    },
                    icon: const Icon(Icons.comment_outlined),
                    label: Text('${_formatCount(currentProject.commentCount)}'),
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
                    _openLocalProject(context, localProject);
                  },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Open Project'),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _downloadProject(context, ref, currentProject, ref.read(subscriptionStateProvider)),
                  icon: const Icon(Icons.download),
                  label: const Text('Download Project'),
                ),
              ),
            ],
          ],
        );
      }
    }
  }

  void _openLocalProject(BuildContext context, Project? localProject) {
    if (localProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local project not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PixelCanvasScreen(project: localProject),
      ),
    );
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
          'Tags',
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

  Widget _buildCommentsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ApiComment>> comments,
    AppTheme theme,
    ApiProject currentProject, {
    bool isDesktop = false,
    bool isTablet = false,
  }) {
    final titleSize = isDesktop ? 20.0 : (isTablet ? 18.0 : 18.0);
    final maxHeight = isDesktop ? 400.0 : double.infinity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Comments',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            if (isDesktop) ...[
              ElevatedButton.icon(
                onPressed: () => _showAddCommentDialog(context, ref, currentProject),
                icon: const Icon(Icons.add_comment, color: Colors.white),
                label: const Text('Add Comment'),
              ),
            ] else ...[
              TextButton.icon(
                onPressed: () => _showAddCommentDialog(context, ref, currentProject),
                icon: const Icon(Icons.add_comment),
                label: const Text('Add Comment'),
              ),
            ],
          ],
        ),
        SizedBox(height: isDesktop ? 20 : 16),
        Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: comments.when(
            data: (commentsList) {
              if (commentsList.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(isDesktop ? 40 : 32),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: isDesktop ? 56 : 48,
                          color: theme.textSecondary,
                        ),
                        SizedBox(height: isDesktop ? 20 : 16),
                        Text(
                          'No comments yet',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: isDesktop ? 18 : 16,
                          ),
                        ),
                        SizedBox(height: isDesktop ? 12 : 8),
                        Text(
                          'Be the first to leave a comment!',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: isDesktop ? 14 : 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              Widget commentsWidget = Column(
                children: commentsList
                    .map((comment) => _buildCommentCard(
                          context,
                          comment,
                          theme,
                          isDesktop: isDesktop,
                          isTablet: isTablet,
                        ))
                    .toList(),
              );

              if (isDesktop) {
                return SingleChildScrollView(child: commentsWidget);
              } else {
                return commentsWidget;
              }
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text(
                'Failed to load comments',
                style: TextStyle(color: theme.error),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentCard(
    BuildContext context,
    ApiComment comment,
    AppTheme theme, {
    bool isDesktop = false,
    bool isTablet = false,
  }) {
    final avatarRadius = isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0);
    final nameSize = isDesktop ? 16.0 : (isTablet ? 14.0 : 14.0);
    final dateSize = isDesktop ? 14.0 : (isTablet ? 12.0 : 12.0);
    final contentSize = isDesktop ? 16.0 : (isTablet ? 14.0 : 14.0);
    final padding = isDesktop ? 20.0 : (isTablet ? 18.0 : 16.0);

    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 16 : 12),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        border: Border.all(color: theme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: theme.primaryColor,
                child: Text(
                  (comment.displayName ?? comment.username)[0].toUpperCase(),
                  style: TextStyle(
                    color: theme.onPrimary,
                    fontSize: avatarRadius * 0.75,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: isDesktop ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.displayName ?? comment.username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.textPrimary,
                            fontSize: nameSize,
                          ),
                        ),
                        if (comment.isVerified) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified,
                            size: nameSize,
                            color: theme.primaryColor,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      _formatDate(comment.createdAt),
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: dateSize,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isDesktop ? 16 : 12),
          Text(
            comment.content,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: contentSize,
              height: 1.4,
            ),
          ),
          if (comment.isEdited) ...[
            SizedBox(height: isDesktop ? 12 : 8),
            Text(
              'Edited',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: dateSize * 0.9,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _toggleVisibility(BuildContext context, WidgetRef ref, ApiProject currentProject) {
    final newVisibility = !currentProject.isPublic;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(newVisibility ? 'Make Project Public' : 'Make Project Private'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              newVisibility
                  ? 'This will make your project visible to everyone in the community. Anyone will be able to view, like, and comment on it.'
                  : 'This will hide your project from the public community. Only you will be able to see it.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: newVisibility ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: newVisibility ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    newVisibility ? Icons.public : Icons.lock,
                    color: newVisibility ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      newVisibility ? 'Project will be publicly visible' : 'Project will be private',
                      style: TextStyle(
                        color: newVisibility ? Colors.green.shade700 : Colors.orange.shade700,
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                // Show loading
                final loader = showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                // Update visibility via API
                // await ref.read(communityProjectsProvider.notifier).updateProjectVisibility(
                //       currentProject.id,
                //       newVisibility,
                //     );

                // Hide loading
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        newVisibility ? 'Project is now public' : 'Project is now private',
                      ),
                    ),
                  );
                }
              } catch (e) {
                // Hide loading
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update visibility: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(newVisibility ? 'Make Public' : 'Make Private'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context, WidgetRef ref, ApiProject currentProject) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to delete this project? This action cannot be undone.',
            ),
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
                        const Text(
                          'This will permanently delete:',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• Project data and artwork\n• All comments and likes\n• Download statistics',
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
              'Type "${currentProject.title}" to confirm deletion:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (value) {
                // Store the value for confirmation
              },
              decoration: const InputDecoration(
                hintText: 'Enter project title...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  void _editProject(BuildContext context, WidgetRef ref, ApiProject currentProject) {
    // Navigate to project editor or show edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening project editor...'),
      ),
    );
    // Implementation would navigate to the pixel art editor with this project
  }

  void _showAnalytics(BuildContext context, WidgetRef ref, ApiProject currentProject) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Project Analytics',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Stats cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalyticsCard(
                              'Total Views',
                              _formatCount(currentProject.viewCount),
                              Icons.visibility,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildAnalyticsCard(
                              'Total Likes',
                              _formatCount(currentProject.likeCount),
                              Icons.favorite,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAnalyticsCard(
                              'Comments',
                              _formatCount(currentProject.commentCount),
                              Icons.comment,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildAnalyticsCard(
                              'Downloads',
                              _formatCount(currentProject.downloadCount),
                              Icons.download,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Additional analytics would go here
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(Icons.analytics, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Detailed Analytics',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Advanced analytics features will be available soon.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareProject(ApiProject currentProject) {
    Share.share(
      'Check out this amazing pixel art project: ${currentProject.title}\n'
      'Created by ${currentProject.displayName ?? currentProject.username}',
      subject: currentProject.title,
    );
  }

  void _copyProjectLink(BuildContext context, ApiProject currentProject) {
    final link = 'https://pixelverse.app/project/${currentProject.id}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Project link copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _saveToFavorites(BuildContext context, WidgetRef ref, ApiProject currentProject) {
    // Implement save to favorites functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to favorites!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _followArtist(BuildContext context, WidgetRef ref, ApiProject currentProject) {
    // Implement follow artist functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Now following ${currentProject.displayName ?? currentProject.username}!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Project'),
        content: const Text(
          'Are you sure you want to report this project? '
          'Please only report content that violates our community guidelines.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your report. We will review it shortly.'),
                ),
              );
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _downloadProject(
    BuildContext context,
    WidgetRef ref,
    ApiProject currentProject,
    UserSubscription subscription,
  ) {
    final isAdLoaded = ref.read(rewardVideoAdProvider);

    if (!subscription.isPro) {
      if (isAdLoaded) {
        _showDownloadOptionsDialog(context, ref, currentProject);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Premium subscription required to download projects'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Upgrade',
              onPressed: () {
                // Navigate to subscription screen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionOfferScreen(),
                  ),
                );
              },
            ),
          ),
        );
      }
      return;
    }

    // Show download dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProjectDownloadDialog(project: currentProject),
    );
  }

  void _showDownloadOptionsDialog(BuildContext context, WidgetRef ref, ApiProject currentProject) {
    RewardDialog.show(
      context,
      title: 'Download Project',
      subtitle: 'To download this project, you can either:',
      onRewardEarned: () async {
        // User successfully watched the video, allow download
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for watching! Your download is starting...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Show download dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ProjectDownloadDialog(project: currentProject),
        );
      },
    );
  }

  void _showAddCommentDialog(BuildContext context, WidgetRef ref, ApiProject currentProject) {
    final authState = ref.read(authProvider);
    if (!authState.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to add comments'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
          controller: commentController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Write your comment...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (commentController.text.trim().isNotEmpty) {
                try {
                  await ref
                      .read(projectCommentsProvider(currentProject.id).notifier)
                      .addComment(commentController.text.trim());

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Comment added successfully!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add comment: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${difference.inDays > 60 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
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
