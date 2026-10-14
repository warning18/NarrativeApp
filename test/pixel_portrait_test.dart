// An enemy's portrait in pixel art (v1.221, see widgets/pixel_portrait.dart):
// it flashes when a blow lands, lunges when its enemy strikes, dissolves
// when it is beaten, and holds still with animations off.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/widgets/combat_vfx.dart';
import 'package:narrative_data_app/widgets/pixel_portrait.dart';

Future<void> _load(WidgetTester tester, String id) async {
  await tester.runAsync(() async {
    PortraitPixels.of(id);
    for (var i = 0; i < 100 && PortraitPixels.of(id) == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  });
  await tester.pump();
}

Widget _app(CombatVfxController controller, GlobalKey anchor,
        {bool alive = true, bool animate = true, bool boss = false}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: KeyedSubtree(
            key: anchor,
            child: PixelEnemyPortrait(
              enemyId: 'slum_thug',
              alive: alive,
              controller: controller,
              anchor: anchor,
              animate: animate,
              boss: boss,
            ),
          ),
        ),
      ),
    );

bool _has(String key) => find.byKey(ValueKey(key)).evaluate().isNotEmpty;

void main() {
  testWidgets('the sprite is read to 32 by 32 pixels', (tester) async {
    await _load(tester, 'slum_thug');
    final px = PortraitPixels.of('slum_thug')!;
    expect(px.length, 32 * 32 * 4);
    var opaque = 0;
    for (var i = 3; i < px.length; i += 4) {
      if (px[i] > 0) opaque++;
    }
    expect(opaque, inInclusiveRange(150, 900));
  });

  testWidgets('a blow flashes it, a strike lunges it, then it rests',
      (tester) async {
    await _load(tester, 'slum_thug');
    final controller = CombatVfxController();
    final anchor = GlobalKey();
    await tester.pumpWidget(_app(controller, anchor));
    expect(_has('portrait_still'), isTrue);

    controller.cue(anchor, PortraitCue.hit);
    await tester.pump();
    expect(_has('portrait_hit'), isTrue);
    await tester.pump(const Duration(milliseconds: 600));
    expect(_has('portrait_still'), isTrue);

    // A strike waits for its delay.
    controller.cue(anchor, PortraitCue.lunge,
        delayMs: 200, dir: const Offset(-1, 0.4));
    await tester.pump();
    expect(_has('portrait_still'), isTrue);
    await tester.pump(const Duration(milliseconds: 250));
    expect(_has('portrait_lunge'), isTrue);
    await tester.pump(const Duration(milliseconds: 800));
    expect(_has('portrait_still'), isTrue);

    // A cue for another card does nothing.
    controller.cue(GlobalKey(), PortraitCue.hit);
    await tester.pump();
    expect(_has('portrait_still'), isTrue);
  });

  testWidgets('beaten, it waits for the last blow, dissolves and is gone',
      (tester) async {
    await _load(tester, 'slum_thug');
    final controller = CombatVfxController();
    final anchor = GlobalKey();
    await tester.pumpWidget(_app(controller, anchor));
    await tester.pumpWidget(_app(controller, anchor, alive: false));
    expect(_has('portrait_still'), isTrue);

    // The killing blow lands: the fall follows it.
    controller.cue(anchor, PortraitCue.hit);
    await tester.pump();
    expect(_has('portrait_hit'), isTrue);
    await tester.pump(const Duration(milliseconds: 200));
    expect(_has('portrait_death'), isTrue);
    await tester.pump(const Duration(milliseconds: 1300));
    expect(_has('portrait_gone'), isTrue);
  });

  testWidgets('beaten with no blow reported, it still falls', (tester) async {
    await _load(tester, 'slum_thug');
    final controller = CombatVfxController();
    final anchor = GlobalKey();
    await tester.pumpWidget(_app(controller, anchor));
    await tester.pumpWidget(_app(controller, anchor, alive: false));
    await tester.pump(const Duration(milliseconds: 950));
    expect(_has('portrait_death'), isTrue);
    await tester.pump(const Duration(milliseconds: 1200));
    expect(_has('portrait_gone'), isTrue);
  });

  testWidgets('a boss falls more slowly', (tester) async {
    expect(portraitCueMs(PortraitCue.death, boss: true),
        greaterThan(portraitCueMs(PortraitCue.death)));
  });

  testWidgets('with animations off it is the still sprite, always',
      (tester) async {
    await _load(tester, 'slum_thug');
    final controller = CombatVfxController();
    final anchor = GlobalKey();
    await tester.pumpWidget(_app(controller, anchor, animate: false));
    controller.cue(anchor, PortraitCue.hit);
    await tester.pump(const Duration(milliseconds: 50));
    expect(_has('portrait_still'), isTrue);
    await tester
        .pumpWidget(_app(controller, anchor, alive: false, animate: false));
    await tester.pump(const Duration(seconds: 3));
    expect(_has('portrait_still'), isTrue);
    expect(_has('portrait_gone'), isFalse);
  });
}
