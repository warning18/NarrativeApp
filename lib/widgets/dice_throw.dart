// The dice are thrown and roll (v2.10.19, UX-2): each die is flung onto the
// board in one of five ways (from the left, from the right, dropped from above
// and rolling sideways, tossed from the bottom-left corner up the board, flung
// hard at the side edge and rolling back), flies low, touches the floor, bounces
// lower each time and rolls on, turning over its edges two full turns or
// more, easing out over the last turn, a final rock, then rest. A shadow
// follows it on the floor and a puff rises at each contact (dice_ground.dart).
// The rules have already decided every die's face; this plans where the dice
// go and how they turn. Cosmetic only: nothing here reads or changes a face,
// and a die's turns end on whole turns, so the face the rules picked stands at
// the front (see Die3D).
//
// The plan is pure: built once per throw from the seats the board gave the
// dice, sampled at 1/170 of the throw, so a frame costs a lookup. Several dice
// start 70 ms apart, each in a different way, and land in a scatter, never on
// top of one another (each has its own seat). With reduced motion the throw is
// a short drop and a settle, no turns and no dust. The cheap-solids profile does
// not use it (the board keeps its plain flight).
import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart' show Listenable, visibleForTesting;
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
const int diceDropMs = 1700;
const int diceDropReducedMs = 200;

/// The five ways a die is thrown.
enum DiceThrowKind { fromLeft, fromRight, dropRoll, diagonal, wallBounce }

/// Pictures and tests set this to fix the ways the dice are thrown; null in
/// play, where each roll picks its own.
@visibleForTesting
List<DiceThrowKind>? diceThrowKindsOverride;

/// A die's turn at one moment: the angles (radians) about the x, y and z axes,
/// applied in that order; whole turns at the end, so the face stands at the
/// front.
typedef DieAngles = ({double x, double y, double z});

class DiceThrowPlan {
  DiceThrowPlan._(
    this._pos,
    this._lift,
    this._turn,
    this._radii,
    this.count, {
    required this.contacts,
    required this.reduced,
    this.kinds = const [],
    List<List<DieAngles>>? angles,
  }) : _angles = angles;

  /// How each die is thrown (empty for a reduced-motion throw).
  final List<DiceThrowKind> kinds;

