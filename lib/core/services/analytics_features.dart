import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../providers/providers.dart';

/// Names of user-facing features whose discoverability is measured with the
/// `feature_opened` event. The backend catalog is generated from this class
/// (see tool/export_analytics_catalog.py), so keep one `static const` per line.
abstract final class AnalyticsFeature {
  static const effectsBrowser = 'effects_browser';
  static const effectStore = 'effect_store';
  static const templates = 'templates';
  static const importDialog = 'import';
  static const editorSettings = 'editor_settings';
  static const challenges = 'challenges';
  static const feedback = 'feedback';
}

/// Records that the user opened a feature. Safe to call from `show` helpers
/// that only have a [BuildContext].
void trackFeature(BuildContext context, String feature) {
  try {
    ProviderScope.containerOf(context, listen: false)
        .read(analyticsProvider)
        .logEvent(name: 'feature_opened', parameters: {'feature': feature});
  } catch (_) {}
}
