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

import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/map_look_provider.dart';
import 'package:narrative_data_app/screens/story_graph_screen.dart';
import 'package:narrative_data_app/screens/world_map_screen.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 150));
  }
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
      expect(discoveredLandmarkIds({'0'}), {'beggar'});
      expect(discoveredLandmarkIds({'0', '100', '270', '280'}),
          {'beggar', 'alley', 'square'});
      expect(discoveredLandmarkIds({'2900'}), {'upper', 'berths'});
    });

    test('the story stands at the later place of a shared scene', () {
      expect(landmarkOfScene('2001')!.id, 'upper');
      expect(landmarkOfScene('2900')!.id, 'berths');
      expect(landmarkOfScene('2015_kelda')!.id, 'wharf');
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
      final journey = journeyOf(
          ['0', '100', '250', '270', '280', 'sub_280_1', '151', '300'], '400');
      expect([for (final l in journey) l.id],
          ['beggar', 'alley', 'square', 'market', 'hovel']);
      expect(journeyOf(const [], 'nowhere'), isEmpty);
    });

    test('the road is the legs walked, each once', () {
      final there = landmarkById('wharf')!, back = landmarkById('tern')!;
      final legs = roadLegs([there, back, there, back], {'wharf', 'tern'});
      expect(legs.length, 1);
      // With no journey, the reached places in story order.
      final road = roadLegs(const [], {'beggar', 'bridge', 'square'});
      expect([for (final (a, b) in road) '${a.id}-${b.id}'],
          ['beggar-bridge', 'bridge-square']);
    });

    test('the walk starts where the map last left off', () {
      final journey = [
        for (final id in ['beggar', 'alley', 'square', 'market', 'hovel'])
          landmarkById(id)!,
      ];
      // First look: the last leg.
      expect(journeyWalkStart(journey), 3);
      // Seen up to the square: walk on from there.
      expect(journeyWalkStart(journey, seenSteps: 3, seenLast: 'square'), 2);
      // Nothing new since.
      expect(journeyWalkStart(journey, seenSteps: 5, seenLast: 'hovel'), 4);
      // Another game's record: the last leg.
      expect(journeyWalkStart(journey, seenSteps: 3, seenLast: 'docks'), 3);
      // Never more than the last few legs.
      final long = [for (var i = 0; i < 20; i++) journey[i % 5]];
      expect(journeyWalkStart(long, seenSteps: 1, seenLast: 'beggar'),
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
        '0',
        '100',
        '250',
        '270',
        '280',
        '151',
        '300',
        '400',
        '891',
        '2001'
      ]),
      'autosave_story_visited': json.encode([
        '0', '100', '250', '270', '280', '151', '300', '400', '891', //
        '2001', '2015', '2015_rats',
      ]),
    });
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    await tester.tap(find.byTooltip('Map'));
    await _settle(tester);
    expect(find.byType(WorldMapPage), findsOneWidget);

    // The story stands at the wharf; its panel says so.
    final panel = find.byKey(const Key('world_map_panel'));
    expect(find.descendant(of: panel, matching: find.text('Smuggler’s Wharf')),
        findsOneWidget);
    expect(find.text('You are here'), findsOneWidget);
    expect(find.text('Scenes read: 3 / 30'), findsOneWidget);
    // The rat was beaten; the rest are still unknown.
    expect(find.text('Harbor Rat'), findsOneWidget);
    expect(find.text('???'), findsNWidgets(4));
    // Next on the road: the Upper Tier, seen on arrival; after it, the
    // old berths are not reached yet.
    expect(find.text('Next: The Upper Tier'), findsOneWidget);
    await tester.tap(find.byKey(const Key('world_map_next')));
    await tester.pump();
    expect(find.text('Next: ???'), findsOneWidget);
    await tester.tap(find.byKey(const Key('world_map_back')));
    await tester.pump();
    // Chapters 1 and 2 have been reached.
    expect(find.byKey(const Key('world_map_chip_1')), findsOneWidget);
    expect(find.byKey(const Key('world_map_chip_2')), findsOneWidget);
    expect(find.byKey(const Key('world_map_chip_3')), findsNothing);

    // Back along the road (past Tern Row, never visited), then a tap on
    // the Blind Beggar itself.
    await tester.tap(find.byKey(const Key('world_map_back')));
    await tester.pump();
    expect(find.descendant(of: panel, matching: find.text('Alster docks')),
        findsOneWidget);
    final canvas = find.byKey(const Key('world_map_canvas'));
    final box = tester.getRect(canvas);
    final scale = box.width / worldMapWidth;
    // A single tap waits to be sure it isn't the first of a double tap.
    await tester.tapAt(box.topLeft + Offset(26 * scale, 126 * scale));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.descendant(of: panel, matching: find.text('The Blind Beggar')),
        findsOneWidget);
    // An unreached place can't be picked.
    await tester.tapAt(box.topLeft + Offset(222 * scale, 24 * scale));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.descendant(of: panel, matching: find.text('The Blind Beggar')),
        findsOneWidget);

    // In French.
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    await tester.pump();
    expect(
        find.descendant(of: panel, matching: find.text('Le Mendiant Aveugle')),
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
      'autosave_story_node': '280',
      'autosave_story_history': json.encode(['0', '100', '250', '270']),
      'autosave_story_visited': json.encode(['0', '100', '250', '270', '280']),
    });
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    await tester.tap(find.byTooltip('Map'));
    await _settle(tester);

    // Opening the map records how far the journey had gone.
    await _settle(tester);
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    expect(json.decode(prefs!.getString(worldMapSeenPrefsKey)!),
        {'steps': 3, 'last': 'square'});

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
