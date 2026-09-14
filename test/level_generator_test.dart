import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:princess_smash/game/education/curriculum.dart';
import 'package:princess_smash/game/level.dart';
import 'package:princess_smash/game/level_generator.dart';
import 'package:princess_smash/game/princess.dart';

const double groundTop = kGroundRowStart * kTileSize;

const List<int> seeds = [0, 1, 7, 42, 1234];

/// Letter placements in reading order.
List<Placement> lettersOf(Level level) =>
    level.placements.where((p) => p.isLetter).toList()
      ..sort((a, b) => a.col.compareTo(b.col));

/// Gate columns (one placement per gate) in reading order.
List<Placement> gatesOf(Level level) =>
    level.placements.where((p) => p.symbol == 'G').toList()
      ..sort((a, b) => a.col.compareTo(b.col));

/// Contiguous runs of open ground-row columns between the first and last
/// solid column — i.e. the pits.
List<List<int>> pitsOf(Level level) {
  final pits = <List<int>>[];
  int? start;
  for (var col = 0; col < level.cols; col++) {
    if (!level.isSolid(col, kGroundRowStart)) {
      start ??= col;
    } else if (start != null) {
      pits.add([start, col - 1]);
      start = null;
    }
  }
  return pits;
}

void main() {
  group('generated levels', () {
    for (final lesson in kCurriculum) {
      for (final seed in seeds) {
        final label = '"${lesson.word}" seed $seed';
        final level = LevelGenerator(lesson: lesson, seed: seed).build();

        test('$label has one spawn and one door', () {
          expect(level.placements.where((p) => p.symbol == 'P').length, 1);
          expect(level.placements.where((p) => p.symbol == 'D').length, 1);
        });

        test('$label spells the focus word in reading order', () {
          final spelled = lettersOf(level).map((p) => p.symbol).join();
          expect(spelled, lesson.word);
        });

        test('$label has one gate per question', () {
          expect(gatesOf(level).length, lesson.questions.length);
        });

        test('$label gates are too tall to jump and reach the ground', () {
          // The highest boost in the game is a held-jump stomp bounce off a
          // hopper at the top of its hop, which lifts her feet to roughly
          // y = 125. Gates must top out well above that or a lucky bounce
          // skips the question (seen in playtesting when a hopper wandered
          // next to a gate).
          const maxBounceChainFeetY = 125.0;
          for (final gate in gatesOf(level)) {
            expect(gate.row, kGateTopRow);
            expect(
              gate.row * kTileSize,
              lessThan(maxBounceChainFeetY - kTileSize),
              reason: 'gate at column ${gate.col} could be bounced over',
            );
            for (var row = kGateTopRow; row < kGroundRowStart; row++) {
              expect(level.isSolid(gate.col, row), isTrue);
            }
            expect(
              level.isSolid(gate.col, kGroundRowStart),
              isTrue,
              reason: 'gate at column ${gate.col} must stand on ground',
            );
          }
        });

        test('$label creatures and the door stand on something solid', () {
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

        test('$label letters hover over a landing spot', () {
          for (final letter in lettersOf(level)) {
            final oneBelow = level.isSolid(letter.col, letter.row + 1);
            final twoBelow = level.isSolid(letter.col, letter.row + 2);
            expect(
              oneBelow || twoBelow,
              isTrue,
              reason:
                  'letter "${letter.symbol}" at column ${letter.col} '
                  'floats with nowhere to stand',
            );
          }
        });

        test('$label pits are narrow with grounded lips', () {
          for (final pit in pitsOf(level)) {
            final width = pit[1] - pit[0] + 1;
            expect(
              width,
              lessThanOrEqualTo(3),
              reason: 'pit at columns ${pit[0]}-${pit[1]} is too wide',
            );
            expect(level.isWalkableTop(pit[0] - 1, kGroundRowStart), isTrue);
            expect(level.isWalkableTop(pit[1] + 1, kGroundRowStart), isTrue);
          }
        });

        test('$label low platforms never overhang a pit', () {
          // Same rule the hand-authored level enforces: anything too low to
          // jump under must sit entirely over solid ground.
          const jumpApexHeadY = 169.0;
          for (var row = 0; row < level.rowCount; row++) {
            final undersideY = (row + 1) * kTileSize;
            if (undersideY <= jumpApexHeadY) continue;
            for (var col = 0; col < level.cols; col++) {
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

        test('$label every pit can be jumped from its lip at full speed', () {
          for (final pit in pitsOf(level)) {
            final lipX = pit[0] * kTileSize;
            final farLipX = (pit[1] + 1) * kTileSize;
            final emery =
                Princess(
                    level: level,
                    spawn: Vector2(lipX - 120, groundTop - 30),
                  )
                  ..moveInput = 1
                  ..jumpHeld = true;

            var jumped = false;
            var landedX = double.nan;
            for (var frame = 0; frame < 240; frame++) {
              if (!jumped && emery.right >= lipX - 2) {
                emery.requestJump();
                jumped = true;
              }
              emery.update(1 / 60);
              expect(
                emery.top,
                lessThan(level.killPlaneY),
                reason: 'fell into the pit at columns ${pit[0]}-${pit[1]}',
              );
              if (jumped && emery.onGround) {
                landedX = emery.left;
                break;
              }
            }

            expect(jumped, isTrue);
            expect(
              landedX,
              greaterThanOrEqualTo(farLipX),
              reason:
                  'did not clear the pit at columns ${pit[0]}-${pit[1]}: '
                  'landed at x=$landedX, needed $farLipX',
            );
          }
        });
      }
    }

    test('the same lesson and seed always build the same level', () {
      final lesson = kCurriculum.first;
      final a = LevelGenerator(lesson: lesson, seed: 99).build();
      final b = LevelGenerator(lesson: lesson, seed: 99).build();

      expect(a.cols, b.cols);
      for (var row = 0; row < a.rowCount; row++) {
        for (var col = 0; col < a.cols; col++) {
          expect(a.kindAt(col, row), b.kindAt(col, row));
        }
      }
      String describe(Placement p) => '${p.symbol}@${p.col},${p.row}';
      expect(a.placements.map(describe), b.placements.map(describe));
    });
  });

  group('quiz gates', () {
    late Level level;
    late Placement gate;

    setUp(() {
      final lesson = kCurriculum.first;
      level = LevelGenerator(lesson: lesson, seed: 3).build();
      gate = gatesOf(level).first;
    });

    test('a locked gate stops her cold', () {
      final gateLeft = gate.col * kTileSize;
      final emery = Princess(
        level: level,
        spawn: Vector2(gateLeft - 70, groundTop - 30),
      )..moveInput = 1;

      for (var frame = 0; frame < 120; frame++) {
        emery.update(1 / 60);
      }

      expect(emery.right, lessThanOrEqualTo(gateLeft + 0.001));
      expect(emery.hitWall, isTrue);
    });

    test('an opened gate lets her through, and reset locks it again', () {
      level.openGate(gate.col);
      for (var row = kGateTopRow; row < kGroundRowStart; row++) {
        expect(level.isSolid(gate.col, row), isFalse);
      }

      final gateLeft = gate.col * kTileSize;
      final emery = Princess(
        level: level,
        spawn: Vector2(gateLeft - 70, groundTop - 30),
      )..moveInput = 1;
      for (var frame = 0; frame < 120; frame++) {
        emery.update(1 / 60);
      }
      expect(emery.left, greaterThan(gateLeft));

      level.resetGates();
      for (var row = kGateTopRow; row < kGroundRowStart; row++) {
        expect(level.isSolid(gate.col, row), isTrue);
      }
    });
  });
}
