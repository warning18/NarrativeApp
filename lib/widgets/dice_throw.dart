// The dice are thrown (v2.2, UX-2). The rules have already decided every die's
// face; this plans where the dice go: each flies in from the bottom edge on an
// arc, bounces 2 to 3 times with damping, slides, pushes the others aside
// without overlapping, and ends on its seat, turning as it slows. Cosmetic
// only: nothing here reads or changes a face, and a die's roll progress ends
// at 1, which is the face the rules picked standing at the front (see Die3D).
//
// The plan is pure: built once per throw from the seats the board gave the
// dice, a small simulation stepped at 1/120 s and sampled at 1/60 s, so a
// frame costs a lookup. Reduced motion and the cheap-solids profile do not
// use it (the board keeps its plain flight).
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

/// How long the simulated throw lasts, in seconds; the plan's 0 to 1 is this.
const double diceThrowSeconds = 2.3;

/// How high a die flies at most above the board, in logical pixels.
const double diceThrowMaxLift = 30;

class _Body {
  _Body(this.seat, this.r, this.fixed);
  final Offset seat;
  final double r;
  final bool fixed;
  double x = 0, y = 0, z = 0, vx = 0, vy = 0, vz = 0;
  int bounces = 0;
  double settled = -1;
}

class DiceThrowPlan {
  DiceThrowPlan._(this._pos, this._lift, this._turn, this._radii, this.count);

  final List<double> _radii;

  /// How wide die [i] is drawn for the throw (never more than its seat's).
  double radiusOf(int i) => _radii[i];

