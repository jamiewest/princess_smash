import 'dart:ui';

import 'appearance.dart';
import 'palette.dart';

/// Paints the hero into a 20 x 30 box with the origin at the top-left.
///
/// Shared by the in-game [Princess] component and the hero maker's live
/// preview, so what you dress up is exactly what you play.
void paintHero(
  Canvas canvas,
  HeroAppearance look, {
  double bob = 0,
  bool blinking = false,
}) {
  canvas.save();
  canvas.translate(0, bob);

  _paintOutfit(canvas, look);
  _paintArms(canvas, look);
  _paintHairBehind(canvas, look);
  _paintFaceBase(canvas, look);
  _paintFringe(canvas, look);
  _paintFace(canvas, look, blinking);
  _paintCrown(canvas);

  canvas.restore();
}

void _paintOutfit(Canvas canvas, HeroAppearance look) {
  final outfit = Paint()..color = look.outfit;
  final outfitDark = Paint()..color = look.outfitDark;

  switch (look.outfitStyle) {
    case OutfitStyle.dress:
      // A soft bell from waist to feet, with a darker hem.
      final dress = Path()
        ..moveTo(6.5, 15)
        ..lineTo(13.5, 15)
        ..quadraticBezierTo(19.5, 24, 18, 29.5)
        ..lineTo(2, 29.5)
        ..quadraticBezierTo(0.5, 24, 6.5, 15)
        ..close();
      canvas.drawPath(dress, outfit);
      canvas.drawPath(
        Path()
          ..moveTo(2, 29.5)
          ..lineTo(18, 29.5)
          ..lineTo(17.2, 26.5)
          ..lineTo(2.8, 26.5)
          ..close(),
        outfitDark,
      );
    case OutfitStyle.tunic:
      final legs = Paint()..color = look.skinShade;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(6.2, 23.5, 3.2, 5),
          const Radius.circular(1.4),
        ),
        legs,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(10.6, 23.5, 3.2, 5),
          const Radius.circular(1.4),
        ),
        legs,
      );
      final shoes = Paint()..color = look.hairDark;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(5.8, 28, 4, 1.7),
          const Radius.circular(0.9),
        ),
        shoes,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(10.2, 28, 4, 1.7),
          const Radius.circular(0.9),
        ),
        shoes,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(5.4, 19.5, 9.2, 5),
          const Radius.circular(2),
        ),
        outfitDark,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(5, 14.5, 10, 7.5),
          const Radius.circular(3),
        ),
        outfit,
      );
  }
}

void _paintArms(Canvas canvas, HeroAppearance look) {
  final arm = Paint()..color = look.skinShade;
  canvas.drawCircle(const Offset(4, 17), 2.4, arm);
  canvas.drawCircle(const Offset(16, 17), 2.4, arm);
}

void _paintHairBehind(Canvas canvas, HeroAppearance look) {
  final hair = Paint()..color = look.hair;
  final long = look.hairLength == HairLength.long;

  canvas.drawCircle(const Offset(10, 9.5), 8.4, hair);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      long
          ? const Rect.fromLTWH(1.8, 8, 16.4, 12)
          : const Rect.fromLTWH(2.6, 8, 14.8, 7),
      const Radius.circular(6),
    ),
    hair,
  );

  switch (look.hairTexture) {
    case HairTexture.curly:
      // Round puffs along the crown, plus more down the sides when long.
      final puffs = <Offset>[
        const Offset(3.2, 5.6),
        const Offset(6.2, 2.8),
        const Offset(10, 1.8),
        const Offset(13.8, 2.8),
        const Offset(16.8, 5.6),
        const Offset(2.6, 12),
        const Offset(17.4, 12),
        if (long) const Offset(3, 18),
        if (long) const Offset(17, 18),
      ];
      for (final puff in puffs) {
        canvas.drawCircle(puff, 2.5, hair);
      }
    case HairTexture.wavy:
      // Gentle bumps on the crown and scallops along the bottom edge.
      canvas.drawCircle(const Offset(5.2, 3.8), 3, hair);
      canvas.drawCircle(const Offset(10, 2.6), 3.2, hair);
      canvas.drawCircle(const Offset(14.8, 3.8), 3, hair);
      final hem = long ? 19.5 : 14.5;
      canvas.drawCircle(Offset(3.6, hem), 2.2, hair);
      canvas.drawCircle(Offset(7, hem + 1), 2.2, hair);
      canvas.drawCircle(Offset(13, hem + 1), 2.2, hair);
      canvas.drawCircle(Offset(16.4, hem), 2.2, hair);
    case HairTexture.straight:
      // A smooth cap; the rounded base shapes already read as sleek hair.
      break;
  }
}

