// Each die wears a cube skin of its own (v1.216, see die_skins.dart), the
// patterns paint, and a die carries its rule words, element, surge, curse
// and hold ring through the cube.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/face_keywords.dart';
import 'package:narrative_data_app/utils/face_style.dart';
import 'package:narrative_data_app/widgets/die_3d.dart';
import 'package:narrative_data_app/widgets/die_skins.dart';

List<DieCubeFace> _faces() => [
      for (final k in FaceKind.values.take(6))
        DieCubeFace(
            glyph: Icon(k.icon, size: 20, color: k.color), color: k.color)
    ];

void main() {
  test('every die in dice.json has a skin of its own', () {
    final dice =
        jsonDecode(File('assets/gamedata/dice.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final id in dice.keys) {
      expect(dieSkins.containsKey(id), isTrue, reason: id);
    }
    expect(dieSkins.length, dice.length);
    // A die without a skin reads as bone.
    expect(dieSkinOf('no_such_die'), same(boneSkin));
    expect(dieSkinOf(null), same(boneSkin));
    // Light-giving dice: the glowing ones are meant to glow.
    expect(dieSkinOf('flame_die').glow, isNotNull);
    expect(dieSkinOf('iron_die').glow, isNull);
  });

  testWidgets('every pattern paints', (tester) async {
    for (final pattern in DiePattern.values) {
      await tester.pumpWidget(MaterialApp(
        home: SizedBox(
          width: 80,
          height: 80,
          child:
              CustomPaint(painter: DiePatternPainter(pattern, Colors.white, 3)),
        ),
      ));
      expect(tester.takeException(), isNull, reason: '$pattern');
    }
  });

  testWidgets('a skinned die shows its hold ring, and each layer bursts',
      (tester) async {
    final roll = AnimationController(
        vsync: const TestVSync(), duration: const Duration(milliseconds: 650));
    addTearDown(roll.dispose);
    Widget die(
            {required bool rolling,
            bool held = false,
            Set<FaceKeyword> kw = const {},
            String element = 'None',
            bool surge = false,
            bool cursed = false,
            DieFx fx = DieFx.strike}) =>
        MaterialApp(
          home: Center(
            child: Die3D(
              faces: _faces(),
              accent: Colors.red,
              roll: roll,
              rolling: rolling,
              fx: fx,
              skin: dieSkinOf('flame_die'),
              held: held,
              keywords: kw,
              element: element,
              surge: surge,
              cursed: cursed,
            ),
          ),
        );
    await tester.pumpWidget(die(rolling: false, held: true));
    expect(find.byKey(const ValueKey('die_held')), findsOneWidget);
    await tester.pumpWidget(die(rolling: false));
    expect(find.byKey(const ValueKey('die_held')), findsNothing);

    for (final fx in [DieFx.strike, DieFx.fizzle]) {
      await tester.pumpWidget(die(rolling: true, fx: fx));
      roll.forward(from: 0);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpWidget(die(
        rolling: false,
        fx: fx,
        kw: FaceKeyword.values.toSet(),
        element: 'Fire',
        surge: true,
        cursed: true,
      ));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 110));
        expect(tester.takeException(), isNull, reason: '$fx step $i');
      }
    }
  });

  testWidgets('every element and rule word paints in a burst', (tester) async {
    for (final element in [
      'None',
      'Fire',
      'Water',
      'Wind',
      'Earth',
      'Electricity',
      'Ice',
      'Void',
      'Light'
    ]) {
      for (final keyword in FaceKeyword.values) {
        await tester.pumpWidget(MaterialApp(
          home: SizedBox(
            width: 140,
            height: 140,
            child: CustomPaint(
              painter: DieBurstPainter(
                fx: DieFx.bloom,
                t: 0.4,
                big: false,
                unit: 40,
                keywords: {keyword},
                element: element,
              ),
            ),
          ),
        ));
        expect(tester.takeException(), isNull, reason: '$element $keyword');
      }
    }
  });
}
