import 'package:flutter/material.dart';

import '../../../ui/widgets/project/flagship/steampunk_project_card.dart';
import '../../routing/transitions/steampunk_iris_transition.dart';
import 'flagship_config.dart';

FlagshipConfig buildSteampunkFlagshipConfig() {
  return FlagshipConfig(
    isFlagship: true,
    transitionDuration: const Duration(milliseconds: 400),
    transitionBuilder: SteampunkIrisTransition.builder,
    cardBuilder: (ctx, data) => SteampunkProjectCard(
      project: data.project,
      onTapProject: data.onTapProject,
      onDeleteProject: data.onDeleteProject,
      onEditProject: data.onEditProject,
      onUploadProject: data.onUploadProject,
      onUpdateProject: data.onUpdateProject,
      onDeleteCloudProject: data.onDeleteCloudProject,
    ),
    appBarGradient: const LinearGradient(
      colors: [Color(0xFF1C0F0A), Color(0xFF3D2B1F)],
    ),
    enableIconGlow: true,
    iconGlowColor: const Color(0xFFB87333),
    iconGlowRadius: 8,
    badgeLabel: '⚙ BRASS',
    badgeColor: const Color(0xFFB87333),
    badgeTextColor: const Color(0xFF1C0F0A),
  );
}
