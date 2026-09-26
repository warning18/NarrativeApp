import 'dart:math';

import 'ship_combat.dart';
import 'ship_combat.dart' as combat show endRound;

/// One ship battle from the first turn to the last, on top of the room
/// rules in ship_combat.dart: what makes a round more than trading shots.
///
/// - Range: the ships lie close, at medium range or far apart. Far off,
///   both are harder to hit; close in, easier. Some weapons reach only so
///   far, boarding needs the ships side by side, and the helm can close
///   in or pull away once a turn (the helm hand spends the turn on it).
/// - Weather: calm, a tailwind for the Eel, a crosswind that throws both
///   ships' aim, a squall that puts every fire out and starts none, fog
///   that hides the enemy's aim. The next round's weather shows ahead.
/// - Shot: round, chain (tears the helm), grape (cuts down the enemy's
///   crew so it repairs less) or heated (sets fires), for less hull.
/// - An aimed shot (see [aimResultFor]) and focused fire (a room already
///   hit this turn loses an extra pip) reward the player's hand.
/// - Crew orders: each crew member can give one order a battle
///   (see [orderFor]).
/// - Enemy habits (enemy_ships.json `habit`): one flees when hurt, one
///   shoots the crew, one rams, one boards again and again.
/// - Leaks: a heavy hit on the hold lets the sea in, hull every round
///   until a hand bails it.
/// - The sea itself: now and then a rogue wave, a sea creature or a
///   drifting wreck.
/// - Quick orders: a turn ended with half the clock left gives the Eel
///   a better chance to slip the volley that follows.
///
/// Deterministic given [random], so tests and the balance simulation can
/// drive whole battles; the panel (ShipBattlePanel) drives one turn at a
/// time, fights the boarding actions on the dice, and draws the [log].

enum SeaWeather { calm, tailwind, crosswind, squall, fog }

/// How often each weather comes, out of their sum.
const Map<SeaWeather, int> weatherWeights = {
  SeaWeather.calm: 40,
  SeaWeather.tailwind: 15,
  SeaWeather.crosswind: 15,
  SeaWeather.squall: 15,
  SeaWeather.fog: 15,
};

/// The weather a [roll] in [0, 1) draws.
SeaWeather weatherFor(double roll) {
  final total = weatherWeights.values.fold<int>(0, (a, b) => a + b);
  var at = roll * total;
  for (final entry in weatherWeights.entries) {
    if (at < entry.value) return entry.key;
    at -= entry.value;
  }
  return SeaWeather.calm;
}

/// The shot a gun is loaded with.
enum ShipAmmo { round, chain, grape, heated }

/// How an ammunition changes a shot: chain and grape do half the hull,
/// chain also tears a pip off the helm, heated does three quarters and
/// sets the room burning. Grape's toll on the enemy's crew is the
/// battle's (see [grapeRounds]).
ShotMods ammoMods(ShipAmmo ammo) => switch (ammo) {
      ShipAmmo.round => const ShotMods(),
      ShipAmmo.chain => const ShotMods(damageFactor: 0.5, helmPips: 1),
      ShipAmmo.grape => const ShotMods(damageFactor: 0.5),
      ShipAmmo.heated => const ShotMods(damageFactor: 0.75, ignite: true),
    };

/// What an enemy ship does beyond firing (enemy_ships.json `habit`).
enum EnemyHabit { none, flee, marksman, ram, boarder }

EnemyHabit habitFromName(String? name) {
  for (final habit in EnemyHabit.values) {
    if (habit.name == name) return habit;
  }
  return EnemyHabit.none;
}

/// A fleeing ship turns tail at this share of its hull or less.
const double fleeHullShare = 0.4;

bool isFleeing(ShipState enemy) => enemy.hull <= enemy.maxHull * fleeHullShare;

/// The range an enemy with [habit] steers for: a raider closes to grapple
/// until it is hurt, then runs; a marksman keeps its distance; a rammer
/// and a boarder come alongside.
ShipRange preferredRange(EnemyHabit habit, ShipState enemy) => switch (habit) {
      EnemyHabit.flee => isFleeing(enemy) ? ShipRange.long : ShipRange.close,
      EnemyHabit.marksman => ShipRange.long,
      EnemyHabit.ram || EnemyHabit.boarder => ShipRange.close,
      EnemyHabit.none => ShipRange.medium,
    };

/// The chance an enemy's helm steers it one range toward the one it likes
/// in a round: 30% a working helm pip, at most 90%. A slow barge drifts; a
/// sharp brig mostly holds its distance; chain shot on the helm pins it.
double enemySteerChance(ShipState enemy) =>
    min(0.9, 0.3 * enemy.room(ShipRoom.helm).working);

