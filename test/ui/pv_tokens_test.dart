import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/app/theme/theme.dart';
import 'package:picell/ui/widgets/pv/pv.dart';

void main() {
  testWidgets('theme data exposes PvTokens derived from the AppTheme', (tester) async {
    final theme = AppTheme.defaultTheme;
    final tokens = theme.themeData.extension<PvTokens>();
    expect(tokens, isNotNull);
    expect(tokens!.primary, theme.primaryColor);
    expect(tokens.gradient.colors, [theme.primaryColor, theme.accentColor]);
  });

  test('PixelCutBorder outer path stays inside the rect and is closed', () {
    const rect = Rect.fromLTWH(0, 0, 100, 40);
    final path = const PixelCutBorder().getOuterPath(rect);
    final b = path.getBounds();
    expect(b, rect);
    expect(path.contains(const Offset(50, 20)), isTrue);
    expect(path.contains(const Offset(0.5, 0.5)), isFalse);
    expect(path.contains(const Offset(99.5, 39.5)), isFalse);
  });

  testWidgets('PvChip, PvShimmerBox and PvCheckerboard build', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.defaultTheme.themeData,
      home: const Column(children: [
        PvChip(label: 'Synced', icon: Icons.cloud_done),
        PvShimmerBox(width: 40, height: 40),
        SizedBox(width: 40, height: 40, child: PvCheckerboard()),
      ]),
    ));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });
}
