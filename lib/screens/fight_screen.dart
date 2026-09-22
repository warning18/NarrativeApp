import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_engine.dart';
import '../combat/status_effect.dart';
import '../data/story_repository.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/ally_state.dart';
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
/// three chapter-2 heavies were a 0% fight at level 3). Solo fights are
/// never scaled.
const Map<int, double> _packStatMultipliers = {2: 0.85, 3: 0.75};

/// A Defend face rolled by the party member an enemy is visibly (see
/// [telegraphTierFor]) about to hit blocks this many times its face value
/// -- the tactical payoff for reading a telegraph: brace where the blow is
/// coming, not where it isn't.
const int _telegraphBraceMultiplier = 2;

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
  banter
}

class _LogEntry {
  const _LogEntry(this.text, this.kind);

  final String text;
  final _LogKind kind;
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
  });

  final String id;
  final String displayName;
  final bool isPlayer;
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
  });

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
  final Map<String, dynamic> data;

  final int maxHealth;

  /// Player-level-scaled (and Elite-multiplied for a solo Elite) damage.
  final int damage;

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

  bool get isAlive => currentHealth > 0;
}

class FightScreen extends ConsumerStatefulWidget {
  const FightScreen({
    super.key,
    required this.enemyId,
    required this.enemy,
    this.additionalEnemyIds = const [],
    this.additionalEnemies = const {},
  });

  final String enemyId;
  final Map<String, dynamic> enemy;

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

  String? _selectedDiceId;
  bool _rolling = false;

  bool _partyBuilt = false;
  List<_PartyMember> _party = [];

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

