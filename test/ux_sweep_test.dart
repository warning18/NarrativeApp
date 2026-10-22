// A sweep of the wave 16 screens (wave 17, UX, item 4): each new widget
// builds without an overflow at 320 and 390 px wide, at text scale 1 and
// 1.6, in English and French, with and without reduced motion, and with
// reduced motion it is whole at once (no card, the spoils counted). The app's
// own fonts are loaded (the test font is far wider, so only they tell the
// truth: see qa_fight_tips_real_font_test.dart).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/map_charts.dart' show ChartPalette;
import 'package:narrative_data_app/data/nemesis.dart';
import 'package:narrative_data_app/data/world_map.dart' show MapLook;
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/roll_power_row.dart';
import 'package:narrative_data_app/widgets/ward_mark.dart';
import 'package:narrative_data_app/data/land_crossing.dart';
import 'package:narrative_data_app/data/ship_forms.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/screens/land_crossing_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/fight_entrance.dart';
import 'package:narrative_data_app/widgets/fight_spoils_strip.dart';
import 'package:narrative_data_app/widgets/sea_battlefield.dart';
import 'package:narrative_data_app/widgets/side_view/deck_crew.dart';
import 'package:narrative_data_app/widgets/side_view/sea_kit.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';
import 'package:narrative_data_app/widgets/walk_bubble.dart';

import 'player_session_provider_test.dart' show baseSession;

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// Every way a screen can be met: width, text scale, language, motion.
final _cases = [
  for (final width in [320.0, 390.0])
    for (final scale in [1.0, 1.6])
      for (final lang in AppLanguage.values)
        for (final reduced in [false, true])
          (width: width, scale: scale, lang: lang, reduced: reduced),
];

String _name(
        ({double width, double scale, AppLanguage lang, bool reduced}) c) =>
    '${c.width.toInt()} px, text ×${c.scale}, ${c.lang.name}'
    '${c.reduced ? ', reduced motion' : ''}';

