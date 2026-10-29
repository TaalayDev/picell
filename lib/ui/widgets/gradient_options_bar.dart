import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../l10n/strings.dart';
import '../../pixel/gradient/gradient_options.dart';
import '../../pixel/gradient/gradient_renderer.dart';
import '../../providers/editor_settings_provider.dart';
import '../../providers/imported_palette_provider.dart';

/// Gradient tool options: shape, colour bands, dither, paint area, blend and
/// which colours the ramp uses. Reads and writes editor settings, so the
/// values persist across sessions.
class GradientOptionsBar extends ConsumerWidget {
  const GradientOptionsBar({super.key, this.primaryColor});

  /// Current drawing colour, offered as "add" in the colour ramp editor.
  final Color? primaryColor;

  static const stepChoices = [0, 2, 3, 4, 5, 6, 8, 10, 12, 16];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(editorSettingsNotifierProvider);
    final notifier = ref.read(editorSettingsNotifierProvider.notifier);
    final s = Strings.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final usesRamp = settings.usesGradientRamp;
    final isSmooth = !usesRamp && settings.gradientSteps < 2;
    final isArea = settings.gradientTarget == GradientTarget.contiguous;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MenuPill<GradientType>(
          key: const ValueKey('gradient-type'),
          accent: accent,
          tooltip: typeLabel(s, settings.gradientType),
          selected: settings.gradientType,
          items: {
            for (final t in GradientType.values) t: typeLabel(s, t),
          },
          onSelected: notifier.setGradientType,
          child: Icon(typeIcon(settings.gradientType), size: 16, color: accent),
        ),
        const SizedBox(width: 6),
        _MenuPill<GradientEnd>(
          key: const ValueKey('gradient-end'),
          accent: accent,
          tooltip: _endLabel(s, settings.gradientEnd),
          selected: settings.gradientEnd,
          items: {
            for (final e in GradientEnd.values) e: _endLabel(s, e),
          },
          onSelected: (end) {
            notifier.setGradientEnd(end);
            if (end == GradientEnd.ramp && settings.gradientRamp.length < 2) {
              showGradientRampEditor(context, primaryColor: primaryColor);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorSwatchBox(color: primaryColor ?? Colors.black, size: 16),
              Icon(Icons.arrow_forward, size: 14, color: accent),
              ColorSwatchBox(
                color: settings.gradientEnd == GradientEnd.transparent ? Colors.transparent : settings.secondaryColor,
                size: 16,
              ),
            ],
          ),
        ),
        if (usesRamp || settings.gradientEnd == GradientEnd.ramp) ...[
          const SizedBox(width: 6),
          _Pill(
            key: const ValueKey('gradient-ramp'),
            accent: accent,
            tooltip: s.gradientRampEdit,
            onTap: () => showGradientRampEditor(context, primaryColor: primaryColor),
            child: settings.gradientRamp.isEmpty
                ? Icon(Icons.add, size: 16, color: accent)
                : GradientRampStrip(colors: settings.gradientRamp),
          ),
        ],
        if (!usesRamp) ...[
          const SizedBox(width: 6),
          _MenuPill<int>(
            key: const ValueKey('gradient-steps'),
            accent: accent,
            tooltip: s.gradientBands,
            selected: isSmooth ? 0 : settings.gradientSteps,
            items: {
              for (final n in stepChoices) n: n == 0 ? s.gradientSmooth : s.gradientStepsCount(n),
            },
            onSelected: notifier.setGradientSteps,
            child: _PillLabel(
              icon: Icons.view_week_outlined,
              text: isSmooth ? s.gradientSmooth : s.gradientStepsCount(settings.gradientSteps),
              accent: accent,
            ),
          ),
        ],
        if (!isSmooth) ...[
          const SizedBox(width: 6),
          _DitherPill(accent: accent, settings: settings, notifier: notifier),
        ],
        const SizedBox(width: 6),
        _Pill(
          key: const ValueKey('gradient-target'),
          accent: accent,
          selected: isArea,
          tooltip: isArea ? s.gradientTargetArea : s.gradientTargetLayer,
          onTap: () => notifier.setGradientTarget(
            isArea ? GradientTarget.layer : GradientTarget.contiguous,
          ),
          child: Icon(
            isArea ? Icons.format_color_fill : Icons.crop_free,
            size: 16,
            color: accent,
          ),
        ),
        const SizedBox(width: 6),
        _MenuPill<GradientBlend>(
          key: const ValueKey('gradient-blend'),
          accent: accent,
          tooltip: _blendLabel(s, settings.gradientBlend),
          selected: settings.gradientBlend,
          items: {
            for (final b in GradientBlend.values) b: _blendLabel(s, b),
          },
          onSelected: notifier.setGradientBlend,
          child: Icon(_blendIcon(settings.gradientBlend), size: 16, color: accent),
        ),
      ],
    );
  }

  static String typeLabel(Strings s, GradientType type) => switch (type) {
        GradientType.linear => s.gradientLinear,
        GradientType.radial => s.gradientRadial,
        GradientType.reflected => s.gradientReflected,
        GradientType.diamond => s.gradientDiamond,
        GradientType.angle => s.gradientAngle,
      };

  static IconData typeIcon(GradientType type) => switch (type) {
        GradientType.linear => Icons.gradient,
        GradientType.radial => Icons.blur_circular,
        GradientType.reflected => Icons.flip,
        GradientType.diamond => Icons.diamond_outlined,
        GradientType.angle => Icons.rotate_right,
      };

  static String _endLabel(Strings s, GradientEnd end) => switch (end) {
        GradientEnd.secondaryColor => s.gradientEndSecondary,
        GradientEnd.transparent => s.gradientEndTransparent,
        GradientEnd.ramp => s.gradientRamp,
      };

  static String _blendLabel(Strings s, GradientBlend blend) => switch (blend) {
        GradientBlend.over => s.gradientBlendOver,
        GradientBlend.replace => s.gradientBlendReplace,
        GradientBlend.lockAlpha => s.gradientBlendLockAlpha,
      };

  static IconData _blendIcon(GradientBlend blend) => switch (blend) {
        GradientBlend.over => Icons.layers_outlined,
        GradientBlend.replace => Icons.swap_horiz,
        GradientBlend.lockAlpha => Icons.lock_outline,
      };
}

