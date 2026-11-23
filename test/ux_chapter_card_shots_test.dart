// The chapter card on the real app (UX_SHOTS=<folder>): the card that inks in over
// the screen when a chapter begins, with the quiet frame and the chapter's
// number, dark and light at 360 wide. Drawn only with UX_SHOTS.
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

import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('the chapter card', skip: shots == null, (tester) async {
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
      usePhone(tester, const Size(360, 780));
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
          })));
      await tester.runAsync(() =>
          container.read(appModeProvider.notifier).setMode(AppMode.inGame));
      await settleApp(tester);
      container.read(storyPlayProvider.notifier).jumpTo('7003');
      await settleApp(tester);
      // The card opens in a fifth of its time and holds, inked.
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 300));
      final bytes = await tester.runAsync(() async {
        final object = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await object.toImage(pixelRatio: 1.5);
        return image.toByteData(format: ui.ImageByteFormat.png);
      });
      File('$shots/chapter-card-${dark ? 'dark' : 'light'}.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    }
  });
}
