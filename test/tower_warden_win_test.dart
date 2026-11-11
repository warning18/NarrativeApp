// A Tower warden won through the real fight screen (v1.910, QA's real
// playthrough on v1.906): the fight's way out opens. The warden is a boss,
// and the story's clan offer used to be queued on the Tower's detached
// session, its dialog waiting for ever over the won fight with "Victory!
// Return" disabled. The Tower has its own oath cards: no story offer, and
// no story mercy for a hunter (QA #956).
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/tower_fight_session.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

import 'fight_qa694_harness.dart';
import 'skill_fight_harness.dart';
import 'support/pump.dart';

void main() {
  testWidgets('a Tower warden won lets the hero out of the fight',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(600, 1600));
    await tester.pumpWidget(ProviderScope(
        overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
        child: const MyApp()));
    await loadApp(tester);

    // Climbed to the first warden's floor.
    final data = towerDataFromAssets();
    var run = towerStart(
        seed: 4, raceId: 'human', professionId: 'warrior', data: data);
    while (towerFloorOf(run, data).kind != TowerFloorKind.warden) {
      run = towerPick(
          towerAfterFight(run, data, won: true, healthLeft: run.health),
          data,
          null);
    }
    final floor = towerFloorOf(run, data);
    final fight = TowerFightSession(run, data);
    // One hit fells it: the fight is won on the first roll. A hunter's
    // clan too: the Tower asks no "spare or finish" (QA #956).
    final warden = {
      ...data.enemies[floor.enemyIds.first] as Map<String, dynamic>,
      'maxHealth': 1,
      'phases': <dynamic>[],
      'hunterClan': 'crows',
    };
    final navigator =
        tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.push(MaterialPageRoute<bool>(
        builder: (_) => fight.wrap(FightScreen(
              enemyId: floor.enemyIds.first,
              enemy: warden,
              modifiers: floor.modifiersFor(run.professionId),
            ))));
    await loadApp(tester);
    await tester.ensureVisible(find.byIcon(Icons.sports_martial_arts));
    await tester.tap(find.byIcon(Icons.sports_martial_arts));
    await settle(tester);

    for (var round = 0; round < 6 && !shows('Victory! Return'); round++) {
      await tapWhenEnabled(tester, 'Roll Dice');
      await pumpUntil(tester, () => shows('Confirm'));
      await tapWhenEnabled(tester, 'Confirm');
      await pumpUntil(tester, () => shows('Victory! Return'));
    }
    await settle(tester);
    expect(find.byKey(const Key('mercy_dialog')), findsNothing);
    expect(buttonLabelled('Victory! Return')?.enabled, isTrue);
    // No story offer queued on the Tower's hero.
    final inner =
        ProviderScope.containerOf(tester.element(find.byType(FightScreen)));
    expect(inner.read(playerSessionProvider).pendingOffers, isEmpty);
    await tester.tap(find.text('Victory! Return'));
    await settle(tester);
    expect(find.byType(FightScreen), findsNothing);
  });
}
