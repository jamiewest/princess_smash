import 'package:flame/game.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import 'game/palette.dart';
import 'game/princess_smash_game.dart';
import 'ui/overlay_panel.dart';
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
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final PrincessSmashGame _game = PrincessSmashGame();

  /// Owned here so overlay buttons can hand keyboard focus straight back to
  /// the game after being tapped.
  final FocusNode _focusNode = FocusNode(debugLabel: 'princess-smash');

  /// Phones and tablets get the on-screen controls up front; anything else
  /// earns them the moment a real touch happens (touch laptops, mis-detected
  /// mobile browsers), so keyboard players never see them.
  bool _touchControls = switch (defaultTargetPlatform) {
    TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.fuchsia =>
      true,
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
                  title: 'Princess Smash',
                  message:
                      'Poor Princess Pip took a wrong turn at the meadow.\n'
                      'Help her bounce her way home!',
                  hint: walkHint,
                  actionLabel: 'Start the journey',
                  onAction: _start,
                ),
                kGameOverOverlay: (_, game) => OverlayPanel(
                  title: 'Oh no!',
                  message:
                      'Pip is all out of hearts.\n'
                      'She found ${game.gems} gems along the way.',
                  hint: 'Every journey home deserves another try.',
                  actionLabel: 'Try again',
                  onAction: _start,
                ),
                kWinOverlay: (_, game) => OverlayPanel(
                  title: 'Home at last!',
                  message:
                      'Pip made it back to her cottage with '
                      '${game.gems} of ${game.level.gemCount} gems\n'
                      'and ${game.hearts} hearts to spare.',
                  hint: 'Warm cocoa, a soft chair, and a very good nap.',
                  actionLabel: 'Play again',
                  onAction: _start,
                ),
              },
            ),
            if (_touchControls) TouchControls(game: _game),
          ],
        ),
      ),
    );
  }
}
