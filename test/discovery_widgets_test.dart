import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/core/utils/api_client.dart';
import 'package:picell/data/models/api_models.dart';
import 'package:picell/data/models/discovery_api_models.dart';
import 'package:picell/data/models/project_api_models.dart';
import 'package:picell/data/models/project_model.dart';
import 'package:picell/data/repo/discovery_api_repo.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:picell/providers/community_projects_providers.dart';
import 'package:picell/providers/discovery_providers.dart';
import 'package:picell/providers/providers.dart';
import 'package:picell/ui/widgets/discovery/discovery_carousel.dart';
import 'package:picell/ui/widgets/project/sidebar_project_list_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePromoApps extends PromoApps {
  @override
  Future<List<PromoAppItem>> build() async => [
        const PromoAppItem(id: 1, name: 'Other App', tagline: 'Also fun', iconUrl: 'https://example.com/icon.png'),
      ];
}

class _EmptyPromoApps extends PromoApps {
  @override
  Future<List<PromoAppItem>> build() async => [];
}

class _FakeNewsItems extends NewsItems {
  @override
  Future<List<NewsItemModel>> build() async => [
        NewsItemModel(id: 1, title: 'Big update', excerpt: 'Lots of new stuff.', publishedAt: DateTime(2026, 1, 1)),
      ];
}

class _EmptyNewsItems extends NewsItems {
  @override
  Future<List<NewsItemModel>> build() async => [];
}

class _FakeFeaturedProjects extends FeaturedProjects {
  @override
  Future<List<ApiProject>> build() async => [
        ApiProject(id: 10, userId: 1, title: 'Featured Art', width: 32, height: 32, username: 'artist'),
      ];
}

class _EmptyFeaturedProjects extends FeaturedProjects {
  @override
  Future<List<ApiProject>> build() async => [];
}

class _FakeTrendingProjects extends TrendingProjects {
  @override
  Future<List<ApiProject>> build() async => [
        ApiProject(id: 11, userId: 2, title: 'Trending Art', width: 16, height: 16, username: 'someone'),
      ];
}

class _EmptyTrendingProjects extends TrendingProjects {
  @override
  Future<List<ApiProject>> build() async => [];
}

class _FakeDiscoveryAPIRepo extends DiscoveryAPIRepo {
  _FakeDiscoveryAPIRepo(LocalStorage storage) : super(ApiClient('https://example.com', storage: storage));

  final impressionAppIds = <int>[];

  @override
  Future<ApiResponse<Map<String, dynamic>>> recordPromoAppImpression(int appId, String installationId) async {
    impressionAppIds.add(appId);
    return const ApiResponse(success: true, data: {'first_seen': true}, timestamp: 0);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  testWidgets('DiscoveryCarousel renders all slide types without error', (tester) async {
    final discoveryRepo = _FakeDiscoveryAPIRepo(LocalStorage());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promoAppsProvider.overrideWith(_FakePromoApps.new),
          newsItemsProvider.overrideWith(_FakeNewsItems.new),
          featuredProjectsProvider.overrideWith(_FakeFeaturedProjects.new),
          trendingProjectsProvider.overrideWith(_FakeTrendingProjects.new),
          discoveryAPIRepoProvider.overrideWithValue(discoveryRepo),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DiscoveryCarousel(height: 220)),
        ),
      ),
    );

    // Let the 4 concurrent futures resolve and the carousel build its slides.
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CarouselView), findsOneWidget);
    expect(discoveryRepo.impressionAppIds, [1]);
    final carousel = tester.widget<CarouselView>(find.byType(CarouselView));
    expect(tester.getSize(find.byType(CarouselView)).width, 600);
    expect(carousel.flexWeights, [1, 6, 1]);
    expect(carousel.itemCount, greaterThan(4));
    expect(carousel.controller!.initialItem, greaterThan(0));

    // Advance past the auto-advance timer once to exercise that code path.
    await tester.pump(const Duration(seconds: 7));
    expect(tester.takeException(), isNull);
  });

  testWidgets('DiscoveryCarousel disappears cleanly when every source is empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promoAppsProvider.overrideWith(_EmptyPromoApps.new),
          newsItemsProvider.overrideWith(_EmptyNewsItems.new),
          featuredProjectsProvider.overrideWith(_EmptyFeaturedProjects.new),
          trendingProjectsProvider.overrideWith(_EmptyTrendingProjects.new),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DiscoveryCarousel(height: 220)),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(CarouselView), findsNothing);
  });

  testWidgets('SidebarProjectListItem renders without overflow', (tester) async {
    final project = Project(
      id: 1,
      name: 'My Pixel Project',
      width: 32,
      height: 32,
      createdAt: DateTime(2026, 1, 1),
      // A couple of hours ago, not "just now" — avoids the justNow string
      // needing full l10n delegate setup in this isolated widget test.
      editedAt: DateTime.now().subtract(const Duration(hours: 2)),
      isCloudSynced: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 272,
            child: SidebarProjectListItem(project: project, onTap: () {}),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('My Pixel Project'), findsOneWidget);
  });
}
