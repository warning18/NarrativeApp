// The chapter signpost (v1.432): "Chapter 4 asks for level 9. You are level
// 6." on the camp's chapter card and as a chip on the Journey map, only while
// the party is under the level; the whole sentence on a tap. EN and FR, at
// phone width and at 320 px. UX_SHOTS (a folder) saves pictures.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/chapter_loop.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/world_map.dart' show MapLook;
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/chapter_loop_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/level_signpost.dart';

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

ChapterLevelAdvice _advice({int player = 6, String note = ''}) =>
    ChapterLevelAdvice(
        chapter: 4, recommendedLevel: 9, playerLevel: player, note: note);

Future<ProviderContainer> _pump(WidgetTester tester, ChapterLevelAdvice? advice,
    {Size size = const Size(360, 230), AppLanguage? language}) async {
  SharedPreferences.setMockInitialValues({});
  if (Platform.environment['UX_SHOTS'] != null) await _loadFonts();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final palette = ChartPalette.of(MapLook.parchment);
  await tester.pumpWidget(ProviderScope(
    overrides: [nextChapterLevelAdviceProvider.overrideWithValue(advice)],
    child: MaterialApp(
      theme: buildAppTheme(ColorScheme.fromSeed(seedColor: Colors.brown)),
      home: Scaffold(
        body: RepaintBoundary(
          key: const Key('shot'),
          child: Container(
            color: palette.fog,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LevelSignpostRow(),
                const SizedBox(height: 16),
                LevelSignpostChip(palette: palette),
                const SizedBox(height: 8),
                LevelSignpostChip(palette: palette, compact: true),
              ],
            ),
          ),
        ),
      ),
    ),
  ));
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(() => container
      .read(appLanguageProvider.notifier)
      .setLanguage(language ?? AppLanguage.en));
  await tester.pump();
  return container;
}

Future<void> _save(WidgetTester tester, String name) async {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) return;
  await tester.runAsync(() async {
    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('shot')));
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('under the level: the card row and the map chip say so',
      (tester) async {
    await _pump(tester, _advice(note: 'The Lantern Hall bites back.'));
    expect(find.byKey(const Key('level_signpost')), findsOneWidget);
    expect(find.text('Chapter 4: level 9 advised (you: 6)'), findsOneWidget);
    expect(find.text('Ch. 4 · lvl 9'), findsOneWidget);
    expect(find.text('Lvl 9'), findsOneWidget);
    await _save(tester, 'signpost-en');

    // A tap on the row, or on the chip, reads the whole sentence and
    // Narrative's line.
    await tester.tap(find.text('Chapter 4: level 9 advised (you: 6)'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
        find.textContaining('Chapter 4 asks for level 9. You are level 6. '
            'The Lantern Hall bites back.'),
        findsOneWidget);
  });

  testWidgets('at the level, or with no advice: nothing', (tester) async {
    await _pump(tester, _advice(player: 9));
    expect(find.byKey(const Key('level_signpost')), findsNothing);
    expect(find.byKey(const Key('journey_level_signpost')), findsNothing);
  });

  testWidgets('no advice at all: nothing', (tester) async {
    await _pump(tester, null);
    expect(find.byKey(const Key('level_signpost')), findsNothing);
    expect(find.byKey(const Key('journey_level_signpost')), findsNothing);
  });

  testWidgets('French, at 320 px', (tester) async {
    await _pump(tester, _advice(note: 'La salle des Lanternes mord.'),
        size: const Size(320, 250), language: AppLanguage.fr);
    expect(find.text('Chapitre 4 : niveau 9 conseillé (vous : 6)'),
        findsOneWidget);
    expect(find.text('Ch. 4 · niv. 9'), findsOneWidget);
    expect(find.text('Niv. 9'), findsOneWidget);
    await _save(tester, 'signpost-fr-320');
    expect(tester.takeException(), isNull);
  });
}
