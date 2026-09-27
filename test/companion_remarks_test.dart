// Companion remarks (v1.167): who speaks up about the player's choices,
// with which line, how often, and whether every companion has their words
// in both languages.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/approval.dart';
import 'package:narrative_data_app/data/companion_remarks.dart';
import 'package:narrative_data_app/widgets/approval_notice.dart';

Map<String, dynamic> _companions() {
  for (final path in [
    'assets/gamedata/companions.json',
    '../assets/gamedata/companions.json'
  ]) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  throw StateError('Cannot find companions.json');
}

ApprovalChange _moved(String id, int delta, {int before = 3}) =>
    ApprovalChange(companionId: id, before: before, after: before + delta);

void main() {
  final companions = _companions();
  Map<String, dynamic> record(String id) =>
      companions[id] as Map<String, dynamic>;

  group('the lines', () {
    const everyone = [
      RemarkKind.approved,
      RemarkKind.disapproved,
      RemarkKind.checkPassed,
      RemarkKind.checkFailed,
      RemarkKind.sneakedPast,
    ];

    test('every companion speaks, on every deed they care about', () {
      expect(companionsWithRemarks.toSet(), companions.keys.toSet());
      for (final id in companions.keys) {
        final weights = record(id);
        final good = (weights['approvesGood'] as num?)?.toInt() ?? 0;
        final evil = (weights['approvesEvil'] as num?)?.toInt() ?? 0;
        final profit = (weights['approvesProfit'] as num?)?.toInt() ?? 0;
        final needed = [
          ...everyone,
          if (good > 0) RemarkKind.kindApproved,
          if (good < 0) RemarkKind.kindDisapproved,
          if (evil > 0) RemarkKind.cruelApproved,
          if (evil < 0) RemarkKind.cruelDisapproved,
          if (profit > 0) RemarkKind.profitApproved,
          if (profit < 0) RemarkKind.profitDisapproved,
        ];
        for (final kind in needed) {
          expect(remarkLinesFor(id, kind), hasLength(greaterThanOrEqualTo(2)),
              reason: '$id ${kind.name}');
        }
      }
    });

    test('English and French line up, and none is empty', () {
      for (final id in companionsWithRemarks) {
        for (final kind in RemarkKind.values) {
          final en = remarkLinesFor(id, kind);
          final fr = remarkLinesFor(id, kind, french: true);
          expect(fr.length, en.length, reason: '$id ${kind.name}');
          for (final line in [...en, ...fr]) {
            expect(line.trim(), isNotEmpty, reason: '$id ${kind.name}');
            expect(line, isNot(contains('“')), reason: 'quoted when shown');
          }
        }
      }
    });

    test('French speaks to the player as « vous »', () {
      final tu = RegExp(r"(?<!\p{L})(?:(?:tu|toi|ton|ta|tes)(?!\p{L})|t['’])",
          caseSensitive: false, unicode: true);
      for (final id in companionsWithRemarks) {
        for (final kind in RemarkKind.values) {
          for (final line in remarkLinesFor(id, kind, french: true)) {
            // « s'est tu » is the Void falling silent, not « tu ».
            expect(tu.hasMatch(line.replaceAll("s'est tu", '')), isFalse,
                reason: line);
          }
        }
      }
    });

    test('a remark reads in the language on screen', () {
      const remark = CompanionRemark(
          companionId: 'maren', kind: RemarkKind.kindApproved, index: 0);
      expect(remark.lineFor(french: false),
          remarkLinesFor('maren', RemarkKind.kindApproved).first);
      expect(remark.lineFor(french: true),
          remarkLinesFor('maren', RemarkKind.kindApproved, french: true).first);
    });
  });

  group('what the reaction was about', () {
    test('kindness and cruelty, by where the companion stands', () {
      const kind = RemarkDeed(alignmentMod: 1);
      const cruel = RemarkDeed(alignmentMod: -2);
      expect(remarkKindFor(_moved('maren', 3), record('maren'), kind),
          RemarkKind.kindApproved);
      expect(remarkKindFor(_moved('sable', -1), record('sable'), kind),
          RemarkKind.kindDisapproved);
      expect(remarkKindFor(_moved('maren', -3), record('maren'), cruel),
          RemarkKind.cruelDisapproved);
      expect(remarkKindFor(_moved('malrik', 2), record('malrik'), cruel),
          RemarkKind.cruelApproved);
    });

    test('the part that moved them most, in the way they moved', () {
      // Sable: kindness -1, the gold +2. She comes out ahead: the gold.
      expect(
          remarkKindFor(_moved('sable', 1), record('sable'),
              const RemarkDeed(alignmentMod: 1, goldMod: 30)),
          RemarkKind.profitApproved);
      // Tobin: kindness +3, the gold -1. Kindness wins.
      expect(
          remarkKindFor(_moved('tobin', 2), record('tobin'),
              const RemarkDeed(alignmentMod: 1, goldMod: 30)),
          RemarkKind.kindApproved);
      expect(
          remarkKindFor(_moved('tobin', -1), record('tobin'),
              const RemarkDeed(goldMod: 30)),
          RemarkKind.profitDisapproved);
    });

    test("a scene's own reaction is plain approval or disapproval", () {
      expect(
          remarkKindFor(_moved('kelda', 1), record('kelda'),
              const RemarkDeed(approvalMods: {'*': 1})),
          RemarkKind.approved);
      expect(
          remarkKindFor(_moved('kelda', -2), record('kelda'),
              const RemarkDeed(approvalMods: {'kelda': -2})),
          RemarkKind.disapproved);
    });
  });

  group('who speaks, and when', () {
    test('whoever took the deed hardest', () {
      final picked = pickRemark(
        memory: const RemarkMemory(),
        activeAllyIds: const ['kelda', 'maren'],
        reactions: [_moved('kelda', 2), _moved('maren', 3)],
        deed: const RemarkDeed(alignmentMod: 1),
        companions: companions,
      );
      expect(picked.remarks.firstOrNull?.companionId, 'maren');
      expect(picked.remarks.firstOrNull?.kind, RemarkKind.kindApproved);
      expect(picked.memory.lastRemarkAt, 1);
    });

    test('on a tie, whoever spoke least recently', () {
      final picked = pickRemark(
        memory: const RemarkMemory(choices: 5, lastSpokeAt: {'kelda': 4}),
        activeAllyIds: const ['kelda', 'liora'],
        reactions: [_moved('kelda', 2), _moved('liora', 2)],
        deed: const RemarkDeed(alignmentMod: 1),
        companions: companions,
      );
      expect(picked.remarks.firstOrNull?.companionId, 'liora');
    });

    test('not one who said their piece already, nor one who walked out', () {
      // Maren just came to trust the player completely: she says so in the
      // approval notice. Sable walked out. Kelda only warmed to the player,
      // which has no words of its own.
      final picked = pickRemark(
        memory: const RemarkMemory(),
        activeAllyIds: const ['maren', 'kelda'],
        reactions: [
          _moved('maren', 3, before: 10),
          _moved('sable', -2),
          _moved('kelda', 2),
        ],
        deed: const RemarkDeed(alignmentMod: 1),
        companions: companions,
      );
      expect(picked.remarks.firstOrNull?.companionId, 'kelda');
    });

    test('a deed the party cares about is always remarked on', () {
      var memory = const RemarkMemory();
      for (var i = 0; i < 4; i++) {
        final picked = pickRemark(
          memory: memory,
          activeAllyIds: const ['maren'],
          reactions: [_moved('maren', 3)],
          deed: const RemarkDeed(alignmentMod: 1),
          companions: companions,
        );
        expect(picked.remarks, isNotEmpty, reason: 'choice ${i + 1}');
        memory = picked.memory;
      }
    });

    test('a check is remarked on at most once every few choices', () {
      var memory = const RemarkMemory();
      final spoken = <bool>[];
      for (var i = 0; i < 7; i++) {
        final picked = pickRemark(
          memory: memory,
          activeAllyIds: const ['kelda'],
          action: RemarkKind.checkPassed,
        );
        spoken.add(picked.remarks.isNotEmpty);
        memory = picked.memory;
      }
      expect(remarkCooldownChoices, 3);
      expect(spoken, [true, false, false, true, false, false, true]);
    });

    test('plain choices pass without a word, and count', () {
      final picked = pickRemark(
          memory: const RemarkMemory(), activeAllyIds: const ['kelda']);
      expect(picked.remarks, isEmpty);
      expect(picked.memory.choices, 1);
      expect(picked.memory.lastRemarkAt, isNull);
    });

    test('nobody to speak when the character walks alone', () {
      final picked = pickRemark(
        memory: const RemarkMemory(),
        activeAllyIds: const [],
        action: RemarkKind.checkFailed,
      );
      expect(picked.remarks, isEmpty);
    });

    test('companions take turns on checks', () {
      var memory = const RemarkMemory();
      final speakers = <String>[];
      for (var i = 0; i < 4; i++) {
        final picked = pickRemark(
          memory: RemarkMemory(
            seed: memory.seed,
            choices: memory.choices + remarkCooldownChoices,
            lastRemarkAt: memory.lastRemarkAt,
            lastSpokeAt: memory.lastSpokeAt,
            used: memory.used,
          ),
          activeAllyIds: const ['grosh', 'vess'],
          action: RemarkKind.checkFailed,
        );
        speakers.add(picked.remarks.first.companionId);
        memory = picked.memory;
      }
      expect(speakers, ['grosh', 'vess', 'grosh', 'vess']);
    });

    test('every line is used before one repeats', () {
      for (final seed in [0, 7, 12345]) {
        var memory = RemarkMemory(seed: seed);
        final lines = remarkLinesFor('maren', RemarkKind.kindApproved);
        final heard = <int>[];
        for (var i = 0; i < lines.length * 2; i++) {
          final picked = pickRemark(
            memory: memory,
            activeAllyIds: const ['maren'],
            reactions: [_moved('maren', 3)],
            deed: const RemarkDeed(alignmentMod: 1),
            companions: companions,
          );
          heard.add(picked.remarks.first.index);
          memory = picked.memory;
        }
        expect(heard.take(lines.length).toSet(), hasLength(lines.length),
            reason: 'seed $seed');
        expect(heard.skip(lines.length), heard.take(lines.length),
            reason: 'then the same round again');
      }
    });
  });

  group('an answer, when the party is split (v1.168)', () {
    test('the one who took it the other way answers', () {
      final picked = pickRemark(
        memory: const RemarkMemory(),
        activeAllyIds: const ['maren', 'malrik', 'kelda'],
        reactions: [
          _moved('maren', 3),
          _moved('malrik', -2),
          _moved('kelda', 2)
        ],
        deed: const RemarkDeed(alignmentMod: 1),
        companions: companions,
      );
      expect(picked.remarks.map((r) => r.companionId), ['maren', 'malrik']);
      expect(picked.remarks.map((r) => r.kind),
          [RemarkKind.kindApproved, RemarkKind.kindDisapproved]);
      expect(picked.memory.lastSpokeAt, {'maren': 1, 'malrik': 1});
    });

    test('nobody answers when everyone agrees', () {
      final picked = pickRemark(
        memory: const RemarkMemory(),
        activeAllyIds: const ['maren', 'kelda'],
        reactions: [_moved('maren', 3), _moved('kelda', 2)],
        deed: const RemarkDeed(alignmentMod: 1),
        companions: companions,
      );
      expect(picked.remarks, hasLength(1));
    });
  });

  group('lines written for a choice (v1.168)', () {
    test('a written line comes before a general one, answers included', () {
      final picked = pickRemark(
        memory: const RemarkMemory(),
        activeAllyIds: const ['kelda', 'sable'],
        reactions: [_moved('kelda', 2), _moved('sable', -1)],
        deed: const RemarkDeed(alignmentMod: 2, goldMod: -120),
        companions: companions,
        deedKeys: const ['refugees_aboard', '2900_boat_fixed#0'],
      );
      expect(picked.remarks.map((r) => r.companionId), ['kelda', 'sable']);
      expect(picked.remarks.map((r) => r.deedKey),
          ['refugees_aboard', 'refugees_aboard']);
      expect(picked.remarks.first.lineFor(french: false),
          deedRemarkFor('refugees_aboard', 'kelda', french: false));
      expect(picked.remarks.last.lineFor(french: true),
          deedRemarkFor('refugees_aboard', 'sable', french: true));
    });

    test('a companion with a written line speaks even if unmoved', () {
      final picked = pickRemark(
        memory: const RemarkMemory(),
        activeAllyIds: const ['grosh', 'maren'],
        deedKeys: const ['4999_standard#2'],
        companions: companions,
      );
      expect(picked.remarks.single.companionId, 'maren');
      expect(picked.remarks.single.deedKey, '4999_standard#2');
    });

    test('a choice is named by its flags, then by its place', () {
      expect(deedKeysFor('7200_elder_later', const ['a', 'b'], 'b', const []),
          ['7200_elder_later#1']);
      expect(deedKeysFor('2999', const ['a'], 'a', const ['skiff_cut']),
          ['skiff_cut', '2999#0']);
    });

    test('every written line names one real choice, in both languages', () {
      final raw = jsonDecode(
              File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>;
      int choicesNamed(String key) {
        if (key.contains('#')) {
          final node = raw[key.split('#').first] as Map<String, dynamic>?;
          final index = int.parse(key.split('#').last);
          return node != null && index < (node['choices'] as List).length
              ? 1
              : 0;
        }
        var n = 0;
        for (final node in raw.values) {
          for (final choice in (node as Map)['choices'] as List) {
            if (((choice as Map)['flagsToAdd'] as List? ?? const [])
                .contains(key)) {
              n++;
            }
          }
        }
        return n;
      }

      expect(deedRemarkKeys, hasLength(greaterThanOrEqualTo(20)));
      final tu = RegExp(r"(?<!\p{L})(?:(?:tu|toi|ton|ta|tes)(?!\p{L})|t['’])",
          caseSensitive: false, unicode: true);
      for (final key in deedRemarkKeys) {
        expect(choicesNamed(key), 1, reason: key);
        final en = deedRemarksOf(key, french: false);
        final fr = deedRemarksOf(key, french: true);
        expect(fr.keys.toSet(), en.keys.toSet(), reason: key);
        for (final id in en.keys) {
          expect(companions, contains(id), reason: '$key $id');
          expect(en[id]!.trim(), isNotEmpty);
          expect(tu.hasMatch(fr[id]!), isFalse, reason: fr[id]);
        }
      }
    });
  });

  test('a drink at the camp gets a word of thanks', () {
    for (final id in companions.keys) {
      expect(remarkLinesFor(id, RemarkKind.drink), hasLength(2), reason: id);
    }
    final picked = drinkRemark(const RemarkMemory(), 'grosh');
    expect(picked.remark?.kind, RemarkKind.drink);
    expect(picked.remark!.lineFor(french: false), isNotEmpty);
    expect(picked.memory.lastSpokeAt, contains('grosh'));
    expect(drinkRemark(const RemarkMemory(), 'nobody').remark, isNull);
  });

  test('the approval notice quotes the remark after its reaction', () {
    final lines = approvalReactionLines(
      [_moved('kelda', 2), _moved('maren', 3)],
      companions,
      (key) => key == 'approval_approves' ? '{name} approves.' : key,
      remarks: const [
        CompanionRemark(
            companionId: 'maren', kind: RemarkKind.kindApproved, index: 1),
      ],
    );
    expect(lines, [
      'Kelda approves.',
      'Sister Maren approves.',
      'Sister Maren: “${remarkLinesFor('maren', RemarkKind.kindApproved)[1]}”',
    ]);
  });
}
