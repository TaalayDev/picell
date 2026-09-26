import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/effects/effect_list_item.dart';
import 'package:picell/ui/widgets/effects/effects_side_panel.dart';
import 'package:picell/ui/widgets/layers_panel.dart';

void main() {
  Widget testApp(Widget child) => ProviderScope(
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(body: SizedBox(width: 320, height: 600, child: child)),
        ),
      );

  Future<void> pressSelectAll(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  testWidgets('Ctrl+A selects every layer in the focused layers panel',
      (tester) async {
    final layers = List.generate(
      3,
      (index) => Layer(
        layerId: index + 1,
        id: 'layer-$index',
        name: 'Layer $index',
        pixels: Uint32List(4),
        order: index,
      ),
    );
    List<int>? copied;

    await tester.pumpWidget(
      testApp(
        LayersPanel(
          width: 2,
          height: 2,
          layers: layers,
          activeLayerIndex: 0,
          onLayerAdded: (_) {},
          onLayerSelected: (_) {},
          onLayersDeleted: (_) {},
          onLayersVisibilityChanged: (_, __) {},
          onLayersLockedChanged: (_, __) {},
          onLayersDuplicated: (indices) => copied = List.of(indices),
          onLayerReordered: (_, __) {},
          onLayersOpacityChanged: (_, __) {},
          onLayerUpdated: (_) {},
          onLayerToTemplate: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('layer-0')));
    await pressSelectAll(tester);
    await tester.tap(find.byIcon(Icons.copy));

    expect(copied, [0, 1, 2]);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Ctrl+A selects every effect in the focused effects panel',
      (tester) async {
    final layer = Layer(
      layerId: 1,
      id: 'layer',
      name: 'Layer',
      pixels: Uint32List(4),
      effects: [
        BrightnessEffect({'value': 0.1}),
        BrightnessEffect({'value': 0.2}),
        BrightnessEffect({'value': 0.3}),
      ],
    );

    await tester.pumpWidget(
      testApp(
        EffectsSidePanel(
          layer: layer,
          width: 2,
          height: 2,
          onLayerUpdated: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(EffectListItem).first);
    await pressSelectAll(tester);

    final items =
        tester.widgetList<EffectListItem>(find.byType(EffectListItem));
    expect(items, hasLength(3));
    expect(items.every((item) => item.isSelected), isTrue);
  });
}
