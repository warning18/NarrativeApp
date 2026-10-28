// Mock: three ways to calm the Skills tab (docs/proposals/skills-versions.md).
// skills-today.png is the real screen at 320 and 412 px, level 1 and mid
// game; skills-a/b/c.png are the three versions, drawn from the same data. Drawn only with
// UX_SHOTS (a folder):
//   UX_SHOTS=docs/ux-shots flutter test test/ux_skills_mock_test.dart
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

import 'ux_skills_mock_parts.dart';

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

  testWidgets('today', (tester) async {
    final (one, mid) = await scenes(tester);
    const real = SkillsScreen();
    Widget bare(Widget w) => w;
    await board(
        tester,
        'skills-today.png',
        [
          (
            one,
            320.0,
            'Today · level 1 · 320 px (2 screens more below)',
            bare(real)
          ),
          (one, 412.0, 'Today · level 1 · 412 px', bare(real)),
          (mid, 320.0, 'Today · mid game · 320 px (3 more below)', bare(real)),
          (mid, 412.0, 'Today · mid game · 412 px', bare(real)),
        ],
        bare: true);
  });

  testWidgets('version A', (tester) async {
    final (one, mid) = await scenes(tester);
    await board(
      tester,
      'skills-a.png',
      [
        (
          one,
          412.0,
          'A · level 1',
          const ATree(tabCounts: 1, showSpells: false)
        ),
        (
          mid,
          412.0,
          'A · mid game',
          const ATree(tabCounts: 7, showSpells: false)
        ),
        (
          mid,
          320.0,
          'A · mid game, 320 px',
          const ATree(tabCounts: 7, showSpells: false)
        ),
      ],
      notes: const NotesPanel(title: 'A · Today, with less on it', sections: [
        (
          'Level 1',
          'No purse (nothing waits, no essence). Only the first skill of each branch is drawn; the rest are dots. Heritage and reputation are folded. One screen, no scrolling.'
        ),
        (
          'Mid game',
          'One line of two pills: the offer waiting, and essence against the cheapest next tier (lit when a tier can be raised). Known skills and the next one of each branch in full; deeper ones are dots until they are next. The Spells tab is for a class that has spells.'
        ),
        (
          'How a skill is learned',
          'As today: a clan offers it (a level, a boss, a quest). Tap a lit skill: who offers it and at what standing.'
        ),
        (
          'Merges and upgrades',
          'As today: a known skill’s sheet has Raise tier (essence); the essence pill lights when one is affordable; the Craft card stays at the bottom of My skills once the Skillwright stands.'
        ),
        (
          'Taken off the first screen',
          'The rules line, both purse notes, the branch descriptions (a tap on a branch name), clan names on locked skills, the Mastery labels until a branch is learned.'
        ),
        ('Needs from Core', 'Nothing.'),
      ]),
    );
  });

  testWidgets('version B', (tester) async {
    final (one, mid) = await scenes(tester);
    await board(
      tester,
      'skills-b.png',
      [
        (one, 412.0, 'B · level 1', const BPage()),
        (mid, 412.0, 'B · mid game', const BPage()),
        (mid, 320.0, 'B · mid game, 320 px', const BPage()),
      ],
      notes: const NotesPanel(title: 'B · A first page that grows', sections: [
        (
          'Level 1',
          'No tabs, no tree. What you know, then what the clans can offer next (the first skill of each branch, who offers it, at what standing), and a link to the whole tree. Nothing about essence, spells or merging yet.'
        ),
        (
          'It opens up as the hero grows',
          'The offer banner while one waits. The essence line after the first skill that has tiers; it becomes a Raise button when essence is enough. The Merge card when the Skillwright stands. A Spells row when the class has spells. The whole tree stays one tap away, as it is today.'
        ),
        (
          'How a skill is learned',
          'As today: a clan’s offer. “Next from the clans” says who and at what standing, so the player knows what to work toward.'
        ),
        (
          'Merges and upgrades',
          'Raise is one purple button (it lists the skills that can rise; a skill\u2019s sheet has the tiers). Merge is one card, shown only with the Skillwright.'
        ),
        (
          'Needs from Core',
          'Nothing: all of it reads the session and the skill tree.'
        ),
      ]),
    );
  });

  testWidgets('version C', (tester) async {
    final (one, mid) = await scenes(tester);
    await board(
      tester,
      'skills-c.png',
      [
        (one, 412.0, 'C · level 1', const CPage()),
        (mid, 412.0, 'C · mid game', const CPage()),
        (mid, 320.0, 'C · mid game, 320 px', const CPage()),
        (mid, 412.0, 'C · a tap on a path', const CBranchSheet()),
      ],
      notes: const NotesPanel(title: 'C · Next skill, paths, map', sections: [
        (
          'Level 1',
          'One card: the skill first in line, who offers it and at what standing. Four paths as rails with one lit bead each. Your skills (one). One button: the map of the whole tree.'
        ),
        (
          'Mid game',
          'The card names the offer waiting. Each path shows its progress (gold ticks, the next bead lit). Your skills are a grid of icons with their tier dots and the essence beside it. The map and Merge are buttons at the foot.'
        ),
        (
          'How a skill is learned',
          'As today: a clan’s offer. The card says which skill and from whom; a path’s sheet lists its four skills with who offers the next.'
        ),
        (
          'Merges and upgrades',
          'Essence is shown over Your skills; a tap on a skill opens today’s sheet (Raise tier). Merge is a button, shown only with the Skillwright.'
        ),
        (
          'Needs from Core',
          'Nothing. “Next skill” is the next of the first unfinished branch; Core could later say which one a waiting offer carries.'
        ),
      ]),
    );
  });
}
