// A swipe up on the clan offer's fan takes the card the way tap + Take does:
// the gift is taken, the offer closes and the climb goes on (v2.10.22).
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
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'support/pump.dart';

void main() {
  testWidgets('a swipe up on the clan fan takes the gift and closes the offer',
      (t) async {
    final data = towerDataFromAssets();
    final start = towerStart(
        seed: 5, raceId: 'human', professionId: 'warrior', data: data);
    final run = start.copyWith(status: TowerStatus.choosing, offer: const [
      TowerReward(TowerRewardKind.skill, id: 'second_wind', clan: 'mire'),
      TowerReward(TowerRewardKind.skill, id: 'shadow_step', clan: 'dominion'),
      TowerReward(TowerRewardKind.skill, id: 'void_blast', clan: 'penitents'),
    ]);
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
    for (var i = 0; i < 8; i++) {
      final level = find.byType(LevelUpScreen);
      if (level.evaluate().isNotEmpty) Navigator.of(t.element(level)).pop();
      final take = find.byKey(const Key('loot_sheet_take'));
      if (take.evaluate().isNotEmpty) await t.tap(take);
      await settle(5);
      if (find.byKey(const Key('tower_card_1')).evaluate().isNotEmpty) break;
    }
    // None in hand at first: the hint, Take off.
    expect(find.byKey(const Key('tower_card_hint')), findsOneWidget);
    expect(
        t.widget<FilledButton>(find.byKey(const Key('tower_take'))).onPressed,
        isNull);
    expect(c.read(towerProvider).value?.run?.status, TowerStatus.choosing);

    // Swipe the middle card up: it flies off and the gift is taken.
    final g = await t
        .startGesture(t.getCenter(find.byKey(const Key('tower_card_1'))));
    for (var i = 0; i < 12; i++) {
      await g.moveBy(const Offset(0, -20));
      await t.pump(const Duration(milliseconds: 30));
    }
    await g.up();
    await t.pump(const Duration(milliseconds: 400));
    await settle(10);
    // The swipe opens the confirm sheet; Confirm takes the gift.
    expect(find.byKey(const Key('tower_pick_confirm')), findsOneWidget);
    await t.tap(find.byKey(const Key('tower_confirm')));
    await settle(10);
    final after = c.read(towerProvider).value?.run;
    expect(after?.taken[1]?.id, 'shadow_step');
    expect(after?.status, isNot(TowerStatus.choosing),
        reason: 'the offer is closed: the climb goes on');
    expect(find.byKey(const Key('tower_take')), findsNothing);
  });
}
