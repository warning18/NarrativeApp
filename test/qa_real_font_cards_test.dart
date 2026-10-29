// QA: the dice loadout's face tiles and the camp town's cards at phone widths,
// measured with the app's own fonts (see qa_real_font_layout_test.dart: the
// test font is far wider, so only the bundled fonts tell the truth). Checks no
// overflow, and that the six face tiles of a die are one size whatever they
// carry (an attack, a long French skill name, a locked or an over-limit face).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/dice_loadout_screen.dart';
import 'package:narrative_data_app/widgets/camp_town_section.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

List<String> _collectOverflows(WidgetTester tester) {
  final seen = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) {
      seen.add(details.exceptionAsString().split('\n').first);
    } else {
      previous?.call(details);
    }
  };
  addTearDown(() => FlutterError.onError = previous);
  return seen;
}

const _sizes = [Size(360, 740), Size(320, 568)];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
    // Read the data once, outside any test's fake clock: the bundle keeps the
    // first read, and one begun inside a test never finishes for the next.
    for (final schema in [
      diceSchema,
      skillsSchema,
      // The camp town's list (camp_works_provider.dart).
      housesSchema,
      zonesSchema,
      shopsSchema,
      itemsSchema,
      companionsSchema,
      chaptersSchema,
    ]) {
      await rootBundle.loadString(schema.assetPath);
    }
  });

  final campCases = <(String, Size, bool)>[];
  for (final size in _sizes) {
    for (final french in [false, true]) {
      final label = '${size.width.toInt()} px ${french ? 'French' : 'English'}';

      testWidgets('dice loadout: the face tiles are one size, $label',
          (tester) async {
        final overflows = _collectOverflows(tester);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
                const MethodChannel('flutter_tts'), (call) async => 1);
        SharedPreferences.setMockInitialValues(
            {if (french) 'app_language': 'fr'});
        // Tall, so the whole list is built: the width is what is measured.
        tester.view.physicalSize = Size(size.width, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final container = ProviderContainer();
        addTearDown(container.dispose);
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(ColorScheme.fromSeed(
                seedColor: Colors.amber, brightness: Brightness.dark)),
            home: const DiceLoadoutScreen(),
          ),
        ));
        await settleApp(tester);
        // Faces: a plain one, three picks of a skill (the third is past its
        // limit), a locked-by-limit one, and a long-named skill.
        await tester.runAsync(() => container
            .read(playerSessionProvider.notifier)
            .loadSession(PlayerSession.fromJson({
              'raceId': 'dwarf',
              'professionId': 'warrior',
              'ownedDiceIds': ['starter_die'],
              'equippedDiceId': 'starter_die',
              'unlockedSkillIds': [
                'warrior_shield_bash',
                'dwarf_stoneskin',
                'final_stand',
              ],
              'diceSkillAssignments': {
                'starter_die': {
                  '0': 'warrior_shield_bash',
                  '1': 'final_stand',
                  '4': 'warrior_shield_bash',
                  '5': 'warrior_shield_bash',
                },
              },
            })));
        await settleApp(tester);
        await settleApp(tester);

        // Each face in turn is the picked one: the tile keeps its size.
        final sizes = <int, Set<Size>>{};
        for (var pick = 0; pick < 6; pick++) {
          final slot = find.byKey(Key('face_slot_$pick'));
          if (slot.evaluate().isEmpty) continue;
          await tester.ensureVisible(slot);
          await tester.tap(slot, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 300));
          for (var i = 0; i < 6; i++) {
            final s = find.byKey(Key('face_slot_$i'));
            if (s.evaluate().isEmpty) continue;
            sizes.putIfAbsent(i, () => {}).add(tester.getSize(s));
          }
        }
        expect(sizes, isNotEmpty);
        final all = {for (final s in sizes.values) ...s};
        expect(all.length, 1,
            reason: 'face tiles differ in size: $sizes ($label)');
        expect(overflows, isEmpty, reason: overflows.toSet().join('\n'));
      });

      campCases.add((label, size, french));
    }
  }
  // After the loadout cases: a camp case run first leaves the loadout's
  // data unloaded for the cases behind it.
  for (final (label, size, french) in campCases) {
    {
      testWidgets('camp town: the cards fit, $label', (tester) async {
        final overflows = _collectOverflows(tester);
        SharedPreferences.setMockInitialValues(
            {if (french) 'app_language': 'fr'});
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final houses =
            json.decode(File('assets/gamedata/houses.json').readAsStringSync())
                as Map<String, dynamic>;

        await tester.pumpWidget(ProviderScope(
          child: MaterialApp(
            theme: buildAppTheme(ColorScheme.fromSeed(
                seedColor: Colors.amber, brightness: Brightness.dark)),
            home: Scaffold(
              body: SingleChildScrollView(
                child: CampTownSection(
                  houses: houses,
                  shops: const {},
                  zones: const {},
                  achievements: const {},
                ),
              ),
            ),
          ),
        ));
        final container = ProviderScope.containerOf(
            tester.element(find.byType(CampTownSection)));
        await tester.runAsync(() => container
            .read(playerSessionProvider.notifier)
            .loadSession(PlayerSession.fromJson(
                {'gold': 400, 'builtHouseIds': <String>[]})));
        await settleApp(tester);

        // Every card of both trays, scrolled into view: a house (built,
        // buildable, locked or too dear) and an addition.
        for (final tab in ['town_tab_houses', 'town_tab_additions']) {
          await tester.ensureVisible(find.byKey(Key(tab)));
          await tester.pump();
          await tester.tap(find.byKey(Key(tab)));
          await tester.pump(const Duration(milliseconds: 300));
          final cards = find.byWidgetPredicate((w) =>
              w.key is ValueKey<String> &&
              (w.key as ValueKey<String>).value.startsWith('town_card_'));
          final n = cards.evaluate().length;
          expect(n, greaterThan(0), reason: tab);
          for (var i = 0; i < n; i++) {
            final card = cards.at(i);
            await tester.ensureVisible(card);
            await tester.pump();
          }
          // The additions are a vertical list now (v1.350), like the
          // houses: cards differ in height with what they say, so only
          // the overflow check below holds.
        }
        expect(overflows, isEmpty, reason: overflows.toSet().join('\n'));
      });
    }
  }

  // The user's own die: the Apprentice Die with a locked Mana face, open
  // Attack and Defend faces and three skills on its skill faces. UX's
  // fix-pack should make the picked face's card hold one height.
  // Both fail on main today (card heights 154 to 210 px as faces are picked;
  // "Storehouse", "Watchtower", "Smugglers'" wider than their line). Turn
  // them on (set to false) when UX's fix-pack PR merges.
  const skipUntilFixPack = false;
  for (final size in _sizes) {
    for (final french in [false, true]) {
      final label = '${size.width.toInt()} px ${french ? 'French' : 'English'}';
      testWidgets(
          'dice loadout: the picked face\'s card keeps its height, '
          '$label', (tester) async {
        final overflows = _collectOverflows(tester);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
                const MethodChannel('flutter_tts'), (call) async => 1);
        SharedPreferences.setMockInitialValues(
            {if (french) 'app_language': 'fr'});
        tester.view.physicalSize = Size(size.width, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildAppTheme(ColorScheme.fromSeed(
                seedColor: Colors.amber, brightness: Brightness.dark)),
            home: const DiceLoadoutScreen(),
          ),
        ));
        await settleApp(tester);
        await tester.runAsync(() => container
            .read(playerSessionProvider.notifier)
            .loadSession(PlayerSession.fromJson({
              'raceId': 'human',
              'professionId': 'cleric',
              'ownedDiceIds': ['apprentice_die'],
              'equippedDiceId': 'apprentice_die',
              'unlockedSkillIds': [
                'cleric_prayer',
                'cleric_holy_light',
                'orc_berserk_rage',
              ],
              'diceSkillAssignments': {
                'apprentice_die': {
                  '1': 'cleric_prayer',
                  '4': 'cleric_holy_light',
                  '5': 'orc_berserk_rage',
                },
              },
            })));
        await settleApp(tester);
        final heights = <int, double>{};
        final tiles = <int, Size>{};
        for (var pick = 0; pick < 6; pick++) {
          final slot = find.byKey(Key('face_slot_$pick'));
          expect(slot, findsOneWidget, reason: 'face $pick');
          await tester.tap(slot, warnIfMissed: false);
          await tester.pump(const Duration(milliseconds: 300));
          // The card is the row that holds the cube and the face's text.
          final card = find
              .ancestor(
                  of: find.byKey(const Key('die_face_name')),
                  matching: find.byType(Row))
              .first;
          heights[pick] = tester.getSize(card).height;
          tiles[pick] = tester.getSize(slot);
        }
        expect(tiles.values.toSet().length, 1, reason: 'tiles $tiles');
        expect(heights.values.toSet().length, 1,
            reason: 'the card changes height with the face: $heights');
        expect(overflows, isEmpty, reason: overflows.toSet().join('\n'));
      }, skip: skipUntilFixPack);

      for (final state in const ['bare', 'rich', 'built']) {
        testWidgets(
            'camp town: no house title breaks inside a word, $label, $state',
            (tester) async {
          SharedPreferences.setMockInitialValues(
              {if (french) 'app_language': 'fr'});
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final houses = json.decode(
                  File('assets/gamedata/houses.json').readAsStringSync())
              as Map<String, dynamic>;
          await tester.pumpWidget(ProviderScope(
            child: MaterialApp(
              theme: buildAppTheme(ColorScheme.fromSeed(
                  seedColor: Colors.amber, brightness: Brightness.dark)),
              home: Scaffold(
                body: SingleChildScrollView(
                  child: CampTownSection(
                    houses: houses,
                    shops: const {},
                    zones: const {},
                    achievements: const {},
                  ),
                ),
              ),
            ),
          ));
          if (state != 'bare') {
            // Rich and unlocked, then some built: the cards in the states a
            // player meets them in (a button, a status chip, a built mark).
            final container = ProviderScope.containerOf(
                tester.element(find.byType(CampTownSection)));
            await tester.runAsync(() => container
                .read(playerSessionProvider.notifier)
                .loadSession(PlayerSession.fromJson({
                  'gold': 9000,
                  'enemyKillCounts': <String, int>{},
                  'flags': [
                    'scaffold_yards_cleared',
                    'cinder_row_cleared',
                    'banner_second_piece_lead',
                    'ossuary_galleries_cleared',
                    'dead_heart_cleared',
                  ],
                  if (state == 'built')
                    'builtHouseIds': [
                      'keldas_hall',
                      'hammersmith',
                      'academy',
                      'harbor',
                    ],
                })));
          }
          await settleApp(tester);
          final broken = <String>[];
          for (final tab in ['town_tab_houses', 'town_tab_additions']) {
            await tester.tap(find.byKey(Key(tab)));
            await tester.pump(const Duration(milliseconds: 300));
            final cards = find.byWidgetPredicate((w) =>
                w.key is ValueKey<String> &&
                (w.key as ValueKey<String>).value.startsWith('town_card_'));
            for (var i = 0; i < cards.evaluate().length; i++) {
              final card = cards.at(i);
              await tester.ensureVisible(card);
              await tester.pump();
              // Every Text of the card: each word must fit the line it has.
              for (final p in find
                  .descendant(of: card, matching: find.byType(RichText))
                  .evaluate()
                  .map((e) => e.renderObject)
                  .whereType<RenderParagraph>()) {
                final span = p.text;
                final style = span.style;
                final text = span.toPlainText();
                for (final word in text.split(RegExp(r'\s+'))) {
                  if (word.length < 6) continue;
                  final painter = TextPainter(
                      text: TextSpan(text: word, style: style),
                      textDirection: TextDirection.ltr,
                      textScaler: p.textScaler)
                    ..layout();
                  if (painter.width > p.size.width + 0.5) {
                    broken.add('"$word" needs ${painter.width.round()} px in '
                        '${p.size.width.round()} px');
                  }
                }
              }
            }
          }
          expect(broken, isEmpty, reason: broken.toSet().join('\n'));
        }, skip: skipUntilFixPack);
      }
    }
  }
}
