// A cue to the hero moves its sprite (v1.451): a lunge with its blow, a flinch
// when hit, and nothing with animations off.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/combat_vfx.dart';
import 'package:narrative_data_app/widgets/fight_hero_sprite.dart';
import 'package:narrative_data_app/widgets/pixel_portrait.dart'
    show PortraitCue;

void main() {
  testWidgets('a cue to the hero moves the sprite: a lunge, then home',
      (tester) async {
    final controller = CombatVfxController();
    final anchor = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: FightHeroSprite(
              controller: controller,
              anchor: anchor,
              alive: true,
              animate: true),
        ),
      ),
    ));
    CustomPaint paint() =>
        tester.widget<CustomPaint>(find.byKey(const Key('fight_hero_sprite')));
    dynamic painter() => paint().painter;
    expect(painter().cue, isNull);
    controller.cue(anchor, PortraitCue.lunge);
    await tester.pump(const Duration(milliseconds: 100));
    expect(painter().cue, PortraitCue.lunge);
    await tester.pump(const Duration(milliseconds: 900));
    expect(painter().cue, isNull);
    // A cue for another card is none of its business.
    controller.cue(GlobalKey(), PortraitCue.hit);
    await tester.pump(const Duration(milliseconds: 100));
    expect(painter().cue, isNull);
    // With animations off it just stands.
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: FightHeroSprite(
              controller: controller,
              anchor: anchor,
              alive: true,
              animate: false),
        ),
      ),
    ));
    controller.cue(anchor, PortraitCue.lunge);
    await tester.pump(const Duration(milliseconds: 100));
    expect(painter().cue, isNull);
  });
}
