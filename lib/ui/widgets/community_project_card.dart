import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data.dart';
import '../../data/models/project_api_models.dart';
import '../../data/models/subscription_model.dart';
import '../../providers/ad/reward_video_ad_controller.dart';
import '../../providers/projects_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../core.dart';
import '../screens.dart';
import '../screens/subscription_screen.dart';
import 'dialogs/project_donwload_dialog.dart';
import 'dialogs/reward_dialog.dart';
import 'theme_selector.dart';

class CommunityProjectCard extends ConsumerWidget {
  final ApiProject project;
  final bool isFeatured;
  final VoidCallback? onTap;
  final Function(ApiProject)? onLike;
  final Function(String)? onUserTap;

  const CommunityProjectCard({
    super.key,
    required this.project,
    this.isFeatured = false,
    this.onTap,
    this.onLike,
    this.onUserTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionStateProvider);
    final theme = ref.watch(themeProvider).theme;
    final isDownloaded = ref.watch(isProjectDownloadedProvider(project.id));
    final localProject = ref.watch(localProjectByRemoteIdProvider(project.id));

    final isAdloaded = ref.watch(rewardVideoAdProvider);

    return Card(
      elevation: isFeatured ? 8 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project image
            AspectRatio(
              aspectRatio: project.width / project.height,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Checkerboard background
                    CustomPaint(
                      painter: CheckerboardPainter(
                        cellSize: 8,
                        color1: Colors.grey.shade100,
                        color2: Colors.grey.shade50,
                      ),
                    ),
                    // Project image
                    CachedNetworkImage(
                      imageUrl: project.thumbnailUrl,
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
                    // Featured badge
                    if (isFeatured)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.warning,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Featured',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
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

            // Project info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (project.username != null)
                    InkWell(
                      onTap: () => onUserTap?.call(project.username!),
                      child: Text(
                        'by ${project.displayName ?? project.username}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.grid_3x3,
                          size: 12, color: theme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${project.width}×${project.height}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: theme.textSecondary,
                            ),
                      ),
                      const Spacer(),
                      Icon(Icons.visibility,
                          size: 12, color: theme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _formatCount(project.viewCount),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: theme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Like button
                  IconButton(
                    icon: Icon(
                      project.isLiked == true
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: project.isLiked == true
                          ? Colors.red
                          : theme.activeIcon,
                      size: 20,
                    ),
                    onPressed: () => onLike?.call(project),
                    tooltip: 'Like',
                  ),

                  // Download button
                  if (isDownloaded) ...[
                    // Show "Open Local" button for downloaded projects
                    IconButton(
                      icon: Icon(
                        Feather.folder,
                        size: 20,
                        color: theme.success,
                      ),
                      onPressed: () =>
                          _openLocalProject(context, ref, localProject),
                      tooltip: 'Open Local Project',
                    ),
                  ] else ...[
                    // Show download button for non-downloaded projects
                    IconButton(
                      icon: const Icon(
                        Icons.download,
                        size: 20,
                        // color: subscription.hasFeatureAccess(SubscriptionFeature.cloudBackup)
                        //     ? theme.activeIcon
                        //     : theme.textDisabled,
                      ),
                      onPressed: subscription
                              .hasFeatureAccess(SubscriptionFeature.cloudBackup)
                          ? () => _downloadProject(context, ref, subscription)
                          : () => _showSubscriptionRequired(
                              context, project, isAdloaded),
                      tooltip: subscription
                              .hasFeatureAccess(SubscriptionFeature.cloudBackup)
                          ? 'Download'
                          : 'Premium Required',
                    ),
                  ],

                  // Share button
                  IconButton(
                    icon: Icon(Icons.share, size: 20, color: theme.activeIcon),
                    onPressed: () => _shareProject(),
                    tooltip: 'Share',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadProject(
      BuildContext context, WidgetRef ref, UserSubscription subscription) {
    // Check subscription access
    if (!subscription.hasFeatureAccess(SubscriptionFeature.cloudBackup)) {
      showTopFlushbar(
        context,
        message:
            const Text('Premium subscription required to download projects'),
        color: Colors.orange,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    // Show download dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProjectDownloadDialog(project: project),
    );
  }

  void _openLocalProject(
    BuildContext context,
    WidgetRef ref,
    Project? localProject,
  ) async {
    if (localProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local project not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Project? projectToOpen = localProject;
    final hasCanvasData = localProject.frames.isNotEmpty &&
        localProject.frames.first.layers.isNotEmpty;
    if (!hasCanvasData) {
      projectToOpen =
          await ref.read(projectsProvider.notifier).getProject(localProject.id);
    }

    if (!context.mounted || projectToOpen == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PixelCanvasScreen(project: projectToOpen!),
      ),
    );
  }

  void _showSubscriptionRequired(
      BuildContext context, ApiProject project, bool isAdLoaded) {
    if (isAdLoaded) {
      _showRewardDialog(context, project);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Premium subscription required to download projects'),
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
  }

  void _showRewardDialog(BuildContext context, ApiProject currentProject) {
    RewardDialog.show(
      context,
      title: 'Download Project',
      subtitle: 'To download this project, you can either:',
      onRewardEarned: () async {
        // User successfully watched the video, allow download
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Thank you for watching! Your download is starting...'),
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

  void _shareProject() {
    Share.share(
      'Check out this amazing pixel art: ${project.title}\n'
      'Created by ${project.displayName ?? project.username}',
      subject: project.title,
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
