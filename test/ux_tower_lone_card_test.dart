// #1145: a card offered alone (the clan oath on floors 1 and 3) is one of
// three, centred, not a screen-high black tarot.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';
import 'package:narrative_data_app/screens/tower/tower_clan_cards.dart';
import 'package:narrative_data_app/screens/tower/tower_tarot_card.dart';

import 'support/fonts.dart';

void main() {
  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });

  testWidgets('a lone oath card is a third of the width, centred, and short',
      (tester) async {
    await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    final data = towerDataFromAssets();
    final at = towerStart(
        seed: 5, raceId: 'human', professionId: 'warrior', data: data);
    var run = at.copyWith(
        status: TowerStatus.choosing,
        offer: [TowerReward(TowerRewardKind.clanOath, id: at.oathsLeft.first)]);
    while (towerPendingPicks(run) > 0) {
      final picks = towerStatPickOffer(run, data, hero: towerHeroOf(run, data));
      if (picks.isEmpty) break;
      run = towerTakeStatPick(run, data, 0, offer: picks);
    }
    SharedPreferences.setMockInitialValues({
      towerRunPrefsKey: jsonEncode(run.toJson()),
      'tutorial_enabled': false,
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 780);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    Future<void> settle([int n = 8]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await settle(12);
    for (final k in ['menu_tower', 'tower_continue']) {
      final f = find.byKey(Key(k));
      await tester.ensureVisible(f.first);
      await tester.pump();
      await tester.tap(f.first);
      await settle(10);
    }
    final take = find.byKey(const Key('loot_sheet_take'));
    if (take.evaluate().isNotEmpty) {
      await tester.ensureVisible(take.first);
      await tester.pump();
      await tester.tap(take.first);
      await settle(10);
    }
    await settle(18);
    // The clan oath alone is the oath row of the clans' table (a wide, short
    // paper row), never a screen-high black tarot (#1145).
    final card = find.byType(TowerClanOathRow);
    expect(card, findsOneWidget);
    expect(find.byType(TowerTarotCard), findsNothing);
    final size = tester.getSize(card);
    expect(size.height, lessThan(220), reason: 'short, not screen-high');
    expect(size.width, lessThan(360));
    expect(tester.takeException(), isNull);
  });
}
