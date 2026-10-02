// The world's places on screen (v1.197), on a 360 px phone in English
// and French: the breadcrumb, the "This land" sheet, the codex's Lands,
// the Journey map's painted land in the three looks, the world map's
// panel and the node editor's place. On fixtures (see geography_test.dart).
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/clans_provider.dart';
import 'package:narrative_data_app/providers/geography_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/world_map_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/biome_backdrop.dart';
import 'package:narrative_data_app/widgets/geography_widgets.dart';

import 'geography_test.dart' show fixture, storyFixture;

const String _nb = ' ';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void _phone(WidgetTester tester, {double height = 720}) {
  tester.view.physicalSize = Size(360, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// A container with the fixture world, the real clans, and the story
/// having been to [visited] (the first where it starts).
Future<ProviderContainer> _container(
  WidgetTester tester, {
  String language = 'en',
  List<String> visited = const ['n_alley'],
}) async {
  SharedPreferences.setMockInitialValues(
      {'app_language': language, 'tutorial_enabled': false});
  final container = ProviderContainer(overrides: [
    geographyProvider.overrideWithValue(fixture()),
    clanDataProvider.overrideWithValue(
        ClanData.fromTables(factions: _json('assets/gamedata/factions.json'))),
    storyDataProvider.overrideWith((ref) async => storyFixture()),
    storyPlayProvider.overrideWith((ref) => StoryPlayNotifier(visited.first)),
  ]);
  addTearDown(container.dispose);
  container.read(appLanguageProvider);
  container.read(storyPlayProvider);
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await container.read(storyDataProvider.future);
  });
  for (final id in visited.skip(1)) {
    container.read(storyPlayProvider.notifier).jumpTo(id);
  }
  return container;
}

Widget _app(ProviderContainer container, Widget home,
        {Brightness brightness = Brightness.light}) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(ColorScheme.fromSeed(
            seedColor: const Color(0xFF8C7A57), brightness: brightness)),
        home: Scaffold(body: home),
      ),
    );

