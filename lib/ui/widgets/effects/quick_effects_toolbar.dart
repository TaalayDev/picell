import 'package:flutter/material.dart';
import '../../../data.dart';
import '../../../l10n/strings.dart';
import '../../../pixel/effects/effects.dart';
import '../../../pixel/services/effect_stack_service.dart';
import 'effects_panel.dart';
import 'effects_selector_dialog.dart';

class QuickEffectsToolbar extends StatelessWidget {
  final Layer layer;
  final Function(Effect) onApplyEffect;

  const QuickEffectsToolbar({
    super.key,
    required this.layer,
    required this.onApplyEffect,
  });

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final workspace in EffectWorkspace.values)
            _buildWorkspaceButton(context, workspace, s),
        ],
      ),
    );
  }

  Widget _buildWorkspaceButton(
    BuildContext context,
    EffectWorkspace workspace,
    Strings s,
  ) {
    final name = switch (workspace) {
      EffectWorkspace.filters => s.effectWorkspaceFilters,
      EffectWorkspace.materials => s.effectWorkspaceMaterials,
      EffectWorkspace.generators => s.effectWorkspaceGenerators,
      EffectWorkspace.animation => s.effectWorkspaceAnimation,
      EffectWorkspace.lighting => s.effectWorkspaceLighting,
      EffectWorkspace.distortions => s.effectWorkspaceDistortions,
    };
    final icon = switch (workspace) {
      EffectWorkspace.filters => Icons.filter_alt_outlined,
      EffectWorkspace.materials => Icons.texture_outlined,
      EffectWorkspace.generators => Icons.auto_awesome_outlined,
      EffectWorkspace.animation => Icons.animation_outlined,
      EffectWorkspace.lighting => Icons.light_mode_outlined,
      EffectWorkspace.distortions => Icons.waves_outlined,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Tooltip(
        message: name,
        child: InkWell(
          key: ValueKey('quick-effects-workspace-${workspace.name}'),
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) => EffectSelectorDialog(
              initialWorkspace: workspace,
              lockWorkspace: true,
              layer: layer,
              onEffectSelected: onApplyEffect,
            ),
          ),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Enhanced effects dialog with quick presets
class EnhancedEffectsDialog extends StatelessWidget {
  final Layer layer;
  final int width;
  final int height;
  final Function(Layer) onLayerUpdated;

  const EnhancedEffectsDialog({
    super.key,
    required this.layer,
    required this.width,
    required this.height,
    required this.onLayerUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);

    return AlertDialog(
      title: Text(s.layerEffects),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            // Quick effects toolbar
            QuickEffectsToolbar(
              layer: layer,
              onApplyEffect: (effect) {
                final result = EffectStackService.addEffect(layer, effect);
                if (result.didAdd) onLayerUpdated(result.layer);
              },
            ),
            const Divider(),
            const SizedBox(height: 8),
            // Full effects panel
            Expanded(
              child: EffectsPanel(
                layer: layer,
                onLayerUpdated: onLayerUpdated,
                width: width,
                height: height,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.cancel),
        ),
      ],
    );
  }
}

// Effects presets for common scenarios
class EffectsPresets {
  static List<Effect> vintagePhoto() {
    return [
      SepiaEffect({'intensity': 0.7}),
      VignetteEffect({'intensity': 0.5, 'size': 0.7}),
      NoiseEffect({'amount': 0.05}),
    ];
  }

  static List<Effect> sharpPixelArt() {
    return [
      SharpenEffect({'amount': 0.4}),
      ContrastEffect({'value': 0.2}),
    ];
  }

  static List<Effect> dreamyGlow() {
    return [
      BlurEffect({'radius': 1}),
      BrightnessEffect({'value': 0.1}),
    ];
  }

  static List<Effect> highContrast() {
    return [
      ContrastEffect({'value': 0.5}),
      SharpenEffect({'amount': 0.3}),
    ];
  }

  static List<Effect> pencilSketch() {
    return [
      GrayscaleEffect({'intensity': 0.9}),
      ContrastEffect({'value': 0.4}),
      EmbossEffect({'strength': 1.5, 'direction': 2}),
    ];
  }

  static List<Effect> neonGlow() {
    return [
      ContrastEffect({'value': 0.3}),
      BlurEffect({'radius': 1}),
      BrightnessEffect({'value': 0.2}),
    ];
  }
}

// Widget that shows effect presets
class EffectPresetsWidget extends StatelessWidget {
  final Function(List<Effect>) onApplyPreset;

  const EffectPresetsWidget({
    super.key,
    required this.onApplyPreset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Effect Presets',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildPresetCard(
                context,
                'Vintage Photo',
                Icons.photo_filter,
                Colors.brown.shade300,
                () => onApplyPreset(EffectsPresets.vintagePhoto()),
              ),
              _buildPresetCard(
                context,
                'Sharp Pixel Art',
                Icons.shape_line,
                Colors.blue.shade300,
                () => onApplyPreset(EffectsPresets.sharpPixelArt()),
              ),
              _buildPresetCard(
                context,
                'Dreamy Glow',
                Icons.light_mode,
                Colors.purple.shade300,
                () => onApplyPreset(EffectsPresets.dreamyGlow()),
              ),
              _buildPresetCard(
                context,
                'High Contrast',
                Icons.contrast,
                Colors.red.shade300,
                () => onApplyPreset(EffectsPresets.highContrast()),
              ),
              _buildPresetCard(
                context,
                'Pencil Sketch',
                Icons.edit,
                Colors.grey.shade400,
                () => onApplyPreset(EffectsPresets.pencilSketch()),
              ),
              _buildPresetCard(
                context,
                'Neon Glow',
                Icons.light_mode,
                Colors.cyan.shade300,
                () => onApplyPreset(EffectsPresets.neonGlow()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetCard(
    BuildContext context,
    String name,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 110,
          height: 100,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
