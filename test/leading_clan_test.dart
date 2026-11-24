// The leading clan (v2.6.0, read by UX's ink accent): in the story, the
// clan with the highest standing once it is Friendly or above and alone at
// the top; in a Tower run, the sworn clan, else the highest run standing
// once it is 4 of 6 or more and alone at the top. Otherwise none.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/providers/clans_provider.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final data = ClanData.fromTables(
    factions: _table('factions'),
    relations: _table('relations'),
  );
  final ids = data.factions.keys.toList();

  PoliticsState standings(Map<String, double> top) =>
      PoliticsState(standings: {for (final id in ids) id: 0, ...top});

  group('the story', () {
    test('no clan leads at the start', () {
      expect(storyLeadingClan(standings(const {}), data), isNull);
    });

    test('a clan leads once Friendly and alone at the top', () {
      expect(storyLeadingClan(standings({ids[0]: 11}), data), isNull,
          reason: 'below Friendly');
      expect(storyLeadingClan(standings({ids[0]: 12}), data), ids[0]);
      expect(
          storyLeadingClan(standings({ids[0]: 30, ids[1]: 20}), data), ids[0]);
    });

    test('a tie at the top leads no one', () {
      expect(
          storyLeadingClan(standings({ids[0]: 20, ids[1]: 20}), data), isNull);
    });
  });

  group('a Tower run', () {
    final tower = towerDataFromAssets();
    final start = towerStart(
        seed: 5, raceId: 'human', professionId: 'warrior', data: tower);
    TowerRun withGifts(Map<int, String> clans) => start.copyWith(
          floor: clans.length + 1,
          taken: {
            ...start.taken,
            for (final MapEntry(:key, :value) in clans.entries)
              key: TowerReward(TowerRewardKind.skill,
                  id: 'second_wind', clan: value),
          },
        );

    test('none before a clan stands at 4', () {
      expect(towerLeadingClan(start, tower), isNull);
      expect(towerLeadingClan(withGifts({1: 'mire'}), tower), isNull);
    });

    test('two gifts of one clan: it leads', () {
      expect(
          towerLeadingClan(withGifts({1: 'mire', 2: 'mire'}), tower), 'mire');
    });

    test('the sworn clan leads, whatever the standing', () {
      final sworn = start.copyWith(
          taken: {0: const TowerReward(TowerRewardKind.clanOath, id: 'crows')});
      expect(towerLeadingClan(sworn, tower), 'crows');
    });
  });
}
