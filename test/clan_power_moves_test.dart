// Clan power that moves (v1.513, docs/proposals/clan-power-story.md): the
// three levers the user chose.
// (a) A story choice's `power` (Narrative's 19 blocks in the DAG) moves the
//     clan once, and the save keeps it.
// (b) The war turn swings harder: a place taken in war moves power
//     ([warSpoils], [warLoss]); a seat needs [seatLead]; a fallen clan's
//     survivors regroup ([fallenRegroup]) and its seat may rise for it.
// (c) The two upheavals: `wrack_vote_result` (chapter 5, only once the
//     vote was carried or refused) and `conclave_counts` (chapter 7, full
//     size while some clan has 50 power, `anyPowerAtLeast`, else half); the
//     simulator now fires the politics events as the app does.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/politics_events.dart';
import 'package:narrative_data_app/data/sim_combat.dart';
import 'package:narrative_data_app/data/sim_growth.dart';
import 'package:narrative_data_app/data/story_repository.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/screens/playthrough_simulator_screen.dart';
import 'support/sim_world.dart';

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
  final geography =
      Geography.parse(geography: _table('geography'), biomes: _table('biomes'));
  final events = parsePoliticsEvents(_table('politics_events'));
  final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
      as Map<String, dynamic>;
  final story = {
    for (final e in raw.entries)
      e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
  };
  const mains = ['dominion', 'vigil', 'compact', 'mire', 'crows', 'penitents'];

  CoastWorld world(int chapter) => CoastWorld(
      data: data, events: events, chapter: chapter, geography: geography);

  group('(a) story choices with power', () {
    test('every power block names a main clan, 2 to 8 points', () {
      var blocks = 0;
      for (final node in story.values) {
        for (final choice in node.choices) {
          for (final e
              in (choice.politics?.power ?? const <String, int>{}).entries) {
            blocks++;
            expect(mains, contains(e.key), reason: node.id);
            expect(e.value.abs(), inInclusiveRange(2, 8), reason: node.id);
          }
        }
      }
      expect(blocks, greaterThanOrEqualTo(19));
    });

    test('taking the choice moves the clan once, and the save keeps it', () {
      final node = story['6010_clan_compact_3_hammer']!;
      final index = node.choices
          .indexWhere((c) => (c.politics?.power['compact'] ?? 0) > 0);
      final choice = node.choices[index];
      final key = choicePoliticsKey(node.id, index);
      final first = applyStoryPolitics(choice.politics!,
          cause: 'story:${node.id}',
          key: key,
          politics: PoliticsState.storyStart,
          flags: const [],
          world: world(6));
      final compact = powerOf(PoliticsState.storyStart, 'compact', data);
      expect(powerOf(first.politics, 'compact', data), compact + 8);
      expect(first.politics.helped, contains('compact'),
          reason: 'raised by the character: no neglect this chapter');
      // Saved and loaded.
      final loaded = PoliticsState.fromJson(
          jsonDecode(jsonEncode(first.politics.toJson())));
      expect(powerOf(loaded, 'compact', data), compact + 8);
      expect(loaded.applied(key), isTrue);
      // Taken again: nothing.
      final again = applyStoryPolitics(choice.politics!,
          cause: 'story:${node.id}',
          key: key,
          politics: loaded,
          flags: const [],
          world: world(6));
      expect(again.applied, isFalse);
      expect(powerOf(again.politics, 'compact', data), compact + 8);
    });

    test('a choice lowering a clan lowers it, without sparing its neglect', () {
      final node = story['4999_standard']!;
      final choice =
          node.choices.firstWhere((c) => c.politics?.power['dominion'] == -6);
      final change = applyStoryPolitics(choice.politics!,
          cause: 'story:${node.id}',
          politics: PoliticsState.storyStart,
          flags: const [],
          world: world(4));
      expect(powerOf(change.politics, 'dominion', data), 54);
      expect(change.politics.helped, isNot(contains('dominion')));
    });
  });

  group('(b) the war turn swings harder', () {
    PoliticsState atWar(Map<String, int> power) => PoliticsState.empty.copyWith(
        power: power,
        helped: ['crows', 'dominion'],
        relationSteps: {relationKey('dominion', 'crows'): warStep});

    test('a place taken in war: the taker gains, the loser bleeds', () {
      final turn = territoryTurn(atWar({'crows': 30}),
          data: data, geography: geography, chapter: 3);
      final war = turn.changes.singleWhere((c) => c.cause == 'war');
      expect((war.from, war.to), ('crows', 'dominion'));
      // Holdings first (the Dominion's six places, the Crows' three).
      expect(powerOf(turn.state, 'dominion', data), 60 + 6 + warSpoils);
      expect(powerOf(turn.state, 'crows', data), 30 + 3 - warLoss);
      expect(warSpoils, 5);
      expect(warLoss, 8);
    });

    test('the seat needs a lead of seatLead, the lands warLead', () {
      expect(seatLead, greaterThan(warLead));
      // The Crows left with their seat alone.
      var state = atWar({'crows': 30});
      for (final place in placesOf('crows', geography, state)) {
        if (place == data.faction('crows')!.seat) continue;
        state = state.copyWith(control: {...state.control, place: 'tidekin'});
      }
      expect(placesOf('crows', geography, state), ['saltmouth_wharf']);
      // 20 ahead (after holdings): the seat holds.
      final close = territoryTurn(
          state.copyWith(power: {...state.power, 'dominion': 46}),
          data: data,
          geography: geography,
          chapter: 6);
      expect(close.changes.where((c) => c.cause == 'war'), isEmpty);
      // 35 ahead: it falls.
      final far = territoryTurn(
          state.copyWith(power: {...state.power, 'dominion': 61}),
          data: data,
          geography: geography,
          chapter: 6);
      expect(far.changes.singleWhere((c) => c.cause == 'war').placeId,
          'saltmouth_wharf');
      expect(far.state.fallen, ['crows']);
      expect(powerOf(far.state, 'crows', data), 0);
      // Outside chapters 6 and 7 the seat holds, however far ahead.
      for (final chapter in [3, 4, 5, 8]) {
        final early = territoryTurn(
            state.copyWith(power: {...state.power, 'dominion': 90}),
            data: data,
            geography: geography,
            chapter: chapter);
        expect(early.changes.where((c) => c.cause == 'war'), isEmpty,
            reason: 'chapter $chapter');
      }
      expect((seatWarFromChapter, seatWarToChapter), (6, 7));
    });

    test('the Dominion\'s seat is guarded: never taken at a turn', () {
      expect(seatGuarded('dominion'), isTrue);
      expect(data.faction('dominion')!.seat, 'candlehold');
      // The Compact far stronger, at war, the Dominion left with Candlehold
      // alone.
      var state = PoliticsState.empty.copyWith(
          power: {'compact': 100, 'dominion': 10},
          helped: ['compact', 'dominion'],
          relationSteps: {relationKey('dominion', 'compact'): 1});
      for (final place in placesOf('dominion', geography, state)) {
        if (place == 'candlehold') continue;
        state = state.copyWith(control: {...state.control, place: 'tidekin'});
      }
      expect(placesOf('dominion', geography, state), ['candlehold']);
      for (var chapter = 3; chapter <= 8; chapter++) {
        state = territoryTurn(state,
                data: data, geography: geography, chapter: chapter)
            .state;
        expect(holderOf('candlehold', geography, state), 'dominion',
            reason: 'chapter $chapter');
      }
      expect(state.fallen, isNot(contains('dominion')));
      // Another clan's seat has no guard.
      expect(seatGuarded('compact'), isFalse);
    });

    test(
        'the Inquisition taking the Returned leaves the Mire Hostile, not at '
        'War', () {
      final change = runDueEvents(
          politics: PoliticsState.storyStart, flags: const [], world: world(3));
      expect(change.fired, contains('returned_taken'));
      expect(change.politics.relationStep('dominion', 'mire', data), 3);
    });

    // The Mire's places but its seat gone first (Saltmouth's Lantern
    // Alleys, wave 18), so its seat is its last.
    final seatOnly = givePlace(
        PoliticsState.empty, 'saltmouth_lantern_alleys', 'crows',
        cause: 'claim', data: data, geography: geography, chapter: 2);

    test('a fallen clan regroups to fallenRegroupCap, then needs help', () {
      expect(placesOf('mire', geography, seatOnly), ['mire_court']);
      var state = givePlace(seatOnly, 'mire_court', 'dominion',
          cause: 'war', data: data, geography: geography, chapter: 3);
      expect(state.fallen, ['mire']);
      final seen = <int>[];
      for (var chapter = 4; chapter <= 9; chapter++) {
        state = territoryTurn(state,
                data: data, geography: geography, chapter: chapter)
            .state;
        seen.add(powerOf(state, 'mire', data));
      }
      expect(seen, [5, 10, 15, 20, 20, 20]);
      expect(fallenRegroupCap, lessThan(risingPower));
      expect(state.fallen, contains('mire'), reason: 'not Rising on its own');
    });

    test('its seat rises for it unless the holder is seatLead stronger', () {
      final fallen = givePlace(seatOnly, 'mire_court', 'penitents',
          cause: 'war', data: data, geography: geography, chapter: 3);
      // Back at Rising (26), the Penitents 15 stronger: the seat rises.
      final close = territoryTurn(
          fallen.copyWith(
              power: {...fallen.power, 'mire': 26, 'penitents': 40},
              helped: ['penitents']),
          data: data,
          geography: geography,
          chapter: 5);
      final back = close.changes.firstWhere((c) => c.to == 'mire');
      expect(back.placeId, 'mire_court');
      expect(close.state.fallen, isNot(contains('mire')));
      // The Dominion 40 stronger keeps it: the Mire takes a free claim.
      final held = givePlace(seatOnly, 'mire_court', 'dominion',
          cause: 'war', data: data, geography: geography, chapter: 3);
      final far = territoryTurn(
          held.copyWith(power: {...held.power, 'mire': 26}),
          data: data,
          geography: geography,
          chapter: 5);
      expect(holderOf('mire_court', geography, far.state), 'dominion');
    });
  });

  group('(c) the upheavals of chapters 5 and 7', () {
    final wrack = events['wrack_vote_result']!;
    final conclave = events['conclave_counts']!;

    test('the vote lands in chapter 5 only once it was carried or refused', () {
      bool due(List<String> flags, int chapter) => eventDue(wrack,
          politics: PoliticsState.storyStart,
          flags: flags,
          world: world(chapter));
      expect(due(const [], 5), isFalse, reason: 'no vote, no result');
      expect(due(const ['vote_carried'], 4), isFalse);
      expect(due(const ['vote_carried'], 5), isTrue);
      expect(due(const ['vote_refused'], 6), isTrue);
    });

    test('carried: the Dominion takes Cinder Row; read: the Crows gain', () {
      final carried = runDueEvents(
          politics: PoliticsState.storyStart,
          flags: const ['vote_carried'],
          world: world(5));
      expect(carried.fired, contains('wrack_vote_result'));
      final p = carried.politics;
      expect(powerOf(p, 'dominion', data), 60 + 8);
      expect(powerOf(p, 'compact', data), 40 - 4);
      expect(holderOf('ashen_quarter_cinder_row', geography, p), 'dominion');
      final read = runDueEvents(
          politics: PoliticsState.storyStart,
          flags: const ['vote_carried', 'vote_read'],
          world: world(5));
      expect(powerOf(read.politics, 'crows', data), 45 + 4);
      final refused = runDueEvents(
          politics: PoliticsState.storyStart,
          flags: const ['vote_refused'],
          world: world(5));
      expect(powerOf(refused.politics, 'dominion', data), 60 - 8);
      expect(holderOf('ashen_quarter_spire_stair', geography, refused.politics),
          'compact');
    });

    test('the Conclave: full size while a clan has 50, half below', () {
      final strong = PoliticsState.storyStart.copyWith(claim: 'vigil');
      expect(strongestPower(strong, data), greaterThanOrEqualTo(50));
      final full = runDueEvents(
          politics: strong, flags: const ['way_force'], world: world(7));
      expect(powerOf(full.politics, 'vigil', data), 30 + 8);
      expect(powerOf(full.politics, 'dominion', data), 60 - 8);
      expect(holderOf('candlehold_lantern_hall', geography, full.politics),
          'vigil');
      // No clan at 50: half the swing, no place moves.
      final weak = strong.copyWith(power: {for (final id in mains) id: 40});
      expect(strongestPower(weak, data), lessThan(50));
      final half = runDueEvents(
          politics: weak, flags: const ['way_force'], world: world(7));
      expect(powerOf(half.politics, 'vigil', data), 40 + 4);
      expect(powerOf(half.politics, 'dominion', data), 40 - 4);
      expect(holderOf('candlehold_lantern_hall', geography, half.politics),
          'dominion');
      // The quiet way: the Houses persuaded.
      final quiet = runDueEvents(
          politics: strong, flags: const ['way_quiet'], world: world(7));
      expect(powerOf(quiet.politics, 'dominion', data), 60 + 5);
      expect(conclave.once, isTrue);
    });

    test('the simulator fires the politics events as the app does', () {
      final growth = SimGrowth(
        mode: SimProgression.offers,
        tables: SimGrowthTables(clans: data, events: events),
        character: SimCharacter.create(
          raceId: 'human',
          race: _table('races')['human'] as Map<String, dynamic>,
          professionId: 'warrior',
          profession: _table('professions')['warrior'] as Map<String, dynamic>,
          gameConfig: _table('game_config'),
          dice: _table('dice'),
          spells: parseSpells(_table('spells')),
        ),
      );
      final flags = growth.runEvents(
          flags: const ['vote_carried'], chapter: 5, geography: geography);
      expect(growth.politics.hasFired('wrack_vote_result'), isTrue);
      expect(holderOf('ashen_quarter_cinder_row', geography, growth.politics),
          'dominion');
      expect(flags, contains('vote_carried'));
      // And a whole run: chapter 2's events fire on the way.
      final run = simulatePlaythroughs(StoryData(story),
              tables: simTables(),
              gameConfig: _table('game_config'),
              plan: [
                (
                  strategy: SimStrategy.favorGood,
                  raceId: 'human',
                  professionId: 'warrior'
                )
              ],
              seed: 7000,
              maxSteps: 400)
          .first;
      expect(run.politics.hasFired('lantern_bearer_failing'), isTrue);
    });
  });
}
