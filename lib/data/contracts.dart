import 'dart:math';

/// The camp's bounty board (v1.162): three contracts posted at a time, each
/// a short goal met in ordinary fights, paid in gold and skill essence at
/// the board. A fresh board goes up once all three are claimed or the
/// chapter turns, so there's always a next thing to aim a fight at.
enum ContractKind {
  /// Put down so many of one common foe.
  hunt,

  /// Win so many fights against a pack.
  packs,

  /// Win so many fights with nobody knocked out and no potion drunk.
  flawless,

  /// Break so many wind-ups (see EnemyIntent.charge).
  breaker,

  /// Hit a weakness so many times.
  weakness,

  /// Beat so many marked foes: an affix or an Elite.
  marked,
}

class Contract {
  const Contract({
    required this.id,
    required this.kind,
    required this.required,
    required this.rewardGold,
    required this.rewardEssence,
    this.targetEnemyId = '',
    this.progress = 0,
  });

  factory Contract.fromJson(Map<String, dynamic> json) => Contract(
        id: json['id']?.toString() ?? '',
        kind: ContractKind.values.firstWhere(
            (k) => k.name == json['kind']?.toString(),
            orElse: () => ContractKind.packs),
        targetEnemyId: json['targetEnemyId']?.toString() ?? '',
        required: (json['required'] as num?)?.toInt() ?? 1,
        progress: (json['progress'] as num?)?.toInt() ?? 0,
        rewardGold: (json['rewardGold'] as num?)?.toInt() ?? 0,
        rewardEssence: (json['rewardEssence'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final ContractKind kind;

  /// The foe a [ContractKind.hunt] is for ('' otherwise).
  final String targetEnemyId;
  final int required;
  final int progress;
  final int rewardGold;
  final int rewardEssence;

  bool get done => progress >= required;

  Contract withProgress(int value) => Contract(
        id: id,
        kind: kind,
        targetEnemyId: targetEnemyId,
        required: required,
        progress: min(required, value),
        rewardGold: rewardGold,
        rewardEssence: rewardEssence,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        if (targetEnemyId.isNotEmpty) 'targetEnemyId': targetEnemyId,
        'required': required,
        'progress': progress,
        'rewardGold': rewardGold,
        'rewardEssence': rewardEssence,
      };
}

/// What one won fight did, as far as the board is concerned.
class ContractTally {
  const ContractTally({
    this.defeatedEnemyIds = const [],
    this.pack = false,
    this.flawless = false,
    this.chargesBroken = 0,
    this.weaknessHits = 0,
    this.markedBeaten = 0,
  });

  final List<String> defeatedEnemyIds;
  final bool pack;
  final bool flawless;
  final int chargesBroken;
  final int weaknessHits;
  final int markedBeaten;
}

/// [contract] after a won fight [tally].
Contract progressContract(Contract contract, ContractTally tally) {
  if (contract.done) return contract;
  final gained = switch (contract.kind) {
    ContractKind.hunt =>
      tally.defeatedEnemyIds.where((id) => id == contract.targetEnemyId).length,
    ContractKind.packs => tally.pack ? 1 : 0,
    ContractKind.flawless => tally.flawless ? 1 : 0,
    ContractKind.breaker => tally.chargesBroken,
    ContractKind.weakness => tally.weaknessHits,
    ContractKind.marked => tally.markedBeaten,
  };
  return gained == 0
      ? contract
      : contract.withProgress(contract.progress + gained);
}

/// A contract's gold at [chapter].
int contractGoldFor(int chapter) => 30 + 25 * max(1, chapter);

/// A contract's skill essence at [chapter].
int contractEssenceFor(int chapter) => 100 * max(1, chapter);

/// A fresh board of three contracts of different kinds at [chapter]. A hunt
/// needs a common foe from [huntPool] (the chapter's pack-eligible random
/// draws); without one, another kind takes its place. [boardNumber] keeps
/// the ids unique across boards.
List<Contract> rollContracts({
  required int chapter,
  required List<String> huntPool,
  required Random random,
  required int boardNumber,
}) {
  final kinds = [
    if (huntPool.isNotEmpty) ContractKind.hunt,
    ContractKind.packs,
    ContractKind.flawless,
    ContractKind.breaker,
    ContractKind.weakness,
    ContractKind.marked,
  ]..shuffle(random);
  // A hunt is the board's staple: always on it when there's a foe to hunt.
  if (kinds.contains(ContractKind.hunt)) {
    kinds
      ..remove(ContractKind.hunt)
      ..insert(0, ContractKind.hunt);
  }
  final gold = contractGoldFor(chapter);
  final essence = contractEssenceFor(chapter);
  return [
    for (final (i, kind) in kinds.take(3).indexed)
      Contract(
        id: 'board${boardNumber}_$i',
        kind: kind,
        targetEnemyId: kind == ContractKind.hunt
            ? huntPool[random.nextInt(huntPool.length)]
            : '',
        required: switch (kind) {
          ContractKind.hunt => 2 + random.nextInt(3),
          ContractKind.packs => 2,
          ContractKind.flawless => 2,
          ContractKind.breaker => 2,
          ContractKind.weakness => 4,
          ContractKind.marked => 1 + random.nextInt(2),
        },
        rewardGold: gold,
        rewardEssence: essence,
      ),
  ];
}

/// Whether the board at the camp needs a fresh notice: nothing posted,
/// everything claimed, or a new chapter since it went up.
bool boardNeedsPosting({
  required List<Contract> contracts,
  required int postedChapter,
  required int chapter,
}) =>
    contracts.isEmpty || postedChapter != chapter;
