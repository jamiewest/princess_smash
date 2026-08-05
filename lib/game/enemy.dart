import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'level.dart';
import 'palette.dart';
import 'physics_entity.dart';

enum EnemyKind { walker, hopper }

/// A patrolling baddie. Walkers turn around at walls and at ledges; hoppers do
/// the same but bounce along in little arcs.
///
/// [isDying] flips the instant a stomp is registered so the same enemy can
/// never both get squashed and damage the princess across neighbouring frames.
class Enemy extends PhysicsEntity {
  Enemy({required super.level, required Vector2 spawn, required this.kind})
    : super(position: spawn.clone(), size: Vector2(22, 20));

  static const double _walkSpeed = 42;
  static const double _hopSpeed = 58;
  static const double _hopImpulse = 330;
  static const double _deathDuration = 0.32;

  final EnemyKind kind;

  int direction = -1;
  bool isDying = false;

  double _deathTimer = 0;
  double _wobble = 0;
  double _hopCooldown = 0.6;

  Color get _body => kind == EnemyKind.walker ? Pal.blob : Pal.hopper;
  Color get _shade => kind == EnemyKind.walker ? Pal.blobDark : Pal.hopperDark;

  /// True when [other] came down onto this enemy during the frame just
  /// simulated: it must be moving downward, and its feet must have started the
  /// frame above the enemy's shoulders. Testing the *previous* position rather
  /// than the current one keeps the stomp window from depending on frame rate.
  bool isStompedBy(PhysicsEntity other) =>
      other.velocity.y > 0 && other.previousBottom <= top + 4;

  /// Squash flat, then disappear. Returns immediately; removal is timed.
  void squash() {
    if (isDying) return;
    isDying = true;
    _deathTimer = _deathDuration;
    velocity.setZero();
  }

  @override
  void update(double dt) {
    if (isDying) {
      _deathTimer -= dt;
      if (_deathTimer <= 0) removeFromParent();
      return;
    }

    _wobble += dt;
    switch (kind) {
      case EnemyKind.walker:
        velocity.x = _walkSpeed * direction;
      case EnemyKind.hopper:
        _hopCooldown -= dt;
        if (onGround && _hopCooldown <= 0) {
          velocity.y = -_hopImpulse;
          _hopCooldown = 1.1;
        }
        velocity.x = onGround && _hopCooldown > 0.85
            ? 0
            : _hopSpeed * direction;
    }

    applyGravity(dt);
    moveWithCollisions(dt);

    if (top > level.killPlaneY) {
      removeFromParent();
      return;
    }

    if (hitWall) {
      direction = -direction;
    } else if (onGround && _atLedge()) {
      direction = -direction;
      position.x += direction * 1.5;
    }
  }

  /// True when the tile just beyond the leading foot has nothing to stand on.
  bool _atLedge() {
    final probeX = direction > 0 ? right + 2 : left - 2;
    final col = (probeX / kTileSize).floor();
    final row = ((bottom + 2) / kTileSize).floor();
    return !level.isSolid(col, row);
  }

  @override
  void render(Canvas canvas) {
    final progress = isDying
        ? 1 - (_deathTimer / _deathDuration).clamp(0.0, 1.0)
        : 0.0;
    final squashY = isDying ? 1 - progress * 0.85 : 1.0;
    final squashX = isDying ? 1 + progress * 0.45 : 1.0;
    final alpha = isDying ? (1 - progress * 0.9).clamp(0.0, 1.0) : 1.0;

    canvas.save();
    canvas.translate(size.x / 2, size.y);
    canvas.scale(squashX, squashY);
    canvas.translate(-size.x / 2, -size.y);

    final wobble = isDying ? 0.0 : math.sin(_wobble * 7) * 1.2;
    _renderBlob(canvas, wobble, alpha);
    canvas.restore();
  }

  void _renderBlob(Canvas canvas, double wobble, double alpha) {
    final feet = Paint()..color = _shade.withValues(alpha: alpha);
    canvas.drawOval(Rect.fromLTWH(2, size.y - 5 + wobble.abs(), 7, 5), feet);
    canvas.drawOval(
      Rect.fromLTWH(size.x - 9, size.y - 5 - wobble.abs(), 7, 5),
      feet,
    );

    final body = Path()
      ..moveTo(1.5, size.y - 3)
      ..quadraticBezierTo(-1.5, 6, 6, 2.5)
      ..quadraticBezierTo(11, 0, 16, 2.5)
      ..quadraticBezierTo(23.5, 6, 20.5, size.y - 3)
      ..close();
    canvas.drawPath(body, Paint()..color = _body.withValues(alpha: alpha));
    canvas.drawPath(
      Path()
        ..moveTo(1.5, size.y - 3)
        ..lineTo(20.5, size.y - 3)
        ..lineTo(19.5, size.y - 6.5)
        ..lineTo(2.5, size.y - 6.5)
        ..close(),
      Paint()..color = _shade.withValues(alpha: alpha),
    );

    // A single wiggly antenna, because it reads as friendly rather than scary.
    canvas.drawPath(
      Path()
        ..moveTo(11, 3)
        ..quadraticBezierTo(12 + wobble, -2, 15 + wobble, -3.5),
      Paint()
        ..color = _shade.withValues(alpha: alpha)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(15 + wobble, -3.5),
      1.6,
      Paint()..color = Pal.sparkle.withValues(alpha: alpha),
    );

    _renderFace(canvas, alpha);
  }

  void _renderFace(Canvas canvas, double alpha) {
    final white = Paint()..color = Pal.eyeWhite.withValues(alpha: alpha);
    final dark = Paint()..color = Pal.eyeDark.withValues(alpha: alpha);
    final look = direction * 0.8;

    if (isDying) {
      final stroke = Paint()
        ..color = Pal.eyeDark.withValues(alpha: alpha)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (final cx in const [7.0, 15.0]) {
        canvas.drawLine(Offset(cx - 2, 8), Offset(cx + 2, 12), stroke);
        canvas.drawLine(Offset(cx + 2, 8), Offset(cx - 2, 12), stroke);
      }
      return;
    }

    canvas.drawCircle(const Offset(7, 10), 3.2, white);
    canvas.drawCircle(const Offset(15, 10), 3.2, white);
    canvas.drawCircle(Offset(7 + look, 10.3), 1.7, dark);
    canvas.drawCircle(Offset(15 + look, 10.3), 1.7, dark);
    canvas.drawArc(
      Rect.fromCenter(center: const Offset(11, 14.6), width: 5, height: 3.4),
      0.25,
      2.6,
      false,
      Paint()
        ..color = Pal.eyeDark.withValues(alpha: alpha)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }
}
