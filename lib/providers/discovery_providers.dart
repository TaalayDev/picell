import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/models/discovery_api_models.dart';
import 'providers.dart';

part 'discovery_providers.g.dart';

/// Cross-promo ads for the developer's other apps.
@riverpod
class PromoApps extends _$PromoApps {
  @override
  Future<List<PromoAppItem>> build() async {
    final response = await ref.read(discoveryAPIRepoProvider).getPromoApps();
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.error ?? 'Failed to load promo apps');
  }
}

/// News / announcements for the discovery carousel.
@riverpod
class NewsItems extends _$NewsItems {
  @override
  Future<List<NewsItemModel>> build() async {
    final response = await ref.read(discoveryAPIRepoProvider).getNews();
    if (response.success && response.data != null) {
      return response.data!;
    }
    throw Exception(response.error ?? 'Failed to load news');
  }
}
