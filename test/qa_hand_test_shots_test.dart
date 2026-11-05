// QA: real pictures of the build for the user's hand test of 1.809 to 1.846
// (docs/qa/hand-test-1.846/). Drawn only with QA_SHOTS=<folder>; without it
// the file holds one empty test.
//
//   QA_SHOTS=docs/qa/hand-test-1.846 flutter test test/qa_hand_test_shots_test.dart
//
// The real app at 412 x 860, the app's own fonts and the Material icons, a
// human warrior, English. Each picture is of a scene opened as the Journey
// opens it (storyPlayProvider.jumpTo), after the map has inked in and the
// place's card and the chapter's notice are closed. A picture the file
// cannot draw is written to _unrendered.txt, with why. It never edits lib/.
//
// QA_SHOTS_ONLY=<prefix> draws only the pictures whose section name starts
// with it (e.g. 1825).
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/data/choice_flow.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/app_mode_provider.dart';
import 'package:narrative_data_app/providers/choice_flow_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/politics_provider.dart'
    show choiceHiddenFor, coastGateWorldProvider;
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'package:narrative_data_app/screens/land_crossing_screen.dart';
import 'package:narrative_data_app/screens/story_node_editor_screen.dart';
import 'package:narrative_data_app/screens/vfx_gallery_screen.dart';
import 'package:narrative_data_app/screens/skills/skills_screen.dart';
import 'package:narrative_data_app/widgets/choice_card.dart' show ChoiceCard;
import 'package:narrative_data_app/widgets/side_view/desert_kit.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart';

import 'skill_fight_harness.dart' as fh;
import 'support/fonts.dart';
import 'support/open_game.dart' show storedCityPlans;

Finder _key(String k) => find.byKey(ValueKey(k));

