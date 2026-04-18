import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/colors.dart';
import '../../../l10n/strings.dart';
import '../../../providers/imported_palette_provider.dart';

/// Utility class to generate different types of color palettes
class ColorPaletteGenerator {
  /// Generate shades and tints of a color
  static List<Color> generateShades(Color baseColor, int count) {
    final List<Color> colors = [];
    final HSLColor hslColor = HSLColor.fromColor(baseColor);

    // Add darker shades (decreasing lightness)
    for (int i = count ~/ 2; i > 0; i--) {
      final double lightness = (hslColor.lightness - (i * 0.1)).clamp(0.0, 1.0);
      colors.add(hslColor.withLightness(lightness).toColor());
    }

    // Add the base color
    colors.add(baseColor);

    // Add lighter tints (increasing lightness)
    for (int i = 1; i <= count ~/ 2; i++) {
      final double lightness = (hslColor.lightness + (i * 0.1)).clamp(0.0, 1.0);
      colors.add(hslColor.withLightness(lightness).toColor());
    }

    return colors;
  }

  /// Generate complementary colors (colors opposite on the color wheel)
  static List<Color> generateComplementary(Color baseColor) {
    final HSLColor hslColor = HSLColor.fromColor(baseColor);
    final double complementaryHue = (hslColor.hue + 180) % 360;

    final complementaryColor = HSLColor.fromAHSL(
      hslColor.alpha,
      complementaryHue,
      hslColor.saturation,
      hslColor.lightness,
    ).toColor();

    return [
      baseColor,
      complementaryColor,
      // Add shades of complementary color
      HSLColor.fromAHSL(
        hslColor.alpha,
        complementaryHue,
        hslColor.saturation,
        (hslColor.lightness - 0.2).clamp(0.0, 1.0),
      ).toColor(),
      HSLColor.fromAHSL(
        hslColor.alpha,
        complementaryHue,
        hslColor.saturation,
        (hslColor.lightness + 0.2).clamp(0.0, 1.0),
      ).toColor(),
    ];
  }

  /// Generate analogous colors (colors adjacent on the color wheel)
  static List<Color> generateAnalogous(Color baseColor, int count) {
    final List<Color> colors = [];
    final HSLColor hslColor = HSLColor.fromColor(baseColor);

    final double hueStep = 30; // 30 degrees on the color wheel

    for (int i = -count ~/ 2; i <= count ~/ 2; i++) {
      final double hue = (hslColor.hue + (i * hueStep)) % 360;
      colors.add(HSLColor.fromAHSL(
        hslColor.alpha,
        hue,
        hslColor.saturation,
        hslColor.lightness,
      ).toColor());
    }

    return colors;
  }

  /// Generate triadic colors (three colors equally spaced on the color wheel)
  static List<Color> generateTriadic(Color baseColor) {
    final HSLColor hslColor = HSLColor.fromColor(baseColor);

    final List<Color> colors = [
      baseColor,
      HSLColor.fromAHSL(
        hslColor.alpha,
        (hslColor.hue + 120) % 360,
        hslColor.saturation,
        hslColor.lightness,
      ).toColor(),
      HSLColor.fromAHSL(
        hslColor.alpha,
        (hslColor.hue + 240) % 360,
        hslColor.saturation,
        hslColor.lightness,
      ).toColor(),
    ];

    return colors;
  }

  /// Generate a monochromatic palette (same hue, different saturation/lightness)
  static List<Color> generateMonochromatic(Color baseColor, int count) {
    final List<Color> colors = [];
    final HSLColor hslColor = HSLColor.fromColor(baseColor);

    // Vary saturation and lightness while keeping the same hue
    for (int i = 0; i < count; i++) {
      final double saturation = 0.1 + (i / count * 0.9);
      final double lightness = 0.1 + (i / count * 0.8);

      colors.add(HSLColor.fromAHSL(
        hslColor.alpha,
        hslColor.hue,
        saturation,
        lightness,
      ).toColor());
    }

    // Add the base color if it's not already in the list
    if (!colors.contains(baseColor)) {
      colors.add(baseColor);
    }

    return colors;
  }
}

// Tab index constants
const _kTabBasic = 0;
const _kTabShades = 1;
const _kTabComplementary = 2;
const _kTabAnalogous = 3;
const _kTabTriadic = 4;
const _kTabMonochromatic = 5;
const _kTabCustom = 6;
const _kTabImported = 7;

class ColorPalettePanel extends HookConsumerWidget {
  final Color currentColor;
  final Function(Color) onColorSelected;
  final Function() onSelectEyedropper;
  final bool isEyedropperSelected;
  final ScrollController? scrollController;

