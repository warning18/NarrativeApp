// Chain Lightning leaps to one other enemy (v1.245).
import 'package:flutter_test/flutter_test.dart';

import 'skill_fight_harness.dart';

void main() {
  testWidgets("Chain Lightning leaps to one other enemy", (tester) async {
    await playSkillRound(tester, 'mage_chain_lightning', enemies: 3);
    expect(inLog('The strike leaps to'), findsOneWidget);
    expect(inLog('is caught by the blow'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });
}
