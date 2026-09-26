import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/encounter.dart';
import '../combat/ship_battle.dart';
import '../combat/ship_combat.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/combat_active_provider.dart';
import '../providers/combat_settings_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/tutorial_provider.dart';
import '../theme/stitched_ink.dart';
import 'fight_screen.dart';

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
  });

  final bool won;
  final ShipState player;
  final List<ShipCrew> crew;
  final List<String> log;

  /// True when the win came by boarding: the prize is the ship's hold.
  final bool boarded;

  /// True when the enemy got away: no prize, and no loss either.
  final bool escaped;
}

/// The room-by-room ship battle (see ship_battle.dart and
/// ship_combat.dart), drawn as two ships of four rooms each. The enemy
/// sits at the top with its weapons and their charge; between the ships,
/// the weather (and the next round's), the range and the helm's
/// maneuvers, and the log; the Eel at the bottom with hers, the shot
/// loaded, her crew at their stations and their orders, and the enemy's
/// aim marked on her rooms when a foresight sail is aboard and the fog
/// allows. A turn: crew work and weapons charge; the player fires each
/// ready weapon at a room of the enemy's ship (tap the weapon, then the
/// room, or hold the room to take aim), moves the crew (tap a member, then
/// a room), may close in or pull away, may give an order, then ends the
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
  });

  final ShipState player;
  final ShipState enemy;
  final String shipName;
  final String enemyName;
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

  /// Which battle rules are on (all of them in play).
  final ShipBattleRules rules;

  @override
  ConsumerState<ShipBattlePanel> createState() => _ShipBattlePanelState();
}

