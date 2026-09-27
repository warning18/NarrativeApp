// Companion approval (v1.162): the pure rules, the party's reaction to a
// choice, walking out, the drink at the camp, the save file and the data.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/approval.dart';
import 'package:narrative_data_app/models/ally_state.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/approval_notice.dart';

import 'player_session_provider_test.dart' show baseSession;

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

Future<PlayerSessionNotifier> _notifierWith(PlayerSession session) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(session);
  return notifier;
}

AllyState _ally(String id, {int approval = startingApproval}) => AllyState(
    companionId: id,
    currentHealth: AllyState.fullHealthSentinel,
    approval: approval);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final companions = _companions();

  group('the rules', () {
    test('tiers', () {
      expect(approvalTierFor(20), ApprovalTier.devoted);
      expect(approvalTierFor(devotedApproval), ApprovalTier.devoted);
      expect(approvalTierFor(friendlyApproval), ApprovalTier.friendly);
      expect(approvalTierFor(startingApproval), ApprovalTier.neutral);
      expect(approvalTierFor(waryApproval), ApprovalTier.wary);
      expect(approvalTierFor(leavingApproval), ApprovalTier.estranged);
    });

    test('a companion weighs a deed by what they value', () {
      final maren = companions['maren'] as Map<String, dynamic>;
      final malrik = companions['malrik'] as Map<String, dynamic>;
      expect(approvalDeltaFor(maren, alignmentMod: 2), 3);
      expect(approvalDeltaFor(maren, alignmentMod: -1), -3);
      // A big deed counts double.
      expect(approvalDeltaFor(maren, alignmentMod: -5), -6);
      expect(approvalDeltaFor(malrik, goldMod: 40), 3);
      expect(approvalDeltaFor(malrik, alignmentMod: 2, goldMod: 40), 1);
      expect(approvalDeltaFor(malrik, goldMod: -20), 0,
          reason: 'spending is not profit');
      expect(approvalDeltaFor(null, alignmentMod: 5, explicit: -4), -4);
    });

    test('approval stays within its bounds', () {
      expect(approvalAfter(19, 5), maxApproval);
      expect(approvalAfter(-19, -5), minApproval);
    });

    test('a scene names a companion, or everyone', () {
      expect(explicitApprovalFor({'maren': 2, '*': -1}, 'maren'), 2);
      expect(explicitApprovalFor({'maren': 2, '*': -1}, 'grosh'), -1);
      expect(explicitApprovalFor(const {}, 'grosh'), 0);
    });

    test('fights: devoted hit harder, wary hold back', () {
      expect(approvalDamagePercent(ApprovalTier.devoted), 110);
      expect(approvalHealthPercent(ApprovalTier.devoted), 110);
      expect(approvalDamagePercent(ApprovalTier.neutral), 100);
      expect(approvalDamagePercent(ApprovalTier.wary), 90);
    });
  });

  group('the party reacts', () {
    test('only the party sees it, and each by their own values', () async {
      final notifier = await _notifierWith(baseSession(recruitedAllies: [
        _ally('maren'),
        _ally('malrik'),
        _ally('kelda'),
      ], activeAllyIds: const [
        'maren',
        'malrik'
      ]));
      final reactions = await notifier.applyChoiceEffects(
          alignmentMod: -2, goldMod: 30, companions: companions);
      final byId = {for (final r in reactions) r.companionId: r};
      expect(byId.keys, unorderedEquals(['maren', 'malrik']));
      // Maren: cruelty -3, profit -1.
      expect(byId['maren']!.delta, -4);
      // Malrik: cruelty +2, profit +3.
      expect(byId['malrik']!.delta, 5);
      final allies = {
        for (final a in notifier.state.recruitedAllies) a.companionId: a
      };
      expect(allies['maren']!.approval, startingApproval - 4);
      expect(allies['kelda']!.approval, startingApproval,
          reason: 'benched: not there to see it');
    });

    test('a choice with no deed in it moves nobody', () async {
      final notifier = await _notifierWith(baseSession(
          recruitedAllies: [_ally('maren')], activeAllyIds: const ['maren']));
      final reactions = await notifier
          .applyChoiceEffects(flagsToAdd: const ['x'], companions: companions);
      expect(reactions, isEmpty);
    });

    test('pushed too far, a companion walks out for good', () async {
      final notifier = await _notifierWith(baseSession(recruitedAllies: [
        _ally('tobin', approval: -8),
        _ally('grosh'),
      ], activeAllyIds: const [
        'tobin',
        'grosh'
      ]));
      final reactions = await notifier.applyChoiceEffects(
          alignmentMod: -5, companions: companions);
      final tobin = reactions.singleWhere((r) => r.companionId == 'tobin');
      expect(tobin.leaves, isTrue);
      final state = notifier.state;
      expect(state.recruitedAllies.map((a) => a.companionId), ['grosh']);
      expect(state.activeAllyIds, ['grosh']);
      expect(state.departedAllyIds, ['tobin']);
      expect(state.lostAllyIds, isEmpty,
          reason: 'the story\'s {lost} lines are for companions it took');
    });

    test('a quest outcome can name its own reactions', () async {
      final notifier = await _notifierWith(baseSession(
          recruitedAllies: [_ally('sable')], activeAllyIds: const ['sable']));
      final reactions = await notifier.reactToDeed(
          companions: companions, approvalMods: const {'sable': 3});
      expect(reactions.single.delta, 3);
    });

    test('the lines tell the player, with the companion\'s own words', () {
      final lines = approvalReactionLines(
        const [
          ApprovalChange(companionId: 'maren', before: 10, after: 13),
          ApprovalChange(companionId: 'grosh', before: -3, after: -6),
          ApprovalChange(companionId: 'malrik', before: -10, after: -14),
        ],
        companions,
        (key) => key,
      );
      expect(lines.first, 'approval_approves');
      expect(lines, contains(contains('I stopped counting my penance')));
      expect(lines, contains(contains("I don't work for promises")));
      expect(lines, contains(contains('Nothing profitable, either')));
      expect(lines, contains('approval_leaves_notice'));
    });
  });

  group('a drink at the camp', () {
    test('costs gold, warms them up, once a chapter', () async {
      final notifier = await _notifierWith(baseSession(
          gold: 500,
          recruitedAllies: [_ally('kelda')],
          activeAllyIds: const ['kelda']));
      expect(await notifier.shareDrink('kelda', chapter: 3), isTrue);
      expect(notifier.state.gold, 500 - giftCostFor(3));
      final kelda = notifier.state.recruitedAllies.single;
      expect(kelda.approval, startingApproval + giftApproval);
      expect(kelda.giftChapter, 3);
      expect(await notifier.shareDrink('kelda', chapter: 3), isFalse);
      expect(await notifier.shareDrink('kelda', chapter: 4), isTrue);
    });

    test('not without the gold', () async {
      final notifier = await _notifierWith(baseSession(
          gold: 10,
          recruitedAllies: [_ally('kelda')],
          activeAllyIds: const ['kelda']));
      expect(await notifier.shareDrink('kelda', chapter: 3), isFalse);
      expect(notifier.state.gold, 10);
    });
  });

  test('approval survives the save file; an old ally starts where new do', () {
    final ally = _ally('vess', approval: -7).copyWith(giftChapter: 4);
    final back = AllyState.fromJson(ally.toJson());
    expect(back.approval, -7);
    expect(back.giftChapter, 4);
    final old = ally.toJson()
      ..remove('approval')
      ..remove('giftChapter');
    expect(AllyState.fromJson(old).approval, startingApproval);

    final session = baseSession().copyWith(departedAllyIds: ['tobin']);
    expect(PlayerSession.fromJson(session.toJson()).departedAllyIds, ['tobin']);
  });

  test('a story choice carries its reactions', () {
    final choice = StoryChoice.fromJson({
      'text': 'Give it one of the crew',
      'next_id': 'x',
      'approvalMods': {'*': -4},
    });
    expect(choice.approvalMods, {'*': -4});
    expect(choice.hasEffects, isTrue);
    expect(StoryChoice.fromJson(choice.toJson()).approvalMods, {'*': -4});
  });

  test('every companion has values and words in both languages', () {
    for (final entry in companions.entries) {
      final c = entry.value as Map<String, dynamic>;
      for (final field in ['approvesGood', 'approvesEvil', 'approvesProfit']) {
        final w = (c[field] as num?)?.toInt();
        expect(w, isNotNull, reason: '${entry.key}.$field');
        expect(w!.abs(), lessThanOrEqualTo(3), reason: '${entry.key}.$field');
      }
      for (final field in ['devotedLine', 'warnLine', 'leaveLine']) {
        expect(c[field]?.toString() ?? '', isNotEmpty,
            reason: '${entry.key}.$field');
        expect(c['${field}Fr']?.toString() ?? '', isNotEmpty,
            reason: '${entry.key}.${field}Fr');
      }
    }
  });
}
