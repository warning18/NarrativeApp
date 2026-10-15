// The rival hunter's mercy choice (hunter_mercy.dart) as a card: the
// hunter's portrait over its clan's colour, what Perception reads of them,
// two options that say what they cost; and the level-up pop-up's line for
// what the patron gave with the level (patron_stats.dart).
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/clans_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/level_up_dialog.dart';
import 'package:narrative_data_app/widgets/mercy_dialog.dart';

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

/// A picture of the page (set UX_SHOTS to a folder).
Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) return;
  await tester.runAsync(() async {
    for (final e in find.byType(Image).evaluate()) {
      await precacheImage((e.widget as Image).image, e);
    }
  });
  await tester.pump(const Duration(milliseconds: 300));
  await tester.runAsync(() async {
    final boundary =
        _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Widget _app(Widget home) => MaterialApp(
      theme: buildAppTheme(const ColorScheme.dark()),
      builder: (context, child) => RepaintBoundary(key: _shotKey, child: child),
      home: home,
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (Platform.environment['UX_SHOTS'] != null) await _loadFonts();
  });

  final factions = parseFactions(
      jsonDecode(File('assets/gamedata/factions.json').readAsStringSync())
          as Map<String, dynamic>);

  /// Opens the mercy card; [answer] fills when a choice is made.
  Future<void> open(WidgetTester tester, List<bool> answer,
      {({String side, bool close})? read,
      AppLanguage lang = AppLanguage.en}) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(Builder(
      builder: (context) => TextButton(
        onPressed: () async => answer.add(await showMercyDialog(context,
            enemyId: 'vigil_spearman_halvard',
            name: 'Halvard',
            clan: factions['dominion'],
            lang: lang,
            read: read)),
        child: const Text('go'),
      ),
    )));
    await tester.tap(find.text('go'));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('spare returns true, with what it costs and gives',
      (tester) async {
    final answer = <bool>[];
    await open(tester, answer);
    expect(find.byKey(const Key('mercy_dialog')), findsOneWidget);
    expect(find.text('Halvard yields.'), findsOneWidget);
    expect(find.textContaining('+3'), findsOneWidget);
    expect(find.textContaining('\u22122'), findsOneWidget);
    // No Perception, no read.
    expect(find.byKey(const Key('mercy_read_good')), findsNothing);
    await _shot(tester, 'mercy-dialog-plain');
    await tester.tap(find.byKey(const Key('mercy_spare')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(answer, [true]);
  });

  testWidgets('finish returns false; a read shows the hunter\'s side',
      (tester) async {
    final answer = <bool>[];
    await open(tester, answer, read: (side: 'evil', close: true));
    expect(find.byKey(const Key('mercy_read_evil')), findsOneWidget);
    await _shot(tester, 'mercy-dialog-read');
    await tester.tap(find.byKey(const Key('mercy_finish')), warnIfMissed: true);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('mercy_dialog')), findsNothing);
    expect(answer, [false]);
  });

  /// The level-up pop-up for a character whose clan log is [log] on [day].
  Future<void> levelUp(
      WidgetTester tester, int day, List<StandingLogEntry> log) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [factionsProvider.overrideWithValue(factions)],
      child: _app(Consumer(
        builder: (context, ref, _) => TextButton(
          onPressed: () => showLevelUpDialog(context, ref, newLevel: 3),
          child: const Text('go'),
        ),
      )),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    container.read(playerSessionProvider);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    final base =
        PlayerSession.fromJson({'professionId': 'warrior', 'day': day});
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(
            base.copyWith(politics: base.politics.copyWith(standingLog: log))));
    await tester.tap(find.text('go'));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('the level-up pop-up names what the patron gave', (tester) async {
    await levelUp(tester, 4, [
      const StandingLogEntry(
          chapter: 1,
          day: 4,
          cause: 'patron:dominion',
          factionId: 'dominion',
          note: '+1 Strength, +5 max health',
          noteFr: '+1 Force, +5 vie max'),
    ]);
    expect(find.byKey(const Key('level_up_patron_line')), findsOneWidget);
    expect(find.textContaining('favour: +1 Strength, +5 max health'),
        findsOneWidget);
    await _shot(tester, 'level-up-patron-line');
  });

  testWidgets('a gift of another day is not shown', (tester) async {
    await levelUp(tester, 9, [
      const StandingLogEntry(
          chapter: 1,
          day: 4,
          cause: 'patron:dominion',
          factionId: 'dominion',
          note: '+1 Strength'),
    ]);
    expect(find.byKey(const Key('level_up_patron_line')), findsNothing);
  });
}
