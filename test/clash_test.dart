// Targeted defence and element reactions (v1.214): a Defend face may parry
// one enemy's coming blow, and two partner elements striking the same enemy
// react.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/element_reaction.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/combat/parry.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 150 && !done(); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

bool _enabled(String label) {
  final button = find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
  return button.evaluate().isNotEmpty &&
      (button.evaluate().first.widget as ButtonStyleButton).enabled;
}

Future<void> _tapWhenEnabled(WidgetTester tester, String label) async {
  await _pumpUntil(tester, () => _enabled(label));
  expect(_enabled(label), isTrue, reason: '"$label" never became enabled');
  await tester.tap(find.text(label));
}

Map<String, dynamic> _gamedata(String name) =>
    jsonDecode(File('assets/gamedata/$name').readAsStringSync())
        as Map<String, dynamic>;

Finder _inLog(String text) => find.descendant(
    of: find.byType(BottomSheet), matching: find.textContaining(text));

void main() {
  group('parry', () {
    test('a parry counts half again, and only a block gives one', () {
      expect(parryAmount(10), 15);
      expect(parryAmount(0), 0);
      expect(parryAmount(-3), 0);
    });

    test('a parry that covers the blow stops it and is answered', () {
      expect(parryStopsBlow(20, 20), isTrue);
      expect(parryStopsBlow(20, 19), isFalse);
      expect(parryStopsBlow(0, 5), isFalse);
      expect(parryCounter(15), 8);
      expect(parryCounter(1), 1);
    });

    test('the parry, then the block, then the mitigation take their share', () {
      expect(
          damageAfterParry(blow: 40, parry: 15, block: 5, mitigation: 3), 17);
      expect(damageAfterParry(blow: 10, parry: 15, block: 5, mitigation: 3), 0);
      expect(damageAfterParry(blow: 10, parry: 0, block: 0, mitigation: 0), 10);
    });
  });

  group('element reactions', () {
    test('partners react in either order, the rest do not', () {
      expect(reactionBetween('Water', 'Electricity'), ElementReaction.conduct);
      expect(reactionBetween('Electricity', 'Water'), ElementReaction.conduct);
      expect(reactionBetween('Fire', 'Ice'), ElementReaction.shatter);
      expect(reactionBetween('Fire', 'Wind'), ElementReaction.firestorm);
      expect(reactionBetween('Water', 'Ice'), ElementReaction.freeze);
      expect(reactionBetween('Earth', 'Wind'), ElementReaction.sandblast);
      expect(reactionBetween('Light', 'Void'), ElementReaction.eclipse);
      expect(reactionBetween('Fire', 'Fire'), isNull);
      expect(reactionBetween('Fire', 'Water'), isNull);
      expect(reactionBetween('None', 'Fire'), isNull);
    });

    test('a prime lasts the round it was struck in and the next', () {
      final marks = {'Water': 3};
      expect(activeMarks(marks, 3), ['Water']);
      expect(activeMarks(marks, 4), ['Water']);
      expect(activeMarks(marks, 5), isEmpty);
      expect(reactionOn(marks, 'Electricity', 4)?.reaction,
          ElementReaction.conduct);
      expect(reactionOn(marks, 'Electricity', 5), isNull);
      expect(reactionOn(marks, 'Fire', 3), isNull);
      expect(reactionOn(marks, 'None', 3), isNull);
    });

    test('the bonus follows the hit that sprang it', () {
      expect(reactionBonus(ElementReaction.conduct, 10), 5);
      expect(reactionBonus(ElementReaction.shatter, 10), 6);
      expect(reactionBonus(ElementReaction.eclipse, 10), 10);
      expect(reactionBonus(ElementReaction.freeze, 10), 0);
      expect(reactionBonus(ElementReaction.conduct, 0), 0);
      expect(reactionBonus(ElementReaction.conduct, 1), 1);
      expect(reactionSpreadShare(ElementReaction.conduct), conductChainShare);
      expect(reactionSpreadShare(ElementReaction.freeze), 0);
    });

    test('every element has a partner to look for', () {
      expect(reactionPartners('Water'), ['Electricity', 'Ice']);
      expect(reactionPartners('Fire'), ['Ice', 'Wind']);
      for (final element in strikeElements) {
        expect(reactionPartners(element), isNotEmpty, reason: element);
      }
    });
  });

  testWidgets('a parry turns a blow aside; partner elements react',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    final dice = _gamedata('dice.json');
    SharedPreferences.setMockInitialValues({
      'gamedb_dice': jsonEncode({
        ...dice,
        'defend_test_die': {
          'diceName': 'defend_test_die',
          'numberOfFaces': 1,
          'faces': [
            {'type': 'Defend', 'value': 60, 'element': 'None'},
          ],
        },
        'water_test_die': {
          'diceName': 'water_test_die',
          'numberOfFaces': 1,
          'faces': [
            {'type': 'Attack', 'value': 6, 'element': 'Water'},
          ],
        },
        'vess_die': {
          ...dice['vess_die'] as Map<String, dynamic>,
          'faces': [
            for (var i = 0; i < 6; i++)
              {'type': 'Attack', 'value': 6, 'element': 'Electricity'},
          ],
        },
      }),
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));

    Future<void> load(String die, {bool ally = false, int dexterity = 0}) =>
        tester.runAsync(() => container
            .read(playerSessionProvider.notifier)
            .loadSession(PlayerSession.fromJson({
              'raceId': 'human',
              'professionId': 'warrior',
              'ownedDiceIds': [die],
              'equippedDiceId': die,
              // A quick player acts before Vess; a slow one cannot dodge the
              // blow a parry is meant to meet.
              'dexterity': dexterity,
              'maxHealth': 900,
              'currentHealth': 900,
              if (ally) ...{
                'recruitedAllies': [
                  {'companionId': 'vess', 'currentHealth': 1 << 30},
                ],
                'activeAllyIds': ['vess'],
              },
            })));

    final thug = {
      ..._gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
      'maxHealth': 900,
      'damage': 20,
      'faction': '',
      'weakTo': <dynamic>[],
      'resists': <dynamic>[],
      'skillMoves': <dynamic>[],
    };
    NavigatorState navigator() =>
        tester.state<NavigatorState>(find.byType(Navigator).first);

    // --- A parry -----------------------------------------------------------
    await load('defend_test_die');
    navigator().push(MaterialPageRoute<bool>(
        builder: (_) => FightScreen(
              enemyId: 'slum_thug',
              enemy: thug,
              modifiers: const EncounterModifiers(
                  forcedCondition: BattlefieldCondition.highGround,
                  forcedGoal: FightGoal.slay),
            )));
    await _settle(tester);
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);
    await _tapWhenEnabled(tester, 'Roll Dice');
    await _pumpUntil(tester, () => _enabled('Confirm'));
    final chip = find.byKey(const Key('parry_player'));
    expect(chip, findsOneWidget, reason: 'a Defend face offers a parry');
    expect(find.text('Parry…'), findsOneWidget);
    await tester.tap(chip);
    await _pumpUntil(
        tester,
        () => find
            .textContaining('Thug')
            .evaluate()
            .any((e) => ((e.widget as Text).data ?? '').startsWith('Parry ')));
    // The thug may have rolled an affix, which prefixes its name.
    expect(find.text('Parry…'), findsNothing);
    await tester.tap(find.text('Confirm'));
    await _pumpUntil(
        tester,
        () =>
            find.textContaining('Round 2').evaluate().isNotEmpty &&
            _enabled('Roll Dice'));
    await tester.tap(find.byIcon(Icons.unfold_more));
    await _settle(tester);
    expect(_inLog('readies a parry against'), findsOneWidget);
    expect(_inLog('turned aside and answered'), findsOneWidget);
    await tester.tapAt(const Offset(195, 40));
    await _settle(tester);
    navigator().pop();
    await _settle(tester);
    navigator().pop();
    await _settle(tester);

    // --- A reaction --------------------------------------------------------
    await load('water_test_die', ally: true, dexterity: 60);
    navigator().push(MaterialPageRoute<bool>(
        builder: (_) => FightScreen(
              enemyId: 'slum_thug',
              enemy: thug,
              modifiers: const EncounterModifiers(
                  forcedCondition: BattlefieldCondition.highGround,
                  forcedGoal: FightGoal.slay),
            )));
    await _settle(tester);
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);
    await _tapWhenEnabled(tester, 'Roll Dice (2×)');
    await _pumpUntil(tester, () => _enabled('Confirm'));
    await tester.tap(find.text('Confirm'));
    await _pumpUntil(
        tester,
        () =>
            find.textContaining('Round 2').evaluate().isNotEmpty &&
            _enabled('Roll Dice (2×)'));
    await tester.tap(find.byIcon(Icons.unfold_more));
    await _settle(tester);
    // Water first (the player, quicker), then Electricity: a Conduct.
    expect(_inLog('Conduct!'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tapAt(const Offset(195, 40));
    await tester.pump(const Duration(seconds: 3));
  });
}
