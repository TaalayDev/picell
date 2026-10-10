import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/template.dart';
import 'package:picell/pixel/services/random_builder.dart';

void main() {
  final templates = Directory('assets/data/templates')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.contains('_builder_') && f.path.endsWith('.json'))
      .map((f) => Template.fromJson(jsonDecode(f.readAsStringSync())).copyWith(isAsset: true))
      .toList();
  for (final category in ['character-builder', 'monster-builder']) {
    test('$category produces varied, valid composites from real parts', () {
      final results = <String>{};
      final sourcePixels = templates.where((t) => t.category == category).expand((t) => t.pixels).toSet();
      for (var seed = 0; seed < 50; seed++) {
        final result = buildRandomCharacter(templates, category, random: Random(seed))!;
        expect(result.width, 16);
        expect(result.height, 16);
        expect(result.pixels.length, 256);
        expect(result.pixels.where((p) => p != 0).length, greaterThan(30));
        expect(result.pixels.every(sourcePixels.contains), isTrue);
        expect(result.isLocal, isTrue);
        expect(result.builderParts.length, greaterThan(4));
        final composed = List<int>.filled(256, 0);
        for (final part in result.builderParts) {
          for (var i = 0; i < 256; i++) {
            if (part.pixels[i] != 0) composed[i] = part.pixels[i];
          }
        }
        expect(composed, result.pixels);
        results.add(result.pixels.join(','));
      }
      expect(results.length, greaterThan(40));
    });
  }
  test('missing parts or unsupported categories cannot create a blank template', () {
    expect(buildRandomCharacter([], 'character-builder'), isNull);
    expect(buildRandomCharacter(templates, 'objects'), isNull);
  });
}
