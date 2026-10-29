// A clan's radar (clan_radar.dart): what its gifts lean on, on five axes,
// and its steps with the other clans, live over relations.json's; and
// every faction says what it stands for, in both languages.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/clan_radar.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';

Map<String, dynamic> _json(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final data = ClanData.fromTables(
    factions: _json('factions'),
    subclans: _json('subclans'),
    relations: _json('relations'),
    titles: _json('titles'),
    intrigues: _json('intrigues'),
  );
  final signs = parseSigns(_json('signs'));

  test('every faction says what it stands for, in both languages', () {
    for (final faction in data.factions.values) {
      expect(faction.standsFor, isNotEmpty, reason: faction.id);
      expect(faction.standsForFr, isNotEmpty, reason: faction.id);
    }
    expect(data.faction('dominion')!.standsForIn(AppLanguage.fr),
        'La loi, l’ordre, une seule flamme sur tous');
  });

  test('a clan\'s orientation runs 0 to 1 on all five axes', () {
    for (final faction in data.factions.values.where((f) => f.isClan)) {
      final radar = clanRadarOf(faction.id, data: data, signs: signs);
      expect(radar.orientation.keys.toSet(), RadarAxis.values.toSet(),
          reason: faction.id);
      for (final v in radar.orientation.values) {
        expect(v, inInclusiveRange(0, 1), reason: faction.id);
      }
      // Its strongest axis is full (every clan has signs or a sworn boon).
      expect(radar.orientation.values.reduce((a, b) => a > b ? a : b), 1,
          reason: faction.id);
    }
  });

  test('the Crows lean on fortune, the Vigil on guard', () {
    final crows = clanRadarOf('crows', data: data, signs: signs);
    final vigil = clanRadarOf('vigil', data: data, signs: signs);
    expect(crows.orientation[RadarAxis.fortune],
        greaterThan(vigil.orientation[RadarAxis.fortune]!));
    expect(vigil.orientation[RadarAxis.guard],
        greaterThan(crows.orientation[RadarAxis.guard]!));
  });

  test('relations come from relations.json, the live steps over them', () {
    final base = clanRadarOf('dominion', data: data, signs: signs);
    final file = data.relations.baseSteps[relationKey('dominion', 'vigil')];
    expect(base.relations['vigil'], file);
    expect(base.relations.containsKey('dominion'), isFalse);
    final live = clanRadarOf('dominion',
        data: data,
        signs: signs,
        relationSteps: {relationKey('dominion', 'vigil'): 7});
    expect(live.relations['vigil'], 7);
  });
}
