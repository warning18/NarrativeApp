// Issue #694 (QA): no die is rolled in the beat between a confirmed roll
// and the enemies' answer.
import 'package:flutter_test/flutter_test.dart';

import 'fight_qa694_harness.dart';
import 'skill_fight_harness.dart';

void main() {
  testWidgets('the dice wait while a round settles', (tester) async {
    await openQa694Fight(tester);
    await tapWhenEnabled(tester, 'Roll Dice');
    await pumpUntil(tester, () => shows('Confirm'));
    await tapWhenEnabled(tester, 'Confirm');
    // The beat before the enemies answer.
    await tester.pump(const Duration(milliseconds: 50));
    expect(buttonLabelled('Roll Dice')?.enabled, isFalse);
    await pumpUntil(tester, () => shows('Round 2'));
    await settle(tester);
    expect(buttonLabelled('Roll Dice')?.enabled, isTrue);
  });
}
