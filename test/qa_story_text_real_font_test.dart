// QA: the story text on a phone, with the app's own fonts (the test font is far
// wider, so only the bundled fonts tell the truth): the longest scenes of the
// story and the ones with the most bold, at 360 and 320 px wide, in English and
// French, lay out with no overflow, the scene's text is shown (written out in
// full, as the typewriter is off in tests), and the choices are reachable.
// L3_SHOTS=<folder> also writes a picture of each to that folder.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'support/fonts.dart';

/// The first settle of a test waits for the game data to load; the later
/// ones only let the screen catch up.
final _warmed = Expando<bool>();

Future<void> _settle(WidgetTester tester) async {
  final first = _warmed[tester] == null;
  _warmed[tester] = true;
  for (var i = 0; i < (first ? 6 : 3); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(Duration(milliseconds: first ? 200 : 30)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Some of the longest scenes and of the ones with the most bold, across the
/// story: the opening, a torture-chamber scene, a catacombs scene, a scene
/// with ten bold runs, a late hub and the epilogue.
const _scenes = [
  '100', '800', '5004b', '6002', '7001', '7005', //
];

void main() {
  final shots = Platform.environment['L3_SHOTS'];
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  // One test for every size and language: the game data is read on the first
  // pass and a read begun inside one test never finishes for the next.
  testWidgets('the longest scenes read on a phone, 360 and 320 px, EN and FR',
      (tester) async {
    final overflows = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflows.add(details.exceptionAsString().split('\n').first);
      } else {
        previous?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = previous);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(360, 740);
    final boundary = GlobalKey();
    await tester.pumpWidget(ProviderScope(
        child: RepaintBoundary(key: boundary, child: const MyApp())));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(
            {'raceId': 'human', 'professionId': 'warrior'})));
    final story = container.read(storyDataProvider).value!;
    for (final size in const [Size(360, 740), Size(320, 568)]) {
      tester.view.physicalSize = size;
      for (final french in [false, true]) {
        final label =
            '${size.width.toInt()} px ${french ? 'French' : 'English'}';
        await tester.runAsync(() => container
            .read(appLanguageProvider.notifier)
            .setLanguage(french ? AppLanguage.fr : AppLanguage.en));
        for (final id in _scenes) {
          final where = '$id at $label';
          expect(story.nodeFor(id), isNotNull, reason: '$id is not a scene');
          container.read(storyPlayProvider.notifier).jumpTo(id);
          await _settle(tester);
          // Close an arrival pop-up if one opened.
          final dialogButton = find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(FilledButton));
          if (dialogButton.evaluate().isNotEmpty) {
            await tester.tap(dialogButton.first, warnIfMissed: false);
            await _settle(tester);
          }
          // Past a new chapter's card (up to ten seconds, with its news).
          await tester.pump(const Duration(seconds: 6));
          await tester.pump(const Duration(seconds: 6));
          expect(overflows, isEmpty, reason: '$where: ${overflows.join('; ')}');
          if (shots != null) {
            final image = await tester.runAsync(() async {
              final object = boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
              return object.toImage();
            });
            final bytes = await tester.runAsync(
                () => image!.toByteData(format: ui.ImageByteFormat.png));
            Directory(shots).createSync(recursive: true);
            File('$shots/story_${id}_${size.width.toInt()}_'
                    '${french ? 'fr' : 'en'}.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
          }
        }
      }
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
