import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../core/services/push_notification_service.dart';

final pushNotificationsProvider = Provider<PushNotificationService>((ref) {
  final service = PushNotificationService();
  ref.onDispose(service.dispose);
  unawaited(service.initialize());
  return service;
});
