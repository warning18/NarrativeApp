// QA guard (#688): on the smallest phone (320 x 568) a fight with the hero,
// a companion-less party and one foe keeps a dice board big enough to play on.
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

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('320 x 568: the dice board keeps room', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(320, 568));
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
        })));
    final thug =
        (jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
            as Map<String, dynamic>)['slum_thug'];
    tester.state<NavigatorState>(find.byType(Navigator).first).push(
        MaterialPageRoute<bool>(
            builder: (_) => FightScreen(
                enemyId: 'slum_thug', enemy: thug as Map<String, dynamic>)));
    await _settle(tester);
    await tester.ensureVisible(find.text('Enter Battle'));
    await tester.pump();
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);

    final board =
        tester.getSize(find.byKey(const Key('fight_board_skin')).first);
    expect(board.height, greaterThan(120),
        reason: 'the dice board is a strip: ${board.height}');
    expect(tester.takeException(), isNull);
  });
}
