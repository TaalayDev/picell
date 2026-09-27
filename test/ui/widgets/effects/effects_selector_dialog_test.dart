import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/effects/effects_selector_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  testWidgets('Materials workspace exposes silhouette-preserving effects',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(
            body: EffectSelectorDialog(onEffectSelected: (_) {}),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Materials'));
    await tester.pump();

    final search = find.byType(TextField);
    for (final name in [
      'Rust & Corrosion',
      'Worn Fabric',
      'Cracked Ceramic',
      'Moss & Lichen',
      'Paint Peeling',
      'Perlin Worms',
      'Voronoi',
    ]) {
      await tester.enterText(search, name);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text(name),
        ),
        findsOneWidget,
      );
    }

    expect(
      find.byKey(const ValueKey('effect-preview-voronoi')),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey('effect-icon-preview-voronoi')),
      findsOneWidget,
    );
  });

  testWidgets('locked functional workspaces expose only their own effects',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const cases = [
      (EffectWorkspace.filters, FilterKind.filter, null, 'Paper Cutout'),
      (
        EffectWorkspace.filters,
        FilterKind.distortion,
        null,
        'Isometric Extrusion'
      ),
      (EffectWorkspace.materials, null, null, 'Rust & Corrosion'),
      (EffectWorkspace.generators, null, null, 'Mountain Range'),
      (
        EffectWorkspace.animation,
        null,
        AnimationKind.transformer,
        'Kaleidoscope'
      ),
      (EffectWorkspace.lighting, null, null, 'Glow'),
    ];

    for (final entry in cases) {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: Strings.localizationsDelegates,
            supportedLocales: Strings.supportedLocales,
            home: Scaffold(
              body: EffectSelectorDialog(
                initialWorkspace: entry.$1,
                lockWorkspace: true,
                initialFilterKind: entry.$2,
                lockFilterKind: entry.$2 != null,
                initialAnimationKind: entry.$3,
                lockAnimationKind: entry.$3 != null,
                onEffectSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ChoiceChip), findsNothing);

      await tester.enterText(find.byType(TextField), entry.$4);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text(entry.$4),
        ),
        findsOneWidget,
        reason: entry.$1.name,
      );
    }
  });

  testWidgets('animation selector separates transformers and special effects',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(
            body: EffectSelectorDialog(
              initialWorkspace: EffectWorkspace.animation,
              lockWorkspace: true,
              onEffectSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('animation-kind-transformer')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('animation-kind-specialEffect')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('animation-kind-transformer')),
    );
    await tester.enterText(find.byType(TextField), 'Fire');
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(GridView),
        matching: find.text('Fire'),
      ),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('animation-kind-specialEffect')),
    );
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(GridView),
        matching: find.text('Fire'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('effect-preview-fire')), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Hologram Glitch');
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(GridView),
        matching: find.text('Hologram Glitch & Flicker'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
      'Frost Glaze & Crystal Freeze is in animation special effects and not materials',
      (tester) async {
    final descriptor = EffectCatalog.forType(EffectType.frostGlaze);
    expect(descriptor.workspace, EffectWorkspace.animation);
    expect(descriptor.animationKind, AnimationKind.specialEffect);

    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Verify not in materials
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(
            body: EffectSelectorDialog(
              initialWorkspace: EffectWorkspace.materials,
              lockWorkspace: true,
              onEffectSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Frost Glaze');
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(GridView),
        matching: find.text('Frost Glaze & Crystal Freeze'),
      ),
      findsNothing,
    );

    // Verify in animation special effects
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(
            body: EffectSelectorDialog(
              key: const ValueKey('special-effects-dialog'),
              initialWorkspace: EffectWorkspace.animation,
              lockWorkspace: true,
              initialAnimationKind: AnimationKind.specialEffect,
              lockAnimationKind: true,
              onEffectSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Frost Glaze');
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(GridView),
        matching: find.text('Frost Glaze & Crystal Freeze'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('explains why an effect cannot be added to the current layer',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    var selected = false;
    final emptyLayer = Layer(
      layerId: 1,
      id: 'empty',
      name: 'Empty',
      pixels: Uint32List(16),
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(
            body: EffectSelectorDialog(
              initialWorkspace: EffectWorkspace.filters,
              lockWorkspace: true,
              layer: emptyLayer,
              onEffectSelected: (_) => selected = true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Brightness');
    await tester.pump();

    await tester.tap(
      find.descendant(
        of: find.byType(GridView),
        matching: find.text('Brightness'),
      ),
    );
    await tester.pump();

    expect(selected, isFalse);
    expect(
      find.text(
          'This effect needs visible pixels or a generator on the layer.'),
      findsOneWidget,
    );
  });
}
