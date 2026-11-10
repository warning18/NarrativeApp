import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_engine.dart' show faceFromJson;
import '../combat/dice_faces.dart';
import '../combat/encounter.dart';
import '../combat/face_smithing.dart';
import '../combat/field_anomaly.dart' show FightStage;
import '../combat/sea_beasts.dart';
import '../combat/ship_battle.dart';
import '../combat/ship_combat.dart';
import '../combat/station_dice.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/aftermath_provider.dart';
import '../providers/combat_active_provider.dart';
import '../providers/combat_settings_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/ship_dress_provider.dart';
import '../providers/tutorial_provider.dart';
import '../theme/stitched_ink.dart';
import '../widgets/ship_cutaway.dart';
import '../widgets/sea_battlefield.dart';
import '../widgets/side_view/sea_kit.dart' show SeaDuelScene;
import '../utils/face_style.dart';
import '../widgets/die_skins.dart';
import '../widgets/ship_fx.dart';
import '../widgets/station_die.dart';
import 'fight_screen.dart';
import '../widgets/ink_sheet.dart';

part 'ship_battle/ship_battle_flow.dart';
part 'ship_battle/ship_battle_dock.dart';
part 'ship_battle/ship_battle_board.dart';
part 'ship_battle/ship_battle_crew.dart';
part 'ship_battle/ship_battle_paint.dart';

/// How a ship battle ended: who won, the Eel as she is now (hull, rooms),
/// and the crew with the hurts the fight cost them.
class ShipBattleOutcome {
  const ShipBattleOutcome({
    required this.won,
    required this.player,
    required this.crew,
    required this.log,
    this.boarded = false,
    this.escaped = false,
    this.fled = false,
    this.enemyHull = 0,
  });

  final bool won;
  final ShipState player;
  final List<ShipCrew> crew;
  final List<String> log;

  /// True when the win came by boarding: the prize is the ship's hold.
  final bool boarded;

  /// True when the enemy got away: no prize, and no loss either.
  final bool escaped;

  /// True when the Eel ran for it and got away (see ShipBattle.runForIt).
  final bool fled;

  /// The enemy's hull at the end (a sea beast carries its wounds away).
  final int enemyHull;
}

/// How big the ships are drawn at [range], against the closest: the sea is
/// seen from the masthead, so the farther apart they lie the smaller each
/// looks.
double seaZoomFor(ShipRange range) => switch (range) {
      ShipRange.close => 1.0,
      ShipRange.medium => 0.82,
      ShipRange.long => 0.64,
    };

/// Below this height the fight leaves out the strip of the two hulls from
/// the side, so the sea keeps the room it needs to be tapped.
const double duelStripMinHeight = 720;

/// The room-by-room ship battle (see ship_battle.dart and
/// ship_combat.dart), seen from above (see sea_battlefield.dart): two
/// ships broadside to broadside on the waters of the voyage, four rooms
/// along each deck, the gap between them the range, the weather drifting
/// over them. The enemy's name, hull and weapons with their charge sit
/// above the sea, and under its name what it means to do next (its
/// intent, which the fog hides) and any friend's sail on the horizon;
/// the Eel's below it, then the weather (and the next
/// round's), the range and the helm's maneuvers, and the log; the shot
/// loaded, her crew at their stations and their orders, and the enemy's
/// aim marked on her rooms when a foresight sail is aboard and the fog
/// allows. A turn: crew work and weapons charge; the player fires each
/// ready weapon at a room of the enemy's ship (tap the weapon, then the
/// room, or hold the room to take aim), moves the crew (tap a member, then
/// a room), may close in or pull away, may give an order, may push one
/// room past its limit (the bolt in the dock), then ends the
/// turn; the enemy fires back, fires burn, leaks flood and bulwarks come
/// back. Ships side by side with the enemy's rail open can be boarded
/// and the enemy's crew fought on the dice (a win takes the ship); the
/// enemy may board the Eel the same way.
/// With [turnSeconds] set, each turn runs against the clock: when it runs
/// out the turn ends as it stands, and a weapon not fired keeps its
/// charge; a turn ended with half the clock left is quick orders.
class ShipBattlePanel extends ConsumerStatefulWidget {
  const ShipBattlePanel({
    super.key,
    required this.player,
    required this.enemy,
    required this.shipName,
    required this.enemyName,
    this.enemyShipId,
    required this.crew,
    required this.foresight,
    required this.random,
    required this.onFinished,
    this.boarding = const BoardingProfile(),
    this.chapter = 1,
    this.buildCrew,
    this.isTest = false,
    this.turnSeconds,
    this.habit = EnemyHabit.none,
    this.windKnot = false,
    this.rules = const ShipBattleRules(),
    this.waters = SeaWaters.open,
    this.canFlee = true,
    this.beast,
    this.placeCrew = false,
  });