Future<void> _loadFonts() async {
  const families = {
    'PixelifySans': [
      'assets/fonts/PixelifySans-Regular.ttf',
      'assets/fonts/PixelifySans-SemiBold.ttf',
    ],
    'Spectral': [
      'assets/fonts/Spectral-Regular.ttf',
      'assets/fonts/Spectral-Medium.ttf',
      'assets/fonts/Spectral-Italic.ttf',
    ],
    'IMFellEnglishSC': ['assets/fonts/IMFellEnglishSC-Regular.ttf'],
  };
  for (final family in families.entries) {
    final loader = FontLoader(family.key);
    for (final path in family.value) {
      loader.addFont(Future.value(ByteData.view(
          Uint8List.fromList(File(path).readAsBytesSync()).buffer)));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(_loadFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> show(
    WidgetTester tester,
    ({double width, double scale, AppLanguage lang, bool reduced}) c,
    Widget Function(AppLanguage lang) child, {
    double height = 700,
  }) async {
    tester.view.physicalSize = Size(c.width, height);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: buildAppTheme(const ColorScheme.dark()),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(c.width, height),
            textScaler: TextScaler.linear(c.scale),
            disableAnimations: c.reduced,
          ),
          child: Scaffold(body: child(c.lang)),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));
  }

  final rat = _table('enemies')['rat_matriarch'] as Map<String, dynamic>;
  final longLine = entranceLine(rat['description'] as String);
  final ships = _table('ships');
  final eel =
      ShipForm.fromRecord('galleon', ships['galleon'] as Map<String, dynamic>);

  for (final c in _cases) {
    testWidgets('entrance card: ${_name(c)}', (tester) async {
      await show(
        tester,
        c,
        (lang) => FightEntrance(
          enemyId: 'rat_matriarch',
          name: lang == AppLanguage.fr
              ? 'La Matriarche des Rats Pestiférés'
              : 'The Plague-Gorged Rat Matriarch',
          line: longLine,
          boss: true,
          child: const Center(child: Text('the setup')),
        ),
      );
      expect(tester.takeException(), isNull);
      // Reduced motion shows no card at all; otherwise it goes by itself.
      expect(find.byKey(const Key('fight_entrance_card')),
          c.reduced ? findsNothing : findsOneWidget);
      await tester.pump(fightEntranceTime);
      await tester.pump();
      expect(find.byKey(const Key('fight_entrance_card')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('spoils strip: ${_name(c)}', (tester) async {
      await show(
        tester,
        c,
        (lang) => FightSpoilsStrip(
          goldLabel: lang == AppLanguage.fr ? 'Or' : 'Gold',
          spoils: const FightSpoils(gold: 1250, xp: 480, items: [
            SpoilItem('potion_minor', 'Potion', 'Minor Potion'),
            SpoilItem('thug_knuckle_wrap', 'Armor', 'Knuckle Wrap'),
            SpoilItem('material_timber', 'Material', 'Timber'),
            SpoilItem('potion_minor', 'Potion', 'Minor Potion'),
            SpoilItem('material_timber', 'Material', 'Timber'),
            SpoilItem('thug_knuckle_wrap', 'Armor', 'Knuckle Wrap'),
          ]),
        ),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(tester.takeException(), isNull);
      expect(find.text('+1250 ${c.lang == AppLanguage.fr ? 'Or' : 'Gold'}'),
          findsOneWidget);
      expect(find.text('+480 XP'), findsOneWidget);
    });

    testWidgets('deck crew and the speech bubble: ${_name(c)}', (tester) async {
      await show(
        tester,
        c,
        (lang) => Column(children: [
          SeaSideScene(
            waters: SeaWaters.open,
            ship: eel,
            crew: const [
              DeckCrew('hero', Color(0xFFC0392B)),
              DeckCrew('maren', Color(0xFF3E7CB1)),
              DeckCrew('tobias', Color(0xFF6B8E4E)),
            ],
            meeting:
                const SeaMeeting(SeaMeetingKind.raider, id: 'raider_skiff'),
            height: 140,
          ),
          WalkBubble(
            speaker: lang == AppLanguage.fr
                ? 'Sœur Maren de la Veille'
                : 'Sister Maren of the Watch',
            line: lang == AppLanguage.fr
                ? 'L’eau est douce aujourd’hui, et je n’aime pas cela.'
                : 'The water is kind today, and I do not like it one bit.',
            width: min(300.0, c.width - 16),
          ),
        ]),
      );
      await tester.pump(seaArrivalTime);
      expect(tester.takeException(), isNull);
    });
  }

  final events = landEventsFrom({
    'fen_mud': {
      'name': 'The mud that takes boots',
      'name_fr': 'La boue qui prend les bottes',
      'text': 'The boardwalk is gone, and what is left is a long stretch of '
          'black mud that smells of something that died some time ago.',
      'text_fr': 'Le caillebotis a disparu, et il ne reste qu’une longue '
          'étendue de boue noire qui sent quelque chose de mort depuis '
          'longtemps.',
      'choices': [
        {
          'id': 'go',
          'text': 'Wade through it, and keep the party close together',
          'text_fr': 'La traverser à gué, en gardant le groupe bien serré',
          'outcome': {'healthPct': -2, 'note': 'n', 'note_fr': 'n'},
        },
      ],
    },
  });
  const route = LandRoute(
    id: 'fen',
    name: 'The Fen Road',
    nameFr: 'La route du marais',
    from: 'cloister',
    to: 'court',
    days: 3,
    terrain: 'fen',
    events: {'fen_mud': 1},
  );
  for (final c in _cases) {
    testWidgets('land crossing: ${_name(c)}', (tester) async {
      tester.view.physicalSize = Size(c.width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({'app_language': c.lang.name});
      });
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(const ColorScheme.dark()),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(c.scale),
                disableAnimations: c.reduced),
            child: child!,
          ),
          home: LandCrossingScreen(
              route: route, events: events, random: Random(1)),
        ),
      ));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  }

  // The ward sheet, its mark and the Banish card, with a clan hunting.
  final data = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
  );
  final hunted = updateNemesis(
      setStandingValue(PoliticsState.empty, 'compact', -40, 'edit', data: data)
          .state,
      data,
      chapter: 3);
  for (final c in _cases.where((c) => !c.reduced)) {
    testWidgets('ward sheet and mark: ${_name(c)}', (tester) async {
      tester.view.physicalSize = Size(c.width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.runAsync(() async {
        final notifier = container.read(playerSessionProvider.notifier);
        await Future<void>.delayed(const Duration(milliseconds: 200));
        for (final schema in [
          factionsSchema,
          subclansSchema,
          relationsSchema,
          titlesSchema,
        ]) {
          await container.read(gameDbProvider(schema).notifier).whenLoaded();
        }
        await container.read(appLanguageProvider.notifier).setLanguage(c.lang);
        await notifier.loadSession(PlayerSession.fromJson({
          ...baseSession(builtHouseIds: const ['warding_cairn']).toJson(),
          'banishCharges': 3,
        }).copyWith(politics: hunted));
      });
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildAppTheme(const ColorScheme.dark()),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(c.scale)),
            child: child!,
          ),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => SingleChildScrollView(
                child: Column(children: [
                  RollPowerRow(
                    keyPrefix: 't',
                    rolls: ref.watch(campRollsProvider),
                    onReroll: () async {},
                    onBanish: (_) async {},
                    onRaise: () async {},
                  ),
                  WardMark(palette: ChartPalette.of(MapLook.night)),
                ]),
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('t_roll_banish')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ward_sheet_title')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('the side view keeps its grid for the crew figures', () {
    expect(sideViewRows, 72);
    expect(deckCrewHeight, lessThan(sideViewRows / 4));
  });
}
