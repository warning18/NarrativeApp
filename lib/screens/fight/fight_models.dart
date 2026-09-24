part of '../fight_screen.dart';

/// Which companions.json banter line a moment calls for -- see
/// [_FightScreenState._rollBanter].
enum _BanterKind { crit, dodge, fightStart, pack, ko, chest }

String _banterFieldFor(_BanterKind kind, AppLanguage lang) {
  final base = switch (kind) {
    _BanterKind.crit => 'critLine',
    _BanterKind.dodge => 'dodgeLine',
    _BanterKind.fightStart => 'fightStartLine',
    _BanterKind.pack => 'packLine',
    _BanterKind.ko => 'koLine',
    _BanterKind.chest => 'chestLine',
  };
  return lang == AppLanguage.fr ? '${base}Fr' : base;
}

/// Broad categories a combat-log line falls into, used to color and icon
/// each line so the log reads at a glance instead of as a wall of text.
enum _LogKind {
  info,
  playerDamage,
  playerHeal,
  playerBlock,
  enemyDamage,
  victory,
  defeat,
  banter,
  mana,
  phase,
}

class _LogEntry {
  const _LogEntry(this.text, this.kind);

  final String text;
  final _LogKind kind;
}

/// What confirming one member's rolled face would do, worked out with the
/// same numbers as [_FightScreenState._confirmRoll] but without the dice's
/// luck: no random critical (a momentum surge, which is a guaranteed one,
/// is counted), the target's Armored affix applied, the battlefield's
/// heal/block multipliers applied, and the same target the confirm would
/// pick. Shown on the die tile, on the enemy card's health bar and in the
/// face sheet, so the player sees the number before committing to it.
class _FacePreview {
  const _FacePreview({
    required this.result,
    required this.target,
    required this.damage,
    required this.healing,
    required this.block,
    required this.surge,
  });

  /// The face resolved with no random critical.
  final PlayerActionResult result;

  /// The enemy this face would hit: null for a face that does not strike,
  /// or when nothing is left standing.
  final _EnemyMember? target;

  /// Damage [target] would take after its affixes; the face's own damage
  /// when there is no target.
  final int damage;

  /// Healing the member would get, after the battlefield's multiplier.
  final int healing;

  /// Block the member would hold, after bracing and the battlefield's
  /// multiplier.
  final int block;

  /// True when this strike cashes in the momentum meter as a guaranteed
  /// critical (only the round's first strike does).
  final bool surge;

  /// True when [damage] would drop [target].
  bool get lethal => target != null && damage >= target!.currentHealth;
}

/// The skill a rolled 'Skill' face actually resolves to — mirrors
/// combat_engine.dart's own fallback so the preview always matches what
/// pressing Confirm will actually do.
String _effectiveSkillId(DiceFaceResult face) =>
    face.linkedSkillID.isEmpty ? 'heavy_attack' : face.linkedSkillID;

/// The element a rolled face actually hits with — the linked skill's own
/// `element` for a Skill face (the skill is what's actually cast; the face
/// is just its delivery), or the face's own `element` for a plain
/// Attack/Defend/Heal face. Used to look up gear's `<prefix>DmgBonus` and
/// to record what the enemy was just hit with for `OnHitByElement`.
String _elementFor(DiceFaceResult face, Map<String, dynamic> skills) {
  if (face.type == 'Skill') {
    final skill = skills[_effectiveSkillId(face)] as Map<String, dynamic>?;
    return skill?['element']?.toString() ?? 'None';
  }
  return face.element;
}

/// The equipment bonus for [element] off [equippedItemIds] — 0 for 'None'
/// or any element without a known item-field prefix (see
/// [elementFieldPrefixes]).
int _elementalDamageBonus(
  String element,
  List<String> equippedItemIds,
  Map<String, dynamic> items,
) {
  final prefix = elementFieldPrefixes[element];
  if (prefix == null) return 0;
  return equipmentBonusFor(equippedItemIds, items, '${prefix}DmgBonus');
}

/// The equipment resist for [element] off [equippedItemIds] — 0 for 'None'
/// or any element without a known item-field prefix.
int _elementalResist(
  String element,
  List<String> equippedItemIds,
  Map<String, dynamic> items,
) {
  final prefix = elementFieldPrefixes[element];
  if (prefix == null) return 0;
  return equipmentBonusFor(equippedItemIds, items, '${prefix}Resist');
}

