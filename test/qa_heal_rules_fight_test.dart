// QA guards for the one healing rule (v1.866, lib/combat/heal_rules.dart) on
// the real fight screen: what a heal heals, from a die's Heal face, a spell
// (Mending Light) or a potion, in a fight played for real. Core's own
// test/heal_rules_test.dart holds the rule's steps; these hold that each path
// of the screen calls it.
//
//   * a shrine heals x1.5, for every source;
//   * fatigue: a non-cleric's later heals from the die heal less than its
//     first, a cleric's do not, a potion never tires;
//   * the Anvil-Deaf (briar guard with the anvil_deaf variant) gets nothing
//     from a Heal face, and a spell or a potion still heals.
// (The Watchfire past full is held by qa_mending_light_watchfire_test and
// qa_cleric_watchfire_tower_test.)
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart'
    show BattlefieldCondition, shrineHealMultiplier;

import 'support/qa_heal_fight.dart';

int _of(List<Heal> heals, String kind, [int nth = 0]) =>
    heals.where((h) => h.kind == kind).elementAt(nth).amount;

void main() {
  testWidgets('the heal rule on the screen: shrine, fatigue, Anvil-Deaf',
      (tester) async {
    // --- A shrine heals x1.5: die, spell and potion, against the same fight
    // on plain ground (a cleric: nothing tires).
    const script = [HealStep.spell, HealStep.potion, HealStep.round];
    final plain = await playHeals(tester, script);
    final shrine =
        await playHeals(tester, script, condition: BattlefieldCondition.shrine);
    for (final kind in ['spell', 'potion', 'die']) {
      final off = _of(plain, kind);
      final on = _of(shrine, kind);
      expect(on, closeTo(off * shrineHealMultiplier, 1),
          reason: 'a $kind heal on a shrine ($on) is x1.5 of the plain '
              'ground\'s ($off); plain: $plain; shrine: $shrine');
    }

    // --- Fatigue (fight_length.dart): a warrior's die heals, one a round.
    final warrior = await playHeals(
        tester, [HealStep.round, HealStep.round, HealStep.round],
        professionId: 'warrior');
    final dies = warrior.where((h) => h.kind == 'die').map((h) => h.amount);
    expect(dies, hasLength(3), reason: '$warrior');
    expect(dies.elementAt(1), lessThan(dies.elementAt(0)),
        reason: 'the 2nd heal tires: $warrior');
    expect(dies.elementAt(2), lessThan(dies.elementAt(1)),
        reason: 'the 3rd heal tires more: $warrior');
    // The cleric's Watchfire doesn't tire.
    final cleric = await playHeals(
        tester, [HealStep.round, HealStep.round, HealStep.round]);
    final cleric3 = cleric.where((h) => h.kind == 'die').map((h) => h.amount);
    expect(cleric3, hasLength(3), reason: '$cleric');
    expect(cleric3.toSet(), hasLength(1),
        reason: 'a cleric\'s heals do not tire: $cleric');
    // A potion never tires, a warrior's included, after heals from the die.
    final potions = await playHeals(
        tester,
        [
          HealStep.round,
          HealStep.round,
          HealStep.potion,
          HealStep.round,
          HealStep.potion,
        ],
        professionId: 'warrior');
    final drinks =
        potions.where((h) => h.kind == 'potion').map((h) => h.amount);
    expect(drinks, hasLength(2), reason: '$potions');
    expect(drinks.toSet(), hasLength(1),
        reason: 'a potion never tires: $potions');

    // --- The Anvil-Deaf: no Heal face heals, a potion still does.
    final deaf = await playHeals(tester, [HealStep.round, HealStep.potion],
        professionId: 'warrior',
        specIds: const ['briar_guard', 'anvil_deaf_briar_guard']);
    // (The foe's blow takes a point or so: a round that heals nothing ends
    // at or under where it began.)
    expect(_of(deaf, 'die'), lessThanOrEqualTo(0),
        reason: 'the Anvil-Deaf takes no Heal face: $deaf');
    expect(_of(deaf, 'potion'), greaterThan(0),
        reason: 'a potion still heals the Anvil-Deaf: $deaf');
  });
}
