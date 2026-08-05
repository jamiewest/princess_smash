import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:princess_smash/game/enemy.dart';
import 'package:princess_smash/game/level.dart';
import 'package:princess_smash/game/physics_entity.dart';
import 'package:princess_smash/game/princess.dart';

/// Top of the ground in world pixels: the last two rows of the map are solid.
const double groundTop = kGroundRowStart * kTileSize;

/// A bare body used to exercise the collision solver on its own.
class TestBody extends PhysicsEntity {
  TestBody({required super.level, required Vector2 spawn})
    : super(position: spawn.clone(), size: Vector2(20, 30));

  void step(double dt, {int times = 1}) {
    for (var i = 0; i < times; i++) {
      applyGravity(dt);
      moveWithCollisions(dt);
    }
  }
}

Princess princessAt(Level level, double x, double bottom) =>
    Princess(level: level, spawn: Vector2(x, bottom - 30));

Enemy walkerAt(Level level, double x, double bottom) =>
    Enemy(level: level, spawn: Vector2(x, bottom - 20), kind: EnemyKind.walker);

/// Runs the princess through the same entry point the game loop uses.
void run(Princess pip, {double dt = 1 / 60, int frames = 1}) {
  for (var i = 0; i < frames; i++) {
    pip.update(dt);
  }
}

