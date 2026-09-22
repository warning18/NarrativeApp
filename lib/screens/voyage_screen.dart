import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/ship_combat.dart';
import '../data/port_helpers.dart';
import '../data/sea_events.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';

enum _VoyagePhase { event, fight, arrived, failed }

/// One crossing of the Rusty Eel from port to port: a short chain of sea
/// events drawn once at cast-off (see [buildVoyage]) -- calm days that
/// mend the hull, storms that cost it, derelicts worth salvaging, and
/// raiders that open a turn-by-turn ship battle fought with the parts
/// aboard. Landfall pops `true` and moors the boat at the new port; a
/// sunk hull pops `false`, the Eel limping back to the port she left.
class VoyageScreen extends ConsumerStatefulWidget {
  const VoyageScreen({
    super.key,
    required this.fromPortId,
    required this.toPortId,
    required this.toPort,
  });

  final String fromPortId;
  final String toPortId;
  final Map<String, dynamic> toPort;

  @override
  ConsumerState<VoyageScreen> createState() => _VoyageScreenState();
}

class _VoyageScreenState extends ConsumerState<VoyageScreen> {
  final _random = Random();
  List<SeaEvent>? _events;
  int _index = 0;
  _VoyagePhase _phase = _VoyagePhase.event;
  ShipCombatant? _player;
  ShipCombatant? _enemy;
  Map<String, dynamic>? _enemyData;
  int _shipRegen = 0;
  final Map<String, int> _cooldowns = {};
  final List<String> _log = [];
  bool _busy = false;

  void _ensureStarted({
    required Map<String, dynamic> ships,
    required Map<String, dynamic> parts,
    required Map<String, dynamic> enemyShips,
    required Map<String, dynamic> ports,
  }) {
    if (_events != null) return;
    final session = ref.read(playerSessionProvider);
    final fromPort = ports[widget.fromPortId] as Map<String, dynamic>?;
    final chapter = max(
      fromPort == null ? 1 : portChapter(fromPort),
      portChapter(widget.toPort),
    );
    _events = buildVoyage(
      random: _random,
      length: portVoyageLength(widget.toPort),
      enemyShips: enemyShips,
      chapter: chapter,
    );
    final shipId = ships.containsKey('rusty_eel')
        ? 'rusty_eel'
        : (ships.keys.isEmpty ? '' : ships.keys.first);
    final ship = ships[shipId] as Map<String, dynamic>? ?? const {};
    _shipRegen = (ship['shieldRegenPerTurn'] as num?)?.toInt() ?? 0;
    _player = buildPlayerShip(
      ship: ship,
      parts: parts,
      installedPartIds: session.shipPartIds,
      currentHull: session.shipHull,
    );
  }

  String _t(String key, {String? ship, int? n}) {
    var text = trFor(ref.read(appLanguageProvider), key);
    if (ship != null) text = text.replaceAll('{ship}', ship);
    if (n != null) text = text.replaceAll('{n}', '$n');
    return text;
  }

  String _enemyName(bool fr) {
    final data = _enemyData ?? const {};
    final name =
        data['displayName']?.toString() ?? data['shipName']?.toString() ?? '';
    final nameFr = data['displayName_fr']?.toString() ?? '';
    return fr && nameFr.isNotEmpty ? nameFr : name;
  }

  Future<void> _resolveEvent(
    SeaEvent event, {
    required Map<String, dynamic> enemyShips,
  }) async {
    setState(() => _busy = true);
    final notifier = ref.read(playerSessionProvider.notifier);
    final player = _player!;
    switch (event.kind) {
      case SeaEventKind.storm:
        final hull = max(1, player.hull + event.hullDelta);
        _player = player.copyWith(hull: hull);
        _log.add(_t('ship_log_storm', n: player.hull - hull));
        await notifier.setShipHull(hull);
        await _advance();
      case SeaEventKind.calm:
        final hull = min(player.maxHull, player.hull + event.hullDelta);
        _player = player.copyWith(hull: hull);
        _log.add(_t('ship_log_calm', n: hull - player.hull));
        await notifier.setShipHull(hull);
        await _advance();
      case SeaEventKind.derelict:
        await notifier.applyChoiceEffects(goldMod: event.gold);
        _log.add(_t('ship_log_salvage', n: event.gold));
        await _advance();
      case SeaEventKind.sighting:
        await _advance();
      case SeaEventKind.raider:
        final data = enemyShips[event.enemyShipId] as Map<String, dynamic>?;
        if (data == null) {
          await _advance();
          return;
        }
        _enemyData = data;
        _enemy = buildEnemyShip(data);
        _cooldowns.clear();
        _log.clear();
        if (!mounted) return;
        setState(() {
          _phase = _VoyagePhase.fight;
          _busy = false;
        });
    }
  }

