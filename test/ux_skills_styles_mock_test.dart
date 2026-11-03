// Mock: three more ways to draw version A of the Skills tab
// (docs/proposals/skills-styles.md): A2 one branch open at a time, A3 a bar
// that stays and depth as silhouettes, A4 the standing grid. skills-a.png is
// the A they sit next to. Drawn only with UX_SHOTS (a folder):
//   UX_SHOTS=docs/ux-shots flutter test test/ux_skills_styles_mock_test.dart
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
import 'ux_skills_styles_parts.dart';
import 'support/fonts.dart';

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
    await tester.runAsync(loadAppFonts);
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

  testWidgets('A2, A3, A4', (tester) async {
    final (one, mid) = await scenes(tester);
    await board(
      tester,
      'skills-a2.png',
      [
        (one, 412.0, 'A2 · level 1', const A2Tree(openIndex: 0, tabCounts: 1)),
        (mid, 412.0, 'A2 · mid game', const A2Tree(openIndex: 0, tabCounts: 7)),
        (
          mid,
          320.0,
          'A2 · mid game, 320 px',
          const A2Tree(openIndex: 0, tabCounts: 7)
        ),
      ],
      notes: const NotesPanel(title: 'A2 · One branch at a time', sections: [
        (
          'What changes from A',
          'The three columns become three rows. The branch you are working on is open as a short list (icon, name, what it does, or who offers it and at what standing); the others are one line with four beads.'
        ),
        (
          'Why',
          'Names get a full line instead of a narrow column, so nothing is cut at 320 px; the screen is as tall as one branch plus two rails at every level.'
        ),
        (
          'Cost',
          'You no longer see the three trees side by side, so comparing branches takes a tap. A tap on a rail opens it and folds the open one.'
        ),
        ('Needs from Core', 'Nothing.'),
      ]),
    );
    await board(
      tester,
      'skills-a3.png',
      [
        (one, 412.0, 'A3 · level 1', const A3Tree(tabCounts: 1)),
        (mid, 412.0, 'A3 · mid game', const A3Tree(tabCounts: 7)),
        (mid, 320.0, 'A3 · mid game, 320 px', const A3Tree(tabCounts: 7)),
      ],
      notes: const NotesPanel(
          title: 'A3 · A bar that stays, depth as shapes',
          sections: [
            (
              'What changes from A',
              'The columns stay. A bar above the tree never scrolls away: the offer waiting (or the next one and who makes it), and the essence pill. Below the next skill of each branch, the deeper ones are grey shapes with the standing a clan asks, not dots.'
            ),
            (
              'Why',
              'The two things you act on are always in view; the shapes show how far each branch goes and what it asks, without naming skills you cannot take yet.'
            ),
            (
              'Cost',
              'The bar takes about 48 px of the screen at all times. The shapes put four nodes per column back on the first screen (smaller than a full node, but taller than the dots of A).'
            ),
            ('Needs from Core', 'Nothing.'),
          ]),
    );
    await board(
      tester,
      'skills-a4.png',
      [
        (one, 412.0, 'A4 · level 1', const A4Tree(tabCounts: 1)),
        (mid, 412.0, 'A4 · mid game', const A4Tree(tabCounts: 7)),
        (mid, 320.0, 'A4 · mid game, 320 px', const A4Tree(tabCounts: 7)),
      ],
      notes: const NotesPanel(title: 'A4 · The standing grid', sections: [
        (
          'The idea',
          'The rule that matters is that a clan offers a skill once you stand high enough with it. So the tree is a grid: branches across, the standing each depth asks down the side, the clan and your standing with it above each column. The rows a clan can offer now are lit.'
        ),
        (
          'Level 1',
          'Unknown or Wary with every clan: only the top row is lit. The player sees at once that the lower rows need standing with the clan above, which tells them what the clans screen is for.'
        ),
        (
          'Mid game',
          'Friendly with the Compact: the Bulwark column’s two top rows are lit; Vanguard (Wary) and Warlord (Unknown) stay on the top row; Stoneward has no clan, so nothing is lit. The skill names appear on what is known or next; the rest are shapes.'
        ),
        (
          'Cost',
          'A new way to read the tree; the skills are in a grid of cells rather than a chain, so the line between a branch’s skills is gone.'
        ),
        ('Needs from Core', 'Nothing: the standing is read from the session.'),
      ]),
    );
  });
}
