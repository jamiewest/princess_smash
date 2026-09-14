import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart' show FontWeight, TextStyle;

import 'palette.dart';

/// Shared bobbing behaviour for anything the princess can pick up.
abstract class Pickup extends PositionComponent {
  Pickup({required Vector2 spawn, required Vector2 boxSize})
    : _baseY = spawn.y,
      super(position: spawn.clone(), size: boxSize);

  final double _baseY;
  double phase = 0;
  bool collected = false;

  @override
  void update(double dt) {
    phase += dt;
    position.y = _baseY + math.sin(phase * 2.6) * 2.6;
  }
}

class Gem extends Pickup {
  Gem({required super.spawn}) : super(boxSize: Vector2(16, 18));

  @override
  void render(Canvas canvas) {
    final spin = (math.sin(phase * 2.2) * 0.5 + 0.5);
    final halfWidth = 1.5 + 6.5 * spin;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    final facet = Path()
      ..moveTo(0, -8.5)
      ..lineTo(halfWidth, -2.5)
      ..lineTo(0, 8.5)
      ..lineTo(-halfWidth, -2.5)
      ..close();
    canvas.drawPath(facet, Paint()..color = Pal.gem);
    canvas.drawPath(
      Path()
        ..moveTo(0, -8.5)
        ..lineTo(halfWidth * 0.45, -2.5)
        ..lineTo(0, 8.5)
        ..lineTo(-halfWidth * 0.15, -2.5)
        ..close(),
      Paint()..color = Pal.gemLight,
    );
    canvas.drawCircle(
      Offset(-halfWidth * 0.3, -4.5),
      1.1,
      Paint()..color = Pal.cloud.withValues(alpha: 0.9),
    );
    canvas.restore();
  }
}

class HeartPickup extends Pickup {
  HeartPickup({required super.spawn}) : super(boxSize: Vector2(18, 16));

  @override
  void render(Canvas canvas) {
    final pulse = 1 + math.sin(phase * 4) * 0.07;
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(pulse);
    canvas.translate(-size.x / 2, -size.y / 2);
    drawHeart(canvas, Rect.fromLTWH(1, 1, size.x - 2, size.y - 2), Pal.heart);
    canvas.drawCircle(
      Offset(size.x * 0.34, size.y * 0.34),
      1.6,
      Paint()..color = Pal.cloud.withValues(alpha: 0.85),
    );
    canvas.restore();
  }
}

/// One letter of the lesson's focus word, floating along the road. Collecting
/// it fills slot [index] of the word tracker in the HUD.
class LetterPickup extends Pickup {
  LetterPickup({
    required super.spawn,
    required this.letter,
    required this.index,
    this.shadow = Pal.dressDark,
  }) : super(boxSize: Vector2(18, 18));

  final String letter;

  /// This letter's position within the focus word.
  final int index;

  /// Drop-shadow under the tile, matched to the hero's outfit.
  final Color shadow;

  static final _glyph = TextPaint(
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      color: Pal.ink,
    ),
  );

  @override
  void render(Canvas canvas) {
    final tilt = math.sin(phase * 2.2) * 0.08;
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate(tilt);

    final tile = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 17, height: 17),
      const Radius.circular(5),
    );
    canvas.drawRRect(tile.shift(const Offset(0, 1.4)), Paint()..color = shadow);
    canvas.drawRRect(tile, Paint()..color = Pal.cloud);
    canvas.drawRRect(
      tile.deflate(0.7),
      Paint()
        ..color = Pal.crown
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    _glyph.render(canvas, letter, Vector2.zero(), anchor: Anchor.center);
    canvas.restore();
  }
}

/// Shared heart shape, used by pickups and the HUD so they stay identical.
void drawHeart(Canvas canvas, Rect rect, Color colour) {
  final w = rect.width;
  final h = rect.height;
  final path = Path()
    ..moveTo(rect.left + w / 2, rect.top + h)
    ..cubicTo(
      rect.left - w * 0.18,
      rect.top + h * 0.52,
      rect.left + w * 0.14,
      rect.top - h * 0.16,
      rect.left + w / 2,
      rect.top + h * 0.28,
    )
    ..cubicTo(
      rect.left + w * 0.86,
      rect.top - h * 0.16,
      rect.left + w * 1.18,
      rect.top + h * 0.52,
      rect.left + w / 2,
      rect.top + h,
    )
    ..close();
  canvas.drawPath(path, Paint()..color = colour);
}
