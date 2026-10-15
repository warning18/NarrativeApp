// The crisis and the fall (v5.2 step 6, PR 2b, clan_crisis.dart): your
// main clan's seat waits for you at a chapter's turn; defend it, pay, or
// refuse; fallen, bend the knee to the winner or stay of it until a banner
// of your own.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/clan_crisis.dart';
import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/nemesis.dart';
import 'package:narrative_data_app/data/patron_stats.dart';
import 'package:narrative_data_app/data/politics_events.dart';
import 'package:narrative_data_app/models/story_node.dart';

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
  final enemies = _table('enemies');
  final world = CoastWorld(data: data, chapter: 4, geography: geography);

  PoliticsState at(Map<String, num> standings, [PoliticsState? from]) {
    var state = from ?? PoliticsState.empty;
    for (final e in standings.entries) {
      state = setStandingValue(state, e.key, e.value, 'edit', data: data).state;
    }
    return state;
  }

  PoliticsState play(StoryChoice choice, PoliticsState state) =>
      applyStoryPolitics(choice.politics!,
              cause: 'story:crisis',
              politics: state,
              flags: const [],
              world: world)
          .politics;

  // The Compact your patron, down to Emberwick, its seat; the Dominion
  // far stronger and at war with it.
  PoliticsState threatened() {
    var state = at({'compact': 30}).copyWith(
        power: {'compact': 20},
        helped: ['compact', 'dominion'],
        relationSteps: {relationKey('dominion', 'compact'): 2});
    for (final place in placesOf('compact', geography, state)) {
      if (place != 'emberwick') {
        state = givePlace(state, place, 'crows',
            cause: 'event', data: data, geography: geography);
      }
    }
    return state;
  }

  test('the Mire sits at its Court', () {
    expect(data.faction('mire')!.seat, 'mire_court');
    expect(geography.place('mire_court')!.nameFor(false), 'The Mire\'s Court');
    expect(holderOf('mire_court', geography, PoliticsState.empty), 'mire');
  });

  test('your main clan: sworn, else your patron', () {
    expect(mainClanOf(PoliticsState.empty), '');
    expect(mainClanOf(at({'compact': 30})), 'compact');
    expect(mainClanOf(at({'compact': 30, 'vigil': 70})), 'vigil');
  });

  test('a chapter\'s turn holds your clan\'s seat for a crisis', () {
    final state = threatened();
    expect(mainClanOf(state), 'compact');
    final turn = territoryTurn(state,
        data: data, geography: geography, chapter: 4, protect: 'compact');
    expect(holderOf('emberwick', geography, turn.state), 'compact');
    expect(turn.state.crisis,
        {'clan': 'compact', 'attacker': 'dominion', 'place': 'emberwick'});
    // Without you to ask, it falls at once.
    final bare =
        territoryTurn(state, data: data, geography: geography, chapter: 4);
    expect(holderOf('emberwick', geography, bare.state), 'dominion');
    expect(bare.state.fallen, contains('compact'));
    expect(bare.state.fellTo['compact'], 'dominion');
  });

  test('the crisis scene: defend, pay, refuse (Narrative\'s words)', () {
    final state = territoryTurn(threatened(),
            data: data, geography: geography, chapter: 4, protect: 'compact')
        .state;
    final node = buildCrisisNode(state,
        data: data,
        geography: geography,
        enemies: enemies,
        chapter: 4,
        gold: 500,
        random: Random(1))!;
    expect(isClanCrisisNode(node.id), isTrue);
    expect(node.contextNote, contains('sends for you'));
    expect(node.description, contains('Emberwick'));
    expect(node.choices.map((c) => c.text),
        ['Defend Emberwick', 'Pay 160 gold', 'Refuse']);
    final defender = node.choices.first.triggerEnemyId!;
    expect((enemies[defender] as Map)['hunterClan'], 'dominion');
    // Too poor to pay: no such choice.
    final poor = buildCrisisNode(state,
        data: data,
        geography: geography,
        enemies: enemies,
        chapter: 4,
        gold: 10,
        random: Random(1))!;
    expect(poor.choices.map((c) => c.text), isNot(contains('Pay 160 gold')));

    // Held: the crisis over, the attacker weaker, the clan stronger.
    final held = play(node.choices[0], state);
    expect(held.crisis, isEmpty);
    expect(holderOf('emberwick', geography, held), 'compact');
    expect(powerOf(held, 'compact', data), powerOf(state, 'compact', data) + 5);
    expect(
        powerOf(held, 'dominion', data), powerOf(state, 'dominion', data) - 10);
    expect(held.standingOf('compact', data),
        state.standingOf('compact', data) + defendStanding);
    // Paid: the gold goes (the choice's), the seat stands.
    expect(node.choices[1].goldMod, -160);
    final paid = play(node.choices[1], state);
    expect(paid.crisis, isEmpty);
    expect(holderOf('emberwick', geography, paid), 'compact');
    // Refused: the seat falls, and the fall waits for your choice.
    final refused = play(node.choices[2], state);
    expect(refused.crisis, isEmpty);
    expect(holderOf('emberwick', geography, refused), 'dominion');
    expect(refused.fallen, contains('compact'));
    expect(pendingFall(refused), (clan: 'compact', winner: 'dominion'));
  });

  PoliticsState fallenState() {
    final state = territoryTurn(threatened(),
            data: data, geography: geography, chapter: 4, protect: 'compact')
        .state;
    final node = buildCrisisNode(state,
        data: data,
        geography: geography,
        enemies: enemies,
        chapter: 4,
        gold: 0,
        random: Random(1))!;
    return play(node.choices.last, state);
  }

  test('the fall: bend the knee, your standing moves to the winner', () {
    // Sworn to the Compact when it fell.
    final state = at({'compact': 70}, fallenState());
    expect(state.swornFactionId, 'compact');
    final node = buildFallNode(state,
        data: data, geography: geography, gold: 200, random: Random(1))!;
    expect(node.contextNote, 'The banner comes down.');
    expect(node.choices.map((c) => c.text), [
      'Bend the knee to The Lantern Dominion',
      'Stay of The Cinder Compact'
    ]);
    expect(node.choices.first.goldMod, -40);
    final knelt = play(node.choices.first, state);
    expect(knelt.swornFactionId, 'dominion');
    expect(knelt.standingOf('dominion', data), greaterThanOrEqualTo(61));
    expect(knelt.standingOf('compact', data), kneelFallenStanding);
    expect(pendingFall(knelt), isNull);
  });

  test('the fall: stay of the fallen clan until a banner of your own', () {
    final state = fallenState();
    final node = buildFallNode(state,
        data: data, geography: geography, gold: 0, random: Random(1))!;
    final stayed = play(node.choices.last, state);
    expect(stayed.fallenOf, 'compact');
    expect(pendingFall(stayed), isNull);
    // Clanless: no patron's stats, and no new oath.
    expect(statPatron(stayed), '');
    expect(at({'vigil': 80}, stayed).swornFactionId, '');
    // The winner hunts you, whatever its power.
    final hunted = updateNemesis(
        stayed.copyWith(power: {...stayed.power, 'dominion': 5}), data,
        chapter: 5);
    expect(hunted.nemesis, 'dominion');
    // Still fallen, no banner: it holds.
    expect(
        settleFallenLoyalty(stayed, bannerRaised: false).fallenOf, 'compact');
    // The banner raised: it pledges to your Host, and you are free.
    final free = settleFallenLoyalty(stayed, bannerRaised: true);
    expect(free.fallenOf, '');
    expect(free.pledged, contains('compact'));
    expect(free.nemesis, '');
  });

  test('crisis and fall are saved', () {
    final state = PoliticsState.empty.copyWith(
      crisis: {'clan': 'mire', 'attacker': 'crows', 'place': 'mire_court'},
      fellTo: {'compact': 'dominion'},
      fallenOf: 'compact',
      fallenWinner: 'dominion',
    );
    final back = PoliticsState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>);
    expect(back.crisis, state.crisis);
    expect(back.fellTo, state.fellTo);
    expect(back.fallenOf, 'compact');
    expect(back.fallenWinner, 'dominion');
  });
}
