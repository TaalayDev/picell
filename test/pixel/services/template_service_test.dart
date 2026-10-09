import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/template.dart';

void main() {
  group('Asset Templates Verification', () {
    const templatesDir = 'assets/data/templates';
    late List<String> indexFiles;

    setUpAll(() {
      final indexFile = File('$templatesDir/index.json');
      expect(indexFile.existsSync(), isTrue, reason: 'index.json must exist');
      final content = indexFile.readAsStringSync();
      indexFiles = (json.decode(content) as List<dynamic>).cast<String>();
    });

    test('index.json contains expected count and files exist', () {
      expect(indexFiles.length, greaterThanOrEqualTo(55));

      for (final fileName in indexFiles) {
        final file = File('$templatesDir/$fileName');
        expect(file.existsSync(), isTrue, reason: 'Template file $fileName must exist on disk');
      }
    });

    test('all templates parse into valid Template models with correct pixel lengths', () {
      final templates = <Template>[];

      for (final fileName in indexFiles) {
        final file = File('$templatesDir/$fileName');
        final jsonMap = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
        final template = Template.fromJson(jsonMap);

        expect(template.name.trim().isNotEmpty, isTrue, reason: '$fileName name must not be empty');
        expect(template.category, isNotNull, reason: '$fileName category must not be null');
        expect(template.category!.trim().isNotEmpty, isTrue, reason: '$fileName category must not be empty');
        expect(template.width, greaterThan(0), reason: '$fileName width must be > 0');
        expect(template.height, greaterThan(0), reason: '$fileName height must be > 0');
        expect(
          template.pixels.length,
          equals(template.width * template.height),
          reason: '${template.name} ($fileName) pixel buffer length must match width * height',
        );

        templates.add(template);
      }

      // Check coverage across 8x8, 16x16, 24x24, and 32x32
      final sizes = templates.map((t) => '${t.width}x${t.height}').toSet();
      expect(sizes.contains('8x8'), isTrue, reason: 'Must contain 8x8 templates');
      expect(sizes.contains('16x16'), isTrue, reason: 'Must contain 16x16 templates');
      expect(sizes.contains('24x24'), isTrue, reason: 'Must contain 24x24 templates');
      expect(sizes.contains('32x32'), isTrue, reason: 'Must contain 32x32 templates');

      // Check specific enhanced templates
      final templateNames = templates.map((t) => t.name).toSet();
      expect(templateNames.contains('Ruby Gem'), isTrue);
      expect(templateNames.contains('Mini Potion'), isTrue);
      expect(templateNames.contains('Mini Dagger'), isTrue);
      expect(templateNames.contains('Gold Coin'), isTrue);
      expect(templateNames.contains('Pixel Heart'), isTrue);
      expect(templateNames.contains('Mini Skull'), isTrue);
      expect(templateNames.contains('Mini 1-Up'), isTrue);
      expect(templateNames.contains('Pixel Wizard'), isTrue);
      expect(templateNames.contains('Cyber Samurai'), isTrue);
      expect(templateNames.contains('Magical Campfire'), isTrue);
      expect(templateNames.contains('Golden Chest'), isTrue);
      expect(templateNames.contains('Arcade Gamepad'), isTrue);
      expect(templateNames.contains('Sushi Roll'), isTrue);
      expect(templateNames.contains('Crystal Butterfly'), isTrue);
      expect(templateNames.contains('Battle Mech'), isTrue);
      expect(templateNames.contains('Castle Fortress'), isTrue);
      expect(templateNames.contains('Cyberpunk Skyline'), isTrue);
      expect(templateNames.contains('Cozy Cafe Window'), isTrue);
      expect(templateNames.contains('Dragon Boss'), isTrue);
      expect(templateNames.contains('Starfighter'), isTrue);
      expect(templateNames.contains('Paladin Knight'), isTrue);
      expect(templateNames.contains('Cyber Hacker'), isTrue);
      expect(templateNames.contains('Floating Island'), isTrue);
      expect(templateNames.contains('Arcade Cabinet'), isTrue);
      expect(templateNames.contains('Mystic Cauldron'), isTrue);
      expect(templateNames.contains('Phoenix Bird'), isTrue);

      final templates32 = templates.where((t) => t.width == 32 && t.height == 32).toList();
      expect(templates32.length, greaterThanOrEqualTo(8));
    });

    test('templates have valid non-zero content', () {
      for (final fileName in indexFiles) {
        final file = File('$templatesDir/$fileName');
        final jsonMap = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
        final template = Template.fromJson(jsonMap);

        final nonZeroPixels = template.pixels.where((p) => p != 0).length;
        expect(
          nonZeroPixels,
          greaterThan(0),
          reason: '${template.name} should have visible colored pixels',
        );
      }
    });
  });
}