  /// Builds [_enemies] — a solo fight rolls Elite (see [_eliteChance]); a
  /// pack (`widget.additionalEnemyIds` non-empty) never does. A pack member
  /// sharing a base name with another gets a " #2"/" #3" suffix on its own
  /// [_EnemyMember.displayName] so the two are distinguishable in the UI;
  /// a solo fight or an all-distinct pack never shows one.
  void _ensureEnemiesBuilt() {
    final entries = widget._allEnemyEntries;
    final lang = ref.read(appLanguageProvider);
    _isElite = entries.length == 1 &&
        !soloOnlyEnemyIds.contains(entries.first.key) &&
        _random.nextDouble() < _eliteChance;

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
  }) {
    final elitePrefixedName =
        _isElite ? '${trFor(lang, 'elite_prefix')} $baseName' : baseName;
    final data = _isElite ? {...raw, 'enemyName': elitePrefixedName} : raw;
    String displayName;
    if (isDuplicateName) {
      seenSoFar[baseName] = (seenSoFar[baseName] ?? 0) + 1;
      displayName = '$elitePrefixedName #${seenSoFar[baseName]}';
    } else {
      displayName = elitePrefixedName;
    }
    var maxHealth =
        scaledMaxHealth((raw['maxHealth'] as num?)?.toInt() ?? 1, _playerLevel);
    var damage =
        scaledDamage((raw['damage'] as num?)?.toInt() ?? 0, _playerLevel);
    if (_isElite) {
      maxHealth = (maxHealth * _eliteStatMultiplier).round();
      damage = (damage * _eliteStatMultiplier).round();
    }
    final packMultiplier = _packStatMultipliers[packSize];
    if (packMultiplier != null) {
      maxHealth = max(1, (maxHealth * packMultiplier).round());
      damage = (damage * packMultiplier).round();
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
    );
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
  ) {
    if (_partyBuilt) return;
    _partyBuilt = true;
    _companions = companions;

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
      maxHealth: session.maxHealth,
      baseDamage: session.baseDamage,
      armor: session.baseArmor,
      currentHealth:
          session.currentHealth > 0 ? session.currentHealth : session.maxHealth,
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
      final liveMaxHealth = scaledMaxHealth(base.maxHealth, _playerLevel);
      activeAllies.add(_PartyMember(
        id: companionId,
        displayName: companion['companionName']?.toString() ?? companionId,
        isPlayer: false,
        maxHealth: liveMaxHealth,
        baseDamage: scaledDamage(base.baseDamage, _playerLevel),
        armor: base.baseArmor,
        currentHealth: allyState.currentHealth.clamp(0, liveMaxHealth),
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

  /// True when some living enemy's pre-rolled next move is aimed at
  /// [member] AND the party can currently read that telegraph at all (see
  /// [telegraphTierFor]) -- the condition under which a Defend face rolled
  /// by [member] braces for the visible blow ([_telegraphBraceMultiplier]).
  bool _isTelegraphedTarget(_PartyMember member) {
    final perception = _bestPartyPerception();
    for (final enemy in _enemies) {
      final pending = enemy.pendingMove;
      if (!enemy.isAlive || pending == null || pending.targetId != member.id) {
        continue;
      }
      if (telegraphTierFor(perception, enemy.guile) != TelegraphTier.none) {
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
  /// (other than [excludeId], so nobody reacts to their own crit or dodge)
  /// to say a short line from their own companions.json `critLine`/
  /// `dodgeLine` — null whenever there's simply nobody around to react (a
  /// solo player, or every ally already knocked out), the line rolled
  /// against and missed, or the chosen companion has no line authored for
  /// this language/event.
  _LogEntry? _rollBanter({required bool isCrit, String? excludeId}) {
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
    final key = isCrit
        ? (lang == AppLanguage.fr ? 'critLineFr' : 'critLine')
        : (lang == AppLanguage.fr ? 'dodgeLineFr' : 'dodgeLine');
    final line = companion[key]?.toString();
    if (line == null || line.isEmpty) return null;
    return _LogEntry('${speaker.displayName}: "$line"', _LogKind.banter);
  }

  void _startFight(Map<String, dynamic> skills) {
    final lang = ref.read(appLanguageProvider);
    for (final enemy in _enemies) {
      _preRollMoveFor(enemy, skills);
    }
    final hpSuffix = _enemies.length == 1
        ? ' ${trFor(lang, 'has_label')} ${_enemies.first.maxHealth} ${trFor(lang, 'hp_label')}'
        : '';
    setState(() {
      _started = true;
      _log.add(
        _LogEntry(
          '${trFor(lang, 'fight_begins_prefix')} ${_battleTitle()}$hpSuffix.',
          _LogKind.info,
        ),
      );
    });
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
    if (_over || _rolling || _rollCount >= _maxRolls) return;
    final acting = _actingParty;

    final rolled = <String, DiceFaceResult>{};
    for (final actor in acting) {
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
    final forced = rollNumber >= _maxRolls;
    setState(() {
      _rolling = false;
      _rollCount = rollNumber;
      _currentFaces
        ..clear()
        ..addAll(rolled);
      _awaitingDecision = !forced;
    });

    if (forced) {
      // No choice left — give the player a beat to see the 3rd faces land
      // before they resolve on their own.
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      await _confirmRoll(skills, items);
    }
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
    for (final actor in _actingParty) {
      final face = _currentFaces[actor.id];
      if (face == null) continue;

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
      final totalDamage = actor.baseDamage +
          equipmentBonusFor(actor.equippedItemIds, items, 'attackDamage') +
          scalingBonus.damageBonus +
          elementalBonus;
      final result = resolvePlayerFace(
        face,
        availableSkills,
        totalDamage,
        language: lang,
        activeEffects: actor.statusEffects,
        wisdomHealBonus: actor.wisdom ~/ 2,
        luck: actor.luck,
        random: _random,
      );
      final kind = result.damageDealt > 0
          ? _LogKind.playerDamage
          : result.healingDone > 0
              ? _LogKind.playerHeal
              : result.blockAmount > 0
                  ? _LogKind.playerBlock
                  : _LogKind.info;

      if (result.isCritical) lastCritActorId = actor.id;
      actor.currentHealth =
          min(actor.maxHealth, actor.currentHealth + result.healingDone);
      final braced = result.blockAmount > 0 && _isTelegraphedTarget(actor);
      actor.block = braced
          ? result.blockAmount * _telegraphBraceMultiplier
          : result.blockAmount;
      newEntries
          .add(_LogEntry('${_actorPrefix(actor)}${result.message}', kind));
      if (braced) {
        newEntries.add(_LogEntry(
          '${actor.displayName} ${trFor(lang, 'braced_suffix')} (${actor.block})',
          _LogKind.playerBlock,
        ));
      }

      _EnemyMember? target;
      if (face.type == 'Attack' || face.type == 'Skill') {
        if (_enemies.length == 1) {
          target = _enemies.first.isAlive ? _enemies.first : null;
        } else {
          final key = _selectedTargets[actor.id];
          final picked = key == null ? null : _enemyByKey(key);
          target = (picked != null && picked.isAlive) ? picked : null;
        }
      }

      if (target != null) {
        target.currentHealth =
            max(0, target.currentHealth - result.damageDealt);
        if (result.damageDealt > 0) {
          lastDamagedEnemyKey = target.key;
          lastEnemyDamage = result.damageDealt;
        }
        if (element != 'None' && result.damageDealt > 0) {
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

    // Each acting member's own effects count down once their turn is over
    // (see tickStatusEffects) -- ticking at the start of the round instead
    // silently ate the first (and, under Wisdom resistance, only) turn of
    // every Weaken landed on the party.
    for (final actor in _actingParty) {
      actor.statusEffects = tickStatusEffects(actor.statusEffects);
    }

    if (lastCritActorId != null) {
      final banter = _rollBanter(isCrit: true, excludeId: lastCritActorId);
      if (banter != null) newEntries.add(banter);
    }

    setState(() {
      _awaitingDecision = false;
      _rollCount = 0;
      _currentFaces.clear();
      _selectedTargets.clear();
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
            newEntries.add(_LogEntry(
              '${member.displayName} ${trFor(lang, 'is_knocked_out_suffix')}',
              _LogKind.defeat,
            ));
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

    setState(() {
      _log.addAll(newEntries);
      _rollCount = 0;
      _currentFaces.clear();
      _selectedTargets.clear();
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
  /// who it lands on is renegotiated.
  void _takeEnemyTurn(Map<String, dynamic> skills, Map<String, dynamic> items) {
    final lang = ref.read(appLanguageProvider);

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

      final pending = enemy.pendingMove ?? _rollMoveAndTargetFor(enemy, skills);
      final move = pending.move;
      final moveDamage = applyWeaken(move.damage, enemy.statusEffects);

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
      final totalArmor = target.armor +
          equipmentBonusFor(target.equippedItemIds, items, 'armor') +
          targetScalingBonus.armorBonus;
      final elementalResist =
          _elementalResist(move.element, target.equippedItemIds, items);
      // A dodge evades the hit outright -- no damage, no status effect --
      // rather than just softening it further on top of block/armor/resist.
      final wasDodged =
          _random.nextDouble() * 100 < dodgeChanceFor(target.dexterity);
      final damageTaken = wasDodged
          ? 0
          : max(0, moveDamage - target.block - totalArmor - elementalResist);
      final wasKnockedOutAlready = target.isKnockedOut;

      setState(() {
        target.currentHealth = max(0, target.currentHealth - damageTaken);
        target.block = 0;
        _lastDamageTaken = damageTaken;
        _lastDamagedMemberId = target.id;
        if (wasDodged) {
          _log.add(_LogEntry(
            target.isPlayer
                ? '${move.message} ${trFor(lang, 'you_dodge_suffix')}'
                : '${move.message} ${target.displayName} '
                    '${trFor(lang, 'dodges_suffix')}',
            _LogKind.playerBlock,
          ));
          final banter = _rollBanter(isCrit: false, excludeId: target.id);
          if (banter != null) _log.add(banter);
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
            _log.add(
              _LogEntry(
                '${target.displayName} ${trFor(lang, 'is_knocked_out_suffix')}',
                _LogKind.defeat,
              ),
            );
          }
          final inflicted = move.inflictedStatus;
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
    setState(() {
      player.currentHealth =
          min(player.maxHealth, player.currentHealth + _potionHealAmount);
      _log.add(
        _LogEntry(
          '${trFor(lang, 'drink_potion_prefix')} $_potionHealAmount ${trFor(lang, 'hp_label')}.',
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

    final notifier = ref.read(playerSessionProvider.notifier);
    final player = _party.firstWhere((m) => m.isPlayer);
    if (won) {
      // Every enemy that died in this fight -- a pack's rewards/loot are
      // summed across all of them, not just the one FightScreen was
      // originally constructed with.
      final defeated = _enemies.where((e) => !e.isAlive).toList();
      var goldGain = 0;
      var xpGain = 0;
      // An Elite always drops its trophy on top of the enemy's own loot
      // table roll below -- the guaranteed "that was worth it" payoff for
      // the harder fight, on top of the reward multiplier applied per
      // enemy. Elite is solo-only, so this never double-applies for a pack.
      final loot = <String>[if (_isElite) 'elite_trophy'];
      // Luck nudges the drop-rate roll directly (in percentage points), so
      // a lucky character sees noticeably better loot without any roll
      // ever becoming guaranteed unless the base rate was already close.
      // A profession-matching item (a Mage's own staves, say) gets its own
      // separate bonus on top -- see professionLootAffinityBonus.
      final session = ref.read(playerSessionProvider);
      final luckBonus = session.luck;
      final items = ref.read(gameDbProvider(itemsSchema)).value ?? const {};
      final professions =
          ref.read(gameDbProvider(professionsSchema)).value ?? const {};
      final preferredScalingStat = (professions[session.professionId]
                  as Map<String, dynamic>?)?['preferredScalingStat']
              ?.toString() ??
          '';
      for (final enemy in defeated) {
        var enemyGold = scaledReward(
            (enemy.data['goldReward'] as num?)?.toInt() ?? 0, _playerLevel);
        var enemyXp = scaledReward(
            (enemy.data['xpReward'] as num?)?.toInt() ?? 0, _playerLevel);
        if (_isElite) {
          enemyGold = (enemyGold * _eliteRewardMultiplier).round();
          enemyXp = (enemyXp * _eliteRewardMultiplier).round();
        }
        goldGain += enemyGold;
        xpGain += enemyXp;
        final lootTable =
            (enemy.data['lootTable'] as List?)?.cast<Map<String, dynamic>>() ??
                const [];
        for (final entry in lootTable) {
          final dropRate = (entry['dropRate'] as num?)?.toDouble() ?? 0;
          final itemId = entry['itemID']?.toString();
          final affinityBonus = professionLootAffinityBonus(
              itemId != null ? items[itemId] as Map<String, dynamic>? : null,
              preferredScalingStat);
          if (_random.nextDouble() * 100 <=
              dropRate + luckBonus + affinityBonus) {
            if (itemId != null && itemId.isNotEmpty) loot.add(itemId);
          }
        }
      }
      final leveledUp = await notifier.applyCombatResult(
        hpAfter: player.currentHealth,
        enemyIds: defeated.map((e) => e.enemyId).toList(),
        goldGain: goldGain,
        xpGain: xpGain,
        itemsGained: loot,
        items: items,
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
      final lang = ref.read(appLanguageProvider);
      setState(() {
        _log.add(
          _LogEntry(
            '${trFor(lang, 'victory_prefix')} +$goldGain ${trFor(lang, 'gold_label')}, '
            '+$xpGain XP'
            '${loot.isNotEmpty ? ", ${trFor(lang, 'loot_label')}: ${loot.join(", ")}" : ""}.',
            _LogKind.victory,
          ),
        );
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
      await notifier.applyCombatResult(hpAfter: player.maxHealth);
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
    final session = ref.watch(playerSessionProvider);

    final dice = diceAsync.value;
    final skills = skillsAsync.value;
    final items = itemsAsync.value;
    final companions = companionsAsync.value;
    final races = racesAsync.value;
    final professions = professionsAsync.value;
    final gameConfig = gameConfigAsync.value;

    if (dice == null ||
        skills == null ||
        items == null ||
        companions == null ||
        races == null ||
        professions == null ||
        gameConfig == null) {
      final error = diceAsync.error ??
          skillsAsync.error ??
          itemsAsync.error ??
          companionsAsync.error ??
          racesAsync.error ??
          professionsAsync.error ??
          gameConfigAsync.error;
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

    _ensurePartyBuilt(session, companions, races, professions, gameConfig);

    return Scaffold(
      appBar: AppBar(
        title: Text('${tr(ref, 'fight_prefix')}: ${_battleTitle()}'),
      ),
      body: !_started
          ? _buildSetup(dice, skills, items)
          : _buildBattle(dice, skills, items, session),
    );
  }

  Widget _buildSetup(
    Map<String, dynamic> dice,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
  ) {
    final player = _party.first;
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final enemy in _enemies) ...[
            _buildEnemySetupCard(enemy),
            const SizedBox(height: 8),
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
            onPressed: equippedDie == null ? null : () => _startFight(skills),
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
            ],
          ),
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

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final t = _shakeController.value;
        final decay = 1 - t;
        final dx = sin(t * pi * 8) * decay * 8;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final member in _party) ...[
              _buildMemberHealthBar(member, items),
              const SizedBox(height: 8),
            ],
            for (final enemy in _enemies) ...[
              _buildEnemyHealthBar(enemy),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  reverse: true,
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
            ),
            const SizedBox(height: 16),
            if (_currentFaces.isNotEmpty) ...[
              for (final actor in acting)
                if (_currentFaces[actor.id] != null) ...[
                  _buildDieFaceCard(
                      actor, _currentFaces[actor.id]!, skills, items),
                  const SizedBox(height: 8),
                ],
              const SizedBox(height: 4),
            ],
            if (_over)
              ElevatedButton(
                onPressed: () async {
                  if (!_won && ref.read(permadeathEnabledProvider)) {
                    final nodesVisited =
                        ref.read(storyPlayProvider).history.length + 1;
                    final playerSession = ref.read(playerSessionProvider);
                    final races =
                        ref.read(gameDbProvider(racesSchema)).value ?? const {};
                    final professions =
                        ref.read(gameDbProvider(professionsSchema)).value ??
                            const {};
                    final result = await ref
                        .read(playerSessionProvider.notifier)
                        .applyPermadeath(
                          race: races[playerSession.raceId]
                                  as Map<String, dynamic>? ??
                              const {},
                          profession: professions[playerSession.professionId]
                                  as Map<String, dynamic>? ??
                              const {},
                        );
                    ref
                        .read(storyPlayProvider.notifier)
                        .restart(StoryRepository.startNodeId);
                    ref.read(homeTabIndexProvider.notifier).state = 0;
                    if (!mounted) return;
                    await Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => DeathScreen(
                          lostItemIds: result.lostItemIds,
                          xpEarned: result.xpEarnedThisRun,
                          skillsLost: result.skillsLost,
                          nodesVisited: nodesVisited,
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
                    : tr(ref, 'retreat_button')),
              )
            else ...[
              if (_awaitingDecision)
                Row(
                  children: [
                    if (_rollCount < _maxRolls) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _rolling
                              ? null
                              : () => _rollDice(dice, skills, items),
                          icon: const Icon(Icons.refresh),
                          label: Text(
                              '${tr(ref, 'reroll_button')} ($_rollCount/$_maxRolls)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_rolling || !_allTargetsPicked)
                            ? null
                            : () => _confirmRoll(skills, items),
                        icon: const Icon(Icons.check),
                        label: Text(tr(ref, 'confirm_roll_button')),
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: (!anyDieAvailable || _rolling)
                      ? null
                      : () => _rollDice(dice, skills, items),
                  icon: const Icon(Icons.casino),
                  label: Text(
                    acting.length > 1
                        ? '${tr(ref, 'roll_dice_button')} (${acting.length}×)'
                        : tr(ref, 'roll_dice_button'),
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed:
                    (session.potionCount > 0 && !_rolling) ? _usePotion : null,
                icon: const Icon(Icons.local_drink),
                label: Text(
                    '${tr(ref, 'potion_button_prefix')} (${session.potionCount})'),
              ),
              if (_party.first.statusEffects.isNotEmpty) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: (session.antidoteCount > 0 && !_rolling)
                      ? _useAntidote
                      : null,
                  icon: const Icon(Icons.healing),
                  label: Text(
                      '${tr(ref, 'antidote_button_prefix')} (${session.antidoteCount})'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMemberHealthBar(
      _PartyMember member, Map<String, dynamic> items) {
    final memberScalingBonus = equipmentScalingBonusFor(
      member.equippedItemIds,
      items,
      strength: member.strength,
      dexterity: member.dexterity,
      constitution: member.constitution,
      intelligence: member.intelligence,
    );
    final armorBonus =
        equipmentBonusFor(member.equippedItemIds, items, 'armor') +
            memberScalingBonus.armorBonus;
    final damageBonus =
        equipmentBonusFor(member.equippedItemIds, items, 'attackDamage') +
            memberScalingBonus.damageBonus;
    final label = member.displayName;
    final bar = _HealthBar(
      label: member.isKnockedOut
          ? '$label (${tr(ref, 'knocked_out_label')})'
          : label,
      current: member.currentHealth,
      max: member.maxHealth,
      statLine:
          '⚔ ${member.baseDamage + damageBonus}  ·  🛡 ${member.armor + armorBonus}',
      statusEffects: member.statusEffects,
    );
    if (_lastDamagedMemberId != member.id || _lastDamageTaken <= 0) return bar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        bar,
        Positioned(
          right: 0,
          top: -4,
          child: AnimatedBuilder(
            animation: _shakeController,
            builder: (context, _) => Opacity(
              opacity: (1 - _shakeController.value).clamp(0.0, 1.0),
              child: Text(
                '-$_lastDamageTaken',
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// One enemy's health bar during battle -- mirrors
  /// [_buildMemberHealthBar]'s floating "-N" indicator, and adds the
  /// telegraph badge (see [_buildEnemyTelegraphBadge]) underneath.
  Widget _buildEnemyHealthBar(_EnemyMember enemy) {
    final bar = _HealthBar(
      label: enemy.displayName,
      current: enemy.currentHealth,
      max: enemy.maxHealth,
      statLine: '⚔ ${enemy.damage}',
      statusEffects: enemy.statusEffects,
    );
    final withIndicator =
        (_lastDamagedEnemyKey != enemy.key || _lastEnemyDamageTaken <= 0)
            ? bar
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  bar,
                  Positioned(
                    right: 0,
                    top: -4,
                    child: Text(
                      '-$_lastEnemyDamageTaken',
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
    final badge = _buildEnemyTelegraphBadge(enemy);
    if (badge == null) return withIndicator;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        withIndicator,
        const SizedBox(height: 2),
        badge,
      ],
    );
  }

  /// A tiered preview of [enemy]'s pre-rolled next move (see
  /// [_preRollMoveFor]), gated by [telegraphTierFor] -- null (nothing
  /// rendered) when the party's best Perception can't read this enemy at
  /// all, or when it hasn't got a cached move to preview yet (a
  /// [_EnemyMember.hasReactiveMoves] enemy, or before the fight's first
  /// pre-roll runs).
  Widget? _buildEnemyTelegraphBadge(_EnemyMember enemy) {
    final pending = enemy.pendingMove;
    if (pending == null) return null;
    final tier = telegraphTierFor(_bestPartyPerception(), enemy.guile);
    if (tier == TelegraphTier.none) return null;

    final target = _memberById(pending.targetId);
    final targetName = target?.displayName ?? '?';
    final chips = <Widget>[
      _telegraphChip(Icons.gps_fixed, targetName),
    ];
    if (tier == TelegraphTier.category || tier == TelegraphTier.full) {
      final (icon, labelKey) = switch (categoryFor(pending.move)) {
        MoveCategory.attack => (Icons.bolt, 'telegraph_category_attack'),
        MoveCategory.healSelf => (Icons.healing, 'telegraph_category_heal'),
        MoveCategory.statusDebuff => (Icons.sick, 'telegraph_category_debuff'),
      };
      chips.add(_telegraphChip(icon, tr(ref, labelKey)));
    }
    if (tier == TelegraphTier.full) {
      if (pending.move.element != 'None') {
        chips.add(_telegraphChip(
            elementIcon(pending.move.element), pending.move.element));
      }
      chips.add(_telegraphChip(Icons.forum, pending.move.message));
    }

    return Wrap(spacing: 6, runSpacing: 2, children: chips);
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

  /// The target-picker row shown under an acting member's Attack/Skill face
  /// when there's more than one enemy to choose from -- a `ChoiceChip` per
  /// living enemy, tapped to set [_selectedTargets]. Not shown at all for a
  /// solo fight, or for a Defend/Heal face (nothing for it to hit).
  Widget _buildTargetPicker(_PartyMember actor) {
    final selectedKey = _selectedTargets[actor.id];
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final enemy in _enemies.where((e) => e.isAlive))
          ChoiceChip(
            label: Text('${enemy.displayName} (${enemy.currentHealth})'),
            selected: enemy.key == selectedKey,
            onSelected: (_) =>
                setState(() => _selectedTargets[actor.id] = enemy.key),
          ),
      ],
    );
  }

  /// The most recently rolled face, kept on screen so the player always
  /// knows what they're looking at — spinning while a roll is in flight,
  /// settled (face name, which skill it maps to if it's a Skill face, and
  /// a preview of what confirming it will do) once it lands.
  Widget _buildDieFaceCard(
    _PartyMember actor,
    DiceFaceResult face,
    Map<String, dynamic> skills,
    Map<String, dynamic> items,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget content;
    if (_rolling) {
      content = Text(tr(ref, 'rolling_label'),
          style: Theme.of(context).textTheme.bodySmall);
    } else {
      final availableSkills = _availableSkillsFor(actor, skills);
      final elementalBonus = _elementalDamageBonus(
          _elementFor(face, availableSkills), actor.equippedItemIds, items);
      final previewScalingBonus = equipmentScalingBonusFor(
        actor.equippedItemIds,
        items,
        strength: actor.strength,
        dexterity: actor.dexterity,
        constitution: actor.constitution,
        intelligence: actor.intelligence,
      );
      final totalDamage = actor.baseDamage +
          equipmentBonusFor(actor.equippedItemIds, items, 'attackDamage') +
          previewScalingBonus.damageBonus +
          elementalBonus;
      final preview = resolvePlayerFace(
        face,
        availableSkills,
        totalDamage,
        language: ref.read(appLanguageProvider),
        activeEffects: actor.statusEffects,
      );
      final needsTarget = _enemies.length > 1 &&
          (face.type == 'Attack' || face.type == 'Skill');
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_party.length > 1)
            Text(
              actor.displayName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          Text(
            face.faceName.isEmpty ? face.type : face.faceName,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          if (face.type == 'Skill') ...[
            const SizedBox(height: 2),
            Text(
              '${tr(ref, 'skill_label')}: ${_effectiveSkillId(face)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic, color: colorScheme.primary),
            ),
          ],
          const SizedBox(height: 2),
          Text(preview.message, style: Theme.of(context).textTheme.bodySmall),
          if (needsTarget) ...[
            const SizedBox(height: 6),
            _buildTargetPicker(actor),
          ],
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: _awaitingDecision
            ? colorScheme.primaryContainer.withValues(alpha: 0.25)
            : null,
        border: Border.all(
          color: _awaitingDecision
              ? colorScheme.primary
              : colorScheme.outlineVariant,
          width: _awaitingDecision ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: Center(
              child: _rolling
                  ? AnimatedBuilder(
                      animation: _rollController,
                      builder: (context, _) {
                        final t = _rollController.value;
                        final angle = Curves.easeOutCubic.transform(t) * 6 * pi;
                        final scale = 1 + (sin(t * pi) * 0.25);
                        return Transform.rotate(
                          angle: angle,
                          child: Transform.scale(
                            scale: scale,
                            child: Icon(Icons.casino,
                                size: 30, color: colorScheme.primary),
                          ),
                        );
                      },
                    )
                  : Icon(_faceTypeIcon(face.type),
                      size: 30, color: colorScheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _HealthBar extends StatelessWidget {
  const _HealthBar({
    required this.label,
    required this.current,
    required this.max,
    this.statLine,
    this.statusEffects = const [],
  });

  final String label;
  final int current;
  final int max;

  /// An optional line of extra stats (e.g. "⚔ 12 · 🛡 4") shown under the bar.
  final String? statLine;

  /// Poison/Stun/Weaken currently afflicting this combatant, shown as a row
  /// of small chips below the bar — empty renders nothing extra.
  final List<StatusEffect> statusEffects;

  @override
  Widget build(BuildContext context) {
    final rawRatio = max <= 0 ? 0.0 : current / max;
    final ratio = rawRatio < 0 ? 0.0 : (rawRatio > 1 ? 1.0 : rawRatio);
    final barColor = ratio > 0.5
        ? Colors.green
        : (ratio > 0.25 ? Colors.orange : Colors.red);
    const barHeight = 26.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: barHeight,
            decoration: BoxDecoration(
              color: barColor.withValues(alpha: 0.18),
              border: Border.all(color: barColor.withValues(alpha: 0.5)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    alignment: Alignment.centerLeft,
                    width: constraints.maxWidth * ratio,
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [barColor.withValues(alpha: 0.75), barColor],
                      ),
                    ),
                  ),
                ),
                Text(
                  '$current / $max',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (statLine != null) ...[
          const SizedBox(height: 2),
          Text(statLine!, style: Theme.of(context).textTheme.bodySmall),
        ],
        if (statusEffects.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final effect in statusEffects)
                _StatusEffectChip(effect: effect),
            ],
          ),
        ],
      ],
    );
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
