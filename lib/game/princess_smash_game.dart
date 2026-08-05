import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart' show KeyEventResult;
import 'package:flutter/services.dart';

import 'enemy.dart';
import 'goal.dart';
import 'hud.dart';
import 'level.dart';
import 'palette.dart';
import 'pickups.dart';
import 'princess.dart';
import 'scenery.dart';
import 'sparkle.dart';

enum GameStatus { title, playing, gameOver, won }

const String kTitleOverlay = 'title';
const String kGameOverOverlay = 'gameOver';
const String kWinOverlay = 'win';

/// A little side-scrolling platformer: the princess is lost, and the way home
/// runs east across the meadow. Jump on the blobs to squash them.
class PrincessSmashGame extends FlameGame with KeyboardEvents {
  PrincessSmashGame()
    : super(
        camera: CameraComponent.withFixedResolution(
          width: viewWidth,
          height: viewHeight,
        ),
      );

  static const double viewWidth = 480;
  static const double viewHeight = 270;
  static const int maxHearts = 3;

  static final Set<LogicalKeyboardKey> _leftKeys = {
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.keyA,
  };
  static final Set<LogicalKeyboardKey> _rightKeys = {
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyD,
  };
  static final Set<LogicalKeyboardKey> _jumpKeys = {
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.keyZ,
  };
  static final Set<LogicalKeyboardKey> _confirmKeys = {
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
  };

  late final Level level;
  late final Scenery scenery;
  late final Terrain terrain;
  late final Hud hud;
  late HomeDoor door;
  late Princess princess;

  final List<Enemy> enemies = [];
  final List<Pickup> pickups = [];
  final List<Component> _spawned = [];

  GameStatus status = GameStatus.title;
  int hearts = maxHearts;
  int gems = 0;

  final Set<LogicalKeyboardKey> _keys = {};
  Vector2 _lastSafeSpot = Vector2.zero();
  double _respawnDelay = 0;

  @override
  Color backgroundColor() => Pal.skyMid;

  @override
  Future<void> onLoad() async {
    level = Level.parse();
    scenery = Scenery(level: level);
    terrain = Terrain(level: level);
    hud = Hud(maxHearts: maxHearts, totalGems: level.gemCount);

    await world.addAll([scenery, terrain]);
    camera.viewport.add(hud);

    _spawnLevelEntities();
    _snapCamera();
    overlays.add(kTitleOverlay);
  }

  /// Creates (or recreates) every dynamic thing described by the ASCII map.
  void _spawnLevelEntities() {
    for (final entity in _spawned) {
      entity.removeFromParent();
    }
    _spawned.clear();
    enemies.clear();
    pickups.clear();

    for (final placement in level.placements) {
      switch (placement.symbol) {
        case 'P':
          princess = Princess(
            level: level,
            spawn: Vector2(placement.x + 2, placement.y + kTileSize - 30),
          );
          _lastSafeSpot = princess.position.clone();
          _spawn(princess);
        case 'E':
        case 'F':
          final enemy = Enemy(
            level: level,
            spawn: Vector2(placement.x + 1, placement.y + kTileSize - 20),
            kind: placement.symbol == 'E' ? EnemyKind.walker : EnemyKind.hopper,
          );
          enemies.add(enemy);
          _spawn(enemy);
        case '*':
          final gem = Gem(spawn: Vector2(placement.x + 4, placement.y + 3));
          pickups.add(gem);
          _spawn(gem);
        case 'H':
          final heart = HeartPickup(
            spawn: Vector2(placement.x + 3, placement.y + 4),
          );
          pickups.add(heart);
          _spawn(heart);
        case 'D':
          door = HomeDoor(spawn: Vector2(placement.x, placement.y));
          _spawn(door);
      }
    }
  }

  void _spawn(Component component) {
    _spawned.add(component);
    world.add(component);
  }

  /// Starts (or restarts) a run. With [jump], the action that dismissed the
  /// menu — a SPACE press, a click on the start button — also becomes Pip's
  /// first jump, so starting always launches her rather than swallowing the
  /// input. The jump goes through [Princess.requestJump] like any other, so
  /// buffering and variable height behave normally.
  void startGame({bool jump = false}) {
    hearts = maxHearts;
    gems = 0;
    _respawnDelay = 0;
    _spawnLevelEntities();
    // Re-sync with the real keyboard rather than clearing: a direction key
    // still held from the previous run should keep working through a restart.
    _keys
      ..clear()
      ..addAll(HardwareKeyboard.instance.logicalKeysPressed);
    status = GameStatus.playing;
    overlays
      ..remove(kTitleOverlay)
      ..remove(kGameOverOverlay)
      ..remove(kWinOverlay);
    _snapCamera();
    if (jump) {
      princess.requestJump();
    }
  }

  /// Longest physics step we will ever simulate. Returning to a backgrounded
  /// tab hands us a multi-second `dt`; without this the world would lurch.
  static const double _maxFrameDelta = 1 / 20;

  @override
  void update(double dt) {
    final step = math.min(dt, _maxFrameDelta);
    final playing = status == GameStatus.playing;

    // Freezing the world with dt = 0 keeps the component lifecycle running
    // (mounts, removals) while nothing moves during menus.
    super.update(playing ? step : 0);
    if (!playing) {
      scenery.update(step);
    } else {
      _applyInput();
      _resolveEnemies();
      _resolvePickups();
      _resolveGoal();
      _checkFallOut(step);
      _syncHud();
      _pruneRemoved();
    }
    _updateCamera(step);
  }

