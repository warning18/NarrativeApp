// Winter's Hush stuns and weakens every enemy (v1.245).
import 'package:flutter_test/flutter_test.dart';

import 'skill_fight_harness.dart';

void main() {
  testWidgets("Winter's Hush stuns and weakens every enemy", (tester) async {
    await playSkillRound(tester, 'cleric_winter_hush', enemies: 2);
    expect(inLog('is stunned!'), findsNWidgets(2));
    expect(inLog('is weakened!'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });
}
