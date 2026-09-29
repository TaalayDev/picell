import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/discovery_api_models.dart';
import '../../../data/models/project_api_models.dart';
import '../../../providers/discovery_slides_provider.dart';
import '../../../providers/providers.dart';
import '../../screens/project_detail_screen.dart';

/// Auto-advancing carousel cycling through cross-promo app ads, projects
/// marked as featured in the admin panel, and news. Purely
/// decorative/discovery — disappears silently rather than showing an error
/// or empty box if its data source fails or is empty.
class DiscoveryCarousel extends HookConsumerWidget {
  final double height;
  final bool showArrows;

  const DiscoveryCarousel({
    super.key,
    this.height = 220,
    this.showArrows = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slidesAsync = ref.watch(discoverySlidesProvider);

    return slidesAsync.when(
      data: (slides) {
        if (slides.isEmpty) return const SizedBox.shrink();
        return _CarouselBody(slides: slides, height: height, showArrows: showArrows);
      },
      loading: () => SizedBox(height: height),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Desktop layout: a small slide on each side of the focused one.
const List<int> _flexWeights = [2, 5, 2];
final int _flexWeightTotal = _flexWeights.reduce((a, b) => a + b);
final int _prominentWeightIndex = _flexWeights.indexOf(_flexWeights.reduce((a, b) => a > b ? a : b));

class _CarouselBody extends HookConsumerWidget {
  final List<DiscoverySlide> slides;
  final double height;
  final bool showArrows;

  const _CarouselBody({
    required this.slides,
    required this.height,
    required this.showArrows,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loopedItemCount = slides.length == 1 ? 1 : slides.length * 10000;
    final initialVirtualIndex = slides.length == 1 ? 0 : slides.length * 5000 + (slides.length ~/ 2);
    final carouselController = useMemoized(
      () => CarouselController(initialItem: initialVirtualIndex),
      [slides.length],
    );
    // The slide shown first is initialVirtualIndex, not slide 0.
    final currentPage = useState(initialVirtualIndex % slides.length);
    final currentVirtualIndex = useState(initialVirtualIndex);
    final timerRef = useRef<Timer?>(null);
    final recordedPromoIds = useRef(<int>{});

    void recordVisiblePromo(int index) {
      final slide = slides[index];
      if (slide is! PromoAppSlide || !recordedPromoIds.value.add(slide.app.id)) return;

      final installationId = ref.read(localStorageProvider).installationId;
      unawaited(
        ref.read(discoveryAPIRepoProvider).recordPromoAppImpression(slide.app.id, installationId),
      );
    }

    void goToVirtualItem(int index, {Duration duration = const Duration(milliseconds: 450)}) {
      final nextVirtual = index.clamp(0, loopedItemCount - 1);
      final nextPage = nextVirtual % slides.length;
      currentVirtualIndex.value = nextVirtual;
      currentPage.value = nextPage;
      recordVisiblePromo(nextPage);
      carouselController.animateToItem(
        nextVirtual,
        duration: duration,
        curve: Curves.easeInOut,
      );
    }

    void restartTimer() {
      timerRef.value?.cancel();
      if (slides.length <= 1) return;
      timerRef.value = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!carouselController.hasClients) return;
        goToVirtualItem(
          currentVirtualIndex.value + 1,
          duration: const Duration(milliseconds: 500),
        );
      });
    }

    useEffect(() => carouselController.dispose, [carouselController]);

    useEffect(() {
      if (slides.length > 1) restartTimer();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) recordVisiblePromo(currentPage.value);
      });
      return () => timerRef.value?.cancel();
      // ignore: exhaustive_keys
    }, [slides.length]);

