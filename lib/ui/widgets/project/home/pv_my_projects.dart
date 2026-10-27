import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../../core.dart';
import '../../../../data.dart';
import '../../../../l10n/strings.dart';
import '../../pv/pv.dart';
import '../project_menu_button.dart';
import '../project_thumbnail.dart';

/// Mobile "home" block of the Projects screen: a Resume card for the last
/// edited project, then a horizontal rail of all projects with a Create tile.
/// Handles its own loading, empty and error states.
class PvMyProjects extends HookWidget {
  const PvMyProjects({
    super.key,
    required this.projects,
    required this.onCreateNew,
    required this.onTapProject,
    required this.onDeleteProject,
    required this.onEditProject,
    required this.onUploadProject,
    required this.onUpdateProject,
    required this.onDeleteCloudProject,
    required this.onRetry,
  });

  final AsyncValue<List<Project>> projects;
  final VoidCallback onCreateNew;
  final void Function(Project) onTapProject;
  final void Function(Project) onDeleteProject;
  final void Function(Project) onEditProject;
  final void Function(Project) onUploadProject;
  final void Function(Project) onUpdateProject;
  final void Function(Project) onDeleteCloudProject;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final query = useState('');
    final showSearch = useState(false);

    useEffect(() {
      void listener() => query.value = searchController.text;
      searchController.addListener(listener);
      return () => searchController.removeListener(listener);
    }, [searchController]);

    final pv = context.pv;
    final strings = Strings.of(context);

