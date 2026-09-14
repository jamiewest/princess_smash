import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart' show FontWeight, TextStyle;

import 'hud.dart';
import 'palette.dart';

/// The little sorting game that pops up when Emery catches a letter: the world
/// pauses, the caught letter floats mid-screen, and it has to be dragged into
/// the right box of the word bar up top before the journey continues.
///
/// Any empty box whose letter matches counts as correct — so with a word like
/// "little", either open `t` box will do. A wrong box wiggles the tile back
/// home for another try; there is no penalty, just practice.
///
/// Lives in the camera viewport, covering the whole fixed-resolution view so
/// a small hand can start the drag anywhere near the tile.
class LetterDropChallenge extends PositionComponent with DragCallbacks {
  LetterDropChallenge({
    required this.letter,
    required this.word,
    required this.filled,
    required this.onPlaced,
    required Vector2 viewSize,
    this.shadow = Pal.dressDark,
  }) : super(size: viewSize.clone(), priority: 200) {
    _home = Vector2(viewSize.x / 2, viewSize.y * 0.55);
    tileCenter = _home.clone();
  }

  /// The letter Emery just caught, lowercase a-z.
  final String letter;

  /// The lesson's focus word the boxes spell.
  final String word;

  /// The game's live slots list, shared so already-filled boxes draw solid.
  final List<bool> filled;

  /// Called with the slot index once the letter lands in a correct box.
  final void Function(int slot) onPlaced;

  /// Drop-shadow under the big tile, matched to the hero's outfit — the same
  /// shade the in-world letter pickups use.
  final Color shadow;

  /// The dragged tile is chunky — an easy target for a 7-year-old's finger.
  static const double tileSide = 30;

  /// Extra reach around the tile and the boxes, so grabs and drops don't have
  /// to be pixel-perfect.
  static const double grabSlop = 10;
  static const double dropSlop = 6;

  late final Vector2 _home;

  /// Centre of the floating letter tile, in viewport coordinates.
  late Vector2 tileCenter;

  bool _dragging = false;
  bool _placed = false;
  double _phase = 0;

  /// Which box just got a wrong drop, and how long its wiggle has left.
  int _wrongSlot = -1;
  double _wrongTime = 0;

  static final _glyph = TextPaint(
    style: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: Pal.ink,
    ),
  );
  static final _slotGlyph = TextPaint(
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Pal.ink,
    ),
  );
  static final _hint = TextPaint(
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Pal.cloud,
    ),
  );

  Rect get _tileRect => Rect.fromCenter(
    center: _offset(tileCenter),
    width: tileSide,
    height: tileSide,
  );

  static Offset _offset(Vector2 v) => Offset(v.x, v.y);

  /// Starts a drag if [point] is on (or near) the letter tile.
  bool grabAt(Vector2 point) {
    if (_placed) return false;
    if (!_tileRect.inflate(grabSlop).contains(_offset(point))) return false;
    _dragging = true;
    return true;
  }

  /// Moves the held tile, kept inside the view so it can't be lost off-screen.
  void dragBy(Vector2 delta) {
    if (!_dragging) return;
    tileCenter += delta;
    tileCenter.x = tileCenter.x.clamp(tileSide / 2, size.x - tileSide / 2);
    tileCenter.y = tileCenter.y.clamp(tileSide / 2, size.y - tileSide / 2);
  }

  /// Lets go of the tile and resolves where it landed.
  void release() {
    if (!_dragging) return;
    _dragging = false;
    final slot = _slotUnderTile();
    if (slot == null) return;
    if (!filled[slot] && word[slot] == letter) {
      _placed = true;
      onPlaced(slot);
    } else {
      _wrongSlot = slot;
      _wrongTime = 0.6;
    }
  }

  /// The word-bar box under the tile's centre, if any.
  int? _slotUnderTile() {
    for (var i = 0; i < word.length; i++) {
      final rect = Hud.wordSlotRect(word.length, i).inflate(dropSlop);
      if (rect.contains(_offset(tileCenter))) return i;
    }
    return null;
  }

  @override
  void update(double dt) {
    _phase += dt;
    _wrongTime = math.max(0, _wrongTime - dt);
    if (!_dragging && !_placed) {
      // Spring gently back home after a miss (or a drop in empty space).
      final t = 1 - math.pow(0.002, dt).toDouble();
      tileCenter += (_home - tileCenter) * t;
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    grabAt(event.localPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final delta = event.localDelta;
    // The delta is NaN when the pointer wanders off the canvas.
    if (!delta.x.isNaN && !delta.y.isNaN) dragBy(delta);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    release();
  }

  @override
  void render(Canvas canvas) {
    // Dusk falls over the paused meadow so the letter game takes the stage.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Pal.ink.withValues(alpha: 0.4),
    );

    _renderBoxes(canvas);

    _hint.render(
      canvas,
      'Drag the letter into the right box!',
      Vector2(size.x / 2, Hud.wordTileTop + Hud.wordTileHeight + 14),
      anchor: Anchor.center,
    );

    _renderTile(canvas);
  }

  /// Redraws the word bar on top of the scrim: filled boxes solid, open boxes
  /// glowing as drop targets, a wrongly-tried box wiggling in soft red.
  void _renderBoxes(Canvas canvas) {
    final pulse = 0.5 + math.sin(_phase * 5) * 0.5;
    for (var i = 0; i < word.length; i++) {
      var rect = Hud.wordSlotRect(word.length, i);
      final wiggling = i == _wrongSlot && _wrongTime > 0;
      if (wiggling) {
        rect = rect.shift(Offset(math.sin(_wrongTime * 40) * 2, 0));
      }
      final found = i < filled.length && filled[i];
      final tile = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(
        tile,
        Paint()..color = Pal.cloud.withValues(alpha: found ? 0.95 : 0.75),
      );
      final ring = wiggling
          ? Pal.heart
          : found
          ? Pal.crown
          : Pal.crown.withValues(alpha: 0.45 + 0.55 * pulse);
      canvas.drawRRect(
        tile,
        Paint()
          ..color = ring
          ..style = PaintingStyle.stroke
          ..strokeWidth = found ? 1.2 : 1.8,
      );
      if (found) {
        _slotGlyph.render(
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

  /// The caught letter, drawn like a big cousin of the in-world pickup.
  void _renderTile(Canvas canvas) {
    final bob = _dragging ? 0.0 : math.sin(_phase * 2.6) * 2.6;
    final tilt = _dragging ? 0.0 : math.sin(_phase * 2.2) * 0.06;

    canvas.save();
    canvas.translate(tileCenter.x, tileCenter.y + bob);
    canvas.rotate(tilt);

    final tile = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: tileSide, height: tileSide),
      const Radius.circular(7),
    );
    canvas.drawRRect(tile.shift(const Offset(0, 2.2)), Paint()..color = shadow);
    canvas.drawRRect(tile, Paint()..color = Pal.cloud);
    canvas.drawRRect(
      tile.deflate(1.0),
      Paint()
        ..color = Pal.crown
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _glyph.render(canvas, letter, Vector2.zero(), anchor: Anchor.center);
    canvas.restore();
  }
}
