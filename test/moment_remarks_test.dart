// Wave 15 moment remarks: a companion in the party speaks up when the
// player builds certain houses, takes a risky gift (and on what its die
// did), or buys a temple service (momentRemark, momentPartyOf).
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/companion_remarks.dart';
import 'package:narrative_data_app/data/risky_gifts.dart';
import 'package:narrative_data_app/models/ally_state.dart';
import 'package:narrative_data_app/providers/moment_remark_provider.dart';

import 'player_session_provider_test.dart' show baseSession;

const _wave15 = [
  'builtParleyTent',
  'builtBoneCastersHut',
  'builtWardingCairn',
  'builtStarWell',
  'riskyTaken',
  'riskyWon',
  'riskyLostHealth',
  'riskyLostGold',
  'riskyLostCurse',
  'templeMended',
  'templeBlessed',
];

const _companions = [
  'grosh',
  'kelda',
  'liora',
  'malrik',
  'maren',
  'sable',
  'tobin',
  'vess',
];

// A few of Narrative's records as they are written
// (docs/proposals/wave15-remarks.json on claude/narrative-remarks-15).
const Map<String, dynamic> _narrativeSample = {
  'grosh_riskyLostCurse': {
    'remarkID': 'grosh_riskyLostCurse',
    'companionID': 'grosh',
    'trigger': 'riskyLostCurse',
    'lines': [
      'Curse! Grosh hits curses! ... Does not work. Grosh is sorry.',
      'Two levels. Grosh will stay close.',
    ],
    'lines_fr': [
      'Malédiction ! Grosh frappe les malédictions ! ... Ça ne marche pas. '
          'Grosh est désolé.',
      'Deux niveaux. Grosh restera près de toi.',
    ],
  },
  'sable_templeBlessed': {
    'remarkID': 'sable_templeBlessed',
    'companionID': 'sable',
    'trigger': 'templeBlessed',
    'lines': [
      'A blessing, three fights. Buy two, love, and see.',
      'Whoever is up there, I hope they take cash.',
    ],
    'lines_fr': [
      'Une bénédiction, trois combats. Achetez-en deux, mon cœur, et voyez.',
      'Qui que ce soit là-haut, j’espère qu’il prend l’argent liquide.',
    ],
  },
  'vess_builtStarWell': {
    'remarkID': 'vess_builtStarWell',
    'companionID': 'vess',
    'trigger': 'builtStarWell',
    'lines': [
      'A well that reaches the night. It looks back, you know.',
      'I will not lean over it. Not today.',
    ],
    'lines_fr': [
      'Un puits qui atteint la nuit. Il regarde aussi, vous savez.',
      'Je ne me pencherai pas dessus. Pas aujourd’hui.',
    ],
  },
};

/// All 88 records in Narrative's shape: the sample, and the rest filled in.
Map<String, dynamic> _all88() => {
      for (final id in _companions)
        for (final trigger in _wave15)
          '${id}_$trigger': {
            'remarkID': '${id}_$trigger',
            'companionID': id,
            'trigger': trigger,
            'lines': ['$id on $trigger, one', '$id on $trigger, two'],
            'lines_fr': ['$id sur $trigger, un', '$id sur $trigger, deux'],
          },
      ..._narrativeSample,
    };

Map<String, dynamic> _lines(String id, RemarkKind kind) => {
      '${id}_${kind.name}': {
        'companionID': id,
        'trigger': kind.name,
        'lines': ['$id a', '$id b'],
      },
    };

AllyState _ally(String id) =>
    AllyState(companionId: id, currentHealth: AllyState.fullHealthSentinel);

