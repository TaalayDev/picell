part of 'tileset_generator_screen.dart';

typedef _Swatch = ({Uint32List pixels, int width, int height});

const _layerTabs = ['Pattern', 'Noise', 'Color', 'Rules'];
const _slotRoles = ['Middle', 'Dark', 'Light', 'Highlight'];
const _mySurfacesKey = 'tileset.mySurfaces';
const _blendShort = {
  TilesetLayerBlend.replace: 'Replace',
  TilesetLayerBlend.dark: 'On dark',
  TilesetLayerBlend.light: 'On light',
  TilesetLayerBlend.tint: 'Tint',
};
const _blendIcons = {
  TilesetLayerBlend.replace: Icons.swap_horiz,
  TilesetLayerBlend.dark: Icons.dark_mode_outlined,
  TilesetLayerBlend.light: Icons.light_mode_outlined,
  TilesetLayerBlend.tint: Icons.palette_outlined,
};

/// Surfaces applied in this app session, newest first.
final _recentSurfaces = <TilesetSurfacePreset>[];

extension _SurfaceEditor on TilesetGeneratorScreenState {
  TilesetSurfaceSpec? get _customSpec => _recipe.surface.spec;

  bool get _hasEightColors => _palette.length >= 8;

  _Swatch? _swatchOf(TilesetSurfaceSpec spec, {int size = 16}) {
    if (!_hasEightColors) return null;
    return (pixels: spec.renderSample(_palette, size: size), width: size, height: size);
  }

