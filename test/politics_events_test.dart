// The clan story layer (v1.195), the rules: a story choice's politics
// (standing through the ripple, marks, relations, flags, the Open Hand's
// remembrance, an intrigue's stage or outcome with its effects, an offer,
// an event), applied once however often the choice is taken; the politics
// events (triggers, variants, conditions, once, chains, the news and its
// line in the log); the choice's hint in both languages; and the Open
// Hand's rules (its stage, its titles, "Your own hand" in an offer, the
// Dominion's -2 once the banner is raised).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/politics_events.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/models/story_node.dart';

/// The Vigil and the Penitents allies; the Dominion rival of both; the
/// Mire and the Crows indifferent; the Open Hand lost. The Hooded Lantern
/// with two outcomes, every shape of effect among them.
final ClanData _data = ClanData.fromTables(
  factions: {
    'dominion': {
      'kind': 'clan',
      'name': 'The Lantern Dominion',
      'short': 'Dominion',
      'short_fr': 'Dominion',
      'startStanding': -10,
      'subclans': ['inquisition'],
    },
    'vigil': {
      'kind': 'clan',
      'name': 'The Grey Vigil',
      'name_fr': 'La Veille Grise',
      'short': 'Vigil',
      'short_fr': 'Veille',
    },
    'penitents': {
      'kind': 'clan',
      'name': 'The Penitents',
      'short': 'Penitents',
      'short_fr': 'Pénitents',
      'subclans': ['wickwardens'],
    },
    'mire': {'kind': 'clan', 'name': 'The Mire', 'short': 'Mire'},
    'crows': {'kind': 'clan', 'name': 'The Crows', 'short': 'Crows'},
    'open_hand': {
      'kind': 'lost',
      'name': 'The Open Hand',
      'name_fr': 'La Main Ouverte',
    },
  },
  subclans: {
    'inquisition': {
      'clan': 'dominion',
      'name': 'The Inquisition',
      'name_fr': 'L’Inquisition',
    },
    'wickwardens': {'clan': 'penitents', 'name': 'The Wickwardens'},
  },
  relations: {
    'pairs': [
      {'a': 'vigil', 'b': 'penitents', 'step': 7},
      {'a': 'dominion', 'b': 'vigil', 'step': 2},
      {'a': 'dominion', 'b': 'penitents', 'step': 3},
      {'a': 'crows', 'b': 'dominion', 'step': 4},
      {'a': 'mire', 'b': 'penitents', 'step': 4},
    ],
  },
  titles: {
    'drawer': {'name': 'Drawer', 'faction': 'open_hand', 'source': 'story'},
    'last_hand': {
      'name': 'Last of the Open Hand',
      'faction': 'open_hand',
      'source': 'story',
    },
    'kingmaker': {
      'name': 'Kingmaker',
      'faction': 'dominion',
      'source': 'intrigue',
    },
  },
  intrigues: {
    'hooded_lantern': {
      'name': 'The Hooded Lantern',
      'outcomes': [
        {
          'name': 'Expose',
          'effects': [
            {'note': 'The Dominion splits.'},
            {'faction': 'vigil', 'delta': 25},
            {'faction': 'penitents', 'delta': 15},
          ],
        },
        {
          'name': 'Keep',
          'effects': [
            {'faction': 'dominion', 'delta': 20},
            {'subclan': 'inquisition', 'mark': 'friend'},
            {'companion': 'vess', 'change': 'leaves'},
            {'title': 'kingmaker'},
            {'title': 'no_such_title'},
            {
              'faction': 'crows',
              'delta': -20,
              'condition': 'found_out',
            },
          ],
        },
      ],
    },
  },
);

CoastWorld _world({
  Map<String, PoliticsEvent> events = const {},
  int chapter = 2,
  int day = 5,
}) =>
    CoastWorld(data: _data, events: events, chapter: chapter, day: day);

CoastChange _apply(
  Map<String, dynamic> json, {
  PoliticsState politics = PoliticsState.empty,
  List<String> flags = const [],
  String key = '',
  CoastWorld? world,
}) =>
    applyStoryPolitics(StoryPolitics.tryParse(json)!,
        cause: 'story:n1',
        key: key,
        politics: politics,
        flags: flags,
        world: world ?? _world());

