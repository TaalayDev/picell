import 'package:flutter/material.dart';

import '../ui/widgets/notifications/app_notification.dart';

export '../ui/widgets/notifications/app_notification.dart';

Future<T?> showTopFlushbar<T>(
  BuildContext context, {
  required Widget message,
  Widget? icon,
  Color? color,
  Duration duration = const Duration(seconds: 2),
}) async {
  final text = message is Text
      ? (message.data ?? '')
      : (message is DefaultTextStyle ? '' : message.toString());

  AppNotification.show(
    context,
    message: text.isNotEmpty ? text : 'Notification',
    duration: duration,
    type: AppNotificationType.info,
  );
  return null;
}

Future<T?> showBottomFlushbar<T>(
  BuildContext context, {
  required Widget message,
  Widget? icon,
  Color? color,
  Duration duration = const Duration(seconds: 2),
}) async {
  return showTopFlushbar(
    context,
    message: message,
    icon: icon,
    color: color,
    duration: duration,
  );
}
