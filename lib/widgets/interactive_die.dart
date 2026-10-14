// A die cube the player turns (v1.241): the same cube the fight tumbles (see
// die_3d.dart), but dragged round with a finger and let go onto the face
// nearest the viewer, which it then reports as the picked one. A tap on a
// side that shows turns the cube to it; a double tap on a side acts on it
// (the loadout opens its skill picker). The cube is six flat faces in 3D
// like the fight's, so what is drawn on them is the same widgets.
//
// It turns on the screen's axes (v1.267): a drag across turns it about the
// upright and a drag down tips it, whichever side is in front, so from the
// top or the bottom it still goes to a side. It used to keep a yaw about its
// own upright and a tip, and from the top or bottom a drag across only spun
// it in place.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'die_3d.dart';
import 'die_skins.dart';

/// The two turns that bring side [slot] of the cube to the front: the cube
/// yawed about the upright (0 front, 1 right, 2 back, 3 left) or tipped over
/// (4 top, 5 bottom), with the die's rest tilt on top so an edge shows.
(double, double) dieFrontAngles(int slot) => switch (slot) {
      0 => (dieRestTipX, dieRestTurnY),
      1 => (dieRestTipX, dieRestTurnY + math.pi / 2),
      2 => (dieRestTipX, dieRestTurnY + math.pi),
      3 => (dieRestTipX, dieRestTurnY - math.pi / 2),
      // Standing on its top or bottom, no yaw, so the face sits upright.
      4 => (math.pi / 2 + dieRestTipX, 0.0),
      _ => (-math.pi / 2 + dieRestTipX, 0.0),
    };

/// The side of the cube nearest the viewer for a cube tipped [rx] and
/// yawed [ry].
int dieFrontSlot(double rx, double ry) {
  var best = 0;
  var bestDistance = double.infinity;
  for (var slot = 0; slot < 6; slot++) {
    final (tx, ty) = dieFrontAngles(slot);
    final dx = _wrap(rx - tx);
    // A cube tipped on its top or bottom turns in place when yawed: the yaw
    // does not tell which side faces front.
    final dy = slot >= 4 ? 0.0 : _wrap(ry - ty);
    final d = dx * dx + dy * dy;
    if (d < bestDistance) {
      bestDistance = d;
      best = slot;
    }
  }
  return best;
}

/// [a] brought into -pi..pi.
double _wrap(double a) {
  final t = (a + math.pi) % (2 * math.pi);
  return (t < 0 ? t + 2 * math.pi : t) - math.pi;
}

/// The turn that stands side [slot] in front, upright.
Matrix4 diePose(int slot) {
  final (rx, ry) = dieFrontAngles(slot);
  return Matrix4.identity()
    ..rotateX(rx)
    ..rotateY(ry);
}

/// The side of the cube nearest the viewer for a cube turned by [model].
int dieFrontSlotOf(Matrix4 model) {
  var best = 0;
  var nearest = double.infinity;
  for (var slot = 0; slot < 6; slot++) {
    final depth = CubeFacePlacement.of(slot, model, 1).depth;
    if (depth < nearest) {
      nearest = depth;
      best = slot;
    }
  }
  return best;
}

/// The turn of [angle] about the unit axis (x, y, z).
Matrix4 _axisAngle(double x, double y, double z, double angle) {
  final c = math.cos(angle);
  final s = math.sin(angle);
  final t = 1 - c;
  return Matrix4(
    t * x * x + c, t * x * y + s * z, t * x * z - s * y, 0, //
    t * x * y - s * z, t * y * y + c, t * y * z + s * x, 0, //
    t * x * z + s * y, t * y * z - s * x, t * z * z + c, 0, //
    0, 0, 0, 1,
  );
}

/// The axis and angle of the turn [from] -> [to] (both rotations), the short
/// way round.
(double, double, double, double) _between(Matrix4 from, Matrix4 to) {
  final d = to.multiplied(from.transposed());
  final cosine = ((d.entry(0, 0) + d.entry(1, 1) + d.entry(2, 2) - 1) / 2)
      .clamp(-1.0, 1.0);
  final angle = math.acos(cosine);
  if (angle < 1e-6) return (0, 1, 0, 0);
  var ax = d.entry(2, 1) - d.entry(1, 2);
  var ay = d.entry(0, 2) - d.entry(2, 0);
  var az = d.entry(1, 0) - d.entry(0, 1);
  var length = math.sqrt(ax * ax + ay * ay + az * az);
  if (length < 1e-6) {
    // A half turn: the axis is the one the matrix keeps.
    ax = math.sqrt(math.max(0.0, (d.entry(0, 0) + 1) / 2));
    ay = math.sqrt(math.max(0.0, (d.entry(1, 1) + 1) / 2));
    az = math.sqrt(math.max(0.0, (d.entry(2, 2) + 1) / 2));
    length = math.sqrt(ax * ax + ay * ay + az * az);
  }
  return (ax / length, ay / length, az / length, angle);
}

class InteractiveDie extends StatefulWidget {
  const InteractiveDie({
    super.key,
    required this.faces,
    required this.skin,
    required this.selected,
    required this.onSelect,
    this.onActivate,
    this.size = 96,
    this.still = false,
  }) : assert(faces.length == 6);

  /// The six sides, slot 0 the one in front at rest.
  final List<DieCubeFace> faces;
  final DieSkin skin;

  /// The side that stands in front (and wears a gold ring).
  final int selected;

  /// A side was turned to the front, by a drag or a tap on it.
  final ValueChanged<int> onSelect;

