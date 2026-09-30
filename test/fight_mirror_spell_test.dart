// A Mirror (v1.182's dice tampering) sends back the party's best blow of
// the round, and a spell is one of the round's blows as much as a die.
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

/// The number [pattern] catches in the full log's sheet.
int _logged(RegExp pattern) {
  for (final element in find
      .descendant(of: find.byType(BottomSheet), matching: find.byType(Text))
      .evaluate()) {
    final match = pattern.firstMatch((element.widget as Text).data ?? '');
    if (match != null) return int.parse(match.group(1)!);
  }
  fail('nothing in the log matches $pattern');
}

void main() {
  testWidgets('a Mirror sends back a spell cast this round', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    // A one-face die that neither hits nor guards: the spell is the
    // round's only blow.
    SharedPreferences.setMockInitialValues({
      'gamedb_dice': jsonEncode({
        ..._gamedata('dice.json'),
        'mana_test_die': {
          'diceName': 'mana_test_die',
          'numberOfFaces': 1,
          'faces': [
            {'type': 'Mana', 'value': 1, 'element': 'None'},
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
          'professionId': 'mage',
          'ownedDiceIds': ['mana_test_die'],
          'equippedDiceId': 'mana_test_die',
          'maxHealth': 400,
          'currentHealth': 400,
          'baseDamage': 10,
          'intelligence': 6,
          'mana': 10,
          'knownSpellIds': ['spell_arcane_bolt'],
          // No armor, and no dodging: the Mirror lands as it is thrown.
          'baseArmor': 0,
          'dexterity': -4,
        })));
    // A thug that mirrors every turn, too sturdy to fall.
    final thug = {
      ..._gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
      'maxHealth': 900,
      'damage': 25,
      'skillMoves': [
        {'skillID': 'glass_reflection', 'condition': 'Always', 'priority': 1},
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

    await tester.tap(find.text('Arcane Bolt'));
    await _pumpUntil(tester, () => _shows('takes'));
    await _tapWhenEnabled(tester, 'Roll Dice');
    await _pumpUntil(tester, () => _shows('Confirm'));
    await _tapWhenEnabled(tester, 'Confirm');
    await _pumpUntil(tester, () => _shows('Round 2'));
    await _settle(tester);

    await tester.tap(find.byIcon(Icons.unfold_more));
    await _settle(tester);
    final spell = _logged(RegExp(r'takes (\d+) damage'));
    final mirrored = _logged(RegExp(r'You take (\d+) damage'));
    expect(mirrored, spell);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });
}