  // ------------------------------------------------------------------ edits

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
    if (_solo != null && _solo! >= spec.layers.length) _solo = null;
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
      _updateDraft(() {
        _layer = 0;
        _solo = null;
      });
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
    _updateDraft(() {
      _layer = to > from ? to - 1 : to;
      _solo = null;
    });
  }

  // ---------------------------------------------------------------- storage

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

  // ---------------------------------------------------------------- dialogs

  Future<void> _openGallery() async {
    if (_busy) return;
    final mine = await _loadMine();
    if (!mounted) return;
    final choice = await showGeneralDialog<({TilesetSurfacePreset preset, bool add})>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Close presets',
        barrierColor: Colors.black38,
        transitionDuration: const Duration(milliseconds: 160),
        pageBuilder: (context, _, __) => Align(
            alignment: Alignment.centerLeft,
            child: Material(
                color: _tg.panel,
                child: SizedBox(
                    width: math.min(420, MediaQuery.sizeOf(context).width),
                    height: double.infinity,
                    child: SafeArea(
                        child: _SurfaceGallery(
                            tg: _tg, mine: mine, canAdd: _customSpec != null, current: _customSpec?.layers))))),
        transitionBuilder: (context, animation, _, child) => SlideTransition(
            position: Tween(begin: const Offset(-0.3, 0), end: Offset.zero)
                .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
            child: FadeTransition(opacity: animation, child: child)));
    if (choice != null && mounted) _usePreset(choice.preset, add: choice.add);
  }

  Future<void> _openPaletteEditor() async {
    final spec = _customSpec;
    if (_busy || !_hasEightColors || spec == null) return;
    final result = await showDialog<List<int>>(
        context: context,
        barrierColor: _tg.ink.withValues(alpha: 0.6),
        builder: (context) => _PaletteEditor(tg: _tg, palette: _palette.sublist(0, 8), spec: spec, size: _size));
    if (result != null && mounted) _updateDraft(() => _palette = [...result, ..._palette.skip(8)]);
  }

  Future<void> _openPatternPicker() async {
    final spec = _customSpec;
    if (_busy || spec == null || !_hasEightColors) return;
    final layer = spec.layers[_layer];
    final result = await showDialog<TilesetPattern>(
        context: context,
        barrierColor: _tg.ink.withValues(alpha: 0.6),
        builder: (context) => _PatternPicker(
            tg: _tg, palette: _palette, current: layer.pattern, title: 'Layer ${_layer + 1} · ${layer.pattern.label}'));
    if (result != null && mounted) _editLayer((l) => l.copyWith(pattern: result));
  }

  // ------------------------------------------------------------ live preview

  ({Uint32List tile, bool seamless, int size})? _liveInfo(TilesetSurfaceSpec spec) {
    if (!_hasEightColors) return null;
    final shown = _solo != null && _solo! < spec.layers.length
        ? TilesetSurfaceSpec(name: spec.name, layers: [spec.layers[_solo!].copyWith(visible: true)])
        : spec;
    final key = Object.hash(shown, Object.hashAll(_palette), _size);
    if (_liveKey != key) {
      _liveKey = key;
      _liveTile = shown.renderSample(_palette, size: _size);
      _liveSeamless = spec.isSeamless(_palette, size: _size);
    }
    return (tile: _liveTile!, seamless: _liveSeamless, size: _size);
  }

  Widget _liveArt(Uint32List pixels, int width, int height, double w, double h) => ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CustomPaint(
          size: Size(w, h),
          painter: _SurfacePreviewPainter((pixels: pixels, width: width, height: height), _tg.checkerA)));

  /// The tile and its 3x2 repeat, as shown beside the sample map.
  Widget _tileCard(TilesetSurfaceSpec spec, {bool framed = true}) {
    final info = _liveInfo(spec);
    if (info == null) return const SizedBox.shrink();
    final n = info.size, tile = info.tile;
    final repeated = Uint32List(n * 3 * n * 2);
    for (var y = 0; y < n * 2; y++) {
      for (var x = 0; x < n * 3; x++) {
        repeated[y * n * 3 + x] = tile[(y % n) * n + x % n];
      }
    }
    final content = Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('TILE $n×$n', style: _tg.pixel(10)),
        const SizedBox(height: 6),
        _liveArt(tile, n, n, 64, 64),
      ]),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text('3×3 REPEAT', style: _tg.pixel(10)),
        const SizedBox(height: 6),
        _liveArt(repeated, n * 3, n * 2, 96, 64),
      ]),
    ]);
    if (!framed) return content;
    return Container(
        key: const ValueKey('tile-card'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: _tg.panel,
            borderRadius: BorderRadius.circular(_tg.cardRadius),
            border: Border.all(color: _tg.border),
            boxShadow: [BoxShadow(color: _tg.shadowColor, blurRadius: _tg.shadowBlur, offset: const Offset(0, 4))]),
        child: content);
  }

  Widget _seamToggle(TilesetSurfaceSpec spec, {bool compact = false}) {
    final info = _liveInfo(spec);
    final ok = info?.seamless ?? true;
    final color = ok ? _tg.green : _tg.amber;
    return Container(
        key: const ValueKey('seam-check'),
        height: compact ? 40 : 48,
        padding: EdgeInsets.fromLTRB(compact ? 6 : 8, 0, compact ? 12 : 16, 0),
        decoration: BoxDecoration(
            color: _tg.panel,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _tg.border),
            boxShadow: compact
                ? null
                : [BoxShadow(color: _tg.shadowColor, blurRadius: _tg.shadowBlur, offset: const Offset(0, 4))]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _SeToggle(
              tg: _tg,
              on: _seamCheck,
              onColor: _tg.green,
              small: compact,
              onChanged: (v) => _updateDraft(() => _seamCheck = v)),
          const SizedBox(width: 10),
          if (!compact) ...[
            const Text('Seam check', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            Container(width: 1, height: 24, color: _tg.border),
            const SizedBox(width: 10),
          ],
          if (_seamCheck) ...[
            Icon(ok ? Icons.check_circle : Icons.warning_amber, size: compact ? 18 : 22, color: color),
            const SizedBox(width: 6),
            Text(ok ? 'all seams match' : 'edges differ',
                style: TextStyle(fontSize: compact ? 12 : 13, fontWeight: FontWeight.w600, color: color)),
          ] else
            Text('off', style: TextStyle(fontSize: 12, color: _tg.muted)),
        ]));
  }

  /// Floating cards over the sample map (wide layout).
  List<Widget> _surfaceOverlays() {
    final spec = _customSpec;
    if (spec == null || !_hasEightColors) return const [];
    return [
      Positioned(right: 16, top: 16, child: _tileCard(spec)),
      Positioned(left: 0, right: 0, bottom: 20, child: Center(child: _seamToggle(spec))),
    ];
  }

  /// Phone layout: the tile, its repeat and the seam check pinned above the list.
  Widget _pinnedPreview() {
    final spec = _customSpec;
    if (spec == null || !_hasEightColors) return const SizedBox.shrink();
    return Container(
        key: const ValueKey('pinned-preview'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(color: _tg.checkerA, border: Border(bottom: BorderSide(color: _tg.border))),
        child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: 12,
            runSpacing: 8,
            children: [
              _tileCard(spec, framed: false),
              _seamToggle(spec, compact: true),
            ]));
  }

  // ------------------------------------------------------------------ panel

  /// Left column of the editor: surface name, layer stack, inspector and global settings.
  Widget _surfacePanel() {
    final spec = _customSpec;
    final wide = _wideLayout;
    return ColoredBox(
        color: _tg.panel,
        child: Column(children: [
          if (!wide) _pinnedPreview(),
          Expanded(child: LayoutBuilder(builder: (context, box) {
            final sheet = !wide && spec != null;
            return Stack(children: [
              Positioned.fill(
                  child: ListView(
                      padding: EdgeInsets.fromLTRB(12, 10, 12, 16 + (sheet ? box.maxHeight * 0.45 : 0)),
                      children: [
                    if (spec != null) ...[
                      _nameRow(spec),
                      const SizedBox(height: 8),
                      _presetRow(),
                      const SizedBox(height: 8),
                      ..._layersSection(spec),
                      if (wide) ...[const SizedBox(height: 8), _inspector(spec, spec.layers[_layer])],
                    ] else ...[
                      ..._classicBanner(),
                    ],
                    const SizedBox(height: 12),
                    ..._globalSection(),
                    const SizedBox(height: 12),
                    ..._moreSection(),
                  ])),
              if (sheet) Positioned.fill(child: _inspectorSheet(spec)),
            ]);
          })),
          Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(color: _tg.panel, border: Border(top: BorderSide(color: _tg.border))),
              child: PvPixelButton(
                  key: const ValueKey('surface-generate'),
                  label: _tiles.isEmpty ? 'GENERATE TILESET' : 'REGENERATE TILESET',
                  icon: Icons.auto_awesome,
                  height: 44,
                  expand: true,
                  onPressed: _busy ? null : _generateTiles)),
        ]));
  }

  Widget _nameRow(TilesetSurfaceSpec spec) {
    final info = _liveInfo(spec);
    final ok = info?.seamless ?? true;
    final color = ok ? _tg.green : _tg.amber;
    return Row(children: [
      Expanded(
          child: PvTextField(
              fieldKey: const ValueKey('surface-name'),
              controller: _specName,
              enabled: !_busy,
              maxLength: 60,
              hint: 'Surface name',
              prefixIcon: Icons.edit_outlined,
              onChanged: (v) {
                final current = _customSpec;
                if (current != null && v.trim().isNotEmpty) {
                  _setSpec(current.copyWith(name: v), coalesce: 'name');
                }
              })),
      const SizedBox(width: 8),
      Container(
          key: const ValueKey('seam-pill'),
          height: 24,
          padding: const EdgeInsets.fromLTRB(6, 0, 8, 0),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.6))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(ok ? Icons.check_circle : Icons.warning_amber, size: 14, color: color),
            const SizedBox(width: 4),
            Text(ok ? 'SEAMLESS' : 'EDGES DIFFER', style: _tg.pixel(10, color: color)),
          ])),
    ]);
  }

  Widget _presetRow() => Row(children: [
        _Pill(
            key: const ValueKey('surface-open-presets'),
            tg: _tg,
            label: 'Preset',
            icon: Icons.grid_view,
            iconColor: _tg.highlight,
            trailing: Icons.expand_more,
            radius: _tg.chipRadius,
            onTap: _busy ? null : _openGallery),
        const SizedBox(width: 8),
        Expanded(
            child: _Pill(
                key: const ValueKey('surface-save-mine'),
                tg: _tg,
                label: 'Save as my surface',
                icon: Icons.bookmark_add_outlined,
                iconColor: _tg.highlight,
                radius: _tg.chipRadius,
                expand: true,
                onTap: _busy ? null : _saveMine)),
      ]);

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
              _Pill(
                  key: const ValueKey('surface-open-presets'),
                  tg: _tg,
                  label: 'Start from a preset',
                  icon: Icons.grid_view,
                  selected: true,
                  onTap: _busy ? null : _openGallery),
            ])),
      ];

  List<Widget> _layersSection(TilesetSurfaceSpec spec) {
    final full = spec.layers.length >= tilesetMaxLayers;
    return [
      SizedBox(
          height: 32,
          child: Row(children: [
            Text('LAYERS', style: _tg.pixel(12)),
            const SizedBox(width: 8),
            Text('${spec.layers.length} / $tilesetMaxLayers', style: _tg.monoAt(12, color: _tg.muted)),
            const Spacer(),
            Tooltip(
                message: full ? 'Maximum of $tilesetMaxLayers layers reached' : 'Add a layer on top',
                child: _Pill(
                    key: const ValueKey('layer-add'),
                    tg: _tg,
                    label: 'Layer',
                    icon: Icons.add,
                    selected: true,
                    height: 28,
                    radius: 14,
                    onTap: _busy || full ? null : _addLayer)),
          ])),
      const SizedBox(height: 2),
      _layerStack(spec),
      if (full)
        Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(children: [
              Icon(Icons.info_outline, size: 16, color: _tg.amber),
              const SizedBox(width: 6),
              Expanded(
                  child: Text('Layer limit reached. Delete or merge a layer to add another.',
                      style: TextStyle(fontSize: 11, color: _tg.muted))),
            ])),
    ];
  }

  Widget _layerStack(TilesetSurfaceSpec spec) {
    final count = spec.layers.length;
    final height = _wideLayout ? 42.0 : 56.0;
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
          final noise = layer.noise;
          final sub = _wideLayout
              ? (noise == null ? 'No noise' : 'Noise · ${noise.type.label}')
              : (index == 0 ? 'Base fill' : _blendShort[layer.blend]!);
          final soloed = _solo == index;
          return Container(
              key: ValueKey('layer-row-$index'),
              height: height,
              margin: const EdgeInsets.only(bottom: 3),
              decoration: BoxDecoration(
                  color: selected ? _tg.elevated : _tg.panel,
                  borderRadius: BorderRadius.circular(_tg.chipRadius),
                  border: Border.all(color: selected ? _tg.highlight : _tg.border, width: selected ? 2 : 1)),
              child: Opacity(
                  opacity: layer.visible ? 1 : 0.6,
                  child: InkWell(
                      borderRadius: BorderRadius.circular(_tg.chipRadius),
                      onTap: () => _updateDraft(() => _layer = index),
                      child: Row(children: [
                        ReorderableDragStartListener(
                            index: row,
                            child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                child: Icon(Icons.drag_indicator, size: 20, color: _tg.muted))),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: CustomPaint(
                                size: Size.square(_wideLayout ? 30 : 40),
                                painter: _SurfacePreviewPainter(swatch, _tg.checkerA))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(layer.pattern.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              Text(sub,
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
                            icon:
                                layer.visible || index == 0 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            size: _wideLayout ? 30 : 40,
                            onPressed: index == 0
                                ? null
                                : () {
                                    final layers = List.of(spec.layers);
                                    layers[index] = layer.copyWith(visible: !layer.visible);
                                    _setSpec(spec.copyWith(layers: layers));
                                  }),
                        _TgIconButton(
                            label: soloed ? 'Show all layers' : 'Solo layer ${index + 1}',
                            icon: Icons.headphones,
                            size: _wideLayout ? 30 : 40,
                            selected: soloed,
                            onPressed: () => _updateDraft(() => _solo = soloed ? null : index)),
                        if (_wideLayout)
                          Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Container(
                                  height: 22,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: _tg.background,
                                      borderRadius: BorderRadius.circular(13),
                                      border: Border.all(color: _tg.border)),
                                  child: Text(index == 0 ? 'Replace' : _blendShort[layer.blend]!,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)))),
                      ]))));
        });
  }

  // -------------------------------------------------------------- inspector

  Widget _inspector(TilesetSurfaceSpec spec, TilesetLayer layer) => Container(
      decoration: BoxDecoration(
          color: _tg.background,
          borderRadius: BorderRadius.circular(_tg.chipRadius),
          border: Border.all(color: _tg.border)),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _inspectorTabs(),
        Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ...switch (_layerTab) {
                0 => _patternTab(spec, layer),
                1 => _noiseTab(layer),
                2 => _colorTab(layer),
                _ => _rulesTab(spec, layer),
              },
            ])),
      ]));

  Widget _inspectorTabs() => Row(children: [
        for (var i = 0; i < _layerTabs.length; i++)
          Expanded(
              child: Semantics(
                  key: ValueKey('layer-tab-${_layerTabs[i].toLowerCase()}'),
                  button: true,
                  selected: _layerTab == i,
                  child: InkWell(
                      onTap: () => _updateDraft(() => _layerTab = i),
                      child: Container(
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: _layerTab == i ? _tg.elevated : null,
                              border: Border(
                                  bottom: BorderSide(
                                      color: _layerTab == i ? _tg.highlight : Colors.transparent, width: 2))),
                          child: Text(_layerTabs[i].toUpperCase(), style: _tg.pixel(10)))))),
      ]);

  /// Phone layout: the inspector rides in a draggable sheet pinned to the bottom.
  Widget _inspectorSheet(TilesetSurfaceSpec spec) => DraggableScrollableSheet(
      key: const ValueKey('layer-sheet'),
      initialChildSize: 0.45,
      minChildSize: 0.12,
      maxChildSize: 0.9,
      snap: true,
      snapSizes: const [0.12, 0.45, 0.9],
      builder: (context, controller) => DecoratedBox(
          decoration: BoxDecoration(
              color: _tg.panel,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(top: BorderSide(color: _tg.border)),
              boxShadow: [BoxShadow(color: _tg.shadowColor, blurRadius: 24, offset: const Offset(0, -6))]),
          child: ListView(controller: controller, padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), children: [
            SizedBox(
                height: 18,
                child: Center(
                    child: Container(
                        key: const ValueKey('sheet-handle'),
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(color: _tg.muted, borderRadius: BorderRadius.circular(3))))),
            _inspector(spec, spec.layers[_layer]),
          ])));

  Widget _slider(String label, String value, double current, double min, double max, ValueChanged<double> onChanged,
          {int? divisions, String? key}) =>
      _SeSlider(
          key: key == null ? null : ValueKey(key),
          tg: _tg,
          label: label,
          value: value,
          current: current,
          min: min,
          max: max,
          divisions: divisions,
          labelWidth: _wideLayout ? 68 : 70,
          onChanged: _busy ? null : onChanged);

  List<Widget> _patternTab(TilesetSurfaceSpec spec, TilesetLayer layer) {
    final thumb = _swatchOf(TilesetSurfaceSpec(
        layers: [layer.copyWith(visible: true, noise: null, area: TilesetLayerArea.all, density: 1, invert: false)]));
    return [
      Row(children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CustomPaint(size: const Size.square(44), painter: _SurfacePreviewPainter(thumb, _tg.checkerA))),
        const SizedBox(width: 10),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(layer.pattern.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Text(layer.pattern.description,
              maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: _tg.muted)),
        ])),
        _Pill(
            key: const ValueKey('pattern-change'),
            tg: _tg,
            label: 'Change',
            icon: Icons.grid_view,
            iconColor: _tg.highlight,
            onTap: _busy ? null : _openPatternPicker),
      ]),
      if (layer.pattern != TilesetPattern.solid) ...[
        const SizedBox(height: 10),
        Text('Cell size', style: _label),
        const SizedBox(height: 4),
        Row(children: [
          for (final (value, name) in const [(-1, 'small'), (0, 'normal'), (1, 'large')]) ...[
            if (value > -1) const SizedBox(width: 6),
            Expanded(
                child: _Pill(
                    key: ValueKey('cell-$name'),
                    tg: _tg,
                    label: '${name[0].toUpperCase()}${name.substring(1)}',
                    selected: layer.cell == value,
                    expand: true,
                    onTap: _busy ? null : () => _editLayer((l) => l.copyWith(cell: value)))),
          ]
        ]),
      ],
      if (const {TilesetPattern.bricks, TilesetPattern.planks, TilesetPattern.tiles}.contains(layer.pattern)) ...[
        const SizedBox(height: 10),
        Text('Grout width', style: _label),
        const SizedBox(height: 4),
        Row(children: [
          for (final width in const [1, 2]) ...[
            if (width > 1) const SizedBox(width: 6),
            Expanded(
                child: _Pill(
                    key: ValueKey('gap-$width'),
                    tg: _tg,
                    label: '$width px',
                    selected: layer.gap == width,
                    expand: true,
                    onTap: _busy ? null : () => _editLayer((l) => l.copyWith(gap: width)))),
          ]
        ]),
      ],
      if (_layer == 0)
        Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('The base layer fills the whole tile; upper layers draw detail on top.',
                style: TextStyle(fontSize: 11, color: _tg.muted))),
      const SizedBox(height: 10),
      Row(children: [
        Tooltip(
            message: 'Duplicate layer ${_layer + 1}',
            child: _Pill(
                key: const ValueKey('layer-duplicate'),
                tg: _tg,
                label: 'Duplicate',
                icon: Icons.copy,
                onTap: _busy || spec.layers.length >= tilesetMaxLayers ? null : () => _duplicateLayer(_layer))),
        const SizedBox(width: 8),
        Tooltip(
            message: 'Delete layer ${_layer + 1}',
            child: _Pill(
                key: const ValueKey('layer-delete'),
                tg: _tg,
                label: 'Delete',
                icon: Icons.delete_outline,
                onTap: _busy || spec.layers.length <= 1 ? null : () => _removeLayer(_layer))),
      ]),
    ];
  }

  TextStyle get _label => TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _tg.muted);

  List<Widget> _noiseTab(TilesetLayer layer) {
    final noise = layer.noise;
    if (noise == null) {
      return [
        Text('This layer is clean. Noise roughens it with speckles, blotches or streaks.',
            style: TextStyle(fontSize: 11, color: _tg.muted)),
        const SizedBox(height: 8),
        Align(
            alignment: Alignment.centerLeft,
            child: _Pill(
                key: const ValueKey('noise-enabled'),
                tg: _tg,
                label: 'Add noise',
                icon: Icons.add,
                selected: true,
                onTap: _busy ? null : () => _editLayer((l) => l.copyWith(noise: const TilesetNoise())))),
      ];
    }
    return [
      Row(children: [
        for (final type in TilesetNoiseType.values) ...[
          if (type != TilesetNoiseType.values.first) const SizedBox(width: 6),
          Expanded(
              child: _Pill(
                  key: ValueKey('noise-${type.name}'),
                  tg: _tg,
                  label: type.label,
                  selected: noise.type == type,
                  expand: true,
                  onTap: _busy ? null : () => _editLayer((l) => l.copyWith(noise: noise.copyWith(type: type))))),
        ]
      ]),
      const SizedBox(height: 2),
      _slider('Scale', '${noise.scale} px', noise.scale.toDouble(), 1, 16,
          (v) => _editLayer((l) => l.copyWith(noise: noise.copyWith(scale: v.round())), coalesce: 'scale'),
          divisions: 15, key: 'noise-scale'),
      _slider('Strength', '${(noise.strength * 100).round()}%', noise.strength, 0, 1,
          (v) => _editLayer((l) => l.copyWith(noise: noise.copyWith(strength: v)), coalesce: 'strength'),
          key: 'noise-strength'),
      _slider('Threshold', noise.threshold.toStringAsFixed(2), noise.threshold, 0, 1,
          (v) => _editLayer((l) => l.copyWith(noise: noise.copyWith(threshold: v)), coalesce: 'threshold'),
          key: 'noise-threshold'),
      Row(children: [
        SizedBox(width: _wideLayout ? 68 : 70, child: Text('Seed', style: _label)),
        Expanded(
            child: Container(
                height: 30,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                    color: _tg.panel,
                    borderRadius: BorderRadius.circular(_tg.chipRadius),
                    border: Border.all(color: _tg.border)),
                child: Text('${noise.seed}', style: _tg.monoAt(12)))),
        const SizedBox(width: 8),
        _Pill(
            key: const ValueKey('noise-roll'),
            tg: _tg,
            label: 'Roll',
            icon: Icons.casino_outlined,
            iconColor: _tg.highlight,
            height: 30,
            radius: _tg.chipRadius,
            onTap: _busy
                ? null
                : () => _editLayer((l) => l.copyWith(noise: noise.copyWith(seed: math.Random().nextInt(9999) + 1)))),
      ]),
      const SizedBox(height: 6),
      Align(
          alignment: Alignment.centerLeft,
          child: _Pill(
              key: const ValueKey('noise-remove'),
              tg: _tg,
              label: 'Remove noise',
              icon: Icons.close,
              onTap: _busy ? null : () => _editLayer((l) => l.copyWith(noise: null)))),
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
        Text(_slotRoles[role], style: _label),
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
                        borderRadius: BorderRadius.circular(5),
                        child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                                color: _hasEightColors ? Color(_palette[slot]) : _tg.elevated,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                    color: values[role] == slot ? _tg.text : _tg.border,
                                    width: values[role] == slot ? 2 : 1)),
                            child: values[role] == slot
                                ? Icon(Icons.check, size: 14, color: _onColor(_palette[slot]))
                                : null)))),
          ]
        ]),
        const SizedBox(height: 6),
      ],
      Text('Slots come from the shared palette; editing a color updates every layer that uses it.',
          style: TextStyle(fontSize: 11, color: _tg.muted)),
    ];
  }

  Color _onColor(int argb) => Color(argb).computeLuminance() > 0.5 ? Colors.black : Colors.white;

  List<Widget> _rulesTab(TilesetSurfaceSpec spec, TilesetLayer layer) {
    final base = _layer == 0;
    final tone = _hasEightColors ? spec.toneBelow(_palette, _layer) : (light: true, dark: true);
    String? reason(TilesetLayerBlend blend) {
      if (base && blend != TilesetLayerBlend.replace) {
        return 'The base layer always replaces. Blend modes apply to layers above it.';
      }
      if (blend == TilesetLayerBlend.dark && !base && !tone.dark) {
        return 'Layer $_layer is all light, so there is nothing dark to sit on.';
      }
      if (blend == TilesetLayerBlend.light && !base && !tone.light) {
        return 'Layer $_layer is all dark, so there is nothing light to sit on.';
      }
      return null;
    }

    final blocked = [
      for (final blend in TilesetLayerBlend.values)
        if (reason(blend) != null) blend
    ];
    return [
      Text('Where', style: _label),
      const SizedBox(height: 4),
      Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
              color: _tg.panel,
              borderRadius: BorderRadius.circular(_tg.chipRadius),
              border: Border.all(color: _tg.border)),
          child: Row(children: [
            for (final area in TilesetLayerArea.values) ...[
              if (area != TilesetLayerArea.values.first) const SizedBox(width: 2),
              Expanded(
                  child: Semantics(
                      key: ValueKey('area-${area.name}'),
                      button: true,
                      selected: layer.area == area,
                      child: InkWell(
                          borderRadius: BorderRadius.circular(math.max(0, _tg.chipRadius - 2)),
                          onTap: _busy ? null : () => _editLayer((l) => l.copyWith(area: area)),
                          child: Container(
                              height: 34,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                  color: layer.area == area ? _tg.accent : null,
                                  borderRadius: BorderRadius.circular(math.max(0, _tg.chipRadius - 2))),
                              child: Text(area.label.replaceFirst('Exposed ', 'Exposed\n'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 10,
                                      height: 1.1,
                                      fontWeight: FontWeight.w600,
                                      color: layer.area == area ? _tg.ink : _tg.text)))))),
            ]
          ])),
      Padding(
          padding: const EdgeInsets.only(top: 4),
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
      SizedBox(
          height: 32,
          child: Row(children: [
            Expanded(child: Text('Invert area', style: _label)),
            _SeToggle(
                key: const ValueKey('layer-invert'),
                tg: _tg,
                on: layer.invert,
                onColor: _tg.accent,
                onChanged: _busy ? null : (on) => _editLayer((l) => l.copyWith(invert: on))),
            SizedBox(
                width: 34,
                child: Text(layer.invert ? 'On' : 'Off',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _tg.muted))),
          ])),
      Text('Blend', style: _label),
      const SizedBox(height: 4),
      GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 150 / 32,
          children: [
            for (final blend in TilesetLayerBlend.values)
              Tooltip(
                  message: reason(blend) ?? blend.description,
                  child: _Pill(
                      key: ValueKey('blend-${blend.name}'),
                      tg: _tg,
                      label: blend.label,
                      icon: layer.blend == blend && reason(blend) == null
                          ? Icons.check
                          : reason(blend) != null
                              ? Icons.block
                              : _blendIcons[blend],
                      selected: layer.blend == blend && reason(blend) == null,
                      dashedWarn: reason(blend) != null && !base,
                      disabled: reason(blend) != null,
                      expand: true,
                      onTap:
                          _busy || reason(blend) != null ? null : () => _editLayer((l) => l.copyWith(blend: blend)))),
          ]),
      if (blocked.isNotEmpty && !base)
        _Callout(
            tg: _tg,
            child: Text.rich(TextSpan(children: [
              TextSpan(
                  text: _blendShort[blocked.first]!.replaceFirst('On ', 'Only on '),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: ' is unavailable. ${reason(blocked.first)}'),
            ]))),
      if (base)
        Padding(
            padding: const EdgeInsets.only(top: 6),
            child:
                Text('Blend modes apply to layers above the base.', style: TextStyle(fontSize: 11, color: _tg.muted))),
    ];
  }

  // ----------------------------------------------------------------- global

  List<Widget> _globalSection() => [
        Text('GLOBAL', style: _tg.pixel(12)),
        const SizedBox(height: 6),
        Row(key: const ValueKey('set-geometry-summary'), children: [
          Expanded(child: _ReadOnlyTile(tg: _tg, label: 'Projection', value: _perspective.label)),
          const SizedBox(width: 6),
          Expanded(child: _ReadOnlyTile(tg: _tg, label: 'Tile size', value: '$_size × $_size px', mono: true)),
        ]),
        if (_perspective == TilesetPerspective.isometric)
          Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Size is the logical diamond height. Sprite width is twice this value.',
                  style: TextStyle(fontSize: 11, color: _tg.muted))),
        const SizedBox(height: 6),
        SizedBox(
            height: 32,
            child: Row(children: [
              SizedBox(width: 54, child: Text('Palette', style: _label)),
              Expanded(
                  child: Row(children: [
                for (var i = 0; i < 8 && i < _palette.length; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Expanded(
                      child: Tooltip(
                          message: 'Palette slot $i · ${tilesetSlotRoles[i]}',
                          child: Container(
                              height: 22,
                              decoration: BoxDecoration(
                                  color: Color(_palette[i]),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: _tg.border))))),
                ]
              ])),
              const SizedBox(width: 8),
              _Pill(
                  key: const ValueKey('palette-edit'),
                  tg: _tg,
                  label: 'Edit',
                  icon: Icons.palette_outlined,
                  height: 30,
                  radius: _tg.chipRadius,
                  onTap: _busy || !_hasEightColors ? null : _openPaletteEditor),
            ])),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(
              child: PvTextField(
                  fieldKey: const ValueKey('global-seed'),
                  controller: _seed,
                  enabled: !_busy,
                  label: 'Seed',
                  hint: 'Seed',
                  mono: true,
                  keyboardType: TextInputType.number,
                  suffix: _TgIconButton(
                      label: 'Shuffle seed',
                      icon: Icons.casino_outlined,
                      size: 32,
                      onPressed: _busy
                          ? null
                          : () => _updateDraft(() => _seed.text = '${math.Random().nextInt(0x7fffffff)}')))),
          const SizedBox(width: 6),
          PvStepper(
              label: 'Variations',
              value: _variations,
              min: 1,
              max: 6,
              decreaseTooltip: 'Fewer variations',
              increaseTooltip: 'More variations',
              onChanged: _busy ? null : (v) => _updateDraft(() => _variations = v)),
        ]),
      ];

  /// Existing set options that sit below the surface: base, modifiers and connection parts.
  List<Widget> _moreSection() {
    final bases = TilesetRecipe.basesFor(_perspective);
    return [
      if (bases.length > 1) ...[
        Text('USE AS', style: _tg.pixel(12)),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final base in bases)
            _Pill(
                key: ValueKey('surface-base-${base.name}'),
                tg: _tg,
                label: base.label,
                selected: _recipe.base == base,
                onTap: _busy ? null : () => _changeRecipe(_fitRecipe(_recipe.copyWith(base: base)))),
        ]),
        const SizedBox(height: 14),
      ],
      Text('MODIFIERS', style: _tg.pixel(12)),
      const SizedBox(height: 4),
      for (final modifier in TilesetModifiers.all) ..._modifierControls(modifier),
      const SizedBox(height: 12),
      Text('CONNECTION PARTS', style: _tg.pixel(12)),
      const SizedBox(height: 6),
      Row(children: [
        _Pill(
            tg: _tg,
            label: 'Select parts · ${_parts.length} / 47',
            icon: Icons.grid_view,
            iconColor: _tg.highlight,
            radius: _tg.chipRadius,
            onTap: _busy ? null : _chooseParts),
        const SizedBox(width: 10),
        Expanded(
            child: Text('${_parts.length} × $_variations = ${_parts.length * _variations} tiles',
                textAlign: TextAlign.right, style: _tg.mono)),
      ]),
    ];
  }
}

