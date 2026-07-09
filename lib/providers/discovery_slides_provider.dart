import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/discovery_api_models.dart';
import '../data/models/project_api_models.dart';
import 'community_projects_providers.dart';
import 'discovery_providers.dart';

part 'discovery_slides_provider.g.dart';

/// A single slide in the discovery carousel. One of: a cross-promo app ad, a
/// featured project, a news item, or a trending "community highlight".
sealed class DiscoverySlide {
  const DiscoverySlide();
}

class PromoAppSlide extends DiscoverySlide {
  final PromoAppItem app;
  const PromoAppSlide(this.app);
}

class FeaturedProjectSlide extends DiscoverySlide {
  final ApiProject project;
  const FeaturedProjectSlide(this.project);
}

class NewsSlide extends DiscoverySlide {
  final NewsItemModel news;
  const NewsSlide(this.news);
}

class CommunityHighlightSlide extends DiscoverySlide {
  final ApiProject project;
  const CommunityHighlightSlide(this.project);
}

/// Combines cross-promo apps, featured projects, news, and trending community
/// projects into one ordered slide list for [DiscoveryCarousel]. Each source
/// is fetched independently and tolerates its own failure — a broken/empty
/// source just contributes no slides rather than blanking the whole carousel.
@riverpod
Future<List<DiscoverySlide>> discoverySlides(DiscoverySlidesRef ref) async {
  final results = await Future.wait([
    ref.watch(promoAppsProvider.future).catchError((_) => <PromoAppItem>[]),
    ref.watch(featuredProjectsProvider.future).catchError((_) => <ApiProject>[]),
    ref.watch(newsItemsProvider.future).catchError((_) => <NewsItemModel>[]),
    ref.watch(trendingProjectsProvider.future).catchError((_) => <ApiProject>[]),
  ]);

  final promos = results[0] as List<PromoAppItem>;
  final featured = results[1] as List<ApiProject>;
  final news = results[2] as List<NewsItemModel>;
  // "Community highlight" reuses TrendingProjects (recently popular) rather
  // than adding a separate backend endpoint/flag for a largely overlapping
  // concept.
  final community = results[3] as List<ApiProject>;

  // Fixed round-robin: ad -> featured -> news -> community -> repeat,
  // skipping any exhausted source, so cross-promo gets regular airtime
  // without ever showing two ads back-to-back.
  final slides = <DiscoverySlide>[];
  var pi = 0, fi = 0, ni = 0, ci = 0;
  while (pi < promos.length || fi < featured.length || ni < news.length || ci < community.length) {
    if (pi < promos.length) slides.add(PromoAppSlide(promos[pi++]));
    if (fi < featured.length) slides.add(FeaturedProjectSlide(featured[fi++]));
    if (ni < news.length) slides.add(NewsSlide(news[ni++]));
    if (ci < community.length) slides.add(CommunityHighlightSlide(community[ci++]));
  }

  return slides;
}
