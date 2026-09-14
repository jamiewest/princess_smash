import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart' show KeyEventResult;
import 'package:flutter/services.dart';

import 'appearance.dart';
import 'education/lesson.dart';
import 'enemy.dart';
import 'goal.dart';
import 'hud.dart';
import 'letter_drop.dart';
import 'level.dart';
import 'palette.dart';
import 'pickups.dart';
import 'princess.dart';
import 'quiz_gate.dart';
import 'scenery.dart';
import 'sparkle.dart';

enum GameStatus { title, playing, quiz, letterDrop, gameOver, won }

const String kTitleOverlay = 'title';
const String kGameOverOverlay = 'gameOver';
const String kWinOverlay = 'win';
const String kQuizOverlay = 'quiz';

/// A little side-scrolling platformer: the princess is lost, and the way home
/// runs east across the meadow. Jump on the blobs to squash them.
///
/// With a [lesson] and a generated [Level], the road home also teaches:
/// letter pickups spell the lesson's focus word and rose gates pause play
/// with a quiz question until it is answered.
class PrincessSmashGame extends FlameGame with KeyboardEvents {
  PrincessSmashGame({
    this.lesson,
    Level? level,
    this.appearance = HeroAppearance.emery,
  }) : _customLevel = level,
       super(
         camera: CameraComponent.withFixedResolution(
           width: viewWidth,
           height: viewHeight,
         ),
       );

  /// The educational goals behind this level, or null for free play.
  final Lesson? lesson;

  /// How the hero looks and is spoken about in the story text.
  final HeroAppearance appearance;

  final Level? _customLevel;

  static const double viewWidth = 480;
  static const double viewHeight = 270;
  static const int maxHearts = 3;

  static final Set<LogicalKeyboardKey> _leftKeys = {
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.keyA,
  };
  static final Set<LogicalKeyboardKey> _rightKeys = {
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.keyD,
  };
  static final Set<LogicalKeyboardKey> _jumpKeys = {
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.keyZ,
  };
  static final Set<LogicalKeyboardKey> _confirmKeys = {
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
  };

  late final Level level;
  late final Scenery scenery;
  late final Terrain terrain;
  late final Hud hud;
  late HomeDoor door;
  late Princess princess;

  final List<Enemy> enemies = [];
  final List<Pickup> pickups = [];
  final List<QuizGate> gates = [];
  final List<Component> _spawned = [];

  GameStatus status = GameStatus.title;
  int hearts = maxHearts;
  int gems = 0;

  /// Which slots of the focus word have been collected.
  List<bool> lettersFound = const [];

  /// Wrong quiz answers this run; the win screen celebrates a clean sweep.
  int quizMisses = 0;

  /// The gate whose question is on screen while [status] is quiz.
  QuizGate? activeGate;

  /// The drag-the-letter mini-game on screen while [status] is letterDrop.
  LetterDropChallenge? letterChallenge;

  int get lettersCollected => lettersFound.where((found) => found).length;

  final Set<LogicalKeyboardKey> _keys = {};
  Vector2 _lastSafeSpot = Vector2.zero();
  double _respawnDelay = 0;

  /// -1, 0 or 1, driven by the on-screen walk pad. Merged with the keyboard
  /// every frame, and deliberately not cleared on restart so a thumb held
  /// through a respawn keeps walking, same as a held arrow key.
  double touchMove = 0;

  @override
  Color backgroundColor() => Pal.skyMid;

  @override
  Future<void> onLoad() async {
    level = _customLevel ?? Level.parse();
    scenery = Scenery(level: level);
    terrain = Terrain(
      level: level,
      platform: appearance.platform,
      platformEdge: appearance.platformEdge,
    );
    hud = Hud(
      maxHearts: maxHearts,
      totalGems: level.gemCount,
      word: lesson?.word,
      accent: appearance.outfit,
    );

    await world.addAll([scenery, terrain]);
    camera.viewport.add(hud);

    _spawnLevelEntities();
    _snapCamera();
    overlays.add(kTitleOverlay);
  }

