part of '../ship_battle_panel.dart';

/// The battle's turns: the orders, the push, the clock, the aim and the shot,
/// the boarding, the lines and flashes the fight plays. Cut out of
/// ship_battle_panel.dart with no change (setState is called as _update).
extension _ShipBattleFlow on _ShipBattlePanelState {
  void _startBattle() {
    _update(() {
      _placing = false;
      _selectedCrewId = null;
    });
    _startClock();
  }

  /// One tap on a hand's order: sent to its room if they stand elsewhere,
  /// then the order is given.
  void _useOrder(ShipCrew member) {
    final order = orderFor(member);
    if (order == null || _busy || _over || !_battle.orderWorks(member)) return;
    _update(() {
      _orderSpins[member.id] = (_orderSpins[member.id] ?? 0) + 1;
      _battle.orderFromStation(member);
      _selectedCrewId = null;
      _playOrder(order);
      _rearm();
    });
  }

  /// A hand dropped on a room of the Eel.
  void _dropCrew(String crewId, ShipRoom room) {
    if (_busy || _over) return;
    _update(() {
      _battle.station(crewId, room);
      _selectedCrewId = null;
    });
  }

  // --- Push (v1.190) --------------------------------------------------------

  /// True when a room can be pushed now: the player's turn, once a turn.
  bool get _canPushNow => !_busy && !_over && _battle.canPushAny;

  /// Pushes [room] past its limit (see ShipBattle.pushRoom): the room
  /// flashes what it did, or the strain it took.
  void _push(ShipRoom room) {
    if (_busy || _over || !_battle.canPush(room)) return;
    final lang = ref.read(appLanguageProvider);
    final logged = _battle.log.length;
    _update(() {
      _battle.pushRoom(room);
      final keys = {for (final l in _battle.log.sublist(logged)) l.key};
      final strained = keys.contains('ship_log_push_strain') ||
          keys.contains('ship_log_push_strain_fire');
      _flashText(true, room,
          trFor(lang, strained ? 'ship_push_strain_flash' : 'ship_push_flash'));
      if (!_still) {
        _fx.play(
            room == ShipRoom.bulwark ? ShipFxKind.shield : ShipFxKind.sparkles,
            _roomKeys[(true, room)]!);
        if (keys.contains('ship_log_push_strain_fire')) {
          _fx.play(ShipFxKind.ignite, _roomKeys[(true, room)]!, delay: 0.2);
        } else if (strained) {
          _fx.play(ShipFxKind.splinters, _roomKeys[(true, room)]!, delay: 0.2);
        }
      }
      // A gun the push brought to readiness is ready to fire.
      _rearm();
      _armedWeaponId ??= _firstReadyWeaponId();
    });
  }

