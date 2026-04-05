import 'package:flutter/material.dart';

import '../../../ui/widgets/project/flagship/cosmic_project_card.dart';
import 'flagship_config.dart';

FlagshipConfig buildCosmicFlagshipConfig() {
  return FlagshipConfig(
    isFlagship: true,
    transitionDuration: const Duration(milliseconds: 420),
    cardBuilder: (ctx, data) => CosmicProjectCard(
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
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.03),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
    appBarGradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF120B2E),
        Color(0xFF1E255C),
        Color(0xFF08213A),
      ],
    ),
    enableIconGlow: true,
    iconGlowColor: const Color(0xFF00D9FF),
    iconGlowRadius: 14,
    badgeLabel: '✦ COSMIC',
    badgeColor: const Color(0xFFFF6B35),
    badgeTextColor: Colors.white,
  );
}
