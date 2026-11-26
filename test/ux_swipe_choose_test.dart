// Swipe a card up to choose it (v2.10.22): the wrapper alone (a drag past a
// share of the card's height or a fling chooses it, less springs back, a tap
// reaches the card, reduce motion only fades) and the Tower's offer (the middle
// card in front but none in hand, Take off until one is, a swipe takes it).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';
import 'package:narrative_data_app/screens/tower/tower_swipe_card.dart';
import 'support/pump.dart';

void main() {
  Widget card(void Function() onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
            key: const Key('c'), width: 100, height: 200, color: Colors.red),
      );

  Future<void> host(WidgetTester t, Widget w, {bool reduce = false}) async {
    await t.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(body: Center(child: w)),
      ),
    ));
  }

  testWidgets('a drag past a third of the card chooses it, and it flies off',
      (t) async {
    var chosen = 0, lifted = 0;
    await host(
        t,
        TowerSwipeToChoose(
            onLift: () => lifted++,
            onChosen: () => chosen++,
            child: card(() {})));
    final start = t.getCenter(find.byKey(const Key('c')));
    final g = await t.startGesture(start);
    await g.moveBy(const Offset(0, -80));
    await g.moveBy(const Offset(0, -80));
    await t.pump();
    expect(lifted, 1);
    expect(chosen, 0, reason: 'not before the finger lifts');
    await g.up();
    await t.pump(const Duration(milliseconds: 100));
    expect(t.getCenter(find.byKey(const Key('c'))).dy, lessThan(start.dy - 70),
        reason: 'it is flying up');
    await t.pump(const Duration(milliseconds: 400));
    expect(chosen, 1);
  });

  testWidgets('a short drag springs back, a fling chooses', (t) async {
    var chosen = 0;
    await host(
        t, TowerSwipeToChoose(onChosen: () => chosen++, child: card(() {})));
    final start = t.getCenter(find.byKey(const Key('c')));
    final g = await t.startGesture(start);
    await g.moveBy(const Offset(0, -25));
    await g.up();
    await t.pump(const Duration(milliseconds: 400));
    expect(chosen, 0);
    expect(t.getCenter(find.byKey(const Key('c'))), start);
    // A fling.
    await t.timedDrag(find.byKey(const Key('c')), const Offset(0, -50),
        const Duration(milliseconds: 50));
    await t.pump(const Duration(milliseconds: 500));
    expect(chosen, 1);
  });

  testWidgets('a tap reaches the card; downward is ignored', (t) async {
    var taps = 0, chosen = 0;
    await host(
        t,
        TowerSwipeToChoose(
            onChosen: () => chosen++, child: card(() => taps++)));
    await t.tap(find.byKey(const Key('c')));
    expect(taps, 1);
    await t.drag(find.byKey(const Key('c')), const Offset(0, 120));
    await t.pump(const Duration(milliseconds: 400));
    expect(chosen, 0);
  });

  testWidgets('reduced motion: no fly-off, a quick fade', (t) async {
    var chosen = 0;
    await host(
        t, TowerSwipeToChoose(onChosen: () => chosen++, child: card(() {})),
        reduce: true);
    final start = t.getCenter(find.byKey(const Key('c')));
    final g = await t.startGesture(start);
    await g.moveBy(const Offset(0, -80));
    await g.moveBy(const Offset(0, -80));
    await g.up();
    await t.pump(const Duration(milliseconds: 60));
    final left = t.getCenter(find.byKey(const Key('c'))).dy;
    expect(left, lessThan(start.dy - 70));
    await t.pump(const Duration(milliseconds: 100));
    expect(t.getCenter(find.byKey(const Key('c'))).dy, left,
        reason: 'no fly-off: it stays where the finger left it');
    await t.pump(const Duration(milliseconds: 300));
    expect(chosen, 1);
  });

  group('the Tower offer', () {
    final data = towerDataFromAssets();
    final start = towerStart(
        seed: 5, raceId: 'human', professionId: 'warrior', data: data);
    final run =
        start.copyWith(floor: 6, status: TowerStatus.choosing, offer: const [
      TowerReward(TowerRewardKind.skill, id: 'fireball'),
      TowerReward(TowerRewardKind.die, id: 'flame_die'),
      TowerReward(TowerRewardKind.spell, id: 'spell_ember_wave'),
    ]);

    Future<ProviderContainer> open(WidgetTester t) async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'en',
        'tower_run_v1': jsonEncode(run.toJson()),
        'tutorial_enabled': false,
      });
      usePhone(t, const Size(412, 900));
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await c.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en);
      await t.pumpWidget(UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
              key: UniqueKey(),
              theme: buildAppTheme(
                  c.read(appPaletteProvider).schemeFor(Brightness.light)),
              home: const TowerFloorScreen())));
      Future<void> settle([int n = 8]) async {
        for (var i = 0; i < n; i++) {
          await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 80)));
          await t.pump(const Duration(milliseconds: 100));
        }
      }

      await settle(30);
      for (var i = 0; i < 6; i++) {
        final level = find.byType(LevelUpScreen);
        if (level.evaluate().isNotEmpty) {
          Navigator.of(t.element(level)).pop();
        }
        final take = find.byKey(const Key('loot_sheet_take'));
        if (take.evaluate().isNotEmpty) await t.tap(take);
        await settle(5);
      }
      for (var i = 0;
          i < 12 && find.byKey(const Key('tower_card_1')).evaluate().isEmpty;
          i++) {
        final take = find.byKey(const Key('loot_sheet_take'));
        if (take.evaluate().isNotEmpty) await t.tap(take);
        await settle(5);
      }
      return c;
    }

    testWidgets('none in hand, Take off, a tap holds, a swipe takes',
        (t) async {
      final c = await open(t);
      expect(find.byKey(const Key('tower_card_hint')), findsOneWidget);
      expect(
          t.widget<FilledButton>(find.byKey(const Key('tower_take'))).onPressed,
          isNull);
      await t.tap(find.byKey(const Key('tower_card_1')));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('tower_card_hint')), findsNothing);
      expect(find.byKey(const Key('tower_card_detail')), findsOneWidget);
      expect(
          t.widget<FilledButton>(find.byKey(const Key('tower_take'))).onPressed,
          isNotNull);

      // And a swipe up takes a card at once, held or not.

      expect(c.read(towerProvider).value?.run?.taken.containsKey(6), isFalse);
      await t.drag(
          find.byKey(const Key('tower_card_0')), const Offset(0, -260));
      await t.pump(const Duration(milliseconds: 600));
      for (var i = 0; i < 10; i++) {
        await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await t.pump(const Duration(milliseconds: 100));
      }
      final taken = c.read(towerProvider).value?.run?.taken[6];
      expect(taken?.id, 'fireball', reason: 'the swiped card was taken');
    });
  });
}
