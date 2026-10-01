// One of the last battles (v1.196): the Host the character raised stands
// with the party -- the fight's setup says so, the log names who came,
// and the Houses' block is on the party as the fight opens. A fight that
// is not one has none of it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/data/factions.dart';
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

bool _shows(String text) =>
    find.textContaining(text, findRichText: true).evaluate().isNotEmpty;

/// [text] in the full log's sheet.
Finder _inLog(String text) => find.descendant(
    of: find.byType(BottomSheet), matching: find.textContaining(text));

Map<String, dynamic> _gamedata(String name) =>
    jsonDecode(File('assets/gamedata/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  testWidgets('the Host stands with the party in a last battle only',
      (tester) async {
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
    // Crowned for the Compact, the Vigil Trusted, four Houses friends.
    final session = PlayerSession.fromJson({
      'raceId': 'human',
      'professionId': 'warrior',
      'ownedDiceIds': ['starter_die'],
      'equippedDiceId': 'starter_die',
      'maxHealth': 400,
      'currentHealth': 400,
    }).copyWith(
      politics: PoliticsState.fromJson({
        'standings': {'compact': 70.0, 'vigil': 30.0},
        'sworn': 'compact',
        'marks': {
          'quarrymen': 'friend',
          'stitchers': 'friend',
          'emberwives': 'friend',
          'moss_choir': 'friend',
        },
        'claim': 'compact',
        'throne': 'compact',
      }),
    );
    await tester.runAsync(() =>
        container.read(playerSessionProvider.notifier).loadSession(session));
    final dummy = {
      ..._gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
      'maxHealth': 900,
    };
    final navigator =
        tester.state<NavigatorState>(find.byType(Navigator).first);

    // A last battle: the note on the setup, the Host in the log.
    navigator.push(MaterialPageRoute<bool>(
        builder: (_) => FightScreen(
              enemyId: 'slum_thug',
              enemy: dummy,
              modifiers: const EncounterModifiers(
                  hostFight: true,
                  forcedCondition: BattlefieldCondition.highGround),
            )));
    await _settle(tester);
    expect(find.byKey(const Key('fight_host_note')), findsOneWidget);
    expect(find.text('Your Host fights beside you.'), findsOneWidget);
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);
    // The whole log, a tap on its ticker away.
    await tester.tap(find.byIcon(Icons.unfold_more));
    await _settle(tester);
    expect(_inLog('Your Host fights beside you: Compact, Vigil, 4 Houses.'),
        findsOneWidget);
    // Two Houses' worth of block for each member as the fight opens.
    expect(_inLog('the party starts behind 2 block'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tapAt(const Offset(20, 20));
    await _settle(tester);
    navigator.pop();
    await _settle(tester);

    // Any other fight: none of it.
    navigator.push(MaterialPageRoute<bool>(
        builder: (_) => FightScreen(
              enemyId: 'slum_thug',
              enemy: dummy,
              modifiers: const EncounterModifiers(
                  forcedCondition: BattlefieldCondition.highGround),
            )));
    await _settle(tester);
    expect(find.byKey(const Key('fight_host_note')), findsNothing);
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);
    expect(_shows('Your Host fights beside you'), isFalse);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });
}
