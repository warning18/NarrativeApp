// The scenes set inside a building stand in one (v1.470): the Journey draws
// a building's own rooms (RoomPlan.ofBuilding) only when the scene's
// `location` is a geography.json building. Wave 14 audited the story for
// scenes the text puts indoors (a cell, a chapel, a forge, a hall, an
// archive, a cellar, a shop): 99 scenes here, of which 7 stood in a building
// before (the Blind Beggar) and the rest showed streets. 94 stand in one now;
// the 5 in [_waiting] have their building but wait: 3 are seated by
// Narrative in another district than their room's, and 2 would make a
// roll's other branch a move with no note
// (docs/proposals/journey-world-data.md).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/room_plan.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// The scenes the text sets inside a building (the audit's list).
const _interiorScenes = [
  '100',
  '105',
  '106',
  '110',
  '115',
  '120',
  '125',
  '800',
  '816',
  '820',
  '822',
  '822_lie_failed',
  '823',
  '2015_house_keyholders_turned',
  '2015_lysa_line',
  '3002',
  '3010_rope_fail',
  '3030',
  '4999',
  '4999_standard',
  '4999_drawn',
  '3020',
  '3040',
  '3050',
  '3005_archive',
  '3005_archive_failed',
  '3005_ledger',
  '3005_ledger_failed',
  '3005_logbook_gap',
  '5003',
  '5004',
  '5004b',
  '5004_altar',
  '5005',
  '5010_archivist',
  '5010_wisps',
  '5010_tobin',
  '5010_archivist_words',
  '5010_tobin_hymn',
  '5010_letter',
  '5010_brannoc',
  '5010_imeh_later',
  '5010_bark_cache',
  '5010_bark_cache_fight',
  '6010_clement_refused',
  '6010_lysa_rescued',
  '6010_lysa_sworn',
  '6010_lysa_mercy',
  '6010_lysa_sacrifice',
  '3100_house_anvil_deaf',
  '3100_widow',
  '3100_widow_later',
  '3200_smith',
  '3200_blade',
  '5200_riddles',
  '5200_riddles_failed',
  '5200_nell',
  '5200_nell_later',
  '5200_sleep',
  '6100_bell',
  '6100_bell_failed',
  '6100_clan_mire_2_found',
  '6100_clan_mire_2_fourth',
  '6200_clan_compact_2',
  '6200_clan_compact_2_refused',
  '6200_hearth',
  '6200_ghrem',
  '7100_log',
  '7100_chaplain',
  '7100_chandlery',
  '7100_clan_crows_3',
  '7100_impound',
  '7100_impound_fight',
  '7520_vane',
  '7520_tallis',
  '7800_council',
  '6010_lysa_dead',
  '6010_record',
  '7590_dominion',
  '7590_vigil',
  '7590_compact',
  '7590_mire',
  '7590_crows',
  '7590_penitents',
  '7590_open_hand',
  '6010_clan_dominion_2',
  '6010_clan_compact_3',
  '6010_clan_compact_3_seen',
  '6010_clan_compact_3_hammer',
  '6010_chartkeeper',
  '6010_chartkeeper_words',
  '6010_chart_bought',
  '6010_spawn',
  '6010_returned_roll',
];

/// Indoor scenes left at their district for now, with the building each
/// goes into: Narrative seats three elsewhere (district_seats.json); the
/// rest would make a roll's other branch a move with no note.
const _waiting = {
  '5200_house_returned': 'kindly_hill_long_room',
  '6010_thread': 'reliquary_chartkeeper_chapel',
  '6010_heist_night': 'reliquary_chartkeeper_chapel',
  '3100_house_anvil_deaf_failed': 'emberwick_cold_forge',
  '5200': 'kindly_hill_long_room',
};

