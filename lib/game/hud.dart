import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart' show FontWeight, TextStyle;

import 'palette.dart';
import 'pickups.dart';

/// Hearts, gem tally and distance-home meter. Lives in the camera viewport so
/// it stays put while the world scrolls.
class Hud extends PositionComponent {
  Hud({required this.maxHearts, required this.totalGems})
    : super(position: Vector2(10, 8), priority: 100);

  final int maxHearts;
  final int totalGems;

  int hearts = 3;
  int gems = 0;
  double progress = 0;

  static final _label = TextPaint(
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Pal.ink,
    ),
  );

  @override
  void render(Canvas canvas) {
    for (var i = 0; i < maxHearts; i++) {
      final rect = Rect.fromLTWH(i * 18.0, 0, 14, 13);
      drawHeart(
        canvas,
        rect,
        i < hearts ? Pal.heart : Pal.ink.withValues(alpha: 0.18),
      );
    }

    final gemOrigin = Offset(maxHearts * 18.0 + 8, 1.5);
    canvas.drawPath(
      Path()
        ..moveTo(gemOrigin.dx + 5, gemOrigin.dy)
        ..lineTo(gemOrigin.dx + 10, gemOrigin.dy + 4)
        ..lineTo(gemOrigin.dx + 5, gemOrigin.dy + 12)
        ..lineTo(gemOrigin.dx, gemOrigin.dy + 4)
        ..close(),
      Paint()..color = Pal.gem,
    );
    _label.render(
      canvas,
      '$gems/$totalGems',
      Vector2(gemOrigin.dx + 14, gemOrigin.dy - 1),
    );

    _renderProgress(canvas);
  }

  /// A little track showing how far along the road home she has come.
  void _renderProgress(Canvas canvas) {
    const width = 108.0;
    final left = 460 - width - 10.0;
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, 4, width, 6),
      const Radius.circular(3),
    );
    canvas.drawRRect(track, Paint()..color = Pal.cloud.withValues(alpha: 0.75));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 4, width * progress.clamp(0, 1), 6),
        const Radius.circular(3),
      ),
      Paint()..color = Pal.dress,
    );
    canvas.drawCircle(
      Offset(left + width * progress.clamp(0, 1), 7),
      4.5,
      Paint()..color = Pal.crown,
    );
    _label.render(canvas, 'home', Vector2(left + width - 26, 12));
  }
}