void _paintFaceBase(Canvas canvas, HeroAppearance look) {
  canvas.drawCircle(const Offset(10, 9.8), 6.8, Paint()..color = look.skin);
}

void _paintFringe(Canvas canvas, HeroAppearance look) {
  final fringe = Paint()..color = look.hairDark;
  switch (look.hairTexture) {
    case HairTexture.curly:
      // A scalloped row of little coils across the forehead.
      for (final coil in const [
        Offset(4.4, 6.6),
        Offset(7.2, 5.4),
        Offset(10, 5),
        Offset(12.8, 5.4),
        Offset(15.6, 6.6),
      ]) {
        canvas.drawCircle(coil, 2.1, fringe);
      }
    case HairTexture.wavy:
      for (final wave in const [
        Offset(5.4, 6.2),
        Offset(10, 5.2),
        Offset(14.6, 6.2),
      ]) {
        canvas.drawCircle(wave, 2.5, fringe);
      }
    case HairTexture.straight:
      // A straight-cut bang with a flat lower edge.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(3.8, 3.6, 12.4, 3.4),
          const Radius.circular(1.6),
        ),
        fringe,
      );
  }
}

void _paintFace(Canvas canvas, HeroAppearance look, bool blinking) {
  if (blinking) {
    final lid = Paint()
      ..color = Pal.eyeDark
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(6.4, 10.4), const Offset(8.6, 10.4), lid);
    canvas.drawLine(const Offset(11.4, 10.4), const Offset(13.6, 10.4), lid);
  } else {
    final iris = Paint()..color = look.eyes;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(7.5, 10.3), width: 2.8, height: 3.6),
      iris,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(12.5, 10.3),
        width: 2.8,
        height: 3.6,
      ),
      iris,
    );
    final glint = Paint()..color = Pal.eyeWhite;
    canvas.drawCircle(const Offset(8.2, 9.4), 0.8, glint);
    canvas.drawCircle(const Offset(13.2, 9.4), 0.8, glint);
  }

  final cheeks = Paint()..color = look.outfitDark.withValues(alpha: 0.6);
  canvas.drawCircle(const Offset(5.6, 12.6), 1.5, cheeks);
  canvas.drawCircle(const Offset(14.4, 12.6), 1.5, cheeks);

  canvas.drawArc(
    Rect.fromCenter(center: const Offset(10, 12.4), width: 4, height: 3),
    0.2,
    2.7,
    false,
    Paint()
      ..color = Pal.eyeDark
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke,
  );
}

void _paintCrown(Canvas canvas) {
  final gold = Paint()..color = Pal.crown;
  final crown = Path()
    ..moveTo(5.6, 3.4)
    ..lineTo(7.2, 0.6)
    ..lineTo(8.8, 3.0)
    ..lineTo(10, 0.2)
    ..lineTo(11.2, 3.0)
    ..lineTo(12.8, 0.6)
    ..lineTo(14.4, 3.4)
    ..close();
  canvas.drawPath(crown, gold);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(5.4, 3.0, 9.2, 2.0),
      const Radius.circular(1),
    ),
    gold,
  );
  canvas.drawCircle(const Offset(10, 2.6), 1.1, Paint()..color = Pal.crownGem);
}
