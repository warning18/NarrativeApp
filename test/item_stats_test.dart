// Item stats shown in shops and the loot chest: the comparison against the
// item worn in the same slot, and what a consumable does.
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/widgets/item_stats.dart';

void main() {
  final items = <String, dynamic>{
    'old_sword': {
      'itemName': 'Old Sword',
      'itemType': 'Weapon',
      'isEquippable': true,
      'equipSlot': 'Weapon',
      'attackDamage': 4,
      'fireResist': 2,
    },
    'new_sword': {
      'itemName': 'New Sword',
      'itemType': 'Weapon',
      'isEquippable': true,
      'equipSlot': 'Weapon',
      'attackDamage': 7,
      'iceDmgBonus': 3,
    },
    'helm': {
      'itemName': 'Helm',
      'itemType': 'Armor',
      'isEquippable': true,
      'equipSlot': 'Head',
      'armor': 3,
    },
    'potion_minor': {'itemName': 'Potion', 'itemType': 'Potion'},
  };

  test('the counterpart is the item worn in the same slot', () {
    expect(
        equippedCounterpart(
            'new_sword', items['new_sword'], ['old_sword', 'helm'], items),
        'old_sword');
    expect(
        equippedCounterpart('new_sword', items['new_sword'], ['helm'], items),
        isNull);
    expect(
        equippedCounterpart(
            'potion_minor', items['potion_minor'], ['old_sword'], items),
        isNull,
        reason: 'a potion is not worn');
  });

  test('stat lines cover both items and give the difference', () {
    final lines =
        gearStatLines(items['new_sword'], items['old_sword'], AppLanguage.en);
    final byLabel = {for (final l in lines) l.label: l};
    expect(byLabel['ATK']!.delta, 3);
    expect(byLabel['Ice Dmg']!.delta, 3);
    expect(byLabel['Fire Resist']!.delta, -2);
    expect(byLabel.containsKey('ARM'), isFalse);
  });

  test('consumables say what they do', () {
    expect(
        consumableNote('potion_minor', items['potion_minor'], AppLanguage.en),
        contains('$potionHealAmount HP'));
    expect(consumableNote('antidote', {'itemType': 'Potion'}, AppLanguage.en),
        contains('poison'));
    expect(
        consumableNote('tome_of_mastery', {'itemType': 'Tome'}, AppLanguage.en),
        contains('skill point'));
    expect(consumableNote('new_sword', items['new_sword'], AppLanguage.en),
        isNull);
  });
}