// ===================================================================== widgets

/// Pill button in the editor's style; filled when [selected].
class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.tg,
    required this.label,
    required this.onTap,
    this.icon,
    this.iconColor,
    this.trailing,
    this.selected = false,
    this.disabled = false,
    this.dashedWarn = false,
    this.expand = false,
    this.height = 32,
    this.radius = 16,
  });
  final _Tg tg;
  final String label;
  final VoidCallback? onTap;
  final IconData? icon, trailing;
  final Color? iconColor;
  final bool selected, disabled, dashedWarn, expand;
  final double height, radius;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? tg.ink : (disabled || onTap == null ? tg.muted : tg.text);
    final content = Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: selected ? tg.ink : (disabled ? tg.muted : iconColor ?? fg)),
            const SizedBox(width: 5),
          ],
          Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w600, color: fg))),
          if (trailing != null) ...[const SizedBox(width: 3), Icon(trailing, size: 16, color: tg.muted)],
        ]);
    final shape = BorderRadius.circular(radius);
    final body = Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: icon != null ? 10 : 12),
        decoration: BoxDecoration(
            color: selected ? tg.accent : null,
            borderRadius: shape,
            border: dashedWarn ? null : Border.all(color: selected ? tg.ink : tg.border)),
        child: Center(widthFactor: expand ? null : 1, child: content));
    return Semantics(
        button: true,
        selected: selected,
        enabled: onTap != null,
        label: label,
        excludeSemantics: true,
        child: Opacity(
            opacity: onTap == null && !disabled ? 0.5 : 1,
            child: InkWell(
                onTap: onTap,
                borderRadius: shape,
                child:
                    dashedWarn ? CustomPaint(foregroundPainter: _DashedBorder(tg.amber, radius), child: body) : body)));
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder(this.color, this.radius);
  final Color color;
  final double radius;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 8) {
        canvas.drawPath(metric.extractPath(d, math.min(d + 4, metric.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color || old.radius != radius;
}

class _ReadOnlyTile extends StatelessWidget {
  const _ReadOnlyTile({required this.tg, required this.label, required this.value, this.mono = false});
  final _Tg tg;
  final String label, value;
  final bool mono;
  @override
  Widget build(BuildContext context) => CustomPaint(
      foregroundPainter: _DashedBorder(tg.border, tg.chipRadius),
      child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(children: [
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label, style: TextStyle(fontSize: 9, height: 1.1, color: tg.muted)),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: mono
                          ? tg.monoAt(12, weight: FontWeight.w600)
                          : const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ])),
            Icon(Icons.lock_outline, size: 14, color: tg.muted),
          ])));
}

