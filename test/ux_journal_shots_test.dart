// The journal on the real app (UX_SHOTS=<folder>): the Now page and the Scenes
// page in the quiet frames, dark and light at 360 wide. Drawn only with
// UX_SHOTS.
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
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journal_screen.dart';

import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('the journal', skip: shots == null, (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    await tester.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    for (final dark in [true, false]) {
      SharedPreferences.setMockInitialValues({
        'app_theme_mode': dark ? 'dark' : 'light',
        'tutorial_enabled': false,
      });
      usePhone(tester, const Size(360, 1100));
      final boundary = GlobalKey();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(ProviderScope(
          child: RepaintBoundary(key: boundary, child: const MyApp())));
      await settleApp(tester);
      await tester.tap(find.byKey(const Key('menu_edit_mode')));
      await settleApp(tester);
      final container =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      await tester.runAsync(() => container
          .read(appLanguageProvider.notifier)
          .setLanguage(AppLanguage.en));
      await tester.runAsync(() => container
          .read(playerSessionProvider.notifier)
          .loadSession(PlayerSession.fromJson(const {
            'raceId': 'human',
            'professionId': 'warrior',
            'level': 8,
            'characterName': 'Maren',
            'activeQuestIds': ['q_ch2_terns_toll'],
          })));
      await tester.runAsync(() =>
          container.read(appModeProvider.notifier).setMode(AppMode.inGame));
      await settleApp(tester);
      for (final id in const ['100', '105', '106', '110', '250', '260']) {
        container.read(storyPlayProvider.notifier).choose(id);
      }
      await settleApp(tester);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator
          .push(MaterialPageRoute<void>(builder: (_) => const JournalScreen()));
      await settleApp(tester);
      for (var k = 0; k < 4; k++) {
        await tester.pump(const Duration(seconds: 1));
      }
      final theme = dark ? 'dark' : 'light';
      Future<void> save(String name) => tester.runAsync(() async {
            final render = boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
            final image = await render.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            File('$shots/$name-$theme.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
          });
      await save('journal-now');
      await tester.tap(find.text('Scenes'));
      await settleApp(tester);
      await tester.pump(const Duration(seconds: 1));
      await save('journal-scenes');
    }
  });
}