  Future<void> _advance() async {
    if (!mounted) return;
    if (_index + 1 >= _events!.length) {
      final notifier = ref.read(playerSessionProvider.notifier);
      await notifier.setShipHull(_player!.hull);
      await notifier.arriveAtPort(widget.toPortId);
      if (!mounted) return;
      setState(() {
        _phase = _VoyagePhase.arrived;
        _busy = false;
      });
      return;
    }
    setState(() {
      _index++;
      _phase = _VoyagePhase.event;
      _busy = false;
    });
  }

  Future<void> _act(ShipAction? action, {required bool fr}) async {
    setState(() => _busy = true);
    final notifier = ref.read(playerSessionProvider.notifier);
    final enemyName = _enemyName(fr);
    if (action != null) {
      final result = resolvePlayerShipAction(
          player: _player!, enemy: _enemy!, action: action);
      if (result.damageDealt > 0) {
        _log.add(
            _t('ship_log_you_strike', ship: enemyName, n: result.damageDealt));
      }
      if (result.shieldRestored > 0) {
        _log.add(_t('ship_log_brace', n: result.shieldRestored));
      }
      if (result.hullRepaired > 0) {
        _log.add(_t('ship_log_repair', n: result.hullRepaired));
      }
      _cooldowns[action.partId] =
          action.cooldownTurns > 0 ? action.cooldownTurns + 1 : 0;
      _player = result.player;
      _enemy = result.enemy;
      if (!_enemy!.isAfloat) {
        _log.add(_t('ship_log_sunk', ship: enemyName));
        final gold = (_enemyData?['goldReward'] as num?)?.toInt() ?? 0;
        final xp = (_enemyData?['xpReward'] as num?)?.toInt() ?? 0;
        final session = ref.read(playerSessionProvider);
        await notifier.applyCombatResult(
          hpAfter: session.currentHealth,
          goldGain: gold,
          xpGain: xp,
        );
        await notifier.setShipHull(_player!.hull);
        _log.add('${_t('ship_fight_won_prefix')}: +$gold ${_t('gold_label')}');
        await _advance();
        return;
      }
    }
    final result = resolveEnemyShipTurn(
      player: _player!,
      enemy: _enemy!,
      weaponDamage: (_enemyData?['weaponDamage'] as num?)?.toInt() ?? 0,
      playerShieldRegen: _shipRegen,
    );
    if (result.damageDealt > 0) {
      _log.add(
          _t('ship_log_enemy_strikes', ship: enemyName, n: result.damageDealt));
    }
    _player = result.player;
    _enemy = result.enemy;
    for (final id in _cooldowns.keys.toList()) {
      _cooldowns[id] = max(0, _cooldowns[id]! - 1);
    }
    if (!_player!.isAfloat) {
      await notifier.setShipHull(limpHomeHull(_player!.maxHull));
      if (!mounted) return;
      setState(() {
        _phase = _VoyagePhase.failed;
        _busy = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final fr = lang == AppLanguage.fr;
    final ships = ref.watch(gameDbProvider(shipsSchema)).value;
    final parts = ref.watch(gameDbProvider(shipPartsSchema)).value;
    final enemyShips = ref.watch(gameDbProvider(enemyShipsSchema)).value;
    final ports = ref.watch(gameDbProvider(portsSchema)).value;
    final title =
        '${trFor(lang, 'voyage_title')}: ${portNameFor(widget.toPort, fr)}';
    if (ships == null || parts == null || enemyShips == null || ports == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    _ensureStarted(
        ships: ships, parts: parts, enemyShips: enemyShips, ports: ports);

    return PopScope(
      canPop: _phase == _VoyagePhase.arrived || _phase == _VoyagePhase.failed,
      child: Scaffold(
        appBar: AppBar(title: Text(title), automaticallyImplyLeading: false),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: switch (_phase) {
              _VoyagePhase.event => _buildEvent(context,
                  fr: fr, enemyShips: enemyShips, parts: parts),
              _VoyagePhase.fight => _buildFight(context, fr: fr, parts: parts),
              _VoyagePhase.arrived => _buildSummary(
                  context,
                  icon: Icons.anchor,
                  title: trFor(lang, 'voyage_arrived_title'),
                  lines: [portNameFor(widget.toPort, fr)],
                  buttonLabel: trFor(lang, 'go_ashore_button'),
                  result: true,
                ),
              _VoyagePhase.failed => _buildSummary(
                  context,
                  icon: Icons.warning_amber_outlined,
                  title: trFor(lang, 'voyage_failed_title'),
                  lines: [trFor(lang, 'voyage_failed_message')],
                  buttonLabel: trFor(lang, 'back_to_port_button'),
                  result: false,
                ),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildShipBars(BuildContext context, ShipCombatant ship, String name) {
    final theme = Theme.of(context);
    final lang = ref.watch(appLanguageProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(name, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: ship.maxHull == 0 ? 0 : ship.hull / ship.maxHull,
          minHeight: 8,
        ),
        const SizedBox(height: 2),
        Text(
          '${trFor(lang, 'hull_label')} ${ship.hull} / ${ship.maxHull} · '
          '${trFor(lang, 'bulwark_label')} ${ship.shield} / ${ship.maxShield}',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildLog(BuildContext context) {
    if (_log.isEmpty) return const SizedBox.shrink();
    final lines = _log.length > 4 ? _log.sublist(_log.length - 4) : _log;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines)
              Text(line, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildEvent(
    BuildContext context, {
    required bool fr,
    required Map<String, dynamic> enemyShips,
    required Map<String, dynamic> parts,
  }) {
    final lang = ref.watch(appLanguageProvider);
    final event = _events![_index];
    final total = _events!.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(value: _index / total),
        const SizedBox(height: 8),
        Text(
          '${trFor(lang, 'voyage_day_label')} ${_index + 1} / $total',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 16),
        _buildShipBars(context, _player!, trFor(lang, 'boat_title')),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Text(
              event.descriptionFor(fr),
              style:
                  Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ),
        ),
        _buildLog(context),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed:
              _busy ? null : () => _resolveEvent(event, enemyShips: enemyShips),
          child: Text(event.choiceTextFor(fr)),
        ),
      ],
    );
  }

  Widget _buildFight(
    BuildContext context, {
    required bool fr,
    required Map<String, dynamic> parts,
  }) {
    final lang = ref.watch(appLanguageProvider);
    final session = ref.watch(playerSessionProvider);
    final actions = [
      for (final id in session.shipPartIds)
        if (parts[id] is Map<String, dynamic>)
          ShipAction.fromPart(id, parts[id] as Map<String, dynamic>),
    ].where((a) => a.isUsable).toList();
    final anyReady = actions.any((a) => (_cooldowns[a.partId] ?? 0) == 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(trFor(lang, 'ship_fight_title'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _buildShipBars(context, _player!, trFor(lang, 'boat_title')),
        const SizedBox(height: 12),
        _buildShipBars(context, _enemy!, _enemyName(fr)),
        const SizedBox(height: 12),
        Expanded(child: SingleChildScrollView(child: _buildLog(context))),
        const SizedBox(height: 8),
        for (final action in actions) ...[
          ElevatedButton(
            onPressed: _busy || (_cooldowns[action.partId] ?? 0) > 0
                ? null
                : () => _act(action, fr: fr),
            child: Text((_cooldowns[action.partId] ?? 0) > 0
                ? '${fr && action.labelFr.isNotEmpty ? action.labelFr : action.label} '
                    '(${trFor(lang, 'ready_in_prefix')} ${_cooldowns[action.partId]! - 1})'
                : (fr && action.labelFr.isNotEmpty
                    ? action.labelFr
                    : action.label)),
          ),
          const SizedBox(height: 8),
        ],
        if (!anyReady)
          OutlinedButton(
            onPressed: _busy ? null : () => _act(null, fr: fr),
            child: Text(trFor(lang, 'sail_on_button')),
          ),
      ],
    );
  }

  Widget _buildSummary(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<String> lines,
    required String buttonLabel,
    required bool result,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(line, textAlign: TextAlign.center),
          ),
        if (_log.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildLog(context),
        ],
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(result),
          child: Text(buttonLabel),
        ),
      ],
    );
  }
}
