import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../app/theme/pv_tokens.dart';
import '../../../pixel/tileset/tileset_canvas.dart';
import '../../../pixel/tileset/tileset_collection.dart';
import 'tileset_atlas_cache.dart';

/// Theme colors for the workspace, taken from [PvTokens] when present.
class TilesetWorkspaceColors {
  const TilesetWorkspaceColors(
      {required this.background,
      required this.surface,
      required this.surfaceHigh,
      required this.divider,
      required this.text,
      required this.textMuted,
      required this.primary,
      required this.warn,
      required this.checkerA});
  final Color background, surface, surfaceHigh, divider, text, textMuted, primary, warn, checkerA;

  factory TilesetWorkspaceColors.of(BuildContext context) {
    final theme = Theme.of(context), t = theme.extension<PvTokens>(), scheme = theme.colorScheme;
    return TilesetWorkspaceColors(
        background: t?.background ?? scheme.surface,
        surface: t?.surface ?? scheme.surfaceContainer,
        surfaceHigh: t?.surfaceHigh ?? scheme.surfaceContainerHigh,
        divider: t?.divider ?? scheme.outlineVariant,
        text: t?.textPrimary ?? scheme.onSurface,
        textMuted: t?.textSecondary ?? scheme.onSurfaceVariant,
        primary: t?.primary ?? scheme.primary,
        warn: t?.warn ?? scheme.error,
        checkerA: t?.checkerA ?? scheme.surfaceContainerHighest);
  }
}

/// Screen position of a cell: `offset + cell * tileSize * zoom`.
Rect tilesetItemRect(
    TilesetCanvasItem item, ({int width, int height}) cells, int tileSize, Offset offset, double zoom) {
  final cell = tileSize * zoom;
  return Rect.fromLTWH(offset.dx + item.x * cell, offset.dy + item.y * cell, cells.width * cell, cells.height * cell);
}

class TilesetCanvasPainter extends CustomPainter {
  TilesetCanvasPainter(
      {required this.canvas,
      required this.entries,
      required this.tileSize,
      required this.offset,
      required this.zoom,
      required this.selection,
      required this.marquee,
      required this.showGrid,
      required this.colors,
      required this.atlas})
      : super(repaint: atlas);
  final TilesetCanvas canvas;
  final Map<String, TilesetEntry> entries;
  final int tileSize;
  final Offset offset;
  final double zoom;
  final Set<String> selection;
  final Rect? marquee;
  final bool showGrid;
  final TilesetWorkspaceColors colors;
  final TilesetAtlasCache atlas;

  static final _nearest = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  void _grid(Canvas c, Size size) {
    final cell = tileSize * zoom;
    if (!showGrid || cell < 6) return;
    final minor = Paint()
      ..color = colors.divider.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final major = Paint()
      ..color = colors.divider.withValues(alpha: 0.8)
      ..strokeWidth = 1;
    final firstX = (-offset.dx / cell).floor(), lastX = ((size.width - offset.dx) / cell).ceil();
    for (var i = firstX; i <= lastX; i++) {
      final x = (offset.dx + i * cell).roundToDouble() + 0.5;
      c.drawLine(Offset(x, 0), Offset(x, size.height), i % 8 == 0 ? major : minor);
    }
    final firstY = (-offset.dy / cell).floor(), lastY = ((size.height - offset.dy) / cell).ceil();
    for (var i = firstY; i <= lastY; i++) {
      final y = (offset.dy + i * cell).roundToDouble() + 0.5;
      c.drawLine(Offset(0, y), Offset(size.width, y), i % 8 == 0 ? major : minor);
    }
  }