void main() {
  group('the breadcrumb', () {
    for (final french in [false, true]) {
      testWidgets(
          'fits a 360 px phone, opened on the place '
          '(${french ? 'FR' : 'EN'})', (tester) async {
        _phone(tester);
        final geo = fixture();
        final tapped = <String>[];
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: GeoBreadcrumb(
                path: geo.pathOf('lower_town'),
                french: french,
                onTap: (place) => tapped.add(place.id),
              ),
            ),
          ),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull);
        // The place itself is in view, at the line's end.
        final last =
            tester.getRect(find.byKey(const ValueKey('geo_crumb_lower_town')));
        expect(last.left, greaterThanOrEqualTo(16));
        expect(last.right, lessThanOrEqualTo(344 + 0.5));
        expect(find.text(french ? 'la Basse-Ville' : 'The Lower Town'),
            findsOneWidget);
        // The first crumb opens a line, so it starts with a capital.
        expect(find.text(french ? 'The Old Land' : 'The Old Land'),
            findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('geo_crumb_lower_town')));
        await tester.tap(find.byKey(const ValueKey('geo_crumb_alster')));
        expect(tapped, ['lower_town', 'alster']);
        // The wider lands are a swipe away.
        await tester.drag(
            find.byType(SingleChildScrollView), const Offset(400, 0));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('geo_crumb_old')));
        expect(tapped.last, 'old');
      });
    }
  });

  group('This land', () {
    for (final french in [false, true]) {
      testWidgets(
          'the zone, its biome, its country and ruler, at 360 px '
          '(${french ? 'FR' : 'EN'})', (tester) async {
        _phone(tester, height: 640);
        final container =
            await _container(tester, language: french ? 'fr' : 'en');
        await tester.pumpWidget(_app(
          container,
          Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showThisLand(context, 'lower_town'),
                child: const Text('open'),
              ),
            ),
          ),
        ));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final sheet = find.byKey(const ValueKey('this_land_sheet'));
        expect(sheet, findsOneWidget);
        Finder inSheet(String text) =>
            find.descendant(of: sheet, matching: find.text(text));
        expect(inSheet(french ? 'CETTE CONTRÉE' : 'THIS LAND'), findsOneWidget);
        expect(inSheet('The Vale'), findsOneWidget);
        expect(
            inSheet(french ? 'Temperate (fr)' : 'Temperate'), findsOneWidget);
        // The district tapped, and the city it is a quarter of.
        expect(inSheet('Alster'), findsOneWidget);
        expect(inSheet(french ? 'La Basse-Ville' : 'The Lower Town'),
            findsOneWidget);
        expect(inSheet('Temperate beast 0'), findsOneWidget);
        expect(inSheet(french ? 'FAUNE' : 'FAUNA'), findsOneWidget);
        // Further down: the weather, the hazards, the country and its
        // ruler, the continent.
        await tester.dragUntilVisible(
            find.byKey(const ValueKey('this_land_ruler')),
            sheet,
            const Offset(0, -200));
        expect(inSheet(french ? 'Les Marches' : 'The Marches'), findsOneWidget);
        expect(
            inSheet(french
                ? 'Autorité$_nb: Le Dominion de la Lanterne'
                : 'Ruled by The Lantern Dominion'),
            findsOneWidget);
        expect(inSheet(french ? 'flood (fr)' : 'FLOOD'), findsOneWidget);
        expect(inSheet('Temperate sky 0'), findsOneWidget);
        await tester.dragUntilVisible(
            inSheet('The Old Land'), sheet, const Offset(0, -200));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a free land is ruled by no one', (tester) async {
      _phone(tester, height: 640);
      final container = await _container(tester);
      await tester.pumpWidget(_app(
        container,
        const ThisLandSheet(placeId: 'wells'),
      ));
      await tester.pump();
      await tester.dragUntilVisible(
          find.byKey(const ValueKey('this_land_ruler')),
          find.byKey(const ValueKey('this_land_sheet')),
          const Offset(0, -200));
      expect(find.text('Ruled by no one: a free land'), findsOneWidget);
      expect(find.text('The White Wells'), findsOneWidget);
      expect(find.text('Desert'), findsOneWidget);
    });
  });

  group('the codex\'s Lands', () {
    testWidgets('the lands found, and "…" for what is not', (tester) async {
      _phone(tester, height: 1400);
      final container = await _container(tester, visited: ['n_alley', 'w1']);
      await tester.pumpWidget(
          _app(container, const SingleChildScrollView(child: LandsCodex())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // The Old Land is found; the Seas are not, nor named.
      expect(find.text('The Old Land'), findsOneWidget);
      expect(find.text('The Seas'), findsNothing);
      expect(find.text('Narrow Sea'), findsNothing);
      expect(find.byKey(const ValueKey('geo_unknown')), findsOneWidget);
      expect(find.text('The Marches'), findsOneWidget);
      expect(find.text('Ruled by The Lantern Dominion'), findsOneWidget);
      expect(find.text('Ruled by no one: a free land'), findsOneWidget);
      // A country opens on its zones: each with its biome, what lives and
      // grows there, and the places found.
      await tester.tap(find.text('The Marches'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('geo_codex_vale')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('biome_chip_temperate')), findsOneWidget);
      expect(find.text('Temperate beast 5'), findsOneWidget);
      expect(find.text('Temperate plant 0'), findsOneWidget);
      final alster = find.byKey(const ValueKey('geo_codex_alster'));
      expect(alster, findsOneWidget);
      final line = tester.widget<Text>(alster).textSpan!.toPlainText();
      // The Lower Town found; the Stone Bridge not.
      expect(line, 'Alster · The Lower Town, …');
      await tester.tap(find.text('The Waste'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('geo_codex_wells')), findsOneWidget);
      expect(find.text('The Wreck'), findsNothing);
      // Unknown: the Seas, and the Wreck.
      expect(find.byKey(const ValueKey('geo_unknown')), findsNWidgets(2));
      // A creature's line, a tap away.
      await tester.tap(find.text('Desert beast 0'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('It lives.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('in French, at 360 px', (tester) async {
      _phone(tester, height: 1400);
      final container = await _container(tester,
          language: 'fr', visited: ['n_alley', 'w1', 'at_sea']);
      await tester.pumpWidget(
          _app(container, const SingleChildScrollView(child: LandsCodex())));
      await tester.pumpAndSettle();
      expect(find.text('Les Mers'), findsOneWidget);
      expect(find.text('Autorité$_nb: Le Dominion de la Lanterne'),
          findsOneWidget);
      expect(find.text('Aucune autorité$_nb: une terre libre'), findsWidgets);
      await tester.tap(find.text('Les Marches'));
      await tester.pumpAndSettle();
      expect(find.text('LIEUX DÉCOUVERTS ICI'), findsOneWidget);
      expect(find.text('FAUNE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('nothing before anything is found', (tester) async {
      _phone(tester);
      final container = await _container(tester, visited: ['0']);
      await tester.pumpWidget(_app(container, const LandsCodex()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('lands_codex_empty')), findsOneWidget);
      expect(find.text('The Old Land'), findsNothing);
    });
  });

  group('the land under a place', () {
    test('every pattern paints in every look, the Shroud in grey', () {
      final biomes = [
        for (final pattern in BiomePattern.values)
          Biome(
            id: pattern.id,
            name: pattern.id,
            pattern: pattern,
            palette: const BiomePalette(
              ground: Color(0xFFC9A86A),
              detail: Color(0xFF9C7B45),
              accent: Color(0xFFE8D7A8),
              water: Color(0xFF4F8FA8),
            ),
          ),
      ];
      for (final look in MapLook.values) {
        final palette = ChartPalette.of(look);
        for (final biome in biomes) {
          final recorder = ui.PictureRecorder();
          final painter = BiomeBackdropPainter(
            biome: biome,
            land: palette.land,
            seed: 7,
            greyed: look == MapLook.shroud,
          );
          painter.paint(Canvas(recorder), const Size(328, 420));
          recorder.endRecording().dispose();
          // The same land, the same paint; another, painted anew.
          expect(
              painter.shouldRepaint(BiomeBackdropPainter(
                  biome: biome,
                  land: palette.land,
                  seed: 7,
                  greyed: look == MapLook.shroud)),
              isFalse);
          expect(
              painter.shouldRepaint(BiomeBackdropPainter(
                  biome: biome, land: palette.land, seed: 8)),
              isTrue);
        }
      }
    });

    test('icons for every biome and the hazards the lands name', () {
      for (final pattern in BiomePattern.values) {
        expect(biomeIcon(Biome(id: 'x', name: 'x', pattern: pattern)),
            isA<IconData>());
      }
      IconData of(String id) => hazardIcon(BiomeHazard(id: id, name: id));
      expect(of('sandstorm'), Icons.air);
      expect(of('blizzard'), Icons.ac_unit);
      expect(of('flooded_ford'), Icons.flood);
      expect(of('ash_fall'), Icons.volcano);
      // By the words' starts: a flash flood is no ash.
      expect(of('flash_flood'), Icons.flood);
      expect(of('hailstorm'), Icons.ac_unit);
      expect(of('sinking_ground'), Icons.flood);
      expect(of('marsh_lights'), Icons.flare);
      expect(of('rockslide'), Icons.landslide);
      expect(of('salt_glare'), Icons.wb_sunny_outlined);
      expect(of('glass_shards'), Icons.blur_on);
      expect(of('thick_fog'), Icons.foggy);
      expect(of('something'), Icons.warning_amber_rounded);
    });
  });

  testWidgets('the world map\'s panel says where a landmark lies',
      (tester) async {
    // The bridge's landmark in the fixture's Stone Bridge district.
    SharedPreferences.setMockInitialValues({
      'tutorial_enabled': false,
      'autosave_story_node': '260',
      'autosave_story_history': json.encode(['0', '100', '250']),
      'autosave_story_visited': json.encode(['0', '100', '250', '260']),
    });
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    expect(landmarkOfScene('260')!.id, 'bridge');
    await tester.pumpWidget(ProviderScope(
      overrides: [geographyProvider.overrideWithValue(fixture())],
      child: const MaterialApp(home: WorldMapPage()),
    ));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    final panel = find.byKey(const Key('world_map_panel'));
    expect(panel, findsOneWidget);
    final crumbs = find.byKey(const Key('world_map_crumbs'));
    expect(crumbs, findsOneWidget);
    // The lands it lies in; the place itself only when the title does not
    // already name it.
    expect(find.descendant(of: crumbs, matching: find.text('Alster')),
        findsOneWidget);
    final title = landmarkById('bridge')!.nameEn;
    expect(
        find.descendant(of: panel, matching: find.text(title)), findsOneWidget);
    expect(find.descendant(of: crumbs, matching: find.text('The Stone Bridge')),
        title == 'The Stone Bridge' ? findsNothing : findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('world_map_biome')),
            matching: find.text('Temperate')),
        findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('geo_crumb_alster')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('this_land_sheet')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the node editor\'s place: a list, or typed in', (tester) async {
    _phone(tester);
    final container = await _container(tester);
    final controller = TextEditingController(text: 'wells');
    addTearDown(controller.dispose);
    await tester.pumpWidget(_app(
      container,
      Padding(
        padding: const EdgeInsets.all(16),
        child: GeoLocationField(
          controller: controller,
          label: 'Place',
          hint: 'hint',
          unknown: 'unknown',
          pick: 'Pick a place',
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('The Old Land › The Waste › The Dunes › The White Wells'),
        findsOneWidget);
    await tester.enterText(find.byType(TextField), 'vale');
    await tester.pump();
    // A zone is no place for a scene.
    expect(find.text('unknown'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('hint'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('node_location_pick')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('   · The Stone Bridge  (stone_bridge)').last);
    await tester.pumpAndSettle();
    expect(controller.text, 'stone_bridge');
    expect(tester.takeException(), isNull);
  });
}