    return Padding(
      padding: EdgeInsets.only(bottom: slides.length > 1 ? 16 : 0),
      child: MouseRegion(
        onEnter: (_) => timerRef.value?.cancel(),
        onExit: (_) => restartTimer(),
        child: SizedBox(
          height: height,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = MediaQuery.sizeOf(context).width >= 780;
                  final itemExtent = _carouselItemExtent(constraints.maxWidth);

                  // The slide in focus, computed exactly as CarouselView lays
                  // items out and as animateToItem targets them, so arrows,
                  // auto-advance and swipes always move by one slide.
                  int virtualIndexFor(ScrollMetrics metrics) {
                    if (!isWide) {
                      return (metrics.pixels / itemExtent).round().clamp(0, loopedItemCount - 1);
                    }

                    // Weighted layout: scrolling one item moves by the first
                    // (small) item's share of the viewport, and the focused
                    // item sits at the biggest weight's position.
                    final step = metrics.viewportDimension * _flexWeights.first / _flexWeightTotal;
                    if (step <= 0) return currentVirtualIndex.value;
                    return ((metrics.pixels / step).round() + _prominentWeightIndex).clamp(0, loopedItemCount - 1);
                  }

                  Widget buildSlide(BuildContext context, int virtualIndex) {
                    final slide = slides[virtualIndex % slides.length];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _SlideCard(slide: slide),
                      ),
                    );
                  }

                  final carousel = isWide && slides.length > 1
                      ? CarouselView.weightedBuilder(
                          controller: carouselController,
                          flexWeights: _flexWeights,
                          consumeMaxWeight: false,
                          itemCount: loopedItemCount,
                          itemBuilder: buildSlide,
                          itemSnapping: true,
                          shrinkExtent: 72,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          itemClipBehavior: Clip.antiAlias,
                          enableSplash: false,
                        )
                      : CarouselView.builder(
                          controller: carouselController,
                          itemExtent: itemExtent,
                          itemCount: loopedItemCount,
                          itemBuilder: buildSlide,
                          itemSnapping: true,
                          shrinkExtent: 96,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          itemClipBehavior: Clip.antiAlias,
                          enableSplash: false,
                        );

                  return Stack(
                    children: [
                      NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.axis != Axis.horizontal) {
                            return false;
                          }
                          final nextVirtual = virtualIndexFor(notification.metrics);
                          final nextPage = nextVirtual % slides.length;
                          currentVirtualIndex.value = nextVirtual;
                          if (currentPage.value != nextPage) {
                            currentPage.value = nextPage;
                            recordVisiblePromo(nextPage);
                          }
                          if (notification is ScrollEndNotification) {
                            if (slides.length > 1 &&
                                (nextVirtual < slides.length * 2 ||
                                    nextVirtual > loopedItemCount - slides.length * 2)) {
                              final recentered = initialVirtualIndex + nextPage;
                              currentVirtualIndex.value = recentered;
                              unawaited(carouselController.animateToItem(
                                recentered,
                                duration: Duration.zero,
                              ));
                            }
                            restartTimer();
                          }
                          return false;
                        },
                        child: carousel,
                      ),
                      if (showArrows && slides.length > 1) ...[
                        Positioned(
                          left: 4,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: _NavArrow(
                              icon: Feather.chevron_left,
                              onTap: () {
                                goToVirtualItem(
                                  currentVirtualIndex.value - 1,
                                  duration: const Duration(milliseconds: 400),
                                );
                                restartTimer();
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          right: 4,
                          top: 0,
                          bottom: 0,
                          child: Center(
                            child: _NavArrow(
                              icon: Feather.chevron_right,
                              onTap: () {
                                goToVirtualItem(
                                  currentVirtualIndex.value + 1,
                                  duration: const Duration(milliseconds: 400),
                                );
                                restartTimer();
                              },
                            ),
                          ),
                        ),
                      ],
                      if (slides.length > 1)
                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(slides.length, (i) {
                              final active = i == currentPage.value;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: active ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: active ? 0.9 : 0.5),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _carouselItemExtent(double width) {
    if (width >= 1180) return width * 0.62;
    if (width >= 780) return width * 0.72;
    return width * 0.92;
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _SlideCard extends ConsumerWidget {
  final DiscoverySlide slide;

  const _SlideCard({required this.slide});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return switch (slide) {
      PromoAppSlide(:final app) => _PromoAppSlide(
          app: app,
          onTap: () {
            unawaited(ref.read(discoveryAPIRepoProvider).recordPromoAppClick(app.id));
            _openPromoApp(app);
          },
        ),
      FeaturedProjectSlide(:final project) => _ImageSlide(
          imageUrl: project.thumbnailUrl,
          badgeLabel: 'FEATURED',
          title: project.title,
          subtitle: project.displayName ?? project.username,
          onTap: () {
            unawaited(ref.read(projectAPIRepoProvider).recordFeaturedClick(project.id));
            _openProject(context, project);
          },
        ),
      NewsSlide(:final news) => _NewsSlideContent(news: news, theme: theme),
    };
  }

  void _openProject(BuildContext context, ApiProject project) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)),
    );
  }

  Future<void> _openPromoApp(PromoAppItem app) async {
    String? url;
    if (!kIsWeb && Platform.isIOS) {
      url = app.iosUrl ?? app.webUrl;
    } else if (!kIsWeb && Platform.isAndroid) {
      url = app.androidUrl ?? app.webUrl;
    } else {
      url = app.webUrl ?? app.iosUrl ?? app.androidUrl;
    }
    if (url == null) return;

    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _PromoAppSlide extends StatelessWidget {
  final PromoAppItem app;
  final VoidCallback onTap;

  const _PromoAppSlide({required this.app, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final imageUrl = app.bannerUrl ?? app.iconUrl;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 680;
        if (!isDesktop) {
          return _ImageSlide(
            imageUrl: imageUrl,
            badgeLabel: 'ALSO BY US',
            title: app.name,
            subtitle: app.tagline,
            onTap: onTap,
          );
        }

        return InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: Colors.black26),
                placeholder: (_, __) => Container(color: Colors.black12),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.72),
                        Colors.black.withValues(alpha: 0.34),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.48, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 24),
                child: Row(
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const _SlideBadge(label: 'ALSO BY US'),
                          const SizedBox(height: 12),
                          Text(
                            app.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (app.tagline != null && app.tagline!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Text(
                                app.tagline!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 14,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              child: Text(
                                'Open',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (app.bannerUrl != null)
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: SizedBox(
                                width: 86,
                                height: 86,
                                child: CachedNetworkImage(
                                  imageUrl: app.iconUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ImageSlide extends StatelessWidget {
  final String imageUrl;
  final String badgeLabel;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ImageSlide({
    required this.imageUrl,
    required this.badgeLabel,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => Container(color: Colors.black26),
            placeholder: (_, __) => Container(color: Colors.black12),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            child: _SlideBadge(label: badgeLabel),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideBadge extends StatelessWidget {
  final String label;

  const _SlideBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _NewsSlideContent extends StatelessWidget {
  final NewsItemModel news;
  final ThemeData theme;

  const _NewsSlideContent({required this.news, required this.theme});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: news.linkUrl == null ? null : () => _openLink(news.linkUrl!),
      child: ColoredBox(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Row(
          children: [
            if (news.imageUrl != null)
              SizedBox(
                width: 120,
                height: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: news.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: Colors.black12),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'NEWS',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      news.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      news.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
