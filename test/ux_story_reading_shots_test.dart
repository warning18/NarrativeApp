// The reading screens on the real app (UX_SHOTS=<folder>): the story scene with a
// plain, a weighty and a major choice (the Saltmouth market, the Reliquary
// tribunal, Beyond the tear), the scene read as a page, and an NPC, with the
// deep frames, dark and light at 360 wide. Drawn only with UX_SHOTS.
import 'dart:convert';
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
import 'package:narrative_data_app/screens/npc_detail_screen.dart';

import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('the reading screens', skip: shots == null, (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    await tester.runAsync(loadAppFonts);
    final npcs =
        jsonDecode(File('assets/gamedata/npcs.json').readAsStringSync())
            as Map<String, dynamic>;
    Directory(shots!).createSync(recursive: true);
    for (final dark in [true, false]) {
      SharedPreferences.setMockInitialValues({
        'app_theme_mode': dark ? 'dark' : 'light',
        'tutorial_enabled': false,
      });
      usePhone(tester, const Size(360, 780));
      final suffix = dark ? 'dark' : 'light';
      final boundary = GlobalKey();
      Future<void> shot(String name) async {
        await tester.pump(const Duration(milliseconds: 400));
        final bytes = await tester.runAsync(() async {
          final object = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await object.toImage(pixelRatio: 1.5);
          return image.toByteData(format: ui.ImageByteFormat.png);
        });
        File('$shots/$name-$suffix.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      }

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
      final play = container.read(storyPlayProvider.notifier);
      NavigatorState nav() =>
          tester.state<NavigatorState>(find.byType(Navigator).first);

      for (final (name, node) in const [
        ('market', '2010'),
      ]) {
        play.jumpTo(node);
        await settleApp(tester);
        for (var i = 0; i < 170; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await shot('$name-journey');
        // A hub: a ring tapped opens its sheet of cards.
        for (final ring in const ['talkDecide', 'go', 'fight', 'checksPay']) {
          final chip = find.byKey(ValueKey('choice_ring_chip_$ring'));
          if (chip.evaluate().isEmpty) continue;
          await tester.tap(chip.first, warnIfMissed: false);
          await settleApp(tester);
          await tester.pump(const Duration(seconds: 1));
          await shot('$name-ring-$ring');
          nav().pop();
          await settleApp(tester);
        }
        // A pin tapped: its card comes up under the map.
        final pin = find.byKey(const ValueKey('journey_step_0'));
        if (pin.evaluate().isNotEmpty) {
          await tester.tap(pin.first, warnIfMissed: false);
          await settleApp(tester);
          await tester.pump(const Duration(seconds: 1));
          await shot('$name-picked');
        }
        final read = find.byKey(const ValueKey('journey_read'));
        if (read.evaluate().isNotEmpty) {
          (tester.widget(read.first) as dynamic).onPressed();
          await settleApp(tester);
          await tester.pump(const Duration(seconds: 2));
          // The choices stand at the foot of the page, or under Continue.
          final card0 = find.byKey(const ValueKey('journey_choice_card_0'));
          if (card0.evaluate().isNotEmpty) {
            await tester.ensureVisible(card0);
            await tester.pump(const Duration(seconds: 1));
          }
          await shot('$name-page');
          final cont = find.byKey(const ValueKey('journey_continue'));
          if (cont.evaluate().isNotEmpty && card0.evaluate().isEmpty) {
            await tester.tap(cont.first);
            await settleApp(tester);
            await tester.pump(const Duration(seconds: 3));
            if (card0.evaluate().isNotEmpty) {
              await tester.ensureVisible(card0);
              await tester.pump(const Duration(seconds: 1));
            }
            await shot('$name-cards');
          }
          final exit = find.byKey(const ValueKey('journey_reading_exit'));
          if (exit.evaluate().isNotEmpty) {
            await tester.tap(exit.first);
            await settleApp(tester);
            await tester.pump(const Duration(seconds: 1));
          }
        }
      }

      nav().push(MaterialPageRoute<void>(
          builder: (_) => NpcDetailScreen(
              npcId: 'aurel_vane',
              npc: Map<String, dynamic>.from(npcs['aurel_vane'] as Map))));
      await settleApp(tester);
      await tester.pump(const Duration(seconds: 1));
      await shot('npc');
    }
  });
}
