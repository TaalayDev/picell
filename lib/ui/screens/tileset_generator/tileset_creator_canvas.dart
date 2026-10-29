part of 'tileset_generator_screen.dart';

extension _CreatorCanvas on TilesetGeneratorScreenState {
  int get _creatorColumns => _creatorView == 'Single Tile' ? 1 : _creatorRepeat;
  Size get _creatorContentSize => Size(_size * _creatorColumns.toDouble(), _size * _creatorColumns.toDouble());

  void _setCreatorCanvasTool(String tool) {
    _updateDraft(() => _creatorCanvasTool = tool);
    _creatorFocus.requestFocus();
  }

  void _creatorZoomTo(double scale, {Offset? anchor}) {
    if (_creatorViewportSize.isEmpty) return;
    final focal = anchor ?? _creatorViewportSize.center(Offset.zero);
    final scene = _creatorTransform.toScene(focal);
    final next = scale.clamp(0.25, 64.0);
    _creatorTransform.value = Matrix4.diagonal3Values(next, next, next)
      ..setEntry(0, 3, focal.dx - scene.dx * next)
      ..setEntry(1, 3, focal.dy - scene.dy * next);
  }

  void _fitCreatorCanvas() {
    if (_creatorViewportSize.isEmpty) return;
    final pixels = _creatorContentSize;
    final ideal =
        math.min((_creatorViewportSize.width - 32) / pixels.width, (_creatorViewportSize.height - 32) / pixels.height);
    final scale = (ideal >= 1 ? ideal.floorToDouble() : ideal).clamp(0.25, 64.0);
    _creatorTransform.value = Matrix4.diagonal3Values(scale, scale, scale)
      ..setEntry(0, 3, (_creatorViewportSize.width - pixels.width * scale) / 2)
      ..setEntry(1, 3, (_creatorViewportSize.height - pixels.height * scale) / 2);
  }