void main() {
  final geo =
      Geography.parse(geography: _json('assets/gamedata/geography.json'));
  final story = _json('assets/Cleaned_Narrative_DAG.json');
  String locationOf(String scene) =>
      (story[scene] as Map<String, dynamic>)['location'] as String;
  String? spotOf(String scene) =>
      (story[scene] as Map<String, dynamic>)['spot'] as String?;
  RoomPlan planOf(GeoPlace b) => RoomPlan.ofBuilding(b.id, b.kind, b.name);

  test('every scene set inside stands in a building', () {
    expect(_interiorScenes.toSet(), hasLength(_interiorScenes.length));
    final outside = [
      for (final scene in _interiorScenes)
        if (geo.place(locationOf(scene))?.isBuilding != true) scene,
    ];
    expect(
        _interiorScenes.toSet().intersection(_waiting.keys.toSet()), isEmpty);
    expect(outside, isEmpty);
    // The waiting ones name buildings that exist, and stand in the same
    // place for now.
    for (final MapEntry(:key, :value) in _waiting.entries) {
      expect(story.containsKey(key), isTrue, reason: key);
      expect(geo.place(value)?.isBuilding, isTrue, reason: value);
      expect(geo.locationOf(value)?.id, geo.locationOf(locationOf(key))?.id,
          reason: key);
    }
    expect(_interiorScenes.length + _waiting.length, 99);
  });

  test('a scene\'s spot is a spot of its building\'s plan', () {
    var spots = 0;
    for (final MapEntry(:key, :value) in story.entries) {
      final spot = (value as Map<String, dynamic>)['spot'] as String?;
      if (spot == null) continue;
      final here = geo.place(value['location'] as String?);
      expect(here?.isBuilding, isTrue, reason: '$key has a spot outdoors');
      expect(planOf(here!).has(spot), isTrue,
          reason: '$key: "$spot" is not a spot of ${here.id} '
              '(${planOf(here).anchors.keys})');
      spots++;
    }
    expect(spots, greaterThan(40));
  });

  test('every building is laid as a kind of its own and has a scene', () {
    final used = {for (final v in story.values) (v as Map)['location']};
    for (final b in geo.places.values.where((p) => p.isBuilding)) {
      expect(geoBuildingKinds, contains(b.kind), reason: b.id);
      expect(
          RoomKind.of(RoomKind.resolve(b.kind, b.name)), isNot(RoomKind.plain),
          reason: b.id);
      expect(used.contains(b.id) || _waiting.containsValue(b.id), isTrue,
          reason: '${b.id} holds no scene');
      // In a city with districts, a building stands in one of them.
      final parent = geo.place(b.parent)!;
      expect(
          parent.level == GeoLevel.district ||
              !geo
                  .childrenOf(parent.id)
                  .any((c) => c.level == GeoLevel.district),
          isTrue,
          reason: b.id);
    }
  });

  test('known rooms: the Hall of Records, the throne room, the cells', () {
    final records = geo.place(locationOf('3020'))!;
    expect(records.id, 'spire_hall_of_records');
    expect(RoomKind.resolve(records.kind, records.name), 'library');
    expect(geo.locationOf(records.id)?.id, 'spire_of_judgment');

    final throne = geo.place(locationOf('7520_vane'))!;
    expect(throne.id, 'candlehold_throne_room');
    expect(geo.ancestorAt(throne.id, GeoLevel.district)?.id,
        'candlehold_lantern_hall');
    expect(spotOf('7520_vane'), 'throne');
    expect(planOf(throne).has('throne'), isTrue);

    final cells = geo.place(locationOf('800'))!;
    expect(RoomKind.resolve(cells.kind, cells.name), 'prison');
    expect(spotOf('800'), 'cells');
    // The Blind Beggar keeps its own.
    expect(locationOf('100'), 'blind_beggar');
  });

  test('a building\'s plan is the same on every visit', () {
    final b = geo.place('kindly_hill_long_room')!;
    expect(planOf(b).anchors, planOf(b).anchors);
    expect(RoomPlan.seedOf('blind_beggar'), RoomPlan.seedOf('blind_beggar'));
    expect(RoomPlan.seedOf('a'), isNot(RoomPlan.seedOf('b')));
  });
}