/// One step from [from] toward [to].
ShipRange stepToward(ShipRange from, ShipRange to) {
  if (from == to) return from;
  return ShipRange.values[from.index + (to.index > from.index ? 1 : -1)];
}

/// Far apart both ships are harder to hit; side by side, easier.
const int rangeEvasionStep = 10;

int rangeEvasion(ShipRange range) => switch (range) {
      ShipRange.close => -rangeEvasionStep,
      ShipRange.medium => 0,
      ShipRange.long => rangeEvasionStep,
    };

const int tailwindEvasion = 10;
const int crosswindEvasion = 10;
const int fogEvasion = 5;

/// A turn ended with at least half the clock left: the Eel is already
/// turning when the volley comes.
const int quickOrdersEvasion = 10;

/// However the wind and the range fall, no ship slips more than this.
const int maxBattleEvasion = 60;

/// True when the wind is behind the Eel: a tailwind, or a crosswind
/// under the Wind-Knot sail. Her helm then turns without a hand's work.
bool tailwindFor(SeaWeather weather, {bool windKnot = false}) =>
    weather == SeaWeather.tailwind ||
    (windKnot && weather == SeaWeather.crosswind);

/// Evasion the weather adds to one ship ([eel] for the player's).
int weatherEvasion(SeaWeather weather,
    {required bool eel, bool windKnot = false}) {
  if (tailwindFor(weather, windKnot: windKnot)) {
    return eel ? tailwindEvasion : 0;
  }
  return switch (weather) {
    SeaWeather.crosswind => crosswindEvasion,
    SeaWeather.fog => fogEvasion,
    _ => 0,
  };
}

/// A ship's evasion in the battle: its helm and helmsman (see
/// [evasionFor]), the range, the weather and any [bonus], from 0 to
/// [maxBattleEvasion]. A ship whose helm is knocked out slips nothing,
/// however far off or however the wind: nobody is steering her.
int battleEvasion(
  ShipState ship, {
  ShipCrew? helmsman,
  ShipRange range = ShipRange.medium,
  SeaWeather weather = SeaWeather.calm,
  required bool eel,
  bool windKnot = false,
  int bonus = 0,
}) {
  if (ship.room(ShipRoom.helm).isDown) return 0;
  return (evasionFor(ship, helmsman: helmsman) +
          rangeEvasion(range) +
          weatherEvasion(weather, eel: eel, windKnot: windKnot) +
          bonus)
      .clamp(0, maxBattleEvasion);
}

/// Where the marker stopped on the aim bar, 0 to 1: the middle is a
/// critical, the edges go wide.
enum AimResult { perfect, steady, wide }

const double aimPerfectHalfWidth = 0.12;
const double aimSteadyHalfWidth = 0.35;

AimResult aimResultFor(double position) {
  final off = (position - 0.5).abs();
  if (off <= aimPerfectHalfWidth) return AimResult.perfect;
  if (off <= aimSteadyHalfWidth) return AimResult.steady;
  return AimResult.wide;
}

/// A critical shot (a perfect aim, or Liora's eagle eye): it cannot be
/// slipped, does half again the hull and knocks an extra pip off.
const ShotMods criticalMods =
    ShotMods(damageFactor: 1.5, extraRoomDamage: 1, sure: true);

/// A room already hit this turn loses this many extra pips per hit after
/// the first.
const int focusRoomDamage = 1;

/// Rounds a grapeshot hit costs the enemy's crew a repair.
const int grapeRounds = 2;

/// One order each crew member can give once a battle.
enum CrewOrder {
  /// The player: every damaged room mends a pip.
  allHands,

  /// Kelda: the Eel takes half the hull this round.
  brace,

  /// Grosh: the ships are hauled side by side and boarded, shields or not.
  grapple,

  /// Maren: every fire out, and the crew healed.
  bless,

  /// Tobin: the bulwark mended and a layer raised.
  shoreUp,

  /// Malrik: the enemy's helmsman marked; it slips nothing this turn.
  markHelm,

  /// Sable: the enemy's rigging cut; every weapon loses a step of charge.
  cutRigging,

  /// Liora: the next shot is a critical.
  eagleEye,

  /// Vess: the next enemy shot this round is turned aside.
  voidWard,
}

const Map<String, CrewOrder> companionOrders = {
  'kelda': CrewOrder.brace,
  'grosh': CrewOrder.grapple,
  'maren': CrewOrder.bless,
  'tobin': CrewOrder.shoreUp,
  'malrik': CrewOrder.markHelm,
  'sable': CrewOrder.cutRigging,
  'liora': CrewOrder.eagleEye,
  'vess': CrewOrder.voidWard,
};

