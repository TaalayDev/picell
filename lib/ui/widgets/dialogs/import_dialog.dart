import 'package:flutter/material.dart';

import '../../../l10n/strings.dart';
import '../../../pixel/pixel_art_converter.dart';

/// Result returned by [ImportDialog.show].
class ImportDialogResult {
  final bool isBackground;
  final PixelArtConversionOptions conversionOptions;

  const ImportDialogResult({
    required this.isBackground,
    this.conversionOptions = const PixelArtConversionOptions(),
  });
}

class ImportDialog extends StatefulWidget {
  const ImportDialog({super.key});

  static Future<ImportDialogResult?> show(BuildContext context) {
    return showDialog<ImportDialogResult>(
      context: context,
      builder: (context) => const ImportDialog(),
    );
  }

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  // Mode: false = pixel art layer, true = background
  bool _isBackground = false;

  // Pixel-art conversion options
  int _paletteSize = 0; // 0 = full color
  PixelArtDithering _dithering = PixelArtDithering.none;
  double _alphaThreshold = 128;

  static const _paletteSizes = [0, 8, 16, 32, 64];

  void _confirm() {
    Navigator.of(context).pop(
      ImportDialogResult(
        isBackground: _isBackground,
        conversionOptions: PixelArtConversionOptions(
          paletteSize: _paletteSize,
          dithering: _dithering,
          alphaThreshold: _alphaThreshold.round(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = Strings.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.file_upload, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text(s.importImage, style: theme.textTheme.titleLarge),
        ],
      ),
      content: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Mode selector ──────────────────────────────────────────
              _ModeSelector(
                isBackground: _isBackground,
                onChanged: (v) => setState(() => _isBackground = v),
              ),

              // ── Conversion settings (only for pixel art mode) ──────────
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _isBackground
                    ? const SizedBox.shrink()
                    : _ConversionSettings(
                        paletteSize: _paletteSize,
                        dithering: _dithering,
                        alphaThreshold: _alphaThreshold,
                        paletteSizes: _paletteSizes,
                        onPaletteChanged: (v) =>
                            setState(() => _paletteSize = v),
                        onDitheringChanged: (v) =>
                            setState(() => _dithering = v),
                        onAlphaChanged: (v) =>
                            setState(() => _alphaThreshold = v),
                      ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(s.cancel),
        ),
        FilledButton.icon(
          onPressed: _confirm,
          icon: const Icon(Icons.photo_library_outlined, size: 18),
          label: Text(s.chooseImage),
        ),
      ],
    );
  }
}

// ─── Mode Selector ────────────────────────────────────────────────────────────

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.isBackground,
    required this.onChanged,
  });

  final bool isBackground;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ModeCard(
          selected: !isBackground,
          icon: Icons.layers,
          title: s.convertToPixelArt,
          description: s.convertToPixelArtDescription,
          onTap: () => onChanged(false),
        ),
        const SizedBox(height: 10),
        _ModeCard(
          selected: isBackground,
          icon: Icons.image_outlined,
          title: s.importAsBackground,
          description: s.importAsBackgroundDescription,
          onTap: () => onChanged(true),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? colorScheme.primary : theme.dividerColor,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
          color: selected
              ? colorScheme.primaryContainer.withValues(alpha: 0.25)
              : colorScheme.surface,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 24,
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Conversion Settings ──────────────────────────────────────────────────────

class _ConversionSettings extends StatelessWidget {
  const _ConversionSettings({
    required this.paletteSize,
    required this.dithering,
    required this.alphaThreshold,
    required this.paletteSizes,
    required this.onPaletteChanged,
    required this.onDitheringChanged,
    required this.onAlphaChanged,
  });

  final int paletteSize;
  final PixelArtDithering dithering;
  final double alphaThreshold;
  final List<int> paletteSizes;
  final ValueChanged<int> onPaletteChanged;
  final ValueChanged<PixelArtDithering> onDitheringChanged;
  final ValueChanged<double> onAlphaChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = Strings.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 24),
        Text(
          s.conversionSettings,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // ── Palette size ──────────────────────────────────────────────────
        Text(s.paletteColors, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        _PalettePicker(
          selected: paletteSize,
          options: paletteSizes,
          fullColorLabel: s.fullColor,
          onChanged: onPaletteChanged,
        ),

        const SizedBox(height: 16),

        // ── Dithering ─────────────────────────────────────────────────────
        Text(s.dithering, style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        _DitheringPicker(
          selected: dithering,
          noneLabel: s.noDithering,
          onChanged: onDitheringChanged,
        ),

        const SizedBox(height: 16),

        // ── Alpha threshold ───────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(s.alphaThreshold, style: theme.textTheme.bodySmall),
            Text(
              alphaThreshold.round().toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: alphaThreshold,
          min: 0,
          max: 255,
          divisions: 51,
          label: alphaThreshold.round().toString(),
          onChanged: onAlphaChanged,
        ),
      ],
    );
  }
}

// ─── Palette picker ───────────────────────────────────────────────────────────

class _PalettePicker extends StatelessWidget {
  const _PalettePicker({
    required this.selected,
    required this.options,
    required this.fullColorLabel,
    required this.onChanged,
  });

  final int selected;
  final List<int> options;
  final String fullColorLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final size in options)
          ChoiceChip(
            label: Text(size == 0 ? fullColorLabel : size.toString()),
            selected: selected == size,
            onSelected: (_) => onChanged(size),
            selectedColor: colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: selected == size
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
              fontWeight:
                  selected == size ? FontWeight.bold : FontWeight.normal,
            ),
          ),
      ],
    );
  }
}

// ─── Dithering picker ─────────────────────────────────────────────────────────

class _DitheringPicker extends StatelessWidget {
  const _DitheringPicker({
    required this.selected,
    required this.noneLabel,
    required this.onChanged,
  });

  final PixelArtDithering selected;
  final String noneLabel;
  final ValueChanged<PixelArtDithering> onChanged;

  static const _labels = {
    PixelArtDithering.none: null, // replaced by noneLabel
    PixelArtDithering.floydSteinberg: 'Floyd-Steinberg',
    PixelArtDithering.bayer4x4: 'Bayer 4×4',
    PixelArtDithering.bayer8x8: 'Bayer 8×8',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final entry in _labels.entries)
          ChoiceChip(
            label: Text(entry.value ?? noneLabel),
            selected: selected == entry.key,
            onSelected: (_) => onChanged(entry.key),
            selectedColor: colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: selected == entry.key
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
              fontWeight: selected == entry.key
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
      ],
    );
  }
}
