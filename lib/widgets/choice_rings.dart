// A hub's choices acted out here, one ring each (design 3 of
// docs/proposals/inplace-choices.md): round the party's mark, one dashed
// ring for each kind of choice (a fight, a talk or a decision, a check or a
// payment), a chip on the ring ("Fight · 4") and up to five of its choices'
// icons on it, the rest a "+N". A tap on a chip or an icon opens the list.
// The same chip sits under the map. And the beat: when one of them is taken
// the party's mark pulses in the kind's colour with the choice's icon rising.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/stitched_ink.dart';

/// One ring: the kind [id], its [label] and number of choices, its colour
/// and the icons of the choices it holds.
class ChoiceRing {
  const ChoiceRing({
    required this.id,
    required this.label,
    required this.count,
    required this.color,
    required this.icons,
  });

  final String id;
  final String label;
  final int count;
  final Color color;
  final List<IconData> icons;
}

/// How many icons a ring shows before its "+N".
const int choiceRingIcons = 5;

/// The rings, in [here]'s coordinates (the layer fills its parent).
class ChoiceRingsLayer extends StatelessWidget {
  const ChoiceRingsLayer({
    super.key,
    required this.here,
    required this.innerRadius,
    required this.rings,
    required this.onTap,
    required this.plate,
    this.lit,
    this.chips = false,
  });

  /// Draws only the chips (over the map's marks) instead of the rings and
  /// their icons (under them).
  final bool chips;

  final Offset here;
  final double innerRadius;
  final List<ChoiceRing> rings;
  final ValueChanged<String> onTap;

  /// The map's land colour: the plates under the icons and chips.
  final Color plate;

  /// The ring whose list is open: the others dim.
  final String? lit;

  static const double _gap = 34;
  static const double _first = 34;
  static const double _disc = 28;

  double radiusOf(int i) => innerRadius + _first + i * _gap;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          clipBehavior: Clip.none,
          children: [
            if (!chips)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RingsPainter(
                      here: here,
                      radii: [
                        for (var i = 0; i < rings.length; i++) radiusOf(i)
                      ],
                      colors: [
                        for (final r in rings)
                          r.color.withValues(
                              alpha: lit == null || lit == r.id ? 0.85 : 0.25),
                      ],
                    ),
                  ),
                ),
              ),
            for (var i = 0; i < rings.length; i++)
              ..._ring(i, Size(box.maxWidth, box.maxHeight)),
          ],
        ),
      ),
    );
  }

  List<Widget> _ring(int i, Size map) {
    final ring = rings[i];
    final radius = radiusOf(i);
    final dim = lit != null && lit != ring.id;
    final shown = ring.count > choiceRingIcons
        ? choiceRingIcons - 1
        : math.min(ring.count, ring.icons.length);
    final discs = shown + (ring.count > shown ? 1 : 0);
    return [
      for (var k = 0; k < (chips ? 0 : discs); k++)
        () {
          // Spread over the ring, none at the top where the chip sits.
          final angle = -math.pi / 2 + (k + 1) * 2 * math.pi / (discs + 1);
          final at = here + Offset(math.cos(angle), math.sin(angle)) * radius;
          final more = k == shown && ring.count > shown;
          return Positioned(
            left: at.dx - _disc / 2,
            top: at.dy - _disc / 2,
            width: _disc,
            height: _disc,
            child: Opacity(
              opacity: dim ? 0.3 : 1,
              child: GestureDetector(
                key: ValueKey('choice_ring_disc_${ring.id}_$k'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(ring.id),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: plate,
                    border: Border.all(color: ring.color, width: 2),
                  ),
                  child: Center(
                    child: more
                        ? Text('+${ring.count - shown}',
                            style: TextStyle(
                                fontFamily: InkFonts.system,
                                fontSize: 11,
                                color: ring.color))
                        : Icon(ring.icons[k], size: 15, color: ring.color),
                  ),
                ),
              ),
            ),
          );
        }(),
      // The chip sits at the top of its ring, kept inside the map (a party
      // standing at its edge has its rings cut by it, never their names).
      if (chips)
        Positioned(
          left:
              (here.dx.clamp(66.0, math.max(66.0, map.width - 66)) as double) -
                  60,
          top: (here.dy - radius).clamp(4.0, math.max(4.0, map.height - 28)) -
              12,
          width: 120,
          height: 24,
          child: Center(
            child: ChoiceGroupChip(
              key: ValueKey('choice_ring_chip_${ring.id}'),
              label: ring.label,
              count: ring.count,
              color: ring.color,
              lit: lit == ring.id,
              dim: dim,
              plate: plate,
              onTap: () => onTap(ring.id),
            ),
          ),
        ),
    ];
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(
      {required this.here, required this.radii, required this.colors});

  final Offset here;
  final List<double> radii;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < radii.length; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      final circumference = 2 * math.pi * radii[i];
      final dashes = (circumference / 9).floor();
      for (var d = 0; d < dashes; d++) {
        final a0 = d * 2 * math.pi / dashes;
        canvas.drawArc(Rect.fromCircle(center: here, radius: radii[i]), a0,
            2 * math.pi / dashes * 0.45, false, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.here != here || old.radii != radii || old.colors != colors;
}

/// "Fight · 4": the pill on a ring, and under the map.
class ChoiceGroupChip extends StatelessWidget {
  const ChoiceGroupChip({
    super.key,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
    this.lit = false,
    this.dim = false,
    this.plate,
  });

  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;
  final bool lit;
  final bool dim;

  /// A solid colour under the pill (on the map); null for the page's own.
  final Color? plate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: dim ? 0.35 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 24),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: lit
                ? color
                : Color.alphaBlend(color.withValues(alpha: 0.14),
                    plate ?? theme.colorScheme.surface),
            border: Border.all(color: color, width: 1.6),
          ),
          child: Text('$label · $count',
              maxLines: 1,
              style: TextStyle(
                  fontFamily: InkFonts.system,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: lit ? theme.colorScheme.surface : color)),
        ),
      ),
    );
  }
}

/// The beat at the party's mark when a choice done here is taken: a ring
/// spreads from the mark in the choice's colour and its icon rises and
/// fades. [animation] runs 0 to 1.
class ChoiceBeat extends StatelessWidget {
  const ChoiceBeat({
    super.key,
    required this.animation,
    required this.here,
    required this.innerRadius,
    required this.color,
    required this.icon,
  });

  final Animation<double> animation;
  final Offset here;
  final double innerRadius;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = animation.value;
            if (t <= 0 || t >= 1) return const SizedBox.shrink();
            final radius = innerRadius + 52 * Curves.easeOut.transform(t);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: here.dx - radius,
                  top: here.dy - radius,
                  width: radius * 2,
                  height: radius * 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: color.withValues(alpha: 0.9 * (1 - t)),
                          width: 4 * (1 - t) + 1),
                    ),
                  ),
                ),
                Positioned(
                  left: here.dx - 14,
                  top: here.dy - innerRadius - 18 - 34 * t,
                  child: Opacity(
                    opacity: (1 - t).clamp(0.0, 1.0),
                    child: Icon(icon, size: 28, color: color),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
