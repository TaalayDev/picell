import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/core/services/push_notification_service.dart';

class _Permission implements NotificationSettings {
  _Permission(this.authorizationStatus);
  @override
  final AuthorizationStatus authorizationStatus;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Messaging implements FirebaseMessaging {
  var permission = AuthorizationStatus.authorized;
  var offline = false;
  final calls = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final method = invocation.memberName;
    if (method == #onTokenRefresh) return const Stream<String>.empty();
    if (method == #getNotificationSettings) {
      return Future<NotificationSettings>.value(_Permission(permission));
    }
    if (method == #requestPermission) {
      calls.add('permission');
      permission = AuthorizationStatus.authorized;
      return Future<NotificationSettings>.value(_Permission(permission));
    }
    if (method == #getAPNSToken) {
      calls.add('apns');
      return Future<String?>.value('apns-token');
    }
    if (method == #getToken) {
      calls.add('token');
      return offline
          ? Future<String?>.error(Exception('offline'))
          : Future<String?>.value('fcm-token');
    }
    if (method == #subscribeToTopic || method == #unsubscribeFromTopic) {
      calls.add(
          '${method == #subscribeToTopic ? 'subscribe' : 'unsubscribe'}:${invocation.positionalArguments.first}');
      return Future<void>.value();
    }
    if (method == #setForegroundNotificationPresentationOptions) {
      return Future<void>.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('permission prompt and Android subscriptions initialize once', () async {
    final messaging = _Messaging()
      ..permission = AuthorizationStatus.notDetermined;
    final service = PushNotificationService(messaging: messaging);
    addTearDown(service.dispose);
    await service.initialize();
    expect(messaging.calls, [
      'permission',
      'token',
      'subscribe:picell_announcements',
      'subscribe:picell_announcements_android'
    ]);
    await service.refresh();
    expect(messaging.calls.where((call) => call == 'permission').length, 1);
  });

  test('denied permission removes topic subscriptions without prompting',
      () async {
    final messaging = _Messaging()..permission = AuthorizationStatus.denied;
    final service = PushNotificationService(messaging: messaging);
    addTearDown(service.dispose);
    await service.initialize();
    expect(messaging.calls, [
      'unsubscribe:picell_announcements',
      'unsubscribe:picell_announcements_android'
    ]);
  });

  test('iOS obtains APNs token before subscribing to its platform topic',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final messaging = _Messaging();
    final service = PushNotificationService(messaging: messaging);
    addTearDown(service.dispose);
    await service.initialize();
    expect(messaging.calls, [
      'apns',
      'token',
      'subscribe:picell_announcements',
      'subscribe:picell_announcements_ios'
    ]);
  });

  test('offline failure can retry on resume and desktop never initializes FCM',
      () async {
    final messaging = _Messaging()..offline = true;
    final service = PushNotificationService(messaging: messaging);
    addTearDown(service.dispose);
    await service.initialize();
    expect(messaging.calls, ['token']);
    messaging.offline = false;
    await service.refresh();
    expect(messaging.calls.last, 'subscribe:picell_announcements_android');
    messaging.calls.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await service.refresh();
    expect(messaging.calls, isEmpty);
  });
}
