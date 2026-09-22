// Unit coverage for the pure, RNG-free telegraph-preview helpers in
// lib/combat/combat_engine.dart: telegraphTierFor's threshold bucketing and
// categoryFor's move classification. Neither function touches
// resolveEnemyMove's own move-selection logic or RNG consumption, so this
// file doesn't need a seeded Random anywhere -- every case here is a plain
// int-in/int-out or object-in/enum-out check.

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/combat/status_effect.dart';

void main() {
  group('telegraphTierFor', () {
    test('effectivePerception 0 (perception == guile) sees nothing', () {
      expect(telegraphTierFor(5, 5), TelegraphTier.none);
    });

    test('effectivePerception 1 sees who only', () {
      expect(telegraphTierFor(1, 0), TelegraphTier.target);
    });

    test('effectivePerception 4 still sees who only', () {
      expect(telegraphTierFor(4, 0), TelegraphTier.target);
    });

    test('effectivePerception 5 crosses into the category tier', () {
      expect(telegraphTierFor(5, 0), TelegraphTier.category);
    });

    test('effectivePerception 9 is still the category tier', () {
      expect(telegraphTierFor(9, 0), TelegraphTier.category);
    });

    test('effectivePerception 10 crosses into full detail', () {
      expect(telegraphTierFor(10, 0), TelegraphTier.full);
    });

    test('a much higher guile than perception clamps to 0, not negative', () {
      expect(telegraphTierFor(2, 5), TelegraphTier.none);
    });

    test('guile directly offsets perception', () {
      // effectivePerception = 12 - 8 = 4 -> target tier, not full.
      expect(telegraphTierFor(12, 8), TelegraphTier.target);
    });
  });

  group('categoryFor', () {
    test('a move that inflicts a status reads as statusDebuff', () {
      const move = EnemyMoveResult(
        damage: 20,
        message: 'A venomous strike!',
        inflictedStatus:
            StatusEffect(type: StatusEffectType.poison, remainingTurns: 3),
      );
      expect(categoryFor(move), MoveCategory.statusDebuff);
    });

    test(
        'a status-inflicting move reads as statusDebuff even though it also '
        'deals damage', () {
      const move = EnemyMoveResult(
        damage: 15,
        message: 'A crippling blow!',
        inflictedStatus:
            StatusEffect(type: StatusEffectType.weaken, remainingTurns: 2),
      );
      expect(categoryFor(move), MoveCategory.statusDebuff);
    });

    test('a move with healAmount and no damage reads as healSelf', () {
      const move = EnemyMoveResult(
        damage: 0,
        message: 'It knits its wounds shut.',
        healAmount: 10,
      );
      expect(categoryFor(move), MoveCategory.healSelf);
    });

    test('a plain damaging move with no status or heal reads as attack', () {
      const move = EnemyMoveResult(damage: 18, message: 'It attacks!');
      expect(categoryFor(move), MoveCategory.attack);
    });

    test(
        'a move dealing damage AND carrying a heal still reads as attack '
        'when no status is inflicted', () {
      const move = EnemyMoveResult(
        damage: 12,
        message: 'A draining strike!',
        healAmount: 6,
      );
      expect(categoryFor(move), MoveCategory.attack);
    });
  });
}
