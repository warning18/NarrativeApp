// The Void Banner's own slot (v2.5.0, Wave 4 brief 5 of
// docs/simulation/wave4-briefs.md, the user's option A): the heirloom from
// chapter 1 is worn in a sixth slot, "Banner", so it no longer takes the
// body's place and a whole gear set can be worn beside it. Worn gear is a
// list of ids and the slot comes from the item, so an old save that wore
// the banner loads with it in its new slot and the body free.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final items =
      jsonDecode(File('assets/gamedata/items.json').readAsStringSync())
          as Map<String, dynamic>;

  test('the banner is the one item of its own slot', () {
    expect(equipSlotOptions, contains('Banner'));
    expect((items['void_banner'] as Map)['equipSlot'], 'Banner');
    expect([
      for (final MapEntry(:key, :value) in items.entries)
        if ((value as Map)['equipSlot'] == 'Banner') key,
    ], [
      'void_banner'
    ]);
  });

  test('a body piece is worn beside the banner, not in its place', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = PlayerSessionNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // An old save: the banner worn (it was in the body's slot then).
    await notifier.loadSession(PlayerSession.fromJson({
      'inventoryItemIds': ['void_banner', 'armor_leather'],
      'equippedItemIds': ['void_banner'],
    }));
    await notifier.equipItem('armor_leather',
        slot: (items['armor_leather'] as Map)['equipSlot'] as String,
        items: items);
    expect(notifier.state.equippedItemIds,
        unorderedEquals(['void_banner', 'armor_leather']));
  });
}