  /// Plans the throw of [seats] on a [board] (seat and board in the same
  /// coordinates); [seed] varies the throw from one roll to the next.
  factory DiceThrowPlan.build({
    required List<DiceThrowSeat> seats,
    required Size board,
    required int seed,
  }) {
    const dt = 1 / 120;
    const g = 1500.0;
    final rnd = math.Random(seed);
    // Two seats closer than their dice are wide: the dice are drawn smaller
    // for the throw, so they stand apart at rest as the board lays them.
    final radii = [for (final s in seats) s.radius];
    for (var i = 0; i < seats.length; i++) {
      for (var j = i + 1; j < seats.length; j++) {
        final d = (seats[i].seat - seats[j].seat).distance;
        final need = radii[i] + radii[j];
        if (need > d && need > 0) {
          radii[i] *= d / need * 0.98;
          radii[j] *= d / need * 0.98;
        }
      }
    }
    const launchZ = 24.0;
    final vz0 = math.sqrt(2 * g * (diceThrowMaxLift - launchZ));

    // One die alone: where it stops for a launch speed along its direction.
    // The aim is found at half the frame rate (it only needs to be close).
    const sdt = 1 / 60;
    Offset alone(_Body b, double v, Offset dir) {
      b
        ..z = launchZ
        ..vz = vz0
        ..vx = dir.dx * v
        ..vy = dir.dy * v
        ..bounces = 0;
      var x = b.x, y = b.y;
      for (var s = 0; s < (diceThrowSeconds / sdt); s++) {
        b.vz -= g * sdt;
        b.z += b.vz * sdt;
        if (b.z <= 0) {
          b.z = 0;
          if (b.vz.abs() > 90 && b.bounces < 3) {
            b.vz = -b.vz * 0.52;
            b.vx *= 0.78;
            b.vy *= 0.78;
            b.bounces++;
          } else {
            b.vz = 0;
          }
        }
        x += b.vx * sdt;
        y += b.vy * sdt;
        if (b.z == 0 && b.vz == 0) {
          final k = math.max(0.0, 1 - 2.6 * sdt);
          b.vx *= k;
          b.vy *= k;
        }
      }
      return Offset(x, y);
    }

    final bodies = <_Body>[];
    final speeds = <double>[];
    for (final s in seats) {
      final b = _Body(s.seat, radii[bodies.length], s.fixed);
      final startX =
          s.seat.dx + (rnd.nextDouble() - 0.5) * radii[bodies.length] * 2;
      b
        ..x = startX
        ..y = board.height + radii[bodies.length] + 12;
      bodies.add(b);
      if (s.fixed) {
        b
          ..x = s.seat.dx
          ..y = s.seat.dy;
        speeds.add(0);
        continue;
      }
      // Aimed at the seat; the speed is found so that it stops there.
      final to = s.seat - Offset(b.x, b.y);
      final dir = to / math.max(1.0, to.distance);
      var lo = 60.0, hi = 1400.0;
      for (var i = 0; i < 10; i++) {
        final mid = (lo + hi) / 2;
        final end = alone(
            _Body(s.seat, s.radius, false)
              ..x = b.x
              ..y = b.y,
            mid,
            dir);
        final travelled = (end - Offset(b.x, b.y)).distance;
        if (travelled < to.distance) {
          lo = mid;
        } else {
          hi = mid;
        }
      }
      speeds.add((lo + hi) / 2);
      b.vx = dir.dx * speeds.last;
      b.vy = dir.dy * speeds.last;
    }

    // The throw, all dice together.
    final starts = [for (final b in bodies) Offset(b.x, b.y)];
    for (var i = 0; i < bodies.length; i++) {
      final b = bodies[i];
      if (b.fixed) continue;
      b
        ..z = launchZ
        ..vz = vz0;
      b.vx = (seats[i].seat - starts[i]).dx /
          math.max(1.0, (seats[i].seat - starts[i]).distance) *
          speeds[i];
      b.vy = (seats[i].seat - starts[i]).dy /
          math.max(1.0, (seats[i].seat - starts[i]).distance) *
          speeds[i];
    }
    // The throw never rises above the highest seat: the dice stay below what
    // stands along the top of the board.
    final ceiling = seats.map((s) => s.seat.dy).reduce(math.min);
    final n = bodies.length;
    final steps = (diceThrowSeconds / dt).round();
    final posAt = <List<Offset>>[];
    final liftAt = <List<double>>[];
    final bounceTimes = List.generate(n, (_) => <double>[]);
    for (var s = 0; s <= steps; s++) {
      final time = s * dt;
      for (final b in bodies) {
        if (b.fixed) continue;
        b.vz -= g * dt;
        b.z += b.vz * dt;
        if (b.z <= 0) {
          b.z = 0;
          if (b.vz.abs() > 90 && b.bounces < 3) {
            b.vz = -b.vz * 0.52;
            b.vx *= 0.78;
            b.vy *= 0.78;
            b.bounces++;
            bounceTimes[bodies.indexOf(b)].add(time);
          } else {
            b.vz = 0;
          }
        }
        b.x += b.vx * dt;
        b.y += b.vy * dt;
        if (b.z == 0 && b.vz == 0) {
          final k = math.max(0.0, 1 - 2.6 * dt);
          b.vx *= k;
          b.vy *= k;
        }
        final inside = b.y < board.height - b.r;
        if (b.x < b.r) {
          b.x = b.r;
          b.vx = b.vx.abs() * 0.5;
        }
        if (b.x > board.width - b.r) {
          b.x = board.width - b.r;
          b.vx = -b.vx.abs() * 0.5;
        }
        if (b.y < ceiling) {
          b.y = ceiling;
          b.vy = b.vy.abs() * 0.5;
        }
        if (inside && b.y > board.height - b.r) {
          b.y = board.height - b.r;
          b.vy = -b.vy.abs() * 0.5;
        }
      }
      for (var i = 0; i < n; i++) {
        for (var j = i + 1; j < n; j++) {
          _push(bodies[i], bodies[j]);
        }
      }
      for (final b in bodies) {
        final speed = math.sqrt(b.vx * b.vx + b.vy * b.vy);
        if (!b.fixed &&
            b.z == 0 &&
            b.vz == 0 &&
            speed < 6 &&
            b.y < board.height - b.r) {
          b.settled = b.settled < 0 ? time : b.settled;
        }
      }
      if (s.isEven) {
        posAt.add([for (final b in bodies) Offset(b.x, b.y)]);
        liftAt.add([for (final b in bodies) b.z]);
      }
    }
    // Each die ends on its seat: the little that the throw missed is closed
    // over the last third, then any pair that came closer than their sizes
    // is pushed apart (a pair on the ground only).
    final frames = posAt.length;
    final end = posAt.last;
    final pos = <List<Offset>>[];
    for (var f = 0; f < frames; f++) {
      final u = f / (frames - 1);
      final w = Curves.easeInOut.transform(((u - 0.62) / 0.38).clamp(0.0, 1.0));
      final row = <Offset>[
        for (var i = 0; i < n; i++)
          bodies[i].fixed
              ? seats[i].seat
              : posAt[f][i] + (seats[i].seat - end[i]) * w,
      ];
      for (var pass = 0; pass < 3; pass++) {
        for (var i = 0; i < n; i++) {
          for (var j = i + 1; j < n; j++) {
            if (liftAt[f][i] > bodies[i].r * 0.5 ||
                liftAt[f][j] > bodies[j].r * 0.5) {
              continue;
            }
            final d = row[j] - row[i];
            final dist = d.distance;
            final min = bodies[i].r + bodies[j].r;
            if (dist < min && dist > 0.001) {
              final push = d / dist * ((min - dist) / 2);
              if (bodies[i].fixed && !bodies[j].fixed) {
                row[j] += push * 2;
              } else if (bodies[j].fixed && !bodies[i].fixed) {
                row[i] -= push * 2;
              } else if (!bodies[i].fixed) {
                row[i] -= push;
                row[j] += push;
              }
            }
          }
        }
      }
      pos.add(row);
    }
    // The turn: from the throw to the moment each die stops moving; a small
    // extra turn at each bounce (the progress dips and comes back), and
    // exactly 1 at the end, the picked face square to the front.
    final turn = <List<double>>[];
    for (var f = 0; f < frames; f++) {
      final u = f / (frames - 1);
      final time = u * diceThrowSeconds;
      final row = <double>[];
      for (var i = 0; i < n; i++) {
        if (bodies[i].fixed) {
          row.add(1);
          continue;
        }
        final settle = bodies[i].settled < 0
            ? diceThrowSeconds
            : math.max(0.6, bodies[i].settled);
        final s = (time / settle).clamp(0.0, 1.0);
        var dip = 0.0;
        for (final bt in bounceTimes[i]) {
          final x = (time - bt) / 0.16;
          if (x > 0 && x < 1) dip += 0.05 * math.sin(math.pi * x) * (1 - s);
        }
        row.add(u >= 1 ? 1.0 : (s - dip).clamp(0.0, 1.0));
      }
      turn.add(row);
    }
    return DiceThrowPlan._(pos, liftAt, turn, radii, n);
  }

  static void _push(_Body a, _Body b) {
    if (a.z > a.r * 0.8 || b.z > b.r * 0.8) return;
    final dx = b.x - a.x, dy = b.y - a.y;
    final dist = math.sqrt(dx * dx + dy * dy);
    final min = a.r + b.r;
    if (dist >= min || dist < 0.001) return;
    final nx = dx / dist, ny = dy / dist, push = (min - dist) / 2;
    if (!a.fixed) {
      a.x -= nx * (b.fixed ? push * 2 : push);
      a.y -= ny * (b.fixed ? push * 2 : push);
    }
    if (!b.fixed) {
      b.x += nx * (a.fixed ? push * 2 : push);
      b.y += ny * (a.fixed ? push * 2 : push);
    }
    final va = a.vx * nx + a.vy * ny, vb = b.vx * nx + b.vy * ny;
    final dv = (va - vb) * 0.6;
    if (dv > 0) {
      if (!a.fixed) {
        a.vx -= nx * dv;
        a.vy -= ny * dv;
      }
      if (!b.fixed) {
        b.vx += nx * dv;
        b.vy += ny * dv;
      }
    }
    a.settled = -1;
    b.settled = -1;
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
