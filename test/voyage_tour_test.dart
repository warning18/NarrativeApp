// The voyage tour (v1.164): it plays by itself on the first day at sea,
// once the crossing has loaded, and lights the hull and the day's choices.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/sea_events.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/tutorial_provider.dart';
import 'package:narrative_data_app/screens/voyage_screen.dart';
import 'package:narrative_data_app/tutorial/guide_tour.dart';
import 'package:narrative_data_app/tutorial/tutorial_topics.dart';

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 40 && !done(); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Long enough for the guide to walk over and say the whole line (the
/// longest voyage line types for over two seconds).
Future<void> _wait(WidgetTester tester) async {
  for (var t = 0; t < 5000; t += 100) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('the tour plays on the first day and points at the choices',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'app_mode': 'inGame'});
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final ports =
        jsonDecode(File('assets/gamedata/ports.json').readAsStringSync())
            as Map<String, dynamic>;
    final container = ProviderContainer(
        overrides: [tutorialAutoShowProvider.overrideWithValue(true)]);
    addTearDown(container.dispose);
    container.read(playerSessionProvider.notifier);
    container.read(tutorialProvider);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'gold': 200,
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
              kind: SeaEventKind.calm,
              description: 'A calm.',
              descriptionFr: 'Un calme.',
              choiceText: 'Make repairs',
              choiceTextFr: 'Faire des réparations',
              hullDelta: 5,
            ),
          ],
        ),
      ),
    ));
    final dog = find.byKey(const Key('guide_dog'));
    await _pumpUntil(tester, () => dog.evaluate().isNotEmpty);
    expect(find.byKey(const Key('sea_choice_repair')), findsOneWidget);
    expect(dog, findsOneWidget);
    await _wait(tester);
    final steps = TutorialTopic.voyage.steps.length;
    expect(find.text('1 / $steps'), findsOneWidget);
    expect(
        container.read(tutorialProvider).hasSeen(TutorialTopic.voyage), isTrue);

    // On to the choices.
    await tester.tap(find.byKey(const Key('tutorial_next')));
    await _wait(tester);
    expect(find.text('2 / $steps'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tutorial_next')));
    await _wait(tester);
    expect(find.text('3 / $steps'), findsOneWidget);
    final choice = tester.getRect(find.byKey(const Key('sea_choice_repair')));
    expect(debugGuideHole!.contains(choice.center), isTrue);

    await tester.tap(find.byKey(const Key('tutorial_skip')));
    await _wait(tester);
    expect(dog, findsNothing);
  });
}
