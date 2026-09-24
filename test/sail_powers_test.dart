// The painted sail: five sigils on the Rusty Eel's canvas, each worn the
// way its people wear power, read off ship_parts.json and applied to a
// voyage (flight, wind-knot, hearth, foresight) and a ship battle
// (foresight, the void volley). Painted the character's own way, a sigil
// holds twice as strong.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/data/sail_powers.dart';
import 'package:narrative_data_app/data/sea_events.dart';

Map<String, dynamic> _loadJson(String relative) {
  for (final path in [relative, '../$relative']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  fail('could not find $relative under ${Directory.current.path}');
}

void main() {
  final parts = _loadJson('assets/gamedata/ship_parts.json');
  final ships = _loadJson('assets/gamedata/ships.json');
  final races = _loadJson('assets/gamedata/races.json');
  final enemyShips = _loadJson('assets/gamedata/enemy_ships.json');

  group('the five painted sails', () {
    test(
        'one sail per power, each painted in a real race\'s medium, with '
        'French', () {
      final byPower = <SailPower, String>{};
      for (final entry in parts.entries) {
        final part = entry.value as Map<String, dynamic>;
        final power = sailPowerOf(part);
        if (part['slotType'] == 'Sail') {
          expect(power, isNotNull, reason: entry.key);
          expect(byPower.containsKey(power), isFalse,
              reason: '${entry.key} repeats ${power!.name}');
          byPower[power] = entry.key;
          expect(races.keys, contains(sailMediumOf(part)), reason: entry.key);
          expect(part['description']?.toString() ?? '', isNotEmpty);
          expect(part['description_fr']?.toString() ?? '', isNotEmpty);
          expect(part['partName_fr']?.toString() ?? '', isNotEmpty);
        } else {
          expect(power, isNull, reason: entry.key);
        }
      }
      expect(byPower.keys.toSet(), SailPower.values.toSet());
      // Five media, five peoples: every race paints one sail.
      final media = {
        for (final id in byPower.values)
          sailMediumOf(parts[id] as Map<String, dynamic>),
      };
      expect(media, races.keys.toSet());
    });

    test('the Eel has one sail slot and a painted sail fits it, once', () {
      final eel = ships['rusty_eel'] as Map<String, dynamic>;
      expect(slotCapacity(eel, 'Sail'), 1);
      expect(
          canInstallPart(
              ship: eel,
              parts: parts,
              installedPartIds: const ['ballista'],
              partId: 'sail_gulls_wing'),
          isTrue);
      expect(
          canInstallPart(
              ship: eel,
              parts: parts,
              installedPartIds: const ['ballista', 'sail_gulls_wing'],
              partId: 'sail_hearth_mark'),
          isFalse,
          reason: 'the second sigil replaces the first instead (BoatScreen)');
      final sail = installedSail(parts, const ['ballista', 'sail_hearth_mark']);
      expect(sail?.power, SailPower.hearth);
      expect(sail?.medium, 'dwarf');
      expect(installedSail(parts, const ['ballista']), isNull);
    });

    test('a sigil painted its own people\'s way holds twice as strong', () {
      expect(sailStrength('dwarf', 'dwarf'), 2);
      expect(sailStrength('dwarf', 'orc'), 1);
      expect(sailStrength('', 'orc'), 1);
    });
  });

  group('what the sails do', () {
    List<SeaEvent> voyage(int seed, {int length = 4}) => buildVoyage(
        random: Random(seed),
        length: length,
        enemyShips: enemyShips,
        chapter: 4);

    test(
        'flight lifts the Eel over every storm and raider, never to an '
        'empty voyage', () {
      for (var seed = 0; seed < 40; seed++) {
        final events = voyage(seed);
        final lifted = applyFlight(events);
        expect(lifted, isNotEmpty);
        expect(
            lifted.any((e) =>
                e.kind == SeaEventKind.storm || e.kind == SeaEventKind.raider),
            lifted.length == 1 &&
                events.every((e) =>
                    e.kind == SeaEventKind.storm ||
                    e.kind == SeaEventKind.raider),
            reason: 'only an all-weather voyage keeps its last day');
        expect(lifted.length, lessThanOrEqualTo(events.length));
      }
    });

    test('the wind-knot shortens the crossing and fattens the wrecks', () {
      expect(windknotLength(4, 1), 3);
      expect(windknotLength(4, 2), 2);
      expect(windknotLength(1, 2), 1);
      expect(windknotSalvage(40, 1), 60);
      expect(windknotSalvage(40, 2), 80);
    });

    test('the hearth heals and mends more when painted by a dwarf', () {
      expect(hearthHealPercent(1), 10);
      expect(hearthHealPercent(2), 20);
      expect(hearthHullRepair(1), 6);
      expect(hearthHullRepair(2), 12);
    });

    test(
        'foresight sees a day ahead, two for the inked, and blunts the '
        'first volley', () {
      expect(foresightDays(1), 1);
      expect(foresightDays(2), 2);
      expect(firstVolleyFactor(1), 0.5);
      expect(firstVolleyFactor(2), 0.0);
    });

    test('the void mark takes the storm\'s teeth and sharpens the volley', () {
      expect(voidmarkStormLoss(12, 1), 6);
      expect(voidmarkStormLoss(12, 2), 0);
      expect(voidVolleyBonus(1), 0);
      expect(voidVolleyBonus(2), 10);
      const ship = {
        'baseMaxHull': 100,
        'rooms': {'helm': 1, 'guns': 1, 'bulwark': 1, 'hold': 1},
        'weaponSlots': 2,
        'shieldSlots': 1,
        'utilitySlots': 1,
        'sailSlots': 1,
      };
      final eel = buildPlayerShip(
        ship: ship,
        parts: parts,
        installedPartIds: const ['sail_void_mark'],
        currentHull: -1,
        voidVolleyPartId: 'sail_void_mark',
        voidVolleyBonus: voidVolleyBonus(2),
      );
      final volley = eel.weapons.single;
      expect(volley.id, 'sail_void_mark');
      expect(volley.damage, 40);
      expect(volley.chargeTurns, 4);
      expect(volley.piercing, isTrue, reason: 'the void ignores a bulwark');
      // Every other sail does nothing in a fight on its own.
      for (final id in [
        'sail_gulls_wing',
        'sail_krakens_eye',
        'sail_hearth_mark',
        'sail_wind_knot',
      ]) {
        final withSail = buildPlayerShip(
          ship: ship,
          parts: parts,
          installedPartIds: [id],
          currentHull: -1,
        );
        expect(withSail.weapons, isEmpty, reason: id);
      }
    });
  });
}