class _ShipBattlePanelState extends ConsumerState<ShipBattlePanel>
    with SingleTickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();
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
    );
    _armedWeaponId = _firstReadyWeaponId();
    _startClock();
  }

  @override
  void dispose() {
    _clock?.cancel();
    for (final timer in _flashTimers.values) {
      timer.cancel();
    }
    _aim.dispose();
    super.dispose();
  }

  // --- Helpers -------------------------------------------------------------

  bool get _french => ref.read(appLanguageProvider) == AppLanguage.fr;

  bool get _over => _battle.over || _finished;

  /// A log line in the player's language.
  String _line(BattleLine line) {
    final lang = ref.read(appLanguageProvider);
    var text = trFor(lang, line.key);
    final side = line.side;
    if (side != null) {
      text = text.replaceAll('{ship}',
          side == BattleSide.eel ? widget.shipName : widget.enemyName);
    }
    final weapon = line.weapon;
    if (weapon != null) {
      text = text.replaceAll('{weapon}', weapon.nameFor(_french));
    }
    final room = line.room;
    if (room != null) {
      text = text.replaceAll('{room}', trFor(lang, 'ship_room_${room.name}'));
    }
    final crew = line.crew;
    if (crew != null) text = text.replaceAll('{crew}', crew);
    final n = line.n;
    if (n != null) text = text.replaceAll('{n}', '$n');
    final range = line.range;
    if (range != null) {
      text =
          text.replaceAll('{range}', trFor(lang, 'ship_range_${range.name}'));
    }
    return tidyShipLine(text, lang);
  }

  // --- One-time tips -------------------------------------------------------

  /// The first rule of the battle on screen now that the player has not
  /// had explained yet (see [TutorialSettings.hasSeenTip]): the range and
  /// the enemy's habit at once, the weather when it turns, aimed shots
  /// with the first ready gun, shot from the second turn, orders, fire,
  /// a leak, an open rail, the sea's surprises. One at a time; none when
  /// tutorials are off.
  String? _pendingTip(TutorialSettings tutorial, AimedShots aimed) {
    if (!tutorial.loaded || !tutorial.enabled || _over) return null;
    if (!ref.read(tutorialAutoShowProvider)) return null;
    final b = _battle;
    final candidates = [
      if (b.rules.range) 'ship_range',
      if (b.rules.habits && widget.habit != EnemyHabit.none)
        'ship_habit_${widget.habit.name}',
      if (b.rules.weather && b.weather != SeaWeather.calm) 'ship_weather',
      if (aimed != AimedShots.off && b.anyShotReady) 'ship_aim',
      if (b.turn >= 2) 'ship_ammo',
      if (b.crew.any(b.canOrder)) 'ship_orders',
      if (b.player.rooms.values.any((r) => r.onFire)) 'ship_fire',
      if (b.player.leaks > 0) 'ship_leak',
      if (b.canBoardThem) 'ship_boarding',
      if (b.log.any((l) => l.key.startsWith('ship_event_'))) 'ship_sea',
    ];
    for (final id in candidates) {
      if (!tutorial.hasSeenTip(id)) return id;
    }
    return null;
  }

  Widget _buildTip(String id, AppLanguage lang) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final habit = id.startsWith('ship_habit_');
    var text = habit
        ? '${trFor(lang, 'tip_ship_habit').replaceAll('{ship}', widget.enemyName)} '
            '${trFor(lang, '${id}_hint')}'
        : trFor(lang, 'tip_$id');
    text = tidyShipLine(text, lang);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        key: Key('ship_tip_$id'),
        color: theme.colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: ink.gold),
        ),
        // One row, so the ships stay on screen: the tip, and a tick to
        // put it away for good.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 0, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline,
                  size: 18, color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text,
                    style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.25,
                        color: theme.colorScheme.onSecondaryContainer)),
              ),
              IconButton(
                key: const Key('ship_tip_ok'),
                tooltip: trFor(lang, 'tip_got_it'),
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.check, size: 20, color: ink.gold),
                onPressed: () =>
                    ref.read(tutorialProvider.notifier).markTipSeen(id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _firstReadyWeaponId() {
    for (final w in _battle.player.weapons) {
      if (_battle.canFire(w)) return w.id;
    }
    return null;
  }

  /// After the range changes, a weapon that no longer reaches is put down
  /// for one that does (or none), so the enemy's rooms never invite a shot
  /// that cannot be fired.
  void _rearm() {
    final armed = _battle.weaponById(_armedWeaponId);
    if (armed == null || !_battle.canFire(armed)) {
      _armedWeaponId = _firstReadyWeaponId();
    }
  }

  void _cancelAim() {
    _aim.stop();
    _aimRoom = null;
  }

  // --- Turn flow -----------------------------------------------------------

  /// Starts the turn's clock afresh, when the battle is timed.
  void _startClock() {
    _clock?.cancel();
    final seconds = widget.turnSeconds;
    if (seconds == null || seconds <= 0 || _over) return;
    _secondsLeft = seconds;
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted || _over) {
      _clock?.cancel();
      return;
    }
    if (_busy) return;
    setState(() => _secondsLeft = max(0, _secondsLeft - 1));
    if (_secondsLeft > 0) return;
    _clock?.cancel();
    // Time's up: the turn ends as it stands. A ready weapon not fired
    // keeps its charge for the next one.
    final held = _battle.player.weapons.any((w) => w.isReady);
    _battle.note(BattleLine(held ? 'ship_log_time_up_held' : 'ship_log_time_up',
        side: BattleSide.eel));
    _endTurn();
  }

  /// True when ending the turn now is quick orders: half the clock left.
  bool get _quickNow {
    final seconds = widget.turnSeconds;
    return seconds != null &&
        seconds > 0 &&
        !_busy &&
        !_over &&
        _secondsLeft * 2 >= seconds;
  }

  void _fire(ShipRoom room, {AimResult? aim}) {
    final weaponId = _armedWeaponId;
    if (_busy || _over || weaponId == null) return;
    final outcome = _battle.fire(weaponId, room, aim: aim);
    _flash(outcome, onEel: false);
    setState(() {
      _cancelAim();
      if (outcome != null) _armedWeaponId = _firstReadyWeaponId();
    });
    if (_battle.over) _finish();
  }

  void _startAim(ShipRoom room) {
    final weapon = _battle.weaponById(_armedWeaponId);
    if (_busy || _over || weapon == null || !_battle.canFire(weapon)) return;
    setState(() {
      _aimRoom = room;
      _selectedCrewId = null;
    });
    _aim.repeat(reverse: true);
  }

  void _releaseAim() {
    final room = _aimRoom;
    if (room == null) return;
    final result = aimResultFor(_aim.value);
    _fire(room, aim: result);
  }

  void _station(ShipRoom room) {
    final crewId = _selectedCrewId;
    if (crewId == null) return;
    setState(() {
      _battle.station(crewId, room);
      _selectedCrewId = null;
    });
  }

  Future<void> _endTurn({bool manual = false}) async {
    if (_busy || _over) return;
    final quick = manual && _quickNow;
    _clock?.cancel();
    setState(() {
      _busy = true;
      _armedWeaponId = null;
      _selectedCrewId = null;
      _cancelAim();
    });
    _battle.startEnemyPhase(quickOrders: quick);
    if (_battle.over) {
      _finish();
      return;
    }
    setState(() {});
    for (final weapon in _battle.enemyVolley) {
      final shot = _battle.fireEnemy(weapon);
      if (!mounted) return;
      _flash(shot, onEel: true);
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      if (_battle.over) {
        _finish();
        return;
      }
    }
    if (!await _maybeRepelBoarders(
        ref.read(localizedDbProvider(enemiesSchema)).value)) {
      return;
    }
    if (!mounted) return;
    _battle.endRound();
    if (_battle.over) {
      setState(() {});
      _finish();
      return;
    }
    setState(() {
      _armedWeaponId = _firstReadyWeaponId();
      _busy = false;
    });
    _startClock();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _clock?.cancel();
    _cancelAim();
    if (mounted) setState(() => _busy = true);
    final end = _battle.end;
    widget.onFinished(ShipBattleOutcome(
      won: end == BattleEnd.won || end == BattleEnd.boarded,
      player: _battle.player,
      crew: _battle.crew,
      log: [for (final line in _battle.log) _line(line)],
      boarded: end == BattleEnd.boarded,
      escaped: end == BattleEnd.escaped,
    ));
  }

  // --- Boarding ------------------------------------------------------------

  /// The boarding crew's records, or null when any of them is unknown.
  Map<String, Map<String, dynamic>>? _boardingCrew(
      Map<String, dynamic>? enemies) {
    if (enemies == null || !widget.boarding.canBoard) return null;
    final records = <String, Map<String, dynamic>>{};
    for (final id in widget.boarding.crew) {
      final record = enemies[id] as Map<String, dynamic>?;
      if (record == null) return null;
      records[id] = record;
    }
    return records;
  }

  /// Fights the enemy's boarding crew on the dice. True on a win, false
  /// on a loss, null when the fight ended the run (permadeath).
  Future<bool?> _deckFight(Map<String, Map<String, dynamic>> records,
      {double healthMultiplier = 1.0}) async {
    final ids = widget.boarding.crew;
    ref.read(combatActiveProvider.notifier).state = true;
    final won = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FightScreen(
          enemyId: ids.first,
          enemy: records[ids.first]!,
          additionalEnemyIds: ids.skip(1).toList(),
          additionalEnemies: {
            for (final id in ids.skip(1)) id: records[id]!,
          },
          modifiers: EncounterModifiers(
            chapter: widget.chapter,
            healthMultiplier: healthMultiplier,
            difficultyMultiplier: boardingDifficulty,
            isTest: widget.isTest,
          ),
        ),
      ),
    );
    ref.read(combatActiveProvider.notifier).state = false;
    if (!mounted) return null;
    // The fight settles the crew's health itself (a loss heals them);
    // read it back rather than keep the panel's stale copy.
    final rebuilt = widget.buildCrew?.call();
    if (rebuilt != null) _battle.crew = rebuilt;
    return won;
  }

  /// The boarding crew by name, duplicates counted: "Street Bandit x2, Harbor Rat".
  String _boardingCrewLabel(Map<String, Map<String, dynamic>> records) {
    final counts = <String, int>{};
    for (final id in widget.boarding.crew) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
    return counts.entries.map((e) {
      final name = records[e.key]!['enemyName']?.toString() ?? e.key;
      return e.value > 1 ? '$name x${e.value}' : name;
    }).join(', ');
  }

  bool _canBoardThem(Map<String, dynamic>? enemies) =>
      !_busy &&
      !_over &&
      _battle.canBoardThem &&
      _boardingCrew(enemies) != null;

  /// Throws the grapples: a ship that still steers may slip them, and
  /// either way the attempt ends the turn. Hooked, the crew fight theirs
  /// on the dice; a win takes the ship, a loss costs hull and the chance
  /// to try again this battle.
  Future<void> _boardThem(Map<String, dynamic>? enemies) async {
    final records = _boardingCrew(enemies);
    if (records == null || !_canBoardThem(enemies)) return;
    setState(() {
      _busy = true;
      _armedWeaponId = null;
      _selectedCrewId = null;
      _cancelAim();
    });
    if (!_battle.throwGrapples()) {
      setState(() => _busy = false);
      await _endTurn();
      return;
    }
    setState(_battle.boardingStarted);
    final won = await _deckFight(records);
    if (!mounted || won == null) return;
    if (won) {
      _battle.boardingWon();
      _finish();
      return;
    }
    setState(() {
      _battle.boardingLost();
      _busy = false;
    });
    await _endTurn();
  }

  /// The enemy's try at the Eel's rail, after its volley. Returns false
  /// when the fight ended the run.
  Future<bool> _maybeRepelBoarders(Map<String, dynamic>? enemies) async {
    final records = _boardingCrew(enemies);
    if (records == null) return true;
    final holdManned = _battle.enemyBoards();
    if (holdManned == null) return true;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return false;
    final won = await _deckFight(records,
        healthMultiplier: holdManned ? holdMannedBoarderHealth : 1.0);
    if (!mounted || won == null) return false;
    if (won) {
      _battle.boardersRepelled();
    } else {
      _battle.boardersWon();
    }
    return true;
  }

  // --- UI ------------------------------------------------------------------

  /// What a shot just did to a room, shown over it for a moment, keyed by
  /// the side (true for the Eel) and the room.
  final Map<(bool, ShipRoom), (String, int)> _flashes = {};
  int _flashCount = 0;
  final Map<(bool, ShipRoom), Timer> _flashTimers = {};

  void _flash(ShotOutcome? outcome, {required bool onEel}) {
    if (outcome == null) return;
    final lang = ref.read(appLanguageProvider);
    final text = outcome.dodged
        ? trFor(lang, 'ship_slipped_label')
        : outcome.absorbed
            ? trFor(lang, 'ship_blocked_label')
            : '−${outcome.hullDamage}';
    final key = (onEel, outcome.room);
    final flash = (text, ++_flashCount);
    _flashes[key] = flash;
    _flashTimers[key]?.cancel();
    _flashTimers[key] = Timer(const Duration(milliseconds: 1200), () {
      _flashTimers.remove(key);
      if (!mounted || _flashes[key] != flash) return;
      setState(() => _flashes.remove(key));
    });
  }

  /// Whether [member]'s order can be given now: once a battle, not while
  /// the enemy fires, and a grapple only with a crew to fight at the rail.
  bool _orderUsable(ShipCrew member, Map<String, dynamic>? enemies) {
    final order = orderFor(member);
    return order != null &&
        !_busy &&
        !_over &&
        _battle.canOrder(member) &&
        (order != CrewOrder.grapple || _boardingCrew(enemies) != null);
  }

  @override
  Widget build(BuildContext context) {
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
    if (_busy && !_over) {
      hint = trFor(lang, 'ship_enemy_turn_label')
          .replaceAll('{ship}', widget.enemyName);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            children: [
              if (tip != null) _buildTip(tip, lang),
              _buildShipHeader(
                name: widget.enemyName,
                ship: _battle.enemy,
                evasion: _battle.enemyEvasion,
                color: ink.blood,
                habit: widget.habit,
              ),
              const SizedBox(height: 4),
              _buildHull(
                  ship: _battle.enemy, isPlayer: false, color: ink.blood),
              const SizedBox(height: 4),
              _buildEnemyWeapons(fr),
              const SizedBox(height: 8),
              _buildSea(lang),
              const SizedBox(height: 6),
              _buildLog(context),
              const SizedBox(height: 8),
              _buildShipHeader(
                name: widget.shipName,
                ship: _battle.player,
                evasion: _battle.playerEvasion,
                color: ink.gold,
              ),
              const SizedBox(height: 4),
              _buildHull(ship: _battle.player, isPlayer: true, color: ink.gold),
            ],
          ),
        ),
        _buildDock(lang, fr, enemies, canBoard, hint),
      ],
    );
  }

  /// The player's side of the turn, always in reach at the bottom: the
  /// clock, the hint (or the aim bar), the weapons, the shot, the crew and
  /// the end of the turn.
  Widget _buildDock(AppLanguage lang, bool fr, Map<String, dynamic>? enemies,
      bool canBoard, String hint) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final readyOrders =
        _battle.crew.where((c) => _orderUsable(c, enemies)).length;
    final total = max(1, widget.turnSeconds ?? 1);
    final timed = widget.turnSeconds != null && !_over;
    return Container(
      key: const Key('ship_dock'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: ink.seam)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The turn's clock runs along the top edge.
          if (timed)
            LinearProgressIndicator(
              value: (_secondsLeft / total).clamp(0.0, 1.0),
              minHeight: 3,
              color: !_busy && _secondsLeft <= 5 ? ink.blood : ink.gold,
              backgroundColor: ink.seam,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_aimRoom != null)
                  _buildAimBar(lang)
                else
                  Row(
                    children: [
                      Expanded(
                        child: Tooltip(
                          message: hint,
                          child: Text(
                            '${trFor(lang, 'round_label')} ${_battle.turn} · $hint',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: _busy && !_over ? ink.blood : ink.ash),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (timed) ...[
                        const SizedBox(width: 8),
                        _buildClock(lang),
                      ],
                    ],
                  ),
                const SizedBox(height: 6),
                _buildPlayerWeapons(fr),
                const SizedBox(height: 6),
                _buildAmmo(lang),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton(
                      key: const Key('ship_crew_button'),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 12)),
                      onPressed: _battle.crew.isEmpty
                          ? null
                          : () => _openCrewSheet(enemies),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(trFor(lang, 'ship_crew_button')),
                          if (readyOrders > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              constraints: const BoxConstraints(
                                  minWidth: 18, minHeight: 18),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: ink.gold,
                                  borderRadius: BorderRadius.circular(9)),
                              child: Text('$readyOrders',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onPrimary)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (canBoard) ...[
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10)),
                        onPressed: () => _boardThem(enemies),
                        icon: const Icon(Icons.sports_kabaddi, size: 18),
                        label: Text(trFor(lang, 'ship_board_button')),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('ship_end_turn'),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48)),
                        onPressed: _busy || _over
                            ? null
                            : () => _endTurn(manual: true),
                        icon: const Icon(Icons.hourglass_bottom, size: 18),
                        label: Text(trFor(lang, 'ship_end_turn_button')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The turn's seconds left, red for the last five and still while the
  /// enemy fires (its bar runs along the top of the dock). While half of
  /// it is left, ending the turn is quick orders.
  Widget _buildClock(AppLanguage lang) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final urgent = !_busy && _secondsLeft <= 5;
    final color = urgent ? ink.blood : ink.gold;
    final quick = _quickNow;
    return Row(
      key: const Key('ship_turn_clock'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          trFor(lang, 'ship_turn_seconds').replaceAll('{n}', '$_secondsLeft'),
          style: theme.textTheme.labelMedium?.copyWith(
              color: color, fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        const SizedBox(width: 6),
        Tooltip(
          message: trFor(lang, 'ship_quick_orders_hint')
              .replaceAll('{n}', '$quickOrdersEvasion'),
          child: Row(
            key: const Key('ship_quick_orders'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, size: 14, color: quick ? ink.ember : ink.ash),
              Text(
                '+$quickOrdersEvasion%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: quick ? ink.ember : ink.ash,
                  fontWeight: quick ? FontWeight.bold : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The aim bar: a marker sweeps from edge to edge; stop it in the middle
  /// for a critical, in the amber for a plain shot; at the red edges the
  /// shot goes wide.
  Widget _buildAimBar(AppLanguage lang) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    return Row(
      key: const Key('ship_aim_bar'),
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: trFor(lang, 'cancel'),
          onPressed: () => setState(_cancelAim),
          icon: const Icon(Icons.close, size: 18),
        ),
        Expanded(
          child: GestureDetector(
            onTap: _releaseAim,
            child: SizedBox(
              height: 26,
              child: AnimatedBuilder(
                animation: _aim,
                builder: (context, _) => CustomPaint(
                  painter: _AimBarPainter(
                    position: _aim.value,
                    marker: theme.colorScheme.onSurface,
                    wide: ink.blood,
                    steady: ink.gold,
                    perfect: ink.heal,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        FilledButton(
          key: const Key('ship_aim_fire'),
          onPressed: _releaseAim,
          child: Text(trFor(lang, 'ship_aim_fire_button')),
        ),
      ],
    );
  }

  /// Between the ships: this round's weather and the next, the range
  /// they lie at on a ruler, and the helm's maneuvers.
  Widget _buildSea(AppLanguage lang) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final muted = theme.textTheme.labelSmall?.copyWith(color: ink.ash);
    final rules = widget.rules;
    final range = _battle.range;
    final closer = range.index > 0 ? ShipRange.values[range.index - 1] : null;
    final farther = range.index < ShipRange.values.length - 1
        ? ShipRange.values[range.index + 1]
        : null;
    final canAct = !_busy && !_over;
    return Container(
      key: const Key('ship_sea_strip'),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: Border.symmetric(horizontal: BorderSide(color: ink.seam)),
      ),
      child: CustomPaint(
        painter: _WavesPainter(color: ink.tide.withValues(alpha: 0.16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (rules.weather)
              Tooltip(
                message:
                    trFor(lang, 'ship_weather_${_battle.weather.name}_hint'),
                child: Row(
                  children: [
                    Icon(_weatherIcon(_battle.weather),
                        size: 16, color: _weatherColor(ink, _battle.weather)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        trFor(lang, 'ship_weather_${_battle.weather.name}'),
                        style: theme.textTheme.labelMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${trFor(lang, 'ship_weather_next_label')} ',
                        style: muted),
                    Icon(_weatherIcon(_battle.nextWeather),
                        size: 14, color: ink.ash),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        trFor(lang, 'ship_weather_${_battle.nextWeather.name}'),
                        style: muted,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_battle.wreck) ...[
                      const Spacer(),
                      Tooltip(
                        message: trFor(lang, 'ship_wreck_hint'),
                        child: Icon(Icons.sailing_outlined,
                            size: 16,
                            color: _roomColor(context, ShipRoom.hold)),
                      ),
                    ],
                  ],
                ),
              ),
            if (rules.range) ...[
              if (rules.weather) const SizedBox(height: 3),
              Row(
                key: const Key('ship_range_bar'),
                children: [
                  _maneuverButton(
                    key: const Key('ship_close_in'),
                    icon: Icons.keyboard_double_arrow_left,
                    label: trFor(lang, 'ship_close_in_button'),
                    onPressed:
                        canAct && closer != null && _battle.canMoveTo(closer)
                            ? () => setState(() {
                                  _battle.maneuver(closer);
                                  _rearm();
                                })
                            : null,
                  ),
                  Expanded(
                    child: Tooltip(
                      message: trFor(lang, 'ship_range_${range.name}_hint'),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 16,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: _RangeRulerPainter(
                                at: range.index,
                                of: ShipRange.values.length,
                                mark: ink.gold,
                                line: ink.ash,
                                fill: theme.colorScheme.surface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            trFor(lang, 'ship_range_${range.name}_title'),
                            key: const Key('ship_range_label'),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: ink.gold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _maneuverButton(
                    key: const Key('ship_pull_away'),
                    icon: Icons.keyboard_double_arrow_right,
                    label: trFor(lang, 'ship_pull_away_button'),
                    onPressed:
                        canAct && farther != null && _battle.canMoveTo(farther)
                            ? () => setState(() {
                                  _battle.maneuver(farther);
                                  _rearm();
                                })
                            : null,
                    trailing: true,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _maneuverButton({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool trailing = false,
  }) {
    final text = Text(label, style: Theme.of(context).textTheme.labelSmall);
    final glyph = Icon(icon, size: 16);
    return OutlinedButton(
      key: key,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: trailing ? [text, glyph] : [glyph, text],
      ),
    );
  }

  /// A ship's name, its shields and how often it slips a shot, the
  /// enemy's habit, and its hull as a bar of planks.
  Widget _buildShipHeader({
    required String name,
    required ShipState ship,
    required int evasion,
    required Color color,
    EnemyHabit habit = EnemyHabit.none,
  }) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.watch(appLanguageProvider);
    final ratio = ship.maxHull == 0 ? 0.0 : ship.hull / ship.maxHull;
    final showHabit = widget.rules.habits && habit != EnemyHabit.none;
    final steel = _roomColor(context, ShipRoom.bulwark);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(name,
                  style: TextStyle(
                      fontFamily: InkFonts.display, fontSize: 20, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            for (var i = 0; i < max(ship.maxLayers, ship.layers); i++)
              Icon(
                i < ship.layers ? Icons.shield : Icons.shield_outlined,
                size: 15,
                color: steel,
              ),
            const SizedBox(width: 8),
            Tooltip(
              message: trFor(lang, 'ship_evasion_hint'),
              child: Text(
                trFor(lang, 'ship_slips_label').replaceAll('{n}', '$evasion'),
                style: theme.textTheme.labelSmall?.copyWith(color: ink.tide),
              ),
            ),
          ],
        ),
        if (showHabit)
          Tooltip(
            message: trFor(lang, 'ship_habit_${habit.name}_hint'),
            child: Row(
              key: const Key('ship_enemy_habit'),
              children: [
                Icon(_habitIcon(habit), size: 13, color: color),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    trFor(lang, 'ship_habit_${habit.name}'),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: ink.ash, fontStyle: FontStyle.italic),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(trFor(lang, 'hull_label').toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 8,
                child: CustomPaint(
                  painter: _PlankBarPainter(
                    ratio: ratio.clamp(0.0, 1.0),
                    color: ratio > 0.5
                        ? color
                        : ratio > 0.25
                            ? ink.ember
                            : ink.blood,
                    empty: ink.seam,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${ship.hull}/${ship.maxHull}',
                style: theme.textTheme.labelSmall?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ),
      ],
    );
  }

  /// A ship drawn side on: the hull, a mast and its flag, the three rooms
  /// on deck (helm aft, guns amidships, bulwark forward) and the hold
  /// below them.
  Widget _buildHull({
    required ShipState ship,
    required bool isPlayer,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    const height = 140.0;
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      Rect at(double l, double t, double r, double b) =>
          Rect.fromLTRB(w * l, height * t, w * r, height * b);
      final rooms = {
        ShipRoom.helm: at(0.05, 0.25, 0.345, 0.585),
        ShipRoom.guns: at(0.355, 0.25, 0.645, 0.585),
        ShipRoom.bulwark: at(0.655, 0.25, 0.95, 0.585),
        ShipRoom.hold: at(0.1, 0.625, 0.9, 0.87),
      };
      return SizedBox(
        key: Key('ship_hull_${isPlayer ? 'eel' : 'enemy'}'),
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _HullPainter(
                  accent: color,
                  fill: theme.colorScheme.surfaceContainer,
                  seam: ink.seam,
                  mast: ink.ash,
                ),
              ),
            ),
            for (final entry in rooms.entries)
              Positioned.fromRect(
                rect: entry.value,
                child: _buildRoomTile(
                  ship: ship,
                  room: entry.key,
                  isPlayer: isPlayer,
                  wide: entry.key == ShipRoom.hold,
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildRoomTile({
    required ShipState ship,
    required ShipRoom room,
    required bool isPlayer,
    bool wide = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ink = InkColors.of(context);
    final lang = ref.watch(appLanguageProvider);
    final state = ship.room(room);
    final color = _roomColor(context, room);
    final crew = isPlayer ? _battle.crewById(_battle.stations[room]) : null;
    final armed = _battle.weaponById(_armedWeaponId);
    final canFireHere = !isPlayer &&
        armed != null &&
        _battle.canFire(armed) &&
        !_busy &&
        !_over;
    final canStationHere = isPlayer && _selectedCrewId != null && !_busy;
    final aiming = !isPlayer && _aimRoom == room;
    final incoming = <ShipWeapon>[
      if (isPlayer && widget.foresight && _battle.aimVisible)
        for (final w in _battle.enemy.weapons)
          if (readyNextTurn(w, _battle.enemy) && _battle.plan[w.id] == room) w,
    ];
    final preview = canFireHere ? _battle.preview(_armedWeaponId, room) : null;
    final focused = !isPlayer && (_battle.focus[room] ?? 0) > 0;
    final leaks = room == ShipRoom.hold ? ship.leaks : 0;
    final railOpen = room == ShipRoom.bulwark && bulwarkOpen(ship);
    final flash = _flashes[(isPlayer, room)];
    final pipSize = wide ? 8.0 : 7.0;
    final label = theme.textTheme.labelSmall;

    final Color border;
    final double borderWidth;
    if (aiming || canFireHere) {
      border = ink.gold;
      borderWidth = aiming ? 3 : 2;
    } else if (canStationHere) {
      border = ink.tide;
      borderWidth = 2;
    } else if (incoming.isNotEmpty) {
      border = ink.blood;
      borderWidth = 2;
    } else {
      border = state.isDown ? ink.seam : color.withValues(alpha: 0.55);
      borderWidth = 1;
    }
    final background = state.isDown
        ? colorScheme.surfaceContainerHighest
        : canFireHere
            ? ink.gold.withValues(alpha: aiming ? 0.22 : 0.10)
            : state.onFire
                ? ink.ember.withValues(alpha: 0.16)
                : colorScheme.surface.withValues(alpha: 0.85);

    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_roomIcon(room),
            size: 14, color: state.isDown ? colorScheme.outline : color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            trFor(lang, 'ship_room_${room.name}_title').toUpperCase(),
            style: label?.copyWith(
                letterSpacing: 0.5,
                color: state.isDown ? colorScheme.outline : null),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (focused) ...[
          const SizedBox(width: 3),
          Tooltip(
            message: trFor(lang, 'ship_focus_hint'),
            child: Icon(Icons.center_focus_strong, size: 13, color: ink.ember),
          ),
        ],
      ],
    );
    final status = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.level == 0)
            Text('—', style: label)
          else
            for (var i = 0; i < state.level; i++)
              Container(
                width: pipSize,
                height: pipSize,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(
                  color: i < state.working ? color : null,
                  border: i < state.working
                      ? null
                      : Border.all(color: ink.blood, width: 1.5),
                ),
              ),
          if (state.isDown) ...[
            const SizedBox(width: 2),
            Text(trFor(lang, 'ship_room_out_label'),
                style: label?.copyWith(color: ink.blood)),
          ],
          if (state.onFire) ...[
            const SizedBox(width: 2),
            Icon(Icons.local_fire_department, size: 14, color: ink.ember),
          ],
          for (var i = 0; i < leaks; i++)
            Icon(Icons.water_drop,
                key: const Key('ship_leak'), size: 13, color: ink.tide),
          for (final w in incoming) ...[
            const SizedBox(width: 2),
            Icon(Icons.warning_amber_rounded, size: 14, color: ink.blood),
            Text('${w.damage}', style: label?.copyWith(color: ink.blood)),
          ],
          if (railOpen) ...[
            const SizedBox(width: 2),
            Icon(Icons.door_front_door_outlined, size: 14, color: ink.ember),
          ],
          if (preview != null) ...[
            const SizedBox(width: 4),
            _buildShotPreview(preview),
          ],
        ],
      ),
    );
    final token = crew == null ? null : _crewToken(crew, size: 18);
    final content = wide
        ? Row(
            children: [
              Flexible(child: title),
              const SizedBox(width: 8),
              Expanded(child: status),
              if (token != null) token,
            ],
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: title),
                  if (token != null) token,
                ],
              ),
              const SizedBox(height: 2),
              status,
            ],
          );
    return Tooltip(
      message: railOpen
          ? trFor(lang, 'ship_room_bulwark_open_hint')
          : trFor(lang, 'ship_room_${room.name}_hint'),
      child: GestureDetector(
        key: Key('ship_room_${isPlayer ? 'eel' : 'enemy'}_${room.name}'),
        onTap: () {
          if (canFireHere) {
            _fire(room);
          } else if (canStationHere) {
            _station(room);
          } else if (isPlayer && crew != null && !_busy) {
            setState(() => _selectedCrewId = crew.id);
          }
        },
        onLongPress:
            canFireHere && ref.watch(aimedShotsProvider) != AimedShots.off
                ? () => _startAim(room)
                : null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 2, 5, 2),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border, width: borderWidth),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: content),
              if (flash != null)
                Positioned(
                  right: 0,
                  top: -14,
                  child: _Flash(
                    key: ValueKey(flash.$2),
                    text: flash.$1,
                    color: isPlayer ? ink.blood : ink.gold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// A crew member's round token: their initial, gold when picked to be
  /// moved.
  Widget _crewToken(ShipCrew crew, {required double size}) {
    final ink = InkColors.of(context);
    final picked = _selectedCrewId == crew.id;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (picked ? ink.gold : ink.tide).withValues(alpha: 0.18),
        border: Border.all(color: picked ? ink.gold : ink.tide, width: 1.5),
      ),
      child: Text(
        crew.name.isEmpty ? '?' : crew.name[0].toUpperCase(),
        style: TextStyle(
            fontFamily: InkFonts.system,
            fontSize: size * 0.48,
            color: picked ? ink.gold : ink.tide),
      ),
    );
  }

  /// What the armed weapon would do to this room if it lands: the shield
  /// that would stop it, or the hull and pips it would cost, KO when the
  /// room would go down, a flame when it would burn, a drop for a leak.
  Widget _buildShotPreview(ShotOutcome preview) {
    final theme = Theme.of(context);
    final lang = ref.watch(appLanguageProvider);
    final style = theme.textTheme.labelSmall
        ?.copyWith(fontWeight: FontWeight.bold, color: _previewColor);
    if (preview.absorbed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield, size: 13, color: _previewColor),
          Text('0', style: style),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('−${preview.hullDamage}', style: style),
        if (preview.roomDamage > 0) ...[
          const SizedBox(width: 3),
          const Icon(Icons.grid_view, size: 11, color: _previewColor),
          Text('−${preview.roomDamage}', style: style),
        ],
        if (preview.roomKnockedOut) ...[
          const SizedBox(width: 3),
          Text(trFor(lang, 'preview_lethal_label'), style: style),
        ],
        if (preview.fireStarted) ...[
          const SizedBox(width: 2),
          const Icon(Icons.local_fire_department,
              size: 13, color: _previewColor),
        ],
        if (preview.leakOpened) ...[
          const SizedBox(width: 2),
          const Icon(Icons.water_drop, size: 13, color: _previewColor),
        ],
      ],
    );
  }

  /// The enemy's guns: each with its charge as a ring, and the room of
  /// the Eel it means to hit when a foresight sail shows it.
  Widget _buildEnemyWeapons(bool fr) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.watch(appLanguageProvider);
    final enemy = _battle.enemy;
    Widget card(ShipWeapon w) {
      final aimAt =
          widget.foresight && _battle.aimVisible && readyNextTurn(w, enemy)
              ? _battle.plan[w.id]
              : null;
      final note = !_battle.inRange(w)
          ? trFor(lang, 'ship_out_of_range_label')
          : aimAt != null
              ? trFor(lang, 'ship_room_${aimAt.name}_title')
              : w.isReady
                  ? trFor(lang, 'ship_weapon_ready_label')
                  : '${w.charge}/${w.chargeTurns}';
      final small = theme.textTheme.labelSmall;
      return Container(
        padding: const EdgeInsets.fromLTRB(4, 3, 6, 3),
        decoration: BoxDecoration(
          border: Border.all(color: ink.seam),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            _ChargeRing(
              value: w.chargeTurns <= 0 ? 1 : w.charge / w.chargeTurns,
              color: ink.blood,
              track: ink.seam,
              size: 24,
              child: Icon(_weaponIcon(w), size: 11, color: ink.blood),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${w.nameFor(fr)} · ${w.damage}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: small),
                  Row(
                    children: [
                      if (aimAt != null)
                        Icon(Icons.arrow_forward, size: 11, color: ink.blood),
                      Flexible(
                        child: Text(note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: small?.copyWith(
                                color: aimAt != null ? ink.blood : ink.ash)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final weapons = enemy.weapons;
    if (weapons.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, constraints) {
      final perRow = min(weapons.length, 3);
      final width = (constraints.maxWidth - 6 * (perRow - 1)) / perRow;
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final w in weapons) SizedBox(width: width, child: card(w)),
        ],
      );
    });
  }

  /// The Eel's guns as cards: the charge as a ring, gold when ready; the
  /// armed one picked out. Tap to arm, then tap a room of the enemy.
  Widget _buildPlayerWeapons(bool fr) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.watch(appLanguageProvider);
    final weapons = _battle.player.weapons;
    Widget card(ShipWeapon w) {
      final armed = _armedWeaponId == w.id;
      final ready = _battle.inRange(w) && w.isReady;
      final state = !_battle.inRange(w)
          ? trFor(lang, 'ship_out_of_range_label')
          : armed
              ? trFor(lang, 'ship_weapon_armed_label')
              : w.isReady
                  ? trFor(lang, 'ship_weapon_ready_label')
                  : '${w.charge}/${w.chargeTurns}';
      final enabled = _battle.canFire(w) && !_busy && !_over;
      return Material(
        color: armed
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(
              color: armed ? ink.gold : ink.seam, width: armed ? 2 : 1),
        ),
        child: InkWell(
          key: Key('ship_weapon_${w.id}'),
          borderRadius: BorderRadius.circular(4),
          onTap: enabled
              ? () => setState(() {
                    _armedWeaponId = armed ? null : w.id;
                    _selectedCrewId = null;
                    _cancelAim();
                  })
              : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 8, 4),
            child: Row(
              children: [
                _ChargeRing(
                  value: w.chargeTurns <= 0 ? 1 : w.charge / w.chargeTurns,
                  color: ready ? ink.gold : ink.ash,
                  track: ink.seam,
                  size: 30,
                  child: Icon(_weaponIcon(w),
                      size: 14, color: ready ? ink.gold : ink.ash),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.nameFor(fr),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge),
                      Text(
                        '${w.damage} · $state',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: ready ? ink.gold : ink.ash),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (weapons.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, constraints) {
      final perRow = weapons.length == 1 ? 1 : 2;
      final width = (constraints.maxWidth - 8 * (perRow - 1)) / perRow;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final w in weapons) SizedBox(width: width, child: card(w)),
        ],
      );
    });
  }

  /// The shot the guns are loaded with, kept until changed.
  Widget _buildAmmo(AppLanguage lang) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    // On a narrow phone the four shots need the label's room.
    final narrow = MediaQuery.sizeOf(context).width < 380;
    return Row(
      children: [
        if (!narrow) ...[
          Text(trFor(lang, 'ship_ammo_label'),
              style: theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final ammo in ShipAmmo.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Tooltip(
                      message: trFor(lang, 'ship_ammo_${ammo.name}_hint'),
                      child: ChoiceChip(
                        key: Key('ship_ammo_${ammo.name}'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        showCheckmark: false,
                        labelPadding: const EdgeInsets.only(right: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        selected: _battle.ammo == ammo,
                        avatar: Icon(_ammoIcon(ammo), size: 13),
                        label: Text(trFor(lang, 'ship_ammo_${ammo.name}'),
                            style: theme.textTheme.labelSmall),
                        onSelected: _busy || _over
                            ? null
                            : (_) => setState(() => _battle.ammo = ammo),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The crew, one card each: health, the station they hold (tap another
  /// to move them) and their order, once a battle.
  Future<void> _openCrewSheet(Map<String, dynamic>? enemies) {
    final lang = ref.read(appLanguageProvider);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) {
          void act(VoidCallback change) {
            setState(change);
            setSheet(() {});
          }

          final theme = Theme.of(sheetContext);
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75),
              child: ListView(
                key: const Key('ship_crew_sheet'),
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(trFor(lang, 'ship_crew_title'),
                            style: const TextStyle(
                                fontFamily: InkFonts.display, fontSize: 20)),
                      ),
                      OutlinedButton.icon(
                        key: const Key('ship_auto_station'),
                        onPressed: _busy || _over || _battle.crew.isEmpty
                            ? null
                            : () => act(() {
                                  _battle.autoStation();
                                  _selectedCrewId = null;
                                }),
                        icon: const Icon(Icons.auto_fix_high, size: 16),
                        label: Text(trFor(lang, 'ship_auto_station_button'),
                            style: theme.textTheme.labelSmall),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final c in _battle.crew) _crewCard(c, enemies, act),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _crewCard(ShipCrew c, Map<String, dynamic>? enemies,
      void Function(VoidCallback) act) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.read(appLanguageProvider);
    final station = _battle.stationOf(c.id);
    final order = orderFor(c);
    final ratio = c.maxHealth <= 0 ? 0.0 : c.health / c.maxHealth;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: ink.seam),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _crewToken(c, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: ratio.clamp(0.0, 1.0),
                              minHeight: 4,
                              color: ink.heal,
                              backgroundColor: ink.seam,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('${c.health}/${c.maxHealth}',
                            style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final room in ShipRoom.values)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: OutlinedButton(
                      key: Key('ship_station_${c.id}_${room.name}'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: station == room
                            ? _roomColor(context, room).withValues(alpha: 0.16)
                            : null,
                        side: BorderSide(
                            color: station == room
                                ? _roomColor(context, room)
                                : ink.seam),
                      ),
                      onPressed: _busy || _over
                          ? null
                          : () => act(() {
                                _battle.station(c.id, room);
                                _selectedCrewId = null;
                              }),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          trFor(lang, 'ship_room_${room.name}_title'),
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (order != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: _buildOrderChip(lang, c, order, enemies, act),
            ),
            const SizedBox(height: 2),
            Text(trFor(lang, 'ship_order_${order.name}_hint'),
                style: theme.textTheme.bodySmall?.copyWith(color: ink.ash)),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderChip(AppLanguage lang, ShipCrew member, CrewOrder order,
      Map<String, dynamic>? enemies, void Function(VoidCallback) act) {
    final theme = Theme.of(context);
    final spent = _battle.ordersUsed.contains(member.id);
    final usable = _orderUsable(member, enemies);
    final name = member.isPlayer ? trFor(lang, 'you_label') : member.name;
    return Tooltip(
      message: trFor(lang, 'ship_order_${order.name}_hint'),
      child: ActionChip(
        key: Key('ship_order_${order.name}'),
        visualDensity: VisualDensity.compact,
        avatar: Icon(spent ? Icons.check : _orderIcon(order), size: 14),
        label: Text(
          '$name: ${trFor(lang, 'ship_order_${order.name}')}',
          style: theme.textTheme.labelSmall?.copyWith(
            decoration: spent ? TextDecoration.lineThrough : null,
          ),
        ),
        onPressed: usable
            ? () => act(() {
                  _battle.giveOrder(member);
                  _rearm();
                })
            : null,
      ),
    );
  }

  /// The last few lines of the battle, in a box that keeps its size so
  /// the Eel never moves down the screen; the whole log opens from it.
  Widget _buildLog(BuildContext context) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.watch(appLanguageProvider);
    final log = _battle.log;
    final lines = log.length > 4 ? log.sublist(log.length - 4) : log;
    final style =
        theme.textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.25);
    // Empty on the first turn: a thin strip, growing to four lines.
    return Container(
      key: const Key('ship_log'),
      height: lines.isEmpty
          ? 32
          : lines.length <= 2
              ? 44
              : 68,
      padding: const EdgeInsets.fromLTRB(10, 3, 0, 3),
      decoration: BoxDecoration(
        border: Border.all(color: ink.seam),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines.length; i++)
                  Text(
                    _line(lines[i]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style?.copyWith(
                        color: i == lines.length - 1
                            ? theme.colorScheme.onSurface
                            : ink.ash),
                  ),
              ],
            ),
          ),
          IconButton(
            key: const Key('ship_log_button'),
            tooltip: trFor(lang, 'ship_log_title'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36, height: 26),
            icon: Icon(Icons.history, size: 18, color: ink.ash),
            onPressed: log.isEmpty ? null : _openLog,
          ),
        ],
      ),
    );
  }

  Future<void> _openLog() {
    final lang = ref.read(appLanguageProvider);
    final lines = [for (final line in _battle.log.reversed) _line(line)];
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(trFor(lang, 'ship_log_title'),
                  style: const TextStyle(
                      fontFamily: InkFonts.display, fontSize: 20)),
              const SizedBox(height: 8),
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(line,
                      style: Theme.of(sheetContext).textTheme.bodyMedium),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The aim bar: red edges where the shot goes wide, amber for a plain
/// shot, green in the middle for a critical, and the sweeping marker.
class _AimBarPainter extends CustomPainter {
  const _AimBarPainter({
    required this.position,
    required this.marker,
    required this.wide,
    required this.steady,
    required this.perfect,
  });

  final double position;
  final Color marker;
  final Color wide;
  final Color steady;
  final Color perfect;

  @override
  void paint(Canvas canvas, Size size) {
    final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.25, size.width, size.height * 0.5),
        const Radius.circular(2));
    canvas.save();
    canvas.clipRRect(bar);
    void band(double from, double to, Color color) => canvas.drawRect(
        Rect.fromLTRB(from * size.width, 0, to * size.width, size.height),
        Paint()..color = color);
    band(0, 1, wide.withValues(alpha: 0.55));
    band(0.5 - aimSteadyHalfWidth, 0.5 + aimSteadyHalfWidth,
        steady.withValues(alpha: 0.75));
    band(0.5 - aimPerfectHalfWidth, 0.5 + aimPerfectHalfWidth,
        perfect.withValues(alpha: 0.9));
    canvas.restore();
    final x = position.clamp(0.0, 1.0) * size.width;
    canvas.drawRect(
        Rect.fromLTWH(x - 2, 0, 4, size.height), Paint()..color = marker);
  }

  @override
  bool shouldRepaint(_AimBarPainter old) =>
      old.position != position ||
      old.marker != marker ||
      old.wide != wide ||
      old.steady != steady ||
      old.perfect != perfect;
}

/// A ship side on: the hull with its deck line, a dashed line between
/// the deck and the hold, and a mast flying a flag.
class _HullPainter extends CustomPainter {
  const _HullPainter({
    required this.accent,
    required this.fill,
    required this.seam,
    required this.mast,
  });

  final Color accent;
  final Color fill;
  final Color seam;
  final Color mast;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final deck = h * 0.2;
    final hull = Path()
      ..moveTo(w * 0.02, deck)
      ..lineTo(w * 0.98, deck)
      ..lineTo(w * 0.94, h * 0.86)
      ..quadraticBezierTo(w * 0.8, h * 0.97, w * 0.5, h * 0.97)
      ..quadraticBezierTo(w * 0.2, h * 0.97, w * 0.07, h * 0.86)
      ..close();
    canvas.drawPath(hull, Paint()..color = fill);
    canvas.drawPath(
        hull,
        Paint()
          ..color = accent.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawLine(
        Offset(w * 0.02, deck),
        Offset(w * 0.98, deck),
        Paint()
          ..color = accent
          ..strokeWidth = 3);
    // Deck and hold.
    final dash = Paint()
      ..color = seam
      ..strokeWidth = 1;
    for (var x = w * 0.06; x < w * 0.94; x += 8) {
      canvas.drawLine(Offset(x, h * 0.605), Offset(x + 4, h * 0.605), dash);
    }
    // Mast and flag.
    final mastX = w * 0.5;
    canvas.drawLine(
        Offset(mastX, deck),
        Offset(mastX, h * 0.02),
        Paint()
          ..color = mast
          ..strokeWidth = 2);
    final flag = Path()
      ..moveTo(mastX + 1, h * 0.03)
      ..lineTo(mastX + 26, h * 0.03)
      ..lineTo(mastX + 20, h * 0.075)
      ..lineTo(mastX + 26, h * 0.12)
      ..lineTo(mastX + 1, h * 0.12)
      ..close();
    canvas.drawPath(flag, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _HullPainter old) =>
      old.accent != accent ||
      old.fill != fill ||
      old.seam != seam ||
      old.mast != mast;
}

/// A hull bar made of ten planks, filled from the left.
class _PlankBarPainter extends CustomPainter {
  const _PlankBarPainter(
      {required this.ratio, required this.color, required this.empty});

  final double ratio;
  final Color color;
  final Color empty;

  @override
  void paint(Canvas canvas, Size size) {
    const planks = 10;
    const gap = 2.0;
    final plank = (size.width - gap * (planks - 1)) / planks;
    final filled = ratio * planks;
    for (var i = 0; i < planks; i++) {
      final left = i * (plank + gap);
      final rect = Rect.fromLTWH(left, 0, plank, size.height);
      canvas.drawRect(rect, Paint()..color = empty);
      final part = (filled - i).clamp(0.0, 1.0);
      if (part > 0) {
        canvas.drawRect(Rect.fromLTWH(left, 0, plank * part, size.height),
            Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PlankBarPainter old) =>
      old.ratio != ratio || old.color != color || old.empty != empty;
}

/// The range as a ruler: close, medium and long notches on a dotted
/// line, the ships' distance marked in gold.
class _RangeRulerPainter extends CustomPainter {
  const _RangeRulerPainter({
    required this.at,
    required this.of,
    required this.mark,
    required this.line,
    required this.fill,
  });

  final int at;
  final int of;
  final Color mark;
  final Color line;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final left = size.width * 0.12;
    final right = size.width * 0.88;
    final dot = Paint()..color = line;
    for (var x = left; x < right; x += 6) {
      canvas.drawCircle(Offset(x, y), 1, dot);
    }
    for (var i = 0; i < of; i++) {
      final x = of == 1 ? size.width / 2 : left + (right - left) * i / (of - 1);
      final c = Offset(x, y);
      if (i == at) {
        canvas.drawCircle(c, 7, Paint()..color = mark);
      } else {
        canvas.drawCircle(c, 5, Paint()..color = fill);
        canvas.drawCircle(
            c,
            5,
            Paint()
              ..color = line
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RangeRulerPainter old) =>
      old.at != at ||
      old.of != of ||
      old.mark != mark ||
      old.line != line ||
      old.fill != fill;
}

/// Two faint lines of waves behind the sea strip.
class _WavesPainter extends CustomPainter {
  const _WavesPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final y in [size.height * 0.3, size.height * 0.75]) {
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x < size.width; x += 24) {
        path.quadraticBezierTo(x + 6, y - 5, x + 12, y);
        path.quadraticBezierTo(x + 18, y + 5, x + 24, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavesPainter old) => old.color != color;
}

/// A weapon's charge as a ring around its icon.
class _ChargeRing extends StatelessWidget {
  const _ChargeRing({
    required this.value,
    required this.color,
    required this.track,
    required this.size,
    required this.child,
  });

  final double value;
  final Color color;
  final Color track;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value.clamp(0.0, 1.0),
              strokeWidth: size / 8,
              color: color,
              backgroundColor: track,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// What a shot just did, rising off the room it hit and fading.
class _Flash extends StatelessWidget {
  const _Flash({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1100),
        builder: (context, t, child) => Opacity(
          opacity: (1 - t * t).clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, -10 * t), child: child),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: InkFonts.system,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
            shadows: const [Shadow(blurRadius: 3, color: Colors.black)],
          ),
        ),
      ),
    );
  }
}

// Built once: the log is tidied on every refresh, and the clock refreshes
// every second.
final RegExp _deElidedArticle = RegExp(r"\bde L['’]");
final RegExp _deBeforeVowel = RegExp(r'\bde ([AEIOUÉÈÊ])');
final RegExp _articleMidSentence = RegExp(r'([a-zà-ÿ]) (Le|La|Les) ');

/// A log line with a ship's name dropped in, made to read right: a name
/// that carries its own article ("The Rusty Eel", "Le Rusty Eel") after
/// the line's article, and the French contractions (du, au, d’).
String tidyShipLine(String text, AppLanguage lang) {
  if (lang == AppLanguage.fr) {
    return text
        .replaceAll(' de Le ', ' du ')
        .replaceAll(' de Les ', ' des ')
        .replaceAll(' à Le ', ' au ')
        .replaceAll(' à Les ', ' aux ')
        .replaceAll(' de La ', ' de la ')
        .replaceAllMapped(_deElidedArticle, (_) => 'de l’')
        .replaceAllMapped(_deBeforeVowel, (m) => 'd’${m.group(1)}')
        // "sous Le Rusty Eel": the name's article, mid-sentence.
        .replaceAllMapped(_articleMidSentence,
            (m) => '${m.group(1)} ${m.group(2)!.toLowerCase()} ');
  }
  return text.replaceAll('the The ', 'the ').replaceAll('The The ', 'The ');
}

/// The color of damage that is coming but not dealt yet, the same blue
/// the dice fight uses for its preview.
const Color _previewColor = Color(0xFF42A5F5);

/// Boarders met by a hand in the hold come over the rail at this share
/// of their health.
const double holdMannedBoarderHealth = 0.75;

/// A room's own colour, from the Stitched Ink palette; darker on a light
/// page so it still reads.
Color _roomColor(BuildContext context, ShipRoom room) {
  final ink = InkColors.of(context);
  final light = Theme.of(context).brightness == Brightness.light;
  return switch (room) {
    ShipRoom.helm => ink.tide,
    ShipRoom.guns => ink.ember,
    ShipRoom.bulwark =>
      light ? const Color(0xFF4F6275) : const Color(0xFF9FB0C2),
    ShipRoom.hold => light ? const Color(0xFF7A5534) : const Color(0xFFB08A64),
  };
}

IconData _weaponIcon(ShipWeapon weapon) => weapon.incendiary
    ? Icons.local_fire_department
    : weapon.piercing
        ? Icons.bolt
        : Icons.gps_fixed;

IconData _roomIcon(ShipRoom room) => switch (room) {
      ShipRoom.helm => Icons.explore,
      ShipRoom.guns => Icons.gps_fixed,
      ShipRoom.bulwark => Icons.shield,
      ShipRoom.hold => Icons.inventory_2,
    };

IconData _weatherIcon(SeaWeather weather) => switch (weather) {
      SeaWeather.calm => Icons.wb_sunny_outlined,
      SeaWeather.tailwind => Icons.air,
      SeaWeather.crosswind => Icons.cyclone,
      SeaWeather.squall => Icons.thunderstorm_outlined,
      SeaWeather.fog => Icons.foggy,
    };

Color _weatherColor(InkColors ink, SeaWeather weather) => switch (weather) {
      SeaWeather.calm => ink.gold,
      SeaWeather.tailwind => ink.tide,
      SeaWeather.crosswind => ink.voidColor,
      SeaWeather.squall => ink.ash,
      SeaWeather.fog => ink.ash,
    };

IconData _ammoIcon(ShipAmmo ammo) => switch (ammo) {
      ShipAmmo.round => Icons.circle,
      ShipAmmo.chain => Icons.link,
      ShipAmmo.grape => Icons.grain,
      ShipAmmo.heated => Icons.local_fire_department_outlined,
    };

IconData _habitIcon(EnemyHabit habit) => switch (habit) {
      EnemyHabit.none => Icons.sailing,
      EnemyHabit.flee => Icons.directions_run,
      EnemyHabit.marksman => Icons.my_location,
      EnemyHabit.ram => Icons.double_arrow,
      EnemyHabit.boarder => Icons.sports_kabaddi,
    };

IconData _orderIcon(CrewOrder order) => switch (order) {
      CrewOrder.allHands => Icons.handyman,
      CrewOrder.brace => Icons.shield_moon_outlined,
      CrewOrder.grapple => Icons.anchor,
      CrewOrder.bless => Icons.volunteer_activism,
      CrewOrder.shoreUp => Icons.add_moderator,
      CrewOrder.markHelm => Icons.gps_not_fixed,
      CrewOrder.cutRigging => Icons.content_cut,
      CrewOrder.eagleEye => Icons.visibility,
      CrewOrder.voidWard => Icons.blur_on,
    };
