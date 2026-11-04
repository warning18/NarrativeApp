// The fight stays upright on a phone (v1.764): the screen is held in portrait
// while a fight is open and let go when it closes; a tablet is never held.
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
import 'package:narrative_data_app/utils/fight_orientation.dart';
import 'support/pump.dart';

/// What the app asked the platform for, in order: a list of orientations
/// (an empty one is "the default").
List<List<String>> _recordOrientations() {
  final calls = <List<String>>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'SystemChrome.setPreferredOrientations') {
      calls.add([for (final o in call.arguments as List) '$o']);
    }
    return null;
  });
  addTearDown(() => TestDefaultBinaryMessengerBinding
      .instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));
  return calls;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  test('a phone is held upright in either turn, a tablet is not', () {
    expect(holdsFightUpright(const Size(360, 740)), isTrue);
    expect(holdsFightUpright(const Size(740, 360)), isTrue);
    expect(holdsFightUpright(const Size(320, 568)), isTrue);
    expect(holdsFightUpright(const Size(800, 1280)), isFalse);
    expect(holdsFightUpright(const Size(1280, 800)), isFalse);
  });

  testWidgets('two fights hold once and let go when the last one leaves',
      (tester) async {
    final calls = _recordOrientations();
    usePhone(tester, const Size(360, 740));
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
      context = c;
      return const SizedBox();
    })));
    expect(holdFightUpright(context), isTrue);
    expect(holdFightUpright(context), isTrue);
    expect(calls, [
      ['DeviceOrientation.portraitUp', 'DeviceOrientation.portraitDown']
    ]);
    releaseFightUpright();
    expect(calls.length, 1, reason: 'one fight is still open');
    releaseFightUpright();
    expect(calls.last, isEmpty, reason: 'the platform default again');
    releaseFightUpright();
    expect(calls.length, 2, reason: 'an extra release does nothing');
  });

  testWidgets('a tablet is not held', (tester) async {
    final calls = _recordOrientations();
    usePhone(tester, const Size(800, 1280));
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (c) {
      context = c;
      return const SizedBox();
    })));
    expect(holdFightUpright(context), isFalse);
    expect(calls, isEmpty);
  });

  // One fight in this file: the game's tables are read once per test file.
  testWidgets('a fight on a phone holds the screen upright until it closes',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    final calls = _recordOrientations();
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(360, 740));
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
    expect(calls, isEmpty, reason: 'nothing is held outside a fight');

    final navigator =
        tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.push(MaterialPageRoute<bool>(
        builder: (_) => FightScreen(
            enemyId: 'slum_thug', enemy: thug as Map<String, dynamic>)));
    await _settle(tester);
    expect(
        calls,
        [
          ['DeviceOrientation.portraitUp', 'DeviceOrientation.portraitDown']
        ],
        reason: 'the fight holds the screen upright');

    navigator.pop();
    await _settle(tester);
    expect(calls.length, 2);
    expect(calls.last, isEmpty, reason: 'the fight let the screen turn again');
  });
}
