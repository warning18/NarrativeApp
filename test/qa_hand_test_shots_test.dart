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
import 'package:narrative_data_app/screens/skills/skills_screen.dart';
import 'package:narrative_data_app/widgets/choice_card.dart' show ChoiceCard;
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart';

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
      final exit = _key('journey_reading_exit');
      if (exit.evaluate().isNotEmpty && _key('journey_go').evaluate().isEmpty) {
        await tester.tap(exit);
        await settle();
        await tester.pump(const Duration(seconds: 2));
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
      try {
        await body();
      } catch (e, s) {
        unrendered.add('$name: ${'$e'.split('\n').first}');
        debugPrint('SECTION $name failed: $e\n$s');
        await clear();
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
      nav.popUntil((r) => r.isFirst);
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
    await section('1822-camp-crossing', () async {
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
        await shot('1822-camp-crossing-${at.toString().padLeft(2, '0')}s');
      }
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      await settle();
      await shot('1822-camp-crossing-arrival');
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
      await tester.tap(_key('camp_tab_party'));
      await settle();
      await shot('1822-camp-party-tab');
      await tester.tap(_key('camp_tab_sea'));
      await settle();
      await shot('1822-camp-sea-tab');
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