  const ColorPalettePanel({
    super.key,
    required this.currentColor,
    required this.onColorSelected,
    required this.onSelectEyedropper,
    required this.isEyedropperSelected,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customColors = useState<List<Color>>([]);
    final recentColors = useState<List<Color>>([]);
    final selectedTab = useState(_kTabBasic);
    final opacity = useState(currentColor.a);

    void trackRecentColor(Color color) {
      final withoutDupe = recentColors.value.where((c) => c != color).toList();
      recentColors.value = [color, ...withoutDupe].take(12).toList();
      onColorSelected(color);
    }

    // Watch the imported palette; auto-switch to Imported tab when it changes
    final importedColors = ref.watch(importedPaletteProvider);
    useEffect(() {
      if (importedColors.isNotEmpty) {
        selectedTab.value = _kTabImported;
      }
      return null;
    }, [importedColors]);

    final hasImported = importedColors.isNotEmpty;

    final tabs = [
      _PaletteTab(icon: Icons.palette, label: Strings.of(context).paletteBasic),
      _PaletteTab(icon: Icons.tonality, label: Strings.of(context).paletteShades),
      _PaletteTab(icon: Icons.flip, label: Strings.of(context).paletteComplementary),
      _PaletteTab(icon: Icons.compare_arrows, label: Strings.of(context).paletteAnalogous),
      _PaletteTab(icon: Icons.change_history, label: Strings.of(context).paletteTriadic),
      _PaletteTab(icon: Icons.gradient, label: Strings.of(context).paletteMonochromatic),
      _PaletteTab(icon: Icons.bookmark, label: Strings.of(context).paletteCustom),
      if (hasImported)
        _PaletteTab(icon: Icons.image_outlined, label: Strings.of(context).paletteImported),
    ];

    List<Color> getTabColors() {
      switch (selectedTab.value) {
        case _kTabBasic:
          return kBasicColors;
        case _kTabShades:
          return ColorPaletteGenerator.generateShades(currentColor, 10);
        case _kTabComplementary:
          return ColorPaletteGenerator.generateComplementary(currentColor);
        case _kTabAnalogous:
          return ColorPaletteGenerator.generateAnalogous(currentColor, 5);
        case _kTabTriadic:
          return ColorPaletteGenerator.generateTriadic(currentColor);
        case _kTabMonochromatic:
          return ColorPaletteGenerator.generateMonochromatic(currentColor, 10);
        case _kTabCustom:
          return customColors.value;
        case _kTabImported:
          return importedColors;
        default:
          return kBasicColors;
      }
    }

    final isCustomTab = selectedTab.value == _kTabCustom;
    final isImportedTab = selectedTab.value == _kTabImported;

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _showColorPicker(context, customColors),
                  child: Container(
                    width: double.infinity,
                    height: 35,
                    decoration: BoxDecoration(
                      color: currentColor,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        '#${currentColor.toARGB32().toRadixString(16).toUpperCase().substring(2)}',
                        style: TextStyle(
                          color: currentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  // Add current color to custom palette
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    tooltip: Strings.of(context).addToCustomPalette,
                    onPressed: () {
                      if (!customColors.value.contains(currentColor)) {
                        customColors.value = [...customColors.value, currentColor];
                      }
                    },
                  ),
                  // Eyedropper tool
                  IconButton(
                    icon: Icon(
                      MaterialCommunityIcons.eyedropper,
                      color: isEyedropperSelected ? Colors.blue : null,
                      size: 18,
                    ),
                    onPressed: onSelectEyedropper,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Opacity slider
          Row(
            children: [
              const Icon(Icons.opacity, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 8,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    trackShape: _OpacitySliderTrackShape(color: currentColor),
                  ),
                  child: Slider(
                    value: opacity.value,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) {
                      opacity.value = value;
                      final newColor = currentColor.withAlpha((value * 255).round());
                      onColorSelected(newColor);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 45,
                child: Text(
                  '${(opacity.value * 100).round()}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          // Recent colors row
          if (recentColors.value.isNotEmpty) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 22,
              child: Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recentColors.value.length,
                      itemBuilder: (context, index) {
                        final c = recentColors.value[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: Tooltip(
                            message: '#${c.toARGB32().toRadixString(16).toUpperCase().substring(2)}',
                            child: GestureDetector(
                              onTap: () => trackRecentColor(c),
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: c == currentColor
                                        ? Colors.blue
                                        : Colors.grey.withValues(alpha: 0.4),
                                    width: c == currentColor ? 2 : 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 5),

          // Tabs for different palette types
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ChoiceChip(
                    avatar: Icon(
                      tabs[index].icon,
                      size: 16,
                      color: selectedTab.value == index
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).iconTheme.color,
                    ),
                    label: Text(
                      tabs[index].label,
                      style: TextStyle(
                        fontSize: 12,
                        color: selectedTab.value == index ? Theme.of(context).colorScheme.onPrimary : null,
                      ),
                    ),
                    selected: selectedTab.value == index,
                    showCheckmark: false,
                    onSelected: (selected) {
                      if (selected) {
                        selectedTab.value = index;
                      }
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Color palette grid
          Expanded(
            child: isCustomTab && customColors.value.isEmpty
                ? Center(
                    child: Text(
                      Strings.of(context).noCustomColors,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  )
                : GridView.builder(
                    controller: scrollController,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 8 : 12,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: getTabColors().length + (isCustomTab ? 1 : 0),
                    itemBuilder: (context, index) {
                      final colors = getTabColors();
                      if (isCustomTab && index == colors.length) {
                        return _buildAddColorButton(context, customColors);
                      } else if (index < colors.length) {
                        return _buildColorItem(
                          colors[index],
                          customColors,
                          isCustomTab,
                          onTap: trackRecentColor,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),

          // Imported palette badge/info
          if (isImportedTab)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${importedColors.length} ${Strings.of(context).paletteImportedCount}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColorItem(
    Color color,
    ValueNotifier<List<Color>> customColors,
    bool showDeleteOption, {
    void Function(Color)? onTap,
  }) {
    return InkWell(
      onTap: () => (onTap ?? onColorSelected)(color),
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: color == currentColor ? Colors.blue : Colors.grey.withValues(alpha: 0.3),
                width: color == currentColor ? 2 : 1,
              ),
            ),
          ),
          if (showDeleteOption && customColors.value.contains(color))
            Positioned(
              top: 1,
              right: 1,
              child: GestureDetector(
                onTap: () {
                  final newList = List<Color>.from(customColors.value);
                  newList.remove(color);
                  customColors.value = newList;
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: const Icon(Icons.close, size: 10, color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddColorButton(
    BuildContext context,
    ValueNotifier<List<Color>> customColors,
  ) {
    return InkWell(
      onTap: () => _showColorPicker(context, customColors),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.add, size: 16),
      ),
    );
  }

  void _showColorPicker(
    BuildContext context,
    ValueNotifier<List<Color>> customColors,
  ) {
    Color pickerColor = currentColor;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            Strings.of(context).pickAColor,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: true,
              displayThumbColor: true,
              showLabel: true,
              paletteType: PaletteType.hsv,
              hexInputBar: true,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(Strings.of(context).cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // TextButton(
            //   child: const Text('Save to Palette'),
            //   onPressed: () {
            //     if (!customColors.value.contains(pickerColor)) {
            //       customColors.value = [...customColors.value, pickerColor];
            //     }
            //     onColorSelected(pickerColor);
            //     Navigator.of(context).pop();
            //   },
            // ),
            TextButton(
              child: Text(Strings.of(context).gotIt),
              onPressed: () {
                onColorSelected(pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

/// Helper class for palette tabs
class _PaletteTab {
  final IconData icon;
  final String label;

  const _PaletteTab({
    required this.icon,
    required this.label,
  });
}

/// Custom slider track shape that shows a gradient from transparent to the selected color
class _OpacitySliderTrackShape extends SliderTrackShape {
  final Color color;

  const _OpacitySliderTrackShape({required this.color});

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 4;
    final trackLeft = offset.dx + 8;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width - 16;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
    );

    final canvas = context.canvas;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));

    // Draw checkerboard pattern for transparency visualization
    canvas.save();
    canvas.clipRRect(rrect);
    const checkerSize = 4.0;
    for (double x = rect.left; x < rect.right; x += checkerSize) {
      for (double y = rect.top; y < rect.bottom; y += checkerSize) {
        final isLight = ((x - rect.left) ~/ checkerSize + (y - rect.top) ~/ checkerSize) % 2 == 0;
        final paint = Paint()..color = isLight ? Colors.white : Colors.grey.shade300;
        canvas.drawRect(
          Rect.fromLTWH(x, y, checkerSize, checkerSize),
          paint,
        );
      }
    }
    canvas.restore();

    // Draw gradient from transparent to opaque
    final gradient = LinearGradient(
      colors: [
        color.withAlpha(0),
        color.withAlpha(255),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, paint);

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(rrect, borderPaint);
  }
}
