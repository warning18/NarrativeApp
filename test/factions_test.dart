// Clans (v1.193), the rules: the tiers, the ripple to allies and rivals,
// the one Sworn banner with its cost and caps, the clamps, the log, the
// sub-clan marks, relations that move and the snapshots the replay
// slider reads, and the data files' shapes.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';

Map<String, dynamic> _faction(String kind,
        {int start = 0, List<String> subclans = const []}) =>
    {
      'kind': kind,
      'name': 'N',
      'startStanding': start,
      'subclans': subclans,
    };

/// Four clans: red allied with blue (7), red and green rivals (2), blue
/// and gold trading (6), gold and green at war (2); a tribe with no
/// relations; the Choir. Red has two sub-clans.
final ClanData _data = ClanData.fromTables(
  factions: {
    'red': _faction('clan', subclans: ['red_a', 'red_b']),
    'blue': _faction('clan'),
    'green': _faction('clan', start: -10),
    'gold': _faction('clan'),
    'tribe': _faction('tribe'),
    'choir': _faction('otherworld'),
    '_newKinds': {'note': 'not a faction'},
  },
  subclans: {
    'red_a': {'clan': 'red', 'name': 'A', 'color': '#FF0000', 'lean': -1},
    'red_b': {'clan': 'red', 'name': 'B'},
  },
  relations: {
    'steps': [
      for (var i = 1; i <= 7; i++) {'step': i, 'name': 'S$i', 'color': '#111'},
    ],
    'pairs': [
      {'a': 'red', 'b': 'blue', 'step': 7, 'reason': 'Kin'},
      {'a': 'green', 'b': 'red', 'step': 2, 'reason': 'Feud'},
      {'a': 'blue', 'b': 'gold', 'step': 6},
      {'a': 'gold', 'b': 'green', 'step': 2},
      {'a': 'blue', 'b': 'green', 'step': 4},
    ],
    'history': [
      {'year': '600 BT', 'year_fr': '600 av. D.', 'name': 'Night'},
    ],
  },
);

StandingResult _change(PoliticsState state, String id, num delta) =>
    applyStandingChange(state, id, delta, 'offer',
        data: _data, chapter: 2, day: 9);

