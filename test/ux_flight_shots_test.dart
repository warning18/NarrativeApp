// (picture test, drawn only with UX_SHOTS=<folder>) The road from the Sleeper's Face
// to the White Wells, frame by frame: the map flight, then the crossing. A move along a world road is walked on the World view (v1.548): the Dune
// Sea road from the Sleeper's Face by the Dry Wadi to the White Wells is a leg
// between two places, never drawn on a district's plan. The District and Town
// views are for places: arriving at one shows its own view again.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/screens/land_crossing_screen.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';
import 'support/pump.dart';
import 'support/open_game.dart';

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

Future<void> _shot(WidgetTester tester, String dir, String name,
    {Finder? within}) async {
  final boundaries = tester.renderObjectList<RenderRepaintBoundary>(
      within ?? find.byType(RepaintBoundary));
  final b = boundaries.first;
  late Uint8List bytes;
  await tester.runAsync(() async {
    final image = await b.toImage(pixelRatio: 1.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    bytes = data!.buffer.asUint8List();
  });
  File('$dir/$name.png').writeAsBytesSync(bytes);
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  testWidgets('the road to the White Wells, frame by frame', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(400, 860));
    final pace = worldMoveTimeScale;
    addTearDown(() => worldMoveTimeScale = pace);
    worldMoveTimeScale = 1;
    await tester.runAsync(_loadFonts);
    final container = await openGame(tester);
    final play = container.read(storyPlayProvider.notifier);
    container.read(homeTabIndexProvider.notifier).state = journeyTabIndex;
    await settleApp(tester);
    Future<void> clearCards() async {
      for (var i = 0; i < 3; i++) {
        Navigator.of(tester.element(find.byType(JourneyScreen)))
            .popUntil(isGameRoute);
        await tester.pump(const Duration(seconds: 1));
      }
    }

    play.jumpTo('1130');
    await settleApp(tester);
    play.jumpTo('1140');
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 4));
    await clearCards();
    final dir = shots!;
    await _shot(tester, dir, '1-place');
    await tester.tap(find.byKey(const ValueKey('journey_step_2')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('journey_go')));
    var n = 0;
    var frame = 2;
    for (var i = 0; i < 400; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(LandCrossingScreen).evaluate().isNotEmpty) break;
      if (find.byType(JourneyWorldMap).evaluate().isNotEmpty) {
        n++;
        if (n == 5 || n == 20 || n == 30) {
          await _shot(tester, dir, '${frame++}-flight-$n');
        }
      }
    }
    for (var i = 0;
        i < 30 && find.byType(LandCrossingScreen).evaluate().isEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (find.byType(LandCrossingScreen).evaluate().isNotEmpty) {
      for (var ms = 0; ms < 500; ms += 50) {
        final rise = find.byKey(const ValueKey('crossing_rise'));
        // ignore: avoid_print
        print(
            'rise $ms ms: ${rise.evaluate().isEmpty ? '-' : tester.getSize(rise.last).height}');
        if (ms == 0 || ms == 100) {
          await _shot(tester, dir, '$frame-map-under-$ms');
          await _shot(tester, dir, '${frame++}-page-risen-$ms',
              within: find
                  .ancestor(of: rise, matching: find.byType(RepaintBoundary))
                  .first);
        }
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pump(const Duration(milliseconds: 600));
      await _shot(tester, dir, '${frame++}-crossing-start');
      await tester.pump(const Duration(seconds: 2));
      await _shot(tester, dir, '${frame++}-crossing-later');
    }
  }, skip: shots == null);
}
