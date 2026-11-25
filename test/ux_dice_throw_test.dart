// v2.2 (UX-2): the dice are thrown. The plan is pure; it never touches a face.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/utils/face_style.dart';
import 'package:narrative_data_app/widgets/dice_throw.dart';
import 'package:narrative_data_app/widgets/die_3d.dart';
import 'package:narrative_data_app/widgets/die_skins.dart';

const _board = Size(330, 200);
const _seats = [
  DiceThrowSeat(Offset(70, 90), 30),
  DiceThrowSeat(Offset(165, 120), 34),
  DiceThrowSeat(Offset(260, 85), 38),
];

/// The throw of one die in the way [kind].
DiceThrowPlan _one(DiceThrowKind kind, {int seed = 3}) => DiceThrowPlan.build(
    seats: const [DiceThrowSeat(Offset(165, 120), 30)],
    board: _board,
    seed: seed,
    kinds: [kind]);

/// The largest angle die 0 turns by, about any one axis.
double _mostTurn(DiceThrowPlan p) {
  var most = 0.0;
  for (var u = 0.0; u <= 1.0; u += 0.004) {
    final a = p.angles(0, u)!;
    most = math.max(most, math.max(a.x.abs(), math.max(a.y.abs(), a.z.abs())));
  }
  return most;
}

