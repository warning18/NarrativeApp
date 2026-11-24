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

double _gap(DiceThrowPlan p, int i, int j, double u) =>
    (p.position(i, u) - p.position(j, u)).distance -
    (_seats[i].radius + _seats[j].radius);

void main() {
  test('every die ends on its seat, turned to the picked face', () {
    for (var seed = 0; seed < 20; seed++) {
      final p = DiceThrowPlan.build(seats: _seats, board: _board, seed: seed);
      for (var i = 0; i < _seats.length; i++) {
        expect((p.position(i, 1) - _seats[i].seat).distance, lessThan(0.01));
        expect(p.turn(i, 1), 1.0);
        expect(p.lift(i, 1), 0.0);
        // It starts below the board and out of sight.
        expect(p.position(i, 0).dy, greaterThan(_board.height));
        expect(p.turn(i, 0), lessThan(0.05));
      }
    }
  });

  test('no two dice overlap at rest, and none on the ground during the throw',
      () {
    for (var seed = 0; seed < 20; seed++) {
      final p = DiceThrowPlan.build(seats: _seats, board: _board, seed: seed);
      for (var i = 0; i < 3; i++) {
        for (var j = i + 1; j < 3; j++) {
          expect(_gap(p, i, j, 1), greaterThanOrEqualTo(0));
          for (var u = 0.0; u <= 1.0; u += 0.01) {
            if (p.lift(i, u) > 14 || p.lift(j, u) > 14) continue;
            // Both on the ground or low: they never sink into each other.
            final onBoard = p.position(i, u).dy < _board.height - 20 &&
                p.position(j, u).dy < _board.height - 20;
            if (onBoard) {
              expect(_gap(p, i, j, u), greaterThan(-1.5),
                  reason: 'seed $seed dice $i $j at $u');
            }
          }
        }
      }
    }
  });

  test('it bounces 2 to 3 times and the arc stays low', () {
    final p = DiceThrowPlan.build(seats: _seats, board: _board, seed: 3);
    for (var i = 0; i < 3; i++) {
      var peak = 0.0, touches = 0;
      var wasUp = false;
      for (var u = 0.0; u <= 1.0; u += 0.002) {
        final z = p.lift(i, u);
        peak = math.max(peak, z);
        final up = z > 2;
        if (wasUp && !up) touches++;
        wasUp = up;
      }
      expect(peak, lessThanOrEqualTo(diceThrowMaxLift + 1));
      expect(touches, inInclusiveRange(2, 4), reason: 'die $i');
    }
  });

  test('the throw never rises above the highest seat', () {
    final top = _seats.map((s) => s.seat.dy).reduce(math.min);
    for (var seed = 0; seed < 20; seed++) {
      final p = DiceThrowPlan.build(seats: _seats, board: _board, seed: seed);
      for (var i = 0; i < 3; i++) {
        for (var u = 0.0; u <= 1.0; u += 0.01) {
          expect(p.position(i, u).dy, greaterThanOrEqualTo(top - 1.5),
              reason: 'seed $seed die $i at $u');
        }
      }
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