  final ShipState player;
  final ShipState enemy;
  final String shipName;
  final String enemyName;

  /// The enemy's id in enemy_ships.json (its record's key, never the
  /// French overlay's name), which picks its look (see
  /// TopShipLook.forEnemy).
  final String? enemyShipId;
  final List<ShipCrew> crew;

  /// True with the Kraken's Eye aboard: the enemy's aim is shown.
  final bool foresight;
  final Random random;
  final void Function(ShipBattleOutcome outcome) onFinished;

  /// The enemy's boarding crew, odds and prize (see [boardingProfileFor]).
  final BoardingProfile boarding;

  /// The chapter the boarding fight is scaled to.
  final int chapter;

  /// Rebuilds the crew from the session after a boarding fight, which
  /// settles their health on its own; null keeps the panel's own copy.
  final List<ShipCrew> Function()? buildCrew;

  /// An Edit Mode test battle (see FightLabScreen): its boarding fight is
  /// a test fight too, with no permadeath on a loss.
  final bool isTest;

  /// Seconds the player has for each turn (see shipTurnSeconds); null
  /// leaves the turn to End turn alone.
  final int? turnSeconds;

  /// What the enemy does beyond firing (enemy_ships.json `habit`).
  final EnemyHabit habit;

  /// The Wind-Knot sail is aboard: a crosswind is a tailwind for the Eel.
  final bool windKnot;

  /// Opens on a placement screen: the crew are set at their stations
  /// before the first round (the voyage and the test battle; tests go
  /// straight to the fight).
  final bool placeCrew;

  /// Which battle rules are on (all of them in play).
  final ShipBattleRules rules;

  /// The waters the fight is on, which set the sea's look.
  final SeaWaters waters;

  /// The Eel may run for it (a story fight must be seen through).
  final bool canFlee;

  /// The enemy is a sea beast (see sea_beasts.dart): its rooms are fins,
  /// jaws, hide and heart, and the battle shows what it is about to do.
  /// It has no look of its own yet: it borrows the ship nearest its size
  /// (see TopShipLook.forEnemy).
  final BeastProfile? beast;

  @override
  ConsumerState<ShipBattlePanel> createState() => _ShipBattlePanelState();
}

