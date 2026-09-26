// v1.157: an effect plays at the power of what caused it. A common scratch
// is small and short, a legendary critical that takes a third of the
// target's health fills the screen, shakes it and lingers. Covers the
// power and tier rules, what a burst takes from its power, and the layer
// drawing a mighty burst bigger than a light one.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/skill_vfx.dart';
import 'package:narrative_data_app/widgets/combat_vfx.dart';

void main() {
  group('power', () {
    test('rarity sets the base, from common to legendary', () {
      final powers = [
        for (final rarity in [
          'common',
          'uncommon',
          'rare',
          'epic',
          'legendary'
        ])
          vfxPowerFor(rarity: rarity),
      ];
      for (var i = 1; i < powers.length; i++) {
        expect(powers[i], greaterThan(powers[i - 1]));
      }
      expect(vfxTierFor(vfxPowerFor(rarity: 'common')), VfxTier.light);
      expect(vfxTierFor(vfxPowerFor(rarity: 'uncommon')), VfxTier.normal);
      expect(vfxTierFor(vfxPowerFor(rarity: 'epic')), VfxTier.strong);
      expect(vfxTierFor(vfxPowerFor(rarity: 'legendary')), VfxTier.mighty);
    });

    test('a basic face with no rarity plays normal, a dearer spell bigger', () {
      expect(vfxTierFor(vfxPowerFor()), VfxTier.normal);
      expect(vfxPowerFor(manaCost: 4), greaterThan(vfxPowerFor(manaCost: 2)));
      expect(vfxTierFor(vfxPowerFor(manaCost: 4)), VfxTier.strong);
    });

    test('upgrades, a big share of health, a critical and a boss add up', () {
      final base =
          vfxPowerFor(rarity: 'rare', amount: 10, targetMaxHealth: 100);
      expect(vfxTierFor(base), VfxTier.normal);
      final upgraded = vfxPowerFor(
          rarity: 'rare', tier: 3, amount: 10, targetMaxHealth: 100);
      expect(upgraded, closeTo(base + 0.24, 1e-9));
      expect(vfxTierFor(upgraded), VfxTier.strong);
      expect(vfxPowerFor(rarity: 'rare', amount: 35, targetMaxHealth: 100),
          greaterThan(base));
      expect(
          vfxPowerFor(
              rarity: 'rare', amount: 10, targetMaxHealth: 100, critical: true),
          closeTo(base + 0.2, 1e-9));
      expect(
          vfxPowerFor(
              rarity: 'rare', amount: 10, targetMaxHealth: 100, boss: true),
          closeTo(base + 0.15, 1e-9));
    });

    test('a scratch on a big foe plays small', () {
      final scratch =
          vfxPowerFor(rarity: 'uncommon', amount: 2, targetMaxHealth: 200);
      expect(vfxTierFor(scratch), VfxTier.light);
      // With no health known, the number alone decides.
      expect(vfxPowerFor(rarity: 'uncommon', amount: 3),
          lessThan(vfxPowerFor(rarity: 'uncommon')));
      expect(vfxPowerFor(rarity: 'uncommon', amount: 45),
          greaterThan(vfxPowerFor(rarity: 'uncommon')));
    });

    test('never falls as the blow grows, and stays in range', () {
      for (final rarity in ['common', 'rare', 'legendary', null]) {
        var last = 0.0;
        // From 1: an amount of 0 is no number at all (a status, a cleanse).
        for (var amount = 1; amount <= 120; amount++) {
          final power = vfxPowerFor(
              rarity: rarity,
              tier: 5,
              amount: amount,
              targetMaxHealth: 100,
              critical: true,
              boss: true);
          expect(power, greaterThanOrEqualTo(last));
          expect(power, inInclusiveRange(minVfxPower, maxVfxPower));
          last = power;
        }
      }
      expect(vfxPowerFor(rarity: 'common', amount: 1, targetMaxHealth: 500),
          greaterThanOrEqualTo(minVfxPower));
    });

    test('tiers: boundaries, and each tier\'s own power maps back to it', () {
      expect(vfxTierFor(0.89), VfxTier.light);
      expect(vfxTierFor(0.9), VfxTier.normal);
      expect(vfxTierFor(1.19), VfxTier.normal);
      expect(vfxTierFor(1.2), VfxTier.strong);
      expect(vfxTierFor(1.44), VfxTier.strong);
      expect(vfxTierFor(1.45), VfxTier.mighty);
      for (final tier in VfxTier.values) {
        expect(vfxTierFor(vfxPowerOfTier(tier)), tier);
      }
      for (var i = 1; i < VfxTier.values.length; i++) {
        final tier = VfxTier.values[i];
        final below = VfxTier.values[i - 1];
        expect(vfxCountFactor(tier), greaterThan(vfxCountFactor(below)));
        expect(vfxDurationFactor(tier), greaterThan(vfxDurationFactor(below)));
      }
    });
  });

  test('numbers grow with the tier', () {
    for (var i = 1; i < VfxTier.values.length; i++) {
      expect(vfxTextSize(VfxTier.values[i]),
          greaterThan(vfxTextSize(VfxTier.values[i - 1])));
    }
  });

  group('burst', () {
    test('a mighty burst plays longer than a light one', () {
      for (final style in VfxStyle.values) {
        VfxBurst burst(double power) => VfxBurst(
              style: style,
              palette: paletteFor(style, 'Fire'),
              target: GlobalKey(),
              power: power,
              seed: 1,
            );
        final light = burst(0.7);
        final mighty = burst(1.7);
        expect(light.tier, VfxTier.light);
        expect(mighty.tier, VfxTier.mighty);
        expect(mighty.durationMs, greaterThan(light.durationMs),
            reason: style.name);
      }
    });

    test('a heal, a shield or mana is not a blow; damage is', () {
      final controller = CombatVfxController();
      final key = GlobalKey();
      controller.play(
          style: VfxStyle.slash,
          target: key,
          text: '-4',
          textKind: VfxTextKind.damage);
      controller.play(
          style: VfxStyle.frost,
          target: key,
          text: '+4',
          textKind: VfxTextKind.heal);
      controller.play(style: VfxStyle.shield, target: key);
      controller.play(style: VfxStyle.quake, target: key);
      controller.play(style: VfxStyle.heal, target: key, big: true);
      final bursts = controller.takeQueued();
      expect(
          [for (final b in bursts) b.hit], [true, false, false, true, false]);
      // No power given: a big one plays at 1.35, the rest at 1.
      expect(bursts.first.power, 1.0);
      expect(bursts.last.power, 1.35);
      controller.dispose();
    });
  });

  group('layer', () {
    testWidgets('plays every style at every tier, then goes quiet',
        (tester) async {
      final controller = CombatVfxController();
      final hero = GlobalKey();
      final foe = GlobalKey();
      await tester.pumpWidget(MaterialApp(
        home: Stack(
          children: [
            Positioned(
                left: 20,
                top: 300,
                width: 160,
                height: 70,
                child: SizedBox(key: hero)),
            Positioned(
                left: 220,
                top: 200,
                width: 160,
                height: 140,
                child: SizedBox(key: foe)),
            Positioned.fill(
              child: IgnorePointer(
                child: CombatVfxLayer(controller: controller),
              ),
            ),
          ],
        ),
      ));
      var i = 0;
      for (final tier in VfxTier.values) {
        for (final style in VfxStyle.values) {
          final support = supportVfxStyles.contains(style);
          controller.play(
            style: style,
            target: support ? hero : foe,
            source: support ? null : hero,
            element: vfxElementNames[i % vfxElementNames.length],
            delayMs: (i % 5) * 40,
            text: support ? '+${i + 1}' : '-${i + 1}',
            textKind: support ? VfxTextKind.heal : VfxTextKind.damage,
            power: vfxPowerOfTier(tier),
          );
          i++;
        }
      }
      for (var frame = 0; frame < 50; frame++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isFalse);
      controller.dispose();
    });

    testWidgets('a mighty blow covers more of the screen than a light one',
        (tester) async {
      tester.view.physicalSize = const Size(400, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      /// How many pixels [style] paints at [tier], halfway through.
      Future<int> coverage(VfxStyle style, VfxTier tier) async {
        final controller = CombatVfxController();
        final boundary = GlobalKey();
        final hero = GlobalKey();
        final foe = GlobalKey();
        await tester.pumpWidget(MaterialApp(
          home: RepaintBoundary(
            key: boundary,
            child: Stack(
              children: [
                Positioned(
                    left: 20,
                    top: 360,
                    width: 140,
                    height: 70,
                    child: SizedBox(key: hero)),
                Positioned(
                    left: 150,
                    top: 150,
                    width: 110,
                    height: 110,
                    child: SizedBox(key: foe)),
                Positioned.fill(
                    child: CombatVfxLayer(
                        key: ValueKey('$style$tier'), controller: controller)),
              ],
            ),
          ),
        ));
        controller.play(
            style: style,
            target: foe,
            source: hero,
            element: 'Fire',
            textKind: VfxTextKind.damage,
            power: vfxPowerOfTier(tier));
        await tester.pump();
        final duration =
            (vfxDurationMs(style) * vfxDurationFactor(tier)).round();
        final at = (duration * (vfxImpactAt(style) + 0.15)).round();
        await tester.pump(Duration(milliseconds: at));
        final render = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final count = await tester.runAsync(() async {
          final image = await render.toImage();
          final bytes =
              await image.toByteData(format: ui.ImageByteFormat.rawRgba);
          image.dispose();
          var painted = 0;
          for (var p = 3; p < bytes!.lengthInBytes; p += 4) {
            if (bytes.getUint8(p) > 24) painted++;
          }
          return painted;
        });
        // Let it finish so nothing is left ticking.
        await tester.pump(const Duration(seconds: 2));
        controller.dispose();
        return count!;
      }

      for (final style in [
        VfxStyle.slash,
        VfxStyle.fireball,
        VfxStyle.frost,
        VfxStyle.quake,
      ]) {
        final light = await coverage(style, VfxTier.light);
        final mighty = await coverage(style, VfxTier.mighty);
        expect(mighty, greaterThan(light * 1.5), reason: style.name);
      }
    });

    testWidgets('a strong blow lands: its card recoils, a light one is still',
        (tester) async {
      final controller = CombatVfxController();
      final hero = GlobalKey();
      final foe = GlobalKey();
      final impacts = <VfxImpact>[];
      controller.addImpactListener(impacts.add);
      await tester.pumpWidget(MaterialApp(
        home: Stack(
          children: [
            Positioned(
                left: 20,
                top: 300,
                width: 160,
                height: 70,
                child: SizedBox(key: hero)),
            Positioned(
              left: 220,
              top: 200,
              width: 160,
              height: 140,
              child: KeyedSubtree(
                key: foe,
                child: VfxRecoil(
                  controller: controller,
                  anchor: foe,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CombatVfxLayer(controller: controller),
              ),
            ),
          ],
        ),
      ));
      Offset shove() {
        final moved = tester
            .widget<Transform>(find.descendant(
                of: find.byType(VfxRecoil), matching: find.byType(Transform)))
            .transform
            .getTranslation();
        return Offset(moved.x, moved.y);
      }

      // A light slash lands without a word.
      controller.play(
          style: VfxStyle.slash,
          target: foe,
          source: hero,
          textKind: VfxTextKind.damage,
          power: vfxPowerOfTier(VfxTier.light));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(impacts, isEmpty);

      // A mighty one: reported as it lands, and the foe's card is shoved.
      controller.play(
          style: VfxStyle.slash,
          target: foe,
          source: hero,
          element: 'Fire',
          textKind: VfxTextKind.damage,
          power: vfxPowerOfTier(VfxTier.mighty));
      var moved = false;
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 30));
        if (shove() != Offset.zero) moved = true;
      }
      expect(impacts, hasLength(1));
      expect(impacts.single.target, foe);
      expect(impacts.single.tier, VfxTier.mighty);
      expect(impacts.single.hit, isTrue);
      expect(moved, isTrue);
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(shove(), Offset.zero, reason: 'it settles');
      expect(tester.binding.hasScheduledFrame, isFalse);
      controller.dispose();
    });
  });
}
