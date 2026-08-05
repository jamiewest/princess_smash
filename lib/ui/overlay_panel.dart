import 'package:flutter/material.dart';

import '../game/palette.dart';

/// The storybook card used for the title, game-over and victory screens.
class OverlayPanel extends StatelessWidget {
  const OverlayPanel({
    required this.title,
    required this.message,
    required this.hint,
    required this.actionLabel,
    required this.onAction,
    super.key,
  });

  final String title;
  final String message;
  final String hint;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
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
            side: const BorderSide(color: Pal.dress, width: 3),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _CrownMark(),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Pal.ink,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: Pal.ink,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: Pal.dress,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 26,
                      vertical: 14,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(actionLabel),
                ),
                const SizedBox(height: 14),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Pal.ink.withValues(alpha: 0.66),
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

/// A tiny crown drawn with the same shapes the in-game princess wears.
class _CrownMark extends StatelessWidget {
  const _CrownMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 66,
      height: 40,
      child: CustomPaint(painter: _CrownPainter()),
    );
  }
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final crown = Path()
      ..moveTo(w * 0.06, h * 0.78)
      ..lineTo(w * 0.2, h * 0.16)
      ..lineTo(w * 0.34, h * 0.62)
      ..lineTo(w * 0.5, h * 0.06)
      ..lineTo(w * 0.66, h * 0.62)
      ..lineTo(w * 0.8, h * 0.16)
      ..lineTo(w * 0.94, h * 0.78)
      ..close();
    canvas.drawPath(crown, Paint()..color = Pal.crown);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.72, w * 0.9, h * 0.2),
        Radius.circular(h * 0.1),
      ),
      Paint()..color = Pal.crown,
    );
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.44),
      h * 0.11,
      Paint()..color = Pal.crownGem,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
