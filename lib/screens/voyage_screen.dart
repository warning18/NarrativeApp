import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_engine.dart';
import '../combat/sea_beasts.dart';
import '../combat/ship_battle.dart';
import '../combat/ship_combat.dart';
import '../data/contracts.dart';
import '../data/port_helpers.dart';
import '../data/ability_check.dart';
import '../data/companion_remarks.dart';
import '../data/sea_events.dart';
import '../data/sail_powers.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/ally_state.dart';
import '../providers/chapter_loop_provider.dart'
    show chapterConditionProvider, reachedChapterProvider;
import '../providers/combat_settings_provider.dart';
import '../providers/game_config_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/player_session_provider.dart';
import '../providers/remark_provider.dart';
import '../theme/stitched_ink.dart';
import '../tutorial/guide_tour.dart';
import '../tutorial/tutorial_topics.dart';
import '../widgets/approval_notice.dart' show speakUpAbout;
import '../widgets/companion_remark_bubble.dart';
import '../widgets/moments.dart';
import '../widgets/sea_battlefield.dart';
import '../widgets/ship_widgets.dart' show HullBar, ShipAtSea;
import 'ship_battle_panel.dart';

enum _VoyagePhase { event, fight, arrived, failed }

/// One crossing of the Rusty Eel from port to port: a short chain of sea
/// events drawn once at cast-off (see [buildVoyage]), each asking what the
/// crew does (see [seaChoicesFor]) -- calm days to mend the hull or rest,
/// storms to ride out, push through or shelter from, derelicts to salvage
/// or board, and raiders to pay off, outrun or fight in a room-by-room
/// ship battle (see [ShipBattlePanel]) with the parts aboard and the party
/// as crew. Landfall pops
/// `true` and moors the boat at the new port; a sunk hull pops `false`,
/// the Eel limping back to the port she left.
///
/// A sea beast (v1.185, see sea_beasts.dart) may cross the Eel's path in
/// its own waters, its omen the day before: fight it, run, or keep still
/// and let it pass. With [huntBeastId] the crossing is a hunt the Harbor
/// sent out: a day at sea, then the beast, on the crew's terms.
class VoyageScreen extends ConsumerStatefulWidget {
  const VoyageScreen({
    super.key,
    required this.fromPortId,
    required this.toPortId,
    required this.toPort,
    this.huntBeastId,
    @visibleForTesting this.debugEvents,
  });

  final String fromPortId;
  final String toPortId;
  final Map<String, dynamic> toPort;

  /// The beast this voyage hunts (enemy_ships.json id), or null for a
  /// crossing.
  final String? huntBeastId;

  /// The days at sea to sail instead of drawing them, for tests.
  final List<SeaEvent>? debugEvents;

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

  /// The enemy's enemy_ships.json id (its record's key, the same in
  /// every language), which picks its look on the sea.
  String? _enemyId;

  /// Bumped per raider so each battle gets a fresh panel.
  int _battleKey = 0;

  /// The chapter this crossing is scaled to (the higher of its two
  /// ports'), the Eel's record and the parts catalogue, kept for the
  /// boarding fight and its prize.
  int _chapter = 1;

  /// The chapter's weather (see chapter_conditions.dart).
  double _stormShift = 0;

  /// The waters a fight is on: the port she sails to, or on a hunt a port
  /// of the beast's own waters.
  SeaWaters _waters = SeaWaters.open;
  Map<String, dynamic> _shipRecord = const {};
  Map<String, dynamic> _parts = const {};
  final List<String> _log = [];
  bool _busy = false;

  /// What each day behind her did to the hull and the purse, for the
  /// route strip; and where the day in hand started.
  final List<({int hull, int gold})> _dayResults = [];
  int _dayStartHull = 0;
  int _dayStartGold = 0;

  /// Kept from cast-off to draw the extra day a sheltered storm costs.
  bool _knownWaters = false;
  Map<String, dynamic> _enemyShips = const {};

  /// The beast being fought, and what it does beyond its weapons (null in
  /// a raider fight).
  String? _beastId;
  BeastProfile? _beast;

