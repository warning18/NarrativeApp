import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_engine.dart';
import '../combat/ship_combat.dart';
import '../data/port_helpers.dart';
import '../data/sea_events.dart';
import '../data/sail_powers.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/ally_state.dart';
import '../providers/game_config_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import 'ship_battle_panel.dart';

enum _VoyagePhase { event, fight, arrived, failed }

/// One crossing of the Rusty Eel from port to port: a short chain of sea
/// events drawn once at cast-off (see [buildVoyage]) -- calm days that
/// mend the hull, storms that cost it, derelicts worth salvaging, and
/// raiders that open a room-by-room ship battle (see [ShipBattlePanel])
/// fought with the parts aboard and the party as crew. Landfall pops
/// `true` and moors the boat at the new port; a sunk hull pops `false`,
/// the Eel limping back to the port she left.
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

  /// The painted sail aboard, if any, and how strongly its sigil holds
  /// (see sail_powers.dart); a foresight sail shows the enemy's aim in a
  /// raider fight.
  ({String partId, SailPower power, String medium})? _sail;
  int _sailStrength = 1;
  int _index = 0;
  _VoyagePhase _phase = _VoyagePhase.event;
  ShipState? _player;
  ShipState? _enemy;
  Map<String, dynamic>? _enemyData;

  /// Bumped per raider so each battle gets a fresh panel.
  int _battleKey = 0;

  /// The chapter this crossing is scaled to (the higher of its two
  /// ports'), the Eel's record and the parts catalogue, kept for the
  /// boarding fight and its prize.
  int _chapter = 1;
  Map<String, dynamic> _shipRecord = const {};
  Map<String, dynamic> _parts = const {};
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
    _chapter = chapter;
    _parts = parts;
    _sail = installedSail(parts, session.shipPartIds);
    _sailStrength =
        _sail == null ? 1 : sailStrength(_sail!.medium, session.raceId);
    // The way home is as long as the way out: a voyage to the cove takes
    // the days of the port it leaves.
    var length = portVoyageLength(portIsHome(widget.toPort) && fromPort != null
        ? fromPort
        : widget.toPort);
    if (_sail?.power == SailPower.windknot) {
      final shorter = windknotLength(length, _sailStrength);
      if (shorter < length) {
        _log.add(_t('ship_log_windknot', n: length - shorter));
      }
      length = shorter;
    }
    _events = buildVoyage(
      random: _random,
      length: length,
      enemyShips: enemyShips,
      chapter: chapter,
      // A port she has put in at before, or the way home, is known water.
      knownWaters: portIsHome(widget.toPort) ||
          session.visitedPortIds.contains(widget.toPortId),
    );
    if (_sail?.power == SailPower.flight) {
      final lifted = applyFlight(_events!);
      final skipped = _events!.length - lifted.length;
      if (skipped > 0) _log.add(_t('ship_log_lift', n: skipped));
      _events = lifted;
    }
    final shipId = ships.containsKey('rusty_eel')
        ? 'rusty_eel'
        : (ships.keys.isEmpty ? '' : ships.keys.first);
    final ship = ships[shipId] as Map<String, dynamic>? ?? const {};
    _shipRecord = ship;
    _player = buildPlayerShip(
      ship: ship,
      parts: parts,
      installedPartIds: session.shipPartIds,
      currentHull: session.shipHull,
      voidVolleyPartId:
          _sail?.power == SailPower.voidmark ? _sail!.partId : null,
      voidVolleyBonus: voidVolleyBonus(_sailStrength),
    );
  }

  String _t(String key, {String? ship, int? n}) {
    var text = trFor(ref.read(appLanguageProvider), key);
    if (ship != null) text = text.replaceAll('{ship}', ship);
    if (n != null) text = text.replaceAll('{n}', '$n');
    return text;
  }

  /// The raider's name and description, under the sighting's text.
  List<Widget> _raiderIntro(Map<String, dynamic> ship, bool fr) {
    final name =
        ship['displayName']?.toString() ?? ship['shipName']?.toString() ?? '';
    final nameFr = ship['displayName_fr']?.toString() ?? '';
    final description = ship['description']?.toString() ?? '';
    final descriptionFr = ship['description_fr']?.toString() ?? '';
    final shownName = fr && nameFr.isNotEmpty ? nameFr : name;
    final shownDescription =
        fr && descriptionFr.isNotEmpty ? descriptionFr : description;
    if (shownName.isEmpty && shownDescription.isEmpty) return const [];
    final theme = Theme.of(context);
    return [
      const SizedBox(height: 12),
      if (shownName.isNotEmpty)
        Text(shownName,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
      if (shownDescription.isNotEmpty)
        Text(
          shownDescription,
          style:
              theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
        ),
    ];
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
        var loss = -event.hullDelta;
        if (_sail?.power == SailPower.voidmark) {
          loss = voidmarkStormLoss(loss, _sailStrength);
          _log.add(_t('ship_log_void_calm'));
        }
        final hull = max(1, player.hull - loss);
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
        final gold = _sail?.power == SailPower.windknot
            ? windknotSalvage(event.gold, _sailStrength)
            : event.gold;
        await notifier.applyChoiceEffects(goldMod: gold);
        _log.add(_t('ship_log_salvage', n: gold));
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
        _log.clear();
        _battleKey++;
        if (!mounted) return;
        setState(() {
          _phase = _VoyagePhase.fight;
          _busy = false;
        });
    }
  }

  Future<void> _advance() async {
    if (!mounted) return;
    if (_sail?.power == SailPower.hearth) {
      // Every day at sea under the hearth-mark heals the crew and mends
      // the hull a little.
      final notifier = ref.read(playerSessionProvider.notifier);
      final session = ref.read(playerSessionProvider);
      final heal =
          max(1, session.maxHealth * hearthHealPercent(_sailStrength) ~/ 100);
      await notifier.applyChoiceEffects(healAmount: heal);
      final hull = min(
          _player!.maxHull, _player!.hull + hearthHullRepair(_sailStrength));
      _player = _player!.copyWith(hull: hull);
      await notifier.setShipHull(hull);
      _log.add(_t('ship_log_hearth', n: heal));
    }
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

  /// The party as the Eel's crew (see [buildShipCrew]).
  List<ShipCrew> _buildCrew({
    required PlayerSession session,
    required Map<String, dynamic> companions,
    required Map<String, dynamic> races,
    required Map<String, dynamic> professions,
    required Map<String, dynamic> gameConfig,
  }) =>
      buildShipCrew(
        session: session,
        companions: companions,
        races: races,
        professions: professions,
        gameConfig: gameConfig,
        youLabel: trFor(ref.read(appLanguageProvider), 'you_label'),
      );

  Future<void> _onBattleFinished(ShipBattleOutcome outcome) async {
    final notifier = ref.read(playerSessionProvider.notifier);
    final enemyName =
        _enemyName(ref.read(appLanguageProvider) == AppLanguage.fr);
    _player = outcome.player;
    _log
      ..clear()
      ..addAll(outcome.log.length > 3
          ? outcome.log.sublist(outcome.log.length - 3)
          : outcome.log);
    var gold =
        outcome.won ? (_enemyData?['goldReward'] as num?)?.toInt() ?? 0 : 0;
    final xp =
        outcome.won ? (_enemyData?['xpReward'] as num?)?.toInt() ?? 0 : 0;
    // A ship taken by boarding gives up her hold: gold, and a part when
    // there is room aboard for it (its worth in gold otherwise).
    String? prizeLine;
    if (outcome.boarded) {
      final prize = boardingProfileFor(_enemyData ?? const {});
      gold += prize.prizeGold;
      final partId = prize.prizePartId;
      final part =
          partId == null ? null : _parts[partId] as Map<String, dynamic>?;
      if (part != null) {
        final session = ref.read(playerSessionProvider);
        final fits = canInstallPart(
            ship: _shipRecord,
            parts: _parts,
            installedPartIds: session.shipPartIds,
            partId: partId!);
        if (fits && await notifier.installShipPart(partId, 0)) {
          final fr = ref.read(appLanguageProvider) == AppLanguage.fr;
          final name = fr && (part['partName_fr']?.toString() ?? '').isNotEmpty
              ? part['partName_fr'].toString()
              : part['partName']?.toString() ?? partId;
          prizeLine = _t('ship_log_prize_part').replaceAll('{weapon}', name);
        } else {
          final worth = ((part['cost'] as num?)?.toInt() ?? 0) ~/ 2;
          gold += worth;
          prizeLine = _t('ship_log_prize_gold', n: prize.prizeGold + worth);
        }
      } else if (prize.prizeGold > 0) {
        prizeLine = _t('ship_log_prize_gold', n: prize.prizeGold);
      }
    }
    // The crew's hurts persist, win or lose; a win also pays.
    for (final member in outcome.crew) {
      if (member.isPlayer) {
        await notifier.applyCombatResult(
            hpAfter: member.health, goldGain: gold, xpGain: xp);
      } else {
        await notifier.applyAllyCombatResult(member.id, hpAfter: member.health);
      }
    }
    if (!mounted) return;
    if (outcome.won) {
      if (!outcome.boarded) _log.add(_t('ship_log_sunk', ship: enemyName));
      if (prizeLine != null) _log.add(prizeLine);
      _log.add('${_t('ship_fight_won_prefix')}: +$gold ${_t('gold_label')}');
      await notifier.setShipHull(_player!.hull);
      await _advance();
      return;
    }
    await notifier.setShipHull(limpHomeHull(_player!.maxHull));
    if (!mounted) return;
    setState(() {
      _phase = _VoyagePhase.failed;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);
    final fr = lang == AppLanguage.fr;
    final ships = ref.watch(localizedDbProvider(shipsSchema)).value;
    final parts = ref.watch(localizedDbProvider(shipPartsSchema)).value;
    final enemyShips = ref.watch(localizedDbProvider(enemyShipsSchema)).value;
    final ports = ref.watch(localizedDbProvider(portsSchema)).value;
    final companions = ref.watch(localizedDbProvider(companionsSchema)).value;
    final races = ref.watch(localizedDbProvider(racesSchema)).value;
    final professions = ref.watch(localizedDbProvider(professionsSchema)).value;
    final gameConfig = ref.watch(gameConfigProvider).value;
    final title =
        '${trFor(lang, 'voyage_title')}: ${portNameFor(widget.toPort, fr)}';
    if (ships == null ||
        parts == null ||
        enemyShips == null ||
        ports == null ||
        companions == null ||
        races == null ||
        professions == null ||
        gameConfig == null) {
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
              _VoyagePhase.fight => _buildFight(
                  fr: fr,
                  companions: companions,
                  races: races,
                  professions: professions,
                  gameConfig: gameConfig,
                ),
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

  Widget _buildShipBars(BuildContext context, ShipState ship, String name) {
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
          '${trFor(lang, 'ship_layers_label')} ${ship.layers} / ${ship.maxLayers}',
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

  /// Foresight: the kinds of the next day or two, in words.
  String _foresightPreview(AppLanguage lang) {
    final ahead = <String>[];
    for (var i = 1; i <= foresightDays(_sailStrength); i++) {
      if (_index + i >= _events!.length) break;
      ahead.add(trFor(lang, 'sea_event_${_events![_index + i].kind.name}'));
    }
    return ahead.isEmpty
        ? trFor(lang, 'voyage_arrived_title')
        : ahead.join(', ');
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  event.descriptionFor(fr),
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(height: 1.5),
                ),
                // A raider is named and described before the guns come
                // out: who she is and what she wants from the Eel.
                if (event.kind == SeaEventKind.raider &&
                    enemyShips[event.enemyShipId] is Map<String, dynamic>)
                  ..._raiderIntro(
                      enemyShips[event.enemyShipId] as Map<String, dynamic>,
                      fr),
                if (_sail?.power == SailPower.foresight) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${trFor(lang, 'ship_log_foresight_prefix')}: '
                    '${_foresightPreview(lang)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
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

  Widget _buildFight({
    required bool fr,
    required Map<String, dynamic> companions,
    required Map<String, dynamic> races,
    required Map<String, dynamic> professions,
    required Map<String, dynamic> gameConfig,
  }) {
    final lang = ref.watch(appLanguageProvider);
    final session = ref.read(playerSessionProvider);
    return ShipBattlePanel(
      key: ValueKey('ship_battle_$_battleKey'),
      player: _player!,
      enemy: _enemy!,
      shipName: trFor(lang, 'boat_title'),
      enemyName: _enemyName(fr),
      crew: _buildCrew(
        session: session,
        companions: companions,
        races: races,
        professions: professions,
        gameConfig: gameConfig,
      ),
      foresight: _sail?.power == SailPower.foresight,
      random: _random,
      onFinished: _onBattleFinished,
      boarding: boardingProfileFor(_enemyData ?? const {}),
      chapter: boardingChapterFor(_chapter, _enemyData ?? const {}),
      buildCrew: () => _buildCrew(
        session: ref.read(playerSessionProvider),
        companions: companions,
        races: races,
        professions: professions,
        gameConfig: gameConfig,
      ),
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

/// The party as the Eel's crew: the player and every active companion,
/// with the stats the stations read and their current health. [youLabel]
/// names the player when the character has no name.
List<ShipCrew> buildShipCrew({
  required PlayerSession session,
  required Map<String, dynamic> companions,
  required Map<String, dynamic> races,
  required Map<String, dynamic> professions,
  required Map<String, dynamic> gameConfig,
  required String youLabel,
}) {
  final crew = <ShipCrew>[
    ShipCrew(
      id: 'player',
      name: session.characterName.isNotEmpty ? session.characterName : youLabel,
      strength: session.strength,
      dexterity: session.dexterity,
      constitution: session.constitution,
      wisdom: session.wisdom,
      health:
          session.currentHealth > 0 ? session.currentHealth : session.maxHealth,
      maxHealth: session.maxHealth,
      isPlayer: true,
    ),
  ];
  for (final companionId in session.activeAllyIds) {
    final companion = companions[companionId] as Map<String, dynamic>?;
    if (companion == null) continue;
    final allyState = session.recruitedAllies.firstWhere(
      (a) => a.companionId == companionId,
      orElse: () => AllyState(
          companionId: companionId,
          currentHealth: AllyState.fullHealthSentinel),
    );
    final race =
        races[companion['raceId']?.toString() ?? ''] as Map<String, dynamic>? ??
            const {};
    final profession = professions[companion['professionId']?.toString() ?? '']
            as Map<String, dynamic>? ??
        const {};
    final base = deriveAllyBaseStats(
        gameConfig: gameConfig, race: race, profession: profession);
    final maxHealth = scaledMaxHealth(base.maxHealth, session.level);
    crew.add(ShipCrew(
      id: companionId,
      name: companion['companionName']?.toString() ?? companionId,
      strength: base.strength,
      dexterity: base.dexterity,
      constitution: base.constitution,
      wisdom: base.wisdom,
      health: allyState.currentHealth.clamp(1, maxHealth),
      maxHealth: maxHealth,
    ));
  }
  return crew;
}
