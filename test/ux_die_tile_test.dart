// The still die tile (v1.952, widgets/die_tile.dart): every die is a real
// solid at rest (the cube for a d6) with its own mark on the front facet, in
// the Tower's "Your dice", the loadout's rail and the inventory's d10; never
// the flat polygon.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/die_3d.dart';
import 'package:narrative_data_app/widgets/die_poly3d.dart';
import 'package:narrative_data_app/widgets/die_tile.dart';
import 'package:narrative_data_app/widgets/poly_die.dart';

void main() {
  final dice = jsonDecode(File('assets/gamedata/dice.json').readAsStringSync())
      as Map<String, dynamic>;

  testWidgets('every die of the game is a solid tile, never a flat one',
      (tester) async {
    for (final e in dice.entries) {
      final faces = e.value['numberOfFaces'] as int;
      await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: DieTile(dieId: e.key, faces: faces, size: 48))));
      expect(find.byType(Die3D), findsOneWidget, reason: e.key);
      expect(find.byType(PolyDie), findsNothing, reason: e.key);
      expect(find.byType(PolyDie3D), faces == 6 ? findsNothing : findsOneWidget,
          reason: '${e.key} d$faces');
      expect(tester.takeException(), isNull, reason: e.key);
    }
  });

  testWidgets('the tile fits its square and carries the die\'s mark',
      (tester) async {
    await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
            child: DieTile(dieId: 'tearglass_die', faces: 12, size: 48))));
    expect(tester.getSize(find.byKey(const Key('die_tile_tearglass_die'))),
        const Size(48, 48));
    // The mark is a painter on the front facet's glyph.
    expect(
        find.descendant(
            of: find.byType(PolyDie3D), matching: find.byType(CustomPaint)),
        findsWidgets);
    // A small tile is a plain solid (no room for a mark), still not flat.
    await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: DieTile(dieId: 'flame_die', faces: 8, size: 26))));
    expect(find.byType(PolyDie3D), findsOneWidget);
    expect(find.byType(PolyDie), findsNothing);
  });

  test('the d4 and the d10 rest turned, so two faces show and the d10 stands',
      () {
    final d4 = dieRestPoseOf(DieShape.d4);
    final d8 = dieRestPoseOf(DieShape.d8);
    expect(d4.tip, greaterThan(d8.tip));
    expect(d4.turn, greaterThan(d8.turn));
    expect(dieRestPoseOf(DieShape.d10).roll, isNot(0));
    expect(d8.roll, 0);
    expect(dieRestPoseOf(DieShape.d12).roll, 0);
  });
}
