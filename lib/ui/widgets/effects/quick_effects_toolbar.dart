import 'package:flutter/material.dart';
import '../../../data.dart';
import '../../../pixel/effects/effects.dart';
import 'effects_panel.dart';

class QuickEffectsToolbar extends StatelessWidget {
  final Function(Effect) onApplyEffect;

  const QuickEffectsToolbar({
    super.key,
    required this.onApplyEffect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildEffectButton(
            context,
            'Invert',
            Icons.invert_colors,
            () => onApplyEffect(InvertEffect()),
          ),
          _buildEffectButton(
            context,
            'Grayscale',
            Icons.monochrome_photos,
            () => onApplyEffect(GrayscaleEffect()),
          ),
          _buildEffectButton(
            context,
            'Sepia',
            Icons.filter_vintage,
            () => onApplyEffect(SepiaEffect()),
          ),
          _buildEffectButton(
            context,
            'Watercolor', // New watercolor effect button
            Icons.water_drop, // Using water_drop icon for watercolor
            () => onApplyEffect(WatercolorEffect()),
          ),
          _buildEffectButton(
            context,
            'Halftone', // New halftone effect button
            Icons.grid_3x3, // Using grid_3x3 icon for halftone
            () => onApplyEffect(HalftoneEffect()),
          ),
          _buildEffectButton(
            context,
            'Glow', // New glow effect button
            Icons.light_mode, // Using light_mode icon for glow
            () => onApplyEffect(GlowEffect()),
          ),
          _buildEffectButton(
            context,
            'Oil Paint', // New glow effect button
            Icons.brush, // Using brush icon for oil paint
            () => onApplyEffect(OilPaintEffect()),
          ),
          _buildEffectButton(
            context,
            'Blur',
            Icons.blur_on,
            () => onApplyEffect(BlurEffect()),
          ),
          _buildEffectButton(
            context,
            'Sharpen',
            Icons.blur_linear,
            () => onApplyEffect(SharpenEffect()),
          ),
          _buildEffectButton(
            context,
            'Pixelate',
            Icons.grid_on,
            () => onApplyEffect(PixelateEffect()),
          ),
          _buildEffectButton(
            context,
            'Emboss',
            Icons.layers,
            () => onApplyEffect(EmbossEffect()),
          ),
          _buildEffectButton(
            context,
            'Noise',
            Icons.grain,
            () => onApplyEffect(NoiseEffect()),
          ),
          _buildEffectButton(
            context,
            'Brightness',
            Icons.brightness_6,
            () => onApplyEffect(BrightnessEffect({'value': 0.2})),
          ),
          _buildEffectButton(
            context,
            'Contrast',
            Icons.contrast,
            () => onApplyEffect(ContrastEffect({'value': 0.2})),
          ),
          _buildEffectButton(
            context,
            'Threshold',
            Icons.tonality,
            () => onApplyEffect(ThresholdEffect()),
          ),
          _buildEffectButton(
            context,
            'Vignette',
            Icons.vignette,
            () => onApplyEffect(VignetteEffect()),
          ),
        ],
      ),
    );
  }

  Widget _buildEffectButton(
    BuildContext context,
    String name,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Tooltip(
        message: name,
        child: InkWell(
          onTap: onTap,
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
    Key? key,
    required this.layer,
    required this.width,
    required this.height,
    required this.onLayerUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Layer Effects'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: Column(
          children: [
            // Quick effects toolbar
            QuickEffectsToolbar(
              onApplyEffect: (effect) {
                final updatedEffects = List<Effect>.from(layer.effects)..add(effect);
                final updatedLayer = layer.copyWith(effects: updatedEffects);
                onLayerUpdated(updatedLayer);
                Navigator.of(context).pop();
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
          child: const Text('Cancel'),
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
    Key? key,
    required this.onApplyPreset,
  }) : super(key: key);

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
