// Sea choices (v1.163): every day at sea asks what the crew does -- the
// rules, and a crossing sailed on fixed days.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/ability_check.dart';
import 'package:narrative_data_app/data/sea_events.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/voyage_screen.dart';

Map<String, dynamic> _load(String name) {
  for (final path in ['assets/gamedata/$name', '../assets/gamedata/$name']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  throw StateError('Cannot find $name');
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 40 && !done(); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('the rules', () {
    test('every kind of day has its choices, the usual one first', () {
      for (final kind in SeaEventKind.values) {
        final choices = seaChoicesFor(kind);
        expect(choices, isNotEmpty, reason: '$kind');
        for (final choice in choices) {
          expect(choice.textFor(false), isNotEmpty);
          expect(choice.textFor(true), isNotEmpty);
          final ability = choice.checkAbility;
          if (ability != null) expect(abilityScoreKeys, contains(ability));
        }
      }
      expect(seaChoicesFor(SeaEventKind.raider).map((c) => c.action),
          [SeaAction.fight, SeaAction.payOff, SeaAction.outrun]);
      expect(seaChoicesFor(SeaEventKind.storm).map((c) => c.action),
          [SeaAction.rideOut, SeaAction.pushThrough, SeaAction.shelter]);
      expect(seaChoicesFor(SeaEventKind.derelict).map((c) => c.action),
          [SeaAction.salvage, SeaAction.board, SeaAction.passBy]);
      expect(seaChoicesFor(SeaEventKind.calm).map((c) => c.action),
          [SeaAction.repair, SeaAction.rest]);
    });

    test('a drawn day still names its usual answer', () {
      const event = SeaEvent(
        kind: SeaEventKind.storm,
        description: 'd',
        descriptionFr: 'd',
        choiceText: 'Ride it out',
        choiceTextFr: 'Tenir bon',
      );
      expect(event.choices.first.text, event.choiceText);
    });

    test('the price of passage and the checks', () {
      final ships = _load('enemy_ships.json');
      expect(tributeFor(ships['raider_skiff'] as Map<String, dynamic>), 50);
      expect(tributeFor(ships['void_barge'] as Map<String, dynamic>), 140);
      expect(tributeFor(null), 60);
      expect(seaCheckDc(3), 12);
      expect(seaCheckDc(0), seaCheckDc(1));
    });
  });

  testWidgets('a crossing: leave the wreck, pay the raider, ride the storm',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final ports = _load('ports.json');
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(playerSessionProvider.notifier);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'gold': 200,
          'shipPartIds': ['ballista'],
        })));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: VoyageScreen(
          fromPortId: 'port_ashen_landing',
          toPortId: 'port_smugglers_wharf',
          toPort: ports['port_smugglers_wharf'] as Map<String, dynamic>,
          debugEvents: const [
            SeaEvent(
              kind: SeaEventKind.derelict,
              description: 'A wreck.',
              descriptionFr: 'Une épave.',
              choiceText: 'Salvage what floats',
              choiceTextFr: 'Récupérer ce qui flotte',
              gold: 40,
            ),
            SeaEvent(
              kind: SeaEventKind.raider,
              description: 'Sails.',
              descriptionFr: 'Des voiles.',
              choiceText: 'Beat to quarters',
              choiceTextFr: 'Branle-bas de combat',
              enemyShipId: 'raider_skiff',
            ),
            SeaEvent(
              kind: SeaEventKind.storm,
              description: 'A storm.',
              descriptionFr: 'Une tempête.',
              choiceText: 'Ride it out',
              choiceTextFr: 'Tenir bon',
              hullDelta: -10,
            ),
          ],
        ),
      ),
    ));
    Finder choice(SeaAction action) =>
        find.byKey(Key('sea_choice_${action.name}'));
    await _pumpUntil(
        tester, () => choice(SeaAction.passBy).evaluate().isNotEmpty);

    // Day 1: the wreck, left alone.
    expect(choice(SeaAction.salvage), findsOneWidget);
    expect(choice(SeaAction.board), findsOneWidget);
    expect(find.textContaining('Perception'), findsOneWidget,
        reason: 'boarding says what it rolls');
    await tester.tap(choice(SeaAction.passBy));
    await _pumpUntil(
        tester, () => choice(SeaAction.payOff).evaluate().isNotEmpty);
    expect(find.textContaining('drifts astern'), findsOneWidget);
    expect(container.read(playerSessionProvider).gold, 200);

    // Day 2: the raider, paid off.
    expect(find.textContaining('(50 gold)'), findsOneWidget);
    await tester.tap(choice(SeaAction.payOff));
    await _pumpUntil(
        tester, () => choice(SeaAction.rideOut).evaluate().isNotEmpty);
    expect(container.read(playerSessionProvider).gold, 150);
    expect(find.textContaining('Paid 50 gold'), findsOneWidget);

    // Day 3: the storm, ridden out; then landfall.
    await tester.tap(choice(SeaAction.rideOut));
    await _pumpUntil(tester,
        () => container.read(playerSessionProvider).currentPortId.isNotEmpty);
    final session = container.read(playerSessionProvider);
    expect(session.currentPortId, 'port_smugglers_wharf');
    expect(session.shipHull, 90);
  });
}
