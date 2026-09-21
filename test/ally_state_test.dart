import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/models/ally_state.dart';

void main() {
  group('deriveAllyBaseStats', () {
    test(
        'derives ability scores from gameConfig defaults + race + profession bonus',
        () {
      final base = deriveAllyBaseStats(
        gameConfig: const {
          'maxHealth': 100,
          'baseDamage': 10,
          'baseArmor': 0,
          'strength': 0,
          'dexterity': 0,
          'constitution': 0,
          'intelligence': 0,
        },
        race: const {'bonusStrength': 2, 'bonusConstitution': 4},
        profession: const {'bonusStrength': 4, 'bonusConstitution': 2},
      );

      expect(base.strength, 6);
      expect(base.constitution, 6);
      expect(base.dexterity, 0);
      expect(base.intelligence, 0);
    });

    test('missing bonus fields default to 0', () {
      final base = deriveAllyBaseStats(
        gameConfig: const {},
        race: const {},
        profession: const {},
      );

      expect(base.strength, 0);
      expect(base.dexterity, 0);
      expect(base.constitution, 0);
      expect(base.intelligence, 0);
    });
  });

  group('equipmentScalingBonusFor', () {
    const items = {
      'sword': {
        'attackDamage': 20,
        'armor': 0,
        'scalingStat': 'strength',
      },
      'shield': {
        'attackDamage': 0,
        'armor': 15,
        'scalingStat': 'constitution',
      },
      'plain_dagger': {
        'attackDamage': 6,
        'armor': 0,
        'scalingStat': '',
      },
    };

    EquipmentScalingBonus bonusFor(
      List<String> equipped, {
      int strength = 0,
      int dexterity = 0,
      int constitution = 0,
      int intelligence = 0,
    }) =>
        equipmentScalingBonusFor(
          equipped,
          items,
          strength: strength,
          dexterity: dexterity,
          constitution: constitution,
          intelligence: intelligence,
        );

    test('a sword scaling with strength adds stat ~/ 2 to damage', () {
      final bonus = bonusFor(['sword'], strength: 9);
      expect(bonus.damageBonus, 4);
      expect(bonus.armorBonus, 0);
    });

    test(
        'a shield scaling with constitution adds stat ~/ 2 to armor, not damage',
        () {
      final bonus = bonusFor(['shield'], constitution: 7);
      expect(bonus.armorBonus, 3);
      expect(bonus.damageBonus, 0);
    });

    test('an item with no scalingStat never gets a bonus', () {
      final bonus = bonusFor(['plain_dagger'], strength: 20);
      expect(bonus.damageBonus, 0);
      expect(bonus.armorBonus, 0);
    });

    test('a zero or negative stat never subtracts below the flat value', () {
      final bonus = bonusFor(['sword'], strength: -4);
      expect(bonus.damageBonus, 0);
    });

    test('multiple equipped items stack their scaling bonuses', () {
      final bonus = bonusFor(['sword', 'shield'], strength: 9, constitution: 7);
      expect(bonus.damageBonus, 4);
      expect(bonus.armorBonus, 3);
    });
  });

  group('meetsItemStatRequirement', () {
    const heavySword = {
      'reqStrength': 10,
      'reqConstitution': 4,
    };

    test('a null item is always equippable', () {
      expect(
        meetsItemStatRequirement(null,
            strength: 0, dexterity: 0, constitution: 0, intelligence: 0),
        isTrue,
      );
    });

    test('an item with no requirement fields is always equippable', () {
      expect(
        meetsItemStatRequirement(const {},
            strength: 0, dexterity: 0, constitution: 0, intelligence: 0),
        isTrue,
      );
    });

    test('exactly meeting every requirement is equippable', () {
      expect(
        meetsItemStatRequirement(heavySword,
            strength: 10, dexterity: 0, constitution: 4, intelligence: 0),
        isTrue,
      );
    });

    test('falling short on just one of several requirements blocks it', () {
      expect(
        meetsItemStatRequirement(heavySword,
            strength: 10, dexterity: 0, constitution: 3, intelligence: 0),
        isFalse,
      );
    });

    test(
        'falling short on the primary stat blocks it even with everything else high',
        () {
      expect(
        meetsItemStatRequirement(heavySword,
            strength: 9, dexterity: 20, constitution: 20, intelligence: 20),
        isFalse,
      );
    });
  });
}
