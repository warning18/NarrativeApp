// The weak links' gifts (v5.2 step 3c, specialisations.dart): eight
// smaller twists, one for each clan only weakly tied to a profession,
// offered from Friend at half a main specialisation's rate, rare, and never
// with sub-clan gifts or a rank II; and their rules' numbers.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/spec_variants.dart';
import 'package:narrative_data_app/combat/specialisations.dart';
import 'package:narrative_data_app/combat/status_effect.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/signs.dart' show SignRarity;

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final specs = specInfosFrom(_table('specialisations'));
  final variants = specVariantsFrom(_table('spec_variants'));

  test('eight weak links, one a clan and profession, no variants or rank', () {
    final raw = _table('specialisations');
    expect(weakLinkSpecs, hasLength(8));
    for (final spec in weakLinkSpecs) {
      final info = specs[specId(spec)]!;
      expect((raw[info.id] as Map)['link'], 'weak', reason: info.id);
      // Not a profession's main clan.
      expect(
          specs.values.any((m) =>
              isMainSpec(m.spec) &&
              m.factionId == info.factionId &&
              m.professionId == info.professionId),
          isFalse,
          reason: info.id);
      expect(variants.values.where((v) => v.spec == spec), isEmpty,
          reason: info.id);
    }
  });

  test('offered from Friend, rare, half as often', () {
    final data = ClanData.fromTables(
      factions: _table('factions'),
      subclans: _table('subclans'),
      relations: _table('relations'),
      titles: _table('titles'),
    );
    OfferContext ctx(String clan, num standing, String profession,
            {List<String> held = const []}) =>
        OfferContext(
          data: data,
          politics: setStandingValue(
                  PoliticsState.empty, clan, standing, 'edit',
                  data: data)
              .state,
          professionId: profession,
          raceId: 'human',
          specs: specs,
          specVariants: variants,
          heldSpecIds: held,
        );
    expect(
        offerableSpecsFor('vigil', ctx('vigil', 20, 'warrior')), ['standfast']);
    expect(offerableSpecsFor('vigil', ctx('vigil', 10, 'warrior')), isEmpty);
    // Held: nothing more, even Sworn (no variants, no rank II).
    expect(
        offerableSpecsFor(
            'vigil', ctx('vigil', 70, 'warrior', held: ['standfast'])),
        isEmpty);
    // Half as often as a main clan's specialisation, and rare.
    int came(String clan, String profession) {
      final random = Random(3);
      var n = 0;
      for (var i = 0; i < 400; i++) {
        final gift = drawGift(clan, ctx(clan, 20, profession), random);
        if (gift?.kind != GiftKind.spec) continue;
        n++;
        if (weakLinkSpecs.contains(specNamed(gift!.id))) {
          expect(gift.rarity, SignRarity.rare);
        }
      }
      return n;
    }

    final weak = came('vigil', 'warrior');
    final main = came('vigil', 'cleric');
    expect(weak, greaterThan(0));
    expect(weak, lessThan(main));
  });

  test('the rules\' numbers', () {
    expect(overheal(30, 90, 100), 20);
    expect(overheal(5, 90, 100), 0);
    expect(stitchThrust(20), 20);
    expect(stitchThrust(0), 0);
    const stun = StatusEffect(type: StatusEffectType.stun, remainingTurns: 1);
    expect(lingered(stun).remainingTurns, 2);
    expect(pitchSlow.type, StatusEffectType.weaken);
    expect(faceStrikes('Attack'), isTrue);
    expect(faceStrikes('Skill'), isTrue);
    expect(faceStrikes('Defend'), isFalse);
  });
}