/// The log line announcing a status effect just landed on [targetName] —
/// shared by the player/ally-inflicted (enemy target) and enemy-inflicted
/// (party target) paths so both read the same way.
String _statusInflictedMessage(
    StatusEffect effect, String targetName, AppLanguage lang) {
  final suffixKey = switch (effect.type) {
    StatusEffectType.poison => 'poisoned_suffix',
    StatusEffectType.stun => 'stunned_suffix',
    StatusEffectType.weaken => 'weakened_suffix',
  };
  return '$targetName ${trFor(lang, suffixKey)}';
}

/// One combatant on the player's side of a fight — the player themself, or
/// one currently-active ally. Ephemeral, fight-scoped state only (mirrors
/// how the player's own HP was already tracked as local widget state before
/// this screen supported more than one combatant per side); persisted back
/// to [PlayerSession]/[AllyState] only once the fight ends.
class _PartyMember {
  _PartyMember({
    required this.id,
    required this.displayName,
    required this.isPlayer,
    required this.maxHealth,
    required this.baseDamage,
    required this.armor,
    required this.currentHealth,
    required this.equippedItemIds,
    required this.unlockedSkillIds,
    required this.diceSkillAssignments,
    required this.equippedDiceId,
    this.skillTiers = const {},
    this.strength = 0,
    this.dexterity = 0,
    this.constitution = 0,
    this.intelligence = 0,
    this.wisdom = 0,
    this.luck = 0,
    this.perception = 0,
    this.gear = GearEffects.none,
  });

  final String id;
  final String displayName;
  final bool isPlayer;

  /// What this member's worn sets and unique items add up to (see
  /// gear_effects.dart) -- resolved once at party build.
  final GearEffects gear;

  /// A [UniqueEffect.secondWind] charge, spent the first time a blow would
  /// have dropped this member this fight.
  late bool secondWindAvailable = gear.secondWind;
  final int maxHealth;
  final int baseDamage;
  final int armor;
  final List<String> equippedItemIds;
  final List<String> unlockedSkillIds;

  /// Ability scores, used only to resolve each equipped item's own
  /// `scalingStat` bonus (see [equipmentScalingBonusFor]) — not part of the
  /// die-roll math itself, exactly like [PlayerSession]'s own scores.
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;

  /// Amplifies this member's own healing (see [resolvePlayerFace]'s
  /// `wisdomHealBonus`) and shortens the duration of status effects landed
  /// on them (see [applyWisdomResistance]) -- not part of the equipment
  /// scaling system above, since it isn't gear-driven.
  final int wisdom;

  /// Feeds this member's own critical-hit chance (see
  /// [criticalChanceFor]) -- not part of the equipment scaling system
  /// above, since it isn't gear-driven either.
  final int luck;

  /// Feeds [telegraphTierFor] via [_FightScreenState._bestPartyPerception]
  /// -- the whole party reads an enemy's telegraphed next move off
  /// whoever's Perception is currently highest, not the player's alone.
  final int perception;

  /// skillId -> tier — only the player has these (see
  /// [PlayerSession.skillTiers]); allies leave this empty, so their skills
  /// always resolve at base numbers.
  final Map<String, int> skillTiers;

  /// faceIndex (as string) -> skillId. For the player this is their
  /// currently-equipped die's slice of [PlayerSession.diceSkillAssignments];
  /// for an ally it's their own flat [AllyState.diceSkillAssignments] as-is.
  final Map<String, String> diceSkillAssignments;
  final String? equippedDiceId;

  int currentHealth;
  int block = 0;

  /// Poison/Stun/Weaken currently afflicting this member — see
  /// status_effect.dart. Applied by an enemy's moves, ticked down once per
  /// round in [_FightScreenState._startPartyRound].
  List<StatusEffect> statusEffects = [];

  bool get isKnockedOut => currentHealth <= 0;
}

/// One enemy's move+target for its NEXT turn, pre-rolled and cached ahead
/// of time so a telegraph preview can show the party exactly what's coming
/// -- see [_FightScreenState._preRollMoveFor]. [_FightScreenState._takeEnemyTurn]
/// applies this same cached result rather than re-rolling either half; only
/// [targetId] ever gets a live fallback re-pick, if the cached target was
/// knocked out in the meantime.
class _PendingEnemyMove {
  const _PendingEnemyMove({required this.move, required this.targetId});

