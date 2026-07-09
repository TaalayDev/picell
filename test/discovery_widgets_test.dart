import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/models/discovery_api_models.dart';
import 'package:picell/data/models/project_api_models.dart';
import 'package:picell/data/models/project_model.dart';
import 'package:picell/providers/community_projects_providers.dart';
import 'package:picell/providers/discovery_providers.dart';
import 'package:picell/ui/widgets/discovery/discovery_carousel.dart';
import 'package:picell/ui/widgets/project/sidebar_project_list_item.dart';

class _FakePromoApps extends PromoApps {
  @override
  Future<List<PromoAppItem>> build() async => [
        const PromoAppItem(id: 1, name: 'Other App', tagline: 'Also fun', iconUrl: 'https://example.com/icon.png'),
      ];
}

class _FakeNewsItems extends NewsItems {
  @override
  Future<List<NewsItemModel>> build() async => [
        NewsItemModel(id: 1, title: 'Big update', excerpt: 'Lots of new stuff.', publishedAt: DateTime(2026, 1, 1)),
      ];
}

class _FakeFeaturedProjects extends FeaturedProjects {
  @override
  Future<List<ApiProject>> build() async => [
        ApiProject(id: 10, userId: 1, title: 'Featured Art', width: 32, height: 32, username: 'artist'),
      ];
}

class _FakeTrendingProjects extends TrendingProjects {
  @override
  Future<List<ApiProject>> build() async => [
        ApiProject(id: 11, userId: 2, title: 'Trending Art', width: 16, height: 16, username: 'someone'),
      ];
}

void main() {
  testWidgets('DiscoveryCarousel renders all slide types without error', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promoAppsProvider.overrideWith(_FakePromoApps.new),
          newsItemsProvider.overrideWith(_FakeNewsItems.new),
          featuredProjectsProvider.overrideWith(_FakeFeaturedProjects.new),
          trendingProjectsProvider.overrideWith(_FakeTrendingProjects.new),
        ],
        child: const MaterialApp(
          home: Scaffold(body: DiscoveryCarousel(height: 220)),
        ),
      ),
    );

    // Let the 4 concurrent futures resolve and the carousel build its slides.
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(PageView), findsOneWidget);

    // Advance past the auto-advance timer once to exercise that code path.
    await tester.pump(const Duration(seconds: 7));
    expect(tester.takeException(), isNull);
  });

  testWidgets('DiscoveryCarousel disappears cleanly when every source is empty', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: const MaterialApp(
          home: Scaffold(body: DiscoveryCarousel(height: 220)),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(PageView), findsNothing);
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