/// Warning callout with a notch pointing up at the option it explains.
class _Callout extends StatelessWidget {
  const _Callout({required this.tg, required this.child});
  final _Tg tg;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
            key: const ValueKey('blend-reason'),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
                color: tg.panel,
                borderRadius: BorderRadius.circular(tg.chipRadius),
                border: Border.all(color: tg.amber, width: 2)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, size: 18, color: tg.amber),
              const SizedBox(width: 8),
              Expanded(child: DefaultTextStyle.merge(style: const TextStyle(fontSize: 12, height: 1.35), child: child)),
            ])),
        Positioned(
            left: 36,
            top: -8,
            child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: tg.panel,
                        border: Border(
                            left: BorderSide(color: tg.amber, width: 2),
                            top: BorderSide(color: tg.amber, width: 2)))))),
      ]));
}

/// Track-and-thumb slider in the design's style: label, bar, mono value.
class _SeSlider extends StatelessWidget {
  const _SeSlider({
    super.key,
    required this.tg,
    required this.label,
    required this.value,
    required this.current,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.labelWidth = 76,
  });
  final _Tg tg;
  final String label, value;
  final double current, min, max, labelWidth;
  final int? divisions;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
      height: 30,
      child: Row(children: [
        SizedBox(
            width: labelWidth,
            child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tg.muted))),
        Expanded(
            child: SliderTheme(
                data: SliderThemeData(
                    trackHeight: 4,
                    activeTrackColor: tg.accent,
                    inactiveTrackColor: tg.border,
                    trackShape: const RoundedRectSliderTrackShape(),
                    thumbShape: _SeThumb(tg.panel, tg.text),
                    overlayShape: SliderComponentShape.noOverlay,
                    tickMarkShape: SliderTickMarkShape.noTickMark),
                child: Slider(
                    value: current.clamp(min, max), min: min, max: max, divisions: divisions, onChanged: onChanged))),
        SizedBox(width: 44, child: Text(value, textAlign: TextAlign.right, style: tg.monoAt(11))),
      ]));
}

