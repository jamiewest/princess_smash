import 'package:flutter/material.dart';

import '../game/appearance.dart';
import '../game/hero_painter.dart';
import '../game/palette.dart';

/// A live, always-current picture of the hero, drawn by the same painter the
/// game uses.
class HeroPreview extends StatelessWidget {
  const HeroPreview({required this.look, this.scale = 6, super.key});

  final HeroAppearance look;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(20 * scale, 30 * scale),
      painter: _HeroPreviewPainter(look: look, scale: scale),
    );
  }
}

class _HeroPreviewPainter extends CustomPainter {
  const _HeroPreviewPainter({required this.look, required this.scale});

  final HeroAppearance look;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale);
    paintHero(canvas, look);
  }

  @override
  bool shouldRepaint(_HeroPreviewPainter old) =>
      old.look != look || old.scale != scale;
}

/// The dress-up screen: pick skin, hair, eyes, outfit, and who the hero is.
/// Every tap updates [heroAppearance], so the next run uses the new look.
class HeroMakerScreen extends StatefulWidget {
  const HeroMakerScreen({super.key});

  @override
  State<HeroMakerScreen> createState() => _HeroMakerScreenState();
}

class _HeroMakerScreenState extends State<HeroMakerScreen> {
  HeroAppearance _look = heroAppearance.value;

