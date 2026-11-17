// The audit of the story side (UX_SHOTS=<folder>): today's real screens at 360
// wide, dark, English: the main menu, the story scene with its choices, the
// Journey, an NPC, the chapter title, the journal and quests, the character
// sheet, the inventory, the clans, the map and the settings. Mock only: it
// draws the real app and nothing else; drawn only with UX_SHOTS.
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
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/inventory_screen.dart';
import 'package:narrative_data_app/screens/journal_screen.dart';
import 'package:narrative_data_app/screens/npc_detail_screen.dart';

import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];

  testWidgets('the audit', skip: shots == null, (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    await tester.runAsync(loadAppFonts);
    final dark = Platform.environment['UX_LIGHT'] == null;
    SharedPreferences.setMockInitialValues({
      if (dark) 'app_theme_mode': 'dark' else 'app_theme_mode': 'light',
      'tutorial_enabled': false,
    });
    final size = Size(double.parse(Platform.environment['UX_W'] ?? '360'),
        double.parse(Platform.environment['UX_H'] ?? '780'));
    usePhone(tester, size);
    Directory(shots!).createSync(recursive: true);
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

    // The main menu, before the game opens.
    await tester.pumpWidget(ProviderScope(
        child: RepaintBoundary(key: boundary, child: const MyApp())));
    await settleApp(tester);
    await shot('01-menu');
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await settleApp(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));

    final quests =
        (jsonDecode(File('assets/gamedata/quests.json').readAsStringSync())
                as Map<String, dynamic>)
            .keys
            .toList();
    final npcs =
        jsonDecode(File('assets/gamedata/npcs.json').readAsStringSync())
            as Map<String, dynamic>;
    // The game, open on the Journey, a hero a few chapters in.
    final c2 = await _open(tester, container, {
      'raceId': 'human',
      'professionId': 'warrior',
      'level': 8,
      'gold': 340,
      'currentXP': 120,
      'activeQuestIds': quests.sublist(2, 6),
      'completedQuestIds': quests.sublist(0, 2),
      'unlockedQuestIds': quests.sublist(0, 8),
      'seenQuestIds': quests.sublist(0, 8),
      'trackedQuestId': quests[3],
      'inventoryItemIds': [
        'sword_t4',
        'shield_t4',
        'potion_minor',
        'potion_minor',
        'sword_t6',
      ],
      'equippedItemIds': ['sword_t4', 'shield_t4'],
      'seenNpcIds': ['lysa', 'renn', 'aurel_vane', 'cassian_oriel'],
    });
    final play = c2.read(storyPlayProvider.notifier);

    // A quest the scene completes shows its reward card: closed first.
    Future<void> dismissCards() async {
      for (var i = 0; i < 6; i++) {
        final cont = find.text('Continue');
        if (cont.evaluate().isEmpty) break;
        await tester.tap(cont.first, warnIfMissed: false);
        await settleApp(tester);
        await tester.pump(const Duration(seconds: 1));
      }
    }

    Future<void> openScene(String node) async {
      play.jumpTo(node);
      await settleApp(tester);
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await dismissCards();
    }

    NavigatorState nav() =>
        tester.state<NavigatorState>(find.byType(Navigator).first);
    // One page pushed over the game, one pop: the game itself stays.
    Future<void> back() async {
      nav().pop();
      await settleApp(tester);
      await tester.pump(const Duration(milliseconds: 500));
    }

    // The Journey, and the scene read as a page.
    await openScene('2010');
    await shot('02-journey');
    final read = find.byKey(const ValueKey('journey_read'));
    if (read.evaluate().isNotEmpty) {
      (tester.widget(read.first) as dynamic).onPressed();
      await settleApp(tester);
      await tester.pump(const Duration(seconds: 2));
      await dismissCards();
      await shot('03-scene');
      final exit = find.byKey(const ValueKey('journey_reading_exit'));
      if (exit.evaluate().isNotEmpty) {
        await tester.tap(exit.first);
        await settleApp(tester);
        await tester.pump(const Duration(seconds: 1));
      }
    }

    // An NPC with a face.
    nav().push(MaterialPageRoute<void>(
        builder: (_) => NpcDetailScreen(
            npcId: 'aurel_vane',
            npc: Map<String, dynamic>.from(npcs['aurel_vane'] as Map))));
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 1));
    await shot('04-npc');
    await back();

    // The journal and its quests.
    nav().push(MaterialPageRoute<void>(builder: (_) => const JournalScreen()));
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 1));
    await shot('05-journal');
    await back();
    c2.read(homeTabIndexProvider.notifier).state = 3;
    await settleApp(tester);
    await shot('06-other');

    // The character sheet and the inventory.
    c2.read(homeTabIndexProvider.notifier).state = 1;
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 1));
    await shot('07-character');
    nav()
        .push(MaterialPageRoute<void>(builder: (_) => const InventoryScreen()));
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 1));
    await shot('08-inventory');
    await back();

    // The clans, the map, the settings (from the app bar's buttons).
    c2.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await settleApp(tester);
    for (final (key, name) in [
      ('home_clans_politics', '09-clans'),
      ('home_full_map', '10-map'),
    ]) {
      final button = find.byKey(Key(key));
      if (button.evaluate().isEmpty) continue;
      await tester.tap(button.first);
      await settleApp(tester);
      await tester.pump(const Duration(seconds: 2));
      await shot(name);
      await back();
    }
    await tester.tap(find.byIcon(Icons.settings).first);
    await settleApp(tester);
    await shot('11-settings');
  });
}

Future<ProviderContainer> _open(WidgetTester tester,
    ProviderContainer container, Map<String, dynamic> session) async {
  // The app already stands on its first screen (Edit Mode pressed): the
  // language, the session and the mode are set directly.
  await tester.runAsync(() =>
      container.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en));
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .loadSession(PlayerSession.fromJson(session)));
  await tester.runAsync(
      () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
  await settleApp(tester);
  return container;
}
