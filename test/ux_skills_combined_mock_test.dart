// Mock: A4's standing grid with A2's rails, in one picture
// (docs/proposals/skills-combined.md): level 1 and mid game, 412 and 320 px, on
// the real skills data. Drawn only with UX_SHOTS (a folder):
//   UX_SHOTS=docs/ux-shots flutter test test/ux_skills_combined_mock_test.dart
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

import 'ux_skills_mock_parts.dart';
import 'ux_skills_combined_parts.dart';

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

const _levelOne = {
  'raceId': 'human',
  'professionId': 'warrior',
  'characterName': 'Mara',
};

const _midGame = {
  'raceId': 'human',
  'professionId': 'warrior',
  'characterName': 'Mara',
  'level': 12,
  'skillEssence': 2600,
  'pendingOffers': [
    {'source': 'level'},
  ],
  'unlockedSkillIds': [
    'warrior_shield_bash',
    'bulwark_stance',
    'power_strike',
    'guard_break',
    'rallying_shout',
    'human_resolve',
  ],
  'skillTiers': {
    'warrior_shield_bash': 3,
    'power_strike': 2,
    'bulwark_stance': 1,
  },
  'builtHouseIds': ['skillwright'],
  // The Compact knows the hero; the others do not yet.
  'politics': {
    'standings': {'compact': 14},
  },
};

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  if (shots == null) {
    test('the skills mock is drawn only with UX_SHOTS', () {});
    return;
  }

  setUp(rootBundle.clear);

  Future<ProviderContainer> scene(
      WidgetTester tester, Map<String, dynamic> session) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(playerSessionProvider);
    await _settle(tester);
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          ...session,
          'flags': ['feat_clans', 'feat_skills'],
        })));
    await _settle(tester, n: 3);
    return container;
  }

  /// [frames] side by side on a dark board, each with a caption; written to
  /// [file].
  Future<void> board(WidgetTester tester, String file,
      List<(ProviderContainer, double, String, Widget)> frames,
      {double height = 780, Widget? notes, bool bare = false}) async {
    final theme =
        buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.light));
    var width = 48.0 + 24 * frames.length;
    for (final f in frames) {
      width += f.$2;
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
                    UncontrolledProviderScope(
                      container: f.$1,
                      child: Phone(
                          width: f.$2, height: height, bare: bare, child: f.$4),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: f.$2,
                      child: Text(f.$3,
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
    await _settle(tester, n: 4);
    await tester.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$file').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  Future<(ProviderContainer, ProviderContainer)> scenes(
      WidgetTester tester) async {
    await tester.runAsync(_loadFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    final one = await scene(tester, _levelOne);
    final mid = await scene(tester, _midGame);
    return (one, mid);
  }

  testWidgets('A4 with A2 rails', (tester) async {
    final (one, mid) = await scenes(tester);
    await board(
      tester,
      'skills-a42.png',
      [
        (
          one,
          412.0,
          'Level 1 · 412 px',
          const A42Tree(openIndex: 0, tabCounts: 1)
        ),
        (
          mid,
          412.0,
          'Mid game · 412 px',
          const A42Tree(openIndex: 0, tabCounts: 7)
        ),
        (
          one,
          320.0,
          'Level 1 · 320 px',
          const A42Tree(openIndex: 0, tabCounts: 1)
        ),
        (
          mid,
          320.0,
          'Mid game · 320 px',
          const A42Tree(openIndex: 1, tabCounts: 7)
        ),
      ],
      notes: const NotesPanel(title: 'A4 with A2 rails', sections: [
        (
          'What it is',
          'A4’s idea (the rule of the game: a clan offers a skill once you stand high enough with it) in A2’s shape (one branch open at a time as a short list; the others one line with four beads). Every rail says its clan and the standing you have with it, so all three standings are in view; the open branch lists its four depths down the standing each asks.'
        ),
        (
          'Lit rows',
          'A row is lit (gold) when the clan can offer it now: the standing it asks is the one you have, or less. A skill known shows what it does; the next one is named, and says either “The clan can offer it now” or what standing it waits for; deeper ones stay “Further on”.'
        ),
        (
          'Level 1',
          'Unknown or Wary with every clan: only the top row of the open branch is lit. The rails tell the player at once which clan stands behind each branch.'
        ),
        (
          'Mid game',
          '412: Bulwark open, Friendly with the Compact, so two rows are lit and Iron Stance waits for “Trusted”. 320: Vanguard open (Wary with the Dominion: only the top row).'
        ),
        (
          'Cost',
          'The grid across is gone: you do not see the three branches’ rows side by side, only one open at a time (a tap on a rail opens it). A branch with no clan (Stoneward) says so.'
        ),
        (
          'Needs from Core',
          'Nothing: standing is read from the session’s politics, the depth it allows from skillIndexCapFor.'
        ),
      ]),
      height: 860,
    );
  });
}
