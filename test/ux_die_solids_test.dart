// The dice that are not cubes as real solids (v1.903, die_solids.dart and
// die_poly3d.dart): the right corners and facets, flat facets, a facet for
// each face, glyphs only on facets that face the viewer, and the flat
// drawing kept for small tiles, reduced motion and "flat".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/utils/face_style.dart';
import 'package:narrative_data_app/widgets/die_3d.dart';
import 'package:narrative_data_app/widgets/die_poly3d.dart';
import 'package:narrative_data_app/widgets/die_skins.dart';
import 'package:narrative_data_app/widgets/die_solids.dart';
import 'package:narrative_data_app/widgets/poly_die.dart';

List<DieCubeFace> _faces(int n) => [
      for (var i = 0; i < n; i++)
        DieCubeFace(
            glyph: Text('f$i', key: ValueKey('glyph_$i')),
            color: FaceKind.values[i % FaceKind.values.length].color)
    ];

Widget _die(DieShape shape, int n,
        {double size = 60, bool flat = false, bool dim = false}) =>
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Die3D(
          faces: _faces(6),
          facets: _faces(n),
          accent: Colors.orange,
          size: size,
          shape: shape,
          flat: flat,
          dim: dim,
          skin: dieSkinOf('flame_die'),
        ),
      ),
    );

void main() {
  test('each solid has its corners and as many facets as the die has faces',
      () {
    const counts = {
      DieShape.d4: (4, 4),
      DieShape.d8: (6, 8),
      DieShape.d10: (12, 10),
      DieShape.d12: (20, 12),
      DieShape.d20: (12, 20),
    };
    counts.forEach((shape, c) {
      final s = dieSolidOf(shape)!;
      expect((s.verts.length, s.faces.length), c, reason: '$shape');
      // Every facet is flat and its normal points out of the solid.
      for (var i = 0; i < s.faces.length; i++) {
        final f = s.faces[i];
        final c0 = s.centre(i);
        final n = vnorm(vcross(vsub(s.verts[f[1]], s.verts[f[0]]),
            vsub(s.verts[f[2]], s.verts[f[0]])));
        for (final v in f) {
          expect(vdot(vsub(s.verts[v], c0), n).abs(), lessThan(1e-6),
              reason: '$shape facet $i is flat');
        }
        expect(vdot(n, c0).abs(), greaterThan(0.1), reason: '$shape $i');
      }
    });
    expect(dieSolidOf(DieShape.d6), isNull);
    expect(dieSolidOf(DieShape.coin), isNull);
  });

  testWidgets('a d20 at rest is a solid: about half its facets show',
      (tester) async {
    await tester.pumpWidget(_die(DieShape.d20, 20));
    expect(find.byType(PolyDie3D), findsOneWidget);
    expect(find.byType(PolyDie), findsNothing);
    // The landed facet (face 0) is square to the viewer and carries its glyph.
    expect(find.byKey(const ValueKey('glyph_0')), findsOneWidget);
    final glyphs = find.byWidgetPredicate(
        (w) => w.key is ValueKey && '${w.key}'.contains('glyph_'));
    expect(glyphs, findsAtLeast(1));
    // Never a glyph on a facet more than 65 degrees off, so at most the
    // front half of the die.
    expect(tester.widgetList(glyphs).length, lessThan(14));
  });

  testWidgets('a d8 draws every kind of face it is given', (tester) async {
    await tester.pumpWidget(_die(DieShape.d8, 8));
    expect(find.byType(PolyDie3D), findsOneWidget);
    expect(find.byKey(const ValueKey('glyph_0')), findsOneWidget);
  });

  testWidgets('small tiles, "flat" and the d6 keep their own drawing',
      (tester) async {
    await tester.pumpWidget(_die(DieShape.d20, 20, size: 26));
    expect(find.byType(PolyDie3D), findsNothing);
    expect(find.byType(PolyDie), findsOneWidget);
    await tester.pumpWidget(_die(DieShape.d8, 8, flat: true));
    expect(find.byType(PolyDie3D), findsNothing);
    await tester.pumpWidget(_die(DieShape.d6, 6));
    expect(find.byType(PolyDie3D), findsNothing);
    await tester.pumpWidget(_die(DieShape.coin, 2));
    expect(find.byType(PolyDie3D), findsNothing);
  });

  testWidgets('a die not rolled yet shows a ? and no face; a rolled one none',
      (tester) async {
    for (final (shape, n) in [
      (DieShape.d20, 20),
      (DieShape.d8, 8),
      (DieShape.d6, 6)
    ]) {
      await tester.pumpWidget(_die(shape, n, dim: true));
      expect(find.byKey(const ValueKey('die_unrolled_mark')), findsOneWidget,
          reason: '$shape');
      expect(find.byKey(const ValueKey('glyph_0')), findsNothing);
      await tester.pumpWidget(_die(shape, n));
      expect(find.byKey(const ValueKey('die_unrolled_mark')), findsNothing,
          reason: '$shape');
    }
  });

  testWidgets('a tumbling solid draws without error', (tester) async {
    for (final t in [0.0, 0.2, 0.5, 0.8]) {
      for (final (shape, n) in [
        (DieShape.d4, 4),
        (DieShape.d10, 10),
        (DieShape.d12, 12),
        (DieShape.d20, 20),
      ]) {
        await tester.pumpWidget(Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
                child: PolyDie3D(
                    shape: shape,
                    faces: _faces(n),
                    skin: dieSkinOf('flame_die'),
                    size: 60,
                    t: t))));
        expect(tester.takeException(), isNull, reason: '$shape t=$t');
      }
    }
  });
}
