import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('CellularDungeonEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = CellularDungeonEffect();
      expect(effect.type, equals(EffectType.cellularDungeon));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['dungeonType'], equals('stoneDungeon'));
      expect(effect.parameters['roomCount'], equals(5));
      expect(effect.parameters['corridorWidth'], equals(3));
      expect(effect.parameters['wallPalette'], equals('granite'));
      expect(effect.parameters['torchPlacement'], isTrue);
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = CellularDungeonEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'dungeonType' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'roomCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'corridorWidth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'wallPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'torchPlacement' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes CellularDungeonEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.cellularDungeon,
        {
          'dungeonType': 'organicCave',
          'roomCount': 8,
          'wallPalette': 'obsidian',
        },
      );
      expect(effect, isA<CellularDungeonEffect>());
      expect(effect.parameters['dungeonType'], equals('organicCave'));
      expect(effect.parameters['roomCount'], equals(8));
      expect(effect.parameters['wallPalette'], equals('obsidian'));
    });

    test('renders procedural stone dungeon layout over canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF000000;
      }

      final effect = CellularDungeonEffect({
        'dungeonType': 'stoneDungeon',
        'roomCount': 5,
        'wallPalette': 'granite',
        'torchPlacement': true,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0xFF000000) {
          nonZeroPixels++;
        }
      }
      expect(nonZeroPixels, greaterThan(0));
    });

    test('generates organic cave with cellular automata', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect = CellularDungeonEffect({
        'dungeonType': 'organicCave',
        'wallPalette': 'obsidian',
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) {
          nonZeroPixels++;
        }
      }
      expect(nonZeroPixels, greaterThan(0));
    });

    test('generates crypt catacombs with pillars', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect = CellularDungeonEffect({
        'dungeonType': 'cryptCatacombs',
        'wallPalette': 'mossy',
        'torchPlacement': true,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) {
          nonZeroPixels++;
        }
      }
      expect(nonZeroPixels, greaterThan(0));
    });

    test('time animation animates torch flickers', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect1 = CellularDungeonEffect({
        'torchPlacement': true,
        'time': 0.1,
        'preserveAlpha': false,
      });
      final effect2 = CellularDungeonEffect({
        'torchPlacement': true,
        'time': 0.6,
        'preserveAlpha': false,
      });

      final out1 = effect1.apply(pixels, width, height);
      final out2 = effect2.apply(pixels, width, height);

      bool differenceDetected = false;
      for (int i = 0; i < pixels.length; i++) {
        if (out1[i] != out2[i]) {
          differenceDetected = true;
          break;
        }
      }
      expect(differenceDetected, isTrue);
    });
  });
}
