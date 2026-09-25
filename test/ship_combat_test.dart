import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';

void main() {
  const ship = {
    'baseMaxHull': 100,
    'rooms': {'helm': 1, 'guns': 1, 'bulwark': 1, 'hold': 1},
    'weaponSlots': 2,
    'shieldSlots': 1,
    'utilitySlots': 1,
  };
  const parts = {
    'ballista': {
      'slotType': 'Weapon',
      'partName': 'Ballista',
      'cost': 0,
      'battleActionLabel': 'Loose the ballista',
      'chargeTurns': 1,
      'damageAmount': 12,
    },
    'harpoon_rack': {
      'slotType': 'Weapon',
      'partName': 'Harpoon Rack',
      'cost': 160,
      'chargeTurns': 2,
      'damageAmount': 22,
      'piercesShield': true,
      'roomDamage': 2,
    },
    'fire_pots': {
      'slotType': 'Weapon',
      'partName': 'Fire Pots',
      'cost': 260,
      'chargeTurns': 3,
      'damageAmount': 36,
      'setsFire': true,
    },
    'iron_plating': {
      'slotType': 'Shield',
      'cost': 150,
      'roomBonus': {'bulwark': 1},
    },
    'spare_canvas': {
      'slotType': 'Utility',
      'cost': 90,
      'roomBonus': {'helm': 1},
    },
    'old_gun': {
      'slotType': 'Weapon',
      'partName': 'Old Gun',
      'cooldownTurns': 2,
      'damageAmount': 9,
    },
  };

  ShipState makeShip({
    int hull = 60,
    int layers = 1,
    Map<ShipRoom, RoomState>? rooms,
    List<ShipWeapon> weapons = const [],
  }) =>
      ShipState(
        hull: hull,
        maxHull: 60,
        layers: layers,
        rooms: rooms ??
            {
              for (final room in ShipRoom.values)
                room: const RoomState(level: 1)
            },
        weapons: weapons,
      );

  const ballista = ShipWeapon(
      id: 'b', name: 'Ballista', nameFr: '', damage: 12, chargeTurns: 1);
  const harpoon = ShipWeapon(
      id: 'h',
      name: 'Harpoon',
      nameFr: '',
      damage: 22,
      chargeTurns: 2,
      piercing: true,
      roomDamage: 2);
  const firePots = ShipWeapon(
      id: 'f',
      name: 'Fire Pots',
      nameFr: '',
      damage: 36,
      chargeTurns: 3,
      incendiary: true);
  const helmsman = ShipCrew(
      id: 'p',
      name: 'Pip',
      strength: 4,
      dexterity: 8,
      constitution: 4,
      wisdom: 6,
      health: 30,
      maxHealth: 30,
      isPlayer: true);

  group('rooms and weapons', () {
    test('a room works for its undamaged pips and is down at zero', () {
      const room = RoomState(level: 2, damage: 1);
      expect(room.working, 1);
      expect(room.isDown, isFalse);
      expect(room.copyWith(damage: 5).damage, 2, reason: 'clamped to level');
      expect(room.copyWith(damage: 2).isDown, isTrue);
    });

    test('a weapon reads its part, an old cooldown becoming charge turns', () {
      final harpoons =
          ShipWeapon.fromPart('harpoon_rack', parts['harpoon_rack']!);
      expect(harpoons.chargeTurns, 2);
      expect(harpoons.piercing, isTrue);
      expect(harpoons.roomDamage, 2);
      expect(harpoons.isReady, isFalse);
      expect(harpoons.withCharge(5).charge, 2, reason: 'capped at chargeTurns');
      expect(harpoons.withCharge(2).isReady, isTrue);
      expect(harpoons.withCharge(2).fired().charge, 0);
      final old = ShipWeapon.fromPart('old_gun', parts['old_gun']!);
      expect(old.chargeTurns, 3, reason: 'cooldown 2 = every third turn');
    });
  });

  group('evasion', () {
    test('comes from the helm and its helmsman, none from a helm knocked out',
        () {
      final ship = makeShip(rooms: {
        for (final room in ShipRoom.values)
          room: RoomState(level: room == ShipRoom.helm ? 3 : 1),
      });
      expect(evasionFor(ship), 24);
      expect(evasionFor(ship, helmsman: helmsman), 24 + 9);
      final blind =
          ship.withRoom(ShipRoom.helm, const RoomState(level: 3, damage: 3));
      expect(evasionFor(blind, helmsman: helmsman), 0);
      final fast = ship.withRoom(ShipRoom.helm, const RoomState(level: 6));
      expect(evasionFor(fast, helmsman: helmsman), maxEvasionPercent);
    });
  });

  group('resolveShot', () {
    test('a dodged shot changes nothing', () {
      final ship = makeShip();
      final shot = resolveShot(
          target: ship,
          weapon: ballista,
          room: ShipRoom.guns,
          evasionPercent: 30,
          roll: 0.1);
      expect(shot.dodged, isTrue);
      expect(shot.target.hull, 60);
      expect(shot.target.layers, 1);
    });

    test('a shield layer stops the shot but the bulwark cracks behind it', () {
      final ship = makeShip(layers: 1);
      final shot = resolveShot(
          target: ship,
          weapon: ballista,
          room: ShipRoom.guns,
          evasionPercent: 0,
          roll: 0.5);
      expect(shot.absorbed, isTrue);
      expect(shot.target.hull, 60);
      expect(shot.target.layers, 0);
      expect(shot.target.room(ShipRoom.bulwark).damage, 1);
      expect(shot.roomKnockedOut, isTrue, reason: 'a 1-pip bulwark is down');
      expect(shot.target.maxLayers, 0);
    });

    test('a piercing shot ignores the layers', () {
      final ship = makeShip(layers: 1);
      final shot = resolveShot(
          target: ship,
          weapon: harpoon,
          room: ShipRoom.guns,
          evasionPercent: 0,
          roll: 0.5);
      expect(shot.landed, isTrue);
      expect(shot.target.layers, 1);
      expect(shot.hullDamage, 22);
      expect(shot.target.room(ShipRoom.guns).damage, 1,
          reason: '2 room damage clamped to the 1-pip room');
      expect(shot.roomKnockedOut, isTrue);
    });

    test('a landed shot costs hull, knocks pips off the room, and burns', () {
      final ship = makeShip(layers: 0, rooms: {
        for (final room in ShipRoom.values) room: const RoomState(level: 2),
      });
      final shot = resolveShot(
          target: ship,
          weapon: firePots,
          room: ShipRoom.hold,
          evasionPercent: 0,
          roll: 0.9);
      expect(shot.landed, isTrue);
      expect(shot.target.hull, 24);
      expect(shot.target.room(ShipRoom.hold).damage, 1);
      expect(shot.target.room(ShipRoom.hold).onFire, isTrue);
      expect(shot.fireStarted, isTrue);
      expect(shot.roomKnockedOut, isFalse);
      // hull never goes below zero
      final sunk = resolveShot(
          target: shot.target.copyWith(hull: 10),
          weapon: firePots,
          room: ShipRoom.hold,
          evasionPercent: 0,
          roll: 0.9);
      expect(sunk.target.hull, 0);
      expect(sunk.target.isAfloat, isFalse);
      expect(sunk.fireStarted, isFalse, reason: 'already burning');
    });

    test('layers never exceed what a damaged bulwark can hold', () {
      final ship = makeShip(layers: 2, rooms: {
        for (final room in ShipRoom.values) room: const RoomState(level: 2),
      });
      final shot = resolveShot(
          target: ship,
          weapon: harpoon,
          room: ShipRoom.bulwark,
          evasionPercent: 0,
          roll: 0.5);
      expect(shot.target.room(ShipRoom.bulwark).working, 0);
      expect(shot.target.layers, 0);
    });
  });

  group('chargeWeapons', () {
    test('every weapon charges a step while the guns work', () {
      final ship = makeShip(weapons: const [ballista, harpoon, firePots]);
      final charged = chargeWeapons(ship);
      expect(charged.weapons.map((w) => w.charge), [1, 1, 1]);
      expect(charged.weapons[0].isReady, isTrue);
    });

    test('extra gun pips and a gunner go to the heaviest weapon charging', () {
      final ship = makeShip(
        weapons: const [ballista, harpoon, firePots],
        rooms: {
          for (final room in ShipRoom.values)
            room: RoomState(level: room == ShipRoom.guns ? 2 : 1),
        },
      );
      final charged = chargeWeapons(ship, gunnerAboard: true);
      // +1 each, then +1 (gun pip) and +1 (gunner) to the fire pots.
      expect(charged.weapons.map((w) => w.charge), [1, 1, 3]);
      expect(charged.weapons[2].isReady, isTrue);
    });

    test('knocked-out guns charge nothing', () {
      final ship = makeShip(
        weapons: const [ballista],
        rooms: {
          for (final room in ShipRoom.values)
            room: room == ShipRoom.guns
                ? const RoomState(level: 1, damage: 1)
                : const RoomState(level: 1),
        },
      );
      expect(chargeWeapons(ship).weapons.single.charge, 0);
      expect(readyNextTurn(ballista, ship), isFalse);
      expect(readyNextTurn(ballista, makeShip()), isTrue);
      expect(readyNextTurn(harpoon, makeShip()), isFalse);
    });
  });

  group('crewTurn', () {
    test(
        'a hand puts out the fire first, else repairs, and a hold hand '
        'patches the hull', () {
      final ship = makeShip(hull: 40, rooms: {
        ShipRoom.helm: const RoomState(level: 1, damage: 1, onFire: true),
        ShipRoom.guns: const RoomState(level: 2, damage: 1),
        ShipRoom.bulwark: const RoomState(level: 1),
        ShipRoom.hold: const RoomState(level: 2),
      });
      const gunner = ShipCrew(
          id: 'g',
          name: 'Gus',
          strength: 8,
          dexterity: 2,
          constitution: 5,
          wisdom: 2,
          health: 20,
          maxHealth: 20);
      const carpenter = ShipCrew(
          id: 'c',
          name: 'Cal',
          strength: 2,
          dexterity: 2,
          constitution: 5,
          wisdom: 10,
          health: 20,
          maxHealth: 20);
      final result = crewTurn(ship, {
        ShipRoom.helm: helmsman,
        ShipRoom.guns: gunner,
        ShipRoom.hold: carpenter,
      });
      expect(result.ship.room(ShipRoom.helm).onFire, isFalse);
      expect(result.ship.room(ShipRoom.helm).damage, 1,
          reason: 'fighting the fire took the turn');
      expect(result.ship.room(ShipRoom.guns).damage, 0);
      expect(result.ship.hull, 40 + crewHullRepair(carpenter, 2));
      expect(crewHullRepair(carpenter, 2), 7);
      expect(crewHullRepair(carpenter, 0), 0, reason: 'hold knocked out');
      expect(result.work.where((w) => w.fireOut).single.crew.id, 'p');
      expect(result.work.where((w) => w.roomRepaired).single.crew.id, 'g');
      expect(result.work.where((w) => w.hullRepaired > 0).single.crew.id, 'c');
      // The two hands who fought and repaired are off their stations.
      expect(result.busy, {ShipRoom.helm, ShipRoom.guns});
    });

    test('a hold hand repairs the hold before patching the hull', () {
      final ship = makeShip(hull: 40)
          .withRoom(ShipRoom.hold, const RoomState(level: 1, damage: 1));
      final result = crewTurn(ship, {ShipRoom.hold: helmsman});
      expect(result.ship.room(ShipRoom.hold).damage, 0);
      expect(result.ship.hull, 40);
      expect(result.busy, {ShipRoom.hold});
    });

    test('injuries floor at one health', () {
      expect(crewInjuryFor(ballista), 6);
      expect(
          crewInjuryFor(const ShipWeapon(
              id: 'x', name: 'x', nameFr: '', damage: 2, chargeTurns: 1)),
          3);
      expect(helmsman.withHealth(-4).health, 1);
      expect(helmsman.withHealth(99).health, 30);
    });
  });

  group('the enemy', () {
    test('fights a fire before repairing, and repairs its guns first', () {
      final burning = makeShip(rooms: {
        ShipRoom.helm: const RoomState(level: 1, damage: 1),
        ShipRoom.guns: const RoomState(level: 1, damage: 1, onFire: true),
        ShipRoom.bulwark: const RoomState(level: 1, damage: 1),
        ShipRoom.hold: const RoomState(level: 1),
      });
      final fought = enemyMaintenance(burning);
      expect(fought.firesOut, [ShipRoom.guns]);
      expect(fought.repaired, isEmpty);
      final repaired = enemyMaintenance(fought.ship);
      expect(repaired.repaired, [ShipRoom.guns]);
      expect(repaired.ship.room(ShipRoom.guns).damage, 0);
      expect(enemyMaintenance(makeShip()).repaired, isEmpty);
    });

    test('a bigger crew makes more repairs a round', () {
      final battered = makeShip(rooms: {
        ShipRoom.helm: const RoomState(level: 1, damage: 1),
        ShipRoom.guns: const RoomState(level: 2, damage: 2, onFire: true),
        ShipRoom.bulwark: const RoomState(level: 1, damage: 1),
        ShipRoom.hold: const RoomState(level: 1),
      }).copyWith();
      final crewed = ShipState(
          hull: battered.hull,
          maxHull: battered.maxHull,
          layers: 0,
          rooms: battered.rooms,
          weapons: const [],
          repairsPerRound: 3);
      final result = enemyMaintenance(crewed);
      expect(result.firesOut, [ShipRoom.guns]);
      expect(result.repaired, [ShipRoom.guns, ShipRoom.guns]);
      expect(result.ship.room(ShipRoom.guns).working, 2);
      expect(result.ship.room(ShipRoom.bulwark).damage, 1);
    });

    test(
        'aims fire at the hold, otherwise the bulwark or guns, then down '
        'the list', () {
      final whole = makeShip();
      expect(enemyTargetFor(whole, firePots, 0.9), ShipRoom.hold);
      expect(enemyTargetFor(whole, ballista, 0.1), ShipRoom.bulwark);
      expect(enemyTargetFor(whole, ballista, 0.9), ShipRoom.guns);
      final noBulwark = whole.withRoom(
          ShipRoom.bulwark, const RoomState(level: 1, damage: 1));
      expect(enemyTargetFor(noBulwark, ballista, 0.1), ShipRoom.guns);
      final noGuns = noBulwark.withRoom(
          ShipRoom.guns, const RoomState(level: 1, damage: 1));
      expect(enemyTargetFor(noGuns, ballista, 0.1), ShipRoom.helm);
      final hulk = noGuns
          .withRoom(ShipRoom.helm, const RoomState(level: 1, damage: 1))
          .withRoom(ShipRoom.hold, const RoomState(level: 1, damage: 1));
      expect(enemyTargetFor(hulk, ballista, 0.1), ShipRoom.hold);
      expect(enemyTargetFor(hulk, firePots, 0.1), ShipRoom.hold);
    });
  });

  group('endRound', () {
    test('fires burn a pip and hull, and a working bulwark comes back', () {
      final ship = makeShip(hull: 20, layers: 0, rooms: {
        ShipRoom.helm: const RoomState(level: 2, onFire: true),
        ShipRoom.guns: const RoomState(level: 1),
        ShipRoom.bulwark: const RoomState(level: 2),
        ShipRoom.hold: const RoomState(level: 1),
      });
      final result = endRound(ship);
      expect(result.burned, [ShipRoom.helm]);
      expect(result.ship.room(ShipRoom.helm).damage, 1);
      expect(result.ship.hull, 20 - fireHullDamagePerRound);
      expect(result.ship.layers, 1);
      final crewed = endRound(ship, bulwarkCrewed: true);
      expect(crewed.ship.layers, 2);
      expect(endRound(crewed.ship, bulwarkCrewed: true).ship.layers, 2,
          reason: 'capped at the bulwark\'s pips');
    });

    test('a knocked-out bulwark holds no layers', () {
      final ship = makeShip(layers: 1)
          .withRoom(ShipRoom.bulwark, const RoomState(level: 1, damage: 1));
      expect(endRound(ship).ship.layers, 0);
    });
  });

  group('boarding', () {
    test('the rail is open only with no layer and the bulwark down', () {
      expect(bulwarkOpen(makeShip(layers: 1)), isFalse);
      expect(bulwarkOpen(makeShip(layers: 0)), isFalse,
          reason: 'the bulwark still works: a layer is coming back');
      final open = makeShip(layers: 0)
          .withRoom(ShipRoom.bulwark, const RoomState(level: 1, damage: 1));
      expect(bulwarkOpen(open), isTrue);
    });

    test('boarders who win the deck wreck the hold and a fifth of the hull',
        () {
      final ship =
          makeShip(hull: 50).withRoom(ShipRoom.hold, const RoomState(level: 2));
      final wrecked = boardersWreck(ship);
      expect(wrecked.hull, 38);
      expect(wrecked.room(ShipRoom.hold).isDown, isTrue);
      expect(boardersWreck(makeShip(hull: 5)).hull, 1,
          reason: 'never sunk by boarders');
    });

    test('grapples hold against a slow ship and slip a nimble one', () {
      final slow = makeShip()
          .withRoom(ShipRoom.helm, const RoomState(level: 1, damage: 1));
      expect(grapplesHold(slow, 0.0), isTrue);
      final nimble =
          makeShip().withRoom(ShipRoom.helm, const RoomState(level: 3));
      expect(evasionFor(nimble), 24);
      expect(grapplesHold(nimble, 0.1), isFalse);
      expect(grapplesHold(nimble, 0.3), isTrue);
    });

    test('a boarding party thrown back costs the Eel hull, never the ship', () {
      expect(boardingRepelled(makeShip(hull: 60)).hull, 51);
      expect(boardingRepelled(makeShip(hull: 3)).hull, 1);
    });

    test('previewShot never dodges and otherwise matches resolveShot', () {
      final ship = makeShip(layers: 0);
      final preview =
          previewShot(target: ship, weapon: harpoon, room: ShipRoom.guns);
      expect(preview.dodged, isFalse);
      expect(preview.hullDamage, 22);
      expect(preview.roomKnockedOut, isTrue);
      final shielded = previewShot(
          target: makeShip(layers: 1), weapon: ballista, room: ShipRoom.guns);
      expect(shielded.absorbed, isTrue);
    });
  });

  group('autoStations', () {
    const nimble = ShipCrew(
        id: 'n',
        name: 'Nim',
        strength: 2,
        dexterity: 9,
        constitution: 3,
        wisdom: 3,
        health: 20,
        maxHealth: 20);
    const strong = ShipCrew(
        id: 's',
        name: 'Sto',
        strength: 9,
        dexterity: 2,
        constitution: 3,
        wisdom: 3,
        health: 20,
        maxHealth: 20);
    const third = ShipCrew(
        id: 't',
        name: 'Thi',
        strength: 3,
        dexterity: 3,
        constitution: 3,
        wisdom: 3,
        health: 20,
        maxHealth: 20);
    const fourth = ShipCrew(
        id: 'f',
        name: 'Fou',
        strength: 1,
        dexterity: 1,
        constitution: 1,
        wisdom: 9,
        health: 20,
        maxHealth: 20);

    test('nimblest at the helm, strongest at the guns, then bulwark, then hold',
        () {
      final stations =
          autoStations(makeShip(), [third, strong, nimble, fourth]);
      expect(stations[ShipRoom.helm]!.id, 'n');
      expect(stations[ShipRoom.guns]!.id, 's');
      expect(stations[ShipRoom.bulwark]!.id, 't');
      expect(stations[ShipRoom.hold]!.id, 'f');
      final two = autoStations(makeShip(), [third, strong]);
      expect(two.keys, containsAll([ShipRoom.helm, ShipRoom.guns]));
      expect(two.containsKey(ShipRoom.hold), isFalse);
    });

    test('under half hull a hand goes to the hold, and a lone hand too', () {
      final low = makeShip(hull: 20);
      final three = autoStations(low, [nimble, strong, third]);
      expect(three[ShipRoom.hold]!.id, 't');
      expect(three.containsKey(ShipRoom.bulwark), isFalse);
      final alone = autoStations(low, [nimble]);
      expect(alone[ShipRoom.hold]!.id, 'n');
      expect(alone.containsKey(ShipRoom.helm), isFalse);
    });

    test('an unmanned fire pulls the hold hand', () {
      final burning = makeShip()
          .withRoom(ShipRoom.bulwark, const RoomState(level: 1, onFire: true));
      final two = autoStations(burning, [nimble, strong]);
      // Nobody in the hold or the bulwark; the guns hand goes to the fire.
      expect(two[ShipRoom.bulwark]!.id, 's');
      expect(two[ShipRoom.helm]!.id, 'n');
    });
  });

  group('fitting', () {
    test('buildPlayerShip: -1 hull means full, parts add pips and weapons', () {
      final fresh = buildPlayerShip(
          ship: ship,
          parts: parts,
          installedPartIds: const [
            'ballista',
            'harpoon_rack',
            'iron_plating',
            'spare_canvas'
          ],
          currentHull: -1);
      expect(fresh.hull, 100);
      expect(fresh.room(ShipRoom.bulwark).level, 2);
      expect(fresh.room(ShipRoom.helm).level, 2);
      expect(fresh.room(ShipRoom.guns).level, 1);
      expect(fresh.layers, 2);
      expect(fresh.weapons.map((w) => w.id), ['ballista', 'harpoon_rack']);
      expect(fresh.weapons.every((w) => w.charge == 0), isTrue);
      final worn = buildPlayerShip(
          ship: ship,
          parts: parts,
          installedPartIds: const ['ballista'],
          currentHull: 37);
      expect(worn.hull, 37);
      expect(worn.layers, 1);
      expect(
          buildPlayerShip(
                  ship: ship,
                  parts: parts,
                  installedPartIds: const [],
                  currentHull: 500)
              .hull,
          100);
    });

    test('the void volley carries the sail\'s bonus, only on its own part', () {
      const withSail = {
        ...parts,
        'sail_void_mark': {
          'slotType': 'Sail',
          'partName': 'The Void Mark',
          'chargeTurns': 3,
          'damageAmount': 30,
          'piercesShield': true,
          'sailPower': 'voidmark',
        },
      };
      final eel = buildPlayerShip(
          ship: ship,
          parts: withSail,
          installedPartIds: const ['ballista', 'sail_void_mark'],
          currentHull: -1,
          voidVolleyPartId: 'sail_void_mark',
          voidVolleyBonus: 10);
      expect(
          eel.weapons.firstWhere((w) => w.id == 'sail_void_mark').damage, 40);
      expect(eel.weapons.firstWhere((w) => w.id == 'ballista').damage, 12);
    });

    test('buildEnemyShip reads rooms and weapons, with a plain gun fallback',
        () {
      final barge = buildEnemyShip(const {
        'maxHull': 140,
        'rooms': {'helm': 1, 'guns': 3, 'bulwark': 2, 'hold': 2},
        'weapons': [
          {
            'weaponName': 'Void lance',
            'damage': 14,
            'chargeTurns': 2,
            'piercesShield': true,
          },
          {'weaponName': 'Bow chaser', 'damage': 8, 'chargeTurns': 1},
        ],
      });
      expect(barge.hull, 140);
      expect(barge.layers, 2);
      expect(barge.room(ShipRoom.guns).level, 3);
      expect(barge.weapons.length, 2);
      expect(barge.weapons.first.piercing, isTrue);
      expect(barge.repairsPerRound, 1);
      expect(
          buildEnemyShip(const {'maxHull': 30, 'crew': 2}).repairsPerRound, 2);
      final old = buildEnemyShip(const {'maxHull': 30, 'weaponDamage': 9});
      expect(old.weapons.single.damage, 9);
      expect(old.weapons.single.chargeTurns, 1);
      expect(old.layers, 1, reason: 'rooms default to one pip each');
    });

    test('canInstallPart respects slot counts and duplicates', () {
      expect(
          canInstallPart(
              ship: ship,
              parts: parts,
              installedPartIds: const ['ballista'],
              partId: 'harpoon_rack'),
          isTrue);
      expect(
          canInstallPart(
              ship: ship,
              parts: parts,
              installedPartIds: const ['ballista', 'harpoon_rack'],
              partId: 'fire_pots'),
          isFalse,
          reason: 'both weapon slots taken');
      expect(
          canInstallPart(
              ship: ship,
              parts: parts,
              installedPartIds: const ['ballista'],
              partId: 'ballista'),
          isFalse,
          reason: 'already aboard');
      expect(
          canInstallPart(
              ship: ship,
              parts: parts,
              installedPartIds: const [],
              partId: 'nonexistent'),
          isFalse);
      expect(slotsUsed(parts, const ['ballista', 'iron_plating'], 'Weapon'), 1);
      expect(slotCapacity(ship, 'Utility'), 1);
      expect(slotCapacity(ship, 'Sails'), 0);
    });

    test('a boarding crew fights at most a chapter past its ship\'s first', () {
      const barge = {'minChapter': 4};
      expect(boardingChapterFor(4, barge), 4);
      expect(boardingChapterFor(5, barge), 5);
      expect(boardingChapterFor(6, barge), 5);
      expect(boardingChapterFor(2, const {'minChapter': 2}), 2);
      expect(boardingChapterFor(6, const {}), 2);
    });

    test('boardingProfileFor reads the crew, odds and prize, with defaults',
        () {
      final profile = boardingProfileFor(const {
        'boardingCrew': ['street_bandit', '', 'harbor_rat'],
        'boardingChance': 1.4,
        'prizePartId': 'spare_canvas',
        'prizeGold': 40,
      });
      expect(profile.crew, ['street_bandit', 'harbor_rat']);
      expect(profile.chance, 1.0, reason: 'clamped');
      expect(profile.prizePartId, 'spare_canvas');
      expect(profile.prizeGold, 40);
      expect(profile.canBoard, isTrue);
      final none = boardingProfileFor(const {'maxHull': 10});
      expect(none.canBoard, isFalse);
      expect(none.prizePartId, isNull);
      expect(none.chance, 0);
    });

    test(
        'repair cost is one gold per missing hull point; limping home '
        'leaves a quarter', () {
      expect(repairCostFor(hull: 63, maxHull: 100), 37);
      expect(repairCostFor(hull: 100, maxHull: 100), 0);
      expect(limpHomeHull(100), 25);
      expect(limpHomeHull(2), 1);
    });
  });
}
