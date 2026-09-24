import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/ship_combat.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';

/// How a ship battle ended: who won, the Eel as she is now (hull, rooms),
/// and the crew with the hurts the fight cost them.
class ShipBattleOutcome {
  const ShipBattleOutcome({
    required this.won,
    required this.player,
    required this.crew,
    required this.log,
  });

  final bool won;
  final ShipState player;
  final List<ShipCrew> crew;
  final List<String> log;
}

/// The room-by-room ship battle (see ship_combat.dart), drawn as two
/// ships of four rooms each. The enemy sits at the top with its weapons
/// and their charge; the Eel at the bottom with hers, her crew at their
/// stations, and the enemy's aim marked on her rooms when a foresight
/// sail is aboard. A turn: crew work and weapons charge, the player fires
/// each ready weapon at a room of the enemy's ship (tap the weapon, then
/// the room) and moves the crew (tap a member, then a room), then ends
/// the turn; the enemy fires back, fires burn, and bulwarks come back.
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
  }

  void _finish({required bool won}) {
    if (_over) return;
    _over = true;
    setState(() => _busy = true);
    widget.onFinished(ShipBattleOutcome(
      won: won,
      player: _player,
      crew: _crew,
      log: List.of(_log),
    ));
  }

  // --- UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final fr = lang == AppLanguage.fr;
    final theme = Theme.of(context);
    final hintKey = _selectedCrewId != null
        ? 'ship_station_hint'
        : _armedWeaponId != null
            ? 'ship_fire_hint'
            : 'ship_station_hint';
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
        const SizedBox(height: 6),
        Text(
          '${trFor(lang, 'round_label')} $_turn · ${trFor(lang, hintKey)}',
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
        const SizedBox(height: 6),
        FilledButton.icon(
          onPressed: _busy || _over ? null : _endTurn,
          icon: const Icon(Icons.hourglass_bottom),
          label: Text(trFor(lang, 'ship_end_turn_button')),
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
    return Tooltip(
      message: trFor(lang, 'ship_room_${room.name}_hint'),
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

  Widget _buildCrewBar() {
    final theme = Theme.of(context);
    final lang = ref.watch(appLanguageProvider);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
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
