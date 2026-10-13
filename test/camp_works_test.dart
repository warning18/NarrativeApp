// The building screen's data (camp_works.dart, docs/proposals/
// building-screen.md): every house in a category, coming with its tier's
// chapter, and what it still needs and where that is found.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/camp_works.dart';

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
}