    return projects.when(
      loading: () => const PvProjectsSkeleton(),
      error: (_, __) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(strings.anErrorOccurred, style: pv.body(size: 13, color: pv.textSecondary)),
            TextButton(onPressed: onRetry, child: Text(strings.tryAgain)),
          ],
        ),
      ),
      data: (all) {
        if (all.isEmpty) return PvEmptyProjects(onCreate: onCreateNew);

        final sorted = List<Project>.of(all)..sort((a, b) => b.editedAt.compareTo(a.editedAt));
        final q = query.value.trim().toLowerCase();
        final filtered = q.isEmpty ? sorted : sorted.where((p) => p.name.toLowerCase().contains(q)).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: PvResumeCard(project: sorted.first, onResume: () => onTapProject(sorted.first)),
            ),
            PvSectionHeader(
              title: '${strings.myProjects} (${all.length})',
              trailing: IconButton(
                tooltip: strings.search,
                icon: Icon(showSearch.value ? Feather.x : Feather.search, size: 18, color: pv.textSecondary),
                onPressed: () {
                  showSearch.value = !showSearch.value;
                  if (!showSearch.value) searchController.clear();
                },
              ),
            ),
            if (showSearch.value)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: searchController,
                  autofocus: true,
                  style: pv.body(size: 14),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: strings.search,
                    prefixIcon: const Icon(Feather.search, size: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
              ),
            SizedBox(
              height: 232,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                itemCount: filtered.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  if (i == 0) return PvCreateTile(onTap: onCreateNew);
                  final project = filtered[i - 1];
                  return PvProjectTile(
                    key: ValueKey(project.id),
                    project: project,
                    onTap: () => onTapProject(project),
                    onDelete: onDeleteProject,
                    onEdit: onEditProject,
                    onUpload: onUploadProject,
                    onUpdate: onUpdateProject,
                    onDeleteCloud: onDeleteCloudProject,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Sync-state chip shared by the Resume card and project tiles.
class _SyncChip extends StatelessWidget {
  const _SyncChip({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final strings = Strings.of(context);
    return project.isCloudSynced
        ? PvChip(label: strings.synced, icon: Icons.cloud_done_outlined, color: pv.ok, solid: true)
        : PvChip(label: strings.local, icon: Icons.smartphone, color: pv.textSecondary, solid: true);
  }
}

class PvResumeCard extends StatelessWidget {
  const PvResumeCard({super.key, required this.project, required this.onResume});

  final Project project;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final strings = Strings.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: PvPressable(
          onTap: onResume,
          builder: (context, hovered) => Container(
            decoration: BoxDecoration(
              color: pv.surface,
              borderRadius: BorderRadius.circular(pv.cardRadius + 4),
              border: Border.all(color: hovered ? pv.accent : pv.divider),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 6))
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 200,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ProjectThumbnailWidget(project: project, fit: BoxFit.contain),
                      Positioned(left: 10, top: 10, child: _SyncChip(project: project)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.continueWhereYouLeftOff.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: pv.pixelLabel(size: 11, color: pv.accent).copyWith(letterSpacing: 1),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              project.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: pv.body(size: 20, weight: FontWeight.w700),
                            ),
                            Text(
                              '${project.width}×${project.height} · ${formatLastEdited(context, project.editedAt)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: pv.body(size: 13, color: pv.textSecondary, weight: FontWeight.w400),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      DecoratedBox(
                        decoration: BoxDecoration(gradient: pv.gradient, borderRadius: BorderRadius.circular(24)),
                        child: SizedBox(
                          height: 48,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12, right: 18),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_arrow_rounded, color: pv.ink, size: 24),
                                const SizedBox(width: 4),
                                Text(strings.resumeProject,
                                    style: pv.body(size: 15, color: pv.ink, weight: FontWeight.w700)),
                              ],
                            ),
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

class PvCreateTile extends StatelessWidget {
  const PvCreateTile({super.key, required this.onTap, this.width = 160});

  final VoidCallback onTap;

  /// Null fills the grid cell it is placed in.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    return PvPressable(
      onTap: onTap,
      builder: (context, hovered) => Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(pv.cardRadius + 4),
          border: Border.all(color: hovered ? pv.accent : pv.divider, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(gradient: pv.gradient, borderRadius: BorderRadius.circular(12)),
              child: Icon(Feather.plus, color: pv.ink, size: 26),
            ),
            const SizedBox(height: 10),
            Text(Strings.of(context).create, style: pv.body(size: 14, weight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class PvProjectTile extends StatelessWidget {
  const PvProjectTile({
    super.key,
    this.width = 160,
    required this.project,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
    required this.onUpload,
    required this.onUpdate,
    required this.onDeleteCloud,
  });

  /// Null fills the grid cell and shows a square thumbnail.
  final double? width;
  final Project project;
  final VoidCallback onTap;
  final void Function(Project) onDelete;
  final void Function(Project) onEdit;
  final void Function(Project) onUpload;
  final void Function(Project) onUpdate;
  final void Function(Project) onDeleteCloud;

  Widget _fixedOrSquare(Widget child) =>
      width == null ? AspectRatio(aspectRatio: 1, child: child) : SizedBox(height: 150, child: child);

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    return ProjectContextMenuRegion(
      project: project,
      onTapProject: (_) => onTap(),
      onDeleteProject: onDelete,
      onEditProject: onEdit,
      onUploadProject: onUpload,
      onUpdateProject: onUpdate,
      onDeleteCloudProject: onDeleteCloud,
      child: PvPressable(
        onTap: onTap,
        builder: (context, hovered) => Container(
          width: width,
          decoration: BoxDecoration(
            color: pv.surface,
            borderRadius: BorderRadius.circular(pv.cardRadius + 4),
            border: Border.all(color: hovered ? pv.accent : pv.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _fixedOrSquare(
                Stack(
                  fit: StackFit.expand,
                  children: [
                    ProjectThumbnailWidget(project: project, fit: BoxFit.contain),
                    Positioned(left: 8, bottom: 8, child: _SyncChip(project: project)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 0, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: pv.body(size: 14, weight: FontWeight.w600),
                          ),
                          Text(
                            '${project.width}×${project.height} · ${formatLastEdited(context, project.editedAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: pv.body(size: 12, color: pv.textSecondary, weight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 44,
                      child: ProjectMenuButton(
                        project: project,
                        onTapProject: (_) => onTap(),
                        onDeleteProject: onDelete,
                        onEditProject: onEdit,
                        onUploadProject: onUpload,
                        onUpdateProject: onUpdate,
                        onDeleteCloudProject: onDeleteCloud,
                        iconSize: 18,
                        buttonSize: 40,
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

/// First-run state: a pixel pencil, short copy and the hero create button.
class PvEmptyProjects extends StatelessWidget {
  const PvEmptyProjects({super.key, required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final strings = Strings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
        decoration: BoxDecoration(
          color: pv.surface,
          borderRadius: BorderRadius.circular(pv.cardRadius + 4),
          border: Border.all(color: pv.divider),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 120,
                height: 120,
                child: PvCheckerboard(
                  cell: 16,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CustomPaint(painter: _PencilPainter(pv)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.noProjectsYet.toUpperCase(),
              textAlign: TextAlign.center,
              style: pv.pixelLabel(size: 18).copyWith(letterSpacing: 1),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                strings.noProjectsSubtitle,
                textAlign: TextAlign.center,
                style: pv.body(size: 14, color: pv.textSecondary, weight: FontWeight.w400),
              ),
            ),
            const SizedBox(height: 16),
            PvPixelButton(label: strings.createFirstProject, icon: Feather.plus, height: 52, onPressed: onCreate),
          ],
        ),
      ),
    );
  }
}

/// Diagonal pixel pencil drawn on a 10x10 grid from theme colors.
class _PencilPainter extends CustomPainter {
  _PencilPainter(this.pv);

  final PvTokens pv;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 10;
    final cell = size.shortestSide / n;
    final paint = Paint();
    void px(int r, int c, Color color) {
      if (r < 0 || c < 0 || r >= n || c >= n) return;
      canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell + 0.5, cell + 0.5), paint..color = color);
    }

    for (var r = 0; r < n; r++) {
      final body = switch (r) {
        <= 1 => pv.primary,
        2 => pv.textSecondary,
        <= 7 => pv.accent,
        8 => pv.warn,
        _ => pv.textPrimary,
      };
      px(r, n - 1 - r, body);
      px(r, n - r, pv.divider);
      px(r, n - 2 - r, pv.divider);
    }
  }

  @override
  bool shouldRepaint(_PencilPainter old) => old.pv != pv;
}

/// Shimmer placeholder matching the Resume card and project rail.
class PvProjectsSkeleton extends StatelessWidget {
  const PvProjectsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PvShimmerBox(height: 290, radius: 16),
          const SizedBox(height: 20),
          const PvShimmerBox(width: 140, height: 18, radius: 4),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < 3; i++) ...const [
                  PvShimmerBox(width: 160, height: 158, radius: 16),
                  SizedBox(width: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Desktop variant of [PvResumeCard]: thumbnail on the left, details and the
/// Resume button on the right.
class PvResumeCardWide extends StatelessWidget {
  const PvResumeCardWide({super.key, required this.project, required this.onResume});

  final Project project;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final strings = Strings.of(context);
    return PvPressable(
      onTap: onResume,
      builder: (context, hovered) => Container(
        height: 240,
        decoration: BoxDecoration(
          color: pv.surface,
          borderRadius: BorderRadius.circular(pv.cardRadius + 4),
          border: Border.all(color: hovered ? pv.accent : pv.divider),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 6))
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            SizedBox(
              width: 300,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProjectThumbnailWidget(project: project, fit: BoxFit.contain),
                  Positioned(left: 10, top: 10, child: _SyncChip(project: project)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.continueWhereYouLeftOff.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: pv.pixelLabel(size: 11, color: pv.accent).copyWith(letterSpacing: 1),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      project.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: pv.body(size: 28, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${project.width}×${project.height} · ${formatLastEdited(context, project.editedAt)}',
                      style: pv.body(size: 14, color: pv.textSecondary, weight: FontWeight.w400),
                    ),
                    const Spacer(),
                    DecoratedBox(
                      decoration: BoxDecoration(gradient: pv.gradient, borderRadius: BorderRadius.circular(24)),
                      child: SizedBox(
                        height: 48,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 18, right: 24),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded, color: pv.ink, size: 24),
                              const SizedBox(width: 6),
                              Text(strings.resumeProject,
                                  style: pv.body(size: 15, color: pv.ink, weight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Start something new": canvas size presets and an import drop zone.
class PvQuickCreatePanel extends StatelessWidget {
  const PvQuickCreatePanel(
      {super.key, required this.onPickSize, required this.onImport, this.sizes = const [16, 32, 64, 128]});

  final void Function(int size) onPickSize;
  final VoidCallback onImport;
  final List<int> sizes;

  @override
  Widget build(BuildContext context) {
    final pv = context.pv;
    final strings = Strings.of(context);
    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pv.surface,
        borderRadius: BorderRadius.circular(pv.cardRadius + 4),
        border: Border.all(color: pv.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(strings.startSomethingNew, style: pv.body(size: 15, weight: FontWeight.w600)),
          Text(strings.pickCanvasSize, style: pv.body(size: 12, color: pv.textSecondary, weight: FontWeight.w400)),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 3.2,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final size in sizes)
                  PvPressable(
                    onTap: () => onPickSize(size),
                    builder: (context, hovered) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: pv.surfaceHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: hovered ? pv.accent : Colors.transparent, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8 + size / 128 * 16,
                            height: 8 + size / 128 * 16,
                            decoration: BoxDecoration(gradient: pv.gradient, borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text('$size×$size',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: pv.body(size: 14, weight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          PvPressable(
            onTap: onImport,
            builder: (context, hovered) => Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: hovered ? pv.accent : pv.divider, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Feather.upload, size: 18, color: pv.textSecondary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      strings.importImageOrProject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: pv.body(size: 14, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive grid of project tiles with a Create tile first.
class PvProjectsGrid extends StatelessWidget {
  const PvProjectsGrid({
    super.key,
    required this.projects,
    required this.onCreateNew,
    required this.onTapProject,
    required this.onDeleteProject,
    required this.onEditProject,
    required this.onUploadProject,
    required this.onUpdateProject,
    required this.onDeleteCloudProject,
  });

  final List<Project> projects;
  final VoidCallback onCreateNew;
  final void Function(Project) onTapProject;
  final void Function(Project) onDeleteProject;
  final void Function(Project) onEditProject;
  final void Function(Project) onUploadProject;
  final void Function(Project) onUpdateProject;
  final void Function(Project) onDeleteCloudProject;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 16.0;
        final columns = ((constraints.maxWidth + gap) / (190 + gap)).floor().clamp(2, 6);
        final cell = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: projects.length + 1,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: gap,
            crossAxisSpacing: gap,
            childAspectRatio: cell / (cell + 60),
          ),
          itemBuilder: (context, i) {
            if (i == 0) return PvCreateTile(onTap: onCreateNew, width: null);
            final project = projects[i - 1];
            return PvProjectTile(
              key: ValueKey(project.id),
              width: null,
              project: project,
              onTap: () => onTapProject(project),
              onDelete: onDeleteProject,
              onEdit: onEditProject,
              onUpload: onUploadProject,
              onUpdate: onUpdateProject,
              onDeleteCloud: onDeleteCloudProject,
            );
          },
        );
      },
    );
  }
}
