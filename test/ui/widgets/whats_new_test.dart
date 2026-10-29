import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/models/discovery_api_models.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/providers/discovery_providers.dart';
import 'package:picell/ui/widgets/discovery/whats_new.dart';

class _FakeNewsItems extends NewsItems {
  @override
  Future<List<NewsItemModel>> build() async => [
        NewsItemModel(id: 1, title: 'Big update', excerpt: 'Lots of new stuff.', publishedAt: DateTime(2026, 1, 1)),
        const NewsItemModel(id: 2, title: 'Bone rigs', excerpt: 'Animate with bones.'),
      ];
}

class _EmptyNewsItems extends NewsItems {
  @override
  Future<List<NewsItemModel>> build() async => [];
}

Widget _app(Widget body, {NewsItems Function()? news}) {
  return ProviderScope(
    overrides: [newsItemsProvider.overrideWith(news ?? _FakeNewsItems.new)],
    child: MaterialApp(
      localizationsDelegates: Strings.localizationsDelegates,
      supportedLocales: Strings.supportedLocales,
      home: Scaffold(body: body),
    ),
  );
}

void main() {
  testWidgets('desktop section shows the feature banner', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const WhatsNewSection()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("What's new"), findsOneWidget);
    expect(find.byKey(const ValueKey('whats-new-bone-rig-banner')), findsOneWidget);
    expect(find.text('Bone rigger'), findsOneWidget);
    expect(find.byKey(const ValueKey('whats-new-bone-rig-image')), findsOneWidget);
  });

  testWidgets('the gradient tool leads the list and the titles', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const Column(children: [WhatsNewSection(), WhatsNewTitles()])));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final banner = find.byKey(const ValueKey('whats-new-gradient-banner'));
    expect(banner, findsOneWidget);
    expect(find.byKey(const ValueKey('whats-new-gradient-image')), findsOneWidget);
    expect(
      tester.getTopLeft(banner).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('whats-new-bone-rig-banner'))).dy),
    );
    // Titles: built-in features first, then server news.
    final titles = tester
        .widgetList<Text>(find.descendant(of: find.byKey(const ValueKey('whats-new-titles')), matching: find.byType(Text)))
        .map((t) => t.data)
        .toList();
    expect(titles.take(3), ['Gradient tool', 'Bone rigger', 'Big update']);
  });

  testWidgets('open example button calls back; sheet closes first', (tester) async {
    var opened = 0;
    await tester.pumpWidget(_app(Align(
      alignment: Alignment.topLeft,
      child: WhatsNewButton(onOpenBoneRigExample: () => opened++),
    )));
    await tester.tap(find.byKey(const ValueKey('whats-new-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('whats-new-open-example')));
    await tester.pumpAndSettle();
    expect(opened, 1);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('sheet shows the empty state under the banner', (tester) async {
    await tester.pumpWidget(_app(const WhatsNewButton(), news: _EmptyNewsItems.new));
    await tester.tap(find.byKey(const ValueKey('whats-new-button')));
    await tester.pumpAndSettle();
    expect(find.text('Nothing new yet. Check back soon!'), findsOneWidget);
    expect(find.byKey(const ValueKey('whats-new-bone-rig-banner')), findsOneWidget);
  });

  testWidgets('mobile button opens a bottom sheet with the same content', (tester) async {
    tester.view.physicalSize = const Size(375, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const Align(alignment: Alignment.topLeft, child: WhatsNewButton())));
    await tester.pumpAndSettle();

    expect(find.text('Big update'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('whats-new-button')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byKey(const ValueKey('whats-new-gradient-banner')), findsOneWidget);
    expect(find.byKey(const ValueKey('whats-new-bone-rig-banner')), findsOneWidget);
    // Server news follows the feature banners, below the fold on a phone.
    final list = find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Bone rigs'), 200, scrollable: list);
    expect(find.text('Big update'), findsOneWidget);
    expect(find.text('Bone rigs'), findsOneWidget);
  });
}
