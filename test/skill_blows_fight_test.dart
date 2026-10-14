// Gale Cut lands two blows, one after the other (v1.245).
import 'package:flutter_test/flutter_test.dart';

import 'skill_fight_harness.dart';

void main() {
  testWidgets("Gale Cut lands two blows, one after the other", (tester) async {
    await playSkillRound(tester, 'rogue_gale_cut');
    expect(inLog('Blow 1:'), findsOneWidget);
    expect(inLog('Blow 2:'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 3));
  });
}