/// A compact row of ramp colours.
class GradientRampStrip extends StatelessWidget {
  const GradientRampStrip({super.key, required this.colors, this.height = 16});

  final List<Color> colors;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in colors)
            SizedBox(
              width: colors.length > 8 ? 6 : 10,
              height: height,
              child: ColoredBox(color: c),
            ),
        ],
      ),
    );
  }
}

/// Edits the saved colour ramp: tap a colour to remove it; add the current
/// colour, the secondary colour or the imported palette; reverse; clear.
Future<void> showGradientRampEditor(BuildContext context, {Color? primaryColor}) {
  return showDialog<void>(
    context: context,
    builder: (context) => _GradientRampEditor(primaryColor: primaryColor),
  );
}

class _GradientRampEditor extends ConsumerWidget {
  const _GradientRampEditor({this.primaryColor});

  final Color? primaryColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    final settings = ref.watch(editorSettingsNotifierProvider);
    final notifier = ref.read(editorSettingsNotifierProvider.notifier);
    final imported = ref.watch(importedPaletteProvider);
    final ramp = settings.gradientRamp;
    final full = ramp.length >= kMaxGradientRampColors;

    void add(Color c) => notifier.setGradientRamp([...ramp, c]);

    return AlertDialog(
      title: Text(s.gradientRamp),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.gradientRampHint, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < ramp.length; i++)
                  InkWell(
                    key: ValueKey('gradient-ramp-color-$i'),
                    onTap: () => notifier.setGradientRamp([...ramp]..removeAt(i)),
                    child: ColorSwatchBox(color: ramp[i], size: 28),
                  ),
                if (ramp.isEmpty) Text(s.gradientRampEmpty, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (primaryColor != null)
                  TextButton.icon(
                    key: const ValueKey('gradient-ramp-add-primary'),
                    onPressed: full ? null : () => add(primaryColor!),
                    icon: ColorSwatchBox(color: primaryColor!, size: 14),
                    label: Text(s.gradientRampAddCurrent),
                  ),
                TextButton.icon(
                  key: const ValueKey('gradient-ramp-add-secondary'),
                  onPressed: full ? null : () => add(settings.secondaryColor),
                  icon: ColorSwatchBox(color: settings.secondaryColor, size: 14),
                  label: Text(s.gradientRampAddSecondary),
                ),
                if (imported.length >= 2)
                  TextButton.icon(
                    onPressed: () => notifier.setGradientRamp(
                      [...imported]..sort((a, b) => a.computeLuminance().compareTo(b.computeLuminance())),
                    ),
                    icon: const Icon(Icons.palette_outlined, size: 16),
                    label: Text(s.gradientRampFromPalette),
                  ),
                TextButton.icon(
                  key: const ValueKey('gradient-ramp-reverse'),
                  onPressed: ramp.length < 2 ? null : () => notifier.setGradientRamp(ramp.reversed.toList()),
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: Text(s.gradientRampReverse),
                ),
                TextButton.icon(
                  onPressed: ramp.isEmpty ? null : () => notifier.setGradientRamp(const []),
                  icon: const Icon(Icons.clear, size: 16),
                  label: Text(s.gradientRampClear),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}

/// Dither pattern menu with a "dither width" slider.
class _DitherPill extends StatelessWidget {
  const _DitherPill({
    required this.accent,
    required this.settings,
    required this.notifier,
  });

  final Color accent;
  final EditorSettings settings;
  final EditorSettingsNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    String label(GradientDither d) => switch (d) {
          GradientDither.none => s.gradientDitherNone,
          GradientDither.bayer2 => s.gradientDitherBayer('2×2'),
          GradientDither.bayer4 => s.gradientDitherBayer('4×4'),
          GradientDither.bayer8 => s.gradientDitherBayer('8×8'),
        };
    final dither = settings.gradientDither;

    return Tooltip(
      message: s.dithering,
      child: PopupMenuButton<GradientDither>(
        key: const ValueKey('gradient-dither'),
        tooltip: '',
        initialValue: dither,
        onSelected: notifier.setGradientDither,
        itemBuilder: (context) => [
          for (final d in GradientDither.values) PopupMenuItem(value: d, child: Text(label(d))),
          if (dither != GradientDither.none) ...[
            const PopupMenuDivider(),
            PopupMenuItem(
              enabled: false,
              child: _DitherSpreadSlider(
                label: s.gradientDitherWidth,
                initial: settings.gradientDitherSpread,
                onChanged: notifier.setGradientDitherSpread,
              ),
            ),
          ],
        ],
        child: _PillFrame(
          accent: accent,
          selected: dither != GradientDither.none,
          child: _PillLabel(
            icon: Icons.grid_4x4,
            text: dither == GradientDither.none ? s.gradientDitherNone : '${dither.size}×${dither.size}',
            accent: accent,
          ),
        ),
      ),
    );
  }
}

class _DitherSpreadSlider extends StatefulWidget {
  const _DitherSpreadSlider({
    required this.label,
    required this.initial,
    required this.onChanged,
  });

