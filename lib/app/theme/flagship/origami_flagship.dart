import 'package:flutter/material.dart';

import '../../../ui/widgets/project/flagship/origami_project_card.dart';
import '../../routing/transitions/origami_fold_transition.dart';
import 'flagship_config.dart';

FlagshipConfig buildOrigamiFlagshipConfig() {
  return FlagshipConfig(
    isFlagship: true,
    transitionDuration: const Duration(milliseconds: 450),
    transitionBuilder: OrigamiFoldTransition.builder,
    cardBuilder: (ctx, data) => OrigamiProjectCard(
      project: data.project,
      onTapProject: data.onTapProject,
      onDeleteProject: data.onDeleteProject,
      onEditProject: data.onEditProject,
      onUploadProject: data.onUploadProject,
      onUpdateProject: data.onUpdateProject,
      onDeleteCloudProject: data.onDeleteCloudProject,
    ),
    appBarGradient: const LinearGradient(
      colors: [Color(0xFFFAFAF8), Color(0xFFF0EFE8)],
    ),
    enableIconGlow: false,
    badgeLabel: '折り FOLD',
    badgeColor: const Color(0xFF7C9A85),
    badgeTextColor: Colors.white,
  );
}
