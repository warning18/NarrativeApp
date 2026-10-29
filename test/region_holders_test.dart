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

  /// The clan holding the most places in [region] (geography.json's).
  String most(String region) {
    final counts = <String, int>{};
    for (final e in holdings(geo, empty).entries) {
      if (geo.countryOf(e.key)?.id == region) {
        counts[e.value] = (counts[e.value] ?? 0) + 1;
      }
    }
    return (counts.entries.toList()..sort((a, b) => b.value - a.value))
        .first
        .key;
  }

  test('every region is listed; a region is held by who holds its places', () {
    final regions = regionHolders(geo, empty);
    expect(regions.keys, containsAll(['salt_coast', 'grey_fen', 'the_waste']));
    final salt = regions['salt_coast']!;
    expect(salt, isNotEmpty);
    expect(salt.first.$2, 1.0);
    expect(salt.first.$1, most('salt_coast'));
  });

  test('a clan taking every place of the Salt Coast tints it alone', () {
    var state = empty;
    for (final e in holdings(geo, empty).entries) {
      if (geo.countryOf(e.key)?.id == 'salt_coast') {
        state = state.copyWith(control: {...state.control, e.key: 'mire'});
      }
    }
    expect(regionHolders(geo, state)['salt_coast'], [('mire', 1.0)]);
  });

  test('two clans holding as many places contest it', () {
    final salt = [
      for (final e in holdings(geo, empty).entries)
        if (geo.countryOf(e.key)?.id == 'salt_coast') e.key,
    ];
    expect(salt.length, greaterThanOrEqualTo(2));
    final half = salt.length ~/ 2;
    final state = empty.copyWith(control: {
      for (final (i, id) in salt.indexed)
        if (i < half * 2) id: i < half ? 'mire' : 'crows',
    });
    final holders = regionHolders(geo, state)['salt_coast']!;
    if (salt.length.isEven) {
      expect(holders, hasLength(2));
      expect(holders.map((h) => h.$1).toSet(), {'mire', 'crows'});
      expect(holders.every((h) => h.$2 == 1.0), isTrue);
    } else {
      expect(holders.map((h) => h.$1).take(3), containsAll(['mire', 'crows']));
    }
  });

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
