// The fight nameplate's emblem says its group in the player's language
// (v1.1003): the groups of no clan from the enemy_group_<id> strings, a clan's
// from its faction's name. Before, EnemyGroup.name (English only) was never read.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/enemy_affix.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'support/pump.dart';

Map<String, dynamic> _enemy(String id) => Map<String, dynamic>.from(
    (jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
        as Map<String, dynamic>)[id] as Map);

void main() {
  setUp(rootBundle.clear);

  Future<void> openFight(
      WidgetTester tester, AppLanguage lang, Map<String, dynamic> foe) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(390, 844));
    await tester.pumpWidget(ProviderScope(
        overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
        child: const MyApp()));
    await settleApp(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(
        () => container.read(appLanguageProvider.notifier).setLanguage(lang));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'ownedDiceIds': ['starter_die'],
          'equippedDiceId': 'starter_die',
        })));
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<bool>(
            builder: (_) => FightScreen(
                  enemyId: 'harbor_rat',
                  enemy: {...foe, 'skillMoves': const <dynamic>[]},
                  modifiers: const EncounterModifiers(
                      forcedCondition: BattlefieldCondition.highGround,
                      forcedGoal: FightGoal.slay,
                      forcedAffixes: [EnemyAffix.packLeader]),
                )));
    await settleApp(tester);
    // The foe's card stands first, the first time this foe is met.
    final enter =
        find.text(lang == AppLanguage.fr ? 'Entrer au combat' : 'Enter Battle');
    if (enter.evaluate().isNotEmpty) {
      await tester.ensureVisible(enter);
      await tester.pump();
      await tester.tap(enter);
    }
    await settleApp(tester);
  }

  testWidgets(
      'a group of no clan: its emblem names it in French and in English',
      (tester) async {
    final foe = {..._enemy('harbor_rat'), 'group': 'hollow_court'};
    await openFight(tester, AppLanguage.fr, foe);
    expect(find.byTooltip('La Cour Creuse'), findsOneWidget);
    expect(find.byTooltip('The Hollow Court'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the same group in English', (tester) async {
    final foe = {..._enemy('harbor_rat'), 'group': 'hollow_court'};
    await openFight(tester, AppLanguage.en, foe);
    expect(find.byTooltip('The Hollow Court'), findsOneWidget);
  });

  testWidgets('a clan group: its emblem names the clan in French',
      (tester) async {
    final foe = {..._enemy('harbor_rat'), 'faction': 'dominion'}
      ..remove('group');
    await openFight(tester, AppLanguage.fr, foe);
    expect(find.byTooltip('Le Dominion de la Lanterne'), findsOneWidget);
  });
}
