part of 'tileset_generator_screen.dart';

extension _RecipeControls on TilesetGeneratorScreenState {
  void _changeRecipe(TilesetRecipe recipe) => _updateDraft(() {
        // Follow the surface's palette unless the user has edited this one.
        if (recipe.surface != _recipe.surface && listEquals(_palette, materialPalettes[_material])) {
          _material = recipe.surface.palettePreset;
          _palette = List.of(materialPalettes[_material]!);
        }
        _recipe = recipe;
        _type = recipe.rendererFor(_perspective);
      });

  /// Drops modifiers the new base or perspective cannot use.
  TilesetRecipe _fitRecipe(TilesetRecipe recipe) {
    final base = recipe.base, p = _perspective;
    return recipe.copyWith(
        platform: recipe.platform && TilesetModifiers.platform.applies(base, p),
        vegetation: recipe.vegetation && TilesetModifiers.vegetation.applies(base, p),
        extraModifiers: {
          for (final e in recipe.extraModifiers.entries)
            if (TilesetModifiers.byId(e.key).applies(base, p)) e.key: e.value
        });
  }

  List<Widget> _recipeControls() => [
        const _TgLabel('2 · SURFACE'),
        const SizedBox(height: 8),
        ..._surfaceEditor(),
        const SizedBox(height: 16),
        const _TgLabel('3 · MODIFIERS'),
        for (final modifier in TilesetModifiers.all) ..._modifierControls(modifier),
        const SizedBox(height: 12),
        const _TgLabel('4 · CONNECTION PARTS'),
        const SizedBox(height: 8),
        OutlinedButton.icon(
            onPressed: _busy ? null : _chooseParts,
            icon: const Icon(Icons.grid_view, size: 16),
            label: Text('Select parts · ${_parts.length} / 47')),
        const SizedBox(height: 5),
        Text('${_parts.length} parts × $_variations variations = ${_parts.length * _variations} tiles',
            style: _tg.mono),
      ];

  List<Widget> _modifierControls(TilesetModifier modifier) {
    final available = modifier.applies(_recipe.base, _perspective);
    final intensity = _recipe.modifierIntensity(modifier.id);
    return [
      SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(modifier.label, style: const TextStyle(fontSize: 12)),
          subtitle: Text(available ? modifier.description : modifier.unavailable, style: const TextStyle(fontSize: 10)),
          value: intensity != null,
          onChanged: _busy || !available
              ? null
              : (on) => _changeRecipe(_recipe.withModifier(modifier.id,
                  on ? (modifier.id == 'vegetation' ? _recipe.vegetationDensity : modifier.defaultIntensity) : null))),
      if (intensity != null && modifier.hasIntensity) ...[
        Text('${modifier.label} ${modifier.intensityLabel} · $intensity%', style: _tg.mono),
        Slider(
            value: intensity.toDouble(),
            min: 0,
            max: 100,
            onChanged: _busy ? null : (v) => _changeRecipe(_recipe.withModifier(modifier.id, v.round()))),
      ],
    ];
  }

  Future<void> _chooseParts() async {
    final draft = Set<int>.of(_parts);
    final result = await showDialog<Set<int>>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                  title: const Text('Choose connection parts'),
                  content: SizedBox(
                      width: 760,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Wrap(spacing: 6, children: [
                          for (final preset in <String, List<int>>{
                            'Full set': platformMasks,
                            'Surface': [255, 110, 155, 55, 205, 38, 76, 19, 137],
                            'Platform parts': [255, 110, 155, 55, 205, 38, 76, 19, 137, 0, 10],
                            'Clear': [],
                          }.entries)
                            TextButton(
                                onPressed: () => update(() {
                                      draft
                                        ..clear()
                                        ..addAll(preset.value);
                                    }),
                                child: Text(preset.key)),
                        ]),
                        const Text('Directions use logical grid axes, before isometric projection.',
                            style: TextStyle(fontSize: 11)),
                        const SizedBox(height: 8),
                        Flexible(
                            child: SingleChildScrollView(
                                child: Wrap(spacing: 8, runSpacing: 4, children: [
                          for (final mask in platformMasks)
                            SizedBox(
                                width: 220,
                                child: CheckboxListTile(
                                    key: ValueKey('part-$mask'),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    title: Text(tilesetPartLabel(mask), style: const TextStyle(fontSize: 11)),
                                    secondary: CustomPaint(
                                        size: const Size.square(24),
                                        painter: _PartDiagram(mask, _tg.accent, _tg.border)),
                                    value: draft.contains(mask),
                                    onChanged: (value) => update(() {
                                          if (value!) {
                                            draft.add(mask);
                                          } else {
                                            draft.remove(mask);
                                          }
                                        }))),
                        ]))),
                      ])),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    FilledButton(
                        onPressed: draft.isEmpty ? null : () => Navigator.pop(context, draft),
                        child: Text('Use ${draft.length} parts'))
                  ],
                )));
    if (result != null && mounted) _updateDraft(() => _parts = result);
  }
}

class _PartDiagram extends CustomPainter {
  const _PartDiagram(this.mask, this.fill, this.edge);
  final int mask;
  final Color fill, edge;
  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 3, paint = Paint();
    for (final cell in [
      (1, 1, true),
      (1, 0, mask & 1 != 0),
      (2, 1, mask & 2 != 0),
      (1, 2, mask & 4 != 0),
      (0, 1, mask & 8 != 0),
      (2, 0, mask & 16 != 0),
      (2, 2, mask & 32 != 0),
      (0, 2, mask & 64 != 0),
      (0, 0, mask & 128 != 0)
    ]) {
      paint.color = cell.$3 ? fill : edge.withValues(alpha: 0.3);
      canvas.drawRect(Rect.fromLTWH(cell.$1 * unit, cell.$2 * unit, unit - 1, unit - 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PartDiagram oldDelegate) =>
      oldDelegate.mask != mask || oldDelegate.fill != fill || oldDelegate.edge != edge;
}

class _SurfacePreviewPainter extends CustomPainter {
  const _SurfacePreviewPainter(this.preview, this.background);
  final _Swatch? preview;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final p = preview;
    if (p == null) return;
    final scale = math.min(size.width / p.width, size.height / p.height);
    final dx = (size.width - p.width * scale) / 2, dy = (size.height - p.height * scale) / 2;
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < p.height; y++) {
      for (var x = 0; x < p.width; x++) {
        final argb = p.pixels[y * p.width + x];
        if (argb >> 24 == 0) continue;
        paint.color = Color(argb);
        canvas.drawRect(Rect.fromLTWH(dx + x * scale, dy + y * scale, scale + 0.5, scale + 0.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SurfacePreviewPainter old) => old.preview != preview || old.background != background;
}
