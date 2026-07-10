import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data.dart';
import '../../data/models/project_api_models.dart';
import '../../data/models/subscription_model.dart';
import '../../l10n/strings.dart';
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

    final g = theme.geometry;
    final canDownload =
        subscription.hasFeatureAccess(SubscriptionFeature.cloudBackup);

    return Card(
      elevation: isFeatured ? g.cardElevation + 2 : g.cardElevation,
      shadowColor: g.shadowColor,
      color: theme.surface,
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(g.cardRadius),
        side: g.cardBorderWidth > 0
            ? BorderSide(
                color: isFeatured
                    ? theme.warning.withValues(alpha: 0.6)
                    : theme.divider,
                width: g.cardBorderWidth,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ──────────────────────────────────────────────
            AspectRatio(
              aspectRatio: project.width / project.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: CheckerboardPainter(
                      cellSize: 8,
                      color1: theme.surfaceVariant.withValues(alpha: 0.6),
                      color2: theme.surfaceVariant.withValues(alpha: 0.25),
                    ),
                  ),
                  CachedNetworkImage(
                    imageUrl: project.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.broken_image_outlined,
                      color: theme.textSecondary,
                    ),
                  ),
                  if (isFeatured)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _ImageChip(
                        color: theme.warning,
                        radius: g.chipRadius,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 11, color: Colors.white),
                            SizedBox(width: 3),
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
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: _ImageChip(
                      color: Colors.black.withValues(alpha: 0.55),
                      radius: g.chipRadius,
                      child: Text(
                        '${project.width}×${project.height}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Info ───────────────────────────────────────────────────
            Padding(
              padding: g.cardPadding.copyWith(bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (project.username != null) ...[
                    const SizedBox(height: 2),
                    InkWell(
                      onTap: () => onUserTap?.call(project.username!),
                      borderRadius: BorderRadius.circular(4),
                      child: Text(
                        Strings.of(context).byUserInline(
                            project.displayName ?? project.username ?? ''),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Stats + actions ────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                  g.cardPadding.left, 6, g.cardPadding.right - 4, 4),
              child: Row(
                children: [
                  _StatAction(
                    icon: project.isLiked == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: project.isLiked == true
                        ? theme.error
                        : theme.textSecondary,
                    label: _formatCount(project.likeCount),
                    labelColor: theme.textSecondary,
                    tooltip: Strings.of(context).like,
                    onTap: () => onLike?.call(project),
                  ),
                  const SizedBox(width: 10),
                  _StatAction(
                    icon: Icons.visibility_outlined,
                    color: theme.textSecondary,
                    label: _formatCount(project.viewCount),
                    labelColor: theme.textSecondary,
                  ),
                  const Spacer(),
                  if (isDownloaded)
                    _StatAction(
                      icon: Feather.folder,
                      color: theme.success,
                      tooltip: Strings.of(context).openLocalProject,
                      onTap: () =>
                          _openLocalProject(context, ref, localProject),
                    )
                  else
                    _StatAction(
                      icon: Icons.download_outlined,
                      color: theme.activeIcon,
                      tooltip: canDownload
                          ? Strings.of(context).download
                          : Strings.of(context).premiumRequired,
                      onTap: canDownload
                          ? () => _downloadProject(context, ref, subscription)
                          : () => _showSubscriptionRequired(
                              context, project, isAdloaded),
                    ),
                  const SizedBox(width: 4),
                  _StatAction(
                    icon: Icons.share_outlined,
                    color: theme.activeIcon,
                    tooltip: Strings.of(context).share,
                    onTap: _shareProject,
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
        message: Text(Strings.of(context).premiumRequiredToDownloadProjects),
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
        SnackBar(
          content: Text(Strings.of(context).localProjectNotFound),
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
          content: Text(Strings.of(context).premiumRequiredToDownloadProjects),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: Strings.of(context).upgrade,
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
      title: Strings.of(context).downloadProject,
      subtitle: Strings.of(context).downloadProjectRewardSubtitle,
      onRewardEarned: () async {
        // User successfully watched the video, allow download
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(Strings.of(context).thankYouWatchingDownloadStarting),
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

/// Small translucent pill overlaid on the thumbnail (featured badge,
/// canvas-size tag). Radius follows the theme's chip radius.
class _ImageChip extends StatelessWidget {
  const _ImageChip({
    required this.color,
    required this.radius,
    required this.child,
  });

  final Color color;
  final double radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

/// Compact icon (+ optional count label) used in the card footer. Much
/// tighter than a stock IconButton so likes/views/download/share fit on
/// one row even at narrow card widths.
class _StatAction extends StatelessWidget {
  const _StatAction({
    required this.icon,
    required this.color,
    this.label,
    this.labelColor,
    this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String? label;
  final Color? labelColor;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          if (label != null) ...[
            const SizedBox(width: 3),
            Text(
              label!,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: labelColor ?? color,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: content,
      );
    }

    if (tooltip != null) {
      content = Tooltip(message: tooltip!, child: content);
    }

    return content;
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
