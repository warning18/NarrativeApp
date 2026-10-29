// No text laid over the Journey's map (v1.607: the band of v1.588 was never
// validated): a hub opens as its map and a scene at a doorstep as its street,
// with nothing over them; the words are behind Read.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/widgets/arrival_sheet.dart';
import 'support/pump.dart';
import 'support/open_game.dart';

/// The Journey at [scene], in English.
Future<ProviderContainer> _journeyAt(WidgetTester tester, String scene,
    {bool closeCards = true}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  SharedPreferences.setMockInitialValues(
      closeCards ? {'tutorial_enabled': false} : {});
  usePhone(tester, const Size(400, 860));
  final container = await openGame(tester);
  container.read(storyPlayProvider.notifier).jumpTo(scene);
  await settleApp(tester);
  await tester.tap(find.text('Journey'));
  await settleApp(tester);
  await tester.pump(Duration(seconds: closeCards ? 6 : 1));
  // What arriving somewhere opens over the game (a new place's card) is
  // closed.
  for (var i = 0; closeCards && i < 3; i++) {
    Navigator.of(tester.element(find.byType(JourneyScreen)))
        .popUntil(isGameRoute);
    await tester.pump(const Duration(seconds: 1));
  }
  return container;
}

void main() {
  // An asset load cached by an earlier test belongs to that test's fake
  // clock and would never finish in this one.
  setUp(rootBundle.clear);

  testWidgets(
      'a hub opens as its map with no text over it; Read opens the scene',
      (tester) async {
    await _journeyAt(tester, '2015');
    expect(find.byKey(const ValueKey('journey_city_chart')), findsOneWidget);
    expect(find.byKey(const Key('scene_band')), findsNothing);
    expect(find.byType(ArrivalSheet), findsNothing);
    expect(find.byKey(const ValueKey('journey_read')), findsOneWidget);
  });

  testWidgets('a scene at a doorstep is its street with no text over it',
      (tester) async {
    await _journeyAt(tester, '300', closeCards: false);
    expect(find.byKey(const ValueKey('journey_street_scene')), findsOneWidget);
    expect(find.byKey(const Key('scene_band')), findsNothing);
    expect(find.byType(ArrivalSheet), findsNothing);
  });
}
