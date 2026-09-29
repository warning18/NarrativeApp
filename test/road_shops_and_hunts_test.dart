// v1.178: a stall met on the road moves on with it (the Wayfarer's Caravan
// and a detour's or an expedition's stall are never browsable later from
// the Shops list), the hunters' cooldown is kept in the session, and a
// quest taken on in a scene counts its bounty from then on.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/alignment_events.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

Future<PlayerSessionNotifier> _notifier(Map<String, dynamic> json) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(PlayerSession.fromJson(
      {'raceId': 'human', 'professionId': 'warrior', ...json}));
  return notifier;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a stall met on the road is marked so, never over its own town',
      () async {
    final notifier = await _notifier(const {});
    await notifier.unlockContent(
        shopId: 'wayfarer_caravan', shopUnlockNodeId: roadShopNodeId);
    expect(notifier.state.unlockedShopIds, contains('wayfarer_caravan'));
    expect(
        notifier.state.shopUnlockNodeIds['wayfarer_caravan'], roadShopNodeId);
    // Found in its town first, a shop stays there when met on a detour.
    await notifier.unlockContent(
        shopId: 'apothecary_row', shopUnlockNodeId: '2015');
    await notifier.unlockContent(
        shopId: 'apothecary_row', shopUnlockNodeId: roadShopNodeId);
    expect(notifier.state.shopUnlockNodeIds['apothecary_row'], '2015');
    // Met on the road first, then found in its town: the town has it.
    await notifier.unlockContent(
        shopId: 'last_lantern', shopUnlockNodeId: roadShopNodeId);
    await notifier.unlockContent(
        shopId: 'last_lantern', shopUnlockNodeId: '5010');
    expect(notifier.state.shopUnlockNodeIds['last_lantern'], '5010');
  });

  test('the hunters’ cooldown is counted and survives a save', () async {
    final notifier = await _notifier(const {});
    expect(notifier.state.alignmentRollsSinceAmbush, hunterCooldownRolls);
    await notifier.noteAlignmentRoll(ambushed: true);
    expect(notifier.state.alignmentRollsSinceAmbush, 0);
    await notifier.noteAlignmentRoll(ambushed: false);
    await notifier.noteAlignmentRoll(ambushed: false);
    expect(notifier.state.alignmentRollsSinceAmbush, 2);
    final back = PlayerSession.fromJson(notifier.state.toJson());
    expect(back.alignmentRollsSinceAmbush, 2);
    for (var i = 0; i < 10; i++) {
      await notifier.noteAlignmentRoll(ambushed: false);
    }
    expect(notifier.state.alignmentRollsSinceAmbush, hunterCooldownRolls);
  });

  test('a quest taken on in a scene counts its bounty from then', () async {
    final notifier = await _notifier(const {
      'enemyKillCounts': {'angel_sentinel': 3},
    });
    await notifier.applyChoiceEffects(questIDToProgress: darkQuestId);
    expect(notifier.state.activeQuestIds, contains(darkQuestId));
    expect(
        notifier.state.questKillBaselines[darkQuestId]?['angel_sentinel'], 3);
  });
}
