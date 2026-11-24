/// The elemental points a character carries (v1.224): for each element, the
/// damage bonus and the resistance its equipped items give (an item's
/// `<prefix>DmgBonus` and `<prefix>Resist`, see elementFieldPrefixes).
library;

import '../combat/combat_engine.dart' show elementFieldPrefixes;
import '../models/ally_state.dart' show equipmentBonusFor;

/// The elements in the order a chart draws them, clockwise from the top:
/// opposites sit across from each other (fire and ice, wind and earth,
/// water and lightning, light and void).
const List<String> elementChartOrder = [
  'Fire',
  'Wind',
  'Water',
  'Light',
  'Ice',
  'Earth',
  'Electricity',
  'Void',
];

class ElementPoints {
  const ElementPoints(this.damage, this.resist);

  /// Element name -> points.
  final Map<String, int> damage;
  final Map<String, int> resist;

  bool get isEmpty =>
      damage.values.every((v) => v == 0) && resist.values.every((v) => v == 0);

  int get highest =>
      [...damage.values, ...resist.values].fold(0, (m, v) => v > m ? v : m);

  List<double> damageInOrder() =>
      [for (final e in elementChartOrder) (damage[e] ?? 0).toDouble()];
  List<double> resistInOrder() =>
      [for (final e in elementChartOrder) (resist[e] ?? 0).toDouble()];
}

/// What [equippedItemIds] give in each element, off the items table.
ElementPoints elementPointsFor(
    List<String> equippedItemIds, Map<String, dynamic> items) {
  final damage = <String, int>{};
  final resist = <String, int>{};
  for (final element in elementChartOrder) {
    final prefix = elementFieldPrefixes[element]!;
    damage[element] =
        equipmentBonusFor(equippedItemIds, items, '${prefix}DmgBonus');
    resist[element] =
        equipmentBonusFor(equippedItemIds, items, '${prefix}Resist');
  }
  return ElementPoints(damage, resist);
}

/// The scale a chart of [highest] points draws to: a round number at least
/// [floor], so a small kit does not fill the chart and a big one fits it.
double chartScaleFor(int highest, {required int floor, required int step}) {
  final need = highest < floor ? floor : highest;
  return (((need + step - 1) ~/ step) * step).toDouble();
}
