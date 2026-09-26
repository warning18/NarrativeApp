// The Edit Mode effects gallery (v1.157), reached from the fight lab:
// picks a style, an element and a power, and plays one tier or all four
// in turn on its stage.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/skill_vfx.dart';
import 'package:narrative_data_app/screens/fight_lab_screen.dart';
import 'package:narrative_data_app/screens/vfx_gallery_screen.dart';

void main() {
  testWidgets('the fight lab opens the gallery, which plays every tier',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: FightLabScreen())));
    await tester.pump();
    await tester.tap(find.byKey(const Key('fight_lab_effects')));
    await tester.pumpAndSettle();
    expect(find.byType(VfxGalleryScreen), findsOneWidget);
    expect(find.text('Effects gallery'), findsOneWidget);
    final tiers = find.byType(SegmentedButton<VfxTier>);
    for (final label in ['Light', 'Normal', 'Strong', 'Mighty']) {
      expect(find.descendant(of: tiers, matching: find.text(label)),
          findsOneWidget);
    }

    // A style plays as soon as it is picked; then at mighty; then all four.
    await tester.tap(find.byKey(const Key('vfx_gallery_style_fireball')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.descendant(of: tiers, matching: find.text('Mighty')));
    await tester.pump();
    expect(find.textContaining('${vfxPowerOfTier(VfxTier.mighty)}'),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('vfx_gallery_play')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('-34'), findsNothing,
        reason: 'numbers are painted, not widgets');
    await tester.tap(find.byKey(const Key('vfx_gallery_play_all')));
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(tester.takeException(), isNull);
    // Everything has played out: the stage stops asking for frames.
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
