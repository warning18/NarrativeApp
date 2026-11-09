// The one healing rule (v1.866, heal_rules.dart): each source against each
// step, so the fight screen and the simulator, which both call it, can't
// drift apart again.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart'
    show shrineHealMultiplier;
import 'package:narrative_data_app/combat/heal_rules.dart';

void main() {
  int half(int amount) => amount ~/ 2;
  int minusOne(int amount) => amount - 1;

  test('the Anvil-Deaf wall takes a Heal face, and only a face', () {
    for (final source in HealSource.values) {
      expect(healDealt(source: source, raw: 10, noHealFaces: true),
          source == HealSource.face ? 0 : 10,
          reason: source.name);
    }
  });

  test('a shrine heals more, whatever the source', () {
    for (final source in HealSource.values) {
      expect(healDealt(source: source, raw: 10, shrine: true),
          (10 * shrineHealMultiplier).round(),
          reason: source.name);
    }
  });

  test('the ground rule comes after the shrine, for every source', () {
    for (final source in HealSource.values) {
      expect(healDealt(source: source, raw: 10, shrine: true, roundRule: half),
          (10 * shrineHealMultiplier).round() ~/ 2,
          reason: source.name);
      // The cleric's heals too (the simulator's spell skipped it before).
      expect(
          healDealt(source: source, raw: 10, watchfire: true, roundRule: half),
          5,
          reason: '${source.name}, cleric');
    }
  });

  test('fatigue tires a face or a spell, never a potion or the cleric', () {
    var counted = 0;
    int tire(int amount) {
      counted++;
      return minusOne(amount);
    }

    expect(healDealt(source: HealSource.face, raw: 10, fatigue: tire), 9);
    expect(healDealt(source: HealSource.spell, raw: 10, fatigue: tire), 9);
    expect(counted, 2);
    expect(healDealt(source: HealSource.potion, raw: 10, fatigue: tire), 10);
    expect(
        healDealt(
            source: HealSource.face, raw: 10, watchfire: true, fatigue: tire),
        10);
    expect(
        healDealt(
            source: HealSource.spell, raw: 10, watchfire: true, fatigue: tire),
        10);
    // Nothing healed is nothing counted.
    expect(
        healDealt(
            source: HealSource.spell,
            raw: 10,
            roundRule: (_) => 0,
            fatigue: tire),
        0);
    expect(counted, 2);
  });

  test('what feeds the Watchfire past full', () {
    expect(healFeedsFire(source: HealSource.face, watchfire: true), isTrue);
    expect(healFeedsFire(source: HealSource.spell, watchfire: true), isTrue);
    expect(healFeedsFire(source: HealSource.face, watchfire: false), isFalse);
    expect(healFeedsFire(source: HealSource.potion, watchfire: true), isFalse);
    expect(
        healFeedsFire(
            source: HealSource.potion, watchfire: true, brimmingDraught: true),
        isTrue);
  });
}
