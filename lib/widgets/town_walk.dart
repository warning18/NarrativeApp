// A walk inside a town, told in words (v1.537): the caption under the
// Journey map when the party crosses from one district of a town to
// another ("You walk to the Stone Bridge..."), and the doorway between a
// building's room and the streets round it, both ways. The caption is the
// road walk's own (journey_screen.dart's party transit); this file has the
// words and the veil.
import 'package:flutter/material.dart';

/// [name] as it reads in the middle of a sentence: a leading article loses
/// its capital ("The Stone Bridge" -> "the Stone Bridge", "Le Pont de
/// Pierre" -> "le Pont de Pierre"); a name with none ("Tern Row") is left
/// alone.
String townNameInSentence(String name) {
  final text = name.trim();
  for (final article in const [
    'The ',
    'Le ',
    'La ',
    'Les ',
    'L’',
    'L\'',
  ]) {
    if (text.startsWith(article) && text.length > article.length) {
      return article.toLowerCase() + text.substring(article.length);
    }
  }
  return text;
}

/// The veil over the map as the party goes through a door: the screen is
/// the colour of the doorway for a moment, then clears, and the doorway's
/// glyph fades with it. [clock] runs 0 to 1 (1 is clear); [still] (reduced
/// motion) shows nothing at all.
class TownDoorVeil extends StatelessWidget {
  const TownDoorVeil({
    super.key,
    required this.clock,
    required this.colour,
    required this.icon,
    this.still = false,
  });

  final Animation<double> clock;
  final Color colour;
  final IconData icon;
  final bool still;

  /// How opaque the veil is at [t] of the way through: full at once, gone by
  /// the end.
  static double opacityAt(double t) =>
      (1 - Curves.easeIn.transform(t.clamp(0.0, 1.0))) * 0.85;

  @override
  Widget build(BuildContext context) {
    if (still) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: clock,
        builder: (context, _) {
          final opacity = opacityAt(clock.value);
          if (opacity <= 0.001) return const SizedBox.shrink();
          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                key: const ValueKey('town_door_veil'),
                color: colour.withValues(alpha: opacity),
              ),
              Center(
                child: Icon(icon,
                    size: 44,
                    color: Colors.white.withValues(alpha: opacity * 0.9)),
              ),
            ],
          );
        },
      ),
    );
  }
}
