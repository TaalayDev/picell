import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Public announcement topics only; private user messages must use device tokens.
class PushNotificationService {
  PushNotificationService({FirebaseMessaging? messaging})
      : _messaging = messaging;

  final FirebaseMessaging? _messaging;
  FirebaseMessaging get _client => _messaging ?? FirebaseMessaging.instance;
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static const allTopic = 'picell_announcements';
  static String get platformTopic => defaultTargetPlatform == TargetPlatform.iOS
      ? 'picell_announcements_ios'
      : 'picell_announcements_android';

  StreamSubscription<String>? _tokenSubscription;
  bool _refreshing = false;
  bool _disposed = false;

  Future<void> initialize() async {
    if (!supported || _disposed) return;
    _tokenSubscription ??= _client.onTokenRefresh.listen(
      (_) => unawaited(refresh()),
      onError: (Object error) =>
          debugPrint('Push token refresh failed: $error'),
    );
    await refresh(requestPermission: true);
  }

  Future<void> refresh({bool requestPermission = false}) async {
    if (!supported || _disposed || _refreshing) return;
    _refreshing = true;
    try {
      final messaging = _client;
      var permission = await messaging.getNotificationSettings();
      if (requestPermission &&
          permission.authorizationStatus == AuthorizationStatus.notDetermined) {
        permission = await messaging.requestPermission(
            alert: true, badge: true, sound: true);
      }
      if (_disposed) return;
      // iOS APNs registration may finish after the permission prompt. Wait for
      // it before calling any FCM APIs, then retry on the next app resume if needed.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken;
        for (var attempt = 0; attempt < 10 && !_disposed; attempt++) {
          apnsToken = await messaging.getAPNSToken();
          if (apnsToken != null) break;
          await Future<void>.delayed(const Duration(seconds: 1));
        }
        if (_disposed || apnsToken == null) return;
      }
      final allowed =
          permission.authorizationStatus == AuthorizationStatus.authorized ||
              permission.authorizationStatus == AuthorizationStatus.provisional;
      if (!allowed) {
        await messaging.unsubscribeFromTopic(allTopic);
        await messaging.unsubscribeFromTopic(platformTopic);
        return;
      }
      // Foreground messages are shown using the app's existing notification UI.
      await messaging.setForegroundNotificationPresentationOptions(
          alert: false, badge: true, sound: true);
      final token = await messaging.getToken();
      if (token == null || _disposed) return;
      await messaging.subscribeToTopic(allTopic);
      if (_disposed) return;
      await messaging.subscribeToTopic(platformTopic);
    } catch (error) {
      // A missing APNs key, unavailable Play Services, or offline device must
      // never stop users from opening the editor.
      debugPrint('Push notification setup failed: $error');
    } finally {
      _refreshing = false;
    }
  }

  void dispose() {
    _disposed = true;
    unawaited(_tokenSubscription?.cancel());
  }
}
