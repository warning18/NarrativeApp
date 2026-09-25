import 'dart:math';

/// Pure, RNG-free rules for the Rusty Eel: fitting parts into her slots,
/// and the room-by-room ship battle a voyage's raider event opens (see
/// ShipBattlePanel and VoyageScreen).
///
/// A ship is a hull behind a bulwark of shield layers, with four rooms
/// that each run one system: the Helm (evasion), the Guns (weapon
/// charge), the Bulwark (shield layers and their regen) and the Hold
/// (repairs, and where the crew shelters). Weapons charge over turns and
/// fire at a room of the enemy's ship; a hit damages the hull and knocks
/// pips off that room's system, and an incendiary one sets it burning.
/// Crew stand in rooms: a helmsman adds evasion, a gunner charge, a
/// bulwark hand a layer a round, a hold hand hull repairs, and anyone
/// repairs the room they stand in and fights its fire. The enemy's crew
/// is abstracted into one repair or one fire fought per round.
///
/// Everything here is deterministic given the `roll`s passed in, so the
/// Python simulator can mirror it exactly and the tests can pin it.

/// The four rooms of any ship, in the order they are drawn.
enum ShipRoom { helm, guns, bulwark, hold }

/// Shield layers are capped here whatever the bulwark's level.
const int maxShieldLayers = 3;

/// Evasion percent per working Helm pip.
const int evasionPerHelmLevel = 8;

/// No ship, however light and however well helmed, slips more than this.
const int maxEvasionPercent = 45;

/// Hull lost per burning room at the end of every round.
const int fireHullDamagePerRound = 3;

/// The share of a landed shot's damage its room's crew member takes.
const double crewInjuryShare = 0.5;

/// One room's system: [level] pips, [damage] of them knocked out, and
/// whether it is burning. A room at zero working pips is knocked out.
class RoomState {
  const RoomState({required this.level, this.damage = 0, this.onFire = false});

  final int level;
  final int damage;
  final bool onFire;

  int get working => max(0, level - damage);
  bool get isDown => working == 0;

  RoomState copyWith({int? level, int? damage, bool? onFire}) {
    final newLevel = level ?? this.level;
    return RoomState(
      level: newLevel,
      damage: (damage ?? this.damage).clamp(0, newLevel),
      onFire: onFire ?? this.onFire,
    );
  }
}

/// A weapon aboard a ship: what it does to the room it hits, how many
/// turns it takes to charge, and how far along that charge it is.
class ShipWeapon {
  const ShipWeapon({
    required this.id,
    required this.name,
    required this.nameFr,
    required this.damage,
    required this.chargeTurns,
    this.piercing = false,
    this.incendiary = false,
    this.roomDamage = 1,
    this.charge = 0,
  });

  /// A player weapon off its ship_parts.json record; [damageBonus] is the
  /// painted sail's extra on its own volley (see sail_powers.dart).
  factory ShipWeapon.fromPart(String partId, Map<String, dynamic> part,
      {int damageBonus = 0}) {
    final cooldown = (part['cooldownTurns'] as num?)?.toInt() ?? 0;
    return ShipWeapon(
      id: partId,
      name: part['partName']?.toString() ?? partId,
      nameFr: part['partName_fr']?.toString() ?? '',
      damage: ((part['damageAmount'] as num?)?.toInt() ?? 0) + damageBonus,
      chargeTurns:
          max(1, (part['chargeTurns'] as num?)?.toInt() ?? (cooldown + 1)),
      piercing: part['piercesShield'] == true,
      incendiary: part['setsFire'] == true,
      roomDamage: max(1, (part['roomDamage'] as num?)?.toInt() ?? 1),
    );
  }

  /// An enemy weapon off one entry of its ship's `weapons` list.
  factory ShipWeapon.fromRecord(Map<String, dynamic> raw, int index) =>
      ShipWeapon(
        id: 'enemy_weapon_$index',
        name: raw['weaponName']?.toString() ?? 'Guns',
        nameFr: raw['weaponName_fr']?.toString() ?? '',
        damage: (raw['damage'] as num?)?.toInt() ?? 0,
        chargeTurns: max(1, (raw['chargeTurns'] as num?)?.toInt() ?? 1),
        piercing: raw['piercesShield'] == true,
        incendiary: raw['setsFire'] == true,
        roomDamage: max(1, (raw['roomDamage'] as num?)?.toInt() ?? 1),
      );

