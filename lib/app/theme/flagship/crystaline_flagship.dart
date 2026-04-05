import 'package:flutter/material.dart';

import '../../../ui/widgets/project/flagship/crystaline_project_card.dart';
import '../../routing/transitions/crystaline_shard_transition.dart';
import 'flagship_config.dart';

FlagshipConfig buildCrystalineFlagshipConfig() {
  return FlagshipConfig(
    isFlagship: true,
    transitionDuration: const Duration(milliseconds: 400),
    transitionBuilder: CrystalineShardTransition.builder,
    cardBuilder: (ctx, data) => CrystalineProjectCard(
      project: data.project,
      onTapProject: data.onTapProject,
      onDeleteProject: data.onDeleteProject,
      onEditProject: data.onEditProject,
      onUploadProject: data.onUploadProject,
      onUpdateProject: data.onUpdateProject,
      onDeleteCloudProject: data.onDeleteCloudProject,
    ),
    appBarGradient: const LinearGradient(
      colors: [Color(0xFF1A0D2E), Color(0xFF2D1854)],
    ),
    enableIconGlow: true,
    iconGlowColor: const Color(0xFF9B59B6),
    iconGlowRadius: 12,
    badgeLabel: '💎 CRYSTAL',
    badgeColor: const Color(0xFF9B59B6),
    badgeTextColor: const Color(0xFFE8D5FF),
  );
}
