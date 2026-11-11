part of '../sim_combat.dart';

// An enemy of a simulated fight (simulateSimFight): its health, guard,
// statuses, phases and the round's tallies.

class _SimEnemy {
  _SimEnemy({
    required this.id,
    required this.data,
    required this.maxHealth,
    required this.damage,
  })  : health = maxHealth,
        phases = parseBossPhases(data);

  final String id;
  Map<String, dynamic> data;
  final int maxHealth;
  int damage;
  int health;
  List<StatusEffect> statusEffects = [];
  Set<String> elementsHit = {};

  /// Boss phases, highest threshold first (see [parseBossPhases]) and how
  /// many have been entered -- the fight screen's own bookkeeping.
  final List<BossPhase> phases;
  int phaseIndex = 0;

  bool get isAlive => health > 0;

  /// Its affixes (enemy_affix.dart), and whether it fled (a Skittish one).
  List<EnemyAffix> affixes = const [];
  bool fled = false;
  bool has(EnemyAffix affix) => affixes.contains(affix);

  /// A `healsOnce` boss (the claimants, fight_length.dart) that has mended
  /// itself once this fight; [skills] is the skill table its heal moves
  /// are read from.
  bool healSpent = false;
  Map<String, dynamic> skills = const {};
  bool get healBlocked => healSpent && healsOnce(data);

  /// Notes a heal of this enemy: a `healsOnce` boss spends its one heal,
  /// and its heal moves leave its list.
  void noteHeal() {
    if (!healsOnce(data)) return;
    healSpent = true;
    data = withoutHealMoves(data, skills);
  }

  /// v1.215 squad role and answer, v1.212 captain mark, and the pack this
  /// enemy fights in (for a guard's cover and a reaction's spread).
  SquadRole? role;
  EnemyResponse response = EnemyResponse.none;
  bool provoked = false;
  bool pressing = false;
  bool isCaptain = false;
  List<_SimEnemy> pack = const [];

  /// v1.214 reaction marks (element -> round struck) and a parry waiting.
  final Map<String, int> marks = {};
  int parryBlock = 0;

  /// The move rolled ahead (telegraphed), kept for the enemy's turn.
  EnemyMoveResult? planned;

  /// v1.162 intents, as the fight screen keeps them: a raised guard, a
  /// held wind-up, a broken one, and how many rallies raised the damage.
  int guard = 0;
  EnemyMoveResult? charged;
  bool staggered = false;
  int rallies = 0;
  int damageThisRound = 0;
  int topHit = 0;
  bool hitWeakness = false;

  /// A party hit of [damage] and [element]: weakness or resistance, then
  /// the guard. Returns what gets through and tallies it towards breaking
  /// a wind-up.
  int takeHit(int damage, String element, {bool pierce = false}) {
    if (damage <= 0) return damage;
    if (elementMultiplierFor(data, element) > 1.0) hitWeakness = true;
    final elemental = damageAfterElement(damage, data, element);
    // A Pierce strike goes through the raised guard.
    final through = pierce
        ? (damage: elemental, guard: guard)
        : damageThroughGuard(elemental, guard);
    guard = through.guard;
    damageThisRound += through.damage;
    topHit = max(topHit, through.damage);
    return through.damage;
  }

  /// A party blow with the v1.214/215 rules on: [takeHit], a standing
  /// guard's cover, the health it costs, the hardest hit this round and an
  /// element reaction. Returns the damage dealt, a reaction's bonus
  /// included.
  int landHit(
    int damage,
    String element,
    int round, {
    bool pierce = false,
    bool react = true,
    int reactionTimes = 1,
  }) {
    var landed = takeHit(damage, element, pierce: pierce);
    if (landed > 0 &&
        !pierce &&
        role != SquadRole.guard &&
        pack.any(
          (o) => !identical(o, this) && o.isAlive && o.role == SquadRole.guard,
        )) {
      final cut = (landed * guardCoverShare).round();
      landed -= cut;
      damageThisRound -= cut;
    }
    health = max(0, health - landed);
    var dealt = landed;
    if (react && element != 'None' && landed > 0 && isAlive) {
      final sprung = reactionOn(marks, element, round);
      if (sprung == null) {
        marks[element] = round;
      } else {
        marks.remove(sprung.primer);
        final reaction = sprung.reaction;
        final bonus = reactionBonus(reaction, landed) * reactionTimes;
        if (bonus > 0) {
          health = max(0, health - bonus);
          dealt += bonus;
        }
        switch (reaction) {
          case ElementReaction.shatter:
            guard = 0;
          case ElementReaction.freeze:
            if (!isBossEnemy(id, data) && phases.isEmpty) {
              statusEffects = applyStatusEffect(
                statusEffects,
                const StatusEffect(
                  type: StatusEffectType.stun,
                  remainingTurns: 1,
                ),
              );
            }
          case ElementReaction.sandblast:
            statusEffects = applyStatusEffect(
              statusEffects,
              const StatusEffect(
                type: StatusEffectType.weaken,
                remainingTurns: weakenTurns,
                magnitude: sandblastWeakenPercent,
              ),
            );
          case ElementReaction.conduct:
          case ElementReaction.firestorm:
          case ElementReaction.eclipse:
            break;
        }
        final spread = reactionSpreadShare(reaction);
        if (spread > 0) {
          for (final other in pack) {
            if (identical(other, this) || !other.isAlive) continue;
            other.health = max(
              0,
              other.health - max(1, (landed * spread).round()),
            );
          }
        }
      }
    }
    return dealt;
  }

  /// Plays every phase crossed since the last check; returns how many.
  int advancePhases() {
    if (phases.isEmpty || !isAlive) return 0;
    final target = bossPhaseIndexFor(phases, health, maxHealth);
    var entered = 0;
    while (phaseIndex < target) {
      final phase = phases[phaseIndex];
      phaseIndex++;
      entered++;
      final before = health;
      if (!healBlocked) health = healthAfterPhaseHeal(phase, health, maxHealth);
      if (phase.cleanse) statusEffects = [];
      damage = (damage * phase.damageMultiplier).round();
      data = enemyDataInPhase(data, phase);
      if (health > before || healBlocked) noteHeal();
    }
    return entered;
  }
}
