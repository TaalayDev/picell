import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../config/constants.dart';

import '../../data/models/subscription_model.dart';
import '../../data/models/project_api_models.dart';
import '../../data/models/template.dart';
import '../../l10n/strings.dart';
import '../../data.dart';
import '../../core.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ad/interstitial_ad_controller.dart';
import '../../providers/project_upload_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/community_projects_providers.dart';
import '../../providers/providers.dart';
import '../../providers/progression_provider.dart';
import '../../providers/subscription_provider.dart';
import '../widgets/dialogs/auth_dialog.dart';
import '../widgets/animated_pro_button.dart';
import '../widgets/animated_background.dart';
import '../widgets/community_project_card.dart';
import '../widgets/project/projects_account_menu.dart';
import '../widgets/dialogs/delete_project_dialog.dart';
import '../widgets/dialogs/project_upload_dialog.dart' hide CheckerboardPainter;
import '../widgets/dialogs/feedback_prompt_dialog.dart';
import '../widgets/challenges/challenges_banner.dart';
import '../../providers/discovery_slides_provider.dart';
import '../widgets/discovery/discovery_carousel.dart';
import '../widgets/home/home_toasts.dart';
import '../widgets/project/home/pv_my_projects.dart';
import '../widgets/project/home/pv_home_action_panel.dart';
import '../widgets/discovery/whats_new.dart';
import '../widgets/drop_target_overlay.dart';
import '../widgets/challenges/sidebar_challenges_and_quests.dart';
import '../widgets/subscription/subscription_menu.dart';
import '../widgets/theme_selector.dart';
import '../widgets.dart';
import '../widgets/theme_selector_sheet.dart';
import 'feedback_screen.dart';
import 'effect_store_screen.dart';
import 'subscription_screen.dart';
import 'about_screen.dart';
import '../../app/routing/flagship_page_route.dart';
import 'editor_workspace_screen.dart';
import 'project_detail_screen.dart';

part 'projects/project_actions.dart';
part 'projects/desktop_projects.dart';
part 'projects/community_projects_view.dart';

