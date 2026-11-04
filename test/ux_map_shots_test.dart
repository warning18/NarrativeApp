// The world map's pictures (UX_SHOTS=<folder> UX_SHOT_TAG=before|after): the
// real full-map screen at 412 px in French, the sphere and the flat chart
// close in on the Salt Coast, with the Clans layer on and the layers sheet.
// Drawn only with UX_SHOTS.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart' show PoliticsState;
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/data/travel_history.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/providers/map_look_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/providers/travel_history_provider.dart';
import 'package:narrative_data_app/screens/full_map_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/chart_map_painter.dart'
    show ChartCalque;

import 'player_session_provider_test.dart' show baseSession;

Future<void> _loadFonts() async {
  for (final (family, files) in [
    (
      InkFonts.system,
      ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']
    ),
    (
      InkFonts.prose,
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    (InkFonts.display, ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(Future.value(
          ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync())));
    }
    await loader.load();
  }
  final icons = File('/tmp/flutter/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final shots = Platform.environment['UX_SHOTS'];
  final tag = Platform.environment['UX_SHOT_TAG'] ?? 'before';
  if (shots == null || shots.isEmpty) {
    test('the map pictures are drawn only with UX_SHOTS', () {});
    return;
  }

  // How far the party has come: just the wreck of the Lark, the Sleeper's
  // Face and the White Wells ('early': most of the world is fog), or a scene
  // of each landmark of chapters 1 to 3 ('mid': most lands charted).
  final early = (Platform.environment['UX_HISTORY'] ?? 'mid') == 'early';
  final ids = [
    for (final l in worldMapLandmarks)
      if (l.chapter <= 3 && l.scenes.isNotEmpty) l.scenes.first,
  ];
  final travels = early
      ? travelHistoryOf(
          history: const ['965', '1100', '1120', '1130'],
          currentNodeId: '1200',
        )
      : travelHistoryOf(
          history: ids.sublist(0, ids.length - 1),
          currentNodeId: ids.last,
        );

  testWidgets('the world map, as the player sees it', (tester) async {
    await tester.runAsync(_loadFonts);
    SharedPreferences.setMockInitialValues({'app_language': 'fr'});
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(824, 1780);
    final key = GlobalKey();
    final container = ProviderContainer(overrides: [
      travelHistoryProvider.overrideWithValue(travels),
      storyDataProvider.overrideWith((ref) async => const StoryData({})),
    ]);
    addTearDown(container.dispose);
    // Some clans hold some places, so the Clans layer has something to say.
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          ...baseSession().toJson(),
          'raceId': 'human',
          'professionId': 'warrior',
        }).copyWith(
            politics: const PoliticsState(control: {
          'saltmouth': 'crows',
          'alster': 'dominion',
          'drowned_cloister': 'mire',
          'white_anchorage': 'vigil',
          'black_reliquary': 'penitents',
        }))));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(ColorScheme.fromSeed(
              seedColor: Colors.amber, brightness: Brightness.dark)),
          home: const FullMapScreen(),
        ),
      ),
    ));

    Future<void> settle() async {
      for (var i = 0; i < 6; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 120)));
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    Future<void> shoot(String name) async {
      await settle();
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/map-$tag-${early ? 'early' : 'mid'}-$name.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    // The screen reads how far the party has come from the story's own play
    // state (the travel history above only feeds the fog), so move it there.
    final path = early
        ? const ['965', '1100', '1120', '1130', '1200']
        : [...ids.sublist(0, ids.length - 1), ids.last];
    container
        .read(storyPlayProvider.notifier)
        .loadState(path.last, path.sublist(0, path.length - 1));
    await settle();
    await shoot('1-sphere');
    if (tag == 'after') {
      // M2, the map's size (not the ball's): (A) the panel takes 0.8 / 0.5 of
      // today's height, the rest of the screen is free; (B) the panel keeps
      // its place but is drawn at 0.8 / 0.5 of today's resolution.
      final mapBox = find.byKey(const ValueKey('full_world_map'));
      final todayH = tester.getSize(mapBox).height;
      final mapRect = tester.getRect(mapBox);
      File('$shots/map-rect.txt').writeAsStringSync(
          '${mapRect.left} ${mapRect.top} ${mapRect.width} ${mapRect.height}');
      for (final f in [0.8, 0.5]) {
        tester.view.physicalSize =
            Size(824, 1780 - (1 - f) * todayH * 2); // logical x 2
        await shoot('M2A-${(f * 100).round()}');
      }
      tester.view.physicalSize = const Size(824, 1780);
      await settle();
      for (final f in [1.0, 0.8, 0.5]) {
        await settle();
        await tester.runAsync(() async {
          final b =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await b.toImage(pixelRatio: 2 * f);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/map-$tag-${early ? 'early' : 'mid'}-M2B-${(f * 100).round()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
    }

    // The Clans layer on the sphere.
    await container
        .read(chartCalqueProvider.notifier)
        .choose(ChartCalque.clans);
    await shoot('2-sphere-clans');

    // The layers sheet.
    await tester.tap(find.byKey(const ValueKey('journey_layers')));
    await settle();
    tester.view.physicalSize = const Size(824, 2300);
    await shoot('3-layers');
    tester.view.physicalSize = const Size(824, 1780);
    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await settle();

    // Close in: the flat chart on the Salt Coast, with and without the layer.
    await container.read(chartCalqueProvider.notifier).choose(ChartCalque.none);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('journey_zoom_in')));
      await settle();
    }
    await shoot('4-close');
    await container
        .read(chartCalqueProvider.notifier)
        .choose(ChartCalque.clans);
    await shoot('5-close-clans');
    expect(tester.takeException(), isNull);
  });
}
