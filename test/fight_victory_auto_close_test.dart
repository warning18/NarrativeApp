// A won fight closes itself (the user's call): the chest opens on its
// own, the spoils are taken, and once nothing else waits on the player the
// fight returns to the story after victoryAutoLeaveDelay -- at once on a
// tap. The rewards follow into the next scene's opening line.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/aftermath_provider.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Map<String, dynamic> _enemy(String id) =>
    (jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
        as Map<String, dynamic>)[id] as Map<String, dynamic>;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<({NavigatorState navigator, ProviderContainer container})> start(
      WidgetTester tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
          'gold': 100,
          'level': 5,
        })));
    return (
      navigator: tester.state<NavigatorState>(find.byType(Navigator).first),
      container: container,
    );
  }

  /// Opens a fight, wins it (edit mode's shortcut) and takes the chest.
  Future<Future<bool?>> winAndTake(
      WidgetTester tester, NavigatorState navigator) async {
    final result = navigator.push(MaterialPageRoute<bool>(
        builder: (_) =>
            FightScreen(enemyId: 'harbor_rat', enemy: _enemy('harbor_rat'))));
    await _settle(tester);
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);
    await tester.tap(find.byTooltip('Win this fight (edit mode)'));
    await _settle(tester);
    // The chest opens by itself and shows its drops.
    bool takeReady() => find
        .widgetWithText(FilledButton, 'Take')
        .evaluate()
        .any((e) => (e.widget as FilledButton).onPressed != null);
    for (var i = 0; i < 80 && !takeReady(); i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(takeReady(), isTrue, reason: 'the chest opened by itself');
    await tester.tap(find.text('Take'));
    await _settle(tester);
    return result;
  }

  testWidgets(
      'a won fight returns on its own once the spoils are taken, or on a tap',
      (tester) async {
    final (:navigator, :container) = await start(tester);
    final result = await winAndTake(tester, navigator);
    // The rewards are on screen a moment.
    expect(find.byType(FightScreen), findsOneWidget);
    expect(find.textContaining('Victory'), findsWidgets);
    await tester
        .pump(victoryAutoLeaveDelay + const Duration(milliseconds: 300));
    await _settle(tester);
    expect(find.byType(FightScreen), findsNothing);
    expect(await result, isTrue);
    // The rewards go on to the next scene.
    expect(container.read(lastFightOutcomeProvider)!.spoils,
        startsWith('Victory'));

    // A tap leaves at once.
    final again = await winAndTake(tester, navigator);
    expect(find.byType(FightScreen), findsOneWidget);
    await tester.tapAt(const Offset(195, 400));
    await _settle(tester);
    expect(find.byType(FightScreen), findsNothing);
    expect(await again, isTrue);
  });
}
