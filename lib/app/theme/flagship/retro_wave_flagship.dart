import 'package:flutter/material.dart';

import '../../../ui/widgets/project/flagship/retro_wave_project_card.dart';
import '../../routing/transitions/retro_wave_transition.dart';
import 'flagship_config.dart';

FlagshipConfig buildRetroWaveFlagshipConfig() {
  return FlagshipConfig(
    isFlagship: true,
    transitionDuration: const Duration(milliseconds: 350),
    transitionBuilder: RetroWaveTransition.builder,
    cardBuilder: (ctx, data) => RetroWaveProjectCard(
      project: data.project,
      onTapProject: data.onTapProject,
      onDeleteProject: data.onDeleteProject,
      onEditProject: data.onEditProject,
      onUploadProject: data.onUploadProject,
      onUpdateProject: data.onUpdateProject,
      onDeleteCloudProject: data.onDeleteCloudProject,
    ),
    appBarGradient: const LinearGradient(
      colors: [Color(0xFF0A0A1A), Color(0xFF2D0A4E)],
    ),
    enableIconGlow: true,
    iconGlowColor: const Color(0xFFFF0080),
    iconGlowRadius: 10,
    badgeLabel: '80s WAVE',
    badgeColor: const Color(0xFFFF0080),
    badgeTextColor: Colors.white,
  );
}
