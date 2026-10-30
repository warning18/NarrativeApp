// The companions of the simulator's competent player (sim_policy.dart): who
// it recruits, who it seats in the party, how they fight and how they feel
// about the run's choices, played by the game's own rules:
// - recruiting: a companion joins when their quest (quests.json
//   `rewardAllyId`) is handed in, never twice and never after leaving or
//   being taken (PlayerSessionNotifier.recruitAlly); the quests' own gates
//   (alignment, flags, gold) are the quest log's;
// - the party: `partyCapacityFor` seats (two companions, never more: three
//   fighters, v1.664), the Barracks Annex's reserve seat (`reserveSeatsFor`,
//   the next best waits there and steps in once a fight for one knocked
//   out), and a companion with a `requiredHouseId` only once that house
//   stands (Kelda and Kelda's Hall);
// - approval (approval.dart): every choice's alignment and gold and its
//   `approvalMods` move the seated companions' approval by their weights; at
//   [leavingApproval] they walk out, and the benched companion who thinks
//   best of the player steps in (PlayerSessionNotifier._removeAlly); a
//   choice's `loseAllyId` takes one for good;
// - the fight (sim_combat.dart's `allies`): each rolls their signature die
//   at the player's level, their approval tier's damage and health, and is
//   knocked out at 0 health; a knocked-out companion is back at 30% after a
//   won fight, and a rest or a level-up heals everyone.
//
// The pick rule (what the competent player decides): the seats go to the
// companions worth most in a fight ([_simCompanionValue]: their die's
// average roll at their damage, plus their health and armor as survival);
// a companion within one point of the best left is a tie, settled toward
// the higher approval, then the one whose weights fit the player's
// alignment, then the earlier recruit. A better companion joining a full
// party takes the weakest seat (a swap).
import 'dart:math';

import '../combat/combat_engine.dart' show scaledDamage, scaledMaxHealth;
import '../combat/fight_numbers.dart' show reviveHealthFraction;
import '../combat/dice_faces.dart' show dieSignatureSkillIds;
import '../combat/status_effect.dart';
import '../models/ally_state.dart' show deriveAllyBaseStats;
import '../providers/player_session_provider.dart'
    show companionStarterSkillIds, partyCapacityFor, reserveSeatsFor;
import 'approval.dart';
import 'perks.dart';
import 'signs.dart';
import 'sim_policy.dart' show simDieValue;
import 'story_companions.dart';

/// A knocked-out companion is back at this share of their health after a
/// won fight (fight_numbers.dart).
const double simReviveHealthFraction = reviveHealthFraction;

/// One thing the party went through: [kind] is `recruit`, `pick` (seated),
/// `bench`, `swap` ([companionId] seated for [other]), `leave` (walked out
/// over their approval), `lost` (the story took them), `devoted` or `wary`
/// (their approval crossed into that tier); [reason], why.
class SimCompanionEvent {
  const SimCompanionEvent({
    required this.chapter,
    required this.kind,
    required this.companionId,
    required this.reason,
    this.other = '',
  });

  final int chapter;
  final String kind;
  final String companionId;
  final String other;
  final String reason;

  /// The report's line.
  String get line => kind == 'swap'
      ? 'Ch$chapter swap: $companionId in, $other out ($reason)'
      : 'Ch$chapter $kind: $companionId ($reason)';
}

/// A recruited companion between fights: their approval and health
/// (null: full, AllyState.fullHealthSentinel's meaning).
class SimCompanionState {
  SimCompanionState(this.id, {this.approval = startingApproval});

  final String id;
  int approval;
  int? health;
}

/// A companion in one fight (sim_combat.dart): their stats as the fight
/// screen builds them (`_ensurePartyBuilt`), their signature die and the
/// skills its faces cast. The fight mutates [currentHealth], [block] and
/// [statusEffects] and counts what the die did.
class SimAlly {
  SimAlly({
    required this.id,
    required this.professionId,
    required this.maxHealth,
    required this.currentHealth,
    required this.damage,
    required this.armor,
    required this.dexterity,
    required this.luck,
    required this.wisdom,
    required this.perception,
    required this.faces,
    required this.skills,
  });

  final String id;
  final String professionId;
  final int maxHealth;
  int currentHealth;
  final int damage;
  final int armor;
  final int dexterity;
  final int luck;
  final int wisdom;
  final int perception;
  final List<Map<String, dynamic>> faces;

