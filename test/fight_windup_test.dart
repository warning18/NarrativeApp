// An enemy that winds up (v1.162): the wind-up shows on its card and in its
// intent whatever the party's Perception, and the blow lands the turn
// after unless the party breaks it.
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

  testWidgets('a wind-up shows, then lands or breaks', (tester) async {
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
          // winds up. The rogue's technique only weakens.
          'professionId': 'rogue',
          'ownedDiceIds': ['starter_die'],
          'equippedDiceId': 'starter_die',
          'gold': 100,
        })));
    // A thug that does nothing but wind up, too sturdy to break by damage.
    final thug = {
      ..._enemy('slum_thug'),
      'maxHealth': 400,
      'skillMoves': [
        {'skillID': 'heavy_windup', 'condition': 'Always', 'priority': 1},
      ],
    };
    final navigator =
        tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.push(MaterialPageRoute<bool>(
        builder: (_) => FightScreen(
              enemyId: 'slum_thug',
              enemy: thug,
              // Never an ambush, which would shift the wind-up a turn
              // earlier; High Ground only changes Defend blocks.
              modifiers: const EncounterModifiers(
                  forcedCondition: BattlefieldCondition.highGround),
            )));
    await _settle(tester);
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);

    await tester.tap(find.text('Roll Dice'));
    await _settle(tester);
    await tester.tap(find.text('Confirm'));
    await _pumpUntil(tester, () => _logShows('is winding up'));

    expect(
        find.textContaining('is winding up', findRichText: true), findsWidgets);
    expect(find.text('Winding up'), findsOneWidget);
    expect(find.text('Charged blow incoming!'), findsOneWidget);

    await tester.tap(find.text('Roll Dice'));
    await _settle(tester);
    await tester.tap(find.text('Confirm'));
    await _pumpUntil(
        tester,
        () =>
            _logShows('comes crashing down') ||
            _logShows('knocked off balance'));
    expect(_logShows('comes crashing down') || _logShows('knocked off balance'),
        isTrue);
    await tester.pump(const Duration(seconds: 3));
  });
}
