// Clan power and territory (v5.2 step 6, clan_power.dart): power by tier,
// the holder of a place now, the chapter's turn (holdings, neglect,
// claims, wars), a clan falling, and the story moving power and places.
// POWER_RUNS=n prints what the simulator's runs do to the map (the PR's
// table).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/politics_events.dart';
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
  const mains = ['dominion', 'vigil', 'compact', 'mire', 'crows', 'penitents'];

  // The Penitents' war kept out (wave 18 step 2 gives them land): the
  // scenarios below are about other clans.
  PoliticsState powered(Map<String, int> power) => PoliticsState.empty.copyWith(
      power: power, relationSteps: {relationKey('dominion', 'penitents'): 4});

  test('every main clan has power, a seat and claims the world knows', () {
    for (final id in mains) {
      final faction = data.faction(id)!;
      expect(faction.startPower, greaterThan(0), reason: id);
      expect(isMainClan(id, data), isTrue, reason: id);
      if (faction.seat.isNotEmpty) {
        expect(geography.place(faction.seat), isNotNull, reason: id);
      }
      expect(faction.claims, isNotEmpty, reason: id);
      for (final claim in faction.claims) {
        expect(geography.place(claim), isNotNull, reason: '$id: $claim');
      }
    }
    expect(powerOf(PoliticsState.empty, 'dominion', data), 60);
    expect(powerOf(PoliticsState.empty, 'mire', data), 25);
    // The minor holders have power, but no neglect.
    expect(hasPower('kindly', data), isTrue);
    expect(isMainClan('kindly', data), isFalse);
  });

  test('tiers', () {
    expect(powerTierFor(0), PowerTier.minor);
    expect(powerTierFor(24), PowerTier.minor);
    expect(powerTierFor(25), PowerTier.rising);
    expect(powerTierFor(50), PowerTier.dominant);
    expect(powerTierFor(75), PowerTier.ascendant);
  });

  test('power moves within 0..100, and helping spares the neglect', () {
    var state = addPower(PoliticsState.empty, 'mire', 90, data, helped: true);
    expect(powerOf(state, 'mire', data), maxPower);
    expect(state.helped, ['mire']);
    state = addPower(state, 'mire', -200, data);
    expect(powerOf(state, 'mire', data), 0);
    // A faction with no power doesn't move.
    expect(addPower(PoliticsState.empty, 'choir', 5, data).power, isEmpty);
    expect(giftPowerFor('common'), giftPower);
    expect(giftPowerFor('heroic'), legendaryGiftPower);
  });

  test('the holder: the place\'s own, its city\'s, or what changed hands', () {
    expect(holderOf('candlehold', geography, PoliticsState.empty), 'dominion');
    expect(
        holderOf('saltmouth_wharf', geography, PoliticsState.empty), 'crows');
    expect(holderOf('drowned_cloister', geography, PoliticsState.empty), '');
    final moved = PoliticsState.empty
        .copyWith(control: {'saltmouth_wharf': 'mire', 'candlehold': 'vigil'});
    expect(holderOf('saltmouth_wharf', geography, moved), 'mire');
    // The lantern hall keeps its own holder; a place under Candlehold with
    // none takes the city's.
    expect(holderOf('candlehold_lantern_hall', geography, moved), 'dominion');
    // (Seven with Saltmouth's Landward Gate and the Reliquary Quarter,
    // wave 18.)
    expect(placesOf('dominion', geography, PoliticsState.empty), hasLength(7));
  });

  test('a chapter: holdings bring power, neglect takes it, never too far', () {
    // The Penitents' war kept out (wave 18 step 2 gives them land).
    final calm = PoliticsState.empty
        .copyWith(relationSteps: {relationKey('dominion', 'penitents'): 4});
    final turn = territoryTurn(calm.copyWith(helped: ['crows']),
        data: data, geography: geography, chapter: 2);
    // The Dominion: +7 for its seven places, -5 neglected.
    expect(powerOf(turn.state, 'dominion', data), 62);
    // The Crows, helped: +3 for three places.
    expect(powerOf(turn.state, 'crows', data), 48);
    // The Vigil, two districts held: +2, -5.
    expect(powerOf(turn.state, 'vigil', data), 27);
    expect(turn.state.helped, isEmpty);
    // Never more than neglectFloor under its start.
    var state = calm;
    for (var chapter = 2; chapter <= 9; chapter++) {
      state = territoryTurn(state,
              data: data, geography: geography, chapter: chapter)
          .state;
    }
    expect(powerOf(state, 'vigil', data), 30 - neglectFloor);
  });

  test('a clan risen a tier takes its next claim from a weaker holder', () {
    // The Mire, Dominant (from Rising): Kindly Hill, from the Kindly.
    final turn = territoryTurn(powered({'mire': 60}).copyWith(helped: ['mire']),
        data: data, geography: geography, chapter: 3);
    expect(holderOf('kindly_hill', geography, turn.state), 'mire');
    expect(turn.changes.single.from, 'kindly');
    expect(turn.changes.single.cause, 'claim');
    expect(turn.state.news.last.eventId, 'territory:kindly_hill');
    expect(turn.state.news.last.text, contains('Kindly Hill'));
    // Still Rising: nothing.
    final still = territoryTurn(
        powered({'mire': 45}).copyWith(helped: ['mire']),
        data: data,
        geography: geography,
        chapter: 3);
    expect(still.changes.where((c) => c.to == 'mire'), isEmpty);
  });

  test('at war, the stronger takes a place, the seat last', () {
    // The Dominion and the Crows at war, the Crows far weaker.
    var state = powered({'crows': 30}).copyWith(
        helped: ['crows', 'dominion'],
        relationSteps: {relationKey('dominion', 'crows'): warStep});
    final turn =
        territoryTurn(state, data: data, geography: geography, chapter: 3);
    final war = turn.changes.where((c) => c.cause == 'war').single;
    expect(war.to, 'dominion');
    expect(war.from, 'crows');
    expect(war.placeId, isNot('saltmouth_wharf'));
    // The relation took a step down.
    expect(turn.state.relationStep('dominion', 'crows', data), warStep - 1);
    state = turn.state;
  });

  test('a clan that loses its last place falls, and rises again', () {
    var state = powered(const {});
    for (final place in placesOf('compact', geography, state)) {
      state = givePlace(state, place, 'dominion',
          cause: 'war', data: data, geography: geography, chapter: 4);
    }
    expect(placesOf('compact', geography, state), isEmpty);
    expect(state.fallen, ['compact']);
    expect(powerOf(state, 'compact', data), 0);
    expect(state.news.last.eventId, 'fallen:compact');
    // Back at Rising, it reaches for its seat first; the Dominion, far
    // stronger, keeps it, so it takes a free claim (the Ash-Market, left
    // to no one: wave 18 step 2 gave it the Compact at the start).
    state = state
        .copyWith(control: {...state.control, 'ashen_quarter_ash_market': ''});
    state = addPower(state, 'compact', 30, data, helped: true);
    expect(claimsAllowed(state, 'compact', data), 1);
    final turn =
        territoryTurn(state, data: data, geography: geography, chapter: 5);
    expect(turn.changes.first.to, 'compact');
    expect(turn.changes.first.from, '');
    expect(turn.state.fallen, isEmpty);
    // Stronger than the holder, it takes its seat back.
    final strong = territoryTurn(
        addPower(state.copyWith(power: {...state.power, 'dominion': 20}),
            'compact', 0, data,
            helped: true),
        data: data,
        geography: geography,
        chapter: 5);
    expect(strong.changes.first.placeId, 'emberwick');
  });

  test('the story moves power and gives places', () {
    final p = StoryPolitics.tryParse({
      'power': {'mire': 10},
      'control': {'drowned_cloister': 'mire'},
    })!;
    expect(p.toJson()['power'], {'mire': 10});
    final change = applyStoryPolitics(p,
        cause: 'story:x',
        politics: PoliticsState.empty,
        flags: const [],
        world: CoastWorld(data: data, chapter: 3, geography: geography));
    expect(powerOf(change.politics, 'mire', data), 35);
    expect(change.politics.helped, ['mire']);
    expect(holderOf('drowned_cloister', geography, change.politics), 'mire');
    // A quest done for a clan: power, as for a gift.
    final quest = applyStoryPolitics(
        StoryPolitics.tryParse({
          'standing': {'vigil': 10, 'dominion': -5},
        })!,
        cause: 'quest:q_ch5_candle_count',
        politics: PoliticsState.empty,
        flags: const [],
        world: CoastWorld(data: data, chapter: 5));
    expect(powerOf(quest.politics, 'vigil', data), 30 + questPower);
    expect(powerOf(quest.politics, 'dominion', data), 60);
    // An event's condition on power.
    final conditions = EventConditions.fromJson({
      'powerAtLeast': {'mire': 30}
    });
    final world = CoastWorld(data: data);
    expect(conditions.holds(world, const [], PoliticsState.empty), isFalse);
    expect(conditions.holds(world, const [], change.politics), isTrue);
  });

  test('the French news agrees with each clan (Narrative\'s gender_fr)', () {
    String fell(String clan, int variant) => fallenNews(AppLanguage.fr,
        clan: data.faction(clan),
        winner: data.faction('dominion'),
        seat: 'Rimewell',
        variant: variant);
    expect(fell('vigil', 0), startsWith('La Veille Grise est tombée\u00a0:'));
    expect(fell('crows', 0), startsWith('Les Corneilles de Sel sont tombées'));
    expect(fell('penitents', 0), contains('sont tombés\u00a0'));
    expect(fell('compact', 0), contains('est tombé\u00a0'));
    expect(fell('crows', 1), contains('Rimewell est au Dominion'));
    expect(fell('crows', 1), contains('n’ont plus'));
    final war = territoryNews(AppLanguage.fr,
        place: 'le Quai Haut',
        to: data.faction('crows'),
        from: data.faction('vigil'),
        fromClan: true,
        war: true);
    expect(
        war,
        'Guerre\u00a0: Les Corneilles de Sel ont pris le Quai Haut '
        'à la Veille Grise.');
    expect(
        territoryNews(AppLanguage.fr,
            place: 'Rimewell', to: data.faction('vigil'), from: null),
        'La Veille Grise tient Rimewell désormais.');
  });

  test('power, places and the fallen are saved', () {
    final state = PoliticsState.empty.copyWith(
      power: {'mire': 40},
      control: {'kindly_hill': 'mire'},
      helped: ['mire'],
      fallen: ['compact'],
    );
    final back = PoliticsState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>);
    expect(back.power, {'mire': 40});
    expect(back.control, {'kindly_hill': 'mire'});
    expect(back.helped, ['mire']);
    expect(back.fallen, ['compact']);
  });

  test('in the simulator, the map moves', () {
    final runs = int.tryParse(Platform.environment['POWER_RUNS'] ?? '');
    if (runs == null) return;
    final raw = jsonDecode(File(StoryRepository.assetPath).readAsStringSync())
        as Map<String, dynamic>;
    final story = StoryData({
      for (final e in raw.entries)
        e.key: StoryNode.fromJson(e.key, e.value as Map<String, dynamic>),
    });
    final tables = simTables();
    final summaries = simulatePlaythroughs(story,
        tables: tables,
        gameConfig: _table('game_config'),
        plan: [
          for (var i = 0; i < runs; i++)
            (
              strategy: SimStrategy.values[i % 4],
              raceId: null,
              professionId: null
            ),
        ],
        seed: 23);
    final byRoute = <String, List<SimRunSummary>>{};
    for (final r in summaries) {
      final sworn = r.politics.swornFactionId;
      byRoute.putIfAbsent(sworn.isEmpty ? '(none)' : sworn, () => []).add(r);
    }
    final lines = <String>[];
    lines.add('| Sworn to | Runs | ${mains.join(' | ')} | Changes | Fallen |');
    for (final e in byRoute.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key))) {
      final rs = e.value;
      String avg(num Function(SimRunSummary) f) =>
          (rs.fold<num>(0, (s, r) => s + f(r)) / rs.length).toStringAsFixed(0);
      final changes =
          (rs.fold<int>(0, (s, r) => s + r.territory.length) / rs.length)
              .toStringAsFixed(1);
      final fallen = rs.where((r) => r.politics.fallen.isNotEmpty).length;
      lines.add('| ${e.key} | ${rs.length} | ${[
        for (final id in mains) avg((r) => powerOf(r.politics, id, data)),
      ].join(' | ')} | $changes | $fallen |');
    }
    final causes = <String, int>{};
    final takers = <String, int>{};
    for (final r in summaries) {
      for (final c in r.territory) {
        causes[c.cause] = (causes[c.cause] ?? 0) + 1;
        takers['${c.to}<-${c.from.isEmpty ? '-' : c.from}:${c.placeId}'] =
            (takers['${c.to}<-${c.from.isEmpty ? '-' : c.from}:${c.placeId}'] ??
                    0) +
                1;
      }
    }
    final top = takers.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // ignore: avoid_print
    print([
      ...lines,
      'causes: $causes',
      'most: ${top.take(8).map((e) => '${e.key} ${e.value}').join(', ')}',
      'runs with no change: ${summaries.where((r) => r.territory.isEmpty).length} of ${summaries.length}',
      'max changes in a run: ${summaries.map((r) => r.territory.length).fold(0, max)}',
    ].join('\n'));
  });

  // The clan power sign (UX, option A): each clan's rank now and as the
  // last chapter's turn began, for its arrow.
  test('the ranking: now, at the last turn, and saved', () {
    final start = clanPowerRanking(PoliticsState.empty, data);
    expect(start.map((r) => r.clanId), [
      'dominion',
      'crows',
      'compact',
      'vigil',
      'mire',
      'penitents',
      'giants',
      'oni',
      'tidekin',
      'kindly'
    ]);
    // Equal powers share a rank; before any turn nothing has moved.
    expect([for (final r in start) r.rank], [1, 2, 3, 4, 5, 5, 7, 8, 8, 10]);
    expect(start.every((r) => r.rankChange == 0 && r.powerChange == 0), isTrue);

    final turned = territoryTurn(powered({'mire': 50}),
            data: data, geography: geography, chapter: 2)
        .state;
    // The turn keeps the powers it began with.
    expect(turned.powerAtTurn['mire'], 50);
    expect(turned.powerAtTurn['dominion'], 60);
    final moved = turned.copyWith(power: {...turned.power, 'mire': 70});
    final mire =
        clanPowerRanking(moved, data).firstWhere((r) => r.clanId == 'mire');
    expect(mire.rank, 1);
    expect(mire.previousRank, 2);
    expect(mire.rankChange, 1);
    expect(mire.powerChange, 20);

    final loaded = PoliticsState.fromJson(
        jsonDecode(jsonEncode(moved.toJson())) as Map<String, dynamic>);
    expect(loaded.powerAtTurn, moved.powerAtTurn);
    expect(PoliticsState.empty.toJson().containsKey('powerAtTurn'), isFalse);
  });
}
