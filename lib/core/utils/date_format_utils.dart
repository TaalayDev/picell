import 'package:flutter/widgets.dart';

import '../../l10n/strings.dart';

/// Compact relative time ("2d", "3h", "5m") used across project list/grid
/// cards. Falls back to [Strings.justNow] for anything under a minute.
String formatLastEdited(BuildContext context, DateTime lastEdited) {
  final now = DateTime.now();
  final difference = now.difference(lastEdited);

  if (difference.inDays > 0) {
    return '${difference.inDays}d';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}h';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}m';
  } else {
    return Strings.of(context).justNow;
  }
}

/// Localized, spelled-out relative time ("3 days ago", "1 month ago").
/// Prefer [formatLastEdited] for cramped card layouts.
String formatRelativeDate(BuildContext context, DateTime dateTime) {
  final s = Strings.of(context);
  final difference = DateTime.now().difference(dateTime);

  if (difference.inDays > 30) {
    return s.relativeMonthsAgo(difference.inDays ~/ 30);
  } else if (difference.inDays > 0) {
    return s.relativeDaysAgo(difference.inDays);
  } else if (difference.inHours > 0) {
    return s.relativeHoursAgo(difference.inHours);
  } else if (difference.inMinutes > 0) {
    return s.relativeMinutesAgo(difference.inMinutes);
  }
  return s.justNow;
}
