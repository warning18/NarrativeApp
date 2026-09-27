// Boarding a derelict (v1.165): twice the salvage when the Perception check
// passes; a failed one costs the Eel hull, not the crew health.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/sea_events.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/voyage_screen.dart';

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 40 && !done(); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _wreck = SeaEvent(
  kind: SeaEventKind.derelict,
  description: 'A wreck.',
  descriptionFr: 'Une épave.',
  choiceText: 'Salvage what floats',
  choiceTextFr: 'Récupérer ce qui flotte',
  gold: 40,
);

void main() {
  test('the stakes', () {
    expect(boardGoldMultiplier, 2);
    expect(boardFailHullLoss, greaterThan(0));
  });

  testWidgets('a boarding that pays, then one that costs the hull',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final ports =
        jsonDecode(File('assets/gamedata/ports.json').readAsStringSync())
            as Map<String, dynamic>;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(playerSessionProvider.notifier);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    // Eyes sharp enough that the first check can't fail.
    await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'gold': 200,
          'perception': 40,
        })));
    final health = container.read(playerSessionProvider).currentHealth;

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: VoyageScreen(
          fromPortId: 'port_ashen_landing',
          toPortId: 'port_smugglers_wharf',
          toPort: ports['port_smugglers_wharf'] as Map<String, dynamic>,
          debugEvents: const [_wreck, _wreck],
        ),
      ),
    ));
    final board = find.byKey(const Key('sea_choice_board'));
    await _pumpUntil(tester, () => board.evaluate().isNotEmpty);

    // Day 1: the check passes, twice the salvage.
    await tester.tap(board);
    await _pumpUntil(
        tester, () => find.textContaining('Found').evaluate().isNotEmpty);
    expect(container.read(playerSessionProvider).gold, 200 + 80);

    // Day 2: eyes that can't pass it; the hulk stoves in the Eel's side.
    await tester.runAsync(() => notifier.debugSetStats(perception: -40));
    await tester.pump();
    await tester.tap(board);
    await _pumpUntil(tester,
        () => container.read(playerSessionProvider).currentPortId.isNotEmpty);
    final session = container.read(playerSessionProvider);
    expect(session.gold, 280, reason: 'nothing found');
    expect(session.shipHull, 100 - boardFailHullLoss);
    expect(session.currentHealth, health, reason: 'the crew is unhurt');
  });
}
