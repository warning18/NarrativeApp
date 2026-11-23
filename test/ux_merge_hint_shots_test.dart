// "A merge is ready" on the real app (UX_SHOTS=<folder>): the plate at the top
// of the Skills screen with the Skillwright built and not built, dark, light
// and French at 360 wide, and the dot on the Camp tab. Drawn only with
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
import 'package:narrative_data_app/data/camp_state.dart' show CampPresence;
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/camp_presence_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/skills/skills_screen.dart';

import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('the merge hint', skip: shots == null, (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    await tester.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    for (final (dark, fr, built) in [
      (true, false, true),
      (false, false, true),
      (true, false, false),
      (false, false, false),
      (false, true, true),
      (false, true, false),
    ]) {
      SharedPreferences.setMockInitialValues({
        'app_theme_mode': dark ? 'dark' : 'light',
        'tutorial_enabled': false,
      });
      usePhone(tester, const Size(360, 900));
      final boundary = GlobalKey();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(ProviderScope(overrides: [
        // At the camp, so the Camp tab can wear its dot.
        campPresenceProvider.overrideWith((ref) => CampPresence.atCamp),
      ], child: RepaintBoundary(key: boundary, child: const MyApp())));
      await settleApp(tester);
      await tester.tap(find.byKey(const Key('menu_edit_mode')));
      await settleApp(tester);
      final container =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      await tester.runAsync(() => container
          .read(appLanguageProvider.notifier)
          .setLanguage(fr ? AppLanguage.fr : AppLanguage.en));
      await tester.runAsync(() => container
          .read(playerSessionProvider.notifier)
          .loadSession(PlayerSession.fromJson({
            'raceId': 'human',
            'professionId': 'warrior',
            'level': 8,
            'characterName': 'Edda Voss',
            'gold': 520,
            'flags': ['feat_skills', 'feat_inventory'],
            'unlockedSkillIds': ['fireball', 'shadow_step', 'heavy_attack'],
            if (built) 'builtHouseIds': ['skillwright'],
          })));
      await tester.runAsync(() =>
          container.read(appModeProvider.notifier).setMode(AppMode.inGame));
      await settleApp(tester);
      container.read(storyPlayProvider.notifier).jumpTo('100');
      await settleApp(tester);
      final theme = '${dark ? 'dark' : 'light'}${fr ? '-fr' : ''}';
      Future<void> save(String name) => tester.runAsync(() async {
            final render = boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
            final image = await render.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            File('$shots/$name-$theme.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
          });
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(MaterialPageRoute<void>(
          builder: (_) => const SkillsScreen(initialTab: 1)));
      await settleApp(tester);
      for (var k = 0; k < 16; k++) {
        await tester.pump(const Duration(seconds: 1));
      }
      for (var k = 0; k < 3; k++) {
        final buttons = find.descendant(
            of: find.byType(AlertDialog), matching: find.byType(FilledButton));
        if (buttons.evaluate().isEmpty) break;
        await tester.tap(buttons.last);
        await settleApp(tester);
        await tester.pump(const Duration(seconds: 2));
      }
      await save(built ? 'skills-built' : 'skills-unbuilt');
      // The camp's side of it: the dot on the Camp tab, at the camp.
      if (!fr && !built) {
        navigator.pop();
        await settleApp(tester);
        for (var k = 0; k < 8; k++) {
          await tester.pump(const Duration(seconds: 1));
        }
        await save('camp-dot');
      }
    }
  });
}
