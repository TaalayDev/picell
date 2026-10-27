import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../app/theme/pv_tokens.dart';
import '../../../l10n/strings.dart';
import '../../../providers/auth_provider.dart';
import '../dialogs/auth_dialog.dart';
import '../dialogs/delete_account_dialog.dart';

enum _AccountAction { signIn, plans, feedback, about, logout, deleteAccount }

/// The same account entry point for both projects screen layouts.
class ProjectsAccountMenu extends ConsumerWidget {
  const ProjectsAccountMenu({
    super.key,
    required this.onPlans,
    required this.onFeedback,
    required this.onAbout,
  });

  final VoidCallback onPlans;
  final VoidCallback onFeedback;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final strings = Strings.of(context);
    final pv = context.pv;
    final avatar = auth.apiUser?.avatarUrl;
    PopupMenuItem<_AccountAction> item(_AccountAction value, IconData icon, String label, {bool destructive = false}) {
      final color = destructive ? pv.err : pv.textPrimary;
      return PopupMenuItem(
        value: value,
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Flexible(child: Text(label, style: TextStyle(color: color))),
          ],
        ),
      );
    }

    return PopupMenuButton<_AccountAction>(
      key: const ValueKey('projects-account-menu'),
      tooltip: strings.profile,
      offset: const Offset(0, 48),
      color: pv.surface,
      icon: auth.isSignedIn && avatar != null
          ? CircleAvatar(radius: 16, backgroundImage: NetworkImage(avatar))
          : Icon(Icons.account_circle_outlined, color: pv.textSecondary),
      onSelected: (action) {
        switch (action) {
          case _AccountAction.signIn:
            AuthDialog.show(context);
          case _AccountAction.plans:
            onPlans();
          case _AccountAction.feedback:
            onFeedback();
          case _AccountAction.about:
            onAbout();
          case _AccountAction.logout:
            ref.read(authProvider.notifier).signOut();
          case _AccountAction.deleteAccount:
            DeleteAccountDialog.show(context, onSuccess: () {});
        }
      },
      itemBuilder: (context) => [
        if (auth.isSignedIn && auth.apiUser?.displayName != null) ...[
          PopupMenuItem<_AccountAction>(
            enabled: false,
            child:
                Text(auth.apiUser!.displayName!, style: TextStyle(color: pv.textPrimary, fontWeight: FontWeight.bold)),
          ),
          const PopupMenuDivider(),
        ],
        if (!auth.isSignedIn) item(_AccountAction.signIn, Icons.login, strings.signInToContinue),
        item(_AccountAction.plans, Icons.workspace_premium_outlined, strings.plansTitle),
        item(_AccountAction.feedback, Icons.feedback_outlined, strings.feedback),
        item(_AccountAction.about, Icons.info_outline, strings.about),
        if (auth.isSignedIn) ...[
          const PopupMenuDivider(),
          item(_AccountAction.logout, Icons.logout, strings.logout),
          item(_AccountAction.deleteAccount, Icons.delete_outline, strings.deleteAccount, destructive: true),
        ],
      ],
    );
  }
}
