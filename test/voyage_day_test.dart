// A day at sea you can read (v1.180): the crossing as a strip of days with
// what each cost, the Eel on the water, one hull bar, and every choice
// with what it wins or costs -- and its odds when it is a check.
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
  test('the odds of a check: a d20 plus the bonus meets the DC', () {
    expect(checkChance(modifier: 0, dc: 11), 0.5);
    expect(checkChance(modifier: 1, dc: 16), 0.3);
    expect(checkChance(modifier: 5, dc: 3), 1.0);
    expect(checkChance(modifier: -2, dc: 30), 0.0);
  });

  testWidgets('each choice says its stake, the strip what the day cost',
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
    await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'gold': 100,
        })));

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
    await _pumpUntil(
        tester,
        () =>
            find.byKey(const Key('sea_choice_salvage')).evaluate().isNotEmpty);

    // The strip: two days, today the first; the Eel on the water.
    expect(find.byKey(const Key('route_day_0')), findsOneWidget);
    expect(find.byKey(const Key('route_day_1')), findsOneWidget);
    expect(find.text('today'), findsOneWidget);
    expect(find.byKey(const Key('ship_at_sea')), findsOneWidget);
    expect(find.byKey(const Key('hull_bar')), findsOneWidget);

    // Stakes: salvage is safe and says how much; boarding gives its check,
    // its odds and both outcomes; leaving costs nothing.
    expect(find.text('Safe · +40 gold'), findsOneWidget);
    expect(find.textContaining('win +80 gold · fail −12 hull'), findsOneWidget);
    expect(find.textContaining('%'), findsOneWidget);
    expect(find.text('Nothing gained, nothing lost'), findsOneWidget);

    // Salvaged: the day behind her says what it gave.
    await tester.tap(find.byKey(const Key('sea_choice_salvage')));
    await _pumpUntil(tester, () => find.text('+40 gold').evaluate().isNotEmpty);
    expect(find.text('+40 gold'), findsOneWidget);
    expect(container.read(playerSessionProvider).gold, 140);
    await tester.pump(const Duration(seconds: 2));
  });
}
