import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:picell/pixel/gradient/gradient_options.dart';
import 'package:picell/pixel/gradient/gradient_renderer.dart';
import 'package:picell/pixel/tools/gradient_tool.dart';
import 'package:picell/providers/editor_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  group('EditorSettings gradient', () {
    test('defaults are pixel-art friendly', () {
      final o = const EditorSettings().gradientOptions;
      expect(o.steps, 6);
      expect(o.dither, GradientDither.bayer4);
      expect(o.endColor, const Color(0xFFFFFFFF));
    });

    test('0 steps means smooth; transparent end ignores secondary', () {
      final o = const EditorSettings(
        gradientSteps: 0,
        gradientEnd: GradientEnd.transparent,
        secondaryColor: Color(0xFFFF0000),
      ).gradientOptions;
      expect(o.steps, isNull);
      expect(o.endColor.a, 0);
    });

    test('settings persist across notifier instances', () {
      var container = ProviderContainer();
      final n = container.read(editorSettingsNotifierProvider.notifier);
      n.setSecondaryColor(const Color(0xFF123456));
      n.setGradientType(GradientType.radial);
      n.setGradientTarget(GradientTarget.contiguous);
      n.setGradientEnd(GradientEnd.transparent);
      n.setGradientSteps(12);
      n.setGradientDither(GradientDither.bayer8);
      n.setGradientDitherSpread(0.3);
      n.setGradientBlend(GradientBlend.lockAlpha);
      container.dispose();

      container = ProviderContainer();
      final s = container.read(editorSettingsNotifierProvider);
      expect(s.secondaryColor, const Color(0xFF123456));
      expect(s.gradientType, GradientType.radial);
      expect(s.gradientTarget, GradientTarget.contiguous);
      expect(s.gradientEnd, GradientEnd.transparent);
      expect(s.gradientSteps, 12);
      expect(s.gradientDither, GradientDither.bayer8);
      expect(s.gradientDitherSpread, closeTo(0.3, 1e-9));
      expect(s.gradientBlend, GradientBlend.lockAlpha);
      container.dispose();
    });
  });

  group('color ramp', () {
    const ramp = [Color(0xFF1A1C2C), Color(0xFF5D275D), Color(0xFFB13E53)];

    test('ramp mode uses the colors verbatim as bands', () {
      final o = const EditorSettings(
        gradientEnd: GradientEnd.ramp,
        gradientRamp: ramp,
        gradientSteps: 0,
      ).gradientOptions;
      expect(o.stops, ramp);
      expect(o.steps, 3);
    });

    test('a ramp with fewer than two colors falls back to secondary', () {
      final o = const EditorSettings(
        gradientEnd: GradientEnd.ramp,
        gradientRamp: [Color(0xFF1A1C2C)],
      ).gradientOptions;
      expect(o.stops, isNull);
      expect(o.endColor, const Color(0xFFFFFFFF));
    });

    test('ramp persists and is capped', () {
      var container = ProviderContainer();
      container.read(editorSettingsNotifierProvider.notifier).setGradientRamp([
        for (var i = 0; i < kMaxGradientRampColors + 4; i++) Color(0xFF000000 | i),
      ]);
      container.dispose();
      container = ProviderContainer();
      final saved = container.read(editorSettingsNotifierProvider).gradientRamp;
      expect(saved.length, kMaxGradientRampColors);
      expect(saved[3], const Color(0xFF000003));
      container.dispose();
    });
  });

  group('GradientTool.snapAngle', () {
    test('snaps to the nearest 15° and keeps length', () {
      const start = Offset(10, 10);
      final snapped = GradientTool.snapAngle(start, const Offset(20, 11));
      expect(snapped.dy, closeTo(10, 1e-9));
      expect((snapped - start).distance, closeTo((const Offset(10, 1)).distance, 1e-9));

      final diag = GradientTool.snapAngle(start, const Offset(19, 20.5));
      expect((diag - start).direction, closeTo(0.7853981634, 1e-9));
    });

    test('zero-length drag is unchanged', () {
      expect(GradientTool.snapAngle(const Offset(3, 3), const Offset(3, 3)), const Offset(3, 3));
    });
  });
}
