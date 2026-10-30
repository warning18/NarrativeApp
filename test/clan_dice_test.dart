// The clans' dice (the user's rules, v1.676, clan_dice.dart): one per main
// clan, given once on its banner card from Trusted, and Resonance's +1 on
// the low faces while it is your main clan at Friend or better.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/combat/clan_dice.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/offers.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final dice = _table('dice');
  final data = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
  );
  PoliticsState standing(String clan, num value, {String sworn = ''}) =>
      setStandingValue(PoliticsState.empty, clan, value, 'edit', data: data)
          .state
          .copyWith(swornFactionId: sworn);

  test('each main clan has its one die; the others none', () {
    expect({
      for (final clan in [
        'dominion',
        'vigil',
        'compact',
        'mire',
        'crows',
        'penitents',
      ])
        clan: clanDieOf(clan, dice),
    }, {
      'dominion': 'lantern_die',
      'vigil': 'vigil_die',
      'compact': 'cinder_die',
      'mire': 'court_die',
      'crows': 'tally_die',
      'penitents': 'ossuary_die',
    });
    for (final clan in ['choir', 'pit', 'giants']) {
      expect(clanDieOf(clan, dice), isNull, reason: clan);
    }
  });

  test("a clan's gift is no shop's; the Tally die stays a quest reward", () {
    final shops = _table('shops');
    final sold = {
      for (final shop in shops.values.whereType<Map<String, dynamic>>())
        ...((shop['diceStock'] as List?) ?? const []).map((e) => '$e'),
    };
    for (final id in [
      'lantern_die',
      'vigil_die',
      'cinder_die',
      'court_die',
      'tally_die',
      'ossuary_die'
    ]) {
      expect(sold, isNot(contains(id)), reason: id);
    }
    final quests = _table('quests');
    expect(
        quests.values
            .whereType<Map<String, dynamic>>()
            .any((q) => q['rewardDiceID'] == 'tally_die'),
        isTrue);
  });

  test("Resonance: the faces of 1 to 3 count one more, the others as they are",
      () {
    final faces = [
      {'type': 'Skill', 'value': 0},
      {'type': 'Attack', 'value': 1},
      {'type': 'Defend', 'value': 3},
      {'type': 'Heal', 'value': 4},
    ];
    expect([for (final f in resonantFaces(faces)) f['value']], [0, 2, 4, 4]);
  });

  test('Resonance lights with the main clan at Friend or better', () {
    final vigil = dice['vigil_die'] as Map<String, dynamic>;
    Resonance of(PoliticsState p) =>
        resonanceOf(vigil, politics: p, data: data);
    expect(of(standing('vigil', 20, sworn: 'vigil')), Resonance.lit);
    expect(of(standing('vigil', 5, sworn: 'vigil')), Resonance.standingLow);
    expect(of(standing('vigil', 40, sworn: 'mire')), Resonance.notMainClan);
    expect(
        resonanceOf(dice['starter_die'] as Map<String, dynamic>,
            politics: standing('vigil', 40, sworn: 'vigil'), data: data),
        Resonance.none);
  });

  test('the banner card brings the die from Trusted, once', () {
    OfferContext ctx(num value, {List<String> owned = const []}) =>
        OfferContext(
          data: data,
          politics: standing('compact', value),
          dice: dice,
          ownedDiceIds: owned,
        );
    expect(offerableDieFor('compact', ctx(22)), isNull);
    expect(offerableDieFor('compact', ctx(30)), 'cinder_die');
    expect(availableGiftKinds('compact', ctx(30)), contains(GiftKind.die));
    expect(offerableDieFor('compact', ctx(30, owned: ['cinder_die'])), isNull);
  });
}
