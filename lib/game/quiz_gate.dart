import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart' show FontWeight, TextStyle;

import 'education/lesson.dart';
import 'level.dart';
import 'palette.dart';

/// A rose-covered gate locked across the road. Its solid tiles live in the
/// [Level] grid (so physics just works); this component only draws the gate
/// and remembers which [QuizQuestion] unlocks it. Answering correctly calls
/// [open], which plays a little swing-and-fade before the component removes
/// itself.
class QuizGate extends PositionComponent {
  QuizGate({required this.question, required this.col, required int topRow})
    : super(
        position: Vector2(col * kTileSize, topRow * kTileSize),
        size: Vector2(kTileSize, (kGroundRowStart - topRow) * kTileSize),
      );

  final QuizQuestion question;
  final int col;

  bool opened = false;

  double _time = 0;
  double _openProgress = 0;

  double get centerX => position.x + size.x / 2;
  double get top => position.y;

  static final _mark = TextPaint(
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: Pal.cloud,
    ),
  );

  /// Starts the opening animation; the level's solid tiles are cleared by the
  /// game at the same moment.
  void open() => opened = true;

  @override
  void update(double dt) {
    _time += dt;
    if (!opened) return;
    _openProgress += dt * 1.6;
    if (_openProgress >= 1) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final sway = math.sin(_time * 1.8) * 0.9;
    final fade = (1 - _openProgress).clamp(0.0, 1.0);

    canvas.save();
    // Swing up and away once opened.
    canvas.translate(0, -_openProgress * 30);

    final wood = Paint()..color = Pal.door.withValues(alpha: fade);
    final woodDark = Paint()..color = Pal.doorDark.withValues(alpha: fade);

    // Two posts and a row of cross bars, like a little garden gate.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 0, 5, size.y),
        const Radius.circular(2.5),
      ),
      wood,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.x - 6, 0, 5, size.y),
        const Radius.circular(2.5),
      ),
      wood,
    );
    for (var y = 8.0; y < size.y - 4; y += 18) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, y, size.x, 5),
          const Radius.circular(2.5),
        ),
        woodDark,
      );
    }

    // Climbing roses.
    final leaf = Paint()..color = Pal.hillNear.withValues(alpha: fade);
    final rose = Paint()..color = Pal.heart.withValues(alpha: fade);
    for (var i = 0; i < 5; i++) {
      final y = 10.0 + i * (size.y - 20) / 4;
      final x = size.x / 2 + math.sin(i * 2.1) * 7 + sway;
      canvas.drawCircle(Offset(x + 3, y + 3), 2.6, leaf);
      canvas.drawCircle(Offset(x, y), 3.2, rose);
      canvas.drawCircle(
        Offset(x - 1, y - 1),
        1.2,
        Paint()..color = Pal.cloud.withValues(alpha: 0.7 * fade),
      );
    }

    // The lock: a friendly question bubble in the middle of the gate.
    final lockCenter = Offset(size.x / 2, size.y * 0.45 + sway);
    canvas.drawCircle(
      lockCenter,
      8.5,
      Paint()..color = Pal.ink.withValues(alpha: 0.85 * fade),
    );
    canvas.drawCircle(
      lockCenter,
      8.5,
      Paint()
        ..color = Pal.crown.withValues(alpha: fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    if (fade > 0.5) {
      _mark.render(
        canvas,
        '?',
        Vector2(lockCenter.dx, lockCenter.dy),
        anchor: Anchor.center,
      );
    }
    canvas.restore();
  }
}
