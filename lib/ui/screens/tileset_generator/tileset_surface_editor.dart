part of 'tileset_generator_screen.dart';

typedef _Swatch = ({Uint32List pixels, int width, int height});

const _layerTabs = ['Pattern', 'Noise', 'Color', 'Rules'];
const _slotRoles = ['Middle', 'Dark', 'Light', 'Highlight'];
const _mySurfacesKey = 'tileset.mySurfaces';

/// Surfaces applied in this app session, newest first.
final _recentSurfaces = <TilesetSurfacePreset>[];

extension _SurfaceEditor on TilesetGeneratorScreenState {
  TilesetSurfaceSpec? get _customSpec => _recipe.surface.spec;

  bool get _hasEightColors => _palette.length >= 8;

  _Swatch? _swatchOf(TilesetSurfaceSpec spec, {int size = 16}) {
    if (!_hasEightColors) return null;
    return (pixels: spec.renderSample(_palette, size: size), width: size, height: size);
  }

  /// Applies an edit to the layer stack. Edits sharing a [coalesce] key within a
  /// short window (a slider drag) become one undo step.
  void _setSpec(TilesetSurfaceSpec spec, {String? coalesce}) {
    final old = _customSpec;
    final now = DateTime.now();
    final merge = coalesce != null &&
        coalesce == _editKey &&
        _editAt != null &&
        now.difference(_editAt!) < const Duration(milliseconds: 700);
    _updateDraft(() {
      if (old != null && !merge) {
        _specUndo.add(old);
        if (_specUndo.length > 60) _specUndo.removeAt(0);
      }
      _specRedo.clear();
      _editKey = coalesce;
      _editAt = now;
      _applySpec(spec);
    });
  }

  void _applySpec(TilesetSurfaceSpec spec) {
    _layer = _layer.clamp(0, spec.layers.length - 1);
    _recipe = _recipe.copyWith(surface: TilesetMaterial.custom(spec));
    _type = _recipe.rendererFor(_perspective);
    if (_specName.text != spec.name) _specName.text = spec.name;
  }

  void _undoSpec() {
    final spec = _customSpec;
    if (spec == null || _specUndo.isEmpty) return;
    _updateDraft(() {
      _specRedo.add(spec);
      _editKey = null;
      _applySpec(_specUndo.removeLast());
    });
  }

  void _redoSpec() {
    final spec = _customSpec;
    if (spec == null || _specRedo.isEmpty) return;
    _updateDraft(() {
      _specUndo.add(spec);
      _editKey = null;
      _applySpec(_specRedo.removeLast());
    });
  }

  void _editLayer(TilesetLayer Function(TilesetLayer layer) change, {String? coalesce}) {
    final spec = _customSpec;
    if (spec == null) return;
    final layers = List.of(spec.layers);
    layers[_layer] = change(layers[_layer]);
    _setSpec(spec.copyWith(layers: layers), coalesce: coalesce == null ? null : '$coalesce$_layer');
  }

  void _usePreset(TilesetSurfacePreset preset, {bool add = false}) {
    final spec = _customSpec;
    if (add && spec != null) {
      final room = tilesetMaxLayers - spec.layers.length;
      if (room <= 0) return;
      _setSpec(spec.copyWith(layers: [...spec.layers, ...preset.spec.layers.take(room)]));
      _updateDraft(() => _layer = _customSpec!.layers.length - 1);
    } else {
      _updateDraft(() => _palette = List.of(preset.palette));
      _setSpec(preset.spec);
      _updateDraft(() => _layer = 0);
    }
    _recentSurfaces
      ..removeWhere((p) => p.id == preset.id)
      ..insert(0, preset);
    if (_recentSurfaces.length > 12) _recentSurfaces.removeLast();
  }

  void _addLayer() {
    final spec = _customSpec;
    if (spec == null || spec.layers.length >= tilesetMaxLayers) return;
    const layer = TilesetLayer(
        pattern: TilesetPattern.dots,
        colors: TilesetLayerColors(mid: 4, dark: 6, light: 4, highlight: 7),
        noise: TilesetNoise(),
        density: 0.6);
    _setSpec(spec.copyWith(layers: [...spec.layers, layer]));
    _updateDraft(() => _layer = _customSpec!.layers.length - 1);
  }

