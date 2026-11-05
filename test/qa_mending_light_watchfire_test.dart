// QA guard: a cleric's spell heal past full feeds the Watchfire, as a
// die's heal does (profession_cores.dart).
import 'dart:convert';
import 'dart:io';

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'package:narrative_data_app/widgets/fight_effect_icons.dart';

import 'support/pump.dart';

/// The first settle of a test waits for the game data to load; the later
/// ones only let the screen catch up.
final _warmed = Expando<bool>();

Future<void> _settle(WidgetTester tester) async {
  final first = _warmed[tester] == null;
  _warmed[tester] = true;
  for (var i = 0; i < (first ? 8 : 3); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(Duration(milliseconds: first ? 200 : 30)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 40 && !done(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

bool _shows(String text) =>
    find.textContaining(text, findRichText: true).evaluate().isNotEmpty;

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

/// The Watchfire's number on the cleric's card.
int _fire() {
  final chip = find
      .byWidgetPredicate(
        (w) => w is FightEffectChip && w.effect == FightEffect.watchfire,
      )
      .evaluate();
  expect(chip, isNotEmpty, reason: 'no Watchfire on the cleric');
  return int.parse((chip.first.widget as FightEffectChip).badge!);
}

void main() {
  // The user's bug (v1.857): Mending Light past full never fed the
  // cleric's Watchfire; only a die's heal did.
  testWidgets('a Mending Light past full feeds the Watchfire', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => 1,
    );
    SharedPreferences.setMockInitialValues({
      'combat_dice_speed': 'quad',
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
    usePhone(tester, const Size(600, 1600));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
        child: const MyApp(),
      ),
    );
    await _settle(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    // Two short of full: all but two of the heal spills into the fire.
    await tester.runAsync(
      () => container.read(playerSessionProvider.notifier).loadSession(
            PlayerSession.fromJson({
              'raceId': 'human',
              'professionId': 'cleric',
              'ownedDiceIds': ['mana_test_die'],
              'equippedDiceId': 'mana_test_die',
              'maxHealth': 400,
              'currentHealth': 398,
              'baseDamage': 10,
              'wisdom': 6,
              'mana': 10,
              'knownSpellIds': ['spell_mending_light'],
            }),
          ),
    );
    final thug = {
      ..._gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
      'maxHealth': 180,
      'damage': 1,
      'skillMoves': const [],
    };
    final navigator = tester.state<NavigatorState>(
      find.byType(Navigator).first,
    );
    navigator.push(
      MaterialPageRoute<bool>(
        builder: (_) => FightScreen(
          enemyId: 'slum_thug',
          enemy: thug,
          modifiers: const EncounterModifiers(
            forcedCondition: BattlefieldCondition.highGround,
            forcedGoal: FightGoal.slay,
          ),
        ),
      ),
    );
    await _settle(tester);
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);
    expect(_fire(), 0);

    await tester.tap(find.text('Mending Light'));
    await _pumpUntil(tester, () => _shows('recovers'));
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.unfold_more));
    await _settle(tester);
    final healed = _logged(RegExp(r'recovers (\d+)'));
    expect(healed, greaterThan(2));
    expect(_fire(), healed - 2);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });
}
