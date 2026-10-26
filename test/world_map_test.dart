// The world map in play mode: every scene of the story sits at one of its
// places, a place shows once the story has reached it, and the map opens
// from the header in play mode only.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/map_look_provider.dart';
import 'package:narrative_data_app/screens/story_graph_screen.dart';
import 'package:narrative_data_app/screens/full_map_screen.dart';
import 'package:narrative_data_app/screens/world_map_screen.dart';

/// The first settle of a test waits for the game data to load; the later
/// ones only let the screen catch up.
final _warmed = Expando<bool>();

Future<void> _settle(WidgetTester tester) async {
  final first = _warmed[tester] == null;
  _warmed[tester] = true;
  for (var i = 0; i < (first ? 6 : 3); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(Duration(milliseconds: first ? 150 : 100)));
    await tester.pump(const Duration(milliseconds: 150));
  }
}

/// Opens the author's world chart over whatever is showing.
Future<void> openOldMap(WidgetTester tester) async {
  tester.state<NavigatorState>(find.byType(Navigator).first).push(
        MaterialPageRoute<void>(builder: (_) => const WorldMapPage()),
      );
  await _settle(tester);
}

void main() {
  final story =
      json.decode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>;
  final enemies =
      json.decode(File('assets/gamedata/enemies.json').readAsStringSync())
          as Map<String, dynamic>;

  group('map data', () {
    test('every scene of the story is at a place on the map, and only those',
        () {
      final onMap = {for (final l in worldMapLandmarks) ...l.scenes};
      expect(onMap.difference(story.keys.toSet()), isEmpty,
          reason: 'scenes on the map that the story no longer has');
      expect(story.keys.toSet().difference(onMap), isEmpty,
          reason: 'scenes of the story missing from the map');
    });

    test('every foe on the map is an enemy of the game', () {
      for (final l in worldMapLandmarks) {
        for (final id in l.fights) {
          if (id == '@first_ally') continue;
          expect(enemies.containsKey(id), isTrue, reason: '${l.id}: $id');
        }
      }
    });

    test('every place has both languages', () {
      for (final l in worldMapLandmarks) {
        expect(l.nameFr, isNotEmpty, reason: l.id);
        expect(l.blurbFr, isNotEmpty, reason: l.id);
      }
    });

    test('the chapter titles are the story\'s own headings', () {
      final headings = <String>{};
      for (final node in story.values) {
        for (final field in ['description', 'description_fr']) {
          final text = (node as Map<String, dynamic>)[field]?.toString() ?? '';
          final match =
              RegExp(r'^\[(CHAP(?:TER|ITRE)[^\]]*)\]').firstMatch(text);
          if (match != null) headings.add(match.group(1)!);
        }
      }
      // French puts a (non-breaking) space before a colon.
      String plain(String s) => s
          .toUpperCase()
          .replaceAll('’', "'")
          .replaceAll(RegExp('[\u00a0\u202f ]+:'), ':');
      for (final chapter in mapChapters.skip(1)) {
        expect(headings.map(plain), contains(plain(chapter.titleEn)));
        expect(headings.map(plain), contains(plain(chapter.titleFr)));
      }
    });
  });

  group('what the map shows', () {
    test('a place shows once one of its scenes has been read', () {
      expect(discoveredLandmarkIds({'0'}), {'alster'});
      // Alster is one place (v1.534), whichever of its districts is read.
      expect(discoveredLandmarkIds({'0', '100', '270', '300'}), {'alster'});
      expect(discoveredLandmarkIds({'1130', '1200'}), {'sleeper', 'wells'});
      expect(discoveredLandmarkIds({'2900'}), {'saltmouth'});
      // So is Saltmouth (v1.536).
      expect(discoveredLandmarkIds({'2001', '2015_ternrow', '2900'}),
          {'saltmouth'});
    });

    test('each scene stands at its own place', () {
      expect(landmarkOfScene('2001')!.id, 'saltmouth');
      expect(landmarkOfScene('470')!.id, 'alster');
      expect(landmarkOfScene('1100')!.id, 'crash');
      expect(landmarkOfScene('2900')!.id, 'saltmouth');
      expect(landmarkOfScene('2015_kelda')!.id, 'saltmouth');
    });

    test('every scene of every landmark resolves to it (v1.209: one lookup)',
        () {
      // A scene two landmarks share belongs to the later one on the road:
      // the last landmark listing it, as the scan it replaces found.
      final expected = <String, Landmark>{};
      for (final landmark in worldMapLandmarks) {
        for (final scene in landmark.scenes) {
          expected[scene] = landmark;
        }
      }
      expect(expected, isNotEmpty);
      for (final entry in expected.entries) {
        expect(landmarkOfScene(entry.key), same(entry.value),
            reason: 'scene ${entry.key}');
      }
      expect(landmarkOfScene('no_such_scene'), isNull);
      expect(landmarkOfScene(''), isNull);
    });

    test('off the map (an excursion step), the last place on it counts', () {
      expect(currentLandmark('sub_3005_2', ['2999', '3001', '3005'])!.id,
          'quarter');
      expect(currentLandmark('7005_dawn', const [])!.id, 'shore');
      expect(currentLandmark('nowhere', const []), isNull);
    });
  });

  group('the player\'s journey', () {
    test('the journey follows the story, one entry per stay', () {
      // All of Alster is one stay (v1.534: its districts are walked on its
      // plan); the wreck, the face and the wells are one each.
      final journey = journeyOf([
        '0', '100', '105', '250', '260', 'sub_260_1', '300', '400', //
        '800', '816', '820', '840', '850', '855', '470', '891', '960',
        '965', '1100', '1120', '1125',
      ], '1200');
      expect([for (final l in journey) l.id],
          ['alster', 'crash', 'sleeper', 'wells']);
      expect(journeyOf(const [], 'nowhere'), isEmpty);
    });

    test('the road is the legs walked, each once', () {
      final there = landmarkById('wells')!, back = landmarkById('saltmouth')!;
      final legs = roadLegs([there, back, there, back], {'wells', 'saltmouth'});
      expect(legs.length, 1);
      // With no journey, the reached places in story order.
      final road = roadLegs(const [], {'alster', 'crash', 'sleeper'});
      expect([for (final (a, b) in road) '${a.id}-${b.id}'],
          ['alster-crash', 'crash-sleeper']);
    });

    test('the walk starts where the map last left off', () {
      final journey = [
        for (final id in ['alster', 'crash', 'sleeper', 'wells', 'saltmouth'])
          landmarkById(id)!,
      ];
      // First look: the last leg.
      expect(journeyWalkStart(journey), 3);
      // Seen up to the sleeper's face: walk on from there.
      expect(journeyWalkStart(journey, seenSteps: 3, seenLast: 'sleeper'), 2);
      // Nothing new since.
      expect(journeyWalkStart(journey, seenSteps: 5, seenLast: 'saltmouth'), 4);
      // Another game's record: the last leg.
      expect(journeyWalkStart(journey, seenSteps: 3, seenLast: 'wells'), 3);
      // Never more than the last few legs.
      final long = [for (var i = 0; i < 20; i++) journey[i % 5]];
      expect(journeyWalkStart(long, seenSteps: 1, seenLast: 'alster'),
          19 - maxWalkLegs);
      expect(journeyWalkStart([journey.first]), 0);
    });

    test('the traveller moves along the path by distance', () {
      const path = [(0.0, 0.0), (10.0, 0.0), (10.0, 10.0)];
      expect(pointAlong(path, 0), (0.0, 0.0));
      expect(pointAlong(path, 0.25), (5.0, 0.0));
      expect(pointAlong(path, 0.75), (10.0, 5.0));
      expect(pointAlong(path, 1), (10.0, 10.0));
    });
  });

  testWidgets('play mode opens the world map from the header', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({
      'player_session': json.encode({
        'raceId': 'human',
        'professionId': 'warrior',
        'characterName': 'Maren',
        'enemyKillCounts': {'harbor_rat': 1},
      }),
      'autosave_story_node': '2015',
      'autosave_story_history': json.encode([
        '0', '100', '105', '250', '270', '300', '400', '450', '470', //
        '891', '895', '960', '965', '1100', '1120', '1130', '1140', '1200',
        '1000', '2001', '2005', '2010',
      ]),
      'autosave_story_visited': json.encode([
        '0', '100', '105', '250', '270', '300', '400', '450', '470', //
        '891', '895', '960', '965', '1100', '1120', '1130', '1140', '1200',
        '1000', '2001', '2005', '2010', '2015', '2015_rats',
      ]),
    });
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // The main menu's Shroud drifts for ever; still, it lets the test settle.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_continue')));
    await _settle(tester);
    final dialog = find.descendant(
        of: find.byType(AlertDialog), matching: find.byType(FilledButton));
    if (dialog.evaluate().isNotEmpty) {
      await tester.tap(dialog.first, warnIfMissed: false);
      await _settle(tester);
    }

    expect(find.byTooltip('Story Map'), findsNothing);
    // The header's map is the full map now; the author's chart, with the
    // place panel, is reached in Edit Mode (and is looked at here directly).
    await tester.tap(find.byTooltip('Map'));
    await _settle(tester);
    expect(find.byType(FullMapScreen), findsOneWidget);
    expect(find.byType(WorldMapPage), findsNothing);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await _settle(tester);
    await openOldMap(tester);
    expect(find.byType(WorldMapPage), findsOneWidget);

    // The story stands at the wharf, in Saltmouth; its panel says so.
    final panel = find.byKey(const Key('world_map_panel'));
    expect(find.descendant(of: panel, matching: find.text('Saltmouth')),
        findsOneWidget);
    expect(find.text('You are here'), findsOneWidget);
    // 42 with the old sign-painter who names the Open Hand (v1.195); 46
    // with the three Houses' favours and the door that was turned, less the
    // landward gate's scenes, which have a place of their own (v1.196);
    // 41 once the gate guard's ambush stands at the gate too (v1.201.2);
    // 46 with the first clues of five plots at the wharf (v1.270.0); 17
    // once the ways moved to their districts (the gate, Tern Row, the yard,
    // the Lantern Alleys and Card Row take the other 29); 18 with the Tide
    // Cellar's line about a girl from Tallow Street (v1.414); 19 with the
    // Crow tally-girl who says the clans will make an offer (v1.422).
    // 61 once Saltmouth is one place, its six districts' scenes together
    // (v1.536): the gate's and the wharf's read.
    expect(find.text('Scenes read: 5 / 61'), findsOneWidget);
    // The rat was beaten; the rest are still unknown.
    expect(find.text('Harbor Rat'), findsOneWidget);
    expect(find.text('???'), findsNWidgets(5));
    // Next on the road, the ship-breaker's yard is not reached yet.
    expect(find.text('Next: ???'), findsOneWidget);
    // Chapters 1 and 2 have been reached.
    expect(find.byKey(const Key('world_map_chip_1')), findsOneWidget);
    expect(find.byKey(const Key('world_map_chip_2')), findsOneWidget);
    expect(find.byKey(const Key('world_map_chip_3')), findsNothing);

    // Back along the road to the White Wells, then a tap on Alster itself.
    await tester.tap(find.byKey(const Key('world_map_back')));
    await tester.pump();
    expect(find.descendant(of: panel, matching: find.text('The White Wells')),
        findsOneWidget);
    final canvas = find.byKey(const Key('world_map_canvas'));
    final box = tester.getRect(canvas);
    final scale = box.width / worldMapWidth;
    // A single tap waits to be sure it isn't the first of a double tap.
    final alster = chartOf(MapShape.archipelago).places['alster']!;
    await tester.tapAt(box.topLeft + alster * scale);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.descendant(of: panel, matching: find.text('Alster')),
        findsOneWidget);
    // An unreached place can't be picked.
    final reliquary = chartOf(MapShape.archipelago).places['reliquary']!;
    await tester.tapAt(box.topLeft + reliquary * scale);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.descendant(of: panel, matching: find.text('Alster')),
        findsOneWidget);

    // In French.
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    await tester.pump();
    expect(find.descendant(of: panel, matching: find.text('Alster')),
        findsOneWidget);
    expect(find.text('Chapitre 1'), findsOneWidget);
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));

    // Edit Mode keeps the story graph.
    await tester.pageBack();
    await _settle(tester);
    await tester.tap(find.byTooltip('Main menu'));
    await _settle(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('menu_edit_mode')));
    await _settle(tester);
    await tester.tap(find.byTooltip('Story Map'));
    await _settle(tester);
    expect(find.byType(StoryMapPage), findsOneWidget);
    expect(find.byType(WorldMapPage), findsNothing);
  });

  testWidgets('the map zooms, changes look, and remembers what it showed',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({
      'player_session': json.encode({
        'raceId': 'human',
        'professionId': 'warrior',
        'enemyKillCounts': <String, dynamic>{},
      }),
      'autosave_story_node': '300',
      'autosave_story_history': json.encode(['0', '100', '250', '270']),
      'autosave_story_visited': json.encode(['0', '100', '250', '270', '300']),
    });
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // The main menu's Shroud drifts for ever; still, it lets the test settle.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('menu_continue')));
    await _settle(tester);
    // A "Previously…" recap opens over a loaded story, once a launch.
    final dialog = find.descendant(
        of: find.byType(Dialog),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
    for (var i = 0; i < 4; i++) {
      await _settle(tester);
      if (dialog.evaluate().isNotEmpty) {
        await tester.tap(dialog.last, warnIfMissed: false);
      }
    }
    await _settle(tester);
    await openOldMap(tester);

    // Opening the map records how far the journey had gone.
    await _settle(tester);
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    expect(json.decode(prefs!.getString(worldMapSeenPrefsKey)!),
        {'steps': 1, 'last': 'alster'});

    double scale() => tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!
        .value
        .getMaxScaleOnAxis();
    expect(scale(), 1);
    await tester.tap(find.byKey(const Key('world_map_zoom_in')));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(scale(), closeTo(1.6, 0.01));
    await tester.tap(find.byKey(const Key('world_map_zoom_out')));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(scale(), closeTo(1, 0.01));
    await tester.tap(find.byKey(const Key('world_map_centre')));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(scale(), closeTo(3, 0.01));
    // A double tap when zoomed in goes back to the whole map.
    final visible = tester.getCenter(find.byType(InteractiveViewer));
    await tester.tapAt(visible);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(visible);
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    expect(scale(), closeTo(1, 0.01));

    // The parchment look, chosen from the header and remembered.
    await tester.tap(find.byKey(const Key('world_map_look')));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const Key('world_map_look_parchment')));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    expect(container.read(mapLookProvider), MapLook.parchment);
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    expect(prefs.getString(mapLookPrefsKey), 'parchment');

    // The journey can be walked again.
    await tester.tap(find.byKey(const Key('world_map_replay')));
    await tester.pump(const Duration(seconds: 3));
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));
  });
}
