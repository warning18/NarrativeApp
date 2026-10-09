import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/battlefield_condition.dart';
import '../data/weather_effects.dart';
import '../providers/climate_provider.dart';
import '../combat/combat_aftermath.dart';
import '../combat/party_bonus.dart';
import '../combat/combat_engine.dart';
import '../combat/dice_faces.dart';
import '../combat/dice_tamper.dart';
import '../combat/duo_techniques.dart';
import '../combat/face_smithing.dart';
import '../combat/party_combos.dart';
import '../combat/encounter.dart';
import '../combat/doctrine.dart';
import '../combat/element_reaction.dart';
import '../combat/parry.dart';
import '../combat/loadout.dart';
import '../combat/quick_resolve.dart';
import '../combat/turn_order.dart';
import '../combat/enemy_affix.dart';
import '../combat/fight_goal.dart';
import '../combat/gear_effects.dart';
import '../combat/loot_box.dart';
import '../combat/spells.dart';
import '../combat/status_effect.dart';
import '../data/encounter_text.dart';
import '../data/item_origin_here.dart';
import '../data/factions.dart'
    show ClanData, Host, parseFactions, parseSubclans, parseTitles;
import '../data/offers.dart' show clanEffectsFor;
import '../data/throne.dart' show fieldedHost, hostEffects;
import '../data/skill_tree.dart';
import '../combat/skill_vfx.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../widgets/combat_vfx.dart';
import '../widgets/item_stats.dart';
import '../data/approval.dart';
import '../data/chapter_loop.dart';
import '../data/journey_rules.dart';
import '../providers/chapter_loop_provider.dart' show reachedChapterProvider;
import '../data/perks.dart';
import '../data/signs.dart';
import '../data/contracts.dart' show ContractTally;
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
import '../theme/stitched_ink.dart';
import '../utils/face_style.dart';
import '../utils/game_icons.dart';
import '../utils/pixel_icons/game_pixel_icons.dart';
import '../widgets/immersive_notice.dart';
import '../widgets/level_up_dialog.dart';
import '../widgets/offer_dialog.dart';
import '../widgets/spoils_chest_dialog.dart';
import 'death_screen.dart';

