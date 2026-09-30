// A sea beast at sea (v1.185): its omen the day before, then the beast
// itself, named and described, with the crew's three answers. Keeping
// still (a Wisdom check) lets it pass and leaves a sign of it for the hunt.
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

Map<String, dynamic> _data(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

const _quiet = SeaEvent(
  kind: SeaEventKind.sighting,
  description: 'Nothing on the water.',
  descriptionFr: 'Rien sur l\'eau.',
  choiceText: 'Sail on',
  choiceTextFr: 'Poursuivre',
);

void main() {
  testWidgets('the omen, the beast, and a sign of it for keeping still',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final ports = _data('ports');
    final brinejaw = _data('enemy_ships')['brinejaw'] as Map<String, dynamic>;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(playerSessionProvider.notifier);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    // A mind still enough that keeping still can't fail.
    await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'gold': 100,
          'wisdom': 40,
        })));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: VoyageScreen(
          fromPortId: 'port_ashen_landing',
          toPortId: 'port_smugglers_wharf',
          toPort: ports['port_smugglers_wharf'] as Map<String, dynamic>,
          debugEvents:
              withBeastDay(const [_quiet, _quiet], 1, 'brinejaw', brinejaw),
        ),
      ),
    ));
    final sailOn = find.byKey(const Key('sea_choice_sailOn'));
    await _pumpUntil(tester, () => sailOn.evaluate().isNotEmpty);

    // Day 1: the omen.
    expect(find.byKey(const Key('beast_omen')), findsOneWidget);
    expect(find.textContaining('The fish have gone'), findsOneWidget);
    await tester.tap(sailOn);
    final keepStill = find.byKey(const Key('sea_choice_holdStill'));
    await _pumpUntil(tester, () => keepStill.evaluate().isNotEmpty);

    // Day 2: the beast, and what can be done about it.
    expect(find.text('The Brinejaw'), findsOneWidget);
    expect(find.byKey(const Key('sea_choice_fight')), findsOneWidget);
    expect(find.byKey(const Key('sea_choice_outrun')), findsOneWidget);
    await tester.tap(keepStill);
    await _pumpUntil(tester,
        () => container.read(playerSessionProvider).currentPortId.isNotEmpty);

    final beast = container.read(playerSessionProvider).seaBeasts['brinejaw']!;
    expect(beast.seen, isTrue);
    expect(beast.clues, 1);
    expect(beast.encounters, 0, reason: 'no battle was fought');
    expect(container.read(playerSessionProvider).currentPortId,
        'port_smugglers_wharf');
  });
}
