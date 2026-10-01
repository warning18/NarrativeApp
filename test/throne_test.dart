// The climb to the Lantern Throne and the Host (v1.196), the rules, on
// fixtures (independent of the story): the politics a choice carries
// (`claim`, `pledge`, `throneWinner`, `muster`), the gate conditions
// (`claim`, `rungAtLeast`, `throneWinner`) shared by `politicsIf` and the
// events' variants, the rungs and the climb, the Host and its effects,
// the throne's title, the state's JSON, and the choice's hint.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/politics_events.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/data/throne.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/models/story_node.dart';

Map<String, dynamic> _host(String kind, int value) => {
      'effects': [
        {'kind': kind, 'value': value},
      ],
      'line': 'They come.',
      'line_fr': 'Ils viennent.',
    };

/// The Dominion (rival of the Vigil), the Vigil and the Compact (allies),
/// the Mire, a tribe, the Choir and the Pit, and the Open Hand with its
/// one House; each with a contingent, and a throne title for the Vigil.
final ClanData _data = ClanData.fromTables(
  factions: {
    'dominion': {
      'kind': 'clan',
      'name': 'The Lantern Dominion',
      'name_fr': 'Le Dominion de la Lanterne',
      'short': 'Dominion',
      'startStanding': -10,
      'subclans': ['inquisition', 'wickwardens'],
      'host': _host('partyStartBlock', 2),
    },
    'vigil': {
      'kind': 'clan',
      'name': 'The Grey Vigil',
      'name_fr': 'La Veille Grise',
      'short': 'Vigil',
      'subclans': ['stitchers'],
      'host': _host('firstRoundDamagePercent', 12),
    },
    'compact': {
      'kind': 'clan',
      'name': 'The Cinder Compact',
      'name_fr': 'Le Pacte des Cendres',
      'short': 'Compact',
      'subclans': ['quarrymen'],
      'host': _host('guardBlockPercent', 10),
    },
    'mire': {
      'kind': 'clan',
      'name': 'The Mire Courts',
      'short': 'Mire',
      'host': _host('mendPercent', 10),
    },
    'giants': {
      'kind': 'tribe',
      'name': 'The giants',
      'short': 'Giants',
      'host': _host('maxHealth', 8),
    },
    'choir': {
      'kind': 'otherworld',
      'name': 'The Choir',
      'host': _host('guardHeal', 2),
    },
    'pit': {
      'kind': 'otherworld',
      'name': 'The Pit',
      'host': _host('killHeal', 3),
    },
    'open_hand': {
      'kind': 'lost',
      'name': 'The Open Hand',
      'name_fr': 'La Main Ouverte',
      'host': _host('allyDamagePercent', 6),
    },
  },
  subclans: {
    'inquisition': {'clan': 'dominion', 'name': 'The Inquisition'},
    'wickwardens': {'clan': 'dominion', 'name': 'The Wickwardens'},
    'stitchers': {'clan': 'vigil', 'name': 'The Stitchers'},
    'quarrymen': {'clan': 'compact', 'name': 'The Quarrymen'},
    'fishbasket_line': {'clan': 'open_hand', 'name': 'The Fishbasket Line'},
  },
  relations: {
    'pairs': [
      {'a': 'dominion', 'b': 'vigil', 'step': 2},
      {'a': 'compact', 'b': 'vigil', 'step': 6},
      {'a': 'dominion', 'b': 'compact', 'step': 4},
    ],
  },
  titles: {
    'throne_vigil': {
      'name': 'Warden of the Throne',
      'faction': 'vigil',
      'source': 'throne:vigil',
    },
    'throne_open_hand': {
      'name': 'The Open Hand Returned',
      'faction': 'open_hand',
      'source': 'throne:open_hand',
    },
  },
);

CoastWorld _w({int chapter = 7, List<String> signPatrons = const []}) =>
    CoastWorld(
        data: _data, chapter: chapter, day: 40, signPatrons: signPatrons);

CoastChange _apply(
  Map<String, dynamic> json, {
  PoliticsState politics = PoliticsState.empty,
  List<String> flags = const [],
  List<String> signPatrons = const [],
}) =>
    applyStoryPolitics(StoryPolitics.tryParse(json)!,
        cause: 'story:t',
        politics: politics,
        flags: flags,
        world: _w(signPatrons: signPatrons));

