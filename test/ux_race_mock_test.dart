// Mock: a clearer race and profession choice (docs/proposals/
// race-profession-choice.md). First the real screen at 320 and 412 px (the
// "before"), then the proposal drawn from the same data. Drawn only with
// UX_SHOTS (a folder):
//   UX_SHOTS=docs/ux-shots flutter test test/ux_race_mock_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/screens/race_profession_screen.dart';

import 'ux_race_mock_parts.dart';

Future<void> _loadFonts() async {
  for (final (family, files) in const [
    ('PixelifySans', ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']),
    (
      'Spectral',
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      final file = File('assets/fonts/$f');
      if (!file.existsSync()) continue;
      loader
          .addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
    }
    await loader.load();
  }
  final icons = File(
      '/tmp/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await loader.load();
  }
}

Future<void> _settle(WidgetTester tester, {int n = 4}) async {
  for (var i = 0; i < n; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  if (shots == null) {
    test('the race and profession mock is drawn only with UX_SHOTS', () {});
    return;
  }

  setUp(rootBundle.clear);

  /// The real screen at [width], captured empty and with a Dwarf Warrior.
  Future<(ui.Image, ui.Image)> real(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 780);
    final key = GlobalKey();
    await tester.pumpWidget(ProviderScope(
      key: UniqueKey(),
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme:
              buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.light)),
          home: const RaceProfessionScreen(),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    container.read(playerSessionProvider);
    await _settle(tester, n: 6);
    late ui.Image empty;
    late ui.Image both;
    Future<ui.Image> grab() async {
      late ui.Image image;
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        image = await b.toImage(pixelRatio: 1.5);
      });
      return image;
    }

    empty = await grab();
    await tester.tap(find.text('Dwarf'));
    await _settle(tester, n: 3);
    await tester.tap(find.text('Warrior'));
    await _settle(tester, n: 3);
    both = await grab();
    return (empty, both);
  }

  Widget picture(ui.Image image, double width) => RawImage(
        image: image,
        width: width,
        height: image.height / 1.5,
        fit: BoxFit.fill,
      );

  Future<void> board(
      WidgetTester tester, String file, List<(double, String, Widget)> frames,
      {double height = 780, Widget? notes, bool bare = false}) async {
    final theme =
        buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.light));
    var width = 48.0 + 24 * frames.length;
    for (final f in frames) {
      width += f.$1;
    }
    if (notes != null) width += 300;
    tester.view.physicalSize = Size(width, height + 110);
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Material(
          color: const Color(0xFF17151B),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final f in frames) ...[
                  Column(children: [
                    ProviderScope(
                      key: UniqueKey(),
                      child: Phone(
                          width: f.$1, height: height, bare: bare, child: f.$3),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: f.$1,
                      child: Text(f.$2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'Spectral',
                              fontSize: 15,
                              color: Color(0xFFEDE6DC))),
                    ),
                  ]),
                  const SizedBox(width: 24),
                ],
                if (notes != null) notes,
              ],
            ),
          ),
        ),
      ),
    ));
    await _settle(tester, n: 6);
    await tester.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$file').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('the real screen, then the proposal', (tester) async {
    await tester.runAsync(_loadFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    final (e320, b320) = await real(tester, 320);
    final (e412, b412) = await real(tester, 412);
    await board(
      tester,
      'race-today.png',
      [
        (320, 'Today · nothing picked · 320 px', picture(e320, 320 - 4)),
        (320, 'Today · a Dwarf Warrior · 320 px', picture(b320, 320 - 4)),
        (412, 'Today · nothing picked · 412 px', picture(e412, 412 - 4)),
        (412, 'Today · a Dwarf Warrior · 412 px', picture(b412, 412 - 4)),
      ],
      bare: true,
    );

    await board(
      tester,
      'race-after-412.png',
      [
        (412, '1 · people, nothing picked', const PickerBody(step: 0)),
        (
          412,
          '1 · a Dwarf, opened',
          const PickerBody(step: 0, raceId: 'dwarf', open: true)
        ),
        (
          412,
          '2 · a Warrior, opened',
          const PickerBody(
              step: 1, raceId: 'dwarf', professionId: 'warrior', open: true)
        ),
        (
          412,
          'Both picked: who you will play as',
          const PickerBody(
              step: 1,
              raceId: 'dwarf',
              professionId: 'warrior',
              showSummary: true)
        ),
      ],
      notes: const NotesPanel(title: 'Choosing who you are', sections: [
        (
          'Before any detail',
          'Each choice is a card: its mark, name and tag, one line on how it plays, three or four stat chips, and the clans behind it as small discs with their count. No paragraph.'
        ),
        (
          'The clans',
          'The discs are clansOfRace / clansOfProfession. "These clans will court you" names each one and says why: a people’s clans sponsor its heritage branch, a calling’s clans each offer one of its three branches. A tap on a clan will open what it offers.'
        ),
        (
          'What it unlocks',
          'A people: its heritage branch, its power medium, its starting skill. A calling: its three branches, what its gear scales with, a die and spells for casters.'
        ),
        (
          'Compare',
          'A Compare button on each step opens two choices side by side (see the 320 px picture).'
        ),
        (
          'After both picks',
          'One summary card: "You will play as a Dwarf Warrior", how it plays, and the clans that will come first (those behind both choices lead).'
        ),
        (
          'Fields needed from Narrative',
          '`playstyle` and `playstyleFr` on every race and profession: one short line each. They now exist (Narrative\u2019s PR #566); the mock shows those lines.'
        ),
      ]),
    );

    await board(
      tester,
      'race-after-320.png',
      [
        (320, '1 · people, nothing picked', const PickerBody(step: 0)),
        (
          320,
          '2 · a Warrior, opened',
          const PickerBody(
              step: 1, raceId: 'dwarf', professionId: 'warrior', open: true)
        ),
        (
          320,
          'Compare two callings',
          const CompareSheet(folder: 'professions', a: 'warrior', b: 'mage')
        ),
        (
          320,
          'Both picked',
          const PickerBody(
              step: 1,
              raceId: 'dwarf',
              professionId: 'warrior',
              showSummary: true)
        ),
      ],
    );
  });
}
