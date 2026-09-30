import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/encounter.dart';
import '../combat/sea_beasts.dart';
import '../combat/ship_battle.dart';
import '../combat/ship_combat.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../providers/aftermath_provider.dart';
import '../providers/combat_active_provider.dart';
import '../providers/combat_settings_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/tutorial_provider.dart';
import '../theme/stitched_ink.dart';
import '../widgets/ship_cutaway.dart';
import '../widgets/sea_battlefield.dart';
import '../widgets/ship_fx.dart';
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

/// The room-by-room ship battle (see ship_battle.dart and
/// ship_combat.dart), seen from above (see sea_battlefield.dart): two
/// ships broadside to broadside on the waters of the voyage, four rooms
/// along each deck, the gap between them the range, the weather drifting
/// over them. The enemy's name, hull and weapons with their charge sit
/// above the sea; the Eel's below it, then the weather (and the next
/// round's), the range and the helm's maneuvers, and the log; the shot
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
  static const _seaSeconds = 600.0;

  /// The weather the sea last showed, the one before it and when it
  /// turned (on the sea's clock): the old weather fades as the new comes.
  SeaWeather? _shownWeather;
  SeaWeather? _fadingWeather;
  double _weatherTurnedAt = -10;
  static const _weatherFade = 1.6;
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
    _armedWeaponId = _firstReadyWeaponId();
    _startClock();
  }

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

  /// The name of [room] of the Eel or, with [enemy], of the enemy: a
  /// beast's rooms are its fins, jaws, hide and heart. [suffix] picks the
  /// word's form ('' in a sentence, '_title' on a tile, '_hint').
  String _roomName(AppLanguage lang, ShipRoom room,
          {required bool enemy, String suffix = ''}) =>
      trFor(
          lang,
          widget.beast != null && enemy
              ? 'beast_room_${room.name}$suffix'
              : 'ship_room_${room.name}$suffix');

  /// A log line in the player's language. A line about a beast is worded
  /// for one where a beast has its own (`beast_` + the key): its crew
  /// mends nothing, it bleeds where a ship takes on water.
  String _line(BattleLine line) {
    final lang = ref.read(appLanguageProvider);
    final aboutBeast = widget.beast != null &&
        (line.side == BattleSide.enemy || line.key == 'ship_log_focus');
    final beastKey = 'beast_${line.key}';
    final key = aboutBeast && trFor(AppLanguage.en, beastKey) != beastKey
        ? beastKey
        : line.key;
    var text = trFor(lang, key);
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
      text =
          text.replaceAll('{room}', _roomName(lang, room, enemy: aboutBeast));
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
      if (widget.beast != null) 'ship_beast',
      if (widget.beast != null &&
          b.player.weapons.any((w) => w.tetherRounds > 0))
        'ship_tether',
      if (b.rules.range) 'ship_range',
      if (b.rules.habits && widget.habit != EnemyHabit.none)
        'ship_habit_${widget.habit.name}',
      if (b.rules.weather && b.weather != SeaWeather.calm) 'ship_weather',
      if (aimed != AimedShots.off && b.anyShotReady) 'ship_aim',
      if (b.crew.any(b.canOrder)) 'ship_orders',
      if (b.player.rooms.values.any((r) => r.onFire)) 'ship_fire',
      if (b.player.leaks > 0) 'ship_leak',
      if (b.canBoardThem) 'ship_boarding',
      if (b.canRun) 'ship_run',
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
      padding: EdgeInsets.zero,
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
    final weapon = _battle.weaponById(weaponId);
    final ammo = weapon?.ammo ?? ShipAmmo.round;
    final logged = _battle.log.length;
    final outcome = _battle.fire(weaponId, room, aim: aim);
    if (outcome != null && weapon != null) {
      _playShot(outcome, _battle.log.sublist(logged),
          fromEel: true,
          kind: weapon.incendiary || ammo == ShipAmmo.heated
              ? ShipShotKind.heated
              : switch (ammo) {
                  ShipAmmo.chain => ShipShotKind.chain,
                  ShipAmmo.grape => ShipShotKind.grape,
                  _ => ShipShotKind.round,
                });
    }
    _flashLater(outcome, onEel: false);
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
    final beforeEnemy = _battle.log.length;
    _battle.startEnemyPhase(quickOrders: quick);
    _playLines(_battle.log.sublist(beforeEnemy));
    if (_battle.over) {
      _finish();
      return;
    }
    setState(() {});
    for (final weapon in _battle.enemyVolley) {
      final logged = _battle.log.length;
      final shot = _battle.fireEnemy(weapon);
      if (!mounted) return;
      if (shot != null) {
        _playShot(shot, _battle.log.sublist(logged),
            fromEel: false,
            kind: weapon.incendiary ? ShipShotKind.heated : ShipShotKind.round);
      }
      _flashLater(shot, onEel: true);
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
    final beforeRound = _battle.log.length;
    _battle.endRound();
    _playLines(_battle.log.sublist(beforeRound));
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
    final sinking = end == BattleEnd.won
        ? false
        : end == BattleEnd.lost
            ? true
            : null;
    if (sinking != null && mounted && !_still) {
      // The losing ship goes down before the battle hands its result on.
      setState(() => _sinkingEel = sinking);
      _sink.forward(from: 0);
      _fx.play(ShipFxKind.bubbles, _hullKeys[sinking]!);
      _fx.play(ShipFxKind.bubbles, _hullKeys[sinking]!, delay: 0.5);
      _finishTimer = Timer(const Duration(milliseconds: 1400), _report);
      return;
    }
    _report();
  }

  void _report() {
    final end = _battle.end;
    widget.onFinished(ShipBattleOutcome(
      won: end == BattleEnd.won || end == BattleEnd.boarded,
      player: _battle.player,
      crew: _battle.crew,
      log: [for (final line in _battle.log) _line(line)],
      boarded: end == BattleEnd.boarded,
      escaped: end == BattleEnd.escaped,
      fled: end == BattleEnd.fled,
      enemyHull: _battle.enemy.hull,
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

  /// Fights the enemy's boarding crew on the dice: won, lost, or run
  /// from (the fight's retreat); null when the fight ended the run
  /// (permadeath).
  Future<_DeckFight?> _deckFight(Map<String, Map<String, dynamic>> records,
      {double healthMultiplier = 1.0}) async {
    final ids = widget.boarding.crew;
    ref.read(combatActiveProvider.notifier).state = true;
    final retreated = ref.read(lastFightRetreatedProvider.notifier);
    retreated.state = false;
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
    // A retreat pops the fight with no result; it is no end of the run.
    if (won == null && retreated.state) {
      retreated.state = false;
      return _DeckFight.fled;
    }
    if (won == null) return null;
    return won ? _DeckFight.won : _DeckFight.lost;
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
    final hooked = _battle.throwGrapples();
    if (hooked && !_still) {
      _fx.shot(_roomKeys[(true, ShipRoom.bulwark)]!,
          _roomKeys[(false, ShipRoom.bulwark)]!, ShipShotKind.chain,
          arrival: const [ShipFxKind.ring]);
    }
    if (!hooked) {
      setState(() => _busy = false);
      await _endTurn();
      return;
    }
    setState(_battle.boardingStarted);
    final result = await _deckFight(records);
    if (!mounted || result == null) return;
    if (result == _DeckFight.won) {
      _battle.boardingWon();
      _finish();
      return;
    }
    setState(() {
      // Run from: back aboard, the grapples cut; lost: thrown back.
      if (result == _DeckFight.fled) {
        _battle.boardingAbandoned();
      } else {
        _battle.boardingLost();
      }
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
    final result = await _deckFight(records,
        healthMultiplier: holdManned ? holdMannedBoarderHealth : 1.0);
    if (!mounted || result == null) return false;
    if (result == _DeckFight.won) {
      _battle.boardersRepelled();
    } else {
      // Lost, or the deck left to them: they wreck the hold either way.
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

  /// Whether the device asks for less motion: no particles, no waiting on
  /// a ball in flight or a ship going down.
  bool get _still => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// Says what a shot did once its ball has landed (at once when still).
  void _flashLater(ShotOutcome? outcome, {required bool onEel}) {
    if (outcome == null) return;
    if (_still) {
      _flash(outcome, onEel: onEel);
      return;
    }
    late final Timer timer;
    timer = Timer(Duration(milliseconds: (shipShotSeconds * 1000).round()), () {
      _fxTimers.remove(timer);
      if (!mounted) return;
      setState(() => _flash(outcome, onEel: onEel));
    });
    _fxTimers.add(timer);
  }

  /// A shot across, from [fromEel]'s guns to the room it was aimed at, and
  /// what it did there: the same for either ship.
  void _playShot(ShotOutcome outcome, List<BattleLine> lines,
      {required bool fromEel, required ShipShotKind kind}) {
    if (_still) return;
    final target = !fromEel;
    final keys = lines.map((l) => l.key).toSet();
    final arrival = <ShipFxKind>[
      if (outcome.absorbed) ShipFxKind.shield,
      if (outcome.landed) ShipFxKind.splinters,
      if (outcome.landed && keys.contains('ship_log_critical'))
        ShipFxKind.critical,
      if (outcome.fireStarted) ShipFxKind.ignite,
      if (outcome.roomKnockedOut) ShipFxKind.knockedOut,
      if (outcome.helmDamage > 0 || keys.contains('ship_log_rigging_torn'))
        ShipFxKind.fibres,
    ];
    _fx.shot(_roomKeys[(fromEel, ShipRoom.guns)]!,
        _roomKeys[(target, outcome.room)]!, kind,
        arrival: arrival);
    if (outcome.dodged) {
      _fx.play(ShipFxKind.splash, _hullKeys[target]!, delay: shipShotSeconds);
    }
    if (outcome.leakOpened) {
      _fx.play(ShipFxKind.bubbles, _roomKeys[(target, ShipRoom.hold)]!,
          delay: shipShotSeconds);
    }
  }

  /// What the rest of a round did, besides the shots: the sea's events, a
  /// ram, boarders.
  void _playLines(List<BattleLine> lines) {
    if (_still) return;
    for (final line in lines) {
      switch (line.key) {
        case 'ship_event_rogue_wave':
          _fx.play(ShipFxKind.wave, _seaKey);
        case 'ship_event_sea_creature':
          _fx.play(ShipFxKind.bubbles,
              _roomKeys[(line.side == BattleSide.eel, ShipRoom.hold)]!);
        case 'ship_event_wreck':
          _fx.play(ShipFxKind.debris, _seaKey);
        case 'ship_log_rammed':
          // The rammer's bow into the other ship's.
          final hit = line.side != BattleSide.eel;
          _fx.play(ShipFxKind.splinters, _roomKeys[(hit, ShipRoom.bulwark)]!);
          _fx.play(ShipFxKind.splinters, _roomKeys[(!hit, ShipRoom.bulwark)]!,
              delay: 0.05);
        case 'ship_log_boarders':
          _fx.shot(_roomKeys[(false, ShipRoom.bulwark)]!,
              _roomKeys[(true, ShipRoom.bulwark)]!, ShipShotKind.chain,
              arrival: const [ShipFxKind.ring]);
      }
    }
  }

  /// What an order looks like as it is given.
  void _playOrder(CrewOrder order) {
    if (_still) return;
    switch (order) {
      case CrewOrder.allHands:
        for (final room in ShipRoom.values) {
          final state = _battle.player.room(room);
          if (state.damage > 0 || room == ShipRoom.guns) {
            _fx.play(ShipFxKind.sparkles, _roomKeys[(true, room)]!);
          }
        }
      case CrewOrder.bless:
        _fx.play(ShipFxKind.motes, _hullKeys[true]!);
      case CrewOrder.brace:
      case CrewOrder.voidWard:
        _fx.play(ShipFxKind.ring, _hullKeys[true]!);
      case CrewOrder.shoreUp:
        _fx.play(ShipFxKind.shield, _roomKeys[(true, ShipRoom.bulwark)]!);
      case CrewOrder.markHelm:
        _fx.play(ShipFxKind.critical, _roomKeys[(false, ShipRoom.helm)]!);
      case CrewOrder.cutRigging:
        _fx.play(ShipFxKind.fibres, _roomKeys[(false, ShipRoom.guns)]!);
      case CrewOrder.eagleEye:
        _fx.play(ShipFxKind.ring, _hullKeys[false]!);
      case CrewOrder.grapple:
        break;
    }
  }

  /// The battle's lasting effects: the weather, rooms burning, holds
  /// leaking, on both ships.
  ShipFxAmbient _ambient() {
    // The weather is drawn over the sea itself (see _buildBattlefield).
    return ShipFxAmbient(
      burning: [
        for (final eel in [true, false])
          for (final room in ShipRoom.values)
            if ((eel ? _battle.player : _battle.enemy).room(room).onFire)
              _roomKeys[(eel, room)]!,
      ],
      leaking: [
        for (final eel in [true, false])
          if ((eel ? _battle.player : _battle.enemy).leaks > 0)
            (
              _roomKeys[(eel, ShipRoom.hold)]!,
              (eel ? _battle.player : _battle.enemy).leaks
            ),
      ],
    );
  }

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
    // Low in the water with a way out: that comes before anything else.
    final runWarning = widget.canFlee &&
        !_over &&
        _battle.player.hull < _battle.player.maxHull * runWarningShare;
    if (runWarning) hint = trFor(lang, 'ship_run_warning');
    if (_busy && !_over) {
      hint = trFor(lang, 'ship_enemy_turn_label')
          .replaceAll('{ship}', widget.enemyName);
    }
    final ink2 = ink;
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
                  if (widget.beast != null) _buildBeastStatus(lang),
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
              children: [bar, Expanded(child: sea), dock],
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

  /// The player's side of the turn, always in reach at the bottom: the
  /// clock, the hint (or the aim bar), the weapons, the shot, the crew and
  /// the end of the turn.
  Widget _buildDock(AppLanguage lang, bool fr, Map<String, dynamic>? enemies,
      bool canBoard, String hint,
      {bool warn = false}) {
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
                _shipBar(
                  name: widget.shipName,
                  ship: _battle.player,
                  evasion: _battle.playerEvasion,
                  color: ink.gold,
                ),
                const SizedBox(height: 6),
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
                            key: const Key('ship_hint'),
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: (_busy && !_over) || warn
                                    ? ink.blood
                                    : ink.ash),
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

  /// A small dark chip floating on the sea.
  Widget _seaChip(Widget child, {Key? key, Color? border}) => Container(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: border ?? Colors.white.withValues(alpha: 0.12)),
        ),
        child: child,
      );

  /// This round's weather and the next, in a chip in the sea's corner;
  /// a wreck adrift beside it.
  Widget _weatherChip(AppLanguage lang) {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final small = theme.textTheme.labelSmall;
    return Tooltip(
      message: trFor(lang, 'ship_weather_${_battle.weather.name}_hint'),
      child: _seaChip(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_weatherIcon(_battle.weather),
              size: 14, color: _weatherColor(ink, _battle.weather)),
          const SizedBox(width: 4),
          Text(trFor(lang, 'ship_weather_${_battle.weather.name}'),
              style: small?.copyWith(color: Colors.white)),
          const SizedBox(width: 6),
          Text('${trFor(lang, 'ship_weather_next_label')} ',
              style: small?.copyWith(color: ink.ash)),
          Tooltip(
            message: trFor(lang, 'ship_weather_${_battle.nextWeather.name}'),
            child: Icon(_weatherIcon(_battle.nextWeather),
                size: 13, color: ink.ash),
          ),
          if (_battle.wreck) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: trFor(lang, 'ship_wreck_hint'),
              child: Icon(Icons.sailing_outlined,
                  size: 14, color: _roomColor(context, ShipRoom.hold)),
            ),
          ],
        ],
      )),
    );
  }

  /// Close in and pull away: two round buttons on the sea's right edge,
  /// up toward the enemy and down away from her.
  Widget _rangeButtons(AppLanguage lang) {
    final ink = InkColors.of(context);
    final range = _battle.range;
    final closer = range.index > 0 ? ShipRange.values[range.index - 1] : null;
    final farther = range.index < ShipRange.values.length - 1
        ? ShipRange.values[range.index + 1]
        : null;
    final canAct = !_busy && !_over;
    Widget button(Key key, IconData icon, String label, VoidCallback? onTap) {
      final on = onTap != null;
      return Tooltip(
        message: label,
        child: Material(
          color: Colors.black.withValues(alpha: 0.55),
          shape: CircleBorder(
              side: BorderSide(color: on ? ink.gold : ink.seam, width: 1.5)),
          child: InkWell(
            key: key,
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, size: 22, color: on ? ink.gold : ink.ash),
            ),
          ),
        ),
      );
    }

    return Column(
      key: const Key('ship_range_bar'),
      mainAxisSize: MainAxisSize.min,
      children: [
        button(
          const Key('ship_close_in'),
          Icons.keyboard_double_arrow_up,
          trFor(lang, 'ship_close_in_button'),
          canAct && closer != null && _battle.canMoveTo(closer)
              ? () => setState(() {
                    _battle.maneuver(closer);
                    _rearm();
                  })
              : null,
        ),
        const SizedBox(height: 10),
        // At long range the Eel can run for it instead (see
        // ShipBattle.runForIt).
        if (farther == null && widget.canFlee)
          button(
            const Key('ship_run_button'),
            Icons.directions_boat_filled_outlined,
            '${trFor(lang, 'ship_run_button')}: '
            '${trFor(lang, 'ship_run_hint')} '
            '${trFor(lang, 'ship_run_left_hint').replaceAll('{n}', '${escapeNeeded - _battle.escape}')}',
            canAct && _battle.canRun
                ? () => setState(() {
                      _battle.runForIt();
                      _rearm();
                      if (_battle.over) _finish();
                    })
                : null,
          )
        else
          button(
            const Key('ship_pull_away'),
            Icons.keyboard_double_arrow_down,
            trFor(lang, 'ship_pull_away_button'),
            canAct && farther != null && _battle.canMoveTo(farther)
                ? () => setState(() {
                      _battle.maneuver(farther);
                      _rearm();
                    })
                : null,
          ),
      ],
    );
  }

  /// What the beast is about to do, under its name: held on the line,
  /// when it dives next, whether it is turning for the deep, what it heals
  /// a round, and the crew's edge against it.
  Widget _buildBeastStatus(AppLanguage lang) {
    final beast = widget.beast!;
    final b = _battle;
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final small = theme.textTheme.labelSmall;
    Widget chip(IconData icon, String text, Color color, String key) => Row(
          key: Key(key),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 3),
            Text(text, style: small?.copyWith(color: color)),
          ],
        );
    // Held on the line, or its fins torn, it cannot dive.
    final dive = b.tethered || b.enemy.room(ShipRoom.helm).isDown
        ? null
        : b.roundsToDive;
    final heartDown = b.enemy.room(ShipRoom.hold).isDown;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing: 10,
        runSpacing: 2,
        children: [
          if (b.beastTurning)
            chip(
                Icons.keyboard_double_arrow_down,
                trFor(lang, 'beast_status_turning'),
                ink.blood,
                'beast_turning'),
          if (b.tethered)
            chip(
                Icons.link,
                trFor(lang, 'beast_status_tethered')
                    .replaceAll('{n}', '${b.tether}'),
                ink.gold,
                'beast_tethered'),
          if (dive != null)
            chip(
                Icons.waves,
                dive == 0
                    ? trFor(lang, 'beast_status_dives_now')
                    : trFor(lang, 'beast_status_dives_in')
                        .replaceAll('{n}', '$dive'),
                dive == 0 ? ink.blood : ink.tide,
                'beast_dive'),
          if (beast.regen > 0)
            chip(
                heartDown ? Icons.heart_broken : Icons.favorite,
                heartDown || b.tethered
                    ? trFor(lang, 'beast_status_regen_stopped')
                    : trFor(lang, 'beast_status_regen')
                        .replaceAll('{n}', '${beast.regen}'),
                heartDown || b.tethered ? ink.ash : ink.blood,
                'beast_regen'),
          if (beast.edge > 0)
            chip(
                Icons.visibility,
                trFor(lang, 'beast_status_edge')
                    .replaceAll('{n}', '${beast.edge}'),
                ink.tide,
                'beast_edge'),
        ],
      ),
    );
  }

  /// A ship on one line and a bar: her name, the enemy's habit, her
  /// shields and how often she slips a shot, then her hull as planks.
  Widget _shipBar({
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
    final small = theme.textTheme.labelSmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(name,
                  style: TextStyle(
                      fontFamily: InkFonts.display, fontSize: 18, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (showHabit) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Tooltip(
                  message: trFor(lang, 'ship_habit_${habit.name}_hint'),
                  child: Container(
                    key: const Key('ship_enemy_habit'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ink.ember),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_habitIcon(habit), size: 12, color: ink.ember),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            trFor(lang, 'ship_habit_${habit.name}'),
                            style: small?.copyWith(color: ink.ember),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const Spacer(),
            for (var i = 0; i < max(ship.maxLayers, ship.layers); i++)
              Icon(
                i < ship.layers ? Icons.shield : Icons.shield_outlined,
                size: 14,
                color: steel,
              ),
            const SizedBox(width: 6),
            Tooltip(
              message: trFor(lang, 'ship_evasion_hint'),
              child: Text(
                trFor(lang, 'ship_slips_label').replaceAll('{n}', '$evasion'),
                style: small?.copyWith(color: ink.tide),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 7,
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
                style: small?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ),
      ],
    );
  }

  /// The fight from the masthead (see sea_battlefield.dart), filling the
  /// screen between the enemy's bar and the dock: the enemy above, the
  /// Eel below, broadside to broadside, the gap between them the range
  /// they lie at; the waters' own waves under them and the weather
  /// drifting over them. Each ship's rooms lie along her deck, helm at
  /// the stern to bulwark at the bow, and each is the tile that is
  /// tapped. On the water: the weather, the enemy's guns, the range with
  /// the helm's maneuvers and the last of the log (a tip shows above the
  /// dock, see build).
  Widget _buildBattlefield(AppLanguage lang) {
    final weather = widget.rules.weather ? _battle.weather : SeaWeather.calm;
    if (_shownWeather != null && _shownWeather != weather) {
      // The weather turns: a wave rolls under both ships as it does.
      _fadingWeather = _shownWeather;
      _weatherTurnedAt = _seaClock.value * _seaSeconds;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _fx.play(ShipFxKind.wave, _seaKey);
      });
    }
    _shownWeather = weather;
    final eelLook = TopShipLook.rustyEel;
    final enemyLook = TopShipLook.forEnemy(widget.enemyShipId, widget.enemy);
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = constraints.maxHeight;
      const label = 14.0;
      const top = 40.0;
      const bottom = 50.0;
      // The ships fit the sea's height as well as its width: a quarter of
      // the open water is always left for the gap between them, so the
      // range reads on a phone.
      final byHeight = max(0.0, height - top - bottom - 2 * label) *
          0.75 /
          (topShipBoxHeight(1, enemyLook) + topShipBoxHeight(1, eelLook));
      final length = min(min(width * 0.64, 260.0), byHeight);
      final left = (width - length) / 2;
      final enemyBox = topShipBoxHeight(length, enemyLook);
      final eelBox = topShipBoxHeight(length, eelLook);
      final spare =
          max(0.0, height - top - bottom - enemyBox - eelBox - 2 * label);
      // The range is how much of the open water lies between them; the
      // rest is split above and below.
      final gap = spare *
          switch (_battle.range) {
            ShipRange.close => 0.04,
            ShipRange.medium => 0.5,
            ShipRange.long => 1.0,
          };
      final slack = (spare - gap) / 2;
      final enemyTop = top + label + slack;
      final eelTop = enemyTop + enemyBox + gap;
      final enemyBand = Rect.fromLTWH(0, enemyTop, width, enemyBox);
      final middle = eelTop - gap / 2;
      const move = Duration(milliseconds: 700);
      return AnimatedBuilder(
        animation: _seaClock,
        builder: (context, _) {
          final t = _seaClock.value * _seaSeconds;
          return Stack(
            key: const Key('ship_sea_strip'),
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  key: const Key('ship_battlefield'),
                  painter: SeaSurfacePainter(
                      waters: widget.waters, weather: weather, t: t),
                ),
              ),
              // The water between the ships, where the sea's own
              // surprises break.
              AnimatedPositioned(
                duration: move,
                curve: Curves.easeInOut,
                left: 0,
                right: 0,
                top: enemyTop + enemyBox * 0.7,
                height: max(8, gap + enemyBox * 0.6),
                child:
                    KeyedSubtree(key: _seaKey, child: const SizedBox.expand()),
              ),
              if (widget.rules.range)
                AnimatedPositioned(
                  duration: move,
                  curve: Curves.easeInOut,
                  left: 6,
                  top: enemyTop + enemyBox / 2,
                  width: 18,
                  height:
                      max(20, eelTop + eelBox / 2 - (enemyTop + enemyBox / 2)),
                  child: _rangeBracket(lang),
                ),
              AnimatedPositioned(
                duration: move,
                curve: Curves.easeInOut,
                left: left,
                top: enemyTop - label,
                width: length,
                height: label,
                child: _roomLabelRow(look: enemyLook, flip: true),
              ),
              AnimatedPositioned(
                duration: move,
                curve: Curves.easeInOut,
                left: left,
                top: enemyTop,
                width: length,
                height: enemyBox,
                child: _topShip(
                    ship: _battle.enemy,
                    isPlayer: false,
                    look: enemyLook,
                    t: t),
              ),
              AnimatedPositioned(
                duration: move,
                curve: Curves.easeInOut,
                left: left,
                top: eelTop,
                width: length,
                height: eelBox,
                child: _topShip(
                    ship: _battle.player, isPlayer: true, look: eelLook, t: t),
              ),
              AnimatedPositioned(
                duration: move,
                curve: Curves.easeInOut,
                left: left,
                top: eelTop + eelBox,
                width: length,
                height: label,
                child: _roomLabelRow(look: eelLook, flip: false),
              ),
              for (final (w, opacity) in _weatherLayers(weather, t))
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: opacity,
                      child: CustomPaint(
                        painter: SeaWeatherPainter(
                          waters: widget.waters,
                          weather: w,
                          t: t,
                          enemyBand: enemyBand,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 8,
                right: 8,
                top: 8,
                child: Row(
                  children: [
                    if (widget.rules.weather) _weatherChip(lang),
                    const Spacer(),
                    Flexible(flex: 3, child: _buildEnemyWeapons()),
                  ],
                ),
              ),
              if (widget.rules.range)
                AnimatedPositioned(
                  duration: move,
                  curve: Curves.easeInOut,
                  right: 8,
                  top: max(top, middle - 47),
                  child: _rangeButtons(lang),
                ),
              if (_battle.log.isNotEmpty)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: _buildLog(context),
                ),
            ],
          );
        },
      );
    });
  }

  /// The weather to draw over the sea and how strongly: the current one,
  /// and while it turns, the last one fading out.
  List<(SeaWeather, double)> _weatherLayers(SeaWeather weather, double t) {
    final since = t - _weatherTurnedAt;
    final fading = _fadingWeather;
    // A still sea, a clock gone round or the fade done: the weather alone.
    if (fading == null ||
        !_seaClock.isAnimating ||
        since < 0 ||
        since >= _weatherFade) {
      return [(weather, 1)];
    }
    final k = since / _weatherFade;
    return [(fading, 1 - k), (weather, k)];
  }

  /// The range as a bracket down the left edge of the sea: from ship to
  /// ship, with its name.
  Widget _rangeBracket(AppLanguage lang) {
    final ink = InkColors.of(context);
    final theme = Theme.of(context);
    return Tooltip(
      message: trFor(lang, 'ship_range_${_battle.range.name}_hint'),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
                painter:
                    _BracketPainter(color: ink.gold.withValues(alpha: 0.8))),
          ),
          Center(
            child: RotatedBox(
              quarterTurns: 3,
              // Far off, or with a run under way, the turns of running
              // still needed to get away.
              child: Text(
                widget.canFlee &&
                        !_over &&
                        (_battle.range == ShipRange.long || _battle.escape > 0)
                    ? '${trFor(lang, 'ship_range_${_battle.range.name}_title')} · '
                        '${trFor(lang, 'ship_escape_label').replaceAll('{n}', '${escapeNeeded - _battle.escape}')}'
                    : trFor(lang, 'ship_range_${_battle.range.name}_title'),
                key: const Key('ship_range_label'),
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: theme.textTheme.labelSmall?.copyWith(
                    color: ink.gold,
                    fontSize: 10,
                    shadows: const [Shadow(blurRadius: 3)]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The rooms' names in a row along a ship's far side, each over its own
  /// room, in its colour.
  Widget _roomLabelRow({required TopShipLook look, required bool flip}) {
    final lang = ref.watch(appLanguageProvider);
    final theme = Theme.of(context);
    return IgnorePointer(
      child: LayoutBuilder(builder: (context, c) {
        final box = Size(c.maxWidth, topShipBoxHeight(c.maxWidth, look));
        return Stack(children: [
          for (final room in ShipRoom.values)
            Positioned(
              left: topShipRoomRect(room, box, look, flip: flip).left,
              width: topShipRoomRect(room, box, look, flip: flip).width,
              top: 0,
              bottom: 0,
              child: Center(
                child: Text(
                  _roomName(lang, room, enemy: flip, suffix: '_title')
                      .toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 9.5,
                    letterSpacing: 0.8,
                    color: _roomColor(context, room),
                    shadows: const [Shadow(blurRadius: 3)],
                  ),
                ),
              ),
            ),
        ]);
      }),
    );
  }

  /// One ship from above with her rooms as tiles on her deck. The enemy
  /// is mirrored, her bow to the left, so the two pass broadside to
  /// broadside; a ship below half her hull is battered.
  Widget _topShip({
    required ShipState ship,
    required bool isPlayer,
    required TopShipLook look,
    required double t,
  }) {
    final flip = !isPlayer;
    final sinking = _sinkingEel == isPlayer;
    final evasion = isPlayer ? _battle.playerEvasion : _battle.enemyEvasion;
    final bob = sin(t * 1.3 + (isPlayer ? 0 : 2)) * 1.5;
    return AnimatedBuilder(
      animation: _sink,
      builder: (context, child) {
        if (!sinking) return child!;
        final k = Curves.easeIn.transform(_sink.value);
        return Opacity(
          opacity: (1 - k * 0.85).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 1 - 0.25 * k,
            child: Transform.rotate(angle: 0.3 * k, child: child),
          ),
        );
      },
      child: Transform.translate(
        offset: Offset(0, bob),
        child: KeyedSubtree(
          key: _hullKeys[isPlayer],
          child: LayoutBuilder(builder: (context, c) {
            final box = Size(c.maxWidth, c.maxHeight);
            return SizedBox(
              key: Key('ship_hull_${isPlayer ? 'eel' : 'enemy'}'),
              width: box.width,
              height: box.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      key: Key('ship_sprite_${isPlayer ? 'eel' : 'enemy'}'),
                      painter: TopShipPainter(
                        look: look,
                        flip: flip,
                        facingDown: !isPlayer,
                        t: t,
                        layers: ship.layers,
                        maxLayers: ship.maxLayers,
                        battered: ship.hull * 2 < ship.maxHull,
                        down: {
                          for (final r in ShipRoom.values)
                            if (ship.room(r).isDown) r
                        },
                        burning: {
                          for (final r in ShipRoom.values)
                            if (ship.room(r).onFire) r
                        },
                        water: min(ship.leaks, 3) / 3,
                        shield: _roomColor(context, ShipRoom.bulwark),
                        foam: const Color(0xFFE6F2F4),
                        roomColors: {
                          for (final r in ShipRoom.values)
                            r: _roomColor(context, r)
                        },
                        refit: isPlayer ? ShipCutaway.refitOf(ship) : 0,
                        speed: (evasion / 22).clamp(0.0, 2.0),
                      ),
                    ),
                  ),
                  for (final room in ShipRoom.values)
                    Positioned.fromRect(
                      rect: topShipRoomRect(room, box, look, flip: flip)
                          .deflate(1.5),
                      child: KeyedSubtree(
                        key: _roomKeys[(isPlayer, room)],
                        child: _buildRoomTile(
                          ship: ship,
                          room: room,
                          isPlayer: isPlayer,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRoomTile({
    required ShipState ship,
    required ShipRoom room,
    required bool isPlayer,
  }) {
    final theme = Theme.of(context);
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
    const pipSize = 6.0;
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
      border = Colors.transparent;
      borderWidth = 1;
    }
    // The room itself is drawn on the ship (see _topShip): the tile is
    // only a frame over it, tinted when it can be fired at.
    final background = canFireHere
        ? ink.gold.withValues(alpha: aiming ? 0.22 : 0.10)
        : Colors.transparent;

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
                margin: const EdgeInsets.only(right: 2),
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
                key: Key('ship_leak_$i'), size: 13, color: ink.tide),
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
    final token = crew == null ? null : _crewToken(crew, size: 15);
    // Labels sit on small dark chips so the room's art shows around them:
    // the name at the top, the pips and marks along the bottom.
    Widget chip(Widget child) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(3),
          ),
          child: child,
        );
    // The name is written by the ship (see _roomLabelRow) and the room's
    // state painted on its deck: the tile adds who mans it at the top and
    // its pips and marks at the bottom. Each has half a tile at most: on a
    // short one (the bow's bulwark on a phone's small sea) they shrink
    // rather than spill.
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (token != null || focused)
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (token != null) token,
                  if (focused)
                    Tooltip(
                      message: trFor(lang, 'ship_focus_hint'),
                      child: Icon(Icons.center_focus_strong,
                          size: 13, color: ink.ember),
                    ),
                ],
              ),
            ),
          ),
        Flexible(
          child: Align(
            alignment: Alignment.bottomRight,
            child: FittedBox(fit: BoxFit.scaleDown, child: chip(status)),
          ),
        ),
      ],
    );
    return Tooltip(
      message: railOpen
          ? trFor(lang, 'ship_room_bulwark_open_hint')
          : _roomName(lang, room, enemy: !isPlayer, suffix: '_hint'),
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
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(2),
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

  /// The enemy's guns in the sea's corner: each its charge as a ring and
  /// its damage, and the Eel's room it means to hit when a foresight sail
  /// shows it.
  Widget _buildEnemyWeapons() {
    final theme = Theme.of(context);
    final ink = InkColors.of(context);
    final lang = ref.watch(appLanguageProvider);
    final fr = lang == AppLanguage.fr;
    final enemy = _battle.enemy;
    final small = theme.textTheme.labelSmall;
    Widget chip(ShipWeapon w) {
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
      return Tooltip(
        message: '${w.nameFor(fr)} · ${w.damage} · $note',
        child: _seaChip(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ChargeRing(
                value: w.chargeTurns <= 0 ? 1 : w.charge / w.chargeTurns,
                color: _battle.inRange(w) ? ink.blood : ink.ash,
                track: ink.seam,
                size: 18,
                child: Icon(_weaponIcon(w), size: 9, color: ink.blood),
              ),
              const SizedBox(width: 4),
              Text('${w.damage}', style: small?.copyWith(color: Colors.white)),
              if (aimAt != null) ...[
                const SizedBox(width: 3),
                Icon(Icons.south, size: 11, color: ink.blood),
                Text(trFor(lang, 'ship_room_${aimAt.name}_title'),
                    style: small?.copyWith(color: ink.blood)),
              ],
            ],
          ),
          border: aimAt != null ? ink.blood : null,
        ),
      );
    }

    final weapons = enemy.weapons;
    if (weapons.isEmpty) return const SizedBox.shrink();
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 4,
      runSpacing: 4,
      children: [for (final w in weapons) chip(w)],
    );
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
            ? ink.gold.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
              color: armed ? ink.gold : ink.seam, width: armed ? 2 : 1),
        ),
        child: InkWell(
          key: Key('ship_weapon_${w.id}'),
          borderRadius: BorderRadius.circular(10),
          onTap: enabled
              ? () => setState(() {
                    _armedWeaponId = armed ? null : w.id;
                    _selectedCrewId = null;
                    _cancelAim();
                  })
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ChargeRing(
                  value: w.chargeTurns <= 0 ? 1 : w.charge / w.chargeTurns,
                  color: ready ? ink.gold : ink.tide,
                  track: ink.seam,
                  size: 32,
                  child: Icon(_weaponIcon(w),
                      size: 15, color: ready ? ink.gold : ink.ash),
                ),
                const SizedBox(height: 3),
                Text(w.nameFor(fr),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: ready ? null : ink.ash)),
                // The shot is the weapon's own: its mark beside the damage,
                // what it does in the tooltip.
                Tooltip(
                  message: trFor(lang, 'ship_ammo_${w.ammo.name}_hint'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (w.ammo != ShipAmmo.round) ...[
                        Icon(_ammoIcon(w.ammo),
                            key: Key('ship_weapon_ammo_${w.id}'),
                            size: 11,
                            color: ready ? ink.ember : ink.ash),
                        const SizedBox(width: 3),
                      ],
                      Flexible(
                        child: Text(
                          '${w.damage} · $state',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: ready ? ink.gold : ink.ash),
                        ),
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
                  _playOrder(order);
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
    final lines = log.length > 2 ? log.sublist(log.length - 2) : log;
    final style =
        theme.textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.2);
    // The last two lines, the newest bright; the whole log a tap away.
    return Container(
      key: const Key('ship_log'),
      padding: const EdgeInsets.fromLTRB(10, 3, 0, 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines.length; i++)
                  Text(
                    _line(lines[i]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style?.copyWith(
                        color: i == lines.length - 1
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.6)),
                  ),
              ],
            ),
          ),
          IconButton(
            key: const Key('ship_log_button'),
            tooltip: trFor(lang, 'ship_log_title'),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 36, height: 30),
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