  /// The skills their faces may cast: their unlocked ones and the die's.
  final Map<String, dynamic> skills;

  List<StatusEffect> statusEffects = [];
  int block = 0;
  bool stunned = false;

  /// Heals given this fight (each tires: fight_length.dart).
  int healsGiven = 0;

  /// What the die did: faces played by type, the skills its Skill faces
  /// cast, the damage that landed.
  final Map<String, int> facesPlayed = {};
  final Map<String, int> skillsCast = {};
  int damageDealt = 0;

  bool get isKnockedOut => currentHealth <= 0;
}

/// What [companion] (a companions.json record) is worth in a fight at the
/// player's [level] and their [approval], in the units of simDieValue: the
/// signature die's average roll at their damage, plus a tenth of their
/// health and most of their armor (what keeps them standing).
double _simCompanionValue(
  Map<String, dynamic> companion, {
  required int level,
  required int approval,
  required Map<String, dynamic> races,
  required Map<String, dynamic> professions,
  required Map<String, dynamic> gameConfig,
  required Map<String, dynamic> dice,
  required Map<String, dynamic> skills,
}) {
  final stats = _allyStats(companion,
      level: level,
      approval: approval,
      races: races,
      professions: professions,
      gameConfig: gameConfig);
  final faces = _facesOf(dice, companion);
  return simDieValue(faces, const {}, skills, damage: stats.damage) +
      stats.maxHealth * 0.1 +
      stats.armor * 0.8;
}

List<Map<String, dynamic>> _facesOf(
        Map<String, dynamic> dice, Map<String, dynamic>? companion) =>
    ((dice[companion?['signatureDiceId']?.toString() ?? '']
            as Map<String, dynamic>?)?['faces'] as List?)
        ?.cast<Map<String, dynamic>>() ??
    const [];

({int maxHealth, int damage, int armor}) _allyStats(
  Map<String, dynamic> companion, {
  required int level,
  required int approval,
  required Map<String, dynamic> races,
  required Map<String, dynamic> professions,
  required Map<String, dynamic> gameConfig,
}) {
  final base = deriveAllyBaseStats(
    gameConfig: gameConfig,
    race:
        races[companion['raceId']?.toString() ?? ''] as Map<String, dynamic>? ??
            const {},
    profession: professions[companion['professionId']?.toString() ?? '']
            as Map<String, dynamic>? ??
        const {},
  );
  final tier = approvalTierFor(approval);
  return (
    maxHealth: scaledMaxHealth(base.maxHealth, level) *
        approvalHealthPercent(tier) ~/
        100,
    damage: scaledDamage(base.baseDamage, level) *
        approvalDamagePercent(tier) ~/
        100,
    armor: base.baseArmor,
  );
}

/// The competent player's companions over a run: the roster, the seats,
/// approval, health between fights, and the [log] of every recruit, pick,
/// swap and loss with its reason.
class SimParty {
  SimParty({
    required this.companions,
    required this.races,
    required this.professions,
    required this.gameConfig,
    required this.dice,
    required this.skills,
    this.houses = const {},
  });

  final Map<String, dynamic> companions;
  final Map<String, dynamic> races;
  final Map<String, dynamic> professions;
  final Map<String, dynamic> gameConfig;
  final Map<String, dynamic> dice;
  final Map<String, dynamic> skills;
  final Map<String, dynamic> houses;

  /// Recruited companions, in the order they joined.
  final Map<String, SimCompanionState> roster = {};

  /// The seated ones (the fight party), in seat order.
  final List<String> active = [];

  /// The one in the reserve seat (the Barracks Annex), null with none: the
  /// next best after the seated ones (the pick rule).
  String? reserve;
  final Set<String> departed = {};
  final Set<String> lost = {};
  final List<SimCompanionEvent> log = [];

  /// The camp's houses standing (for the seats and Kelda's Hall).
  Set<String> builtHouses = {};

  /// Knock-outs per companion over the run.
  final Map<String, int> knockouts = {};

  /// Signature-die skills cast per companion over the run.
  final Map<String, Map<String, int>> skillsCast = {};

  int _level = 1;

  /// Companion seats: partyCapacityFor (two, plus each built house's bonus).
  int get capacity => partyCapacityFor(builtHouses.toList(), houses);

  /// Reserve seats: reserveSeatsFor (one once the Barracks Annex stands).
  int get reserveSeats => reserveSeatsFor(builtHouses.toList(), houses);

