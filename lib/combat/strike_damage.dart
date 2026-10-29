// The damage a party member's strike starts from, before the dice, the
// signs and the ground: one sum for the fight screen (fight_queries.dart)
// and the simulator (sim_combat.dart), so the two never drift apart.
import '../models/ally_state.dart'
    show alignmentGearBonusFor, equipmentBonusFor, equipmentScalingBonusFor;
import 'combat_engine.dart' show elementFieldPrefixes;

/// What [equippedItemIds] add to a hit of [element]: their
/// `<element>DmgBonus` (0 for an element with no field, or none).
int elementalDamageBonusFor(
  String element,
  List<String> equippedItemIds,
  Map<String, dynamic> items,
) {
  final prefix = elementFieldPrefixes[element];
  if (prefix == null) return 0;
  return equipmentBonusFor(equippedItemIds, items, '${prefix}DmgBonus');
}

/// A strike of [element]'s damage before the dice: [baseDamage], the
/// gear's `attackDamage`, its stat scaling, its alignment bonus (worn by
/// a hero of [alignmentLabel]), the worn sets' and uniques' attack
/// ([gearAttack], gear_effects.dart) and the element's bonus.
int strikeDamageFor({
  required int baseDamage,
  required List<String> equippedItemIds,
  required Map<String, dynamic> items,
  required String element,
  required int gearAttack,
  required int strength,
  required int dexterity,
  required int constitution,
  required int intelligence,
  required String alignmentLabel,
}) =>
    baseDamage +
    equipmentBonusFor(equippedItemIds, items, 'attackDamage') +
    equipmentScalingBonusFor(equippedItemIds, items,
            strength: strength,
            dexterity: dexterity,
            constitution: constitution,
            intelligence: intelligence)
        .damageBonus +
    alignmentGearBonusFor(equippedItemIds, items, alignmentLabel).damageBonus +
    gearAttack +
    elementalDamageBonusFor(element, equippedItemIds, items);
