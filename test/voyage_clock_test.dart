// A day at sea on the world clock (v1.187): the whole day passes, and the
// crew eats a ration for it, or goes hungry with the pack empty.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/sea_events.dart';
import 'package:narrative_data_app/providers/chapter_loop_provider.dart';
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
  testWidgets('each day at sea eats a ration; with none, the crew goes hungry',
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
    // Chapter 4's waters.
    final container = ProviderContainer(
        overrides: [reachedChapterProvider.overrideWithValue(4)]);
    addTearDown(container.dispose);
    final notifier = container.read(playerSessionProvider.notifier);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'maxHealth': 100,
          'currentHealth': 100,
          'day': 10,
          'watch': 1,
          'provisions': 1,
        })));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: VoyageScreen(
          fromPortId: 'port_ashen_landing',
          toPortId: 'port_drowned_stair',
          toPort: ports['port_drowned_stair'] as Map<String, dynamic>,
          debugEvents: const [_wreck, _wreck],
        ),
      ),
    ));
    PlayerSession session() => container.read(playerSessionProvider);
    Finder salvage() => find.byKey(const Key('sea_choice_salvage'));
    await _pumpUntil(tester, () => salvage().evaluate().isNotEmpty);

    // The first day: the last ration, and the log says so.
    await tester.tap(salvage());
    await _pumpUntil(tester,
        () => find.textContaining('the last ration').evaluate().isNotEmpty);
    expect(session().day, 11);
    expect(session().watch, 1);
    expect(session().provisions, 0);
    expect(session().currentHealth, 100);
    expect(find.textContaining('That was the last ration'), findsOneWidget);

    // The second: nothing left to eat.
    await _pumpUntil(tester, () => salvage().evaluate().isNotEmpty);
    await tester.tap(salvage());
    await _pumpUntil(tester, () => session().day == 12);
    expect(session().provisions, 0);
    expect(session().currentHealth, 92);
    await tester.pump(const Duration(seconds: 2));
  });
}