  /// The four rooms of the Eel to push, each with what it does and the
  /// strain it risks; a tap pushes and closes the sheet.
  Future<void> _openPushSheet() {
    final lang = ref.read(appLanguageProvider);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final ink = InkColors.of(sheetContext);
        Widget row(ShipRoom room) {
          final can = _battle.canPush(room);
          final strain = _battle.pushStrainChance(room);
          final risky = strain >= 50;
          final color = _roomColor(sheetContext, room);
          return Opacity(
            opacity: can ? 1 : 0.45,
            child: InkWell(
              key: Key('ship_push_${room.name}'),
              borderRadius: BorderRadius.circular(8),
              onTap: can
                  ? () {
                      Navigator.of(sheetContext).pop();
                      _push(room);
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color),
                      ),
                      child: Icon(_roomIcon(room), size: 18, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(trFor(lang, 'ship_room_${room.name}_title'),
                              style: theme.textTheme.titleSmall),
                          Text(
                            trFor(lang, 'ship_push_${room.name}_hint')
                                .replaceAll('{n}', '$pushHullPatch'),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: ink.ash),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: trFor(lang, 'ship_push_strain_hint')
                          .replaceAll('{n}', '$strain'),
                      child: Text(
                        trFor(lang, 'ship_push_strain_label')
                            .replaceAll('{n}', '$strain'),
                        key: Key('ship_push_strain_${room.name}'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: risky ? ink.blood : ink.ash,
                          fontWeight: risky ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8),
            child: ListView(
              key: const Key('ship_push_sheet'),
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Row(
                  children: [
                    Icon(Icons.bolt, color: ink.ember, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(trFor(lang, 'ship_push_title'),
                          style: const TextStyle(
                              fontFamily: InkFonts.display, fontSize: 20)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(trFor(lang, 'ship_push_once_label'),
                    style:
                        theme.textTheme.labelSmall?.copyWith(color: ink.ash)),
                const SizedBox(height: 6),
                for (final room in ShipRoom.values) row(room),
              ],
            ),
          ),
        );
      },
    );
  }

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
  /// with the first ready gun, the enemy's intent the first time it shows
  /// more than a volley, the push, orders, fire, a leak, an open rail, the
  /// sea's surprises. One at a time; none when tutorials are off.
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
      if (b.rules.intents &&
          b.intentVisible &&
          b.intent != ShipIntent.volley &&
          !_busy)
        'ship_intent',
      if (b.rules.push && b.canPushAny && !_busy) 'ship_push',
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
    _update(() => _secondsLeft = max(0, _secondsLeft - 1));
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
    _update(() {
      _cancelAim();
      if (outcome != null) _armedWeaponId = _firstReadyWeaponId();
    });
    if (_battle.over) _finish();
  }

  void _startAim(ShipRoom room) {
    final weapon = _battle.weaponById(_armedWeaponId);
    if (_busy || _over || weapon == null || !_battle.canFire(weapon)) return;
    _update(() {
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
    _update(() {
      _battle.station(crewId, room);
      _selectedCrewId = null;
    });
  }

  Future<void> _endTurn({bool manual = false}) async {
    if (_busy || _over) return;
    final quick = manual && _quickNow;
    _clock?.cancel();
    _update(() {
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
    _update(() {});
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
      _update(() {});
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
      _update(() {});
      _finish();
      return;
    }
    _update(() {
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
    if (mounted) _update(() => _busy = true);
    final end = _battle.end;
    final sinking = end == BattleEnd.won
        ? false
        : end == BattleEnd.lost
            ? true
            : null;
    if (sinking != null && mounted && !_still) {
      // The losing ship goes down before the battle hands its result on.
      _update(() => _sinkingEel = sinking);
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
            // A boarding fight is fought on the ship deck (v1.660).
            forcedStage: FightStage.shipDeck,
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
    _update(() {
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
      _update(() => _busy = false);
      await _endTurn();
      return;
    }
    _update(_battle.boardingStarted);
    final result = await _deckFight(records);
    if (!mounted || result == null) return;
    if (result == _DeckFight.won) {
      _battle.boardingWon();
      _finish();
      return;
    }
    _update(() {
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
    _update(() {});
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return false;
    final result = await _deckFight(records,
        healthMultiplier: holdManned ? _holdMannedBoarderHealth : 1.0);
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
      _update(() => _flash(outcome, onEel: onEel));
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
        case 'ship_log_fire_spreads':
          final room = line.room;
          if (room != null) {
            _fx.play(ShipFxKind.ignite,
                _roomKeys[(line.side == BattleSide.eel, room)]!);
          }
        case 'ship_log_intent_ram_missed':
          _fx.play(ShipFxKind.splash, _seaKey);
        case 'ship_log_sail_arrives':
          _fx.play(ShipFxKind.wave, _seaKey);
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
            ? (outcome.hullDamage > 0
                ? '${trFor(lang, 'ship_blocked_label')} −${outcome.hullDamage}'
                : trFor(lang, 'ship_blocked_label'))
            : '−${outcome.hullDamage}';
    final key = (onEel, outcome.room);
    final flash = (text, ++_flashCount);
    if (outcome.landed && outcome.hullDamage > 0) {
      final pop = (outcome.hullDamage, flash.$2);
      _hullPops[onEel] = pop;
      late final Timer timer;
      timer = Timer(const Duration(milliseconds: 1600), () {
        _fxTimers.remove(timer);
        if (!mounted || _hullPops[onEel] != pop) return;
        _update(() => _hullPops.remove(onEel));
      });
      _fxTimers.add(timer);
    }
    _showFlash(key, flash);
  }

  /// A few words rising off a room of the Eel ([onEel]) or the enemy.
  void _flashText(bool onEel, ShipRoom room, String text) =>
      _showFlash((onEel, room), (text, ++_flashCount));

  void _showFlash((bool, ShipRoom) key, (String, int) flash) {
    _flashes[key] = flash;
    _flashTimers[key]?.cancel();
    _flashTimers[key] = Timer(const Duration(milliseconds: 1450), () {
      _flashTimers.remove(key);
      if (!mounted || _flashes[key] != flash) return;
      _update(() => _flashes.remove(key));
    });
  }

  /// Whether [member]'s order can be given now: once a battle, not while
  /// the enemy fires, and a grapple only with a crew to fight at the rail.
  bool _orderUsable(ShipCrew member, Map<String, dynamic>? enemies) {
    final order = orderFor(member);
    return order != null &&
        !_busy &&
        !_over &&
        _battle.orderWorks(member) &&
        (order != CrewOrder.grapple || _boardingCrew(enemies) != null);
  }
}
