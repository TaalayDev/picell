import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/app/theme/pv_tokens.dart';
import 'package:picell/app/theme/theme.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_collection_screen.dart';

void main() {
  testWidgets('collection setup text follows the active theme', (tester) async {
    PvTokens.useDesignFonts = false;
    addTearDown(() => PvTokens.useDesignFonts = true);
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey<TilesetCollectionScreenState>();
    for (final type in [ThemeType.neon, ThemeType.darkMode, ThemeType.lightMode]) {
      final theme = AppTheme.fromType(type);
      await tester.pumpWidget(MaterialApp(
        theme: theme.themeData,
        home: TilesetCollectionScreen(key: key, embedded: true),
      ));
      await tester.pumpAndSettle();
      for (final label in [
        'Set up your tileset project',
        'Perspective',
        'Tile size',
        'Side View',
        'Top-Down',
        'Isometric'
      ]) {
        expect(tester.widget<Text>(find.text(label)).style?.color, theme.textPrimary, reason: '$type: $label');
      }
      for (final label in [
        'Choose the perspective and tile size first. They apply to every tileset in this project.',
        'Platformers and side-scrollers',
        'RPGs and strategy maps',
        '2:1 diamond grid with raised faces',
        'Every tileset in this project uses these values.',
      ]) {
        expect(tester.widget<Text>(find.text(label)).style?.color, theme.textSecondary, reason: '$type: $label');
      }
      await tester.tap(find.text('Isometric'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.text('Size is the logical diamond height. Sprite width is twice this value.'))
            .style
            ?.color,
        theme.textSecondary,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
