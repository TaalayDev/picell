import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:picell/app/theme/theme.dart';
import 'package:picell/ui/widgets/animated_background.dart';

const Size _surfaceSize = Size(1280, 720);
const int _warmUpFrameCount = 20;
const int _measuredFrameCount = 90;
const Duration _frameStep = Duration(milliseconds: 16);
const double _themeIntensity = 1.0;
const String _themeFilter = String.fromEnvironment(
  'THEME_PERF_FILTER',
  defaultValue: '',
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;

  final themeTypes = ThemeType.values
      .where(_isAnimatedTheme)
      .where(_matchesThemeFilter)
      .toList(growable: false);
  final collectedSummaries = <Map<String, dynamic>>[];

  setUpAll(() async {
    await binding.setSurfaceSize(_surfaceSize);
    binding.reportData = <String, dynamic>{
      'theme_background_perf_config': <String, dynamic>{
        'surface_width': _surfaceSize.width,
        'surface_height': _surfaceSize.height,
        'warm_up_frame_count': _warmUpFrameCount,
        'measured_frame_count': _measuredFrameCount,
        'frame_step_millis': _frameStep.inMilliseconds,
        'intensity': _themeIntensity,
        'theme_filter': _themeFilter,
      },
    };
  });

  tearDownAll(() async {
    final ranking = List<Map<String, dynamic>>.from(collectedSummaries)
      ..sort(
        (a, b) => (b['score'] as num).compareTo(a['score'] as num),
      );

    binding.reportData ??= <String, dynamic>{};
    binding.reportData!['theme_background_perf_summary'] = collectedSummaries;
    binding.reportData!['theme_background_perf_ranking'] = ranking;
    await binding.setSurfaceSize(null);
  });

  testWidgets('records frame timings for animated theme backgrounds',
      (tester) async {
    expect(
      themeTypes,
      isNotEmpty,
      reason:
          'Theme filter "$_themeFilter" excluded every animated theme. Clear it or pick an existing theme name.',
    );

    for (final themeType in themeTypes) {
      final appTheme = AppTheme.fromType(themeType);
      final reportKey = 'theme_background_${themeType.name}';

      await tester.pumpWidget(
        _ThemeBackgroundPerfHarness(appTheme: appTheme),
      );
      await tester.pump();
      await _pumpFrames(tester, _warmUpFrameCount);

      await binding.watchPerformance(
        () async {
          await _pumpFrames(tester, _measuredFrameCount);
        },
        reportKey: reportKey,
      );

      final rawMetrics =
          Map<String, dynamic>.from(binding.reportData![reportKey] as Map);
      expect(rawMetrics['frame_count'], greaterThan(0));

      collectedSummaries.add(_buildCompactSummary(themeType, rawMetrics));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });
}

bool _isAnimatedTheme(ThemeType type) {
  return type != ThemeType.darkMode && type != ThemeType.lightMode;
}

bool _matchesThemeFilter(ThemeType type) {
  final normalizedFilter = _themeFilter.trim().toLowerCase();
  if (normalizedFilter.isEmpty) {
    return true;
  }

  final tokens = normalizedFilter
      .split(',')
      .map((token) => token.trim())
      .where((token) => token.isNotEmpty);
  final themeName = type.name.toLowerCase();
  final displayName = type.displayName.toLowerCase();

  return tokens.any(
    (token) => themeName == token || displayName.contains(token),
  );
}

Future<void> _pumpFrames(WidgetTester tester, int frameCount) async {
  for (var i = 0; i < frameCount; i++) {
    await tester.pump(_frameStep);
  }
}

Map<String, dynamic> _buildCompactSummary(
  ThemeType themeType,
  Map<String, dynamic> metrics,
) {
  final averageBuild =
      (metrics['average_frame_build_time_millis'] as num?)?.toDouble() ?? 0.0;
  final worstBuild =
      (metrics['worst_frame_build_time_millis'] as num?)?.toDouble() ?? 0.0;
  final averageRaster =
      (metrics['average_frame_rasterizer_time_millis'] as num?)?.toDouble() ??
          0.0;
  final worstRaster =
      (metrics['worst_frame_rasterizer_time_millis'] as num?)?.toDouble() ??
          0.0;
  final missedBuild = (metrics['missed_frame_build_budget_count'] as num?) ?? 0;
  final missedRaster =
      (metrics['missed_frame_rasterizer_budget_count'] as num?) ?? 0;
  final score = averageBuild +
      averageRaster +
      worstBuild * 0.35 +
      worstRaster * 0.65 +
      missedBuild * 8 +
      missedRaster * 12;

  return <String, dynamic>{
    'theme': themeType.name,
    'display_name': themeType.displayName,
    'frame_count': metrics['frame_count'],
    'average_frame_build_time_millis': averageBuild,
    'average_frame_rasterizer_time_millis': averageRaster,
    'worst_frame_build_time_millis': worstBuild,
    'worst_frame_rasterizer_time_millis': worstRaster,
    'missed_frame_build_budget_count': missedBuild,
    'missed_frame_rasterizer_budget_count': missedRaster,
    'average_layer_cache_memory': metrics['average_layer_cache_memory'],
    'average_picture_cache_memory': metrics['average_picture_cache_memory'],
    'new_gen_gc_count': metrics['new_gen_gc_count'],
    'old_gen_gc_count': metrics['old_gen_gc_count'],
    'score': score,
  };
}

class _ThemeBackgroundPerfHarness extends StatelessWidget {
  final AppTheme appTheme;

  const _ThemeBackgroundPerfHarness({
    required this.appTheme,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: appTheme.themeData,
        home: Scaffold(
          body: AnimatedBackground(
            appTheme: appTheme,
            intensity: _themeIntensity,
            enableAnimation: true,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}