CrewOrder? orderFor(ShipCrew crew) =>
    crew.isPlayer ? CrewOrder.allHands : companionOrders[crew.id];

/// Health Maren's blessing gives each crew member.
const int blessHeal = 10;

/// What the sea throws in now and then, from the second round on.
enum BattleSeaEvent { rogueWave, seaCreature, driftingWreck }

const double seaEventChance = 0.10;
const int seaCreatureHull = 10;

/// A rammer's prow: hull through any shield, and a leak.
const int ramHullDamage = 12;

/// A boarder comes over the rail every this many rounds alongside (the
/// third, the sixth…, counted only while the ships lie side by side),
/// shields or not, this many times a battle at most.
const int boarderEvery = 3;
const int boarderMaxTries = 2;

/// A marksman's shots go for the crew.
const double marksmanInjuryFactor = 1.5;

/// Which rules are on: all of them in play; [classic] is the battle before
/// v1.153, for the balance simulation's comparison.
class ShipBattleRules {
  const ShipBattleRules({
    this.range = true,
    this.weather = true,
    this.seaEvents = true,
    this.habits = true,
    this.flooding = true,
  });

  static const classic = ShipBattleRules(
    range: false,
    weather: false,
    seaEvents: false,
    habits: false,
    flooding: false,
  );

  final bool range;
  final bool weather;
  final bool seaEvents;
  final bool habits;
  final bool flooding;
}

enum BattleEnd { won, lost, boarded, escaped }

/// Whose ship a log line is about.
enum BattleSide { eel, enemy }

/// One line of the battle log, as a string key and what fills it; the
/// panel words it in the player's language.
class BattleLine {
  const BattleLine(
    this.key, {
    this.side,
    this.weapon,
    this.room,
    this.crew,
    this.n,
    this.range,
  });

  final String key;
  final BattleSide? side;
  final ShipWeapon? weapon;
  final ShipRoom? room;
  final String? crew;
  final int? n;
  final ShipRange? range;
}

class ShipBattle {
  ShipBattle({
    required this.player,
    required this.enemy,
    required List<ShipCrew> crew,
    required this.random,
    this.boarding = const BoardingProfile(),
    this.habit = EnemyHabit.none,
    this.rules = const ShipBattleRules(),
    this.windKnot = false,
  }) : crew = List.of(crew) {
    // Everyone starts somewhere useful: the player at the helm, the next
    // hand at the guns, the next at the bulwark, the last in the hold.
    for (var i = 0; i < this.crew.length && i < ShipRoom.values.length; i++) {
      stations[ShipRoom.values[i]] = this.crew[i].id;
    }
    if (rules.weather) {
      weather = weatherFor(random.nextDouble());
      nextWeather = weatherFor(random.nextDouble());
    }
    _beginPlayerTurn();
  }

  final Random random;
  final BoardingProfile boarding;
  final EnemyHabit habit;
  final ShipBattleRules rules;

  /// The Wind-Knot sail is aboard: a crosswind is a tailwind for the Eel.
  final bool windKnot;

  ShipState player;
  ShipState enemy;
  List<ShipCrew> crew;

  /// Room -> crew id at that station.
  final Map<ShipRoom, String> stations = {};

  /// Rooms whose hand spent this turn on work (a fire, a repair, a leak,
  /// the helm's maneuver) and so is not at their station (see [crewTurn]).
  Set<ShipRoom> busyRooms = {};

  /// Enemy weapon id -> the room it will fire at next.
  final Map<String, ShipRoom> plan = {};
  final List<BattleLine> log = [];

  int turn = 1;
  ShipRange range = ShipRange.medium;
  SeaWeather weather = SeaWeather.calm;
  SeaWeather nextWeather = SeaWeather.calm;
  ShipAmmo ammo = ShipAmmo.round;

  /// Crew ids whose order is given.
  final Set<String> ordersUsed = {};
  BattleEnd? end;

  // This turn.
  bool maneuvered = false;
  bool braced = false;
  bool helmMarked = false;
  bool eagleEye = false;
  bool voidWard = false;
  bool grappled = false;
  bool quick = false;

  /// Enemy room -> shots landed in it this turn (see [focusRoomDamage]).
  final Map<ShipRoom, int> focus = {};

  // Across turns.
  bool wreck = false;
  int grapeLeft = 0;
  bool rammed = false;
  int enemyBoardTries = 0;

