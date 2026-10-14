// The People codex (v1.204, see people_codex.dart): who is known (by the
// scenes stood in, the flags held, the shops found, or a word with them;
// a legacy record by its chapter and flag), what passed between them and
// the player (v1.210: also by the coast's standing and marks, through a
// state's `conditions`), where they stand in the intrigues (v1.210, the
// stages and outcomes that name them), the grouping by chapter and the
// badge count; then a person's page.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/people_codex.dart';
import 'package:narrative_data_app/data/politics_events.dart';
import 'package:narrative_data_app/data/quest_tracking.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/npc_detail_screen.dart';
import 'package:narrative_data_app/widgets/people_widgets.dart';

import 'player_session_provider_test.dart' show baseSession;

const Map<String, dynamic> _vane = {
  'npcID': 'aurel_vane',
  'npcName': 'Aurel Vane',
  'role': 'Inquisitor-General',
  'role_fr': 'Inquisiteur général',
  'faction': 'inquisition',
  'placeId': 'alster_lower_town',
  'chapter': 1,
  'kind': 'inquisitor',
  'description': 'The man who took your sister.',
  'description_fr': 'L’homme qui prit votre sœur.',
  'want': 'Order, whatever it costs.',
  'want_fr': 'L’ordre, quoi qu’il en coûte.',
  'metNodes': ['400', '400_lost'],
  'metFlags': <String>[],
  'shopId': '',
  'requiredFlag': '',
  'states': [
    {
      'flag': 'lysa_survived',
      'line': 'You took Lysa back from him.',
      'line_fr': 'Vous lui avez repris Lysa.',
    },
    {
      'flag': 'lysa_lost',
      'line': 'He kept Lysa.',
      'line_fr': 'Il a gardé Lysa.',
    },
    {
      'flag': 'rival_spared',
      'andFlags': ['throne_vane'],
      'line': 'You spared his rival on the Throne.',
      'line_fr': 'Vous avez épargné son rival sur le Trône.',
    },
    {
      'flag': 'hub_2015',
      'unlessFlags': ['tern_row_spared'],
      'line': 'You fought at Tern Row.',
      'line_fr': 'Vous vous êtes battu à Tern Row.',
    },
  ],
  'dialogueLines': ['"Sit."'],
  'dialogueLines_fr': ['« Asseyez-vous. »'],
};

const Map<String, dynamic> _keeper = {
  'npcID': 'tide_keeper',
  'npcName': 'The Tide Keeper',
  'chapter': 2,
  'kind': 'keeper',
  'shopId': 'tide_cellar',
  'metNodes': <String>[],
  'metFlags': <String>[],
};

const Map<String, dynamic> _nadira = {
  'npcID': 'nadira',
  'npcName': 'Nadira',
  'chapter': 2,
  'kind': 'sailor',
  'metFlags': ['host_tidekin'],
};

const Map<String, dynamic> _harker = {
  'npcID': 'old_harker',
  'npcName': 'Old Harker',
  'chapter': 2,
  'requiredFlag': '',
};

const Map<String, dynamic> _records = {
  'aurel_vane': _vane,
  'tide_keeper': _keeper,
  'nadira': _nadira,
  'old_harker': _harker,
};

/// A keeper whose states read the coast (v1.210): standing with the
/// Crows either way, a mark on the Inquisition, and one state written
/// with neither a flag nor conditions, which never shows.
const Map<String, dynamic> _keyholder = {
  'npcID': 'keyholder_wharf',
  'npcName': 'The Keyholder',
  'chapter': 2,
  'kind': 'smuggler',
  'metFlags': ['keyholder_key'],
  'states': [
    {
      'flag': 'keyholder_key',
      'line': 'She gave you a key.',
      'line_fr': 'Elle vous a donné une clef.',
    },
    {
      'flag': '',
      'conditions': {
        'standingAtLeast': {'crows': 26},
      },
      'line': 'The Keyholders count you one of their own now.',
      'line_fr': 'Les Porte-Clefs vous comptent désormais parmi les leurs.',
    },
    {
      'flag': 'keyholder_key',
      'conditions': {
        'standingAtMost': {'crows': -26},
      },
      'line': 'The Keyholders bar their doors to you.',
      'line_fr': 'Les Porte-Clefs vous ferment leurs portes.',
    },
    {
      'flag': '',
      'conditions': {
        'marks': {'inquisition': 'foe'},
      },
      'line': 'The Inquisition has your name on a writ.',
      'line_fr': 'L’Inquisition a votre nom sur un mandat.',
    },
    {
      'flag': '',
      'line': 'Never shown: no flag, no conditions.',
    },
  ],
};

