// The story's own nemesis (v1.409, nemesis.dart): every new game opens
// with the Dominion the nemesis (it wants the piece of the Shroud). It hunts at the
// Hostile odds and keeps its people out of your fights; it lets go at
// Friendly, gives way to a clan crossed harder, and turned Hostile it is
// an earned nemesis like any other. Old saves take it on load unless
// Friendly with the Dominion.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/context_rules.dart'
    show Reinforcement;
import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/nemesis.dart';
import 'package:narrative_data_app/data/rival_hunters.dart';

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
  PoliticsState at(Map<String, num> standings,
      [PoliticsState from = PoliticsState.storyStart]) {
    var state = from;
    for (final e in standings.entries) {
      state = setStandingValue(state, e.key, e.value, 'edit', data: data).state;
    }
    return state;
  }

  test('a new game opens with the Dominion the nemesis, for the story', () {
    const start = PoliticsState.storyStart;
    expect(start.nemesis, 'dominion');
    expect(start.nemesisReason, nemesisReasonStory);
    expect(start.isStoryNemesis, isTrue);
    // Saved and read back as it was.
    final back = PoliticsState.fromJson(jsonDecode(jsonEncode(start.toJson())));
    expect(back.isStoryNemesis, isTrue);
    // A state of today's format without a nemesis keeps none.
    final none = PoliticsState.fromJson(
        jsonDecode(jsonEncode(PoliticsState.empty.toJson())));
    expect(none.nemesis, '');
  });

  test('an old save takes the Dominion on load, unless Friendly with it', () {
    final old = PoliticsState.fromJson({'standings': <String, dynamic>{}});
    expect(old.isStoryNemesis, isTrue);
    expect(
        PoliticsState.fromJson({
          'standings': {'dominion': 14.0}
        }).nemesis,
        '');
    // Its own nemesis kept, and earned.
    final crows = PoliticsState.fromJson({'nemesis': 'crows'});
    expect(crows.nemesis, 'crows');
    expect(crows.isStoryNemesis, isFalse);
    // The Dominion fallen, or broken lately: none.
    expect(
        PoliticsState.fromJson({
          'fallen': ['dominion']
        }).nemesis,
        '');
    expect(
        PoliticsState.fromJson({
          'nemesisCooldown': {'dominion': 6}
        }).nemesis,
        '');
  });

  test('at Wary it holds; at Friendly it lets go', () {
    const start = PoliticsState.storyStart;
    expect(start.tierOf('dominion', data), StandingTier.wary);
    expect(updateNemesis(start, data, chapter: 2).isStoryNemesis, isTrue);
    expect(updateNemesis(at({'dominion': 0}), data, chapter: 2).isStoryNemesis,
        isTrue);
    final friendly = updateNemesis(at({'dominion': 12}), data, chapter: 2);
    expect(friendly.nemesis, '');
    expect(friendly.news.last.eventId, 'nemesis_end:dominion');
  });

  test('turned Hostile, it is an earned nemesis', () {
    final earned = updateNemesis(at({'dominion': -40}), data, chapter: 2);
    expect(earned.nemesis, 'dominion');
    expect(earned.isStoryNemesis, isFalse);
    // From there the ordinary rules: it lets go at Wary.
    expect(
        updateNemesis(at({'dominion': -8}, earned), data, chapter: 3).nemesis,
        '');
  });

  test('a clan crossed harder takes its place', () {
    final crows = updateNemesis(at({'crows': -40}), data, chapter: 2);
    expect(crows.nemesis, 'crows');
    expect(crows.isStoryNemesis, isFalse);
    expect(crows.news.last.eventId, 'nemesis:crows');
    // Crossed less than the Dominion: the Dominion stays.
    final both = updateNemesis(
        at({'dominion': -50, 'crows': -40}, PoliticsState.storyStart), data,
        chapter: 2);
    expect(both.nemesis, 'dominion');
  });

  test('broken, it is gone, and cools down as any nemesis', () {
    final broken =
        breakNemesis(PoliticsState.storyStart, 'dominion', data, chapter: 5);
    expect(broken.nemesis, '');
    expect(broken.nemesisReason, '');
    expect(updateNemesis(broken, data, chapter: 6).nemesis, '');
  });

  test('it hunts at the Hostile odds, and its people hold back', () {
    expect(rivalHunts(PoliticsState.storyStart, data),
        {'dominion': rivalHunterChanceHostile});
    final earned = PoliticsState.empty.copyWith(nemesis: 'dominion');
    expect(rivalHunts(earned, data), {'dominion': rivalHunterChanceHunted});
    final geography = Geography.parse(
        geography: _table('geography'), biomes: _table('biomes'));
    final seat = data.faction('dominion')!.seat;
    expect(holderOf(seat, geography, PoliticsState.storyStart), 'dominion');
    expect(reinforcementAt(seat, geography, PoliticsState.storyStart, data),
        Reinforcement.none);
    expect(reinforcementAt(seat, geography, earned, data), Reinforcement.foes);
  });

  test('the pact or Vane backed for the throne side you with it for good', () {
    for (final flag in dominionSidedFlags) {
      final sided = updateNemesis(PoliticsState.storyStart, data,
          chapter: 7, flags: [flag]);
      expect(sided.nemesis, '', reason: flag);
      // Not even crossed after: no nemesis from it.
      final crossed = updateNemesis(
          at({'dominion': -70}, PoliticsState.empty), data,
          chapter: 7, flags: [flag]);
      expect(crossed.nemesis, isNot('dominion'), reason: flag);
    }
  });

  test('the panel says why, for the story\'s own only', () {
    final line = nemesisReasonLine(PoliticsState.storyStart)!;
    expect(line.en, contains('Shroud'));
    expect(line.fr, contains('Linceul'));
    expect(nemesisReasonLine(PoliticsState.empty.copyWith(nemesis: 'crows')),
        isNull);
  });
}
