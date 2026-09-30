// The camp's bounty board (v1.162): rolling a board, counting fights toward
// each contract, saving it, and paying it out at the board.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/contracts.dart';
import 'package:narrative_data_app/data/quest_objectives.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

import 'player_session_provider_test.dart' show baseSession;

Future<PlayerSessionNotifier> _notifierWith(PlayerSession session) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(session);
  return notifier;
}

Contract _contract(ContractKind kind,
        {int required = 2, int progress = 0, String target = ''}) =>
    Contract(
      id: 'c_${kind.name}',
      kind: kind,
      targetEnemyId: target,
      required: required,
      progress: progress,
      rewardGold: 80,
      rewardEssence: 200,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('rollContracts', () {
    test('three contracts of different kinds, a hunt first', () {
      for (var seed = 0; seed < 40; seed++) {
        final board = rollContracts(
          chapter: 2,
          huntPool: const ['harbor_rat', 'dock_thug'],
          random: Random(seed),
          boardNumber: 3,
        );
        expect(board, hasLength(3));
        expect(board.map((c) => c.kind).toSet(), hasLength(3));
        expect(board.first.kind, ContractKind.hunt);
        expect(
            ['harbor_rat', 'dock_thug'], contains(board.first.targetEnemyId));
        expect(board.map((c) => c.id), ['board3_0', 'board3_1', 'board3_2']);
        for (final c in board) {
          expect(c.progress, 0);
          expect(c.required, greaterThan(0));
          expect(c.rewardGold, contractGoldFor(2));
          expect(c.rewardEssence, contractEssenceFor(2));
          if (c.kind != ContractKind.hunt) expect(c.targetEnemyId, isEmpty);
        }
      }
    });

    test('no hunt without a foe to hunt', () {
      final board = rollContracts(
        chapter: 1,
        huntPool: const [],
        random: Random(7),
        boardNumber: 1,
      );
      expect(board, hasLength(3));
      expect(board.map((c) => c.kind), isNot(contains(ContractKind.hunt)));
    });

    test('pay rises with the chapter', () {
      expect(contractGoldFor(6), greaterThan(contractGoldFor(1)));
      expect(contractEssenceFor(6), greaterThan(contractEssenceFor(1)));
      expect(contractGoldFor(0), contractGoldFor(1));
    });
  });

  group('progressContract', () {
    const tally = ContractTally(
      defeatedEnemyIds: ['harbor_rat', 'harbor_rat', 'dock_thug'],
      pack: true,
      flawless: true,
      chargesBroken: 1,
      weaknessHits: 3,
      markedBeaten: 1,
    );

    test('each kind counts its own part of the fight', () {
      expect(
          progressContract(
                  _contract(ContractKind.hunt,
                      required: 4, target: 'harbor_rat'),
                  tally)
              .progress,
          2);
      expect(
          progressContract(_contract(ContractKind.packs), tally).progress, 1);
      expect(progressContract(_contract(ContractKind.flawless), tally).progress,
          1);
      expect(
          progressContract(_contract(ContractKind.breaker), tally).progress, 1);
      expect(
          progressContract(_contract(ContractKind.weakness, required: 4), tally)
              .progress,
          3);
      expect(
          progressContract(_contract(ContractKind.marked), tally).progress, 1);
    });

    test('a fight that did not help leaves the contract alone', () {
      const nothing = ContractTally(defeatedEnemyIds: ['dock_thug']);
      final hunt = _contract(ContractKind.hunt, target: 'harbor_rat');
      expect(identical(progressContract(hunt, nothing), hunt), isTrue);
      expect(
          progressContract(_contract(ContractKind.packs), nothing).progress, 0);
    });

    test('progress stops at the goal, and a met contract stays met', () {
      final almost = _contract(ContractKind.weakness, required: 4, progress: 3);
      final met = progressContract(almost, tally);
      expect(met.progress, 4);
      expect(met.done, isTrue);
      expect(progressContract(met, tally).progress, 4);
    });
  });

  test('a contract survives the save file', () {
    final contract = _contract(ContractKind.hunt,
        required: 3, progress: 1, target: 'harbor_rat');
    final back = Contract.fromJson(contract.toJson());
    expect(back.id, contract.id);
    expect(back.kind, ContractKind.hunt);
    expect(back.targetEnemyId, 'harbor_rat');
    expect(back.required, 3);
    expect(back.progress, 1);
    expect(back.rewardGold, 80);
    expect(back.rewardEssence, 200);
    expect(_contract(ContractKind.packs).toJson(),
        isNot(contains('targetEnemyId')));
  });

  test('a board needs posting when empty or when the chapter turns', () {
    final board = [_contract(ContractKind.packs)];
    expect(boardNeedsPosting(contracts: const [], postedChapter: 2, chapter: 2),
        isTrue);
    expect(boardNeedsPosting(contracts: board, postedChapter: 2, chapter: 2),
        isFalse);
    expect(boardNeedsPosting(contracts: board, postedChapter: 2, chapter: 3),
        isTrue);
  });

  test('a new chapter keeps the contracts already met, unclaimed', () {
    final earned =
        _contract(ContractKind.hunt, target: 'harbor_rat', progress: 3);
    final halfway = _contract(ContractKind.packs, progress: 1);
    final fresh = rollContracts(
      chapter: 4,
      huntPool: const ['harbor_rat'],
      random: Random(1),
      boardNumber: 9,
    );
    final board = repostBoard([earned, halfway], fresh);
    expect(board, hasLength(contractBoardSize));
    expect(board.first, same(earned), reason: 'earned, still to claim');
    expect(board, isNot(contains(halfway)), reason: 'unmet: the new board');
    expect(board.skip(1).map((c) => c.id), fresh.take(2).map((c) => c.id));
    // Nothing earned: a whole fresh board.
    expect(repostBoard([halfway], fresh), fresh);
  });

  test('PlayerSession keeps the board through toJson/fromJson', () {
    final session = baseSession().copyWith(
      contracts: [
        _contract(ContractKind.marked, progress: 1),
        _contract(ContractKind.hunt, target: 'harbor_rat'),
      ],
      contractsChapter: 4,
      contractBoards: 5,
    );
    final back = PlayerSession.fromJson(session.toJson());
    expect(back.contracts.map((c) => c.kind),
        [ContractKind.marked, ContractKind.hunt]);
    expect(back.contracts.first.progress, 1);
    expect(back.contracts.last.targetEnemyId, 'harbor_rat');
    expect(back.contractsChapter, 4);
    expect(back.contractBoards, 5);

    // A save from before the board opens with it empty.
    final old = session.toJson()
      ..remove('contracts')
      ..remove('contractsChapter')
      ..remove('contractBoards');
    final fromOld = PlayerSession.fromJson(old);
    expect(fromOld.contracts, isEmpty);
    expect(fromOld.contractBoards, 0);
  });

  group('the board at the camp', () {
    test('posting, progressing in a fight, and claiming', () async {
      final notifier = await _notifierWith(baseSession(gold: 10));
      await notifier.postContractBoard([
        _contract(ContractKind.packs, required: 1),
        _contract(ContractKind.hunt, required: 2, target: 'harbor_rat'),
      ], chapter: 2);
      expect(notifier.state.contracts, hasLength(2));
      expect(notifier.state.contractsChapter, 2);
      expect(notifier.state.contractBoards, 1);

      // Not met yet: nothing is paid.
      await notifier.claimContract('c_packs');
      expect(notifier.state.gold, 10);
      expect(notifier.state.contracts, hasLength(2));

      await notifier.applyCombatResult(
        hpAfter: 100,
        enemyIds: const ['harbor_rat', 'harbor_rat'],
        contractTally: const ContractTally(
          defeatedEnemyIds: ['harbor_rat', 'harbor_rat'],
          pack: true,
        ),
      );
      expect(notifier.state.contracts.every((c) => c.done), isTrue);

      final essenceBefore = notifier.state.skillEssence;
      await notifier.claimContract('c_packs');
      expect(notifier.state.gold, 90);
      expect(notifier.state.skillEssence, essenceBefore + 200);
      expect(notifier.state.contracts.map((c) => c.id), ['c_hunt']);

      // Claiming twice pays once.
      await notifier.claimContract('c_packs');
      expect(notifier.state.gold, 90);
    });

    test('a fight without a tally leaves the board as it was', () async {
      final notifier = await _notifierWith(baseSession());
      await notifier.postContractBoard(
          [_contract(ContractKind.packs, required: 1)],
          chapter: 1);
      await notifier
          .applyCombatResult(hpAfter: 100, enemyIds: const ['harbor_rat']);
      expect(notifier.state.contracts.single.progress, 0);
    });
  });

  group('bounty quests count from when they were taken', () {
    const bounty = {
      'objectives': [
        {
          'type': 'Kill',
          'targetEnemyID': 'bone_warden',
          'requiredAmount': 2,
          'countFromAccept': true,
        },
      ],
    };
    const lifetime = {
      'objectives': [
        {
          'type': 'Kill',
          'targetEnemyID': 'bone_warden',
          'requiredAmount': 2,
        },
      ],
    };

    test('kills made before accepting do not count toward a bounty', () async {
      final notifier = await _notifierWith(
          baseSession().copyWith(enemyKillCounts: {'bone_warden': 3}));
      await notifier.acceptQuest('q_bounty');
      await notifier.acceptQuest('q_lifetime');
      expect(notifier.state.questKillBaselines['q_bounty'], {'bone_warden': 3});

      var bountyStatus =
          objectiveStatusesFor('q_bounty', bounty, notifier.state).single;
      expect(bountyStatus.current, 0);
      expect(bountyStatus.met, isFalse);
      expect(allObjectivesMet('q_lifetime', lifetime, notifier.state), isTrue);

      await notifier.applyCombatResult(
          hpAfter: 100, enemyIds: const ['bone_warden', 'bone_warden']);
      bountyStatus =
          objectiveStatusesFor('q_bounty', bounty, notifier.state).single;
      expect(bountyStatus.current, 2);
      expect(bountyStatus.met, isTrue);
    });

    test('only a bounty keeps a baseline, only for its foes, until done',
        () async {
      final notifier = await _notifierWith(baseSession()
          .copyWith(enemyKillCounts: {'bone_warden': 3, 'harbor_rat': 40}));
      await notifier.acceptQuest('q_bounty', quest: bounty);
      await notifier.acceptQuest('q_lifetime', quest: lifetime);
      expect(notifier.state.questKillBaselines, {
        'q_bounty': {'bone_warden': 3},
      });
      await notifier.completeQuest('q_bounty');
      expect(notifier.state.questKillBaselines, isEmpty);
    });

    test('the baseline survives the save file', () {
      final session = baseSession().copyWith(questKillBaselines: {
        'q_bounty': {'bone_warden': 3},
      });
      expect(PlayerSession.fromJson(session.toJson()).questKillBaselines, {
        'q_bounty': {'bone_warden': 3}
      });
    });
  });

  group('the sea\'s contracts (v1.184)', () {
    test('once the Harbor stands, one contract is the sea\'s', () {
      for (var seed = 0; seed < 30; seed++) {
        final board = rollContracts(
          chapter: 4,
          huntPool: const ['harbor_rat'],
          random: Random(seed),
          boardNumber: seed,
          sea: true,
        );
        expect(board, hasLength(contractBoardSize));
        expect(board.where((c) => seaContractKinds.contains(c.kind)),
            hasLength(1));
        expect(board.first.kind, ContractKind.hunt);
        for (final c in board) {
          // A fight at sea comes along on every crossing: the sea's
          // contracts pay less than the land's, and take three ships.
          final sea = seaContractKinds.contains(c.kind);
          expect(
              c.rewardGold,
              sea
                  ? (contractGoldFor(4) * seaContractPay).round()
                  : contractGoldFor(4),
              reason: c.kind.name);
          if (c.kind == ContractKind.sinkShips) expect(c.required, 3);
        }
      }
      final land = rollContracts(
          chapter: 4,
          huntPool: const ['harbor_rat'],
          random: Random(1),
          boardNumber: 1);
      expect(land.where((c) => seaContractKinds.contains(c.kind)), isEmpty);
    });

    test('a won sea fight counts', () {
      const sink = Contract(
          id: 's',
          kind: ContractKind.sinkShips,
          required: 2,
          rewardGold: 1,
          rewardEssence: 1);
      const take = Contract(
          id: 't',
          kind: ContractKind.takeShip,
          required: 1,
          rewardGold: 1,
          rewardEssence: 1);
      const intact = Contract(
          id: 'i',
          kind: ContractKind.keelIntact,
          required: 1,
          rewardGold: 1,
          rewardEssence: 1);
      final sunk = ContractTally.sea(
          boarded: false, hullBefore: 100, hullAfter: 60, maxHull: 100);
      expect(progressContract(sink, sunk).progress, 1);
      expect(progressContract(take, sunk).progress, 0);
      expect(progressContract(intact, sunk).progress, 0,
          reason: 'lost more than a quarter');
      final taken = ContractTally.sea(
          boarded: true, hullBefore: 100, hullAfter: 80, maxHull: 100);
      expect(progressContract(take, taken).done, isTrue);
      expect(progressContract(intact, taken).done, isTrue);
    });
  });
}
