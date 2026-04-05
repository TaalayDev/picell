import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';

import '../../../data.dart';
import '../../../l10n/strings.dart';
import 'project_card.dart';
import 'theme_aware_project_card.dart';

class AdaptiveProjectGrid extends StatelessWidget {
  final List<Project> projects;
  final Function()? onCreateNew;
  final Function(Project)? onTapProject;
  final Function(Project)? onDeleteProject;
  final Function(Project)? onEditProject;
  final Function(Project)? onUploadProject;
  final Function(Project)? onUpdateProject;
  final Function(Project)? onDeleteCloudProject;

  const AdaptiveProjectGrid({
    super.key,
    required this.projects,
    this.onCreateNew,
    this.onTapProject,
    this.onDeleteProject,
    this.onEditProject,
    this.onUploadProject,
    this.onUpdateProject,
    this.onDeleteCloudProject,
  });

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Feather.folder, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              Strings.of(context).noProjectsFound,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: Icon(
                Feather.plus,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              label: Text(Strings.of(context).createNewProject),
              onPressed: onCreateNew,
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width < 600 ? 2 : (width < 1200 ? 3 : 5);

        return MasonryGridView.count(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          padding: const EdgeInsets.all(16),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            return ThemeAwareProjectCard(
              key: ValueKey(projects[index].id),
              project: projects[index],
              onTapProject: onTapProject,
              onDeleteProject: onDeleteProject,
              onEditProject: onEditProject,
              onUploadProject: onUploadProject,
              onUpdateProject: onUpdateProject,
              onDeleteCloudProject: onDeleteCloudProject,
            );
          },
        );
      },
    );
  }
}
