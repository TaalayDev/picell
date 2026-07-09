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
    final pageController = usePageController(viewportFraction: 0.92);
    final currentPage = useState(0);
    final timerRef = useRef<Timer?>(null);

    void restartTimer() {
      timerRef.value?.cancel();
      timerRef.value = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!pageController.hasClients) return;
        final next = (currentPage.value + 1) % slides.length;
        pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }

    useEffect(() {
      restartTimer();
      return () => timerRef.value?.cancel();
      // ignore: exhaustive_keys
    }, [slides.length]);

    return MouseRegion(
      onEnter: (_) => timerRef.value?.cancel(),
      onExit: (_) => restartTimer(),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            PageView.builder(
              controller: pageController,
              itemCount: slides.length,
              onPageChanged: (i) {
                currentPage.value = i;
                restartTimer();
              },
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _SlideCard(slide: slides[index]),
                  ),
                );
              },
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
                      pageController.animateToPage(
                        prev,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
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
                      final next = (currentPage.value + 1) % slides.length;
                      pageController.animateToPage(
                        next,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
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
        ),
      ),
    );
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
      PromoAppSlide(:final app) => _ImageSlide(
          imageUrl: app.bannerUrl ?? app.iconUrl,
          badgeLabel: 'ALSO BY US',
          title: app.name,
          subtitle: app.tagline,
          onTap: () => _openPromoApp(app),
        ),
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badgeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
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

class _NewsSlideContent extends StatelessWidget {
  final NewsItemModel news;
  final ThemeData theme;

  const _NewsSlideContent({required this.news, required this.theme});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: news.linkUrl == null ? null : () => _openLink(news.linkUrl!),
      child: Container(
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
