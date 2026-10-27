// The scene's words as a band over the map or the street (v1.588,
// lib/widgets/scene_band.dart): a hub opens as its map with three lines of
// prose, a scene at a doorstep as its street with four, a tap opens the
// sheet with the whole scene.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/widgets/arrival_sheet.dart';
import 'package:narrative_data_app/widgets/scene_band.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The Journey at [scene], in English.
Future<ProviderContainer> _journeyAt(WidgetTester tester, String scene,
    {bool closeCards = true}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  SharedPreferences.setMockInitialValues(
      closeCards ? {'tutorial_enabled': false} : {});
  tester.view.physicalSize = const Size(400, 860);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const ProviderScope(child: MyApp()));
  await _settle(tester);
  await tester.tap(find.byKey(const Key('menu_edit_mode')));
  await _settle(tester);
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(() =>
      container.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en));
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .loadSession(PlayerSession.fromJson(
          {'raceId': 'human', 'professionId': 'warrior'})));
  await tester.runAsync(
      () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
  await _settle(tester);
  container.read(storyPlayProvider.notifier).jumpTo(scene);
  await _settle(tester);
  await tester.tap(find.text('Journey'));
  await _settle(tester);
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
  setUp(() => rootBundle.clear());

  group('bandTextOf', () {
    test('takes the first paragraph, on one line', () {
      expect(bandTextOf('The quay stood\nquiet.\n\nA second paragraph.'),
          'The quay stood quiet.');
      expect(bandTextOf('  \n\n One.  '), 'One.');
      expect(bandTextOf(''), '');
    });
  });

  group('the band', () {
    Widget host(Widget child) => MaterialApp(
          home: Scaffold(
              body: Align(alignment: Alignment.topCenter, child: child)),
        );
    const long =
        'The harbor master’s office had shut its shutters at the first bell, '
        'and the quay beneath it smelled of tar and old rope, of wet sailcloth '
        'and the brine the tide left on every stone, of crates nobody claimed '
        'and gulls that did not care who did.';

    testWidgets('shows at most its lines, a tap opens the scene',
        (tester) async {
      var opened = 0;
      await tester.pumpWidget(host(SizedBox(
        width: 260,
        child: SceneBand(text: long, lines: 3, onOpen: () => opened++),
      )));
      final text =
          tester.widget<Text>(find.byKey(const Key('scene_band_text')));
      expect(text.maxLines, 3);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(find.text(long), findsOneWidget);
      await tester.tap(find.byKey(const Key('scene_band')));
      expect(opened, 1);
    });

    testWidgets('a drag down opens it too; no words, no band', (tester) async {
      var opened = 0;
      await tester.pumpWidget(host(SizedBox(
        width: 260,
        child: SceneBand(text: long, onOpen: () => opened++),
      )));
      await tester.fling(
          find.byKey(const Key('scene_band')), const Offset(0, 120), 600);
      expect(opened, 1);
      await tester
          .pumpWidget(host(SceneBand(text: '  ', onOpen: () => opened++)));
      expect(find.byKey(const Key('scene_band')), findsNothing);
    });
  });

  testWidgets('a hub opens as its map with the band; a tap opens the sheet',
      (tester) async {
    await _journeyAt(tester, '2015');
    // The map, and the band over it with three lines of the prose.
    expect(find.byKey(const ValueKey('journey_city_chart')), findsOneWidget);
    final band = find.byKey(const Key('scene_band'));
    expect(band, findsOneWidget);
    expect(
        tester.widget<Text>(find.byKey(const Key('scene_band_text'))).maxLines,
        hubBandLines);
    expect(find.byType(ArrivalSheet), findsNothing);
    // A tap on it opens the whole scene; Continue folds it back to the band.
    await tester.tap(band);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ArrivalSheet), findsOneWidget);
    expect(find.byKey(const Key('scene_band')), findsNothing);
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ArrivalSheet), findsNothing);
    expect(find.byKey(const Key('scene_band')), findsOneWidget);
  });

  testWidgets('a scene at a doorstep is its street with four lines',
      (tester) async {
    await _journeyAt(tester, '300', closeCards: false);
    expect(find.byKey(const ValueKey('journey_street_scene')), findsOneWidget);
    expect(find.byKey(const Key('scene_band')), findsOneWidget);
    expect(
        tester.widget<Text>(find.byKey(const Key('scene_band_text'))).maxLines,
        streetBandLines);
  });
}
