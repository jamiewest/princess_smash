/// The level is authored as an ASCII map so layout can be tweaked in seconds.
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
library;

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
}

/// Which visual style a solid tile should render with.
enum TileKind { none, ground, platform }

class Level {
  Level._(this._tiles, this.placements);

  final List<List<TileKind>> _tiles;
  final List<Placement> placements;

  double get width => kLevelCols * kTileSize;
  double get height => kLevelRowCount * kTileSize;

  /// Anything below this has fallen out of the world.
  double get killPlaneY => height + kTileSize * 2;

  factory Level.parse() {
    final tiles = List.generate(
      kLevelRowCount,
      (_) => List.filled(kLevelCols, TileKind.none),
    );
    final placements = <Placement>[];

    for (var row = 0; row < kLevelRowCount; row++) {
      final line = row < kLevelRows.length ? kLevelRows[row] : '';
      for (var col = 0; col < kLevelCols; col++) {
        final ch = col < line.length ? line[col] : '.';
        switch (ch) {
          case '#':
            tiles[row][col] = TileKind.ground;
          case '=':
            tiles[row][col] = TileKind.platform;
          case '.':
            break;
          default:
            placements.add(Placement(ch, col, row));
        }
      }
    }

    // Lay down the two solid ground layers from the span table.
    for (final span in kGroundSpans) {
      for (var col = span[0]; col <= span[1]; col++) {
        for (var row = kGroundRowStart; row < kLevelRowCount; row++) {
          tiles[row][col] = TileKind.ground;
        }
      }
    }

    return Level._(tiles, placements);
  }

  TileKind kindAt(int col, int row) {
    if (col < 0 || col >= kLevelCols || row < 0 || row >= kLevelRowCount) {
      return TileKind.none;
    }
    return _tiles[row][col];
  }

  /// Out-of-bounds columns count as solid walls so nothing walks off the ends
  /// of the world; out-of-bounds rows stay open so falling still kills.
  bool isSolid(int col, int row) {
    if (col < 0 || col >= kLevelCols) return true;
    if (row < 0 || row >= kLevelRowCount) return false;
    return _tiles[row][col] != TileKind.none;
  }

  /// True when the tile is solid and the one above it is not — i.e. a surface
  /// something can stand on. Used for edge-detecting enemy patrols.
  bool isWalkableTop(int col, int row) =>
      isSolid(col, row) && !isSolid(col, row - 1);

  int get gemCount => placements.where((p) => p.symbol == '*').length;
}