/// The range between the ships: a line from one to the other with a
/// tick at each end.
class _BracketPainter extends CustomPainter {
  const _BracketPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    final x = size.width / 2;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height * 0.3), paint);
    canvas.drawLine(
        Offset(x, size.height * 0.7), Offset(x, size.height), paint);
    canvas.drawLine(Offset(x - 5, 0), Offset(x + 5, 0), paint);
    canvas.drawLine(
        Offset(x - 5, size.height), Offset(x + 5, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _BracketPainter old) => old.color != color;
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
  return text
      .replaceAll('the The ', 'the ')
      .replaceAll('The The ', 'The ')
      // "bear the marks of The Pale Leviathan": the name's article,
      // mid-sentence.
      .replaceAllMapped(_theMidSentence, (m) => '${m.group(1)} the ');
}

final RegExp _theMidSentence = RegExp(r"([a-z,;:]) The ");

/// The color of damage that is coming but not dealt yet, the same blue
/// the dice fight uses for its preview.
const Color _previewColor = Color(0xFF42A5F5);

/// Boarders met by a hand in the hold come over the rail at this share
/// of their health.
const double holdMannedBoarderHealth = 0.75;

/// Below this share of her hull the dock tells the player to run for it:
/// a run started lower often fails, the enemy closing as she turns.
const double runWarningShare = 0.3;

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

/// How a dice fight on a deck ended (see _ShipBattlePanelState._deckFight).
enum _DeckFight { won, lost, fled }
