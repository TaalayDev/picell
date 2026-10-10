import 'dart:math';
import 'dart:typed_data';

import '../../data/models/template.dart';

/// Composes compatible built-in parts in their documented layer order.
Template? buildRandomCharacter(List<Template> templates, String category, {Random? random}) {
  final rng = random ?? Random();
  final parts = <String, Template>{
    for (final t in templates)
      if (t.isAsset && t.category == category && t.width == 16 && t.height == 16)
        t.name.split(': ').last.split(' · ').first: t,
  };
  final selected = <Template>[];
  void pick(List<String> names, {bool optional = false}) {
    if (optional && rng.nextBool()) return;
    final available = names.where(parts.containsKey).toList();
    if (available.isNotEmpty) selected.add(parts[available[rng.nextInt(available.length)]]!);
  }

  if (category == 'character-builder') {
    final tone = ['Light', 'Medium', 'Deep'][rng.nextInt(3)];
    pick(['Dark Trousers', 'Brown Trousers', 'Blue Trousers', 'Green Skirt']);
    pick(['Leather Boots', 'Iron Boots', 'Black Shoes']);
    pick(['Head $tone']);
    pick(['Arms $tone']);
    pick(['Green Shirt', 'Blue Shirt', 'Red Shirt', 'Cream Shirt', 'Iron Breastplate']);
    pick(['Calm Face', 'Smiling Face', 'Stern Face']);
    pick([
      for (final style in ['Short', 'Long'])
        for (final color in ['Brown', 'Black', 'Blond', 'Red']) '$style Hair $color',
      'Copper Mohawk'
    ]);
    pick(['Brass Button Vest', 'Detective Coat'], optional: true);
    pick(['Brass Buckle Belt', 'Red Scarf'], optional: true);
    pick(['Detective Fedora', 'Worker Cap', 'Iron Helmet'], optional: true);
    pick(['Round Glasses', 'Brass Goggles'], optional: true);
    pick(['Left Hand Sword', 'Left Hand Lantern'], optional: true);
    pick(['Right Hand Shield', 'Right Hand Fishing Rod'], optional: true);
  } else if (category == 'monster-builder') {
    final tone = ['Moss', 'Ember', 'Night', 'Ice'][rng.nextInt(4)];
    pick(['Bat Wings', 'Feather Wings'], optional: true);
    pick(['Curled Tail', 'Spiked Tail'], optional: true);
    pick(['$tone Feet', 'Taloned Feet', 'Tentacle Feet']);
    pick(['$tone Body', 'Slime Body', 'Furry Body', 'Stone Body', 'Skeleton Body']);
    pick(['$tone Arms', 'Clawed Arms', 'Tentacle Arms']);
    pick(['Golden Belly Patch', 'Scale Markings', 'Purple Spots', 'Monster Armor'], optional: true);
    pick(['Round Eyes', 'Angry Eyes', 'Cyclops Eye', 'Four Eyes']);
    pick(['Fanged Mouth', 'Toothy Grin', 'Monster Beak', 'Long Tongue']);
    pick(['Curved Horns', 'Single Horn', 'Pointed Ears', 'Round Ears', 'Monster Antennae', 'Feather Crest'],
        optional: true);
    pick(['Monster Crown'], optional: true);
  } else {
    return null;
  }
  if (selected.isEmpty) return null;
  final pixels = Uint32List(256);
  for (final part in selected) {
    for (var i = 0; i < pixels.length; i++) {
      if (part.pixels[i] != 0) pixels[i] = part.pixels[i];
    }
  }
  return Template(
      name: category == 'character-builder' ? 'Random Character' : 'Random Monster',
      category: category,
      width: 16,
      height: 16,
      pixels: pixels,
      builderParts: List.unmodifiable(selected),
      isLocal: true);
}