  /// Creates (or recreates) every dynamic thing described by the ASCII map.
  void _spawnLevelEntities() {
    for (final entity in _spawned) {
      entity.removeFromParent();
    }
    _spawned.clear();
    enemies.clear();
    pickups.clear();
    gates.clear();
    activeGate = null;
    _removeLetterChallenge();
    quizMisses = 0;
    level.resetGates();
    lettersFound = List.filled(lesson?.word.length ?? 0, false);

    for (final placement in level.placements) {
      switch (placement.symbol) {
        case 'P':
          princess = Princess(
            level: level,
            spawn: Vector2(placement.x + 2, placement.y + kTileSize - 30),
            appearance: appearance,
          );
          _lastSafeSpot = princess.position.clone();
          _spawn(princess);
        case 'E':
        case 'F':
          final enemy = Enemy(
            level: level,
            spawn: Vector2(placement.x + 1, placement.y + kTileSize - 20),
            kind: placement.symbol == 'E' ? EnemyKind.walker : EnemyKind.hopper,
          );
          enemies.add(enemy);
          _spawn(enemy);
        case '*':
          final gem = Gem(spawn: Vector2(placement.x + 4, placement.y + 3));
          pickups.add(gem);
          _spawn(gem);
        case 'H':
          final heart = HeartPickup(
            spawn: Vector2(placement.x + 3, placement.y + 4),
          );
          pickups.add(heart);
          _spawn(heart);
        case 'D':
          door = HomeDoor(
            spawn: Vector2(placement.x, placement.y),
            roof: appearance.roof,
          );
          _spawn(door);
      }
    }
    _spawnLessonEntities();
  }

  /// Letters and quiz gates need their reading order, so they are matched to
  /// the word and question list by column rather than parse order.
  void _spawnLessonEntities() {
    final lesson = this.lesson;
    if (lesson == null) return;

    final letterSpots = level.placements.where((p) => p.isLetter).toList()
      ..sort((a, b) => a.col.compareTo(b.col));
    for (var i = 0; i < letterSpots.length; i++) {
      final spot = letterSpots[i];
      final letter = LetterPickup(
        spawn: Vector2(spot.x + 3, spot.y + 3),
        letter: spot.symbol,
        index: i,
        shadow: appearance.outfitDark,
      );
      pickups.add(letter);
      _spawn(letter);
    }

    final gateSpots = level.placements.where((p) => p.symbol == 'G').toList()
      ..sort((a, b) => a.col.compareTo(b.col));
    for (var i = 0; i < gateSpots.length; i++) {
      final spot = gateSpots[i];
      final gate = QuizGate(
        question: lesson.questions[i],
        col: spot.col,
        topRow: spot.row,
      );
      gates.add(gate);
      _spawn(gate);
    }
  }

  void _spawn(Component component) {
    _spawned.add(component);
    world.add(component);
  }

  /// Starts (or restarts) a run. With [jump], the action that dismissed the
  /// menu — a SPACE press, a click on the start button — also becomes Pip's
  /// first jump, so starting always launches her rather than swallowing the
  /// input. The jump goes through [Princess.requestJump] like any other, so
  /// buffering and variable height behave normally.
  void startGame({bool jump = false}) {
    hearts = maxHearts;
    gems = 0;
    _respawnDelay = 0;
    _spawnLevelEntities();
    // Re-sync with the real keyboard rather than clearing: a direction key
    // still held from the previous run should keep working through a restart.
    _keys
      ..clear()
      ..addAll(HardwareKeyboard.instance.logicalKeysPressed);
    status = GameStatus.playing;
    overlays
      ..remove(kTitleOverlay)
      ..remove(kGameOverOverlay)
      ..remove(kWinOverlay);
    _snapCamera();
    if (jump) {
      princess.requestJump();
    }
  }

  /// Longest physics step we will ever simulate. Returning to a backgrounded
  /// tab hands us a multi-second `dt`; without this the world would lurch.
  static const double _maxFrameDelta = 1 / 20;

  @override
  void update(double dt) {
    final step = math.min(dt, _maxFrameDelta);
    final playing = status == GameStatus.playing;

    // Freezing the world with dt = 0 keeps the component lifecycle running
    // (mounts, removals) while nothing moves during menus.
    super.update(playing ? step : 0);
    if (!playing) {
      scenery.update(step);
      // The mini-game keeps animating (bobbing tile, box glow) while the
      // frozen world waits, exactly like the scenery.
      letterChallenge?.update(step);
    } else {
      _applyInput();
      _resolveEnemies();
      _resolvePickups();
      _resolveGates();
      _resolveGoal();
      _checkFallOut(step);
      _syncHud();
      _pruneRemoved();
    }
    _updateCamera(step);
  }

  void _applyInput() {
    if (!princess.isAlive) {
      princess.moveInput = 0;
      return;
    }
    final left = _keys.any(_leftKeys.contains) || touchMove < 0;
    final right = _keys.any(_rightKeys.contains) || touchMove > 0;
    princess.moveInput = (right ? 1 : 0) + (left ? -1 : 0);

    if (princess.onGround && princess.velocity.x.abs() < 40) {
      _lastSafeSpot = princess.position.clone();
    }
  }

