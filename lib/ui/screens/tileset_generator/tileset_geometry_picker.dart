import 'package:flutter/material.dart';
import '../../../pixel/tileset/tileset_collection.dart';
import '../../../pixel/tileset/tileset_generator.dart';

/// Picks the project-wide perspective and tile size. Neither has a default:
/// the project cannot be created until both are chosen.
class TilesetGeometryPicker extends StatelessWidget {
  const TilesetGeometryPicker(
      {super.key, required this.perspective, required this.size, required this.onPerspective, required this.onSize});
  final TilesetPerspective? perspective;
  final int? size;
  final ValueChanged<TilesetPerspective> onPerspective;
  final ValueChanged<int> onSize;

  static const _icons = {
    TilesetPerspective.side: Icons.terrain,
    TilesetPerspective.topDown: Icons.grid_4x4,
    TilesetPerspective.isometric: Icons.view_in_ar_outlined,
  };
  static const _hints = {
    TilesetPerspective.side: 'Platformers and side-scrollers',
    TilesetPerspective.topDown: 'RPGs and strategy maps',
    TilesetPerspective.isometric: '2:1 diamond grid with raised faces',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text('Perspective', style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final value in TilesetPerspective.values)
          SizedBox(
              width: 150,
              child: Semantics(
                  button: true,
                  selected: perspective == value,
                  child: Card(
                      key: ValueKey('tileset-perspective-${value.id}'),
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color:
                                  perspective == value ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                              width: perspective == value ? 2 : 1)),
                      child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onPerspective(value),
                          child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Icon(_icons[value], color: perspective == value ? theme.colorScheme.primary : null),
                                const SizedBox(height: 8),
                                Text(value.label, style: theme.textTheme.titleSmall),
                                Text(_hints[value]!, style: theme.textTheme.bodySmall),
                              ])))))),
      ]),
      const SizedBox(height: 16),
      Text('Tile size', style: theme.textTheme.titleSmall),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        for (final value in tilesetTileSizes)
          ChoiceChip(
              key: ValueKey('tileset-size-$value'),
              label: Text('${value}px'),
              selected: size == value,
              onSelected: (_) => onSize(value)),
      ]),
      if (perspective == TilesetPerspective.isometric)
        const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Size is the logical diamond height. Sprite width is twice this value.')),
      const SizedBox(height: 8),
      Text('Every tileset in this project uses these values.', style: theme.textTheme.bodySmall),
    ]);
  }
}

/// Asks for the geometry before a tileset project exists. Returns null on cancel.
Future<TilesetGeometry?> showTilesetGeometryDialog(BuildContext context,
    {String title = 'New tileset project', String confirm = 'Create', TilesetGeometry? initial}) {
  TilesetPerspective? perspective = initial?.perspective;
  int? size = initial?.size;
  return showDialog<TilesetGeometry>(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
                title: Text(title),
                content: SingleChildScrollView(
                    child: TilesetGeometryPicker(
                        perspective: perspective,
                        size: size,
                        onPerspective: (value) => setState(() => perspective = value),
                        onSize: (value) => setState(() => size = value))),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  FilledButton(
                      onPressed: perspective == null || size == null
                          ? null
                          : () => Navigator.pop(context, (perspective: perspective!, size: size!)),
                      child: Text(confirm)),
                ],
              )));
}