void main() {
  test('every die ends on its seat, still, turned to the picked face', () {
    for (final reduced in [false, true]) {
      for (var seed = 0; seed < 12; seed++) {
        final p = DiceThrowPlan.build(
            seats: _seats, board: _board, seed: seed, reduced: reduced);
        for (var i = 0; i < _seats.length; i++) {
          expect((p.position(i, 1) - _seats[i].seat).distance, lessThan(0.5));
          expect(p.lift(i, 1), 0);
          expect(p.turn(i, 1), 1);
          final a = p.angles(i, 1);
          if (reduced) {
            expect(a, isNull, reason: 'a reduced throw keeps its own settle');
          } else {
            expect((a!.x, a.y, a.z), (0.0, 0.0, 0.0));
          }
        }
      }
    }
  });

  test('a human pace: between 1.4 and 2 seconds', () {
    expect(diceDropMs, inInclusiveRange(1400, 2000));
    expect(diceDropReducedMs, lessThanOrEqualTo(250));
  });

  test('five ways to throw, and each die can pick its own', () {
    expect(DiceThrowKind.values, hasLength(5));
    // Seeds give every way, and the dice of one throw differ.
    final seen = <DiceThrowKind>{};
    for (var seed = 0; seed < 10; seed++) {
      final p = DiceThrowPlan.build(seats: _seats, board: _board, seed: seed);
      seen.addAll(p.kinds);
      expect(p.kinds.toSet(), hasLength(3), reason: 'seed $seed');
    }
    expect(seen, DiceThrowKind.values.toSet());
  });

  test('the ways start where they say', () {
    final left = _one(DiceThrowKind.fromLeft);
    expect(left.position(0, 0).dx, lessThan(0));
    expect(left.lift(0, 0), lessThan(_board.height * 0.4), reason: 'low');
    final right = _one(DiceThrowKind.fromRight);
    expect(right.position(0, 0).dx, greaterThan(_board.width));
    final drop = _one(DiceThrowKind.dropRoll);
    expect(drop.lift(0, 0), greaterThan(_board.height * 0.5), reason: 'above');
    final diagonal = _one(DiceThrowKind.diagonal);
    expect(diagonal.position(0, 0).dx, lessThan(0));
    expect(diagonal.position(0, 0).dy, greaterThan(_board.height));
  });

  test('the hard throw hits the side edge and comes back', () {
    final p = _one(DiceThrowKind.wallBounce);
    var farthest = 0.0, at = 0.0;
    for (var u = 0.0; u <= 1.0; u += 0.004) {
      final x = p.position(0, u).dx;
      if (x > farthest) {
        farthest = x;
        at = u;
      }
    }
    expect(farthest, greaterThan(_board.width - 40));
    expect(p.position(0, 1).dx, lessThan(farthest - 40), reason: 'back');
    expect(p.position(0, math.min(1.0, at + 0.2)).dx, lessThan(farthest));
    // The contact with the edge is one of the puffs.
    expect(p.contacts[0].any((c) => (c - at).abs() < 0.08), isTrue);
  });

  test('each throw turns over its edges at least one full turn, easing out',
      () {
    for (final kind in DiceThrowKind.values) {
      final p = _one(kind);
      expect(_mostTurn(p), greaterThanOrEqualTo(2 * math.pi),
          reason: kind.name);
      // Fast at first, slow in the last third: the turning eases out.
      double travelled(double from, double to) {
        var sum = 0.0;
        var last = p.angles(0, from)!;
        for (var u = from; u <= to; u += 0.004) {
          final a = p.angles(0, u)!;
          sum += (a.x - last.x).abs() + (a.y - last.y).abs();
          last = a;
        }
        return sum;
      }

      expect(travelled(0.0, 0.33), greaterThan(travelled(0.66, 1.0)),
          reason: kind.name);
    }
  });

  test('it never goes below the floor, bounces lower each time, ends still',
      () {
    for (final kind in DiceThrowKind.values) {
      final p = _one(kind);
      final contact = p.contacts[0];
      expect(contact.length, greaterThanOrEqualTo(3), reason: kind.name);
      for (var u = 0.0; u <= 1.0; u += 0.004) {
        expect(p.lift(0, u), greaterThanOrEqualTo(0));
      }
      for (final c in contact) {
        expect(p.lift(0, c), lessThan(6), reason: '${kind.name} at $c');
      }
      // The peaks between the touches: each lower than the one before (the
      // edge's touch of the hard throw is not a bounce).
      final peaks = <double>[];
      for (var c = 0; c < contact.length - 1; c++) {
        var top = 0.0;
        for (var u = contact[c]; u < contact[c + 1]; u += 0.002) {
          top = math.max(top, p.lift(0, u));
        }
        peaks.add(top);
      }
      for (var k = 1; k < peaks.length; k++) {
        if (peaks[k - 1] < 1) continue;
        expect(peaks[k], lessThanOrEqualTo(peaks[k - 1] + 0.5),
            reason: '${kind.name} bounce $k');
      }
      // The last stretch is a rock on the spot.
      for (var u = 0.95; u <= 1.0; u += 0.005) {
        expect(p.lift(0, u), lessThan(0.5));
        expect(
            (p.position(0, u) - const Offset(165, 120)).distance, lessThan(0.5),
            reason: kind.name);
      }
    }
  });

  test('the dice start a moment apart and land in a scatter', () {
    final p = DiceThrowPlan.build(seats: _seats, board: _board, seed: 5);
    expect(p.contacts[1].first, isNot(p.contacts[0].first));
    // At rest no two dice overlap.
    for (var i = 0; i < _seats.length; i++) {
      for (var j = i + 1; j < _seats.length; j++) {
        final d = (p.position(i, 1) - p.position(j, 1)).distance;
        expect(d, greaterThanOrEqualTo(p.radiusOf(i) + p.radiusOf(j) - 0.5));
      }
    }
  });

  test('reduced motion: a short drop and a settle, no bounce, no dust', () {
    final p = DiceThrowPlan.build(
        seats: _seats, board: _board, seed: 3, reduced: true);
    for (var i = 0; i < _seats.length; i++) {
      expect(p.contacts[i], isEmpty, reason: 'no dust');
      // After it lands, it never lifts again.
      var landed = false;
      for (var u = 0.0; u <= 1.0; u += 0.005) {
        final h = p.lift(i, u);
        if (landed) expect(h, lessThan(0.5), reason: 'die $i at $u');
        if (h < 0.5 && u > 0.3) landed = true;
      }
      expect(landed, isTrue);
    }
  });

  test('the weather is cut away round each die, and only there', () {
    final clip = DiceHoles(
        () => const [Rect.fromLTWH(40, 40, 60, 60)], ValueNotifier<int>(0));
    final path = clip.getClip(const Size(200, 200));
    expect(path.contains(const Offset(70, 70)), isFalse,
        reason: 'over a die nothing falls');
    expect(path.contains(const Offset(150, 150)), isTrue);
    expect(path.contains(const Offset(10, 70)), isTrue);
    // No dice yet: the whole layer.
    final bare = DiceHoles(() => const [], ValueNotifier<int>(0))
        .getClip(const Size(200, 200));
    expect(bare.contains(const Offset(70, 70)), isTrue);
  });

  test('the same seed throws the same, a kept die does not move', () {
    final a = DiceThrowPlan.build(seats: _seats, board: _board, seed: 7);
    final b = DiceThrowPlan.build(seats: _seats, board: _board, seed: 7);
    expect(a.position(1, 0.4), b.position(1, 0.4));
    final kept = DiceThrowPlan.build(seats: [
      _seats[0],
      const DiceThrowSeat(Offset(165, 120), 34, fixed: true),
      _seats[2],
    ], board: _board, seed: 7);
    for (var u = 0.0; u <= 1.0; u += 0.1) {
      expect(kept.position(1, u), const Offset(165, 120));
    }
  });

  testWidgets('a die driven by the throw lands on the face it was given',
      (t) async {
    final plan = DiceThrowPlan.build(seats: _seats, board: _board, seed: 1);
    final c = AnimationController(
        vsync: const TestVSync(), duration: const Duration(seconds: 2));
    addTearDown(c.dispose);
    List<DieCubeFace> faces() => [
          for (var i = 0; i < 6; i++)
            DieCubeFace(
                glyph: Text('f$i', key: ValueKey('glyph_$i')),
                color: FaceKind.values[i % FaceKind.values.length].color)
        ];
    await t.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: AnimatedBuilder(
          animation: c,
          builder: (_, __) => Die3D(
            faces: faces(),
            accent: Colors.orange,
            size: 60,
            skin: dieSkinOf('flame_die'),
            rolling: c.isAnimating,
            roll: c,
            tumbleAt: (u) => plan.angles(0, u),
          ),
        ),
      ),
    ));
    c.forward();
    await t.pump(const Duration(milliseconds: 600));
    await t.pumpAndSettle();
    expect(c.value, 1.0);
    // At rest the picked (first) face stands at the front.
    expect(find.byKey(const ValueKey('glyph_0')), findsOneWidget);
  });
}
