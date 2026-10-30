// QA: the cove camp (7400) story page, with a chapter 7 quest in the tracker,
// at phone widths with the app's own fonts: no overflow, and the visitors'
// ways on are on the page. At 320x568 the tracker strip ("The Reed Gate's
// Grievance / Goal: Read the Reed Gate's petition") pushes the "Enter the
// camp" button 18 px past the page (story_player_screen.dart,
// _EnterPlaceButton), in English and French. Off until the fix (a shorter
// objective, or a scrollable area) lands.
// QA: the dice loadout's face tiles and the camp town's cards at phone widths,
// measured with the app's own fonts (see qa_real_font_layout_test.dart: the
// test font is far wider, so only the bundled fonts tell the truth). Checks no
// overflow, and that the six face tiles of a die are one size whatever they
// carry (an attack, a long French skill name, a locked or an over-limit face).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

List<String> _collectOverflows(WidgetTester tester) {
  final seen = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) {
      seen.add(details.exceptionAsString().split('\n').first);
    } else {
      previous?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = previous);
  return seen;
}

// Set to false when the 320 px fix lands.
const skipUntilFixPack = false;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
    // Read the data once, outside any test's fake clock: the bundle keeps the
    // first read, and one begun inside a test never finishes for the next.
    for (final path in [
      'assets/Cleaned_Narrative_DAG.json',
      for (final f in Directory('assets/gamedata').listSync())
        if (f.path.endsWith('.json')) f.path,
    ]) {
      await rootBundle.loadString(path);
    }
  });

  for (final size in const [Size(360, 740), Size(320, 568)]) {
    for (final french in [false, true]) {
      final label = '${size.width.toInt()} px ${french ? 'French' : 'English'}';
      testWidgets('the cove camp story page fits, $label', (tester) async {
        final overflows = _collectOverflows(tester);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
                const MethodChannel('flutter_tts'), (call) async => 1);
        SharedPreferences.setMockInitialValues(
            {if (french) 'app_language': 'fr'});
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
        await tester.pumpWidget(const ProviderScope(child: MyApp()));
        await settleApp(tester);
        final container =
            ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
        await tester.runAsync(() => container
            .read(playerSessionProvider.notifier)
            .loadSession(PlayerSession.fromJson({
              'raceId': 'human',
              'professionId': 'warrior',
              'flags': ['banner_five', 'hub_7400_reed'],
              'activeQuestIds': ['q_ch7_reed_gate_grievance'],
              'enemyKillCounts': <String, int>{},
            })));
        await settleApp(tester);
        final edit = find.byKey(const Key('menu_edit_mode'));
        await tester.ensureVisible(edit);
        await tester.tap(edit);
        await settleApp(tester);
        container.read(storyPlayProvider.notifier).jumpTo('7400');
        await settleApp(tester);
        await tester.pump(const Duration(seconds: 3));
        await settleApp(tester);
        // The ways on sit under the scene: scroll down to them.
        for (var i = 0; i < 12; i++) {
          await tester.dragFrom(
              Offset(size.width / 2, size.height * 0.3), const Offset(0, -300));
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(
            find.textContaining(french ? 'Roseaux' : 'Reed Gate',
                skipOffstage: false),
            findsWidgets);
        // The visitors' ways on that are acted out at the camp are choices
        // in the Journey's scene view (a button under its map opens it).
        // They used to be found here only because the Journey tab, offstage,
        // held them as cards under its map.
        await tester.tap(find.text(french ? 'Parcours' : 'Journey').last);
        await settleApp(tester);
        await tester.tap(find.byKey(const ValueKey('journey_open_choices')));
        await settleApp(tester);
        expect(
            find.textContaining(french ? 'héraut' : 'herald',
                skipOffstage: false),
            findsWidgets);
        expect(overflows, isEmpty, reason: overflows.toSet().join('\n'));
      }, skip: size.width < 340 && skipUntilFixPack);
    }
  }
}
