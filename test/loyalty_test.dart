// The price of loyalty (v5.2 step 3): a held specialisation follows its
// clan's standing (specsByStanding: halved when Resented or Hostile, asleep
// when Hunted), and each new chapter the patron's favour cools its rivals
// (applyLoyaltyDrift). LOYALTY_REPORT=1 prints what a loyal run's rivals
// end at, by patron (the PR's table).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/spec_variants.dart';
import 'package:narrative_data_app/combat/specialisations.dart';
import 'package:narrative_data_app/data/factions.dart';

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
  PoliticsState at(Map<String, num> standings) {
    var state = PoliticsState.empty;
    for (final e in standings.entries) {
      state = setStandingValue(state, e.key, e.value, 'edit', data: data).state;
    }
    return state;
  }

  test('each specialisation\'s clan is the one specialisations.json names', () {
    final infos = specInfosFrom(_table('specialisations'));
    for (final spec in Spec.values) {
      expect(clanOfSpec(spec), infos[specId(spec)]!.factionId,
          reason: specId(spec));
    }
    // Every gift and rank names its specialisation.
    for (final v in specVariantsFrom(_table('spec_variants')).values) {
      expect(specOfHeldId(v.id), v.spec, reason: v.id);
    }
  });

  test('a cold clan halves its specialisation, a hunting one puts it to sleep',
      () {
    const held = [
      'berserker',
      'tar_hands_berserker',
      'berserker_ii',
      'fever_blade',
      'barkbleeders_fever_blade',
    ];
    num standing(Map<String, num> s, String id) => s[id] ?? 0;
    // Friendly with both: all of it plays.
    var by = specsByStanding(held, (id) => standing({'crows': 15}, id));
    expect(by.ids, held);
    expect(by.halved, isEmpty);
    // Resented with the Crows: the Berserker alone, every other round.
    by = specsByStanding(held, (id) => standing({'crows': -20}, id));
    expect(by.ids, ['berserker', 'fever_blade', 'barkbleeders_fever_blade']);
    expect(by.halved, {Spec.berserker});
    // Hostile: the same.
    by = specsByStanding(held, (id) => standing({'crows': -40}, id));
    expect(by.halved, {Spec.berserker});
    // Hunted by the Crows, Hostile with the Mire.
    by = specsByStanding(
        held, (id) => standing({'crows': -70, 'mire': -30}, id));
    expect(by.ids, ['fever_blade']);
    expect(by.halved, {Spec.feverBlade});
    // Wary and Unfriendly change nothing.
    by = specsByStanding(held, (id) => standing({'crows': -15}, id));
    expect(by.ids, held);
    expect(halvedPlaysIn(1), isTrue);
    expect(halvedPlaysIn(2), isFalse);
  });

  test('the patron: the sworn clan, else the highest at Trusted', () {
    expect(loyaltyPatron(at({'crows': 20}), data), '');
    expect(loyaltyPatron(at({'crows': 30, 'mire': 40}), data), 'mire');
    expect(loyaltyPatron(at({'dominion': 70}), data), 'dominion');
  });

  test('each chapter, the patron\'s favour cools its rivals', () {
    // Trusted with the Dominion: its rivals −2, nobody else.
    var state = at({'dominion': 40});
    final rivals = rivalsOf('dominion', state, data);
    expect(rivals, isNotEmpty);
    var drift = loyaltyDrift(state, data);
    expect(drift.keys.toSet(), rivals.toSet());
    expect(drift.values.toSet(), {trustedRivalDrift});
    // Sworn: rivals −4, tense −2, allies +1.
    state = at({'dominion': 70});
    drift = loyaltyDrift(state, data);
    for (final id in rivalsOf('dominion', state, data)) {
      expect(drift[id], swornRivalDrift, reason: id);
    }
    for (final id in tenseWith('dominion', state, data)) {
      expect(drift[id], swornTenseDrift, reason: id);
    }
    for (final id in alliesOf('dominion', state, data)) {
      expect(drift[id], swornAllyDrift, reason: id);
    }
    // Applied and logged, the patron named.
    final before = state.standingOf(rivals.first, data);
    final result = applyLoyaltyDrift(state, data: data, chapter: 4);
    expect(result.state.standingOf(rivals.first, data), before - 4);
    expect(result.entry!.cause, 'loyalty:dominion');
    expect(result.entry!.chapter, 4);
    // Friend and below: nothing.
    expect(applyLoyaltyDrift(at({'crows': 20}), data: data).changed, isFalse);
  });

  test('what a loyal run\'s rivals end at, by patron', () {
    // Trusted in chapter 3, Sworn in chapter 5, eight chapters: the gains
    // through applyStandingChange (their ripple and the swearing's cost),
    // a chapter's drift at each chapter from 2.
    final lines = <String>[];
    for (final patron in data.clans.map((c) => c.id)) {
      var state = PoliticsState.empty;
      final costs = <String>[];
      for (var chapter = 2; chapter <= 8; chapter++) {
        final target = chapter >= 5
            ? 70
            : chapter >= 3
                ? 40
                : 15;
        final gap = target - state.standingOf(patron, data);
        if (gap > 0) {
          state = applyStandingChange(state, patron, gap, 'quest',
                  data: data, chapter: chapter)
              .state;
        }
        state = applyLoyaltyDrift(state, data: data, chapter: chapter).state;
      }
      for (final clan in data.clans) {
        if (clan.id == patron) continue;
        final value = state.standingOf(clan.id, data);
        costs.add('${clan.id} ${value.round()} '
            '(${standingTierFor(value).name})');
      }
      lines.add('| $patron | ${costs.join(', ')} |');
      // Sworn, it costs at least one clan its trade.
      expect(
          data.clans.any((c) =>
              c.id != patron &&
              standingTierFor(state.standingOf(c.id, data)).index <=
                  StandingTier.hostile.index),
          isTrue,
          reason: patron);
    }
    if (Platform.environment['LOYALTY_REPORT'] != null) {
      // ignore: avoid_print
      print(lines.join('\n'));
    }
  });
}