  final String id;
  final String name;
  final String nameFr;
  final int damage;
  final int chargeTurns;

  /// Ignores shield layers entirely.
  final bool piercing;

  /// Sets the room it lands in burning.
  final bool incendiary;

  /// System pips knocked off the room it lands in.
  final int roomDamage;

  /// Charge so far, 0 to [chargeTurns].
  final int charge;

  bool get isReady => charge >= chargeTurns;

  String nameFor(bool french) => french && nameFr.isNotEmpty ? nameFr : name;

  ShipWeapon withCharge(int value) => ShipWeapon(
        id: id,
        name: name,
        nameFr: nameFr,
        damage: damage,
        chargeTurns: chargeTurns,
        piercing: piercing,
        incendiary: incendiary,
        roomDamage: roomDamage,
        charge: value.clamp(0, chargeTurns),
      );

  ShipWeapon fired() => withCharge(0);
}

/// One ship in a battle.
class ShipState {
  const ShipState({
    required this.hull,
    required this.maxHull,
    required this.layers,
    required this.rooms,
    required this.weapons,
    this.repairsPerRound = 1,
  });

  final int hull;
  final int maxHull;

  /// How many repairs (or fires fought) an enemy ship's crew manages
  /// between volleys (see [enemyMaintenance]); the Eel's crew are real.
  final int repairsPerRound;

  /// Shield layers up right now, each stopping one non-piercing shot.
  final int layers;
  final Map<ShipRoom, RoomState> rooms;
  final List<ShipWeapon> weapons;

  bool get isAfloat => hull > 0;

  RoomState room(ShipRoom which) => rooms[which] ?? const RoomState(level: 0);

  /// Layers the bulwark can hold right now: its working pips.
  int get maxLayers => min(maxShieldLayers, room(ShipRoom.bulwark).working);

  /// Evasion from the helm alone (see [evasionFor] for the helmsman's).
  int get baseEvasion =>
      min(maxEvasionPercent, room(ShipRoom.helm).working * evasionPerHelmLevel);

  ShipState copyWith({
    int? hull,
    int? layers,
    Map<ShipRoom, RoomState>? rooms,
    List<ShipWeapon>? weapons,
  }) =>
      ShipState(
        hull: hull ?? this.hull,
        maxHull: maxHull,
        layers: layers ?? this.layers,
        rooms: rooms ?? this.rooms,
        weapons: weapons ?? this.weapons,
        repairsPerRound: repairsPerRound,
      );

  ShipState withRoom(ShipRoom which, RoomState state) =>
      copyWith(rooms: {...rooms, which: state});

  ShipState withWeapon(ShipWeapon weapon) => copyWith(weapons: [
        for (final w in weapons) w.id == weapon.id ? weapon : w,
      ]);
}

/// One crew member aboard the Eel: the player or an active companion,
/// with the stats the stations read and the health a hit costs.
class ShipCrew {
  const ShipCrew({
    required this.id,
    required this.name,
    required this.strength,
    required this.dexterity,
    required this.constitution,
    required this.wisdom,
    required this.health,
    required this.maxHealth,
    this.isPlayer = false,
  });

  final String id;
  final String name;
  final int strength;
  final int dexterity;
  final int constitution;
  final int wisdom;
  final int health;
  final int maxHealth;
  final bool isPlayer;

  ShipCrew withHealth(int value) => ShipCrew(
        id: id,
        name: name,
        strength: strength,
        dexterity: dexterity,
        constitution: constitution,
        wisdom: wisdom,
        health: value.clamp(1, maxHealth),
        maxHealth: maxHealth,
        isPlayer: isPlayer,
      );
}

/// Where the crew stand: at most one member per room.
typedef Stations = Map<ShipRoom, ShipCrew>;

/// A helmsman's evasion on top of the helm's own: a nimble one adds more.
int crewEvasionBonus(ShipCrew crew) =>
    (5 + max(0, crew.dexterity) ~/ 2).clamp(5, 15);

/// Hull a hold hand patches per turn: more with a working hold and a
/// steady head; nothing from a knocked-out hold.
int crewHullRepair(ShipCrew crew, int holdWorking) => holdWorking <= 0
    ? 0
    : (2 * holdWorking + max(0, crew.wisdom) ~/ 3).clamp(2, 10);

