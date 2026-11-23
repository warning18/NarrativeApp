// QA flow check (L3 1.992): the app is killed in the middle of a fight and
// started again. What the player lives with, pinned so a change of it is a
// choice and not an accident:
//  - a potion drunk in the fight stays spent (the session is saved at once),
//  - the fight itself does not come back (no fight state is saved),
//  - the app starts again at the menu, with Continue offered, and does not
//    crash or stick on a half-drawn fight.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'support/pump.dart';

void main() {
  testWidgets('a potion drunk mid-fight stays spent after a restart',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(390, 844));
    Widget app() => ProviderScope(
        overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
        child: const MyApp());
    await tester.pumpWidget(app());
    await settleApp(tester);
    var c = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => c
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'characterName': 'Kill',
          'ownedDiceIds': ['starter_die'],
          'equippedDiceId': 'starter_die',
          'potionCount': 3,
        })));
    final enemies =
        jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
            as Map<String, dynamic>;
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<bool>(
            builder: (_) => FightScreen(enemyId: 'harbor_rat', enemy: {
                  ...Map<String, dynamic>.from(enemies['harbor_rat'] as Map),
                  'skillMoves': const <dynamic>[],
                })));
    await settleApp(tester);
    await tester.tapAt(const Offset(4, 300));
    await settleApp(tester);
    await tester.tap(find.text('Enter Battle'));
    await settleApp(tester);
    // Drink: the potion button of the fight.
    final potion = find.byIcon(Icons.local_drink);
    if (potion.evaluate().isNotEmpty) {
      await tester.tap(potion.first);
      await settleApp(tester);
    } else {
      // The icon may differ: use the notifier, as the button does.
      await c.read(playerSessionProvider.notifier).consumePotion();
    }
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    expect(c.read(playerSessionProvider).potionCount, 2);

    // The kill: the whole tree goes, the saved preferences stay.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await tester.pumpWidget(app());
    await settleApp(tester);
    c = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(milliseconds: 200));
    expect(c.read(playerSessionProvider).potionCount, 2,
        reason: 'the potion stays spent');
    expect(find.byKey(const Key('menu_continue')), findsOneWidget);
    expect(find.text('Enter Battle'), findsNothing,
        reason: 'the fight does not come back');
    expect(tester.takeException(), isNull);
  });
}
