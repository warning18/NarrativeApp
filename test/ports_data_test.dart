import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/port_helpers.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';

Map<String, dynamic> _loadGamedata(String name) {
  for (final path in ['assets/gamedata/$name', '../assets/gamedata/$name']) {
    final file = File(path);
    if (file.existsSync()) {
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }
  }
  fail('could not find $name under ${Directory.current.path}');
}

void main() {
  final ports = _loadGamedata('ports.json');
  final zones = _loadGamedata('zones.json');
  final shops = _loadGamedata('shops.json');
  final ships = _loadGamedata('ships.json');
  final parts = _loadGamedata('ship_parts.json');
  final enemyShips = _loadGamedata('enemy_ships.json');

  group('ports.json', () {
    test('exactly one home port, and every port names real zones and shops',
        () {
      expect(ports.values.where((p) => portIsHome(p)).length, 1);
      for (final entry in ports.entries) {
        final port = entry.value as Map<String, dynamic>;
        expect(port['portID'], entry.key);
        expect(portNameFor(port, false), isNotEmpty);
        expect(portNameFor(port, true), isNot(portNameFor(port, false)));
        expect(portDescriptionFor(port, true), isNotEmpty);
        for (final zoneId in portZoneIds(port)) {
          expect(zones, contains(zoneId),
              reason: '${entry.key} lists unknown zone $zoneId');
        }
        for (final shopId in portShopIds(port)) {
          expect(shops, contains(shopId),
              reason: '${entry.key} lists unknown shop $shopId');
        }
        expect(portVoyageLength(port), greaterThanOrEqualTo(1));
      }
    });

    test('every zone belongs to exactly one port', () {
      final owners = <String, int>{};
      for (final port in ports.values) {
        for (final zoneId in portZoneIds(port as Map<String, dynamic>)) {
          owners[zoneId] = (owners[zoneId] ?? 0) + 1;
        }
      }
      for (final zoneId in zones.keys) {
        expect(owners[zoneId], 1,
            reason: '$zoneId is at ${owners[zoneId]} ports');
      }
    });

    test('a port opens with its chapter and its flags; the boat starts home',
        () {
      final wharf = ports['port_smugglers_wharf'] as Map<String, dynamic>;
      expect(portUnlocked(wharf, chapter: 1, flags: const []), isFalse);
      expect(portUnlocked(wharf, chapter: 2, flags: const []), isTrue);
      expect(homePortId(ports), 'port_ashen_landing');
      expect(currentPortIdFor(ports, ''), 'port_ashen_landing');
      expect(currentPortIdFor(ports, 'port_smugglers_wharf'),
          'port_smugglers_wharf');
      expect(currentPortIdFor(ports, 'port_unknown'), 'port_ashen_landing');
      expect(currentPortIdFor(const {}, ''), isNull);
    });
  });

  group('ship data', () {
    test('the Rusty Eel exists and has room for the starting ballista', () {
      final eel = ships['rusty_eel'] as Map<String, dynamic>?;
      expect(eel, isNotNull);
      expect((eel!['weaponSlots'] as num).toInt(), greaterThanOrEqualTo(1));
      final ballista = parts['ballista'] as Map<String, dynamic>?;
      expect(ballista, isNotNull);
      expect((ballista!['cost'] as num).toInt(), 0);
      expect(ballista['slotType'], 'Weapon');
    });

    test('every part has a valid slot, a price and something to do', () {
      for (final entry in parts.entries) {
        final part = entry.value as Map<String, dynamic>;
        expect(part['partID'], entry.key);
        expect(slotTypeOptions, contains(part['slotType']),
            reason: '${entry.key} has slot ${part['slotType']}');
        expect((part['cost'] as num).toInt(), greaterThanOrEqualTo(0));
        expect(part['partName_fr']?.toString() ?? '', isNotEmpty);
        // A painted sail works on the voyage itself (see sail_powers.dart)
        // and needs no battle action unless it fires one.
        final painted = (part['sailPower']?.toString() ?? '').isNotEmpty;
        final effect = ((part['damageAmount'] as num?)?.toInt() ?? 0) +
            ((part['shieldRestoreAmount'] as num?)?.toInt() ?? 0) +
            ((part['maxShieldBonus'] as num?)?.toInt() ?? 0) +
            ((part['hullRepairAmount'] as num?)?.toInt() ?? 0);
        if (!painted || effect > 0) {
          expect(part['battleActionLabel_fr']?.toString() ?? '', isNotEmpty,
              reason: entry.key);
        }
        expect(effect > 0 || painted, isTrue,
            reason: '${entry.key} does nothing');
      }
    });

    test(
        'enemy ships are keyed by shipName, named in both languages and '
        'gated by chapter', () {
      for (final entry in enemyShips.entries) {
        final ship = entry.value as Map<String, dynamic>;
        expect(ship['shipName'], entry.key);
        expect(ship['displayName']?.toString() ?? '', isNotEmpty);
        expect(ship['displayName_fr']?.toString() ?? '', isNotEmpty);
        expect((ship['minChapter'] as num).toInt(), greaterThanOrEqualTo(2),
            reason: 'no ship should sail before the boat exists');
        expect((ship['maxHull'] as num).toInt(), greaterThan(0));
        expect((ship['weaponDamage'] as num).toInt(), greaterThan(0));
      }
    });
  });
}