final ClanData _clans = ClanData.fromTables(
  factions: {
    'crows': {'kind': 'clan', 'name': 'The Crows', 'short': 'Crows'},
    'dominion': {
      'kind': 'clan',
      'name': 'The Lantern Dominion',
      'short': 'Dominion',
      'startStanding': -10,
      'subclans': ['inquisition'],
    },
  },
  subclans: {
    'inquisition': {'clan': 'dominion', 'name': 'The Inquisition'},
  },
);

CoastWorld _world({int chapter = 2}) =>
    CoastWorld(data: _clans, chapter: chapter);

/// An intrigue with faces (v1.210): the informant at the Clue, Vane at
/// the Hook and the Turn, no one at the Reveal; Vane on both outcomes.
const Map<String, dynamic> _lanternJson = {
  'id': 'hooded_lantern',
  'name': 'The Hooded Lantern',
  'name_fr': 'La Lanterne encapuchonnée',
  'factions': ['dominion'],
  'stages': [
    {
      'stage': 'Clue',
      'chapter': '1',
      'text': 'An informant is paid in Inquisition silver.',
      'text_fr': 'Un indicateur est payé en argent de l’Inquisition.',
      'npcId': 'wharf_informant',
    },
    {
      'stage': 'Hook',
      'chapter': '3',
      'text': 'A condemned voidkin whispers.',
      'text_fr': 'Un enfant du Néant condamné murmure.',
      'npcId': 'aurel_vane',
    },
    {
      'stage': 'Turn',
      'chapter': '4',
      'text': 'A letter shows where the pieces go.',
      'text_fr': 'Une lettre montre où vont les pièces.',
      'npcId': 'aurel_vane',
    },
    {
      'stage': 'Reveal',
      'chapter': '5',
      'text': 'The rite that widens the tear.',
      'text_fr': 'Le rite qui élargit la déchirure.',
    },
  ],
  'outcomes': [
    {
      'name': 'The door shut',
      'name_fr': 'La porte close',
      'npcId': 'aurel_vane',
    },
    {
      'name': 'The door open',
      'name_fr': 'La porte ouverte',
      'npcId': 'aurel_vane',
      'effects': [
        {'faction': 'dominion', 'delta': 25},
      ],
    },
  ],
};

final Intrigue _lantern = Intrigue.fromJson('hooded_lantern', _lanternJson);

