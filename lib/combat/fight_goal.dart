import 'dart:math';

/// What a fight asks of the party besides "kill everything" (v1.212).
///
/// Most fights are still [FightGoalKind.slay]. About one in four eligible
/// fights (see [rollFightGoal]) asks for something else, and the setup
/// screen says so before the first die is rolled:
///
/// - [FightGoalKind.hold]: a pack presses the party; surviving
///   [FightGoal.rounds] of its turns wins, whoever still stands.
/// - [FightGoalKind.rout]: the pack's captain (its sturdiest member) is the
///   mark; when it falls the rest flee, as a Skittish enemy does.
/// - [FightGoalKind.subdue]: a lone fighter who can be broken; at
///   [yieldHealthShare] of its health it yields and pays a ransom, but a
///   blow that kills it outright leaves only the usual spoils.
///
/// Everything here is pure, like enemy_affix.dart.
enum FightGoalKind { slay, hold, rout, subdue }

/// Odds an eligible fight asks for something other than a slaughter.
const double fightGoalChance = 0.25;

/// The share of its health under which a [FightGoalKind.subdue] fighter
/// yields.
const double yieldHealthShare = 0.30;

/// The gold a yielded fighter pays, over its usual reward (it drops no
/// loot of its own: the ransom is the trade).
const double ransomGoldMultiplier = 1.5;

/// Every enemy hits this much harder in a [FightGoalKind.hold] fight: the
/// party need not kill them, so they press.
const double holdDamageMultiplier = 1.1;

/// The gold and XP multiplier a fight with [kind] pays on top of its
/// usual rewards -- the price of a harder ask than a plain slaughter.
double goalRewardMultiplier(FightGoalKind kind) => switch (kind) {
      FightGoalKind.slay => 1.0,
      FightGoalKind.hold => 1.35,
      FightGoalKind.rout => 1.1,
      FightGoalKind.subdue => 1.0,
    };

class FightGoal {
  const FightGoal(this.kind, {this.rounds = 0});

  /// The default: kill everything.
  static const FightGoal slay = FightGoal(FightGoalKind.slay);

  final FightGoalKind kind;

  /// For [FightGoalKind.hold]: the enemy turns the party must survive.
  final int rounds;

  bool get isSlay => kind == FightGoalKind.slay;

  @override
  bool operator ==(Object other) =>
      other is FightGoal && other.kind == kind && other.rounds == rounds;

  @override
  int get hashCode => Object.hash(kind, rounds);

  @override
  String toString() => 'FightGoal($kind, rounds: $rounds)';
}

/// The enemy turns a [FightGoalKind.hold] fight against [enemyCount]
/// enemies asks the party to survive: three against a pair, four against
/// three or more.
int holdRoundsFor(int enemyCount) => enemyCount >= 3 ? 4 : 3;

/// Rolls a fight's goal. [eligible] is the caller's verdict on the fight
/// itself (never a lesson, a test, a boss, a hunt or an ambush);
/// [enemyCount] is how many stand against the party and [canYield] whether
/// a lone enemy is the kind that can be broken (a person, not a beast).
FightGoal rollFightGoal({
  required bool eligible,
  required int enemyCount,
  required bool canYield,
  required Random random,
  double chance = fightGoalChance,
}) {
  if (!eligible || random.nextDouble() >= chance) return FightGoal.slay;
  if (enemyCount >= 2) {
    return random.nextBool()
        ? FightGoal(FightGoalKind.hold, rounds: holdRoundsFor(enemyCount))
        : const FightGoal(FightGoalKind.rout);
  }
  return canYield ? const FightGoal(FightGoalKind.subdue) : FightGoal.slay;
}

/// The goal named [name] ('hold', 'rout', 'subdue'; 'hold:5' sets the
/// rounds) -- what a hand-made fight carries -- or null for an unknown
/// name. A hold without rounds takes [holdRoundsFor] [enemyCount].
FightGoal? fightGoalFromName(String? name, {int enemyCount = 2}) {
  if (name == null || name.isEmpty) return null;
  final parts = name.split(':');
  switch (parts.first) {
    case 'slay':
      return FightGoal.slay;
    case 'hold':
      final rounds = parts.length > 1 ? int.tryParse(parts[1]) : null;
      return FightGoal(FightGoalKind.hold,
          rounds: max(1, rounds ?? holdRoundsFor(enemyCount)));
    case 'rout':
      return const FightGoal(FightGoalKind.rout);
    case 'subdue':
      return const FightGoal(FightGoalKind.subdue);
  }
  return null;
}

/// The index of a pack's captain: its sturdiest member (the first of equals).
int captainIndex(List<int> maxHealths) {
  var best = 0;
  for (var i = 1; i < maxHealths.length; i++) {
    if (maxHealths[i] > maxHealths[best]) best = i;
  }
  return best;
}

/// True once the party has lived through the enemy turns a hold asks for.
bool holdComplete(FightGoal goal, int enemyTurnsSurvived) =>
    goal.kind == FightGoalKind.hold && enemyTurnsSurvived >= goal.rounds;

/// True when a standing fighter at [currentHealth] of [maxHealth] breaks
/// and yields.
bool yieldsNow(int currentHealth, int maxHealth) =>
    currentHealth > 0 && currentHealth <= maxHealth * yieldHealthShare;

/// l10n key of the goal's name ("Hold the line").
String goalLabelKey(FightGoalKind kind) => switch (kind) {
      FightGoalKind.slay => 'goal_slay',
      FightGoalKind.hold => 'goal_hold',
      FightGoalKind.rout => 'goal_rout',
      FightGoalKind.subdue => 'goal_subdue',
    };

/// l10n key of the goal's one-line rules text; `{n}` is the hold's rounds.
String goalDescriptionKey(FightGoalKind kind) => '${goalLabelKey(kind)}_desc';

/// The factions whose fighters can be broken: people, not beasts, angels
/// or the Pit's things. A lone enemy of one of them may be [subdue]d.
const Set<String> yieldingFactions = {
  'dominion',
  'vigil',
  'compact',
  'mire',
  'crows',
  'penitents',
  'giants',
  'oni',
  'kindly',
};

/// True when an enemy of [factionId] is a person who can yield.
bool canYieldFaction(String? factionId) =>
    factionId != null && yieldingFactions.contains(factionId);
