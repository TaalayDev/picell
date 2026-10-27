part of '../projects_screen.dart';

// ── Desktop widgets ────────────────────────────────────────────────────────

class _DesktopSidebar extends StatelessWidget {
  final AppTheme theme;
  final UserSubscription subscription;
  final VoidCallback onNewProject;
  final VoidCallback onImport;
  final VoidCallback onFeedback;
  final VoidCallback onTheme;
  final VoidCallback onPro;

  const _DesktopSidebar({
    required this.theme,
    required this.subscription,
    required this.onNewProject,
    required this.onImport,
    required this.onFeedback,
    required this.onTheme,
    required this.onPro,
  });

  @override
  Widget build(BuildContext context) {
    final flagship = theme.flagship;

    return Container(
      width: 272,
      decoration: BoxDecoration(
        color: theme.surface,
        border: Border(right: BorderSide(color: theme.divider, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(flagship),
          Divider(color: theme.divider, height: 1),

          // ── New Project ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: PvPixelButton(
              label: Strings.of(context).newProject,
              icon: Feather.plus,
              expand: true,
              onPressed: onNewProject,
            ),
          ),

          Expanded(child: SidebarChallengesAndQuests(onStartDrawing: onNewProject)),

          // ── Bottom actions ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: theme.divider, height: 1),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                _NavItem(
                  icon: Feather.file,
                  label: Strings.of(context).importFile,
                  selected: false,
                  theme: theme,
                  flagship: flagship,
                  onTap: onImport,
                ),
                _NavItem(
                  icon: Icons.palette_outlined,
                  label: Strings.of(context).theme,
                  selected: false,
                  theme: theme,
                  flagship: flagship,
                  onTap: onTheme,
                ),
                _NavItem(
                  icon: Icons.storefront_outlined,
                  label: Strings.of(context).effectStoreTitle,
                  selected: false,
                  theme: theme,
                  flagship: flagship,
                  onTap: () => EffectStoreScreen.show(context),
                ),
                if (!subscription.isPro)
                  _NavItem(
                    icon: MaterialCommunityIcons.crown,
                    label: Strings.of(context).getPro,
                    selected: false,
                    theme: theme,
                    flagship: flagship,
                    onTap: onPro,
                    accentColor: Colors.orange,
                  ),
                _NavItem(
                  icon: Icons.feedback_outlined,
                  label: Strings.of(context).feedback,
                  selected: false,
                  theme: theme,
                  flagship: flagship,
                  onTap: onFeedback,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeader(FlagshipConfig? flagship) {
    final hasFlagship = flagship != null && flagship.isFlagship;
    return Stack(
      children: [
        // Flagship gradient tint
        if (hasFlagship && flagship.appBarGradient != null)
          Positioned.fill(
            child: Opacity(
              opacity: 0.18,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: flagship.appBarGradient),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.draw_outlined, size: 24, color: theme.primaryColor),
                  const SizedBox(width: 10),
                  Text('PICELL', style: PvTokens.fromTheme(theme).pixelTitle(size: 14)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final AppTheme theme;
  final FlagshipConfig? flagship;
  final VoidCallback onTap;
  final Color? accentColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.theme,
    required this.flagship,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = accentColor ?? theme.primaryColor;
    final iconColor = selected ? activeColor : theme.textSecondary;

    final iconWidget = Icon(icon, size: 22, color: iconColor);

    // Optional glow for flagship active items
    final displayIcon = (flagship != null && flagship!.enableIconGlow && selected)
        ? DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: (flagship!.iconGlowColor ?? activeColor).withValues(alpha: 0.55),
                  blurRadius: flagship!.iconGlowRadius * 0.7,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: iconWidget,
          )
        : iconWidget;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            displayIcon,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: PvTokens.fromTheme(theme).body(
                  size: 14,
                  weight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? activeColor : theme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Desktop page header: title, community search and the app-level actions
/// that live in the app bar on mobile.
class _DesktopContentHeader extends ConsumerWidget {
  final AppTheme theme;
  final FlagshipConfig? flagship;
  final VoidCallback onAbout;
  final VoidCallback onImport;
  final VoidCallback onTheme;
  final VoidCallback onPro;
  final VoidCallback onFeedback;

  const _DesktopContentHeader({
    required this.theme,
    required this.flagship,
    required this.onAbout,
    required this.onImport,
    required this.onTheme,
    required this.onPro,
    required this.onFeedback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pv = context.pv;
    final strings = Strings.of(context);
    final subscription = ref.watch(subscriptionStateProvider);
    final claimable = ref.watch(progressionProvider.select((state) => state.claimableCount));
    final hasFlagshipGradient = flagship != null && flagship!.appBarGradient != null;

    Widget action(IconData icon, String tooltip, VoidCallback onTap, {Widget? badge}) => IconButton(
          tooltip: tooltip,
          iconSize: 24,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          icon: badge ?? Icon(icon, color: pv.textSecondary),
          onPressed: onTap,
        );

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        gradient: hasFlagshipGradient ? flagship!.appBarGradient : null,
        color: hasFlagshipGradient ? null : pv.background.withValues(alpha: 0.6),
        border: Border(bottom: BorderSide(color: pv.divider)),
      ),
      child: Row(
        children: [
          Text(strings.projects.toUpperCase(), style: pv.pixelLabel(size: 22).copyWith(letterSpacing: 1)),
          const SizedBox(width: 32),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: TextField(
                style: pv.body(size: 14),
                onSubmitted: (value) => ref.read(communityProjectsProvider.notifier).searchProjects(value),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: strings.searchProjectsAndCommunity,
                  hintStyle: pv.body(size: 14, color: pv.textSecondary, weight: FontWeight.w400),
                  prefixIcon: Icon(Icons.search, color: pv.textSecondary),
                  filled: true,
                  fillColor: pv.surfaceHigh,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          const Spacer(),
          action(Feather.download, strings.importFile, onImport),
          action(
            Icons.storefront_outlined,
            strings.effectStoreTitle,
            () => EffectStoreScreen.show(
              context,
              tab: claimable > 0 ? EffectStoreTab.quests : EffectStoreTab.packs,
            ),
            badge: Badge(
              isLabelVisible: claimable > 0,
              label: Text('$claimable'),
              child: Icon(Icons.storefront_outlined, color: pv.textSecondary),
            ),
          ),
          if (!subscription.isPro) ...[
            const SizedBox(width: 4),
            AnimatedProButton(onTap: onPro, theme: theme),
            const SizedBox(width: 4),
          ],
          action(Icons.palette_outlined, strings.chooseTheme, onTheme),
          ProjectsAccountMenu(onPlans: onPro, onFeedback: onFeedback, onAbout: onAbout),
        ],
      ),
    );
  }
}

/// Desktop "home" block: Resume card beside quick-create, then the project grid.
/// Featured header plus carousel; renders nothing when there is nothing to show.
class _FeaturedSection extends ConsumerWidget {
  const _FeaturedSection({required this.height, required this.hPad, this.showArrows = true});

  final double height;
  final double hPad;
  final bool showArrows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slides = ref.watch(discoverySlidesProvider);
    if (slides.hasError || (slides.valueOrNull?.isEmpty ?? false)) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PvSectionHeader(
            icon: Icons.star_outline,
            title: Strings.of(context).featured,
            padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 0)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: DiscoveryCarousel(height: height, showArrows: showArrows),
        ),
      ],
    );
  }
}

class _DesktopHome extends StatelessWidget {
  final bool isPro;
  final VoidCallback onPreviewPro;
  final AsyncValue<List<Project>> projects;
  final VoidCallback onCreateNew;
  final void Function(int size) onQuickCreate;
  final VoidCallback onImport;
  final void Function(Project) onTapProject;
  final void Function(Project) onDeleteProject;
  final void Function(Project) onEditProject;
  final void Function(Project) onUploadProject;
  final void Function(Project) onUpdateProject;
  final void Function(Project) onDeleteCloudProject;
  final VoidCallback onRetry;

  const _DesktopHome({
    required this.isPro,
    required this.onPreviewPro,
    required this.projects,
    required this.onCreateNew,
    required this.onQuickCreate,
    required this.onImport,
    required this.onTapProject,
    required this.onDeleteProject,
    required this.onEditProject,
    required this.onUploadProject,
    required this.onUpdateProject,
    required this.onDeleteCloudProject,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final strings = Strings.of(context);
    return projects.when(
      loading: () => const PvProjectsSkeleton(),
      error: (_, __) => Center(
        child: Column(
          children: [
            Text(strings.anErrorOccurred),
            TextButton(onPressed: onRetry, child: Text(strings.tryAgain)),
          ],
        ),
      ),
      data: (all) {
        final sorted = List<Project>.of(all)..sort((a, b) => b.editedAt.compareTo(a.editedAt));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: sorted.isEmpty
                      ? PvEmptyProjects(onCreate: onCreateNew)
                      : PvResumeCardWide(project: sorted.first, onResume: () => onTapProject(sorted.first)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: PvHomeActionPanel(
                    isPro: isPro,
                    onPreviewPro: onPreviewPro,
                    onPickSize: onQuickCreate,
                    onImport: onImport,
                  ),
                ),
              ],
            ),
            if (sorted.isNotEmpty) ...[
              PvSectionHeader(title: '${strings.myProjects} (${sorted.length})', padding: EdgeInsets.zero),
              PvProjectsGrid(
                projects: sorted,
                onCreateNew: onCreateNew,
                onTapProject: onTapProject,
                onDeleteProject: onDeleteProject,
                onEditProject: onEditProject,
                onUploadProject: onUploadProject,
                onUpdateProject: onUpdateProject,
                onDeleteCloudProject: onDeleteCloudProject,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// "Support on Ko-fi" link. The full variant is a warm gradient pill used at
/// the bottom of the desktop sidebar; [compact] renders just a tinted coffee
/// icon for the crowded mobile app bar. Ko-fi's brand red is used for both so
/// the button reads as external support, not another app action.
class KofiSupportButton extends StatelessWidget {
  final bool compact;

  const KofiSupportButton({super.key, this.compact = false});

  static const _kofiRed = Color(0xFFFF5E5B);

  void _open() => launchUrlString(Constants.kofiUrl);

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        tooltip: Strings.of(context).supportOnKofi,
        icon: const Icon(MaterialCommunityIcons.coffee_outline, color: _kofiRed),
        style: IconButton.styleFrom(
          backgroundColor: _kofiRed.withValues(alpha: 0.12),
        ),
        onPressed: _open,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _open,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kofiRed, Color(0xFFFF8C69)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _kofiRed.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(MaterialCommunityIcons.coffee, size: 17, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Support on Ko-fi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.2,
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
