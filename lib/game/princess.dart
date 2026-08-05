import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'palette.dart';
import 'physics_entity.dart';

/// The player. Handles run/jump feel (acceleration, coyote time, jump
/// buffering, variable jump height) plus the squash-and-stretch that carries
/// most of the game's charm.
class Princess extends PhysicsEntity {
  Princess({required super.level, required Vector2 spawn})
    : super(position: spawn.clone(), size: Vector2(20, 30));

  static const double _maxRunSpeed = 190;
  static const double _acceleration = 1250;
  static const double _groundFriction = 1500;
  static const double _airFriction = 420;
  static const double _jumpSpeed = 500;
  static const double _jumpCutFactor = 0.42;
  static const double _coyoteTime = 0.11;
  static const double _jumpBufferTime = 0.14;
  static const double _invulnerableTime = 1.4;

  /// Bounce applied after squashing an enemy; higher while jump is held.
  static const double _stompBounce = 380;
  static const double _stompBounceHeld = 540;

  /// -1, 0 or 1, driven by the game's keyboard state.
  double moveInput = 0;
  bool jumpHeld = false;

  int facing = 1;
  bool isAlive = true;
  double invulnerable = 0;

  double _coyote = 0;
  double _jumpBuffer = 0;
  bool _jumpConsumed = true;

  double _squash = 1;
  double _squashVelocity = 0;
  double _walkPhase = 0;
  double _blinkTimer = 2;
  bool _wasOnGround = true;

  bool get isInvulnerable => invulnerable > 0;

  /// Queues a jump. Buffered so a press just before landing still fires.
  void requestJump() {
    _jumpBuffer = _jumpBufferTime;
    _jumpConsumed = false;
  }

  void releaseJump() {
    jumpHeld = false;
    if (velocity.y < 0) {
      velocity.y *= _jumpCutFactor;
    }
  }

  /// Puts her back on her feet at the last safe spot she stood on.
  void respawn(Vector2 at) {
    position.setFrom(at);
    velocity.setZero();
    isAlive = true;
    invulnerable = _invulnerableTime;
    _squash = 1;
    _squashVelocity = 0;
  }

  /// Called when an enemy is squashed underfoot.
  void bounce() {
    velocity.y = jumpHeld ? -_stompBounceHeld : -_stompBounce;
    _squash = 0.72;
    _squashVelocity = 0;
    _coyote = 0;
    _jumpConsumed = true;
  }

  void knockBack(double fromX) {
    invulnerable = _invulnerableTime;
    velocity
      ..x = centerX < fromX ? -160 : 160
      ..y = -260;
    _squash = 1.24;
  }

  @override
  void update(double dt) {
    if (!isAlive) return;

    _updateTimers(dt);
    _updateHorizontal(dt);
    _updateJump(dt);

    applyGravity(dt);
    moveWithCollisions(dt);

    if (onGround) {
      _coyote = _coyoteTime;
      _walkPhase += velocity.x.abs() * dt * 0.05;
      if (!_wasOnGround) {
        _squash = 0.78;
        _squashVelocity = 0;
      }
    } else {
      _coyote = math.max(0, _coyote - dt);
    }
    _wasOnGround = onGround;

    _updateSquash(dt);
  }

  void _updateTimers(double dt) {
    if (invulnerable > 0) invulnerable = math.max(0, invulnerable - dt);
    if (_jumpBuffer > 0) _jumpBuffer = math.max(0, _jumpBuffer - dt);
    _blinkTimer -= dt;
    if (_blinkTimer < -0.12) _blinkTimer = 2.4 + (centerX % 7) * 0.2;
  }

  void _updateHorizontal(double dt) {
    if (moveInput != 0) {
      velocity.x += moveInput * _acceleration * dt;
      velocity.x = velocity.x.clamp(-_maxRunSpeed, _maxRunSpeed);
      facing = moveInput > 0 ? 1 : -1;
    } else {
      final friction = (onGround ? _groundFriction : _airFriction) * dt;
      if (velocity.x.abs() <= friction) {
        velocity.x = 0;
      } else {
        velocity.x -= friction * velocity.x.sign;
      }
    }
  }

  void _updateJump(double dt) {
    final canJump = onGround || _coyote > 0;
    if (_jumpBuffer > 0 && !_jumpConsumed && canJump) {
      velocity.y = -_jumpSpeed;
      _jumpBuffer = 0;
      _coyote = 0;
      _jumpConsumed = true;
      _squash = 1.28;
      _squashVelocity = 0;
    }
  }

