import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/encounter.dart';
import '../combat/ship_combat.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/combat_active_provider.dart';
import '../providers/game_db_providers.dart';
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
  });

  final bool won;
  final ShipState player;
  final List<ShipCrew> crew;
  final List<String> log;

  /// True when the win came by boarding: the prize is the ship's hold.
  final bool boarded;
}

/// The room-by-room ship battle (see ship_combat.dart), drawn as two
/// ships of four rooms each. The enemy sits at the top with its weapons
/// and their charge; the Eel at the bottom with hers, her crew at their
/// stations, and the enemy's aim marked on her rooms when a foresight
/// sail is aboard. A turn: crew work and weapons charge, the player fires
/// each ready weapon at a room of the enemy's ship (tap the weapon, then
/// the room) and moves the crew (tap a member, then a room), then ends
/// the turn; the enemy fires back, fires burn, and bulwarks come back.
/// When a bulwark is down and no layer stands, the rail is open: the
/// player can board and fight the enemy's crew on the dice (a win takes
/// the ship), and the enemy may board the Eel (a hand in the hold meets
/// them weakened; losing the deck wrecks the hold and a fifth of the hull).
/// With [turnSeconds] set, each turn runs against the clock: when it runs
/// out the turn ends as it stands, and a weapon not fired keeps its charge.
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

  @override
  ConsumerState<ShipBattlePanel> createState() => _ShipBattlePanelState();
}

class _ShipBattlePanelState extends ConsumerState<ShipBattlePanel> {
  late ShipState _player;
  late ShipState _enemy;
  late List<ShipCrew> _crew;

  /// Room -> crew id at that station.
  final Map<ShipRoom, String> _stations = {};

  /// Enemy weapon id -> the room it will fire at next.
  final Map<String, ShipRoom> _plan = {};

  /// Rooms whose hand spent this turn repairing or fighting a fire, and
  /// so is not at their station (see [crewTurn]).
  Set<ShipRoom> _busyRooms = {};
  final List<String> _log = [];
  String? _armedWeaponId;
  String? _selectedCrewId;
  bool _busy = false;
  bool _over = false;
  int _turn = 1;

  /// A boarding party thrown back does not try again this battle.
  bool _boardingSpent = false;
  bool _enemyBoardingSpent = false;

  /// The turn's clock (see [ShipBattlePanel.turnSeconds]): it stands still
  /// while the enemy fires or a deck is fought over.
  Timer? _clock;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _enemy = widget.enemy;
    _crew = List.of(widget.crew);
    // Everyone starts somewhere useful: the player at the helm, the next
    // hand at the guns, the next at the bulwark.
    final order = [
      ShipRoom.helm,
      ShipRoom.guns,
      ShipRoom.bulwark,
      ShipRoom.hold
    ];
    for (var i = 0; i < _crew.length && i < order.length; i++) {
      _stations[order[i]] = _crew[i].id;
    }
    _planEnemy();
    _beginPlayerTurn();
    _startClock();
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  // --- Helpers -------------------------------------------------------------

  String _t(
    String key, {
    String? ship,
    String? weapon,
    ShipRoom? room,
    String? crew,
    int? n,
  }) {
    final lang = ref.read(appLanguageProvider);
    var text = trFor(lang, key);
    if (ship != null) text = text.replaceAll('{ship}', ship);
    if (weapon != null) text = text.replaceAll('{weapon}', weapon);
    if (room != null) {
      text = text.replaceAll('{room}', trFor(lang, 'ship_room_${room.name}'));
    }
    if (crew != null) text = text.replaceAll('{crew}', crew);
    if (n != null) text = text.replaceAll('{n}', '$n');
    return text;
  }

  bool get _french => ref.read(appLanguageProvider) == AppLanguage.fr;

  ShipCrew? _crewById(String? id) {
    if (id == null) return null;
    for (final c in _crew) {
      if (c.id == id) return c;
    }
    return null;
  }

  Stations get _stationsMap => {
        for (final entry in _stations.entries)
          if (_crewById(entry.value) != null)
            entry.key: _crewById(entry.value)!,
      };

  ShipRoom? _stationOf(String crewId) {
    for (final entry in _stations.entries) {
      if (entry.value == crewId) return entry.key;
    }
    return null;
  }

  String? _firstReadyWeaponId() {
    for (final w in _player.weapons) {
      if (w.isReady) return w.id;
    }
    return null;
  }