  final String label;
  final double initial;
  final ValueChanged<double> onChanged;

  @override
  State<_DitherSpreadSlider> createState() => _DitherSpreadSliderState();
}

class _DitherSpreadSliderState extends State<_DitherSpreadSlider> {
  late double _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${widget.label}: ${(_value * 100).round()}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SizedBox(
          width: 180,
          child: Slider(
            value: _value,
            min: 0.1,
            max: 1,
            divisions: 9,
            onChanged: (v) {
              setState(() => _value = v);
              widget.onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

class _MenuPill<T> extends StatelessWidget {
  const _MenuPill({
    super.key,
    required this.accent,
    required this.tooltip,
    required this.selected,
    required this.items,
    required this.onSelected,
    required this.child,
  });

  final Color accent;
  final String tooltip;
  final T selected;
  final Map<T, String> items;
  final ValueChanged<T> onSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: tooltip,
      initialValue: selected,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final e in items.entries)
          CheckedPopupMenuItem(
            value: e.key,
            checked: e.key == selected,
            child: Text(e.value),
          ),
      ],
      child: _PillFrame(accent: accent, child: child),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.accent,
    required this.tooltip,
    required this.onTap,
    required this.child,
    this.selected = false,
  });

  final Color accent;
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: _PillFrame(accent: accent, selected: selected, child: child),
        ),
      ),
    );
  }
}

/// Same pill look as the magic-wand options.
class _PillFrame extends StatelessWidget {
  const _PillFrame({
    required this.accent,
    required this.child,
    this.selected = false,
  });

  final Color accent;
  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: selected ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 1),
      ),
      child: Center(widthFactor: 1, child: child),
    );
  }
}

class _PillLabel extends StatelessWidget {
  const _PillLabel({
    required this.icon,
    required this.text,
    required this.accent,
  });

  final IconData icon;
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: accent),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// A colour square; transparent colours show a checkerboard.
class ColorSwatchBox extends StatelessWidget {
  const ColorSwatchBox({
    super.key,
    required this.color,
    this.size = 16,
    this.borderRadius = 3,
  });

  final Color color;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CustomPaint(
        size: Size.square(size),
        painter: _SwatchPainter(color),
      ),
    );
  }
}

class _SwatchPainter extends CustomPainter {
  _SwatchPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a < 1) {
      final cell = size.width / 4;
      final light = Paint()..color = const Color(0xFFFFFFFF);
      final dark = Paint()..color = const Color(0xFFCCCCCC);
      for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell, cell),
            (x + y).isEven ? light : dark,
          );
        }
      }
    }
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    canvas.drawRect(
      (Offset.zero & size).deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0x66000000),
    );
  }

  @override
  bool shouldRepaint(_SwatchPainter oldDelegate) => oldDelegate.color != color;
}