/// What a shot that lands in a crewed room costs the crew member there.
int crewInjuryFor(ShipWeapon weapon) =>
    max(3, (weapon.damage * crewInjuryShare).round());

/// A ship's evasion percent this turn: the helm's pips plus its helmsman,
/// none of it from a knocked-out helm.
int evasionFor(ShipState ship, {ShipCrew? helmsman}) {
  final helm = ship.room(ShipRoom.helm);
  if (helm.isDown) return 0;
  var evasion = helm.working * evasionPerHelmLevel;
  if (helmsman != null) evasion += crewEvasionBonus(helmsman);
  return min(maxEvasionPercent, evasion);
}

/// How one shot ended.
class ShotOutcome {
  const ShotOutcome({
    required this.target,
    required this.room,
    this.dodged = false,
    this.absorbed = false,
    this.hullDamage = 0,
    this.roomDamage = 0,
    this.fireStarted = false,
    this.roomKnockedOut = false,
  });

  final ShipState target;
  final ShipRoom room;
  final bool dodged;
  final bool absorbed;
  final int hullDamage;
  final int roomDamage;
  final bool fireStarted;
  final bool roomKnockedOut;

  bool get landed => !dodged && !absorbed;
}

/// One weapon fired at [room] of [target]. The helm's evasion is rolled
/// first ([roll] in [0, 1)); then a shield layer stops a non-piercing shot,
/// though the blow still cracks a pip off the bulwark behind it; a shot
/// that gets through costs hull and knocks pips off the room it lands in,
/// and an incendiary one leaves it burning.
ShotOutcome resolveShot({
  required ShipState target,
  required ShipWeapon weapon,
  required ShipRoom room,
  required int evasionPercent,
  required double roll,
}) {
  if (roll * 100 < evasionPercent) {
    return ShotOutcome(target: target, room: room, dodged: true);
  }
  if (!weapon.piercing && target.layers > 0) {
    final bulwark = target.room(ShipRoom.bulwark);
    final cracked = bulwark.copyWith(damage: bulwark.damage + 1);
    var next = target
        .copyWith(layers: target.layers - 1)
        .withRoom(ShipRoom.bulwark, cracked);
    next = next.copyWith(layers: min(next.layers, next.maxLayers));
    return ShotOutcome(
      target: next,
      room: room,
      absorbed: true,
      roomDamage: cracked.damage - bulwark.damage,
      roomKnockedOut: !bulwark.isDown && cracked.isDown,
    );
  }
  final before = target.room(room);
  final after = before.copyWith(
    damage: before.damage + weapon.roomDamage,
    onFire: before.onFire || weapon.incendiary,
  );
  var next = target
      .copyWith(hull: max(0, target.hull - weapon.damage))
      .withRoom(room, after);
  next = next.copyWith(layers: min(next.layers, next.maxLayers));
  return ShotOutcome(
    target: next,
    room: room,
    hullDamage: target.hull - next.hull,
    roomDamage: after.damage - before.damage,
    fireStarted: weapon.incendiary && !before.onFire,
    roomKnockedOut: !before.isDown && after.isDown,
  );
}

/// Charges every weapon one step while the guns work, then hands the
/// guns' extra pips (and a gunner's) to the heaviest weapon still
/// charging. Knocked-out guns charge nothing.
ShipState chargeWeapons(ShipState ship, {bool gunnerAboard = false}) {
  final guns = ship.room(ShipRoom.guns);
  if (guns.isDown) return ship;
  var weapons = [for (final w in ship.weapons) w.withCharge(w.charge + 1)];
  var extra = (guns.working - 1) + (gunnerAboard ? 1 : 0);
  while (extra > 0) {
    ShipWeapon? heaviest;
    for (final w in weapons) {
      if (w.isReady) continue;
      if (heaviest == null ||
          w.chargeTurns > heaviest.chargeTurns ||
          (w.chargeTurns == heaviest.chargeTurns &&
              w.damage > heaviest.damage)) {
        heaviest = w;
      }
    }
    if (heaviest == null) break;
    final target = heaviest;
    weapons = [
      for (final w in weapons)
        w.id == target.id ? w.withCharge(w.charge + 1) : w,
    ];
    extra--;
  }
  return ship.copyWith(weapons: weapons);
}

