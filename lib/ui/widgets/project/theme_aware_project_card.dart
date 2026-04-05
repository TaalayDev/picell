import 'package:flutter/material.dart';
import 'package:picell/data.dart';

import '../../../app/theme/flagship/flagship_extensions.dart';
import '../../../app/theme/flagship/project_card_data.dart';
import 'project_card.dart';

/// Dispatcher: returns a flagship-specific card when the current theme
/// provides one, otherwise falls back to the default [ProjectCard].
class ThemeAwareProjectCard extends StatelessWidget {
  final Project project;
  final Function(Project)? onTapProject;
  final Function(Project)? onDeleteProject;
  final Function(Project)? onEditProject;
  final Function(Project)? onUploadProject;
  final Function(Project)? onUpdateProject;
  final Function(Project)? onDeleteCloudProject;

  const ThemeAwareProjectCard({
    super.key,
    required this.project,
    this.onTapProject,
    this.onDeleteProject,
    this.onEditProject,
    this.onUploadProject,
    this.onUpdateProject,
    this.onDeleteCloudProject,
  });

  @override
  Widget build(BuildContext context) {
    final flagship = context.flagship;

    if (flagship?.isFlagship == true && flagship?.cardBuilder != null) {
      return flagship!.cardBuilder!(
        context,
        ProjectCardData(
          project: project,
          onTapProject: onTapProject,
          onDeleteProject: onDeleteProject,
          onEditProject: onEditProject,
          onUploadProject: onUploadProject,
          onUpdateProject: onUpdateProject,
          onDeleteCloudProject: onDeleteCloudProject,
        ),
      );
    }

    return ProjectCard(
      project: project,
      onTapProject: onTapProject,
      onDeleteProject: onDeleteProject,
      onEditProject: onEditProject,
      onUploadProject: onUploadProject,
      onUpdateProject: onUpdateProject,
      onDeleteCloudProject: onDeleteCloudProject,
    );
  }
}
