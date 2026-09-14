import 'package:flutter/painting.dart' show Color, HSLColor;
import 'package:flutter_test/flutter_test.dart';
import 'package:princess_smash/game/appearance.dart';
import 'package:princess_smash/game/palette.dart';

/// Channel-wise closeness, loose enough to absorb HSL round-tripping.
void expectClose(Color actual, Color expected) {
  const tolerance = 3 / 255;
  expect((actual.r - expected.r).abs(), lessThanOrEqualTo(tolerance));
  expect((actual.g - expected.g).abs(), lessThanOrEqualTo(tolerance));
  expect((actual.b - expected.b).abs(), lessThanOrEqualTo(tolerance));
}

void main() {
  group('matching world colours', () {
    test("Emery's derived colours land on the original pinks", () {
      expectClose(HeroAppearance.emery.platform, Pal.platform);
      expect(HeroAppearance.emery.platformEdge, Pal.platformEdge);
      expect(HeroAppearance.emery.roof, Pal.roof);
    });

    test('world colours follow the outfit colour', () {
      const blue = Color(0xFF9ECBFF);
      final look = HeroAppearance.emery.copyWith(outfit: blue);
      expect(look.platformEdge, blue);
      expect(look.roof, blue);
      // The platform tint keeps the outfit hue but sits lighter.
      final outfitLightness = HSLColor.fromColor(blue).lightness;
      final platformHsl = HSLColor.fromColor(look.platform);
      expect(platformHsl.hue, closeTo(HSLColor.fromColor(blue).hue, 1));
      expect(platformHsl.lightness, greaterThan(outfitLightness));
    });
  });

  group('the prince variation', () {
    test('Milo is the blue-tunic twin of Emery', () {
      const milo = HeroAppearance.milo;
      const emery = HeroAppearance.emery;
      expect(milo.gender, HeroGender.boy);
      expect(milo.titledName, 'Prince Milo');
      expect(milo.outfitStyle, OutfitStyle.tunic);
      // A twin: same skin, hair and eyes, different outfit colour.
      expect(milo.skin, emery.skin);
      expect(milo.hair, emery.hair);
      expect(milo.eyes, emery.eyes);
      expect(milo.outfit, isNot(emery.outfit));
    });

    test('his pronouns drive the story text', () {
      expect(HeroAppearance.milo.gender.subject, 'he');
      expect(HeroAppearance.milo.gender.object, 'him');
      expect(HeroAppearance.milo.gender.possessive, 'his');
    });
  });

  group('appearance equality', () {
    test('value equality survives copyWith round trips', () {
      expect(HeroAppearance.emery.copyWith(), HeroAppearance.emery);
      expect(
        HeroAppearance.emery.copyWith(name: 'Milo'),
        isNot(HeroAppearance.emery),
      );
      expect(HeroAppearance.milo.copyWith(), HeroAppearance.milo);
    });
  });
}