/// What a room's crew member did at the start of the turn.
class CrewWork {
  const CrewWork({
    required this.crew,
    required this.room,
    this.fireOut = false,
    this.roomRepaired = false,
    this.hullRepaired = 0,
  });

  final ShipCrew crew;
  final ShipRoom room;
  final bool fireOut;
  final bool roomRepaired;
  final int hullRepaired;
}

/// The Eel's crew at their stations, at the start of the player's turn:
/// each puts out the fire in their room or, if it isn't burning, repairs
/// one pip of it, and either takes the turn, so that hand is [busy] and
/// not at their station until the next one (no helmsman's evasion, no
/// gunner's charge, no bulwark hand's layer). A hold hand whose room is
/// sound patches the hull instead. Returns the ship, what each of them
/// did, and the rooms whose hands are busy.
({ShipState ship, List<CrewWork> work, Set<ShipRoom> busy}) crewTurn(
    ShipState ship, Stations stations) {
  var next = ship;
  final work = <CrewWork>[];
  final busy = <ShipRoom>{};
  for (final entry in stations.entries) {
    final room = entry.key;
    final crew = entry.value;
    final state = next.room(room);
    if (state.onFire) {
      next = next.withRoom(room, state.copyWith(onFire: false));
      work.add(CrewWork(crew: crew, room: room, fireOut: true));
      busy.add(room);
      continue;
    }
    if (state.damage > 0) {
      next = next.withRoom(room, state.copyWith(damage: state.damage - 1));
      work.add(CrewWork(crew: crew, room: room, roomRepaired: true));
      busy.add(room);
      continue;
    }
    if (room == ShipRoom.hold) {
      final hull = min(next.maxHull - next.hull,
          crewHullRepair(crew, next.room(ShipRoom.hold).working));
      if (hull > 0) {
        next = next.copyWith(hull: next.hull + hull);
        work.add(CrewWork(crew: crew, room: room, hullRepaired: hull));
      }
    }
  }
  return (ship: next, work: work, busy: busy);
}

/// What the enemy's crew did between volleys: fires fought and pips
/// repaired, [ShipState.repairsPerRound] actions in all, on the rooms
/// that matter most first.
class EnemyMaintenance {
  const EnemyMaintenance({
    required this.ship,
    this.firesOut = const [],
    this.repaired = const [],
  });

  final ShipState ship;
  final List<ShipRoom> firesOut;
  final List<ShipRoom> repaired;
}

/// The order the enemy's crew tends its rooms in: its guns before all,
/// since a silenced ship is a lost one.
const List<ShipRoom> enemyRepairPriority = [
  ShipRoom.guns,
  ShipRoom.bulwark,
  ShipRoom.helm,
  ShipRoom.hold,
];

EnemyMaintenance enemyMaintenance(ShipState ship) {
  var next = ship;
  final firesOut = <ShipRoom>[];
  final repaired = <ShipRoom>[];
  for (var action = 0; action < max(1, ship.repairsPerRound); action++) {
    ShipRoom? burning;
    for (final room in enemyRepairPriority) {
      if (next.room(room).onFire) {
        burning = room;
        break;
      }
    }
    if (burning != null) {
      next = next.withRoom(burning, next.room(burning).copyWith(onFire: false));
      firesOut.add(burning);
      continue;
    }
    ShipRoom? damaged;
    for (final room in enemyRepairPriority) {
      if (next.room(room).damage > 0) {
        damaged = room;
        break;
      }
    }
    if (damaged == null) break;
    final state = next.room(damaged);
    next = next.withRoom(damaged, state.copyWith(damage: state.damage - 1));
    repaired.add(damaged);
  }
  return EnemyMaintenance(ship: next, firesOut: firesOut, repaired: repaired);
}

/// Where the enemy aims a weapon at [player]: fire goes for the hold
/// where the crew shelters; while the bulwark works the enemy tries to
/// break it (or, some of the time, the guns); then the guns, the helm,
/// and last the hold. [roll] in [0, 1) picks between bulwark and guns.
ShipRoom enemyTargetFor(ShipState player, ShipWeapon weapon, double roll) {
  if (weapon.incendiary && !player.room(ShipRoom.hold).isDown) {
    return ShipRoom.hold;
  }
  if (!player.room(ShipRoom.bulwark).isDown) {
    return roll < 0.6 ? ShipRoom.bulwark : ShipRoom.guns;
  }
  if (!player.room(ShipRoom.guns).isDown) return ShipRoom.guns;
  if (!player.room(ShipRoom.helm).isDown) return ShipRoom.helm;
  return ShipRoom.hold;
}