class _SeThumb extends SliderComponentShape {
  const _SeThumb(this.fill, this.stroke);
  final Color fill, stroke;
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size.square(16);
  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final canvas = context.canvas;
    canvas.drawCircle(center, 8, Paint()..color = fill);
    canvas.drawCircle(
        center,
        7,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }
}

/// The editor's switch: a [PvSwitch] tinted with [onColor].
class _SeToggle extends StatelessWidget {
  const _SeToggle(
      {super.key,
      required this.tg,
      required this.on,
      required this.onColor,
      required this.onChanged,
      this.small = false});
  final _Tg tg;
  final bool on, small;
  final Color onColor;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => PvSwitch(value: on, onChanged: onChanged, activeColor: onColor, small: small);
}

// ==================================================================== dialogs

/// Preset browser: Presets / Mine / Recent with search and tag filters.
class _SurfaceGallery extends StatefulWidget {
  const _SurfaceGallery({required this.tg, required this.mine, required this.canAdd, required this.current});
  final _Tg tg;
  final List<({List<int> palette, TilesetSurfaceSpec spec})> mine;
  final bool canAdd;
  final List<TilesetLayer>? current;
  @override
  State<_SurfaceGallery> createState() => _SurfaceGalleryState();
}

class _SurfaceGalleryState extends State<_SurfaceGallery> {
  var _tab = 0;
  var _query = '';
  String? _tag;

