// The art of the first-launch intro (v1.583, docs/proposals/intro-animation-d.md):
// the painted plates (v1.904, Art's), and over them what stays code, drawn in
// pixel art on a 70 x 124 grid: the ash coming down, the flash of the first
// shell, the old bone die and the Shroud's embers. Each painter is still: the
// intro (screens/intro_screen.dart) redraws it as its clock moves.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/stitched_ink.dart';
import 'die_3d.dart';
import 'die_skins.dart';
import 'pixel_banner.dart';
import '../theme/palette.dart';

const Color _ember = Palette.orange52b;
const Color _gold = Palette.orange73;

const _cols = 70;
const _rows = 124;

class _Grid {
  _Grid(this.canvas, Size size) : u = size.width / _cols;
  final Canvas canvas;
  final double u;
  void px(num x, num y, num w, num h, Color c) => canvas.drawRect(
      Rect.fromLTWH(x * u, y * u, w * u, h * u),
      Paint()
        ..color = c
        ..isAntiAlias = false);
}

double _h(int i, int salt) {
  final x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
  return x - x.floorToDouble();
}

/// Ash coming down: small grey flakes and a few embers, still.
class IntroAsh extends CustomPainter {
  const IntroAsh(this.salt);
  final int salt;
  @override
  void paint(Canvas canvas, Size size) {
    final g = _Grid(canvas, size);
    for (var i = 0; i < 70; i++) {
      final ember = _h(i, salt + 40) > 0.93;
      g.px(
          _h(i, salt) * _cols,
          _h(i, salt + 1) * _rows,
          ember ? 1 : 0.9,
          ember ? 1 : 0.9,
          ember
              ? const Color(0xFFF0B050)
              : const Color(0xFFB8B2BC)
                  .withValues(alpha: 0.35 + _h(i, 3) * 0.4));
    }
  }

  @override
  bool shouldRepaint(IntroAsh old) => false;
}

// ---------------------------------------------------------------------------
// v1.904: the four plates of Version A (Art's, art/pixellab-intro/final/)
// replace the code-drawn scenes; the embers, the ash and the shell's flash
// stay code, over the still plate.
// ---------------------------------------------------------------------------

/// The plates, in the order of the intro: the Shroud burning (beats 1 and 2),
/// the city on alert (3), Tallow Street and the Blind Beggar (4), the tavern
/// room (5 to 7).
const List<String> introPlates = [
  'assets/visuals/intro/plate1_shroud_burns.png',
  'assets/visuals/intro/plate2_city_on_alert.png',
  'assets/visuals/intro/plate3_blind_beggar.png',
  'assets/visuals/intro/plate4_tavern_room.png',
];

/// A plate (180 x 320) covering the stage, nearest neighbour, [zoom] times
/// larger about [anchor] (a slow push in or a pan down between beats).
class IntroPlate extends StatelessWidget {
  const IntroPlate(this.plate,
      {super.key, this.zoom = 1, this.anchor = Alignment.center});

  /// Index into [introPlates].
  final int plate;
  final double zoom;
  final Alignment anchor;

  @override
  Widget build(BuildContext context) => ClipRect(
        child: Transform.scale(
          scale: zoom,
          alignment: anchor,
          child: Image.asset(
            introPlates[plate],
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.none,
            gaplessPlayback: true,
          ),
        ),
      );
}

/// The first shell lands outside: its light through the window, over the
/// room's plate.
class IntroFlash extends CustomPainter {
  const IntroFlash();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ui.Gradient.linear(
              Offset.zero,
              Offset(0, size.height * 0.5),
              [const Color(0x99FFC070), const Color(0x00FFC070)]));
  }

  @override
  bool shouldRepaint(IntroFlash old) => false;
}

/// A die, the old bone one: [roll] is how far through a tumble it is (null
/// at rest), the front face showing [face].
Widget introDie(double size, {double? roll, int face = 6}) => Die3D(
      faces: [
        for (var i = 0; i < 6; i++)
          DieCubeFace(
              glyph: Text('${i == 0 ? face : (face % 6) + 1 + i % 5}',
                  style: TextStyle(
                      fontFamily: InkFonts.system,
                      fontSize: size * 0.45,
                      fontWeight: FontWeight.w600,
                      color: Palette.orange17)),
              color: const Color(0xFFE8DDC0)),
      ],
      accent: _gold,
      size: size,
      skin: boneSkin,
      roll: roll == null ? null : AlwaysStoppedAnimation(roll),
      rolling: roll != null,
      still: roll == null,
    );

/// A piece of the Shroud as an ember: dim cloth lit at its edge, with a glow.
class IntroEmber extends StatelessWidget {
  const IntroEmber(
      {super.key, required this.id, required this.height, this.tilt = 0});

  final String id;
  final double height;
  final double tilt;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: tilt,
        child: DecoratedBox(
          decoration: BoxDecoration(boxShadow: [
            BoxShadow(
                color: _ember.withValues(alpha: 0.75),
                blurRadius: 10,
                spreadRadius: 1),
          ]),
          child: SizedBox(
            width: height / 2,
            height: height,
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                0.9, 0.2, 0.0, 0, 30, //
                0.1, 0.55, 0.0, 0, 6,
                0.05, 0.05, 0.3, 0, 0,
                0, 0, 0, 1, 0,
              ]),
              child: FittedBox(child: PixelBanner(id: id, scale: 1)),
            ),
          ),
        ),
      );
}