  void _ensureStarted({
    required Map<String, dynamic> ships,
    required Map<String, dynamic> parts,
    required Map<String, dynamic> enemyShips,
    required Map<String, dynamic> ports,
  }) {
    if (_events != null) return;
    final session = ref.read(playerSessionProvider);
    final fromPort = ports[widget.fromPortId] as Map<String, dynamic>?;
    final huntId = widget.huntBeastId;
    final huntRecord =
        huntId == null ? null : enemyShips[huntId] as Map<String, dynamic>?;
    // A hunt goes out to the beast's own waters.
    final chapter = huntRecord != null
        ? beastWaters(huntRecord).first
        : max(
            fromPort == null ? 1 : portChapter(fromPort),
            portChapter(widget.toPort),
          );
    _chapter = chapter;
    _waters = seaWatersFor(
        name: widget.toPort['waters']?.toString(), portId: widget.toPortId);
    if (huntRecord != null) {
      for (final entry in ports.entries) {
        final port = entry.value as Map<String, dynamic>;
        if (portChapter(port) != chapter) continue;
        _waters =
            seaWatersFor(name: port['waters']?.toString(), portId: entry.key);
        break;
      }
    }
    _stormShift = ref.read(chapterConditionProvider)?.stormShift ?? 0;
    _parts = parts;
    _sail = installedSail(parts, session.shipPartIds);
    _sailStrength =
        _sail == null ? 1 : sailStrength(_sail!.medium, session.raceId);
    // The way home is as long as the way out: a voyage to the cove takes
    // the days of the port it leaves.
    var length = portVoyageLength(portIsHome(widget.toPort) && fromPort != null
        ? fromPort
        : widget.toPort);
    if (_sail?.power == SailPower.windknot && huntRecord == null) {
      final shorter = windknotLength(length, _sailStrength);
      if (shorter < length) {
        _log.add(_t('ship_log_windknot', n: length - shorter));
      }
      length = shorter;
    }
    // A port she has put in at before, or the way home, is known water.
    _knownWaters = portIsHome(widget.toPort) ||
        session.visitedPortIds.contains(widget.toPortId);
    _enemyShips = enemyShips;
    _events = widget.debugEvents ??
        [
          ...buildVoyage(
            random: _random,
            // A hunt is a day out, then the beast.
            length: huntRecord != null ? 1 : length,
            enemyShips: enemyShips,
            chapter: chapter,
            knownWaters: _knownWaters,
            stormShift: _stormShift,
          ),
          if (huntRecord != null) beastDayFor(huntId!, huntRecord, hunt: true),
        ];
    if (_sail?.power == SailPower.flight) {
      final lifted = applyFlight(_events!);
      final skipped = _events!.length - lifted.length;
      if (skipped > 0) _log.add(_t('ship_log_lift', n: skipped));
      _events = lifted;
    }
    // A beast that roams these waters may cross the Eel's path (no sail
    // lifts her over one).
    if (widget.debugEvents == null && huntRecord == null) {
      final beastId = rollBeastEncounter(
        random: _random,
        enemyShips: enemyShips,
        chapter: chapter,
        beasts: session.seaBeasts,
      );
      if (beastId != null) {
        _events = withBeastDay(
            _events!,
            beastDayIndex(_random, _events!.length),
            beastId,
            enemyShips[beastId] as Map<String, dynamic>);
      }
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
    _dayStartHull = _player!.hull;
    _dayStartGold = session.gold;
  }

  String _t(String key, {String? ship, int? n}) {
    final lang = ref.read(appLanguageProvider);
    var text = trFor(lang, key);
    if (ship != null) {
      // A name with its own article ("The Pale Leviathan", "La
      // Mère-des-Marées") made to read right mid-sentence.
      text = tidyShipLine(text.replaceAll('{ship}', ship), lang);
    }
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

  /// True for a day that brings an enemy: a raider or a beast.
  bool _meetsShip(SeaEvent event) =>
      event.kind == SeaEventKind.raider ||
      event.kind == SeaEventKind.beast ||
      event.kind == SeaEventKind.hunt;

  /// What the crew knows of the beast [beastId]: the wounds it still
  /// carries and the edge they have on it.
  List<Widget> _beastIntro(String beastId) {
    final state = ref.read(playerSessionProvider).seaBeasts[beastId];
    if (state == null || state.encounters == 0) return const [];
    final lang = ref.read(appLanguageProvider);
    final record = _enemyShips[beastId] as Map<String, dynamic>? ?? const {};
    final maxHull = max(1, (record['maxHull'] as num?)?.toInt() ?? 1);
    final wounds = maxHull - beastStartHull(maxHull, state);
    return [
      const SizedBox(height: 8),
      Text(
        [
          if (wounds > 0)
            trFor(lang, 'beast_wounds_line').replaceAll('{n}', '$wounds'),
          trFor(lang, 'beast_known_line').replaceAll('{n}',
              '${beastEdge(state, hunt: _events![_index].kind == SeaEventKind.hunt)}'),
        ].join(' '),
        key: const Key('beast_known'),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ];
  }

  /// Tomorrow's beast, felt today.
  List<Widget> _omen(Map<String, dynamic> record) {
    final text = beastSpecOf(record)['omen']?.toString() ?? '';
    if (text.isEmpty) return const [];
    final theme = Theme.of(context);
    return [
      const SizedBox(height: 12),
      Row(
        key: const Key('beast_omen'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_outlined,
              size: 18, color: theme.colorScheme.tertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.tertiary)),
          ),
        ],
      ),
    ];
  }

  String _beastName(String beastId, bool fr) {
    final data = _enemyShips[beastId] as Map<String, dynamic>? ?? const {};
    final name = data['displayName']?.toString() ?? beastId;
    final nameFr = data['displayName_fr']?.toString() ?? '';
    return fr && nameFr.isNotEmpty ? nameFr : name;
  }

  /// A sign of [beastId] found: the crew is one step nearer its lair. The
  /// log says so, and how many signs the Harbor has now.
  Future<void> _gainClue(String beastId, String logKey) async {
    await ref.read(playerSessionProvider.notifier).updateSeaBeast(
        beastId, (b) => b.copyWith(seen: true, clues: b.clues + 1));
    final fr = ref.read(appLanguageProvider) == AppLanguage.fr;
    final name = _beastName(beastId, fr);
    final clues =
        ref.read(playerSessionProvider).seaBeasts[beastId]?.clues ?? 0;
    _log.add(_t(logKey, ship: name));
    _log.add(_cluesLine(name, clues));
  }

  String _cluesLine(String name, int clues) => clues >= cluesNeeded
      ? _t('ship_log_beast_hunt_ready', ship: name)
      : _t('ship_log_beast_clues', ship: name, n: clues)
          .replaceAll('{of}', '$cluesNeeded');

