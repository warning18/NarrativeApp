// The die in the middle of the loadout's ring (docs/proposals/dice-looks.md):
// a flat polyhedron of the die's size that rolls to a face when one is
// chosen, the chosen face's number settling on its front. A bigger die rolls
// longer (see [dieRollDuration]); a tap on the die skips to the end, and with
// reduced motion it simply shows the face.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'die_skins.dart';
import 'poly_die.dart';

class RollingDie extends StatefulWidget {
  const RollingDie({
    super.key,
    required this.faceCount,
    required this.face,
    this.size = 56,
    this.skin,
    this.clan,
    this.still = false,
  });

  /// How many faces the die has (its shape).
  final int faceCount;

  /// The face (0-based) the die rolls to whenever it changes; its number
  /// ends on the front.
  final int face;
  final double size;
  final DieSkin? skin;
  final DieClan? clan;

  /// Reduced motion: no roll.
  final bool still;

  @override
  State<RollingDie> createState() => _RollingDieState();
}

class _RollingDieState extends State<RollingDie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _roll = AnimationController(
      vsync: this, duration: dieRollDuration(widget.faceCount), value: 1);

  @override
  void didUpdateWidget(RollingDie old) {
    super.didUpdateWidget(old);
    if (old.face == widget.face && old.faceCount == widget.faceCount) return;
    _roll.duration = dieRollDuration(widget.faceCount);
    if (widget.still) {
      _roll.value = 1;
    } else {
      _roll.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _roll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return GestureDetector(
      key: const ValueKey('rolling_die'),
      behavior: HitTestBehavior.opaque,
      // A tap skips the roll.
      onTap: () {
        if (_roll.isAnimating) _roll.value = 1;
      },
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: _roll,
          builder: (context, child) {
            final t = _roll.value;
            // A hop that dies away as the die lands, its shadow shrinking.
            final hop = _roll.isAnimating
                ? size *
                    0.3 *
                    math.pow(math.sin(math.pi * math.min(1, t * 1.6)), 2) *
                    (1 - t)
                : 0.0;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: -size * 0.04,
                  child: Container(
                    width: size * (0.8 - 0.25 * (hop / size)),
                    height: size * 0.12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size),
                      color: Colors.black.withValues(alpha: 0.25),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, -hop),
                  child: PolyDie(
                    shape: dieShapeOf(widget.faceCount),
                    size: size,
                    skin: widget.skin,
                    clan: widget.clan,
                    label: '${widget.face + 1}',
                    progress: t,
                    still: true,
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
