import 'package:flutter/material.dart';

import '../game/palette.dart';
import '../game/princess_smash_game.dart';

/// On-screen controls for touch play: a walk pad bottom-left, a jump button
/// bottom-right. Pointers are tracked by hand through [Listener]s rather than
/// per-button GestureDetectors so that walking and jumping work at the same
/// time, and so a thumb can slide between ◀ and ▶ without lifting.
class TouchControls extends StatefulWidget {
  const TouchControls({required this.game, super.key});

  final PrincessSmashGame game;

  @override
  State<TouchControls> createState() => _TouchControlsState();
}

class _TouchControlsState extends State<TouchControls> {
  static const double _padWidth = 172;
  static const double _padHeight = 84;
  static const double _jumpSize = 96;
  static const EdgeInsets _margin = EdgeInsets.fromLTRB(14, 0, 14, 14);

  /// Walk-pad pointers, in press order: pointer id → -1 (left) or 1 (right).
  final Map<int, int> _walkPointers = {};
  final Set<int> _jumpPointers = {};

  int get _direction =>
      _walkPointers.isEmpty ? 0 : _walkPointers.values.last;

  void _setWalkPointer(int pointer, Offset localPosition) {
    final dir = localPosition.dx < _padWidth / 2 ? -1 : 1;
    if (_walkPointers[pointer] == dir) return;
    setState(() => _walkPointers[pointer] = dir);
    widget.game.touchMove = _direction.toDouble();
  }

  void _clearWalkPointer(int pointer) {
    if (_walkPointers.remove(pointer) == null) return;
    setState(() {});
    widget.game.touchMove = _direction.toDouble();
  }

  void _jumpDown(int pointer) {
    final wasEmpty = _jumpPointers.isEmpty;
    setState(() => _jumpPointers.add(pointer));
    if (wasEmpty) {
      widget.game.pressJumpButton();
    }
  }

  void _jumpUp(int pointer) {
    if (!_jumpPointers.remove(pointer)) return;
    setState(() {});
    if (_jumpPointers.isEmpty) {
      widget.game.releaseJumpButton();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: SafeArea(
        minimum: _margin,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) => _setWalkPointer(e.pointer, e.localPosition),
                onPointerMove: (e) => _setWalkPointer(e.pointer, e.localPosition),
                onPointerUp: (e) => _clearWalkPointer(e.pointer),
                onPointerCancel: (e) => _clearWalkPointer(e.pointer),
                child: SizedBox(
                  width: _padWidth,
                  height: _padHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: _ControlFace(
                          pressed: _direction < 0,
                          icon: Icons.chevron_left_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ControlFace(
                          pressed: _direction > 0,
                          icon: Icons.chevron_right_rounded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) => _jumpDown(e.pointer),
                onPointerUp: (e) => _jumpUp(e.pointer),
                onPointerCancel: (e) => _jumpUp(e.pointer),
                child: SizedBox(
                  width: _jumpSize,
                  height: _jumpSize,
                  child: _ControlFace(
                    pressed: _jumpPointers.isNotEmpty,
                    icon: Icons.arrow_upward_rounded,
                    circular: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The visual of a single button, in the same storybook style as the cards.
class _ControlFace extends StatelessWidget {
  const _ControlFace({
    required this.pressed,
    required this.icon,
    this.circular = false,
  });

  final bool pressed;
  final IconData icon;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        decoration: BoxDecoration(
          color: pressed
              ? Pal.dress.withValues(alpha: 0.85)
              : Pal.cloud.withValues(alpha: 0.55),
          shape: circular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circular ? null : BorderRadius.circular(20),
          border: Border.all(
            color: Pal.ink.withValues(alpha: pressed ? 0.45 : 0.25),
            width: 2.5,
          ),
        ),
        child: Icon(
          icon,
          size: 44,
          color: pressed ? Colors.white : Pal.ink.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}
