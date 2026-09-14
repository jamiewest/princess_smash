import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/education/lesson.dart';
import '../game/palette.dart';

/// The storybook question card shown when Emery reaches a locked rose gate.
///
/// Answer choices are shuffled for display so the right answer is never
/// always the first button. Wrong picks stay disabled with a gentle nudge to
/// try again; the game itself dismisses the card once [onAnswer] returns true.
class QuizPanel extends StatefulWidget {
  const QuizPanel({
    required this.question,
    required this.onAnswer,
    this.accent = Pal.dress,
    this.accentDark = Pal.dressDark,
    super.key,
  });

  final QuizQuestion question;

  /// Button and highlight colours, matched to the hero's outfit.
  final Color accent;
  final Color accentDark;

  /// Receives the index into [QuizQuestion.choices] that was picked and
  /// returns whether it was correct.
  final bool Function(int choiceIndex) onAnswer;

  @override
  State<QuizPanel> createState() => _QuizPanelState();
}

class _QuizPanelState extends State<QuizPanel> {
  late final List<int> _order = List.generate(
    widget.question.choices.length,
    (i) => i,
  )..shuffle(math.Random());

  final Set<int> _wrongPicks = {};

  void _pick(int choiceIndex) {
    if (widget.onAnswer(choiceIndex)) return;
    setState(() => _wrongPicks.add(choiceIndex));
  }

  @override
  Widget build(BuildContext context) {
    final missed = _wrongPicks.isNotEmpty;
    return Container(
      color: Pal.ink.withValues(alpha: 0.42),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          margin: const EdgeInsets.all(24),
          color: Pal.cloud,
          elevation: 14,
          shadowColor: Pal.ink.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: Pal.crown, width: 3),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🌹', style: TextStyle(fontSize: 26)),
                const SizedBox(height: 8),
                Text(
                  'The rose gate asks...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.accentDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.question.prompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Pal.ink,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 18),
                for (final choiceIndex in _order) ...[
                  _ChoiceButton(
                    label: widget.question.choices[choiceIndex],
                    missed: _wrongPicks.contains(choiceIndex),
                    accent: widget.accent,
                    onPressed: () => _pick(choiceIndex),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 4),
                Text(
                  missed
                      ? 'Not quite — try another one!'
                      : 'Pick the right answer to open the gate.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: missed ? FontWeight.w700 : FontWeight.w400,
                    color: missed
                        ? widget.accentDark
                        : Pal.ink.withValues(alpha: 0.66),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.missed,
    required this.accent,
    required this.onPressed,
  });

  final String label;
  final bool missed;
  final Color accent;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: missed ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Pal.ink.withValues(alpha: 0.12),
          disabledForegroundColor: Pal.ink.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
