// A die as a still tile (v1.952): a real solid at rest (the cube for a d6)
// with the die's own mark (the flame, the wave, the crown: die_art.dart) on
// its front facet, in its own skin. Every die the player sees is a 3D object,
// rolling or not; the flat polygon is gone from the tiles too (the Tower's
// "Your dice", the loadout's list, the inventory's rows).
//
// Under about 24 px a facet has no room for a mark (a plain solid then, the
// skin still tells the die).
import 'package:flutter/material.dart';

import 'die_3d.dart';
import 'die_art.dart';
import 'die_skins.dart';

class DieTile extends StatelessWidget {
  const DieTile({
    super.key,
    required this.dieId,
    required this.faces,
    this.size = 48,
    this.glowing = true,
  });

  /// The die's id (dice.json key), for its skin and its mark.
  final String? dieId;

  /// How many faces it has (its shape).
  final int faces;

  /// The square it is given: the solid fits in it.
  final double size;

  /// Whether the skin's glow shows (a die in play), or not.
  final bool glowing;

  @override
  Widget build(BuildContext context) {
    final shape = dieShapeOf(faces);
    final skin = dieSkinOf(dieId);
    final tone = glowing || skin.glow == null
        ? skin
        : DieSkin(skin.material, skin.base, skin.edge, skin.pattern);
    // The solids are drawn bigger than their square: fit them in this one.
    final fit = size / dieSolidScale(shape);
    final front = DieCubeFace(
      glyph: SizedBox(
        width: 48,
        height: 48,
        child: CustomPaint(painter: _MarkPainter(dieId, tone, shape)),
      ),
      color: skin.edge,
    );
    final blank = DieCubeFace(glyph: const SizedBox.shrink(), color: skin.edge);
    final sides = [front, for (var i = 1; i < 6; i++) blank];
    return SizedBox(
      key: Key('die_tile_${dieId ?? 'plain'}'),
      width: size,
      height: size,
      child: Center(
        child: Die3D(
          faces: sides,
          facets: shape == DieShape.d6
              ? null
              : [front, for (var i = 1; i < faces; i++) blank],
          accent: skin.edge,
          size: fit,
          shape: shape,
          skin: tone,
          still: true,
          artId: dieId,
        ),
      ),
    );
  }
}

/// The die's art over a facet: [paintDieArt] in the box, with a ring of
/// corners for the marks that spike (a facet has no corners of the whole
/// die).
class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.dieId, this.skin, this.shape);

  final String? dieId;
  final DieSkin skin;
  final DieShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final sides = switch (shape) {
      DieShape.d4 || DieShape.d8 => 3,
      DieShape.d12 => 5,
      _ => 4,
    };
    final corners = [
      for (var i = 0; i < sides; i++)
        Offset.fromDirection(-1.5708 + i * 6.2832 / sides, 0.9)
    ];
    paintDieArt(canvas, size, dieId, skin, corners);
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.dieId != dieId || old.skin != skin || old.shape != shape;
}