  void _applyInput() {
    if (!princess.isAlive) {
      princess.moveInput = 0;
      return;
    }
    final left = _keys.any(_leftKeys.contains);
    final right = _keys.any(_rightKeys.contains);
    princess.moveInput = (right ? 1 : 0) + (left ? -1 : 0);

    if (princess.onGround && princess.velocity.x.abs() < 40) {
      _lastSafeSpot = princess.position.clone();
    }
  }

  /// Stomp resolution. A hit counts as a smash only while falling and only
  /// while the princess' feet are still above the enemy's middle.
  void _resolveEnemies() {
    if (!princess.isAlive) return;
    for (final enemy in enemies) {
      if (enemy.isDying || !enemy.isMounted) continue;
      if (!princess.overlaps(enemy, inset: 1.5)) continue;

      if (enemy.isStompedBy(princess)) {
        enemy.squash();
        princess.position.y = enemy.top - princess.size.y;
        princess.bounce();
        world.add(
          SparkleBurst(
            spawn: Vector2(enemy.centerX, enemy.centerY),
            colour: Pal.sparkle,
            count: 12,
          ),
        );
      } else if (!princess.isInvulnerable) {
        _damagePrincess(fromX: enemy.centerX);
      }
    }
  }

  void _resolvePickups() {
    if (!princess.isAlive) return;
    final body = princess.toRect();
    for (final pickup in pickups) {
      if (pickup.collected || !pickup.isMounted) continue;
      if (!body.overlaps(pickup.toRect())) continue;

      pickup.collected = true;
      pickup.removeFromParent();
      final centre = Vector2(
        pickup.position.x + pickup.size.x / 2,
        pickup.position.y + pickup.size.y / 2,
      );
      if (pickup is Gem) {
        gems++;
        world.add(SparkleBurst(spawn: centre, colour: Pal.gemLight, count: 9));
      } else {
        hearts = math.min(maxHearts, hearts + 1);
        world.add(SparkleBurst(spawn: centre, colour: Pal.heart, count: 12));
      }
    }
  }

  void _resolveGoal() {
    final distance = (door.position.x - princess.centerX).abs();
    door.excitement = (1 - distance / 260).clamp(0.0, 1.0);
    if (!princess.isAlive) return;
    if (princess.toRect().overlaps(door.toRect())) {
      status = GameStatus.won;
      world.add(
        SparkleBurst(
          spawn: Vector2(door.position.x + 12, door.position.y + 20),
          colour: Pal.crown,
          count: 20,
          speed: 140,
          lifetime: 0.9,
          dotRadius: 2.6,
        ),
      );
      overlays.add(kWinOverlay);
    }
  }

  void _checkFallOut(double dt) {
    if (princess.isAlive && princess.top > level.killPlaneY) {
      princess.isAlive = false;
      _loseHeart();
      _respawnDelay = 0.6;
    }
    if (!princess.isAlive && status == GameStatus.playing) {
      _respawnDelay -= dt;
      if (_respawnDelay <= 0) {
        princess.respawn(_lastSafeSpot);
      }
    }
  }

  void _damagePrincess({required double fromX}) {
    _loseHeart();
    if (status == GameStatus.playing) {
      princess.knockBack(fromX);
      world.add(
        SparkleBurst(
          spawn: Vector2(princess.centerX, princess.centerY),
          colour: Pal.heart,
          count: 8,
          speed: 70,
        ),
      );
    }
  }

  void _loseHeart() {
    hearts--;
    if (hearts > 0) return;
    hearts = 0;
    status = GameStatus.gameOver;
    overlays.add(kGameOverOverlay);
  }

  void _syncHud() {
    hud
      ..hearts = hearts
      ..gems = gems
      ..progress = (princess.centerX / (door.position.x + 12)).clamp(0.0, 1.0);
  }

  void _pruneRemoved() {
    enemies.removeWhere((enemy) => enemy.isRemoved);
    pickups.removeWhere((pickup) => pickup.isRemoved);
  }

  Vector2 _cameraTarget() {
    final target = Vector2(princess.centerX, princess.centerY - 18);
    return Vector2(
      target.x.clamp(viewWidth / 2, level.width - viewWidth / 2),
      target.y.clamp(viewHeight / 2, level.height - viewHeight / 2),
    );
  }

  void _snapCamera() {
    camera.viewfinder.position = _cameraTarget();
  }

  void _updateCamera(double dt) {
    final target = _cameraTarget();
    final current = camera.viewfinder.position;
    // Exponential smoothing, frame-rate independent.
    final t = 1 - math.pow(0.0008, dt).toDouble();
    camera.viewfinder.position = current + (target - current) * t;
    if (camera.isMounted) {
      terrain.visible = camera.visibleWorldRect;
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _keys
      ..clear()
      ..addAll(keysPressed);

    if (event is KeyDownEvent && _confirmKeys.contains(event.logicalKey)) {
      if (status != GameStatus.playing) {
        final isJumpKey = _jumpKeys.contains(event.logicalKey);
        startGame(jump: isJumpKey);
        // The key is still physically down, so holding it should give the
        // full-height jump; the matching keyup releases it as usual. A mouse
        // start has no held key, which is why this stays out of startGame.
        if (isJumpKey) {
          princess.jumpHeld = true;
        }
        return KeyEventResult.handled;
      }
    }

    if (status != GameStatus.playing) return KeyEventResult.handled;

    if (_jumpKeys.contains(event.logicalKey)) {
      if (event is KeyDownEvent) {
        princess.jumpHeld = true;
        princess.requestJump();
      } else if (event is KeyUpEvent) {
        princess.releaseJump();
      }
    }
    return KeyEventResult.handled;
  }
}
