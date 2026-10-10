import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../data/models/project_api_models.dart';
import '../../data/models/project_model.dart';
import '../../l10n/strings.dart';
import '../../providers/projects_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../core.dart';
import 'community_project_actions.dart';
import 'painter/checkboard_painter.dart';
import 'theme_selector.dart';

class CommunityProjectCard extends ConsumerWidget {
  final ApiProject project;
  final bool isFeatured;

  /// When set, the thumbnail is a [Hero] with this tag so the detail view can
  /// animate from it. Must be unique within the route the card lives in.
  final String? heroTag;
  final VoidCallback? onTap;
  final Function(ApiProject)? onLike;
  final Function(String)? onUserTap;

  const CommunityProjectCard({
    super.key,
    required this.project,
    this.isFeatured = false,
    this.heroTag,
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

    final g = theme.geometry;
    final canDownload = subscription.isPro;

    return LayoutBuilder(builder: (context, constraints) {
      final boundedHeight = constraints.hasBoundedHeight;
      Widget thumbnail(Widget child) {
        final content = heroTag == null ? child : Hero(tag: heroTag!, child: child);
        return boundedHeight
            ? Expanded(child: SizedBox(width: double.infinity, child: content))
            : AspectRatio(aspectRatio: project.width / project.height, child: content);
      }

      return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onSecondaryTapUp: (details) =>
              _showContextMenu(context, ref, details.globalPosition, isDownloaded, localProject),
          child: Card(
            elevation: isFeatured ? g.cardElevation + 2 : g.cardElevation,
            shadowColor: g.shadowColor,
            color: theme.surface,
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(g.cardRadius),
              side: g.cardBorderWidth > 0
                  ? BorderSide(
                      color: isFeatured ? theme.warning.withValues(alpha: 0.6) : theme.divider,
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
                  // In a masonry grid the card is height-unbounded and the
                  // thumbnail follows the project's aspect ratio. In fixed-height
                  // strips (carousels) it fills whatever the info/actions leave.
                  thumbnail(
                    Stack(
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
                          fit: boundedHeight ? BoxFit.contain : BoxFit.cover,
                          filterQuality: FilterQuality.none,
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
                              Strings.of(context).byUserInline(project.displayName ?? project.username ?? ''),
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
                    padding: EdgeInsets.fromLTRB(g.cardPadding.left, 6, g.cardPadding.right - 4, 4),
                    child: Row(
                      children: [
                        _StatAction(
                          icon: project.isLiked == true ? Icons.favorite : Icons.favorite_border,
                          color: project.isLiked == true ? theme.error : theme.textSecondary,
                          label: formatCount(project.likeCount),
                          labelColor: theme.textSecondary,
                          tooltip: Strings.of(context).like,
                          onTap: () => onLike?.call(project),
                        ),
                        const SizedBox(width: 10),
                        _StatAction(
                          icon: Icons.visibility_outlined,
                          color: theme.textSecondary,
                          label: formatCount(project.viewCount),
                          labelColor: theme.textSecondary,
                        ),
                        const Spacer(),
                        if (isDownloaded)
                          _StatAction(
                            icon: Feather.folder,
                            color: theme.success,
                            tooltip: Strings.of(context).openLocalProject,
                            onTap: () => openDownloadedProject(context, ref, localProject),
                          )
                        else
                          _StatAction(
                            icon: Icons.download_outlined,
                            color: theme.activeIcon,
                            tooltip: canDownload ? Strings.of(context).download : Strings.of(context).premiumRequired,
                            onTap: () => downloadCommunityProject(context, ref, project),
                          ),
                        const SizedBox(width: 4),
                        _StatAction(
                          icon: Icons.share_outlined,
                          color: theme.activeIcon,
                          tooltip: Strings.of(context).share,
                          onTap: () => shareCommunityProject(context, project),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ));
    });
  }

  /// Right-click (secondary tap) options, mirroring the card's footer actions.
  Future<void> _showContextMenu(
    BuildContext context,
    WidgetRef ref,
    Offset position,
    bool isDownloaded,
    Project? localProject,
  ) async {
    final s = Strings.of(context);
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;

    PopupMenuItem<String> item(String value, IconData icon, String label) => PopupMenuItem(
          value: value,
          child: Row(children: [Icon(icon, size: 18), const SizedBox(width: 10), Text(label)]),
        );

    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        if (onTap != null) item('open', Icons.open_in_new, s.openProject),
        item(
          'like',
          project.isLiked == true ? Icons.favorite : Icons.favorite_border,
          project.isLiked == true ? s.unlike : s.like,
        ),
        if (isDownloaded)
          item('local', Feather.folder, s.openLocalProject)
        else
          item('download', Icons.download_outlined, s.download),
        item('share', Icons.share_outlined, s.share),
      ],
    );
    if (value == null || !context.mounted) return;

    switch (value) {
      case 'open':
        onTap?.call();
      case 'like':
        onLike?.call(project);
      case 'local':
        openDownloadedProject(context, ref, localProject);
      case 'download':
        downloadCommunityProject(context, ref, project);
      case 'share':
        shareCommunityProject(context, project);
    }
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