part 'fight/fight_actions.dart';
part 'fight/fight_cards.dart';
part 'fight/fight_controls.dart';
part 'fight/fight_clash.dart';
part 'fight/fight_dice_rules.dart';
part 'fight/fight_effects.dart';
part 'fight/fight_goals.dart';
part 'fight/fight_lucky_die.dart';
part 'fight/fight_models.dart';
part 'fight/fight_quick.dart';
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

  /// How much stronger the chapter's enemies have grown while the party
  /// lingered (see journey_rules.dart); bosses keep their tuning.
  double _threat = 0;

  /// What the hired sellsword deals each round (0: none hired, see
  /// journey_rules.dart).
  int _sellswordStrike = 0;

  /// Resolve and the camp's works, resolved once at party build (see
  /// party_bonus.dart).
  PartyBonus _partyBonus = PartyBonus.none;

  /// The Host beside the party in one of the last battles (v1.196, see
  /// throne.dart), fixed at party build; [Host.none] in any other fight.
  Host _host = Host.none;

  /// The factions the Host's contingents are named from.
  ClanData _hostData = ClanData.empty;

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

  /// The first fight's lucky die (see fight_lucky_die.dart): whether the
  /// fight's tour may play yet, and the timer that lets it, a moment after
  /// the die has struck.
  bool _luckyDieTourReady = false;
  Timer? _luckyDieTourTimer;
  List<_PartyMember> _party = [];

  /// This fight's one-off circumstance, if any -- see
  /// battlefield_condition.dart. Rolled once in [_ensureEnemiesBuilt].
  BattlefieldCondition? _condition;

  /// True while a quick resolve plays the fight (v1.213, see
  /// quick_resolve.dart): short animations, the choices made for the
  /// player, a Stop button in place of the dice.
  bool _quick = false;

  /// Which enemy each defender's Defend face parries this round (v1.214,
  /// see parry.dart): actor id -> enemy key. Empty means a plain guard.
  final Map<String, String> _parryTargets = {};

  /// What this fight asks of the party besides killing everything
  /// (v1.212, see fight_goal.dart). Rolled once in [_ensureEnemiesBuilt].
  FightGoal _goal = FightGoal.slay;

  /// The doctrine the enemies fight under, if any (v1.212, see
  /// doctrine.dart). Set once in [_ensureEnemiesBuilt].
  Doctrine? _doctrine;

  /// What the day's sky does to this fight (v1.208, see
  /// weather_effects.dart): set once in [_ensureEnemiesBuilt].
  WeatherEffects _sky = WeatherEffects.of(null);

  /// Party rounds begun so far -- the spoils chest's "swift fight" bonus
  /// reads this, and an Ambush hides every telegraph while it's still 1.
  int _roundsStarted = 0;

  /// The member whose kept Defend face draws the enemies' attacks this
  /// round (see _confirmRoll): null outside a party fight or when nobody
  /// defended.
  String? _guardianId;

  /// Wind-ups the party broke this fight (see _checkChargeBreaks), and
  /// hits that landed on a weakness: both count on the camp's bounty board.
  int _chargesBroken = 0;
  int _weaknessHits = 0;

  /// Damaging party hits landed, less one for every hit the party takes
  /// (see momentumAfterHit). At [_momentumThreshold] the next Attack/Skill
  /// face is a guaranteed critical (which spends it).
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

  /// The player's level-up perks (see perks.dart), read at party build.
  PerkEffects _perks = PerkEffects.none;

  /// The player's signs (see signs.dart), read at party build like the
  /// perks, and the signs table for their names in the log.
  SignEffects _signs = SignEffects.none;
  Map<String, SignDef> _signDefs = const {};

  /// Health a running pact's curse took before the fight began, for the
  /// opening log.
  int _signStartCurseTaken = 0;

  /// A Defend face the player played this round arms the guard signs
  /// (retaliation, the guard's statuses) for the enemies' turn after it.
  bool _signGuardArmed = false;

  /// Enemies whose fall a kill-heal sign has already fed on.
  final Set<String> _signKillsFed = {};

  /// Hits needed for a surge: [_momentumThreshold], less a Battle Rhythm
  /// perk.
  int get _momentumNeeded => max(1, _momentumThreshold - _perks.momentumDrop);
  bool _luckyCoinArmed = false;
  bool _ironSkinArmed = false;
  int _wardingCharges = 0;

  /// The clans' Sworn boons this fight (see signs.dart's v1.194 kinds):
  /// enemy blows on the player the Lantern's Writ still cancels, enemy
  /// guards the Compact edge still breaks, Curses the Ember face still
  /// lifts, and the hits the Crow's Price has stolen on.
  int _writCharges = 0;
  int _edgeCharges = 0;
  int _emberCharges = 0;
  int _crowsHits = 0;

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

  // --- The dice's own rules (v1.182) -------------------------------------

  /// Growth faces' uses this fight, by `member id:face index` (see
  /// face_keywords.dart).
  final Map<String, int> _growthUses = {};

  /// The face each member played last round: what an Echo first in line
  /// repeats.
  final Map<String, DiceFaceResult> _lastPlayedFaces = {};

  /// Members whose landed face is Steady this round: kept, and not to be
  /// released.
  final Set<String> _steadyActorIds = {};

  /// Faces an enemy's Curse made Pain faces this fight, per member id.
  final Map<String, Set<int>> _cursedFaces = {};

  /// A Hex waiting on the party's next roll; a Silence over the party's
  /// next round, and the one over this round (see dice_tamper.dart).
  bool _hexPending = false;
  bool _silencePending = false;
  bool _silenced = false;

  /// Luck nudges left this fight (see nudgesForLuck).
  int _nudgesLeft = 0;

  /// The biggest hit the party landed this round: what a Mirror sends back.
  int _bestHitThisRound = 0;

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
    _vfx.addImpactListener(_onVfxImpact);
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
    _luckyDieTourTimer?.cancel();
    _shakeController.dispose();
    _vfx.removeImpactListener(_onVfxImpact);
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
    final diceAsync = ref.watch(localizedDbProvider(diceSchema));
    final skillsAsync = ref.watch(localizedDbProvider(skillsSchema));
    final itemsAsync = ref.watch(localizedDbProvider(itemsSchema));
    final companionsAsync = ref.watch(localizedDbProvider(companionsSchema));
    final racesAsync = ref.watch(localizedDbProvider(racesSchema));
    final professionsAsync = ref.watch(localizedDbProvider(professionsSchema));
    final gameConfigAsync = ref.watch(gameConfigProvider);
    final spellsAsync = ref.watch(localizedDbProvider(spellsSchema));
    final itemSetsAsync = ref.watch(localizedDbProvider(itemSetsSchema));
    final housesAsync = ref.watch(localizedDbProvider(housesSchema));
    final skillTreesAsync = ref.watch(gameDbProvider(skillTreesSchema));
    final signsAsync = ref.watch(gameDbProvider(signsSchema));
    // The titles worn and the Sworn boons lend their effects too.
    final titlesAsync = ref.watch(gameDbProvider(titlesSchema));
    final factionsAsync = ref.watch(gameDbProvider(factionsSchema));
    // One of the last battles (v1.196): the sub-clans, for the Host's
    // Houses. Any other fight waits for nothing more.
    final subclansAsync = widget.modifiers.hostFight
        ? ref.watch(gameDbProvider(subclansSchema))
        : null;
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
    final skillTrees = skillTreesAsync.value;
    final signsDb = signsAsync.value;
    final titlesDb = titlesAsync.value;
    final factionsDb = factionsAsync.value;
    final subclansDb =
        subclansAsync == null ? const <String, dynamic>{} : subclansAsync.value;

    if (dice == null ||
        skills == null ||
        items == null ||
        companions == null ||
        races == null ||
        professions == null ||
        gameConfig == null ||
        spellsDb == null ||
        itemSetsDb == null ||
        houses == null ||
        skillTrees == null ||
        signsDb == null ||
        titlesDb == null ||
        factionsDb == null ||
        subclansDb == null) {
      final error = diceAsync.error ??
          skillsAsync.error ??
          itemsAsync.error ??
          companionsAsync.error ??
          racesAsync.error ??
          professionsAsync.error ??
          gameConfigAsync.error ??
          spellsAsync.error ??
          itemSetsAsync.error ??
          housesAsync.error ??
          skillTreesAsync.error ??
          signsAsync.error ??
          titlesAsync.error ??
          factionsAsync.error ??
          subclansAsync?.error;
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
    final clanData = ClanData(
        factions: parseFactions(factionsDb),
        subclans: parseSubclans(subclansDb),
        titles: parseTitles(titlesDb));
    // One of the last battles (v1.196, see throne.dart): the Host fights
    // beside the party, its effects through the signs' machinery.
    if (!_partyBuilt && widget.modifiers.hostFight) {
      _hostData = clanData;
      _host = fieldedHost(
          politics: session.politics,
          data: clanData,
          signPatrons: session.signPatronsThisLife);
    }
    _ensurePartyBuilt(session, companions, races, professions, gameConfig,
        items, _itemSets, houses, dice, skillTrees, skills, signsDb, [
      ...clanEffectsFor(
        activeTitleId: session.activeTitleId,
        heldTitleIds: session.heldTitleIds,
        swornBoonIds: session.swornBoonIds,
        swornFactionId: session.politics.swornFactionId,
        data: clanData,
      ),
      ...hostEffects(_host, clanData),
    ]);
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
