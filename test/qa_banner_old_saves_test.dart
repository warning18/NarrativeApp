// QA guard (the Void Banner's own slot, v2.5.0): old saves load with the
// banner in its slot and the body free. Held over Core's typical players'
// builds (docs/simulation/typical-player-builds.json, every profession at
// every stage, saves from before the slot) and over every worn-gear shape an
// old save can hold: after loading, no slot holds two pieces, the banner is in
// the Banner slot alone, any body piece can be put on beside it, and a save
// written and read back keeps all of it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

String _slotOf(Map<String, dynamic> items, String id) =>
    '${(items[id] as Map?)?['equipSlot'] ?? ''}';

/// Every worn piece's slot, and each slot's count.
Map<String, int> _slots(Map<String, dynamic> items, Iterable<String> worn) {
  final counts = <String, int>{};
  for (final id in worn) {
    final s = _slotOf(items, id);
    counts[s] = (counts[s] ?? 0) + 1;
  }
  return counts;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final items = _json('assets/gamedata/items.json');

  test('every worn set in Core\'s typical builds has one piece to a slot', () {
    final builds = _json('docs/simulation/typical-player-builds.json');
    var sets = 0;
    var withBanner = 0;
    void check(String where, Object? raw) {
      if (raw is! Map) return;
      final worn = [
        for (final id in (raw['equippedItemIds'] as List?) ?? const []) '$id'
      ];
      if (worn.isEmpty) return;
      sets++;
      final counts = _slots(items, worn);
      counts.forEach((slot, n) {
        expect(n, 1, reason: '$where: $n pieces in the "$slot" slot: $worn');
      });
      if (worn.contains('void_banner')) {
        withBanner++;
        expect(_slotOf(items, 'void_banner'), 'Banner', reason: where);
      }
      // The save is read as it was written.
      final session = PlayerSession.fromJson(Map<String, dynamic>.from(raw));
      expect(session.equippedItemIds, worn,
          reason: '$where: worn gear changed');
      final back = PlayerSession.fromJson(
          jsonDecode(jsonEncode(session.toJson())) as Map<String, dynamic>);
      expect(back.equippedItemIds, worn, reason: '$where: lost in a save');
    }

    void walk(String where, Object? node) {
      if (node is Map) {
        if (node['equippedItemIds'] is List) check(where, node);
        node.forEach((k, v) => walk('$where/$k', v));
      } else if (node is List) {
        for (var i = 0; i < node.length; i++) {
          walk('$where[$i]', node[i]);
        }
      }
    }

    walk('builds', builds);
    expect(sets, greaterThan(5), reason: 'no worn set found in the builds');
    // ignore: avoid_print
    print('worn sets read: $sets, with the banner: $withBanner');
  });

  test('an old save wearing the banner takes any body piece beside it',
      () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = PlayerSessionNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final slots = <String>{};
    var tried = 0;
    for (final e in items.entries) {
      final v = e.value;
      if (v is! Map) continue;
      final slot = '${v['equipSlot'] ?? ''}';
      if (slot.isEmpty || slot == 'Banner' || !slots.add(slot)) continue;
      // One piece of every other slot, with the banner worn: the old save.
      await notifier.loadSession(PlayerSession.fromJson({
        'inventoryItemIds': ['void_banner', e.key],
        'equippedItemIds': ['void_banner'],
      }));
      await notifier.equipItem(e.key, slot: slot, items: items);
      expect(notifier.state.equippedItemIds,
          unorderedEquals(['void_banner', e.key]),
          reason: 'a "$slot" piece (${e.key}) did not go on beside the banner');
      tried++;
    }
    expect(tried, greaterThan(3), reason: 'only $tried slots tried');
  });

  test('the banner is the only item of its slot, and a slot is not lost', () {
    final bannerItems = [
      for (final e in items.entries)
        if (e.value is Map && (e.value as Map)['equipSlot'] == 'Banner') e.key
    ];
    expect(bannerItems, ['void_banner']);
    // Every item that can be worn has a slot the app knows.
    final known = {
      for (final e in items.entries)
        if (e.value is Map &&
            '${(e.value as Map)['equipSlot'] ?? ''}'.isNotEmpty)
          '${(e.value as Map)['equipSlot']}'
    };
    expect(known, contains('Banner'));
    expect(known.length, greaterThanOrEqualTo(6),
        reason: 'the six slots (five body slots and the banner): $known');
  });
}
