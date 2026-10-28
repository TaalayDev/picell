import 'tileset_generator.dart';

/// Set-level settings. Generated documents keep their actual pixel geometry
/// until the user explicitly regenerates with this configuration.
class TilesetConfiguration {
  TilesetConfiguration(
      {this.name = 'Ground tileset',
      this.perspective = TilesetPerspective.side,
      this.size = 16,
      this.seed = 48213,
      this.material = 'Grass & Dirt',
      List<int>? palette})
      : palette = List.unmodifiable(palette ?? materialPalettes[material] ?? materialPalettes.values.first) {
    if (![16, 32, 48].contains(size) || seed < 0 || seed > 0x7fffffff || this.palette.length != 8) {
      throw ArgumentError('Invalid tileset configuration');
    }
  }
  final String name, material;
  final TilesetPerspective perspective;
  final int size, seed;
  final List<int> palette;
  factory TilesetConfiguration.fromDocument(TilesetDocument d) => TilesetConfiguration(
      name: d.name,
      perspective: d.settings.perspective,
      size: d.settings.size,
      seed: d.settings.seed,
      material: d.settings.material,
      palette: d.settings.palette);
  TilesetConfiguration copyWith(
          {String? name,
          TilesetPerspective? perspective,
          int? size,
          int? seed,
          String? material,
          List<int>? palette}) =>
      TilesetConfiguration(
          name: name ?? this.name,
          perspective: perspective ?? this.perspective,
          size: size ?? this.size,
          seed: seed ?? this.seed,
          material: material ?? this.material,
          palette: palette ?? this.palette);
  Map<String, dynamic> toJson() => {
        'name': name,
        'perspective': perspective.id,
        'size': size,
        'seed': seed,
        'material': material,
        'palette': palette
      };
  factory TilesetConfiguration.fromJson(Map<String, dynamic> json) => TilesetConfiguration(
      name: json['name'] as String,
      perspective: TilesetPerspective.parse(json['perspective'] as String),
      size: json['size'] as int,
      seed: json['seed'] as int,
      material: json['material'] as String,
      palette: (json['palette'] as List).cast<int>());
}