  final EnemyMoveResult move;

  /// The [_PartyMember.id] this move is aimed at.
  final String targetId;
}

/// One enemy on the opposing side of a fight — the pack-fight counterpart to
/// [_PartyMember]. A solo fight is simply a pack of one; every fight this
/// screen ran before multi-enemy packs existed is `_enemies.length == 1`,
/// behaviorally unchanged.
class _EnemyMember {
  _EnemyMember({
    required this.key,
    required this.enemyId,
    required this.displayName,
    required this.data,
    required this.maxHealth,
    required this.damage,
    required this.guile,
    required this.hasReactiveMoves,
    required this.currentHealth,
    this.affixes = const [],
  });

  /// This enemy's affixes (see enemy_affix.dart) -- rolled once at fight
  /// start, or forced by the encounter for a hunt's quarry.
  final List<EnemyAffix> affixes;

  bool hasAffix(EnemyAffix affix) => affixes.contains(affix);

  /// True once a Skittish enemy has run from the fight -- it's out of the
  /// fight like a defeated one, but yields only part of its reward.
  bool fled = false;

  /// Fight-scoped unique id (e.g. `enemy_0`, `enemy_1`) -- NOT [enemyId],
  /// since a pack may contain two of the same enemy. Used to key
  /// [_FightScreenState._selectedTargets] and this fight's health bars.
  final String key;

  /// The raw gamedata id (e.g. `harbor_rat`) -- may repeat across pack
  /// members. Used for reward/loot summing and unlock-tracking on a win.
  final String enemyId;

  /// This enemy's display name -- Elite-prefixed for a solo Elite
  /// encounter, and disambiguated with a " #2"/" #3" suffix when a pack
  /// has more than one enemy sharing the same base name.
  final String displayName;

  /// This enemy's own gamedata record (Elite-name-adjusted for a solo
  /// Elite) — everywhere this screen used to read `widget.enemy`/
  /// `_enemyData` directly, per-enemy code now reads this instead. Base
  /// numeric fields (`maxHealth`/`damage`/`goldReward`/`xpReward`/
  /// `lootTable`/`guile`) are read straight from here since Elite only
  /// changes the display name, never these.
  Map<String, dynamic> data;

  final int maxHealth;

  /// Player-level-scaled (and Elite-multiplied for a solo Elite) damage --
  /// climbs when a boss phase enrages it.
  int damage;

  /// This enemy's own Guile (see db_schema.dart's enemiesSchema) — read
  /// once at fight start, never changes mid-fight.
  final int guile;

  /// True if this enemy's own skillMoves include an `OnHitByElement`
  /// condition — such an enemy is never pre-rolled (see
  /// [_FightScreenState._preRollMoveFor]'s doc comment) and so never
  /// telegraphs; it live-rolls its move exactly as every enemy did before
  /// telegraphing existed.
  final bool hasReactiveMoves;

  int currentHealth;

  /// Poison/Stun/Weaken currently afflicting THIS enemy.
  List<StatusEffect> statusEffects = [];

  /// Elements the party hit THIS enemy with in the round that just
  /// resolved — per-enemy (a sibling enemy being hit with Fire shouldn't
  /// make this one react to Fire too), reset fresh at the top of every
  /// [_FightScreenState._confirmRoll].
  Set<String> elementsHitThisRound = {};

  /// This enemy's move+target for its NEXT turn, pre-rolled and cached --
  /// see [_FightScreenState._preRollMoveFor]. Null for a
  /// [hasReactiveMoves] enemy (never pre-rolled) or before the first
  /// pre-roll has run.
  _PendingEnemyMove? pendingMove;

  /// This enemy's boss phases (see [parseBossPhases]), highest threshold
  /// first; empty for an ordinary enemy.
  List<BossPhase> phases = const [];

  /// How many of [phases] have been entered so far -- only ever climbs, so
  /// a phase's heal lifting the enemy back above its threshold never
  /// replays it.
  int phaseIndex = 0;

  BossPhase? get currentPhase => phaseIndex > 0 && phaseIndex <= phases.length
      ? phases[phaseIndex - 1]
      : null;

  bool get isAlive => currentHealth > 0;
}
