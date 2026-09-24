// Back is no way out of a fight: before it starts the party can still
// turn away, but once it has begun the back gesture leaves the fight
// running (a loss can't be skipped, a win can't be walked away from).
// Retreat is the way out of a fight in progress, for a share of the gold.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/aftermath_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

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

  testWidgets('back leaves the setup but not a fight in progress',
      (tester) async {
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
    // A character with the starter die, so the fight can begin.
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'ownedDiceIds': ['starter_die'],
          'equippedDiceId': 'starter_die',
          'gold': 100,
        })));
    final navigator =
        tester.state<NavigatorState>(find.byType(Navigator).first);

    Future<void> openFight() async {
      navigator.push(MaterialPageRoute<bool>(
          builder: (_) =>
              FightScreen(enemyId: 'harbor_rat', enemy: _enemy('harbor_rat'))));
      await _settle(tester);
      expect(find.byType(FightScreen), findsOneWidget);
    }

    // Before the fight begins, back turns away from it.
    await openFight();
    await navigator.maybePop();
    await _settle(tester);
    expect(find.byType(FightScreen), findsNothing);

    // Once it has begun, back leaves it running.
    await openFight();
    await tester.tap(find.text('Enter Battle'));
    await _settle(tester);
    await navigator.maybePop();
    await _settle(tester);
    expect(find.byType(FightScreen), findsOneWidget);
    expect(find.textContaining('not over'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));

    // Retreat is the way out: it costs a share of the purse.
    await tester.tap(find.byTooltip('Retreat'));
    await _settle(tester);
    await tester.tap(find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(FilledButton)));
    await _settle(tester);
    expect(find.byType(FightScreen), findsNothing);
    expect(
        container.read(playerSessionProvider).gold, 100 - retreatCostFor(100));
    expect(container.read(lastFightRetreatedProvider), isTrue);
  });
}
