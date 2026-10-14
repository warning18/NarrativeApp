// The building screen's data (camp_works.dart, docs/proposals/
// building-screen.md): every house in a category, coming with its tier's
// chapter, and what it still needs and where that is found.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/camp_works.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final houses = _table('houses');
  final zones = _table('zones');
  final shops = _table('shops');

  Map<WorkCategory, List<CampWork>> works({
    int chapter = 3,
    List<String> flags = const [],
    int gold = 0,
    List<String> inventory = const [],
    List<String> built = const [],
    List<String> allies = const [],
  }) =>
      campWorksOf(
        houses: houses,
        zones: zones,
        shops: shops,
        chapter: chapter,
        flags: flags,
        gold: gold,
        inventory: inventory,
        builtHouseIds: built,
        recruitedAllyIds: allies,
      );

  CampWork work(Map<WorkCategory, List<CampWork>> all, String id) =>
      all.values.expand((w) => w).firstWhere((w) => w.houseId == id);

  test('every house is in a category, its own field matching what it gives',
      () {
    final all = works();
    expect(all.values.expand((w) => w).map((w) => w.houseId).toSet(),
        houses.keys.toSet());
    for (final MapEntry(:key, :value) in houses.entries) {
      final record = Map<String, dynamic>.of(value as Map<String, dynamic>);
      final named = workCategoryOf(key, record);
      record.remove('category');
      expect(workCategoryOf(key, record), named, reason: key);
    }
    expect(all[WorkCategory.sea]!.map((w) => w.houseId), ['harbor']);
    expect(all[WorkCategory.greatWorks]!.map((w) => w.houseId),
        ['hearth_hall', 'banner_loft', 'shroud_shrine']);
  });

  test('a house comes with its tier\'s chapter', () {
    expect(work(works(), 'harbor').chapter, 1);
    expect(work(works(), 'hammersmith').chapter, 3);
    expect(work(works(), 'banner_loft').chapter, 5);
    final early = work(works(chapter: 4), 'shroud_shrine');
    expect(early.state, WorkState.locked);
    expect(early.needs.single.kind, WorkNeedKind.chapter);
    expect(work(works(chapter: 5), 'shroud_shrine').state, WorkState.shown);
  });

  test('a companion\'s house waits for the companion', () {
    final kelda = work(works(), 'keldas_hall');
    expect(kelda.state, WorkState.locked);
    expect(kelda.needs.single.kind, WorkNeedKind.ally);
    expect(
        work(works(allies: ['kelda']), 'keldas_hall').state, WorkState.shown);
  });

  test('what is missing says where to find it', () {
    final hammersmith = work(works(), 'hammersmith');
    expect(hammersmith.state, WorkState.shown);
    final flag =
        hammersmith.needs.firstWhere((n) => n.kind == WorkNeedKind.flag);
    expect(flag.zoneIds, contains('z_scaffold_yards'));
    final ore = hammersmith.needs.firstWhere(
        (n) => n.kind == WorkNeedKind.material && n.id == 'material_iron_ore');
    expect(ore.need, 3);
    expect(ore.shopIds, isNotEmpty);
    expect(hammersmith.needs.map((n) => n.kind), contains(WorkNeedKind.gold));
    // A rare is never sold.
    final hearth = work(works(), 'hearth_hall');
    final ash = hearth.needs.firstWhere((n) => n.id == 'material_ash_steel');
    expect(ash.shopIds, isEmpty);
  });

  test('the Shroud Shrine opens on the Dead Heart or on the Shroud\'s Vigil',
      () {
    WorkNeed flagNeed(List<String> flags) =>
        work(works(chapter: 5, flags: flags), 'shroud_shrine').needs.firstWhere(
            (n) => n.kind == WorkNeedKind.flag,
            orElse: () => const WorkNeed(kind: WorkNeedKind.gold));
    final waiting = flagNeed(const []);
    expect(waiting.id, 'dead_heart_cleared');
    expect(waiting.zoneIds,
        containsAll(['z_dead_heart_approach', 'z_shroud_vigil']));
    expect(flagNeed(const ['dead_heart_cleared']).kind, WorkNeedKind.gold);
    expect(flagNeed(const ['shroud_vigil_cleared']).kind, WorkNeedKind.gold);
  });

  test('buildable once everything is there, and built once up', () {
    final harbour = work(
        works(inventory: [
          for (var i = 0; i < 4; i++) 'material_timber',
          'material_cut_stone',
          'material_cut_stone',
        ]),
        'harbor');
    expect(harbour.state, WorkState.buildable);
    expect(harbour.needs, isEmpty);
    expect(work(works(built: ['harbor']), 'harbor').state, WorkState.built);
    // Built stays built, whatever the chapter.
    expect(work(works(chapter: 1, built: ['banner_loft']), 'banner_loft').state,
        WorkState.built);
  });

  test('every section has its name and blurb in both languages', () {
    for (final category in WorkCategory.values) {
      for (final key in [
        'works_category_${category.name}',
        'works_category_${category.name}_blurb',
      ]) {
        for (final lang in AppLanguage.values) {
          expect(trFor(lang, key), isNot(key), reason: '$key $lang');
        }
      }
    }
  });

  testWidgets('a locked house is refused: its chapter, its companion',
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
      await notifier.loadSession(PlayerSession.fromJson({'gold': 100}));
      await notifier.buildHouse('banner_loft', 0, fromChapter: 5, chapter: 4);
      await notifier.buildHouse('keldas_hall', 0, requiredAllyId: 'kelda');
      expect(ref.read(playerSessionProvider).builtHouseIds, isEmpty);
      await notifier.buildHouse('banner_loft', 0, fromChapter: 5, chapter: 5);
      expect(ref.read(playerSessionProvider).builtHouseIds, ['banner_loft']);
      await notifier.buildHouse('shroud_shrine', 0,
          requiredFlags: ['dead_heart_cleared']);
      expect(ref.read(playerSessionProvider).builtHouseIds, ['banner_loft']);
      // The Shroud's Vigil opens it on its own.
      await notifier.loadSession(PlayerSession.fromJson({
        'gold': 100,
        'flags': ['shroud_vigil_cleared'],
      }));
      await notifier.buildHouse('shroud_shrine', 0,
          requiredFlags: ['dead_heart_cleared'],
          unlockedByFlags: ['shroud_vigil_cleared']);
      expect(ref.read(playerSessionProvider).builtHouseIds, ['shroud_shrine']);
    });
  });
}