  Map<String, dynamic>? _record(String id) =>
      companions[id] as Map<String, dynamic>?;

  bool houseBuiltFor(String id) {
    final house = _record(id)?['requiredHouseId']?.toString() ?? '';
    return house.isEmpty || builtHouses.contains(house);
  }

  double valueOf(String id, {int? level}) {
    final record = _record(id);
    if (record == null) return 0;
    return _simCompanionValue(record,
        level: level ?? _level,
        approval: roster[id]?.approval ?? startingApproval,
        races: races,
        professions: professions,
        gameConfig: gameConfig,
        dice: dice,
        skills: skills);
  }

  /// How well [id]'s weights fit the player's [alignment]: their
  /// approvesGood for a good one, approvesEvil for an evil one,
  /// approvesProfit at zero.
  int fitOf(String id, int alignment) {
    final field = alignment > 0
        ? 'approvesGood'
        : alignment < 0
            ? 'approvesEvil'
            : 'approvesProfit';
    return (_record(id)?[field] as num?)?.toInt() ?? 0;
  }

  /// [companionId]'s quest is handed in: they join (recruitAlly's rules)
  /// and sit in a free seat when their house stands; then the competent
  /// player seats the best party. False when they cannot join.
  bool recruit(String companionId,
      {required int chapter, required String cause, int alignment = 0}) {
    if (_record(companionId) == null ||
        roster.containsKey(companionId) ||
        lost.contains(companionId) ||
        departed.contains(companionId)) {
      return false;
    }
    roster[companionId] = SimCompanionState(companionId);
    log.add(SimCompanionEvent(
        chapter: chapter,
        kind: 'recruit',
        companionId: companionId,
        reason: cause));
    if (houseBuiltFor(companionId) && active.length < capacity) {
      active.add(companionId);
      log.add(SimCompanionEvent(
          chapter: chapter,
          kind: 'pick',
          companionId: companionId,
          reason: 'a free seat'));
    }
    arrange(chapter: chapter, alignment: alignment);
    return true;
  }

  /// The pick rule (see the file's head): the seats go to the companions
  /// worth most, a tie within one point to the higher approval, then the
  /// better fit to [alignment], then the earlier recruit. Logs each seat
  /// that changes.
  void arrange({required int chapter, int alignment = 0}) {
    final order = roster.keys.toList();
    final left = [
      for (final id in order)
        if (houseBuiltFor(id)) id,
    ];
    final values = {for (final id in left) id: valueOf(id)};
    final want = <String>[];
    final why = <String, String>{};
    // The seats, then the reserve seat, by the same rule.
    while (want.length < capacity + reserveSeats && left.isNotEmpty) {
      final top = left.map((id) => values[id]!).reduce(max);
      final tied = [
        for (final id in left)
          if (values[id]! >= top - 1) id,
      ];
      tied.sort((a, b) {
        final byApproval = roster[b]!.approval.compareTo(roster[a]!.approval);
        if (byApproval != 0) return byApproval;
        final byFit = fitOf(b, alignment).compareTo(fitOf(a, alignment));
        if (byFit != 0) return byFit;
        return order.indexOf(a).compareTo(order.indexOf(b));
      });
      final pick = tied.first;
      why[pick] = tied.length > 1
          ? 'tie within 1 of ${top.toStringAsFixed(1)}: approval '
              '${roster[pick]!.approval}, fit ${fitOf(pick, alignment)}'
          : 'most to the fight, ${values[pick]!.toStringAsFixed(1)}';
      want.add(pick);
      left.remove(pick);
    }
    final standby = want.length > capacity ? want.removeLast() : null;
    if (standby != reserve) {
      reserve = standby;
      if (standby != null) {
        log.add(SimCompanionEvent(
            chapter: chapter,
            kind: 'reserve',
            companionId: standby,
            reason: why[standby]!));
      }
    }
    final seated = [
      for (final id in want)
        if (!active.contains(id)) id,
    ];
    final benched = [
      for (final id in active)
        if (!want.contains(id)) id,
    ];
    for (var i = 0; i < max(seated.length, benched.length); i++) {
      if (i < seated.length && i < benched.length) {
        log.add(SimCompanionEvent(
            chapter: chapter,
            kind: 'swap',
            companionId: seated[i],
            other: benched[i],
            reason: '${valueOf(seated[i]).toStringAsFixed(1)} over '
                '${valueOf(benched[i]).toStringAsFixed(1)}; ${why[seated[i]]}'));
      } else if (i < seated.length) {
        log.add(SimCompanionEvent(
            chapter: chapter,
            kind: 'pick',
            companionId: seated[i],
            reason: why[seated[i]]!));
      } else {
        log.add(SimCompanionEvent(
            chapter: chapter,
            kind: 'bench',
            companionId: benched[i],
            reason: 'no seat: ${valueOf(benched[i]).toStringAsFixed(1)}'));
      }
    }
    if (seated.isEmpty && benched.isEmpty) return;
    active
      ..clear()
      ..addAll(want);
  }

