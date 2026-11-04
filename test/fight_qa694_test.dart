// Issue #694 (QA): a fight whose rewards fail to pay (a save that throws)
// can still be left: the error is reported and the return button opens.
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';

import 'fight_qa694_harness.dart';
import 'skill_fight_harness.dart';

/// A session whose first reward call throws, as a failed save would.
class _BrokenPurse extends PlayerSessionNotifier {
  @override
  Future<void> noteFightWonOnLadder({required bool tutorial}) async =>
      throw StateError('the purse would not open');
}

void main() {
  testWidgets('a fight whose rewards fail to pay can still be left',
      (tester) async {
    await openQa694Fight(tester, enemyHealth: 1, notifier: _BrokenPurse.new);
    await tapWhenEnabled(tester, 'Roll Dice');
    await pumpUntil(tester, () => shows('Confirm'));
    await tapWhenEnabled(tester, 'Confirm');
    await pumpUntil(tester, () => shows('Victory! Return'));
    await settle(tester);
    expect(tester.takeException(), isA<StateError>());
    expect(buttonLabelled('Victory! Return')?.enabled, isTrue);
  });
}
