// fightGroundAt (lib/combat/fight_ground_rule.dart): the one ground rule
// the fight screen and the playthrough simulator share (v1.884), on the
// game's own geography.
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/context_rules.dart';
import 'package:narrative_data_app/combat/field_anomaly.dart';
import 'package:narrative_data_app/combat/fight_ground_rule.dart';
import 'package:narrative_data_app/data/geography.dart';

import 'support/sim_world.dart';

void main() {
  final world = Geography.parse(
      geography: simTable('geography'), biomes: simTable('biomes'));
  final ids = world.places.keys.toList()..sort();
  ContextRule ruleAt(String? id, {FightStage? stage, bool boss = false}) =>
      fightGroundAt(world, id, forcedStage: stage, bossFight: boss).rule;

  test('a boss is fought on the Tide wherever it stands', () {
    for (final id in ids) {
      expect(ruleAt(id, boss: true), ContextRule.tide, reason: id);
    }
  });

  test('the watch keeps a city, a holy place has its ground', () {
    final city = ids
        .firstWhere((id) => guardedPlaceKinds.contains(world.place(id)?.kind));
    expect(ruleAt(city), ContextRule.townGuards);
    final holy = ids.firstWhere((id) =>
        world.tagsOf(id).contains('holy') &&
        !guardedPlaceKinds.contains(world.place(id)?.kind));
    expect(ruleAt(holy), ContextRule.sanctified);
  });

  test('a scene that names its stage plays that stage\'s ground', () {
    final open = ids.firstWhere((id) =>
        !world.tagsOf(id).contains('holy') &&
        !guardedPlaceKinds.contains(world.place(id)?.kind));
    expect(ruleAt(open, stage: FightStage.reeds), ContextRule.marshMist);
    expect(ruleAt(open, stage: FightStage.dunes), ContextRule.desertHeat);
    expect(ruleAt(open, stage: FightStage.shipDeck), ContextRule.risingWater);
    expect(fightStageAt(world, open, forcedStage: FightStage.reeds),
        FightStage.reeds);
  });

  test('no place known: open country, on the Tide', () {
    expect(ruleAt(null), ContextRule.tide);
  });

  test('the world holds more than one ground', () {
    final rules = {for (final id in ids) ruleAt(id)};
    expect(rules.length, greaterThanOrEqualTo(4), reason: '$rules');
  });
}
