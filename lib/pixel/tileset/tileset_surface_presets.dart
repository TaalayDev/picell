part of 'tileset_generator.dart';

/// A starting point for a layered surface, with the palette it was drawn for.
class TilesetSurfacePreset {
  const TilesetSurfacePreset(
      {required this.id, required this.tag, required this.palette, required this.spec, this.pro = false});
  final String id, tag;
  final List<int> palette;
  final TilesetSurfaceSpec spec;
  final bool pro;
  String get name => spec.name;
}

TilesetNoise _noise(TilesetNoiseType type, int scale, double strength, double threshold, int seed) =>
    TilesetNoise(type: type, scale: scale, strength: strength, threshold: threshold, seed: seed);

TilesetLayerColors _colors({int m = 5, int d = 6, int l = 4, int h = 7}) =>
    TilesetLayerColors(mid: m, dark: d, light: l, highlight: h);

abstract final class TilesetSurfacePresets {
  static const _brick = <int>[
    0xff3a1414, 0xff4e7a3a, 0xff8aa84a, 0xffd8c08a, 0xffc86a58, 0xffa8483a, 0xff6a2a24, 0xfff0b8a8 //
  ];
  static const _grass = <int>[
    0xff1f3d24, 0xff3a7a3a, 0xff7cc65c, 0xffe8e060, 0xff6fb850, 0xff4e9a44, 0xff32703a, 0xffbff08a //
  ];
  static const _lava = <int>[
    0xff3a0a05, 0xffff7a1c, 0xffffb02e, 0xfffff2a0, 0xffffb02e, 0xffe8541c, 0xff8a1a0a, 0xffffe066 //
  ];
  static const _ice = <int>[
    0xff2a5a80, 0xff6ab8e0, 0xffa8e4ff, 0xffffffff, 0xffd8f4ff, 0xff9ad8f0, 0xff5aa8d0, 0xffffffff //
  ];
  static const _wood = <int>[
    0xff3a2210, 0xff8a5a2a, 0xffc8964e, 0xffdeb070, 0xffc8964e, 0xffa8743a, 0xff6a4420, 0xffe8c488 //
  ];
  static const _stone = <int>[
    0xff23262e, 0xff5a6070, 0xff8a90a0, 0xffb8c0d0, 0xffa0a8ba, 0xff7b8394, 0xff4a5062, 0xffd8e0ee //
  ];
  static const _water = <int>[
    0xff12306a, 0xff2a6ac0, 0xff6aa8f0, 0xffc8e8ff, 0xff6aa8f0, 0xff3a7bd5, 0xff1f4a9a, 0xffe8f8ff //
  ];
  static const _dirt = <int>[
    0xff2e1a10, 0xff5a3624, 0xff8a5a3a, 0xffc08a5a, 0xffa9764e, 0xff8a5a3a, 0xff5a3624, 0xffd8aa7a //
  ];
  static const _metal = <int>[
    0xff161a24, 0xff5ad0e0, 0xffff8a3a, 0xffc4ccdc, 0xff9aa6bc, 0xff6a7488, 0xff343c4c, 0xffd8f4ff //
  ];
  static const _roof = <int>[
    0xff2a1010, 0xff8a2a24, 0xffd0503a, 0xffe8a078, 0xffd0503a, 0xffa8383a, 0xff6a1e24, 0xfff0b898 //
  ];
  static const _cloth = <int>[
    0xff2a1a40, 0xff8a5aa0, 0xffc88ae0, 0xfff0d0ff, 0xffb080d0, 0xff8a5aa8, 0xff5a3a78, 0xffe8c8ff //
  ];
  static const _road = <int>[
    0xff1a1c22, 0xffe0c040, 0xfff0e090, 0xffffffff, 0xff8a8e98, 0xff686c78, 0xff464a56, 0xffb0b4c0 //
  ];