  _Tg get tg => widget.tg;

  List<TilesetSurfacePreset> get _mine => [
        for (var i = 0; i < widget.mine.length; i++)
          TilesetSurfacePreset(id: 'mine-$i', tag: 'Mine', palette: widget.mine[i].palette, spec: widget.mine[i].spec)
      ];

  List<TilesetSurfacePreset> get _items {
    final source = switch (_tab) {
      0 => TilesetSurfacePresets.all,
      1 => _mine,
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
    final counts = [TilesetSurfacePresets.all.length, widget.mine.length, _recentSurfaces.length];
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text('PRESETS', style: tg.pixel(15))),
            _TgIconButton(label: 'Close presets', icon: Icons.close, size: 40, onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 10),
          DecoratedBox(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tg.border))),
              child: Row(children: [
                for (final (i, name) in const ['Presets', 'Mine', 'Recent'].indexed)
                  Expanded(
                      child: Semantics(
                          key: ValueKey('gallery-${name.toLowerCase()}'),
                          button: true,
                          selected: _tab == i,
                          child: InkWell(
                              onTap: () => setState(() => _tab = i),
                              child: Container(
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color: _tab == i ? tg.highlight : Colors.transparent, width: 2))),
                                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Text(name.toUpperCase(),
                                        style: tg.pixel(12, color: _tab == i ? tg.text : tg.muted)),
                                    const SizedBox(width: 6),
                                    Text('${counts[i]}', style: tg.monoAt(10, color: tg.muted)),
                                  ]))))),
              ])),
          const SizedBox(height: 10),
          Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                  color: tg.background, borderRadius: BorderRadius.circular(20), border: Border.all(color: tg.border)),
              child: Row(children: [
                Icon(Icons.search, size: 20, color: tg.muted),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        key: const ValueKey('gallery-search'),
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration.collapsed(
                            hintText: 'Search presets', hintStyle: TextStyle(color: tg.muted)),
                        onChanged: (v) => setState(() => _query = v))),
              ])),
          if (_tab == 0) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final tag in ['All', ...TilesetSurfacePresets.tags])
                _Pill(
                    key: ValueKey('gallery-tag-$tag'),
                    tg: tg,
                    label: tag,
                    selected: tag == 'All' ? _tag == null : _tag == tag,
                    onTap: () => setState(() => _tag = tag == 'All' || _tag == tag ? null : tag)),
            ]),
          ],
          const SizedBox(height: 10),
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
                  : GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.8,
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [for (final preset in items) _card(preset)])),
        ]));
  }

  Widget _card(TilesetSurfacePreset preset) {
    final swatch = (pixels: preset.spec.renderSample(preset.palette), width: 16, height: 16);
    final count = preset.spec.layers.length;
    final selected = widget.current != null && listEquals(widget.current, preset.spec.layers);
    return Container(
        key: ValueKey('preset-${preset.id}'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
            color: selected ? tg.elevated : tg.background,
            borderRadius: BorderRadius.circular(tg.cardRadius),
            border: Border.all(color: selected ? tg.highlight : tg.border, width: selected ? 2 : 1)),
        child: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InkWell(
                onTap: () => Navigator.pop(context, (preset: preset, add: false)),
                child: SizedBox(
                    height: 80,
                    width: double.infinity,
                    child: CustomPaint(
                        painter: _CheckerBackdrop(tg.checkerA, tg.checkerB),
                        child: Center(
                            child: CustomPaint(
                                size: const Size.square(64),
                                painter: _SurfacePreviewPainter(swatch, Colors.transparent)))))),
            Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
                child: Row(children: [
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(preset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Container(
                        height: 18,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: tg.background,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: tg.border)),
                        child: Text('$count ${count == 1 ? 'LAYER' : 'LAYERS'}', style: tg.pixel(9))),
                  ])),
                  if (widget.canAdd)
                    Tooltip(
                        message: 'Add as layers',
                        child: InkWell(
                            key: ValueKey('preset-add-${preset.id}'),
                            onTap: () => Navigator.pop(context, (preset: preset, add: true)),
                            child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.layers_outlined, size: 18, color: tg.muted)))),
                ])),
          ]),
          if (preset.pro)
            Positioned(
                right: 0,
                top: 0,
                child: Container(
                    height: 20,
                    padding: const EdgeInsets.fromLTRB(9, 0, 7, 0),
                    decoration: ShapeDecoration(
                        gradient: tg.tokens?.gradient ?? LinearGradient(colors: [tg.accent, tg.highlight]),
                        shape:
                            const BeveledRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(6)))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.lock, size: 12, color: tg.ink),
                      const SizedBox(width: 2),
                      Text('PRO', style: tg.pixel(10, color: tg.ink)),
                    ]))),
          if (selected)
            Positioned(
                left: 6,
                top: 6,
                child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(color: tg.accent, shape: BoxShape.circle),
                    child: Icon(Icons.check, size: 16, color: tg.ink))),
        ]));
  }
}

class _CheckerBackdrop extends CustomPainter {
  const _CheckerBackdrop(this.a, this.b);
  final Color a, b;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = a);
    final paint = Paint()..color = b;
    const cell = 8.0;
    for (var y = 0; y * cell < size.height; y++) {
      for (var x = 0; x * cell < size.width; x++) {
        if ((x + y).isEven) canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerBackdrop old) => old.a != a || old.b != b;
}