void main() {
  late Level level;

  setUp(() => level = Level.parse());

  group('level', () {
    test('parses a full-width map with the expected contents', () {
      expect(kLevelRows.every((row) => row.length == kLevelCols), isTrue);
      expect(level.gemCount, 20);
      expect(
        level.placements.where((p) => p.symbol == 'D').length,
        1,
        reason: 'exactly one way home',
      );
      expect(level.placements.where((p) => p.symbol == 'P').length, 1);
    });

    test('ground spans are solid and pits are not', () {
      expect(level.isSolid(3, kGroundRowStart), isTrue);
      expect(level.isSolid(18, kGroundRowStart), isFalse);
      expect(level.isSolid(40, kGroundRowStart), isFalse);
    });

    test('low platforms never overhang a pit', () {
      // A full jump raises Pip's head to y = groundTop - 30 - 89, which is
      // y=169 with the current tuning: she clears under row-6 platforms
      // (underside y=168) by a pixel, but bonks anything lower. So any
      // platform too low to pass under must sit entirely over solid ground —
      // a low platform overlapping a pit turns the crossing jump into a head
      // bonk and a lost heart.
      const jumpApexHeadY = 169.0;
      for (var row = 0; row < kLevelRowCount; row++) {
        final undersideY = (row + 1) * kTileSize;
        if (undersideY <= jumpApexHeadY) continue;
        for (var col = 0; col < kLevelCols; col++) {
          if (level.kindAt(col, row) != TileKind.platform) continue;
          expect(
            level.isSolid(col, kGroundRowStart),
            isTrue,
            reason:
                'platform at column $col, row $row is too low to jump '
                'under but hangs over a pit',
          );
        }
      }
    });

    test('every pit can be jumped from its left lip at full speed', () {
      // Simulates the real crossing for each pit: run right at full speed,
      // jump from the lip, and keep holding jump — the way a player does it.
      // Fails if anything (like the platform that used to overhang column 37)
      // interrupts the arc and drops her in.
      const pits = [
        [17, 19],
        [38, 41],
        [59, 62],
        [79, 81],
      ];
      for (final pit in pits) {
        final lipX = pit[0] * kTileSize;
        final farLipX = (pit[1] + 1) * kTileSize;
        final pip = princessAt(level, lipX - 120, groundTop)
          ..moveInput = 1
          ..jumpHeld = true;

        var jumped = false;
        var landedX = double.nan;
        for (var frame = 0; frame < 240; frame++) {
          if (!jumped && pip.right >= lipX - 2) {
            pip.requestJump();
            jumped = true;
          }
          pip.update(1 / 60);
          expect(
            pip.top,
            lessThan(level.killPlaneY),
            reason: 'fell into the pit at columns ${pit[0]}-${pit[1]}',
          );
          if (jumped && pip.onGround) {
            landedX = pip.left;
            break;
          }
        }

        expect(jumped, isTrue);
        expect(
          landedX,
          greaterThanOrEqualTo(farLipX),
          reason:
              'did not clear the pit at columns ${pit[0]}-${pit[1]}: '
              'landed at x=$landedX, needed ${farLipX}',
        );
      }
    });

    test('every character and pickup has something to stand over', () {
      for (final placement in level.placements) {
        if (!'EFPD'.contains(placement.symbol)) continue;
        expect(
          level.isSolid(placement.col, placement.row + 1),
          isTrue,
          reason:
              '${placement.symbol} at column ${placement.col} '
              'has nothing to stand on',
        );
      }
    });
  });

  group('collision solver', () {
    test('a body resting on the ground stays put', () {
      final body = TestBody(level: level, spawn: Vector2(72, groundTop - 30))
        ..step(1 / 60, times: 60);

      expect(body.onGround, isTrue);
      expect(body.bottom, closeTo(groundTop, 0.001));
    });

    test('a very long frame cannot tunnel through the floor', () {
      // Nine seconds is what a backgrounded browser tab hands back on resume.
      final body = TestBody(level: level, spawn: Vector2(72, groundTop - 30))
        ..step(9);

      expect(body.onGround, isTrue);
      expect(body.bottom, closeTo(groundTop, 0.001));
    });

    test('falling into a pit passes the kill plane', () {
      final body = TestBody(
        level: level,
        spawn: Vector2(18 * kTileSize, groundTop - 60),
      )..step(1 / 60, times: 240);

      expect(body.top, greaterThan(level.killPlaneY));
    });

    test('running into the end of the world stops her', () {
      final body = TestBody(
        level: level,
        spawn: Vector2(99 * kTileSize, groundTop - 30),
      );
      body.velocity.x = 300;
      body.step(1 / 60);

      expect(body.hitWall, isTrue);
      expect(body.right, lessThanOrEqualTo(level.width));
      expect(body.velocity.x, 0);
    });
  });

  group('smashing', () {
    test('coming down on a blob counts as a stomp', () {
      final blob = walkerAt(level, 72, groundTop);
      // Feet level with the blob's head, on the way down.
      final pip = princessAt(level, 72, groundTop - 20);
      pip.velocity.y = 400;
      run(pip);

      expect(pip.overlaps(blob, inset: 1.5), isTrue);
      expect(blob.isStompedBy(pip), isTrue);
    });

    test('a fast fall still registers across a long frame', () {
      final blob = walkerAt(level, 72, groundTop);
      final pip = princessAt(level, 72, groundTop - 58);
      pip.velocity.y = 900;
      run(pip, dt: 1 / 20);

      expect(pip.overlaps(blob, inset: 1.5), isTrue);
      expect(
        blob.isStompedBy(pip),
        isTrue,
        reason: 'the stomp window must not depend on frame rate',
      );
    });

    test('walking into a blob sideways is not a stomp', () {
      final blob = walkerAt(level, 100, groundTop);
      final pip = princessAt(level, 72, groundTop)..moveInput = 1;
      run(pip, frames: 12);

      expect(pip.overlaps(blob, inset: 1.5), isTrue);
      expect(blob.isStompedBy(pip), isFalse);
    });

    test('a stomp squashes the blob and bounces her back up', () {
      final blob = walkerAt(level, 72, groundTop);
      final pip = princessAt(level, 72, groundTop - 20);
      pip.velocity.y = 400;
      run(pip);
      expect(blob.isStompedBy(pip), isTrue);

      // The same sequence the game runs once the stomp is detected.
      blob.squash();
      pip.position.y = blob.top - pip.size.y;
      pip.bounce();

      expect(blob.isDying, isTrue);
      expect(pip.velocity.y, lessThan(0), reason: 'she should rebound upward');
      expect(pip.bottom, closeTo(blob.top, 0.001));
    });

    test('a side hit knocks her away and grants a moment of mercy', () {
      final blob = walkerAt(level, 100, groundTop);
      final pip = princessAt(level, 72, groundTop)..moveInput = 1;
      run(pip, frames: 12);
      expect(blob.isStompedBy(pip), isFalse);

      pip.knockBack(blob.centerX);

      expect(
        pip.velocity.x,
        lessThan(0),
        reason: 'she is to the blob\'s left, so she is pushed further left',
      );
      expect(pip.velocity.y, lessThan(0));
      expect(pip.isInvulnerable, isTrue);
    });

    test('a blob can only be squashed once', () {
      final blob = walkerAt(level, 72, groundTop)..squash();
      expect(blob.isDying, isTrue);

      blob.squash();
      expect(blob.isDying, isTrue);
    });
  });

  group('princess feel', () {
    test('she jumps from the ground', () {
      final pip = princessAt(level, 72, groundTop);
      run(pip, frames: 2);
      expect(pip.onGround, isTrue);

      pip.requestJump();
      run(pip);

      expect(pip.velocity.y, lessThan(0));
      expect(pip.onGround, isFalse);
    });

    test('a jump pressed just before landing still fires', () {
      final pip = princessAt(level, 72, groundTop - 5);
      pip.velocity.y = 200;
      pip.requestJump();
      run(pip, frames: 4);

      expect(
        pip.velocity.y,
        lessThan(0),
        reason: 'the buffered press should fire on the landing frame',
      );
    });

    test('she can still jump just after stepping off a ledge', () {
      // Column 17 is open air; the ledge is the last solid tile before it.
      final pip = princessAt(level, 16 * kTileSize + 8, groundTop)
        ..moveInput = 1;
      run(pip, frames: 12);
      expect(pip.onGround, isFalse, reason: 'she should be over the pit');

      pip.requestJump();
      run(pip);

      expect(pip.velocity.y, lessThan(0));
    });

    test('releasing jump early cuts the rise short', () {
      final pip = princessAt(level, 72, groundTop);
      run(pip, frames: 2);
      pip.jumpHeld = true;
      pip.requestJump();
      run(pip);

      final full = pip.velocity.y;
      expect(full, lessThan(0));

      pip.releaseJump();
      expect(pip.velocity.y, greaterThan(full));
      expect(pip.velocity.y, lessThan(0));
    });

    test('a stomp bounces her up, higher when jump is held', () {
      final low = princessAt(level, 72, groundTop)..bounce();
      final high = princessAt(level, 72, groundTop)
        ..jumpHeld = true
        ..bounce();

      expect(low.velocity.y, lessThan(0));
      expect(high.velocity.y, lessThan(low.velocity.y));
    });

    test('respawning puts her back on the last safe spot', () {
      final pip = princessAt(level, 72, groundTop);
      pip.position.setValues(999, 9999);
      pip.isAlive = false;

      pip.respawn(Vector2(72, groundTop - 30));

      expect(pip.isAlive, isTrue);
      expect(pip.isInvulnerable, isTrue);
      expect(pip.position.x, 72);
      expect(pip.bottom, closeTo(groundTop, 0.001));
    });
  });
}
