import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../providers/editor_settings_provider.dart';

/// Magic-wand tool options: tolerance slider (0-100%) and a contiguous
/// toggle (flood-fill vs select-by-color). Reads and writes editor settings,
/// so the values persist across sessions.
class WandOptionsBar extends ConsumerWidget {
  const WandOptionsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(editorSettingsNotifierProvider);
    final notifier = ref.read(editorSettingsNotifierProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 1),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_fix_high, size: 16, color: accentColor),
              SizedBox(
                width: 120,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: accentColor,
                    inactiveTrackColor: accentColor.withValues(alpha: 0.2),
                    thumbColor: accentColor,
                    overlayColor: accentColor.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: settings.wandTolerance.toDouble(),
                    min: 0,
                    max: 100,
                    onChanged: (v) => notifier.setWandTolerance(v.round()),
                  ),
                ),
              ),
              Text(
                '${settings.wandTolerance}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: settings.wandContiguous ? 'Contiguous: connected pixels only' : 'Global: all matching colors',
          child: Material(
            color: settings.wandContiguous ? accentColor.withValues(alpha: 0.25) : accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => notifier.setWandContiguous(!settings.wandContiguous),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withValues(alpha: 0.25), width: 1),
                ),
                child: Icon(
                  settings.wandContiguous ? Icons.grain : Icons.blur_on,
                  size: 16,
                  color: accentColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