/// True when [weapon] will be ready to fire after one more charge step
/// (what a foresight sail shows coming).
bool readyNextTurn(ShipWeapon weapon, ShipState ship) {
  if (ship.room(ShipRoom.guns).isDown) return false;
  return weapon.charge + 1 >= weapon.chargeTurns;
}

/// Fires burn and the bulwark comes back, for one ship, at the end of a
/// round: each burning room loses a pip and costs hull, and a working
/// bulwark raises one layer (two with a hand at it), never past what its
/// pips can hold.
({ShipState ship, List<ShipRoom> burned}) endRound(ShipState ship,
    {bool bulwarkCrewed = false}) {
  var next = ship;
  final burned = <ShipRoom>[];
  for (final room in ShipRoom.values) {
    final state = next.room(room);
    if (!state.onFire) continue;
    burned.add(room);
    next = next
        .withRoom(room, state.copyWith(damage: state.damage + 1))
        .copyWith(hull: max(0, next.hull - fireHullDamagePerRound));
  }
  if (!next.room(ShipRoom.bulwark).isDown) {
    final regen = 1 + (bulwarkCrewed ? 1 : 0);
    next = next.copyWith(layers: min(next.maxLayers, next.layers + regen));
  } else {
    next = next.copyWith(layers: 0);
  }
  return (ship: next, burned: burned);
}

/// The player's ship as it sets out: hull and rooms from ships.json plus
/// every installed part's `roomBonus`, its weapons from every part that
/// fires, layers full; a stored hull of -1 (a fresh save, or just
/// repaired) means full. [voidVolleyBonus] is the painted sail's extra
/// on its own volley, if that sail is aboard.
ShipState buildPlayerShip({
  required Map<String, dynamic> ship,
  required Map<String, dynamic> parts,
  required List<String> installedPartIds,
  required int currentHull,
  String? voidVolleyPartId,
  int voidVolleyBonus = 0,
}) {
  final maxHull = max(1, (ship['baseMaxHull'] as num?)?.toInt() ?? 100);
  final rooms = _roomsFrom(ship['rooms']);
  final weapons = <ShipWeapon>[];
  for (final id in installedPartIds) {
    final part = parts[id] as Map<String, dynamic>?;
    if (part == null) continue;
    final bonus = part['roomBonus'];
    if (bonus is Map) {
      for (final entry in bonus.entries) {
        final room = roomFromName(entry.key.toString());
        if (room == null) continue;
        final current = rooms[room]!;
        rooms[room] = current.copyWith(
            level: current.level + ((entry.value as num?)?.toInt() ?? 0));
      }
    }
    if (((part['damageAmount'] as num?)?.toInt() ?? 0) > 0) {
      weapons.add(ShipWeapon.fromPart(id, part,
          damageBonus: id == voidVolleyPartId ? voidVolleyBonus : 0));
    }
  }
  final hull = currentHull < 0 ? maxHull : min(maxHull, max(0, currentHull));
  final state = ShipState(
    hull: hull,
    maxHull: maxHull,
    layers: 0,
    rooms: rooms,
    weapons: weapons,
  );
  return state.copyWith(layers: state.maxLayers);
}