  /// A side was double-tapped.
  final ValueChanged<int>? onActivate;

  /// The cube's edge in logical pixels.
  final double size;

  /// With reduced motion the cube jumps rather than turns.
  final bool still;

  @override
  State<InteractiveDie> createState() => _InteractiveDieState();
}

class _InteractiveDieState extends State<InteractiveDie>
    with SingleTickerProviderStateMixin {
  /// How the cube is turned now (a rotation).
  late Matrix4 _m = diePose(widget.selected);
  late final AnimationController _turn = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 280));

  /// Where the turn in progress started and ends.
  late Matrix4 _from = _m;
  late Matrix4 _to = _m;
  bool _dragging = false;
  int? _doubleTapAt;

  @override
  void initState() {
    super.initState();
    _turn.addListener(() {
      final e = Curves.easeOutCubic.transform(_turn.value);
      final (x, y, z, angle) = _between(_from, _to);
      setState(() => _m = _axisAngle(x, y, z, angle * e).multiplied(_from));
    });
  }

  @override
  void didUpdateWidget(InteractiveDie old) {
    super.didUpdateWidget(old);
    // Told from outside to stand another side in front.
    if (old.selected != widget.selected &&
        !_dragging &&
        dieFrontSlotOf(_to) != widget.selected) {
      _turnTo(widget.selected);
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  /// Turns the cube, the short way round, to put [slot] in front.
  void _turnTo(int slot) {
    _from = _m;
    _to = diePose(slot);
    if (widget.still) {
      setState(() => _m = _to);
      return;
    }
    _turn.forward(from: 0);
  }

  void _settle() {
    final slot = dieFrontSlotOf(_m);
    _turnTo(slot);
    if (slot != widget.selected) widget.onSelect(slot);
  }

  Matrix4 get _model => _m;

  List<CubeFacePlacement> get _placed => [
        for (var i = 0; i < 6; i++)
          CubeFacePlacement.of(i, _model, widget.size / 2),
      ];

  /// The side under [local] (centre-relative), nearest first, or null.
  int? _hit(Offset local) {
    final visible = _placed.where((p) => p.visible).toList()
      ..sort((a, b) => a.depth.compareTo(b.depth));
    final h = widget.size / 2;
    for (final p in visible) {
      final quad = [
        for (final c in [
          Offset(-h, -h),
          Offset(h, -h),
          Offset(h, h),
          Offset(-h, h)
        ])
          MatrixUtils.transformPoint(p.matrix, c),
      ];
      if (_inside(quad, local)) return p.slot;
    }
    return null;
  }

  static bool _inside(List<Offset> quad, Offset p) {
    var inside = false;
    for (var i = 0, j = quad.length - 1; i < quad.length; j = i++) {
      final a = quad[i];
      final b = quad[j];
      if ((a.dy > p.dy) != (b.dy > p.dy) &&
          p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) {
        inside = !inside;
      }
    }
    return inside;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final area = size * 1.7;
    final placed = _placed..sort((a, b) => b.depth.compareTo(a.depth));
    final front = dieFrontSlotOf(_m);
    return Semantics(
      label: 'die',
      child: GestureDetector(
        key: const ValueKey('interactive_die'),
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          _dragging = true;
          _turn.stop();
        },
        // The turn is about the screen's axes: across about the upright,
        // down about the horizontal, whichever side is in front.
        onPanUpdate: (d) => setState(() {
          final turn = Matrix4.rotationX(d.delta.dy * 0.014)
              .multiplied(Matrix4.rotationY(-d.delta.dx * 0.014));
          _m = turn.multiplied(_m);
        }),
        onPanEnd: (_) {
          _dragging = false;
          _settle();
        },
        onPanCancel: () {
          _dragging = false;
          _settle();
        },
        // A tap on a side that shows turns the cube to it.
        onTapUp: (d) {
          final slot = _hit(d.localPosition - Offset(area / 2, area / 2));
          if (slot == null || slot == front && slot == widget.selected) return;
          _turnTo(slot);
          widget.onSelect(slot);
        },
        // A double tap acts on the side it lands on (the loadout opens its
        // skill picker).
        onDoubleTapDown: (d) =>
            _doubleTapAt = _hit(d.localPosition - Offset(area / 2, area / 2)),
        onDoubleTap: () {
          final slot = _doubleTapAt;
          if (slot == null) return;
          if (slot != widget.selected) {
            _turnTo(slot);
            widget.onSelect(slot);
          }
          widget.onActivate?.call(slot);
        },
        child: SizedBox(
          width: area,
          height: area,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              if (widget.skin.glow != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          widget.skin.glow!.withValues(alpha: 0.30),
                          widget.skin.glow!.withValues(alpha: 0),
                        ]),
                      ),
                    ),
                  ),
                ),
              // Its shadow on the table.
              Positioned(
                bottom: area * 0.5 - size * 0.78,
                child: Container(
                  width: size * 0.9,
                  height: size * 0.16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size),
                    color: Colors.black.withValues(alpha: 0.28),
                  ),
                ),
              ),
              for (final p in placed)
                if (p.visible)
                  Transform(
                    alignment: Alignment.center,
                    transform: p.matrix,
                    child: DieFaceTile(
                      face: widget.faces[p.slot],
                      size: size,
                      skin: widget.skin,
                      skinned: true,
                      placement: p,
                      ring: p.slot == widget.selected && p.slot == front
                          ? const Color(0xFFF2C14E)
                          : null,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
