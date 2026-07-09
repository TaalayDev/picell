import 'package:flutter/material.dart';

import '../../../ui/widgets/project/flagship/studio_dark_project_card.dart';
import 'flagship_config.dart';

FlagshipConfig buildStudioDarkFlagshipConfig() {
  return FlagshipConfig(
    isFlagship: true,
    transitionDuration: const Duration(milliseconds: 220),
    cardBuilder: (ctx, data) => StudioDarkProjectCard(
      project: data.project,
      onTapProject: data.onTapProject,
      onDeleteProject: data.onDeleteProject,
      onEditProject: data.onEditProject,
      onUploadProject: data.onUploadProject,
      onUpdateProject: data.onUpdateProject,
      onDeleteCloudProject: data.onDeleteCloudProject,
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.985, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
    appBarGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0B0B0D), Color(0xFF131316)],
    ),
    enableIconGlow: true,
    iconGlowColor: const Color(0xFF2F80ED),
    iconGlowRadius: 6,
    badgeLabel: '◆ STUDIO',
    badgeColor: const Color(0xFF2F80ED),
    badgeTextColor: Colors.white,
  );
}
