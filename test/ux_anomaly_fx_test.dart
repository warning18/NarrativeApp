// The ground in a fight (v1.241): the stage behind the battle, an anomaly's
// omen the round before it breaks, and its tick on the side it falls on --
// here the earth breaking under the enemy.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/field_anomaly.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'support/pump.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
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
  usePhone(tester, const Size(600, 1600));

  await tester.pumpWidget(ProviderScope(
      overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
      child: const MyApp()));
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
  // The whole-screen atmosphere and the warning toast: on the omen (a round
  // ahead) the toast says it is coming and the atmosphere is faint; on the
  // break the toast names it with its effect; the action bar stays clear.
  testWidgets('an anomaly: the omen toast, the atmosphere, the break toast',
      (tester) async {
    await _start(
        tester,
        EncounterModifiers(
          forcedStage: FightStage.cliffs,
          forcedGoal: FightGoal.slay,
          forcedAnomaly:
              forcedFieldAnomaly('earth_break', side: AnomalySide.enemies),
        ));
    expect(find.byKey(const Key('anomaly_atmosphere')), findsNothing);
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);
    // Round one: the omen. The toast says it is coming, and the favour.
    expect(find.byKey(const Key('anomaly_toast_omen')), findsOneWidget);
    expect(find.textContaining('The ground shudders underfoot'), findsWidgets);
    // The atmosphere is there, over the battle and clear of the controls.
    expect(find.byKey(const Key('anomaly_atmosphere')), findsOneWidget);
    final layerRect =
        tester.getRect(find.byKey(const Key('anomaly_atmosphere')));
    final clip = tester.widget<ClipRect>(find
        .ancestor(
            of: find.byKey(const Key('anomaly_atmosphere')),
            matching: find.byType(ClipRect))
        .first);
    final cut = clip.clipper!.getClip(layerRect.size);
    expect(layerRect.top + cut.bottom,
        lessThanOrEqualTo(tester.getTopLeft(find.text('Roll Dice')).dy),
        reason: 'the veil stops above the action bar');
    // The toast fades by itself.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const Key('anomaly_toast_omen')), findsNothing);

    await _tapWhenEnabled(tester, 'Roll Dice');
    await _pumpUntil(tester, () => _shows('Confirm'));
    await _tapWhenEnabled(tester, 'Confirm');
    // Round two: it breaks: the toast names it and says what it does.
    await _pumpUntil(
        tester,
        () => find
            .byKey(const Key('anomaly_toast_active'))
            .evaluate()
            .isNotEmpty);
    expect(find.textContaining('Earth break!'), findsOneWidget);
    expect(find.byKey(const Key('anomaly_atmosphere')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });
}
