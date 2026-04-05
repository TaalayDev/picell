import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';

Future<T?> showTopFlushbar<T>(
  BuildContext context, {
  required Widget message,
  Widget? icon,
  Color? color,
  Duration duration = const Duration(seconds: 2),
}) {
  return Flushbar<T>(
    padding: const EdgeInsets.symmetric(
      horizontal: 10.0,
      vertical: 15.0,
    ),
    margin: const EdgeInsets.symmetric(
      horizontal: 5.0,
      vertical: 5.0,
    ),
    borderRadius: BorderRadius.circular(5.0),
    backgroundColor: const Color(0xffCBCBCB).withValues(alpha: 0.8),
    messageText: DefaultTextStyle(
      style: TextStyle(
        color: color ?? Theme.of(context).colorScheme.onSurface,
        fontSize: 16,
      ),
      child: message,
    ),
    duration: duration,
    flushbarPosition: FlushbarPosition.TOP,
    icon: icon != null
        ? IconTheme(
            data: IconThemeData(
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
            child: icon,
          )
        : null,
  ).show(context);
}

Future<T?> showBottomFlushbar<T>(
  BuildContext context, {
  required Widget message,
  Widget? icon,
  Color? color,
  Duration duration = const Duration(seconds: 2),
}) {
  return Flushbar<T>(
    padding: const EdgeInsets.symmetric(
      horizontal: 10.0,
      vertical: 15.0,
    ),
    margin: const EdgeInsets.symmetric(
      horizontal: 5.0,
      vertical: 5.0,
    ),
    borderRadius: BorderRadius.circular(5.0),
    backgroundColor: const Color(0xffCBCBCB).withValues(alpha: 0.4),
    messageText: DefaultTextStyle(
      style: TextStyle(
        color: color ?? Theme.of(context).colorScheme.onSurface,
        fontSize: 16,
      ),
      child: message,
    ),
    duration: duration,
    flushbarPosition: FlushbarPosition.BOTTOM,
    icon: icon != null
        ? IconTheme(
            data: IconThemeData(
              color: color ?? Theme.of(context).colorScheme.onSurface,
            ),
            child: icon,
          )
        : null,
  ).show(context);
}
