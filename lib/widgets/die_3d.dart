// The party's dice in the fight as cubes (v1.214): each die tumbles through
// the air in perspective and lands on the face it rolled, which stands
// front; the other five sides carry the die's other faces. A face that
// lands lets go a burst fitted to what it does (see [DieFx]): sparks and a
// shock ring for a strike, a ward for a guard, rising blooms for a heal,
// motes for mana, bubbles for poison, bolts for a stun, a draining spiral
// for a weaken, a puff of grey dust for a blank. A skill face or a heavy
// blow lands bigger. Over the burst go a mark for each rule word the face
// carries, a tint for its element and, when they apply, a surge ring, a
// curse's chains and a blank's shudder (v1.216). Each die wears a skin of
// its own (see die_skins.dart).
//
// The cube is six flat faces in 3D (a 4x4 matrix each: the tumble, the
// face's place on the cube, the perspective), the far ones culled and the
// near ones lit by a fixed lamp, so the face glyphs are the very widgets
// the rest of the fight draws.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../combat/face_keywords.dart';
import '../utils/face_style.dart';
import 'die_skins.dart';
import 'pixel_sprite.dart';

/// One side of the cube: what it shows, and the colour it is tinted.
class DieCubeFace {
  const DieCubeFace({required this.glyph, required this.color});

  final Widget glyph;
  final Color color;
}

/// The burst a face lets go when it lands.
enum DieFx { strike, ward, bloom, arcs, miasma, shock, drain, fizzle }

/// The burst fitted to [kind].
DieFx dieFxOf(FaceKind kind) => switch (kind) {
      FaceKind.attack => DieFx.strike,
      FaceKind.defend => DieFx.ward,
      FaceKind.heal => DieFx.bloom,
      FaceKind.mana => DieFx.arcs,
      FaceKind.poison => DieFx.miasma,
      FaceKind.stun => DieFx.shock,
      FaceKind.weaken => DieFx.drain,
      FaceKind.empty => DieFx.fizzle,
    };

/// Where the die rests: the landed face stands almost square to the viewer,
/// tipped and turned just enough for an edge of the top and of a side to
/// show, so the face that rolled (and its skill icon) is what reads.
const double dieRestTipX = 0.2;
const double dieRestTurnY = 0.26;

/// Perspective: the eye sits `1 / _perspective` in front of the cube.
const double _perspective = 0.0016;

/// Turns the tumble makes before the die settles.
const double _tumbleTurns = 2.5;

class Die3D extends StatefulWidget {
  const Die3D({
    super.key,
    required this.faces,
    required this.accent,
    this.size = 40,
    this.roll,
    this.rolling = false,
    this.fx,
    this.big = false,
    this.dim = false,
    this.still = false,
    this.skin,
    this.held = false,
    this.keywords = const {},
    this.element = 'None',
    this.surge = false,
    this.cursed = false,
  }) : assert(faces.length == 6);

  /// The six sides, the front one (the face that lands) first.
  final List<DieCubeFace> faces;

  /// The roller's colour, the cube's edge.
  final Color accent;

  /// The cube's edge, in logical pixels.
  final double size;

  /// The roll's progress, 0 to 1 (the die is at rest at 1); null at rest.
  final Animation<double>? roll;

  /// Whether the die is in the air: it tumbles by [roll]. When it stops,
  /// a landed [fx] bursts.
  final bool rolling;

  /// The burst when the die lands, if any.
  final DieFx? fx;

  /// A skill face or a heavy blow: a bigger burst.
  final bool big;

  /// A die not yet rolled: paler.
  final bool dim;

  /// No motion (reduced motion): no tumble, no burst.
  final bool still;

  /// The die's stone, edge, pattern and glow; null for the plain look in
  /// [accent].
  final DieSkin? skin;

  /// Kept through the reroll: a gold ring and a lock round the cube.
  final bool held;

  /// The landed face's rule words, each with a flourish on landing.
  final Set<FaceKeyword> keywords;

  /// The landed face's element ('None' for none): a tint on the burst.
  final String element;

  /// The guaranteed critical of a full momentum meter: a gold ring.
  final bool surge;

