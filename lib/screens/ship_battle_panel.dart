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

  String? _firstReadyWeaponId() {
    for (final w in _battle.player.weapons) {
      if (_battle.canFire(w)) return w.id;
    }
    return null;
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
      _battle.fireEnemy(weapon);
      if (!mounted) return;
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
                ship: _battle.enemy,
                evasion: _battle.enemyEvasion,
                color: theme.colorScheme.error,
                habit: widget.habit,
              ),
              const SizedBox(height: 6),
              _buildRoomGrid(ship: _battle.enemy, isPlayer: false),
              const SizedBox(height: 6),
              _buildEnemyWeapons(fr),
              const SizedBox(height: 8),
              _buildSea(lang),
              const SizedBox(height: 8),
              _buildLog(context),
              const SizedBox(height: 10),
              _buildShipHeader(
                name: widget.shipName,
                ship: _battle.player,
                evasion: _battle.playerEvasion,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 6),
              _buildRoomGrid(ship: _battle.player, isPlayer: true),
              const SizedBox(height: 6),
              _buildPlayerWeapons(fr),
              const SizedBox(height: 4),
              _buildAmmo(lang),
              const SizedBox(height: 6),
              _buildCrewBar(),
              const SizedBox(height: 4),
              _buildOrders(lang, enemies),
            ],
          ),
        ),
        if (widget.turnSeconds != null && !_over) ...[
          const SizedBox(height: 6),
          _buildClock(lang),
        ],
        const SizedBox(height: 6),
        if (_aimRoom != null)
          _buildAimBar(lang)
        else
          Text(
            '${trFor(lang, 'round_label')} ${_battle.turn} · $hint',
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
                onPressed: _busy || _over ? null : () => _endTurn(manual: true),
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
  /// the last five; still while the enemy fires. While half of it is
  /// left, ending the turn is quick orders.
  Widget _buildClock(AppLanguage lang) {
    final theme = Theme.of(context);
    final total = max(1, widget.turnSeconds ?? 1);
    final urgent = !_busy && _secondsLeft <= 5;
    final color = urgent ? theme.colorScheme.error : theme.colorScheme.primary;
    final quick = _quickNow;
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
        const SizedBox(width: 8),
        Tooltip(
          message: trFor(lang, 'ship_quick_orders_hint')
              .replaceAll('{n}', '$quickOrdersEvasion'),
          child: Row(
            key: const Key('ship_quick_orders'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt,
                  size: 15,
                  color: quick
                      ? Colors.amber.shade700
                      : theme.colorScheme.outline),
              Text(
                '+$quickOrdersEvasion%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color:
                      quick ? Colors.amber.shade800 : theme.colorScheme.outline,
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
  /// they lie at, and the helm's maneuvers.
  Widget _buildSea(AppLanguage lang) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelSmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    final rules = widget.rules;
    final range = _battle.range;
    final closer = range.index > 0 ? ShipRange.values[range.index - 1] : null;
    final farther = range.index < ShipRange.values.length - 1
        ? ShipRange.values[range.index + 1]
        : null;
    final canAct = !_busy && !_over;
    return Container(
      key: const Key('ship_sea_strip'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rules.weather)
            Tooltip(
              message: trFor(lang, 'ship_weather_${_battle.weather.name}_hint'),
              child: Row(
                children: [
                  Icon(_weatherIcon(_battle.weather),
                      size: 16, color: _weatherColor(_battle.weather)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      trFor(lang, 'ship_weather_${_battle.weather.name}'),
                      style: theme.textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${trFor(lang, 'ship_weather_next_label')} ',
                      style: muted),
                  Icon(_weatherIcon(_battle.nextWeather),
                      size: 14, color: theme.colorScheme.onSurfaceVariant),
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
                      child: const Icon(Icons.sailing_outlined,
                          size: 16, color: Colors.brown),
                    ),
                  ],
                ],
              ),
            ),
          if (rules.range) ...[
            if (rules.weather) const SizedBox(height: 4),
            Row(
              key: const Key('ship_range_bar'),
              children: [
                _maneuverButton(
                  key: const Key('ship_close_in'),
                  icon: Icons.keyboard_double_arrow_left,
                  label: trFor(lang, 'ship_close_in_button'),
                  onPressed:
                      canAct && closer != null && _battle.canMoveTo(closer)
                          ? () => setState(() => _battle.maneuver(closer))
                          : null,
                ),
                Expanded(
                  child: Tooltip(
                    message: trFor(lang, 'ship_range_${range.name}_hint'),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (final r in ShipRange.values)
                              Container(
                                width: 22,
                                height: 6,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  color: r == range
                                      ? Colors.blue
                                      : theme.colorScheme.outlineVariant,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trFor(lang, 'ship_range_${range.name}_title'),
                          key: const Key('ship_range_label'),
                          style: theme.textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
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
                          ? () => setState(() => _battle.maneuver(farther))
                          : null,
                  trailing: true,
                ),
              ],
            ),
          ],
        ],
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
    return TextButton(
      key: key,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 6),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: trailing ? [text, glyph] : [glyph, text],
      ),
    );
  }

  Widget _buildShipHeader({
    required String name,
    required ShipState ship,
    required int evasion,
    required Color color,
    EnemyHabit habit = EnemyHabit.none,
  }) {
    final theme = Theme.of(context);
    final lang = ref.watch(appLanguageProvider);
    final ratio = ship.maxHull == 0 ? 0.0 : ship.hull / ship.maxHull;
    final showHabit = widget.rules.habits && habit != EnemyHabit.none;
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
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
    final crew = isPlayer ? _battle.crewById(_battle.stations[room]) : null;
    final canFireHere = !isPlayer && _armedWeaponId != null && !_busy && !_over;
    final canStationHere = isPlayer && _selectedCrewId != null && !_busy;
    final aiming = !isPlayer && _aimRoom == room;
    final highlighted = canFireHere || canStationHere || aiming;
    final incoming = <ShipWeapon>[
      if (isPlayer && widget.foresight && _battle.aimVisible)
        for (final w in _battle.enemy.weapons)
          if (readyNextTurn(w, _battle.enemy) && _battle.plan[w.id] == room) w,
    ];
    final preview = canFireHere ? _battle.preview(_armedWeaponId, room) : null;
    final focused = !isPlayer && (_battle.focus[room] ?? 0) > 0;
    final leaks = room == ShipRoom.hold ? ship.leaks : 0;
    final railOpen = room == ShipRoom.bulwark && bulwarkOpen(ship);
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
        onLongPress: canFireHere ? () => _startAim(room) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: state.isDown
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: aiming
                  ? Colors.amber.shade700
                  : highlighted
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            trFor(lang, 'ship_room_${room.name}_title'),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: state.isDown ? colorScheme.outline : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (focused) ...[
                          const SizedBox(width: 3),
                          Tooltip(
                            message: trFor(lang, 'ship_focus_hint'),
                            child: const Icon(Icons.center_focus_strong,
                                size: 13, color: Colors.deepOrange),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Row(
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
                          for (var i = 0; i < leaks; i++)
                            const Icon(Icons.water_drop,
                                key: Key('ship_leak'),
                                size: 13,
                                color: Colors.lightBlue),
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
        if (preview.leakOpened) ...[
          const SizedBox(width: 2),
          const Icon(Icons.water_drop, size: 13, color: _previewColor),
        ],
      ],
    );
  }

  Widget _buildEnemyWeapons(bool fr) {
    final theme = Theme.of(context);
    final lang = ref.watch(appLanguageProvider);
    final enemy = _battle.enemy;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final w in enemy.weapons)
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
              '${_battle.inRange(w) ? '' : ' · ${trFor(lang, 'ship_out_of_range_label')}'}'
              '${widget.foresight && _battle.aimVisible && readyNextTurn(w, enemy) && _battle.plan[w.id] != null ? ' · ${trFor(lang, 'ship_aim_prefix')} ${trFor(lang, 'ship_room_${_battle.plan[w.id]!.name}_title')}' : ''}',
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
        for (final w in _battle.player.weapons)
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
              '${!_battle.inRange(w) ? trFor(lang, 'ship_out_of_range_label') : w.isReady ? trFor(lang, 'ship_weapon_ready_label') : '${w.charge}/${w.chargeTurns}'}',
              style: theme.textTheme.labelSmall,
            ),
            onSelected: _battle.canFire(w) && !_busy && !_over
                ? (_) => setState(() {
                      _armedWeaponId = _armedWeaponId == w.id ? null : w.id;
                      _selectedCrewId = null;
                      _cancelAim();
                    })
                : null,
          ),
      ],
    );
  }

  /// The shot the guns are loaded with, kept until changed.
  Widget _buildAmmo(AppLanguage lang) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(trFor(lang, 'ship_ammo_label'),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        for (final ammo in ShipAmmo.values)
          Tooltip(
            message: trFor(lang, 'ship_ammo_${ammo.name}_hint'),
            child: ChoiceChip(
              key: Key('ship_ammo_${ammo.name}'),
              visualDensity: VisualDensity.compact,
              selected: _battle.ammo == ammo,
              avatar: Icon(_ammoIcon(ammo), size: 14),
              label: Text(trFor(lang, 'ship_ammo_${ammo.name}'),
                  style: theme.textTheme.labelSmall),
              onSelected: _busy || _over
                  ? null
                  : (_) => setState(() => _battle.ammo = ammo),
            ),
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
        ActionChip(
          visualDensity: VisualDensity.compact,
          avatar: const Icon(Icons.auto_fix_high, size: 14),
          label: Text(trFor(lang, 'ship_auto_station_button'),
              style: theme.textTheme.labelSmall),
          onPressed: _busy || _over || _battle.crew.isEmpty
              ? null
              : () => setState(() {
                    _battle.autoStation();
                    _selectedCrewId = null;
                  }),
        ),
        for (final c in _battle.crew)
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
              '${_battle.stationOf(c.id) != null ? ' · ${trFor(lang, 'ship_room_${_battle.stationOf(c.id)!.name}_title')}' : ''}',
              style: theme.textTheme.labelSmall,
            ),
            onSelected: _busy || _over
                ? null
                : (_) => setState(() {
                      _selectedCrewId = _selectedCrewId == c.id ? null : c.id;
                      _armedWeaponId = null;
                      _cancelAim();
                    }),
          ),
      ],
    );
  }

  /// Each crew member's order, once a battle: greyed when spent or when it
  /// would do nothing now.
  Widget _buildOrders(AppLanguage lang, Map<String, dynamic>? enemies) {
    final theme = Theme.of(context);
    final members = [
      for (final c in _battle.crew)
        if (orderFor(c) != null) c,
    ];
    if (members.isEmpty) return const SizedBox.shrink();
    return Wrap(
      key: const Key('ship_orders'),
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(trFor(lang, 'ship_orders_label'),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        for (final c in members)
          _buildOrderChip(lang, c, orderFor(c)!, enemies),
      ],
    );
  }

  Widget _buildOrderChip(AppLanguage lang, ShipCrew member, CrewOrder order,
      Map<String, dynamic>? enemies) {
    final theme = Theme.of(context);
    final spent = _battle.ordersUsed.contains(member.id);
    // A grapple needs a crew to fight at the rail.
    final usable = !_busy &&
        !_over &&
        _battle.canOrder(member) &&
        (order != CrewOrder.grapple || _boardingCrew(enemies) != null);
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
            ? () => setState(() {
                  _battle.giveOrder(member);
                  _armedWeaponId ??= _firstReadyWeaponId();
                })
            : null,
      ),
    );
  }

  Widget _buildLog(BuildContext context) {
    final theme = Theme.of(context);
    final log = _battle.log;
    final lines = log.length > 4 ? log.sublist(log.length - 4) : log;
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
              Text(_line(line),
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// The aim bar: red edges where the shot goes wide, amber for a plain
/// shot, green in the middle for a critical, and the sweeping marker.
class _AimBarPainter extends CustomPainter {
  const _AimBarPainter({required this.position, required this.marker});

  final double position;
  final Color marker;

  @override
  void paint(Canvas canvas, Size size) {
    final bar = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, size.height * 0.25, size.width, size.height * 0.5),
        const Radius.circular(4));
    canvas.save();
    canvas.clipRRect(bar);
    void band(double from, double to, Color color) => canvas.drawRect(
        Rect.fromLTRB(from * size.width, 0, to * size.width, size.height),
        Paint()..color = color);
    band(0, 1, Colors.red.withValues(alpha: 0.55));
    band(0.5 - aimSteadyHalfWidth, 0.5 + aimSteadyHalfWidth,
        Colors.amber.withValues(alpha: 0.75));
    band(0.5 - aimPerfectHalfWidth, 0.5 + aimPerfectHalfWidth,
        Colors.green.withValues(alpha: 0.85));
    canvas.restore();
    final x = position.clamp(0.0, 1.0) * size.width;
    canvas.drawRect(
        Rect.fromLTWH(x - 2, 0, 4, size.height), Paint()..color = marker);
  }

  @override
  bool shouldRepaint(_AimBarPainter old) =>
      old.position != position || old.marker != marker;
}

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
        .replaceAllMapped(RegExp(r"\bde L['’]"), (_) => 'de l’')
        .replaceAllMapped(
            RegExp(r'\bde ([AEIOUÉÈÊ])'), (m) => 'd’${m.group(1)}')
        // "sous Le Rusty Eel": the name's article, mid-sentence.
        .replaceAllMapped(RegExp(r'([a-zà-ÿ]) (Le|La|Les) '),
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

IconData _weatherIcon(SeaWeather weather) => switch (weather) {
      SeaWeather.calm => Icons.wb_sunny_outlined,
      SeaWeather.tailwind => Icons.air,
      SeaWeather.crosswind => Icons.cyclone,
      SeaWeather.squall => Icons.thunderstorm_outlined,
      SeaWeather.fog => Icons.foggy,
    };

Color _weatherColor(SeaWeather weather) => switch (weather) {
      SeaWeather.calm => Colors.amber.shade700,
      SeaWeather.tailwind => Colors.teal,
      SeaWeather.crosswind => Colors.indigo,
      SeaWeather.squall => Colors.blueGrey,
      SeaWeather.fog => Colors.grey,
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