  /// Rounds the enemy has ended side by side with the Eel (see
  /// [boarderEvery]).
  int roundsAlongside = 0;
  bool boardingSpent = false;
  bool enemyBoardingSpent = false;
  List<ShipWeapon> _volley = const [];

  bool get over => end != null;

  // --- Crew ---------------------------------------------------------------

  ShipCrew? crewById(String? id) {
    if (id == null) return null;
    for (final c in crew) {
      if (c.id == id) return c;
    }
    return null;
  }

  Stations get stationsMap => {
        for (final entry in stations.entries)
          if (crewById(entry.value) != null) entry.key: crewById(entry.value)!,
      };

  ShipRoom? stationOf(String crewId) {
    for (final entry in stations.entries) {
      if (entry.value == crewId) return entry.key;
    }
    return null;
  }

  /// The helmsman at the helm this turn, if not busy.
  ShipCrew? get helmsman =>
      busyRooms.contains(ShipRoom.helm) ? null : stationsMap[ShipRoom.helm];

  /// Sends [crewId] to [room]; whoever stood there takes the mover's old
  /// station, if any.
  void station(String crewId, ShipRoom room) {
    if (over) return;
    final from = stationOf(crewId);
    final occupant = stations[room];
    if (from != null) stations.remove(from);
    if (occupant != null && occupant != crewId && from != null) {
      stations[from] = occupant;
    }
    stations[room] = crewId;
  }

  void autoStation() {
    stations
      ..clear()
      ..addAll({
        for (final entry in autoStations(player, crew).entries)
          entry.key: entry.value.id,
      });
  }

  bool get _holdManned =>
      stations.containsKey(ShipRoom.hold) &&
      !busyRooms.contains(ShipRoom.hold) &&
      !player.room(ShipRoom.hold).isDown;

  // --- Evasion ------------------------------------------------------------

  int get playerEvasion => battleEvasion(
        player,
        helmsman: helmsman,
        range: range,
        weather: weather,
        eel: true,
        windKnot: windKnot,
        bonus: quick ? quickOrdersEvasion : 0,
      );

  int get enemyEvasion => helmMarked
      ? 0
      : battleEvasion(
          enemy,
          range: range,
          weather: weather,
          eel: false,
          windKnot: windKnot,
        );

  // --- Turn flow ----------------------------------------------------------

  void _beginPlayerTurn() {
    maneuvered = false;
    braced = false;
    helmMarked = false;
    eagleEye = false;
    voidWard = false;
    grappled = false;
    quick = false;
    focus.clear();
    final result = crewTurn(player, stationsMap);
    player = result.ship;
    busyRooms = result.busy;
    for (final work in result.work) {
      if (work.fireOut) {
        _add('ship_log_fire_out', crew: work.crew.name, room: work.room);
      }
      if (work.leakBailed) _add('ship_log_leak_bailed', crew: work.crew.name);
      if (work.roomRepaired) {
        _add('ship_log_room_repaired', crew: work.crew.name, room: work.room);
      }
      if (work.hullRepaired > 0) {
        _add('ship_log_hull_patched',
            crew: work.crew.name, n: work.hullRepaired);
      }
    }
    player = chargeWeapons(player,
        gunnerAboard: stations.containsKey(ShipRoom.guns) &&
            !busyRooms.contains(ShipRoom.guns));
    _planEnemy();
  }

  void _planEnemy() {
    plan.clear();
    for (final weapon in enemy.weapons) {
      plan[weapon.id] = _aimFor(weapon, random.nextDouble());
    }
  }

  /// A marksman shoots the crew where it can see them (not in fog): the
  /// first manned room, helm first.
  ShipRoom _aimFor(ShipWeapon weapon, double roll) {
    if (rules.habits &&
        habit == EnemyHabit.marksman &&
        weather != SeaWeather.fog) {
      for (final room in ShipRoom.values) {
        if (stations.containsKey(room)) return room;
      }
    }
    return enemyTargetFor(player, weapon, roll);
  }

  /// True when the enemy's aim can be read this turn (fog hides it).
  bool get aimVisible => weather != SeaWeather.fog;

  // --- The player's turn --------------------------------------------------

  ShipWeapon? weaponById(String? id) {
    for (final w in player.weapons) {
      if (w.id == id) return w;
    }
    return null;
  }

  bool inRange(ShipWeapon weapon) => !rules.range || weapon.reaches(range);

  bool canFire(ShipWeapon weapon) => !over && weapon.isReady && inRange(weapon);