PoliticsState _standing(Map<String, num> values,
    {PoliticsState from = PoliticsState.empty}) {
  var p = from;
  for (final e in values.entries) {
    p = setStandingValue(p, e.key, e.value, 'edit', data: _data).state;
  }
  return p;
}

PoliticsState _friend(List<String> subclans,
    {PoliticsState from = PoliticsState.empty}) {
  var p = from;
  for (final s in subclans) {
    p = setSubclanMark(p, s, SubclanMark.friend, 'edit', data: _data).state;
  }
  return p;
}

void main() {
  group('the politics keys', () {
    test('claim, pledge, throneWinner and muster read and write back', () {
      final p = StoryPolitics.tryParse({
        'claim': 'compact',
        'pledge': ['vigil', 'mire'],
        'throneWinner': 'compact',
        'muster': true,
      })!;
      expect(p.claim, 'compact');
      expect(p.pledges, ['vigil', 'mire']);
      expect(p.throneWinner, 'compact');
      expect(p.muster, isTrue);
      expect(p.isEmpty, isFalse);
      expect(p.extra, isEmpty);
      expect(p.toJson(), {
        'claim': 'compact',
        'pledge': ['vigil', 'mire'],
        'throneWinner': 'compact',
        'muster': true,
      });
      expect(StoryPolitics.tryParse({'pledge': 'vigil'})!.toJson(),
          {'pledge': 'vigil'});
      expect(StoryPolitics.tryParse({'muster': true})!.hasHint, isFalse);
      expect(StoryPolitics.tryParse({'pledge': 'vigil'})!.hasHint, isTrue);
      expect(
          StoryPolitics.tryParse({'claim': 'vigil', 'hidden': true})!.hasHint,
          isFalse);
    });

    test('a story choice keeps its gate and its last-battle mark', () {
      final choice = StoryChoice.fromJson({
        'text': 'Take the hammer',
        'next_id': '2',
        'politicsIf': {
          'claim': 'none',
          'rungAtLeast': {'compact': 1},
        },
        'hostFight': true,
      });
      expect(choice.politicsIf['claim'], 'none');
      expect(choice.hostFight, isTrue);
      final back = choice.toJson();
      expect(back['politicsIf'], {
        'claim': 'none',
        'rungAtLeast': {'compact': 1},
      });
      expect(back['hostFight'], isTrue);
    });
  });

  group('the claim', () {
    test('raises the faction to Sworn, sets its flag and logs it', () {
      final change = _apply({'claim': 'compact'});
      expect(change.politics.claim, 'compact');
      expect(change.politics.standingOf('compact', _data),
          greaterThanOrEqualTo(swornThreshold));
      expect(change.politics.swornFactionId, 'compact');
      expect(change.flags, contains('claim_compact'));
      final entry = change.politics.standingLog.last;
      expect(entry.cause, 'claim');
      expect(entry.factionId, 'compact');
      // No ripple: the Vigil (the Compact's ally) did not move.
      expect(change.politics.standingOf('vigil', _data), 0);
    });

    test('a second claim renounces the first', () {
      final first = _apply({'claim': 'vigil'});
      final vigilBefore = first.politics.standingOf('vigil', _data);
      final second = _apply({'claim': 'compact'},
          politics: first.politics, flags: first.flags);
      expect(second.politics.claim, 'compact');
      expect(second.politics.standingOf('vigil', _data),
          lessThanOrEqualTo(vigilBefore - renounceCost));
      expect(second.flags, contains('claim_compact'));
      expect(second.flags, isNot(contains('claim_vigil')));
      expect(second.politics.swornFactionId, 'compact');
      final causes = [for (final e in second.politics.standingLog) e.cause];
      expect(causes, containsAllInOrder(['renounce:vigil', 'claim']));
    });

    test('the claim takes the banner from another sworn faction', () {
      var politics = _standing({'mire': 70});
      expect(politics.swornFactionId, 'mire');
      politics = _apply({'claim': 'compact'}, politics: politics).politics;
      expect(politics.swornFactionId, 'compact');
      expect(politics.standingOf('mire', _data), lessThanOrEqualTo(60));
    });

    test('the Open Hand can be claimed: no standing, the log says so', () {
      final change = _apply({'claim': 'open_hand'});
      expect(change.politics.claim, 'open_hand');
      expect(change.flags, contains('claim_open_hand'));
      expect(change.politics.standingLog.last.cause, 'claim');
      final again = _apply({'claim': 'vigil'},
          politics: change.politics, flags: change.flags);
      expect(again.politics.standingLog.map((e) => e.cause),
          contains('renounce:open_hand'));
    });
  });

  group('the pledge, the crown and the muster', () {
    test('a pledge joins the cause once', () {
      final change = _apply({
        'pledge': ['vigil', 'vigil']
      });
      expect(change.politics.pledged, ['vigil']);
      expect(change.flags, contains('pledged_vigil'));
      expect(change.politics.standingLog.where((e) => e.cause == 'pledge'),
          hasLength(1));
    });

    test('the coronation sets its flags and gives the throne title', () {
      final change = _apply({'claim': 'vigil', 'throneWinner': 'vigil'});
      expect(change.politics.throneWinner, 'vigil');
      expect(change.flags, containsAll(['throne_winner_vigil', 'on_throne']));
      expect(change.titles, ['throne_vigil']);
      final again = _apply({'throneWinner': 'open_hand'},
          politics: change.politics, flags: change.flags);
      expect(again.flags, contains('throne_winner_open_hand'));
      expect(again.flags, isNot(contains('throne_winner_vigil')));
    });

    test('titlesEarned gives the throne title to the one on the Throne', () {
      final crowned = PoliticsState.empty.copyWith(throneWinner: 'vigil');
      final earned = titlesEarned(const [], crowned, _data);
      expect(earned.gained, ['throne_vigil']);
      expect(titlesEarned(const [], PoliticsState.empty, _data).held, isEmpty);
    });

    test('the muster keeps the Host and sets its counted flags', () {
      var politics = _standing({'mire': 30, 'giants': 40, 'dominion': -40});
      politics =
          _friend(['stitchers', 'quarrymen', 'inquisition'], from: politics);
      final change = _apply(
          {'claim': 'vigil', 'throneWinner': 'vigil', 'muster': true},
          politics: politics,
          signPatrons: const ['choir']);
      expect(change.mustered, isTrue);
      final host = change.politics.host;
      expect(host.mustered, isTrue);
      expect(host.chapter, 7);
      expect(host.banner, 'vigil');
      expect(host.allies, ['mire', 'giants', 'choir']);
      expect(host.houses, ['inquisition', 'stitchers', 'quarrymen']);
      expect(
          change.flags,
          containsAll([
            'host_vigil',
            'host_mire',
            'host_giants',
            'host_choir',
            'host_houses_3',
            'host_size_7',
          ]));
      // The counts are exact: one paragraph a count.
      expect(change.flags, isNot(contains('host_houses_1')));
      expect(change.flags, isNot(contains('host_houses_4')));
      expect(change.flags, isNot(contains('host_size_6')));
      expect(change.flags, isNot(contains('host_dominion')));
      // A second muster replaces the first one's flags.
      final again = _apply({'muster': true},
          politics: change.politics
              .copyWith(appliedKeys: const [], pledged: const ['dominion']),
          flags: change.flags);
      expect(again.flags, isNot(contains('host_choir')));
      // More Houses than the story counts read as the most it does.
      expect(hostFlagsFor(Host(houses: [for (var i = 0; i < 25; i++) 'h$i'])),
          containsAll(['host_houses_20', 'host_size_25']));
      expect(hostFlagsFor(Host.none), isEmpty);
    });

    test('a scene muster then fires its event, which reads the Host', () {
      // 7800's way: {"muster": true, "event": "the_last_battle"}.
      final events = parsePoliticsEvents({
        'the_last_battle': {
          'variants': [
            {
              'conditions': {
                'flags': ['host_vigil']
              },
              'effects': {
                'flags': ['vigil_came']
              },
              'news': 'The Vigil came.',
            },
            {
              'effects': {
                'flags': ['nobody_came']
              }
            },
          ],
        },
      });
      final politics = _standing({'vigil': 40});
      final change = applyStoryPolitics(
          StoryPolitics.tryParse({'muster': true, 'event': 'the_last_battle'})!,
          cause: 'story:7800',
          politics: politics,
          flags: const [],
          world: CoastWorld(data: _data, chapter: 8, events: events));
      expect(change.flags, containsAll(['host_vigil', 'vigil_came']));
      expect(change.flags, isNot(contains('nobody_came')));
    });

    test(
        'flags the story set too change nothing; a claim still drops '
        'the last one\'s', () {
      // 7500 sets claim_<id> by flagsToAdd beside its claim.
      final first = _apply({'claim': 'vigil'},
          flags: const ['claim_vigil', 'throne_winner_vigil']);
      expect(first.flags.where((f) => f == 'claim_vigil'), hasLength(1));
      final second = _apply({
        'claim': 'compact',
        'flags': ['claim_compact']
      }, politics: first.politics, flags: first.flags);
      expect(
          second.flags.where((f) => f.startsWith('claim_')), ['claim_compact']);
      final crowned = _apply({
        'throneWinner': 'compact',
        'flags': ['throne_winner_compact', 'on_throne']
      }, politics: second.politics, flags: second.flags);
      expect(crowned.flags.where((f) => f.startsWith('throne_winner_')),
          ['throne_winner_compact']);
      expect(crowned.flags.where((f) => f == 'on_throne'), hasLength(1));
      // A late claim alone is politics enough.
      expect(StoryPolitics.tryParse({'claim': 'open_hand'}), isNotNull);
      expect(
          StoryChoice.fromJson({
            'text': 'Raise the grey hand',
            'next_id': '7510_open_hand',
            'politics': {'claim': 'open_hand'},
          }).hasPolitics,
          isTrue);
    });
  });

  group('the gate conditions', () {
    bool holds(Map<String, dynamic> conditions, PoliticsState politics,
            {List<String> flags = const []}) =>
        politicsIfHolds(conditions,
            politics: politics, flags: flags, world: _w());

    test('claim: an id, any, none, or a list', () {
      final claimed = PoliticsState.empty.copyWith(claim: 'vigil');
      expect(holds({'claim': 'vigil'}, claimed), isTrue);
      expect(holds({'claim': 'compact'}, claimed), isFalse);
      expect(holds({'claim': 'any'}, claimed), isTrue);
      expect(holds({'claim': 'none'}, claimed), isFalse);
      expect(holds({'claim': 'none'}, PoliticsState.empty), isTrue);
      expect(holds({'claim': 'any'}, PoliticsState.empty), isFalse);
      expect(
          holds({
            'claim': ['compact', 'vigil']
          }, claimed),
          isTrue);
    });

    test('rungAtLeast reads the House, the claim and the Throne', () {
      final house = _friend(['quarrymen']);
      expect(rungFor('compact', house, _data), rungHouse);
      expect(
          holds({
            'rungAtLeast': {'compact': 1}
          }, house),
          isTrue);
      expect(
          holds({
            'rungAtLeast': {'compact': 2}
          }, house),
          isFalse);
      expect(
          holds({
            'rungAtLeast': {'vigil': 1}
          }, house),
          isFalse);
      final claimed = house.copyWith(claim: 'compact');
      expect(
          holds({
            'rungAtLeast': {'compact': 2}
          }, claimed),
          isTrue);
      final crowned = claimed.copyWith(throneWinner: 'compact');
      expect(rungFor('compact', crowned, _data), rungThrone);
      expect(
          holds({
            'rungAtLeast': {'compact': 3}
          }, crowned),
          isTrue);
      // The Open Hand's House.
      expect(
          rungFor('open_hand', _friend(['fishbasket_line']), _data), rungHouse);
    });

    test('throneWinner, with the old keys beside it', () {
      final crowned = _standing({'vigil': 30}).copyWith(throneWinner: 'vigil');
      expect(holds({'throneWinner': 'vigil'}, crowned), isTrue);
      expect(holds({'throneWinner': 'any'}, crowned), isTrue);
      expect(holds({'throneWinner': 'none'}, crowned), isFalse);
      expect(
          holds(
              {
                'throneWinner': 'vigil',
                'standingAtLeast': {'vigil': 26},
                'flags': ['x'],
              },
              crowned,
              flags: const ['x']),
          isTrue);
      expect(
          holds({
            'throneWinner': 'vigil',
            'flags': ['x'],
          }, crowned),
          isFalse);
    });

    test('an event variant reads them too', () {
      final event = PoliticsEvent.fromJson('succession', {
        'variants': [
          {
            'conditions': {'claim': 'dominion'},
            'effects': {
              'flags': ['houses_wait']
            },
          },
          {
            'conditions': {
              'rungAtLeast': {'vigil': 1}
            },
            'effects': {
              'flags': ['vigil_house']
            },
          },
          {
            'effects': {
              'flags': ['default']
            }
          },
        ],
      });
      int variant(PoliticsState p) =>
          eventVariantFor(event, politics: p, flags: const [], world: _w());
      expect(variant(PoliticsState.empty.copyWith(claim: 'dominion')), 0);
      expect(variant(_friend(['stitchers'])), 1);
      expect(variant(PoliticsState.empty), 2);
    });

    test('a choice failing its gate is hidden, or locked with a text', () {
      StoryChoice choice({String? locked}) => StoryChoice.fromJson({
            'text': 'Walk before us',
            'next_id': '2',
            'politicsIf': {'claim': 'any'},
            if (locked != null) 'lockedText': locked,
          });
      ChoiceGate gate(StoryChoice c, PoliticsState p) =>
          choicePoliticsGate(c, politics: p, flags: const [], world: _w());
      expect(gate(choice(), PoliticsState.empty), ChoiceGate.hidden);
      expect(gate(choice(locked: 'Only a claimant.'), PoliticsState.empty),
          ChoiceGate.locked);
      expect(gate(choice(), PoliticsState.empty.copyWith(claim: 'vigil')),
          ChoiceGate.open);
      expect(
          gate(StoryChoice.fromJson({'text': 'Go', 'next_id': '2'}),
              PoliticsState.empty),
          ChoiceGate.open);
    });
  });

  group('the climb', () {
    test('steps come from the clan quest flags', () {
      expect(clanStepsFrom(const [], 'vigil'), 0);
      expect(
          clanStepsFrom(
              const ['clan_vigil_step_1', 'clan_vigil_step_2'], 'vigil'),
          2);
      expect(clanStepsFrom(const ['clan_vigil_step_3'], 'vigil'), 3);
      expect(clanStepsFrom(const ['clan_compact_step_3'], 'vigil'), 0);
    });

    test('climbFor and the faction the Character tab follows', () {
      final politics = _friend(['stitchers', 'quarrymen']);
      final flags = ['clan_compact_step_1'];
      final climb = climbFor('vigil', politics, flags, _data);
      expect(climb.house?.id, 'stitchers');
      expect(climb.rung, rungHouse);
      expect(climb.steps, 0);
      expect(climbFocusFor(politics, flags, _data), 'compact');
      expect(climbFocusFor(PoliticsState.empty, const [], _data), '');
      expect(climbFocusFor(politics.copyWith(claim: 'vigil'), flags, _data),
          'vigil');
      expect(
          climbFocusFor(
              politics.copyWith(claim: 'vigil', throneWinner: 'open_hand'),
              flags,
              _data),
          'open_hand');
    });
  });

  group('the Host', () {
    test(
        'allies: Trusted or pledged, never Hostile; the otherworld by '
        'its signs', () {
      var politics = _standing({
        'compact': 26,
        'mire': 25,
        'giants': 60,
        'dominion': -30,
      });
      politics = politics
          .copyWith(claim: 'vigil', pledged: const ['mire', 'dominion', 'pit']);
      final host =
          hostFor(politics: politics, data: _data, signPatrons: const []);
      expect(host.banner, 'vigil');
      // The Dominion pledged but is Hostile; the Pit pledged.
      expect(host.allies, ['compact', 'mire', 'giants', 'pit']);
      expect(
          hostFor(
              politics: PoliticsState.empty,
              data: _data,
              signPatrons: const ['choir']).allies,
          ['choir']);
      // The throne's faction flies the banner over the claim.
      expect(
          hostFor(
                  politics: politics.copyWith(throneWinner: 'open_hand'),
                  data: _data)
              .banner,
          'open_hand');
    });

    test('the effects: each contingent and the Houses', () {
      const host = Host(
          banner: 'vigil',
          allies: ['compact'],
          houses: ['stitchers', 'quarrymen', 'inquisition']);
      final effects = hostEffects(host, _data);
      int sum(SignEffectKind kind) => effects
          .where((e) => e.kind == kind)
          .fold(0, (total, e) => total + e.value);
      expect(sum(SignEffectKind.firstRoundDamagePercent), 12);
      expect(sum(SignEffectKind.guardBlockPercent), 10);
      expect(sum(SignEffectKind.partyStartBlock), 1);
      expect(sum(SignEffectKind.partyMaxHealthPercent), 3);
      // The Houses' bonus stops at its caps.
      int houses(int n, SignEffectKind kind) => houseEffects(n)
          .where((e) => e.kind == kind)
          .fold(0, (total, e) => total + e.value);
      expect(houses(0, SignEffectKind.partyStartBlock), 0);
      expect(houses(12, SignEffectKind.partyStartBlock), houseBlockMax);
      expect(houses(12, SignEffectKind.partyMaxHealthPercent), houseHealthMax);
      // Through the Signs pipeline, as a fight reads it.
      final signs = signEffectsFor(const [], const {},
          alignment: 0, extra: hostEffects(host, _data));
      expect(signs.firstRoundDamagePercent, 12);
      expect(signs.guardBlockPercent, 10);
      expect(signs.partyStartBlock, 1);
      expect(Host.none.contingents, isEmpty);
      expect(hostEffects(Host.none, _data), isEmpty);
    });

    test('the Host fielded is the mustered one, else the one now', () {
      final politics = _standing({'compact': 40}).copyWith(claim: 'vigil');
      expect(fieldedHost(politics: politics, data: _data).allies, ['compact']);
      final mustered = politics.copyWith(
          host: const Host(banner: 'vigil', chapter: 8, day: 3));
      expect(fieldedHost(politics: mustered, data: _data).allies, isEmpty);
    });
  });

  group('the state', () {
    test('claim, throne, pledges and the Host survive a save', () {
      final state = PoliticsState.empty.copyWith(
        claim: 'compact',
        throneWinner: 'compact',
        pledged: const ['vigil', 'giants'],
        host: const Host(
            banner: 'compact',
            allies: ['vigil'],
            houses: ['stitchers'],
            chapter: 8,
            day: 12),
      );
      final back = PoliticsState.fromJson(state.toJson());
      expect(back.claim, 'compact');
      expect(back.throneWinner, 'compact');
      expect(back.pledged, ['vigil', 'giants']);
      expect(back.host.banner, 'compact');
      expect(back.host.allies, ['vigil']);
      expect(back.host.houses, ['stitchers']);
      expect(back.host.chapter, 8);
      expect(back.host.day, 12);
      expect(back.isEmpty, isFalse);
    });

    test('a save from before the climb loads with none of it', () {
      final old = PoliticsState.fromJson({
        'standings': {'vigil': 12.0},
        'marks': {'stitchers': 'friend'},
        'sworn': '',
      });
      expect(old.claim, isEmpty);
      expect(old.throneWinner, isEmpty);
      expect(old.pledged, isEmpty);
      expect(old.host.mustered, isFalse);
      expect(PoliticsState.empty.toJson().containsKey('claim'), isFalse);
      expect(PoliticsState.empty.toJson().containsKey('host'), isFalse);
    });
  });

  group('the words', () {
    test(
        'the hint names the claim, the one given up, a pledge and the '
        'Throne', () {
      final claim = StoryPolitics.tryParse({'claim': 'compact'});
      expect(politicsHint(claim, _data, AppLanguage.en),
          'Claim: The Cinder Compact');
      expect(
          politicsHint(claim, _data, AppLanguage.en,
              politics: PoliticsState.empty.copyWith(claim: 'vigil')),
          'Claim: The Cinder Compact (gives up the Grey Vigil)');
      expect(
          politicsHint(claim, _data, AppLanguage.fr,
              politics: PoliticsState.empty.copyWith(claim: 'vigil')),
          'Prétention : Le Pacte des Cendres (vous quittez la Veille '
          'Grise)');
      expect(
          politicsHint(StoryPolitics.tryParse({'pledge': 'vigil'}), _data,
              AppLanguage.en),
          'Joins your cause: The Grey Vigil');
      expect(
          politicsHint(StoryPolitics.tryParse({'throneWinner': 'open_hand'}),
              _data, AppLanguage.fr),
          'Le Trône : La Main Ouverte');
      expect(midSentenceName('L’Inquisition'), 'l’Inquisition');
      expect(midSentenceName('Salt Crows'), 'Salt Crows');
    });
  });
}