class ProjectsScreen extends HookConsumerWidget with _ProjectsScreenActions {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider).theme;
    final projects = ref.watch(projectsProvider);
    final overlayLoader = useState<OverlayEntry?>(null);

    final showBadge = useState(false);
    final showWhatsNewToast = useState(true);
    final showChallengesToast = useState(true);
    final subscription = ref.watch(subscriptionStateProvider);
    final claimableQuests = ref.watch(progressionProvider.select((state) => state.claimableCount));

    final reviewService = ref.watch(inAppReviewProvider);

    final authState = ref.watch(authProvider);

    final currentTheme = theme;

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkAndShowReviewDialog(context, ref);
      });

      return () {
        if (overlayLoader.value?.mounted == true) {
          overlayLoader.value?.remove();
        }
      };
    }, []);

    useEffect(() {
      if (ref.read(localStorageProvider).feedbackPromptNeverAskAgain) {
        return null;
      }

      final timer = Timer(const Duration(seconds: 5), () async {
        if (!context.mounted) return;
        final count = await reviewService.getSessionCount();
        if ((count == 2 || count % 5 == 0) && context.mounted) {
          FeedbackPromptDialog.show(context, () {
            _navigateToFeedback(context, ref);
          });
        }
      });
      return timer.cancel;
    }, []);

    final isDesktop = MediaQuery.sizeOf(context).width >= 800;
    final flagship = currentTheme.flagship;

    Future<void> importProject() async {
      final error = await ref.read(projectsProvider.notifier).importProject(context);
      if (error != null && context.mounted) {
        showTopFlushbar(context, message: Text(Strings.of(context).invalidFileContent));
      }
    }

    void showAbout() => showDialog(
          context: context,
          builder: (_) => Dialog(
            child: ClipRRect(
              clipBehavior: Clip.antiAlias,
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: const AboutScreen(),
              ),
            ),
          ),
        );

    // ── Desktop layout ─────────────────────────────────────────────────────
    if (isDesktop) {
      return DropTargetOverlay(
        onFilesDropped: (results) => _handleDroppedFiles(context, ref, results),
        acceptedTypes: const [
          DroppedFileType.image,
          DroppedFileType.aseprite,
          DroppedFileType.project,
        ],
        child: AnimatedBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Row(
              children: [
                _DesktopSidebar(
                  theme: currentTheme,
                  subscription: subscription,
                  onNewProject: () => _navigateToNewProject(context, ref, subscription),
                  onImport: importProject,
                  onFeedback: () => _navigateToFeedback(context, ref),
                  onTheme: () => ThemeSelectorBottomSheet.show(context),
                  onPro: () => _showSubscriptionScreen(context),
                ),
                Expanded(
                  child: Column(
                    children: [
                      _DesktopContentHeader(
                        theme: currentTheme,
                        flagship: flagship,
                        onAbout: showAbout,
                        onImport: importProject,
                        onTheme: () => ThemeSelectorBottomSheet.show(context),
                        onPro: () => _showSubscriptionScreen(context),
                        onFeedback: () => _navigateToFeedback(context, ref),
                      ),
                      if (!subscription.isPro && showBadge.value)
                        SubscriptionPromoBanner(onDismiss: () => showBadge.value = false),
                      Expanded(
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CloudProjectsView(
                                theme: theme,
                                subscription: subscription,
                                leadingSlivers: [
                                  const SliverToBoxAdapter(child: _FeaturedSection(height: 220, hPad: 32)),
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(32, 20, 32, 0),
                                      child: _DesktopHome(
                                        isPro: subscription.isPro,
                                        onPreviewPro: () => _showSubscriptionScreen(context),
                                        projects: projects,
                                        onCreateNew: () => _navigateToNewProject(context, ref, subscription),
                                        onQuickCreate: (size) => _quickCreateProject(context, ref, size),
                                        onImport: importProject,
                                        onTapProject: (project) => _openProject(context, ref, project, overlayLoader),
                                        onDeleteProject: (project) =>
                                            _onDeleteProject(context, ref, project, authState),
                                        onEditProject: (project) =>
                                            ref.read(projectsProvider.notifier).renameProject(project.id, project.name),
                                        onUploadProject: (project) =>
                                            _onUploadProject(context, ref, project, authState),
                                        onUpdateProject: (project) =>
                                            _onUpdateProject(context, ref, project, authState),
                                        onDeleteCloudProject: (project) =>
                                            _onDeleteCloudProject(context, ref, project, authState),
                                        onRetry: () => ref.refresh(projectsProvider),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: HomeToasts(
                                showWhatsNew: showWhatsNewToast.value,
                                showChallenges: false,
                                onCloseWhatsNew: () => showWhatsNewToast.value = false,
                                onCloseChallenges: () => showChallengesToast.value = false,
                                onStartDrawing: () => _navigateToNewProject(context, ref, subscription),
                                onOpenBoneRigExample: () => _openBoneRigExample(context, ref),
                              ),
                            ),
                          ],
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

    // ── Mobile layout ──────────────────────────────────────────────────────
    return DropTargetOverlay(
      onFilesDropped: (results) => _handleDroppedFiles(context, ref, results),
      acceptedTypes: const [
        DroppedFileType.image,
        DroppedFileType.aseprite,
        DroppedFileType.project,
      ],
      child: AnimatedBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Row(
              children: [
                const SizedBox(width: 16),
                TextButton.icon(
                  label: const Icon(Feather.file),
                  onPressed: importProject,
                  style: TextButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    minimumSize: const Size(44, 40),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            leadingWidth: 68,
            actions: [
              IconButton(
                key: const ValueKey('open-effect-store'),
                tooltip: Strings.of(context).effectStoreTitle,
                icon: Badge(
                  isLabelVisible: claimableQuests > 0,
                  label: Text('$claimableQuests'),
                  child: const Icon(Icons.storefront_outlined),
                ),
                onPressed: () => EffectStoreScreen.show(
                  context,
                  tab: claimableQuests > 0 ? EffectStoreTab.quests : EffectStoreTab.packs,
                ),
              ),
              if (!subscription.isPro && !showBadge.value) ...[
                const SizedBox(width: 8),
                AnimatedProButton(
                  onTap: () => _showSubscriptionScreen(context),
                  theme: theme,
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                tooltip: Strings.of(context).chooseTheme,
                icon: Icon(
                  Icons.palette_outlined,
                  color: currentTheme.activeIcon,
                ),
                onPressed: () => ThemeSelectorBottomSheet.show(context),
              ),
              ProjectsAccountMenu(
                onPlans: () => _showSubscriptionScreen(context),
                onFeedback: () => _navigateToFeedback(context, ref),
                onAbout: showAbout,
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _navigateToNewProject(context, ref, subscription),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: context.pv.ink,
            shape: const PixelCutBorder(),
            extendedPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            label: Text(Strings.of(context).newProject, style: context.pv.pixelLabel(size: 14, color: context.pv.ink)),
            icon: const Icon(Feather.plus),
            tooltip: Strings.of(context).createNewProjectTooltip,
          ),
          body: Column(
            children: [
              if (!subscription.isPro && showBadge.value) ...[
                SubscriptionPromoBanner(
                  onDismiss: () {
                    showBadge.value = false;
                  },
                ),
              ],
              // Single scrolling page: compact "My Projects" list, then the
              // discovery carousel, then the community feed — no more
              // Local/Community tabs.
              Expanded(
                child: CloudProjectsView(
                  theme: theme,
                  subscription: subscription,
                  leadingSlivers: [
                    const SliverToBoxAdapter(child: _FeaturedSection(height: 180, hPad: 12, showArrows: false)),
                    SliverToBoxAdapter(
                      child: PvMyProjects(
                        projects: projects,
                        onCreateNew: () => _navigateToNewProject(context, ref, subscription),
                        onTapProject: (project) => _openProject(context, ref, project, overlayLoader),
                        onDeleteProject: (project) => _onDeleteProject(context, ref, project, authState),
                        onEditProject: (project) =>
                            ref.read(projectsProvider.notifier).renameProject(project.id, project.name),
                        onUploadProject: (project) => _onUploadProject(context, ref, project, authState),
                        onUpdateProject: (project) => _onUpdateProject(context, ref, project, authState),
                        onDeleteCloudProject: (project) => _onDeleteCloudProject(context, ref, project, authState),
                        onRetry: () => ref.refresh(projectsProvider),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ChallengesBanner(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        onStartDrawing: () => _navigateToNewProject(context, ref, subscription),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: WhatsNewButton(onOpenBoneRigExample: () => _openBoneRigExample(context, ref)),
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
}