  /// What the loaded shot, the room's focus and a pending critical do to a
  /// shot at [room].
  ShotMods shotMods(ShipRoom room, {AimResult? aim}) {
    var mods = ammoMods(ammo);
    if (weather == SeaWeather.squall) {
      mods = mods.merge(const ShotMods(noFire: true));
    }
    if ((focus[room] ?? 0) > 0) {
      mods = mods.merge(const ShotMods(extraRoomDamage: focusRoomDamage));
    }
    if (eagleEye || aim == AimResult.perfect) mods = mods.merge(criticalMods);
    if (!rules.flooding) mods = mods.merge(const ShotMods(floods: false));
    return mods;
  }

  /// What [weaponId] would do to [room] if it lands, for the room's preview.
  ShotOutcome? preview(String? weaponId, ShipRoom room) {
    final weapon = weaponById(weaponId);
    if (weapon == null) return null;
    return previewShot(
        target: enemy, weapon: weapon, room: room, mods: shotMods(room));
  }

  /// Fires [weaponId] at [room] of the enemy with the loaded shot. [aim]
  /// is where an aimed shot's marker stopped (null for a plain shot): a
  /// perfect aim is a critical, a wide one misses outright.
  ShotOutcome? fire(String weaponId, ShipRoom room, {AimResult? aim}) {
    final weapon = weaponById(weaponId);
    if (weapon == null || !canFire(weapon)) return null;
    player = player.withWeapon(weapon.fired());
    if (aim == AimResult.wide) {
      _add('ship_log_shot_wide', weapon: weapon);
      return ShotOutcome(target: enemy, room: room, dodged: true);
    }
    final critical = eagleEye || aim == AimResult.perfect;
    final focused = (focus[room] ?? 0) > 0;
    final outcome = resolveShot(
      target: enemy,
      weapon: weapon,
      room: room,
      evasionPercent: enemyEvasion,
      roll: random.nextDouble(),
      mods: shotMods(room, aim: aim),
    );
    eagleEye = false;
    enemy = outcome.target;
    if (outcome.landed && critical) _add('ship_log_critical');
    if (outcome.landed && focused) _add('ship_log_focus', room: room);
    _logShot(outcome, weapon, BattleSide.enemy);
    if (outcome.landed) {
      focus[room] = (focus[room] ?? 0) + 1;
      if (ammo == ShipAmmo.grape) {
        grapeLeft = grapeRounds;
        _add('ship_log_grape', side: BattleSide.enemy);
      }
    }
    if (!enemy.isAfloat) _finish(BattleEnd.won);
    return outcome;
  }

  /// True while the helm can close in or pull away this turn: a working
  /// helm with a hand at it (or the wind behind her), once a turn.
  bool get canManeuver =>
      rules.range &&
      !over &&
      !maneuvered &&
      !player.room(ShipRoom.helm).isDown &&
      (helmsman != null || tailwindFor(weather, windKnot: windKnot));

  bool canMoveTo(ShipRange to) =>
      canManeuver && (to.index - range.index).abs() == 1;

  /// Closes in or pulls away one range. The helm hand spends the turn on
  /// it (no helmsman's evasion) unless the wind is behind the Eel.
  void maneuver(ShipRange to) {
    if (!canMoveTo(to)) return;
    final closing = to.index < range.index;
    range = to;
    maneuvered = true;
    if (!tailwindFor(weather, windKnot: windKnot)) {
      busyRooms = {...busyRooms, ShipRoom.helm};
    }
    _add(closing ? 'ship_log_close_in' : 'ship_log_pull_away',
        side: BattleSide.eel, range: to);
  }

  // --- Orders -------------------------------------------------------------

  /// True when a weapon can fire this turn.
  bool get anyShotReady => player.weapons.any(canFire);

  /// True when [member]'s order can be given now and would do something.
  /// Liora's eagle eye and Malrik's mark wait for a turn a weapon can
  /// fire: spent on a silent turn they would do nothing.
  bool canOrder(ShipCrew member) {
    final order = orderFor(member);
    if (order == null || over || ordersUsed.contains(member.id)) return false;
    return switch (order) {
      CrewOrder.allHands => player.rooms.values.any((r) => r.damage > 0),
      CrewOrder.brace => !braced,
      CrewOrder.grapple => boarding.canBoard && !boardingSpent && !grappled,
      CrewOrder.bless => player.rooms.values.any((r) => r.onFire) ||
          crew.any((c) => c.health < c.maxHealth),
      CrewOrder.shoreUp => player.room(ShipRoom.bulwark).damage > 0 ||
          player.layers < player.maxLayers,
      CrewOrder.markHelm => !helmMarked && anyShotReady,
      CrewOrder.cutRigging => enemy.weapons.any((w) => w.charge > 0),
      CrewOrder.eagleEye => !eagleEye && anyShotReady,
      CrewOrder.voidWard => !voidWard,
    };
  }

