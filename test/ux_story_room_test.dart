// The story text keeps room on a small phone (QA's L3 finding): with the
// app's own fonts, at 320 x 568 and 360 x 740, a scene with choices leaves the
// story text a window of at least about four lines (the companion strip folds
// away and the choices scroll before the text gives up its room).
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
import 'package:narrative_data_app/screens/story_player_screen.dart'
    show storyTextMinHeight;
import 'support/fonts.dart';

/// The first settle of a test waits for the game data to load; the later
/// ones only let the screen catch up.
final _warmed = Expando<bool>();

Future<void> _settle(WidgetTester tester) async {
  final first = _warmed[tester] == null;
  _warmed[tester] = true;
  for (var i = 0; i < (first ? 6 : 3); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(Duration(milliseconds: first ? 200 : 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _scenes = ['800', '7005', '6002', '100'];

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final boundary = GlobalKey();
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  testWidgets('the story text keeps about four lines on a small phone',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(360, 740);
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
        await tester.runAsync(() => container
            .read(appLanguageProvider.notifier)
            .setLanguage(french ? AppLanguage.fr : AppLanguage.en));
        for (final id in _scenes) {
          final where =
              '$id at ${size.width.toInt()} px ${french ? 'FR' : 'EN'}';
          expect(story.nodeFor(id), isNotNull);
          container.read(storyPlayProvider.notifier).jumpTo(id);
          await _settle(tester);
          final dialogButton = find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(FilledButton));
          if (dialogButton.evaluate().isNotEmpty) {
            await tester.tap(dialogButton.first, warnIfMissed: false);
            await _settle(tester);
          }
          await tester.pump(const Duration(seconds: 6));
          await _settle(tester);
          final text = find.byKey(ValueKey('${id}_false_text'));
          if (text.evaluate().isEmpty) continue;
          final height = tester.getSize(text).height;
          // Four lines of the prose and the card's padding.
          expect(height, greaterThanOrEqualTo(storyTextMinHeight - 1),
              reason: where);
          if (shots != null && size.width == 320 && !french && id == '800') {
            await tester.runAsync(() async {
              final b = tester
                  .renderObject<RenderRepaintBoundary>(find.byKey(boundary));
              final img = await b.toImage(pixelRatio: 2);
              final data = await img.toByteData(format: ui.ImageByteFormat.png);
              File('$shots/story-room-320.png')
                  .writeAsBytesSync(data!.buffer.asUint8List());
            });
          }
        }
      }
    }
  });
}
