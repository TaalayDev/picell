import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../l10n/strings.dart';
import '../../../providers/auth_provider.dart';

class AuthDialog extends HookConsumerWidget {
  bool get isAppleSignInAvailable {
    return !kIsWeb && (Platform.isIOS || Platform.isMacOS);
  }

  const AuthDialog({
    super.key,
    this.title,
    this.subtitle,
    this.showSkipOption = false,
    this.onSkip,
    this.onSuccess,
  });

  final String? title;
  final String? subtitle;
  final bool showSkipOption;
  final VoidCallback? onSkip;
  final VoidCallback? onSuccess;

  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? subtitle,
    bool showSkipOption = false,
    VoidCallback? onSkip,
    VoidCallback? onSuccess,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: !showSkipOption,
      builder: (context) => AuthDialog(
        title: title,
        subtitle: subtitle,
        showSkipOption: showSkipOption,
        onSkip: onSkip,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Clear any previous errors when dialog opens
        authNotifier.clearError();
      });
      return null;
    }, []);

    useEffect(() {
      // Handle successful sign-in
      if (authState.isSignedIn && !authState.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            onSuccess?.call();
            Navigator.of(context).pop(true);
          }
        });
      }
      return null;
    }, [authState.isSignedIn, authState.isLoading]);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Feather.user,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),

          const SizedBox(height: 24),

          // Title
          Text(
            title ?? Strings.of(context).signInToContinue,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Subtitle
          Text(
            subtitle ?? Strings.of(context).signInToSyncProjects,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Error message
          if (authState.error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Feather.alert_circle,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      authState.error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Sign in button
          Column(
            children: [
              if (isAppleSignInAvailable) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: authState.isLoading ? null : () => authNotifier.signInWithApple(),
                    icon: authState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : _buildAppleIcon(),
                    label: Text(
                      authState.isLoading ? Strings.of(context).signingIn : Strings.of(context).continueWithApple,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: authState.isLoading ? null : () => authNotifier.signInWithGoogle(),
                  icon: authState.isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : _buildGoogleIcon(),
                  label: Text(
                    authState.isLoading ? Strings.of(context).signingIn : Strings.of(context).signInWithGoogle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Skip option
          if (showSkipOption) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: authState.isLoading
                  ? null
                  : () {
                      onSkip?.call();
                      Navigator.of(context).pop(false);
                    },
              child: Text(
                Strings.of(context).skipForNow,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],

          // Close button (when skip is not available)
          if (!showSkipOption) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: authState.isLoading ? null : () => Navigator.of(context).pop(false),
              child: Text(Strings.of(context).cancel),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppleIcon() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: Icon(
        AntDesign.apple1,
        size: 18,
        color: Colors.white,
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        AntDesign.google,
        size: 16,
        color: Colors.red,
      ),
    );
  }
}

// Alternative simplified sign-in button widget
class GoogleSignInButton extends ConsumerWidget {
  const GoogleSignInButton({
    super.key,
    this.onSuccess,
    this.text,
    this.isCompact = false,
  });

  final VoidCallback? onSuccess;
  final String? text;
  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    return SizedBox(
      width: isCompact ? null : double.infinity,
      child: ElevatedButton.icon(
        onPressed: authState.isLoading
            ? null
            : () async {
                await authNotifier.signInWithGoogle();
                if (authState.isSignedIn) {
                  onSuccess?.call();
                }
              },
        icon: authState.isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              )
            : Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AntDesign.google,
                  size: 14,
                  color: Colors.red,
                ),
              ),
        label: Text(
          text ?? (authState.isLoading ? Strings.of(context).signingIn : Strings.of(context).signInWithGoogle),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: EdgeInsets.symmetric(
            vertical: isCompact ? 12 : 16,
            horizontal: isCompact ? 16 : 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

// User profile widget to show signed-in user
class UserProfileWidget extends ConsumerWidget {
  const UserProfileWidget({
    super.key,
    this.showSignOut = true,
    this.onSignOut,
  });

  final bool showSignOut;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isSignedIn || authState.user == null) {
      return const SizedBox.shrink();
    }

    final user = authState.user!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null
                  ? Text(
                      user.displayName?.isNotEmpty == true
                          ? user.displayName![0].toUpperCase()
                          : (user.email ?? 'A')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.displayName?.isNotEmpty == true)
                    Text(
                      user.displayName!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  Text(
                    user.email ?? Strings.of(context).noEmail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
            if (showSignOut)
              IconButton(
                icon: const Icon(Feather.log_out),
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        await ref.read(authProvider.notifier).signOut();
                        onSignOut?.call();
                      },
                tooltip: Strings.of(context).logout,
              ),
          ],
        ),
      ),
    );
  }
}
