/// Builds a playable level around a [Lesson]: the focus word's letters are
/// laid out in reading order (left to right) across a road of generated
/// terrain, and each quiz question locks a rose gate the princess must answer
/// to pass.
///
/// The generator emits the same ASCII map format the hand-authored level
/// uses, so a generated layout can be printed, eyeballed and tweaked. It is
/// deterministic for a given (lesson, seed) pair.
///
/// Layout invariants (enforced by `test/level_generator_test.dart`):
///  * pits are at most 3 columns wide with flat, grounded lips — clearable
///    with a running jump;
///  * platforms low enough to bonk a jumping head only appear over solid
///    ground, never over a pit;
///  * gates reach up from the ground past every jump and stomp-bounce
///    height, so they cannot be hopped over;
///  * every enemy, letter and gate stands on something solid.
library;

import 'dart:math' as math;

import 'education/lesson.dart';
import 'level.dart';

/// Topmost row of a gate's tile column. A full jump reaches feet y = 199 and
/// the highest possible stomp-bounce chain (held jump off a hopper at the top
/// of its hop) about y = 125; row 3 tops the gate at y = 72, far above
/// either, so the only way past is answering the question.
const int kGateTopRow = 3;

class LevelGenerator {
  LevelGenerator({required this.lesson, this.seed = 0});

  final Lesson lesson;
  final int seed;

  Level build() {
    final random = math.Random(seed);
    final grid = _Grid();
    final letters = lesson.word.split('');
    final questionCount = lesson.questions.length;

    final start = grid.add(8);
    grid.set(start + 3, 11, 'P');

    // Letters go down in reading order; gates are spread evenly between
    // them so each stretch of road earns the next question.
    var gatesPlaced = 0;
    for (var i = 0; i < letters.length; i++) {
      _letterSegment(grid, random, letters[i]);
      final lettersDone = i + 1;
      while (gatesPlaced < questionCount &&
          (gatesPlaced + 1) * letters.length / (questionCount + 1) <=
              lettersDone) {
        _gateSegment(grid, random);
        gatesPlaced++;
      }
    }
    while (gatesPlaced < questionCount) {
      _gateSegment(grid, random);
      gatesPlaced++;
    }

    final end = grid.add(8);
    grid.set(end + 5, 11, 'D');

    return Level.fromRows(grid.toRows());
  }

  void _letterSegment(_Grid grid, math.Random random, String letter) {
    final roll = random.nextInt(10);
    if (roll < 3) {
      _stroll(grid, random, letter);
    } else if (roll < 6) {
      _hop(grid, random, letter);
    } else if (roll < 8) {
      _pitCrossing(grid, random, letter);
    } else {
      _tower(grid, random, letter);
    }
  }

  /// Flat ground with the letter at walking height; sometimes a blob to
  /// squash along the way.
  void _stroll(_Grid grid, math.Random random, String letter) {
    final base = grid.add(7);
    grid.set(base + 2, 10, letter);
    if (random.nextDouble() < 0.5) grid.set(base + 5, 11, 'E');
  }

  /// A low platform holding the letter one hop up.
  void _hop(_Grid grid, math.Random random, String letter) {
    final base = grid.add(8);
    grid.platform(base + 3, base + 5, 9);
    grid.set(base + 4, 8, letter);
    if (random.nextDouble() < 0.5) grid.set(base + 1, 10, '*');
    if (random.nextDouble() < 0.35) grid.set(base + 6, 11, 'F');
  }

  /// A short pit with bonus gems floating over it; the letter waits safely
  /// on the far side.
  void _pitCrossing(_Grid grid, math.Random random, String letter) {
    final pitWidth = random.nextDouble() < 0.3 ? 3 : 2;
    grid.add(3);
    final pit = grid.add(pitWidth, pit: true);
    for (var i = 0; i < pitWidth; i++) {
      grid.set(pit + i, 8, '*');
    }
    final far = grid.add(4);
    grid.set(far + 2, 10, letter);
  }

  /// Two stacked platforms; the letter sits up high as a little challenge.
  void _tower(_Grid grid, math.Random random, String letter) {
    final base = grid.add(10);
    grid.platform(base + 2, base + 4, 9);
    grid.platform(base + 5, base + 7, 6);
    grid.set(base + 6, 5, letter);
    grid.set(base + 3, 8, '*');
    if (random.nextDouble() < 0.4) grid.set(base + 8, 11, 'E');
  }

  /// A rose gate across the whole road, sometimes with a heart waiting as a
  /// reward just past it.
  void _gateSegment(_Grid grid, math.Random random) {
    final base = grid.add(7);
    for (var row = kGateTopRow; row < kGroundRowStart; row++) {
      grid.set(base + 3, row, 'G');
    }
    if (random.nextDouble() < 0.4) grid.set(base + 5, 10, 'H');
  }
}

/// A column-at-a-time ASCII map under construction.
class _Grid {
  final List<List<String>> _columns = [];

  /// Appends [count] columns and returns the index of the first one. Columns
  /// get the two solid ground rows unless this is a [pit].
  int add(int count, {bool pit = false}) {
    final base = _columns.length;
    for (var i = 0; i < count; i++) {
      final column = List.filled(kLevelRowCount, '.');
      if (!pit) {
        for (var row = kGroundRowStart; row < kLevelRowCount; row++) {
          column[row] = '#';
        }
      }
      _columns.add(column);
    }
    return base;
  }

  void set(int col, int row, String ch) => _columns[col][row] = ch;

  void platform(int colStart, int colEnd, int row) {
    for (var col = colStart; col <= colEnd; col++) {
      set(col, row, '=');
    }
  }

  List<String> toRows() => [
    for (var row = 0; row < kLevelRowCount; row++)
      [for (final column in _columns) column[row]].join(),
  ];
}
