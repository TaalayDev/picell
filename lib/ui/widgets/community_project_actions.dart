import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../config/constants.dart';
import '../../core.dart';
import '../../data/models/project_api_models.dart';
import '../../data/models/project_model.dart';
import '../../l10n/strings.dart';
import '../../providers/ad/reward_video_ad_controller.dart';
import '../../providers/projects_provider.dart';
import '../../providers/subscription_provider.dart';
import '../screens.dart';
import '../screens/subscription_screen.dart';
import 'dialogs/project_donwload_dialog.dart';
import 'dialogs/reward_dialog.dart';
import 'overlay.dart';

/// Downloads a community project into the local library.
///
/// Pro users download directly. Everyone else is offered a rewarded video
/// when one is loaded, and otherwise sent to the upgrade screen.
void downloadCommunityProject(
  BuildContext context,
  WidgetRef ref,
  ApiProject project,
) {
  final s = Strings.of(context);

  void startDownload() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProjectDownloadDialog(project: project),
    );
  }

  if (ref.read(subscriptionStateProvider).isPro) {
    startDownload();
    return;
  }

  if (ref.read(rewardVideoAdProvider)) {
    RewardDialog.show(
      context,
      title: s.downloadProject,
      subtitle: s.downloadProjectRewardSubtitle,
      onRewardEarned: () async {
        AppNotification.success(
          context,
          s.thankYouWatchingDownloadStarting,
          duration: const Duration(seconds: 2),
        );
        startDownload();
      },
    );
    return;
  }

  AppNotification.warning(
    context,
    s.premiumRequiredToDownloadProjects,
    duration: const Duration(seconds: 3),
    actionLabel: s.upgrade,
    onAction: () {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SubscriptionOfferScreen()),
      );
    },
  );
}

/// Opens the local copy of a downloaded community project in the editor,
/// loading the full project from the database first when needed.
Future<void> openDownloadedProject(
  BuildContext context,
  WidgetRef ref,
  Project? localProject,
) async {
  if (localProject == null) {
    AppNotification.error(context, Strings.of(context).localProjectNotFound);
    return;
  }

  var projectToOpen = localProject;
  final hasCanvasData = localProject.frames.isNotEmpty && localProject.frames.first.layers.isNotEmpty;
  if (!hasCanvasData) {
    final loaded = await ref.read(projectsProvider.notifier).getProject(localProject.id);
    if (loaded == null) return;
    projectToOpen = loaded;
  }

  if (!context.mounted) return;
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => EditorWorkspaceScreen(initialProject: projectToOpen),
    ),
  );
}

/// Shares the project's title, author and public link.
void shareCommunityProject(BuildContext context, ApiProject project) {
  final author = project.displayName ?? project.username ?? Strings.of(context).unknownArtist;
  final message = Strings.of(context).shareProjectMessage(project.title, author);
  Share.share(
    '$message\n${Constants.projectUrl(project.id)}',
    subject: project.title,
  );
}

/// Creates a fresh local copy of an already-downloaded community project and
/// opens it, so edits don't touch the original download. The copy keeps the
/// community lineage ([Project.forkedFromId]) so uploading it records a fork.
Future<void> remixCommunityProject(
  BuildContext context,
  WidgetRef ref,
  ApiProject project,
  Project? localProject,
) async {
  if (localProject == null) {
    AppNotification.error(context, Strings.of(context).localProjectNotFound);
    return;
  }

  final s = Strings.of(context);
  final loader = showLoader(context, loadingText: s.creatingProject);
  try {
    var source = localProject;
    final hasCanvasData = source.frames.isNotEmpty && source.frames.first.layers.isNotEmpty;
    if (!hasCanvasData) {
      final loaded = await ref.read(projectsProvider.notifier).getProject(source.id);
      if (loaded == null) return;
      source = loaded;
    }

    final now = DateTime.now();
    const uuid = Uuid();
    final copy = source.copyWith(
      id: 0,
      name: '${source.name} · ${s.remixProject}',
      isCloudSynced: false,
      clearRemoteId: true,
      forkedFromId: project.id,
      clearSelectedFrameId: true,
      clearSelectedLayerId: true,
      createdAt: now,
      editedAt: now,
      frames: [
        for (final frame in source.frames)
          frame.copyWith(layers: [for (final layer in frame.layers) layer.copyWith(id: uuid.v4())]),
      ],
    );

    final created = await ref.read(projectsProvider.notifier).addProject(copy);
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditorWorkspaceScreen(initialProject: created)),
    );
  } finally {
    loader.remove();
  }
}
