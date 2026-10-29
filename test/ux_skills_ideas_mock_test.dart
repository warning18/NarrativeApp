// Mock: three new ideas for the Skills tab (docs/proposals/skills-ideas.md):
// a star chart, a hand and the clans' decks, a paper doll. Level 1 and mid
// game, 412 and 320 px, on the real skills data, next to today's tab. Drawn
// only with UX_SHOTS (a folder):
//   UX_SHOTS=docs/ux-shots flutter test test/ux_skills_ideas_mock_test.dart
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

import 'package:narrative_data_app/screens/skills/skills_screen.dart';

import 'ux_skills_ideas_parts.dart';
import 'ux_skills_mock_parts.dart';
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

  testWidgets('the star chart', (tester) async {
    final (one, mid) = await scenes(tester);
    await board(
      tester,
      'skills-ideas-1-stars.png',
      [
        (
          one,
          412.0,
          'Level 1 · 412 px',
          const StarChart(focus: 0, tabCounts: 1)
        ),
        (
          mid,
          412.0,
          'Mid game · 412 px',
          const StarChart(focus: 0, tabCounts: 7)
        ),
        (
          one,
          320.0,
          'Level 1 · 320 px',
          const StarChart(focus: 0, tabCounts: 1)
        ),
        (
          mid,
          320.0,
          'Mid game · 320 px',
          const StarChart(focus: 1, tabCounts: 7)
        ),
      ],
      notes: const NotesPanel(title: '1 · The star chart', sections: [
        (
          'What it is',
          'Every branch is a constellation: a star for each of its four skills and a crown star for Mastery, on one night sky that fits the screen with no scrolling. A star lights gold when you learn the skill; the ringed star is the next one, bright when its clan can offer it now. Each constellation carries its clan’s flag and your standing with it.'
        ),
        (
          'Reading it',
          'Level 1: four dim constellations, one star ringed and bright in each branch whose clan already deals its first skill. Mid game: the Bulwark line is lit two stars deep, the next star is ringed and bright (the Compact can offer it now). A tap on a constellation puts its next skill in the card under the sky: its name, what it does, who offers it, at what standing.'
        ),
        (
          'Cost',
          'It shows state, not detail: a skill’s name and effect are one tap away. A class with more than four branches needs another cell (the shapes are drawn by branch position). The pixel icons are not on the stars; they are in the card.'
        ),
        (
          'Needs from Core',
          'Nothing: the same model, standing and offer depth as today. The star shapes are UX’s table.'
        ),
      ]),
      height: 860,
    );
  });

  testWidgets('the hand and the decks', (tester) async {
    final (one, mid) = await scenes(tester);
    await board(
      tester,
      'skills-ideas-2-decks.png',
      [
        (one, 412.0, 'Level 1 · 412 px', const HandAndDecks(tabCounts: 1)),
        (mid, 412.0, 'Mid game · 412 px', const HandAndDecks(tabCounts: 7)),
        (one, 320.0, 'Level 1 · 320 px', const HandAndDecks(tabCounts: 1)),
        (mid, 320.0, 'Mid game · 320 px', const HandAndDecks(tabCounts: 7)),
      ],
      notes:
          const NotesPanel(title: '2 · A hand and the clans’ decks', sections: [
        (
          'What it is',
          'What you know is a hand of cards, fanned at the top. What you can still learn is a deck for each branch, in its clan’s colour with its flag: the number says how many cards are left. When the clan can deal the top card now, it is turned face up with a gold edge; otherwise it stays face down and says which standing it waits for.'
        ),
        (
          'Reading it',
          'Level 1: an empty hand, “the clans deal your first card”, and the decks whose clan already stands for you turned up. Mid game: five cards in hand, and the Compact’s deck turned up on its next card while the Dominion’s waits face down for “Trusted”.'
        ),
        (
          'Cost',
          'The order inside a branch (which comes after which) is not shown, only the top card. The deeper cards are a count. It is the lightest idea of the three: nothing to scroll at 412 px.'
        ),
        (
          'Needs from Core',
          'Nothing: the top card is the first skill not known; “can deal it now” is the offer depth from standing, as today.'
        ),
      ]),
      height: 860,
    );
  });

  testWidgets('the paper doll', (tester) async {
    final (one, mid) = await scenes(tester);
    await board(
      tester,
      'skills-ideas-3-doll.png',
      [
        (one, 412.0, 'Level 1 · 412 px', const PaperDoll(tabCounts: 1)),
        (mid, 412.0, 'Mid game · 412 px', const PaperDoll(tabCounts: 7)),
        (one, 320.0, 'Level 1 · 320 px', const PaperDoll(tabCounts: 1)),
        (mid, 320.0, 'Mid game · 320 px', const PaperDoll(tabCounts: 7)),
      ],
      notes: const NotesPanel(title: '3 · The paper doll', sections: [
        (
          'What it is',
          'The hero’s outline, with each branch hung on a part of the body: off hand, sword hand, head, feet. A socket shows the deepest skill you know there (dim when you know none, a lock when nothing is left), the branch’s name, its clan and standing, and four beads for the steps. A socket glows when its clan can offer the next skill now; a card under the doll lists what is ready to be taught.'
        ),
        (
          'Reading it',
          'Level 1: four sockets with their clans, the ones that can already be fed glowing, and “Ready to be taught” listing them. Mid game: the sockets show the skills in use, the beads fill from the left.'
        ),
        (
          'Cost',
          'A branch is tied to a body part by its position, so the slot names fit the warrior best (shield, sword, helm, boots). Other classes’ branches would carry a slot name of their own.'
        ),
        (
          'Needs from Core',
          'Nothing to ship it; to name the slots right for every class, an optional `slot` on each branch in skill_trees.json (Core’s file), else the four slot names by order.'
        ),
      ]),
      height: 860,
    );
  });

  Widget today() => const SkillsScreen();

  /// An idea under a "Skills" bar, as the real screen has its own.
  Widget withBar(Widget body) => Builder(builder: (context) {
        final theme = Theme.of(context);
        return Column(children: [
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: InkColors.of(context).seam)),
            ),
            child: Row(children: [
              Expanded(
                child: Text('Skills',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontFamily: InkFonts.display)),
              ),
              Icon(Icons.info_outline,
                  size: 22, color: theme.colorScheme.onSurface),
            ]),
          ),
          Expanded(child: ClipRect(child: body)),
        ]);
      });

  for (final width in [412.0, 320.0]) {
    testWidgets('side by side at ${width.toInt()}', (tester) async {
      final (_, mid) = await scenes(tester);
      await board(
        tester,
        'skills-ideas-compare-${width.toInt()}.png',
        [
          (mid, width, 'Today · mid game', today()),
          (
            mid,
            width,
            '1 · Star chart',
            withBar(const StarChart(focus: 0, tabCounts: 7))
          ),
          (
            mid,
            width,
            '2 · Hand and decks',
            withBar(const HandAndDecks(tabCounts: 7))
          ),
          (
            mid,
            width,
            '3 · Paper doll',
            withBar(const PaperDoll(tabCounts: 7))
          ),
        ],
        height: 860,
        bare: true,
      );
    });
  }
}
