// The dice are thrown (v2.10.16, UX-2): each die falls from above the board on
// a short arc, touches the floor, bounces once or twice with decreasing height
// and settles on its seat, turning as it goes, a shadow on the floor under it
// that grows and sharpens as it falls and a puff of dust at each contact (drawn
// by dice_ground.dart). The rules have already decided every die's face; this
// plans where the dice go. Cosmetic only: nothing here reads or changes a
// face, and a die's roll progress ends at 1, which is the face the rules
// picked standing at the front (see Die3D).
//
// The plan is pure: built once per throw from the seats the board gave the
// dice, sampled at 1/120 of the throw, so a frame costs a lookup. Several dice
// start 55 ms apart and land in a scatter, never on top of one another (each
// has its own seat). With reduced motion the throw is a short drop and a
// settle, no bounce and no dust. The cheap-solids profile does not use it (the
// board keeps its plain flight).
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart' show Listenable;
import 'package:flutter/rendering.dart' show CustomClipper;
import 'dart:ui'
    show Offset, Path, PathOperation, RRect, Radius, Rect, Size, lerpDouble;

/// Where a die ends and how big it is; [fixed] ones (kept through a reroll)
/// do not move but are in the way.
class DiceThrowSeat {
  const DiceThrowSeat(this.seat, this.radius, {this.fixed = false});
  final Offset seat;
  final double radius;
  final bool fixed;
}

/// How long the throw lasts, in milliseconds (the controller's, before the
/// speed setting); a reduced-motion throw is [diceDropReducedMs].
const int diceDropMs = 880;
const int diceDropReducedMs = 200;

class DiceThrowPlan {
  DiceThrowPlan._(this._pos, this._lift, this._turn, this._radii, this.count,
      {required this.contacts, required this.reduced});

  final List<double> _radii;

  /// How wide die [i] is drawn for the throw (never more than its seat's).
  double radiusOf(int i) => _radii[i];

  /// The moments (0 to 1 of the throw) each die touches the floor: the puffs
  /// of dust. Empty for a reduced-motion throw (no dust).
  final List<List<double>> contacts;

  /// Whether this is the reduced-motion throw: a drop and a settle.
  final bool reduced;

