import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/ship_combat.dart';

void main() {
  const ship = {
    'baseMaxHull': 100,
    'baseMaxShield': 30,
    'shieldRegenPerTurn': 5,
    'weaponSlots': 2,
    'shieldSlots': 1,
    'utilitySlots': 1,
  };
  const parts = {
    'ballista': {
      'slotType': 'Weapon',
      'cost': 0,
      'battleActionLabel': 'Loose the ballista',
      'cooldownTurns': 0,
      'damageAmount': 12,
    },
    'harpoon_rack': {'slotType': 'Weapon', 'cost': 160, 'damageAmount': 22},
    'fire_pots': {'slotType': 'Weapon', 'cost': 260, 'damageAmount': 36},
    'iron_plating': {
      'slotType': 'Shield',
      'cost': 150,
      'shieldRestoreAmount': 15,
      'maxShieldBonus': 15,
      'cooldownTurns': 1,
    },
    'spare_canvas': {
      'slotType': 'Utility',
      'cost': 90,
      'hullRepairAmount': 12,
    },
  };

  group('applyShipDamage', () {
    test('the bulwark absorbs first, the rest reaches the hull', () {
      const target =
          ShipCombatant(hull: 50, maxHull: 60, shield: 10, maxShield: 20);
      final hit = applyShipDamage(target, 25);
      expect(hit.shield, 0);
      expect(hit.hull, 35);
    });

    test('hull never drops below zero and zero damage is a no-op', () {
      const target =
          ShipCombatant(hull: 5, maxHull: 60, shield: 0, maxShield: 20);
      expect(applyShipDamage(target, 40).hull, 0);
      expect(applyShipDamage(target, 40).isAfloat, isFalse);
      expect(applyShipDamage(target, 0), same(target));
    });
  });

  group('resolvePlayerShipAction', () {
    const player =
        ShipCombatant(hull: 60, maxHull: 100, shield: 10, maxShield: 30);
    const enemy =
        ShipCombatant(hull: 40, maxHull: 60, shield: 5, maxShield: 20);

    test('an attack reports the damage that actually landed', () {
      final result = resolvePlayerShipAction(
        player: player,
        enemy: enemy,
        action: ShipAction.fromPart('ballista', parts['ballista']!),
      );
      expect(result.damageDealt, 12);
      expect(result.enemy.shield, 0);
      expect(result.enemy.hull, 33);
      expect(result.player, same(player));
    });

    test('bracing and repairing are capped at the maximums', () {
      final brace = resolvePlayerShipAction(
        player: player,
        enemy: enemy,
        action: ShipAction.fromPart('iron_plating', parts['iron_plating']!),
      );
      expect(brace.shieldRestored, 15);
      expect(brace.player.shield, 25);
      final nearFull = player.copyWith(hull: 95);
      final repair = resolvePlayerShipAction(
        player: nearFull,
        enemy: enemy,
        action: ShipAction.fromPart('spare_canvas', parts['spare_canvas']!),
      );
      expect(repair.hullRepaired, 5);
      expect(repair.player.hull, 100);
    });

    test('a pure slot-bonus part has no usable action', () {
      const bonusOnly = {'slotType': 'Shield', 'maxShieldBonus': 10};
      expect(ShipAction.fromPart('x', bonusOnly).isUsable, isFalse);
      expect(
          ShipAction.fromPart('ballista', parts['ballista']!).isUsable, isTrue);
    });
  });

  group('resolveEnemyShipTurn', () {
    test('hits the player, then both bulwarks regenerate', () {
      const player =
          ShipCombatant(hull: 60, maxHull: 100, shield: 4, maxShield: 30);
      const enemy =
          ShipCombatant(hull: 40, maxHull: 60, shield: 0, maxShield: 20);
      final result = resolveEnemyShipTurn(
        player: player,
        enemy: enemy,
        weaponDamage: 10,
        playerShieldRegen: 5,
        enemyShieldRegen: 3,
      );
      expect(result.damageDealt, 10);
      expect(result.player.hull, 54);
      expect(result.player.shield, 5);
      expect(result.enemy.shield, 3);
    });

    test('a sunk player does not regenerate', () {
      const player =
          ShipCombatant(hull: 3, maxHull: 100, shield: 0, maxShield: 30);
      const enemy =
          ShipCombatant(hull: 40, maxHull: 60, shield: 0, maxShield: 20);
      final result = resolveEnemyShipTurn(
          player: player, enemy: enemy, weaponDamage: 10, playerShieldRegen: 5);
      expect(result.player.isAfloat, isFalse);
      expect(result.player.shield, 0);
    });
  });

  group('fitting', () {
    test('buildPlayerShip: -1 hull means full, parts add bulwark', () {
      final fresh = buildPlayerShip(
          ship: ship,
          parts: parts,
          installedPartIds: const ['ballista', 'iron_plating'],
          currentHull: -1);
      expect(fresh.hull, 100);
      expect(fresh.maxShield, 45);
      expect(fresh.shield, 45);
      final worn = buildPlayerShip(
          ship: ship,
          parts: parts,
          installedPartIds: const ['ballista'],
          currentHull: 37);
      expect(worn.hull, 37);
      expect(worn.maxShield, 30);
      expect(
          buildPlayerShip(
                  ship: ship,
                  parts: parts,
                  installedPartIds: const [],
                  currentHull: 500)
              .hull,
          100);
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
