import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'level.dart';
import 'palette.dart';

/// Sky, clouds and rolling hills. Sized to the whole level so it is always
/// behind the camera no matter where the princess wanders.
class Scenery extends PositionComponent {
  Scenery({required this.level}) : super(priority: -20) {
    size = Vector2(level.width, level.height);
  }

  final Level level;

  final List<_Cloud> _clouds = [];
  double _time = 0;

  @override
  Future<void> onLoad() async {
    final random = math.Random(7);
    for (var i = 0; i < 26; i++) {
      _clouds.add(
        _Cloud(
          x: random.nextDouble() * level.width,
          y: 20 + random.nextDouble() * 130,
          scale: 0.6 + random.nextDouble() * 0.9,
          drift: 3 + random.nextDouble() * 6,
        ),
      );
    }
  }

  @override
  void update(double dt) => _time += dt;

  @override
  void render(Canvas canvas) {
    final sky = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = Gradient.linear(
          Offset.zero,
          Offset(0, size.y),
          const [Pal.skyTop, Pal.skyMid, Pal.skyBottom],
          const [0, 0.55, 1],
        ),
    );

    _renderHills(
      canvas,
      amplitude: 26,
      baseY: size.y - 96,
      colour: Pal.hillFar,
      wavelength: 340,
      phase: 0,
    );
    _renderHills(
      canvas,
      amplitude: 34,
      baseY: size.y - 54,
      colour: Pal.hillNear,
      wavelength: 230,
      phase: 1.4,
    );

    for (final cloud in _clouds) {
      cloud.render(canvas, _time);
    }
  }

  void _renderHills(
    Canvas canvas, {
    required double amplitude,
    required double baseY,
    required Color colour,
    required double wavelength,
    required double phase,
  }) {
    final path = Path()..moveTo(0, size.y);
    for (var x = 0.0; x <= size.x; x += 12) {
      final y =
          baseY - math.sin(x / wavelength * math.pi * 2 + phase) * amplitude;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.x, size.y)
      ..close();
    canvas.drawPath(path, Paint()..color = colour);
  }
}

class _Cloud {
  _Cloud({
    required this.x,
    required this.y,
    required this.scale,
    required this.drift,
  });

  final double x;
  final double y;
  final double scale;
  final double drift;

  void render(Canvas canvas, double time) {
    final paint = Paint()..color = Pal.cloud.withValues(alpha: 0.85);
    final cx = x + math.sin(time * 0.12 + x) * drift;
    canvas.save();
    canvas.translate(cx, y);
    canvas.scale(scale);
    canvas
      ..drawCircle(const Offset(0, 0), 11, paint)
      ..drawCircle(const Offset(13, 3), 8, paint)
      ..drawCircle(const Offset(-13, 4), 9, paint)
      ..drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-14, 2, 28, 10),
          const Radius.circular(5),
        ),
        paint,
      );
    canvas.restore();
  }
}

/// Draws the solid tile grid. Tiles are culled to the camera's visible rect so
/// the whole 100-column level costs almost nothing to render.
class Terrain extends PositionComponent {
  Terrain({required this.level}) : super(priority: -10) {
    size = Vector2(level.width, level.height);
    visible = Rect.fromLTWH(0, 0, level.width, level.height);
  }

  final Level level;

  /// Set each frame by the game so rendering can cull off-screen tiles.
  late Rect visible;

  @override
  void render(Canvas canvas) {
    final colStart = math.max(0, (visible.left / kTileSize).floor() - 1);
    final colEnd = math.min(
      kLevelCols - 1,
      (visible.right / kTileSize).ceil() + 1,
    );

    for (var row = 0; row < kLevelRowCount; row++) {
      for (var col = colStart; col <= colEnd; col++) {
        final kind = level.kindAt(col, row);
        if (kind == TileKind.none) continue;
        final rect = Rect.fromLTWH(
          col * kTileSize,
          row * kTileSize,
          kTileSize,
          kTileSize,
        );
        final exposed = !level.isSolid(col, row - 1);
        if (kind == TileKind.ground) {
          _renderGround(canvas, rect, exposed);
        } else {
          _renderPlatform(canvas, rect, col, row);
        }
      }
    }
  }

  void _renderGround(Canvas canvas, Rect rect, bool exposed) {
    canvas.drawRect(rect, Paint()..color = Pal.dirt);
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.bottom - 4, rect.width, 4),
      Paint()..color = Pal.dirtDark,
    );
    if (!exposed) return;

    final cap = Rect.fromLTWH(rect.left, rect.top, rect.width, 9);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        cap,
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(5),
      ),
      Paint()..color = Pal.grassTop,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(rect.left + 2, rect.top + 1.5, rect.width - 4, 3),
        topLeft: const Radius.circular(2),
        topRight: const Radius.circular(2),
      ),
      Paint()..color = Pal.grassTopLight,
    );
  }

  void _renderPlatform(Canvas canvas, Rect rect, int col, int row) {
    final leftEnd = !level.isSolid(col - 1, row);
    final rightEnd = !level.isSolid(col + 1, row);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        rect.deflate(0.5),
        topLeft: Radius.circular(leftEnd ? 8 : 0),
        bottomLeft: Radius.circular(leftEnd ? 8 : 0),
        topRight: Radius.circular(rightEnd ? 8 : 0),
        bottomRight: Radius.circular(rightEnd ? 8 : 0),
      ),
      Paint()..color = Pal.platform,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(rect.left, rect.top, rect.width, 5),
        topLeft: Radius.circular(leftEnd ? 6 : 0),
        topRight: Radius.circular(rightEnd ? 6 : 0),
      ),
      Paint()..color = Pal.platformEdge,
    );
  }
}
