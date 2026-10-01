// Chapter 1's first fight on screen (v1.196): the enemy lands the first
// blow, the lucky die rolls loose and strikes back before the party's
// first roll; and a fight with a story branch for its loss is a scene,
// never a death, even with permadeath on (a plain one still is).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/permadeath_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/death_screen.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Map<String, dynamic> _enemy(String id) =>
    (jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
        as Map<String, dynamic>)[id] as Map<String, dynamic>;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the lucky die strikes first; a story loss is no death',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    Future<void> character({required int health}) =>
        tester.runAsync(() => container
            .read(playerSessionProvider.notifier)
            .loadSession(PlayerSession.fromJson({
              'raceId': 'human',
              'professionId': 'warrior',
              'ownedDiceIds': ['starter_die'],
              'equippedDiceId': 'starter_die',
              'gold': 100,
              'maxHealth': 100,
              'currentHealth': health,
            })));
    final navigator =
        tester.state<NavigatorState>(find.byType(Navigator).first);

    // The first fight: the bouncer's blow, then the die's sign, before
    // the party has rolled anything.
    await character(health: 100);
    navigator.push(MaterialPageRoute<bool>(
        builder: (_) => FightScreen(
              enemyId: 'den_bouncer',
              enemy: _enemy('den_bouncer'),
              modifiers: const EncounterModifiers(
                tutorial: true,
                luckyDieReveal: true,
                keepWounds: true,
                lossContinues: true,
              ),
            )));
    await _settle(tester);
    expect(find.text('Lucky Die'), findsOneWidget);
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);
    expect(find.textContaining('Roll it.'), findsWidgets);
    expect(find.textContaining('Elite'), findsNothing);
    await tester.pump(const Duration(seconds: 3));
    // A lesson can still be walked away from.
    await tester.tap(find.byTooltip('Retreat'));
    await _settle(tester);
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
    await _settle(tester);
    expect(find.byType(FightScreen), findsNothing);
    // The die's blow wounded, it did not fell.
    final wounded = container.read(playerSessionProvider).currentHealth;
    expect(wounded, inExclusiveRange(1, 100));

    // With permadeath on, a fight lost into a story branch is a scene.
    await tester.runAsync(
        () => container.read(permadeathEnabledProvider.notifier).setEnabled(
              true,
            ));
    final killer = {
      ..._enemy('den_bouncer'),
      'damage': 999,
      'skillMoves': const <Map<String, dynamic>>[],
    };
    Future<Future<bool?>> loseAnAmbush({required bool storyBranch}) async {
      await character(health: 1);
      final result = navigator.push(MaterialPageRoute<bool>(
          builder: (_) => FightScreen(
                enemyId: 'den_bouncer',
                enemy: killer,
                // Three blows, so not all three are dodged.
                additionalEnemyIds: const ['den_bouncer', 'den_bouncer'],
                additionalEnemies: {'den_bouncer': killer},
                modifiers: EncounterModifiers(
                  lossContinues: storyBranch,
                  forcedCondition: BattlefieldCondition.ambush,
                ),
              )));
      await _settle(tester);
      // Three foes push the setup's button below the fold.
      await tester.ensureVisible(find.text('Enter Battle'));
      await tester.pump();
      await tester.tap(find.text('Enter Battle'));
      await _settle(tester);
      await tester.pump(const Duration(seconds: 3));
      await _settle(tester);
      await tester.tap(find.widgetWithText(
          ElevatedButton, storyBranch ? 'Face what comes' : 'Retreat'));
      await _settle(tester);
      return result;
    }

    final branch = await loseAnAmbush(storyBranch: true);
    expect(await tester.runAsync(() => branch), isFalse);
    expect(find.byType(DeathScreen), findsNothing);
    expect(find.byType(FightScreen), findsNothing);

    // Without one, permadeath still takes the character.
    await loseAnAmbush(storyBranch: false);
    await _settle(tester);
    expect(find.byType(DeathScreen), findsOneWidget);
  });
}