  /// The seated companions react to a deed (approval.dart's
  /// approvalDeltaFor, as PlayerSessionNotifier._reactToDeed does): one
  /// pushed to [leavingApproval] walks out, the bench's best-disposed
  /// steps in, and the party is arranged again. [exclude]: the one the
  /// story takes with this deed.
  void react({
    required int chapter,
    required String cause,
    int alignmentMod = 0,
    int goldMod = 0,
    Map<String, int> approvalMods = const {},
    String? exclude,
    int alignment = 0,
  }) {
    final leaving = <String>[];
    for (final id in [...active]) {
      if (id == exclude) continue;
      final member = roster[id]!;
      final delta = approvalDeltaFor(_record(id),
          alignmentMod: alignmentMod,
          goldMod: goldMod,
          explicit: explicitApprovalFor(approvalMods, id));
      final after = permanentApprovalFloor(
          _record(id), approvalAfter(member.approval, delta));
      if (after == member.approval) continue;
      final change = ApprovalChange(
          companionId: id, before: member.approval, after: after);
      member.approval = after;
      if (change.leaves) {
        leaving.add(id);
      } else if (change.tierChanged &&
          (change.tierAfter == ApprovalTier.devoted ||
              change.tierAfter == ApprovalTier.wary)) {
        log.add(SimCompanionEvent(
            chapter: chapter,
            kind: change.tierAfter.name,
            companionId: id,
            reason: 'approval $after after $cause'));
      }
    }
    for (final id in leaving) {
      _remove(id,
          lost: false,
          chapter: chapter,
          reason: 'approval ${roster[id]!.approval} after $cause');
    }
    if (leaving.isNotEmpty) arrange(chapter: chapter, alignment: alignment);
  }

  /// The story's own companions (story_companions.dart: Vica) join once the
  /// walk has [visited] one of their scenes, whatever the policy. Returns
  /// who joined.
  List<String> joinFromStory(Iterable<String> visited,
      {required int chapter, int alignment = 0}) {
    final due = storyRecruitsDue(companions,
        visited: visited, recruited: roster.keys, gone: [...departed, ...lost]);
    for (final id in due) {
      recruit(id, chapter: chapter, cause: 'the story', alignment: alignment);
    }
    return due;
  }

  /// The story takes [companionId] (a choice's `loseAllyId`; `*` the first
  /// seated) for good; never a permanent one (Vica).
  void lose(String companionId,
      {required int chapter, required String cause, int alignment = 0}) {
    final id = storyLossOf(companionId, active: active, companions: companions);
    if (id == null || !roster.containsKey(id)) return;
    _remove(id, lost: true, chapter: chapter, reason: cause);
    arrange(chapter: chapter, alignment: alignment);
  }

  /// PlayerSessionNotifier._removeAlly: off the roster for good; a seated
  /// one's seat goes to the bench's highest approval (house built).
  void _remove(String id,
      {required bool lost, required int chapter, required String reason}) {
    final wasSeated = active.remove(id);
    roster.remove(id);
    (lost ? this.lost : departed).add(id);
    String? replacement;
    if (wasSeated) {
      final bench = [
        for (final member in roster.values)
          if (!active.contains(member.id) && houseBuiltFor(member.id)) member,
      ];
      if (bench.isNotEmpty) {
        replacement =
            bench.reduce((best, m) => m.approval > best.approval ? m : best).id;
        active.add(replacement);
      }
    }
    log.add(SimCompanionEvent(
        chapter: chapter,
        kind: lost ? 'lost' : 'leave',
        companionId: id,
        reason:
            replacement == null ? reason : '$reason; $replacement steps in'));
  }

  /// The houses standing now; a new seat or Kelda's Hall rearranges.
  void housesBuilt(Iterable<String> ids,
      {required int chapter, int alignment = 0}) {
    final next = ids.toSet();
    if (next.length == builtHouses.length && next.containsAll(builtHouses)) {
      return;
    }
    builtHouses = next;
    arrange(chapter: chapter, alignment: alignment);
  }

