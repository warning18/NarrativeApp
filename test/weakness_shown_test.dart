// Foe weaknesses show from the start of a fight (v1.994, the user's call):
// a foe never met, with no kill of its kind, names its weakness on the
// loadout picker before any hit. Its resistances stay learned.
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
  testWidgets('a foe never met shows its weaknesses from the start',
      (tester) async {
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
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    // No kill of its kind, and the starting Perception: before v1.994 the
    // weakness stayed hidden until a hit found it.
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'ownedDiceIds': ['starter_die', 'flame_die'],
          'equippedDiceId': 'starter_die',
        })));
    final rat = {
      ..._enemy('harbor_rat'),
      'weakTo': ['Fire'],
      'skillMoves': <dynamic>[],
    };
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<bool>(
            builder: (_) => FightScreen(
                  enemyId: 'harbor_rat',
                  enemy: rat,
                  modifiers: const EncounterModifiers(
                      forcedCondition: BattlefieldCondition.highGround,
                      forcedGoal: FightGoal.slay,
                      forcedAffixes: [EnemyAffix.packLeader]),
                )));
    await settleApp(tester);
    expect(find.textContaining('Known weaknesses: Fire'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
