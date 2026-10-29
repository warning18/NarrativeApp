// The report of a "Play to chapter" walk (autoplay_summary.dart): items
// moved as multisets, the banner carried, the fights counted.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/autoplay_engine.dart';
import 'package:narrative_data_app/data/autoplay_summary.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final data = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
  );

  test('items moved count as multisets', () {
    expect(multisetLess(['a', 'a', 'b', 'c'], ['a', 'c']), ['a', 'b']);
    expect(multisetLess(['a'], ['a', 'a']), isEmpty);
    expect(multisetLess(const [], ['a']), isEmpty);
  });

  test('the summary reads the session and the log', () {
    final base = PlayerSession.fromJson(const {});
    final before =
        base.copyWith(inventoryItemIds: const ['potion', 'potion', 'rope']);
    final after = base.copyWith(
      level: 4,
      gold: 120,
      inventoryItemIds: const ['potion', 'sword'],
      equippedItemIds: const ['sword'],
      politics: PoliticsState.empty.copyWith(swornFactionId: 'vigil'),
    );
    final log = AutoplayLog()
      ..choices.add((nodeId: '100', text: 'Go'))
      ..fights.addAll([
        (enemyId: 'rat', name: 'Rat', won: true, forced: false),
        (enemyId: 'wolf', name: 'Wolf', won: false, forced: false),
      ])
      ..banners.add((chapter: 2, factionId: 'vigil', gift: 'shield_bash'));
    final s = autoplaySummaryOf(
        before: before,
        after: after,
        log: log,
        data: data,
        chapter: 3,
        nodeId: '3001');
    expect((s.level, s.gold, s.chapter, s.nodeId), (4, 120, 3, '3001'));
    expect(s.gained, ['sword']);
    expect(s.lost, ['potion', 'rope']);
    expect(s.equipped, ['sword']);
    expect(s.carriedBanner, 'vigil');
    expect(s.banners.single.factionId, 'vigil');
    expect((s.fightsWon, s.fightsLost), (1, 1));
    expect(s.choices.single.nodeId, '100');
    // Every main clan, highest standing first.
    expect(s.standings.length, data.clans.length);
    for (var i = 1; i < s.standings.length; i++) {
      expect(s.standings[i - 1].value >= s.standings[i].value, isTrue);
    }
  });
}
