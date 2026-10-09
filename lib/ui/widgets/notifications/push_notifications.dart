import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/services/push_notification_service.dart';
import '../../../providers/push_notifications_provider.dart';
import 'app_notification.dart';

/// Lives in the home route so announcements can reach the root overlay while
/// the editor or any other route is open above it.
class PushNotifications extends ConsumerStatefulWidget {
  const PushNotifications({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<PushNotifications> createState() => _PushNotificationsState();
}

class _PushNotificationsState extends ConsumerState<PushNotifications> {
  StreamSubscription<RemoteMessage>? _messages;

  @override
  void initState() {
    super.initState();
    if (!PushNotificationService.supported) return;
    _messages = FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (!mounted || notification == null) return;
      AppNotification.info(context, notification.body ?? '',
          title: notification.title, duration: const Duration(seconds: 8));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(pushNotificationsProvider);
    });
  }

  @override
  void dispose() {
    unawaited(_messages?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
