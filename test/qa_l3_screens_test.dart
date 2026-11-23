// QA, the L3's screen read-through (v1.992): the screens that changed since the
// last L3, on the REAL app with the app's own fonts, at the sizes of a phone,
// in English and French, and with the large text of the accessibility setting
// (1.3x). A picture of each, and every "overflowed" error caught, with the
// screen and the setting it came from.
//
// Inert unless QA_L3=<folder>. Variables:
//   QA_L3_CFG     the settings, "WxH:lang:scale" comma separated (default: the nine
//                 of the L3: 412x892:en:1, 360x740:en:1, 320x568:en:1, 360x740:fr:1,
//                 320x568:fr:1, 360x740:en:1.3, 320x568:en:1.3, 360x740:fr:1.3,
//                 320x568:fr:1.3)
//   QA_L3_ONLY    a comma list of screen names to draw (default all)
//   QA_L3_BUILDS  the builds file of Core's typical players (default
//                 docs/simulation/typical-player-builds.json); the hero is the
//                 7810 build's most common profession: a late hero with gear,
//                 clans, companions and merges to show
//
// Writes `<folder>/<cfg>/<screen>.png`, `<folder>/overflow.txt` (one line a
// problem) and `<folder>/_trace.txt`. It never edits lib/.
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
import 'package:narrative_data_app/screens/achievements_screen.dart';
import 'package:narrative_data_app/screens/camp_screen.dart';
import 'package:narrative_data_app/screens/character_screen.dart';
import 'package:narrative_data_app/screens/clans_politics_screen.dart';
import 'package:narrative_data_app/screens/dice_loadout_screen.dart';
import 'package:narrative_data_app/screens/inventory_screen.dart';
import 'package:narrative_data_app/screens/journal_screen.dart';
import 'package:narrative_data_app/screens/settings_screen.dart';
import 'package:narrative_data_app/screens/skills/skills_screen.dart';

import 'support/fonts.dart';
import 'support/open_game.dart' show storedCityPlans;

/// What to show: a screen pushed on the root navigator, or a story scene.
class _Shot {
  const _Shot(this.name, {this.screen, this.node});
  final String name;
  final Widget Function()? screen;
  final String? node;
}