  void _removeLayer(int index) {
    final spec = _customSpec;
    if (spec == null || spec.layers.length <= 1) return;
    _setSpec(spec.copyWith(layers: List.of(spec.layers)..removeAt(index)));
  }

  void _duplicateLayer(int index) {
    final spec = _customSpec;
    if (spec == null || spec.layers.length >= tilesetMaxLayers) return;
    final layers = List.of(spec.layers)..insert(index + 1, spec.layers[index]);
    _setSpec(spec.copyWith(layers: layers));
    _updateDraft(() => _layer = index + 1);
  }

  void _reorderLayer(int from, int to) {
    final spec = _customSpec;
    if (spec == null) return;
    final layers = List.of(spec.layers);
    final moved = layers.removeAt(from);
    layers.insert(to > from ? to - 1 : to, moved);
    _setSpec(spec.copyWith(layers: layers));
    _updateDraft(() => _layer = to > from ? to - 1 : to);
  }

  Future<List<({List<int> palette, TilesetSurfaceSpec spec})>> _loadMine() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return [
        for (final raw in prefs.getStringList(_mySurfacesKey) ?? const <String>[])
          if (_parseMine(raw) case final entry?) entry
      ];
    } catch (_) {
      return [];
    }
  }

  ({List<int> palette, TilesetSurfaceSpec spec})? _parseMine(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final palette = (json['palette'] as List).cast<int>();
      if (palette.length != 8) return null;
      return (palette: palette, spec: TilesetSurfaceSpec.fromJson((json['spec'] as Map).cast<String, dynamic>()));
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveMine() async {
    final spec = _customSpec;
    if (spec == null || !_hasEightColors) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = [...?prefs.getStringList(_mySurfacesKey)];
      entries.insert(0, jsonEncode({'palette': _palette.sublist(0, 8), 'spec': spec.toJson()}));
      await prefs.setStringList(_mySurfacesKey, entries.take(60).toList());
      messenger?.showSnackBar(SnackBar(content: Text('Saved “${spec.name}” to My surfaces')));
    } catch (_) {
      messenger?.showSnackBar(const SnackBar(content: Text('Could not save this surface')));
    }
  }

  Future<void> _openGallery() async {
    if (_busy) return;
    final mine = await _loadMine();
    if (!mounted) return;
    final choice = await showDialog<({TilesetSurfacePreset preset, bool add})>(
        context: context, builder: (context) => _SurfaceGallery(tg: _tg, mine: mine, canAdd: _customSpec != null));
    if (choice != null && mounted) _usePreset(choice.preset, add: choice.add);
  }

  // ---------------------------------------------------------------- panel

  List<Widget> _surfaceEditor() {
    final spec = _customSpec;
    final bases = TilesetRecipe.basesFor(_perspective);
    return [
      if (spec == null) ..._classicBanner() else ..._layeredEditor(spec),
      if (bases.length > 1) ...[
        const SizedBox(height: 10),
        Text('Use as', style: TextStyle(fontSize: 11, color: _tg.muted)),
        const SizedBox(height: 4),
        Wrap(spacing: 6, children: [
          for (final base in bases)
            ChoiceChip(
                key: ValueKey('surface-base-${base.name}'),
                label: Text(base.label),
                selected: _recipe.base == base,
                showCheckmark: false,
                selectedColor: _tg.tint,
                side: BorderSide(color: _recipe.base == base ? _tg.accent : _tg.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_tg.chipRadius)),
                onSelected: _busy ? null : (_) => _changeRecipe(_fitRecipe(_recipe.copyWith(base: base)))),
        ]),
      ],
    ];
  }

  List<Widget> _classicBanner() => [
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: _tg.tint,
                borderRadius: BorderRadius.circular(_tg.cardRadius),
                border: Border.all(color: _tg.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${_recipe.surface.label} is a classic surface.',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Start from a preset to edit its layers, patterns, noise and colors.',
                  style: TextStyle(fontSize: 11, color: _tg.muted)),
              const SizedBox(height: 8),
              FilledButton.icon(
                  key: const ValueKey('surface-open-presets'),
                  onPressed: _busy ? null : _openGallery,
                  icon: const Icon(Icons.auto_awesome_mosaic, size: 16),
                  label: const Text('Start from a preset')),
            ])),
      ];

  List<Widget> _layeredEditor(TilesetSurfaceSpec spec) {
    final layer = spec.layers[_layer];
    return [
      Row(children: [
        Expanded(
            child: SizedBox(
                height: 36,
                child: TextField(
                    key: const ValueKey('surface-name'),
                    controller: _specName,
                    enabled: !_busy,
                    maxLength: 60,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                        counterText: '',
                        labelText: 'Surface name',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                    onChanged: (v) {
                      final current = _customSpec;
                      if (current != null && v.trim().isNotEmpty) _setSpec(current.copyWith(name: v), coalesce: 'name');
                    }))),
        const SizedBox(width: 4),
        _TgIconButton(label: 'Undo surface edit', icon: Icons.undo, onPressed: _specUndo.isEmpty ? null : _undoSpec),
        _TgIconButton(label: 'Redo surface edit', icon: Icons.redo, onPressed: _specRedo.isEmpty ? null : _redoSpec),
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 6, children: [
        OutlinedButton.icon(
            key: const ValueKey('surface-open-presets'),
            onPressed: _busy ? null : _openGallery,
            icon: const Icon(Icons.auto_awesome_mosaic, size: 16),
            label: const Text('Preset')),
        OutlinedButton.icon(
            key: const ValueKey('surface-save-mine'),
            onPressed: _busy ? null : _saveMine,
            icon: const Icon(Icons.bookmark_add_outlined, size: 16),
            label: const Text('Save as my surface')),
      ]),
      const SizedBox(height: 10),
      _liveCard(spec),
      const SizedBox(height: 12),
      Row(children: [
        const _TgLabel('LAYERS'),
        const Spacer(),
        Text('${spec.layers.length} / $tilesetMaxLayers', style: _tg.mono),
      ]),
      const SizedBox(height: 6),
      _layerStack(spec),
      const SizedBox(height: 4),
      Tooltip(
          message: spec.layers.length >= tilesetMaxLayers ? 'Maximum of $tilesetMaxLayers layers reached' : '',
          child: OutlinedButton.icon(
              key: const ValueKey('layer-add'),
              onPressed: _busy || spec.layers.length >= tilesetMaxLayers ? null : _addLayer,
              icon: const Icon(Icons.add, size: 16),
              label: Text(spec.layers.length >= tilesetMaxLayers ? 'Layer limit reached' : 'Add layer'))),
      const SizedBox(height: 12),
      Container(
          padding: const EdgeInsets.all(10),
          decoration:
              BoxDecoration(borderRadius: BorderRadius.circular(_tg.cardRadius), border: Border.all(color: _tg.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('LAYER ${_layer + 1} · ${layer.pattern.label.toUpperCase()}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: _tg.muted)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (var i = 0; i < _layerTabs.length; i++)
                ChoiceChip(
                    key: ValueKey('layer-tab-${_layerTabs[i].toLowerCase()}'),
                    label: Text(_layerTabs[i]),
                    selected: _layerTab == i,
                    showCheckmark: false,
                    selectedColor: _tg.tint,
                    side: BorderSide(color: _layerTab == i ? _tg.accent : _tg.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_tg.chipRadius)),
                    onSelected: (_) => _updateDraft(() => _layerTab = i)),
            ]),
            const SizedBox(height: 10),
            ...switch (_layerTab) {
              0 => _patternTab(layer),
              1 => _noiseTab(layer),
              2 => _colorTab(layer),
              _ => _rulesTab(layer),
            },
          ])),
    ];
  }

  Widget _liveCard(TilesetSurfaceSpec spec) {
    if (!_hasEightColors) return const SizedBox.shrink();
    final key = Object.hash(spec, Object.hashAll(_palette), _size);
    if (_liveKey != key) {
      const size = 16;
      _liveKey = key;
      _liveTile = spec.renderSample(_palette, size: size);
      _liveSeamless = spec.isSeamless(_palette, size: size);
    }
    final tile = _liveTile!;
    final repeated = Uint32List(48 * 48);
    for (var y = 0; y < 48; y++) {
      for (var x = 0; x < 48; x++) {
        repeated[y * 48 + x] = tile[(y % 16) * 16 + x % 16];
      }
    }
    final ok = _liveSeamless;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _TgLabel('TILE'),
        const SizedBox(height: 4),
        _liveArt(tile, 16, 96),
      ]),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _TgLabel('3×3 REPEAT'),
        const SizedBox(height: 4),
        _liveArt(repeated, 48, 96),
      ]),
      const SizedBox(width: 12),
      Expanded(
          child: Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Container(
                  key: const ValueKey('seam-pill'),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                      color: (ok ? _tg.green : _tg.amber).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(_tg.chipRadius),
                      border: Border.all(color: ok ? _tg.green : _tg.amber)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(ok ? Icons.check_circle_outline : Icons.warning_amber,
                        size: 14, color: ok ? _tg.green : _tg.amber),
                    const SizedBox(width: 4),
                    Flexible(
                        child: Text(ok ? 'Seamless' : 'Edges differ',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _tg.text))),
                  ])))),
    ]);
  }

  Widget _liveArt(Uint32List pixels, int side, double extent) => ClipRRect(
      borderRadius: BorderRadius.circular(_tg.buttonRadius),
      child: CustomPaint(
          size: Size.square(extent),
          painter: _SurfacePreviewPainter((pixels: pixels, width: side, height: side), _tg.checkerA)));

  Widget _layerStack(TilesetSurfaceSpec spec) {
    final count = spec.layers.length;
    return ReorderableListView.builder(
        shrinkWrap: true,
        buildDefaultDragHandles: false,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        // The list shows the top layer first.
        onReorder: (from, to) => _reorderLayer(count - 1 - from, count - to),
        itemBuilder: (context, row) {
          final index = count - 1 - row;
          final layer = spec.layers[index];
          final selected = index == _layer;
          final swatch = _swatchOf(TilesetSurfaceSpec(layers: [layer.copyWith(visible: true)]));
          return Container(
              key: ValueKey('layer-row-$index'),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                  color: selected ? _tg.tint : null,
                  borderRadius: BorderRadius.circular(_tg.buttonRadius),
                  border: Border.all(color: selected ? _tg.accent : _tg.border, width: selected ? 2 : 1)),
              child: InkWell(
                  borderRadius: BorderRadius.circular(_tg.buttonRadius),
                  onTap: () => _updateDraft(() => _layer = index),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(children: [
                        ReorderableDragStartListener(
                            index: row,
                            child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                child: Icon(Icons.drag_indicator, size: 18, color: _tg.muted))),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CustomPaint(
                                size: const Size.square(40), painter: _SurfacePreviewPainter(swatch, _tg.checkerA))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(layer.pattern.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: layer.visible ? _tg.text : _tg.muted)),
                          Text(index == 0 ? 'Base fill' : layer.blend.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 10, color: _tg.muted)),
                        ])),
                        _TgIconButton(
                            label: index == 0
                                ? 'The base layer is always visible'
                                : layer.visible
                                    ? 'Hide layer ${index + 1}'
                                    : 'Show layer ${index + 1}',
                            icon: layer.visible || index == 0 ? Icons.visibility : Icons.visibility_off,
                            onPressed: index == 0
                                ? null
                                : () {
                                    final layers = List.of(spec.layers);
                                    layers[index] = layer.copyWith(visible: !layer.visible);
                                    _setSpec(spec.copyWith(layers: layers));
                                  }),
                        _TgIconButton(
                            label: 'Duplicate layer ${index + 1}',
                            icon: Icons.copy,
                            onPressed: count >= tilesetMaxLayers ? null : () => _duplicateLayer(index)),
                        _TgIconButton(
                            label: 'Delete layer ${index + 1}',
                            icon: Icons.delete_outline,
                            onPressed: count <= 1 ? null : () => _removeLayer(index)),
                      ]))));
        });
  }

  // ---------------------------------------------------------- inspector tabs

  Widget _slider(String label, String value, double current, double min, double max, ValueChanged<double> onChanged,
          {int? divisions, String? key}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const Spacer(),
          Text(value, style: _tg.mono),
        ]),
        SizedBox(
            height: 28,
            child: Slider(
                key: key == null ? null : ValueKey(key),
                value: current.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                padding: EdgeInsets.zero,
                onChanged: _busy ? null : onChanged)),
      ]);

  List<Widget> _patternTab(TilesetLayer layer) => [
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final pattern in TilesetPattern.values)
            Tooltip(
                message: '${pattern.label} · ${pattern.description}',
                child: Semantics(
                    button: true,
                    selected: layer.pattern == pattern,
                    label: pattern.label,
                    child: InkWell(
                        key: ValueKey('pattern-${pattern.name}'),
                        borderRadius: BorderRadius.circular(_tg.buttonRadius),
                        onTap: _busy ? null : () => _editLayer((l) => l.copyWith(pattern: pattern)),
                        child: Container(
                            width: 64,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                                color: layer.pattern == pattern ? _tg.tint : null,
                                borderRadius: BorderRadius.circular(_tg.buttonRadius),
                                border: Border.all(
                                    color: layer.pattern == pattern ? _tg.accent : _tg.border,
                                    width: layer.pattern == pattern ? 2 : 1)),
                            child: Column(children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: CustomPaint(
                                      size: const Size.square(52),
                                      painter: _SurfacePreviewPainter(
                                          _swatchOf(TilesetSurfaceSpec(layers: [
                                            layer.copyWith(
                                                pattern: pattern,
                                                visible: true,
                                                noise: null,
                                                area: TilesetLayerArea.all,
                                                density: 1,
                                                invert: false)
                                          ])),
                                          _tg.checkerA))),
                              const SizedBox(height: 2),
                              Text(pattern.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
                            ]))))),
        ]),
        const SizedBox(height: 6),
        Text(layer.pattern.description, style: TextStyle(fontSize: 11, color: _tg.muted)),
        if (_layer == 0)
          Text('The base layer fills the whole tile; upper layers draw detail on top.',
              style: TextStyle(fontSize: 11, color: _tg.muted)),
      ];

  List<Widget> _noiseTab(TilesetLayer layer) {
    final noise = layer.noise;
    return [
      SwitchListTile.adaptive(
          key: const ValueKey('noise-enabled'),
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Roughen this layer', style: TextStyle(fontSize: 12)),
          subtitle: const Text('Adds speckles, blotches or streaks.', style: TextStyle(fontSize: 10)),
          value: noise != null,
          onChanged: _busy ? null : (on) => _editLayer((l) => l.copyWith(noise: on ? const TilesetNoise() : null))),
      if (noise != null) ...[
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final type in TilesetNoiseType.values)
            ChoiceChip(
                key: ValueKey('noise-${type.name}'),
                label: Text(type.label),
                selected: noise.type == type,
                showCheckmark: false,
                selectedColor: _tg.tint,
                side: BorderSide(color: noise.type == type ? _tg.accent : _tg.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_tg.chipRadius)),
                onSelected: _busy ? null : (_) => _editLayer((l) => l.copyWith(noise: noise.copyWith(type: type)))),
        ]),
        const SizedBox(height: 6),
        _slider('Scale', '${noise.scale}', noise.scale.toDouble(), 1, 16,
            (v) => _editLayer((l) => l.copyWith(noise: noise.copyWith(scale: v.round())), coalesce: 'scale'),
            divisions: 15, key: 'noise-scale'),
        _slider('Strength', '${(noise.strength * 100).round()}%', noise.strength, 0, 1,
            (v) => _editLayer((l) => l.copyWith(noise: noise.copyWith(strength: v)), coalesce: 'strength'),
            key: 'noise-strength'),
        _slider('Threshold', '${(noise.threshold * 100).round()}%', noise.threshold, 0, 1,
            (v) => _editLayer((l) => l.copyWith(noise: noise.copyWith(threshold: v)), coalesce: 'threshold'),
            key: 'noise-threshold'),
        Row(children: [
          Text('Seed ${noise.seed}', style: _tg.mono),
          const SizedBox(width: 6),
          _TgIconButton(
              label: 'Shuffle noise seed',
              icon: Icons.casino_outlined,
              onPressed: _busy
                  ? null
                  : () => _editLayer((l) => l.copyWith(noise: noise.copyWith(seed: math.Random().nextInt(9999) + 1)))),
        ]),
      ],
    ];
  }

  List<Widget> _colorTab(TilesetLayer layer) {
    final values = [layer.colors.mid, layer.colors.dark, layer.colors.light, layer.colors.highlight];
    TilesetLayerColors withSlot(int role, int slot) => layer.colors.copyWith(
        mid: role == 0 ? slot : null,
        dark: role == 1 ? slot : null,
        light: role == 2 ? slot : null,
        highlight: role == 3 ? slot : null);
    return [
      for (var role = 0; role < 4; role++) ...[
        Text(_slotRoles[role], style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Row(children: [
          for (var slot = 0; slot < 8; slot++) ...[
            if (slot > 0) const SizedBox(width: 3),
            Expanded(
                child: Tooltip(
                    message: 'Palette slot $slot',
                    child: InkWell(
                        key: ValueKey('color-$role-$slot'),
                        onTap: _busy || !_hasEightColors
                            ? null
                            : () => _editLayer((l) => l.copyWith(colors: withSlot(role, slot))),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                            height: 28,
                            decoration: BoxDecoration(
                                color: _hasEightColors ? Color(_palette[slot]) : _tg.elevated,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: values[role] == slot ? _tg.text : _tg.border,
                                    width: values[role] == slot ? 2 : 1)),
                            child: values[role] == slot
                                ? Icon(Icons.check, size: 14, color: _onColor(_palette[slot]))
                                : null)))),
          ]
        ]),
        const SizedBox(height: 8),
      ],
      Text('Slots come from the shared palette below; editing a color updates every layer that uses it.',
          style: TextStyle(fontSize: 11, color: _tg.muted)),
    ];
  }

  Color _onColor(int argb) => Color(argb).computeLuminance() > 0.5 ? Colors.black : Colors.white;

  List<Widget> _rulesTab(TilesetLayer layer) {
    final base = _layer == 0;
    return [
      const Text('Where', style: TextStyle(fontSize: 12)),
      const SizedBox(height: 4),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final area in TilesetLayerArea.values)
          ChoiceChip(
              key: ValueKey('area-${area.name}'),
              label: Text(area.label),
              selected: layer.area == area,
              showCheckmark: false,
              selectedColor: _tg.tint,
              side: BorderSide(color: layer.area == area ? _tg.accent : _tg.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_tg.chipRadius)),
              onSelected: _busy ? null : (_) => _editLayer((l) => l.copyWith(area: area))),
      ]),
      Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 6),
          child: Text(
              switch (layer.area) {
                TilesetLayerArea.all => 'Draws across the whole tile.',
                TilesetLayerArea.interior => 'Keeps clear of the tile border so neighbours match.',
                TilesetLayerArea.border => 'Draws only along the tile edge.',
                TilesetLayerArea.top => 'Draws on edges with nothing above them.',
                TilesetLayerArea.sides => 'Draws on edges with nothing beside them.',
              },
              style: TextStyle(fontSize: 11, color: _tg.muted))),
      _slider('Density', '${(layer.density * 100).round()}%', layer.density, 0, 1,
          (v) => _editLayer((l) => l.copyWith(density: v), coalesce: 'density'),
          key: 'layer-density'),
      SwitchListTile.adaptive(
          key: const ValueKey('layer-invert'),
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: const Text('Invert pattern', style: TextStyle(fontSize: 12)),
          value: layer.invert,
          onChanged: _busy ? null : (on) => _editLayer((l) => l.copyWith(invert: on))),
      const Text('Blend', style: TextStyle(fontSize: 12)),
      const SizedBox(height: 4),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final blend in TilesetLayerBlend.values)
          Tooltip(
              message: base ? 'The base layer always replaces' : blend.description,
              child: ChoiceChip(
                  key: ValueKey('blend-${blend.name}'),
                  label: Text(blend.label),
                  selected: layer.blend == blend,
                  showCheckmark: false,
                  selectedColor: _tg.tint,
                  side: BorderSide(color: layer.blend == blend ? _tg.accent : _tg.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_tg.chipRadius)),
                  onSelected: _busy || base ? null : (_) => _editLayer((l) => l.copyWith(blend: blend)))),
      ]),
      if (base)
        Padding(
            padding: const EdgeInsets.only(top: 4),
            child:
                Text('Blend modes apply to layers above the base.', style: TextStyle(fontSize: 11, color: _tg.muted))),
    ];
  }
}