void main() {
  final out = Platform.environment['QA_SHOTS'];
  if (out == null || out.isEmpty) {
    test('the hand-test pictures are drawn only with QA_SHOTS', () {});
    return;
  }
  final only = Platform.environment['QA_SHOTS_ONLY'] ?? '';

  testWidgets('the hand-test pictures', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    await tester.runAsync(loadAppFonts);
    SharedPreferences.setMockInitialValues({
      'tutorial_enabled': false,
      'combat_dice_speed': 'quad',
    });
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 860);
    Directory(out).createSync(recursive: true);

    final boundary = GlobalKey();
    await tester.pumpWidget(ProviderScope(
        overrides: [storedCityPlans],
        child: RepaintBoundary(key: boundary, child: const MyApp())));
    Future<void> settle([int n = 6]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await settle();
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await settle();
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    Future<void> newSession(Map<String, dynamic> extra) async {
      await tester.runAsync(() => container
          .read(playerSessionProvider.notifier)
          .loadSession(PlayerSession.fromJson({
            'raceId': 'human',
            'professionId': 'warrior',
            ...extra,
          })));
    }

    await newSession(const {});
    await tester.runAsync(
        () => container.read(appModeProvider.notifier).setMode(AppMode.inGame));
    await settle();
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await settle();
    final play = container.read(storyPlayProvider.notifier);

    Future<void> fightSettle(WidgetTester t) => fh.settle(t);
    final unrendered = <String>[];
    final notes = <String>[];
    void note(String text) => notes.add(text);
    final table = <Map<String, Object?>>[];

    Future<void> shot(String name) async {
      await tester.pump(const Duration(milliseconds: 300));
      final bytes = await tester.runAsync(() async {
        final object = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await object.toImage();
        return image.toByteData(format: ui.ImageByteFormat.png);
      });
      File('$out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    }

    Future<void> clear() async {
      for (var i = 0; i < 3; i++) {
        // Whatever the last step opened (a fight, a sheet, a notice) is left.
        tester
            .state<NavigatorState>(find.byType(Navigator).first)
            .popUntil(isGameRoute);
        await tester.pump(const Duration(seconds: 1));
      }
    }

    Future<void> go(String id, {int ink = 6}) async {
      play.jumpTo(id);
      await settle();
      await tester.pump(Duration(seconds: ink));
      await clear();
    }

    Future<void> read() async {
      final b = _key('journey_read');
      if (b.evaluate().isNotEmpty) {
        await tester.tap(b.first);
        await settle();
        await tester.pump(const Duration(seconds: 3));
      }
    }

    /// Closes the scene's page (Back to the map), when it is the page that is
    /// up, so the map is what the picture shows.
    Future<void> toMap() async {
      for (final k in ['journey_reading_exit', 'journey_continue']) {
        final button = _key(k);
        if (_key('journey_go').evaluate().isEmpty &&
            button.evaluate().isNotEmpty) {
          await tester.tap(button.first);
          await settle();
          await tester.pump(const Duration(seconds: 2));
        }
      }
    }

    /// What the screen shows of the scene's ways: the spots, the banners, the
    /// cards, and which of the scene's choices move the party.
    Map<String, Object?> describe(String id) {
      final node = container.read(storyDataProvider).value!.nodeFor(id)!;
      final session = container.read(playerSessionProvider);
      final gate = container.read(coastGateWorldProvider);
      final stops = container.read(storyStopsProvider);
      final visible = [
        for (final c in node.choices)
          if (!choiceHiddenFor(c, session, gate)) c,
      ];
      final moves = [
        for (final c in visible)
          if (stops?.flowOf(node, c) is FlowMap) c,
      ];
      final spots = [
        for (var i = 0; i < 12; i++)
          if (_key('journey_step_$i').evaluate().isNotEmpty) i,
      ];
      final chart = find.byType(CityChartView).evaluate();
      final cv = chart.isEmpty ? null : chart.first.widget as CityChartView;
      final badge = _key('journey_open_choices').evaluate().isEmpty
          ? null
          : find
              .descendant(
                  of: _key('journey_open_choices'), matching: find.byType(Text))
              .evaluate()
              .map((e) => (e.widget as Text).data)
              .whereType<String>()
              .firstWhere((t) => int.tryParse(t) != null, orElse: () => '?');
      return {
        'scene': id,
        'choices': visible.length,
        'moves': moves.length,
        'surface': _key('journey_room').evaluate().isNotEmpty
            ? 'room'
            : _key('journey_city_chart').evaluate().isNotEmpty
                ? 'town chart'
                : _key('journey_world_map').evaluate().isNotEmpty
                    ? 'land map'
                    : _key('journey_ground').evaluate().isNotEmpty
                        ? 'ground'
                        : _key('journey_reading_exit').evaluate().isNotEmpty
                            ? 'page'
                            : '?',
        'spots': spots.length,
        'banners': cv == null ? null : cv.banners.length + cv.numbers.length,
        'cards': badge,
        'go': _key('journey_go').evaluate().isNotEmpty,
        'movesTexts': [for (final c in moves) c.text],
      };
    }

    Future<void> section(String name, Future<void> Function() body) async {
      if (only.isNotEmpty && !name.startsWith(only)) return;
      await clear();
      // Each section starts from the Journey tab, in English, in play mode.
      container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
      await tester.runAsync(() => container
          .read(appLanguageProvider.notifier)
          .setLanguage(AppLanguage.en));
      await tester.runAsync(() =>
          container.read(appModeProvider.notifier).setMode(AppMode.inGame));
      await settle();
      try {
        await body();
      } catch (e, s) {
        unrendered.add('$name: ${'$e'.split('\n').first}');
        debugPrint('SECTION $name failed: $e\n$s');
        await clear();
      }
      // A layout error the screen threw while it was drawn is a finding: it
      // goes to the notes, not to the test's failure.
      for (var e = tester.takeException();
          e != null;
          e = tester.takeException()) {
        final all = '$e';
        final overflow = RegExp(r'overflowed by [0-9.]+ pixels on the \w+')
            .allMatches(all)
            .map((m) => m.group(0))
            .toSet();
        final where = RegExp(r'[A-Za-z_/]+\.dart:\d+')
            .allMatches(all)
            .map((m) => m.group(0))
            .where((w) => w!.startsWith('lib') || w.contains('screens'))
            .toSet();
        note('$name: a layout error while drawing: '
            '${overflow.isEmpty ? all.split('\n').first : overflow.join('; ')}'
            ' (${where.join(', ')})');
      }
    }

    // ---- 1.825: rooms show their spots; towns keep banners ----
    await section('1825-rooms', () async {
      await newSession(const {
        'flags': ['casino_tables', 'casino_rescue'],
      });
      for (final id in ['100', '105', '106', '110', '120']) {
        await go(id);
        await shot('1825-blind-beggar-$id');
        table.add(describe(id));
      }
    });
    await section('1825-town-250', () async {
      await go('250');
      await shot('1825-lower-town-chart-250');
      table.add(describe('250'));
    });
    await section('1825-one-plain-way', () async {
      await go('100_dice');
      await shot('1825-one-plain-way-100_dice-map');
      table.add(describe('100_dice'));
      await read();
      await shot('1825-one-plain-way-100_dice-page');
      if (_key('journey_continue').evaluate().isNotEmpty) {
        await tester.tap(_key('journey_continue'));
        await settle();
        await tester.pump(const Duration(seconds: 2));
        await shot('1825-one-plain-way-100_dice-after-continue');
      }
    });
    await section('1825-white-wells', () async {
      await newSession(const {
        'flags': ['lysa_survived', 'vica_follow'],
      });
      await go('1200');
      await shot('1825-white-wells-1200');
      table.add(describe('1200'));
    });
    await section('1825-district-walk', () async {
      await newSession(const {});
      await go('250');
      final to = _key('journey_city_walk_alster_stone_bridge');
      if (to.evaluate().isEmpty) {
        throw StateError('no walk to the Stone Bridge on the Lower Town');
      }
      await shot('1825-district-walk-250-before');
      await tester.tap(to);
      await tester.pump(const Duration(milliseconds: 500));
      await shot('1825-district-walk-250-card');
      // The walk card's button, if one is up.
      final walk = find.byKey(const Key('city_chart_walk'));
      final goBtn = _key('journey_go');
      if (goBtn.evaluate().isNotEmpty) {
        await tester.tap(goBtn);
      } else if (walk.evaluate().isNotEmpty) {
        await tester.tap(walk);
      }
      await tester.pump(const Duration(milliseconds: 900));
      await shot('1825-district-walk-250-mid');
      for (var i = 0; i < 14; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      await settle();
      await shot('1825-district-walk-250-arrival');
    });

    // ---- 1.827: Back to the map ----
    await section('1827-back-to-map', () async {
      await newSession(const {});
      await go('100');
      await go('1101_scarred');
      await shot('1827-1101_scarred-map');
      table.add(describe('1101_scarred'));
      await read();
      await shot('1827-1101_scarred-page');
      await tester.tap(_key('journey_reading_exit'));
      await settle();
      await tester.pump(const Duration(seconds: 3));
      await shot('1827-1101_scarred-after-back-to-the-map');
      await tester.tap(_key('journey_step_0'));
      await tester.pump(const Duration(milliseconds: 800));
      await shot('1827-1101_scarred-after-one-tap-on-the-mark');
    });

    // The keys on screen with a prefix (to find what to tap).
    String keysOf(Iterable<String> prefixes) {
      final found = <String>{};
      void walk(Element e) {
        final k = e.widget.key;
        if (k is ValueKey<String> && prefixes.any(k.value.startsWith)) {
          found.add(k.value);
        }
        e.visitChildren(walk);
      }

      walk(tester.binding.rootElement!);
      return (found.toList()..sort()).join(' ');
    }

    /// Opens the scene's cards (the list behind "choices here") and takes the
    /// first one with Go, as a player does; the pictures are before, the list
    /// and after.
    Future<void> takeFirstCard(String name) async {
      await shot('$name-1-before');
      if (_key('journey_open_choices').evaluate().isNotEmpty) {
        await tester.tap(_key('journey_open_choices'));
        await tester.pump(const Duration(milliseconds: 700));
        await shot('$name-2-cards');
      } else {
        await read();
        await shot('$name-2-page');
      }
      if (find.byType(ChoiceCard).evaluate().isEmpty) {
        // A hub keeps its cards behind chips, one list for each.
        final chip = find.byWidgetPredicate((w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('choice_chip_'));
        if (chip.evaluate().isNotEmpty) {
          await tester.tap(chip.first);
          await tester.pump(const Duration(milliseconds: 700));
          await shot('$name-2b-chip-list');
        }
      }
      if (find.byType(ChoiceCard).evaluate().isEmpty) {
        note('$name: the scene has no card to take (its way is a mark or Go)');
        return;
      }
      final card = find.byType(ChoiceCard).first;
      await tester.tap(card);
      await tester.pump(const Duration(milliseconds: 400));
      final goBtn = _key('journey_go');
      if (goBtn.evaluate().isNotEmpty) await tester.tap(goBtn);
      await tester.pump();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      await settle();
      await shot('$name-3-after');
    }

    // ---- 1.810: the taken line and the still-here line ----
    await section('1810-landward-gate', () async {
      await newSession(const {});
      for (final id in ['2005', '2010', '2015', '2020']) {
        await go(id);
        table.add(describe(id));
        await takeFirstCard('1810-$id');
      }
    });

    // ---- 1.819: callbacks and revisits ----
    Future<void> language(AppLanguage l) => tester.runAsync(
        () => container.read(appLanguageProvider.notifier).setLanguage(l));
    List<String> callbackFlags(String id) {
      final node = container.read(storyDataProvider).value!.nodeFor(id)!;
      return [for (final c in node.flagCallbacks) c.flag];
    }

    await section('1819-callbacks', () async {
      for (final id in ['7800', '7004', '7001', '7400', '7500']) {
        // Many choices made: every flag the scene calls back is set.
        await newSession({'flags': callbackFlags(id)});
        await go(id);
        // A chapter's first scene opens under its notice: let it go.
        await tester.pump(const Duration(seconds: 10));
        await shot('1819-callbacks-$id-map');
        await read();
        await shot('1819-callbacks-$id-page');
        await clear();
      }
    });
    await section('1819-revisit', () async {
      for (final id in ['4999', '7800', '2900', '7515_rest']) {
        for (final l in [AppLanguage.en, AppLanguage.fr]) {
          await language(l);
          await newSession({'flags': callbackFlags(id)});
          await go(id);
          await go('100');
          await go(id);
          await read();
          await shot('1819-revisit-$id-${l.name}');
          await clear();
        }
      }
      await language(AppLanguage.en);
    });

    // ---- skills 1.829 to 1.844: my skills, the skill tree ----
    await section('skills', () async {
      // Every skill that has a glyph (1.829 to 1.844): the generator's list.
      final glyphSkills = RegExp('\'([a-z0-9_]+)\': \\["')
          .allMatches(File('tool/gen_skill_glyphs.py').readAsStringSync())
          .map((m) => m.group(1)!)
          .toList();
      await newSession({'level': 12, 'unlockedSkillIds': glyphSkills});
      await tester.tap(find.text('Character').last);
      await settle();
      await shot('skills-character-overview');
      // The skills screen (the Character tab's skills card opens it): its
      // tabs are my skills, the tree and the rest.
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute<void>(builder: (_) => const SkillsScreen()));
      await settle();
      await tester.pump(const Duration(seconds: 1));
      final tabs = find.byType(Tab);
      final count = tabs.evaluate().length;
      for (var i = 0; i < count; i++) {
        await tester.tap(tabs.at(i));
        await settle();
        await tester.pump(const Duration(seconds: 1));
        await shot('skills-screen-tab${i + 1}');
      }
      debugPrint('SKILLTABS $count');
      nav.popUntil(isGameRoute);
      await tester.pump(const Duration(seconds: 1));
    });

    // ---- travel: 1.815, 1.821, 1.822, 1.812, 1.826 ----
    await section('1815-land-crossing', () async {
      await newSession(const {});
      await go('100');
      await go('1101_scarred');
      await toMap();
      await shot('1815-land-crossing-0-before');
      await tester.tap(_key('journey_go'));
      await tester.pump();
      var t = 0;
      for (final at in [1, 2, 4, 7, 11]) {
        while (t < at * 2) {
          await tester.pump(const Duration(milliseconds: 500));
          t++;
        }
        await shot('1815-land-crossing-${at.toString().padLeft(2, '0')}s');
      }
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      await settle();
      await shot('1815-land-crossing-arrival');
    });
    await section('1822-camp-sea-voyage', () async {
      await newSession({'flags': callbackFlags('7001')});
      await go('7001');
      await tester.pump(const Duration(seconds: 8));
      await shot('1822-camp-road');
      await tester.ensureVisible(_key('place_7002'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(_key('place_7002'));
      await tester.pump(const Duration(milliseconds: 700));
      await shot('1822-camp-place-card');
      final goBtn =
          find.descendant(of: _key('place_7002'), matching: find.text('Go'));
      if (goBtn.evaluate().isEmpty) throw StateError('no Go on the place row');
      await tester.tap(goBtn);
      await tester.pump();
      var t = 0;
      for (final at in [1, 3, 6, 10]) {
        while (t < at * 2) {
          await tester.pump(const Duration(milliseconds: 500));
          t++;
        }
        await shot('1822-camp-sea-voyage-${at.toString().padLeft(2, '0')}s');
      }
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      await settle();
      await shot('1822-camp-sea-voyage-arrival');
      await clear();
    });
    await section('1822-camp-town-tab', () async {
      await newSession({'flags': callbackFlags('7001')});
      await go('7001');
      await tester.pump(const Duration(seconds: 8));
      await tester.fling(
          find.byType(Scrollable).first, const Offset(0, 3000), 5000);
      await settle();
      await tester.tap(_key('camp_tab_town'));
      await settle();
      await shot('1822-camp-town-tab');
      for (var i = 1; i <= 3; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -520));
        await settle();
        await shot('1822-camp-town-tab-scroll$i');
      }
      await tester.tap(_key('camp_tab_party'));
      await settle();
      await shot('1822-camp-party-tab');
      await tester.tap(_key('camp_tab_sea'));
      await settle();
      await shot('1822-camp-sea-tab');
    });

    // A crossing played on its own screen, as the Journey starts it
    // (runLandCrossing: the real road, the strip and the world camera).
    Future<void> crossing(String routeId, String name) async {
      await newSession(const {});
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute<void>(
          builder: (_) => _CrossingLauncher(routeId: routeId)));
      await settle(10);
      await tester.pump(const Duration(seconds: 2));
      await shot('$name-day1-start');
      // What the road holds is answered with its first choice; the screen
      // after each answer is a picture while a crossing is on.
      for (var step = 1; step <= 6; step++) {
        final options = find.descendant(
            of: find.byType(LandCrossingScreen),
            matching: find.byType(InkWell));
        if (options.evaluate().isEmpty) break;
        await tester.tap(options.first, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 700));
        if (find.byType(LandCrossingScreen).evaluate().isEmpty) break;
        await shot('$name-step$step-answer');
        await tester.pump(const Duration(milliseconds: 2500));
        if (find.byType(LandCrossingScreen).evaluate().isEmpty) break;
        await shot('$name-step$step-next');
      }
      await clear();
    }

    await section('1822-camp-to-quarter', () async {
      await crossing('camp_to_quarter', '1822-camp-to-quarter');
    });
    await section('1815-sleeper-to-wells', () async {
      await crossing('sleeper_to_wells', '1815-sleeper-to-wells');
    });

    // ---- fights: the aim line (1.824), the land behind the cards (1.826),
    // the board and its effects (1.814), the spoils sheet (1.831) ----
    Future<void> fight(String name,
        {Map<String, dynamic> enemyPatch = const {},
        String enemyId = 'slum_thug',
        List<SideLayer>? land,
        bool win = false,
        bool pushed = false}) async {
      final enemy = {
        ...fh.gamedata('enemies.json')[enemyId] as Map<String, dynamic>,
        'skillMoves': <dynamic>[],
        ...enemyPatch,
      };
      if (!pushed) {
        tester
            .state<NavigatorState>(find.byType(Navigator).first)
            .push(MaterialPageRoute<bool>(
                builder: (_) => FightScreen(
                      enemyId: enemyId,
                      enemy: enemy,
                      landLayers: land,
                      modifiers: const EncounterModifiers(
                          forcedCondition: BattlefieldCondition.highGround,
                          forcedGoal: FightGoal.slay),
                    )));
      }
      await fightSettle(tester);
      await shot('$name-0-prebattle');
      final enter = find.text('Enter Battle');
      if (enter.evaluate().isEmpty) throw StateError('no Enter Battle');
      await tester.ensureVisible(enter);
      await tester.pump();
      await tester.tap(enter);
      await fightSettle(tester);
      await shot('$name-1-board');
      // The button reads "Roll Dice" or "Roll Dice (2×)" with rerolls left.
      final roll = find.textContaining('Roll Dice');
      for (var i = 0; i < 40 && roll.evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(roll.first);
      await tester.pump();
      await fh.pumpUntil(tester, () => fh.shows('Confirm'));
      await fightSettle(tester);
      await shot('$name-2-rolled');
      final die = find.byWidgetPredicate((w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('die_tile_'));
      if (die.evaluate().isNotEmpty) {
        await tester.tap(die.first);
        await fightSettle(tester);
        await tester.pump(const Duration(milliseconds: 700));
        await shot('$name-3-die-picked-aim-line');
      }
      if (win) {
        await fh.tapWhenEnabled(tester, 'Confirm');
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 700));
          await shot('$name-4-after-confirm-$i');
        }
      }
      await clear();
    }

    await section('1824-fight-allies', () async {
      // A fight with Vica and Kelda beside the hero.
      await newSession({
        'level': 9,
        'ownedDiceIds': ['starter_die', 'iron_die'],
        'equippedDiceId': 'starter_die',
        'maxHealth': 60,
        'currentHealth': 60,
        'recruitedAllies': [
          {'companionId': 'vica', 'currentHealth': 1 << 30},
          {'companionId': 'kelda', 'currentHealth': 1 << 30},
        ],
        'activeAllyIds': ['vica', 'kelda'],
      });
      await fight('1824-fight-allies', enemyPatch: {'maxHealth': 900});
    });
    await section('1826-fight-on-a-crossing', () async {
      await newSession({
        'level': 9,
        'ownedDiceIds': ['starter_die'],
        'equippedDiceId': 'starter_die',
      });
      await fight('1826-fight-on-a-crossing',
          enemyPatch: {'maxHealth': 900}, land: desertLayers(progress: 0.5));
    });
    await section('1831-spoils', () async {
      await newSession({
        'level': 9,
        'ownedDiceIds': ['starter_die'],
        'equippedDiceId': 'starter_die',
      });
      await fight('1831-spoils',
          enemyPatch: {'maxHealth': 1, 'minHealth': 1}, win: true);
    });

    // ---- 1.820: Edit Mode keeps a scene's camp errand ----
    await section('1820-edit-mode-errand', () async {
      await newSession(const {});
      await tester.runAsync(
          () => container.read(appModeProvider.notifier).setMode(AppMode.edit));
      await settle();
      await go('loyal_kelda');
      await shot('1820-errand-loyal_kelda-journey-edit-mode');
      final story = container.read(storyDataProvider).value!;
      final node = story.nodeFor('loyal_kelda')!;
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(MaterialPageRoute<void>(
          builder: (_) => StoryNodeEditorScreen(node: node)));
      await settle();
      await tester.pump(const Duration(seconds: 1));
      await shot('1820-errand-loyal_kelda-editor-top');
      for (var i = 1; i <= 3; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
        await settle();
        await shot('1820-errand-loyal_kelda-editor-scroll$i');
      }
      nav.popUntil(isGameRoute);
      await tester.runAsync(() =>
          container.read(appModeProvider.notifier).setMode(AppMode.inGame));
      await settle();
    });

    // ---- 1.814: the dice, element and keyword effects, the campfire ----
    await section('1814-effects-gallery', () async {
      final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(
          MaterialPageRoute<void>(builder: (_) => const VfxGalleryScreen()));
      await settle();
      await tester.pump(const Duration(seconds: 2));
      await shot('1814-effects-gallery-1');
      for (var i = 2; i <= 4; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
        await tester.pump(const Duration(milliseconds: 600));
        await shot('1814-effects-gallery-$i');
      }
      for (final effect in ['fireball', 'lightning', 'frost']) {
        final chip = find.text(effect);
        if (chip.evaluate().isEmpty) continue;
        await tester.ensureVisible(chip.first);
        await tester.tap(chip.first);
        await tester.pump(const Duration(milliseconds: 280));
        await shot('1814-effects-gallery-play-$effect');
      }
      nav.popUntil(isGameRoute);
      await tester.pump(const Duration(seconds: 1));
    });
    await section('1814-campfire', () async {
      await newSession({'flags': callbackFlags('7001')});
      await go('7001');
      await tester.pump(const Duration(seconds: 8));
      await tester.fling(
          find.byType(Scrollable).first, const Offset(0, 3000), 5000);
      await settle();
      await shot('1814-campfire-camp');
      final rest = find.text('Rest');
      if (rest.evaluate().isNotEmpty) {
        await tester.tap(rest.first);
        await tester.pump(const Duration(milliseconds: 700));
        await shot('1814-campfire-rest-0');
        await tester.pump(const Duration(milliseconds: 1500));
        await shot('1814-campfire-rest-1');
      }
      await clear();
    });

    // ---- where a move is a pin or a banner on the map, and where a card ----
    final moveRows = <Map<String, Object?>>[];
    await section('movement-table', () async {
      const scenes = <(String, List<String>)>[
        ('106', ['casino_tables']),
        ('110', ['casino_tables']),
        ('250', []),
        ('260', []),
        ('1101_scarred', []),
        ('1140', []),
        ('1200', ['lysa_survived', 'vica_follow']),
        ('2005', []),
        ('2010', []),
        ('2015', []),
        ('2020', []),
        ('3001_camp', []),
        ('7400', ['banner_five']),
        ('7500', []),
        ('6100_clan_vigil_2', []),
      ];
      for (final (id, flags) in scenes) {
        try {
          await newSession({'flags': flags});
          await go(id);
          // A chapter's first scene opens under its notice: let it go.
          await tester.pump(const Duration(seconds: 10));
          await toMap();
          final row = describe(id);
          await shot('movement-$id');
          // The scene's cards (behind the hand badge), by their words.
          final opener = _key('journey_open_choices');
          if (opener.evaluate().isNotEmpty) {
            await tester.tap(opener);
            await tester.pump(const Duration(milliseconds: 800));
            row['cardTexts'] = [
              for (final e in find.byType(ChoiceCard).evaluate())
                find
                    .descendant(
                        of: find.byWidget(e.widget),
                        matching: find.byType(Text))
                    .evaluate()
                    .map((t) => (t.widget as Text).data ?? '')
                    .where((t) => t.isNotEmpty)
                    .first,
            ];
            await shot('movement-$id-cards');
            await clear();
          }
          moveRows.add(row);
        } catch (e) {
          unrendered.add('movement-$id: ${'$e'.split('\n').first}');
        }
      }
    });
    File('$out/_movement.json')
        .writeAsStringSync(const JsonEncoder.withIndent(' ').convert(moveRows));

    // ---- the hub and the gate as the Journey opens them (marks counted) ----
    await section('priority-hub-marks', () async {
      for (final (id, flags) in const <(String, List<String>)>[
        ('125', ['casino_rescue', 'saved_woman']),
        ('125', ['casino_rescue', 'saved_woman', 'saved_boy']),
        ('2005', []),
        ('2015', []),
      ]) {
        await newSession({'flags': flags});
        await go(id);
        await toMap();
        // The Journey keeps the level (District, Town, World) it was left on.
        final district = find.text('District');
        if (district.evaluate().isNotEmpty) {
          await tester.tap(district.first);
          // The camera flies to the district: let it land.
          await tester.pump(const Duration(seconds: 5));
        }
        final row = describe(id);
        final rows = [
          for (final e in find.byType(InkWell).evaluate())
            if ('${e.widget.key}'.contains('city_row')) 1,
        ].length;
        final steps = row['spots'];
        final tag = flags.length > 2
            ? '-price35'
            : flags.isNotEmpty
                ? '-price15'
                : '';
        await shot('priority-$id$tag-district');
        debugPrint(
            'PRIORITY $id $flags journey_step_ marks=$steps chartBanners='
            '${row['banners']} cityRows=$rows cardsBadge=${row['cards']} '
            'choices=${row['choices']} surface=${row['surface']}');
        // The same scene on the Town level, as the segmented control offers.
        final town = find.text('Town');
        if (town.evaluate().isNotEmpty) {
          await tester.tap(town.first);
          await tester.pump(const Duration(seconds: 5));
          await shot('priority-$id$tag-town');
        }
      }
    });

    // ---- the keys of the other tabs, to find what to tap ----
    if (Platform.environment['QA_SHOTS_KEYS'] != null) {
      for (final tab in ['Character', 'Camp', 'Other']) {
        await tester.tap(find.text(tab).last);
        await settle();
        debugPrint('KEYS $tab: ${keysOf([
              'character_',
              'camp_',
              'home_',
              'skill',
              'other_'
            ])}');
        await shot('keys-$tab');
      }
      await tester.tap(find.text('Journey').last);
      await settle();
    }

    File('$out/_unrendered.txt').writeAsStringSync(unrendered.join('\n'));
    File('$out/_notes.txt').writeAsStringSync(notes.join('\n'));
    File('$out/_table.json')
        .writeAsStringSync(const JsonEncoder.withIndent(' ').convert(table));
    debugPrint('UNRENDERED ${unrendered.length}: ${unrendered.join(' | ')}');
  });
}

/// Starts a land crossing on its own page, as the Journey does.
class _CrossingLauncher extends ConsumerStatefulWidget {
  const _CrossingLauncher({required this.routeId});
  final String routeId;

  @override
  ConsumerState<_CrossingLauncher> createState() => _CrossingLauncherState();
}

class _CrossingLauncherState extends ConsumerState<_CrossingLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) runLandCrossing(context, ref, widget.routeId);
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}