/// An enemy ship off its enemy_ships.json record: hull, rooms and the
/// weapons in its `weapons` list (one plain gun off `weaponDamage` when
/// the list is missing, for an old record).
ShipState buildEnemyShip(Map<String, dynamic> enemyShip) {
  final hull = max(1, (enemyShip['maxHull'] as num?)?.toInt() ?? 1);
  final rooms = _roomsFrom(enemyShip['rooms']);
  final rawWeapons =
      (enemyShip['weapons'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final weapons = <ShipWeapon>[
    for (var i = 0; i < rawWeapons.length; i++)
      ShipWeapon.fromRecord(rawWeapons[i], i),
  ];
  if (weapons.isEmpty) {
    weapons.add(ShipWeapon(
      id: 'enemy_weapon_0',
      name: 'Guns',
      nameFr: 'Canons',
      damage: max(1, (enemyShip['weaponDamage'] as num?)?.toInt() ?? 8),
      chargeTurns: 1,
    ));
  }
  final state = ShipState(
    hull: hull,
    maxHull: hull,
    layers: 0,
    rooms: rooms,
    weapons: weapons,
    repairsPerRound: max(1, (enemyShip['crew'] as num?)?.toInt() ?? 1),
  );
  return state.copyWith(layers: state.maxLayers);
}

/// Every room at level 1 unless the record says otherwise.
Map<ShipRoom, RoomState> _roomsFrom(Object? raw) {
  final rooms = <ShipRoom, RoomState>{
    for (final room in ShipRoom.values) room: const RoomState(level: 1),
  };
  if (raw is Map) {
    for (final entry in raw.entries) {
      final room = roomFromName(entry.key.toString());
      if (room == null) continue;
      rooms[room] =
          RoomState(level: max(0, (entry.value as num?)?.toInt() ?? 1));
    }
  }
  return rooms;
}

ShipRoom? roomFromName(String name) {
  for (final room in ShipRoom.values) {
    if (room.name == name) return room;
  }
  return null;
}

/// What a shot would do if it lands: [resolveShot] with the helm taken out
/// of it, so the Eel's rooms can show the number before the trigger is
/// pulled. The bulwark's layer still counts.
ShotOutcome previewShot({
  required ShipState target,
  required ShipWeapon weapon,
  required ShipRoom room,
}) =>
    resolveShot(
        target: target, weapon: weapon, room: room, evasionPercent: 0, roll: 1);

/// True when a ship's rail is open to boarders: no shield layer stands and
/// the bulwark itself is knocked out.
bool bulwarkOpen(ShipState ship) =>
    ship.layers == 0 && ship.room(ShipRoom.bulwark).isDown;

/// The share of max hull boarders wreck when they win the deck.
const double boardersHullShare = 0.2;

/// The share of max hull a boarding party thrown back costs the Eel: the
/// grapple lines cut and the deck raked while they scramble home.
const double repelledHullShare = 0.15;

/// A deck fight is fought at this difficulty: a crew on its own pitching
/// deck, at the rail, is far more than the same men met on a road.
const double boardingDifficulty = 2.5;

/// True when the grapples hold: a ship that can still steer slips them
/// with its helm's evasion ([roll] in [0, 1)).
bool grapplesHold(ShipState target, double roll) =>
    roll * 100 >= evasionFor(target);

/// The Eel after her boarding party was thrown back.
ShipState boardingRepelled(ShipState ship) => ship.copyWith(
    hull: max(1, ship.hull - (ship.maxHull * repelledHullShare).round()));

/// Boarders who won the deck before they were driven off: the hold is
/// wrecked (knocked out) and a share of the hull with it, never below one
/// point, since the ship is theirs to sink only by cannon.
ShipState boardersWreck(ShipState ship) {
  final hold = ship.room(ShipRoom.hold);
  return ship
      .withRoom(ShipRoom.hold, hold.copyWith(damage: hold.level))
      .copyWith(
          hull: max(1, ship.hull - (ship.maxHull * boardersHullShare).round()));
}

/// What an enemy ship brings to the rail: the crew it boards with (ids in
/// enemies.json), how likely it is to try each turn the Eel's rail is
/// open, and what its hold holds for whoever takes it.
class BoardingProfile {
  const BoardingProfile({
    this.crew = const [],
    this.chance = 0,
    this.prizePartId,
    this.prizeGold = 0,
  });

  final List<String> crew;
  final double chance;
  final String? prizePartId;
  final int prizeGold;

  bool get canBoard => crew.isNotEmpty;
}

BoardingProfile boardingProfileFor(Map<String, dynamic> enemyShip) {
  final crew = (enemyShip['boardingCrew'] as List?)
          ?.map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList() ??
      const <String>[];
  final prize = enemyShip['prizePartId']?.toString() ?? '';
  return BoardingProfile(
    crew: crew,
    chance: ((enemyShip['boardingChance'] as num?)?.toDouble() ?? 0)
        .clamp(0.0, 1.0),
    prizePartId: prize.isEmpty ? null : prize,
    prizeGold: max(0, (enemyShip['prizeGold'] as num?)?.toInt() ?? 0),
  );
}

/// The chapter a ship's boarding crew fights at: the crossing's [chapter],
/// but never more than one past the chapter the ship first sails in
/// (enemy_ships.json `minChapter`). A ship's hull does not grow with the
/// chapters, and neither does its crew past that: the open chapters send
/// the party to sea far more often, late ones included.
int boardingChapterFor(int chapter, Map<String, dynamic> enemyShip) {
  final first = (enemyShip['minChapter'] as num?)?.toInt() ?? 1;
  return max(1, min(chapter, first + 1));
}

/// Sensible stations for [crew] aboard [ship], for a player who would
/// rather not place them by hand (and for the simulator): the nimblest at
/// the helm, the strongest at the guns, the next at the bulwark, the last
/// in the hold; with the hull under half, the bulwark hand (or the guns
/// hand, or a lone helmsman) goes to the hold; a burning room with nobody
/// in it pulls the hold or bulwark hand.
Stations autoStations(ShipState ship, List<ShipCrew> crew) {
  final stations = <ShipRoom, ShipCrew>{};
  final pool = List.of(crew);
  ShipCrew take(int Function(ShipCrew) score) {
    var best = pool.first;
    for (final c in pool) {
      if (score(c) > score(best)) best = c;
    }
    pool.remove(best);
    return best;
  }

  if (pool.isNotEmpty) stations[ShipRoom.helm] = take((c) => c.dexterity);
  if (pool.isNotEmpty) stations[ShipRoom.guns] = take((c) => c.strength);
  if (pool.isNotEmpty) stations[ShipRoom.bulwark] = pool.removeAt(0);
  if (pool.isNotEmpty) stations[ShipRoom.hold] = pool.removeAt(0);
  if (ship.hull * 2 < ship.maxHull &&
      !stations.containsKey(ShipRoom.hold) &&
      !ship.room(ShipRoom.hold).isDown) {
    for (final room in [ShipRoom.bulwark, ShipRoom.guns, ShipRoom.helm]) {
      final hand = stations.remove(room);
      if (hand != null) {
        stations[ShipRoom.hold] = hand;
        break;
      }
    }
  }
  for (final room in ShipRoom.values) {
    if (!ship.room(room).onFire || stations.containsKey(room)) continue;
    for (final donor in [ShipRoom.hold, ShipRoom.bulwark, ShipRoom.guns]) {
      if (donor == room) continue;
      final hand = stations.remove(donor);
      if (hand != null) {
        stations[room] = hand;
        break;
      }
    }
  }
  return stations;
}

/// How many parts of [slotType] ('Weapon' / 'Shield' / 'Utility') the ship
/// can carry.
int slotCapacity(Map<String, dynamic> ship, String slotType) {
  switch (slotType) {
    case 'Weapon':
      return (ship['weaponSlots'] as num?)?.toInt() ?? 0;
    case 'Shield':
      return (ship['shieldSlots'] as num?)?.toInt() ?? 0;
    case 'Utility':
      return (ship['utilitySlots'] as num?)?.toInt() ?? 0;
    case 'Sail':
      // The painted sail (see sail_powers.dart): one sigil at a time.
      return (ship['sailSlots'] as num?)?.toInt() ?? 0;
  }
  return 0;
}

int slotsUsed(
  Map<String, dynamic> parts,
  List<String> installedPartIds,
  String slotType,
) =>
    installedPartIds
        .where((id) =>
            (parts[id] as Map<String, dynamic>?)?['slotType']?.toString() ==
            slotType)
        .length;

/// A part fits if it isn't already aboard and its slot type has room.
bool canInstallPart({
  required Map<String, dynamic> ship,
  required Map<String, dynamic> parts,
  required List<String> installedPartIds,
  required String partId,
}) {
  if (installedPartIds.contains(partId)) return false;
  final part = parts[partId] as Map<String, dynamic>?;
  if (part == null) return false;
  final slotType = part['slotType']?.toString() ?? '';
  return slotsUsed(parts, installedPartIds, slotType) <
      slotCapacity(ship, slotType);
}

/// One gold per hull point missing.
int repairCostFor({required int hull, required int maxHull}) =>
    max(0, maxHull - hull);

/// The hull a sunk ship limps home with (a quarter of max, at least 1).
int limpHomeHull(int maxHull) => max(1, (maxHull * 0.25).round());
