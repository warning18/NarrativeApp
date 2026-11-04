// A fighter's effect icons open ONE pop-in that lists all its effects
// (v1.792): the icon tapped does not matter, and a fighter with a single
// effect keeps the one-effect pop-in. The cards do not move.
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
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'package:narrative_data_app/widgets/fight_effect_icons.dart';
import 'support/pump.dart';

/// Pumps until [done] holds (or ~45 s of real time pass): the enemy turn
/// waits on real async work before its own delay, so a busy machine needs
/// longer than a fixed number of pumps. CI runs the whole suite at once,
/// and ~12 s was once not enough for the second enemy turn; the wait ends
/// as soon as [done] holds, so a generous cap costs a passing run nothing.
Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 150 && !done(); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

bool _logShows(String text) =>
    find.textContaining(text, findRichText: true).evaluate().isNotEmpty;

/// Taps the button labelled [label] once it is enabled. The enemy's line
/// shows before its turn is over, and a busy machine can still be in that
/// turn when the test moves on: the buttons are there, but disabled, and a
/// tap then does nothing.
Future<void> _tapWhenEnabled(WidgetTester tester, String label) async {
  bool enabled() {
    final button = find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
    return button.evaluate().isNotEmpty &&
        (button.evaluate().first.widget as ButtonStyleButton).enabled;
  }

  await _pumpUntil(tester, enabled);
  expect(enabled(), isTrue, reason: '"$label" never became enabled');
  await tester.tap(find.text(label));
}

/// Whether the party's turn is open: Roll Dice there and enabled.
bool _rollEnabled() {
  final button = find.ancestor(
      of: find.text('Roll Dice'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
  return button.evaluate().isNotEmpty &&
      (button.evaluate().first.widget as ButtonStyleButton).enabled;
}

Map<String, dynamic> _enemy(String id) {
  for (final path in [
    'assets/gamedata/enemies.json',
    '../assets/gamedata/enemies.json'
  ]) {
    final file = File(path);
    if (file.existsSync()) {
      return (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)[id]
          as Map<String, dynamic>;
    }
  }
  throw StateError('Cannot find enemies.json');
}

void main() {
  setUp(() {
    final dice =
        jsonDecode(File('assets/gamedata/dice.json').readAsStringSync())
            as Map<String, dynamic>;
    SharedPreferences.setMockInitialValues({
      'combat_dice_speed': 'quad',
      // A die of one Defend face: the hero ends the round with a block.
      'gamedb_dice': jsonEncode({
        ...dice,
        'defend_test_die': {
          'diceName': 'defend_test_die',
          'numberOfFaces': 1,
          'faces': [
            {'type': 'Defend', 'value': 6, 'element': 'None'},
          ],
        },
      }),
    });
  });

  testWidgets('a tap on any effect icon lists all the fighter\'s effects',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
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
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          // Fury, and a block from a Defend die.
          'professionId': 'warrior',
          'ownedDiceIds': ['defend_test_die'],
          'equippedDiceId': 'defend_test_die',
          'maxHealth': 900,
          'currentHealth': 900,
          'gold': 100,
        })));
    final thug = {
      ..._enemy('slum_thug'),
      'maxHealth': 400,
      'skillMoves': [
        {'skillID': 'heavy_windup', 'condition': 'Always', 'priority': 1},
      ],
    };
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<bool>(
            builder: (_) => FightScreen(
                  enemyId: 'slum_thug',
                  enemy: thug,
                  modifiers: const EncounterModifiers(
                      forcedCondition: BattlefieldCondition.highGround,
                      forcedGoal: FightGoal.slay),
                )));
    await settleApp(tester);
    await tester.tap(find.text('Enter Battle'));
    await settleApp(tester);
    await _tapWhenEnabled(tester, 'Roll Dice');
    await _tapWhenEnabled(tester, 'Confirm');
    await _pumpUntil(tester, _rollEnabled);
    final slot = find.byKey(const Key('party_slot_player'));
    final chips =
        find.descendant(of: slot, matching: find.byType(FightEffectChip));
    final before = tester.getRect(slot);
    final count = chips.evaluate().length;
    expect(count, greaterThan(1), reason: 'the hero has Fury and a block');

    // Each icon, tapped, opens the same one pop-in with every effect.
    for (var i = 0; i < count; i++) {
      await tester.tap(chips.at(i));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('fight_effect_popin')), findsOneWidget);
      expect(find.textContaining('$count effects'), findsOneWidget);
      expect(
          find.descendant(
              of: find.byKey(const Key('fight_effect_popin')),
              matching: find.byType(FightEffectChip)),
          findsNWidgets(count));
      await tester.tapAt(const Offset(5, 500));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('fight_effect_popin')), findsNothing);
    }
    // Nothing moved.
    expect(tester.getRect(slot), before);
  });

  testWidgets('the list scrolls when it is long, and fits at 320 px',
      (tester) async {
    usePhone(tester, const Size(320, 568));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showFightEffectsPopin(
                context,
                anchor: const Rect.fromLTWH(20, 100, 27, 23),
                title: 'Voleur des taudis · 7 effets',
                closeHint: 'Touchez ailleurs pour fermer.',
                entries: [
                  for (final e in FightEffect.values.take(7))
                    FightEffectEntry(
                        effect: e,
                        title: e.name,
                        body: 'Une règle assez longue pour passer sur '
                            'plusieurs lignes à 320 px de large, et plus.'),
                ],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump(const Duration(milliseconds: 300));
    final card = tester.getRect(find.byKey(const Key('fight_effect_popin')));
    expect(card.bottom, lessThanOrEqualTo(568));
    expect(card.width, 300);
    expect(tester.takeException(), isNull);
  });
}