  /// A curse lies on the landed face: chains.
  final bool cursed;

  @override
  State<Die3D> createState() => _Die3DState();
}

class _Die3DState extends State<Die3D> with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    PixelStrips.preload(_pixelNames(widget.fx));
  }

  /// The strips that make a landing, in pixel art (see
  /// tool/gen_pixel_fx.py): the kind's burst, the element's tint, a mark
  /// for each rule word, and the special landings.
  List<String> _pixelNames(DieFx? fx) => [
        if (fx != null) 'die_${fx.name}',
        if (widget.element != 'None') 'el_${widget.element.toLowerCase()}',
        for (final keyword in widget.keywords) 'kw_${keyword.name}',
        if (widget.surge) 'die_surge',
        if (widget.cursed) 'die_curse',
        if (widget.big) 'die_glint',
      ];

  DieSkin get _skin =>
      widget.skin ?? DieSkin('', _faceStone, widget.accent, DiePattern.none);

  @override
  void didUpdateWidget(Die3D old) {
    super.didUpdateWidget(old);
    if (old.rolling && !widget.rolling && widget.fx != null && !widget.still) {
      _burst.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final skin = _skin;
    final roll = widget.roll;
    final tumbling = widget.rolling && !widget.still && roll != null;
    final cube = tumbling
        ? AnimatedBuilder(
            animation: roll,
            builder: (context, _) => _cube(context, roll.value),
          )
        : _cube(context, 1);
    final fx = widget.fx;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (skin.glow != null && !widget.dim)
            Positioned(
              left: -size * 0.45,
              top: -size * 0.45,
              width: size * 1.9,
              height: size * 1.9,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      skin.glow!.withValues(alpha: 0.32),
                      skin.glow!.withValues(alpha: 0),
                    ]),
                  ),
                ),
              ),
            ),
          AnimatedBuilder(
            animation: _burst,
            builder: (context, child) {
              // A blank landing shudders once.
              final shake = fx == DieFx.fizzle && _burst.isAnimating
                  ? math.sin(_burst.value * 38) * (1 - _burst.value) * 3
                  : 0.0;
              return Transform.translate(
                  offset: Offset(shake, 0), child: child);
            },
            child: Opacity(opacity: widget.dim ? 0.55 : 1, child: cube),
          ),
          if (widget.held)
            Positioned(
              left: -size * 0.3,
              top: -size * 0.3,
              width: size * 1.6,
              height: size * 1.6,
              child: IgnorePointer(
                child: CustomPaint(
                  key: const ValueKey('die_held'),
                  painter: _HeldRingPainter(),
                ),
              ),
            ),
          if (fx != null)
            Positioned(
              left: -size * 0.8,
              top: -size * 0.8,
              width: size * 2.6,
              height: size * 2.6,
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _burst,
                  builder: (context, _) => !_burst.isAnimating
                      ? const SizedBox.shrink()
                      : PixelStrips.ready(_pixelNames(fx))
                          // The landing in pixel art.
                          ? CustomPaint(
                              key: const ValueKey('die_burst'),
                              painter: PixelStripPainter(
                                names: _pixelNames(fx),
                                progress: _burst.value,
                                scale: (size * 2.6 / 40)
                                    .round()
                                    .clamp(1, 4)
                                    .toDouble(),
                              ),
                            )
                          // Until its strips are in, the drawn one.
                          : CustomPaint(
                              key: const ValueKey('die_burst'),
                              painter: DieBurstPainter(
                                fx: fx,
                                t: _burst.value,
                                big: widget.big,
                                unit: size,
                                keywords: widget.keywords,
                                element: widget.element,
                                surge: widget.surge,
                                cursed: widget.cursed,
                              ),
                            ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The cube [t] of the way through the roll (1 = at rest).
  Widget _cube(BuildContext context, double t) {
    final size = widget.size;
    final e = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final spin = (1 - e) * _tumbleTurns * 2 * math.pi;
    // The tumble decays to nothing, leaving the rest tilt.
    final model = Matrix4.identity()
      ..rotateX(spin * 0.9)
      ..rotateY(spin * 1.3)
      ..rotateZ(spin * 0.35)
      ..rotateX(dieRestTipX)
      ..rotateY(dieRestTurnY);
    // A hop that dies away as it settles, with the shadow shrinking under it.
    final hop = widget.rolling && widget.roll != null
        ? size *
            0.7 *
            math.pow(math.sin(math.pi * math.min(1, t * 1.6)), 2) *
            (1 - t)
        : 0.0;
    final placed = [
      for (var i = 0; i < 6; i++) CubeFacePlacement.of(i, model, size / 2),
    ]..sort((a, b) => b.depth.compareTo(a.depth));
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned(
          bottom: -size * 0.12,
          child: Container(
            width: size * (0.9 - 0.3 * (hop / size)),
            height: size * 0.18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size),
              color: Colors.black.withValues(alpha: 0.22 - 0.1 * (hop / size)),
            ),
          ),
        ),
        Transform.translate(
          offset: Offset(0, -hop),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              for (final p in placed)
                if (p.visible)
                  Transform(
                    alignment: Alignment.center,
                    transform: p.matrix,
                    child: _face(widget.faces[p.slot], p),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _face(DieCubeFace face, CubeFacePlacement p) {
    final size = widget.size;
    final skin = _skin;
    final base = Color.alphaBlend(
        face.color.withValues(alpha: widget.skin == null ? 0.34 : 0.24),
        skin.base);
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(size * 0.16),
          border: Border.all(color: skin.edge, width: 1.6),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The mark cut into the stone.
            ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.16),
              child: CustomPaint(
                painter: DiePatternPainter(skin.pattern,
                    Color.lerp(skin.edge, skin.base, 0.25)!, 7 + p.slot),
              ),
            ),
            Center(child: FittedBox(fit: BoxFit.scaleDown, child: face.glyph)),
            // The lamp: the faces turned from it go dark.
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(size * 0.16),
                color: Colors.black.withValues(alpha: (1 - p.light) * 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The cube's own stone, under every face's tint.
const Color _faceStone = Color(0xFF211E26);

/// Where one side of the cube stands in a given turn: its matrix, how far
/// it is, whether it faces the viewer, and how lit it is.
class CubeFacePlacement {
  CubeFacePlacement._(
      this.slot, this.matrix, this.depth, this.visible, this.light);

  /// Which of the six sides (0 front, 1 right, 2 back, 3 left, 4 top,
  /// 5 bottom, at rest before the turn).
  final int slot;
  final Matrix4 matrix;

  /// The side's centre along the viewing axis: the larger, the farther.
  final double depth;
  final bool visible;

  /// 0 (dark) to 1 (full lamp).
  final double light;

  /// The side [slot] of a cube of half-edge [half], turned by [model].
  static CubeFacePlacement of(int slot, Matrix4 model, double half) {
    // Each side starts as a flat square facing the viewer (its outward
    // direction is -z) and is turned onto its place, then pushed out.
    final orient = switch (slot) {
      0 => Matrix4.identity(),
      1 => Matrix4.rotationY(-math.pi / 2),
      2 => Matrix4.rotationY(math.pi),
      3 => Matrix4.rotationY(math.pi / 2),
      4 => Matrix4.rotationX(-math.pi / 2),
      _ => Matrix4.rotationX(math.pi / 2),
    };
    final normal = _apply(model.multiplied(orient), 0, 0, -1);
    final centre = _apply(model.multiplied(orient), 0, 0, -half);
    const eye = -1 / _perspective;
    // Facing the viewer: its normal points against the way to the eye.
    final toFace = [centre[0], centre[1], centre[2] - eye];
    final facing =
        normal[0] * toFace[0] + normal[1] * toFace[1] + normal[2] * toFace[2] <
            0;
    // A lamp above, to the left and in front of the cube.
    const lamp = [-0.35, -0.55, -0.76];
    final lit =
        (normal[0] * lamp[0] + normal[1] * lamp[1] + normal[2] * lamp[2])
            .clamp(0.0, 1.0);
    final matrix = (Matrix4.identity()..setEntry(3, 2, _perspective))
        .multiplied(model)
        .multiplied(orient)
        .multiplied(Matrix4.translationValues(0.0, 0.0, -half));
    return CubeFacePlacement._(
        slot, matrix, centre[2], facing, 0.45 + 0.55 * lit);
  }

  /// [m]'s rotation applied to a vector (x, y, z).
  static List<double> _apply(Matrix4 m, double x, double y, double z) {
    final s = m.storage;
    return [
      s[0] * x + s[4] * y + s[8] * z,
      s[1] * x + s[5] * y + s[9] * z,
      s[2] * x + s[6] * y + s[10] * z,
    ];
  }
}

/// The gold ring and lock of a die kept through the reroll.
class _HeldRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 2;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFF2C14E).withValues(alpha: 0.9);
    final circle = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    for (final metric in circle.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(
            metric.extractPath(d, math.min(d + 4, metric.length)), ring);
      }
    }
    // The lock, at the ring's upper right.
    final at = c + Offset(r * 0.72, -r * 0.72);
    final gold = Paint()..color = const Color(0xFFF2C14E);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: at + const Offset(0, 3), width: 14, height: 11),
            const Radius.circular(2.5)),
        gold);
    canvas.drawArc(
        Rect.fromCenter(center: at + const Offset(0, -2), width: 9, height: 10),
        math.pi,
        math.pi,
        false,
        ring..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_HeldRingPainter old) => false;
}

