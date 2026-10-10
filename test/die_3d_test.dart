// The dice as cubes (v1.214, see die_3d.dart): six sides in 3D, three of
// them showing at rest, the far ones culled as it tumbles; a landed face
// lets go a burst fitted to what it does; with reduced motion, none.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/utils/face_style.dart';
import 'package:narrative_data_app/widgets/die_3d.dart';

List<DieCubeFace> _faces() => [
      for (final k in FaceKind.values.take(6))
        DieCubeFace(
            glyph: Icon(k.icon, size: 20, color: k.color), color: k.color)
    ];

Widget _app(Widget child) => MaterialApp(home: Center(child: child));

void main() {
  test('each kind of face has its burst', () {
    final fx = {for (final kind in FaceKind.values) dieFxOf(kind)};
    expect(fx.length, FaceKind.values.length);
    expect(dieFxOf(FaceKind.attack), DieFx.strike);
    expect(dieFxOf(FaceKind.heal), DieFx.bloom);
    expect(dieFxOf(FaceKind.empty), DieFx.fizzle);
  });

  test('at rest the cube shows three sides, front among them', () {
    final model = Matrix4.identity()
      ..rotateX(0.5)
      ..rotateY(0.62);
    final shown = [
      for (var i = 0; i < 6; i++) CubeFacePlacement.of(i, model, 20),
    ].where((p) => p.visible).map((p) => p.slot).toSet();
    expect(shown.length, 3);
    expect(shown, contains(0));
    // Straight on, only the front side.
    expect(
        [
          for (var i = 0; i < 6; i++)
            CubeFacePlacement.of(i, Matrix4.identity(), 20),
        ].where((p) => p.visible).map((p) => p.slot),
        [0]);
  });

  test('the landed face stands nearly square to the viewer at rest', () {
    final model = Matrix4.identity()
      ..rotateX(dieRestTipX)
      ..rotateY(dieRestTurnY);
    final placed = [
      for (var i = 0; i < 6; i++) CubeFacePlacement.of(i, model, 20),
    ];
    // Of the sides that show, the front one is the most lit and faces the
    // viewer most squarely: its normal sits within 20 degrees of the line
    // of sight.
    final shown = placed.where((p) => p.visible).toList();
    expect(shown.map((p) => p.slot), contains(0));
    final front = shown.firstWhere((p) => p.slot == 0);
    expect(front.light,
        greaterThanOrEqualTo(shown.map((p) => p.light).reduce(math.max)));
    expect(math.cos(dieRestTipX) * math.cos(dieRestTurnY),
        greaterThan(math.cos(20 * math.pi / 180)));
  });

  test('a tumble never loses the cube: one to three sides show', () {
    for (var step = 0; step <= 20; step++) {
      final a = step * 0.37;
      final model = Matrix4.identity()
        ..rotateX(a * 0.9)
        ..rotateY(a * 1.3)
        ..rotateZ(a * 0.35);
      final placed = [
        for (var i = 0; i < 6; i++) CubeFacePlacement.of(i, model, 20),
      ];
      final shown = placed.where((p) => p.visible).length;
      expect(shown, inInclusiveRange(1, 3), reason: 'step $step');
      for (final p in placed) {
        expect(p.matrix.storage.every((v) => v.isFinite), isTrue);
        expect(p.light, inInclusiveRange(0.45, 1.0));
      }
    }
  });

  testWidgets('it tumbles, lands and bursts, then the burst goes',
      (tester) async {
    final roll = AnimationController(
        vsync: const TestVSync(), duration: const Duration(milliseconds: 650));
    addTearDown(roll.dispose);
    Widget die({required bool rolling, bool still = false}) => _app(Die3D(
          faces: _faces(),
          accent: Colors.red,
          roll: roll,
          rolling: rolling,
          fx: DieFx.strike,
          big: true,
          still: still,
        ));
    await tester.pumpWidget(die(rolling: true));
    roll.forward(from: 0);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    }
    expect(find.byKey(const ValueKey('die_burst')), findsNothing);
    await tester.pumpWidget(die(rolling: false));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('die_burst')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const ValueKey('die_burst')), findsNothing);
  });

  testWidgets('reduced motion: no burst', (tester) async {
    final roll = AnimationController(
        vsync: const TestVSync(), duration: const Duration(milliseconds: 650));
    addTearDown(roll.dispose);
    Widget die(bool rolling) => _app(Die3D(
          faces: _faces(),
          accent: Colors.red,
          roll: roll,
          rolling: rolling,
          fx: DieFx.bloom,
          still: true,
        ));
    await tester.pumpWidget(die(true));
    await tester.pumpWidget(die(false));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('die_burst')), findsNothing);
  });

  testWidgets('every burst paints at every moment', (tester) async {
    for (final fx in DieFx.values) {
      for (final big in [false, true]) {
        await tester.pumpWidget(_app(
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: DieBurstPainter(fx: fx, t: 0.4, big: big, unit: 40),
            ),
          ),
        ));
        expect(tester.takeException(), isNull, reason: '$fx $big');
      }
    }
  });
}