  /// A tracked beast's sign in these waters: marks on a wreck boarded
  /// ([wreck], now and then) or a shape under the keel on a sighting. A
  /// hunt's own days tell nothing new of the beast it is after.
  Future<void> _beastSign({required bool wreck}) async {
    final id = trackedBeastIn(
      enemyShips: _enemyShips,
      chapter: _chapter,
      beasts: ref.read(playerSessionProvider).seaBeasts,
    );
    if (id == null || id == widget.huntBeastId) return;
    if (wreck && _random.nextDouble() >= derelictClueChance) return;
    await _gainClue(id,
        wreck ? 'ship_log_beast_sign_wreck' : 'ship_log_beast_sign_sighting');
  }

  String _enemyName(bool fr) {
    final data = _enemyData ?? const {};
    final name =
        data['displayName']?.toString() ?? data['shipName']?.toString() ?? '';
    final nameFr = data['displayName_fr']?.toString() ?? '';
    return fr && nameFr.isNotEmpty ? nameFr : name;
  }

  /// Rolls [choice]'s check against its DC (see seaChoiceDc) and writes the
  /// roll in the log.
  bool _seaCheck(SeaChoice choice) {
    final lang = ref.read(appLanguageProvider);
    final result = rollAbilityCheck(
      ability: choice.checkAbility!,
      dc: seaChoiceDc(choice, _chapter),
      session: ref.read(playerSessionProvider),
      random: _random,
    );
    _log.add('${trFor(lang, '${result.ability}_label')} '
        '${trFor(lang, 'check_label')}: '
        '${result.roll} + ${result.modifier} = ${result.total} '
        '${trFor(lang, 'vs_dc_label')} ${result.dc} — '
        '${trFor(lang, result.success ? 'ability_check_success' : 'ability_check_fail')}');
    return result.success;
  }

  /// Now and then, one of the crew says something about how a check at
  /// sea went (see companion_remarks.dart), in a speech bubble over the
  /// sea; the voyage goes on once the player has heard it.
  Future<void> _crewRemark(bool success, {bool slipped = false}) async {
    final remarks = speakUpAbout(ref,
        action: !success
            ? RemarkKind.checkFailed
            : slipped
                ? RemarkKind.sneakedPast
                : RemarkKind.checkPassed);
    if (remarks.isEmpty || !mounted) return;
    // The roll and its result on the log first, under the bubble.
    setState(() {});
    await showCompanionRemarks(context, ref, remarks);
  }

  /// A storm's toll on the hull, eased by a void-marked sail.
  int _stormToll(SeaEvent event) => _sail?.power == SailPower.voidmark
      ? voidmarkStormLoss(-event.hullDelta, _sailStrength)
      : -event.hullDelta;

  /// The storm's toll taken ([_stormToll]), with the void-mark's calm on
  /// the log.
  int _stormLoss(SeaEvent event) {
    if (_sail?.power == SailPower.voidmark) {
      _log.add(_t('ship_log_void_calm'));
    }
    return _stormToll(event);
  }

  Future<void> _loseHull(int loss, String logKey) async {
    final player = _player!;
    final hull = max(1, player.hull - loss);
    _player = player.copyWith(hull: hull);
    _log.add(_t(logKey, n: player.hull - hull));
    await ref.read(playerSessionProvider.notifier).setShipHull(hull);
  }