void main() {
  group('tiers', () {
    test('the seven ranges, edges included, and their prices', () {
      const cases = {
        -100: StandingTier.hunted,
        -61: StandingTier.hunted,
        -60: StandingTier.hostile,
        -26: StandingTier.hostile,
        -25: StandingTier.wary,
        -6: StandingTier.wary,
        -5: StandingTier.unknown,
        5: StandingTier.unknown,
        6: StandingTier.known,
        25: StandingTier.known,
        26: StandingTier.trusted,
        60: StandingTier.trusted,
        61: StandingTier.sworn,
        100: StandingTier.sworn,
      };
      cases.forEach((value, tier) {
        expect(standingTierFor(value), tier, reason: '$value');
      });
      expect(standingTierFor(5.4), StandingTier.unknown);
      expect(standingTierFor(5.5), StandingTier.known, reason: 'read rounded');
      expect(tierPriceFactor(StandingTier.hunted), isNull);
      expect(tierPriceFactor(StandingTier.hostile), 1.40);
      expect(tierPriceFactor(StandingTier.wary), 1.15);
      expect(tierPriceFactor(StandingTier.unknown), 1.0);
      expect(tierPriceFactor(StandingTier.known), 0.95);
      expect(tierPriceFactor(StandingTier.trusted), 0.85);
      expect(tierPriceFactor(StandingTier.sworn), 0.75);
      expect(tierColor(StandingTier.sworn), 0xFFF2C14E);
      expect(StandingTier.trusted.isAtLeast(StandingTier.known), isTrue);
      expect(StandingTier.wary.isAtLeast(StandingTier.unknown), isFalse);
    });
  });

  group('the data', () {
    test('factions, sub-clans and relations parse; notes are skipped', () {
      expect(_data.factions.keys, isNot(contains('_newKinds')));
      expect(_data.clans.map((f) => f.id), ['red', 'blue', 'green', 'gold']);
      expect(_data.tribes.single.id, 'tribe');
      expect(_data.otherworld.single.id, 'choir');
      expect(_data.subclansOf('red').map((s) => s.id), ['red_a', 'red_b']);
      expect(_data.subclan('red_a')!.lean, -1);
      expect(_data.subclan('red_a')!.color, 0xFFFF0000);
      expect(_data.relations.steps, hasLength(7));
      expect(_data.relations.pair('blue', 'red')!.reason, 'Kin');
      expect(
          _data.relations.history.single.yearFor(AppLanguage.fr), '600 av. D.');
      expect(patronsFromFactions(_data.factions)['choir']!.kind,
          PatronKind.otherworld);
      expect(parsePatrons({'_newKinds': <String, dynamic>{}, 'x': {}}).keys,
          ['x']);
    });

    test('allies are steps 6 and 7, rivals 1 to 3', () {
      const state = PoliticsState.empty;
      expect(alliesOf('red', state, _data), ['blue']);
      expect(rivalsOf('red', state, _data), ['green']);
      expect(alliesOf('blue', state, _data), ['red', 'gold']);
      expect(rivalsOf('blue', state, _data), isEmpty, reason: 'green is 4');
      expect(rivalsOf('green', state, _data), ['red', 'gold']);
      expect(alliesOf('tribe', state, _data), isEmpty);
    });

    test('a faction\'s Sworn boon keeps the kinds it doesn\'t know', () {
      final faction = Faction.fromJson('vigil', {
        'kind': 'clan',
        'name': 'Vigil',
        'lean': 3,
        'objects': [
          {'itemId': 'tonic', 'minTier': 'trusted'},
          {'itemId': ''},
        ],
        'sworn': {
          'name': 'Open Eyes',
          'effects': [
            {'kind': 'armor', 'value': 1},
            {'kind': 'intentPreview', 'value': 1},
          ],
        },
      });
      expect(faction.lean, 1, reason: 'clamped');
      expect(faction.objects.single.minTier, StandingTier.trusted);
      expect(faction.sworn!.effects.single.kind, SignEffectKind.armor);
      expect(faction.sworn!.unknownEffectKinds, ['intentPreview']);
      expect(faction.sworn!.rawEffects, hasLength(2));
    });
  });

  group('the ripple', () {
    test('a gain: allies a quarter, rivals lose half', () {
      final result = _change(PoliticsState.empty, 'red', 6);
      expect(result.deltas, {'red': 6, 'blue': 1.5, 'green': -3});
      final state = result.state;
      expect(state.standingOf('red', _data), 6);
      expect(state.standingOf('blue', _data), 1.5);
      expect(state.standingOf('green', _data), -13, reason: 'from -10');
      expect(state.standingOf('gold', _data), 0);
      expect(state.tierOf('red', _data), StandingTier.known);
    });

    test('a loss: allies share it, rivals don\'t move', () {
      final result = _change(PoliticsState.empty, 'red', -8);
      expect(result.deltas, {'red': -8, 'blue': -2});
    });

    test('a preview moves nothing', () {
      expect(standingPreview(PoliticsState.empty, 'red', 10, data: _data),
          {'red': 10, 'blue': 2.5, 'green': -5});
      expect(_change(PoliticsState.empty, 'nobody', 6).changed, isFalse);
      expect(_change(PoliticsState.empty, 'red', 0).changed, isFalse);
    });

    test('every standing stays within -100..100', () {
      var state = PoliticsState.empty;
      state = _change(state, 'red', 250).state;
      expect(state.standingOf('red', _data), lessThanOrEqualTo(100));
      expect(state.standingOf('green', _data), -100);
      state = _change(state, 'blue', -500).state;
      expect(state.standingOf('blue', _data), -100);
    });
  });

  group('the banner', () {
    test('reaching 61 swears, costs the rivals 20 and caps them at 25', () {
      var state = setStandingValue(PoliticsState.empty, 'green', 50, 'edit',
              data: _data)
          .state;
      state = setStandingValue(state, 'red', 56, 'edit', data: _data).state;
      expect(state.swornFactionId, '');
      final result = _change(state, 'red', 6);
      state = result.state;
      expect(state.swornFactionId, 'red');
      expect(result.swore, 'red');
      expect(result.entry!.swore, 'red');
      // Green: 50 - 3 (half the gain) - 20 (swearing) = 27, then capped.
      expect(state.standingOf('green', _data), swornRivalCap);
      expect(result.deltas['green'], -25);
      expect(state.tierOf('red', _data), StandingTier.sworn);
      // Its rivals at war with gold too: gold is no rival of red's.
      expect(state.standingOf('gold', _data), 0);
    });

    test('only one is sworn: the others stop at 60, its rivals at 25', () {
      var state = _change(PoliticsState.empty, 'red', 70).state;
      expect(state.swornFactionId, 'red');
      state = _change(state, 'gold', 90).state;
      expect(state.standingOf('gold', _data), 60);
      expect(state.swornFactionId, 'red');
      state = setStandingValue(state, 'green', 80, 'edit', data: _data).state;
      expect(state.standingOf('green', _data), swornRivalCap);
      expect(state.tierOf('green', _data), StandingTier.known);
      expect(state.swornFactionId, 'red');
    });

    test('losing the Sworn tier frees the rivals', () {
      var state = _change(PoliticsState.empty, 'red', 65).state;
      final result = _change(state, 'red', -10);
      state = result.state;
      expect(state.swornFactionId, '');
      expect(result.released, 'red');
      state = setStandingValue(state, 'green', 40, 'edit', data: _data).state;
      expect(state.standingOf('green', _data), 40);
    });

    test('the change\'s own faction swears before an ally reaching it', () {
      var state =
          setStandingValue(PoliticsState.empty, 'blue', 60, 'edit', data: _data)
              .state;
      state = _change(state, 'red', 61).state;
      // Blue would reach 75.25 by the ripple, but red is the one sworn.
      expect(state.swornFactionId, 'red');
      expect(state.standingOf('blue', _data), 60);
    });

    test('Edit Mode sets a value with no ripple, the banner still holds', () {
      var state =
          setStandingValue(PoliticsState.empty, 'red', 40, 'edit', data: _data)
              .state;
      expect(state.standingOf('blue', _data), 0);
      expect(state.standingOf('green', _data), -10);
      state = setStandingValue(state, 'red', 80, 'edit', data: _data).state;
      expect(state.swornFactionId, 'red');
      expect(state.standingOf('green', _data), -10, reason: 'no cost');
      state = setStandingValue(state, 'gold', 99, 'edit', data: _data).state;
      expect(state.standingOf('gold', _data), 60);
      state = setStandingValue(state, 'red', 10, 'edit', data: _data).state;
      expect(state.swornFactionId, '');
    });
  });

  group('the log', () {
    test('each change is dated, with its cause and every delta', () {
      var state = _change(PoliticsState.empty, 'red', 6).state;
      state = applyStandingChange(state, 'gold', -4, 'sea:Brig sunk',
              data: _data, chapter: 3, day: 21)
          .state;
      expect(state.standingLog, hasLength(2));
      final first = state.standingLog.first;
      expect(first.chapter, 2);
      expect(first.day, 9);
      expect(first.cause, 'offer');
      expect(first.factionId, 'red');
      expect(first.mainDelta, 6);
      expect(first.rippleDeltas, {'blue': 1.5, 'green': -3});
      expect(first.after['green'], -13);
      final last = state.standingLog.last;
      expect(last.deltas, {'gold': -4, 'blue': -1});
      expect(standingCauseLabel(last.cause, AppLanguage.en), 'Sea · Brig sunk');
      expect(standingCauseLabel('mystery', AppLanguage.en), 'mystery');
    });

    test('the history the chart draws, from where each started', () {
      var state = _change(PoliticsState.empty, 'red', 6).state;
      state = _change(state, 'gold', 8).state;
      final history = standingHistory(state, _data, ['red', 'green', 'gold']);
      expect(history, hasLength(3));
      expect(history[0], {'red': 0, 'green': -10, 'gold': 0});
      expect(history[1], {'red': 6, 'green': -13, 'gold': 0});
      expect(history[2], {'red': 6, 'green': -17, 'gold': 8});
    });

    test('numbers read the way the screens show them', () {
      expect(formatStanding(31), '+31');
      expect(formatStanding(-14.2), '\u221214');
      expect(formatStanding(0.4), '0');
      expect(formatStandingDelta(1.5), '+1.5');
      expect(formatStandingDelta(1.5, language: AppLanguage.fr), '+1,5');
      expect(formatStandingDelta(-3), '\u22123');
    });
  });

  group('marks', () {
    test('friend, none or foe, logged under the clan', () {
      final result = setSubclanMark(
          PoliticsState.empty, 'red_a', SubclanMark.foe, 'intrigue',
          data: _data, chapter: 4, day: 30);
      expect(result.changed, isTrue);
      expect(result.state.markOf('red_a'), SubclanMark.foe);
      expect(result.state.markOf('red_b'), SubclanMark.none);
      final entry = result.state.standingLog.single;
      expect(entry.factionId, 'red');
      expect(entry.subclanId, 'red_a');
      expect(entry.mark, SubclanMark.foe);
      expect(entry.deltas, isEmpty);
      final again = setSubclanMark(
          result.state, 'red_a', SubclanMark.foe, 'intrigue',
          data: _data);
      expect(again.changed, isFalse);
      final cleared = setSubclanMark(
          result.state, 'red_a', SubclanMark.none, 'edit',
          data: _data);
      expect(cleared.state.marks, isEmpty);
      expect(nextSubclanMark(SubclanMark.none), SubclanMark.friend);
      expect(nextSubclanMark(SubclanMark.friend), SubclanMark.foe);
      expect(nextSubclanMark(SubclanMark.foe), SubclanMark.none);
    });
  });

  group('relations', () {
    test('a shift moves a pair, logs it and changes the ripple', () {
      final result = shiftRelation(
          PoliticsState.empty, 'blue', 'green', -2, 'intrigue',
          data: _data, chapter: 3, day: 12);
      final state = result.state;
      expect(state.relationStep('green', 'blue', _data), 2);
      expect(rivalsOf('blue', state, _data), ['green']);
      final entry = state.relationsLog.single;
      expect([entry.from, entry.to, entry.chapter, entry.day], [4, 2, 3, 12]);
      expect(_change(state, 'blue', 4).deltas['green'], -2);
      // Within 1..7.
      final capped = shiftRelation(state, 'blue', 'green', -5, 'x',
          data: _data, chapter: 3);
      expect(capped.state.relationStep('blue', 'green', _data), 1);
      expect(
          shiftRelation(capped.state, 'blue', 'green', -1, 'x', data: _data)
              .changed,
          isFalse);
      // Back to where it opened: no override kept.
      final back = shiftRelation(state, 'green', 'blue', 2, 'x', data: _data);
      expect(back.state.relationSteps, isEmpty);
    });

    test('the snapshot per chapter replays the table', () {
      var state = shiftRelation(PoliticsState.empty, 'red', 'blue', -1, 'a',
              data: _data, chapter: 2)
          .state;
      state =
          shiftRelation(state, 'red', 'blue', -2, 'b', data: _data, chapter: 4)
              .state;
      state =
          shiftRelation(state, 'gold', 'green', 3, 'c', data: _data, chapter: 4)
              .state;
      String key(String a, String b) => relationKey(a, b);
      expect(relationsAtChapter(state, 1, _data)[key('red', 'blue')], 7);
      expect(relationsAtChapter(state, 2, _data)[key('red', 'blue')], 6);
      expect(relationsAtChapter(state, 3, _data)[key('red', 'blue')], 6);
      expect(relationsAtChapter(state, 4, _data)[key('red', 'blue')], 4);
      expect(relationsAtChapter(state, 4, _data)[key('gold', 'green')], 5);
      expect(relationsAtChapter(state, 7, _data)[key('gold', 'green')], 5);
      expect(relationsAtChapter(state, 3, _data)[key('gold', 'green')], 2);
    });

    test('while sworn, a pair turned rival is capped at once', () {
      var state =
          setStandingValue(PoliticsState.empty, 'gold', 50, 'edit', data: _data)
              .state;
      state = _change(state, 'red', 70).state;
      expect(state.swornFactionId, 'red');
      expect(state.standingOf('gold', _data), 50);
      final result =
          shiftRelation(state, 'red', 'gold', -4, 'war', data: _data);
      expect(result.state.standingOf('gold', _data), swornRivalCap);
      expect(result.standing!.cause, 'sworn_cap');
    });
  });

  group('the save', () {
    test('a round trip keeps everything; an old save reads empty', () {
      var state = _change(PoliticsState.empty, 'red', 70).state;
      state = setSubclanMark(state, 'red_b', SubclanMark.friend, 'offer',
              data: _data)
          .state;
      state =
          shiftRelation(state, 'gold', 'green', 1, 'x', data: _data, chapter: 5)
              .state;
      final back = PoliticsState.fromJson(state.toJson());
      expect(back.standings, state.standings);
      expect(back.marks, state.marks);
      expect(back.swornFactionId, 'red');
      expect(back.relationSteps, state.relationSteps);
      expect(back.relationSnapshots, state.relationSnapshots);
      expect(back.standingLog, hasLength(state.standingLog.length));
      expect(back.standingLog.first.deltas, state.standingLog.first.deltas);
      expect(back.standingLog.last.mark, SubclanMark.friend);
      expect(back.relationsLog.single.to, 3);
      expect(PoliticsState.fromJson(null).isEmpty, isTrue);
      expect(PoliticsState.fromJson('junk').isEmpty, isTrue);
    });
  });

  group('intrigues', () {
    test('the stage reached and the outcome come from flags', () {
      expect(intrigueStageFrom(const [], 'hooded'), 0);
      expect(
          intrigueStageFrom(const [
            'intrigue_hooded_stage_2',
            'intrigue_hooded_stage_4',
            'intrigue_other_stage_6',
          ], 'hooded'),
          4);
      expect(intrigueStageFrom(const ['intrigue_hooded_stage=5'], 'hooded'), 5);
      expect(intrigueStageFrom(const ['intrigue_hooded_stage_9'], 'hooded'), 0);
      expect(intrigueOutcomeFrom(const ['intrigue_hooded_outcome_1'], 'hooded'),
          1);
      final intrigue = Intrigue.fromJson('hooded', {
        'name': 'The Hooded Lantern',
        'factions': ['red', 'blue'],
        'stages': [
          {'stage': 'Clue', 'chapter': '1–2', 'text': 'A clue.'},
        ],
        'outcomes': [
          {
            'name': 'Expose',
            'effects': [
              {'faction': 'blue', 'delta': 25},
              {'subclan': 'red_a', 'mark': 'foe'},
              {'note': 'Vess leaves'},
            ],
          },
        ],
      });
      expect(intrigue.stages.single.key, 'intrigue_stage_clue');
      final effects = intrigue.outcomes.single.effects;
      expect(effects[0].delta, 25);
      expect(effects[1].mark, SubclanMark.foe);
      expect(effects[2].note, 'Vess leaves');
    });
  });
}
