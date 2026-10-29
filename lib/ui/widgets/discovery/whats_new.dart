import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/theme.dart';
import '../../../data/models/discovery_api_models.dart';
import '../../../l10n/strings.dart';
import '../../../pixel/gradient/gradient_renderer.dart';
import '../../../providers/discovery_providers.dart';

/// Scrollable list of recent news / release notes, backed by [newsItemsProvider]
/// (the same source as the discovery carousel's news slides).
class WhatsNewList extends ConsumerWidget {
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;

  /// Opens the bone rig example project; the banner hides its button without it.
  final VoidCallback? onOpenBoneRigExample;

  const WhatsNewList({
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.controller,
    this.onOpenBoneRigExample,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final news = ref.watch(newsItemsProvider);
    final strings = Strings.of(context);

    final items = news.valueOrNull ?? const <NewsItemModel>[];

    // The feature banner always leads, so the section is never blank; the
    // server news (or its loading / empty / error state) follows it.
    return ListView(
      controller: controller,
      padding: padding,
      children: [
        const GradientToolBanner(),
        const SizedBox(height: 12),
        BoneRigBanner(onOpenExample: onOpenBoneRigExample),
        const SizedBox(height: 12),
        if (news.isLoading && items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (news.hasError && items.isEmpty)
          _Message(text: strings.whatsNewLoadFailed)
        else if (items.isEmpty)
          _Message(text: strings.whatsNewEmpty)
        else
          for (final item in items) ...[
            _WhatsNewTile(item: item),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

/// Feature banner for the bone rigger, with an optional button that opens the
/// example project.
class BoneRigBanner extends StatelessWidget {
  final VoidCallback? onOpenExample;
  const BoneRigBanner({super.key, this.onOpenExample});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final strings = Strings.of(context);

    return Container(
      key: const ValueKey('whats-new-bone-rig-banner'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [scheme.primary.withValues(alpha: 0.25), scheme.tertiary.withValues(alpha: 0.18)],
        ),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 72,
              height: 72,
              color: scheme.surface.withValues(alpha: 0.5),
              child: Image.asset(
                'assets/data/BoneJumpAnim.gif',
                key: const ValueKey('whats-new-bone-rig-image'),
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                errorBuilder: (_, __, ___) => Icon(Feather.activity, color: scheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.whatsNewBoneRigTitle,
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.whatsNewBoneRigBody,
                  style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                if (onOpenExample != null) ...[
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    key: const ValueKey('whats-new-open-example'),
                    onPressed: onOpenExample,
                    icon: const Icon(Feather.play, size: 16),
                    label: Text(strings.whatsNewOpenExample),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature banner for the gradient tool. Its thumbnail is rendered by the
/// gradient engine itself: a banded, dithered radial gradient.
class GradientToolBanner extends StatelessWidget {
  const GradientToolBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final strings = Strings.of(context);

    return Container(
      key: const ValueKey('whats-new-gradient-banner'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [scheme.tertiary.withValues(alpha: 0.22), scheme.primary.withValues(alpha: 0.18)],
        ),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const SizedBox(
              width: 72,
              height: 72,
              child: CustomPaint(
                key: ValueKey('whats-new-gradient-image'),
                painter: _GradientThumbnailPainter(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.whatsNewGradientTitle,
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.whatsNewGradientBody,
                  style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientThumbnailPainter extends CustomPainter {
  const _GradientThumbnailPainter();

  static const _size = 18;

  // A sunset ramp, drawn as 18×18 pixel art.
  static final Uint32List _pixels = GradientRenderer.render(
    base: Uint32List(_size * _size),
    width: _size,
    height: _size,
    spec: const GradientSpec(
      type: GradientType.radial,
      start: Offset(6, 6),
      end: Offset(18, 18),
      stops: [0xFFFFE08A, 0xFFF5934C, 0xFFC4425A, 0xFF5B2A6E, 0xFF1E1B3A],
      steps: 5,
      dither: GradientDither.bayer4,
      ditherSpread: 0.6,
    ),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _size;
    final paint = Paint();
    for (var y = 0; y < _size; y++) {
      for (var x = 0; x < _size; x++) {
        paint.color = Color(_pixels[y * _size + x]);
        canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GradientThumbnailPainter oldDelegate) => false;
}

class _Message extends StatelessWidget {
  final String text;
  const _Message({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

class _WhatsNewTile extends StatelessWidget {
  final NewsItemModel item;
  const _WhatsNewTile({required this.item});

  Future<void> _open() async {
    final uri = Uri.tryParse(item.linkUrl ?? '');
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final date = item.publishedAt;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: item.linkUrl == null ? null : _open,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (date != null)
                Text(
                  MaterialLocalizations.of(context).formatMediumDate(date),
                  style: textTheme.labelSmall?.copyWith(color: scheme.primary),
                ),
              Text(
                item.title,
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                item.excerpt,
                style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "What's new" block shown with the other banners on wide layouts.
class WhatsNewSection extends StatelessWidget {
  final VoidCallback? onOpenBoneRigExample;
  const WhatsNewSection({super.key, this.onOpenBoneRigExample});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Feather.gift, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              Strings.of(context).whatsNew,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const GradientToolBanner(),
        const SizedBox(height: 10),
        BoneRigBanner(onOpenExample: onOpenBoneRigExample),
      ],
    );
  }
}

/// Compact list of the latest item titles (built-in features plus server news).
/// Tapping any row opens the full "What's new" sheet.
class WhatsNewTitles extends ConsumerWidget {
  final VoidCallback? onOpenBoneRigExample;
  final int maxItems;
  const WhatsNewTitles({super.key, this.onOpenBoneRigExample, this.maxItems = 4});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pv = context.pv;
    final strings = Strings.of(context);
    final news = ref.watch(newsItemsProvider).valueOrNull ?? const <NewsItemModel>[];
    final titles = [
      strings.whatsNewGradientTitle,
      strings.whatsNewBoneRigTitle,
      ...news.map((n) => n.title),
    ].take(maxItems).toList();

    return Column(
      key: const ValueKey('whats-new-titles'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, title) in titles.indexed)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => WhatsNewButton.showSheet(context, onOpenBoneRigExample: onOpenBoneRigExample),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  if (i == 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.auto_awesome, size: 20, color: pv.accent, semanticLabel: strings.newBadge),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(Icons.check_circle_outline, size: 20, color: pv.accent),
                    ),
                  Expanded(
                    child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: pv.body(size: 14)),
                  ),
                  Icon(Icons.chevron_right, size: 18, color: pv.textSecondary),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Single button that opens the "What's new" content in a bottom sheet.
class WhatsNewButton extends StatelessWidget {
  final VoidCallback? onOpenBoneRigExample;
  const WhatsNewButton({super.key, this.onOpenBoneRigExample});

  static Future<void> showSheet(BuildContext context, {VoidCallback? onOpenBoneRigExample}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (context, controller) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                Strings.of(context).whatsNew,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: WhatsNewList(
                controller: controller,
                onOpenBoneRigExample: onOpenBoneRigExample == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        onOpenBoneRigExample();
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final strings = Strings.of(context);
    return Material(
      key: const ValueKey('whats-new-button'),
      color: pv.surface,
      shape: StadiumBorder(side: BorderSide(color: pv.divider)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showSheet(context, onOpenBoneRigExample: onOpenBoneRigExample),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: 6),
              Icon(Icons.new_releases_outlined, size: 24, color: pv.accent, semanticLabel: strings.newBadge),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.whatsNew,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: pv.body(size: 14),
                ),
              ),
              Icon(Icons.chevron_right, size: 22, color: pv.textSecondary),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
