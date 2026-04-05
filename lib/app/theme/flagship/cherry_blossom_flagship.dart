import 'package:flutter/material.dart';

import '../../../ui/widgets/project/flagship/cherry_blossom_project_card.dart';
import '../../routing/transitions/cherry_petal_transition.dart';
import 'flagship_config.dart';

FlagshipConfig buildCherryBlossomFlagshipConfig() {
  return FlagshipConfig(
    isFlagship: true,
    transitionDuration: const Duration(milliseconds: 400),
    transitionBuilder: CherryPetalTransition.builder,
    cardBuilder: (ctx, data) => CherryBlossomProjectCard(
      project: data.project,
      onTapProject: data.onTapProject,
      onDeleteProject: data.onDeleteProject,
      onEditProject: data.onEditProject,
      onUploadProject: data.onUploadProject,
      onUpdateProject: data.onUpdateProject,
      onDeleteCloudProject: data.onDeleteCloudProject,
    ),
    appBarGradient: const LinearGradient(
      colors: [Color(0xFFFFFBFC), Color(0xFFFFF0F3)],
    ),
    enableIconGlow: false,
    iconGlowColor: const Color(0xFFFFB7C5),
    iconGlowRadius: 8,
    badgeLabel: '桜 SAKURA',
    badgeColor: const Color(0xFFFFB7C5),
    badgeTextColor: const Color(0xFF9C4A6E),
  );
}