  /// Stomp resolution. A hit counts as a smash only while falling and only
  /// while the princess' feet are still above the enemy's middle.
  void _resolveEnemies() {
    if (!princess.isAlive) return;
    for (final enemy in enemies) {
      if (enemy.isDying || !enemy.isMounted) continue;
      if (!princess.overlaps(enemy, inset: 1.5)) continue;

      if (enemy.isStompedBy(princess)) {
        enemy.squash();
        princess.position.y = enemy.top - princess.size.y;
        princess.bounce();
        world.add(
          SparkleBurst(
            spawn: Vector2(enemy.centerX, enemy.centerY),
            colour: Pal.sparkle,
            count: 12,
          ),
        );
      } else if (!princess.isInvulnerable) {
        _damagePrincess(fromX: enemy.centerX);
      }
    }
  }

  void _resolvePickups() {
    if (!princess.isAlive) return;
    final body = princess.toRect();
    for (final pickup in pickups) {
      if (pickup.collected || !pickup.isMounted) continue;
      if (!body.overlaps(pickup.toRect())) continue;

      pickup.collected = true;
      pickup.removeFromParent();
      final centre = Vector2(
        pickup.position.x + pickup.size.x / 2,
        pickup.position.y + pickup.size.y / 2,
      );
      if (pickup is Gem) {
        gems++;
        world.add(SparkleBurst(spawn: centre, colour: Pal.gemLight, count: 9));
      } else if (pickup is LetterPickup) {
        world.add(
          SparkleBurst(spawn: centre, colour: Pal.crown, count: 14, speed: 90),
        );
        _startLetterDrop(pickup.letter);
        // The world is pausing for the mini-game; anything else she brushed
        // this frame gets collected the moment play resumes.
        return;
      } else {
        hearts = math.min(maxHearts, hearts + 1);
        world.add(SparkleBurst(spawn: centre, colour: Pal.heart, count: 12));
      }
    }
  }

  /// Catching a letter pauses the world: the caught tile has to be dragged
  /// into the right box of the word bar before the journey continues.
  void _startLetterDrop(String letter) {
    status = GameStatus.letterDrop;
    final challenge = LetterDropChallenge(
      letter: letter,
      word: lesson!.word,
      filled: lettersFound,
      onPlaced: _onLetterPlaced,
      viewSize: Vector2(viewWidth, viewHeight),
      shadow: appearance.outfitDark,
    );
    letterChallenge = challenge;
    camera.viewport.add(challenge);
  }

  /// Called by the challenge once the letter lands in a correct box.
  void _onLetterPlaced(int slot) {
    lettersFound[slot] = true;
    final box = Hud.wordSlotRect(lesson!.word.length, slot);
    camera.viewport.add(
      SparkleBurst(
        spawn: Vector2(box.center.dx, box.center.dy),
        colour: Pal.crown,
        count: 14,
        speed: 70,
      )..priority = 150,
    );
    _removeLetterChallenge();
    status = GameStatus.playing;
    // Same re-sync as answerGate: keys may have changed during the pause.
    _keys
      ..clear()
      ..addAll(HardwareKeyboard.instance.logicalKeysPressed);
  }

  void _removeLetterChallenge() {
    letterChallenge?.removeFromParent();
    letterChallenge = null;
  }

  /// Reaching a locked gate pauses the world and pops the question card.
  void _resolveGates() {
    if (!princess.isAlive) return;
    for (final gate in gates) {
      if (gate.opened || !gate.isMounted) continue;
      if ((gate.centerX - princess.centerX).abs() > 30) continue;
      activeGate = gate;
      status = GameStatus.quiz;
      overlays.add(kQuizOverlay);
      return;
    }
  }

  /// Called by the quiz card. A correct answer swings the gate open and play
  /// resumes; a wrong one keeps the card up so she can try again.
  bool answerGate(int choiceIndex) {
    final gate = activeGate;
    if (gate == null || status != GameStatus.quiz) return false;
    if (choiceIndex != gate.question.answerIndex) {
      quizMisses++;
      return false;
    }
    level.openGate(gate.col);
    gate.open();
    world.add(
      SparkleBurst(
        spawn: Vector2(gate.centerX, gate.top + gate.size.y / 2),
        colour: Pal.sparkle,
        count: 18,
        speed: 120,
        lifetime: 0.8,
      ),
    );
    overlays.remove(kQuizOverlay);
    activeGate = null;
    status = GameStatus.playing;
    // While the quiz card held focus the game missed key events, so a key
    // released mid-quiz could read as still held. Re-sync with the real
    // keyboard, exactly like startGame does.
    _keys
      ..clear()
      ..addAll(HardwareKeyboard.instance.logicalKeysPressed);
    return true;
  }

