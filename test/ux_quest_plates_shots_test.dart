// The Quests section on the real app (UX_SHOTS=<folder>): each quest on a
// nameplate in its clan's colour, the followed one outlined. Dark and light at
// 360 wide. Drawn only with UX_SHOTS.
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
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';

import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('the quest plates', skip: shots == null, (tester) async {
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
      usePhone(tester, const Size(360, 1500));
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
            'activeQuestIds': [
              'q_ch2_dockside_debts',
              'q_ch2_keldas_stand',
              'q_ch2_terns_toll',
            ],
            'completedQuestIds': ['q_ch2_harbor_reckoning'],
          })));
      await tester.runAsync(() =>
          container.read(appModeProvider.notifier).setMode(AppMode.inGame));
      await settleApp(tester);
      container.read(storyPlayProvider.notifier).jumpTo('3005');
      await settleApp(tester);
      if (find.byKey(const Key('menu_continue')).evaluate().isNotEmpty) {
        await tester.tap(find.byKey(const Key('menu_continue')));
        await settleApp(tester);
      }
      for (var k = 0; k < 4; k++) {
        final more = find.text('Continue');
        if (more.evaluate().isEmpty) break;
        await tester.tap(more.first);
        await settleApp(tester);
      }
      container.read(homeTabIndexProvider.notifier).state = 3;
      await settleApp(tester);
      for (var k = 0; k < 8; k++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await settleApp(tester);
      final plate = find.byKey(const ValueKey('quest_plate_q_ch2_terns_toll'));
      // The header row only: the middle of an open tile is a quest card.
      final header = tester.getTopLeft(find.byType(ExpansionTile).first) +
          const Offset(60, 30);
      for (var k = 0; k < 3 && plate.evaluate().isEmpty; k++) {
        await tester.tapAt(header);
        await tester.pump(const Duration(seconds: 2));
      }
      expect(plate, findsOneWidget);
      for (var k = 0; k < 10; k++) {
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
      // The list at rest: no dialog over it.
      if (find.text('Cancel').evaluate().isNotEmpty) {
        await tester.tap(find.text('Cancel'));
        await settleApp(tester);
      }
      expect(find.text('Cancel'), findsNothing);
      await save('quests');
      // Turning Tern's Toll in asks how it is settled: the choices weigh.
      await tester
          .tap(find.descendant(of: plate, matching: find.text('Complete')));
      await settleApp(tester);
      await save('quests-turn-in');
    }
  });
}
