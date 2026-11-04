// Who holds a region, for the world map's Clans layer (region_holders.dart):
// a region and a chart land tinted by the clan holding its places, striped
// when a second holds as many.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/region_holders.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final geo =
      Geography.parse(geography: _table('geography'), biomes: _table('biomes'));
  const empty = PoliticsState.empty;

  test('the story chart: Saltmouth\'s land takes its holder', () {
    final chart = chartOf(MapShape.story);
    final zones = chartZoneHolders(chart, geo, empty);
    expect(zones, hasLength(chart.zones.length));
    final at = chart.places['saltmouth']!;
    final i = chart.zones.indexWhere((z) => pointInPolygon(at, z.polygon));
    expect(i, greaterThanOrEqualTo(0));
    expect(zones[i], isNotEmpty);
    final taken = empty.copyWith(
        control: {for (final id in holdings(geo, empty).keys) id: 'vigil'});
    expect(chartZoneHolders(chart, geo, taken)[i], [('vigil', 1.0)]);
  });
}
