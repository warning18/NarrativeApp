// Shared by the heal guards (test/qa_heal_*_test.dart): a real fight played
// as a script of heals, then the heals the log reports, in the order they
// were given. QA's, tests only.
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

import '../skill_fight_harness.dart'
    show gamedata, pumpUntil, settle, shows, tapWhenEnabled;
import 'pump.dart';

/// One heal the log reports.
class Heal {
  const Heal(this.kind, this.amount);

  /// 'die', 'spell' or 'potion'.
  final String kind;
  final int amount;

  @override
  String toString() => '$kind $amount';
}

/// A step of the script: cast Mending Light, drink a potion, or play a round
/// (roll the one-face Heal die and confirm).
enum HealStep { spell, potion, round }

/// Plays [steps] in a fight of [professionId] on [condition] (a shrine, or
/// the plain high ground) against a foe too sturdy to fall, with a one-face
/// Heal die worth [dieHeal], and returns the heals of the log, oldest first.
/// The hero is at full health: the log still reports what was healed.
Future<List<Heal>> playHeals(
  WidgetTester tester,
  List<HealStep> steps, {
  String professionId = 'cleric',
  BattlefieldCondition condition = BattlefieldCondition.highGround,
  int dieHeal = 40,
  List<String> specIds = const [],
  int potions = 5,
  Map<String, dynamic> enemyPatch = const {},
}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  SharedPreferences.setMockInitialValues({
    'combat_dice_speed': 'quad',
    'gamedb_dice': jsonEncode({
      ...gamedata('dice.json'),
      'heal_die': {
        'diceName': 'heal_die',
        'numberOfFaces': 1,
        'faces': [
          {
            'faceName': 'Mend',
            'type': 'Heal',
            'value': dieHeal,
            'element': 'None'
          },
        ],
      },
    }),
  });
  usePhone(tester, const Size(600, 1600));
  await tester.pumpWidget(ProviderScope(
      key: UniqueKey(),
      overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
      child: const MyApp()));
  await settle(tester);
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .loadSession(PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': professionId,
        'ownedDiceIds': ['heal_die'],
        'equippedDiceId': 'heal_die',
        'maxHealth': 4000,
        'currentHealth': 2000,
        'wisdom': 6,
        'mana': 40,
        'potionCount': potions,
        'knownSpellIds': ['spell_mending_light'],
        'specIds': specIds,
      })));
  final thug = {
    ...gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
    'maxHealth': 90000,
    'damage': 1,
    'skillMoves': <dynamic>[],
    ...enemyPatch,
  };
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(MaterialPageRoute<bool>(
          builder: (_) => FightScreen(
                enemyId: 'slum_thug',
                enemy: thug,
                modifiers: EncounterModifiers(
                    forcedCondition: condition, forcedGoal: FightGoal.slay),
              )));
  await settle(tester);
  await tester.tap(find.text('Enter Battle'));
  await settle(tester);

  // The hero's health on its card ("2000 / 4000"): what each step healed is
  // the change in it (the foe hits for next to nothing). The log's "Heal:
  // you recover N HP" line is the face's own number, before the rule.
  int hp() {
    for (final e in find.byType(Text).evaluate()) {
      final m =
          RegExp(r'^(\d+) ?/ ?4000$').firstMatch((e.widget as Text).data ?? '');
      if (m != null) return int.parse(m.group(1)!);
    }
    fail('the hero\'s health is not on the screen');
  }

  final heals = <Heal>[];
  for (final step in steps) {
    final before = hp();
    switch (step) {
      case HealStep.spell:
        await tester.tap(find.text('Mending Light'));
        await settle(tester);
      case HealStep.potion:
        await tester.tap(find.byIcon(Icons.local_drink));
        await settle(tester);
      case HealStep.round:
        await tapWhenEnabled(tester, 'Roll Dice');
        await pumpUntil(tester, () => shows('Confirm'));
        await tapWhenEnabled(tester, 'Confirm');
        await pumpFor(tester, 40);
        await settle(tester);
    }
    await tester.pump(const Duration(milliseconds: 800));
    heals.add(Heal(
        switch (step) {
          HealStep.spell => 'spell',
          HealStep.potion => 'potion',
          HealStep.round => 'die',
        },
        hp() - before));
  }
  return heals;
}