Map<String, PoliticsEvent> _events(Map<String, dynamic> json) =>
    parsePoliticsEvents(json);

void main() {
  group('the politics a choice carries', () {
    test('read, written back, and kept through the story model', () {
      const json = {
        'standing': {'vigil': 5, 'dominion': -5},
        'marks': {'inquisition': 'foe', 'wickwardens': 'friend'},
        'relations': [
          {'a': 'mire', 'b': 'penitents', 'steps': 1},
        ],
        'offerFrom': 'penitents',
        'intrigue': {'id': 'hooded_lantern', 'stage': 2},
        'remembrance': 3,
        'event': 'lantern_bearer_dies',
        'hidden': true,
        'later': {'kept': 1},
      };
      final politics = StoryPolitics.tryParse(json)!;
      expect(politics.standing, {'vigil': 5, 'dominion': -5});
      expect(politics.marks['inquisition'], 'foe');
      expect(politics.relations.single.steps, 1);
      expect(politics.intrigue!.stage, 2);
      expect(politics.remembrance, 3);
      expect(politics.event, 'lantern_bearer_dies');
      expect(politics.hidden, isTrue);
      expect(politics.toJson(), json, reason: 'a later key survives');

      final choice = StoryChoice.fromJson(
          const {'text': 'Go', 'next_id': 'n2', 'politics': json});
      expect(choice.hasPolitics, isTrue);
      expect(StoryChoice.fromJson(choice.toJson()).toJson(), choice.toJson());
      final node = StoryNode.fromJson('n1', const {
        'description': 'A room.',
        'politicsOnEnter': {'remembrance': 1},
        'choices': [],
      });
      expect(node.politicsOnEnter!.remembrance, 1);
      expect(node.toJson()['politicsOnEnter'], {'remembrance': 1});
      expect(StoryPolitics.tryParse(null), isNull);
      expect(StoryPolitics.tryParse(const {}), isNull);
      // Another way to write a relation, and an outcome.
      final other = StoryPolitics.tryParse(const {
        'relations': [
          {'a': 'x', 'b': 'y', 'step': -2},
        ],
        'intrigue': {'id': 'i', 'outcome': 1},
      })!;
      expect(other.relations.single.steps, -2);
      expect(other.intrigue!.outcome, 1);
    });

    test('standing goes through the ripple, logged under story:<node>', () {
      final change = _apply(const {
        'standing': {'penitents': 8},
      });
      final expected = applyStandingChange(
          PoliticsState.empty, 'penitents', 8, 'story:n1',
          data: _data, chapter: 2, day: 5);
      expect(change.politics.standings, expected.state.standings);
      final entry = change.politics.standingLog.single;
      expect(entry.cause, 'story:n1');
      expect([entry.chapter, entry.day], [2, 5]);
      // The ally a quarter, the rival half.
      expect(entry.deltas['penitents'], 8);
      expect(entry.deltas['vigil'], 2);
      expect(entry.deltas['dominion'], -4);
    });

    test('marks, relations and flags; the lost clan has no standing', () {
      final change = _apply(const {
        'marks': {'inquisition': 'foe', 'nobody': 'bogus'},
        'relations': [
          {'a': 'mire', 'b': 'penitents', 'steps': 1},
        ],
        'flags': ['seen_it'],
        'standing': {'open_hand': 10},
      }, flags: const [
        'old'
      ]);
      final p = change.politics;
      expect(p.markOf('inquisition'), SubclanMark.foe);
      expect(p.relationStep('mire', 'penitents', _data), 5);
      expect(p.relationsLog.single.cause, 'story:n1');
      expect(change.flags, ['old', 'seen_it']);
      expect(p.standings.containsKey('open_hand'), isFalse);
    });

    test('applied once under its key: taken again, nothing moves', () {
      const json = {
        'standing': {'vigil': 5},
        'flags': ['once'],
      };
      final first = _apply(json, key: choicePoliticsKey('n1', 0));
      expect(first.applied, isTrue);
      expect(first.politics.appliedKeys, ['story:n1:choice0']);
      final again = _apply(json,
          key: choicePoliticsKey('n1', 0),
          politics: first.politics,
          flags: first.flags);
      expect(again.applied, isFalse);
      expect(again.politics.standings, first.politics.standings);
      expect(again.politics.standingLog, hasLength(1));
      // Another choice of the same scene, and the scene on entry, are
      // their own.
      final other = _apply(json,
          key: choicePoliticsKey('n1', 1),
          politics: first.politics,
          flags: first.flags);
      expect(other.applied, isTrue);
      expect(other.politics.standingOf('vigil', _data), 10);
      expect(enterPoliticsKey('n1'), 'story:n1:enter');
    });

    test('remembrance sets every stage up to it; offerFrom asks an offer', () {
      final change = _apply(const {'remembrance': 3, 'offerFrom': 'mire'});
      expect(change.flags, ['open_hand_1', 'open_hand_2', 'open_hand_3']);
      expect(openHandStageFrom(change.flags), 3);
      expect(change.offers.single.factionId, 'mire');
      expect(change.offers.single.cause, 'story:n1');
    });

    test('an intrigue stage sets its flag, read by the Intrigues tab', () {
      final change = _apply(const {
        'intrigue': {'id': 'hooded_lantern', 'stage': 2},
      });
      expect(change.flags, ['intrigue_hooded_lantern_stage_2']);
      expect(intrigueStageFrom(change.flags, 'hooded_lantern'), 2);
      expect(intrigueOutcomeFrom(change.flags, 'hooded_lantern'), isNull);
    });

    test('an outcome applies its effects, in all their shapes, once', () {
      final change = _apply(const {
        'intrigue': {'id': 'hooded_lantern', 'outcome': 1},
      });
      expect(intrigueOutcomeFrom(change.flags, 'hooded_lantern'), 1);
      expect(intrigueStageFrom(change.flags, 'hooded_lantern'), 6,
          reason: 'the Choice stage comes with it');
      final p = change.politics;
      expect(p.standingOf('dominion', _data), greaterThan(-10));
      expect(p.markOf('inquisition'), SubclanMark.friend);
      expect(change.companions.single.companionId, 'vess');
      expect(change.companions.single.change, 'leaves');
      expect(change.titles, ['kingmaker'], reason: 'only a title that exists');
      // A condition that does not hold leaves its effect out.
      expect(p.standings.containsKey('crows'), isFalse);
      for (final e in p.standingLog) {
        expect(e.cause, 'story:n1');
      }
      // The intrigue has ended: another outcome changes nothing.
      final again = _apply(const {
        'intrigue': {'id': 'hooded_lantern', 'outcome': 0},
      }, politics: p, flags: change.flags);
      expect(again.politics.standingOf('vigil', _data),
          p.standingOf('vigil', _data));
      expect(intrigueOutcomeFrom(again.flags, 'hooded_lantern'), 1);
      // With the condition's flag held, its effect applies.
      final found = _apply(const {
        'intrigue': {'id': 'hooded_lantern', 'outcome': 1},
      }, flags: const [
        'found_out'
      ]);
      expect(found.politics.standingOf('crows', _data), lessThan(0));
    });

    test('an event it fires happens now', () {
      final events = _events(const {
        'raid': {
          'variants': [
            {
              'effects': {
                'flags': ['raided']
              },
              'news': 'A raid.',
            },
          ],
        },
      });
      final change =
          _apply(const {'event': 'raid'}, world: _world(events: events));
      expect(change.fired, ['raid']);
      expect(change.flags, contains('raided'));
      expect(change.news.single.text, 'A raid.');
    });
  });

  group('the coast moves', () {
    test('the sample file reads: three events, each with its news', () {
      final events = parsePoliticsEvents(jsonDecode(
              File('assets/gamedata/politics_events.json').readAsStringSync())
          as Map<String, dynamic>);
      expect(events, hasLength(greaterThanOrEqualTo(2)));
      for (final event in events.values) {
        expect(event.variants, isNotEmpty, reason: event.id);
        expect(event.nameFor(AppLanguage.fr), isNotEmpty, reason: event.id);
        for (final v in event.variants) {
          expect(v.news, isNotEmpty, reason: event.id);
          expect(v.newsFr, isNotEmpty, reason: event.id);
        }
      }
    });

    final events = _events(const {
      'feast': {
        'name': 'The Feast',
        'trigger': {'chapter': 1, 'day': 3},
        'variants': [
          {
            'effects': {
              'flags': ['bearer_failing'],
            },
            'news': 'The Lantern-Bearer missed the Feast.',
            'news_fr': 'Le Porte-Lanterne manqua la fête.',
          },
        ],
      },
      'raid': {
        'trigger': {'chapter': 2},
        'variants': [
          {
            'conditions': {
              'flags': ['crows_warned'],
            },
            'news': 'The Crows were ready.',
          },
          {
            'effects': {
              'relations': [
                {'a': 'crows', 'b': 'dominion', 'steps': -1},
              ],
            },
            'news': 'Crow brigs burned.',
          },
        ],
      },
      'on_flag': {
        'trigger': {'flag': 'bearer_failing'},
        'variants': [
          {'news': 'Word spreads.'},
        ],
      },
      'by_story': {
        'variants': [
          {'news': 'Only when told.'},
        ],
      },
    });

    test('a trigger: the chapter reached, the story day, a flag', () {
      final early = runDueEvents(
          politics: PoliticsState.empty,
          flags: const [],
          world: _world(events: events, chapter: 1, day: 2));
      expect(early.applied, isFalse);
      expect(early.fired, isEmpty);

      final day3 = runDueEvents(
          politics: PoliticsState.empty,
          flags: const [],
          world: _world(events: events, chapter: 1, day: 3));
      // The feast sets the flag the next one waits for: both fire.
      expect(day3.fired, ['feast', 'on_flag']);
      expect(day3.flags, ['bearer_failing']);
      expect(day3.news.map((n) => n.eventId), ['feast', 'on_flag']);
      expect(day3.news.first.textFor(AppLanguage.fr),
          'Le Porte-Lanterne manqua la fête.');
      expect(day3.politics.news, hasLength(2));
      expect(day3.politics.firedEvents['feast']!.day, 3);

      final chapter2 = runDueEvents(
          politics: day3.politics,
          flags: day3.flags,
          world: _world(events: events, chapter: 2, day: 4));
      expect(chapter2.fired, ['raid'], reason: 'once: the feast is done');
      expect(chapter2.politics.hasFired('by_story'), isFalse,
          reason: 'no trigger: only the story fires it');
    });

    test('the first variant whose conditions hold; the last by default', () {
      final warned = runDueEvents(
          politics: PoliticsState.empty,
          flags: const ['crows_warned'],
          world: _world(events: events, chapter: 2, day: 1));
      expect(warned.politics.firedEvents['raid']!.variant, 0);
      expect(warned.news.single.text, 'The Crows were ready.');
      expect(warned.politics.relationStep('crows', 'dominion', _data), 4);

      final not = runDueEvents(
          politics: PoliticsState.empty,
          flags: const [],
          world: _world(events: events, chapter: 2, day: 1));
      expect(not.politics.firedEvents['raid']!.variant, 1);
      expect(not.politics.relationStep('crows', 'dominion', _data), 3);
      // Logged under the event: its news first, then what it moved.
      final line =
          not.politics.standingLog.where((e) => e.cause == 'event:raid').single;
      expect(line.note, 'Crow brigs burned.');
      expect(not.politics.relationsLog.single.cause, 'event:raid');
    });

    test('every condition key', () {
      PoliticsEvent event(Map<String, dynamic> conditions) =>
          PoliticsEvent.fromJson('e', {
            'variants': [
              {'conditions': conditions},
              {},
            ],
          });
      var politics = applyStandingChange(PoliticsState.empty, 'vigil', 30, 'x',
              data: _data)
          .state;
      politics = setSubclanMark(politics, 'inquisition', SubclanMark.foe, 'x',
              data: _data)
          .state;
      int pick(Map<String, dynamic> c, {List<String> flags = const []}) =>
          eventVariantFor(event(c),
              politics: politics, flags: flags, world: _world(chapter: 3));
      expect(
          pick({
            'flags': ['a']
          }, flags: [
            'a'
          ]),
          0);
      expect(
          pick({
            'flags': ['a']
          }),
          1);
      expect(
          pick({
            'notFlags': ['a']
          }, flags: [
            'a'
          ]),
          1);
      expect(
          pick({
            'notFlags': ['a']
          }),
          0);
      expect(pick({'chapterAtLeast': 3}), 0);
      expect(pick({'chapterAtLeast': 4}), 1);
      expect(
          pick({
            'standingAtLeast': {'vigil': 30}
          }),
          0);
      expect(
          pick({
            'standingAtLeast': {'vigil': 31}
          }),
          1);
      // The Vigil's gain cost its rival half: the Dominion at -25.
      expect(
          pick({
            'standingAtMost': {'dominion': -25}
          }),
          0);
      expect(
          pick({
            'standingAtMost': {'dominion': -30}
          }),
          1);
      expect(
          pick({
            'relationAtMost': {'vigil|dominion': 2}
          }),
          0);
      expect(
          pick({
            'relationAtMost': {'dominion|vigil': 1}
          }),
          1);
      expect(
          pick({
            'relationAtLeast': {'vigil|penitents': 7}
          }),
          0);
      expect(
          pick({
            'relationAtLeast': {'mire|penitents': 5}
          }),
          1);
      expect(
          pick({
            'marks': {'inquisition': 'foe'}
          }),
          0);
      expect(
          pick({
            'marks': {'inquisition': 'friend'}
          }),
          1);
    });

    test('once: never again; not once: again in a later chapter', () {
      final repeat = _events(const {
        'tide': {
          'trigger': {'chapter': 1},
          'once': false,
          'variants': [
            {
              'effects': {
                'standing': {'mire': 1},
              },
              'news': 'The tide turns.',
            },
          ],
        },
      });
      final first = runDueEvents(
          politics: PoliticsState.empty,
          flags: const [],
          world: _world(events: repeat, chapter: 2));
      expect(first.fired, ['tide']);
      final sameChapter = runDueEvents(
          politics: first.politics,
          flags: first.flags,
          world: _world(events: repeat, chapter: 2, day: 9));
      expect(sameChapter.applied, isFalse);
      final later = runDueEvents(
          politics: first.politics,
          flags: first.flags,
          world: _world(events: repeat, chapter: 3));
      expect(later.fired, ['tide']);
      expect(later.politics.firedEvents['tide']!.count, 2);
      expect(later.politics.standingOf('mire', _data), 2);

      // A once event fired by the story does nothing the second time;
      // Edit Mode's Fire now fires it anyway.
      final told = fireEvent('by_story',
          politics: PoliticsState.empty,
          flags: const [],
          world: _world(events: events));
      expect(told.news.single.text, 'Only when told.');
      final twice = fireEvent('by_story',
          politics: told.politics,
          flags: told.flags,
          world: _world(events: events));
      expect(twice.applied, isFalse);
      final forced = fireEvent('by_story',
          politics: told.politics,
          flags: told.flags,
          world: _world(events: events),
          force: true);
      expect(forced.applied, isTrue);
      expect(forced.politics.news, hasLength(2));
      expect(
          fireEvent('nobody',
                  politics: PoliticsState.empty,
                  flags: const [],
                  world: _world(events: events))
              .applied,
          isFalse);
    });

    test('other ways to write the file: a list, inline variants, triggers', () {
      final parsed = parsePoliticsEvents(const {
        '_note': 'not an event',
        'events': [
          {
            'id': 'listed',
            'trigger': [
              {'chapter': 4},
              {'chapter': 3, 'flag': 'clue_found'},
            ],
            'variants': [
              {
                'flags': ['clue_found'],
                'effects': {
                  'flags': ['early'],
                },
                'news': 'Sooner.',
              },
              {
                'standing': {'vigil': 2},
                'news': 'Later.',
              },
            ],
          },
        ],
        'short': {'trigger': 'day:7', 'news': 'One way.', 'effects': {}},
      });
      expect(parsed.keys, ['listed', 'short']);
      final listed = parsed['listed']!;
      expect(listed.triggers, hasLength(2));
      expect(
          eventDue(listed,
              politics: PoliticsState.empty,
              flags: const ['clue_found'],
              world: _world(chapter: 3)),
          isTrue);
      expect(
          eventDue(listed,
              politics: PoliticsState.empty,
              flags: const [],
              world: _world(chapter: 3)),
          isFalse);
      expect(listed.variants.first.conditions.flags, ['clue_found']);
      expect(listed.variants.last.effects.standing, {'vigil': 2});
      expect(parsed['short']!.triggers.single.day, 7);
      expect(parsed['short']!.variants.single.news, 'One way.');
    });
  });

  group('the hint under a choice', () {
    test('standing then marks, by short name; French; hidden says nothing', () {
      final politics = StoryPolitics.tryParse(const {
        'standing': {'vigil': 5, 'dominion': -5},
        'marks': {'inquisition': 'foe'},
      });
      expect(politicsHint(politics, _data, AppLanguage.en),
          'Vigil +5 · Dominion −5 · The Inquisition: foe');
      expect(politicsHint(politics, _data, AppLanguage.fr),
          'Veille +5 · Dominion −5 · L’Inquisition : inimitié');
      final hidden = StoryPolitics.tryParse(const {
        'standing': {'vigil': 5},
        'hidden': true,
      });
      expect(politicsHint(hidden, _data, AppLanguage.en), isEmpty);
      expect(
          politicsHint(StoryPolitics.tryParse(const {'remembrance': 2}), _data,
              AppLanguage.en),
          isEmpty,
          reason: 'nothing it may say');
      expect(politicsHint(null, _data, AppLanguage.en), isEmpty);
    });
  });

  group('the Open Hand', () {
    test('its stage and the titles remembrance earns', () {
      expect(openHandStageFrom(const []), 0);
      expect(openHandStageFrom(const ['open_hand_2', 'open_hand_5', 'x']), 5);
      expect(openHandStageFrom(const ['open_hand_9']), 0);
      expect(_data.openHand!.isLost, isTrue);
      expect(_data.clans.map((f) => f.id), isNot(contains('open_hand')));
      expect(remembranceTitlesFor(const ['open_hand_2'], _data), isEmpty);
      expect(remembranceTitlesFor(openHandFlagsUpTo(3), _data), ['drawer']);
      expect(remembranceTitlesFor(openHandFlagsUpTo(6), _data), ['drawer'],
          reason: 'the last wants the banner raised');
      expect(
          remembranceTitlesFor(
              [...openHandFlagsUpTo(6), bannerRaisedFlag], _data),
          ['drawer', 'last_hand']);
      final earned = titlesEarned(const [], PoliticsState.empty, _data,
          flags: openHandFlagsUpTo(4));
      expect(earned.gained, ['drawer']);
    });

    final signs = parseSigns({
      for (final patron in ['dominion', 'vigil', 'mire', 'open_hand'])
        for (var i = 0; i < 6; i++)
          '${patron}_$i': {
            'patron': patron,
            'slot': 'passive',
            'name': '$patron $i',
            'effects': [
              {'kind': 'armor', 'value': 1},
            ],
          },
    });
    OfferContext ctx(List<String> flags) => OfferContext(
          data: _data,
          politics: PoliticsState.empty,
          signs: signs,
          flags: flags,
        );
    const ticket = OfferTicket(source: OfferSource.level);

    test('it never comes the ordinary ways', () {
      expect(eligibleSuitors(ctx(openHandFlagsUpTo(6))),
          isNot(contains('open_hand')));
      final random = Random(3);
      for (var i = 0; i < 100; i++) {
        final offer = drawOffer(ticket, ctx(const []), random)!;
        expect(offer.suitors.map((s) => s.factionId),
            isNot(contains('open_hand')));
      }
    });

    test(
        '"Your own hand": a fourth card at 25% from stage 3, always at 6 '
        'with the banner raised', () {
      expect(ownHandComes(const [], Random(1)), isFalse);
      expect(ownHandComes(openHandFlagsUpTo(2), Random(1)), isFalse);
      final random = Random(4);
      var came = 0;
      for (var i = 0; i < 2000; i++) {
        if (ownHandComes(openHandFlagsUpTo(3), random)) came++;
      }
      expect(came / 2000, closeTo(ownHandChance, 0.04));
      for (var i = 0; i < 50; i++) {
        expect(
            ownHandComes(
                [...openHandFlagsUpTo(6), bannerRaisedFlag], Random(i)),
            isTrue);
      }
      // In an offer: a fourth suitor, one of the Open Hand's signs.
      final draw = Random(5);
      for (var i = 0; i < 30; i++) {
        final offer = drawOffer(
            ticket, ctx([...openHandFlagsUpTo(6), bannerRaisedFlag]), draw)!;
        final hand = offer.suitors.last;
        expect(hand.factionId, 'open_hand');
        expect(offer.suitors, hasLength(offerSuitorCount + 1));
        expect(hand.gift.kind, GiftKind.sign);
        expect(signs[hand.gift.id]!.patronId, 'open_hand');
        expect(hand.subclanId, isEmpty);
      }
    });

    test(
        'taking it moves no standing; the Dominion -2 once the banner '
        'is raised', () {
      const hand = Suitor(
          factionId: 'open_hand',
          gift: OfferGift(kind: GiftKind.sign, id: 'open_hand_0'));
      final quiet = acceptPolitics(hand, ticket,
          politics: PoliticsState.empty, data: _data, flags: const []);
      expect(quiet.politics.standingLog, isEmpty);
      expect(quiet.alignment, 0);
      expect(
          suitorPreview(hand, ticket,
              politics: PoliticsState.empty, data: _data),
          isEmpty);
      final raised = [...openHandFlagsUpTo(6), bannerRaisedFlag];
      final hunted = acceptPolitics(hand, ticket,
          politics: PoliticsState.empty, data: _data, flags: raised);
      expect(hunted.politics.standingOf('dominion', _data), -12);
      expect(hunted.politics.standingLog.single.cause, 'offer:open_hand_0');
      expect(
          suitorPreview(hand, ticket,
              politics: PoliticsState.empty,
              data: _data,
              flags: raised)['dominion'],
          -2);
    });

    test('a story offer logs under its cause', () {
      const story = OfferTicket(
          source: OfferSource.story, detail: 'story:n4', factionId: 'mire');
      const gift = OfferGift(kind: GiftKind.sign, id: 'mire_0');
      expect(offerCause(story, gift), 'story:n4');
      expect(story.major, isFalse);
      expect(offerCause(const OfferTicket(source: OfferSource.story), gift),
          'offer:mire_0');
    });
  });

  test('the politics state keeps what was applied, fired and told', () {
    final change = runDueEvents(
        politics: _apply(const {
          'standing': {'vigil': 3},
        }, key: 'story:n1:choice0')
            .politics,
        flags: const [],
        world: _world(
            chapter: 2,
            events: _events(const {
              'e': {
                'trigger': {'chapter': 1},
                'variants': [
                  {'news': 'Told.', 'news_fr': 'Dit.'},
                ],
              },
            })));
    final saved = PoliticsState.fromJson(
        jsonDecode(jsonEncode(change.politics.toJson())));
    expect(saved.appliedKeys, ['story:n1:choice0']);
    expect(saved.firedEvents['e']!.chapter, 2);
    expect(saved.news.single.textFr, 'Dit.');
    expect(saved.news.single.read, isFalse);
    expect(saved.unreadNews, hasLength(1));
    expect(saved.standingLog.last.note, 'Told.');
    expect(saved.standingLog.last.noteFor(AppLanguage.fr), 'Dit.');
    expect(saved.isEmpty, isFalse);
    // A save from before keeps nothing of it.
    final old = PoliticsState.fromJson(const {'standings': {}});
    expect(old.appliedKeys, isEmpty);
    expect(old.firedEvents, isEmpty);
    expect(old.news, isEmpty);
  });
}