  void _label(Canvas c, String text, Offset at, double maxWidth, Color color) {
    final painter = TextPainter(
        text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr)
      ..layout(maxWidth: math.max(maxWidth, 1));
    painter.paint(c, at);
    painter.dispose();
  }

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.clipRect(Offset.zero & size);
    c.drawRect(Offset.zero & size, Paint()..color = colors.background);
    _grid(c, size);
    for (final item in canvas.items) {
      final cells = tilesetCanvasItemCells(item, entries, tileSize);
      if (cells == null) continue;
      final rect = tilesetItemRect(item, cells, tileSize, offset, zoom);
      if (!rect.inflate(24).overlaps(Offset.zero & size)) continue;
      final entry = entries[item.entryId];
      switch (item.kind) {
        case TilesetCanvasKind.set:
          final image = atlas.imageFor(entry!);
          final px = TilesetAtlasCache.sizeOf(entry);
          final art = Rect.fromLTWH(rect.left, rect.top, px.width * zoom, px.height * zoom);
          c.drawRect(rect, Paint()..color = colors.surface);
          c.drawRect(art, Paint()..color = colors.checkerA);
          if (image != null) {
            c.drawImageRect(image, Rect.fromLTWH(0, 0, px.width.toDouble(), px.height.toDouble()), art, _nearest);
          }
          c.drawRect(
              rect,
              Paint()
                ..style = PaintingStyle.stroke
                ..color = colors.divider);
          _label(c, entry.document.name, rect.topLeft.translate(0, -16), rect.width, colors.textMuted);
        case TilesetCanvasKind.tile:
          final image = atlas.imageFor(entry!);
          final src = TilesetAtlasCache.tileRect(entry, item.tileId!);
          final s = entry.document.settings;
          final art = Rect.fromLTWH(rect.left, rect.top, s.spriteWidth * zoom, s.spriteHeight * zoom);
          c.drawRect(art, Paint()..color = colors.checkerA);
          if (image != null && src != null) c.drawImageRect(image, src, art, _nearest);
        case TilesetCanvasKind.note:
          final r = RRect.fromRectAndRadius(rect, const Radius.circular(8));
          c.drawRRect(r, Paint()..color = colors.surfaceHigh);
          c.drawRRect(
              r,
              Paint()
                ..style = PaintingStyle.stroke
                ..color = colors.divider);
          if (rect.width > 24) {
            final painter = TextPainter(
                text: TextSpan(
                    text: item.text.isEmpty ? 'Note' : item.text,
                    style: TextStyle(
                        color: item.text.isEmpty ? colors.textMuted : colors.text,
                        fontSize: math.max(9, math.min(15, zoom * 7)))),
                textDirection: TextDirection.ltr,
                ellipsis: '…')
              ..layout(maxWidth: math.max(rect.width - 16, 1));
            c.save();
            c.clipRRect(r);
            painter.paint(c, rect.topLeft.translate(8, 8));
            c.restore();
            painter.dispose();
          }
      }
      if (selection.contains(item.id)) {
        c.drawRect(
            rect.inflate(2),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = colors.primary);
      }
    }
    final box = marquee;
    if (box != null) {
      c.drawRect(box, Paint()..color = colors.primary.withValues(alpha: 0.12));
      c.drawRect(
          box,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = colors.primary);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(TilesetCanvasPainter old) =>
      !identical(old.canvas, canvas) ||
      !identical(old.entries, entries) ||
      old.tileSize != tileSize ||
      old.offset != offset ||
      old.zoom != zoom ||
      old.selection != selection ||
      old.marquee != marquee ||
      old.showGrid != showGrid ||
      old.colors != colors;
}

/// Paints one tile or a whole set's first tile into a small thumbnail.
class TilesetThumbPainter extends CustomPainter {
  TilesetThumbPainter(this.atlas, this.entry, this.tileId, this.background) : super(repaint: atlas);
  final TilesetAtlasCache atlas;
  final TilesetEntry entry;
  final String? tileId;
  final Color background;
  @override
  void paint(Canvas c, Size size) {
    c.drawRect(Offset.zero & size, Paint()..color = background);
    final image = atlas.imageFor(entry);
    final id = tileId ?? (entry.document.tiles.isEmpty ? null : entry.document.tiles.first.id);
    final src = id == null ? null : TilesetAtlasCache.tileRect(entry, id);
    if (image == null || src == null) return;
    final scale = math.min(size.width / src.width, size.height / src.height);
    final dst = Rect.fromLTWH((size.width - src.width * scale) / 2, (size.height - src.height * scale) / 2,
        src.width * scale, src.height * scale);
    c.drawImageRect(
        image,
        src,
        dst,
        Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false);
  }

  @override
  bool shouldRepaint(TilesetThumbPainter old) =>
      old.entry != entry || old.tileId != tileId || old.background != background;
}