  void giveOrder(ShipCrew member) {
    if (!canOrder(member)) return;
    final order = orderFor(member)!;
    ordersUsed.add(member.id);
    switch (order) {
      case CrewOrder.allHands:
        player = player.copyWith(rooms: {
          for (final entry in player.rooms.entries)
            entry.key: entry.value.copyWith(damage: entry.value.damage - 1),
        });
      case CrewOrder.brace:
        braced = true;
      case CrewOrder.grapple:
        grappled = true;
        if (rules.range) range = ShipRange.close;
      case CrewOrder.bless:
        player = player.copyWith(rooms: {
          for (final entry in player.rooms.entries)
            entry.key: entry.value.copyWith(onFire: false),
        });
        crew = [for (final c in crew) c.withHealth(c.health + blessHeal)];
      case CrewOrder.shoreUp:
        final bulwark = player.room(ShipRoom.bulwark);
        player = player.withRoom(ShipRoom.bulwark, bulwark.copyWith(damage: 0));
        player =
            player.copyWith(layers: min(player.maxLayers, player.layers + 1));
      case CrewOrder.markHelm:
        helmMarked = true;
      case CrewOrder.cutRigging:
        enemy = enemy.copyWith(weapons: [
          for (final w in enemy.weapons) w.withCharge(w.charge - 1),
        ]);
      case CrewOrder.eagleEye:
        eagleEye = true;
      case CrewOrder.voidWard:
        voidWard = true;
    }
    _add('ship_order_log_${order.name}', crew: member.name);
  }

  // --- Boarding them ------------------------------------------------------

  /// True when the player can board: the enemy has a crew to fight, no
  /// try spent, and either Grosh's grapple is fast or the ships lie side by
  /// side with the enemy's rail open.
  bool get canBoardThem =>
      !over &&
      !boardingSpent &&
      boarding.canBoard &&
      (grappled ||
          ((!rules.range || range == ShipRange.close) && bulwarkOpen(enemy)));

  /// Throws the grapples; true when they hold (always, after a grapple
  /// order). A ship that still steers may slip them.
  bool throwGrapples() {
    if (grappled) return true;
    final hold = grapplesHold(enemy, random.nextDouble());
    if (!hold) _add('ship_log_grapple_slipped', side: BattleSide.enemy);
    return hold;
  }

  void boardingStarted() =>
      _add('ship_log_boarding_start', side: BattleSide.enemy);

  void boardingWon() {
    _add('ship_log_boarding_won', side: BattleSide.enemy);
    _finish(BattleEnd.boarded);
  }

  void boardingLost() {
    final before = player.hull;
    player = boardingRepelled(player);
    boardingSpent = true;
    grappled = false;
    _add('ship_log_boarding_repelled',
        side: BattleSide.enemy, n: before - player.hull);
  }

  // --- The enemy's turn ---------------------------------------------------

  /// The enemy's turn up to its volley: a fleeing ship already far off
  /// escapes; its crew works (less after grapeshot); its guns charge; its
  /// helm may steer it a range toward the one it likes (see
  /// [enemySteerChance]); a rammer rams. [quickOrders]:
  /// the player ended the turn with half the clock left.
  void startEnemyPhase({bool quickOrders = false}) {
    if (over) return;
    quick = quickOrders;
    if (quick) _add('ship_log_quick_orders', n: quickOrdersEvasion);
    final steers = !enemy.room(ShipRoom.helm).isDown;
    if (rules.habits &&
        rules.range &&
        habit == EnemyHabit.flee &&
        isFleeing(enemy) &&
        range == ShipRange.long &&
        steers) {
      _add('ship_log_escaped', side: BattleSide.enemy);
      _finish(BattleEnd.escaped);
      return;
    }
    final maintenance = enemyMaintenance(enemy, penalty: grapeLeft > 0 ? 1 : 0);
    enemy = maintenance.ship;
    for (final room in maintenance.firesOut) {
      _add('ship_log_enemy_fire_out', side: BattleSide.enemy, room: room);
    }
    if (maintenance.leaksPlugged > 0) {
      _add('ship_log_enemy_leak_plugged', side: BattleSide.enemy);
    }
    for (final room in maintenance.repaired) {
      _add('ship_log_enemy_repairs', side: BattleSide.enemy, room: room);
    }
    enemy = chargeWeapons(enemy);
    if (rules.range && steers) {
      final want =
          rules.habits ? preferredRange(habit, enemy) : ShipRange.medium;
      if (want != range && random.nextDouble() < enemySteerChance(enemy)) {
        final to = stepToward(range, want);
        _add(
            to.index < range.index
                ? 'ship_log_enemy_closes'
                : 'ship_log_enemy_pulls_away',
            side: BattleSide.enemy,
            range: to);
        range = to;
      }
    }
    if (rules.habits &&
        habit == EnemyHabit.ram &&
        !rammed &&
        range == ShipRange.close &&
        steers) {
      rammed = true;
      final damage = scaledDamage(ramHullDamage, braced ? 0.5 : 1.0);
      player = player.copyWith(
        hull: max(0, player.hull - damage),
        leaks: rules.flooding ? player.leaks + 1 : player.leaks,
      );
      _add('ship_log_rammed', side: BattleSide.enemy, n: damage);
      if (!player.isAfloat) {
        _finish(BattleEnd.lost);
        return;
      }
    }
    _volley = [
      for (final w in enemy.weapons)
        if (w.isReady && inRange(w)) w,
    ];
  }

