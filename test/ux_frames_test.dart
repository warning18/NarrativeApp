// The Tower's frames (frame_style.dart, tower_look.dart): the material goes up
// with the climb (wood, iron, silver, gilt after a win), the frame's pieces
// are all in the bundle, and the Tower's theme carries the style once they are
// loaded (until then it wears the plain bevel).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/screens/tower/tower_look.dart';
import 'package:narrative_data_app/theme/frame_style.dart';
import 'package:narrative_data_app/widgets/ink_panel.dart';

void main() {
  test('the material goes up with the floors, gilt once a run is won', () {
    FrameMaterial of(int f, {bool won = false}) =>
        towerMaterialOf(floor: f, climbed: won);
    expect([1, 10].map(of), everyElement(FrameMaterial.wood));
    expect([11, 20].map(of), everyElement(FrameMaterial.iron));
    expect([21, 30].map(of), everyElement(FrameMaterial.silver));
    expect([1, 15, 30].map((f) => of(f, won: true)),
        everyElement(FrameMaterial.gilt));
  });

  test('every material has every piece, the decoration sets their sprites', () {
    for (final m in FrameMaterial.values) {
      for (final p in FramePiece.values) {
        expect(File('assets/ui/frames/${m.name}/${p.file}.png').existsSync(),
            isTrue,
            reason: '${m.name}/${p.file}');
      }
    }
    for (final e in EnvDecor.values.where((e) => e != EnvDecor.none)) {
      for (final part in ['top', 'bottom', 'corner']) {
        for (var i = 0; i < 3; i++) {
          expect(
              File('assets/ui/frames/env/${e.file}_${part}_$i.png')
                  .existsSync(),
              isTrue,
              reason: '${e.file}_${part}_$i');
        }
      }
    }
  });

  testWidgets('the Tower carries the frame style once the pieces are loaded',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    FrameImages.reset();
    FrameStyle? seen;
    Widget app() => ProviderScope(
          child: MaterialApp(
            home: TowerNight(
              floor: 14,
              child: Builder(builder: (context) {
                seen = Theme.of(context).extension<FrameStyle>();
                return const InkPanel(child: Text('floor 14'));
              }),
            ),
          ),
        );
    await tester.pumpWidget(app());
    expect(seen, isNull, reason: 'not loaded: the plain bevel');
    await tester.runAsync(() async {
      await FrameImages.preload(FrameMaterial.iron, EnvDecor.towerStone);
    });
    await tester.pump();
    expect(seen?.material, FrameMaterial.iron);
  });
}
