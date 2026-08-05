import 'dart:math' as math;

import 'package:flame/components.dart';

import 'level.dart';

/// Shared platformer physics: gravity plus swept AABB resolution against the
/// tile grid. Axes are resolved separately (X first, then Y) which is what
/// keeps corners from snagging and stops the classic wall-slide jitter.
///
/// Positions use the default top-left anchor, so `position` is the top-left of
/// the collision box and rendering happens in local `0..size` space.
abstract class PhysicsEntity extends PositionComponent {
  PhysicsEntity({required this.level, super.position, super.size});

  static const double gravity = 1400;
  static const double terminalVelocity = 900;

  final Level level;
  final Vector2 velocity = Vector2.zero();

  bool onGround = false;
  bool hitWall = false;

  /// Where the bottom edge was before the last integration step. Stomps are
  /// tested against this so a fast fall can't skip past the window between
  /// two frames.
  double previousBottom = 0;

  double get left => position.x;
  double get right => position.x + size.x;
  double get top => position.y;
  double get bottom => position.y + size.y;
  double get centerX => position.x + size.x / 2;
  double get centerY => position.y + size.y / 2;

  void applyGravity(double dt) {
    velocity.y = math.min(velocity.y + gravity * dt, terminalVelocity);
  }

  /// Largest distance an entity may travel between collision tests. Anything
  /// further than half a tile per step could skip clean over a solid tile.
  static const double _maxStepDistance = kTileSize * 0.5;

  /// Integrates X then Y against the tile grid. Sets [onGround] and [hitWall].
  ///
  /// The motion is split into sub-steps so a long frame (a throttled browser
  /// tab, a stalled main thread) can never tunnel an entity through the floor.
  void moveWithCollisions(double dt) {
    onGround = false;
    hitWall = false;
    previousBottom = bottom;

    final distance = math.max((velocity.x * dt).abs(), (velocity.y * dt).abs());
    final steps = math.max(1, (distance / _maxStepDistance).ceil());
    final stepDt = dt / steps;
    for (var i = 0; i < steps; i++) {
      _moveX(velocity.x * stepDt);
      _moveY(velocity.y * stepDt);
    }
  }

  void _moveX(double dx) {
    if (dx == 0) return;
    position.x += dx;

    final rowStart = (top / kTileSize).floor();
    final rowEnd = ((bottom - 0.01) / kTileSize).floor();
    final colStart = (left / kTileSize).floor();
    final colEnd = ((right - 0.01) / kTileSize).floor();

    // Scan from the leading edge inward so the first solid tile found is the
    // one actually blocking us.
    final cols = dx > 0
        ? [for (var c = colStart; c <= colEnd; c++) c]
        : [for (var c = colEnd; c >= colStart; c--) c];

    for (final col in cols) {
      for (var row = rowStart; row <= rowEnd; row++) {
        if (!level.isSolid(col, row)) continue;
        position.x = dx > 0 ? col * kTileSize - size.x : (col + 1) * kTileSize;
        velocity.x = 0;
        hitWall = true;
        return;
      }
    }
  }

  void _moveY(double dy) {
    if (dy == 0) return;
    position.y += dy;

    final colStart = (left / kTileSize).floor();
    final colEnd = ((right - 0.01) / kTileSize).floor();
    final rowStart = (top / kTileSize).floor();
    final rowEnd = ((bottom - 0.01) / kTileSize).floor();

    final rows = dy > 0
        ? [for (var r = rowStart; r <= rowEnd; r++) r]
        : [for (var r = rowEnd; r >= rowStart; r--) r];

    for (final row in rows) {
      for (var col = colStart; col <= colEnd; col++) {
        if (!level.isSolid(col, row)) continue;
        if (dy > 0) {
          position.y = row * kTileSize - size.y;
          onGround = true;
        } else {
          position.y = (row + 1) * kTileSize;
        }
        velocity.y = 0;
        return;
      }
    }
  }

  /// Axis-aligned overlap test used for all entity-vs-entity checks. Doing this
  /// by hand (rather than via collision callbacks) keeps stomp resolution
  /// deterministic within a single frame.
  bool overlaps(PhysicsEntity other, {double inset = 0}) {
    return left + inset < other.right - inset &&
        right - inset > other.left + inset &&
        top + inset < other.bottom - inset &&
        bottom - inset > other.top + inset;
  }
}
