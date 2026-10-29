// Towns tinted by the clan that rules them (town_rulers.dart): every town
// has a ruler or is neutral, places taken via politics re-tint, districts
// report their own ruler, and every clan that can hold a place has a
// colour of its own.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/town_rulers.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final factions = parseFactions(_table('factions'));
  final geography =
      Geography.parse(geography: _table('geography'), biomes: _table('biomes'));
  final planIds = _table('city_plans').keys.toList();
  const mains = ['dominion', 'vigil', 'compact', 'mire', 'crows', 'penitents'];

  Map<String, TownRuler> rulers(
          [PoliticsState politics = PoliticsState.empty]) =>
      townRulers(geography, politics, factions, planIds: planIds);

  test('every town with a city plan gets a ruler or neutral', () {
    final now = rulers();
    expect(planIds, isNotEmpty);
    for (final id in planIds) {
      final r = now[id];
      expect(r, isNotNull, reason: id);
      expect(r!.isDistrict, isFalse, reason: id);
      expect(r.cityId, id);
      expect(r.color, townColorOf(r.clanId, factions), reason: id);
      expect(r.accent, shadeColor(r.color), reason: id);
      if (r.isNeutral) {
        expect(r.source, TownRulerSource.none, reason: id);
        expect(r.color, townNeutralColor, reason: id);
      } else {
        expect(factions[r.clanId], isNotNull, reason: '$id: ${r.clanId}');
      }
    }
    // Every town kind is in, and the cove camp by its plan.
    expect(now['cove_camp'], isNotNull);
    expect(townIds(geography, planIds: planIds).length, 16);
    // As geography holds them at the start.
    expect(now['candlehold']!.clanId, 'dominion');
    expect(now['candlehold']!.source, TownRulerSource.own);
    expect(now['highhearth']!.clanId, 'giants');
    expect(now['saltmouth']!.clanId, 'crows');
    expect(now['saltmouth']!.source, TownRulerSource.districts);
    expect(now['saltmouth']!.mixed, isTrue);
    // The Ash-Market and Cinder Row put the Compact ahead in the Quarter
    // (wave 18 step 2); a tie between districts (the Reliquary's four
    // clans) is neutral.
    expect(now['ashen_quarter']!.clanId, 'compact');
    expect(now['ashen_quarter']!.source, TownRulerSource.districts);
    expect(now['black_reliquary']!.isNeutral, isTrue);
    expect(now['greyhithe']!.isNeutral, isTrue);
  });

  test('a place taken via control changes ruler', () {
    expect(rulers()['greyhithe']!.isNeutral, isTrue);
    final taken = PoliticsState.empty
        .copyWith(control: {'greyhithe': 'penitents', 'candlehold': 'crows'});
    final now = rulers(taken);
    expect(now['greyhithe']!.clanId, 'penitents');
    expect(now['greyhithe']!.source, TownRulerSource.own);
    expect(now['greyhithe']!.color, factions['penitents']!.color);
    expect(now['candlehold']!.clanId, 'crows');
    // Its district held by the old ruler stays, and the town is mixed.
    expect(now['candlehold_lantern_hall']!.clanId, 'dominion');
    expect(now['candlehold']!.mixed, isTrue);
  });

  test('a district held apart from its city reports its own ruler', () {
    final now = rulers();
    final cinder = now['ashen_quarter_cinder_row']!;
    expect(cinder.isDistrict, isTrue);
    expect(cinder.cityId, 'ashen_quarter');
    expect(cinder.clanId, 'compact');
    expect(cinder.source, TownRulerSource.own);
    expect(now['ashen_quarter_spire_stair']!.clanId, 'dominion');
    // The Spire Stair changes hands; the Compact leads the more.
    final moved = rulers(PoliticsState.empty
        .copyWith(control: {'ashen_quarter_spire_stair': 'compact'}));
    expect(moved['ashen_quarter_spire_stair']!.clanId, 'compact');
    expect(moved['ashen_quarter']!.clanId, 'compact');
    expect(moved['ashen_quarter']!.mixed, isTrue); // the Gate is the Vigil's
    // A town held outright: its unheld district (the Reliquary's Dead
    // Heart) takes its ruler.
    final held = rulers(
        PoliticsState.empty.copyWith(control: {'black_reliquary': 'vigil'}));
    expect(held['black_reliquary']!.clanId, 'vigil');
    expect(held['reliquary_chapels']!.clanId, 'compact');
    final unheld = held.values.firstWhere((r) =>
        r.cityId == 'black_reliquary' &&
        r.isDistrict &&
        r.source.name == 'above');
    expect(unheld.placeId, 'dead_heart');
    expect(unheld.clanId, 'vigil');
  });

  test('every clan that can hold a place has a valid colour', () {
    final holders = <String>{
      ...holdings(geography, PoliticsState.empty).values,
      for (final f in factions.values) ...[
        if (f.seat.isNotEmpty) f.id,
        if (f.claims.isNotEmpty) f.id,
      ],
    };
    expect(holders, containsAll(mains));
    for (final id in holders) {
      final color = factions[id]?.color;
      expect(color, isNotNull, reason: id);
      expect(color! >> 24, 0xFF, reason: '$id is opaque');
      expect(color, isNot(townNeutralColor), reason: id);
      // Written in factions.json, not the parser's fallback.
      expect((_table('factions')[id] as Map)['color'], isA<String>(),
          reason: id);
    }
  });

  test('the main clans have distinct colours', () {
    int dist(int a, int b) {
      var sum = 0;
      for (final shift in [16, 8, 0]) {
        final d = ((a >> shift) & 0xFF) - ((b >> shift) & 0xFF);
        sum += d * d;
      }
      return sum;
    }

    // The closest pair, the Compact and the Crows, are ~60 apart in RGB.
    final colors = [for (final id in mains) factions[id]!.color];
    for (var i = 0; i < colors.length; i++) {
      for (var j = i + 1; j < colors.length; j++) {
        expect(dist(colors[i], colors[j]), greaterThan(50 * 50),
            reason: '${mains[i]} / ${mains[j]}');
      }
      expect(dist(colors[i], townNeutralColor), greaterThan(20 * 20),
          reason: '${mains[i]} / neutral');
    }
  });
}
