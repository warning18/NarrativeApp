import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/battlefield_condition.dart';
import '../combat/combat_aftermath.dart';
import '../combat/party_bonus.dart';
import '../combat/combat_engine.dart';
import '../combat/dice_faces.dart';
import '../combat/encounter.dart';
import '../combat/enemy_affix.dart';
import '../combat/gear_effects.dart';
import '../combat/loot_box.dart';
import '../combat/spells.dart';
import '../combat/status_effect.dart';
import '../data/encounter_text.dart';
import '../combat/skill_vfx.dart';
import '../widgets/combat_vfx.dart';
import '../widgets/item_stats.dart';
import '../data/chapter_spine.dart';
import '../data/story_repository.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/ally_state.dart';
import '../providers/aftermath_provider.dart';
import '../providers/app_mode_provider.dart';
import '../providers/combat_settings_provider.dart';
import '../providers/game_config_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/home_tab_provider.dart';
import '../providers/permadeath_provider.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import '../utils/game_icons.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import '../widgets/immersive_notice.dart';
import '../widgets/level_up_dialog.dart';
import '../widgets/spoils_chest_dialog.dart';
import 'death_screen.dart';

part 'fight/fight_actions.dart';
part 'fight/fight_cards.dart';
part 'fight/fight_controls.dart';
part 'fight/fight_effects.dart';
part 'fight/fight_models.dart';
part 'fight/fight_queries.dart';
part 'fight/fight_rewards.dart';
part 'fight/fight_rounds.dart';
part 'fight/fight_setup.dart';
part 'fight/fight_view.dart';
part 'fight/fight_widgets.dart';

const int _potionHealAmount = potionHealAmount;

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

/// The color of damage that is coming but not dealt yet: the slice of an
/// enemy's health bar the aimed dice would take off, and its "-N" chip
/// (see [_FightScreenState._buildHpBar]). Blue on purpose -- nothing else
/// on the enemy side is blue, so it never reads as damage already taken.
const Color _previewColor = Color(0xFF42A5F5);

/// Armor added to the player for one fight by a `charm_iron_skin`.
const int _ironSkinArmorBonus = 5;

/// The Poison a Venomous enemy's plain attack carries (see [EnemyAffix]).
const StatusEffect _venomousPoison = StatusEffect(
    type: StatusEffectType.poison, remainingTurns: 2, magnitude: 3);

const int _maxRolls = 3;

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

  /// True once [_finishFight] has applied everything (rewards, chest
  /// choices, the loss) -- only then can the fight be left.
  bool _settled = false;
  bool _leaving = false;

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

  /// The member the player chose to cash a ready momentum surge on (see
  /// [_FightQueries._surgeRecipient]); null lets the game pick.
  String? _surgeActorId;

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

  /// The on-screen effects (see combat_vfx.dart): each card is anchored by
  /// a key so an effect lands on the fighter it belongs to.
  final CombatVfxController _vfx = CombatVfxController();
  final Map<String, GlobalKey> _cardKeys = {};

  GlobalKey _memberCardKey(String id) =>
      _cardKeys.putIfAbsent('member:$id', GlobalKey.new);
  GlobalKey _enemyCardKey(String key) =>
      _cardKeys.putIfAbsent('enemy:$key', GlobalKey.new);

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
    _vfx.dispose();
    _rollController.dispose();
    super.dispose();
  }

  /// [setState] for the part files: it is @protected, so the extensions
  /// on this state (see fight/) call this instead.
  void _update(VoidCallback fn) => setState(fn);

  /// Members stunned when this round began. Their stun counts down at the
  /// start of the round (a one-turn stun is gone by the time the dice
  /// roll), so without this they would roll anyway -- they sit the whole
  /// round out instead, and their effects aren't ticked a second time.
  Set<String> _sittingOut = {};

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
        items, _itemSets, houses, dice);
    _spells = parseSpells(spellsDb);

    // Once the fight has begun, back is no way out of it: a fight in
    // progress must be finished, and a finished one is left through
    // [_leaveFight], so a loss always counts (its story branch and, with
    // permadeath on, the death) and a win is never walked away from before
    // the story records it.
    return PopScope(
      canPop: !_started,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_over) {
          _leaveFight();
          return;
        }
        showImmersiveNotice(
          context,
          icon: Icons.sports_martial_arts,
          message: tr(ref, 'fight_not_over_notice'),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${tr(ref, 'fight_prefix')}: ${_battleTitle()}'),
          actions: [
            if (_canRetreat)
              IconButton(
                icon: const Icon(Icons.directions_run),
                tooltip: tr(ref, 'retreat_button'),
                onPressed: _rolling ? null : _retreat,
              ),
            // Edit mode only: skip a fight while testing the story.
            if (ref.watch(appModeProvider) == AppMode.edit && !_over)
              IconButton(
                icon: const Icon(Icons.emoji_events_outlined),
                tooltip: tr(ref, 'edit_auto_win_tooltip'),
                onPressed: _rolling ? null : () => _autoWin(skills, items),
              ),
          ],
        ),
        body: !_started
            ? _buildSetup(dice, skills, items, session)
            : _buildBattle(dice, skills, items, session),
      ),
    );
  }
}