  /// Resolves the day's [event] the way the crew [choice] (v1.163: each
  /// event has a few, see [seaChoicesFor]).
  Future<void> _resolveEvent(
    SeaEvent event,
    SeaChoice choice, {
    required Map<String, dynamic> enemyShips,
  }) async {
    setState(() => _busy = true);
    final notifier = ref.read(playerSessionProvider.notifier);
    final player = _player!;
    switch (choice.action) {
      case SeaAction.rideOut:
        await _loseHull(_stormLoss(event), 'ship_log_storm');
        await _advance();
      case SeaAction.pushThrough:
        final through = _seaCheck(choice);
        if (through) {
          _log.add(_t('ship_log_pushed_through'));
        } else {
          await _loseHull(_stormLoss(event) * pushThroughFailMultiplier,
              'ship_log_push_failed');
        }
        await _crewRemark(through);
        await _advance();
      case SeaAction.shelter:
        // Safe in a cove, but the crossing takes another day at sea: one
        // drawn by the same rules as the rest (known waters send one
        // raider a crossing at most; a flight sail lifts the Eel over
        // storms and raiders, and then the day is no longer at all).
        var extra = buildVoyage(
          random: _random,
          length: 1,
          enemyShips: _enemyShips,
          chapter: _chapter,
          knownWaters: _knownWaters,
          alreadyRaided: _events!.any((e) => e.kind == SeaEventKind.raider),
          stormShift: _stormShift,
        );
        if (_sail?.power == SailPower.flight) {
          extra = [
            for (final day in extra)
              if (day.kind != SeaEventKind.storm &&
                  day.kind != SeaEventKind.raider)
                day,
          ];
        }
        _events = [
          ..._events!.take(_index + 1),
          ...extra,
          ..._events!.skip(_index + 1),
        ];
        _log.add(_t('ship_log_sheltered'));
        await _advance();
      case SeaAction.repair:
        final hull = min(player.maxHull, player.hull + event.hullDelta);
        _player = player.copyWith(hull: hull);
        _log.add(_t('ship_log_calm', n: hull - player.hull));
        await notifier.setShipHull(hull);
        await _advance();
      case SeaAction.rest:
        final session = ref.read(playerSessionProvider);
        final heal = max(1, session.maxHealth * restHealPercent ~/ 100);
        await notifier.applyChoiceEffects(healAmount: heal);
        _log.add(_t('ship_log_rested', n: heal));
        await _advance();
      case SeaAction.salvage:
        final gold = _sail?.power == SailPower.windknot
            ? windknotSalvage(event.gold, _sailStrength)
            : event.gold;
        await notifier.applyChoiceEffects(goldMod: gold);
        _log.add(_t('ship_log_salvage', n: gold));
        await _advance();
      case SeaAction.board:
        final boarded = _seaCheck(choice);
        if (boarded) {
          final gold = (event.gold * boardGoldMultiplier).round();
          await notifier.applyChoiceEffects(goldMod: gold);
          _log.add(_t('ship_log_boarded', n: gold));
          await _beastSign(wreck: true);
        } else {
          await _loseHull(boardFailHullLoss, 'ship_log_board_holed');
        }
        await _crewRemark(boarded);
        await _advance();
      case SeaAction.passBy:
        _log.add(_t('ship_log_passed_by'));
        await _advance();
      case SeaAction.sailOn:
        if (event.kind == SeaEventKind.sighting) {
          await _beastSign(wreck: false);
        }
        await _advance();
      case SeaAction.holdStill:
        // Sails struck, not a word aboard: the beast may pass beneath and
        // leave the crew a long look at it.
        final id = event.enemyShipId!;
        if (_seaCheck(choice)) {
          _log.add(_t('ship_log_beast_passed',
              ship: _beastName(
                  id, ref.read(appLanguageProvider) == AppLanguage.fr)));
          await _gainClue(id, 'ship_log_beast_watched');
          await _crewRemark(true, slipped: true);
          await _advance();
          return;
        }
        _log.add(_t('ship_log_beast_noticed',
            ship: _beastName(
                id, ref.read(appLanguageProvider) == AppLanguage.fr)));
        await _crewRemark(false);
        await _startRaiderFight(event, enemyShips, keepLog: true);
      case SeaAction.payOff:
        final tribute =
            tributeFor(enemyShips[event.enemyShipId] as Map<String, dynamic>?);
        await notifier.applyChoiceEffects(goldMod: -tribute);
        _log.add(_t('ship_log_paid', n: tribute));
        await _advance();
      case SeaAction.outrun:
        final beast = event.kind == SeaEventKind.beast;
        if (beast) {
          await notifier.updateSeaBeast(
              event.enemyShipId!, (b) => b.copyWith(seen: true));
        }
        if (_seaCheck(choice)) {
          if (beast) {
            // Looking back, the crew sees where it turned away.
            final id = event.enemyShipId!;
            _log.add(_t('ship_log_beast_outran',
                ship: _beastName(
                    id, ref.read(appLanguageProvider) == AppLanguage.fr)));
            await _gainClue(id, 'ship_log_beast_sign_outran');
          } else {
            _log.add(_t('ship_log_outran'));
          }
          await _crewRemark(true, slipped: true);
          await _advance();
          return;
        }
        // Caught: they rake the Eel as they close, then it's a fight. The
        // roll and the raking stay on the log, to say why the hull fell.
        // A beast rams her quarter.
        await _loseHull(beast ? beastOutrunFailHullLoss : outrunFailHullLoss,
            beast ? 'ship_log_beast_caught' : 'ship_log_outrun_failed');
        await _crewRemark(false);
        await _startRaiderFight(event, enemyShips, keepLog: true);
      case SeaAction.fight:
        await _startRaiderFight(event, enemyShips);
    }
  }

  Future<void> _startRaiderFight(
      SeaEvent event, Map<String, dynamic> enemyShips,
      {bool keepLog = false}) async {
    final data = enemyShips[event.enemyShipId] as Map<String, dynamic>?;
    if (data == null) {
      await _advance();
      return;
    }
    _enemyData = data;
    _enemyId = event.enemyShipId;
    var enemy = buildEnemyShip(data);
    _beastId = null;
    _beast = null;
    if (event.kind != SeaEventKind.raider && isBeastRecord(data)) {
      // A beast carries the wounds of the last meeting, and the crew what
      // they learned of it.
      final id = event.enemyShipId!;
      final state =
          ref.read(playerSessionProvider).seaBeasts[id] ?? const BeastState();
      enemy = enemy.copyWith(hull: beastStartHull(enemy.maxHull, state));
      _beastId = id;
      final hunt = event.kind == SeaEventKind.hunt;
      _beast =
          BeastProfile.fromRecord(data, edge: beastEdge(state, hunt: hunt));
      // A hunt spends the signs that led the Eel here once the beast is
      // met, not before: a hunt that never reaches it keeps them.
      await ref.read(playerSessionProvider.notifier).updateSeaBeast(
          id, (b) => b.copyWith(seen: true, clues: hunt ? 0 : null));
      if (!mounted) return;
    }
    _enemy = enemy;
    // The fight's own log starts clean, unless what led to it (a failed
    // run) has to stay to explain it.
    if (!keepLog) _log.clear();
    _battleKey++;
    // The battle reads the clock setting once: wait for the saved
    // choice, not the default it starts at.
    await ref.read(shipTurnTimerProvider.notifier).loaded;
    if (!mounted) return;
    setState(() {
      _phase = _VoyagePhase.fight;
      _busy = false;
    });
  }

