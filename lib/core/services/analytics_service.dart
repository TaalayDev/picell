import 'package:firebase_analytics/firebase_analytics.dart';

/// Sends product analytics to Firebase.
class AnalyticsService {
  AnalyticsService(this._firebaseAnalytics);

  final FirebaseAnalytics _firebaseAnalytics;

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) {
    return _firebaseAnalytics.logEvent(name: name, parameters: parameters);
  }
}
