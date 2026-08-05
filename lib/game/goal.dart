import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'level.dart';
import 'palette.dart';

/// Home: the little cottage the princess is trying to reach. It leans and
/// glows a bit harder as she gets close, so the goal reads from a distance.
class HomeDoor extends PositionComponent {
  HomeDoor({required Vector2 spawn})
    : super(position: spawn.clone(), size: Vector2(kTileSize, kTileSize * 2)) {
    position.y -= kTileSize;
  }

  double _time = 0;
  double excitement = 0;

  @override
  void update(double dt) {
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    final glow = 0.25 + excitement * 0.55;
    canvas.drawCircle(
      Offset(size.x / 2, size.y * 0.55),
      26 + math.sin(_time * 3) * 2.5,
      Paint()..color = Pal.sparkle.withValues(alpha: glow * 0.5),
    );

    final wall = Rect.fromLTWH(0, size.y * 0.32, size.x, size.y * 0.68);
    canvas.drawRRect(
      RRect.fromRectAndRadius(wall, const Radius.circular(3)),
      Paint()..color = Pal.door,
    );

    final roof = Path()
      ..moveTo(-6, size.y * 0.34)
      ..lineTo(size.x / 2, size.y * 0.02)
      ..lineTo(size.x + 6, size.y * 0.34)
      ..close();
    canvas.drawPath(roof, Paint()..color = Pal.roof);

    final doorway = RRect.fromRectAndCorners(
      Rect.fromLTWH(size.x * 0.24, size.y * 0.55, size.x * 0.52, size.y * 0.45),
      topLeft: const Radius.circular(7),
      topRight: const Radius.circular(7),
    );
    canvas.drawRRect(doorway, Paint()..color = Pal.doorDark);
    canvas.drawCircle(
      Offset(size.x * 0.66, size.y * 0.79),
      1.4,
      Paint()..color = Pal.crown,
    );

    // Warm window light that brightens on approach.
    canvas.drawCircle(
      Offset(size.x * 0.5, size.y * 0.44),
      3.4,
      Paint()..color = Pal.crown.withValues(alpha: 0.55 + excitement * 0.45),
    );
  }
}