  /// The enemy weapons that fire this round, in order (see [fireEnemy]).
  List<ShipWeapon> get enemyVolley => List.unmodifiable(_volley);

  /// One enemy weapon fires at the room it aimed at. Vess's ward or a
  /// drifting wreck takes the first shot; Kelda's brace halves the hull.
  /// Returns null when nothing landed on the Eel's side to show.
  ShotOutcome? fireEnemy(ShipWeapon weapon) {
    if (over) return null;
    ShipWeapon? current;
    for (final w in enemy.weapons) {
      if (w.id == weapon.id) current = w;
    }
    if (current == null || !current.isReady) return null;
    enemy = enemy.withWeapon(current.fired());
    if (voidWard) {
      voidWard = false;
      _add('ship_log_warded', weapon: current);
      return null;
    }
    if (wreck) {
      wreck = false;
      _add('ship_log_wreck_hit', weapon: current);
      return null;
    }
    final room = plan[current.id] ?? _aimFor(current, random.nextDouble());
    final outcome = resolveShot(
      target: player,
      weapon: current,
      room: room,
      evasionPercent: playerEvasion,
      roll: random.nextDouble(),
      mods: ShotMods(
        damageFactor: braced ? 0.5 : 1.0,
        noFire: weather == SeaWeather.squall,
        floods: rules.flooding,
      ),
    );
    player = outcome.target;
    _logShot(outcome, current, BattleSide.eel);
    if (outcome.landed) {
      final hurt = crewById(stations[room]);
      if (hurt != null) {
        final factor = rules.habits && habit == EnemyHabit.marksman
            ? marksmanInjuryFactor
            : 1.0;
        final injury = (crewInjuryFor(current) * factor).round();
        crew = [
          for (final c in crew)
            c.id == hurt.id ? c.withHealth(c.health - injury) : c,
        ];
        _add('ship_log_crew_hurt', crew: hurt.name, room: room, n: injury);
      }
    }
    if (!player.isAfloat) _finish(BattleEnd.lost);
    return outcome;
  }

  /// The enemy's try at the Eel's rail after its volley: null when it does
  /// not come; otherwise whether a hand in the hold meets the boarders.
  /// They need the ships side by side and the Eel's rail open, and try
  /// once; a boarder comes every few rounds alongside whatever the rail.
  bool? enemyBoards() {
    if (over || !boarding.canBoard) return null;
    if (rules.range && range != ShipRange.close) return null;
    roundsAlongside++;
    final tries = enemyBoardTries + (enemyBoardingSpent ? 1 : 0);
    final eager = rules.habits &&
        habit == EnemyHabit.boarder &&
        roundsAlongside % boarderEvery == 0 &&
        tries < boarderMaxTries;
    if (eager) {
      enemyBoardTries++;
    } else {
      if (enemyBoardingSpent ||
          tries >= boarderMaxTries ||
          !bulwarkOpen(player) ||
          random.nextDouble() >= boarding.chance) {
        return null;
      }
      enemyBoardingSpent = true;
    }
    _add('ship_log_boarders', side: BattleSide.enemy);
    return _holdManned;
  }

  void boardersRepelled() => _add('ship_log_boarders_repelled');

  void boardersWon() {
    final before = player.hull;
    player = boardersWreck(player);
    _add('ship_log_boarders_won', n: before - player.hull);
  }

