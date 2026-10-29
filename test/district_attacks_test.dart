// Attacks by rival clans (wave 18 step 2, item 1; district_attacks.dart):
// who attacks whom, one siege a town, the siege settled away (taken or
// held), the defence scene and its choices, and the siege flags.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/district_attacks.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// A Random whose every double is [value] and every int 0.
class _Fixed implements Random {
  _Fixed(this.value);
  final double value;
  @override
  double nextDouble() => value;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

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
  final clans = data.factions.keys.toList();

  /// Every pair of clans at [step], but [except].
  PoliticsState related(int step, [Map<String, int> except = const {}]) =>
      PoliticsState.empty.copyWith(relationSteps: {
        for (final a in clans)
          for (final b in clans)
            if (a.compareTo(b) < 0) relationKey(a, b): step,
        ...except,
      });

  ({PoliticsState state, List<DistrictSiege> begun}) roll(
          PoliticsState state, double dice) =>
      rollDistrictAttacks(state,
          data: data, geography: geography, day: 4, random: _Fixed(dice));

  String cityOf(String districtId) => geography.locationOf(districtId)!.id;

  test('a blood feud attacks; tense or warmer never does', () {
    expect(roll(related(4), 0).begun, isEmpty);
    final feud =
        roll(related(4, {relationKey('dominion', 'crows'): 1}), 0.3).begun;
    expect(feud, isNotEmpty);
    for (final siege in feud) {
      expect({siege.attacker, siege.holder}, {'dominion', 'crows'});
      expect(holderOf(siege.districtId, geography, PoliticsState.empty),
          siege.holder);
      expect(siege.until, 4 + siegeDays);
    }
    // A blood feud's odds are 35%: a roll of 0.4 starts nothing.
    expect(roll(related(4, {relationKey('dominion', 'crows'): 1}), 0.4).begun,
        isEmpty);
    // Hostile's 10%: 0.05 is enough, 0.15 is not.
    final hostile = related(4, {relationKey('dominion', 'crows'): 3});
    expect(roll(hostile, 0.05).begun, isNotEmpty);
    expect(roll(hostile, 0.15).begun, isEmpty);
  });

  test('at most one siege a town, none in a town under siege', () {
    final first = roll(related(1), 0);
    expect(first.begun, isNotEmpty);
    final towns = [for (final s in first.begun) s.cityId];
    expect(towns.toSet().length, towns.length);
    for (final siege in first.begun) {
      expect(cityOf(siege.districtId), siege.cityId);
      expect(first.state.sieges[siege.districtId]!['attacker'], siege.attacker);
    }
    // Each siege begun is told.
    final told = first.state.news.where((n) => n.eventId.startsWith('siege:'));
    expect(told, hasLength(first.begun.length));
    expect(told.first.text, contains('has two days'));
    expect(told.first.textFr, contains('deux jours'));
    expect(roll(first.state, 0).begun, isEmpty);
  });

  test('a clan below the power floor, or fallen, never attacks', () {
    final weak = related(1).copyWith(power: {
      for (final c in clans) c: attackMinPower - 1,
    });
    expect(roll(weak, 0).begun, isEmpty);
    final fallen = related(4, {relationKey('dominion', 'crows'): 1})
        .copyWith(fallen: ['dominion', 'crows']);
    expect(roll(fallen, 0).begun, isEmpty);
  });

  DistrictSiege siegeOf(PoliticsState state) => siegesOf(state).single;

  PoliticsState oneSiege() {
    final rolled =
        roll(related(4, {relationKey('dominion', 'crows'): 1}), 0).state;
    final siege = siegesOf(rolled).first;
    return rolled.copyWith(sieges: {siege.districtId: siege.toEntry()});
  }

  test('a siege settled away: taken with war spoils, or held as news', () {
    final state = oneSiege();
    final siege = siegeOf(state);
    final changes = <TerritoryChange>[];
    final taken = settleSiegeAway(state, siege,
        data: data,
        geography: geography,
        random: _Fixed(0),
        chapter: 3,
        changes: changes);
    expect(taken.sieges, isEmpty);
    expect(holderOf(siege.districtId, geography, taken), siege.attacker);
    expect(changes.single.cause, 'war');
    expect(taken.news.last.eventId, 'territory:${siege.districtId}');
    expect(
        taken.news.last.text,
        startsWith(
            '${data.faction(siege.attacker)!.nameFor(AppLanguage.en)} took '));
    expect(powerOf(taken, siege.attacker, data),
        powerOf(state, siege.attacker, data) + warSpoils);
    expect(powerOf(taken, siege.holder, data),
        powerOf(state, siege.holder, data) - warLoss);

    final held = settleSiegeAway(state, siege,
        data: data, geography: geography, random: _Fixed(0.99));
    expect(held.sieges, isEmpty);
    expect(holderOf(siege.districtId, geography, held), siege.holder);
    expect(held.news.last.eventId, 'siege:${siege.districtId}');
    expect(held.news.last.text, contains('held.'));
    expect(held.news.last.textFr, contains('a tenu bon'));

    // The holder changed meanwhile: nothing to take.
    final moved = state.copyWith(control: {siege.districtId: 'vigil'});
    final over = settleSiegeAway(moved, siege,
        data: data, geography: geography, random: _Fixed(0));
    expect(over.sieges, isEmpty);
    expect(holderOf(siege.districtId, geography, over), 'vigil');
  });

