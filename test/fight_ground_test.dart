// The ground in a fight (v1.241): the stage behind the battle, an anomaly's
// omen the round before it breaks, and its tick on the side it falls on --
// here the earth breaking under the enemy.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/field_anomaly.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
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
  for (var i = 0; i < 60 && !done(); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

bool _shows(String text) =>
    find.textContaining(text, findRichText: true).evaluate().isNotEmpty;

/// [text] in the full log's sheet.
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

Future<ProviderContainer> _start(
    WidgetTester tester, EncounterModifiers modifiers) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  SharedPreferences.setMockInitialValues({});
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
        'ownedDiceIds': ['starter_die'],
        'equippedDiceId': 'starter_die',
        'maxHealth': 400,
        'currentHealth': 400,
      })));
  // A thug that only braces, too sturdy to fall in a round or two.
  final thug = {
    ..._gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
    'maxHealth': 900,
    'skillMoves': [
      {'skillID': 'brace', 'condition': 'Always', 'priority': 1},
    ],
  };
  final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
  navigator.push(MaterialPageRoute<bool>(
      builder: (_) => FightScreen(
          enemyId: 'slum_thug', enemy: thug, modifiers: modifiers)));
  await _settle(tester);
  return container;
}

void main() {
  // One test pumps the whole app: the setup shows the ground, the battle
  // sits on it, and an anomaly is announced, breaks the next round and
  // strikes.
  testWidgets('a fight on its ground: the stage, the omen, the break',
      (tester) async {
    await _start(
        tester,
        EncounterModifiers(
          forcedStage: FightStage.cliffs,
          forcedGoal: FightGoal.slay,
          // The earth breaks under the enemy from the second round: a tenth
          // of the thug's health, once a round.
          forcedAnomaly:
              forcedFieldAnomaly('earth_break', side: AnomalySide.enemies),
        ));
    // The setup screen shows where the party stands, and says nothing yet
    // of what is coming.
    expect(find.byKey(const Key('fight_ground_strip')), findsOneWidget);
    expect(find.text('Sea cliffs'), findsOneWidget);
    expect(find.byKey(const Key('fight_anomaly_chip')), findsNothing);

    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);
    expect(find.byKey(const Key('fight_backdrop')), findsOneWidget);

    // Round one: the omen, as a chip over the battle.
    expect(find.byKey(const Key('fight_anomaly_chip')), findsOneWidget);

    await _tapWhenEnabled(tester, 'Roll Dice');
    await _pumpUntil(tester, () => _shows('Confirm'));
    await _tapWhenEnabled(tester, 'Confirm');
    // Round two: it breaks, and wounds the enemy by a tenth of its health.
    await _pumpUntil(tester, () => _shows('Earth break strikes'));

    // The whole log: the omen, the break, the wound.
    await tester.tap(find.byIcon(Icons.unfold_more));
    await _settle(tester);
    expect(_inLog('The ground shudders underfoot'), findsOneWidget);
    expect(_inLog('Earth break:'), findsOneWidget);
    expect(_inLog('Earth break strikes'), findsOneWidget);
    // A tenth of the thug's health: about a hundred, more when the thug
    // came up Elite (a random roll the test does not pin).
    final wound = RegExp(r'Earth break strikes .* for (\d+) damage').firstMatch(
        find
            .descendant(
                of: find.byType(BottomSheet),
                matching: find.textContaining('Earth break strikes'))
            .evaluate()
            .map((e) => (e.widget as Text).data!)
            .first)!;
    expect(int.parse(wound.group(1)!), inInclusiveRange(90, 200));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });
}