void main() {
  final out = Platform.environment['QA_L3'];
  if (out == null || out.isEmpty) {
    test('the L3 screens are drawn only with QA_L3', () {});
    return;
  }
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  testWidgets('the L3 screens, at the sizes of a phone', (tester) async {
    final cfgText = Platform.environment['QA_L3_CFG'] ??
        '412x892:en:1,360x740:en:1,320x568:en:1,360x740:fr:1,320x568:fr:1,'
            '360x740:en:1.3,320x568:en:1.3,360x740:fr:1.3,320x568:fr:1.3';
    final only = (Platform.environment['QA_L3_ONLY'] ?? '')
        .split(',')
        .where((s) => s.isNotEmpty)
        .toSet();
    final builds = jsonDecode(File(Platform.environment['QA_L3_BUILDS'] ??
            'docs/simulation/typical-player-builds.json')
        .readAsStringSync()) as Map<String, dynamic>;
    final fight = builds['7810'] as Map<String, dynamic>;
    final build = (fight['byProfession']
            as Map<String, dynamic>)[fight['mostCommonProfession']]
        as Map<String, dynamic>;
    final save = Map<String, dynamic>.from(build['save'] as Map);
    final assigned = save['diceSkillAssignments'];
    if (assigned is Map && assigned.values.any((v) => v is! Map)) {
      save['diceSkillAssignments'] = {'${save['equippedDiceId']}': assigned};
    }

    // A fuller bag and a merge ready to craft, to show the rarity frames of the
    // worn rows and the merge plate: one item of each rarity, and the two
    // skills of the first merge with the gold to craft it.
    final items =
        jsonDecode(File('assets/gamedata/items.json').readAsStringSync())
            as Map<String, dynamic>;
    final byRarity = <String, String>{};
    for (final e in items.entries) {
      byRarity.putIfAbsent('${(e.value as Map)['rarity']}', () => e.key);
    }
    save['inventoryItemIds'] = [
      ...((save['inventoryItemIds'] as List?) ?? const []),
      ...byRarity.values,
    ];
    final merges =
        jsonDecode(File('assets/gamedata/skill_merges.json').readAsStringSync())
            as Map<String, dynamic>;
    final ingredients = [
      for (final id in ((merges.values.first as Map)['inputSkillIDs'] as List))
        '$id'
    ];
    save['unlockedSkillIds'] = {
      ...((save['unlockedSkillIds'] as List?) ?? const []).map((e) => '$e'),
      ...ingredients,
    }.toList();
    save['gold'] = 5000;

    final shots = <_Shot>[
      const _Shot('journey_3100_emberwick', node: '3100'),
      const _Shot('journey_7500_candlehold', node: '7500'),
      const _Shot('journey_2005_saltmouth', node: '2005'),
      const _Shot('journey_250_streets', node: '250'),
      _Shot('character', screen: () => const CharacterScreen()),
      _Shot('inventory', screen: () => const InventoryScreen()),
      _Shot('journal', screen: () => const JournalScreen()),
      _Shot('skills_tree', screen: () => const SkillsScreen()),
      _Shot('skills_mine', screen: () => const SkillsScreen(initialTab: 1)),
      _Shot('skills_spells', screen: () => const SkillsScreen(initialTab: 2)),
      _Shot('clans', screen: () => const ClansPoliticsScreen()),
      _Shot('camp', screen: () => const CampScreen()),
      _Shot('dice_loadout', screen: () => const DiceLoadoutScreen()),
      _Shot('achievements', screen: () => const AchievementsScreen()),
      _Shot('settings', screen: () => const SettingsScreen()),
    ];

    final overflows = <String>[];
    final trace = <String>[];
    String where = '';
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.exceptionAsString();
      if (text.contains('overflowed')) {
        overflows.add('$where: ${text.split('\n').first}');
      } else {
        trace.add('$where: ERROR ${text.split('\n').first}');
        previous?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = previous);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({
      'tutorial_enabled': false,
      'combat_dice_speed': 'quad',
    });
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    Future<void> settle([int n = 8]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 60)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    final boundary = GlobalKey();
    await tester.pumpWidget(ProviderScope(
        overrides: [storedCityPlans],
        child: RepaintBoundary(key: boundary, child: const MyApp())));
    await settle(10);
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await settle(10);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(save)));
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await settle(10);

    Future<void> picture(String cfg, String name) async {
      final bytes = await tester.runAsync(() async {
        final object = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await object.toImage();
        return image.toByteData(format: ui.ImageByteFormat.png);
      });
      final dir = Directory('$out/$cfg')..createSync(recursive: true);
      File('${dir.path}/$name.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    }

    for (final cfg in cfgText.split(',')) {
      final parts = cfg.split(':');
      final size = parts[0].split('x').map(double.parse).toList();
      final french = parts[1] == 'fr';
      final scale = double.parse(parts[2]);
      tester.view.physicalSize = Size(size[0], size[1]);
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      await tester.runAsync(() => container
          .read(appLanguageProvider.notifier)
          .setLanguage(french ? AppLanguage.fr : AppLanguage.en));
      await settle(6);
      final tag = cfg.replaceAll(':', '_');
      for (final shot in shots) {
        if (only.isNotEmpty && !only.contains(shot.name)) continue;
        where = '$tag/${shot.name}';
        try {
          final nav =
              tester.state<NavigatorState>(find.byType(Navigator).first);
          if (shot.node != null) {
            nav.popUntil((r) => r.isFirst);
            container.read(storyPlayProvider.notifier).jumpTo(shot.node!);
            await settle(14);
          } else {
            nav.push(MaterialPageRoute<void>(builder: (_) => shot.screen!()));
            await settle(12);
          }
          await picture(tag, shot.name);
          trace.add('$where: drawn');
          if (shot.node == null) {
            nav.pop();
            await settle(4);
          }
        } catch (e) {
          trace.add('$where: NOT DRAWN: ${'$e'.split('\n').first}');
          tester
              .state<NavigatorState>(find.byType(Navigator).first)
              .popUntil((r) => r.isFirst);
          await settle(3);
        }
      }
    }
    Directory(out).createSync(recursive: true);
    File('$out/overflow.txt').writeAsStringSync(
        overflows.isEmpty ? 'none\n' : '${overflows.toSet().join('\n')}\n');
    File('$out/_trace.txt').writeAsStringSync('${trace.join('\n')}\n');
  }, timeout: const Timeout(Duration(minutes: 60)));
}
