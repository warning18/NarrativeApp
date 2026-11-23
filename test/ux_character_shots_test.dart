// The character screen on the real app (UX_SHOTS=<folder>): the Now page and the Scenes
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
import 'package:narrative_data_app/providers/home_tab_provider.dart';

import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('the character screen', skip: shots == null, (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    await tester.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    for (final (dark, fr) in [(true, false), (false, false), (false, true)]) {
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
          .setLanguage(fr ? AppLanguage.fr : AppLanguage.en));
      await tester.runAsync(() => container
          .read(playerSessionProvider.notifier)
          .loadSession(PlayerSession.fromJson(const {
            'raceId': 'human',
            'professionId': 'warrior',
            'level': 8,
            'characterName': 'Edda Voss',
            'gold': 340,
            'currentXP': 410,
            'strength': 14,
            'dexterity': 11,
            'constitution': 13,
            'intelligence': 8,
            'wisdom': 9,
            'perception': 12,
            'luck': 7,
            'charisma': 10,
            'currentHealth': 41,
            'maxHealth': 52,
            'unlockedSkillIds': ['heavy_attack', 'shield_bash'],
            'inventoryItemIds': [
              'sword_t6',
              'armor_leather',
              'helm_iron_cap',
              'boots_iron_shod'
            ],
            'equippedItemIds': [
              'sword_t6',
              'armor_leather',
              'helm_iron_cap',
              'boots_iron_shod'
            ],
          })));
      await tester.runAsync(() =>
          container.read(appModeProvider.notifier).setMode(AppMode.inGame));
      await settleApp(tester);
      container.read(storyPlayProvider.notifier).jumpTo('100');
      await settleApp(tester);
      container.read(homeTabIndexProvider.notifier).state = 1;
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
      await save('character');
      for (final (key, name) in const [
        ('character_view_detail', 'detail'),
        ('character_view_skills', 'skills'),
      ]) {
        final seg = find.byKey(Key(key));
        if (seg.evaluate().isEmpty) continue;
        await tester.tap(seg);
        await settleApp(tester);
        await tester.pump(const Duration(seconds: 1));
        await save('character-$name');
      }
    }
  });
}
