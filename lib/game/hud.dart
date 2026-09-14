import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart' show FontWeight, TextStyle;

import 'palette.dart';
import 'pickups.dart';

/// Hearts, gem tally, distance-home meter and — on lesson levels — the focus
/// word filling in letter by letter. Lives in the camera viewport so it stays
/// put while the world scrolls.
class Hud extends PositionComponent {
  Hud({
    required this.maxHearts,
    required this.totalGems,
    this.word,
    this.accent = Pal.dress,
  }) : super(position: Vector2(10, 8), priority: 100);

  final int maxHearts;
  final int totalGems;

  /// Accent colour for the distance-home meter, matched to the hero's outfit.
  final Color accent;

  /// The lesson's focus word, or null on free-play levels.
  final String? word;

  int hearts = 3;
  int gems = 0;
  double progress = 0;

  /// Which slots of [word] have been collected; synced by the game.
  List<bool> lettersFound = const [];

  static const wordTileWidth = 15.0;
  static const wordTileHeight = 17.0;
  static const wordTileGap = 3.0;
  static const wordTileTop = 8.0;

  /// The viewport-space box for slot [index] of a [wordLength]-letter word.
  ///
  /// Shared with [LetterDropChallenge] so the drop targets sit exactly on the
  /// boxes the HUD draws. The word bar is centred in the fixed 480-wide view.
  static Rect wordSlotRect(int wordLength, int index) {
    final total = wordLength * (wordTileWidth + wordTileGap) - wordTileGap;
    final startX = (480 - total) / 2;
    return Rect.fromLTWH(
      startX + index * (wordTileWidth + wordTileGap),
      wordTileTop,
      wordTileWidth,
      wordTileHeight,
    );
  }

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
    _renderWord(canvas);
  }

  /// Letter tiles across the top middle: collected letters fill in, missing
  /// ones show as little dashes — like a friendly hangman board.
  void _renderWord(Canvas canvas) {
    final word = this.word;
    if (word == null || word.isEmpty) return;

    for (var i = 0; i < word.length; i++) {
      final found = i < lettersFound.length && lettersFound[i];
      // Slot rects are in viewport space; the component sits at (10, 8).
      final rect = wordSlotRect(
        word.length,
        i,
      ).shift(Offset(-position.x, -position.y));
      final tile = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(
        tile,
        Paint()..color = Pal.cloud.withValues(alpha: found ? 0.95 : 0.4),
      );
      canvas.drawRRect(
        tile,
        Paint()
          ..color = found ? Pal.crown : Pal.ink.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      if (found) {
        _label.render(
          canvas,
          word[i],
          Vector2(rect.center.dx, rect.center.dy),
          anchor: Anchor.center,
        );
      } else {
        canvas.drawLine(
          Offset(rect.left + 4, rect.bottom - 4.5),
          Offset(rect.right - 4, rect.bottom - 4.5),
          Paint()
            ..color = Pal.ink.withValues(alpha: 0.4)
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round,
        );
      }
    }
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
      Paint()..color = accent,
    );
    canvas.drawCircle(
      Offset(left + width * progress.clamp(0, 1), 7),
      4.5,
      Paint()..color = Pal.crown,
    );
    _label.render(canvas, 'home', Vector2(left + width - 26, 12));
  }
}