  /// The end of the round: fires burn (or the squall puts them out), leaks
  /// flood, bulwarks come back; then the sea may throw something in, the
  /// weather moves on and the next turn begins.
  void endRound() {
    if (over) return;
    final rain = weather == SeaWeather.squall;
    final mine = combat.endRound(player,
        bulwarkCrewed: stations.containsKey(ShipRoom.bulwark) &&
            !busyRooms.contains(ShipRoom.bulwark),
        rain: rain);
    player = mine.ship;
    _roundLines(mine, BattleSide.eel);
    final theirs = combat.endRound(enemy, rain: rain);
    enemy = theirs.ship;
    _roundLines(theirs, BattleSide.enemy);
    if (!player.isAfloat) {
      _finish(BattleEnd.lost);
      return;
    }
    if (!enemy.isAfloat) {
      _finish(BattleEnd.won);
      return;
    }
    if (grapeLeft > 0) grapeLeft--;
    _seaEvent();
    if (rules.weather) {
      final was = weather;
      weather = nextWeather;
      nextWeather = weatherFor(random.nextDouble());
      if (weather != was) _add('ship_log_weather_${weather.name}');
    }
    turn++;
    _beginPlayerTurn();
  }

  void _roundLines(
      ({
        ShipState ship,
        List<ShipRoom> burned,
        List<ShipRoom> quenched,
        int flooded
      }) result,
      BattleSide side) {
    if (result.quenched.isNotEmpty) _add('ship_log_squall_quench', side: side);
    for (final room in result.burned) {
      _add('ship_log_fire_burns', side: side, room: room);
    }
    if (result.flooded > 0) {
      _add('ship_log_flooding', side: side, n: result.flooded);
    }
  }

  void _seaEvent() {
    if (!rules.seaEvents || turn < 2) return;
    if (random.nextDouble() >= seaEventChance) return;
    final kind =
        BattleSeaEvent.values[random.nextInt(BattleSeaEvent.values.length)];
    switch (kind) {
      case BattleSeaEvent.rogueWave:
        player = player.copyWith(layers: max(0, player.layers - 1));
        enemy = enemy.copyWith(layers: max(0, enemy.layers - 1));
        _add('ship_event_rogue_wave');
      case BattleSeaEvent.seaCreature:
        // It goes for the ship lower in the water.
        final eelRatio = player.hull / max(1, player.maxHull);
        final theirRatio = enemy.hull / max(1, enemy.maxHull);
        final side = eelRatio < theirRatio ? BattleSide.eel : BattleSide.enemy;
        ShipState bitten(ShipState ship) {
          final hold = ship.room(ShipRoom.hold);
          return ship
              .withRoom(ShipRoom.hold, hold.copyWith(damage: hold.damage + 1))
              .copyWith(hull: max(1, ship.hull - seaCreatureHull));
        }
        if (side == BattleSide.eel) {
          final before = player.hull;
          player = bitten(player);
          _add('ship_event_sea_creature', side: side, n: before - player.hull);
        } else {
          final before = enemy.hull;
          enemy = bitten(enemy);
          _add('ship_event_sea_creature', side: side, n: before - enemy.hull);
        }
      case BattleSeaEvent.driftingWreck:
        wreck = true;
        _add('ship_event_wreck');
    }
  }

  /// Adds a line the panel writes itself (the clock running out).
  void note(BattleLine line) => log.add(line);

  void _finish(BattleEnd how) {
    end ??= how;
  }

  void _logShot(ShotOutcome outcome, ShipWeapon weapon, BattleSide target) {
    if (outcome.dodged) {
      _add('ship_log_shot_dodged', side: target, weapon: weapon);
      return;
    }
    if (outcome.absorbed) {
      _add('ship_log_shot_absorbed', side: target, weapon: weapon);
      if (outcome.roomKnockedOut) {
        _add('ship_log_room_down', side: target, room: ShipRoom.bulwark);
      }
      return;
    }
    _add('ship_log_shot_hits',
        side: target,
        weapon: weapon,
        room: outcome.room,
        n: outcome.hullDamage);
    if (outcome.fireStarted) {
      _add('ship_log_fire_started', side: target, room: outcome.room);
    }
    if (outcome.roomKnockedOut) {
      _add('ship_log_room_down', side: target, room: outcome.room);
    }
    if (outcome.helmDamage > 0) {
      _add('ship_log_rigging_torn', side: target);
    }
    if (outcome.helmKnockedOut) {
      _add('ship_log_room_down', side: target, room: ShipRoom.helm);
    }
    if (outcome.leakOpened) _add('ship_log_leak', side: target);
  }

  void _add(
    String key, {
    BattleSide? side,
    ShipWeapon? weapon,
    ShipRoom? room,
    String? crew,
    int? n,
    ShipRange? range,
  }) =>
      log.add(BattleLine(key,
          side: side,
          weapon: weapon,
          room: room,
          crew: crew,
          n: n,
          range: range));
}