void main() {
  group('discovery', () {
    test('a scene stood in, a flag held or a shop found reveals a person', () {
      final s = baseSession();
      expect(npcDiscovered('aurel_vane', _vane, s, 8), isFalse,
          reason: 'the chapter alone reveals nothing in the codex');
      expect(
          npcDiscovered('aurel_vane', _vane, s, 1,
              visitedNodeIds: const {'400_lost'}),
          isTrue);
      expect(
          npcDiscovered('aurel_vane', _vane, s, 1,
              visitedNodeIds: const {'401'}),
          isFalse);
      expect(npcDiscovered('tide_keeper', _keeper, s, 2), isFalse);
      expect(
          npcDiscovered('tide_keeper', _keeper,
              s.copyWith(unlockedShopIds: const ['tide_cellar']), 1),
          isTrue);
      expect(
          npcDiscovered('tide_keeper', _keeper, s, 1,
              unlockedShopIds: const ['tide_cellar']),
          isTrue);
      expect(npcDiscovered('nadira', _nadira, s, 2), isFalse);
      expect(
          npcDiscovered(
              'nadira', _nadira, s.copyWith(flags: const ['host_tidekin']), 2),
          isTrue);
      // A word with them always counts.
      expect(
          npcDiscovered('nadira', _nadira,
              s.copyWith(talkedToNpcIds: const ['nadira']), 1),
          isTrue);
    });

    test('a legacy record is known by its chapter and flag', () {
      final s = baseSession();
      expect(npcIsLegacy(_harker), isTrue);
      expect(npcIsLegacy(_vane), isFalse);
      expect(npcIsLegacy(_keeper), isFalse);
      expect(npcDiscovered('old_harker', _harker, s, 1), isFalse);
      expect(npcDiscovered('old_harker', _harker, s, 2), isTrue);
    });

    test('the people known, by chapter, and how many are new', () {
      final s = baseSession().copyWith(
          unlockedShopIds: const ['tide_cellar'],
          seenNpcIds: const ['tide_keeper']);
      final known = discoveredNpcIds(_records, s,
          currentChapter: 2, visitedNodeIds: const ['400']);
      expect(known, ['aurel_vane', 'tide_keeper', 'old_harker']);
      expect(npcsByChapter(known, _records), {
        1: ['aurel_vane'],
        2: ['old_harker', 'tide_keeper'],
      });
      expect(unseenNpcCount(known, s.seenNpcIds), 2);
    });
  });

  group('what passed between you', () {
    test('a state shows when its flag is held, with its conditions', () {
      expect(npcStateLines(_vane, const [], false), isEmpty);
      expect(npcStateLines(_vane, const ['lysa_survived'], false),
          ['You took Lysa back from him.']);
      expect(npcStateLines(_vane, const ['lysa_survived'], true),
          ['Vous lui avez repris Lysa.']);
      // andFlags: all held.
      expect(npcStateLines(_vane, const ['rival_spared'], false), isEmpty);
      expect(npcStateLines(_vane, const ['rival_spared', 'throne_vane'], false),
          ['You spared his rival on the Throne.']);
      // unlessFlags: none held.
      expect(npcStateLines(_vane, const ['hub_2015'], false),
          ['You fought at Tern Row.']);
      expect(npcStateLines(_vane, const ['hub_2015', 'tern_row_spared'], false),
          isEmpty);
      // In the record's order.
      expect(npcStateLines(_vane, const ['hub_2015', 'lysa_lost'], false),
          ['He kept Lysa.', 'You fought at Tern Row.']);
    });

    test('a state with conditions reads the coast, only when given one', () {
      // No world: the conditioned states are skipped, flag or not.
      expect(npcStateLines(_keyholder, const ['keyholder_key'], false),
          ['She gave you a key.']);
      expect(
          npcStateLines(_keyholder, const ['keyholder_key'], false,
              world: _world()),
          ['She gave you a key.'],
          reason: 'the politics are needed too');
      // standingAtLeast met and unmet (the Crows start at 0).
      expect(
          npcStateLines(_keyholder, const [], false,
              world: _world(),
              politics: const PoliticsState(standings: {'crows': 30})),
          ['The Keyholders count you one of their own now.']);
      expect(
          npcStateLines(_keyholder, const [], false,
              world: _world(),
              politics: const PoliticsState(standings: {'crows': 25})),
          isEmpty);
      expect(
          npcStateLines(_keyholder, const [], false,
              world: _world(), politics: PoliticsState.empty),
          isEmpty);
      // A flag and standingAtMost together: both must hold.
      expect(
          npcStateLines(_keyholder, const ['keyholder_key'], false,
              world: _world(),
              politics: const PoliticsState(standings: {'crows': -30})),
          ['She gave you a key.', 'The Keyholders bar their doors to you.']);
      expect(
          npcStateLines(_keyholder, const [], false,
              world: _world(),
              politics: const PoliticsState(standings: {'crows': -30})),
          isEmpty,
          reason: 'the flag is still needed');
      expect(
          npcStateLines(_keyholder, const ['keyholder_key'], true,
              world: _world(),
              politics: const PoliticsState(standings: {'crows': -30})),
          [
            'Elle vous a donné une clef.',
            'Les Porte-Clefs vous ferment leurs portes.',
          ]);
      // A mark.
      expect(
          npcStateLines(_keyholder, const [], false,
              world: _world(),
              politics:
                  const PoliticsState(marks: {'inquisition': SubclanMark.foe})),
          ['The Inquisition has your name on a writ.']);
      expect(
          npcStateLines(_keyholder, const [], false,
              world: _world(),
              politics: const PoliticsState(
                  marks: {'inquisition': SubclanMark.friend})),
          isEmpty);
      // The conditions are read off the record.
      expect(npcStateConditions(const {'flag': 'x'}), isEmpty);
      expect(
          npcStateConditions(const {
            'conditions': {
              'standingAtLeast': {'crows': 26},
            },
          }),
          {
            'standingAtLeast': {'crows': 26},
          });
    });

    test('the text helpers fall back to English', () {
      expect(npcText(_vane, 'role', true), 'Inquisiteur général');
      expect(npcText(_vane, 'role', false), 'Inquisitor-General');
      expect(npcText(_harker, 'role', true), '');
      expect(npcChapter(_harker), 2);
      expect(npcChapter(const {}), 1);
      expect(npcMetNodes(_vane), ['400', '400_lost']);
      expect(npcShopId(_keeper), 'tide_cellar');
    });
  });

  group('in the intrigues', () {
    test('the stages and outcomes naming the person, once their flag is held',
        () {
      expect(npcIntrigueLines(_vane, [_lantern], const [], false), isEmpty);
      // Stage 1 names the informant, not Vane.
      expect(
          npcIntrigueLines(_vane, [_lantern],
              const ['intrigue_hooded_lantern_stage_1'], false),
          isEmpty);
      expect(
          npcIntrigueLines(const {'npcID': 'wharf_informant'}, [_lantern],
              const ['intrigue_hooded_lantern_stage_1'], false),
          [
            (
              intrigue: 'The Hooded Lantern',
              stage: 'Clue',
              text: 'An informant is paid in Inquisition silver.',
            ),
          ]);
      // Stage 2 names Vane; stage 3 too, but its flag is not held.
      final hook = npcIntrigueLines(
          _vane, [_lantern], const ['intrigue_hooded_lantern_stage_2'], false);
      expect(hook, [
        (
          intrigue: 'The Hooded Lantern',
          stage: 'Hook',
          text: 'A condemned voidkin whispers.',
        ),
      ]);
      expect(npcIntrigueLineText(hook.single, false),
          'The Hooded Lantern · Hook: A condemned voidkin whispers.');
      // Stages then outcomes, in the record's order; only the outcome
      // whose flag is held.
      expect(
          npcIntrigueLines(
              _vane,
              [_lantern],
              const [
                'intrigue_hooded_lantern_outcome_1',
                'intrigue_hooded_lantern_stage_3',
                'intrigue_hooded_lantern_stage_2',
                'intrigue_hooded_lantern_stage_4',
              ],
              false),
          [
            (
              intrigue: 'The Hooded Lantern',
              stage: 'Hook',
              text: 'A condemned voidkin whispers.',
            ),
            (
              intrigue: 'The Hooded Lantern',
              stage: 'Turn',
              text: 'A letter shows where the pieces go.',
            ),
            (
              intrigue: 'The Hooded Lantern',
              stage: 'Outcome',
              text: 'The door open',
            ),
          ]);
      // In French, with the no-break space before the colon.
      final fr = npcIntrigueLines(
          _vane, [_lantern], const ['intrigue_hooded_lantern_outcome_0'], true);
      expect(fr, [
        (
          intrigue: 'La Lanterne encapuchonnée',
          stage: 'Issue',
          text: 'La porte close',
        ),
      ]);
      expect(npcIntrigueLineText(fr.single, true),
          'La Lanterne encapuchonnée · Issue\u00a0: La porte close');
      // A record without an id names no one.
      expect(
          npcIntrigueLines(const {'npcName': 'Nobody'}, [_lantern],
              const ['intrigue_hooded_lantern_stage_2'], false),
          isEmpty);
    });

    test('the model keeps the faces, and does without them', () {
      expect(_lantern.stages.map((s) => s.npcId),
          ['wharf_informant', 'aurel_vane', 'aurel_vane', '']);
      expect(
          _lantern.outcomes.map((o) => o.npcId), ['aurel_vane', 'aurel_vane']);
      final bare = Intrigue.fromJson('bare', const {
        'name': 'Bare',
        'stages': [
          {'stage': 'Clue', 'text': 'A clue.'},
        ],
        'outcomes': [
          {'name': 'An end'},
        ],
      });
      expect(bare.stages.single.npcId, '');
      expect(bare.outcomes.single.npcId, '');
      expect(
          npcIntrigueLines(
              _vane, [bare], const ['intrigue_bare_stage_1'], false),
          isEmpty);
    });
  });

  group('the person\'s page', () {
    testWidgets('shows who they are, what they want and what passed',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'en',
        'gamedb_geography': jsonEncode({
          'alster_lower_town': {
            'level': 'district',
            'name': 'The Lower Town',
            'name_fr': 'La Ville basse',
          },
        }),
        'gamedb_biomes': jsonEncode(<String, dynamic>{}),
        'gamedb_subclans': jsonEncode({
          'inquisition': {
            'clan': 'dominion',
            'name': 'The Inquisition',
            'name_fr': 'L’Inquisition',
            'color': '#AA3333',
          },
        }),
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appLanguageProvider);
      final notifier = container.read(playerSessionProvider.notifier);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.runAsync(() => notifier
          .loadSession(baseSession().copyWith(flags: const ['lysa_survived'])));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
            home: NpcDetailScreen(npcId: 'aurel_vane', npc: _vane)),
      ));
      // The data tables load off the asset bundle.
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pumpAndSettle();

      expect(find.text('Aurel Vane'), findsWidgets);
      expect(find.byKey(const Key('npc_role')), findsOneWidget);
      expect(find.text('Inquisitor-General'), findsOneWidget);
      expect(find.text('The Lower Town'), findsOneWidget);
      expect(find.text('Met in chapter 1'), findsOneWidget);
      expect(find.text('The man who took your sister.'), findsOneWidget);
      expect(find.text('What they want'), findsOneWidget);
      expect(find.text('Order, whatever it costs.'), findsOneWidget);
      expect(find.text('What passed between you'), findsOneWidget);
      expect(find.text('You took Lysa back from him.'), findsOneWidget);
      expect(find.text('He kept Lysa.'), findsNothing);
      // No intrigue names them yet: no heading.
      expect(find.byKey(const Key('npc_intrigues_label')), findsNothing);
      // The faction tag, by the sub-clan's name.
      expect(find.byType(NpcFactionTag), findsOneWidget);
      expect(find.text('The Inquisition'), findsOneWidget);
      // The dialogue and the Talk button, as before.
      expect(find.text('"Sit."'), findsOneWidget);
      expect(find.text('Talk'), findsOneWidget);
      await tester.ensureVisible(find.text('Talk'));
      await tester.tap(find.text('Talk'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(
          container.read(playerSessionProvider).talkedToNpcIds, ['aurel_vane']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows where they stand in the intrigues (v1.210)',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'app_language': 'en',
        'gamedb_geography': jsonEncode(<String, dynamic>{}),
        'gamedb_biomes': jsonEncode(<String, dynamic>{}),
        'gamedb_intrigues': jsonEncode({'hooded_lantern': _lanternJson}),
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(appLanguageProvider);
      final notifier = container.read(playerSessionProvider.notifier);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.runAsync(() => notifier.loadSession(baseSession().copyWith(
            flags: const [
              'intrigue_hooded_lantern_stage_1',
              'intrigue_hooded_lantern_stage_2',
            ],
          )));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
            home: NpcDetailScreen(npcId: 'aurel_vane', npc: _vane)),
      ));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('npc_intrigues_label')), findsOneWidget);
      expect(find.text('In the intrigues'), findsOneWidget);
      expect(
          find.text('The Hooded Lantern · Hook: A condemned voidkin whispers.'),
          findsOneWidget);
      expect(find.byKey(const Key('npc_intrigue_1')), findsNothing,
          reason: 'stage 1 names the informant, stage 3 is not reached');
      // No flag of theirs is held: nothing passed between you.
      expect(find.text('What passed between you'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