/// Shared frame for the large editor dialogs: title, subtitle, close button and a pinned footer.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame(
      {required this.tg,
      required this.title,
      required this.subtitle,
      required this.width,
      required this.body,
      required this.footer});
  final _Tg tg;
  final String title, subtitle;
  final double width;
  final Widget body, footer;
  @override
  Widget build(BuildContext context) => Dialog(
      backgroundColor: tg.panel,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tg.cardRadius), side: BorderSide(color: tg.border)),
      child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: tg.pixel(18)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: tg.muted)),
                  ])),
                  _TgIconButton(label: 'Close', icon: Icons.close, size: 40, onPressed: () => Navigator.pop(context)),
                ]),
                const SizedBox(height: 14),
                Flexible(child: SingleChildScrollView(child: body)),
                const SizedBox(height: 14),
                footer,
              ]))));
}

class _PatternPicker extends StatefulWidget {
  const _PatternPicker({required this.tg, required this.palette, required this.current, required this.title});
  final _Tg tg;
  final List<int> palette;
  final TilesetPattern current;
  final String title;
  @override
  State<_PatternPicker> createState() => _PatternPickerState();
}

class _PatternPickerState extends State<_PatternPicker> {
  late TilesetPattern _picked = widget.current;
  _Tg get tg => widget.tg;

  @override
  Widget build(BuildContext context) => _SheetFrame(
      tg: tg,
      width: 760,
      title: 'PICK A PATTERN',
      subtitle: '${widget.title}. The pattern sets the shape; noise and color come next.',
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        LayoutBuilder(builder: (context, box) {
          final columns = box.maxWidth >= 640
              ? 4
              : box.maxWidth >= 430
                  ? 3
                  : 2;
          final tile = (box.maxWidth - 12 * (columns - 1)) / columns - 0.01;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            for (final pattern in TilesetPattern.values) _card(pattern, tile),
          ]);
        }),
      ]),
      footer: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        _Pill(
            key: const ValueKey('pattern-cancel'),
            tg: tg,
            label: 'Cancel',
            height: 48,
            radius: tg.chipRadius,
            onTap: () => Navigator.pop(context)),
        const SizedBox(width: 10),
        PvPixelButton(
            key: const ValueKey('pattern-use'),
            label: 'USE ${_picked.label.toUpperCase()}',
            height: 48,
            onPressed: () => Navigator.pop(context, _picked)),
      ]));

  Widget _card(TilesetPattern pattern, double width) {
    final selected = pattern == _picked;
    final swatch = (
      pixels: TilesetSurfaceSpec(layers: [TilesetLayer(pattern: pattern)]).renderSample(widget.palette),
      width: 16,
      height: 16
    );
    return SizedBox(
        width: width,
        child: Semantics(
            key: ValueKey('pattern-${pattern.name}'),
            button: true,
            selected: selected,
            label: pattern.label,
            child: InkWell(
                borderRadius: BorderRadius.circular(tg.chipRadius),
                onTap: () => setState(() => _picked = pattern),
                child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: selected ? tg.elevated : tg.background,
                        borderRadius: BorderRadius.circular(tg.chipRadius),
                        border: Border.all(color: selected ? tg.highlight : tg.border, width: selected ? 2 : 1)),
                    child: Stack(children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                                height: 112,
                                width: double.infinity,
                                child: CustomPaint(
                                    painter: _CheckerBackdrop(tg.checkerA, tg.checkerB),
                                    child: Center(
                                        child: CustomPaint(
                                            size: const Size.square(96),
                                            painter: _SurfacePreviewPainter(swatch, Colors.transparent)))))),
                        const SizedBox(height: 6),
                        Text(pattern.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(pattern.description, style: TextStyle(fontSize: 11, color: tg.muted)),
                      ]),
                      if (selected)
                        Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(color: tg.accent, shape: BoxShape.circle),
                                child: Icon(Icons.check, size: 18, color: tg.ink))),
                    ])))));
  }
}

/// Eight labelled slots with a picker, palette presets, suggested shades and a contrast check.
class _PaletteEditor extends StatefulWidget {
  const _PaletteEditor({required this.tg, required this.palette, required this.spec, required this.size});
  final _Tg tg;
  final List<int> palette;
  final TilesetSurfaceSpec spec;
  final int size;
  @override
  State<_PaletteEditor> createState() => _PaletteEditorState();
}

class _PaletteEditorState extends State<_PaletteEditor> {
  late final List<int> _colors = List.of(widget.palette);
  var _slot = 5;
  late HSVColor _hsv = HSVColor.fromColor(Color(_colors[_slot]));

  _Tg get tg => widget.tg;

