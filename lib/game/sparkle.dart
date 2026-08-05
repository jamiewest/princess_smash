import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// A short-lived burst of little glowing dots. Hand-rolled rather than using a
/// particle system so the motion, colour and fade stay easy to tune.
class SparkleBurst extends PositionComponent {
  SparkleBurst({
    required Vector2 spawn,
    required this.colour,
    int count = 10,
    this.speed = 90,
    this.lifetime = 0.55,
    this.dotRadius = 2.0,
  }) : super(position: spawn.clone(), priority: 5) {
    final random = math.Random(spawn.x.toInt() * 31 + spawn.y.toInt());
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * math.pi * 2 + random.nextDouble() * 0.4;
      final power = 0.5 + random.nextDouble() * 0.7;
      _dots.add(
        _Dot(
          velocity: Vector2(math.cos(angle), math.sin(angle) - 0.4)
            ..scale(speed * power),
          radius: dotRadius * (0.6 + random.nextDouble() * 0.7),
        ),
      );
    }
  }

  final Color colour;
  final double speed;
  final double lifetime;
  final double dotRadius;

  final List<_Dot> _dots = [];
  double _age = 0;

  @override
  void update(double dt) {
    _age += dt;
    if (_age >= lifetime) {
      removeFromParent();
      return;
    }
    for (final dot in _dots) {
      dot.offset.add(dot.velocity * dt);
      dot.velocity.y += 240 * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = (_age / lifetime).clamp(0.0, 1.0);
    final paint = Paint()..color = colour.withValues(alpha: 1 - progress);
    for (final dot in _dots) {
      canvas.drawCircle(
        Offset(dot.offset.x, dot.offset.y),
        dot.radius * (1 - progress * 0.7),
        paint,
      );
    }
  }
}

class _Dot {
  _Dot({required this.velocity, required this.radius});

  final Vector2 velocity;
  final double radius;
  final Vector2 offset = Vector2.zero();
}
