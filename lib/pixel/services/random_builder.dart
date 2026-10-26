import 'dart:math';
import 'dart:typed_data';

import '../../data/models/template.dart';

/// Composes compatible built-in parts in their documented layer order.
Template? buildRandomCharacter(List<Template> templates, String category, {Random? random, bool facingLeft = false}) {
  final rng = random ?? Random();
  if (category == 'side-character-builder') return _buildRandomSideCharacter(templates, rng, facingLeft);
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

/// Separate slots and palettes keep near/far limbs and skin tones consistent.
Template? _buildRandomSideCharacter(List<Template> templates, Random rng, bool facingLeft) {
  final slots = <String, Map<String, Template>>{};
  for (final t in templates) {
    if (!t.isAsset || t.category != 'side-character-builder' || t.width != 32 || t.height != 32) continue;
    String? tag(String prefix) => t.tags.where((v) => v.startsWith(prefix)).firstOrNull?.substring(prefix.length);
    final slot = tag('slot:'), variant = tag('variant:');
    if (slot != null && variant != null) slots.putIfAbsent(slot, () => {})[variant] = t;
  }
  String? common(List<String> names) {
    Set<String>? available;
    for (final name in names) {
      final values = slots[name]?.keys.toSet() ?? <String>{};
      available = available == null ? values : available.intersection(values);
    }
    if (available == null || available.isEmpty) return null;
    final sorted = available.toList()..sort();
    return sorted[rng.nextInt(sorted.length)];
  }

  final skin = common(['head', 'neck', 'hand_far', 'hand_near']);
  final outfit = common(['torso', 'upper_arm_far', 'forearm_far', 'upper_arm_near', 'forearm_near']);
  final pants = common(['hips', 'thigh_far', 'shin_far', 'thigh_near', 'shin_near']);
  final boots = common(['foot_far', 'foot_near']);
  if (skin == null || outfit == null || pants == null || boots == null) return null;
  final selected = <Template>[];
  void pick(String slot, String? variant) {
    final t = slots[slot]?[variant];
    if (t != null) selected.add(t);
  }

  void optional(String slot, {bool required = false}) {
    final names = slots[slot]?.keys.toList() ?? [];
    names.sort();
    if (names.isNotEmpty && (required || rng.nextBool())) pick(slot, names[rng.nextInt(names.length)]);
  }

  for (final slot in [
    'upper_arm_far',
    'forearm_far',
    'hand_far',
    'thigh_far',
    'shin_far',
    'foot_far',
    'hips',
    'thigh_near',
    'shin_near',
    'foot_near',
    'torso',
    'neck',
    'head',
    'upper_arm_near',
    'forearm_near',
    'hand_near'
  ]) {
    pick(
        slot,
        slot.startsWith('hand_') || slot == 'head' || slot == 'neck'
            ? skin
            : slot.startsWith('foot_')
                ? boots
                : slot == 'hips' || slot.startsWith('thigh_') || slot.startsWith('shin_')
                    ? pants
                    : outfit);
  }
  optional('hair', required: true);
  optional('hat');
  optional('accessory');
  // Overlays such as hair and hats join their owner, so one layer per bone
  // can be auto-bound when the side-profile skeleton is added.
  final layers = <String, Uint32List>{};
  for (final part in selected) {
    final role = part.tags.where((v) => v.startsWith('rig:')).firstOrNull?.substring(4);
    if (role == null) return null;
    final pixels = layers.putIfAbsent(role, () => Uint32List(1024));
    for (var i = 0; i < pixels.length; i++) {
      if (part.pixels[i] != 0) pixels[i] = part.pixels[i];
    }
  }
  Uint32List facing(Uint32List pixels) => facingLeft
      ? Uint32List.fromList([
          for (var y = 0; y < 32; y++)
            for (var x = 0; x < 32; x++) pixels[y * 32 + 31 - x],
        ])
      : pixels;
  final parts = [
    for (final entry in layers.entries)
      Template(
          name: entry.key,
          category: 'side-character-builder',
          width: 32,
          height: 32,
          pixels: facing(entry.value),
          isLocal: true,
          tags: ['side-profile', facingLeft ? 'facing-left' : 'facing-right', 'rig:${entry.key}'])
  ];
  final pixels = Uint32List(1024);
  for (final part in parts) {
    for (var i = 0; i < 1024; i++) {
      if (part.pixels[i] != 0) pixels[i] = part.pixels[i];
    }
  }
  return Template(
      name: 'Random Side Character · ${facingLeft ? 'Left' : 'Right'}',
      category: 'side-character-builder',
      width: 32,
      height: 32,
      pixels: pixels,
      isLocal: true,
      builderParts: List.unmodifiable(parts),
      tags: ['side-profile', facingLeft ? 'facing-left' : 'facing-right']);
}
