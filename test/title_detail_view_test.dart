// The title sheet: the clan's banner, the title's badge in the clan's
// colour, the effect in a card, the words last. UX_SHOTS=<dir> writes a
// picture of each case.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/title_detail_view.dart';

Map<String, dynamic> _data(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

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

Future<void> _open(
  WidgetTester tester, {
  required TitleDef title,
  required Faction? faction,
  bool worn = false,
  AppLanguage language = AppLanguage.en,
  Brightness brightness = Brightness.dark,
  VoidCallback? onToggle,
}) async {
  tester.view.physicalSize = const Size(390 * 2, 844 * 2);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: buildAppTheme(brightness == Brightness.dark
        ? const ColorScheme.dark()
        : const ColorScheme.light()),
    builder: (context, child) => RepaintBoundary(key: _shotKey, child: child),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => showTitleSheet(context,
                title: title,
                faction: faction,
                language: language,
                worn: worn,
                onToggle: onToggle),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) return;
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
  late Map<String, TitleDef> titles;
  late Map<String, Faction> factions;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await _loadFonts();
    titles = {
      for (final e in _data('titles').entries)
        e.key: TitleDef.fromJson(e.key, (e.value as Map).cast()),
    };
    factions = {
      for (final e in _data('factions').entries)
        if (e.value is Map)
          e.key: Faction.fromJson(e.key, (e.value as Map).cast()),
    };
  });

  testWidgets('Road Dust shows the Penitents, its effect and its words',
      (tester) async {
    var toggled = 0;
    await _open(tester,
        title: titles['road_dust']!,
        faction: factions['penitents'],
        onToggle: () => toggled++);
    expect(find.text('Road Dust'), findsOneWidget);
    expect(find.byKey(const Key('title_badge')), findsOneWidget);
    expect(find.byKey(const Key('title_banner')), findsOneWidget);
    expect(find.byKey(const Key('title_clan')), findsOneWidget);
    expect(find.text('Granted by'), findsOneWidget);
    expect(find.byKey(const Key('title_effect')), findsOneWidget);
    expect(find.byKey(const Key('title_line')), findsOneWidget);
    expect(find.text('Wear'), findsOneWidget);
    await _shot(tester, 'title_road_dust');
    await tester.tap(find.byKey(const Key('title_toggle')));
    await tester.pumpAndSettle();
    expect(toggled, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a worn title offers to be taken off; a bad one has no action',
      (tester) async {
    await _open(tester,
        title: titles['road_dust']!,
        faction: factions['penitents'],
        worn: true,
        language: AppLanguage.fr,
        onToggle: () {});
    expect(find.text('Retirer'), findsOneWidget);
    expect(find.text('Porté'), findsOneWidget);
    await _shot(tester, 'title_worn_fr');
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    final bad = titles.values.firstWhere((t) => t.negative);
    await _open(tester,
        title: bad,
        faction: factions[bad.factionId],
        brightness: Brightness.light,
        onToggle: () {});
    expect(find.byKey(const Key('title_toggle')), findsNothing);
    await _shot(tester, 'title_bad_light');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a title with no clan says it was earned on the road',
      (tester) async {
    await _open(tester,
        title: titles['road_dust']!, faction: null, onToggle: () {});
    expect(find.text('Earned on the road'), findsOneWidget);
    expect(find.byKey(const Key('title_banner')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
