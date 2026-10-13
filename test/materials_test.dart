// The building economy's materials (materials.dart): the tiers, what the
// data asks for and pays, a house that waits on its materials, an
// expedition that pays them, and an old save given its rares once.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/materials.dart';
import 'package:narrative_data_app/data/shop_stock.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final items = _table('items');
  final houses = _table('houses');
  final zones = _table('zones');
  final shops = _table('shops');

  test('chapters fall in tiers of two', () {
    expect([for (var c = 1; c <= 8; c++) materialTierForChapter(c)],
        [1, 1, 2, 2, 3, 3, 4, 4]);
    expect(salvageMaterialFor(1), 'material_timber');
    expect(shipBattleMaterialFor(2), isNull);
    expect(shipBattleMaterialFor(5), 'material_shroud_thread');
  });

  test('every tier\'s materials are Material items of that tier', () {
    for (final MapEntry(key: tier, value: (:commons, :rare))
        in materialTiers.entries) {
      for (final id in [...commons, if (rare != null) rare]) {
        final item = items[id] as Map<String, dynamic>?;
        expect(item?['itemType'], 'Material', reason: id);
        expect(item?['materialTier'], tier, reason: id);
        expect(item?['itemName_fr'], isNotEmpty, reason: id);
        expect(item?['description_fr'], isNotEmpty, reason: id);
      }
    }
  });

  test('what houses cost and zones pay is a Material item, rares never sold',
      () {
    for (final (table, key) in [
      (houses, 'materialCost'),
      (zones, 'rewardMaterials'),
    ]) {
      for (final MapEntry(key: id, value: record) in table.entries) {
        for (final material
            in materialCountsOf(record as Map<String, dynamic>, key).keys) {
          expect((items[material] as Map?)?['itemType'], 'Material',
              reason: '$id: $material');
        }
      }
    }
    final rares = {
      for (final t in materialTiers.values)
        if (t.rare != null) t.rare!,
    };
    for (final MapEntry(key: id, value: shop) in shops.entries) {
      expect(
          allShopStock(shop as Map<String, dynamic>)
              .toSet()
              .intersection(rares),
          isEmpty,
          reason: id);
    }
    // Every house asks for materials now, every tier's rare gates one.
    expect([
      for (final h in houses.values)
        if (materialCountsOf(h as Map<String, dynamic>, 'materialCost').isEmpty)
          h
    ], isEmpty);
  });

  test('missing and spent materials count copies', () {
    const pack = ['material_timber', 'material_timber', 'material_cut_stone'];
    expect(missingMaterials(pack, {'material_timber': 2}), isEmpty);
    expect(
        missingMaterials(pack, {'material_timber': 3, 'material_cut_stone': 1}),
        {'material_timber': 1});
    expect(
        withoutMaterials(pack, {'material_timber': 2}), ['material_cut_stone']);
  });

  test('a save from before materials gets one rare a passed tier, once', () {
    // Chapter 7: tiers 2 and 3 are behind it.
    final old = PlayerSession.fromJson({
      'saveVersion': 3,
      'clockChapter': 7,
      'inventoryItemIds': ['potion'],
    });
    expect(old.inventoryItemIds,
        ['potion', 'material_ash_steel', 'material_shroud_thread']);
    // Saved again it carries the new version, and loading it adds nothing.
    final again = PlayerSession.fromJson(
        jsonDecode(jsonEncode(old.toJson())) as Map<String, dynamic>);
    expect(again.inventoryItemIds, old.inventoryItemIds);
    // An early save, or one already on the new version, gets nothing.
    expect(
        PlayerSession.fromJson({'saveVersion': 3, 'clockChapter': 3})
            .inventoryItemIds,
        isEmpty);
    expect(
        PlayerSession.fromJson(
                {'saveVersion': materialsSaveVersion, 'clockChapter': 8})
            .inventoryItemIds,
        isEmpty);
  });

  testWidgets('a house waits on its materials and spends them; a zone pays',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    late WidgetRef ref;
    await tester.pumpWidget(ProviderScope(
      child: Consumer(builder: (context, r, _) {
        ref = r;
        return const SizedBox.shrink();
      }),
    ));
    await tester.runAsync(() async {
      final notifier = ref.read(playerSessionProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await notifier.loadSession(PlayerSession.fromJson({
        'saveVersion': materialsSaveVersion,
        'gold': 500,
        'inventoryItemIds': ['material_timber'],
      }));
      const cost = {'material_timber': 2};
      await notifier.buildHouse('keldas_hall', 100, materialCost: cost);
      expect(ref.read(playerSessionProvider).builtHouseIds, isEmpty);

      await notifier.completeZone('z_fishermans_row',
          rewardMaterials: materialCountsOf(
              zones['z_fishermans_row'] as Map<String, dynamic>,
              'rewardMaterials'));
      expect(
          ref
              .read(playerSessionProvider)
              .inventoryItemIds
              .where((id) => id == 'material_timber'),
          hasLength(4));

      await notifier.buildHouse('keldas_hall', 100, materialCost: cost);
      final after = ref.read(playerSessionProvider);
      expect(after.builtHouseIds, ['keldas_hall']);
      expect(after.gold, 400);
      expect(after.inventoryItemIds, ['material_timber', 'material_timber']);
    });
  });
}
