// The training offer as cards (training_picker.dart): an icon tile in the
// path's colour, its gains as tiles with where each stat goes, a card
// picked and then taken with the button under the cards. UX_SHOTS=<dir>
// writes a picture.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/training.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/training_provider.dart';
import 'package:narrative_data_app/screens/training_picker.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';

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

final _shotKey = GlobalKey();

Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) return;
  // The pixel icons decode off the frame loop.
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  final paths = trainingPathsFrom(
      jsonDecode(File('assets/gamedata/training_paths.json').readAsStringSync())
          as Map<String, dynamic>);

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
  });

  Future<ProviderContainer> open(WidgetTester tester, int points,
      {Brightness brightness = Brightness.dark}) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [trainingPathsProvider.overrideWith((ref) async => paths)],
      child: MaterialApp(
        theme: buildAppTheme(brightness == Brightness.dark
            ? const ColorScheme.dark()
            : const ColorScheme.light()),
        builder: (context, child) =>
            RepaintBoundary(key: _shotKey, child: child),
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: TrainingPicker(),
          ),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    container.read(playerSessionProvider);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(
            {'statPoints': points, 'professionId': 'warrior'})));
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 30));
    }
    return container;
  }

  testWidgets('three paths, each with its gains and where the stat goes',
      (tester) async {
    final container = await open(tester, 5);
    final offer = container.read(playerSessionProvider).trainingOffer;
    expect(offer, hasLength(3));
    for (final (i, c) in offer.indexed) {
      expect(find.byKey(Key('training_choice_$i')), findsOneWidget);
      expect(find.byKey(Key('training_icon_${c.pathId}')), findsOneWidget);
      for (final stat in c.gains.keys) {
        expect(
            find.byKey(Key('training_gain_${c.pathId}_$stat')), findsOneWidget);
      }
    }
    // The button waits for a pick.
    final take = find.byKey(const Key('training_take'));
    expect(tester.widget<FilledButton>(take).onPressed, isNull);
    await tester.tap(find.byKey(const Key('training_choice_1')));
    await tester.pump();
    expect(tester.widget<FilledButton>(take).onPressed, isNotNull);
    await _shot(tester, 'training_picked');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the picked path is the one taken', (tester) async {
    final container = await open(tester, 5);
    final offer = container.read(playerSessionProvider).trainingOffer;
    await tester.tap(find.byKey(const Key('training_choice_2')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('training_take')));
    for (var i = 0; i < 8; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 20));
    }
    final after = container.read(playerSessionProvider);
    expect(after.statPoints, 0);
    expect(after.trainingTaken, {offer[2].pathId: 1});
    expect(tester.takeException(), isNull);
  });

  testWidgets('a small offer reads the same, one point each', (tester) async {
    await open(tester, 1, brightness: Brightness.light);
    expect(find.text('A moment of insight'), findsOneWidget);
    expect(find.byKey(const Key('training_choice_0')), findsOneWidget);
    await _shot(tester, 'training_small_light');
    expect(tester.takeException(), isNull);
  });
}
