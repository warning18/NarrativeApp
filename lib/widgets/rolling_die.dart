// The die in the middle of the loadout's ring (docs/proposals/dice-looks.md):
// a flat polyhedron of the die's size that rolls to a face when one is
// chosen, the chosen face's number settling on its front. A bigger die rolls
// longer (see [dieRollDuration]); a tap on the die skips to the end, and with
// reduced motion it simply shows the face.
import 'package:flutter/material.dart';

import 'die_3d.dart';
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
    this.dieId,
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

  /// The die's id, for its art.
  final String? dieId;

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

  /// The faces the solid carries, the landed one first: each plaque is the
  /// number of the face on the die's own stone, in the clan's colour for a
  /// clan's die.
  List<DieCubeFace> _facets() {
    final n = widget.faceCount;
    final skin = widget.skin;
    final color = widget.clan?.color ?? skin?.edge ?? Colors.blueGrey;
    return [
      for (var i = 0; i < n; i++)
        DieCubeFace(
          color: color,
          glyph: Text('${(widget.face + i) % n + 1}',
              style: TextStyle(
                  fontSize: widget.size * 0.3,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: Colors.white,
                  shadows: const [Shadow(blurRadius: 3, color: Colors.black)])),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final shape = dieShapeOf(widget.faceCount);
    final facets = _facets();
    // A real solid for every shape (the cube for a d6), tumbling the way a
    // fight's dice do; the flat polygon is never what a roll looks like.
    final sides = [for (var i = 0; i < 6; i++) facets[i % facets.length]];
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
          builder: (context, _) => Die3D(
            faces: sides,
            facets: shape == DieShape.d6 ? null : facets,
            accent: widget.skin?.edge ?? Colors.blueGrey,
            size: size,
            shape: shape,
            skin: widget.skin,
            artId: widget.dieId,
            roll: _roll,
            rolling: _roll.isAnimating,
            still: widget.still,
          ),
        ),
      ),
    );
  }
}