  /// A rest (a chapter's hub): everyone back to full.
  void rest() {
    for (final member in roster.values) {
      member.health = null;
    }
  }

  /// The player's level now; a level-up heals every recruited companion
  /// (applyCombatResult).
  void levelIs(int level) {
    if (level > _level) rest();
    _level = level;
  }

  /// The seated companions as one fight meets them (fight_setup.dart's
  /// `_ensurePartyBuilt`): their stats at the player's level and their
  /// approval, a sign's party health and ally damage, and the health they
  /// carry from the last fight.
  List<SimAlly> fightAllies({
    SignEffects signs = SignEffects.none,
    PerkEffects perks = PerkEffects.none,
  }) {
    return [
      for (final id in active)
        if (_simAlly(id, signs: signs, perks: perks) case final ally?) ally,
    ];
  }

  /// The reserve as a fight meets them (fightAllies), to step in for one
  /// knocked out (sim_combat.dart's `reserve`); null with none, or when
  /// they are down themselves.
  SimAlly? fightReserve({
    SignEffects signs = SignEffects.none,
    PerkEffects perks = PerkEffects.none,
  }) {
    final id = reserve;
    if (id == null || active.contains(id)) return null;
    final ally = _simAlly(id, signs: signs, perks: perks);
    return ally == null || ally.isKnockedOut ? null : ally;
  }

  SimAlly? _simAlly(
    String id, {
    required SignEffects signs,
    required PerkEffects perks,
  }) {
    final record = _record(id);
    final member = roster[id];
    if (record == null || member == null) return null;
    final race =
        races[record['raceId']?.toString() ?? ''] as Map<String, dynamic>? ??
            const {};
    final profession = professions[record['professionId']?.toString() ?? '']
            as Map<String, dynamic>? ??
        const {};
    final base = deriveAllyBaseStats(
        gameConfig: gameConfig, race: race, profession: profession);
    final stats = _allyStats(record,
        level: _level,
        approval: member.approval,
        races: races,
        professions: professions,
        gameConfig: gameConfig);
    final liveMax = signs.maxHealthFor(stats.maxHealth, partyWide: true);
    final faces = _facesOf(dice, record);
    final known = {
      ...companionStarterSkillIds(
          race: race, profession: profession, companion: record, dice: dice),
      ...dieSignatureSkillIds(dice[record['signatureDiceId']?.toString() ?? '']
          as Map<String, dynamic>?),
    };
    return SimAlly(
      id: id,
      professionId: record['professionId']?.toString() ?? '',
      maxHealth: liveMax,
      currentHealth: SignEffects.healthEntering(
        current: (member.health ?? stats.maxHealth).clamp(0, stats.maxHealth),
        base: stats.maxHealth,
        fightMax: liveMax,
      ),
      damage: signs.scaleAllyDamage(perks.scaleAllyDamage(stats.damage)),
      armor: stats.armor,
      dexterity: base.dexterity,
      luck: base.luck,
      wisdom: base.wisdom,
      perception: base.perception,
      faces: faces,
      skills: {
        for (final entry in skills.entries)
          if (known.contains(entry.key) ||
              ((entry.value as Map?)?['isUnlocked'] as bool? ?? false))
            entry.key: entry.value,
      },
    );
  }

  /// What a fight left (fight_rewards.dart): on a win each one's health
  /// is kept (a knocked-out one back at [simReviveHealthFraction]) plus a
  /// sign's mending; a loss changes nothing. Knock-outs and the skills cast
  /// are counted either way.
  void afterFight(List<SimAlly> allies,
      {required bool won, SignEffects signs = SignEffects.none}) {
    for (final ally in allies) {
      if (ally.isKnockedOut) {
        knockouts[ally.id] = (knockouts[ally.id] ?? 0) + 1;
      }
      final cast = skillsCast.putIfAbsent(ally.id, () => {});
      for (final MapEntry(:key, :value) in ally.skillsCast.entries) {
        cast[key] = (cast[key] ?? 0) + value;
      }
      final member = roster[ally.id];
      if (!won || member == null) continue;
      final after = ally.isKnockedOut
          ? (ally.maxHealth * simReviveHealthFraction).round()
          : ally.currentHealth;
      member.health =
          min(ally.maxHealth, after + signs.afterFightHeal(ally.maxHealth));
    }
  }
}