  void _resolveGoal() {
    final distance = (door.position.x - princess.centerX).abs();
    door.excitement = (1 - distance / 260).clamp(0.0, 1.0);
    if (!princess.isAlive) return;
    if (princess.toRect().overlaps(door.toRect())) {
      status = GameStatus.won;
      world.add(
        SparkleBurst(
          spawn: Vector2(door.position.x + 12, door.position.y + 20),
          colour: Pal.crown,
          count: 20,
          speed: 140,
          lifetime: 0.9,
          dotRadius: 2.6,
        ),
      );
      overlays.add(kWinOverlay);
    }
  }

  void _checkFallOut(double dt) {
    if (princess.isAlive && princess.top > level.killPlaneY) {
      princess.isAlive = false;
      _loseHeart();
      _respawnDelay = 0.6;
    }
    if (!princess.isAlive && status == GameStatus.playing) {
      _respawnDelay -= dt;
      if (_respawnDelay <= 0) {
        princess.respawn(_lastSafeSpot);
      }
    }
  }

  void _damagePrincess({required double fromX}) {
    _loseHeart();
    if (status == GameStatus.playing) {
      princess.knockBack(fromX);
      world.add(
        SparkleBurst(
          spawn: Vector2(princess.centerX, princess.centerY),
          colour: Pal.heart,
          count: 8,
          speed: 70,
        ),
      );
    }
  }

  void _loseHeart() {
    hearts--;
    if (hearts > 0) return;
    hearts = 0;
    status = GameStatus.gameOver;
    overlays.add(kGameOverOverlay);
  }

  void _syncHud() {
    hud
      ..hearts = hearts
      ..gems = gems
      ..lettersFound = lettersFound
      ..progress = (princess.centerX / (door.position.x + 12)).clamp(0.0, 1.0);
  }

  void _pruneRemoved() {
    enemies.removeWhere((enemy) => enemy.isRemoved);
    pickups.removeWhere((pickup) => pickup.isRemoved);
    gates.removeWhere((gate) => gate.isRemoved);
  }

  Vector2 _cameraTarget() {
    final target = Vector2(princess.centerX, princess.centerY - 18);
    return Vector2(
      target.x.clamp(viewWidth / 2, level.width - viewWidth / 2),
      target.y.clamp(viewHeight / 2, level.height - viewHeight / 2),
    );
  }

  void _snapCamera() {
    camera.viewfinder.position = _cameraTarget();
  }

  void _updateCamera(double dt) {
    final target = _cameraTarget();
    final current = camera.viewfinder.position;
    // Exponential smoothing, frame-rate independent.
    final t = 1 - math.pow(0.0008, dt).toDouble();
    camera.viewfinder.position = current + (target - current) * t;
    if (camera.isMounted) {
      terrain.visible = camera.visibleWorldRect;
    }
  }

  /// Press from the on-screen jump button. Mirrors the SPACE key exactly: on
  /// a menu the press starts a run and doubles as the first jump; during play
  /// it feeds the usual buffered jump, with variable height while held.
  void pressJumpButton() {
    if (!isLoaded) return;
    // Same guard as the keyboard: a tap during a quiz card or the letter
    // mini-game must not restart the run underneath it.
    if (status == GameStatus.quiz || status == GameStatus.letterDrop) return;
    if (status != GameStatus.playing) {
      startGame(jump: true);
      princess.jumpHeld = true;
      return;
    }
    princess.jumpHeld = true;
    princess.requestJump();
  }

  /// Release for the on-screen jump button; cuts the jump short like a keyup.
  void releaseJumpButton() {
    if (!isLoaded) return;
    princess.releaseJump();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _keys
      ..clear()
      ..addAll(keysPressed);

    // While a quiz card or the letter mini-game is up, the run must not
    // restart from a stray SPACE; the quiz overlay also wants the keyboard.
    if (status == GameStatus.quiz || status == GameStatus.letterDrop) {
      return KeyEventResult.ignored;
    }

    if (event is KeyDownEvent && _confirmKeys.contains(event.logicalKey)) {
      if (status != GameStatus.playing) {
        final isJumpKey = _jumpKeys.contains(event.logicalKey);
        startGame(jump: isJumpKey);
        // The key is still physically down, so holding it should give the
        // full-height jump; the matching keyup releases it as usual. A mouse
        // start has no held key, which is why this stays out of startGame.
        if (isJumpKey) {
          princess.jumpHeld = true;
        }
        return KeyEventResult.handled;
      }
    }

    if (status != GameStatus.playing) return KeyEventResult.handled;

    if (_jumpKeys.contains(event.logicalKey)) {
      if (event is KeyDownEvent) {
        princess.jumpHeld = true;
        princess.requestJump();
      } else if (event is KeyUpEvent) {
        princess.releaseJump();
      }
    }
    return KeyEventResult.handled;
  }
}
