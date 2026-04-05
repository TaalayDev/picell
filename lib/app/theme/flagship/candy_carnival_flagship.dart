import 'package:flutter/material.dart';

import '../../../ui/widgets/project/flagship/candy_carnival_project_card.dart';
import '../../routing/transitions/candy_bounce_transition.dart';
import 'flagship_config.dart';

FlagshipConfig buildCandyCarnivalFlagshipConfig() {
  return FlagshipConfig(
    isFlagship: true,
    transitionDuration: const Duration(milliseconds: 500),
    transitionBuilder: CandyBounceTransition.builder,
    cardBuilder: (ctx, data) => CandyCarnivalProjectCard(
      project: data.project,
      onTapProject: data.onTapProject,
      onDeleteProject: data.onDeleteProject,
      onEditProject: data.onEditProject,
      onUploadProject: data.onUploadProject,
      onUpdateProject: data.onUpdateProject,
      onDeleteCloudProject: data.onDeleteCloudProject,
    ),
    appBarGradient: const LinearGradient(
      colors: [Color(0xFFFF6EB4), Color(0xFFFFB347)],
    ),
    enableIconGlow: false,
    badgeLabel: 'SWEET',
    badgeColor: const Color(0xFFFF6EB4),
    badgeTextColor: Colors.white,
  );
}
