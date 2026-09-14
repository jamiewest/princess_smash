import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:princess_smash/game/hud.dart';
import 'package:princess_smash/game/letter_drop.dart';

LetterDropChallenge challenge({
  String letter = 'a',
  String word = 'cat',
  List<bool>? filled,
  void Function(int slot)? onPlaced,
}) {
  return LetterDropChallenge(
    letter: letter,
    word: word,
    filled: filled ?? List.filled(word.length, false),
    onPlaced: onPlaced ?? (_) {},
    viewSize: Vector2(480, 270),
  );
}

/// Grabs the floating tile and drops it in the middle of box [slot], the way
/// a finger-drag would.
void dragToSlot(LetterDropChallenge drop, String word, int slot) {
  final target = Hud.wordSlotRect(word.length, slot).center;
  expect(drop.grabAt(drop.tileCenter.clone()), isTrue);
  drop.dragBy(Vector2(target.dx, target.dy) - drop.tileCenter);
  drop.release();
}

void main() {
  group('word bar slots', () {
    test('are centred in the view and sized like the hud tiles', () {
      final first = Hud.wordSlotRect(3, 0);
      final last = Hud.wordSlotRect(3, 2);
      expect(first.top, Hud.wordTileTop);
      expect(first.width, Hud.wordTileWidth);
      expect(first.height, Hud.wordTileHeight);
      // The bar as a whole sits symmetric around the view's middle.
      expect(first.left + last.right, closeTo(480, 0.001));
    });

    test('leave a gap between neighbouring boxes', () {
      final a = Hud.wordSlotRect(5, 1);
      final b = Hud.wordSlotRect(5, 2);
      expect(b.left - a.right, closeTo(Hud.wordTileGap, 0.001));
    });
  });

  group('letter drop challenge', () {
    test('a grab far from the tile does not pick it up', () {
      final drop = challenge();
      expect(drop.grabAt(Vector2(20, 20)), isFalse);

      drop.dragBy(Vector2(100, -100));
      drop.release();
      expect(drop.tileCenter, Vector2(240, 270 * 0.55));
    });

    test('dropping on the matching box places the letter', () {
      int? placed;
      final drop = challenge(
        letter: 'a',
        word: 'cat',
        onPlaced: (slot) => placed = slot,
      );

      dragToSlot(drop, 'cat', 1);
      expect(placed, 1);
    });

    test('dropping on the wrong box places nothing and bounces home', () {
      int? placed;
      final drop = challenge(
        letter: 'a',
        word: 'cat',
        onPlaced: (slot) => placed = slot,
      );

      dragToSlot(drop, 'cat', 0);
      expect(placed, isNull);

      // The spring animation carries the tile back to its resting spot.
      for (var i = 0; i < 120; i++) {
        drop.update(1 / 60);
      }
      expect(drop.tileCenter.x, closeTo(240, 1));
      expect(drop.tileCenter.y, closeTo(270 * 0.55, 1));
    });

    test('a box that is already filled does not accept a second letter', () {
      int? placed;
      final drop = challenge(
        letter: 't',
        word: 'tot',
        filled: [true, false, false],
        onPlaced: (slot) => placed = slot,
      );

      dragToSlot(drop, 'tot', 0);
      expect(placed, isNull);
    });

    test('with duplicate letters, any open matching box counts', () {
      int? placed;
      final drop = challenge(
        letter: 't',
        word: 'tot',
        filled: [true, false, false],
        onPlaced: (slot) => placed = slot,
      );

      dragToSlot(drop, 'tot', 2);
      expect(placed, 2);
    });

    test('a drop in empty space just floats the tile back home', () {
      int? placed;
      final drop = challenge(onPlaced: (slot) => placed = slot);

      expect(drop.grabAt(drop.tileCenter.clone()), isTrue);
      drop.dragBy(Vector2(150, 40));
      drop.release();
      expect(placed, isNull);

      for (var i = 0; i < 120; i++) {
        drop.update(1 / 60);
      }
      expect(drop.tileCenter.x, closeTo(240, 1));
    });

    test('the tile cannot be dragged out of the view', () {
      final drop = challenge();
      expect(drop.grabAt(drop.tileCenter.clone()), isTrue);
      drop.dragBy(Vector2(-9999, 9999));

      expect(drop.tileCenter.x, LetterDropChallenge.tileSide / 2);
      expect(drop.tileCenter.y, 270 - LetterDropChallenge.tileSide / 2);
    });

    test('after a correct drop the tile cannot be grabbed again', () {
      final drop = challenge(letter: 'a', word: 'cat');
      dragToSlot(drop, 'cat', 1);

      expect(drop.grabAt(drop.tileCenter.clone()), isFalse);
    });
  });
}
