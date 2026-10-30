part of '../projects_screen.dart';

// ── Cloud / Community tab ──────────────────────────────────────────────────

class CloudProjectsView extends HookConsumerWidget {
  final AppTheme theme;
  final UserSubscription subscription;

  /// Extra slivers rendered above the search bar — the discovery carousel
  /// on both platforms, plus (on mobile) the compact "My Projects" section.
  /// Kept as a parameter rather than a separate "no chrome" widget variant
  /// so this single scroll view can host everything above the community
  /// feed without nesting one scrollable inside another.
  final List<Widget> leadingSlivers;

  const CloudProjectsView({
    super.key,
    required this.theme,
    required this.subscription,
    this.leadingSlivers = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityState = ref.watch(communityProjectsProvider);
    final searchController = useTextEditingController();
    final scrollController = useScrollController();
    final showSearch = useState(false);
    final selectedSort = useState('recent');

    // Handle infinite scroll
    useEffect(() {
      void onScroll() {
        if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
          ref.read(communityProjectsProvider.notifier).loadMore();
        }
      }

      scrollController.addListener(onScroll);
      return () => scrollController.removeListener(onScroll);
    }, [scrollController]);

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        ...leadingSlivers,

        // Search and Sort Bar
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: showSearch.value
                      ? TextField(
                          controller: searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: Strings.of(context).searchProjects,
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onSubmitted: (value) {
                            ref.read(communityProjectsProvider.notifier).searchProjects(value);
                          },
                        )
                      : PvSectionHeader(
                          icon: Icons.public,
                          title: Strings.of(context).community,
                          padding: EdgeInsets.zero,
                        ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    showSearch.value ? Icons.close : Icons.search,
                    color: theme.activeIcon,
                  ),
                  onPressed: () {
                    showSearch.value = !showSearch.value;
                    if (!showSearch.value) {
                      searchController.clear();
                      ref.read(communityProjectsProvider.notifier).searchProjects('');
                    }
                  },
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.sort, color: theme.activeIcon),
                  tooltip: Strings.of(context).sortBy,
                  onSelected: (value) {
                    selectedSort.value = value;
                    ref.read(communityProjectsProvider.notifier).setSortOrder(value);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'recent', child: Text(Strings.of(context).mostRecent)),
                    PopupMenuItem(value: 'popular', child: Text(Strings.of(context).mostPopular)),
                    PopupMenuItem(value: 'views', child: Text(Strings.of(context).mostViewed)),
                    PopupMenuItem(value: 'likes', child: Text(Strings.of(context).mostLiked)),
                    PopupMenuItem(value: 'title', child: Text(Strings.of(context).titleAZ)),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: theme.activeIcon),
                  onPressed: () => ref.read(communityProjectsProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
        ),

        // Filter chips
        if (communityState.popularTags.isNotEmpty)
          SliverToBoxAdapter(child: _buildFilterChips(context, ref, communityState, theme)),

        // Featured projects section
        SliverToBoxAdapter(child: _buildFeaturedSection(context, ref, theme)),

        // Main projects grid
        ..._buildProjectsGridSlivers(
          context,
          ref,
          communityState,
          theme,
          subscription,
        ),
      ],
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    WidgetRef ref,
    CommunityProjectsState state,
    AppTheme theme,
  ) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.popularTags.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(Strings.of(context).all),
                selected: state.filters.tags.isEmpty,
                selectedColor: theme.primaryColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: state.filters.tags.isEmpty ? theme.primaryColor : theme.textPrimary,
                ),
                iconTheme: IconThemeData(
                  color: state.filters.tags.isEmpty ? theme.primaryColor : theme.textPrimary,
                ),
                onSelected: (selected) {
                  if (selected) {
                    ref.read(communityProjectsProvider.notifier).clearFilters();
                  }
                },
              ),
            );
          }

          final tag = state.popularTags[index - 1];
          final isSelected = state.filters.tags.contains(tag.slug);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(tag.name),
              selected: isSelected,
              selectedColor: theme.primaryColor.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? theme.primaryColor : theme.textPrimary,
              ),
              iconTheme: IconThemeData(
                color: isSelected ? theme.primaryColor : theme.textPrimary,
              ),
              onSelected: (selected) {
                final newTags = List<String>.from(state.filters.tags);
                if (selected) {
                  newTags.add(tag.slug);
                } else {
                  newTags.remove(tag.slug);
                }
                ref.read(communityProjectsProvider.notifier).filterByTags(newTags);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedSection(
    BuildContext context,
    WidgetRef ref,
    AppTheme theme,
  ) {
    final featuredProjects = ref.watch(featuredProjectsProvider);

    return featuredProjects.when(
      data: (projects) {
        if (projects.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.star, color: theme.warning, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    Strings.of(context).featuredProjects,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    child: CommunityProjectCard(
                      project: projects[index],
                      isFeatured: true,
                      heroTag: 'featured-${projects[index].id}',
                      onTap: () {
                        final project = projects[index];
                        unawaited(ref.read(projectAPIRepoProvider).recordFeaturedClick(project.id));
                        _openProjectDetail(
                          context,
                          ref,
                          project,
                          subscription,
                          siblings: projects,
                          heroTag: 'featured-${project.id}',
                        );
                      },
                      onLike: (project) => ref.read(communityProjectsProvider.notifier).toggleLike(project),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  /// Returns the sliver(s) for the main community grid — loading/error/empty
  /// states each fill the remaining viewport, and the populated state is a
  /// [SliverMasonryGrid] whose column count reacts to the sliver's own
  /// cross-axis extent (via [SliverLayoutBuilder]) rather than the full
  /// screen width, so it stays correct when this view sits beside a sidebar.
  List<Widget> _buildProjectsGridSlivers(
    BuildContext context,
    WidgetRef ref,
    CommunityProjectsState state,
    AppTheme theme,
    UserSubscription subscription,
  ) {
    if (state.isLoading && state.projects.isEmpty) {
      return [
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (state.error != null && state.projects.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Feather.alert_circle,
                  size: 64,
                  color: theme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  Strings.of(context).errorLoadingProjects,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.error!,
                  style: TextStyle(color: theme.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(Strings.of(context).tryAgain),
                  onPressed: () => ref.read(communityProjectsProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (state.projects.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Feather.search,
                  size: 64,
                  color: theme.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No projects found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search or filters',
                  style: TextStyle(color: theme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.crossAxisExtent;
            // More granular than before so typical desktop content widths
            // (screen minus the ~272px sidebar) land on 5-6 smaller cards
            // per row instead of maxing out at 3-5.
            final crossAxisCount = switch (width) {
              < 500 => 2,
              < 800 => 3,
              < 1000 => 4,
              < 1300 => 5,
              _ => 6,
            };

            return SliverMasonryGrid.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childCount: state.projects.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= state.projects.length) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final project = state.projects[index];
                return CommunityProjectCard(
                  key: ValueKey(project.id),
                  project: project,
                  heroTag: 'grid-${project.id}',
                  onTap: () => _openProjectDetail(
                    context,
                    ref,
                    project,
                    subscription,
                    siblings: state.projects,
                    heroTag: 'grid-${project.id}',
                  ),
                  onLike: (project) => ref.read(communityProjectsProvider.notifier).toggleLike(project),
                  onUserTap: (username) {
                    ref.read(communityProjectsProvider.notifier).filterByUser(username);
                  },
                );
              },
            );
          },
        ),
      ),
    ];
  }

  void _openProjectDetail(
    BuildContext context,
    WidgetRef ref,
    ApiProject project,
    UserSubscription subscription, {
    List<ApiProject> siblings = const [],
    String? heroTag,
  }) async {
    if (Random().nextInt(10) < 2 && !subscription.isPro) {
      await ref.read(interstitialAdProvider.notifier).showAdIfLoaded(() {});
    }

    if (!context.mounted) return;
    await ProjectDetailScreen.show(context, project, siblings: siblings, heroTag: heroTag);
  }
}