  KeyEventResult _creatorCanvasKey(FocusNode node, KeyEvent event) {
    if (_workspaceTab != 0) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space) {
      _updateDraft(() => _creatorSpaceDown = event is! KeyUpEvent);
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isAltPressed) {
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.keyH) {
      _setCreatorCanvasTool('hand');
    } else if (key == LogicalKeyboardKey.keyI) {
      _setCreatorCanvasTool('pick');
    } else if (key == LogicalKeyboardKey.keyZ) {
      _setCreatorCanvasTool('zoom');
    } else if (key == LogicalKeyboardKey.digit0) {
      _fitCreatorCanvas();
    } else if (key == LogicalKeyboardKey.digit1) {
      _creatorZoomTo(1);
    } else if (key == LogicalKeyboardKey.equal || key == LogicalKeyboardKey.numpadAdd) {
      _creatorZoomTo(_creatorZoom * 1.25);
    } else if (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract) {
      _creatorZoomTo(_creatorZoom / 1.25);
    } else if (key == LogicalKeyboardKey.keyG) {
      _updateDraft(() => _creatorPixelGrid = !_creatorPixelGrid);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  ({int x, int y, int color})? _creatorPixelAt(Offset local, _Swatch swatch) {
    final point = _creatorTransform.toScene(local);
    if (point.dx < 0 || point.dy < 0 || point.dx >= swatch.width || point.dy >= swatch.height) return null;
    final x = point.dx.floor(), y = point.dy.floor();
    return (x: x % _size, y: y % _size, color: swatch.pixels[y * swatch.width + x]);
  }

  Widget _creatorCanvas(TilesetSurfaceSpec spec) {
    final info = _liveInfo(spec);
    if (info == null) return const SizedBox.shrink();
    final cols = _creatorColumns, n = info.size;
    final width = n * cols;
    final cacheKey = Object.hash(info.tile, cols, n);
    if (_creatorSwatchKey != cacheKey) {
      final pixels = Uint32List(width * width);
      for (var y = 0; y < width; y++) {
        for (var x = 0; x < width; x++) {
          pixels[y * width + x] = info.tile[(y % n) * n + x % n];
        }
      }
      _creatorSwatchKey = cacheKey;
      _creatorSwatch = (pixels: pixels, width: width, height: width);
    }
    final swatch = _creatorSwatch!;
    return LayoutBuilder(builder: (context, bounds) {
      _creatorViewportSize = bounds.biggest;
      if (!_creatorCanvasInitialized) {
        _creatorCanvasInitialized = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _fitCreatorCanvas();
        });
      }
      return Focus(
        focusNode: _creatorFocus,
        onKeyEvent: _creatorCanvasKey,
        onFocusChange: (focused) {
          if (!focused && _creatorSpaceDown) _updateDraft(() => _creatorSpaceDown = false);
        },
        child: MouseRegion(
          cursor:
              _creatorSpaceDown || _creatorCanvasTool == 'hand' ? SystemMouseCursors.grab : SystemMouseCursors.precise,
          onHover: (event) {
            final pixel = _creatorPixelAt(event.localPosition, swatch);
            if (_creatorHover != pixel) _updateDraft(() => _creatorHover = pixel);
          },
          onExit: (_) {
            if (_creatorHover != null) _updateDraft(() => _creatorHover = null);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              _creatorFocus.requestFocus();
              if (_creatorSpaceDown) return;
              if (_creatorCanvasTool == 'zoom') {
                _creatorZoomTo(_creatorZoom * (HardwareKeyboard.instance.isAltPressed ? 0.8 : 1.25),
                    anchor: details.localPosition);
              } else if (_creatorCanvasTool == 'pick') {
                final pixel = _creatorPixelAt(details.localPosition, swatch);
                if (pixel != null) _updateDraft(() => _creatorPickedColor = pixel.color);
              }
            },
            child: ValueListenableBuilder<Matrix4>(
              valueListenable: _creatorTransform,
              builder: (context, transform, _) => InteractiveViewer(
                key: ValueKey('creator-preview-$_creatorView'),
                transformationController: _creatorTransform,
                alignment: Alignment.topLeft,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                panEnabled: _creatorSpaceDown || _creatorCanvasTool == 'hand',
                minScale: 0.25,
                maxScale: 64,
                trackpadScrollCausesScale: true,
                child: CustomPaint(
                    size: Size(width.toDouble(), width.toDouble()),
                    painter: _SurfacePreviewPainter(swatch, _tg.checkerA),
                    foregroundPainter: _creatorPixelGrid && transform.getMaxScaleOnAxis() >= 6
                        ? _CreatorPixelGrid(width, transform.getMaxScaleOnAxis())
                        : null),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _creatorCanvasStatus() => ValueListenableBuilder<Matrix4>(
      valueListenable: _creatorTransform,
      builder: (context, transform, _) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              Text('${(transform.getMaxScaleOnAxis() * 100).round()}% · $_size×$_size px',
                  key: const ValueKey('creator-zoom-status'), style: _tg.monoAt(11)),
              const SizedBox(width: 16),
              if (_creatorHover case final pixel?)
                Text('x ${pixel.x}, y ${pixel.y} · ${_creatorHex(pixel.color)}',
                    key: const ValueKey('creator-hover-status'), style: _tg.monoAt(11)),
              if (_creatorPickedColor case final color?)
                TextButton.icon(
                    key: const ValueKey('creator-picked-color'),
                    onPressed: () => Clipboard.setData(ClipboardData(text: _creatorHex(color))),
                    icon: Container(width: 14, height: 14, color: Color(color)),
                    label: Text('Copy ${_creatorHex(color)}', style: _tg.monoAt(11))),
            ]),
          ));

  String _creatorHex(int color) => '#${(color & 0xffffff).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class _CreatorPixelGrid extends CustomPainter {
  const _CreatorPixelGrid(this.pixels, this.scale);
  final int pixels;
  final double scale;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x55000000)
      ..strokeWidth = 1 / scale;
    for (var i = 0; i <= pixels; i++) {
      canvas.drawLine(Offset(i.toDouble(), 0), Offset(i.toDouble(), size.height), paint);
      canvas.drawLine(Offset(0, i.toDouble()), Offset(size.width, i.toDouble()), paint);
    }
  }

  @override
  bool shouldRepaint(_CreatorPixelGrid oldDelegate) => pixels != oldDelegate.pixels || scale != oldDelegate.scale;
}
