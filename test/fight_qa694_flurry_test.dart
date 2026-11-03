// Issue #694 (QA): a Flurry's second strike spends none of the
// Relicbreaker's mana the first already spent on its sure critical (as
// the simulator, sim_combat.dart).
import 'package:flutter_test/flutter_test.dart';

import 'fight_qa694_harness.dart';
import 'skill_fight_harness.dart';

void main() {
  testWidgets('a Flurry spends the Relicbreaker\'s mana once', (tester) async {
    await openQa694Fight(tester, professionId: 'rogue', session: {
      'specIds': ['relicbreaker'],
      'wisdom': 4,
      'mana': 6,
    });
    expect(shows('6/8'), isTrue);
    await tapWhenEnabled(tester, 'Roll Dice');
    await pumpUntil(tester, () => shows('Confirm'));
    await tapWhenEnabled(tester, 'Confirm');
    await pumpUntil(tester, () => shows('Round 2'));
    await settle(tester);
    // 6 less one sure critical (3), plus a mana per critical (1 or 2).
    expect(shows('4/8') || shows('5/8'), isTrue);
  });
}