/// A face's burst, [t] of the way (0 to 1) through, over a box
/// 2.6 [unit]s wide with the die in its middle.
class DieBurstPainter extends CustomPainter {
  const DieBurstPainter({
    required this.fx,
    required this.t,
    required this.big,
    required this.unit,
    this.keywords = const {},
    this.element = 'None',
    this.surge = false,
    this.cursed = false,
  });

  final DieFx fx;
  final double t;
  final bool big;
  final double unit;
  final Set<FaceKeyword> keywords;
  final String element;
  final bool surge;
  final bool cursed;

  static double _hash(int i, int salt) {
    final x = math.sin(i * 12.9898 + salt * 78.233) * 43758.5453;
    return x - x.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final u = unit * (big ? 1.25 : 1.0);
    final fade = (1 - t).clamp(0.0, 1.0);
    final out = Curves.easeOutCubic.transform(t);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fill = Paint();
    switch (fx) {
      case DieFx.strike:
        // A flash, a shock ring and sparks thrown out.
        fill.color =
            const Color(0xFFFF8A3D).withValues(alpha: 0.5 * fade * fade);
        canvas.drawCircle(c, u * (0.35 + 0.5 * out), fill);
        line
          ..strokeWidth = 3 * fade + 0.5
          ..color = const Color(0xFFFFB04D).withValues(alpha: 0.9 * fade);
        canvas.drawCircle(c, u * (0.45 + 0.85 * out), line);
        final sparks = big ? 18 : 11;
        for (var i = 0; i < sparks; i++) {
          final a = i * 2 * math.pi / sparks + _hash(i, 1) * 0.5;
          final r0 = u * (0.45 + 0.55 * out * (0.6 + _hash(i, 2) * 0.6));
          final r1 = r0 + u * 0.22 * (1 - out) + 2;
          line
            ..strokeWidth = 2
            ..color =
                (i.isEven ? const Color(0xFFFFE08A) : const Color(0xFFE53935))
                    .withValues(alpha: fade);
          canvas.drawLine(c + Offset(math.cos(a), math.sin(a)) * r0,
              c + Offset(math.cos(a), math.sin(a)) * r1, line);
        }
      case DieFx.ward:
        // A hexagonal ward opening and thinning.
        for (var ring = 0; ring < (big ? 2 : 1); ring++) {
          final k = (t - ring * 0.18).clamp(0.0, 1.0);
          final path = Path();
          final rad = u * (0.5 + 0.7 * Curves.easeOutCubic.transform(k));
          for (var i = 0; i < 6; i++) {
            final a = i * math.pi / 3 + math.pi / 6;
            final p = c + Offset(math.cos(a), math.sin(a)) * rad;
            i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
          }
          path.close();
          line
            ..strokeWidth = 3 * (1 - k) + 0.6
            ..color = const Color(0xFF9FC2D6).withValues(alpha: 0.85 * (1 - k));
          canvas.drawPath(path, line);
        }
        fill.color = const Color(0xFF90B4C8).withValues(alpha: 0.22 * fade);
        canvas.drawCircle(c, u * (0.55 + 0.4 * out), fill);
      case DieFx.bloom:
        // Little crosses rising, swaying, pink and pale.
        final n = big ? 11 : 7;
        for (var i = 0; i < n; i++) {
          final dx = (_hash(i, 3) - 0.5) * u * 1.3;
          final start = _hash(i, 4) * 0.3;
          final k = ((t - start) / (1 - start)).clamp(0.0, 1.0);
          final p = c +
              Offset(
                  dx + math.sin(k * 5 + i) * u * 0.08, u * 0.25 - k * u * 1.15);
          final s = u * (0.07 + _hash(i, 5) * 0.07);
          line
            ..strokeWidth = 2.2
            ..color =
                (i.isEven ? const Color(0xFFF48FB1) : const Color(0xFFE8F5E9))
                    .withValues(alpha: math.sin(math.pi * k).clamp(0.0, 1.0));
          canvas.drawLine(p - Offset(s, 0), p + Offset(s, 0), line);
          canvas.drawLine(p - Offset(0, s), p + Offset(0, s), line);
        }
        fill.color = const Color(0xFFEC407A).withValues(alpha: 0.18 * fade);
        canvas.drawCircle(c, u * 0.7, fill);
      case DieFx.arcs:
        // Blue motes orbiting up and outward.
        final n = big ? 12 : 8;
        for (var i = 0; i < n; i++) {
          final a = i * 2 * math.pi / n + t * 4;
          final r = u * (0.45 + 0.55 * out);
          final p =
              c + Offset(math.cos(a) * r, math.sin(a) * r * 0.7 - t * u * 0.5);
          fill.color =
              (i.isEven ? const Color(0xFF64B5F6) : const Color(0xFFBBDEFB))
                  .withValues(alpha: fade);
          canvas.drawCircle(p, 2.6 * fade + 0.8, fill);
        }
        line
          ..strokeWidth = 1.6
          ..color = const Color(0xFF64B5F6).withValues(alpha: 0.7 * fade);
        canvas.drawCircle(c, u * (0.5 + 0.7 * out), line);
      case DieFx.miasma:
        // Green bubbles rising out of a thin cloud.
        fill.color = const Color(0xFF43A047).withValues(alpha: 0.2 * fade);
        canvas.drawOval(
            Rect.fromCenter(
                center: c + Offset(0, u * 0.1),
                width: u * 1.6 * out + u * 0.6,
                height: u * 0.9),
            fill);
        final n = big ? 10 : 7;
        for (var i = 0; i < n; i++) {
          final dx = (_hash(i, 6) - 0.5) * u * 1.0;
          final k = ((t - _hash(i, 7) * 0.3) / 0.7).clamp(0.0, 1.0);
          final p = c + Offset(dx, u * 0.3 - k * u * 1.0);
          line
            ..strokeWidth = 1.6
            ..color = const Color(0xFF81C784)
                .withValues(alpha: math.sin(math.pi * k));
          canvas.drawCircle(p, 2 + k * 4, line);
        }
      case DieFx.shock:
        // Amber bolts, bright at first and gone fast.
        final flash = (1 - t * 2).clamp(0.0, 1.0);
        fill.color = const Color(0xFFFFC107).withValues(alpha: 0.5 * flash);
        canvas.drawCircle(c, u * 0.8, fill);
        final n = big ? 6 : 4;
        for (var i = 0; i < n; i++) {
          final a = i * 2 * math.pi / n + _hash(i, 8);
          final path = Path()..moveTo(c.dx, c.dy);
          var p = c;
          for (var k = 1; k <= 4; k++) {
            final r = u * (0.3 + 0.28 * k) * (0.5 + out * 0.5);
            final jag = (k.isEven ? 1 : -1) * u * 0.12;
            p = c +
                Offset(math.cos(a) * r - math.sin(a) * jag,
                    math.sin(a) * r + math.cos(a) * jag);
            path.lineTo(p.dx, p.dy);
          }
          line
            ..strokeWidth = 2.4 * fade + 0.4
            ..color = const Color(0xFFFFE082).withValues(alpha: fade);
          canvas.drawPath(path, line);
        }
      case DieFx.drain:
        // A purple ring closing and motes spiralling in.
        line
          ..strokeWidth = 2.4 * fade + 0.5
          ..color = const Color(0xFFAB47BC).withValues(alpha: 0.8 * fade);
        canvas.drawCircle(c, u * (1.1 - 0.7 * out), line);
        final n = big ? 12 : 8;
        for (var i = 0; i < n; i++) {
          final a = i * 2 * math.pi / n - t * 5;
          final r = u * (1.0 - 0.8 * out);
          fill.color = const Color(0xFFCE93D8).withValues(alpha: fade);
          canvas.drawCircle(
              c + Offset(math.cos(a), math.sin(a)) * r, 2.4 * fade + 0.6, fill);
        }
      case DieFx.fizzle:
        // Grey dust puffing out and thinning: nothing came of it.
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3 + _hash(i, 9);
          final r = u * (0.25 + 0.5 * out);
          fill.color = const Color(0xFF9E9E9E).withValues(alpha: 0.32 * fade);
          canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r,
              u * (0.12 + 0.12 * out), fill);
        }
    }
    _element(canvas, c, u, t, out, fade, line, fill);
    for (final keyword in keywords) {
      _keyword(canvas, keyword, c, u, t, out, fade, line, fill);
    }
    if (surge) {
      // A gold dashed ring turning, and a crown over the die.
      line
        ..strokeWidth = 2.4
        ..color = const Color(0xFFF2C14E)
            .withValues(alpha: 0.9 * math.min(1.0, fade * 1.6));
      final ring = Path()
        ..addOval(Rect.fromCircle(center: c, radius: u * 0.95));
      for (final metric in ring.computeMetrics()) {
        for (var d = t * 40; d < metric.length; d += 11) {
          canvas.drawPath(
              metric.extractPath(d, math.min(d + 5, metric.length)), line);
        }
      }
      final crown = c + Offset(0, -u * 1.05);
      canvas.drawPath(
          Path()
            ..moveTo(crown.dx - 9, crown.dy + 6)
            ..lineTo(crown.dx - 11, crown.dy - 4)
            ..lineTo(crown.dx - 4, crown.dy + 1)
            ..lineTo(crown.dx, crown.dy - 7)
            ..lineTo(crown.dx + 4, crown.dy + 1)
            ..lineTo(crown.dx + 11, crown.dy - 4)
            ..lineTo(crown.dx + 9, crown.dy + 6)
            ..close(),
          fill
            ..color = const Color(0xFFF2C14E)
                .withValues(alpha: math.min(1.0, fade * 1.6)));
    }
    if (cursed) {
      // Chains across the die that fade slowly.
      line
        ..strokeWidth = 3
        ..color =
            const Color(0xFF9E9E9E).withValues(alpha: 0.85 * math.sqrt(fade));
      for (final s in [-1.0, 1.0]) {
        final chain = Path()
          ..moveTo(c.dx - u * .75, c.dy + s * u * .28)
          ..quadraticBezierTo(
              c.dx, c.dy + s * u * .02, c.dx + u * .75, c.dy + s * u * .28);
        for (final metric in chain.computeMetrics()) {
          for (var d = 0.0; d < metric.length; d += 11) {
            canvas.drawPath(
                metric.extractPath(d, math.min(d + 7, metric.length)), line);
          }
        }
      }
    }
    if (big) {
      // The heavy ones throw a four-point glint.
      final g = math.sin(math.pi * t.clamp(0.0, 1.0));
      line
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.85 * g);
      final len = u * 0.8 * g;
      canvas.drawLine(c - Offset(len, 0), c + Offset(len, 0), line);
      canvas.drawLine(c - Offset(0, len), c + Offset(0, len), line);
    }
  }

  /// The element's tint over the burst: a few motes of what it is.
  void _element(Canvas canvas, Offset c, double u, double t, double out,
      double fade, Paint line, Paint fill) {
    final color = switch (element) {
      'Fire' => const Color(0xFFFF7043),
      'Water' => const Color(0xFF4FC3F7),
      'Wind' => const Color(0xFFA5D6C8),
      'Earth' => const Color(0xFFA1887F),
      'Electricity' => const Color(0xFFFFE082),
      'Ice' => const Color(0xFFB3E5FC),
      'Void' => const Color(0xFF9575CD),
      'Light' => const Color(0xFFFFF59D),
      _ => null,
    };
    if (color == null) return;
    line
      ..strokeWidth = 2
      ..color = color.withValues(alpha: fade);
    fill.color = color.withValues(alpha: fade * 0.85);
    switch (element) {
      case 'Fire':
        for (var i = 0; i < 8; i++) {
          final x = (_hash(i, 11) - .5) * u * 1.2;
          final y = u * .4 - t * u * (.8 + _hash(i, 12) * .6);
          canvas.drawCircle(c + Offset(x, y), 2.4 * fade + 1, fill);
        }
      case 'Water':
        for (var i = 0; i < 6; i++) {
          final x = (_hash(i, 13) - .5) * u * 1.1;
          final y = -u * .7 + t * u * 1.5 * (.7 + _hash(i, 14) * .5);
          canvas.drawOval(
              Rect.fromCenter(center: c + Offset(x, y), width: 4, height: 7),
              fill);
        }
      case 'Wind':
        for (var i = 0; i < 3; i++) {
          final r = u * (.55 + i * .22);
          canvas.drawArc(Rect.fromCircle(center: c, radius: r), t * 7 + i * 2,
              1.7, false, line);
        }
      case 'Earth':
        for (var i = 0; i < 6; i++) {
          final x = (_hash(i, 15) - .5) * u * 1.3;
          final up = math.sin(math.pi * t) * u * (.3 + _hash(i, 16) * .5);
          canvas.drawRect(
              Rect.fromCenter(
                  center: c + Offset(x, u * .5 - up), width: 5, height: 5),
              fill);
        }
      case 'Electricity':
        if (t < .6) {
          for (var i = 0; i < 2; i++) {
            final a = i * math.pi + _hash(i, 17) * 2;
            final path = Path()..moveTo(c.dx, c.dy);
            for (var k = 1; k <= 3; k++) {
              final r = u * .45 * k;
              final j = (k.isEven ? 1 : -1) * u * .1;
              path.lineTo(c.dx + math.cos(a) * r - math.sin(a) * j,
                  c.dy + math.sin(a) * r + math.cos(a) * j);
            }
            canvas.drawPath(path, line);
          }
        }
      case 'Ice':
        for (var i = 0; i < 4; i++) {
          final a = math.pi / 4 + i * math.pi / 2;
          final base = c + Offset(math.cos(a), math.sin(a)) * u * .75;
          final tip = base + Offset(math.cos(a), math.sin(a)) * u * .35 * out;
          canvas.drawPath(
              Path()
                ..moveTo(base.dx - 3, base.dy)
                ..lineTo(tip.dx, tip.dy)
                ..lineTo(base.dx + 3, base.dy)
                ..close(),
              fill);
        }
      case 'Void':
        for (var i = 0; i < 3; i++) {
          final a = i * 2.1 + t * 2;
          final r = u * (.5 + .7 * out);
          canvas.drawArc(
              Rect.fromCircle(center: c, radius: r), a, .9, false, line);
        }
      case 'Light':
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          canvas.drawLine(c + Offset(math.cos(a), math.sin(a)) * u * .5,
              c + Offset(math.cos(a), math.sin(a)) * u * (.5 + .7 * out), line);
        }
    }
  }

  /// A rule word's flourish on landing.
  void _keyword(Canvas canvas, FaceKeyword keyword, Offset c, double u,
      double t, double out, double fade, Paint line, Paint fill) {
    switch (keyword) {
      case FaceKeyword.cleave:
        // The blow splits: arcs flung to either side.
        line
          ..strokeWidth = 3
          ..color = const Color(0xFFFF8A3D).withValues(alpha: fade);
        for (final s in [-1.0, 1.0]) {
          final x = c.dx + s * u * (.4 + .9 * out);
          canvas.drawArc(
              Rect.fromCenter(
                  center: Offset(x, c.dy), width: u * .5, height: u * 1.1),
              s > 0 ? -1.1 : math.pi - 1.1,
              2.2,
              false,
              line);
        }
      case FaceKeyword.pierce:
        // A line driven clean through.
        line
          ..strokeWidth = 3
          ..color = const Color(0xFF7FD1FF).withValues(alpha: fade);
        final x = c.dx - u * 1.1 + u * 2.2 * out;
        canvas.drawLine(Offset(x - u * .7, c.dy), Offset(x, c.dy), line);
        canvas.drawLine(Offset(x, c.dy), Offset(x - 8, c.dy - 6), line);
        canvas.drawLine(Offset(x, c.dy), Offset(x - 8, c.dy + 6), line);
      case FaceKeyword.growth:
        // A +1 rising off the die.
        final tp = TextPainter(
          text: TextSpan(
              text: '+1',
              style: TextStyle(
                  color: const Color(0xFFCFEFB8).withValues(alpha: fade),
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, c + Offset(u * .45, -u * .75 - out * u * .45));
      case FaceKeyword.echo:
        // Rings repeating the landing.
        for (var i = 0; i < 3; i++) {
          final k = (t - i * .14).clamp(0.0, 1.0);
          line
            ..strokeWidth = 2.2 * (1 - k) + .4
            ..color = const Color(0xFFB39DFF).withValues(alpha: .8 * (1 - k));
          canvas.drawCircle(
              c, u * (.5 + .8 * Curves.easeOutCubic.transform(k)), line);
        }
      case FaceKeyword.pain:
        // A crack across the die and a drop falling.
        line
          ..strokeWidth = 2.6
          ..color = const Color(0xFFE8473F).withValues(alpha: fade);
        canvas.drawPath(
            Path()
              ..moveTo(c.dx - u * .15, c.dy - u * .6)
              ..lineTo(c.dx + u * .05, c.dy - u * .15)
              ..lineTo(c.dx - u * .1, c.dy + u * .15)
              ..lineTo(c.dx + u * .1, c.dy + u * .6),
            line);
        fill.color = const Color(0xFFE8473F).withValues(alpha: fade);
        final dy = c.dy + u * .6 + out * u * .7;
        canvas.drawPath(
            Path()
              ..moveTo(c.dx + u * .3, dy - 6)
              ..quadraticBezierTo(
                  c.dx + u * .3 - 5, dy + 2, c.dx + u * .3, dy + 4)
              ..quadraticBezierTo(
                  c.dx + u * .3 + 5, dy + 2, c.dx + u * .3, dy - 6),
            fill);
      case FaceKeyword.steady:
        // An anchor dropped over the die.
        final k = math.sin(math.pi * t.clamp(0.0, 1.0));
        line
          ..strokeWidth = 3
          ..color = const Color(0xFFD6C28A).withValues(alpha: k);
        final a = c + Offset(0, -u * .95);
        canvas.drawCircle(a + const Offset(0, -9), 4, line);
        canvas.drawLine(a + const Offset(0, -5), a + const Offset(0, 11), line);
        canvas.drawLine(a + const Offset(-6, 0), a + const Offset(6, 0), line);
        canvas.drawArc(
            Rect.fromCenter(
                center: a + const Offset(0, 6), width: 22, height: 14),
            0,
            math.pi,
            false,
            line);
    }
  }

  @override
  bool shouldRepaint(DieBurstPainter old) =>
      old.t != t ||
      old.fx != fx ||
      old.big != big ||
      old.unit != unit ||
      old.surge != surge ||
      old.cursed != cursed ||
      old.element != element ||
      old.keywords != keywords;
}
