// QA guard (the user's feedback of 12 November: "all dice must be 3D objects,
// some in Tower mode still seem to be a flat animation"; UX-2's v1.952): every
// die the game has is drawn as a real solid, never as the flat polygon
// (PolyDie), at every size, resting or mid-roll, with the cheap-solid flag
// (`dieCheapSolids`, what one slow roll sets) forced on as well.
//
// The dice come from the DATA, not a list in this file: every id of dice.json
// and every die of the Tower's own table (the Tower rolls its own faces of
// some dice), each with the shape its face count gives (`dieShapeOf`). A die
// is a solid when it is the cube (d6: the faces' `DieFaceTile`s) or a
// `PolyDie3D` (d4, d8, d10, d12, d20); anything with a `PolyDie` is flat.
//
// It draws the three places a die is drawn: `Die3D` (the fight's party row,
// the Tower's roll), `DieTile` (the Tower's "Your dice", the loadout's list,
// the inventory's rows) and `RollingDie` (the loadout's ring). UX-2's own
// tests (ux_die_solids_test, ux_die_tile_test, ux_die_same_look_test) check
// the solids' geometry and look on chosen dice; this one walks every id.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/utils/face_style.dart';
import 'package:narrative_data_app/widgets/die_3d.dart';
import 'package:narrative_data_app/widgets/die_poly3d.dart';
import 'package:narrative_data_app/widgets/die_skins.dart';
import 'package:narrative_data_app/widgets/die_tile.dart';
import 'package:narrative_data_app/widgets/poly_die.dart';
import 'package:narrative_data_app/widgets/rolling_die.dart';

/// The sizes a die is drawn at: the rail's and the loadout ring's small tiles,
/// the Tower's tiles (48), the fight's party row (46), the big ones.
const _sizes = [16.0, 24.0, 32.0, 40.0, 46.0, 48.0, 56.0, 96.0];

List<DieCubeFace> _faces(int n) => [
      for (var i = 0; i < n; i++)
        DieCubeFace(
            glyph: Text('f$i'),
            color: FaceKind.values[i % FaceKind.values.length].color)
    ];

Widget _host(Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: Center(child: child),
      ),
    );

/// Every die id the game can put in a hand, with its face count: dice.json's,
/// and the Tower's own table's (the same ids, as the Tower rolls them).
Map<String, int> _allDice() {
  final fromJson =
      jsonDecode(File('assets/gamedata/dice.json').readAsStringSync())
          as Map<String, dynamic>;
  final dice = <String, int>{
    for (final e in fromJson.entries)
      'dice.json:${e.key}': ((e.value as Map)['faces'] as List).length,
  };
  for (final e in towerDataFromAssets().dice.entries) {
    dice['tower:${e.key}'] = ((e.value as Map)['faces'] as List).length;
  }
  return dice;
}

void main() {
  final dice = _allDice();

  setUp(dieResetQuality);
  tearDown(dieResetQuality);

  /// What is on screen says "solid": the cube's faces or a PolyDie3D, and no
  /// flat PolyDie. [what] names the die and the drawing for the failure.
  void expectSolid(WidgetTester tester, String what, DieShape shape) {
    expect(find.byType(PolyDie), findsNothing,
        reason: '$what draws a flat PolyDie');
    if (shape == DieShape.d6) {
      expect(find.byType(DieFaceTile), findsWidgets,
          reason: '$what (a d6) draws no cube');
      expect(find.byType(PolyDie3D), findsNothing,
          reason: '$what (a d6) draws a polyhedron instead of the cube');
    } else {
      expect(find.byType(PolyDie3D), findsOneWidget,
          reason: '$what ($shape) draws no solid');
    }
  }

  test('the game has dice to check (dice.json and the Tower)', () {
    expect(dice.length, greaterThan(30));
    expect(dice.keys.where((k) => k.startsWith('tower:')), isNotEmpty);
  });

  for (final cheap in [false, true]) {
    testWidgets(
        'every die is a solid in Die3D, at every size, resting and mid-roll'
        '${cheap ? ', the cheap-solid flag on' : ''}', (tester) async {
      dieCheapSolids = cheap;
      final controller = AnimationController(
          vsync: tester, duration: const Duration(milliseconds: 800))
        ..value = 0.4;
      addTearDown(controller.dispose);
      for (final e in dice.entries) {
        final id = e.key.split(':').last;
        final shape = dieShapeOf(e.value);
        for (final size in _sizes) {
          for (final rolling in [false, true]) {
            await tester.pumpWidget(_host(Die3D(
              faces: _faces(6),
              facets: shape == DieShape.d6 ? null : _faces(e.value),
              accent: Colors.orange,
              size: size,
              shape: shape,
              roll: rolling ? controller : null,
              rolling: rolling,
              skin: dieSkinOf(id),
              artId: id,
            )));
            await tester.pump(const Duration(milliseconds: 50));
            expectSolid(
                tester,
                '${e.key} at $size px ${rolling ? 'rolling' : 'resting'}',
                shape);
          }
        }
      }
    });
  }

  for (final cheap in [false, true]) {
    testWidgets(
        'every die is a solid as a tile and in the loadout ring'
        '${cheap ? ', the cheap-solid flag on' : ''}', (tester) async {
      dieCheapSolids = cheap;
      for (final e in dice.entries) {
        final id = e.key.split(':').last;
        final shape = dieShapeOf(e.value);
        for (final size in _sizes) {
          await tester.pumpWidget(
              _host(DieTile(dieId: id, faces: e.value, size: size)));
          await tester.pump(const Duration(milliseconds: 50));
          expectSolid(tester, '${e.key} as a DieTile at $size px', shape);
        }
        for (final size in [32.0, 56.0, 96.0]) {
          await tester.pumpWidget(_host(RollingDie(
              faceCount: e.value,
              face: 0,
              size: size,
              dieId: id,
              skin: dieSkinOf(id))));
          await tester.pump(const Duration(milliseconds: 50));
          expectSolid(
              tester, '${e.key} in the loadout ring at $size px', shape);
        }
      }
    });
  }
}
