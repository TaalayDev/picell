import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/snackbar.dart';
import '../../../data/models/trial_model.dart';
import '../../../l10n/strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/providers.dart';
import '../../../providers/trial_provider.dart';
import 'auth_dialog.dart';

/// Starts a trial. Trials belong to an account, so signed-out users are asked
/// to sign in first; once they do, the claim goes ahead. Tells the user what
/// happened and returns whether the trial is now running.
Future<bool> startTrialFlow(
  BuildContext context,
  WidgetRef ref,
  Future<TrialClaimResult> Function(TrialsNotifier trials) claim, {
  required String kind,
}) async {
  final strings = Strings.of(context);

  if (!ref.read(authProvider).isSignedIn) {
    ref.read(analyticsProvider).logEvent(name: 'trial_sign_in_prompted', parameters: {'kind': kind});
    await AuthDialog.show(
      context,
      title: strings.trialSignInTitle,
      subtitle: strings.trialSignInSubtitle,
    );
    if (!context.mounted || !ref.read(authProvider).isSignedIn) return false;
  }

  // Signing in recreates the notifier for the new account, so read it late.
  final result = await claim(ref.read(trialsProvider.notifier));
  if (!context.mounted) return result.isSuccess;

  final message = switch (result) {
    TrialClaimResult.granted => strings.trialStarted,
    TrialClaimResult.existing => null,
    TrialClaimResult.alreadyUsed => strings.trialAlreadyUsed,
    TrialClaimResult.notSignedIn || TrialClaimResult.unavailable => strings.trialUnavailable,
  };
  if (message != null) showTopFlushbar(context, message: Text(message));
  return result.isSuccess;
}

/// Offers the rig editor trial for the open project. Returns true when the
/// user may go on and edit the rig (trial started or already running here).
Future<bool> offerRigTrial(BuildContext context, WidgetRef ref, {required String projectKey}) async {
  final strings = Strings.of(context);
  ref.read(analyticsProvider).logEvent(name: 'trial_prompt_shown', parameters: {'kind': 'rig'});
  final choice = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(strings.trialRigTitle),
      content: Text(strings.trialRigBody),
      actions: [
        TextButton(
          key: const ValueKey('rig-trial-plans'),
          onPressed: () => Navigator.pop(context, false),
          child: Text(strings.trialSeePlans),
        ),
        FilledButton(
          key: const ValueKey('rig-trial-start'),
          onPressed: () => Navigator.pop(context, true),
          child: Text(strings.trialOnThisProject),
        ),
      ],
    ),
  );
  if (choice != true || !context.mounted) return false;
  return startTrialFlow(context, ref, (trials) => trials.claimRig(projectKey), kind: 'rig');
}
