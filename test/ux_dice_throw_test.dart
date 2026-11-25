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

void main() {
  test('every die ends on its seat, turned to the picked face', () {
    for (final reduced in [false, true]) {
      for (var seed = 0; seed < 12; seed++) {
        final p = DiceThrowPlan.build(
            seats: _seats, board: _board, seed: seed, reduced: reduced);
        for (var i = 0; i < _seats.length; i++) {
          expect((p.position(i, 1) - _seats[i].seat).distance, lessThan(0.5));
          expect(p.lift(i, 1), 0);
          expect(p.turn(i, 1), 1);
        }
      }
    }
  });

  test('it falls from above, never below the floor, and ends still', () {
    final p = DiceThrowPlan.build(seats: _seats, board: _board, seed: 3);
    for (var i = 0; i < _seats.length; i++) {
      // The first die is high at the start; the last ones start a moment later.
      expect(p.lift(i, 0), greaterThan(_board.height * 0.5), reason: 'die $i');
      var rest = 0;
      for (var u = 0.0; u <= 1.0; u += 0.005) {
        expect(p.lift(i, u), greaterThanOrEqualTo(0));
        if (u > 0.9) rest++;
        if (u > 0.9) expect(p.lift(i, u), lessThan(0.5));
      }
      expect(rest, greaterThan(10));
    }
  });

  test('it touches the floor, bounces once or twice, lower each time', () {
    final p = DiceThrowPlan.build(seats: _seats, board: _board, seed: 3);
    for (var i = 0; i < _seats.length; i++) {
      final contact = p.contacts[i];
      expect(contact.length, greaterThanOrEqualTo(2));
      // The peaks between the contacts: each lower than the one before.
      final peaks = <double>[];
      for (var c = 0; c < contact.length - 1; c++) {
        var top = 0.0;
        for (var u = contact[c]; u < contact[c + 1]; u += 0.002) {
          top = math.max(top, p.lift(i, u));
        }
        peaks.add(top);
      }
      expect(peaks.first, inInclusiveRange(10, 60), reason: 'die $i');
      for (var k = 1; k < peaks.length; k++) {
        expect(peaks[k], lessThan(peaks[k - 1]));
      }
      // The contact is on the floor.
      for (final c in contact) {
        expect(p.lift(i, c), lessThan(6));
      }
    }
  });

  test('the dice start a moment apart and land in a scatter', () {
    final p = DiceThrowPlan.build(seats: _seats, board: _board, seed: 5);
    expect(p.contacts[1].first, greaterThan(p.contacts[0].first));
    expect(p.contacts[2].first, greaterThan(p.contacts[1].first));
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
    expect(diceDropReducedMs, lessThanOrEqualTo(250));
    expect(diceDropMs, lessThan(900));
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
            roll: c.drive(CurveTween(curve: plan.turnCurve(0))),
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
