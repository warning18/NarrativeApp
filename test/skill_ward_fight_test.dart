// Thornwall poisons the enemy that strikes it (v1.245).
import 'package:flutter_test/flutter_test.dart';

import 'skill_fight_harness.dart';

void main() {
  testWidgets("Thornwall poisons the enemy that strikes it", (tester) async {
    await playSkillRound(tester, 'warrior_thornwall');
    expect(inLog('strikes back at'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });
}