  final List<List<DieAngles>>? _angles;

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
    List<DiceThrowKind>? kinds,
  }) {
    if (!reduced) {
      return _thrown(seats, board, seed, kinds);
    }
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
        final slide = Curves.easeOutQuad.transform(
          (tt / (tFall * 1.08)).clamp(0.0, 1.0),
        );
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
        t.add(
          u >= 1
              ? 1.0
              : (Curves.easeOutCubic.transform(s) - dip).clamp(0.0, 1.0),
        );
      }
      pos.add(p);
      liftAt.add(l);
      turn.add(t);
    }
    return DiceThrowPlan._(
      pos,
      liftAt,
      turn,
      radii,
      n,
      contacts: contacts,
      reduced: reduced,
    );
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

  /// Die [i]'s turn at [u] (0 to 1 of the throw): null for a reduced-motion
  /// throw (the die keeps its own short settle).
  DieAngles? angles(int i, double u) {
    final rows = _angles;
    if (rows == null) return null;
    final x = u.clamp(0.0, 1.0) * (rows.length - 1);
    final f = x.floor().clamp(0, rows.length - 1);
    final g = math.min(f + 1, rows.length - 1);
    final k = x - f;
    final a = rows[f][i], b = rows[g][i];
    return (
      x: lerpDouble(a.x, b.x, k)!,
      y: lerpDouble(a.y, b.y, k)!,
      z: lerpDouble(a.z, b.z, k)!,
    );
  }

  /// The throw of [seats], each die in its own way.
  static DiceThrowPlan _thrown(
    List<DiceThrowSeat> seats,
    Size board,
    int seed,
    List<DiceThrowKind>? given,
  ) {
    final n = seats.length;
    const frames = 170;
    const total = diceDropMs / 1000;
    const stagger = 0.07;
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
    given ??= diceThrowKindsOverride;
    final kinds = [
      for (var i = 0; i < n; i++)
        given != null && i < given.length
            ? given[i]
            : DiceThrowKind.values[(seed.abs() + i * 2) % 5],
    ];
    final maxDelay = (n - 1) * stagger;
    final span = total - maxDelay;
    final contacts = <List<double>>[];
    final tracks = <_Track>[];
    for (var i = 0; i < n; i++) {
      final track = _Track(
        kinds[i],
        seats[i].seat,
        board,
        radii[i],
        dir: ((seed.abs() >> 2) + i).isEven ? 1 : -1,
      );
      tracks.add(track);
      contacts.add(
        seats[i].fixed
            ? const []
            : [
                for (final c in track.contacts)
                  (i * stagger + c * span) / total,
              ],
      );
    }
    final pos = <List<Offset>>[], liftAt = <List<double>>[];
    final angles = <List<DieAngles>>[], turn = <List<double>>[];
    for (var f = 0; f < frames; f++) {
      final u = f / (frames - 1);
      final time = u * total;
      final p = <Offset>[], l = <double>[], a = <DieAngles>[], t = <double>[];
      for (var i = 0; i < n; i++) {
        if (seats[i].fixed) {
          p.add(seats[i].seat);
          l.add(0);
          a.add((x: 0, y: 0, z: 0));
          t.add(1);
          continue;
        }
        final tau = ((time - i * stagger) / span).clamp(0.0, 1.0);
        final s = tracks[i].at(tau);
        p.add(s.ground);
        l.add(math.max(0.0, s.lift));
        a.add(u >= 1 ? (x: 0, y: 0, z: 0) : s.angles);
        t.add(u >= 1 ? 1.0 : tau);
      }
      pos.add(p);
      liftAt.add(l);
      angles.add(a);
      turn.add(t);
    }
    return DiceThrowPlan._(
      pos,
      liftAt,
      turn,
      radii,
      n,
      contacts: contacts,
      reduced: false,
      kinds: kinds,
      angles: angles,
    );
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

/// One sample of a die's throw.
class _Sample {
  const _Sample(this.ground, this.lift, this.angles);
  final Offset ground;
  final double lift;
  final DieAngles angles;
}

/// A flight between two touches of the floor: from [t0] at height [h0] to the
/// floor at [t1], rising to about [apex]; one that starts as high as its apex
/// is a plain fall.
typedef _Flight = (double t0, double t1, double h0, double apex);

double _out(double x, int power) =>
    1 - math.pow(1 - x.clamp(0.0, 1.0), power).toDouble();

/// One die's way of being thrown, as a function of its own time [tau]
/// (0 to 1): where it is on the floor, how high above it, how far it has turned.
class _Track {
  _Track(this.kind, this.seat, this.board, this.radius, {required this.dir}) {
    final w = board.width, h = board.height;
    switch (kind) {
      case DiceThrowKind.fromLeft:
      case DiceThrowKind.fromRight:
        flights = [
          (0.0, 0.27, 0.17 * h, 0.19 * h),
          (0.27, 0.45, 0.0, 0.05 * h),
          (0.45, 0.57, 0.0, 0.014 * h),
        ];
      case DiceThrowKind.dropRoll:
        flights = [
          (0.0, 0.26, 0.62 * h, 0.62 * h),
          (0.26, 0.48, 0.0, 0.11 * h),
          (0.48, 0.62, 0.0, 0.03 * h),
        ];
      case DiceThrowKind.diagonal:
        flights = [
          (0.0, 0.31, 0.06 * h, 0.18 * h),
          (0.31, 0.52, 0.0, 0.085 * h),
          (0.52, 0.68, 0.0, 0.03 * h),
        ];
      case DiceThrowKind.wallBounce:
        flights = [
          (0.0, 0.20, 0.10 * h, 0.12 * h),
          (0.20, 0.34, 0.0, 0.035 * h),
          (0.36, 0.46, 0.0, 0.03 * h),
          (0.46, 0.56, 0.0, 0.012 * h),
        ];
    }
    contacts = [for (final f in flights) f.$2];
    final off = radius * 2.6;
    switch (kind) {
      case DiceThrowKind.fromLeft:
        start = Offset(-off, seat.dy + 0.05 * h);
      case DiceThrowKind.fromRight:
        start = Offset(w + off, seat.dy + 0.05 * h);
      case DiceThrowKind.dropRoll:
        start = Offset(seat.dx - dir * 0.25 * w, seat.dy);
      case DiceThrowKind.diagonal:
        start = Offset(-off, h + off);
      case DiceThrowKind.wallBounce:
        start = Offset(-off, seat.dy + 0.10 * h);
    }
  }

  final DiceThrowKind kind;
  final Offset seat;
  final Size board;
  final double radius;
  final int dir;
  late final List<_Flight> flights;
  late final List<double> contacts;
  late final Offset start;

  double _z(double tau) {
    for (final (t0, t1, h0, apex) in flights) {
      if (tau >= t0 && tau < t1) {
        final x = (tau - t0) / (t1 - t0);
        return apex <= h0
            ? h0 * (1 - x * x)
            : h0 * (1 - x) + 4 * (apex - h0 / 2) * x * (1 - x);
      }
    }
    return 0;
  }

  _Sample at(double tau) {
    const tau2pi = 2 * math.pi;
    final w = board.width;
    late Offset ground;
    var ax = 0.0, ay = 0.0, az = 0.0;
    switch (kind) {
      case DiceThrowKind.fromLeft:
      case DiceThrowKind.fromRight:
        final d = kind == DiceThrowKind.fromLeft ? 1 : -1;
        final px = _out(tau / 0.92, 2);
        ground = Offset(
          start.dx + (seat.dx - start.dx) * px,
          start.dy + (seat.dy - start.dy) * _out(tau / 0.45, 3),
        );
        ay = d * tau2pi * 2 * px;
      case DiceThrowKind.dropRoll:
        final land = Offset(seat.dx - dir * 0.22 * w, seat.dy);
        final roll = _out((tau - 0.26) / 0.66, 2);
        ground = tau < 0.26
            ? Offset.lerp(start, land, tau / 0.26)!
            : Offset.lerp(land, seat, roll)!;
        ax = tau2pi * _out(tau / 0.55, 2);
        ay = dir * tau2pi * roll;
      case DiceThrowKind.diagonal:
        final p = _out(tau / 0.93, 2);
        ground = Offset.lerp(start, seat, p)!;
        ay = tau2pi * p;
        ax = -tau2pi * 2 * p;
      case DiceThrowKind.wallBounce:
        final wall = w - radius - 3;
        const tw = 0.36;
        final x = tau < tw
            ? start.dx + (wall - start.dx) * (tau / tw)
            : wall + (seat.dx - wall) * _out((tau - tw) / (0.92 - tw), 2);
        ground = Offset(
          x,
          start.dy + (seat.dy - start.dy) * _out(tau / 0.5, 2),
        );
        ay = tau2pi * 2 * (x - start.dx) / (seat.dx - start.dx);
    }
    // The final rock, then rest.
    if (tau > 0.92) {
      final x = (tau - 0.92) / 0.08;
      final rock = 0.11 * math.sin(tau2pi * 2 * x) * (1 - x);
      ax += rock;
      az += rock * 0.5;
    }
    return _Sample(ground, _z(tau), (x: ax, y: ay, z: az));
  }
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
          ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(16))),
      );
    }
    return path;
  }

  @override
  bool shouldReclip(DiceHoles old) => true;
}
