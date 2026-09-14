import 'package:flutter/material.dart';

import 'palette.dart';

/// How the hero's hair is drawn: tight coils, soft waves, or a smooth cut.
enum HairTexture { curly, wavy, straight }

/// Whether the hair falls past the shoulders or stops at the chin.
enum HairLength { long, short }

/// What the hero wears: a bell dress or a tunic with shorts.
enum OutfitStyle { dress, tunic }

/// Drives the royal title and the pronouns used in the story text.
enum HeroGender { girl, boy, kid }

extension HeroGenderWords on HeroGender {
  /// The royal title shown in story text, e.g. "Princess Emery".
  String get title => switch (this) {
    HeroGender.girl => 'Princess',
    HeroGender.boy => 'Prince',
    HeroGender.kid => 'Royal',
  };

  String get subject => switch (this) {
    HeroGender.girl => 'she',
    HeroGender.boy => 'he',
    HeroGender.kid => 'they',
  };

  String get subjectCap => switch (this) {
    HeroGender.girl => 'She',
    HeroGender.boy => 'He',
    HeroGender.kid => 'They',
  };

  String get object => switch (this) {
    HeroGender.girl => 'her',
    HeroGender.boy => 'him',
    HeroGender.kid => 'them',
  };

  String get possessive => switch (this) {
    HeroGender.girl => 'her',
    HeroGender.boy => 'his',
    HeroGender.kid => 'their',
  };
}

/// Everything configurable about how the hero looks and is spoken about.
///
/// Immutable; use [copyWith] to change one attribute at a time. The shaded
/// companion colours ([skinShade], [hairDark], [outfitDark]) are derived, so
/// picking any base colour keeps the character's soft two-tone look.
@immutable
class HeroAppearance {
  const HeroAppearance({
    required this.name,
    required this.gender,
    required this.skin,
    required this.hair,
    required this.eyes,
    required this.outfit,
    required this.hairTexture,
    required this.hairLength,
    required this.outfitStyle,
  });

  /// The default hero: Princess Emery, matching the original game art.
  static const emery = HeroAppearance(
    name: 'Emery',
    gender: HeroGender.girl,
    skin: Pal.skin,
    hair: Pal.hair,
    eyes: Pal.eyeDark,
    outfit: Pal.dress,
    hairTexture: HairTexture.curly,
    hairLength: HairLength.long,
    outfitStyle: OutfitStyle.dress,
  );

  /// The prince variation: Milo, Emery's twin — same skin, curls and crown,
  /// in a cornflower-blue tunic that re-dyes the whole world to match.
  static const milo = HeroAppearance(
    name: 'Milo',
    gender: HeroGender.boy,
    skin: Pal.skin,
    hair: Pal.hair,
    eyes: Pal.eyeDark,
    outfit: Color(0xFF9ECBFF),
    hairTexture: HairTexture.curly,
    hairLength: HairLength.short,
    outfitStyle: OutfitStyle.tunic,
  );

  final String name;
  final HeroGender gender;
  final Color skin;
  final Color hair;
  final Color eyes;
  final Color outfit;
  final HairTexture hairTexture;
  final HairLength hairLength;
  final OutfitStyle outfitStyle;

  Color get skinShade => _darken(skin, 0.07);
  Color get hairDark => _darken(hair, 0.08);
  Color get outfitDark => _darken(outfit, 0.10);

  /// Floating platforms, dyed a lighter tint of the outfit. With Emery's pink
  /// dress this lands on the game's original platform colour.
  Color get platform => _lighten(outfit, 0.08);
  Color get platformEdge => outfit;

  /// The cottage roof flies the hero's colour, like a flag for whoever is
  /// coming home.
  Color get roof => outfit;

  /// "Princess Emery", "Prince Theo", "Royal Sam".
  String get titledName => '${gender.title} $name';

  HeroAppearance copyWith({
    String? name,
    HeroGender? gender,
    Color? skin,
    Color? hair,
    Color? eyes,
    Color? outfit,
    HairTexture? hairTexture,
    HairLength? hairLength,
    OutfitStyle? outfitStyle,
  }) {
    return HeroAppearance(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      skin: skin ?? this.skin,
      hair: hair ?? this.hair,
      eyes: eyes ?? this.eyes,
      outfit: outfit ?? this.outfit,
      hairTexture: hairTexture ?? this.hairTexture,
      hairLength: hairLength ?? this.hairLength,
      outfitStyle: outfitStyle ?? this.outfitStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HeroAppearance &&
      other.name == name &&
      other.gender == gender &&
      other.skin == skin &&
      other.hair == hair &&
      other.eyes == eyes &&
      other.outfit == outfit &&
      other.hairTexture == hairTexture &&
      other.hairLength == hairLength &&
      other.outfitStyle == outfitStyle;

  @override
  int get hashCode => Object.hash(
    name,
    gender,
    skin,
    hair,
    eyes,
    outfit,
    hairTexture,
    hairLength,
    outfitStyle,
  );

  static Color _darken(Color colour, double amount) {
    final hsl = HSLColor.fromColor(colour);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  static Color _lighten(Color colour, double amount) {
    final hsl = HSLColor.fromColor(colour);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}

/// Swatch choices offered by the hero maker. All stay soft and pastel so any
/// combination sits comfortably in the storybook world.
class HeroChoices {
  const HeroChoices._();

  static const skins = <Color>[
    Color(0xFF8D5A3B),
    Color(0xFFA9713F),
    Color(0xFFC98F66),
    Color(0xFFDBA97E),
    Color(0xFFEDC39B),
    Color(0xFFF7DDC0),
  ];

  static const hairs = <Color>[
    Color(0xFF2E2231),
    Color(0xFF523726),
    Color(0xFF6B4A38),
    Color(0xFFA5682E),
    Color(0xFFE3B24C),
    Color(0xFFD96F30),
    Color(0xFFE0E4EC),
    Color(0xFFF48FB1),
    Color(0xFF8E7CC3),
  ];

  static const eyeColors = <Color>[
    Color(0xFF453056),
    Color(0xFF5B3A21),
    Color(0xFF2F6B4F),
    Color(0xFF2E5E9E),
    Color(0xFF6D6F74),
    Color(0xFF7B4FA0),
  ];

  static const outfits = <Color>[
    Color(0xFFFF9EC4),
    Color(0xFF9ECBFF),
    Color(0xFFA5E6B8),
    Color(0xFFC9B3F5),
    Color(0xFFFFD480),
    Color(0xFFFF9A8C),
  ];
}

/// The hero look used for the next run. The hero maker writes to this and the
/// game screen reads it when it builds the level.
final ValueNotifier<HeroAppearance> heroAppearance = ValueNotifier(
  HeroAppearance.emery,
);
