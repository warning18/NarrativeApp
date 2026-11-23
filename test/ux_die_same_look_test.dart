// A die looks the same rolling and at rest (v1.907), and every die is a real
// solid on every phone (v1.952): a slow roll never turns the solid on the
// board into another drawing; it only makes the dice mounted after it
// cheaper (no glyph plaques on the facets, a shorter tumble), still solids.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/utils/face_style.dart';
import 'package:narrative_data_app/widgets/die_3d.dart';
import 'package:narrative_data_app/widgets/die_poly3d.dart';
import 'package:narrative_data_app/widgets/die_skins.dart';
import 'package:narrative_data_app/widgets/poly_die.dart';

List<DieCubeFace> _faces(int n) => [
      for (var i = 0; i < n; i++)
        DieCubeFace(glyph: Text('f$i'), color: FaceKind.values[i % 6].color)
    ];

Widget _die({required bool rolling}) => Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: Die3D(
          faces: _faces(6),
          facets: _faces(10),
          accent: Colors.orange,
          size: 70,
          shape: DieShape.d10,
          rolling: rolling,
          skin: dieSkinOf('flame_die'),
        ),
      ),
    );

void main() {
  setUp(dieResetQuality);
  tearDown(dieResetQuality);

  testWidgets('a slow roll never changes the die on screen', (tester) async {
    await tester.pumpWidget(_die(rolling: true));
    expect(find.byType(PolyDie3D), findsOneWidget);
    for (var i = 0; i < 40; i++) {
      dieJudgeFrame(const Duration(milliseconds: 80));
    }
    expect(dieCheapSolids, isTrue);
    await tester.pumpWidget(_die(rolling: false));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PolyDie3D), findsOneWidget);
    expect(find.byType(PolyDie), findsNothing);
  });

  testWidgets('the dice mounted after a slow roll are still solids, cheaper',
      (tester) async {
    await tester.pumpWidget(_die(rolling: false));
    final glyphs = find
        .byWidgetPredicate((w) => w is Text && (w.data ?? '').startsWith('f'));
    expect(glyphs, findsAtLeast(1), reason: 'a fast phone: plaques');
    for (var i = 0; i < 12; i++) {
      dieJudgeFrame(const Duration(milliseconds: 50));
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(_die(rolling: false));
    expect(find.byType(PolyDie3D), findsOneWidget);
    expect(find.byType(PolyDie), findsNothing, reason: 'never a flat die');
    expect(glyphs, findsNothing, reason: 'no plaques on a slow phone');
  });

  test(
      'a few slow frames, or slow ones with fast between, do not make the solids cheaper',
      () {
    for (var i = 0; i < 40; i++) {
      dieJudgeFrame(Duration(milliseconds: i.isEven ? 60 : 8));
    }
    for (var i = 0; i < 11; i++) {
      dieJudgeFrame(const Duration(milliseconds: 60));
    }
    expect(dieCheapSolids, isFalse);
  });
}
