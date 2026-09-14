import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'appearance.dart';
import 'hero_painter.dart';
import 'physics_entity.dart';

/// The player: the royal hero, Princess Emery by default. Handles run/jump
/// feel (acceleration, coyote time, jump buffering, variable jump height)
/// plus the squash-and-stretch that carries most of the game's charm.
class Princess extends PhysicsEntity {
  Princess({
    required super.level,
    required Vector2 spawn,
    this.appearance = HeroAppearance.emery,
  }) : super(position: spawn.clone(), size: Vector2(20, 30));

  /// How the hero looks; see [HeroAppearance] for what can be customised.
  final HeroAppearance appearance;

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

    paintHero(
      canvas,
      appearance,
      bob: onGround ? math.sin(_walkPhase * 6) * 0.8 : 0.0,
      blinking: _blinkTimer <= 0,
    );
    canvas.restore();
  }
}