  // --- Turn flow -----------------------------------------------------------

  void _planEnemy() {
    _plan.clear();
    for (final weapon in _enemy.weapons) {
      _plan[weapon.id] =
          enemyTargetFor(_player, weapon, widget.random.nextDouble());
    }
  }

  void _beginPlayerTurn() {
    final result = crewTurn(_player, _stationsMap);
    _player = result.ship;
    _busyRooms = result.busy;
    for (final work in result.work) {
      if (work.fireOut) {
        _log.add(
            _t('ship_log_fire_out', crew: work.crew.name, room: work.room));
      }
      if (work.roomRepaired) {
        _log.add(_t('ship_log_room_repaired',
            crew: work.crew.name, room: work.room));
      }
      if (work.hullRepaired > 0) {
        _log.add(_t('ship_log_hull_patched',
            crew: work.crew.name, n: work.hullRepaired));
      }
    }
    _player = chargeWeapons(_player,
        gunnerAboard: _stations.containsKey(ShipRoom.guns) &&
            !_busyRooms.contains(ShipRoom.guns));
    _armedWeaponId = _firstReadyWeaponId();
  }

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
    final held = _player.weapons.any((w) => w.isReady);
    _log.add(_t(held ? 'ship_log_time_up_held' : 'ship_log_time_up',
        ship: widget.shipName));
    _endTurn();
  }

  /// The helmsman at the helm this turn, if not busy repairing it.
  ShipCrew? get _helmsman =>
      _busyRooms.contains(ShipRoom.helm) ? null : _stationsMap[ShipRoom.helm];

  void _logShot(ShotOutcome outcome, ShipWeapon weapon,
      {required String ship}) {
    final name = weapon.nameFor(_french);
    if (outcome.dodged) {
      _log.add(_t('ship_log_shot_dodged', ship: ship, weapon: name));
      return;
    }
    if (outcome.absorbed) {
      _log.add(_t('ship_log_shot_absorbed', ship: ship, weapon: name));
      if (outcome.roomKnockedOut) {
        _log.add(_t('ship_log_room_down', ship: ship, room: ShipRoom.bulwark));
      }
      return;
    }
    _log.add(_t('ship_log_shot_hits',
        ship: ship, weapon: name, room: outcome.room, n: outcome.hullDamage));
    if (outcome.fireStarted) {
      _log.add(_t('ship_log_fire_started', ship: ship, room: outcome.room));
    }
    if (outcome.roomKnockedOut) {
      _log.add(_t('ship_log_room_down', ship: ship, room: outcome.room));
    }
  }

  void _fire(ShipRoom room) {
    if (_busy || _over || _armedWeaponId == null) return;
    ShipWeapon? weapon;
    for (final w in _player.weapons) {
      if (w.id == _armedWeaponId) weapon = w;
    }
    if (weapon == null || !weapon.isReady) return;
    final outcome = resolveShot(
      target: _enemy,
      weapon: weapon,
      room: room,
      evasionPercent: evasionFor(_enemy),
      roll: widget.random.nextDouble(),
    );
    setState(() {
      _enemy = outcome.target;
      _player = _player.withWeapon(weapon!.fired());
      _logShot(outcome, weapon, ship: widget.enemyName);
      _armedWeaponId = _firstReadyWeaponId();
    });
    if (!_enemy.isAfloat) _finish(won: true);
  }

  void _station(ShipRoom room) {
    final crewId = _selectedCrewId;
    if (crewId == null) return;
    setState(() {
      final from = _stationOf(crewId);
      final occupant = _stations[room];
      if (from != null) _stations.remove(from);
      if (occupant != null && occupant != crewId) {
        // Swap: whoever stood here takes the mover's old room, if any.
        if (from != null) {
          _stations[from] = occupant;
        }
      }
      _stations[room] = crewId;
      _selectedCrewId = null;
    });
  }

  Future<void> _endTurn() async {
    if (_busy || _over) return;
    _clock?.cancel();
    setState(() {
      _busy = true;
      _armedWeaponId = null;
      _selectedCrewId = null;
    });
    final enemyName = widget.enemyName;
    final maintenance = enemyMaintenance(_enemy);
    _enemy = maintenance.ship;
    for (final room in maintenance.firesOut) {
      _log.add(_t('ship_log_enemy_fire_out', ship: enemyName, room: room));
    }
    for (final room in maintenance.repaired) {
      _log.add(_t('ship_log_enemy_repairs', ship: enemyName, room: room));
    }
    _enemy = chargeWeapons(_enemy);
    final helmsman = _helmsman;
    for (final weapon in _enemy.weapons.where((w) => w.isReady).toList()) {
      final room = _plan[weapon.id] ??
          enemyTargetFor(_player, weapon, widget.random.nextDouble());
      final outcome = resolveShot(
        target: _player,
        weapon: weapon,
        room: room,
        evasionPercent: evasionFor(_player, helmsman: helmsman),
        roll: widget.random.nextDouble(),
      );
      _player = outcome.target;
      _enemy = _enemy.withWeapon(weapon.fired());
      _logShot(outcome, weapon, ship: widget.shipName);
      if (outcome.landed) {
        final hurt = _crewById(_stations[room]);
        if (hurt != null) {
          final injury = crewInjuryFor(weapon);
          _crew = [
            for (final c in _crew)
              c.id == hurt.id ? c.withHealth(c.health - injury) : c,
          ];
          _log.add(
              _t('ship_log_crew_hurt', crew: hurt.name, room: room, n: injury));
        }
      }
      if (!mounted) return;
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      if (!_player.isAfloat) {
        _finish(won: false);
        return;
      }
    }
    if (!await _maybeRepelBoarders(
        ref.read(localizedDbProvider(enemiesSchema)).value)) {
      return;
    }
    if (!mounted) return;
    final mine = endRound(_player,
        bulwarkCrewed: _stations.containsKey(ShipRoom.bulwark) &&
            !_busyRooms.contains(ShipRoom.bulwark));
    _player = mine.ship;
    for (final room in mine.burned) {
      _log.add(_t('ship_log_fire_burns', ship: widget.shipName, room: room));
    }
    final theirs = endRound(_enemy);
    _enemy = theirs.ship;
    for (final room in theirs.burned) {
      _log.add(_t('ship_log_fire_burns', ship: enemyName, room: room));
    }
    if (!_player.isAfloat) {
      setState(() {});
      _finish(won: false);
      return;
    }
    if (!_enemy.isAfloat) {
      setState(() {});
      _finish(won: true);
      return;
    }
    _planEnemy();
    _turn++;
    _beginPlayerTurn();
    if (!mounted) return;
    setState(() => _busy = false);
    _startClock();
  }

  void _finish({required bool won, bool boarded = false}) {
    if (_over) return;
    _over = true;
    _clock?.cancel();
    setState(() => _busy = true);
    widget.onFinished(ShipBattleOutcome(
      won: won,
      player: _player,
      crew: _crew,
      log: List.of(_log),
      boarded: boarded,
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
    if (rebuilt != null) _crew = rebuilt;
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
      !_boardingSpent &&
      bulwarkOpen(_enemy) &&
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
    });
    if (!grapplesHold(_enemy, widget.random.nextDouble())) {
      setState(() {
        _log.add(_t('ship_log_grapple_slipped', ship: widget.enemyName));
        _busy = false;
      });
      await _endTurn();
      return;
    }
    setState(() {
      _log.add(_t('ship_log_boarding_start', ship: widget.enemyName));
    });
    final won = await _deckFight(records);
    if (!mounted || won == null) return;
    if (won) {
      _log.add(_t('ship_log_boarding_won', ship: widget.enemyName));
      _finish(won: true, boarded: true);
      return;
    }
    final before = _player.hull;
    _player = boardingRepelled(_player);
    setState(() {
      _boardingSpent = true;
      _log.add(_t('ship_log_boarding_repelled',
          ship: widget.enemyName, n: before - _player.hull));
      _busy = false;
    });
    await _endTurn();
  }

  /// The enemy's try at the Eel's open rail, after its volley. Returns
  /// false when the fight ended the run.
  Future<bool> _maybeRepelBoarders(Map<String, dynamic>? enemies) async {
    final records = _boardingCrew(enemies);
    if (records == null ||
        _enemyBoardingSpent ||
        !bulwarkOpen(_player) ||
        widget.random.nextDouble() >= widget.boarding.chance) {
      return true;
    }
    _enemyBoardingSpent = true;
    final holdManned = _stations.containsKey(ShipRoom.hold) &&
        !_busyRooms.contains(ShipRoom.hold) &&
        !_player.room(ShipRoom.hold).isDown;
    setState(() {
      _log.add(_t('ship_log_boarders', ship: widget.enemyName));
    });
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return false;
    final won = await _deckFight(records,
        healthMultiplier: holdManned ? holdMannedBoarderHealth : 1.0);
    if (!mounted || won == null) return false;
    if (won) {
      _log.add(_t('ship_log_boarders_repelled'));
      return true;
    }
    final before = _player.hull;
    _player = boardersWreck(_player);
    _log.add(_t('ship_log_boarders_won', n: before - _player.hull));
    return true;
  }

  // --- UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final fr = lang == AppLanguage.fr;
    final theme = Theme.of(context);
    final enemies = ref.watch(localizedDbProvider(enemiesSchema)).value;
    final canBoard = _canBoardThem(enemies);
    final hintKey = _selectedCrewId != null
        ? 'ship_station_hint'
        : _armedWeaponId != null
            ? 'ship_fire_hint'
            : canBoard
                ? 'ship_board_hint'
                : 'ship_station_hint';
    var hint = trFor(lang, hintKey);
    if (hintKey == 'ship_board_hint') {
      hint = hint.replaceAll(
          '{crew}', _boardingCrewLabel(_boardingCrew(enemies)!));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildShipHeader(
                name: widget.enemyName,
                ship: _enemy,
                evasion: evasionFor(_enemy),
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 6),
              _buildRoomGrid(ship: _enemy, isPlayer: false),
              const SizedBox(height: 6),
              _buildEnemyWeapons(fr),
              const SizedBox(height: 10),
              _buildLog(context),
              const SizedBox(height: 10),
              _buildShipHeader(
                name: widget.shipName,
                ship: _player,
                evasion: evasionFor(_player, helmsman: _helmsman),
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 6),
              _buildRoomGrid(ship: _player, isPlayer: true),
              const SizedBox(height: 6),
              _buildPlayerWeapons(fr),
              const SizedBox(height: 6),
              _buildCrewBar(),
            ],
          ),
        ),
        if (widget.turnSeconds != null && !_over) ...[
          const SizedBox(height: 6),
          _buildClock(lang),
        ],
        const SizedBox(height: 6),
        Text(
          '${trFor(lang, 'round_label')} $_turn · $hint',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (canBoard) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _boardThem(enemies),
                  icon: const Icon(Icons.sports_kabaddi),
                  label: Text(trFor(lang, 'ship_board_button')),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy || _over ? null : _endTurn,
                icon: const Icon(Icons.hourglass_bottom),
                label: Text(trFor(lang, 'ship_end_turn_button')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// The turn's clock: a bar that empties and the seconds left, red for
  /// the last five; still while the enemy fires.
  Widget _buildClock(AppLanguage lang) {
    final theme = Theme.of(context);
    final total = max(1, widget.turnSeconds ?? 1);
    final urgent = !_busy && _secondsLeft <= 5;
    final color = urgent ? theme.colorScheme.error : theme.colorScheme.primary;
    return Row(
      key: const Key('ship_turn_clock'),
      children: [
        Icon(Icons.timer_outlined, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_secondsLeft / total).clamp(0.0, 1.0),
              minHeight: 6,
              color: color,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          trFor(lang, 'ship_turn_seconds').replaceAll('{n}', '$_secondsLeft'),
          style: theme.textTheme.labelMedium?.copyWith(
              color: color, fontFeatures: const [FontFeature.tabularFigures()]),
        ),
      ],
    );
  }

  Widget _buildShipHeader({
    required String name,
    required ShipState ship,
    required int evasion,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final lang = ref.watch(appLanguageProvider);
    final ratio = ship.maxHull == 0 ? 0.0 : ship.hull / ship.maxHull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            for (var i = 0; i < max(ship.maxLayers, ship.layers); i++)
              Icon(
                i < ship.layers ? Icons.shield : Icons.shield_outlined,
                size: 16,
                color: Colors.blueGrey,
              ),
            const SizedBox(width: 8),
            Icon(Icons.air,
                size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 2),
            Text('$evasion%', style: theme.textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 10,
            color: ratio > 0.5
                ? Colors.green
                : (ratio > 0.25 ? Colors.orange : Colors.red),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${trFor(lang, 'hull_label')} ${ship.hull} / ${ship.maxHull}',
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _buildRoomGrid({required ShipState ship, required bool isPlayer}) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.6,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: [
        for (final room in ShipRoom.values)
          _buildRoomTile(ship: ship, room: room, isPlayer: isPlayer),
      ],
    );
  }

  Widget _buildRoomTile({
    required ShipState ship,
    required ShipRoom room,
    required bool isPlayer,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lang = ref.watch(appLanguageProvider);
    final state = ship.room(room);
    final color = _roomColor(room);
    final crew = isPlayer ? _crewById(_stations[room]) : null;
    final canFireHere = !isPlayer && _armedWeaponId != null && !_busy && !_over;
    final canStationHere = isPlayer && _selectedCrewId != null && !_busy;
    final highlighted = canFireHere || canStationHere;
    final incoming = <ShipWeapon>[
      if (isPlayer && widget.foresight)
        for (final w in _enemy.weapons)
          if (readyNextTurn(w, _enemy) && _plan[w.id] == room) w,
    ];
    ShipWeapon? armed;
    if (canFireHere) {
      for (final w in _player.weapons) {
        if (w.id == _armedWeaponId) armed = w;
      }
    }
    final preview = armed == null
        ? null
        : previewShot(target: _enemy, weapon: armed, room: room);
    final railOpen = room == ShipRoom.bulwark && bulwarkOpen(ship);
    return Tooltip(
      message: railOpen
          ? trFor(lang, 'ship_room_bulwark_open_hint')
          : trFor(lang, 'ship_room_${room.name}_hint'),
      child: GestureDetector(
        onTap: () {
          if (canFireHere) {
            _fire(room);
          } else if (canStationHere) {
            _station(room);
          } else if (isPlayer && crew != null && !_busy) {
            setState(() => _selectedCrewId = crew.id);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: state.isDown
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: highlighted
                  ? colorScheme.primary
                  : color.withValues(alpha: 0.6),
              width: highlighted ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(_roomIcon(room),
                  size: 22, color: state.isDown ? colorScheme.outline : color),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trFor(lang, 'ship_room_${room.name}_title'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: state.isDown ? colorScheme.outline : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (state.level == 0)
                          Text('—', style: theme.textTheme.labelSmall)
                        else
                          for (var i = 0; i < state.level; i++)
                            Container(
                              width: 9,
                              height: 9,
                              margin: const EdgeInsets.only(right: 3),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                color: i < state.working
                                    ? color
                                    : Colors.red.withValues(alpha: 0.7),
                              ),
                            ),
                        if (state.onFire) ...[
                          const SizedBox(width: 2),
                          const Icon(Icons.local_fire_department,
                              size: 14, color: Colors.deepOrange),
                        ],
                        for (final w in incoming) ...[
                          const SizedBox(width: 2),
                          const Icon(Icons.warning_amber_rounded,
                              size: 14, color: Colors.amber),
                          Text('${w.damage}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.bold)),
                        ],
                        if (railOpen) ...[
                          const SizedBox(width: 2),
                          const Icon(Icons.door_front_door_outlined,
                              size: 14, color: Colors.deepOrange),
                        ],
                        if (preview != null) ...[
                          const SizedBox(width: 4),
                          _buildShotPreview(preview),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (crew != null)
                CircleAvatar(
                  radius: 12,
                  backgroundColor: _selectedCrewId == crew.id
                      ? colorScheme.primary
                      : colorScheme.secondary,
                  child: Text(
                    crew.name.isEmpty ? '?' : crew.name[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// What the armed weapon would do to this room if it lands: the shield
  /// that would stop it, or the hull and pips it would cost, KO when the
  /// room would go down, a flame when it would burn.
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
        Text('-${preview.hullDamage}', style: style),
        if (preview.roomDamage > 0) ...[
          const SizedBox(width: 3),
          const Icon(Icons.grid_view, size: 11, color: _previewColor),
          Text('-${preview.roomDamage}', style: style),
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
      ],
    );
  }

  Widget _buildEnemyWeapons(bool fr) {
    final theme = Theme.of(context);
    final lang = ref.watch(appLanguageProvider);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final w in _enemy.weapons)
          Chip(
            visualDensity: VisualDensity.compact,
            avatar: Icon(
              w.incendiary
                  ? Icons.local_fire_department
                  : w.piercing
                      ? Icons.bolt
                      : Icons.gps_fixed,
              size: 14,
              color: theme.colorScheme.error,
            ),
            label: Text(
              '${w.nameFor(fr)} ${w.damage} · ${w.charge}/${w.chargeTurns}'
              '${widget.foresight && readyNextTurn(w, _enemy) && _plan[w.id] != null ? ' · ${trFor(lang, 'ship_aim_prefix')} ${trFor(lang, 'ship_room_${_plan[w.id]!.name}_title')}' : ''}',
              style: theme.textTheme.labelSmall,
            ),
          ),
      ],
    );
  }

  Widget _buildPlayerWeapons(bool fr) {
    final theme = Theme.of(context);
    final lang = ref.watch(appLanguageProvider);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final w in _player.weapons)
          ChoiceChip(
            visualDensity: VisualDensity.compact,
            selected: _armedWeaponId == w.id,
            avatar: Icon(
              w.incendiary
                  ? Icons.local_fire_department
                  : w.piercing
                      ? Icons.bolt
                      : Icons.gps_fixed,
              size: 14,
            ),
            label: Text(
              '${w.nameFor(fr)} ${w.damage} · '
              '${w.isReady ? trFor(lang, 'ship_weapon_ready_label') : '${w.charge}/${w.chargeTurns}'}',
              style: theme.textTheme.labelSmall,
            ),
            onSelected: w.isReady && !_busy && !_over
                ? (_) => setState(() {
                      _armedWeaponId = _armedWeaponId == w.id ? null : w.id;
                      _selectedCrewId = null;
                    })
                : null,
          ),
      ],
    );
  }

  void _autoStation() {
    setState(() {
      _stations
        ..clear()
        ..addAll({
          for (final entry in autoStations(_player, _crew).entries)
            entry.key: entry.value.id,
        });
      _selectedCrewId = null;
    });
  }

  Widget _buildCrewBar() {
    final theme = Theme.of(context);
    final lang = ref.watch(appLanguageProvider);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        ActionChip(
          visualDensity: VisualDensity.compact,
          avatar: const Icon(Icons.auto_fix_high, size: 14),
          label: Text(trFor(lang, 'ship_auto_station_button'),
              style: theme.textTheme.labelSmall),
          onPressed: _busy || _over || _crew.isEmpty ? null : _autoStation,
        ),
        for (final c in _crew)
          ChoiceChip(
            visualDensity: VisualDensity.compact,
            selected: _selectedCrewId == c.id,
            avatar: CircleAvatar(
              radius: 10,
              backgroundColor: theme.colorScheme.secondary,
              child: Text(
                c.name.isEmpty ? '?' : c.name[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
            label: Text(
              '${c.name} ${c.health}/${c.maxHealth}'
              '${_stationOf(c.id) != null ? ' · ${trFor(lang, 'ship_room_${_stationOf(c.id)!.name}_title')}' : ''}',
              style: theme.textTheme.labelSmall,
            ),
            onSelected: _busy || _over
                ? null
                : (_) => setState(() {
                      _selectedCrewId = _selectedCrewId == c.id ? null : c.id;
                      _armedWeaponId = null;
                    }),
          ),
      ],
    );
  }

  Widget _buildLog(BuildContext context) {
    final theme = Theme.of(context);
    final lines = _log.length > 4 ? _log.sublist(_log.length - 4) : _log;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lines.isEmpty)
            Text('…', style: theme.textTheme.bodySmall)
          else
            for (final line in lines)
              Text(line,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// The color of damage that is coming but not dealt yet, the same blue
/// the dice fight uses for its preview.
const Color _previewColor = Color(0xFF42A5F5);

/// Boarders met by a hand in the hold come over the rail at this share
/// of their health.
const double holdMannedBoarderHealth = 0.75;

Color _roomColor(ShipRoom room) => switch (room) {
      ShipRoom.helm => Colors.blue,
      ShipRoom.guns => Colors.deepOrange,
      ShipRoom.bulwark => Colors.blueGrey,
      ShipRoom.hold => Colors.brown,
    };

IconData _roomIcon(ShipRoom room) => switch (room) {
      ShipRoom.helm => Icons.explore,
      ShipRoom.guns => Icons.gps_fixed,
      ShipRoom.bulwark => Icons.shield,
      ShipRoom.hold => Icons.inventory_2,
    };
