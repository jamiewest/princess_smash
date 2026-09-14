/// Levels are described as ASCII maps so layouts stay easy to read, whether
/// they were written by hand (the classic meadow below) or produced by the
/// educational [LevelGenerator].
///
/// Legend:
///   `.`  empty air
///   `#`  solid ground block
///   `=`  floating platform (also solid)
///   `P`  princess spawn
///   `E`  walking blob enemy
///   `F`  hopping enemy
///   `*`  gem
///   `H`  heart pickup
///   `D`  the door home (goal)
///   `G`  quiz gate tile (solid until its question is answered)
///   a-z  a letter pickup spelling the lesson's focus word
library;

import 'dart:math' as math;

const double kTileSize = 24;

/// Rows are written in chunks of ten columns so the layout stays countable by
/// eye. Ragged rows are padded during parsing.
const List<String> kLevelRows = [
  /*  0 */ '..................................................'
      '..................................................',
  /*  1 */ '..................................................'
      '..................................................',
  /*  2 */ '..................................................'
      '..................................................',
  /*  3 */ '..................................................'
      '..................................................',
  /*  4 */ '..................................................'
      '..................................................',
  /*  5 */ '..................*.............................*.'
      '.............*.......................*............',
  /*  6 */ '.................===...........................==='
      '............===.....................===...........',
  /*  7 */ '..................................................'
      '..................................................',
  /*  8 */ '......*.......*...........*..................*....'
      '......*..........*.......*.......*................',
  /*  9 */ '.....===.....===.........===......===.......===...'
      '.....===........===.....===.....===...............',
  /* 10 */ '......*......................*....H...............'
      '*.............H....................*..............',
  /* 11 */ '...P....................E........*..E.......F.....'
      '..E....*.......*......E.....*.....F........E....D.',
  /* 12 */ '..................................................'
      '..................................................',
  /* 13 */ '..................................................'
      '..................................................',
];

/// Ground rows are generated rather than typed twice, so the two ground layers
/// can never drift out of sync. Each pair is an inclusive [start, end] column.
const List<List<int>> kGroundSpans = [
  [0, 16],
  [20, 37],
  [42, 58],
  [63, 78],
  [82, 99],
];

const int kLevelCols = 100;
const int kLevelRowCount = 14;
const int kGroundRowStart = 12;

/// A parsed entity placement from the ASCII map.
class Placement {
  Placement(this.symbol, this.col, this.row);

  final String symbol;
  final int col;
  final int row;

  /// World position of the tile's top-left corner.
  double get x => col * kTileSize;
  double get y => row * kTileSize;

  /// True for `a`-`z`: a letter of the lesson's focus word.
  bool get isLetter =>
      symbol.length == 1 &&
      symbol.codeUnitAt(0) >= 0x61 &&
      symbol.codeUnitAt(0) <= 0x7A;
}

/// Which visual style a solid tile should render with.
enum TileKind { none, ground, platform, gate }

class Level {
  Level._(this._tiles, this.placements, this._gateCells);

  final List<List<TileKind>> _tiles;
  final List<Placement> placements;

  /// Every cell that started life as a gate tile, so gates can re-lock when
  /// the level restarts.
  final List<(int, int)> _gateCells;

  int get cols => _tiles[0].length;
  int get rowCount => _tiles.length;

  double get width => cols * kTileSize;
  double get height => rowCount * kTileSize;

  /// Anything below this has fallen out of the world.
  double get killPlaneY => height + kTileSize * 2;

  /// The classic hand-authored meadow.
  factory Level.parse() =>
      Level.fromRows(kLevelRows, groundSpans: kGroundSpans);

  /// Parses any ASCII map. Ragged rows are padded with air; [groundSpans]
  /// (optional) lays solid ground from [kGroundRowStart] down, exactly like
  /// the classic map's span table.
  factory Level.fromRows(
    List<String> rows, {
    List<List<int>> groundSpans = const [],
  }) {
    final colCount = rows.map((row) => row.length).reduce(math.max);
    final rowCount = math.max(rows.length, kLevelRowCount);
    final tiles = List.generate(
      rowCount,
      (_) => List.filled(colCount, TileKind.none),
    );
    final placements = <Placement>[];
    final gateCells = <(int, int)>[];
    final gateColsSeen = <int>{};

    for (var row = 0; row < rowCount; row++) {
      final line = row < rows.length ? rows[row] : '';
      for (var col = 0; col < colCount; col++) {
        final ch = col < line.length ? line[col] : '.';
        switch (ch) {
          case '#':
            tiles[row][col] = TileKind.ground;
          case '=':
            tiles[row][col] = TileKind.platform;
          case 'G':
            tiles[row][col] = TileKind.gate;
            gateCells.add((col, row));
            // One placement per gate column, at its topmost cell, so the
            // game spawns a single gate component per column of gate tiles.
            if (gateColsSeen.add(col)) {
              placements.add(Placement(ch, col, row));
            }
          case '.':
            break;
          default:
            placements.add(Placement(ch, col, row));
        }
      }
    }

    for (final span in groundSpans) {
      for (var col = span[0]; col <= span[1]; col++) {
        for (var row = kGroundRowStart; row < rowCount; row++) {
          tiles[row][col] = TileKind.ground;
        }
      }
    }

    return Level._(tiles, placements, gateCells);
  }

  TileKind kindAt(int col, int row) {
    if (col < 0 || col >= cols || row < 0 || row >= rowCount) {
      return TileKind.none;
    }
    return _tiles[row][col];
  }

  /// Out-of-bounds columns count as solid walls so nothing walks off the ends
  /// of the world; out-of-bounds rows stay open so falling still kills.
  bool isSolid(int col, int row) {
    if (col < 0 || col >= cols) return true;
    if (row < 0 || row >= rowCount) return false;
    return _tiles[row][col] != TileKind.none;
  }

  /// True when the tile is solid and the one above it is not — i.e. a surface
  /// something can stand on. Used for edge-detecting enemy patrols.
  bool isWalkableTop(int col, int row) =>
      isSolid(col, row) && !isSolid(col, row - 1);

  /// Removes the gate tiles in [col] so the princess can walk through.
  void openGate(int col) {
    for (final (gateCol, gateRow) in _gateCells) {
      if (gateCol == col) _tiles[gateRow][gateCol] = TileKind.none;
    }
  }

  /// Re-locks every gate; called when a run restarts.
  void resetGates() {
    for (final (col, row) in _gateCells) {
      _tiles[row][col] = TileKind.gate;
    }
  }

  int get gemCount => placements.where((p) => p.symbol == '*').length;
}
