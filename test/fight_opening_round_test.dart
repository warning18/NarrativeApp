// The party's first round (v1.176's sellsword, v1.182's dice rules): a
// hired sellsword strikes before the first roll as before every other, a
// die's middle face (its own opposite) offers no Luck nudge, and a Hex
// leaves a Steady die where it landed.
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

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 40 && !done(); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

bool _shows(String text) =>
    find.textContaining(text, findRichText: true).evaluate().isNotEmpty;

/// [text] in the full log's sheet (the ticker under it shows the last two
/// lines again).
Finder _inLog(String text) => find.descendant(
    of: find.byType(BottomSheet), matching: find.textContaining(text));

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

Map<String, dynamic> _gamedata(String name) =>
    jsonDecode(File('assets/gamedata/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  testWidgets('the sellsword opens the fight; a Hex leaves a Steady die be',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    // A one-face die, a Steady guard: its only face is its own opposite.
    SharedPreferences.setMockInitialValues({
      'gamedb_dice': jsonEncode({
        ..._gamedata('dice.json'),
        'steady_test_die': {
          'diceName': 'steady_test_die',
          'numberOfFaces': 1,
          'faces': [
            {
              'type': 'Defend',
              'value': 6,
              'element': 'None',
              'keywords': ['steady'],
            },
          ],
        },
      }),
    });
    // Room for the test font's wide chips, and for the whole log at once.
    tester.view.physicalSize = const Size(600, 1600);
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
          'professionId': 'warrior',
          'ownedDiceIds': ['steady_test_die'],
          'equippedDiceId': 'steady_test_die',
          'maxHealth': 400,
          'currentHealth': 400,
          // Two nudges (see nudgesForLuck).
          'luck': 7,
          'sellswordFights': 3,
        })));
    // A thug that only ever hexes the party's dice, too sturdy to fall.
    final thug = {
      ..._gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
      'maxHealth': 900,
      'skillMoves': [
        {'skillID': 'hex_of_ill_luck', 'condition': 'Always', 'priority': 1},
      ],
    };
    final navigator =
        tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.push(MaterialPageRoute<bool>(
        builder: (_) => FightScreen(
              enemyId: 'slum_thug',
              enemy: thug,
              modifiers: const EncounterModifiers(
                  forcedCondition: BattlefieldCondition.highGround),
            )));
    await _settle(tester);
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);

    // No ambush, and the sellsword has struck before the first roll.
    expect(_shows('Your sellsword strikes'), isTrue);
    expect(container.read(playerSessionProvider).sellswordFights, 2);

    await _tapWhenEnabled(tester, 'Roll Dice');
    await _pumpUntil(tester, () => _shows('Confirm'));
    await tester.longPress(find.byKey(const ValueKey('die_tile_player')));
    await _settle(tester);
    expect(find.text('Nudges 2'), findsOneWidget);
    expect(find.textContaining('Nudge to'), findsNothing);
    await tester.tapAt(const Offset(20, 20));
    await _settle(tester);

    await _tapWhenEnabled(tester, 'Confirm');
    await _pumpUntil(tester, () => _shows('rolled again on your next throw'));
    await _tapWhenEnabled(tester, 'Roll Dice');
    await _pumpUntil(tester, () => _shows('Confirm'));
    await _settle(tester);

    // The whole log, a tap on its ticker away: the Hex found no die to
    // take, and the sellsword struck again as the second round began.
    await tester.tap(find.byIcon(Icons.unfold_more));
    await _settle(tester);
    expect(_inLog('rolled again on your next throw'), findsOneWidget);
    expect(_inLog('is rolled again:'), findsNothing);
    expect(_inLog('Your sellsword strikes'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });
}