  /// A little spring so squash eases back to 1 instead of popping.
  void _updateSquash(double dt) {
    const stiffness = 260.0;
    const damping = 18.0;
    _squashVelocity += (1 - _squash) * stiffness * dt;
    _squashVelocity -= _squashVelocity * damping * dt;
    _squash += _squashVelocity * dt;

    if (!onGround) {
      final stretch = (velocity.y / 900).clamp(-0.6, 0.6);
      _squash = _squash * 0.86 + (1 + stretch * 0.22) * 0.14;
    }
    _squash = _squash.clamp(0.7, 1.35);
  }

  @override
  void render(Canvas canvas) {
    if (!isAlive) return;
    // Blink out a few frames at a time while invulnerable.
    if (isInvulnerable && (invulnerable * 14).floor().isEven) return;

    final scaleY = _squash;
    final scaleX = 2 - _squash;

    canvas.save();
    canvas.translate(size.x / 2, size.y);
    canvas.scale(scaleX * facing, scaleY);
    canvas.translate(-size.x / 2, -size.y);

    _renderBody(canvas);
    canvas.restore();
  }

  void _renderBody(Canvas canvas) {
    final skin = Paint()..color = Pal.skin;
    final hairPaint = Paint()..color = Pal.hair;
    final bob = onGround ? math.sin(_walkPhase * 6) * 0.8 : 0.0;

    canvas.save();
    canvas.translate(0, bob);

    // Dress: a soft bell from waist to feet.
    final dress = Path()
      ..moveTo(6.5, 15)
      ..lineTo(13.5, 15)
      ..quadraticBezierTo(19.5, 24, 18, 29.5)
      ..lineTo(2, 29.5)
      ..quadraticBezierTo(0.5, 24, 6.5, 15)
      ..close();
    canvas.drawPath(dress, Paint()..color = Pal.dress);
    canvas.drawPath(
      Path()
        ..moveTo(2, 29.5)
        ..lineTo(18, 29.5)
        ..lineTo(17.2, 26.5)
        ..lineTo(2.8, 26.5)
        ..close(),
      Paint()..color = Pal.dressDark,
    );

    // Arms.
    canvas.drawCircle(const Offset(4, 17), 2.4, skin);
    canvas.drawCircle(const Offset(16, 17), 2.4, skin);

    // Hair behind the head.
    canvas.drawCircle(const Offset(10, 9.5), 8.4, hairPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(1.8, 8, 16.4, 12),
        const Radius.circular(6),
      ),
      hairPaint,
    );

    // Face.
    canvas.drawCircle(const Offset(10, 9.8), 6.8, skin);

    // Fringe.
    canvas.drawPath(
      Path()
        ..moveTo(3.4, 8.6)
        ..quadraticBezierTo(10, 0.6, 16.6, 8.6)
        ..quadraticBezierTo(13.5, 5.4, 10, 6.6)
        ..quadraticBezierTo(6.5, 5.4, 3.4, 8.6)
        ..close(),
      Paint()..color = Pal.hairDark,
    );

    _renderFace(canvas);
    _renderCrown(canvas);

    canvas.restore();
  }

  void _renderFace(Canvas canvas) {
    final eye = Paint()..color = Pal.eyeDark;
    final blinking = _blinkTimer <= 0;
    if (blinking) {
      final lid = Paint()
        ..color = Pal.eyeDark
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(6.4, 10.4), const Offset(8.6, 10.4), lid);
      canvas.drawLine(const Offset(11.4, 10.4), const Offset(13.6, 10.4), lid);
    } else {
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(7.5, 10.3),
          width: 2.8,
          height: 3.6,
        ),
        eye,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(12.5, 10.3),
          width: 2.8,
          height: 3.6,
        ),
        eye,
      );
      final glint = Paint()..color = Pal.eyeWhite;
      canvas.drawCircle(const Offset(8.2, 9.4), 0.8, glint);
      canvas.drawCircle(const Offset(13.2, 9.4), 0.8, glint);
    }

    final cheeks = Paint()..color = Pal.dress.withValues(alpha: 0.55);
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

  void _renderCrown(Canvas canvas) {
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
    canvas.drawCircle(
      const Offset(10, 2.6),
      1.1,
      Paint()..color = Pal.crownGem,
    );
  }
}