  Future<void> _advance() async {
    if (!mounted) return;
    // The day's toll, for the strip.
    final gold = ref.read(playerSessionProvider).gold;
    _dayResults
        .add((hull: _player!.hull - _dayStartHull, gold: gold - _dayStartGold));
    // Each sea event is a day at sea, on the chapter's clock too (see
    // journey_rules.dart): a voyage's days are counted here, as sailed.
    await _passTheDay();
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
    _dayStartHull = _player!.hull;
    _dayStartGold = ref.read(playerSessionProvider).gold;
    setState(() {
      _index++;
      _phase = _VoyagePhase.event;
      _busy = false;
    });
  }

  /// A day at sea gone (see PlayerSessionNotifier.passSeaDay): on the
  /// chapter's clock, and a ration the crew eats, or hunger with none left.
  Future<void> _passTheDay() async {
    final day = await ref
        .read(playerSessionProvider.notifier)
        .passSeaDay(chapter: ref.read(reachedChapterProvider));
    if (day.hungry && day.hunger > 0) {
      _log.add(_t('road_note_hungry', n: day.hunger));
    } else if (day.counted && day.provisionsLeft == 0) {
      _log.add(_t('road_note_last'));
    }
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

  /// A beast battle's end: slain, it pays and leaves its trophy; alive,
  /// it carries its wounds away, and a battle fought out and lived through
  /// gives the crew one more sign of it (not one they ran from).
  Future<void> _onBeastFinished(ShipBattleOutcome outcome) async {
    final id = _beastId!;
    final notifier = ref.read(playerSessionProvider.notifier);
    final fr = ref.read(appLanguageProvider) == AppLanguage.fr;
    final name = _enemyName(fr);
    final data = _enemyData ?? const <String, dynamic>{};
    final maxHull = _enemy?.maxHull ?? 1;
    _player = outcome.player;
    _beastId = null;
    _beast = null;
    _log
      ..clear()
      ..addAll(outcome.log.length > 3
          ? outcome.log.sublist(outcome.log.length - 3)
          : outcome.log);
    final slain = outcome.won;
    final lost = !slain && !outcome.escaped && !outcome.fled;
    final learned = !lost && !outcome.fled;
    await notifier.updateSeaBeast(
        id,
        (b) => beastAfterBattle(b,
            maxHull: maxHull,
            hullAtEnd: slain ? 0 : outcome.enemyHull,
            slain: slain,
            learned: learned));
    final gold = slain ? (data['goldReward'] as num?)?.toInt() ?? 0 : 0;
    final xp = slain ? (data['xpReward'] as num?)?.toInt() ?? 0 : 0;
    for (final member in outcome.crew) {
      if (member.isPlayer) {
        await notifier.applyCombatResult(
          hpAfter: member.health,
          goldGain: gold,
          xpGain: xp,
          // Standing up to a beast and living counts on the camp's board;
          // running from it does not.
          contractTally: learned
              ? ContractTally(beastsFought: 1, shipsBeaten: slain ? 1 : 0)
              : null,
        );
      } else {
        await notifier.applyAllyCombatResult(member.id, hpAfter: member.health);
      }
    }
    if (!mounted) return;
    if (lost) {
      await notifier.setShipHull(limpHomeHull(_player!.maxHull));
      // The day of the fight counts, lost as it was.
      await _passTheDay();
      if (!mounted) return;
      setState(() {
        _phase = _VoyagePhase.failed;
        _busy = false;
      });
      return;
    }
    if (slain) {
      await notifier.applyChoiceEffects(
          itemId: beastTrophyItemId, flagsToAdd: ['beast_slain_$id']);
      _log.add(_t('ship_log_beast_slain', ship: name));
      // Its trophy goes on the Eel if there is room aboard; if not, it
      // waits at the Harbor, fitted for nothing.
      final partId = beastTrophyPartId(data);
      final part =
          partId == null ? null : _parts[partId] as Map<String, dynamic>?;
      if (part != null) {
        final partName =
            fr && (part['partName_fr']?.toString() ?? '').isNotEmpty
                ? part['partName_fr'].toString()
                : part['partName']?.toString() ?? partId!;
        final fits = canInstallPart(
            ship: _shipRecord,
            parts: _parts,
            installedPartIds: ref.read(playerSessionProvider).shipPartIds,
            partId: partId!);
        final fitted = fits && await notifier.installShipPart(partId, 0);
        if (!fitted) await notifier.storeShipPart(partId);
        _log.add(
            _t(fitted ? 'ship_log_trophy_fitted' : 'ship_log_trophy_waiting')
                .replaceAll('{weapon}', partName));
      }
      _log.add('${_t('ship_fight_won_prefix')}: +$gold ${_t('gold_label')}');
    } else if (outcome.escaped) {
      _log.add(_t('ship_log_beast_got_away', ship: name));
      _log.add(_cluesLine(
          name, ref.read(playerSessionProvider).seaBeasts[id]?.clues ?? 0));
    } else {
      _log.add(_t('ship_log_beast_outran', ship: name));
    }
    await notifier.setShipHull(_player!.hull);
    await _advance();
  }

  Future<void> _onBattleFinished(ShipBattleOutcome outcome) async {
    if (_beastId != null) {
      await _onBeastFinished(outcome);
      return;
    }
    final notifier = ref.read(playerSessionProvider.notifier);
    final enemyName =
        _enemyName(ref.read(appLanguageProvider) == AppLanguage.fr);
    final before = _player;
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
          hpAfter: member.health,
          goldGain: gold,
          xpGain: xp,
          // A won sea fight counts on the camp's board (see contracts.dart).
          contractTally: outcome.won
              ? ContractTally.sea(
                  boarded: outcome.boarded,
                  hullBefore: before?.hull ?? outcome.player.hull,
                  hullAfter: outcome.player.hull,
                  maxHull: outcome.player.maxHull)
              : null,
        );
      } else {
        await notifier.applyAllyCombatResult(member.id, hpAfter: member.health);
      }
    }
    if (!mounted) return;
    if (outcome.fled) {
      // The Eel outran them: no prize, and she sails on as she is.
      _log.add(_t('ship_log_outran'));
      await notifier.setShipHull(_player!.hull);
      await _advance();
      return;
    }
    if (outcome.escaped) {
      // The raider got away: nothing to take, and the Eel sails on as
      // she is.
      _log.add(_t('ship_log_got_away', ship: enemyName));
      await notifier.setShipHull(_player!.hull);
      await _advance();
      return;
    }
    if (outcome.won) {
      if (!outcome.boarded) _log.add(_t('ship_log_sunk', ship: enemyName));
      if (prizeLine != null) _log.add(prizeLine);
      _log.add('${_t('ship_fight_won_prefix')}: +$gold ${_t('gold_label')}');
      await notifier.setShipHull(_player!.hull);
      await _advance();
      return;
    }
    await notifier.setShipHull(limpHomeHull(_player!.maxHull));
    // The day of the fight counts, lost as it was.
    await _passTheDay();
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
    // Loaded before the first check at sea, for the crew's remarks.
    ref.watch(remarkBookProvider);
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
      return _tour(
        ready: false,
        child: Scaffold(
          appBar: AppBar(title: Text(title)),
          body: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    _ensureStarted(
        ships: ships, parts: parts, enemyShips: enemyShips, ports: ports);

    // The tour waits for a day at sea, so it has the hull and the choices
    // to point at (not the spinner, nor a battle already under way).
    return _tour(
      ready: _phase == _VoyagePhase.event,
      child: _buildScreen(
        context,
        title: title,
        lang: lang,
        fr: fr,
        enemyShips: enemyShips,
        parts: parts,
        companions: companions,
        races: races,
        professions: professions,
        gameConfig: gameConfig,
      ),
    );
  }

  /// The voyage's tour around [child]. The one trigger stays put from the
  /// spinner to the first day, so its pause carries over when the data
  /// lands.
  Widget _tour({required bool ready, required Widget child}) =>
      TutorialTrigger(topic: TutorialTopic.voyage, ready: ready, child: child);

  Widget _buildScreen(
    BuildContext context, {
    required String title,
    required AppLanguage lang,
    required bool fr,
    required Map<String, dynamic> enemyShips,
    required Map<String, dynamic> parts,
    required Map<String, dynamic> companions,
    required Map<String, dynamic> races,
    required Map<String, dynamic> professions,
    required Map<String, dynamic> gameConfig,
  }) {
    return PopScope(
      canPop: _phase == _VoyagePhase.arrived || _phase == _VoyagePhase.failed,
      child: Scaffold(
        appBar: AppBar(title: Text(title), automaticallyImplyLeading: false),
        body: SafeArea(
          child: Padding(
            // The battle keeps its own margins, so it has the width.
            padding: _phase == _VoyagePhase.fight
                ? EdgeInsets.zero
                : const EdgeInsets.all(20),
            child: switch (_phase) {
              // A storm day rains and flashes behind its card.
              _VoyagePhase.event => Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_events![_index].kind == SeaEventKind.storm)
                      const Positioned.fill(child: StormLayer()),
                    FlipIn(
                      flipKey: _index,
                      child: _buildEvent(context,
                          fr: fr, enemyShips: enemyShips, parts: parts),
                    ),
                  ],
                ),
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
        HullBar(hull: ship.hull, maxHull: ship.maxHull),
        if (ship.maxLayers > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${trFor(lang, 'shield_short_label')} ${ship.layers} / ${ship.maxLayers}',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: InkColors.of(context).voidColor),
            ),
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
            Text(trFor(ref.read(appLanguageProvider), 'ships_log_title'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: InkColors.of(context).ash, letterSpacing: 1)),
            const SizedBox(height: 4),
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
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final event = _events![_index];
    final (icon, colour) = _kindLook(event.kind, ink);
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRoute(context, fr: fr),
          const SizedBox(height: 10),
          // The Eel on the water, beside what she meets. On a short phone
          // the day's words need the room more: she is left out.
          if (constraints.maxHeight >= dayPictureMinHeight) ...[
            ShipAtSea(
              ship: _player!,
              height: 104,
              beside: Icon(icon, size: 46, color: colour),
            ),
            const SizedBox(height: 8),
          ],
          TutorialTarget(
            id: 'voyage.hull',
            child: _buildShipBars(context, _player!, trFor(lang, 'boat_title')),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Icon(icon, size: 18, color: colour),
                    const SizedBox(width: 6),
                    Text(
                      trFor(lang, 'sea_event_${event.kind.name}').toUpperCase(),
                      key: const Key('sea_event_kind'),
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: colour, letterSpacing: 1),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    event.descriptionFor(fr),
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                  // A raider is named and described before the guns come
                  // out: who she is and what she wants from the Eel. So is
                  // a beast, with what the crew knows of it.
                  if (_meetsShip(event) &&
                      enemyShips[event.enemyShipId]
                          is Map<String, dynamic>) ...[
                    ..._raiderIntro(
                        enemyShips[event.enemyShipId] as Map<String, dynamic>,
                        fr),
                    if (event.kind != SeaEventKind.raider)
                      ..._beastIntro(event.enemyShipId!),
                  ],
                  if (event.omenBeastId != null &&
                      enemyShips[event.omenBeastId] is Map<String, dynamic>)
                    ..._omen(
                        enemyShips[event.omenBeastId] as Map<String, dynamic>),
                  if (_sail?.power == SailPower.foresight) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${trFor(lang, 'ship_log_foresight_prefix')}: '
                      '${_foresightPreview(lang)}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildLog(context),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TutorialTarget(
            id: 'voyage.choices',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, choice) in event.choices.indexed) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _choiceCard(
                    key: Key('sea_choice_${choice.action.name}'),
                    onPressed: _busy || !_canAfford(event, choice, enemyShips)
                        ? null
                        : () => _resolveEvent(event, choice,
                            enemyShips: enemyShips),
                    label: _choiceLabel(event, choice, enemyShips, fr),
                    stake: _stakeFor(event, choice, enemyShips),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A sea event's mark and colour.
  (IconData, Color) _kindLook(SeaEventKind kind, InkColors ink) =>
      switch (kind) {
        SeaEventKind.calm => (Icons.waves, ink.heal),
        SeaEventKind.storm => (Icons.thunderstorm_outlined, ink.blood),
        SeaEventKind.raider => (Icons.sailing, ink.ember),
        SeaEventKind.derelict => (Icons.sailing_outlined, ink.gold),
        SeaEventKind.sighting => (Icons.visibility_outlined, ink.tide),
        SeaEventKind.beast || SeaEventKind.hunt => (
            Icons.tsunami_outlined,
            ink.blood
          ),
      };

  /// The crossing as a strip of days: where she left, each day behind her
  /// with what it cost or gave, today, the days still to come, and the
  /// port ahead.
  Widget _buildRoute(BuildContext context, {required bool fr}) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.watch(appLanguageProvider);
    final ports = ref.watch(localizedDbProvider(portsSchema)).value ?? const {};
    final from = ports[widget.fromPortId] as Map<String, dynamic>?;
    final total = _events!.length;
    String result(({int hull, int gold}) r) {
      final parts = [
        if (r.hull != 0)
          '${r.hull > 0 ? '+' : '−'}${r.hull.abs()} ${trFor(lang, 'hull_label').toLowerCase()}',
        if (r.gold != 0)
          '${r.gold > 0 ? '+' : '−'}${r.gold.abs()} ${trFor(lang, 'gold_label').toLowerCase()}',
      ];
      return parts.isEmpty ? trFor(lang, 'route_day_quiet') : parts.join('\n');
    }

    Widget end(IconData icon, Color colour) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Icon(icon, size: 18, color: colour),
        );
    // A link between two days: it takes the room left, or a fixed width
    // when the strip scrolls.
    Widget link(bool lit, {double? width}) {
      final line = Container(
        width: width,
        height: 2,
        margin: const EdgeInsets.only(top: 12),
        color: lit ? ink.gold : ink.seam,
      );
      return width == null ? Expanded(child: line) : line;
    }

    Widget day(int i) {
      final e = _events![i];
      final (icon, colour) = _kindLook(e.kind, ink);
      final past = i < _index;
      final now = i == _index;
      final seen = past || now;
      return SizedBox(
        key: Key('route_day_$i'),
        width: 50,
        child: Column(children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: now ? ink.gold : ink.seam, width: now ? 2 : 1),
            ),
            child: Icon(seen ? icon : Icons.question_mark,
                size: 14, color: seen ? colour : ink.ash),
          ),
          const SizedBox(height: 2),
          Text(
            now
                ? trFor(lang, 'route_today')
                : past && i < _dayResults.length
                    ? result(_dayResults[i])
                    : '',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10, color: now ? ink.gold : ink.ash, height: 1.2),
          ),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          [
            if (from != null)
              trFor(lang, 'route_from_to')
                  .replaceAll('{from}', portNameFor(from, fr))
                  .replaceAll('{to}', portNameFor(widget.toPort, fr)),
            '${trFor(lang, 'voyage_day_label')} ${_index + 1} / $total',
          ].join(' · '),
          style: theme.textTheme.labelMedium?.copyWith(color: ink.ash),
        ),
        const SizedBox(height: 6),
        // A long crossing (a shelter adds a day) scrolls sideways rather
        // than running off the screen.
        LayoutBuilder(builder: (context, constraints) {
          const linkMin = 8.0;
          final fits =
              36 + total * 50 + (total + 1) * linkMin <= constraints.maxWidth;
          final width = fits ? null : linkMin * 2;
          final row = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: fits ? MainAxisSize.max : MainAxisSize.min,
            children: [
              end(Icons.circle, ink.ash),
              for (var i = 0; i < total; i++) ...[
                link(i <= _index, width: width),
                day(i),
              ],
              link(false, width: width),
              end(Icons.anchor, ink.tide),
            ],
          );
          return fits
              ? row
              : SingleChildScrollView(
                  key: const Key('route_scroll'),
                  scrollDirection: Axis.horizontal,
                  child: row,
                );
        }),
      ],
    );
  }

  /// What [choice] wins or costs, and its odds when it is a check.
  ({String text, String? odds, bool safe}) _stakeFor(
      SeaEvent event, SeaChoice choice, Map<String, dynamic> enemyShips) {
    final lang = ref.read(appLanguageProvider);
    final session = ref.read(playerSessionProvider);
    String t(String key, [int? n]) {
      final text = trFor(lang, key);
      return n == null ? text : text.replaceAll('{n}', '$n');
    }

    final ability = choice.checkAbility;
    String? odds;
    String check = '';
    if (ability != null) {
      final modifier = abilityModifierFor(ability, session);
      final dc = seaChoiceDc(choice, _chapter);
      odds = '${(checkChance(modifier: modifier, dc: dc) * 100).round()}%';
      check = '${trFor(lang, '${ability}_label')} '
          '${modifier >= 0 ? '+' : '−'}${modifier.abs()} '
          '${trFor(lang, 'vs_dc_label')} $dc · ';
    }
    final salvage = _sail?.power == SailPower.windknot
        ? windknotSalvage(event.gold, _sailStrength)
        : event.gold;
    // What the storm would take, eased by a void-marked sail as it is on
    // the day.
    final storm = _stormToll(event);
    final beast = event.kind == SeaEventKind.beast;
    return switch (choice.action) {
      SeaAction.salvage => (
          text: t('stake_safe_gold', salvage),
          odds: null,
          safe: true
        ),
      SeaAction.board => (
          text:
              '$check${t('stake_board').replaceAll('{gold}', '${(event.gold * boardGoldMultiplier).round()}').replaceAll('{hull}', '$boardFailHullLoss')}',
          odds: odds,
          safe: false
        ),
      SeaAction.passBy || SeaAction.sailOn => (
          text: t('stake_nothing'),
          odds: null,
          safe: true
        ),
      SeaAction.rideOut => (
          text: t('stake_lose_hull', storm),
          odds: null,
          safe: false
        ),
      SeaAction.pushThrough => (
          text: '$check${t('stake_push', storm * pushThroughFailMultiplier)}',
          odds: odds,
          safe: false
        ),
      SeaAction.shelter => (text: t('stake_shelter'), odds: null, safe: true),
      SeaAction.repair => (
          text: t('stake_repair',
              min(event.hullDelta, _player!.maxHull - _player!.hull)),
          odds: null,
          safe: true
        ),
      SeaAction.rest => (
          text: t(
              'stake_rest', max(1, session.maxHealth * restHealPercent ~/ 100)),
          odds: null,
          safe: true
        ),
      SeaAction.payOff => (
          text: t(
              'stake_pay',
              tributeFor(
                  enemyShips[event.enemyShipId] as Map<String, dynamic>?)),
          odds: null,
          safe: true
        ),
      SeaAction.outrun => (
          text:
              '$check${t('stake_outrun', beast ? beastOutrunFailHullLoss : outrunFailHullLoss)}',
          odds: odds,
          safe: false
        ),
      SeaAction.holdStill => (
          text: '$check${t('stake_hold_still')}',
          odds: odds,
          safe: false
        ),
      SeaAction.fight => (text: t('stake_fight'), odds: null, safe: false),
    };
  }

  bool _canAfford(
          SeaEvent event, SeaChoice choice, Map<String, dynamic> enemyShips) =>
      choice.action != SeaAction.payOff ||
      ref.read(playerSessionProvider).gold >=
          tributeFor(enemyShips[event.enemyShipId] as Map<String, dynamic>?);

  String _choiceLabel(SeaEvent event, SeaChoice choice,
      Map<String, dynamic> enemyShips, bool fr) {
    final lang = ref.read(appLanguageProvider);
    final text = choice.textFor(fr);
    if (choice.action == SeaAction.payOff) {
      final tribute =
          tributeFor(enemyShips[event.enemyShipId] as Map<String, dynamic>?);
      return '$text (${trFor(lang, 'sea_choice_cost').replaceAll('{n}', '$tribute')})';
    }
    return text;
  }

  /// A choice as a card: what the crew does, then what it wins or costs
  /// (and its odds, for a check). None is marked as the one to take.
  Widget _choiceCard({
    required Key key,
    required VoidCallback? onPressed,
    required String label,
    required ({String text, String? odds, bool safe}) stake,
  }) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final enabled = onPressed != null;
    return OutlinedButton(
      key: key,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        side: BorderSide(color: ink.seam),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  stake.text,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: !enabled
                          ? ink.ash
                          : stake.safe
                              ? ink.heal
                              : ink.ash),
                ),
              ],
            ),
          ),
          if (stake.odds != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: ink.tide.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(stake.odds!,
                  style:
                      theme.textTheme.labelMedium?.copyWith(color: ink.tide)),
            ),
          ],
        ],
      ),
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
      placeCrew: true,
      player: _player!,
      enemy: _enemy!,
      shipName: trFor(lang, 'boat_title'),
      enemyName: _enemyName(fr),
      enemyShipId: _enemyId,
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
      turnSeconds: ref.read(shipTurnTimerProvider)
          ? shipTurnSeconds(
              ship: _shipRecord,
              parts: _parts,
              installedPartIds: session.shipPartIds)
          : null,
      habit: habitFromName(_enemyData?['habit']?.toString()),
      windKnot: _sail?.power == SailPower.windknot,
      beast: _beast,
      waters: _waters,
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

/// Below this height a day at sea leaves the Eel's picture out, so the
/// day's words (a beast named and described, what the crew knows of it)
/// keep room to be read above the choices.
const double dayPictureMinHeight = 600;

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
