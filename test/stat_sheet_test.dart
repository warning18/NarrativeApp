// A stat's popin on the Character radar (v1.469): a tap on an ability's name
// opens its number, what a point does for this hero, and where it comes from
// (the ledger: picks, the patron...), at phone width, in English and in
// French at 320 px. UX_SHOTS (a folder) saves pictures.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/skills_radar_card.dart';

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
  await tester.pump(const Duration(milliseconds: 400));
  await tester.runAsync(() async {
    final boundary =
        _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('the popin: the number, what a point does, where it comes from',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    if (Platform.environment['UX_SHOTS'] != null) await _loadFonts();
    tester.view.physicalSize = const Size(360, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      child: RepaintBoundary(
        key: _shotKey,
        child: MaterialApp(
          theme: buildAppTheme(ColorScheme.fromSeed(seedColor: Colors.brown)),
          home: const Scaffold(
            body: SingleChildScrollView(child: SkillsRadarCard()),
          ),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'ranger',
          'dexterity': 16,
          'statSources': {
            'pick:duelist': {'dexterity': 2},
            'pick:hunter': {'dexterity': 1},
            'patron:open_hand': {'dexterity': 1},
          },
        })));
    await _settle(tester);

    // Nothing is open; the radar says it can be tapped.
    expect(find.byKey(const Key('stat_sheet_dexterity')), findsNothing);
    expect(find.byKey(const Key('character_radar_hint')), findsOneWidget);

    // A tap on DEX opens its sheet.
    await tester.tap(find.text('DEX'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('stat_sheet_dexterity')), findsOneWidget);
    // The exact number, the session's.
    expect(tester.widget<Text>(find.byKey(const Key('stat_sheet_value'))).data,
        '16');
    // What a point does for a ranger: damage and dodge.
    final does =
        tester.widget<Text>(find.byKey(const Key('stat_sheet_effects'))).data!;
    expect(does, allOf(contains('damage'), contains('dodge')));
    // Where it comes from: the picks add up their paths, the patron's gift is
    // the Open Hand's, and the rows add up to the number.
    expect(find.byKey(const Key('stat_src_pick')), findsOneWidget);
    expect(find.text('+3'), findsOneWidget,
        reason: 'two picks and one: the picks line is +3');
    expect(find.byKey(const Key('stat_src_patron')), findsOneWidget);
    expect(find.text('The Open Hand'), findsOneWidget);
    await _shot(tester, 'stat-sheet-dex-en');
    expect(tester.takeException(), isNull);

    // French, and the narrowest phone.
    await tester.tapAt(const Offset(180, 20));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.fr));
    tester.view.physicalSize = const Size(320, 640);
    await _settle(tester);
    await tester.tap(find.text('DEX'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('stat_sheet_dexterity')), findsOneWidget);
    expect(
        tester.widget<Text>(find.byKey(const Key('stat_sheet_effects'))).data,
        startsWith('Chaque point'));
    await _shot(tester, 'stat-sheet-dex-fr-320');
    expect(tester.takeException(), isNull);
  });
}
