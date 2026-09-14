import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import 'game/appearance.dart';
import 'game/education/curriculum.dart';
import 'game/education/lesson.dart';
import 'game/level_generator.dart';
import 'game/palette.dart';
import 'game/princess_smash_game.dart';
import 'ui/hero_maker.dart';
import 'ui/overlay_panel.dart';
import 'ui/quiz_panel.dart';
import 'ui/touch_controls.dart';

void main() {
  runApp(const PrincessSmashApp());
}

class PrincessSmashApp extends StatelessWidget {
  const PrincessSmashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Princess Smash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Pal.dress,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const LessonPickerScreen(),
    );
  }
}

/// The front door: pick free play, or one of the school lessons that a level
/// gets generated around.
class LessonPickerScreen extends StatelessWidget {
  const LessonPickerScreen({super.key});

  void _play(BuildContext context, Lesson? lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(lesson: lesson)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final byKind = <LessonKind, List<Lesson>>{};
    for (final lesson in kCurriculum) {
      byKind.putIfAbsent(lesson.kind, () => []).add(lesson);
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Pal.skyTop, Pal.skyMid, Pal.skyBottom],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            // The whole menu re-dresses itself in the hero's colours: pink
            // for a princess in her dress, blue for a prince in his tunic.
            child: ValueListenableBuilder<HeroAppearance>(
              valueListenable: heroAppearance,
              builder: (context, look, _) => ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                children: [
                  Text(
                    '${look.gender.title} Smash',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Pal.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Choose today's adventure",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Pal.ink.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _HeroCard(),
                  _LessonCard(
                    emoji: '👑',
                    title: 'Free Play',
                    subtitle: 'The classic meadow — just bounce home!',
                    accent: look.outfit,
                    onTap: () => _play(context, null),
                  ),
                  _Section(
                    emoji: '📚',
                    title: 'Word Builder',
                    blurb: 'Learn a big new word and what it means.',
                    lessons: byKind[LessonKind.vocabulary] ?? const [],
                    accent: look.outfit,
                    onPick: (lesson) => _play(context, lesson),
                  ),
                  _Section(
                    emoji: '👀',
                    title: 'Sight Words',
                    blurb: 'Spot and spell the words you see everywhere.',
                    lessons: byKind[LessonKind.sightWords] ?? const [],
                    accent: look.outfit,
                    onPick: (lesson) => _play(context, lesson),
                  ),
                  _Section(
                    emoji: '📖',
                    title: 'Story Time',
                    blurb:
                        'Read a little story, then remember it at the gates.',
                    lessons: byKind[LessonKind.story] ?? const [],
                    accent: look.outfit,
                    onPick: (lesson) => _play(context, lesson),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the current hero and opens the dress-up screen. Listens to
/// [heroAppearance] so the little preview refreshes after editing.
class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<HeroAppearance>(
      valueListenable: heroAppearance,
      builder: (context, look, _) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          color: Pal.cloud,
          elevation: 4,
          shadowColor: Pal.ink.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: look.outfit.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          child: ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HeroMakerScreen()),
            ),
            leading: HeroPreview(look: look, scale: 1.6),
            title: Text(
              look.titledName,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Pal.ink,
              ),
            ),
            subtitle: Text(
              'Tap to change hair, skin, eyes, and outfit',
              style: TextStyle(color: Pal.ink.withValues(alpha: 0.65)),
            ),
            trailing: Icon(Icons.brush_rounded, color: look.outfit),
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.emoji,
    required this.title,
    required this.blurb,
    required this.lessons,
    required this.accent,
    required this.onPick,
  });

  final String emoji;
  final String title;
  final String blurb;
  final List<Lesson> lessons;
  final Color accent;
  final void Function(Lesson lesson) onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Pal.ink,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  blurb,
                  style: TextStyle(
                    fontSize: 12,
                    color: Pal.ink.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final lesson in lessons)
          _LessonCard(
            emoji: emoji,
            title: lesson.title,
            subtitle: lesson.kind == LessonKind.story
                ? 'A story with ${lesson.questions.length} questions '
                      'to remember'
                : 'Spell "${lesson.word}" and answer '
                      '${lesson.questions.length} riddles',
            accent: accent,
            onTap: () => onPick(lesson),
          ),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      color: Pal.cloud,
      elevation: 4,
      shadowColor: Pal.ink.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: accent.withValues(alpha: 0.6), width: 2),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Text(emoji, style: const TextStyle(fontSize: 24)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Pal.ink),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Pal.ink.withValues(alpha: 0.65)),
        ),
        trailing: Icon(Icons.play_circle_fill, color: accent),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({this.lesson, super.key});

  final Lesson? lesson;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  /// A fresh seed per visit, so replaying a lesson from the picker builds a
  /// new road around the same goals.
  late final PrincessSmashGame _game = PrincessSmashGame(
    lesson: widget.lesson,
    appearance: heroAppearance.value,
    level: widget.lesson == null
        ? null
        : LevelGenerator(
            lesson: widget.lesson!,
            seed: math.Random().nextInt(1 << 30),
          ).build(),
  );

  /// Owned here so overlay buttons can hand keyboard focus straight back to
  /// the game after being tapped.
  final FocusNode _focusNode = FocusNode(debugLabel: 'princess-smash');

  /// Phones and tablets get the on-screen controls up front; anything else
  /// earns them the moment a real touch happens (touch laptops, mis-detected
  /// mobile browsers), so keyboard players never see them.
  bool _touchControls = switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.fuchsia => true,
    _ => false,
  };

  void _onPointerDown(PointerDownEvent event) {
    if (!_touchControls && event.kind == PointerDeviceKind.touch) {
      setState(() => _touchControls = true);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _start() {
    // A click on the start button counts as Pip's first jump, matching the
    // SPACE-to-start path.
    _game.startGame(jump: true);
    _focusNode.requestFocus();
  }

  bool _answer(int choiceIndex) {
    final correct = _game.answerGate(choiceIndex);
    if (correct) _focusNode.requestFocus();
    return correct;
  }

  HeroAppearance get _hero => _game.appearance;

  String get _titleHeading =>
      widget.lesson?.title ?? '${_hero.gender.title} Smash';

  String get _titleMessage {
    final lesson = widget.lesson;
    if (lesson == null) {
      return 'Poor ${_hero.titledName} took a wrong turn at the meadow.\n'
          'Help ${_hero.gender.object} bounce '
          '${_hero.gender.possessive} way home!';
    }
    final story = lesson.story;
    if (story != null) return '$story\n\n${lesson.intro}';
    return lesson.intro;
  }

  String _winMessage(PrincessSmashGame game) {
    final lesson = widget.lesson;
    if (lesson == null) {
      return '${_hero.name} made it back to '
          '${_hero.gender.possessive} cottage with '
          '${game.gems} of ${game.level.gemCount} gems\n'
          'and ${game.hearts} hearts to spare.';
    }
    final letters = game.lettersCollected;
    final total = lesson.word.length;
    final spelling = letters == total
        ? '${_hero.name} spelled the whole word "${lesson.word}"!'
        : '${_hero.name} found $letters of $total letters of '
              '"${lesson.word}" — can ${_hero.gender.subject} find them '
              'all next time?';
    final riddles = lesson.questions.isEmpty
        ? ''
        : game.quizMisses == 0
        ? '\nEvery gate riddle answered on the first try. Amazing!'
        : '\nAll the gate riddles solved — great sticking with it!';
    return '$spelling$riddles';
  }

  @override
  Widget build(BuildContext context) {
    final walkHint = _touchControls
        ? 'Hold ◀ ▶ to walk  •  the big button to jump and smash'
        : 'Arrow keys or A / D to walk  •  SPACE to jump and smash';
    return Scaffold(
      backgroundColor: Pal.ink,
      body: Listener(
        onPointerDown: _onPointerDown,
        child: Stack(
          children: [
            GameWidget<PrincessSmashGame>(
              game: _game,
              focusNode: _focusNode,
              autofocus: true,
              overlayBuilderMap: {
                kTitleOverlay: (_, game) => OverlayPanel(
                  title: _titleHeading,
                  message: _titleMessage,
                  hint: walkHint,
                  actionLabel: widget.lesson == null
                      ? 'Start the journey'
                      : "Let's go!",
                  accent: _hero.outfit,
                  onAction: _start,
                ),
                kGameOverOverlay: (_, game) => OverlayPanel(
                  title: 'Oh no!',
                  message:
                      '${_hero.name} is all out of hearts.\n'
                      '${_hero.gender.subjectCap} found ${game.gems} gems '
                      'along the way.',
                  hint: 'Every journey home deserves another try.',
                  actionLabel: 'Try again',
                  accent: _hero.outfit,
                  onAction: _start,
                ),
                kWinOverlay: (_, game) => OverlayPanel(
                  title: 'Home at last!',
                  message: _winMessage(game),
                  hint: 'Warm cocoa, a soft chair, and a very good nap.',
                  actionLabel: 'Play again',
                  accent: _hero.outfit,
                  onAction: _start,
                ),
                kQuizOverlay: (_, game) => QuizPanel(
                  key: ValueKey(game.activeGate?.col),
                  question: game.activeGate!.question,
                  accent: _hero.outfit,
                  accentDark: _hero.outfitDark,
                  onAnswer: _answer,
                ),
              },
            ),
            if (_touchControls) TouchControls(game: _game),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back to lessons',
                  style: IconButton.styleFrom(
                    backgroundColor: Pal.ink.withValues(alpha: 0.35),
                    foregroundColor: Pal.cloud,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