  test('the French news agrees with the clan', () {
    final mire = data.faction('mire');
    final vigil = data.faction('vigil');
    expect(
        siegeBegunNews(AppLanguage.fr,
            district: 'la Ruelle', attacker: mire, holder: vigil),
        'Les Cours du Marais marchent sur la Ruelle. '
        'La Veille Grise a deux jours.');
    expect(
        siegeTakenNews(AppLanguage.fr,
            district: 'la Ruelle', attacker: vigil, holder: mire),
        'La Veille Grise a pris la Ruelle aux Cours du Marais.');
    expect(siegeHeldNews(AppLanguage.fr, district: 'La Ruelle', attacker: mire),
        'La Ruelle a tenu bon. Les Cours du Marais ont rebroussé chemin.');
  });

  test('the win chance is kept between its floor and ceiling', () {
    final state = oneSiege();
    final siege = siegeOf(state);
    double chance(Map<String, int> power) =>
        attackerWinChance(state.copyWith(power: power), siege,
            data: data, geography: geography);
    expect(chance({siege.attacker: 100, siege.holder: 0}), attackOddsCeiling);
    expect(chance({siege.attacker: 0, siege.holder: 100}), attackOddsFloor);
  });

  test('the defence scene: hold, join or stand aside', () {
    final state = oneSiege();
    final siege = siegeOf(state);
    final node = buildSiegeNode(state, siege,
        data: data,
        geography: geography,
        enemies: enemies,
        chapter: 4,
        random: _Fixed(0))!;
    expect(isSiegeNode(node.id), isTrue);
    expect(node.choices, hasLength(3));
    final [hold, join, aside] = node.choices;
    expect(hold.triggerEnemyId, isNotEmpty);
    expect(hold.politics!.standing[siege.holder], siegeDefendStanding);
    expect(hold.politics!.power[siege.attacker], -siegeDefendAttackerPower);
    expect(
        hold.politics!.flags, [siegeOutcomeFlag(siege.districtId, 'defended')]);
    expect(join.politics!.control, {siege.districtId: siege.attacker});
    expect(
        join.politics!.flags, [siegeOutcomeFlag(siege.districtId, 'joined')]);

    expect(applySiegeChoice(state, hold.politics!.settleSiege).sieges, isEmpty);
    final stoodAside = applySiegeChoice(state, aside.politics!.settleSiege);
    expect(siegeOf(stoodAside).met, isTrue);
    // Met once: not met again on the next road, but still settled.
    expect(
        siegeToMeet(state, fromCity: siege.cityId, toCity: 'nowhere')
            ?.districtId,
        siege.districtId);
    expect(siegeToMeet(stoodAside, fromCity: siege.cityId, toCity: ''), isNull);
    expect(siegeToMeet(state, fromCity: 'a', toCity: 'b'), isNull);
    expect(expiredSieges(stoodAside, siege.until), isEmpty);
    expect(expiredSieges(stoodAside, siege.until + 1).single.districtId,
        siege.districtId);
  });

  test('the sieges are saved and loaded', () {
    final state = applySiegeChoice(
        oneSiege(), '${siegeOf(oneSiege()).districtId}$asideSuffix');
    final loaded = PoliticsState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>);
    expect(loaded.sieges, state.sieges);
    expect(PoliticsState.empty.toJson().containsKey('sieges'), isFalse);
  });

  test('the siege flags follow the sieges; outcome flags stay', () {
    final state = oneSiege();
    final siege = siegeOf(state);
    final d = siege.districtId;
    final flags = syncSiegeFlags(['other'], state);
    expect(flags, ['other', attackFlag(d), attackByFlag(d, siege.attacker)]);
    expect(syncSiegeFlags(flags, state), same(flags));
    final over = syncSiegeFlags(
        [...flags, siegeOutcomeFlag(d, 'defended')], PoliticsState.empty);
    expect(over, ['other', siegeOutcomeFlag(d, 'defended')]);
  });

  // The user's rule (wave 18 step 2, Q1 = A): a guarded clan may shrink but
  // not disappear. The Penitents against everyone, at their worst: every
  // chapter's turn, every attack rolled and every siege lost.
  test('a guarded seat is never attacked: the Penitents shrink, never fall',
      () {
    const wall = 'ashen_quarter_wall_of_names';
    expect(seatGuarded('penitents'), isTrue);
    expect(data.faction('penitents')!.seat, wall);
    var state = related(1).copyWith(power: {
      for (final c in clans) c: 90,
      'penitents': attackMinPower,
    });
    for (var chapter = 2; chapter <= 8; chapter++) {
      state = territoryTurn(state,
              data: data, geography: geography, chapter: chapter)
          .state;
      final rolled = rollDistrictAttacks(state,
          data: data, geography: geography, day: chapter, random: _Fixed(0));
      expect(rolled.begun.map((s) => s.districtId), isNot(contains(wall)));
      state = rolled.state;
      for (final siege in siegesOf(state)) {
        state = settleSiegeAway(state, siege,
            data: data, geography: geography, random: _Fixed(0));
      }
    }
    expect(holderOf(wall, geography, state), 'penitents');
    expect(state.fallen, isNot(contains('penitents')));
    // They shrank: Last Lantern Street is gone.
    expect(holderOf('reliquary_last_lantern', geography, state),
        isNot('penitents'));

    // A siege of the seat saved before the guard breaks, with nothing taken.
    final old = DistrictSiege(
        districtId: wall,
        attacker: 'dominion',
        holder: 'penitents',
        cityId: 'ashen_quarter',
        until: 1);
    final settled = settleSiegeAway(
        PoliticsState.empty.copyWith(sieges: {wall: old.toEntry()}), old,
        data: data, geography: geography, random: _Fixed(0));
    expect(settled.sieges, isEmpty);
    expect(holderOf(wall, geography, settled), 'penitents');
  });
}
