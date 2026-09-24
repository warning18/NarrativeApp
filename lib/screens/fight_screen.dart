import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/battlefield_condition.dart';
import '../combat/combat_aftermath.dart';
import '../combat/party_bonus.dart';
import '../combat/combat_engine.dart';
import '../combat/encounter.dart';
import '../combat/enemy_affix.dart';
import '../combat/gear_effects.dart';
import '../combat/loot_box.dart';
import '../combat/spells.dart';
import '../combat/status_effect.dart';
import '../data/chapter_spine.dart';
import '../data/story_repository.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/ally_state.dart';
import '../providers/aftermath_provider.dart';
import '../providers/combat_settings_provider.dart';
import '../providers/game_config_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/home_tab_provider.dart';
import '../providers/permadeath_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../utils/game_icons.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import '../widgets/level_up_dialog.dart';
import '../widgets/spoils_chest_dialog.dart';
import 'death_screen.dart';

const int _potionHealAmount = 30;

/// A knocked-out ally is revived at this fraction of their (live-derived)
/// max health after a won fight — see [_FightScreenState._finishFight].
const double _reviveHealthFraction = 0.3;

/// Odds a solo fight against an enemy not in [soloOnlyEnemyIds] is promoted
/// to an Elite encounter — see [_FightScreenState._isElite]. Never rolled
/// for a multi-enemy pack (see [_FightScreenState._ensureEnemiesBuilt]) —
/// Elite and packs are two separate variance mechanics, deliberately never
/// combined.
const double _eliteChance = 0.12;

/// An Elite's health/damage are both multiplied by this on top of the
/// normal player-level scaling -- a real, noticeable step up, not a
/// rounding error, without being so far past the enemy's own tuned
/// baseline that it stops feeling like a harder version of the same fight.
const double _eliteStatMultiplier = 1.35;

/// An Elite's gold/XP reward on a win are multiplied by this -- the
/// "worth the extra risk" payoff, alongside the guaranteed trophy drop
/// (see [_FightScreenState._finishFight]).
const double _eliteRewardMultiplier = 1.5;

/// Odds a still-active, non-acting ally reacts with a short banter line
/// (see companions.json's `critLine`/`dodgeLine` fields) when a crit or a
/// dodge lands -- rolled independently of the crit/dodge chance itself, so
/// the moment stays a pleasant surprise rather than a guaranteed line
/// every single time.
const double _banterChance = 0.35;

/// Per-member hp/damage multiplier for a multi-enemy pack, by pack size. A
/// pack's threat is its action economy -- two or three hits a round against
/// one party's worth of rolls -- so each member is scaled down to keep the
/// fight winnable for a party at the pack's own chapter level (unscaled,
/// three chapter-2 heavies were a 0% fight at level 3; at 0.85/0.75 a pair
/// of mid-tier enemies was still the worst random fight in the game).
/// Solo fights are never scaled.
const Map<int, double> _packStatMultipliers = {2: 0.8, 3: 0.7};

/// A Defend face rolled by the party member an enemy is visibly (see
/// [telegraphTierFor]) about to hit blocks this many times its face value
/// -- the tactical payoff for reading a telegraph: brace where the blow is
/// coming, not where it isn't.
const int _telegraphBraceMultiplier = 2;

/// Damaging party hits that build up (with no enemy hit landing on the
/// party in between) before the next Attack/Skill face is a guaranteed
/// critical -- see [_FightScreenState._momentum].
const int _momentumThreshold = 3;

/// Luck added to the player's own crit roll for one fight by a
/// `charm_lucky_coin` (10 Luck = +15 percentage points, see
/// [criticalChanceFor]).
const int _luckyCoinLuckBonus = 10;

/// Armor added to the player for one fight by a `charm_iron_skin`.
const int _ironSkinArmorBonus = 5;

/// The Poison a Venomous enemy's plain attack carries (see [EnemyAffix]).
const StatusEffect _venomousPoison = StatusEffect(
    type: StatusEffectType.poison, remainingTurns: 2, magnitude: 3);

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

Color _logColor(BuildContext context, _LogKind kind) {
  switch (kind) {
    case _LogKind.info:
      return Theme.of(context).colorScheme.onSurfaceVariant;
    case _LogKind.playerDamage:
      return Colors.deepOrange;
    case _LogKind.playerHeal:
      return Colors.green;
    case _LogKind.playerBlock:
      return Colors.blueGrey;
    case _LogKind.enemyDamage:
      return Colors.red;
    case _LogKind.victory:
      return Colors.amber.shade800;
    case _LogKind.defeat:
      return Colors.red.shade900;
    case _LogKind.banter:
      return Colors.indigo;
    case _LogKind.mana:
      return manaColor;
    case _LogKind.phase:
      return Colors.deepPurple;
  }
}

IconData _logIcon(_LogKind kind) {
  switch (kind) {
    case _LogKind.info:
      return Icons.info_outline;
    case _LogKind.playerDamage:
      return Icons.bolt;
    case _LogKind.playerHeal:
      return Icons.favorite;
    case _LogKind.playerBlock:
      return Icons.shield;
    case _LogKind.enemyDamage:
      return Icons.warning_amber_rounded;
    case _LogKind.victory:
      return Icons.emoji_events;
    case _LogKind.defeat:
      return Icons.heart_broken;
    case _LogKind.banter:
      return Icons.chat_bubble_outline;
    case _LogKind.mana:
      return manaIcon;
    case _LogKind.phase:
      return Icons.change_circle_outlined;
  }
}

