import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data.dart';

import '../../../l10n/strings.dart';
import '../../../providers/providers.dart';
import '../../screens/feedback_screen.dart';

/// Dialog that prompts users to leave feedback
class FeedbackPromptDialog extends ConsumerWidget {
  const FeedbackPromptDialog({super.key, required this.onNavigateToFeedback});

  static Future<bool?> show(BuildContext context, VoidCallback onNavigateToFeedback) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => FeedbackPromptDialog._(
        onNavigateToFeedback: onNavigateToFeedback,
      ),
    );
  }

  const FeedbackPromptDialog._({super.key, required this.onNavigateToFeedback});

  final VoidCallback onNavigateToFeedback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = Strings.of(context);
    final localStorage = ref.read(localStorageProvider);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: _DialogContent(
          theme: theme,
          s: s,
          localStorage: localStorage,
          onNavigateToFeedback: onNavigateToFeedback,
        ),
      ),
    );
  }
}

class _DialogContent extends StatefulWidget {
  final ThemeData theme;
  final Strings s;
  final LocalStorage localStorage;
  final VoidCallback onNavigateToFeedback;

  const _DialogContent({
    required this.theme,
    required this.s,
    required this.localStorage,
    required this.onNavigateToFeedback,
  });

  @override
  State<_DialogContent> createState() => _DialogContentState();
}

class _DialogContentState extends State<_DialogContent> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onLeaveFeedback() async {
    await _controller.reverse();
    if (!mounted) return;

    Navigator.of(context).pop(true);

    // Navigate to feedback screen
    widget.onNavigateToFeedback();
  }

  void _onMaybeLater() async {
    await _controller.reverse();
    if (!mounted) return;
    Navigator.of(context).pop(false);
  }

  void _onNeverAsk() async {
    await _controller.reverse();
    if (!mounted) return;
    Navigator.of(context).pop(null);

    widget.localStorage.feedbackPromptNeverAskAgain = true;
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: widget.theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top decoration with gradient
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.theme.colorScheme.primary,
                        widget.theme.colorScheme.secondary,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -30,
                        left: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      // Icon
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.feedback_outlined,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Title
                      Text(
                        widget.s.feedback_dialog_title,
                        style: widget.theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.theme.colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Description
                      Text(
                        widget.s.feedback_dialog_description,
                        style: widget.theme.textTheme.bodyMedium?.copyWith(
                          color: widget.theme.colorScheme.onSurface.withOpacity(0.7),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Benefits list
                      _BenefitItem(
                        icon: Icons.lightbulb_outline,
                        text: widget.s.feedback_dialog_benefit_1,
                        theme: widget.theme,
                      ),
                      const SizedBox(height: 12),
                      _BenefitItem(
                        icon: Icons.bug_report_outlined,
                        text: widget.s.feedback_dialog_benefit_2,
                        theme: widget.theme,
                      ),
                      const SizedBox(height: 12),
                      _BenefitItem(
                        icon: Icons.favorite_outline,
                        text: widget.s.feedback_dialog_benefit_3,
                        theme: widget.theme,
                      ),
                      const SizedBox(height: 28),

                      // Main action button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _onLeaveFeedback,
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(widget.s.feedback_dialog_leave_feedback),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Secondary action button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _onMaybeLater,
                          icon: const Icon(Icons.schedule_outlined),
                          label: Text(widget.s.feedback_dialog_maybe_later),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Dismiss option
                      TextButton(
                        onPressed: _onNeverAsk,
                        child: Text(
                          widget.s.feedback_dialog_dont_ask,
                          style: widget.theme.textTheme.bodySmall?.copyWith(
                            color: widget.theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final ThemeData theme;

  const _BenefitItem({
    required this.icon,
    required this.text,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}