  static final brick = TilesetSurfacePreset(
      id: 'brick',
      tag: 'Dungeon',
      palette: _brick,
      spec: TilesetSurfaceSpec(name: 'Mossy brick wall', layers: [
        TilesetLayer(pattern: TilesetPattern.bricks, noise: _noise(TilesetNoiseType.speckle, 4, 0.5, 0.5, 3)),
        TilesetLayer(
            pattern: TilesetPattern.cells,
            colors: _colors(m: 2, d: 1, l: 2, h: 3),
            blend: TilesetLayerBlend.dark,
            noise: _noise(TilesetNoiseType.blotch, 5, 0.62, 0.55, 4821)),
        TilesetLayer(
            pattern: TilesetPattern.dots,
            colors: _colors(m: 3, d: 6, l: 3, h: 3),
            blend: TilesetLayerBlend.tint,
            density: 0.5),
        TilesetLayer(
            pattern: TilesetPattern.mesh,
            colors: _colors(d: 0, l: 0, h: 0),
            area: TilesetLayerArea.border,
            density: 0.4,
            visible: false),
      ]));
  static final grass = TilesetSurfacePreset(
      id: 'grass',
      tag: 'Earth',
      palette: _grass,
      spec: TilesetSurfaceSpec(name: 'Meadow grass', layers: [
        TilesetLayer(noise: _noise(TilesetNoiseType.blotch, 5, 0.6, 0.55, 11)),
        TilesetLayer(pattern: TilesetPattern.dots, colors: _colors(d: 6, l: 7)),
        TilesetLayer(pattern: TilesetPattern.waves, colors: _colors(d: 6, l: 4), density: 0.35),
      ]));
  static final lava = TilesetSurfacePreset(
      id: 'lava',
      tag: 'Liquid',
      palette: _lava,
      spec: TilesetSurfaceSpec(name: 'Molten lava', layers: [
        const TilesetLayer(pattern: TilesetPattern.cells),
        TilesetLayer(pattern: TilesetPattern.waves, colors: _colors(d: 5, l: 4), density: 0.7),
        TilesetLayer(pattern: TilesetPattern.dots, colors: _colors(l: 7, d: 7), density: 0.3),
      ]));
  static final ice = TilesetSurfacePreset(
      id: 'ice',
      tag: 'Liquid',
      palette: _ice,
      spec: TilesetSurfaceSpec(name: 'Glacier ice', layers: [
        const TilesetLayer(pattern: TilesetPattern.cells),
        TilesetLayer(pattern: TilesetPattern.mesh, colors: _colors(d: 1, l: 3), density: 0.55),
        TilesetLayer(pattern: TilesetPattern.dots, colors: _colors(l: 3, d: 3), density: 0.25),
      ]));
  static final planks = TilesetSurfacePreset(
      id: 'planks',
      tag: 'Wood',
      palette: _wood,
      spec: TilesetSurfaceSpec(name: 'Oak planks', layers: [
        TilesetLayer(pattern: TilesetPattern.planks, noise: _noise(TilesetNoiseType.streak, 4, 0.6, 0.5, 5)),
        TilesetLayer(pattern: TilesetPattern.dots, colors: _colors(d: 0, l: 0), density: 0.18),
        TilesetLayer(pattern: TilesetPattern.waves, colors: _colors(d: 6, l: 6), density: 0.15),
      ]));
  static final cobble = TilesetSurfacePreset(
      id: 'cobble',
      tag: 'Stone',
      palette: _stone,
      spec: TilesetSurfaceSpec(name: 'Cobblestone', layers: [
        const TilesetLayer(pattern: TilesetPattern.cobble),
        TilesetLayer(pattern: TilesetPattern.dots, colors: _colors(d: 6, l: 7), density: 0.3),
        TilesetLayer(
            pattern: TilesetPattern.cells, colors: _colors(d: 6, l: 4), density: 0.3, blend: TilesetLayerBlend.light),
      ]));
  static final metal = TilesetSurfacePreset(
      id: 'metal',
      tag: 'Tech',
      pro: true,
      palette: _metal,
      spec: TilesetSurfaceSpec(name: 'Hull plates', layers: [
        const TilesetLayer(pattern: TilesetPattern.tiles),
        TilesetLayer(pattern: TilesetPattern.mesh, colors: _colors(d: 6, l: 3), density: 0.35),
        TilesetLayer(pattern: TilesetPattern.dots, colors: _colors(d: 1, l: 2), density: 0.22),
      ]));
  static final roof = TilesetSurfacePreset(
      id: 'roof',
      tag: 'Roof',
      palette: _roof,
      spec: TilesetSurfaceSpec(name: 'Clay roof', layers: [
        const TilesetLayer(pattern: TilesetPattern.scales),
        TilesetLayer(pattern: TilesetPattern.dots, colors: _colors(d: 6, l: 7), density: 0.25),
        TilesetLayer(pattern: TilesetPattern.bricks, colors: _colors(d: 6, l: 4), density: 0.15),
      ]));
  static final cloth = TilesetSurfacePreset(
      id: 'cloth',
      tag: 'Fabric',
      palette: _cloth,
      spec: TilesetSurfaceSpec(name: 'Woven cloth', layers: [
        const TilesetLayer(pattern: TilesetPattern.checker),
        TilesetLayer(pattern: TilesetPattern.mesh, colors: _colors(d: 6, l: 4), density: 0.6),
      ]));
  static final water = TilesetSurfacePreset(
      id: 'water',
      tag: 'Liquid',
      palette: _water,
      spec: TilesetSurfaceSpec(name: 'Shallow water', layers: [
        const TilesetLayer(pattern: TilesetPattern.waves),
        TilesetLayer(pattern: TilesetPattern.dots, colors: _colors(l: 7, d: 7), density: 0.2),
        TilesetLayer(
            pattern: TilesetPattern.cells, colors: _colors(d: 6, l: 4), density: 0.2, blend: TilesetLayerBlend.light),
      ]));
  static final dirt = TilesetSurfacePreset(
      id: 'dirt',
      tag: 'Earth',
      palette: _dirt,
      spec: TilesetSurfaceSpec(name: 'Packed dirt', layers: [
        TilesetLayer(noise: _noise(TilesetNoiseType.blotch, 4, 0.6, 0.5, 2)),
        TilesetLayer(pattern: TilesetPattern.dots, colors: _colors(d: 6, l: 7), density: 0.6),
      ]));
  static final road = TilesetSurfacePreset(
      id: 'road',
      tag: 'Road',
      palette: _road,
      spec: TilesetSurfaceSpec(name: 'Paved road', layers: [
        const TilesetLayer(pattern: TilesetPattern.cobble),
        TilesetLayer(pattern: TilesetPattern.dots, colors: _colors(l: 7, d: 7), density: 0.2),
      ]));

  /// Order of the gallery.
  static final all = <TilesetSurfacePreset>[
    grass, brick, planks, lava, ice, cobble, metal, roof, cloth, water, dirt, road //
  ];

  /// Filter tags shown above the gallery.
  static const tags = ['Earth', 'Stone', 'Wood', 'Liquid', 'Dungeon', 'Tech', 'Roof', 'Fabric', 'Road'];

  static TilesetSurfacePreset byId(String id) => all.firstWhere((p) => p.id == id);
}