  static String _hex(int argb) => '#${(argb & 0xffffff).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  void _select(int slot) => setState(() {
        _slot = slot;
        _hsv = HSVColor.fromColor(Color(_colors[slot]));
      });

  void _setHsv(HSVColor hsv) => setState(() {
        _hsv = hsv;
        _colors[_slot] = 0xff000000 | hsv.toColor().toARGB32() & 0xffffff;
      });

  @override
  Widget build(BuildContext context) {
    final issue = paletteContrastIssue(_colors);
    final flagged = {if (issue != null) issue.a, if (issue != null) issue.b};
    final color = Color(_colors[_slot]);
    final presets = [
      ('Moss', TilesetSurfacePresets.grass.palette),
      ('Ember', TilesetSurfacePresets.lava.palette),
      ('Frost', TilesetSurfacePresets.ice.palette),
      ('Dusk', TilesetSurfacePresets.cloth.palette),
    ];
    final n = widget.size;
    final tile = widget.spec.renderSample(_colors, size: n);
    final repeated = Uint32List(n * 3 * n * 2);
    for (var y = 0; y < n * 2; y++) {
      for (var x = 0; x < n * 3; x++) {
        repeated[y * n * 3 + x] = tile[(y % n) * n + x % n];
      }
    }
    final slots = Column(children: [
      for (var i = 0; i < 8; i++)
        Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: InkWell(
                key: ValueKey('palette-slot-$i'),
                borderRadius: BorderRadius.circular(tg.chipRadius),
                onTap: () => _select(i),
                child: Container(
                    height: 44,
                    padding: const EdgeInsets.fromLTRB(6, 0, 10, 0),
                    decoration: BoxDecoration(
                        color: _slot == i ? tg.elevated : tg.background,
                        borderRadius: BorderRadius.circular(tg.chipRadius),
                        border: Border.all(color: _slot == i ? tg.highlight : tg.border, width: _slot == i ? 2 : 1)),
                    child: Row(children: [
                      Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: Color(_colors[i]),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: tg.border))),
                      const SizedBox(width: 10),
                      SizedBox(width: 12, child: Text('$i', style: tg.monoAt(12, color: tg.muted))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(i >= 1 && i <= 3 ? 'Accent' : tilesetSlotRoles[i],
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                      if (flagged.contains(i)) Icon(Icons.warning_amber, size: 18, color: tg.amber),
                      const SizedBox(width: 6),
                      Text(_hex(_colors[i]), style: tg.monoAt(12)),
                    ])))),
    ]);
    Widget box(String label, String value, {int flex = 1}) => Expanded(
        flex: flex,
        child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration:
                BoxDecoration(borderRadius: BorderRadius.circular(tg.chipRadius), border: Border.all(color: tg.border)),
            child: Row(children: [
              Text(label, style: TextStyle(fontSize: 11, color: tg.muted)),
              const SizedBox(width: 6),
              Flexible(child: Text(value, maxLines: 1, style: tg.monoAt(14, weight: FontWeight.w600))),
            ])));
    final editor = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Editing slot $_slot · ${tilesetSlotRoles[_slot]}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tg.muted)),
      const SizedBox(height: 8),
      _SvArea(key: const ValueKey('palette-sv'), tg: tg, hsv: _hsv, onChanged: _setHsv),
      const SizedBox(height: 12),
      _HueBar(key: const ValueKey('palette-hue'), tg: tg, hsv: _hsv, onChanged: _setHsv),
      const SizedBox(height: 12),
      Row(children: [
        box('HEX', _hex(_colors[_slot]), flex: 14),
        const SizedBox(width: 8),
        box('R', '${(color.r * 255).round()}', flex: 10),
        const SizedBox(width: 8),
        box('G', '${(color.g * 255).round()}', flex: 10),
        const SizedBox(width: 8),
        box('B', '${(color.b * 255).round()}', flex: 10),
      ]),
      const SizedBox(height: 12),
      Text('Palette presets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tg.muted)),
      const SizedBox(height: 6),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (name, colors) in presets)
          _PresetChip(
              key: ValueKey('palette-preset-$name'),
              tg: tg,
              label: name,
              swatches: [colors[4], colors[5], colors[6]],
              selected: false,
              onTap: () => setState(() {
                    for (var i = 0; i < 8; i++) {
                      _colors[i] = colors[i];
                    }
                    _hsv = HSVColor.fromColor(Color(_colors[_slot]));
                  })),
        _PresetChip(
            tg: tg,
            label: 'Custom',
            swatches: [_colors[4], _colors[5], _colors[6]],
            selected: !presets.any((p) => listEquals(p.$2.sublist(0, 8), _colors)),
            onTap: null),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        InkWell(
            key: const ValueKey('palette-suggest'),
            borderRadius: BorderRadius.circular(22),
            onTap: () => setState(() {
                  final shades = suggestShades(_colors[_slot]);
                  shades.forEach((slot, c) => _colors[slot] = c);
                  _slot = 5;
                  _hsv = HSVColor.fromColor(Color(_colors[5]));
                }),
            child: Container(
                height: 44,
                padding: const EdgeInsets.fromLTRB(12, 0, 16, 0),
                decoration: BoxDecoration(
                    color: tg.elevated,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: tg.highlight)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.auto_awesome, size: 20, color: tg.highlight),
                  const SizedBox(width: 6),
                  const Text('Suggest shades', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ]))),
        const SizedBox(width: 10),
        Expanded(
            child: Text('Builds Light, Dark and Highlight from the selected color.',
                style: TextStyle(fontSize: 11, height: 1.35, color: tg.muted))),
      ]),
      if (issue != null) ...[
        const SizedBox(height: 12),
        Container(
            key: const ValueKey('palette-warning'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: tg.background,
                borderRadius: BorderRadius.circular(tg.chipRadius),
                border: Border.all(color: tg.amber, width: 2)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.warning_amber, size: 20, color: tg.amber),
              const SizedBox(width: 10),
              Expanded(
                  child: Text.rich(TextSpan(style: const TextStyle(fontSize: 12, height: 1.4), children: [
                TextSpan(
                    text:
                        'Low contrast: ${issue.a} ${tilesetSlotRoles[issue.a]} vs ${issue.b} ${tilesetSlotRoles[issue.b]} is ${issue.ratio.toStringAsFixed(1)}:1. ',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: issue.message),
              ]))),
            ])),
      ],
    ]);
    return _SheetFrame(
        tg: tg,
        width: 920,
        title: 'PALETTE',
        subtitle: 'Eight slots shared by every layer. Change a slot and the whole surface follows.',
        body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          LayoutBuilder(builder: (context, box) {
            if (box.maxWidth < 700) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [slots, const SizedBox(height: 16), editor]);
            }
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 320, child: slots),
              const SizedBox(width: 28),
              Expanded(child: editor),
            ]);
          }),
        ]),
        footer: Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CustomPaint(
                  size: const Size(64, 64),
                  painter: _SurfacePreviewPainter((pixels: tile, width: n, height: n), tg.checkerA))),
          ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CustomPaint(
                  size: const Size(96, 64),
                  painter: _SurfacePreviewPainter((pixels: repeated, width: n * 3, height: n * 2), tg.checkerA))),
          Text('Live preview', style: TextStyle(fontSize: 12, color: tg.muted)),
          const SizedBox(width: 20),
          _Pill(
              key: const ValueKey('palette-cancel'),
              tg: tg,
              label: 'Cancel',
              height: 48,
              radius: tg.chipRadius,
              onTap: () => Navigator.pop(context)),
          PvPixelButton(
              key: const ValueKey('palette-apply'),
              label: 'APPLY PALETTE',
              height: 48,
              onPressed: () => Navigator.pop(context, _colors)),
        ]));
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip(
      {super.key,
      required this.tg,
      required this.label,
      required this.swatches,
      required this.selected,
      required this.onTap});
  final _Tg tg;
  final String label;
  final List<int> swatches;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
              height: 40,
              padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
              decoration: BoxDecoration(
                  color: selected ? tg.accent : null,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: selected ? tg.ink : tg.border)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                for (final c in swatches)
                  Container(width: 8, height: 16, margin: const EdgeInsets.only(right: 1), color: Color(c)),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? tg.ink : tg.text)),
              ]))));
}

/// Saturation / value square for the current hue.
class _SvArea extends StatelessWidget {
  const _SvArea({super.key, required this.tg, required this.hsv, required this.onChanged});
  final _Tg tg;
  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        const h = 190.0;
        void update(Offset p) =>
            onChanged(hsv.withSaturation((p.dx / w).clamp(0.0, 1.0)).withValue(1 - (p.dy / h).clamp(0.0, 1.0)));
        return GestureDetector(
            onPanStart: (d) => update(d.localPosition),
            onPanUpdate: (d) => update(d.localPosition),
            onTapDown: (d) => update(d.localPosition),
            child: Container(
                height: h,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(tg.chipRadius),
                    border: Border.all(color: tg.border),
                    gradient: LinearGradient(colors: [Colors.white, HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor()])),
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(tg.chipRadius),
                        gradient: const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black, Colors.transparent])),
                    child: Stack(clipBehavior: Clip.none, children: [
                      Positioned(
                          left: hsv.saturation * w - 10,
                          top: (1 - hsv.value) * h - 10,
                          child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [BoxShadow(color: Colors.black, spreadRadius: 1.5)]))),
                    ]))));
      });
}

class _HueBar extends StatelessWidget {
  const _HueBar({super.key, required this.tg, required this.hsv, required this.onChanged});
  final _Tg tg;
  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        void update(Offset p) => onChanged(hsv.withHue((p.dx / w).clamp(0.0, 1.0) * 359.99));
        return GestureDetector(
            onPanStart: (d) => update(d.localPosition),
            onPanUpdate: (d) => update(d.localPosition),
            onTapDown: (d) => update(d.localPosition),
            child: Container(
                height: 20,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tg.border),
                    gradient: const LinearGradient(colors: [
                      Color(0xffff0000),
                      Color(0xffffff00),
                      Color(0xff00ff00),
                      Color(0xff00ffff),
                      Color(0xff0000ff),
                      Color(0xffff00ff),
                      Color(0xffff0000)
                    ])),
                child: Stack(clipBehavior: Clip.none, children: [
                  Positioned(
                      left: hsv.hue / 360 * w - 5,
                      top: -3,
                      child: Container(
                          width: 10,
                          height: 24,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [BoxShadow(color: Colors.black, spreadRadius: 1.5)]))),
                ])));
      });
}