class _ShipBattlePanelState extends ConsumerState<ShipBattlePanel>
    with TickerProviderStateMixin {
  late final ShipBattle _battle;
  String? _armedWeaponId;
  String? _selectedCrewId;
  bool _busy = false;
  bool _finished = false;

  /// The turn's clock (see [ShipBattlePanel.turnSeconds]): it stands still
  /// while the enemy fires or a deck is fought over.
  Timer? _clock;
  int _secondsLeft = 0;

  /// The room an aimed shot is being lined up on, and the marker sweeping
  /// the aim bar (see [aimResultFor]).
  ShipRoom? _aimRoom;
  late final AnimationController _aim;

  // --- Particles (see ship_fx.dart) ---------------------------------------

  final ShipFxController _fx = ShipFxController();

  /// Anchors for the particles: every room of both ships, both hulls and
  /// the sea between them.
  final Map<(bool, ShipRoom), GlobalKey> _roomKeys = {
    for (final eel in [true, false])
      for (final room in ShipRoom.values) (eel, room): GlobalKey(),
  };
  final Map<bool, GlobalKey> _hullKeys = {
    true: GlobalKey(),
    false: GlobalKey()
  };
  final GlobalKey _seaKey = GlobalKey();

  /// The ship going down at the end, and how far along.
  bool? _sinkingEel;
  late final AnimationController _sink;

  /// The sea's clock: waves, weather and ships all move with it; still
  /// with reduced motion.
  late final AnimationController _seaClock;

  /// The weather the sea last showed, the one before it and when it
  /// turned (on the sea's clock): the old weather fades as the new comes.
  SeaWeather? _shownWeather;
  SeaWeather? _fadingWeather;
  double _weatherTurnedAt = -10;
  Timer? _finishTimer;
  final List<Timer> _fxTimers = [];

  @override
  void initState() {
    super.initState();
    _sink = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300));
    _seaClock = AnimationController(
        vsync: this, duration: const Duration(seconds: 600));
    _aim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _battle = ShipBattle(
      player: widget.player,
      enemy: widget.enemy,
      crew: widget.crew,
      random: widget.random,
      boarding: widget.boarding,
      habit: widget.habit,
      rules: widget.rules,
      windKnot: widget.windKnot,
      canFlee: widget.canFlee,
      beast: widget.beast,
    );
    _ensureCrewDice();
    _armedWeaponId = _firstReadyWeaponId();
    _placing = widget.placeCrew && widget.crew.length > 1;
    if (!_placing) _startClock();
  }

  /// True once the hands' dice are read from the game data (see
  /// [_ensureCrewDice]).
  bool _diceRead = false;
  final Map<String, String?> _dieIds = {};

  /// The die [crew] rolls, for its skin.
  String? _equippedDieOf(ShipCrew crew) => _dieIds[crew.id];

  /// Each hand's die (station_dice.dart): the player's equipped die and a
  /// companion's signature die as the Hammersmith left them, read once the
  /// dice data is in.
  void _ensureCrewDice() {
    if (_diceRead) return;
    final dice = ref.read(localizedDbProvider(diceSchema)).value;
    if (dice == null || dice.isEmpty) return;
    _diceRead = true;
    final session = ref.read(playerSessionProvider);
    final skills =
        ref.read(localizedDbProvider(skillsSchema)).value ?? const {};
    final companions =
        ref.read(localizedDbProvider(companionsSchema)).value ?? const {};
    final lang = ref.read(appLanguageProvider);
    final result = <String, CrewDie>{};
    for (final member in widget.crew) {
      final String? dieId = member.isPlayer
          ? session.equippedDiceId ??
              (session.ownedDiceIds.isNotEmpty
                  ? session.ownedDiceIds.first
                  : null)
          : (companions[member.id] as Map<String, dynamic>?)?['signatureDiceId']
              ?.toString();
      final raws =
          ((dice[dieId ?? ''] as Map<String, dynamic>?)?['faces'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              const <Map<String, dynamic>>[];
      if (raws.isEmpty) continue;
      _dieIds[member.id] = dieId;
      final faces = smithedFaces(
          raws,
          session.upgradesOfDie(dieId,
              companionId: member.isPlayer ? null : member.id));
      var assigned = const <String, String>{};
      if (member.isPlayer) {
        assigned = session.diceSkillAssignments[dieId] ?? assigned;
      } else {
        for (final ally in session.recruitedAllies) {
          if (ally.companionId == member.id) {
            assigned = ally.diceSkillAssignments;
          }
        }
      }
      assigned = limitedFaceAssignments(faces, assigned, skills);
      result[member.id] = CrewDie([
        for (var i = 0; i < faces.length; i++)
          () {
            final face = applyFaceAssignment(
              faceFromJson(faces[i], i).withFaceName(''),
              faces[i],
              assigned[i.toString()],
              language: lang,
            );
            final kind = face.type == 'Skill'
                ? skillKind(skills[face.linkedSkillID.isEmpty
                    ? 'heavy_attack'
                    : face.linkedSkillID] as Map<String, dynamic>?)
                : faceKind(face.type);
            return StationFace(face, kind);
          }(),
      ]);
    }
    _battle.crewDice = result;
  }

  /// What a die landed at its station does this turn, for the room's tip.
  String _stationRollHint(AppLanguage lang, StationRoll roll) {
    final kind = roll.kind;
    if (kind == null) return trFor(lang, 'ship_dice_blank');
    final share =
        (stationShare(roll.value) * (kind == FaceKind.poison ? 0.5 : 1.0) * 100)
            .round();
    final n = switch (kind) {
      FaceKind.heal => stationPatch(roll.value),
      _ => share,
    };
    return trFor(lang, 'ship_dice_${kind.name}').replaceAll('{n}', '$n');
  }

  /// Whole turns each order die has spun, one per order given.
  final Map<String, int> _orderSpins = {};

  /// True while the crew are being placed before the first round.
  bool _placing = false;

  /// What a shot just did to a room, shown over it for a moment, keyed by
  /// the side (true for the Eel) and the room.
  final Map<(bool, ShipRoom), (String, int)> _flashes = {};

  /// The hull a shot just took off each ship (true for the Eel), shown
  /// by her hull bar for a moment.
  final Map<bool, (int, int)> _hullPops = {};
  int _flashCount = 0;
  final Map<(bool, ShipRoom), Timer> _flashTimers = {};

  /// [setState] for the part files: it is @protected, so the extensions on
  /// this state (see ship_battle/) call this instead.
  void _update(VoidCallback fn) => setState(fn);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.of(context).disableAnimations;
    if (still && _seaClock.isAnimating) {
      _seaClock.stop();
    } else if (!still && !_seaClock.isAnimating) {
      _seaClock.repeat();
    }
  }

  @override
  void dispose() {
    _clock?.cancel();
    for (final timer in _flashTimers.values) {
      timer.cancel();
    }
    _aim.dispose();
    _sink.dispose();
    _seaClock.dispose();
    _fx.dispose();
    _finishTimer?.cancel();
    for (final timer in _fxTimers) {
      timer.cancel();
    }
    super.dispose();
  }

  // --- Helpers -------------------------------------------------------------

  bool get _french => ref.read(appLanguageProvider) == AppLanguage.fr;

  bool get _over => _battle.over || _finished;

  @override
  Widget build(BuildContext context) {
    // The dice data arrives after the panel opens on a cold start.
    if (!_diceRead) ref.watch(localizedDbProvider(diceSchema));
    _ensureCrewDice();
    final lang = ref.watch(appLanguageProvider);
    final fr = lang == AppLanguage.fr;
    final ink = InkColors.of(context);
    final enemies = ref.watch(localizedDbProvider(enemiesSchema)).value;
    final canBoard = _canBoardThem(enemies);
    final aimed = ref.watch(aimedShotsProvider);
    if (!_aim.isAnimating) _aim.duration = aimSweepFor(aimed);
    final hintKey = _selectedCrewId != null
        ? 'ship_station_hint'
        : _armedWeaponId != null
            ? (aimed == AimedShots.off
                ? 'ship_fire_hint_no_aim'
                : 'ship_fire_hint')
            : canBoard
                ? 'ship_board_hint'
                : 'ship_station_hint';
    final tip = _pendingTip(ref.watch(tutorialProvider), aimed);
    var hint = trFor(lang, hintKey);
    if (hintKey == 'ship_board_hint') {
      hint = hint.replaceAll(
          '{crew}', _boardingCrewLabel(_boardingCrew(enemies)!));
    }
    // Low in the water with a way out: that comes before anything else.
    final runWarning = widget.canFlee &&
        !_over &&
        _battle.player.hull < _battle.player.maxHull * _runWarningShare;
    if (runWarning) hint = trFor(lang, 'ship_run_warning');
    if (_busy && !_over) {
      hint = trFor(lang, 'ship_enemy_turn_label')
          .replaceAll('{ship}', widget.enemyName);
    }
    final ink2 = ink;
    if (_placing) return _buildPlacement(lang, enemies);
    return Stack(
      children: [
        Positioned.fill(
          child: LayoutBuilder(builder: (context, constraints) {
            final bar = Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _shipBar(
                    name: widget.enemyName,
                    ship: _battle.enemy,
                    evasion: _battle.enemyEvasion,
                    color: ink.blood,
                    habit: widget.habit,
                  ),
                  _buildShieldSums(lang),
                  _buildEnemyStatus(lang),
                ],
              ),
            );
            // A tip sits above the dock, off the sea, so it never covers a
            // room that has to be tapped.
            final dock = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (tip != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                    child: _buildTip(tip, lang),
                  ),
                _buildDock(lang, fr, enemies, canBoard, hint, warn: runWarning),
              ],
            );
            final sea = Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildBattlefield(lang),
              ),
            );
            // A tall screen gives the sea all the room between the enemy
            // and the dock. On a short one the enemy's bar and the sea
            // scroll, the sea at a fixed height, and the dock stays pinned
            // below them, so End turn is always on screen.
            if (constraints.maxHeight < 600) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      key: const Key('ship_sea_scroll'),
                      padding: EdgeInsets.zero,
                      children: [bar, SizedBox(height: 340, child: sea)],
                    ),
                  ),
                  dock,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                bar,
                // A tall screen has room for the two hulls from the side,
                // facing each other as the range says.
                if (constraints.maxHeight >= duelStripMinHeight)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                    child: _buildDuelStrip(),
                  ),
                Expanded(child: sea),
                dock,
              ],
            );
          }),
        ),
        Positioned.fill(
          child: ShipFxLayer(
            controller: _fx,
            ambient: _ambient,
            palette: ShipFxPalette(
              gold: ink2.gold,
              ember: ink2.ember,
              blood: ink2.blood,
              tide: ink2.tide,
              wood: _roomColor(context, ShipRoom.hold),
              steel: _roomColor(context, ShipRoom.bulwark),
              smoke: ink2.ash,
              light: const Color(0xFFFFF3C4),
              voidColor: ink2.voidColor,
            ),
          ),
        ),
      ],
    );
  }
}

const _seaSeconds = 600.0;
const _weatherFade = 1.6;
