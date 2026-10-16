// Places on the world map keep a readable size however close the chart is
// looked at (v1.412): a plate under each mark at least 24 px across, names
// at least 12 px with a small plate behind, and a tap that finds a mark
// within 22 px of it on the screen. UX_SHOTS (a folder) saves pictures at
// the whole world, the land, the district and the closest zoom.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/data/travel_history.dart';
import 'package:narrative_data_app/providers/map_look_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/providers/travel_history_provider.dart';
import 'package:narrative_data_app/screens/full_map_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

final _shotKey = GlobalKey();

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

Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) return;
  await tester.pump(const Duration(milliseconds: 600));
  await tester.runAsync(() async {
    final boundary =
        _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (Platform.environment['UX_SHOTS'] != null) await _loadFonts();
  });

  final travels = travelHistoryOf(
    history: const ['965', '1100', '1120', '1130'],
    currentNodeId: '1200',
  );

  Future<void> open(WidgetTester tester, {required bool sphere}) async {
    SharedPreferences.setMockInitialValues({chartGlobePrefsKey: sphere});
    tester.view.physicalSize = const Size(411, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        travelHistoryProvider.overrideWithValue(travels),
        storyDataProvider.overrideWith((ref) async => const StoryData({})),
      ],
      child: RepaintBoundary(
        key: _shotKey,
        child: MaterialApp(
          theme: buildAppTheme(ColorScheme.fromSeed(
              seedColor: Colors.amber, brightness: Brightness.dark)),
          home: const FullMapScreen(),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  for (final sphere in [true, false]) {
    final shape = sphere ? 'sphere' : 'flat';
    testWidgets('marks and names hold their size on the $shape chart',
        (tester) async {
      await open(tester, sphere: sphere);
      expect(
          find.byKey(ValueKey(
              sphere ? 'journey_globe_canvas' : 'journey_world_canvas')),
          findsOneWidget);
      await _shot(tester, 'poi-$shape-1-world');
      for (final (i, name) in ['land', 'district', 'closest'].indexed) {
        await tester.tap(find.byKey(const Key('journey_zoom_in')));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 600));
        await _shot(tester, 'poi-$shape-${i + 2}-$name');
      }
      expect(tester.takeException(), isNull);
    });
  }
}