/// Preset browser: Presets / Mine / Recent with search and tag filters.
class _SurfaceGallery extends StatefulWidget {
  const _SurfaceGallery({required this.tg, required this.mine, required this.canAdd});
  final _Tg tg;
  final List<({List<int> palette, TilesetSurfaceSpec spec})> mine;
  final bool canAdd;
  @override
  State<_SurfaceGallery> createState() => _SurfaceGalleryState();
}

class _SurfaceGalleryState extends State<_SurfaceGallery> {
  var _tab = 0;
  var _query = '';
  String? _tag;

  _Tg get tg => widget.tg;

  List<TilesetSurfacePreset> get _items {
    final source = switch (_tab) {
      0 => TilesetSurfacePresets.all,
      1 => [
          for (var i = 0; i < widget.mine.length; i++)
            TilesetSurfacePreset(id: 'mine-$i', tag: 'Mine', palette: widget.mine[i].palette, spec: widget.mine[i].spec)
        ],
      _ => _recentSurfaces,
    };
    final q = _query.trim().toLowerCase();
    return [
      for (final p in source)
        if ((_tag == null || p.tag == _tag || _tab != 0) && (q.isEmpty || p.name.toLowerCase().contains(q))) p
    ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return AlertDialog(
        title: const Text('Surface presets'),
        content: SizedBox(
            width: 440,
            height: 460,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Presets')),
                    ButtonSegment(value: 1, label: Text('Mine')),
                    ButtonSegment(value: 2, label: Text('Recent')),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (v) => setState(() => _tab = v.first)),
              const SizedBox(height: 8),
              TextField(
                  key: const ValueKey('gallery-search'),
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                      isDense: true, prefixIcon: Icon(Icons.search, size: 18), hintText: 'Search surfaces'),
                  onChanged: (v) => setState(() => _query = v)),
              if (_tab == 0) ...[
                const SizedBox(height: 8),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  for (final tag in TilesetSurfacePresets.tags)
                    FilterChip(
                        key: ValueKey('gallery-tag-$tag'),
                        label: Text(tag, style: const TextStyle(fontSize: 11)),
                        selected: _tag == tag,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        selectedColor: tg.tint,
                        side: BorderSide(color: _tag == tag ? tg.accent : tg.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tg.chipRadius)),
                        onSelected: (on) => setState(() => _tag = on ? tag : null)),
                ]),
              ],
              const SizedBox(height: 8),
              Expanded(
                  child: items.isEmpty
                      ? Center(
                          child: Text(
                              _tab == 1
                                  ? 'Saved surfaces appear here.'
                                  : _tab == 2
                                      ? 'Surfaces you use appear here.'
                                      : 'No presets match.',
                              style: TextStyle(color: tg.muted)))
                      : SingleChildScrollView(
                          child: Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final preset in items) _card(preset),
                        ]))),
            ])),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]);
  }

  Widget _card(TilesetSurfacePreset preset) {
    final swatch = (pixels: preset.spec.renderSample(preset.palette), width: 16, height: 16);
    final count = preset.spec.layers.length;
    return Container(
        key: ValueKey('preset-${preset.id}'),
        width: 128,
        padding: const EdgeInsets.all(6),
        decoration:
            BoxDecoration(borderRadius: BorderRadius.circular(tg.buttonRadius), border: Border.all(color: tg.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
              onTap: () => Navigator.pop(context, (preset: preset, add: false)),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: CustomPaint(size: const Size(114, 64), painter: _SurfacePreviewPainter(swatch, tg.checkerA)))),
          const SizedBox(height: 4),
          Text(preset.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Row(children: [
            Text('$count ${count == 1 ? 'layer' : 'layers'}', style: TextStyle(fontSize: 10, color: tg.muted)),
            const Spacer(),
            if (widget.canAdd)
              Tooltip(
                  message: 'Add as layers',
                  child: InkWell(
                      key: ValueKey('preset-add-${preset.id}'),
                      onTap: () => Navigator.pop(context, (preset: preset, add: true)),
                      child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(Icons.layers_outlined, size: 16, color: tg.muted)))),
          ]),
        ]));
  }
}