/// Icon for a die face's own type — distinct from [_logIcon], which is
/// about a resolved log line's category.
IconData _faceTypeIcon(String type) {
  switch (type) {
    case 'Attack':
      return Icons.bolt;
    case 'Defend':
      return Icons.shield;
    case 'Heal':
      return Icons.favorite;
    case 'Skill':
      return Icons.auto_awesome;
    case 'Mana':
      return manaIcon;
    default:
      return Icons.remove_circle_outline;
  }
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

const int _maxRolls = 3;

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

class FightScreen extends ConsumerStatefulWidget {
  const FightScreen({
    super.key,
    required this.enemyId,
    required this.enemy,
    this.additionalEnemyIds = const [],
    this.additionalEnemies = const {},
    this.modifiers = EncounterModifiers.none,
  });

  final String enemyId;
  final Map<String, dynamic> enemy;

  /// Per-encounter overrides (a hunt's named quarry, an alignment
  /// hunter's ambush) -- see encounter.dart. The default leaves every
  /// existing call site's fight exactly as it was.
  final EncounterModifiers modifiers;

  /// Extra enemy ids alongside [enemyId] for a 2-3-enemy pack fight — empty
  /// for a solo fight (every call site from before packs existed), which
  /// leaves this screen's behavior completely unaffected.
  final List<String> additionalEnemyIds;

  /// [additionalEnemyIds]' own gamedata records, keyed by id — parallels
  /// how [enemy] is [enemyId]'s own record.
  final Map<String, Map<String, dynamic>> additionalEnemies;

  /// Every enemy in this fight as (id, data) pairs, [enemyId]/[enemy] first
  /// followed by [additionalEnemyIds] in order — the one place that
  /// resolves "which enemies" for the whole screen.
  List<MapEntry<String, Map<String, dynamic>>> get _allEnemyEntries => [
        MapEntry(enemyId, enemy),
        for (final id in additionalEnemyIds)
          MapEntry(id, additionalEnemies[id] ?? const {}),
      ];

  @override
  ConsumerState<FightScreen> createState() => _FightScreenState();
}

class _FightScreenState extends ConsumerState<FightScreen>
    with TickerProviderStateMixin {
  final Random _random = Random();
  final List<_LogEntry> _log = [];

  bool _started = false;
  bool _over = false;
  bool _won = false;

  late int _playerLevel;
  int _lastDamageTaken = 0;

  /// True only for a solo fight promoted to Elite — rolled once in
  /// [_ensureEnemiesBuilt] and fixed for the rest of the fight. Always
  /// false for a multi-enemy pack (Elite and packs are never combined).
  bool _isElite = false;

  /// Resolve and the camp's works, resolved once at party build (see
  /// party_bonus.dart).
  PartyBonus _partyBonus = PartyBonus.none;

  /// Every enemy in this fight — a solo fight is `_enemies.length == 1`.
  /// Built once in [_ensureEnemiesBuilt], mutated in place for the rest of
  /// the fight (mirrors how [_party] already worked).
  List<_EnemyMember> _enemies = [];

  /// The loaded companions.json table, kept for [_rollBanter]'s
  /// crit/dodge reaction-line lookup -- set once in [_ensurePartyBuilt],
  /// alongside the party itself.
  Map<String, dynamic> _companions = const {};

  /// Which party member most recently took damage from an enemy, so the
  /// floating "-N" indicator lands on the right health bar. Null until the
  /// first hit lands.
  String? _lastDamagedMemberId;

  /// The mirror of [_lastDamagedMemberId]/[_lastDamageTaken] for the enemy
  /// side — which enemy (by [_EnemyMember.key]) most recently took damage
  /// from the party, and how much, so its own floating "-N" indicator lands
  /// on the right health bar.
  String? _lastDamagedEnemyKey;
  int _lastEnemyDamageTaken = 0;

  /// actorId -> target [_EnemyMember.key], this round's picks — only
  /// meaningful once `_enemies.length > 1`; a solo fight never populates
  /// this (every Attack/Skill face implicitly targets the only enemy).
  /// Cleared each [_confirmRoll], same lifecycle as [_currentFaces].
  final Map<String, String> _selectedTargets = {};

  /// Acting members whose current face is kept (locked) through the next
  /// reroll -- tapping a landed die toggles it. Cleared with the round.
  final Set<String> _lockedActorIds = {};

  /// In a pack fight, the member whose die an enemy-card tap re-aims.
  String? _selectedActorId;

  /// Block granted by spells this round, per member id -- added on top of
  /// whatever Defend face the member confirms (see [_confirmRoll]), so a
  /// Mana Ward cast before the roll isn't overwritten by it.
  final Map<String, int> _spellBlock = {};

  /// The party's mana pool this fight -- seeded from the session, moved by
  /// Mana faces and casts, written back through `setMana` as it moves.
  int _mana = 0;
  int _maxMana = 0;

  /// spells.json, parsed -- set in [build].
  Map<String, SpellSpec> _spells = const {};

  /// item_sets.json, parsed -- set in [build].
  Map<String, ItemSet> _itemSets = const {};

  /// The session's New Game+ cycle, read once at fight start -- every
  /// enemy is scaled by [newGamePlusMultiplier] of it.
  int _newGamePlusCycle = 0;

  /// See [companionAutoTargetProvider]: when set, companions aim their
  /// own strikes (focus fire on the player's target, else the weakest
  /// enemy) and their cards aren't selectable in the target picker.
  bool _companionsAutoAim = true;

  String? _selectedDiceId;
  bool _rolling = false;

  bool _partyBuilt = false;
  List<_PartyMember> _party = [];

  /// This fight's one-off circumstance, if any -- see
  /// battlefield_condition.dart. Rolled once in [_ensureEnemiesBuilt].
  BattlefieldCondition? _condition;

  /// Party rounds begun so far -- the spoils chest's "swift fight" bonus
  /// reads this, and an Ambush hides every telegraph while it's still 1.
  int _roundsStarted = 0;

  /// Damaging party hits landed since the party last took a hit. At
  /// [_momentumThreshold] the next Attack/Skill face is a guaranteed
  /// critical (which spends it).
  int _momentum = 0;

  /// Flawless-fight tracking for the spoils chest: no potion drunk, nobody
  /// knocked out.
  bool _potionUsed = false;
  bool _anyKnockedOut = false;

  /// The last companion knocked out this fight, for the story's aftermath
  /// line (see combat_aftermath.dart).
  String? _lastKnockedOutAllyName;

  /// Boss phases crossed this fight, across every enemy.
  int _phasesCrossed = 0;

  /// The party read at least one enemy at the full telegraph tier this
  /// fight -- the chest's Perception extra slot.
  bool _fullTelegraphRead = false;

  /// Whether the hit that took down the most recently killed enemy was a
  /// critical -- the chest's "critical finish" bonus reads it at the end.
  bool _lastKillWasCritical = false;

  /// The player's own alignment label ('Good'/'Neutral'/'Evil'), read once
  /// at party build -- stands for the whole party, as for skill gating.
  String _alignmentLabel = 'Neutral';

  /// Charms picked on the setup screen, burned (and applied) at
  /// [_startFight].
  final Set<String> _armedCharmIds = {};
  int _maxRollsThisFight = _maxRolls;
  bool _luckyCoinArmed = false;
  bool _ironSkinArmed = false;
  int _wardingCharges = 0;

  /// This round's rolled face per conscious party member id — every
  /// conscious member (the player, plus each active ally) rolls their own
  /// die together as one combined action instead of taking separate
  /// sequential turns. Cleared once a roll is confirmed.
  final Map<String, DiceFaceResult> _currentFaces = {};

  /// How many times the party has rolled so far *this round* (0-3) — a
  /// single shared budget covering every member's die at once, not a
  /// per-member count.
  int _rollCount = 0;

  /// True right after a roll lands and before the player has chosen to
  /// keep it or reroll — false before the first roll of a turn, and false
  /// again once a choice is confirmed (manually, or forced at the 3rd roll).
  bool _awaitingDecision = false;

  late final AnimationController _shakeController;
  late final AnimationController _rollController;

  @override
  void initState() {
    super.initState();
    final session = ref.read(playerSessionProvider);
    _playerLevel = session.level;
    _newGamePlusCycle = session.newGamePlusCycle;
    _maxMana = session.maxMana;
    _mana = session.mana.clamp(0, _maxMana);
    _ensureEnemiesBuilt();
    _selectedDiceId = session.equippedDiceId ??
        (session.ownedDiceIds.isNotEmpty ? session.ownedDiceIds.first : null);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // Spins and bounces the die icon for a beat before a roll's result is
    // applied, so a tap reads as "rolling" rather than an instant stat swap.
    _rollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _rollController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    if (!ref.read(trembleEnabledProvider)) return;
    _shakeController.forward(from: 0);
  }

  /// The story chapter this fight belongs to: the caller's (an expedition
  /// passes its zone's), else the current story node's, else 1. Drives the
  /// chapter difficulty curve and the chest's loot window.
  int get _chapter =>
      widget.modifiers.chapter ??
      chapterForNode(ref.read(storyPlayProvider).currentNodeId) ??
      1;

  /// Builds [_enemies] — a solo fight rolls Elite (see [_eliteChance]); a
  /// pack (`widget.additionalEnemyIds` non-empty) never does. A pack member
  /// sharing a base name with another gets a " #2"/" #3" suffix on its own
  /// [_EnemyMember.displayName] so the two are distinguishable in the UI;
  /// a solo fight or an all-distinct pack never shows one. Also rolls
  /// every enemy's affixes (see [rollEncounterAffixes]) and this fight's
  /// battlefield condition (see [rollBattlefieldCondition]).
  void _ensureEnemiesBuilt() {
    final entries = widget._allEnemyEntries;
    final lang = ref.read(appLanguageProvider);
    final modifiers = widget.modifiers;
    _isElite = entries.length == 1 &&
        !soloOnlyEnemyIds.contains(entries.first.key) &&
        modifiers.forcedAffixes.isEmpty &&
        _random.nextDouble() < _eliteChance;
    _condition =
        rollBattlefieldCondition(enemyCount: entries.length, random: _random);

    final affixes = rollEncounterAffixes(
      enemyIds: [for (final e in entries) e.key],
      isElite: _isElite,
      random: _random,
    );
    if (modifiers.forcedAffixes.isNotEmpty) {
      affixes[0] = modifiers.forcedAffixes;
    }

    final baseNames = [
      for (final entry in entries)
        entry.value['enemyName']?.toString() ?? entry.key,
    ];
    final totalCounts = <String, int>{};
    for (final name in baseNames) {
      totalCounts[name] = (totalCounts[name] ?? 0) + 1;
    }
    final seenSoFar = <String, int>{};

    _enemies = [
      for (var i = 0; i < entries.length; i++)
        _buildEnemyMember(
          index: i,
          id: entries[i].key,
          raw: entries[i].value,
          baseName: baseNames[i],
          isDuplicateName: (totalCounts[baseNames[i]] ?? 1) > 1,
          seenSoFar: seenSoFar,
          packSize: entries.length,
          lang: lang,
          affixes: affixes[i],
          nameOverride: i == 0 ? modifiers.namedEnemyName : null,
          healthMultiplier: i == 0 ? modifiers.healthMultiplier : 1.0,
        ),
    ];
  }

  _EnemyMember _buildEnemyMember({
    required int index,
    required String id,
    required Map<String, dynamic> raw,
    required String baseName,
    required bool isDuplicateName,
    required Map<String, int> seenSoFar,
    required int packSize,
    required AppLanguage lang,
    List<EnemyAffix> affixes = const [],
    String? nameOverride,
    double healthMultiplier = 1.0,
  }) {
    final elitePrefixedName =
        _isElite ? '${trFor(lang, 'elite_prefix')} $baseName' : baseName;
    // An affix reads as a one-word title ("Venomous Harbor Rat") so the
    // player always knows what they're facing; a hunt's named quarry keeps
    // its own name and shows its affixes as chips instead.
    final affixPrefix = affixes.isEmpty || nameOverride != null
        ? ''
        : '${affixes.map((a) => trFor(lang, affixLabelKey(a))).join(' ')} ';
    final titledName = nameOverride ?? '$affixPrefix$elitePrefixedName';
    final data =
        titledName != baseName ? {...raw, 'enemyName': titledName} : raw;
    String displayName;
    if (isDuplicateName && nameOverride == null) {
      seenSoFar[baseName] = (seenSoFar[baseName] ?? 0) + 1;
      displayName = '$titledName #${seenSoFar[baseName]}';
    } else {
      displayName = titledName;
    }
    var maxHealth =
        scaledMaxHealth((raw['maxHealth'] as num?)?.toInt() ?? 1, _playerLevel);
    var damage =
        scaledDamage((raw['damage'] as num?)?.toInt() ?? 0, _playerLevel);
    // The difficulty curve (the flat floor, the chapter, a zone's tier and
    // the New Game+ cycle) scales every enemy before the Elite/pack
    // multipliers, so those keep their tuned ratios.
    final curve = difficultyCurveFor(
      chapter: _chapter,
      zoneMultiplier: widget.modifiers.difficultyMultiplier,
      newGamePlusCycle: _newGamePlusCycle,
      isBoss: isBossEnemy(id, raw),
    );
    maxHealth = max(1, (maxHealth * curve.health).round());
    damage = (damage * curve.damage).round();
    if (_isElite) {
      maxHealth = (maxHealth * _eliteStatMultiplier).round();
      damage = (damage * _eliteStatMultiplier).round();
    }
    final packMultiplier = _packStatMultipliers[packSize];
    if (packMultiplier != null) {
      maxHealth = max(1, (maxHealth * packMultiplier).round());
      damage = (damage * packMultiplier).round();
    }
    if (affixes.contains(EnemyAffix.packLeader)) {
      maxHealth = (maxHealth * packLeaderHealthMultiplier).round();
    }
    if (healthMultiplier != 1.0) {
      maxHealth = max(1, (maxHealth * healthMultiplier).round());
    }
    final moves =
        (raw['skillMoves'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    return _EnemyMember(
      key: 'enemy_$index',
      enemyId: id,
      displayName: displayName,
      data: data,
      maxHealth: maxHealth,
      damage: damage,
      guile: (raw['guile'] as num?)?.toInt() ?? 0,
      hasReactiveMoves:
          moves.any((m) => m['condition']?.toString() == 'OnHitByElement'),
      currentHealth: maxHealth,
      affixes: affixes,
    )..phases = parseBossPhases(raw);
  }

  /// Builds [_party] (the player plus every currently-active ally) once
  /// every data source it needs has loaded. Idempotent — a rebuild
  /// triggered by an unrelated provider change is a no-op past the first
  /// successful call, since mid-fight party state (health, block) lives
  /// only here from that point on, not in the providers being watched.
  void _ensurePartyBuilt(
    PlayerSession session,
    Map<String, dynamic> companions,
    Map<String, dynamic> races,
    Map<String, dynamic> professions,
    Map<String, dynamic> gameConfig,
    Map<String, dynamic> items,
    Map<String, ItemSet> itemSets,
    Map<String, dynamic> houses,
  ) {
    if (_partyBuilt) return;
    _partyBuilt = true;
    _companions = companions;
    _alignmentLabel = session.alignmentLabel;
    _partyBonus = partyBonusFor(
      bossDefeatCounts: session.bossDefeatCounts,
      enemyIds: [for (final e in _enemies) e.enemyId],
      builtHouseIds: session.builtHouseIds,
      houses: houses,
    );

    final playerDiceAssignments =
        session.diceSkillAssignments[_selectedDiceId] ??
            const <String, String>{};
    final playerLabel = session.characterName.isNotEmpty
        ? session.characterName
        : trFor(ref.read(appLanguageProvider), 'you_label');
    final player = _PartyMember(
      id: 'player',
      displayName: playerLabel,
      isPlayer: true,
      maxHealth: _partyBonus.scaleMaxHealth(session.maxHealth),
      baseDamage: _partyBonus.scaleDamage(session.baseDamage),
      armor: session.baseArmor,
      currentHealth: _partyBonus.scaleCurrentHealth(session.currentHealth > 0
          ? session.currentHealth
          : session.maxHealth),
      equippedItemIds: session.equippedItemIds,
      unlockedSkillIds: session.unlockedSkillIds,
      diceSkillAssignments: playerDiceAssignments,
      equippedDiceId: _selectedDiceId,
      skillTiers: session.skillTiers,
      strength: session.strength,
      dexterity: session.dexterity,
      constitution: session.constitution,
      intelligence: session.intelligence,
      wisdom: session.wisdom,
      luck: session.luck,
      perception: session.perception,
      gear: gearEffectsFor(session.equippedItemIds, items, itemSets),
    );

    final activeAllies = <_PartyMember>[];
    for (final companionId in session.activeAllyIds) {
      final companion = companions[companionId] as Map<String, dynamic>?;
      if (companion == null) continue;
      final allyState = session.recruitedAllies.firstWhere(
        (a) => a.companionId == companionId,
        orElse: () => AllyState(
            companionId: companionId,
            currentHealth: AllyState.fullHealthSentinel),
      );
      final race = races[companion['raceId']?.toString() ?? '']
              as Map<String, dynamic>? ??
          const {};
      final profession =
          professions[companion['professionId']?.toString() ?? '']
                  as Map<String, dynamic>? ??
              const {};
      final base = deriveAllyBaseStats(
          gameConfig: gameConfig, race: race, profession: profession);
      final liveMaxHealth = _partyBonus
          .scaleMaxHealth(scaledMaxHealth(base.maxHealth, _playerLevel));
      activeAllies.add(_PartyMember(
        id: companionId,
        displayName: companion['companionName']?.toString() ?? companionId,
        isPlayer: false,
        maxHealth: liveMaxHealth,
        baseDamage: _partyBonus
            .scaleDamage(scaledDamage(base.baseDamage, _playerLevel)),
        armor: base.baseArmor,
        currentHealth: _partyBonus
            .scaleCurrentHealth(allyState.currentHealth)
            .clamp(0, liveMaxHealth),
        equippedItemIds: allyState.equippedItemIds,
        unlockedSkillIds: allyState.unlockedSkillIds,
        diceSkillAssignments: allyState.diceSkillAssignments,
        equippedDiceId: companion['signatureDiceId']?.toString(),
        strength: base.strength,
        dexterity: base.dexterity,
        constitution: base.constitution,
        intelligence: base.intelligence,
        wisdom: base.wisdom,
        luck: base.luck,
        perception: base.perception,
        gear: gearEffectsFor(allyState.equippedItemIds, items, itemSets),
      ));
    }

    _party = [player, ...activeAllies];
  }

  /// A log line's actor prefix — only shown once there's more than one
  /// combatant on the player's side, so a solo player (the common case
  /// through most of the game, before any ally is both recruited and
  /// active) sees the exact same unprefixed log this screen always had.
  String _actorPrefix(_PartyMember actor) =>
      _party.length > 1 ? '${actor.displayName}: ' : '';

  /// The highest Perception among currently-conscious party members — feeds
  /// [telegraphTierFor] for every enemy's telegraph badge. A
  /// Perception-built ally can carry the party's tactical read even if the
  /// player's own Perception is low.
  int _bestPartyPerception() {
    var best = 0;
    for (final member in _party) {
      if (member.isKnockedOut) continue;
      if (member.perception > best) best = member.perception;
    }
    return best;
  }

  /// The telegraph tier the party actually reads [enemy] at this round --
  /// [telegraphTierFor] off the party's best Perception, one step worse
  /// under a Dark battlefield, and nothing at all during an Ambush's
  /// opening round.
  TelegraphTier _effectiveTierFor(_EnemyMember enemy) {
    if (_condition == BattlefieldCondition.ambush && _roundsStarted <= 1) {
      return TelegraphTier.none;
    }
    final tier = telegraphTierFor(_bestPartyPerception(), enemy.guile);
    return _condition == BattlefieldCondition.dark ? darkenedTier(tier) : tier;
  }

  /// Records whether any living enemy reads at the full tier right now --
  /// the spoils chest's Perception extra slot.
  void _noteTelegraphReads() {
    for (final enemy in _enemies) {
      if (!enemy.isAlive || enemy.pendingMove == null) continue;
      if (_effectiveTierFor(enemy) == TelegraphTier.full) {
        _fullTelegraphRead = true;
      }
    }
  }

  /// True when some living enemy's pre-rolled next move is aimed at
  /// [member] AND the party can currently read that telegraph at all (see
  /// [_effectiveTierFor]) -- the condition under which a Defend face rolled
  /// by [member] braces for the visible blow ([_telegraphBraceMultiplier]).
  bool _isTelegraphedTarget(_PartyMember member) {
    for (final enemy in _enemies) {
      final pending = enemy.pendingMove;
      if (!enemy.isAlive || pending == null || pending.targetId != member.id) {
        continue;
      }
      if (_effectiveTierFor(enemy) != TelegraphTier.none) {
        return true;
      }
    }
    return false;
  }

  _PartyMember? _memberById(String id) {
    for (final member in _party) {
      if (member.id == id) return member;
    }
    return null;
  }

  /// A member's attack damage behind [face]: base, equipment, stat
  /// scaling, alignment gear, unique/set gear and the face's element
  /// bonus. The one formula [_confirmRoll], [_previewRoll] and the face
  /// sheet all use, so a number shown is a number dealt.
  int _totalDamageFor(
    _PartyMember actor,
    DiceFaceResult face,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
  ) {
    final availableSkills = _availableSkillsFor(actor, skills);
    final element = _elementFor(face, availableSkills);
    final elementalBonus =
        _elementalDamageBonus(element, actor.equippedItemIds, items);
    final scalingBonus = equipmentScalingBonusFor(
      actor.equippedItemIds,
      items,
      strength: actor.strength,
      dexterity: actor.dexterity,
      constitution: actor.constitution,
      intelligence: actor.intelligence,
    );
    final alignedBonus =
        alignmentGearBonusFor(actor.equippedItemIds, items, _alignmentLabel);
    return actor.baseDamage +
        equipmentBonusFor(actor.equippedItemIds, items, 'attackDamage') +
        scalingBonus.damageBonus +
        alignedBonus.damageBonus +
        actor.gear.attackDamage +
        elementalBonus;
  }

  /// The enemy a strike by [actor] lands on if confirmed now: the only
  /// enemy in a solo fight, the aimed one in a pack, or the first still
  /// standing when the aimed one has gone down (the same redirect
  /// [_confirmRoll] makes). Null when nothing is left to hit.
  _EnemyMember? _strikeTargetFor(_PartyMember actor) {
    if (_enemies.length == 1) {
      return _enemies.first.isAlive ? _enemies.first : null;
    }
    final key = _selectedTargets[actor.id];
    final picked = key == null ? null : _enemyByKey(key);
    if (picked != null && picked.isAlive) return picked;
    return _firstLivingEnemy();
  }

  /// Every acting member's [_FacePreview] for the faces on the table,
  /// keyed by member id: empty while the dice are still spinning. Walks
  /// the party in the confirm's own order so the momentum surge lands on
  /// the same strike it will land on.
  Map<String, _FacePreview> _previewRoll(
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
    AppLanguage lang,
  ) {
    final previews = <String, _FacePreview>{};
    if (_rolling) return previews;
    var surgeArmed = _momentum >= _momentumThreshold;
    for (final actor in _actingParty) {
      final face = _currentFaces[actor.id];
      if (face == null) continue;
      final isStrike = face.type == 'Attack' || face.type == 'Skill';
      final surge = isStrike && surgeArmed;
      if (surge) surgeArmed = false;
      final result = resolvePlayerFace(
        face,
        _availableSkillsFor(actor, skills),
        _totalDamageFor(actor, face, skills, items),
        language: lang,
        activeEffects: actor.statusEffects,
        wisdomHealBonus: actor.wisdom ~/ 2,
        forceCritical: surge,
        alignmentLabel: _alignmentLabel,
      );
      final target = isStrike ? _strikeTargetFor(actor) : null;
      final damage = target == null
          ? result.damageDealt
          : strikeDamageAfterAffixes(result.damageDealt, face.type,
              armored: target.hasAffix(EnemyAffix.armored));
      var healing = result.healingDone;
      if (_condition == BattlefieldCondition.shrine && healing > 0) {
        healing = (healing * shrineHealMultiplier).round();
      }
      var block = result.blockAmount;
      if (block > 0 && _isTelegraphedTarget(actor)) {
        block *= _telegraphBraceMultiplier;
      }
      if (_condition == BattlefieldCondition.highGround && block > 0) {
        block = (block * highGroundBlockMultiplier).round();
      }
      previews[actor.id] = _FacePreview(
        result: result,
        target: target,
        damage: damage,
        healing: healing,
        block: block,
        surge: surge,
      );
    }
    return previews;
  }

  _EnemyMember? _enemyByKey(String key) {
    for (final enemy in _enemies) {
      if (enemy.key == key) return enemy;
    }
    return null;
  }

  _EnemyMember? _firstLivingEnemy() {
    for (final enemy in _enemies) {
      if (enemy.isAlive) return enemy;
    }
    return null;
  }

  /// A single display string naming every enemy in this fight — the
  /// enemy's own name for a solo fight (unchanged from before packs
  /// existed), or every distinct name in the pack joined together, each
  /// prefixed with a "Nx " count when it appears more than once (e.g. "2x
  /// Harbor Rat, Dock Overseer").
  String _battleTitle() {
    if (_enemies.length == 1) {
      return _enemies.first.data['enemyName']?.toString() ??
          _enemies.first.enemyId;
    }
    final counts = <String, int>{};
    final order = <String>[];
    for (final enemy in _enemies) {
      final name = enemy.data['enemyName']?.toString() ?? enemy.enemyId;
      if (!counts.containsKey(name)) order.add(name);
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return order
        .map(
            (name) => (counts[name] ?? 1) > 1 ? '${counts[name]}x $name' : name)
        .join(', ');
  }

  /// Rolls [_banterChance] for a random active, still-conscious ally
  /// (other than [excludeId], so nobody reacts to their own crit, dodge or
  /// knockout) to say a short line from their own companions.json banter
  /// fields for [kind] — null whenever there's simply nobody around to
  /// react (a solo player, or every ally already knocked out), the line
  /// rolled against and missed, or the chosen companion has no line
  /// authored for this language/moment.
  _LogEntry? _rollBanter({required _BanterKind kind, String? excludeId}) {
    final candidates = _party
        .where((m) => !m.isPlayer && !m.isKnockedOut && m.id != excludeId)
        .toList();
    if (candidates.isEmpty || _random.nextDouble() >= _banterChance) {
      return null;
    }
    final speaker = candidates[_random.nextInt(candidates.length)];
    final companion = _companions[speaker.id] as Map<String, dynamic>?;
    if (companion == null) return null;
    final lang = ref.read(appLanguageProvider);
    final line = companion[_banterFieldFor(kind, lang)]?.toString();
    if (line == null || line.isEmpty) return null;
    return _LogEntry('${speaker.displayName}: "$line"', _LogKind.banter);
  }

  void _startFight(Map<String, dynamic> skills, Map<String, dynamic> items) {
    final lang = ref.read(appLanguageProvider);
    for (final enemy in _enemies) {
      _preRollMoveFor(enemy, skills);
    }
    _applyArmedCharms(items);
    final hpSuffix = _enemies.length == 1
        ? ' ${trFor(lang, 'has_label')} ${_enemies.first.maxHealth} ${trFor(lang, 'hp_label')}'
        : '';
    final condition = _condition;
    final banter = _rollBanter(
        kind: _enemies.length > 1 ? _BanterKind.pack : _BanterKind.fightStart);
    setState(() {
      _started = true;
      _roundsStarted = 1;
      _log.add(
        _LogEntry(
          '${trFor(lang, 'fight_begins_prefix')} ${_battleTitle()}$hpSuffix.',
          _LogKind.info,
        ),
      );
      if (condition != null) {
        _log.add(_LogEntry(
          '${trFor(lang, conditionLabelKey(condition))}: '
          '${trFor(lang, conditionDescriptionKey(condition))}',
          _LogKind.info,
        ));
      }
      for (final id in _armedCharmIds) {
        final name =
            (items[id] as Map<String, dynamic>?)?['itemName']?.toString() ?? id;
        _log.add(_LogEntry(
            '${trFor(lang, 'charm_used_prefix')} $name', _LogKind.playerHeal));
      }
      if (banter != null) _log.add(banter);
    });
    _noteTelegraphReads();
    if (condition == BattlefieldCondition.ambush) {
      // The enemies strike before the party's first roll; the party round
      // that follows is the opening one, so nothing reads off them yet.
      _roundsStarted = 0;
      _takeEnemyTurn(skills, items);
    }
  }

  /// Burns every charm picked on the setup screen and arms its one-fight
  /// effect (see items.json's Charm-type items).
  void _applyArmedCharms(Map<String, dynamic> items) {
    if (_armedCharmIds.isEmpty) return;
    for (final id in _armedCharmIds) {
      switch (id) {
        case 'charm_fourth_roll':
          _maxRollsThisFight = _maxRolls + 1;
        case 'charm_lucky_coin':
          _luckyCoinArmed = true;
        case 'charm_iron_skin':
          _ironSkinArmed = true;
        case 'charm_warding':
          _wardingCharges = 1;
      }
    }
    ref
        .read(playerSessionProvider.notifier)
        .consumeInventoryItems(_armedCharmIds.toList());
  }

  Map<String, dynamic> _availableSkillsFor(
      _PartyMember actor, Map<String, dynamic> skills) {
    return <String, dynamic>{
      for (final entry in skills.entries)
        if (((entry.value as Map<String, dynamic>)['isUnlocked'] as bool? ??
                false) ||
            actor.unlockedSkillIds.contains(entry.key))
          entry.key: applySkillTier(
            entry.value as Map<String, dynamic>,
            actor.skillTiers[entry.key] ?? 0,
          ),
    };
  }

  /// Every party member able to act this round — conscious, and not
  /// currently Stunned (see status_effect.dart; a stunned member is
  /// skipped for the round entirely, announced in [_startPartyRound]).
  List<_PartyMember> get _actingParty => _party
      .where((m) => !m.isKnockedOut && !isStunned(m.statusEffects))
      .toList();

  /// Rolls a die for every acting party member at once — one face per
  /// member, shown side by side — instead of each combatant taking a
  /// separate sequential turn. The first roll of a round just shows its
  /// results and waits for a keep/reroll decision (see [_confirmRoll]); the
  /// 3rd roll is forced — there's no more choice left, so it locks in and
  /// resolves automatically after a beat.
  Future<void> _rollDice(
    Map<String, dynamic> diceDb,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
  ) async {
    if (_over || _rolling || _rollCount >= _maxRollsThisFight) return;
    final acting = _actingParty;

    final rolled = <String, DiceFaceResult>{};
    final isReroll = _rollCount > 0;
    for (final actor in acting) {
      // A die kept (locked) through a reroll shows its current face again.
      if (isReroll && _lockedActorIds.contains(actor.id)) {
        final kept = _currentFaces[actor.id];
        if (kept != null) rolled[actor.id] = kept;
        continue;
      }
      final actorDice = actor.equippedDiceId != null
          ? diceDb[actor.equippedDiceId] as Map<String, dynamic>?
          : null;
      final faces =
          (actorDice?['faces'] as List?)?.cast<Map<String, dynamic>>() ??
              const [];
      if (faces.isEmpty) continue;

      var face = rollDie(faces, _random);
      if (face.type == 'Skill') {
        final assigned = actor.diceSkillAssignments[face.faceIndex.toString()];
        if (assigned != null && assigned.isNotEmpty) {
          face = face.withLinkedSkillID(assigned);
        }
      }
      rolled[actor.id] = face;
    }
    if (rolled.isEmpty) return;

    setState(() => _rolling = true);
    await _rollController.forward(from: 0);
    if (!mounted) return;

    final rollNumber = _rollCount + 1;
    final forced = rollNumber >= _maxRollsThisFight;
    setState(() {
      _rolling = false;
      _rollCount = rollNumber;
      _currentFaces
        ..clear()
        ..addAll(rolled);
      _awaitingDecision = !forced;
      _autoAssignTargets();
    });

    if (forced) {
      // No choice left — give the player a beat to see the 3rd faces land
      // before they resolve on their own.
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      await _confirmRoll(skills, items);
    }
  }

  /// Aims every acting member's Attack/Skill face at the first living enemy
  /// unless they already picked one still standing -- a roll is never
  /// blocked on a pick; the enemy column is where a pick is changed. Also
  /// keeps [_selectedActorId] on a member who has something to aim.
  void _autoAssignTargets() {
    if (_enemies.length <= 1) return;
    for (final actor in _actingParty) {
      final face = _currentFaces[actor.id];
      if (face == null || !(face.type == 'Attack' || face.type == 'Skill')) {
        _selectedTargets.remove(actor.id);
        continue;
      }
      if (_companionsAutoAim && !actor.isPlayer) {
        final focus = _focusTargetFor();
        if (focus != null) _selectedTargets[actor.id] = focus.key;
        continue;
      }
      final current = _selectedTargets[actor.id];
      final picked = current == null ? null : _enemyByKey(current);
      if (picked != null && picked.isAlive) continue;
      final fallback = _firstLivingEnemy();
      if (fallback != null) _selectedTargets[actor.id] = fallback.key;
    }
    final selected = _selectedActorId;
    if (selected == null ||
        !_selectedTargets.containsKey(selected) ||
        (_companionsAutoAim && selected != 'player')) {
      _selectedActorId = _selectedTargets.containsKey('player')
          ? 'player'
          : _companionsAutoAim || _selectedTargets.isEmpty
              ? null
              : _selectedTargets.keys.first;
    }
  }

  /// Where an auto-aiming companion strikes (see
  /// [companionAutoTargetProvider]): the enemy the player is aiming at, so
  /// the party focuses fire, else the living enemy closest to going down.
  _EnemyMember? _focusTargetFor() {
    final playerPick = _selectedTargets['player'];
    final picked = playerPick == null ? null : _enemyByKey(playerPick);
    if (picked != null && picked.isAlive) return picked;
    _EnemyMember? weakest;
    for (final enemy in _enemies) {
      if (!enemy.isAlive) continue;
      if (weakest == null || enemy.currentHealth < weakest.currentHealth) {
        weakest = enemy;
      }
    }
    return weakest;
  }

  /// True once every acting member currently showing an Attack/Skill face
  /// has picked a target — always true for a solo fight (nothing to pick),
  /// used to gate the Confirm button when `_enemies.length > 1` so a roll
  /// can never resolve against an unset target.
  bool get _allTargetsPicked {
    if (_enemies.length <= 1) return true;
    for (final actor in _actingParty) {
      final face = _currentFaces[actor.id];
      if (face == null) continue;
      if ((face.type == 'Attack' || face.type == 'Skill') &&
          !_selectedTargets.containsKey(actor.id)) {
        return false;
      }
    }
    return true;
  }

  /// Locks in every acting member's currently-shown rolled face and applies
  /// all of their effects together, whether by tapping Confirm or the 3rd
  /// roll forcing it — then, once at least one enemy still stands, hands
  /// the turn straight to them (there's no more per-member turn order to
  /// advance through).
  Future<void> _confirmRoll(
      Map<String, dynamic> skills, Map<String, dynamic> items) async {
    if (_currentFaces.isEmpty || _over) return;
    final lang = ref.read(appLanguageProvider);

    // Safety-net backfill for the forced-3rd-roll path (no player input is
    // possible there) -- picks the first living enemy so a roll can never
    // silently miss for lack of a target.
    if (_enemies.length > 1) {
      for (final actor in _actingParty) {
        final face = _currentFaces[actor.id];
        if (face == null) continue;
        if ((face.type == 'Attack' || face.type == 'Skill') &&
            !_selectedTargets.containsKey(actor.id)) {
          final fallback = _firstLivingEnemy() ?? _enemies.first;
          _selectedTargets[actor.id] = fallback.key;
        }
      }
    }

    for (final enemy in _enemies) {
      enemy.elementsHitThisRound = {};
    }

    final newEntries = <_LogEntry>[];
    String? lastCritActorId;
    String? lastDamagedEnemyKey;
    var lastEnemyDamage = 0;
    var hitsLanded = 0;
    var manaGained = 0;
    for (final actor in _actingParty) {
      final face = _currentFaces[actor.id];
      if (face == null) continue;

      final availableSkills = _availableSkillsFor(actor, skills);
      final element = _elementFor(face, availableSkills);
      final totalDamage = _totalDamageFor(actor, face, skills, items);
      final isStrike = face.type == 'Attack' || face.type == 'Skill';
      // Momentum: the built-up hits cash in as a guaranteed critical on
      // this strike, and the counter starts over from it.
      final surge = isStrike && _momentum >= _momentumThreshold;
      if (surge) _momentum = 0;
      final result = resolvePlayerFace(
        face,
        availableSkills,
        totalDamage,
        language: lang,
        activeEffects: actor.statusEffects,
        wisdomHealBonus: actor.wisdom ~/ 2,
        luck: actor.luck +
            (actor.isPlayer && _luckyCoinArmed ? _luckyCoinLuckBonus : 0),
        random: _random,
        forceCritical: surge,
        alignmentLabel: _alignmentLabel,
        critChanceBonus: actor.gear.critChance,
      );
      var healing = result.healingDone;
      if (_condition == BattlefieldCondition.shrine && healing > 0) {
        healing = (healing * shrineHealMultiplier).round();
      }
      final kind = result.damageDealt > 0
          ? _LogKind.playerDamage
          : healing > 0
              ? _LogKind.playerHeal
              : result.blockAmount > 0
                  ? _LogKind.playerBlock
                  : result.manaGained > 0
                      ? _LogKind.mana
                      : _LogKind.info;

      if (result.isCritical) lastCritActorId = actor.id;
      // Any member's Mana face feeds the one shared pool.
      if (result.manaGained > 0) manaGained += result.manaGained;
      actor.currentHealth = min(actor.maxHealth, actor.currentHealth + healing);
      final braced = result.blockAmount > 0 && _isTelegraphedTarget(actor);
      var block = braced
          ? result.blockAmount * _telegraphBraceMultiplier
          : result.blockAmount;
      if (_condition == BattlefieldCondition.highGround && block > 0) {
        block = (block * highGroundBlockMultiplier).round();
      }
      // A spell's block this round (Mana Ward, War Shout) stacks under the
      // face's own -- see [_spellBlock].
      actor.block = block + (_spellBlock[actor.id] ?? 0);
      newEntries
          .add(_LogEntry('${_actorPrefix(actor)}${result.message}', kind));
      if (surge) {
        newEntries.add(_LogEntry(
            trFor(lang, 'momentum_surge_message'), _LogKind.playerDamage));
      }
      if (braced) {
        newEntries.add(_LogEntry(
          '${actor.displayName} ${trFor(lang, 'braced_suffix')} (${actor.block})',
          _LogKind.playerBlock,
        ));
      }

      _EnemyMember? target;
      var redirected = false;
      if (isStrike) {
        target = _strikeTargetFor(actor);
        // The picked enemy went down to an earlier hit this same round --
        // the blow carries on to the next one standing rather than
        // vanishing into a corpse while the log claims a hit.
        final key = _selectedTargets[actor.id];
        final picked = key == null ? null : _enemyByKey(key);
        redirected = _enemies.length > 1 &&
            target != null &&
            (picked == null || !picked.isAlive);
      }

      if (redirected && target != null) {
        newEntries.add(_LogEntry(
          '${trFor(lang, 'redirected_hit_prefix')} ${target.displayName}',
          _LogKind.info,
        ));
      }

      if (target != null) {
        final armored = target.hasAffix(EnemyAffix.armored);
        final damage = strikeDamageAfterAffixes(result.damageDealt, face.type,
            armored: armored);
        if (result.damageDealt > 0 && face.type == 'Attack' && armored) {
          newEntries.add(_LogEntry(
            '${target.displayName} ${trFor(lang, 'armored_absorbs_suffix')}',
            _LogKind.info,
          ));
        }
        final wasAlive = target.isAlive;
        target.currentHealth = max(0, target.currentHealth - damage);
        if (damage > 0) {
          lastDamagedEnemyKey = target.key;
          lastEnemyDamage = damage;
          hitsLanded++;
          // Lifesteal (a Bloodthorn Blade, the full Hollow Court set) and
          // mana on hit (a Siphon Wand) pay out per landed hit.
          final drained = actor.gear.lifestealFor(damage);
          if (drained > 0 && actor.currentHealth < actor.maxHealth) {
            actor.currentHealth =
                min(actor.maxHealth, actor.currentHealth + drained);
            newEntries.add(_LogEntry(
              '${actor.displayName} ${trFor(lang, 'lifesteal_suffix')} '
              '$drained ${trFor(lang, 'hp_label')}.',
              _LogKind.playerHeal,
            ));
          }
          if (actor.gear.manaOnHit > 0) manaGained += actor.gear.manaOnHit;
        }
        if (wasAlive && !target.isAlive) {
          _lastKillWasCritical = result.isCritical;
        }
        if (element != 'None' && damage > 0) {
          target.elementsHitThisRound.add(element);
        }
        final inflicted = result.inflictedStatus;
        if (inflicted != null) {
          target.statusEffects = applyStatusEffect(
            target.statusEffects,
            inflicted,
          );
          newEntries.add(_LogEntry(
            _statusInflictedMessage(inflicted, target.displayName, lang),
            _LogKind.info,
          ));
        }
      }
    }

    _advanceBossPhases(newEntries, lang, skills);

    if (hitsLanded > 0) {
      final before = _momentum;
      _momentum = min(_momentumThreshold, _momentum + hitsLanded);
      if (before < _momentumThreshold && _momentum >= _momentumThreshold) {
        newEntries.add(
            _LogEntry(trFor(lang, 'momentum_ready_message'), _LogKind.info));
      }
    }

    // Each acting member's own effects count down once their turn is over
    // (see tickStatusEffects) -- ticking at the start of the round instead
    // silently ate the first (and, under Wisdom resistance, only) turn of
    // every Weaken landed on the party.
    for (final actor in _actingParty) {
      actor.statusEffects = tickStatusEffects(actor.statusEffects);
    }

    if (lastCritActorId != null) {
      final banter =
          _rollBanter(kind: _BanterKind.crit, excludeId: lastCritActorId);
      if (banter != null) newEntries.add(banter);
    }

    if (manaGained > 0) {
      _mana = min(_maxMana, _mana + manaGained);
      ref.read(playerSessionProvider.notifier).setMana(_mana);
    }

    _noteSkittishFlights(newEntries, lang);

    setState(() {
      _awaitingDecision = false;
      _rollCount = 0;
      _currentFaces.clear();
      _selectedTargets.clear();
      _lockedActorIds.clear();
      _selectedActorId = null;
      if (lastDamagedEnemyKey != null) {
        _lastDamagedEnemyKey = lastDamagedEnemyKey;
        _lastEnemyDamageTaken = lastEnemyDamage;
      }
      _log.addAll(newEntries);
    });

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    if (_enemies.every((e) => !e.isAlive)) {
      _finishFight(won: true);
      return;
    }

    _takeEnemyTurn(skills, items);
  }

  /// A Skittish enemy that's been hurt enough runs for it -- out of the
  /// fight, but taking part of its share of the spoils with it. Checked
  /// after every party action that can hurt one: a confirmed roll and a
  /// cast spell.
  void _noteSkittishFlights(List<_LogEntry> entries, AppLanguage lang) {
    for (final enemy in _enemies) {
      if (!enemy.isAlive || !enemy.hasAffix(EnemyAffix.skittish)) continue;
      if (enemy.currentHealth < enemy.maxHealth * skittishFleeThreshold) {
        enemy.fled = true;
        enemy.currentHealth = 0;
        entries.add(_LogEntry(
          '${enemy.displayName} ${trFor(lang, 'flees_suffix')}',
          _LogKind.info,
        ));
      }
    }
  }

  /// Starts a fresh party round — called once every enemy's turn resolves
  /// without ending the fight. This is also where every still-conscious
  /// party member's own status effects take hold for the round about to
  /// start: Poison ticks its damage and Stun determines who's excluded from
  /// [_actingParty]. A stunned member's effects count down here (the stun
  /// consumed their turn); everyone else's count down once they've actually
  /// acted, in [_confirmRoll]. If nobody is able to act at all, the round is
  /// skipped straight through to the enemies' next turn rather than
  /// stalling on a roll nobody can make.
  void _startPartyRound(
      Map<String, dynamic> skills, Map<String, dynamic> items) {
    final lang = ref.read(appLanguageProvider);
    final newEntries = <_LogEntry>[];
    var playerDied = false;
    _roundsStarted++;

    for (final member in _party) {
      if (member.isKnockedOut) continue;
      final poison = poisonDamageFor(member.statusEffects);
      if (poison > 0) {
        member.currentHealth = max(0, member.currentHealth - poison);
        newEntries.add(_LogEntry(
          member.isPlayer
              ? '${trFor(lang, 'you_take_damage_prefix')} $poison '
                  '${trFor(lang, 'damage_word')} ${trFor(lang, 'from_poison_suffix')}.'
              : '${member.displayName} ${trFor(lang, 'takes_damage_word')} '
                  '$poison ${trFor(lang, 'damage_word')} ${trFor(lang, 'from_poison_suffix')}.',
          _LogKind.enemyDamage,
        ));
        if (member.isKnockedOut) {
          if (member.isPlayer) {
            playerDied = true;
          } else {
            _anyKnockedOut = true;
            _lastKnockedOutAllyName = member.displayName;
            newEntries.add(_LogEntry(
              '${member.displayName} ${trFor(lang, 'is_knocked_out_suffix')}',
              _LogKind.defeat,
            ));
            final banter =
                _rollBanter(kind: _BanterKind.ko, excludeId: member.id);
            if (banter != null) newEntries.add(banter);
          }
        }
      }
      if (!member.isKnockedOut && isStunned(member.statusEffects)) {
        newEntries.add(_LogEntry(
          '${member.displayName} ${trFor(lang, 'stunned_skip_turn_suffix')}',
          _LogKind.info,
        ));
      }
    }

    // Snapshot before ticking — a member stunned this round must still be
    // excluded from acting this round even though the same tick below may
    // expire that very stun for the round after.
    final canAct = _actingParty.isNotEmpty;

    for (final member in _party) {
      if (member.isKnockedOut || !isStunned(member.statusEffects)) continue;
      member.statusEffects = tickStatusEffects(member.statusEffects);
    }

    // A telegraph is a promise about WHO gets hit -- if poison just took
    // that member down, re-aim the cached move now so the badge never names
    // someone who's already out (the move itself is untouched).
    final conscious = _party.where((m) => !m.isKnockedOut).toList();
    if (conscious.isNotEmpty) {
      for (final enemy in _enemies) {
        final pending = enemy.pendingMove;
        if (pending == null || !enemy.isAlive) continue;
        final cachedTarget = _memberById(pending.targetId);
        if (cachedTarget != null && !cachedTarget.isKnockedOut) continue;
        enemy.pendingMove = _PendingEnemyMove(
          move: pending.move,
          targetId: conscious[_random.nextInt(conscious.length)].id,
        );
      }
    }
    _noteTelegraphReads();

    setState(() {
      _log.addAll(newEntries);
      _rollCount = 0;
      _currentFaces.clear();
      _selectedTargets.clear();
      _lockedActorIds.clear();
      _spellBlock.clear();
      _selectedActorId = null;
      _awaitingDecision = false;
      // A fresh round with nothing hit yet on any enemy — otherwise a
      // round skipped outright below (nobody able to act) would hand
      // _takeEnemyTurn last round's stale hits, letting an
      // OnHitByElement reaction fire again for an element nobody
      // actually struck with this round.
      for (final enemy in _enemies) {
        enemy.elementsHitThisRound = {};
      }
    });

    if (playerDied) {
      _finishFight(won: false);
      return;
    }

    if (!canAct) {
      _takeEnemyTurn(skills, items);
    }
  }

  /// Pre-rolls and caches [enemy]'s move+target for its NEXT turn -- called
  /// once per enemy at fight start (see [_startFight]), and again after
  /// every enemy-turn-phase resolves (see [_takeEnemyTurn]), so the
  /// upcoming party round can show a Perception/Guile-gated preview of
  /// exactly what's coming. Deliberately skipped for a
  /// [_EnemyMember.hasReactiveMoves] enemy: pre-rolling immediately after
  /// its own turn would hand it the SAME elements-hit set that already
  /// justified that turn's OnHitByElement reaction, risking a stale
  /// double-fire on a hit that already fired -- rather than resolve that
  /// ambiguity, that one enemy (iron_golem is the only current example)
  /// simply isn't pre-rolled at all: it live-rolls at execution time
  /// exactly as every enemy did before telegraphing existed, and shows no
  /// telegraph.
  void _preRollMoveFor(_EnemyMember enemy, Map<String, dynamic> skills) {
    if (!enemy.isAlive || enemy.hasReactiveMoves) {
      enemy.pendingMove = null;
      return;
    }
    enemy.pendingMove = _rollMoveAndTargetFor(enemy, skills);
  }

  /// Plays every boss phase a living enemy has crossed since the last
  /// check (see [bossPhaseIndexFor]): the transition's heal, cleanse and
  /// enrage apply at once, its new moves join the enemy's list, and the
  /// enemy's telegraphed move is re-rolled so the new stance shows on its
  /// very next turn. Appends each announcement to [entries].
  void _advanceBossPhases(
      List<_LogEntry> entries, AppLanguage lang, Map<String, dynamic> skills) {
    for (final enemy in _enemies) {
      if (!enemy.isAlive || enemy.phases.isEmpty) continue;
      final target =
          bossPhaseIndexFor(enemy.phases, enemy.currentHealth, enemy.maxHealth);
      var entered = false;
      while (enemy.phaseIndex < target) {
        final phase = enemy.phases[enemy.phaseIndex];
        enemy.phaseIndex++;
        entered = true;
        _phasesCrossed++;
        final healed =
            healthAfterPhaseHeal(phase, enemy.currentHealth, enemy.maxHealth) -
                enemy.currentHealth;
        enemy.currentHealth += healed;
        if (phase.cleanse) enemy.statusEffects = [];
        enemy.damage = (enemy.damage * phase.damageMultiplier).round();
        enemy.data = enemyDataInPhase(enemy.data, phase);
        final details = <String>[
          if (healed > 0)
            '${trFor(lang, 'phase_heals_prefix')} $healed ${trFor(lang, 'hp_label')}',
          if (phase.cleanse) trFor(lang, 'phase_cleansed_label'),
          if (phase.damageMultiplier > 1.0) trFor(lang, 'phase_enraged_label'),
        ];
        entries.add(_LogEntry(
          '${enemy.displayName} — ${phase.nameFor(lang)}: '
          '${phase.messageFor(lang)}'
          '${details.isEmpty ? '' : ' (${details.join(', ')})'}',
          _LogKind.phase,
        ));
      }
      if (entered) _preRollMoveFor(enemy, skills);
    }
  }

  /// [_advanceBossPhases] straight into the log, for the enemy-turn
  /// paths that write the log as they go.
  void _advancePhasesNow(AppLanguage lang, Map<String, dynamic> skills) {
    final entries = <_LogEntry>[];
    _advanceBossPhases(entries, lang, skills);
    if (entries.isEmpty) return;
    setState(() => _log.addAll(entries));
  }

  /// Rolls [enemy]'s move+target — shared by [_preRollMoveFor] (ahead of
  /// time) and [_takeEnemyTurn] (live, for a [_EnemyMember.hasReactiveMoves]
  /// enemy that's never pre-rolled). Reads [_EnemyMember.elementsHitThisRound]
  /// as of the moment it's called, so calling it live at execution time
  /// (rather than ahead of time) is exactly what every enemy did before
  /// pre-rolling existed.
  _PendingEnemyMove _rollMoveAndTargetFor(
      _EnemyMember enemy, Map<String, dynamic> skills) {
    final lang = ref.read(appLanguageProvider);
    // Rolled un-Weakened: a Weaken is applied at execution time in
    // [_takeEnemyTurn] against the enemy's effects as they stand THEN, so a
    // Weaken the party lands this round cuts the very next hit rather than
    // the one after (a pre-rolled move baked the debuff in a turn late).
    final move = resolveEnemyMove(
      enemy: {...enemy.data, 'damage': enemy.damage},
      skills: skills,
      enemyCurrentHealth: enemy.currentHealth,
      enemyMaxHealth: enemy.maxHealth,
      random: _random,
      language: lang,
      elementsHitThisRound: enemy.elementsHitThisRound,
    );
    final conscious = _party.where((m) => !m.isKnockedOut).toList();
    final targetId = conscious[_random.nextInt(conscious.length)].id;
    return _PendingEnemyMove(move: move, targetId: targetId);
  }

  /// Resolves every living enemy's turn once each, in [_enemies] order --
  /// each independently poison-ticks, checks its own Stun, then applies its
  /// own pre-rolled move (see [_preRollMoveFor]) against its own target,
  /// exactly mirroring how a solo enemy's single turn always worked, just
  /// looped once per pack member. An enemy with no cached
  /// [_EnemyMember.pendingMove] (a [_EnemyMember.hasReactiveMoves] enemy)
  /// rolls its move+target on the spot instead, exactly as every enemy did
  /// before telegraphing existed. A cached target that's no longer valid
  /// (knocked out since the roll, e.g. by an earlier enemy's turn this same
  /// phase) gets a fresh target pick without touching the move itself -- a
  /// pre-rolled move was already shown to the player as a promise, so only
  /// who it lands on is renegotiated. Affixes (Frenzied, Pack Leader,
  /// Venomous) and a Cramped battlefield shape the damage and who gets to
  /// swing at all.
  void _takeEnemyTurn(Map<String, dynamic> skills, Map<String, dynamic> items) {
    final lang = ref.read(appLanguageProvider);
    final leaderStanding =
        _enemies.any((e) => e.isAlive && e.hasAffix(EnemyAffix.packLeader));

    // Cramped: only so many enemies can reach the party each round; the
    // rest hold back, rotating so the same one isn't always the one waiting.
    var heldBack = <String>{};
    final living = _enemies.where((e) => e.isAlive).toList();
    if (_condition == BattlefieldCondition.cramped &&
        living.length > crampedMaxActingEnemies) {
      final offset = _roundsStarted % living.length;
      final rotated = [...living.skip(offset), ...living.take(offset)];
      heldBack =
          rotated.skip(crampedMaxActingEnemies).map((e) => e.key).toSet();
    }

    for (final enemy in _enemies) {
      if (!enemy.isAlive) continue;

      final poison = poisonDamageFor(enemy.statusEffects);
      if (poison > 0) {
        setState(() {
          enemy.currentHealth = max(0, enemy.currentHealth - poison);
          _log.add(_LogEntry(
            '${enemy.displayName} ${trFor(lang, 'takes_damage_word')} '
            '$poison ${trFor(lang, 'damage_word')} ${trFor(lang, 'from_poison_suffix')}.',
            _LogKind.playerDamage,
          ));
        });
        if (!enemy.isAlive) continue;
        _advancePhasesNow(lang, skills);
      }

      if (isStunned(enemy.statusEffects)) {
        setState(() {
          _log.add(_LogEntry(
            '${enemy.displayName} ${trFor(lang, 'stunned_skip_turn_suffix')}',
            _LogKind.info,
          ));
          enemy.statusEffects = tickStatusEffects(enemy.statusEffects);
        });
        continue;
      }

      if (heldBack.contains(enemy.key)) {
        setState(() {
          _log.add(_LogEntry(
            '${enemy.displayName} ${trFor(lang, 'holds_back_suffix')}',
            _LogKind.info,
          ));
          enemy.statusEffects = tickStatusEffects(enemy.statusEffects);
        });
        continue;
      }

      final pending = enemy.pendingMove ?? _rollMoveAndTargetFor(enemy, skills);
      final move = pending.move;
      var moveDamage = applyWeaken(move.damage, enemy.statusEffects);
      if (enemy.hasAffix(EnemyAffix.frenzied) &&
          enemy.currentHealth < enemy.maxHealth * frenziedHealthThreshold) {
        moveDamage = (moveDamage * frenziedDamageMultiplier).round();
      }
      if (leaderStanding && !enemy.hasAffix(EnemyAffix.packLeader)) {
        moveDamage = (moveDamage * packLeaderAllyDamageMultiplier).round();
      }

      final _PartyMember target;
      final cachedTarget = _memberById(pending.targetId);
      if (cachedTarget != null && !cachedTarget.isKnockedOut) {
        target = cachedTarget;
      } else {
        final conscious = _party.where((m) => !m.isKnockedOut).toList();
        target = conscious[_random.nextInt(conscious.length)];
      }

      final targetScalingBonus = equipmentScalingBonusFor(
        target.equippedItemIds,
        items,
        strength: target.strength,
        dexterity: target.dexterity,
        constitution: target.constitution,
        intelligence: target.intelligence,
      );
      final targetAlignedBonus =
          alignmentGearBonusFor(target.equippedItemIds, items, _alignmentLabel);
      final totalArmor = target.armor +
          equipmentBonusFor(target.equippedItemIds, items, 'armor') +
          targetScalingBonus.armorBonus +
          targetAlignedBonus.armorBonus +
          target.gear.armor +
          (target.isPlayer && _ironSkinArmed ? _ironSkinArmorBonus : 0);
      final elementalResist =
          _elementalResist(move.element, target.equippedItemIds, items);
      // A dodge evades the hit outright -- no damage, no status effect --
      // rather than just softening it further on top of block/armor/resist.
      final wasDodged = _random.nextDouble() * 100 <
          dodgeChanceFor(target.dexterity) + target.gear.dodgeChance;
      var damageTaken = wasDodged
          ? 0
          : max(0, moveDamage - target.block - totalArmor - elementalResist);
      // A Warding Knot swallows the first real hit on the player outright.
      var warded = false;
      if (damageTaken > 0 && target.isPlayer && _wardingCharges > 0) {
        _wardingCharges--;
        damageTaken = 0;
        warded = true;
      }
      // A Phoenix Sigil (see UniqueEffect.secondWind) turns one lethal
      // blow per fight into a 1 HP survival.
      var secondWind = false;
      if (damageTaken >= target.currentHealth &&
          target.currentHealth > 0 &&
          target.secondWindAvailable) {
        target.secondWindAvailable = false;
        damageTaken = target.currentHealth - 1;
        secondWind = true;
      }
      // Thorns (a Thornmail Hauberk, the Hollow Court set) cut whatever
      // actually connected.
      final thorns = damageTaken > 0 ? target.gear.thorns : 0;
      final wasKnockedOutAlready = target.isKnockedOut;
      final inflicted = move.inflictedStatus ??
          (enemy.hasAffix(EnemyAffix.venomous) ? _venomousPoison : null);

      setState(() {
        target.currentHealth = max(0, target.currentHealth - damageTaken);
        target.block = 0;
        _lastDamageTaken = damageTaken;
        _lastDamagedMemberId = target.id;
        if (damageTaken > 0) _momentum = 0;
        if (wasDodged) {
          _log.add(_LogEntry(
            target.isPlayer
                ? '${move.message} ${trFor(lang, 'you_dodge_suffix')}'
                : '${move.message} ${target.displayName} '
                    '${trFor(lang, 'dodges_suffix')}',
            _LogKind.playerBlock,
          ));
          final banter =
              _rollBanter(kind: _BanterKind.dodge, excludeId: target.id);
          if (banter != null) _log.add(banter);
        } else if (warded) {
          _log.add(_LogEntry(
            '${move.message} ${trFor(lang, 'warding_absorbs_message')}',
            _LogKind.playerBlock,
          ));
        } else {
          final damageLine = target.isPlayer
              ? '${move.message} ${trFor(lang, 'you_take_damage_prefix')} $damageTaken '
                  '${trFor(lang, 'damage_word')}.'
              : '${move.message} ${target.displayName} ${trFor(lang, 'takes_damage_word')} '
                  '$damageTaken ${trFor(lang, 'damage_word')}.';
          _log.add(
            _LogEntry(damageLine,
                damageTaken > 0 ? _LogKind.enemyDamage : _LogKind.playerBlock),
          );
          if (!target.isPlayer &&
              !wasKnockedOutAlready &&
              target.isKnockedOut) {
            _anyKnockedOut = true;
            _lastKnockedOutAllyName = target.displayName;
            _log.add(
              _LogEntry(
                '${target.displayName} ${trFor(lang, 'is_knocked_out_suffix')}',
                _LogKind.defeat,
              ),
            );
            final banter =
                _rollBanter(kind: _BanterKind.ko, excludeId: target.id);
            if (banter != null) _log.add(banter);
          }
          if (inflicted != null && !target.isKnockedOut) {
            target.statusEffects = applyStatusEffect(
              target.statusEffects,
              applyWisdomResistance(inflicted, target.wisdom),
            );
            _log.add(_LogEntry(
              _statusInflictedMessage(inflicted, target.displayName, lang),
              _LogKind.info,
            ));
          }
        }
        enemy.statusEffects = tickStatusEffects(enemy.statusEffects);
      });
      if (secondWind) {
        setState(() {
          _log.add(_LogEntry(
            '${target.displayName} ${trFor(lang, 'second_wind_message')}',
            _LogKind.playerHeal,
          ));
        });
      }
      if (thorns > 0 && enemy.isAlive) {
        setState(() {
          enemy.currentHealth = max(0, enemy.currentHealth - thorns);
          _lastDamagedEnemyKey = enemy.key;
          _lastEnemyDamageTaken = thorns;
          _log.add(_LogEntry(
            '${enemy.displayName} ${trFor(lang, 'thorns_suffix')} $thorns '
            '${trFor(lang, 'damage_word')}.',
            _LogKind.playerDamage,
          ));
        });
        _advancePhasesNow(lang, skills);
      }
      if (damageTaken > 0 && target.isPlayer) _triggerShake();

      if (target.isPlayer && target.currentHealth <= 0) {
        _finishFight(won: false);
        return;
      }
    }

    if (_enemies.every((e) => !e.isAlive)) {
      _finishFight(won: true);
      return;
    }

    for (final enemy in _enemies) {
      _preRollMoveFor(enemy, skills);
    }

    _startPartyRound(skills, items);
  }

  void _usePotion() {
    final session = ref.read(playerSessionProvider);
    if (session.potionCount <= 0 || _over) return;
    final player = _party.firstWhere((m) => m.isPlayer);
    ref.read(playerSessionProvider.notifier).consumePotion();
    final lang = ref.read(appLanguageProvider);
    final heal = _condition == BattlefieldCondition.shrine
        ? (_potionHealAmount * shrineHealMultiplier).round()
        : _potionHealAmount;
    _potionUsed = true;
    setState(() {
      player.currentHealth = min(player.maxHealth, player.currentHealth + heal);
      _log.add(
        _LogEntry(
          '${trFor(lang, 'drink_potion_prefix')} $heal ${trFor(lang, 'hp_label')}.',
          _LogKind.playerHeal,
        ),
      );
    });
  }

  /// Cures every active status effect (Poison/Stun/Weaken) off the player —
  /// mirrors [_usePotion]'s plumbing exactly, just against
  /// [PlayerSessionNotifier.consumeAntidote] and [_PartyMember.statusEffects]
  /// instead of health. Allies aren't cured (matches how potions are
  /// player-only too).
  void _useAntidote() {
    final session = ref.read(playerSessionProvider);
    final player = _party.firstWhere((m) => m.isPlayer);
    if (session.antidoteCount <= 0 || _over || player.statusEffects.isEmpty) {
      return;
    }
    ref.read(playerSessionProvider.notifier).consumeAntidote();
    final lang = ref.read(appLanguageProvider);
    setState(() {
      player.statusEffects = [];
      _log.add(
        _LogEntry(trFor(lang, 'drink_antidote_prefix'), _LogKind.playerHeal),
      );
    });
  }

  Future<void> _finishFight({required bool won}) async {
    setState(() {
      _over = true;
      _won = won;
    });

    // What this fight left behind, for the next scene's opening line.
    ref.read(lastFightOutcomeProvider.notifier).state = FightOutcome(
      won: won,
      enemyNames: [for (final e in _enemies) e.displayName],
      isElite: _isElite,
      isHunt: widget.modifiers.isHunt,
      isBoss: widget.modifiers.isZoneBoss ||
          _enemies.any((e) => e.phases.isNotEmpty),
      phasesCrossed: _phasesCrossed,
      knockedOutAllyName: _lastKnockedOutAllyName,
      flawless: !_potionUsed && !_anyKnockedOut,
      rounds: max(1, _roundsStarted),
      chapter: _chapter,
    );

    final notifier = ref.read(playerSessionProvider.notifier);
    final player = _party.firstWhere((m) => m.isPlayer);
    if (won) {
      // Every enemy that died (or fled) in this fight -- a pack's rewards
      // are summed across all of them, not just the one FightScreen was
      // originally constructed with.
      final defeated = _enemies.where((e) => !e.isAlive).toList();
      var goldGain = 0;
      var xpGain = 0;
      // An Elite always drops its trophy on top of the spoils chest -- the
      // guaranteed "that was worth it" payoff for the harder fight, on top
      // of the reward multiplier applied per enemy and the chest's own
      // Silver floor. Elite is solo-only, so this never double-applies.
      final loot = <String>[if (_isElite) 'elite_trophy'];
      final session = ref.read(playerSessionProvider);
      final items = ref.read(gameDbProvider(itemsSchema)).value ?? const {};
      final professions =
          ref.read(gameDbProvider(professionsSchema)).value ?? const {};
      final preferredScalingStat = (professions[session.professionId]
                  as Map<String, dynamic>?)?['preferredScalingStat']
              ?.toString() ??
          '';
      final rewardMultiplier =
          widget.modifiers.rewardMultiplier * chapterRewardMultiplier(_chapter);
      var affixCount = 0;
      var anyFled = false;
      var firstKill = false;
      var hasBoss = false;
      final signatureIds = <String>[];
      for (final enemy in defeated) {
        var enemyGold = scaledReward(
            (enemy.data['goldReward'] as num?)?.toInt() ?? 0, _playerLevel);
        var enemyXp = scaledReward(
            (enemy.data['xpReward'] as num?)?.toInt() ?? 0, _playerLevel);
        if (_isElite) {
          enemyGold = (enemyGold * _eliteRewardMultiplier).round();
          enemyXp = (enemyXp * _eliteRewardMultiplier).round();
        }
        if (enemy.fled) {
          enemyGold = (enemyGold * skittishFledRewardShare).round();
          enemyXp = (enemyXp * skittishFledRewardShare).round();
          anyFled = true;
        }
        goldGain += (enemyGold * rewardMultiplier).round();
        xpGain += (enemyXp * rewardMultiplier).round();
        affixCount += enemy.affixes.length;
        if (soloOnlyEnemyIds.contains(enemy.enemyId)) hasBoss = true;
        if ((session.enemyKillCounts[enemy.enemyId] ?? 0) == 0) {
          firstKill = true;
        }
        // An enemy's loot table now only steers WHICH gear its chest
        // favors (see LootContext.signatureItemIds); the chest itself
        // decides whether anything drops at all.
        final lootTable =
            (enemy.data['lootTable'] as List?)?.cast<Map<String, dynamic>>() ??
                const [];
        for (final entry in lootTable) {
          final itemId = entry['itemID']?.toString();
          if (itemId == null || itemId.isEmpty) continue;
          // A 100% entry is a guaranteed drop (a quest item such as the
          // High Warden's sealed letter), never a mere chest weighting.
          if (((entry['dropRate'] as num?)?.toDouble() ?? 0) >= 100) {
            loot.add(itemId);
          } else {
            signatureIds.add(itemId);
          }
        }
      }

      var bestAllyLuck = 0;
      final ownedItemIds = <String>[
        ...session.inventoryItemIds,
        ...session.equippedItemIds,
      ];
      for (final member in _party) {
        if (member.isPlayer) continue;
        if (member.luck > bestAllyLuck) bestAllyLuck = member.luck;
        ownedItemIds.addAll(member.equippedItemIds);
      }
      final chapter = _chapter;
      final lootContext = LootContext(
        chapter: chapter,
        playerLuck: player.luck,
        bestAllyLuck: bestAllyLuck,
        isElite: _isElite,
        hasBossOrUnique: hasBoss,
        enemyCount: _enemies.length,
        flawless: !_potionUsed && !_anyKnockedOut,
        rounds: max(1, _roundsStarted),
        finalBlowCritical: _lastKillWasCritical,
        fullTelegraphRead: _fullTelegraphRead,
        firstKill: firstKill,
        pityStreak: session.lootPityStreak,
        affixCount: affixCount,
        conditionBonus: conditionFortuneBonus(_condition),
        tierFloor: widget.modifiers.chestTierFloor,
        tierShift: anyFled ? -1 : 0,
        preferredScalingStat: preferredScalingStat,
        alignmentLabel: session.alignmentLabel,
        ownedItemIds: ownedItemIds,
        recentLootIds: session.recentLootIds,
        signatureItemIds: signatureIds,
      );
      final chest = rollLootBox(lootContext, items, _random);
      loot.addAll(chest.itemIds);
      goldGain += chest.gold;

      final lang = ref.read(appLanguageProvider);
      final chestBanter =
          chest.isBigChest ? _rollBanter(kind: _BanterKind.chest) : null;
      if (!mounted) return;
      await showSpoilsChestDialog(
        context,
        result: chest,
        items: items,
        autoOpen: ref.read(chestAutoOpenProvider),
        language: lang,
      );
      if (!mounted) return;

      final leveledUp = await notifier.applyCombatResult(
        hpAfter: player.currentHealth,
        enemyIds: defeated.map((e) => e.enemyId).toList(),
        goldGain: goldGain,
        xpGain: xpGain,
        itemsGained: loot,
        items: items,
        lootPityStreak: nextPityStreak(session.lootPityStreak, chest.tier),
        recentLootIds: nextRecentLootIds(session.recentLootIds, chest.itemIds),
        manaAfter: _mana,
      );
      // A knocked-out ally is revived at partial health on a win; a
      // survivor's ending health is simply persisted as-is. Level-ups
      // already full-heal every recruited ally inside applyCombatResult
      // itself, so skip writing each ally's stale pre-level-up battle-end
      // HP over that full heal (and over the new, higher level-up max).
      var anyAllyRevived = false;
      for (final member in _party) {
        if (member.isPlayer) continue;
        if (member.isKnockedOut) anyAllyRevived = true;
        if (leveledUp) continue;
        final hpAfter = member.isKnockedOut
            ? (member.maxHealth * _reviveHealthFraction).round()
            : member.currentHealth;
        await notifier.applyAllyCombatResult(member.id, hpAfter: hpAfter);
      }
      final newlyUnlockedAchievement = anyAllyRevived
          ? await notifier.unlockAchievement('ally_revival')
          : false;
      if (!mounted) return;
      final lootNames = [
        for (final id in loot)
          (items[id] as Map<String, dynamic>?)?['itemName']?.toString() ?? id,
      ];
      setState(() {
        _log.add(
          _LogEntry(
            '${trFor(lang, 'victory_prefix')} +$goldGain ${trFor(lang, 'gold_label')}, '
            '+$xpGain XP'
            '${lootNames.isNotEmpty ? ", ${trFor(lang, 'loot_label')}: ${lootNames.join(", ")}" : ""}.',
            _LogKind.victory,
          ),
        );
        _log.add(_LogEntry(
          '${trFor(lang, chestTierLabelKey(chest.tier))} '
          '(${trFor(lang, 'fortune_roll_label')} ${chest.roll})',
          _LogKind.victory,
        ));
        if (chestBanter != null) _log.add(chestBanter);
        if (newlyUnlockedAchievement) {
          _log.add(
            _LogEntry(
              '${trFor(lang, 'achievement_unlocked_prefix')}: Not Dead Yet',
              _LogKind.victory,
            ),
          );
        }
      });
      if (leveledUp) {
        final newLevel = ref.read(playerSessionProvider).level;
        showLevelUpDialog(context, ref, newLevel: newLevel);
      }
    } else {
      // Ally HP changes from a lost fight are never persisted (mirrors the
      // player's own full-heal-on-loss below — neither side is punished
      // HP-wise by a loss).
      // A loss refills mana along with health -- neither is a lasting
      // punishment. A boss's win is remembered, though: Resolve stacks
      // against it next time (see party_bonus.dart).
      final bossIds = [
        for (final e in _enemies)
          if (isBossEnemy(e.enemyId, e.data)) e.enemyId,
      ];
      if (bossIds.isNotEmpty) await notifier.recordBossDefeat(bossIds);
      await notifier.applyCombatResult(
          hpAfter: player.maxHealth, manaAfter: _maxMana);
      if (!mounted) return;
      setState(() {
        _log.add(_LogEntry(
            trFor(ref.read(appLanguageProvider), 'defeat_message'),
            _LogKind.defeat));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final diceAsync = ref.watch(gameDbProvider(diceSchema));
    final skillsAsync = ref.watch(gameDbProvider(skillsSchema));
    final itemsAsync = ref.watch(gameDbProvider(itemsSchema));
    final companionsAsync = ref.watch(gameDbProvider(companionsSchema));
    final racesAsync = ref.watch(gameDbProvider(racesSchema));
    final professionsAsync = ref.watch(gameDbProvider(professionsSchema));
    final gameConfigAsync = ref.watch(gameConfigProvider);
    final spellsAsync = ref.watch(gameDbProvider(spellsSchema));
    final itemSetsAsync = ref.watch(gameDbProvider(itemSetsSchema));
    final housesAsync = ref.watch(gameDbProvider(housesSchema));
    final session = ref.watch(playerSessionProvider);
    _companionsAutoAim = ref.watch(companionAutoTargetProvider);

    final dice = diceAsync.value;
    final skills = skillsAsync.value;
    final items = itemsAsync.value;
    final companions = companionsAsync.value;
    final races = racesAsync.value;
    final professions = professionsAsync.value;
    final gameConfig = gameConfigAsync.value;
    final spellsDb = spellsAsync.value;
    final itemSetsDb = itemSetsAsync.value;
    final houses = housesAsync.value;

    if (dice == null ||
        skills == null ||
        items == null ||
        companions == null ||
        races == null ||
        professions == null ||
        gameConfig == null ||
        spellsDb == null ||
        itemSetsDb == null ||
        houses == null) {
      final error = diceAsync.error ??
          skillsAsync.error ??
          itemsAsync.error ??
          companionsAsync.error ??
          racesAsync.error ??
          professionsAsync.error ??
          gameConfigAsync.error ??
          spellsAsync.error ??
          itemSetsAsync.error ??
          housesAsync.error;
      return Scaffold(
        appBar: AppBar(
          title: Text('${tr(ref, 'fight_prefix')}: ${_battleTitle()}'),
        ),
        body: Center(
          child: error != null
              ? Text('${tr(ref, 'failed_to_load_dice')}: $error')
              : const CircularProgressIndicator(),
        ),
      );
    }

    _itemSets = parseItemSets(itemSetsDb);
    _ensurePartyBuilt(session, companions, races, professions, gameConfig,
        items, _itemSets, houses);
    _spells = parseSpells(spellsDb);

    return Scaffold(
      appBar: AppBar(
        title: Text('${tr(ref, 'fight_prefix')}: ${_battleTitle()}'),
      ),
      body: !_started
          ? _buildSetup(dice, skills, items, session)
          : _buildBattle(dice, skills, items, session),
    );
  }

  Widget _buildSetup(
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
    PlayerSession session,
  ) {
    final player = _party.first;
    final condition = _condition;
    // Charms carried right now, one chip per distinct charm (a second copy
    // of the same charm can't be armed twice in one fight).
    final charmCounts = <String, int>{};
    for (final id in session.inventoryItemIds) {
      if ((items[id] as Map<String, dynamic>?)?['itemType']?.toString() ==
          'Charm') {
        charmCounts[id] = (charmCounts[id] ?? 0) + 1;
      }
    }
    final playerScalingBonus = equipmentScalingBonusFor(
      player.equippedItemIds,
      items,
      strength: player.strength,
      dexterity: player.dexterity,
      constitution: player.constitution,
      intelligence: player.intelligence,
    );
    final damageBonus =
        equipmentBonusFor(player.equippedItemIds, items, 'attackDamage') +
            playerScalingBonus.damageBonus;
    final armorBonus =
        equipmentBonusFor(player.equippedItemIds, items, 'armor') +
            playerScalingBonus.armorBonus;
    final equippedDie = _selectedDiceId != null
        ? dice[_selectedDiceId] as Map<String, dynamic>?
        : null;
    final faceCount = (equippedDie?['faces'] as List?)?.length ?? 0;
    final activeAllies = _party.skip(1).toList();
    final lang = ref.watch(appLanguageProvider);
    final knownSpellNames = <String>[
      for (final id in session.knownSpellIds)
        if (_spells[id] != null) _spells[id]!.nameFor(lang),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (condition != null) ...[
            _buildConditionBanner(condition),
            const SizedBox(height: 12),
          ],
          if (_newGamePlusCycle > 0) ...[
            Text(
              '${tr(ref, 'new_game_plus_label')} · '
              '${tr(ref, 'new_game_plus_cycle_label')} $_newGamePlusCycle · '
              '+${(newGamePlusStep * _newGamePlusCycle * 100).round()}% '
              '${tr(ref, 'new_game_plus_enemies_suffix')}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
          ],
          if (_partyBonus.resolveStacks > 0) ...[
            Text(
              '${tr(ref, 'resolve_label')} ×${_partyBonus.resolveStacks} · '
              '+${_partyBonus.resolvePercent}% '
              '${tr(ref, 'resolve_bonus_suffix')}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
          ],
          if (_partyBonus.hasHouseBonus) ...[
            Text(
              '${tr(ref, 'camp_works_label')} · '
              '+${_partyBonus.houseHealthPercent}% '
              '${tr(ref, 'party_health_bonus_label')} · '
              '+${_partyBonus.houseDamagePercent}% '
              '${tr(ref, 'party_damage_bonus_label')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
          ],
          if (widget.modifiers.isHunt ||
              widget.modifiers.isHunterAmbush ||
              widget.modifiers.isZoneBoss) ...[
            Text(
              tr(ref, _encounterNoteKey(widget.modifiers)),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
          ],
          for (final enemy in _enemies) ...[
            _buildEnemySetupCard(enemy),
            const SizedBox(height: 8),
          ],
          if (charmCounts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(tr(ref, 'charms_label'),
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(tr(ref, 'charms_hint'),
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final entry in charmCounts.entries)
                  FilterChip(
                    avatar: ItemPixelIcon(entry.key, 'Charm', size: 18),
                    label: Text(
                      '${(items[entry.key] as Map<String, dynamic>?)?['itemName'] ?? entry.key}'
                      '${entry.value > 1 ? ' x${entry.value}' : ''}',
                    ),
                    tooltip: tr(ref, '${entry.key}_desc'),
                    selected: _armedCharmIds.contains(entry.key),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _armedCharmIds.add(entry.key);
                      } else {
                        _armedCharmIds.remove(entry.key);
                      }
                    }),
                  ),
              ],
            ),
          ],
          if (damageBonus > 0 || armorBonus > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${tr(ref, 'your_equipment_prefix')}: +$damageBonus ${tr(ref, 'damage_word')}, '
              '+$armorBonus ${tr(ref, 'armor_label')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (activeAllies.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${tr(ref, 'fighting_alongside_prefix')}: '
              '${activeAllies.map((a) => a.displayName).join(", ")}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(manaIcon, size: 14, color: manaColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${tr(ref, 'mana_label')} $_mana/$_maxMana · '
                  '${tr(ref, 'spells_label')}: '
                  '${knownSpellNames.isEmpty ? '—' : knownSpellNames.join(", ")}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          Text(tr(ref, 'mana_faces_note'),
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 24),
          Text(tr(ref, 'equipped_die_label'),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (equippedDie == null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(tr(ref, 'no_die_equipped')),
                subtitle: Text(tr(ref, 'equip_die_hint')),
              ),
            )
          else
            Card(
              child: ListTile(
                leading: const Icon(Icons.casino),
                title: Text(_selectedDiceId!),
                subtitle: Text('$faceCount ${tr(ref, 'faces_label')}'),
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed:
                equippedDie == null ? null : () => _startFight(skills, items),
            icon: const Icon(Icons.sports_martial_arts),
            label: Text(tr(ref, 'enter_battle_button')),
          ),
        ],
      ),
    );
  }

  /// One enemy's card on the pre-fight setup screen — a solo fight renders
  /// exactly what this screen always showed for its one enemy; a pack
  /// renders one of these per member.
  Widget _buildEnemySetupCard(_EnemyMember enemy) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: _isElite
              ? Colors.amber.shade700
              : Theme.of(context).colorScheme.errorContainer,
          child: EnemyPixelIcon(enemy.enemyId, size: 36),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                enemy.displayName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: _isElite ? Colors.amber.shade800 : null,
                      fontWeight: _isElite ? FontWeight.bold : null,
                    ),
              ),
              Text(
                '${tr(ref, 'hp_label')} ${enemy.maxHealth} · ${tr(ref, 'damage_label')} ${enemy.damage} '
                '(${tr(ref, 'scaled_to_level')} $_playerLevel)',
              ),
              if (enemy.affixes.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildAffixChips(enemy, withDescriptions: true),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// One chip per affix on [enemy] -- the one-word name, plus its rules
  /// text on the setup screen ([withDescriptions]) so the player can plan
  /// around it before the first roll.
  Widget _buildAffixChips(_EnemyMember enemy, {bool withDescriptions = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final affix in enemy.affixes)
          Tooltip(
            message: tr(ref, affixDescriptionKey(affix)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                withDescriptions
                    ? '${tr(ref, affixLabelKey(affix))}: ${tr(ref, affixDescriptionKey(affix))}'
                    : tr(ref, affixLabelKey(affix)),
                style: TextStyle(
                    fontSize: 11, color: colorScheme.onErrorContainer),
              ),
            ),
          ),
      ],
    );
  }

  /// The battlefield condition's banner on the setup screen: its name and
  /// its rules text, so the fight is read before it's rolled.
  Widget _buildConditionBanner(BattlefieldCondition condition) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.tertiary),
      ),
      child: Row(
        children: [
          Icon(Icons.terrain, color: colorScheme.onTertiaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(ref, conditionLabelKey(condition)),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  tr(ref, conditionDescriptionKey(condition)),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: colorScheme.onTertiaryContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The small status chips shown above the log during battle: the
  /// battlefield condition (if any) and the momentum meter.
  Widget _buildBattleChips() {
    final condition = _condition;
    final ready = _momentum >= _momentumThreshold;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (condition != null)
          _telegraphChip(Icons.terrain, tr(ref, conditionLabelKey(condition))),
        _telegraphChip(
          ready ? Icons.local_fire_department : Icons.trending_up,
          ready
              ? tr(ref, 'momentum_ready_label')
              : '${tr(ref, 'momentum_label')} $_momentum/$_momentumThreshold',
        ),
      ],
    );
  }

  Widget _buildBattle(
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
    PlayerSession session,
  ) {
    final acting = _actingParty;
    final anyDieAvailable = acting.any((m) =>
        m.equippedDiceId != null &&
        ((dice[m.equippedDiceId] as Map<String, dynamic>?)?['faces'] as List?)
                ?.isNotEmpty ==
            true);
    final previews =
        _previewRoll(skills, items, ref.watch(appLanguageProvider));

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final t = _shakeController.value;
        final decay = 1 - t;
        final dx = sin(t * pi * 8) * decay * 8;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: _buildTopStrip(),
          ),
          const SizedBox(height: 6),
          _buildDiceTray(acting, dice, skills, items, previews),
          const SizedBox(height: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _buildPartyColumn(items)),
                  const SizedBox(width: 8),
                  Expanded(flex: 6, child: _buildEnemyColumn(previews)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          _buildLogTicker(),
          const SizedBox(height: 4),
          _buildBottomBar(
              acting, anyDieAvailable, dice, skills, items, session),
        ],
      ),
    );
  }

  // --- Top strip -----------------------------------------------------------

  /// The battlefield condition, the momentum meter and the round counter --
  /// the fight-wide state, above the dice.
  Widget _buildTopStrip() {
    return Row(
      children: [
        Expanded(child: _buildBattleChips()),
        _telegraphChip(
            Icons.flag_outlined, '${tr(ref, 'round_label')} $_roundsStarted'),
      ],
    );
  }

  // --- Dice tray -----------------------------------------------------------

  /// The party's rolled dice, one tile per acting member, in the member's
  /// own accent color, with what the landed face is worth this round under
  /// its name (see [_buildPreviewLine]). A tap on a landed die keeps it
  /// through the next reroll (tap again to release it); a long-press opens
  /// the face's details and the whole die.
  Widget _buildDiceTray(
    List<_PartyMember> acting,
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
    Map<String, _FacePreview> previews,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final canLock =
        _awaitingDecision && !_rolling && _rollCount < _maxRollsThisFight;
    final hintKey = acting.isEmpty
        ? 'nobody_can_act_label'
        : _currentFaces.isEmpty
            ? 'roll_hint'
            : canLock
                ? 'lock_hint'
                : 'confirm_hint';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final actor in acting)
                Expanded(
                  child: Center(
                    child: _buildDieTile(actor, dice, skills, items, canLock,
                        previews[actor.id]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            tr(ref, hintKey),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDieTile(
    _PartyMember actor,
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
    bool canLock,
    _FacePreview? preview,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _accentFor(actor);
    final face = _currentFaces[actor.id];
    final locked = _lockedActorIds.contains(actor.id);
    final spinning = _rolling && !locked;

    Widget inner;
    if (spinning) {
      inner = AnimatedBuilder(
        animation: _rollController,
        builder: (context, _) {
          final t = _rollController.value;
          final angle = Curves.easeOutCubic.transform(t) * 6 * pi;
          final scale = 1 + (sin(t * pi) * 0.25);
          return Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: scale,
              child: Icon(Icons.casino, size: 30, color: accent),
            ),
          );
        },
      );
    } else if (face == null) {
      inner =
          Icon(Icons.casino, size: 30, color: accent.withValues(alpha: 0.45));
    } else {
      inner = _buildFaceGlyph(face, size: 30);
    }

    final label = face == null || spinning
        ? ''
        : (face.faceName.isEmpty ? face.type : face.faceName);
    return GestureDetector(
      onTap: face == null
          ? null
          : () {
              if (canLock) {
                setState(() {
                  if (locked) {
                    _lockedActorIds.remove(actor.id);
                  } else {
                    _lockedActorIds.add(actor.id);
                  }
                });
              } else {
                _showFaceSheet(actor, face, dice, skills, items);
              }
            },
      onLongPress: face == null
          ? null
          : () => _showFaceSheet(actor, face, dice, skills, items),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color:
                  locked ? accent.withValues(alpha: 0.22) : colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent, width: locked ? 3 : 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 3,
                  offset: const Offset(1, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(child: inner),
                if (locked)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(Icons.lock, size: 12, color: accent),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: 72,
            child: Text(
              actor.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: accent, fontWeight: FontWeight.bold, fontSize: 10),
            ),
          ),
          SizedBox(
            width: 72,
            height: 12,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9),
            ),
          ),
          SizedBox(
            width: 72,
            height: 13,
            child: face == null || spinning || preview == null
                ? null
                : _buildPreviewLine(preview),
          ),
        ],
      ),
    );
  }

  /// The one number a landed die is worth this round, under its name on
  /// the tile: the damage its target would take (marked when it would drop
  /// the target, starred when momentum makes it a guaranteed critical),
  /// or the healing, block or mana it gives.
  Widget _buildPreviewLine(_FacePreview preview) {
    final result = preview.result;
    final IconData icon;
    final String text;
    final Color color;
    if (result.damageDealt > 0) {
      icon = preview.surge ? Icons.auto_awesome : Icons.bolt;
      text = preview.lethal
          ? '${preview.damage} ${tr(ref, 'preview_lethal_label')}'
          : '${preview.damage}';
      color = preview.lethal ? Colors.red : Colors.deepOrange;
    } else if (preview.healing > 0) {
      icon = Icons.favorite;
      text = '+${preview.healing}';
      color = Colors.green;
    } else if (preview.block > 0) {
      icon = Icons.shield;
      text = '${preview.block}';
      color = Colors.blue;
    } else if (result.manaGained > 0) {
      icon = manaIcon;
      text = '+${result.manaGained}';
      color = manaColor;
    } else {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 2),
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  /// A rolled face as a glyph: its type icon over its value (a Skill face
  /// shows the skill's own pixel icon instead).
  Widget _buildFaceGlyph(DiceFaceResult face, {double size = 28}) {
    if (face.type == 'Skill') {
      return SkillPixelIcon(_effectiveSkillId(face), size: size);
    }
    final color = _faceTypeColor(face.type);
    final showValue = face.value > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_faceTypeIcon(face.type),
            size: showValue ? size * 0.62 : size, color: color),
        if (showValue)
          Text(
            '${face.value}',
            style: TextStyle(
              fontSize: size * 0.42,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1,
            ),
          ),
      ],
    );
  }

  /// The sheet behind a die tile: what confirming this face would do, which
  /// skill it resolves to, and every face of the die it came from -- the
  /// same read a long-press gives on a die in Slice & Dice.
  Future<void> _showFaceSheet(
    _PartyMember actor,
    DiceFaceResult face,
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
  ) {
    final lang = ref.read(appLanguageProvider);
    final availableSkills = _availableSkillsFor(actor, skills);
    // The tile's own preview when this is the face on the table (the usual
    // case); otherwise the face resolved on its own, with no target.
    final tablePreview = _previewRoll(skills, items, lang)[actor.id];
    final preview = tablePreview != null &&
            tablePreview.result.message.isNotEmpty &&
            _currentFaces[actor.id] == face
        ? tablePreview
        : _FacePreview(
            result: resolvePlayerFace(
              face,
              availableSkills,
              _totalDamageFor(actor, face, skills, items),
              language: lang,
              activeEffects: actor.statusEffects,
              wisdomHealBonus: actor.wisdom ~/ 2,
              alignmentLabel: _alignmentLabel,
            ),
            target: null,
            damage: 0,
            healing: 0,
            block: 0,
            surge: false,
          );
    final target = preview.target;
    final targetLine = target == null || preview.damage <= 0
        ? null
        : '${trFor(lang, 'preview_against_prefix')} ${target.displayName}: '
            '${preview.damage} ${trFor(lang, 'damage_word')}, '
            '${preview.lethal ? trFor(lang, 'preview_lethal_label') : '${max(0, target.currentHealth - preview.damage)} ${trFor(lang, 'hp_label')} ${trFor(lang, 'preview_left_suffix')}'}';
    final element = _elementFor(face, availableSkills);
    final dieId = actor.equippedDiceId;
    final faces = dieId == null
        ? const <Map<String, dynamic>>[]
        : ((dice[dieId] as Map<String, dynamic>?)?['faces'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            const <Map<String, dynamic>>[];
    final accent = _accentFor(actor);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accent, width: 2),
                      ),
                      child: Center(child: _buildFaceGlyph(face, size: 26)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            face.faceName.isEmpty ? face.type : face.faceName,
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            '${actor.displayName} · ${dieId ?? ''}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: accent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(preview.result.message, style: theme.textTheme.bodyMedium),
                if (targetLine != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    targetLine,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: preview.lethal ? Colors.red : Colors.deepOrange,
                        fontWeight: FontWeight.bold),
                  ),
                ],
                if (face.type == 'Skill') ...[
                  const SizedBox(height: 4),
                  Text(
                    '${trFor(lang, 'skill_label')}: ${_effectiveSkillId(face)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
                if (element != 'None') ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(elementIcon(element), size: 14),
                      const SizedBox(width: 4),
                      Text('${trFor(lang, 'element_label')}: $element',
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
                if (faces.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(trFor(lang, 'die_faces_label'),
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < faces.length; i++)
                        _buildMiniFace(faces[i], i, i == face.faceIndex, accent,
                            actor, sheetContext),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Text(trFor(lang, 'lock_hint'),
                    style: theme.textTheme.labelSmall),
              ],
            ),
          ),
        );
      },
    );
  }

  /// One face of a whole die in [_showFaceSheet]'s grid.
  Widget _buildMiniFace(
    Map<String, dynamic> raw,
    int index,
    bool isRolled,
    Color accent,
    _PartyMember actor,
    BuildContext sheetContext,
  ) {
    var face = DiceFaceResult(
      faceIndex: index,
      faceName: raw['faceName']?.toString() ?? '',
      type: raw['type']?.toString() ?? 'Empty',
      value: (raw['value'] as num?)?.toInt() ?? 0,
      linkedSkillID: raw['linkedSkillID']?.toString() ?? '',
      element: raw['element']?.toString() ?? 'None',
    );
    if (face.type == 'Skill') {
      final assigned = actor.diceSkillAssignments[index.toString()];
      if (assigned != null && assigned.isNotEmpty) {
        face = face.withLinkedSkillID(assigned);
      }
    }
    final colorScheme = Theme.of(sheetContext).colorScheme;
    return SizedBox(
      width: 60,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isRolled ? accent.withValues(alpha: 0.2) : null,
              border: Border.all(
                color: isRolled ? accent : colorScheme.outlineVariant,
                width: isRolled ? 2 : 1,
              ),
            ),
            child: Center(child: _buildFaceGlyph(face, size: 22)),
          ),
          const SizedBox(height: 2),
          Text(
            face.faceName.isEmpty ? face.type : face.faceName,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  // --- Party column --------------------------------------------------------

  Widget _buildPartyColumn(Map<String, dynamic> items) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (final member in _party) ...[
          _buildPartyCard(member, items),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  /// One party member: avatar in their accent color, name, a thin health
  /// bar with numbers, block/status chips, and the die slot showing the
  /// face they're holding. In a pack fight, tapping the card selects whose
  /// die the enemy column's taps aim.
  Widget _buildPartyCard(_PartyMember member, Map<String, dynamic> items) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _accentFor(member);
    final face = _currentFaces[member.id];
    final isStrike =
        face != null && (face.type == 'Attack' || face.type == 'Skill');
    final canSelect = _enemies.length > 1 &&
        isStrike &&
        _awaitingDecision &&
        !_rolling &&
        (member.isPlayer || !_companionsAutoAim);
    final isSelected = canSelect && _selectedActorId == member.id;
    final targeted = !member.isKnockedOut && _isTelegraphedTarget(member);
    final scalingBonus = equipmentScalingBonusFor(
      member.equippedItemIds,
      items,
      strength: member.strength,
      dexterity: member.dexterity,
      constitution: member.constitution,
      intelligence: member.intelligence,
    );
    final armor = member.armor +
        equipmentBonusFor(member.equippedItemIds, items, 'armor') +
        scalingBonus.armorBonus;
    final damage = member.baseDamage +
        equipmentBonusFor(member.equippedItemIds, items, 'attackDamage') +
        scalingBonus.damageBonus;
    final initial =
        member.displayName.isEmpty ? '?' : member.displayName[0].toUpperCase();

    final card = GestureDetector(
      onTap:
          canSelect ? () => setState(() => _selectedActorId = member.id) : null,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: member.isKnockedOut
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accent : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor:
                      member.isKnockedOut ? colorScheme.outline : accent,
                  child: Text(
                    initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    member.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (targeted)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.gps_fixed,
                        size: 14, color: colorScheme.error),
                  ),
                _buildDieSlot(face, accent),
              ],
            ),
            const SizedBox(height: 5),
            _buildHpBar(member.currentHealth, member.maxHealth),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _miniStat(Icons.bolt, '$damage', Colors.deepOrange),
                _miniStat(Icons.shield_outlined, '$armor', Colors.blueGrey),
                if (member.block > 0)
                  _miniStat(Icons.shield, '+${member.block}', Colors.blue),
                for (final effect in member.statusEffects)
                  _StatusEffectChip(effect: effect),
                if (member.isKnockedOut)
                  Text(
                    tr(ref, 'knocked_out_label'),
                    style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    return _withDamagePopup(
      card,
      show: _lastDamagedMemberId == member.id && _lastDamageTaken > 0,
      amount: _lastDamageTaken,
      fade: true,
    );
  }

  /// The small square next to a party member's name holding the face they
  /// rolled this round -- empty (dashed) before the roll.
  Widget _buildDieSlot(DiceFaceResult? face, Color accent) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: face == null ? null : accent.withValues(alpha: 0.12),
        border: Border.all(
          color: face == null ? colorScheme.outlineVariant : accent,
          width: face == null ? 1 : 1.5,
        ),
      ),
      child: face == null || _rolling
          ? Icon(Icons.casino,
              size: 14, color: colorScheme.outline.withValues(alpha: 0.6))
          : Center(child: _buildFaceGlyph(face, size: 18)),
    );
  }

  Widget _miniStat(IconData icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 2),
        Text(value,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  /// A thin health bar with its numbers inside -- shared by both columns.
  /// With [pending] damage on the way (the dice aimed at an enemy, see
  /// [_previewRoll]) the slice about to go is darkened and the numbers
  /// read "now → after / max".
  Widget _buildHpBar(int current, int maxValue,
      {double height = 14, int pending = 0}) {
    final rawRatio = maxValue <= 0 ? 0.0 : current / maxValue;
    final ratio = rawRatio.clamp(0.0, 1.0);
    final after = max(0, current - pending);
    final afterRatio = maxValue <= 0 ? 0.0 : (after / maxValue).clamp(0.0, 1.0);
    final barColor = ratio > 0.5
        ? Colors.green
        : (ratio > 0.25 ? Colors.orange : Colors.red);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: barColor.withValues(alpha: 0.18),
          border: Border.all(color: barColor.withValues(alpha: 0.5)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      width: constraints.maxWidth * ratio,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [barColor.withValues(alpha: 0.75), barColor],
                        ),
                      ),
                    ),
                  ),
                  if (pending > 0 && ratio > afterRatio)
                    Positioned(
                      left: constraints.maxWidth * afterRatio,
                      width: constraints.maxWidth * (ratio - afterRatio),
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border(
                            left: BorderSide(
                                color: Colors.white.withValues(alpha: 0.8)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              pending > 0
                  ? '$current → $after / $maxValue'
                  : '$current / $maxValue',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: height * 0.68,
                height: 1,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 2)],
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Overlays a floating "-N" on [child] for the combatant that was just
  /// hit -- fading with the screen shake for the party, static for an enemy.
  Widget _withDamagePopup(Widget child,
      {required bool show, required int amount, bool fade = false}) {
    if (!show) return child;
    final label = Text(
      '-$amount',
      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: 4,
          top: -6,
          child: fade
              ? AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, _) => Opacity(
                    opacity: (1 - _shakeController.value).clamp(0.0, 1.0),
                    child: label,
                  ),
                )
              : label,
        ),
      ],
    );
  }

  // --- Enemy column --------------------------------------------------------

  Widget _buildEnemyColumn(Map<String, _FacePreview> previews) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        for (final enemy in _enemies) ...[
          _buildEnemyCard(enemy, previews),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  /// One enemy: portrait, name, health bar (with the slice the dice aimed
  /// at it would take off, see [_buildHpBar]), affix/status chips, the
  /// dots of every party die currently aimed at it, and its intent box
  /// (see [_buildIntentBox]). In a pack fight a tap aims the selected
  /// member's die here; otherwise (or on a long-press) it opens the
  /// enemy's details.
  Widget _buildEnemyCard(
      _EnemyMember enemy, Map<String, _FacePreview> previews) {
    final colorScheme = Theme.of(context).colorScheme;
    var pending = 0;
    for (final preview in previews.values) {
      if (preview.target?.key == enemy.key) pending += preview.damage;
    }
    final lethal = enemy.isAlive && pending >= enemy.currentHealth;
    final selectedActor =
        _selectedActorId == null ? null : _memberById(_selectedActorId!);
    final canRetarget = selectedActor != null &&
        _enemies.length > 1 &&
        _awaitingDecision &&
        !_rolling &&
        enemy.isAlive &&
        _selectedTargets.containsKey(selectedActor.id);
    final aimingActors = <_PartyMember>[
      for (final actor in _actingParty)
        if (_currentFaces[actor.id] != null &&
            (_currentFaces[actor.id]!.type == 'Attack' ||
                _currentFaces[actor.id]!.type == 'Skill') &&
            (_enemies.length == 1
                ? enemy.isAlive
                : _selectedTargets[actor.id] == enemy.key))
          actor,
    ];
    final aimedBySelected =
        canRetarget && _selectedTargets[selectedActor.id] == enemy.key;
    final borderColor = aimedBySelected
        ? _accentFor(selectedActor)
        : _isElite && enemy.isAlive
            ? Colors.amber.shade700
            : colorScheme.outlineVariant;

    final card = GestureDetector(
      onTap: !enemy.isAlive
          ? null
          : canRetarget
              ? () => setState(() {
                    _selectedTargets[selectedActor.id] = enemy.key;
                    // Auto-aiming companions follow the player's new pick.
                    _autoAssignTargets();
                  })
              : () => _showEnemySheet(enemy),
      onLongPress: () => _showEnemySheet(enemy),
      child: Opacity(
        opacity: enemy.isAlive ? 1 : 0.45,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: aimedBySelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  EnemyPixelIcon(enemy.enemyId, size: 30),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      enemy.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _isElite ? Colors.amber.shade800 : null,
                          ),
                    ),
                  ),
                  if (aimingActors.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final actor in aimingActors)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _accentFor(actor),
                                border:
                                    Border.all(color: Colors.white, width: 1),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              _buildHpBar(enemy.currentHealth, enemy.maxHealth,
                  pending: enemy.isAlive ? pending : 0),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _miniStat(Icons.bolt, '${enemy.damage}', Colors.deepOrange),
                  if (enemy.isAlive && pending > 0)
                    _miniStat(
                      lethal ? Icons.dangerous_outlined : Icons.arrow_downward,
                      lethal
                          ? '-$pending ${tr(ref, 'preview_lethal_label')}'
                          : '-$pending',
                      Colors.red,
                    ),
                  if (enemy.fled)
                    Text(tr(ref, 'fled_label'),
                        style: const TextStyle(
                            fontSize: 10, fontStyle: FontStyle.italic)),
                  for (final effect in enemy.statusEffects)
                    _StatusEffectChip(effect: effect),
                ],
              ),
              if (enemy.affixes.isNotEmpty) ...[
                const SizedBox(height: 3),
                _buildAffixChips(enemy),
              ],
              if (enemy.currentPhase != null) _buildPhaseChip(enemy),
              if (enemy.isAlive) ...[
                const SizedBox(height: 5),
                _buildIntentBox(enemy),
              ],
            ],
          ),
        ),
      ),
    );
    return _withDamagePopup(
      card,
      show: _lastDamagedEnemyKey == enemy.key && _lastEnemyDamageTaken > 0,
      amount: _lastEnemyDamageTaken,
    );
  }

  /// The boss phase [enemy] is currently in, as a small purple chip under
  /// its affixes; its message on hover.
  Widget _buildPhaseChip(_EnemyMember enemy) {
    final phase = enemy.currentPhase;
    if (phase == null) return const SizedBox.shrink();
    final lang = ref.watch(appLanguageProvider);
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Tooltip(
        message: phase.messageFor(lang),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.change_circle_outlined,
                  size: 11, color: Colors.deepPurple),
              const SizedBox(width: 3),
              Text(
                '${tr(ref, 'phase_chip_prefix')} ${enemy.phaseIndex}: '
                '${phase.nameFor(lang)}',
                style: const TextStyle(
                    fontSize: 10,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The enemy's intent for its next turn, at whatever detail the party's
  /// Perception reads it (see [telegraphTierFor]): a "?" box when nothing
  /// can be read, the target's name from the first tier, a move-category
  /// icon from the second, and the damage number, element and the move's
  /// own words at the full tier.
  Widget _buildIntentBox(_EnemyMember enemy) {
    final colorScheme = Theme.of(context).colorScheme;
    final pending = enemy.pendingMove;
    final tier =
        pending == null ? TelegraphTier.none : _effectiveTierFor(enemy);
    final textStyle = TextStyle(
        fontSize: 10,
        color: colorScheme.onErrorContainer,
        fontWeight: FontWeight.w600);

    Widget content;
    if (pending == null || tier == TelegraphTier.none) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline,
              size: 12, color: colorScheme.onErrorContainer),
          const SizedBox(width: 4),
          Text(tr(ref, 'intent_unknown_label'), style: textStyle),
        ],
      );
    } else {
      final targetName = _memberById(pending.targetId)?.displayName ?? '?';
      final showCategory =
          tier == TelegraphTier.category || tier == TelegraphTier.full;
      final categoryIcon = switch (categoryFor(pending.move)) {
        MoveCategory.attack => Icons.bolt,
        MoveCategory.healSelf => Icons.healing,
        MoveCategory.statusDebuff => Icons.sick,
      };
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(showCategory ? categoryIcon : Icons.visibility,
                  size: 12, color: colorScheme.onErrorContainer),
              if (tier == TelegraphTier.full) ...[
                const SizedBox(width: 2),
                Text('${pending.move.damage}', style: textStyle),
              ],
              const SizedBox(width: 3),
              Icon(Icons.arrow_forward,
                  size: 11, color: colorScheme.onErrorContainer),
              const SizedBox(width: 3),
              Expanded(
                child: Text(targetName,
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              if (tier == TelegraphTier.full && pending.move.element != 'None')
                Icon(elementIcon(pending.move.element),
                    size: 12, color: colorScheme.onErrorContainer),
            ],
          ),
          if (tier == TelegraphTier.full)
            Text(
              pending.move.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 9,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onErrorContainer),
            ),
        ],
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.35)),
      ),
      child: content,
    );
  }

  Widget _telegraphChip(IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colorScheme.onTertiaryContainer),
          const SizedBox(width: 3),
          Text(
            label,
            style:
                TextStyle(fontSize: 11, color: colorScheme.onTertiaryContainer),
          ),
        ],
      ),
    );
  }

  /// The sheet behind an enemy card: its numbers, every affix's rules text,
  /// its active status effects and its readable intent, in full sentences.
  Future<void> _showEnemySheet(_EnemyMember enemy) {
    final lang = ref.read(appLanguageProvider);
    final pending = enemy.pendingMove;
    final tier =
        pending == null ? TelegraphTier.none : _effectiveTierFor(enemy);
    final targetName = pending == null
        ? ''
        : _memberById(pending.targetId)?.displayName ?? '?';
    final categoryLabel = pending == null
        ? ''
        : trFor(
            lang,
            switch (categoryFor(pending.move)) {
              MoveCategory.attack => 'telegraph_category_attack',
              MoveCategory.healSelf => 'telegraph_category_heal',
              MoveCategory.statusDebuff => 'telegraph_category_debuff',
            });
    final intentText = switch (tier) {
      TelegraphTier.none => trFor(lang, 'intent_unknown_desc'),
      TelegraphTier.target =>
        '${trFor(lang, 'intent_target_prefix')} $targetName.',
      TelegraphTier.category =>
        '${trFor(lang, 'intent_target_prefix')} $targetName ($categoryLabel).',
      TelegraphTier.full => '${trFor(lang, 'intent_target_prefix')} $targetName: '
          '${pending!.move.message} '
          '(${pending.move.damage} ${trFor(lang, 'damage_word')}'
          '${pending.move.element != 'None' ? ', ${pending.move.element}' : ''}).',
    };
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    EnemyPixelIcon(enemy.enemyId, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(enemy.displayName,
                          style: theme.textTheme.titleMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${trFor(lang, 'hp_label')} ${enemy.currentHealth} / ${enemy.maxHealth}'
                  ' · ${trFor(lang, 'damage_label')} ${enemy.damage}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (enemy.affixes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final affix in enemy.affixes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${trFor(lang, affixLabelKey(affix))}: '
                        '${trFor(lang, affixDescriptionKey(affix))}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                ],
                if (enemy.statusEffects.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final effect in enemy.statusEffects)
                        _StatusEffectChip(effect: effect),
                    ],
                  ),
                ],
                if (enemy.phases.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    enemy.currentPhase == null
                        ? '${trFor(lang, 'phases_label')}: ${enemy.phases.length} '
                            '· ${trFor(lang, 'phases_hint')}'
                        : '${trFor(lang, 'phase_chip_prefix')} '
                            '${enemy.phaseIndex}/${enemy.phases.length} — '
                            '${enemy.currentPhase!.nameFor(lang)}: '
                            '${enemy.currentPhase!.messageFor(lang)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.deepPurple),
                  ),
                ],
                const SizedBox(height: 10),
                Text(trFor(lang, 'intent_label'),
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(intentText, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Log ticker ----------------------------------------------------------

  /// The last two log lines, tappable for the whole log.
  Widget _buildLogTicker() {
    final colorScheme = Theme.of(context).colorScheme;
    final recent = _log.length <= 2 ? _log : _log.sublist(_log.length - 2);
    return GestureDetector(
      onTap: _showFullLog,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final entry in recent)
                    Row(
                      children: [
                        Icon(_logIcon(entry.kind),
                            size: 12, color: _logColor(context, entry.kind)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            entry.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: _logColor(context, entry.kind),
                              fontWeight: entry.kind == _LogKind.info
                                  ? FontWeight.normal
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  if (recent.isEmpty)
                    Text(tr(ref, 'battle_log_title'),
                        style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.unfold_more, size: 16, color: colorScheme.outline),
          ],
        ),
      ),
    );
  }

  Future<void> _showFullLog() {
    final lang = ref.read(appLanguageProvider);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.6,
          child: Column(
            children: [
              Text(trFor(lang, 'battle_log_title'),
                  style: Theme.of(sheetContext).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _log.length,
                  itemBuilder: (context, index) {
                    final entry = _log[_log.length - 1 - index];
                    final color = _logColor(context, entry.kind);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_logIcon(entry.kind), size: 14, color: color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              entry.text,
                              style: TextStyle(
                                color: color,
                                fontWeight: entry.kind == _LogKind.info
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Bottom bar ----------------------------------------------------------

  /// Mana and spells on the first line; potion/antidote, reroll and confirm
  /// (or roll) on the second -- everything the player can press, in one
  /// place, like the action bar under a Slice & Dice fight.
  Widget _buildBottomBar(
    List<_PartyMember> acting,
    bool anyDieAvailable,
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
    PlayerSession session,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    if (_over) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        child: _buildReturnButton(),
      );
    }
    final rollsLeft = _maxRollsThisFight - _rollCount;
    final allLocked = acting.isNotEmpty &&
        acting.every((a) => _lockedActorIds.contains(a.id));
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildManaRow(session, skills, items),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildConsumableButton(
                icon: Icons.local_drink,
                count: session.potionCount,
                tooltip: tr(ref, 'potion_button_prefix'),
                enabled: session.potionCount > 0 && !_rolling,
                onTap: _usePotion,
              ),
              if (_party.first.statusEffects.isNotEmpty) ...[
                const SizedBox(width: 6),
                _buildConsumableButton(
                  icon: Icons.healing,
                  count: session.antidoteCount,
                  tooltip: tr(ref, 'antidote_button_prefix'),
                  enabled: session.antidoteCount > 0 && !_rolling,
                  onTap: _useAntidote,
                ),
              ],
              const SizedBox(width: 8),
              if (_awaitingDecision) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_rolling || rollsLeft <= 0 || allLocked)
                        ? null
                        : () => _rollDice(dice, skills, items),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text('${tr(ref, 'reroll_button')} ($rollsLeft)'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_rolling || !_allTargetsPicked)
                        ? null
                        : () => _confirmRoll(skills, items),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(tr(ref, 'confirm_roll_button')),
                  ),
                ),
              ] else
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (!anyDieAvailable || _rolling)
                        ? null
                        : () => _rollDice(dice, skills, items),
                    icon: const Icon(Icons.casino, size: 18),
                    label: Text(
                      acting.length > 1
                          ? '${tr(ref, 'roll_dice_button')} (${acting.length}×)'
                          : tr(ref, 'roll_dice_button'),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// A square icon button with a count badge -- potions and antidotes.
  Widget _buildConsumableButton({
    required IconData icon,
    required int count,
    required String tooltip,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: '$tooltip ($count)',
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outline),
              color: colorScheme.surface,
            ),
            child: Stack(
              children: [
                Center(child: Icon(icon, size: 20, color: Colors.green)),
                Positioned(
                  right: 2,
                  bottom: 1,
                  child: Text(
                    '$count',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The mana meter and one button per known spell, scrolling sideways.
  Widget _buildManaRow(
    PlayerSession session,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
  ) {
    final known = <SpellSpec>[
      for (final id in session.knownSpellIds)
        if (_spells[id] != null) _spells[id]!,
    ];
    return Row(
      children: [
        _buildManaMeter(),
        const SizedBox(width: 8),
        Expanded(
          child: known.isEmpty
              ? Text(
                  tr(ref, 'no_spells_hint'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final spell in known)
                        _buildSpellButton(spell, skills, items),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildManaMeter() {
    final showPips = _maxMana <= 10;
    return Tooltip(
      message: '${tr(ref, 'mana_label')} $_mana / $_maxMana',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(manaIcon, size: 16, color: manaColor),
          const SizedBox(width: 2),
          Text(
            '$_mana/$_maxMana',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 12, color: manaColor),
          ),
          if (showPips) ...[
            const SizedBox(width: 4),
            for (var i = 0; i < _maxMana; i++)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      i < _mana ? manaColor : manaColor.withValues(alpha: 0.2),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpellButton(
    SpellSpec spell,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
  ) {
    final lang = ref.watch(appLanguageProvider);
    final enabled = _mana >= spell.manaCost && !_rolling && !_over;
    final color = spellEffectColor(spell.effect);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: '${spell.nameFor(lang)} · ${spell.manaCost} '
            '${tr(ref, 'mana_label')}\n${spell.descriptionFor(lang)}',
        child: InkWell(
          onTap: enabled ? () => _castSpell(spell, skills, items) : null,
          onLongPress: () => _showSpellSheet(spell, items),
          borderRadius: BorderRadius.circular(8),
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.7)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(spellEffectIcon(spell.effect), size: 15, color: color),
                  const SizedBox(width: 4),
                  Text(
                    spell.nameFor(lang),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                  const SizedBox(width: 5),
                  for (var i = 0; i < spell.manaCost; i++)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(left: 1.5),
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: manaColor),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// What [spell] would deal / heal / block if the player cast it right
  /// now -- a Damage spell rides the same total the player's dice hit
  /// with (base, gear, stat scaling, alignment, the spell's element).
  int _spellAmountNow(SpellSpec spell, Map<String, dynamic> items) {
    final player = _party.firstWhere((m) => m.isPlayer);
    final scalingBonus = equipmentScalingBonusFor(
      player.equippedItemIds,
      items,
      strength: player.strength,
      dexterity: player.dexterity,
      constitution: player.constitution,
      intelligence: player.intelligence,
    );
    final alignedBonus =
        alignmentGearBonusFor(player.equippedItemIds, items, _alignmentLabel);
    final casterDamage = player.baseDamage +
        equipmentBonusFor(player.equippedItemIds, items, 'attackDamage') +
        scalingBonus.damageBonus +
        alignedBonus.damageBonus +
        player.gear.attackDamage +
        _elementalDamageBonus(spell.element, player.equippedItemIds, items);
    return spellAmountFor(
      spell,
      intelligence: player.intelligence,
      wisdom: player.wisdom,
      level: _playerLevel,
      casterDamage: casterDamage,
    );
  }

  /// A spell's full description, numbers as they'd land right now.
  Future<void> _showSpellSheet(SpellSpec spell, Map<String, dynamic> items) {
    final lang = ref.read(appLanguageProvider);
    final amount = _spellAmountNow(spell, items);
    final status = spellStatusFor(spell, level: _playerLevel);
    final color = spellEffectColor(spell.effect);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(spellEffectIcon(spell.effect), color: color, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(spell.nameFor(lang),
                          style: theme.textTheme.titleMedium),
                    ),
                    const Icon(manaIcon, size: 16, color: manaColor),
                    const SizedBox(width: 2),
                    Text('${spell.manaCost}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: manaColor)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(spell.descriptionFor(lang),
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 6),
                Text(
                  '${trFor(lang, spellEffectLabelKey(spell.effect))}'
                  '${amount > 0 ? ' $amount' : ''}'
                  ' · ${trFor(lang, spellTargetLabelKey(spell.target))}'
                  '${spell.element != 'None' ? ' · ${spell.element}' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
                if (status != null)
                  Text(
                    '${_statusInflictedMessage(status, trFor(lang, 'the_enemy_label'), lang)}'
                    '${status.type == StatusEffectType.poison ? ' (${status.magnitude} x ${status.remainingTurns})' : ' (${status.remainingTurns})'}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The end-of-fight button: back to the story on a win, retreat (or the
  /// permadeath flow) on a loss.
  Widget _buildReturnButton() {
    return ElevatedButton(
      onPressed: () async {
        if (!_won && ref.read(permadeathEnabledProvider)) {
          final nodesVisited = ref.read(storyPlayProvider).history.length + 1;
          final playerSession = ref.read(playerSessionProvider);
          final races = ref.read(gameDbProvider(racesSchema)).value ?? const {};
          final professions =
              ref.read(gameDbProvider(professionsSchema)).value ?? const {};
          final result =
              await ref.read(playerSessionProvider.notifier).applyPermadeath(
                    race:
                        races[playerSession.raceId] as Map<String, dynamic>? ??
                            const {},
                    profession: professions[playerSession.professionId]
                            as Map<String, dynamic>? ??
                        const {},
                  );
          ref
              .read(storyPlayProvider.notifier)
              .restart(StoryRepository.startNodeId);
          ref.read(homeTabIndexProvider.notifier).state = 0;
          // The dead character's last fight is the death screen's to tell,
          // not the next scene's.
          ref.read(lastFightOutcomeProvider.notifier).state = null;
          if (!mounted) return;
          await Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => DeathScreen(
                lostItemIds: result.lostItemIds,
                xpEarned: result.xpEarnedThisRun,
                skillsLost: result.skillsLost,
                nodesVisited: nodesVisited,
                killerName: _enemies.isEmpty ? '' : _enemies.first.displayName,
                narrationSeed: _random.nextInt(1 << 20),
              ),
            ),
            (route) => route.isFirst,
          );
          return;
        }
        Navigator.of(context).pop(_won);
      },
      child: Text(_won
          ? tr(ref, 'victory_return_button')
          : widget.modifiers.lossContinues
              ? tr(ref, 'defeat_continue_button')
              : tr(ref, 'retreat_button')),
    );
  }

  // --- Spells --------------------------------------------------------------

  /// Casts [spell] right now, like drinking a potion: picks its target(s)
  /// (a sheet when there's a real choice), applies the effect, spends the
  /// mana and persists it. Spells never crit, are never Weakened and
  /// ignore the Armored affix -- the number on the button is what lands.
  Future<void> _castSpell(
    SpellSpec spell,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
  ) async {
    if (_over || _rolling || !_started || _mana < spell.manaCost) return;
    final lang = ref.read(appLanguageProvider);
    final player = _party.firstWhere((m) => m.isPlayer);
    final amount = _spellAmountNow(spell, items);
    final status = spellStatusFor(spell, level: _playerLevel);

    final enemyTargets = <_EnemyMember>[];
    final memberTargets = <_PartyMember>[];
    switch (spell.target) {
      case SpellTarget.enemy:
        final living = _enemies.where((e) => e.isAlive).toList();
        if (living.isEmpty) return;
        final picked =
            living.length == 1 ? living.first : await _pickEnemy(living, spell);
        if (picked == null) return;
        enemyTargets.add(picked);
      case SpellTarget.allEnemies:
        enemyTargets.addAll(_enemies.where((e) => e.isAlive));
      case SpellTarget.ally:
        final conscious = _party.where((m) => !m.isKnockedOut).toList();
        if (conscious.isEmpty) return;
        final picked = conscious.length == 1
            ? conscious.first
            : await _pickMember(conscious, spell);
        if (picked == null) return;
        memberTargets.add(picked);
      case SpellTarget.party:
        memberTargets.addAll(_party.where((m) => !m.isKnockedOut));
      case SpellTarget.self:
        memberTargets.add(player);
    }
    if (!mounted || _over || _rolling) return;

    final entries = <_LogEntry>[
      _LogEntry(
        '${trFor(lang, 'cast_prefix')} ${spell.nameFor(lang)} '
        '(-${spell.manaCost} ${trFor(lang, 'mana_label')}). '
        '${spell.battleMessageFor(lang)}',
        _LogKind.mana,
      ),
    ];
    var hitsLanded = 0;
    for (final enemy in enemyTargets) {
      if (spell.effect == SpellEffectKind.damage) {
        final damage = amount;
        final wasAlive = enemy.isAlive;
        enemy.currentHealth = max(0, enemy.currentHealth - damage);
        if (damage > 0) {
          hitsLanded++;
          _lastDamagedEnemyKey = enemy.key;
          _lastEnemyDamageTaken = damage;
          if (spell.element != 'None') {
            enemy.elementsHitThisRound.add(spell.element);
          }
        }
        if (wasAlive && !enemy.isAlive) _lastKillWasCritical = false;
        entries.add(_LogEntry(
          '${enemy.displayName} ${trFor(lang, 'takes_damage_word')} $damage '
          '${trFor(lang, 'damage_word')}.',
          _LogKind.playerDamage,
        ));
      }
      if (status != null && enemy.isAlive) {
        enemy.statusEffects = applyStatusEffect(enemy.statusEffects, status);
        entries.add(_LogEntry(
          _statusInflictedMessage(status, enemy.displayName, lang),
          _LogKind.info,
        ));
      }
    }
    for (final member in memberTargets) {
      switch (spell.effect) {
        case SpellEffectKind.heal:
          var healing = amount;
          if (_condition == BattlefieldCondition.shrine) {
            healing = (healing * shrineHealMultiplier).round();
          }
          member.currentHealth =
              min(member.maxHealth, member.currentHealth + healing);
          entries.add(_LogEntry(
            '${member.displayName} ${trFor(lang, 'recovers_word')} $healing '
            '${trFor(lang, 'hp_label')}.',
            _LogKind.playerHeal,
          ));
        case SpellEffectKind.block:
          var block = amount;
          if (_condition == BattlefieldCondition.highGround) {
            block = (block * highGroundBlockMultiplier).round();
          }
          _spellBlock[member.id] = (_spellBlock[member.id] ?? 0) + block;
          member.block += block;
          entries.add(_LogEntry(
            '${member.displayName} ${trFor(lang, 'gains_block_word')} $block '
            '${trFor(lang, 'block_word')}.',
            _LogKind.playerBlock,
          ));
        case SpellEffectKind.cleanse:
          member.statusEffects = [];
          entries.add(_LogEntry(
            '${member.displayName} ${trFor(lang, 'cleansed_suffix')}',
            _LogKind.playerHeal,
          ));
        case SpellEffectKind.damage:
        case SpellEffectKind.status:
          break;
      }
    }
    _advanceBossPhases(entries, lang, skills);
    if (hitsLanded > 0) {
      final before = _momentum;
      _momentum = min(_momentumThreshold, _momentum + hitsLanded);
      if (before < _momentumThreshold && _momentum >= _momentumThreshold) {
        entries.add(
            _LogEntry(trFor(lang, 'momentum_ready_message'), _LogKind.info));
      }
    }
    _noteSkittishFlights(entries, lang);

    _mana -= spell.manaCost;
    ref.read(playerSessionProvider.notifier).setMana(_mana);
    setState(() {
      _log.addAll(entries);
      _autoAssignTargets();
    });

    if (_enemies.every((e) => !e.isAlive)) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      _finishFight(won: true);
    }
  }

  Future<_EnemyMember?> _pickEnemy(
      List<_EnemyMember> candidates, SpellSpec spell) {
    final lang = ref.read(appLanguageProvider);
    return showModalBottomSheet<_EnemyMember>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${spell.nameFor(lang)} · ${trFor(lang, 'choose_target_title')}',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            for (final enemy in candidates)
              ListTile(
                leading: EnemyPixelIcon(enemy.enemyId, size: 28),
                title: Text(enemy.displayName),
                subtitle: Text(
                    '${trFor(lang, 'hp_label')} ${enemy.currentHealth} / ${enemy.maxHealth}'),
                onTap: () => Navigator.of(sheetContext).pop(enemy),
              ),
          ],
        ),
      ),
    );
  }

  Future<_PartyMember?> _pickMember(
      List<_PartyMember> candidates, SpellSpec spell) {
    final lang = ref.read(appLanguageProvider);
    return showModalBottomSheet<_PartyMember>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${spell.nameFor(lang)} · ${trFor(lang, 'choose_target_title')}',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            for (final member in candidates)
              ListTile(
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: _accentFor(member),
                  child: Text(
                    member.displayName.isEmpty
                        ? '?'
                        : member.displayName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text(member.displayName),
                subtitle: Text(
                    '${trFor(lang, 'hp_label')} ${member.currentHealth} / ${member.maxHealth}'),
                onTap: () => Navigator.of(sheetContext).pop(member),
              ),
          ],
        ),
      ),
    );
  }

  // --- Small helpers -------------------------------------------------------

  static const List<Color> _allyAccents = [
    Colors.teal,
    Colors.deepPurple,
    Colors.orange,
    Colors.pink,
    Colors.brown,
  ];

  /// The color that stands for [member] everywhere on the battle screen:
  /// their die tile, their card, their target dot on an enemy.
  Color _accentFor(_PartyMember member) {
    if (member.isPlayer) return Theme.of(context).colorScheme.primary;
    final index = _party.indexWhere((m) => m.id == member.id) - 1;
    return _allyAccents[max(0, index) % _allyAccents.length];
  }
}

Color _faceTypeColor(String type) {
  switch (type) {
    case 'Attack':
      return Colors.deepOrange;
    case 'Defend':
      return Colors.blueGrey;
    case 'Heal':
      return Colors.green;
    case 'Mana':
      return manaColor;
    case 'Skill':
      return Colors.deepPurple;
    default:
      return Colors.grey;
  }
}

/// A small pill showing one active status effect's icon and how many
/// rounds it has left — the visual half of the status-effect system,
/// paired with the log lines [_FightScreenState] writes when one is
/// inflicted or ticks.
class _StatusEffectChip extends StatelessWidget {
  const _StatusEffectChip({required this.effect});

  final StatusEffect effect;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (effect.type) {
      StatusEffectType.poison => (Icons.coronavirus, Colors.green),
      StatusEffectType.stun => (Icons.flash_on, Colors.amber),
      StatusEffectType.weaken => (Icons.trending_down, Colors.purple),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            '${effect.remainingTurns}',
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// The setup screen's one-line note for a special encounter.
String _encounterNoteKey(EncounterModifiers modifiers) {
  if (modifiers.isHunt) return 'hunt_fight_note';
  if (modifiers.isZoneBoss) return 'zone_boss_fight_note';
  return 'hunter_fight_note';
}
