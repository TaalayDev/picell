import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../providers/auth_provider.dart';

class DeleteAccountDialog extends HookConsumerWidget {
  const DeleteAccountDialog({
    super.key,
    this.onSuccess,
    this.onError,
  });

  final VoidCallback? onSuccess;
  final Function(String)? onError;

  static Future<bool?> show(
    BuildContext context, {
    VoidCallback? onSuccess,
    Function(String)? onError,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteAccountDialog(
        onSuccess: onSuccess,
        onError: onError,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    final confirmationController = useTextEditingController();
    final isConfirmed = useState(false);
    final isDeleting = useState(false);
    final currentStep = useState(0);
    final errorMessage = useState<String?>(null);

    // Listen for text changes
    useEffect(() {
      void listener() {
        final text = confirmationController.text.trim().toLowerCase();
        isConfirmed.value = text == 'delete';
        errorMessage.value = null;
      }

      confirmationController.addListener(listener);
      return () => confirmationController.removeListener(listener);
    }, [confirmationController]);

    Future<void> handleDeleteAccount() async {
      if (!isConfirmed.value) return;

      try {
        isDeleting.value = true;
        errorMessage.value = null;

        // Add haptic feedback
        HapticFeedback.heavyImpact();

        await authNotifier.deleteAccount();

        if (context.mounted) {
          onSuccess?.call();
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        errorMessage.value = e.toString();
        onError?.call(e.toString());
        isDeleting.value = false;
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 16,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with warning animation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade50,
                      Colors.red.shade100,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Animated warning icon
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.red.shade500,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.shade200,
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Feather.alert_triangle,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Delete Account',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'This action cannot be undone',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning message
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Feather.info,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Deleting your account will permanently remove all your data.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.orange.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // What will be deleted
                    Text(
                      'The following will be permanently deleted:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),

                    const SizedBox(height: 12),

                    // List of items to be deleted
                    Column(
                      children: [
                        _buildDeleteItem(
                          context,
                          icon: Feather.settings,
                          title: 'App Preferences',
                          subtitle: 'Settings and customizations',
                        ),
                        _buildDeleteItem(
                          context,
                          icon: Feather.user,
                          title: 'Account Information',
                          subtitle: 'Profile and authentication data',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Confirmation input
                    Text(
                      'Type "DELETE" to confirm:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: confirmationController,
                      enabled: !isDeleting.value,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Type DELETE here...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isConfirmed.value ? Colors.red.shade400 : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isConfirmed.value ? Colors.red.shade400 : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.red.shade500,
                            width: 2,
                          ),
                        ),
                        prefixIcon: Icon(
                          isConfirmed.value ? Feather.check : Feather.type,
                          color: isConfirmed.value ? Colors.red.shade500 : Colors.grey.shade500,
                        ),
                        fillColor: isConfirmed.value ? Colors.red.shade50 : Colors.grey.shade50,
                        filled: true,
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isConfirmed.value ? Colors.red.shade700 : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),

                    // Error message
                    if (errorMessage.value != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Feather.alert_circle,
                              size: 16,
                              color: Colors.red.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage.value!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        // Cancel button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isDeleting.value ? null : () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Delete button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isConfirmed.value && !isDeleting.value ? handleDeleteAccount : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: isConfirmed.value ? 4 : 0,
                            ),
                            child: isDeleting.value
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
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Feather.trash_2,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete Account',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Footer note
                    Center(
                      child: Text(
                        'This action is irreversible and will take effect immediately.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontStyle: FontStyle.italic,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.red.shade200,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Feather.x,
            size: 16,
            color: Colors.red.shade400,
          ),
        ],
      ),
    );
  }
}

// Alternative simpler version for quick confirmation
class QuickDeleteAccountDialog extends HookConsumerWidget {
  const QuickDeleteAccountDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => const QuickDeleteAccountDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDeleting = useState(false);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Feather.alert_triangle,
              color: Colors.red.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Delete Account',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to permanently delete your account?',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text(
            '• All your projects will be lost\n'
            '• Cloud backups will be deleted\n'
            '• This action cannot be undone',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isDeleting.value ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isDeleting.value
              ? null
              : () async {
                  isDeleting.value = true;
                  try {
                    await ref.read(authProvider.notifier).deleteAccount();
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  } catch (e) {
                    isDeleting.value = false;
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete account: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
          ),
          child: isDeleting.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Delete Account'),
        ),
      ],
    );
  }
}
