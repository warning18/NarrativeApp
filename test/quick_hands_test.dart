// Quick hands (v1.213): the party acts in Dexterity order, a fight against
// enemies beaten many times can play itself (quick resolve), and the die
// rolled can be swapped before a fight for one that fits the enemy.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/combat/loadout.dart';
import 'package:narrative_data_app/combat/quick_resolve.dart';
import 'package:narrative_data_app/combat/turn_order.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/aftermath_provider.dart';
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
  for (var i = 0; i < 200 && !done(); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Map<String, dynamic> _enemy(String id) =>
    (jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
        as Map<String, dynamic>)[id] as Map<String, dynamic>;

void main() {
  group('turn order', () {
    test('the quickest acts first, equals keep the party’s order', () {
      final party = [
        ('player', 4),
        ('kelda', 9),
        ('sable', 4),
        ('liora', 12),
      ];
      expect([for (final m in actingOrder(party, (m) => m.$2)) m.$1],
          ['liora', 'kelda', 'player', 'sable']);
    });

    test('a party of equals plays as it always did', () {
      final party = ['a', 'b', 'c'];
      expect(actingOrder(party, (_) => 5), party);
      expect(actingOrder(<String>[], (_) => 0), isEmpty);
    });
  });

  group('quick resolve', () {
    test('offered only against enemies beaten often, with the player fit', () {
      bool offered({
        Map<String, int> kills = const {'harbor_rat': 5},
        bool eligible = true,
        double health = 0.9,
        List<String> ids = const ['harbor_rat'],
      }) =>
          quickResolveOffered(
              enemyIds: ids,
              killCounts: kills,
              eligible: eligible,
              healthShare: health);

      expect(offered(), isTrue);
      expect(offered(kills: {'harbor_rat': 4}), isFalse);
      expect(offered(eligible: false), isFalse);
      expect(offered(health: 0.5), isFalse);
      expect(offered(ids: ['harbor_rat', 'plague_hound']), isFalse);
      expect(
          offered(
              ids: ['harbor_rat', 'plague_hound'],
              kills: {'harbor_rat': 9, 'plague_hound': 5}),
          isTrue);
      expect(offered(ids: const []), isFalse);
    });

    test('it stops when the player is hurt or a companion has fallen', () {
      expect(quickResolveShouldStop(playerHealthShare: 0.8, anyAllyDown: false),
          isFalse);
      expect(quickResolveShouldStop(playerHealthShare: 0.4, anyAllyDown: false),
          isTrue);
      expect(quickResolveShouldStop(playerHealthShare: 0.8, anyAllyDown: true),
          isTrue);
    });
  });

  group('loadout', () {
    final dice =
        jsonDecode(File('assets/gamedata/dice.json').readAsStringSync())
            as Map<String, dynamic>;
    final skills =
        jsonDecode(File('assets/gamedata/skills.json').readAsStringSync())
            as Map<String, dynamic>;
    Set<String> elements(String id) {
      final faces = ((dice[id] as Map<String, dynamic>)['faces'] as List)
          .cast<Map<String, dynamic>>();
      return dieElements(faces, const {}, skills);
    }

    test('a die’s elements come from its attack faces and its skills', () {
      expect(elements('starter_die'), isEmpty);
      expect(elements('flame_die'), contains('Fire'));
      expect(elements('frost_die'), contains('Ice'));
    });

    test('the weaknesses a die can hit, sorted', () {
      expect(weaknessesHit({'Fire', 'Earth'}, ['Ice', 'Fire', 'Earth']),
          ['Earth', 'Fire']);
      expect(weaknessesHit({'Fire'}, ['Ice']), isEmpty);
      expect(weaknessesHit(<String>{}, ['Ice']), isEmpty);
    });
  });

  testWidgets(
      'the die is swapped for the enemy, and a known fight plays itself',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
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
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'ownedDiceIds': ['starter_die', 'flame_die'],
          'equippedDiceId': 'starter_die',
          'maxHealth': 900,
          'currentHealth': 900,
          'enemyKillCounts': {'harbor_rat': 6},
        })));

    // A rat that is weak to Fire, frail, and barely scratches.
    final rat = {
      ..._enemy('harbor_rat'),
      'maxHealth': 30,
      'damage': 1,
      'weakTo': ['Fire'],
      'skillMoves': <dynamic>[],
    };
    final navigator =
        tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.push(MaterialPageRoute<bool>(
        builder: (_) => FightScreen(
              enemyId: 'harbor_rat',
              enemy: rat,
              modifiers: const EncounterModifiers(
                  forcedCondition: BattlefieldCondition.highGround,
                  forcedGoal: FightGoal.slay),
            )));
    await _settle(tester);

    // The loadout picker names the weakness and what this die brings.
    expect(find.byKey(const Key('loadout_picker')), findsOneWidget);
    expect(find.textContaining('Known weaknesses: Fire'), findsOneWidget);
    expect(find.textContaining('This die hits none of them'), findsOneWidget);
    expect(find.textContaining('★'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('loadout_die_flame_die')));
    await tester.tap(find.byKey(const Key('loadout_die_flame_die')));
    await _settle(tester);
    expect(find.textContaining('This die hits: Fire'), findsOneWidget);

    // Beaten five times already: the fight offers to play itself.
    await tester.ensureVisible(find.byKey(const Key('quick_resolve_button')));
    await tester.tap(find.byKey(const Key('quick_resolve_button')));
    await _pumpUntil(
        tester, () => container.read(lastFightOutcomeProvider) != null);
    final outcome = container.read(lastFightOutcomeProvider);
    expect(outcome, isNotNull, reason: 'the quick resolve never finished');
    expect(outcome!.won, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}