void main() {
  test('the 11 wave 15 kinds are triggers a record may have', () {
    for (final trigger in _wave15) {
      expect(remarkTriggerOptions, contains(trigger));
      expect(RemarkKind.values.asNameMap()[trigger], isNotNull);
    }
  });

  test("Narrative's 88 records load into a RemarkBook", () {
    final records = _all88();
    expect(records, hasLength(88));
    final book = RemarkBook(records);
    for (final id in _companions) {
      for (final trigger in _wave15) {
        final kind = RemarkKind.values.byName(trigger);
        expect(book.linesFor(id, kind), hasLength(2), reason: '$id $trigger');
        expect(book.linesFor(id, kind, french: true), hasLength(2));
      }
    }
    expect(book.linesFor('grosh', RemarkKind.riskyLostCurse).last,
        'Two levels. Grosh will stay close.');
    expect(book.linesFor('sable', RemarkKind.templeBlessed, french: true).last,
        'Qui que ce soit là-haut, j’espère qu’il prend l’argent liquide.');
  });

  group('momentRemark', () {
    test('a party member with lines speaks; nobody when none has any', () {
      final book = RemarkBook(_lines('malrik', RemarkKind.templeMended));
      const memory = RemarkMemory();
      final said = momentRemark(
          book, memory, const ['maren', 'malrik'], RemarkKind.templeMended);
      expect(said.remark?.companionId, 'malrik');
      expect(said.remark?.kind, RemarkKind.templeMended);
      expect(said.remark!.lineFor(book, french: false), isNotEmpty);

      final none = momentRemark(
          book, memory, const ['maren', 'malrik'], RemarkKind.templeBlessed);
      expect(none.remark, isNull);
      expect(identical(none.memory, memory), isTrue);
      // Lines, but not in the party: nobody.
      expect(
          momentRemark(book, memory, const ['maren'], RemarkKind.templeMended)
              .remark,
          isNull);
    });

    test('the one who spoke least recently goes first', () {
      final book = RemarkBook({
        ..._lines('maren', RemarkKind.riskyTaken),
        ..._lines('malrik', RemarkKind.riskyTaken),
      });
      const memory = RemarkMemory(
          choices: 9, lastSpokeAt: {'maren': 2, 'malrik': 8}, lastRemarkAt: 8);
      final said = momentRemark(
          book, memory, const ['malrik', 'maren'], RemarkKind.riskyTaken);
      expect(said.remark?.companionId, 'maren');
    });

    test('moments between two choices take turns, and never wait', () {
      final book = RemarkBook({
        for (final kind in [RemarkKind.riskyTaken, RemarkKind.riskyWon]) ...{
          ..._lines('maren', kind),
          ..._lines('malrik', kind),
        },
      });
      // Someone just spoke on this very choice: a moment does not wait.
      var memory = const RemarkMemory(
          choices: 4, lastRemarkAt: 4, lastSpokeAt: {'maren': 4});
      final party = ['maren', 'malrik'];
      final first = momentRemark(book, memory, party, RemarkKind.riskyTaken);
      expect(first.remark?.companionId, 'malrik');
      memory = first.memory;
      final second = momentRemark(book, memory, party, RemarkKind.riskyWon);
      expect(second.remark?.companionId, 'maren');
      memory = second.memory;
      // Each has said one line: the one further forward.
      final third = momentRemark(book, memory, party, RemarkKind.riskyTaken);
      expect(third.remark?.companionId, 'maren');
      memory = third.memory;
      final fourth = momentRemark(book, memory, party, RemarkKind.riskyTaken);
      expect(fourth.remark?.companionId, 'malrik');
      // Their lines go round rather than repeat.
      expect(fourth.remark!.index, isNot(first.remark!.index));
    });

    test('on a full tie, the one further forward in the party', () {
      final book = RemarkBook({
        ..._lines('maren', RemarkKind.builtStarWell),
        ..._lines('malrik', RemarkKind.builtStarWell),
      });
      final said = momentRemark(book, const RemarkMemory(),
          const ['malrik', 'maren'], RemarkKind.builtStarWell);
      expect(said.remark?.companionId, 'malrik');
    });
  });

  test('the party: picked, recruited, not lost or gone', () {
    final session = baseSession(
      recruitedAllies: [_ally('maren'), _ally('malrik'), _ally('vess')],
      activeAllyIds: const ['vess', 'maren', 'tobin', 'malrik'],
    ).copyWith(departedAllyIds: const ['malrik']);
    expect(momentPartyOf(session), ['vess', 'maren']);
    expect(momentPartyOf(session.copyWith(lostAllyIds: const ['vess'])),
        ['maren']);
  });

  test('the four houses and the die outcomes have their kinds', () {
    expect(houseBuiltRemarkKinds, {
      'parley_tent': RemarkKind.builtParleyTent,
      'bone_casters_hut': RemarkKind.builtBoneCastersHut,
      'warding_cairn': RemarkKind.builtWardingCairn,
      'star_well': RemarkKind.builtStarWell,
    });
    expect(houseBuiltRemarkKinds['parley_tent'], isNotNull);
    expect(
        houseBuiltRemarkKinds[parleyTentHouseId], RemarkKind.builtParleyTent);
    expect({
      for (final o in RiskyOutcome.values) o: riskyOutcomeRemarkKind(o),
    }, {
      RiskyOutcome.gift: RemarkKind.riskyWon,
      RiskyOutcome.health: RemarkKind.riskyLostHealth,
      RiskyOutcome.gold: RemarkKind.riskyLostGold,
      RiskyOutcome.curse: RemarkKind.riskyLostCurse,
    });
  });
}