  /// The throw of [seats] on a [board] (seat and board in the same
  /// coordinates); [seed] varies the throw from one roll to the next.
  factory DiceThrowPlan.build({
    required List<DiceThrowSeat> seats,
    required Size board,
    required int seed,
    bool reduced = false,
  }) {
    final rnd = math.Random(seed);
    final n = seats.length;
    const frames = 120;
    // Two seats closer than their dice are wide: the dice are drawn smaller
    // for the throw, so they stand apart at rest as the board lays them.
    final radii = [for (final s in seats) s.radius];
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final d = (seats[i].seat - seats[j].seat).distance;
        final need = radii[i] + radii[j];
        if (need > d && need > 0) {
          radii[i] *= d / need * 0.98;
          radii[j] *= d / need * 0.98;
        }
      }
    }
    final total = (reduced ? diceDropReducedMs : diceDropMs) / 1000;
    // The fall, the bounce (none when reduced) and the second.
    const e = 0.36;
    final tFall = reduced ? 0.13 : 0.23;
    final z0 = board.height * (reduced ? 0.3 : 0.62);
    final g = 2 * z0 / (tFall * tFall);
    final vz = g * tFall;
    final tb1 = reduced ? 0.0 : 2 * e * vz / g;
    final tb2 = reduced ? 0.0 : 2 * e * e * vz / g;
    final delay = [for (var i = 0; i < n; i++) reduced ? 0.0 : i * 0.055];
    final back = [
      for (var i = 0; i < n; i++)
        Offset((rnd.nextDouble() - 0.5) * 70, -(60 + rnd.nextDouble() * 50)),
    ];
    final tEnd = [
      for (var i = 0; i < n; i++)
        delay[i] + tFall + tb1 + tb2 + (reduced ? 0.04 : 0.14),
    ];
    final contacts = <List<double>>[
      for (var i = 0; i < n; i++)
        reduced || seats[i].fixed
            ? const []
            : [
                (delay[i] + tFall) / total,
                (delay[i] + tFall + tb1) / total,
                (delay[i] + tFall + tb1 + tb2) / total,
              ],
    ];
    final pos = <List<Offset>>[];
    final liftAt = <List<double>>[];
    final turn = <List<double>>[];
    for (var f = 0; f < frames; f++) {
      final u = f / (frames - 1);
      final time = u * total;
      final p = <Offset>[], l = <double>[], t = <double>[];
      for (var i = 0; i < n; i++) {
        final seat = seats[i].seat;
        if (seats[i].fixed) {
          p.add(seat);
          l.add(0);
          t.add(1);
          continue;
        }
        final tt = time - delay[i];
        // Height above the floor.
        double z;
        if (tt < 0) {
          z = z0 + 40;
        } else if (tt < tFall) {
          z = z0 - 0.5 * g * tt * tt;
        } else if (tt < tFall + tb1) {
          final x = tt - tFall;
          z = e * vz * x - 0.5 * g * x * x;
        } else if (tt < tFall + tb1 + tb2) {
          final x = tt - tFall - tb1;
          z = e * e * vz * x - 0.5 * g * x * x;
        } else {
          z = 0;
        }
        // The floor point slides from behind to the seat while it falls, then
        // rests.
        final slide =
            Curves.easeOutQuad.transform((tt / (tFall * 1.08)).clamp(0.0, 1.0));
        p.add(seat + back[i] * (1 - slide));
        l.add(math.max(0.0, z));
        // The turn: from the throw to a few frames after the last touch, with
        // a small dip at each contact, exactly 1 at the end.
        final s = (tt / (tEnd[i] - delay[i] - 0.04)).clamp(0.0, 1.0);
        var dip = 0.0;
        for (final c in contacts[i]) {
          final x = (time - c * total) / 0.10;
          if (x > 0 && x < 1) dip += 0.04 * math.sin(math.pi * x) * (1 - s);
        }
        t.add(u >= 1
            ? 1.0
            : (Curves.easeOutCubic.transform(s) - dip).clamp(0.0, 1.0));
      }
      pos.add(p);
      liftAt.add(l);
      turn.add(t);
    }
    return DiceThrowPlan._(pos, liftAt, turn, radii, n,
        contacts: contacts, reduced: reduced);
  }

  final List<List<Offset>> _pos;
  final List<List<double>> _lift;
  final List<List<double>> _turn;
  final int count;

  int get _frames => _pos.length;

  T _at<T>(List<List<T>> rows, int i, double u, T Function(T, T, double) mix) {
    final x = u.clamp(0.0, 1.0) * (_frames - 1);
    final f = x.floor().clamp(0, _frames - 1);
    final g = math.min(f + 1, _frames - 1);
    return mix(rows[f][i], rows[g][i], x - f);
  }

  /// Die [i]'s ground point at [u] (0 to 1 of the throw), in board
  /// coordinates; at 1 exactly its seat.
  Offset position(int i, double u) =>
      _at(_pos, i, u, (a, b, t) => Offset.lerp(a, b, t)!);

  /// How high above the board die [i] is at [u], in logical pixels.
  double lift(int i, double u) =>
      _at(_lift, i, u, (a, b, t) => lerpDouble(a, b, t)!);

  /// Die [i]'s roll progress at [u], what a Die3D's `roll` reads: 1 at the
  /// end, the face the rules picked at the front.
  double turn(int i, double u) =>
      _at(_turn, i, u, (a, b, t) => lerpDouble(a, b, t)!);

  /// [turn] as a curve, to drive a Die3D's roll from the throw's controller.
  Curve turnCurve(int i) => _TurnCurve(this, i);
}

class _TurnCurve extends Curve {
  const _TurnCurve(this.plan, this.i);
  final DiceThrowPlan plan;
  final int i;

  @override
  double transformInternal(double t) => plan.turn(i, t);
}

/// The screen with a round-cornered hole at each die: what is clipped by it
/// (the day's weather) never crosses a die. [holes] is read each time the
/// clip is made, and [repaint] re-makes it every frame of a throw.
class DiceHoles extends CustomClipper<Path> {
  DiceHoles(this.holes, Listenable repaint) : super(reclip: repaint);

  final List<Rect> Function() holes;

  @override
  Path getClip(Size size) {
    var path = Path()..addRect(Offset.zero & size);
    for (final hole in holes()) {
      path = Path.combine(
          PathOperation.difference,
          path,
          Path()
            ..addRRect(
                RRect.fromRectAndRadius(hole, const Radius.circular(16))));
    }
    return path;
  }

  @override
  bool shouldReclip(DiceHoles old) => true;
}