  void _update(HeroAppearance next) {
    setState(() => _look = next);
    heroAppearance.value = next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Pal.skyTop, Pal.skyMid, Pal.skyBottom],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: Pal.ink,
                        tooltip: 'Back',
                      ),
                      const Expanded(
                        child: Text(
                          'Make Your Hero',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Pal.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: Pal.cloud,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: _look.outfit.withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          HeroPreview(look: _look),
                          const SizedBox(height: 10),
                          Text(
                            _look.titledName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Pal.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _SectionTitle('Quick picks'),
                  Row(
                    children: [
                      Expanded(
                        child: _PresetCard(
                          preset: HeroAppearance.emery,
                          selected: _look == HeroAppearance.emery,
                          onTap: () => _update(HeroAppearance.emery),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PresetCard(
                          preset: HeroAppearance.milo,
                          selected: _look == HeroAppearance.milo,
                          onTap: () => _update(HeroAppearance.milo),
                        ),
                      ),
                    ],
                  ),
                  _NameField(
                    name: _look.name,
                    accent: _look.outfit,
                    onChanged: (name) => _update(_look.copyWith(name: name)),
                  ),
                  _ChoiceSection<HeroGender>(
                    title: 'Who are you?',
                    options: const [
                      (HeroGender.girl, '👧 Princess'),
                      (HeroGender.boy, '👦 Prince'),
                      (HeroGender.kid, '⭐ Royal'),
                    ],
                    selected: _look.gender,
                    accent: _look.outfit,
                    accentDark: _look.outfitDark,
                    onPick: (g) => _update(_look.copyWith(gender: g)),
                  ),
                  _SwatchSection(
                    title: 'Skin',
                    colors: HeroChoices.skins,
                    selected: _look.skin,
                    onPick: (c) => _update(_look.copyWith(skin: c)),
                  ),
                  _SwatchSection(
                    title: 'Hair colour',
                    colors: HeroChoices.hairs,
                    selected: _look.hair,
                    onPick: (c) => _update(_look.copyWith(hair: c)),
                  ),
                  _ChoiceSection<HairTexture>(
                    title: 'Hair style',
                    options: const [
                      (HairTexture.curly, '🌀 Curly'),
                      (HairTexture.wavy, '🌊 Wavy'),
                      (HairTexture.straight, '💇 Straight'),
                    ],
                    selected: _look.hairTexture,
                    accent: _look.outfit,
                    accentDark: _look.outfitDark,
                    onPick: (t) => _update(_look.copyWith(hairTexture: t)),
                  ),
                  _ChoiceSection<HairLength>(
                    title: 'Hair length',
                    options: const [
                      (HairLength.long, 'Long'),
                      (HairLength.short, 'Short'),
                    ],
                    selected: _look.hairLength,
                    accent: _look.outfit,
                    accentDark: _look.outfitDark,
                    onPick: (l) => _update(_look.copyWith(hairLength: l)),
                  ),
                  _SwatchSection(
                    title: 'Eyes',
                    colors: HeroChoices.eyeColors,
                    selected: _look.eyes,
                    onPick: (c) => _update(_look.copyWith(eyes: c)),
                  ),
                  _ChoiceSection<OutfitStyle>(
                    title: 'Outfit',
                    options: const [
                      (OutfitStyle.dress, '👗 Dress'),
                      (OutfitStyle.tunic, '👕 Tunic'),
                    ],
                    selected: _look.outfitStyle,
                    accent: _look.outfit,
                    accentDark: _look.outfitDark,
                    onPick: (o) => _update(_look.copyWith(outfitStyle: o)),
                  ),
                  _SwatchSection(
                    title: 'Outfit colour',
                    colors: HeroChoices.outfits,
                    selected: _look.outfit,
                    onPick: (c) => _update(_look.copyWith(outfit: c)),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: _look.outfit,
                      foregroundColor: Pal.ink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('All done!'),
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

/// A tappable preset — the classic princess or her prince twin — that swaps
/// the whole look (and its matching world colours) in one go.
class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final HeroAppearance preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Pal.cloud,
      elevation: selected ? 6 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected
              ? preset.outfit
              : preset.outfit.withValues(alpha: 0.4),
          width: selected ? 3 : 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              HeroPreview(look: preset, scale: 2.2),
              const SizedBox(height: 6),
              Text(
                preset.titledName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Pal.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameField extends StatefulWidget {
  const _NameField({
    required this.name,
    required this.accent,
    required this.onChanged,
  });

  final String name;
  final Color accent;
  final void Function(String) onChanged;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.name,
  );

  @override
  void didUpdateWidget(_NameField old) {
    super.didUpdateWidget(old);
    // A preset tap renames the hero from outside; typing does not (the
    // incoming name already matches what is in the field).
    if (widget.name != old.name && widget.name != _controller.text.trim()) {
      _controller.text = widget.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _controller,
        maxLength: 12,
        style: const TextStyle(fontWeight: FontWeight.w700, color: Pal.ink),
        decoration: InputDecoration(
          labelText: 'Hero name',
          counterText: '',
          filled: true,
          fillColor: Pal.cloud,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: widget.accent, width: 2),
          ),
        ),
        onChanged: (value) {
          final trimmed = value.trim();
          widget.onChanged(
            trimmed.isEmpty ? HeroAppearance.emery.name : trimmed,
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: Pal.ink,
        ),
      ),
    );
  }
}

/// A titled row of big, tappable colour dots.
class _SwatchSection extends StatelessWidget {
  const _SwatchSection({
    required this.title,
    required this.colors,
    required this.selected,
    required this.onPick,
  });

  final String title;
  final List<Color> colors;
  final Color selected;
  final void Function(Color) onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final colour in colors)
              InkWell(
                onTap: () => onPick(colour),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colour,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colour == selected ? Pal.ink : Pal.cloud,
                      width: colour == selected ? 3.5 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Pal.ink.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: colour == selected
                      ? const Icon(Icons.check, size: 20, color: Pal.cloud)
                      : null,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A titled row of labelled choice chips for enum-style options.
class _ChoiceSection<T> extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.accent,
    required this.accentDark,
    required this.onPick,
  });

  final String title;
  final List<(T, String)> options;
  final T selected;
  final Color accent;
  final Color accentDark;
  final void Function(T) onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, label) in options)
              ChoiceChip(
                label: Text(label),
                selected: value == selected,
                onSelected: (_) => onPick(value),
                selectedColor: accent,
                backgroundColor: Pal.cloud,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Pal.ink,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: value == selected
                        ? accentDark
                        : accent.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
