import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

enum AppNotificationType {
  success,
  error,
  warning,
  info,
}

class AppNotification {
  static final _NotificationOverlayManager _manager =
      _NotificationOverlayManager();

  /// Shows a notification from the top-right corner.
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppNotificationType type = AppNotificationType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onDismiss,
  }) {
    _manager.show(
      context,
      message: message,
      title: title,
      type: type,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      onDismiss: onDismiss,
    );
  }

  /// Convenience method for success notification.
  static void success(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onDismiss,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppNotificationType.success,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      onDismiss: onDismiss,
    );
  }

  /// Convenience method for error notification.
  static void error(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onDismiss,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppNotificationType.error,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      onDismiss: onDismiss,
    );
  }

  /// Convenience method for warning notification.
  static void warning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onDismiss,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppNotificationType.warning,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      onDismiss: onDismiss,
    );
  }

  /// Convenience method for info notification.
  static void info(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onDismiss,
  }) {
    show(
      context,
      message: message,
      title: title,
      type: AppNotificationType.info,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      onDismiss: onDismiss,
    );
  }

  /// Dismisses all currently visible notifications.
  static void dismissAll() {
    _manager.dismissAll();
  }
}

class _NotificationEntry {
  final String id;
  final String message;
  final String? title;
  final AppNotificationType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;
  final GlobalKey<_NotificationCardState> key =
      GlobalKey<_NotificationCardState>();

  _NotificationEntry({
    required this.id,
    required this.message,
    this.title,
    required this.type,
    required this.duration,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });
}

class _NotificationOverlayManager {
  OverlayEntry? _overlayEntry;
  final List<_NotificationEntry> _notifications = [];
  int _counter = 0;

  void show(
    BuildContext context, {
    required String message,
    String? title,
    required AppNotificationType type,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onDismiss,
  }) {
    final overlay =
        Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    if (overlay == null) return;

    final id = 'notif_${++_counter}_${DateTime.now().millisecondsSinceEpoch}';
    final entry = _NotificationEntry(
      id: id,
      message: message,
      title: title,
      type: type,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      onDismiss: onDismiss,
    );

    // Limit active notifications to max 4 to prevent screen clutter
    if (_notifications.length >= 4) {
      final oldest = _notifications.first;
      oldest.key.currentState?.dismissImmediately();
      _notifications.removeAt(0);
    }

    _notifications.add(entry);

    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(
        builder: (context) => _NotificationContainer(
          notifications: _notifications,
          onRemove: _removeEntry,
        ),
      );
      overlay.insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _removeEntry(_NotificationEntry entry) {
    _notifications.remove(entry);
    entry.onDismiss?.call();
    if (_notifications.isEmpty) {
      _overlayEntry?.remove();
      _overlayEntry?.dispose();
      _overlayEntry = null;
    } else {
      _overlayEntry?.markNeedsBuild();
    }
  }

  void dismissAll() {
    for (final notif in List<_NotificationEntry>.from(_notifications)) {
      notif.key.currentState?.dismissImmediately();
    }
    _notifications.clear();
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
  }
}

class _NotificationContainer extends StatelessWidget {
  final List<_NotificationEntry> notifications;
  final ValueChanged<_NotificationEntry> onRemove;

  const _NotificationContainer({
    required this.notifications,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 16.0;
    final maxWidth = math.min(390.0, mediaQuery.size.width - 32.0);

    return Positioned(
      top: topPadding,
      right: 16.0,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: notifications
                .map(
                  (entry) => _NotificationCard(
                    key: entry.key,
                    entry: entry,
                    onDismissed: () => onRemove(entry),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatefulWidget {
  final _NotificationEntry entry;
  final VoidCallback onDismissed;

  const _NotificationCard({
    super.key,
    required this.entry,
    required this.onDismissed,
  });

  @override
  State<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _timer;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.4, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _controller.forward();

    _timer = Timer(widget.entry.duration, _startExit);
  }

  void _startExit() {
    if (!mounted || _isExiting) return;
    _isExiting = true;
    _controller.reverse().then((_) {
      if (mounted) widget.onDismissed();
    });
  }

  void dismissImmediately() {
    _timer?.cancel();
    _startExit();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Color _accentColor(ThemeData theme) {
    switch (widget.entry.type) {
      case AppNotificationType.success:
        return const Color(0xFF10B981); // Emerald
      case AppNotificationType.error:
        return const Color(0xFFEF4444); // Crimson
      case AppNotificationType.warning:
        return const Color(0xFFF59E0B); // Amber
      case AppNotificationType.info:
        return theme.colorScheme.primary;
    }
  }

  IconData _iconData() {
    switch (widget.entry.type) {
      case AppNotificationType.success:
        return Icons.check_circle_rounded;
      case AppNotificationType.error:
        return Icons.error_rounded;
      case AppNotificationType.warning:
        return Icons.warning_amber_rounded;
      case AppNotificationType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _accentColor(theme);

    // Sleek surface with high contrast and subtle glassmorphic effect
    final backgroundColor = isDark
        ? const Color(0xFF181824).withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.98);

    final borderColor = accent.withValues(alpha: isDark ? 0.35 : 0.25);
    final onSurface = isDark ? Colors.white : const Color(0xFF1F2937);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Dismissible(
            key: ValueKey(widget.entry.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
              _timer?.cancel();
              widget.onDismissed();
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon badge
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _iconData(),
                                size: 18,
                                color: accent,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Text Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.entry.title != null) ...[
                                    Text(
                                      widget.entry.title!,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                  Text(
                                    widget.entry.message,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: onSurface.withValues(alpha: 0.85),
                                      height: 1.35,
                                    ),
                                  ),
                                  if (widget.entry.actionLabel != null &&
                                      widget.entry.onAction != null) ...[
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: () {
                                        _startExit();
                                        widget.entry.onAction!();
                                      },
                                      borderRadius: BorderRadius.circular(4),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 3,
                                          horizontal: 6,
                                        ),
                                        child: Text(
                                          widget.entry.actionLabel!,
                                          style: TextStyle(
                                            color: accent,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Close button
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              icon: Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: onSurface.withValues(alpha: 0.5),
                              ),
                              onPressed: _startExit,
                              splashRadius: 14,
                            ),
                          ],
                        ),
                      ),

                      // Left accent bar
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 3.5,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
