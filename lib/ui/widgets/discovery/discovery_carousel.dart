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
import '../../screens/project_detail_screen.dart';

/// Auto-advancing carousel cycling through cross-promo app ads, featured
/// projects, news, and trending "community highlight" projects. Purely
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

class _CarouselBody extends HookWidget {
  final List<DiscoverySlide> slides;
  final double height;
  final bool showArrows;

  const _CarouselBody({
    required this.slides,
    required this.height,
    required this.showArrows,
  });

  @override
  Widget build(BuildContext context) {
    final carouselController = useMemoized(() => CarouselController());
    final currentPage = useState(0);
    final timerRef = useRef<Timer?>(null);

    void goToSlide(int index, {Duration duration = const Duration(milliseconds: 450)}) {
      final next = index.clamp(0, slides.length - 1);
      currentPage.value = next;
      carouselController.animateToItem(
        next,
        duration: duration,
        curve: Curves.easeInOut,
      );
    }

    void restartTimer() {
      timerRef.value?.cancel();
      timerRef.value = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!carouselController.hasClients) return;
        final next = (currentPage.value + 1) % slides.length;
        goToSlide(next, duration: const Duration(milliseconds: 500));
      });
    }

    useEffect(() {
      restartTimer();
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemExtent = _carouselItemExtent(constraints.maxWidth);

              return Stack(
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.axis != Axis.horizontal) {
                        return false;
                      }
                      final nextPage = (notification.metrics.pixels / itemExtent).round().clamp(0, slides.length - 1);
                      if (currentPage.value != nextPage) {
                        currentPage.value = nextPage;
                      }
                      if (notification is ScrollEndNotification) {
                        restartTimer();
                      }
                      return false;
                    },
                    child: CarouselView(
                      controller: carouselController,
                      itemExtent: itemExtent,
                      itemSnapping: true,
                      shrinkExtent: 96,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      itemClipBehavior: Clip.antiAlias,
                      enableSplash: false,
                      children: [
                        for (final slide in slides)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _SlideCard(slide: slide),
                          ),
                      ],
                    ),
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
                            final prev = (currentPage.value - 1 + slides.length) % slides.length;
                            goToSlide(prev, duration: const Duration(milliseconds: 400));
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
                            final next = (currentPage.value + 1) % slides.length;
                            goToSlide(next, duration: const Duration(milliseconds: 400));
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

class _SlideCard extends StatelessWidget {
  final DiscoverySlide slide;

  const _SlideCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return switch (slide) {
      PromoAppSlide(:final app) => _PromoAppSlide(app: app, onTap: () => _openPromoApp(app)),
      FeaturedProjectSlide(:final project) => _ImageSlide(
          imageUrl: project.thumbnailUrl,
          badgeLabel: 'FEATURED',
          title: project.title,
          subtitle: project.displayName ?? project.username,
          onTap: () => _openProject(context, project),
        ),
      CommunityHighlightSlide(:final project) => _ImageSlide(
          imageUrl: project.thumbnailUrl,
          badgeLabel: 'COMMUNITY',
          title: project.title,
          subtitle: project.displayName ?? project.username,
          onTap: () => _openProject(context, project),
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
