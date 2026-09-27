// An enemy that raises its guard (v1.162): the log says so, its card shows
// the guard, and the party's next hits are soaked by it.
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
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Pumps until [done] holds (or ~12 s of real time pass): the enemy turn
/// waits on real async work before its own delay, so a busy machine needs
/// longer than a fixed number of pumps.
Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 40 && !done(); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

bool _logShows(String text) =>
    find.textContaining(text, findRichText: true).evaluate().isNotEmpty;

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
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('an enemy that braces shows its guard', (tester) async {
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
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          // Not a warrior: Shield Bash stuns, and a stunned thug never
          // braces. The rogue's technique only weakens.
          'professionId': 'rogue',
          'ownedDiceIds': ['starter_die'],
          'equippedDiceId': 'starter_die',
          'gold': 100,
        })));
    // A thug that does nothing but brace, and lives long enough to show it.
    final thug = {
      ..._enemy('slum_thug'),
      'maxHealth': 400,
      'skillMoves': [
        {'skillID': 'brace', 'condition': 'Always', 'priority': 1},
      ],
    };
    final navigator =
        tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.push(MaterialPageRoute<bool>(
        builder: (_) => FightScreen(
              enemyId: 'slum_thug',
              enemy: thug,
              // No ambush or other surprise; High Ground only changes
              // Defend blocks.
              modifiers: const EncounterModifiers(
                  forcedCondition: BattlefieldCondition.highGround),
            )));
    await _settle(tester);
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);

    await tester.tap(find.text('Roll Dice'));
    await _settle(tester);
    await tester.tap(find.text('Confirm'));
    await _pumpUntil(tester, () => _logShows('raises a guard of'));

    expect(find.textContaining('raises a guard of', findRichText: true),
        findsWidgets);
    expect(
        find.byTooltip('Raised guard: soaks your next hits'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
  });
}
