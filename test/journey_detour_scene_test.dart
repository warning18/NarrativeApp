// A written detour plays over a scene of its own on the Journey (v1.439):
// the map gives way to a band with the scene's title, the beat it is at and
// the place of the beat, dressed by the biome (the ruins kit for the
// ashlands, a tinted band for the fen); leaving the detour brings the map
// back. UX_SHOTS (a folder) saves pictures.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/detour_scenes.dart';
import 'package:narrative_data_app/data/expedition_steps.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/widgets/detour_scene_band.dart';
import 'support/fonts.dart';
import 'support/pump.dart';
import 'support/open_game.dart';

Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) return;
  await tester.pump(const Duration(milliseconds: 400));
  await tester.runAsync(() async {
    RenderObject? node = tester.renderObject(find.byType(MaterialApp));
    while (node != null && node is! RenderRepaintBoundary) {
      node = node.parent;
    }
    node ??= tester.renderObject(find.byType(Scaffold).first);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first);
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

const _fen = DetourScene(
  id: 'test_fen',
  title: 'The Drowned Milestone',
  titleFr: 'La borne noyée',
  where: DetourWhere(biomes: ['fen']),
  beats: [
    WrittenStep(
      id: 'stone',
      text: 'A milestone stands to its neck in black water.',
      place: 'The sunk causeway',
      placeFr: 'La chaussée engloutie',
      choices: [
        WrittenChoice(id: 'wade', text: 'Wade out to it', check: 'strength'),
      ],
    ),
    WrittenStep(
      id: 'find',
      type: 'discovery',
      text: 'Under the moss, a purse.',
      place: 'The milestone',
      placeFr: 'La borne',
    ),
  ],
);

const _ash = DetourScene(
  id: 'test_ash',
  title: 'The Cinder Stair',
  titleFr: 'L’escalier de cendre',
  where: DetourWhere(biomes: ['ashlands']),
  tags: {detourLandmarkTag},
  beats: [
    WrittenStep(
      id: 'stair',
      text: 'A stair climbs out of the slag to nothing.',
      place: 'The cinder stair',
      placeFr: 'L’escalier de cendre',
    ),
    WrittenStep(id: 'top', text: 'At the top, a bell.', place: 'The top'),
    WrittenStep(id: 'bell', text: 'It rings once.', place: 'The bell'),
  ],
);

void main() {
  testWidgets('a written detour plays over a scene, and leaving brings the map',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    if (Platform.environment['UX_SHOTS'] != null) await loadAppFonts();
    usePhone(tester, const Size(400, 860));

    final container = await openGame(tester);
    final play = container.read(storyPlayProvider.notifier);
    play.jumpTo('100');
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);
    expect(find.byKey(const Key('journey_detour_scene')), findsNothing);

    // The fen scene: a tinted band, its title, beat 1 of 2, the beat's place.
    play.startScene(
        buildDetourScene(_fen, chapter: 3, random: Random(1)), '100',
        origin: 'The road south');
    await settleApp(tester);
    expect(find.byKey(const Key('journey_detour_scene')), findsOneWidget);
    expect(find.text('The Drowned Milestone'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('The sunk causeway'), findsOneWidget);
    // The beat's words are under the scene, not behind Read.
    expect(
        find.textContaining('A milestone stands to its neck in black water.'),
        findsOneWidget);
    expect(find.byKey(const ValueKey('journey_world_map')), findsNothing);
    // No map, so no levels to zoom between.
    expect(find.text('District'), findsNothing);
    // The beat's ways are cards under the scene, "Leave it" the last.
    expect(find.textContaining('Wade out to it'), findsOneWidget);
    expect(find.textContaining('Leave it'), findsOneWidget);
    await _shot(tester, 'detour-scene-fen');

    // The next beat: the band follows.
    play.advanceExcursion();
    await settleApp(tester);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('The milestone'), findsOneWidget);
    expect(find.textContaining('Under the moss, a purse.'), findsOneWidget);

    // Backed away from: the map is back.
    play.leaveExcursion();
    await settleApp(tester);
    expect(find.byKey(const Key('journey_detour_scene')), findsNothing);

    // The ashlands scene wears the ruins kit and a landmark's star.
    play.startScene(
        buildDetourScene(_ash, chapter: 3, random: Random(2)), '100');
    await settleApp(tester);
    expect(find.byKey(const Key('journey_detour_scene')), findsOneWidget);
    expect(find.text('3 beats'), findsNothing);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.byIcon(Icons.star_outline), findsOneWidget);
    await _shot(tester, 'detour-scene-ashlands');
    play.leaveExcursion();
    await settleApp(tester);

    final error = tester.takeException();
    expect(error, isNull,
        reason: error is FlutterError ? error.toStringDeep() : '$error');
  });

  test('the biomes a kit dresses, and the others are tinted', () {
    expect(detourKitOf('desert'), DetourKit.desert);
    expect(detourKitOf('arid_coast'), DetourKit.desert);
    expect(detourKitOf('ashlands'), DetourKit.ruins);
    expect(detourKitOf('tear'), DetourKit.ruins);
    expect(detourKitOf('fen'), isNull);
    expect(detourKitOf(null), isNull);
    expect(detourBiomeLook('frost').$3, Icons.ac_unit);
    expect(detourBiomeLook('nowhere').$3, Icons.explore_outlined);
  });
}
