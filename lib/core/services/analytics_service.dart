import 'package:amplitude_flutter/amplitude.dart';
import 'package:amplitude_flutter/configuration.dart';
import 'package:amplitude_flutter/events/base_event.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Sends product analytics to Firebase and, when configured, Amplitude.
///
/// Keeping a single service means existing event instrumentation is delivered
/// to both providers while Amplitude is rolled out. Amplitude is intentionally
/// disabled when no API key is supplied, so local and test builds remain safe.
class AnalyticsService {
  AnalyticsService(this._firebaseAnalytics);

  final FirebaseAnalytics _firebaseAnalytics;
  Amplitude? _amplitude;

  bool get isAmplitudeEnabled => _amplitude != null;

  Future<void> initializeAmplitude(String? apiKey) async {
    final normalizedApiKey = apiKey?.trim();
    if (normalizedApiKey == null || normalizedApiKey.isEmpty) {
      return;
    }

    final amplitude = Amplitude(Configuration(apiKey: normalizedApiKey));
    await amplitude.isBuilt;
    _amplitude = amplitude;
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _firebaseAnalytics.logEvent(name: name, parameters: parameters);

    _amplitude?.track(
      BaseEvent(
        name,
        eventProperties: parameters,
      ),
    );
  }

  Future<void> flush() async {
    await _amplitude?.flush();
  }
}
