// QA: the dice loadout's face tiles and the camp town's cards at phone widths,
// measured with the app's own fonts (see qa_real_font_layout_test.dart: the
// test font is far wider, so only the bundled fonts tell the truth). Checks no
// overflow, and that the six face tiles of a die are one size whatever they
// carry (an attack, a long French skill name, a locked or an over-limit face).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/dice_loadout_screen.dart';
import 'package:narrative_data_app/widgets/camp_town_section.dart';

Future<void> _loadFonts() async {
  const families = {
    'PixelifySans': [
      'assets/fonts/PixelifySans-Regular.ttf',
      'assets/fonts/PixelifySans-SemiBold.ttf',
    ],
    'Spectral': [
      'assets/fonts/Spectral-Regular.ttf',
      'assets/fonts/Spectral-Medium.ttf',
      'assets/fonts/Spectral-Italic.ttf',
    ],
    'IMFellEnglishSC': ['assets/fonts/IMFellEnglishSC-Regular.ttf'],
  };
  for (final family in families.entries) {
    final loader = FontLoader(family.key);
    for (final path in family.value) {
      loader.addFont(
          Future.value(ByteData.view(File(path).readAsBytesSync().buffer)));
    }
    await loader.load();
  }
}

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

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

const _sizes = [Size(360, 740), Size(320, 568)];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
    // Read the data once, outside any test's fake clock: the bundle keeps the
    // first read, and one begun inside a test never finishes for the next.
    for (final schema in [diceSchema, skillsSchema]) {
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
        await _settle(tester);
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
        await _settle(tester);
        await _settle(tester);

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
        await _settle(tester);

        // Every card of both trays, scrolled into view: a house (built,
        // buildable, locked or too dear) and an addition.
        for (final tab in ['town_tab_houses', 'town_tab_additions']) {
          await tester.tap(find.byKey(Key(tab)));
          await tester.pump(const Duration(milliseconds: 300));
          final cards = find.byWidgetPredicate((w) =>
              w.key is ValueKey<String> &&
              (w.key as ValueKey<String>).value.startsWith('town_card_'));
          final n = cards.evaluate().length;
          expect(n, greaterThan(0), reason: tab);
          final heights = <double>{};
          for (var i = 0; i < n; i++) {
            final card = cards.at(i);
            await tester.ensureVisible(card);
            await tester.pump();
            heights.add(tester.getSize(card).height);
          }
          expect(heights.length, 1,
              reason: '$tab: cards differ in height $heights ($label)');
        }
        expect(overflows, isEmpty, reason: overflows.toSet().join('\n'));
      });
    }
  }
}
