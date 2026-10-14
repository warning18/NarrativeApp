// QA: the full map (full_map_screen.dart) on real story walks: an empty
// history, an early save, a mid-game save (chapter 5) and an ending save, at
// 360 and 320 px with the bundled fonts in English and French. It must lay out
// without overflow; a tap on the place the party stands at says so; one that
// is no way to travel says so; a ringed place offers the journey, and "Travel
// here" is disabled during a fight and during an expedition; and Go moves the
// story and closes the map's own page, whatever is showing over it.
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/data/chapter_loop.dart';
import 'package:narrative_data_app/data/chapter_spine.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/data/travel_history.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/providers/travel_history_provider.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/providers/combat_active_provider.dart';
import 'package:narrative_data_app/providers/expedition_active_provider.dart';
import 'package:narrative_data_app/screens/full_map_screen.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';

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
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
    for (final path in [
      'assets/Cleaned_Narrative_DAG.json',
      for (final f in Directory('assets/gamedata').listSync())
        if (f.path.endsWith('.json')) f.path,
    ]) {
      await rootBundle.loadString(path);
    }
  });

  final dag =
      jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>;
  final story = StoryData({
    for (final e in dag.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  });

  List<String> walk(int seed, bool Function(List<String> path) stop) {
    final random = Random(seed);
    final path = <String>[StoryRepository.startNodeId];
    while (path.length < 4000 && !stop(path)) {
      final next = [
        for (final c in story.nodeFor(path.last)!.choices)
          if (story.nodeFor(c.nextId) != null) c.nextId,
      ];
      if (next.isEmpty) break;
      path.add(next[random.nextInt(next.length)]);
    }
    return path;
  }

  final fixtures = <String, List<String>>{
    'empty': const ['0'],
    'early': walk(3, (p) => p.length >= 14),
    'mid-game': walk(5, (p) => (chapterForNode(p.last) ?? 0) >= 5),
    'ending': walk(9, (p) => false),
  };

  // A party that has been to a town and is now somewhere else: the town is
  // a ringed place, and not where it stands.
  List<String> townThenElsewhere() {
    for (final place in knownPlaces(story, chapter: 8, flags: const [])) {
      final town = landmarkOfScene(place.id) ??
          landmarkOfScene(place.settlement?.arrivalNodeId ?? '');
      if (town == null) continue;
      for (final node in story.nodes.values) {
        final there = landmarkOfScene(node.id);
        if (there != null && there.id != town.id) {
          return ['0', place.id, node.id];
        }
      }
    }
    throw StateError('no town to go back to');
  }

  TravelHistory historyOf(List<String> path) => travelHistoryOf(
        history: path.sublist(0, path.length - 1),
        currentNodeId: path.last,
        visitedNodeIds: path,
        knownPlaces: knownPlaces(story, chapter: 8, flags: const []),
      );

  Future<ProviderContainer> open(
    WidgetTester tester,
    List<String> path, {
    required Size size,
    bool french = false,
    bool fighting = false,
    bool expedition = false,
    Widget? home,
  }) async {
    SharedPreferences.setMockInitialValues({if (french) 'app_language': 'fr'});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        travelHistoryProvider.overrideWithValue(historyOf(path)),
        if (fighting) combatActiveProvider.overrideWith((ref) => true),
        if (expedition) expeditionActiveProvider.overrideWith((ref) => true),
      ],
      child: MaterialApp(
        theme: buildAppTheme(ColorScheme.fromSeed(
            seedColor: Colors.amber, brightness: Brightness.dark)),
        home: home ?? const FullMapScreen(),
      ),
    ));
    await _settle(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    container
        .read(storyPlayProvider.notifier)
        .loadState(path.last, path.sublist(0, path.length - 1));
    await tester.runAsync(() => container.read(storyDataProvider.future));
    await _settle(tester);
    return container;
  }

  void tapPlace(WidgetTester tester, String id) => tester
      .widget<JourneyWorldMap>(find.byKey(const ValueKey('full_world_map')))
      .onSelect!(landmarkById(id)!);

  Future<void> sheetUp(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Future<void> closeSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('map_cancel')));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  for (final fixture in fixtures.entries) {
    for (final size in const [Size(360, 740), Size(320, 568)]) {
      for (final french in [false, true]) {
        final label = '${fixture.key}, ${size.width.toInt()} px, '
            '${french ? 'French' : 'English'}';
        testWidgets('the full map: $label', (tester) async {
          final overflows = _collectOverflows(tester);
          final path = fixture.value;
          final history = historyOf(path);
          await open(tester, path, size: size, french: french);
          expect(find.byKey(const ValueKey('full_world_map')), findsOneWidget);
          // Where the party stands.
          if (history.currentId != null) {
            tapPlace(tester, history.currentId!);
            await sheetUp(tester);
            expect(find.byKey(const Key('map_here')), findsOneWidget);
            expect(find.byKey(const Key('travel_go')), findsNothing);
            await closeSheet(tester);
          }
          // A place that is no way to travel.
          final other = [
            for (final l in worldMapLandmarks)
              if (l.id != history.currentId &&
                  !history.travelTargets.containsKey(l.id))
                l.id,
          ];
          tapPlace(tester, other.first);
          await sheetUp(tester);
          expect(find.byKey(const Key('map_no_road')), findsOneWidget);
          expect(find.byKey(const Key('travel_go')), findsNothing);
          await closeSheet(tester);
          // A ringed place offers the journey.
          for (final id in history.travelTargets.keys.take(1)) {
            if (id == history.currentId) continue;
            tapPlace(tester, id);
            await sheetUp(tester);
            expect(find.byKey(const Key('travel_go')), findsOneWidget);
            await closeSheet(tester);
          }
          expect(overflows, isEmpty, reason: overflows.toSet().join('\n'));
        });
      }
    }
  }

  // Travel here is shut during a fight and during an expedition.
  for (final busy in const ['fight', 'expedition']) {
    testWidgets('Travel here is disabled during a $busy', (tester) async {
      final path = townThenElsewhere();
      final history = historyOf(path);
      final target = history.travelTargets.keys
          .firstWhere((id) => id != history.currentId);
      await open(tester, path,
          size: const Size(360, 740),
          fighting: busy == 'fight',
          expedition: busy == 'expedition');
      tapPlace(tester, target);
      await sheetUp(tester);
      expect(find.byKey(const Key('map_busy')), findsOneWidget);
      final go =
          tester.widget<FilledButton>(find.byKey(const Key('travel_go')));
      expect(go.onPressed, isNull);
    });
  }

  testWidgets('Travel here is enabled when nothing is going on',
      (tester) async {
    final path = townThenElsewhere();
    final history = historyOf(path);
    final target =
        history.travelTargets.keys.firstWhere((id) => id != history.currentId);
    await open(tester, path, size: const Size(360, 740));
    tapPlace(tester, target);
    await sheetUp(tester);
    expect(find.byKey(const Key('map_busy')), findsNothing);
    final go = tester.widget<FilledButton>(find.byKey(const Key('travel_go')));
    expect(go.onPressed, isNotNull);
  });

  // Go: the story moves and the map's own page closes, whatever shows over it.
  for (var attempt = 0; attempt < 3; attempt++) {
    testWidgets('Go from the full map travels and closes it ($attempt)',
        (tester) async {
      final path = townThenElsewhere();
      final history = historyOf(path);
      final target = history.travelTargets.keys
          .firstWhere((id) => id != history.currentId);
      final container = await open(tester, path,
          size: const Size(360, 740),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const Key('open_map'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FullMapScreen()),
                  ),
                  child: const Text('map'),
                ),
              ),
            ),
          ));
      await tester.tap(find.byKey(const Key('open_map')));
      await _settle(tester);
      final before = container.read(storyPlayProvider);
      Object? thrown;
      tapPlaceZoned() => runZonedGuarded(
          () => tester
              .widget<JourneyWorldMap>(
                  find.byKey(const ValueKey('full_world_map')))
              .onSelect!(landmarkById(target)!),
          (error, stack) => thrown = error);
      tapPlaceZoned();
      await sheetUp(tester);
      await tester.tap(find.byKey(const Key('travel_go')));
      // The walk takes a while; stop as soon as the map's page is gone.
      for (var i = 0; i < 40; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump(const Duration(milliseconds: 300));
        if (find.byKey(const ValueKey('full_world_map')).evaluate().isEmpty) {
          break;
        }
      }
      await tester.pump(const Duration(seconds: 6));
      final after = container.read(storyPlayProvider);
      expect(after.currentNodeId != before.currentNodeId || after.isInExcursion,
          isTrue,
          reason: 'the story did not move');
      expect(thrown, isNull);
      expect(find.byKey(const ValueKey('full_world_map')), findsNothing,
          reason: 'the map is still open');
    });
  }
}
