// Signs (v1.192), the rules: rarity and level, what an offer holds, which
// patron makes it, the slots, the Choir's vows and the Pit's pacts, favour,
// and what the held signs add up to.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/combat/face_keywords.dart';
import 'package:narrative_data_app/combat/status_effect.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';

Patron _patron(String id, PatronKind kind,
        {String unlockFlag = '', int? minAlignment, int? maxAlignment}) =>
    Patron(
      id: id,
      name: id,
      kind: kind,
      greetings: const ['Well met.', 'Again.', 'Sit.'],
      unlockFlag: unlockFlag,
      minAlignment: minAlignment,
      maxAlignment: maxAlignment,
    );

final Map<String, Patron> _patrons = {
  for (final p in [
    _patron('red', PatronKind.clan),
    _patron('blue', PatronKind.clan),
    _patron('green', PatronKind.clan),
    _patron('gold', PatronKind.clan),
    _patron('tribe', PatronKind.tribe, unlockFlag: 'met_tribe'),
    _patron(choirPatronId, PatronKind.otherworld, minAlignment: 10),
    _patron(pitPatronId, PatronKind.otherworld, maxAlignment: -10),
  ])
    p.id: p,
};

const _flat = SignEffect(kind: SignEffectKind.strikeFlat, value: 2);

/// Four signs a patron (strike, guard and two passives), a duo of red and
/// blue, and a pact on every Pit sign.
final Map<String, SignDef> _signs = {
  for (final id in _patrons.keys) ...{
    '${id}_strike': SignDef(
      id: '${id}_strike',
      patronId: id,
      slot: SignSlot.strike,
      name: '$id strike',
      effects: const [_flat],
      pact: id == pitPatronId
          ? const SignPact(curse: PactCurse.enemyDamagePercent, value: 20)
          : null,
    ),
    '${id}_guard': SignDef(
      id: '${id}_guard',
      patronId: id,
      slot: SignSlot.guard,
      name: '$id guard',
      effects: const [SignEffect(kind: SignEffectKind.guardFlat, value: 2)],
    ),
    '${id}_health': SignDef(
      id: '${id}_health',
      patronId: id,
      slot: SignSlot.passive,
      name: '$id health',
      effects: const [SignEffect(kind: SignEffectKind.maxHealth, value: 10)],
    ),
    '${id}_armor': SignDef(
      id: '${id}_armor',
      patronId: id,
      slot: SignSlot.passive,
      name: '$id armor',
      effects: const [SignEffect(kind: SignEffectKind.armor, value: 1)],
    ),
  },
  'duo_red_blue': const SignDef(
    id: 'duo_red_blue',
    patronId: 'red',
    slot: SignSlot.passive,
    name: 'Duo',
    effects: [SignEffect(kind: SignEffectKind.critChance, value: 5)],
    requiresPatrons: ['red', 'blue'],
  ),
};

Map<String, Patron> _only(Iterable<String> ids) =>
    {for (final id in ids) id: _patrons[id]!};

SignOffer? _offer({
  Map<String, Patron>? patrons,
  List<HeldSign> held = const [],
  Iterable<String> flags = const [],
  int alignment = 0,
  List<String> patronsThisLife = const [],
  List<String> patronsMet = const [],
  required int seed,
}) =>
    rollSignOffer(
      patrons: patrons ?? _patrons,
      signs: _signs,
      held: held,
      flags: flags,
      alignment: alignment,
      random: Random(seed),
      patronsThisLife: patronsThisLife,
      patronsMet: patronsMet,
    );

HeldSign _held(String id,
        {SignRarity rarity = SignRarity.common, int level = 1}) =>
    HeldSign(signId: id, rarity: rarity, level: level);

void main() {
  group('rarity and level', () {
    test('the odds start at 62/27/9/2; Luck and favour move Common\'s share',
        () {
      int sum(Map<SignRarity, int> odds) => odds.values.reduce((a, b) => a + b);
      expect(signRarityOdds(), signRarityBaseOdds);
      final lucky = signRarityOdds(luck: 5, favourLevel: 3);
      expect(lucky[SignRarity.common], 62 - 5 - 3);
      expect(lucky[SignRarity.rare], 27 + 5);
      expect(lucky[SignRarity.epic], 9 + 3);
      expect(lucky[SignRarity.heroic], 2);
      expect(sum(lucky), 100);
      final capped = signRarityOdds(luck: 40, favourLevel: 9);
      expect(capped[SignRarity.rare], 27 + luckRarityCap);
      expect(capped[SignRarity.epic], 9 + favourRarityCap);
      expect(sum(capped), 100);
    });

    test('rolls follow the odds, and a duo is never Common', () {
      final random = Random(7);
      final counts = <SignRarity, int>{};
      for (var i = 0; i < 20000; i++) {
        final rarity = rollSignRarity(random: random);
        counts[rarity] = (counts[rarity] ?? 0) + 1;
      }
      expect(counts[SignRarity.common]! / 20000, closeTo(0.62, 0.02));
      expect(counts[SignRarity.heroic]! / 20000, closeTo(0.02, 0.01));
      for (var seed = 0; seed < 500; seed++) {
        expect(rollSignRarity(random: Random(seed), duo: true),
            isNot(SignRarity.common));
      }
    });

    test('rarity and level scale a value; chances cap at 60, durations stay',
        () {
      expect(signPower(SignRarity.common, 1), 1);
      expect(signPower(SignRarity.rare, 3), 3);
      expect(signPower(SignRarity.heroic, 5), 7.5);
      expect(signPower(SignRarity.heroic, 9), 7.5, reason: 'level caps at 5');
      expect(_flat.scaled(SignRarity.rare, 3).value, 6);
      expect(_flat.scaled(SignRarity.epic, 1).value, 4);

      const poison = SignEffect(
        kind: SignEffectKind.strikeStatus,
        status: StatusEffectType.poison,
        chance: 25,
        duration: 2,
        magnitude: 3,
      );
      final raised = poison.scaled(SignRarity.rare, 1);
      expect(raised.chance, 38);
      expect(raised.duration, 2);
      expect(raised.magnitude, 3);
      expect(poison.scaled(SignRarity.heroic, 5).chance, signChanceCap);
      const crit = SignEffect(kind: SignEffectKind.critChance, value: 10);
      expect(crit.scaled(SignRarity.heroic, 5).value, signChanceCap);
      // A count or a switch is what it is.
      const cleanse = SignEffect(kind: SignEffectKind.mendCleanse, value: 1);
      expect(cleanse.scaled(SignRarity.heroic, 5).value, 1);
    });

    test('an effect reads from its record', () {
      final guard = SignEffect.tryParse({
        'kind': 'guardStatus',
        'status': 'stun',
        'chance': 15,
        'duration': 1,
        'magnitude': 0,
      })!;
      expect(guard.status, StatusEffectType.stun);
      expect(guard.inflicted!.remainingTurns, 1);
      // A guard with no status named weakens.
      expect(SignEffect.tryParse({'kind': 'guardStatus', 'chance': 10})!.status,
          StatusEffectType.weaken);
      expect(
          SignEffect.tryParse({'kind': 'strikeKeyword', 'keyword': 'pierce'})!
              .keyword,
          FaceKeyword.pierce);
      expect(SignEffect.tryParse({'kind': 'mendCleanse'})!.value, 1);
      expect(SignEffect.tryParse({'kind': 'notAKind', 'value': 3}), isNull);
      final def = SignDef.fromJson('x', {
        'patron': 'red',
        'slot': 'guard',
        'name': 'X',
        'effects': [
          {'kind': 'guardFlat', 'value': 2},
          {'kind': 'mystery'},
        ],
        'requiresPatrons': [],
        'pact': null,
      });
      expect(def.slot, SignSlot.guard);
      expect(def.effects, hasLength(1));
      expect(def.unknownEffectKinds, ['mystery']);
      expect(def.pact, isNull);
      expect(def.isDuo, isFalse);
    });

    test('one pick each odd level; favour levels every three signs', () {
      expect(signPicksFor(1, 2), 0);
      expect(signPicksFor(2, 3), 1);
      expect(signPicksFor(1, 3), 1);
      expect(signPicksFor(1, 9), 4);
      expect(signPicksFor(5, 5), 0);
      expect(favourLevelFor(0), 0);
      expect(favourLevelFor(2), 0);
      expect(favourLevelFor(3), 1);
      expect(favourLevelFor(14), 4);
      expect(favourLevelFor(99), maxFavourLevel);
    });
  });

  group('the offer', () {
    test('three different signs of one patron, none of them held', () {
      final held = [_held('red_strike'), _held('blue_guard')];
      for (var seed = 0; seed < 100; seed++) {
        final offer = _offer(held: held, seed: seed)!;
        expect(offer.cards, hasLength(signOfferSize));
        expect(offer.cards.map((c) => c.signId).toSet(), hasLength(3));
        for (final card in offer.cards) {
          expect(_signs[card.signId]!.offeredBy(offer.patronId), isTrue);
          expect(held.map((h) => h.signId), isNot(contains(card.signId)));
        }
      }
    });

    test('fewer than three left: what is left; none: no offer', () {
      final red = _only(['red']);
      final offer = _offer(
          patrons: red,
          held: [_held('red_strike'), _held('red_guard'), _held('red_armor')],
          seed: 1)!;
      expect(offer.cards.map((c) => c.signId), ['red_health']);
      final all = [
        for (final id in _signs.keys)
          if (_signs[id]!.patronId == 'red' && !_signs[id]!.isDuo) _held(id),
      ];
      expect(_offer(patrons: red, held: all, seed: 1), isNull);
      expect(
          anyPatronCanOffer(
              patrons: red,
              signs: _signs,
              held: all,
              flags: const [],
              alignment: 0),
          isFalse);
    });

    test('a duo comes in once both its patrons have given, about 35%', () {
      final pair = _only(['red', 'blue']);
      for (var seed = 0; seed < 200; seed++) {
        final offer =
            _offer(patrons: pair, held: [_held('red_armor')], seed: seed)!;
        expect(
            offer.cards.map((c) => c.signId), isNot(contains('duo_red_blue')));
      }
      var duos = 0;
      for (var seed = 0; seed < 4000; seed++) {
        final offer = _offer(
            patrons: pair,
            held: [_held('red_armor'), _held('blue_armor')],
            seed: seed)!;
        final card = offer.cardFor('duo_red_blue');
        if (card != null) {
          duos++;
          expect(card.rarity, isNot(SignRarity.common));
        }
      }
      expect(duos / 4000, closeTo(duoOfferChance, 0.03));
    });

    test('a patron offers only when the story lets them', () {
      final ids = {
        for (var seed = 0; seed < 300; seed++) _offer(seed: seed)!.patronId,
      };
      expect(ids, containsAll(['red', 'blue', 'green', 'gold']));
      expect(ids, isNot(contains('tribe')));
      expect(ids, isNot(contains(choirPatronId)));
      expect(ids, isNot(contains(pitPatronId)));

      final met = {
        for (var seed = 0; seed < 300; seed++)
          _offer(flags: const ['met_tribe'], alignment: 12, seed: seed)!
              .patronId,
      };
      expect(met, containsAll(['tribe', choirPatronId]));
      expect(met, isNot(contains(pitPatronId)));
      final dark = {
        for (var seed = 0; seed < 300; seed++)
          _offer(alignment: -10, seed: seed)!.patronId,
      };
      expect(dark, contains(pitPatronId));
      expect(dark, isNot(contains(choirPatronId)));
    });

    test('no cap on clans a life (v1.193): a fourth still comes', () {
      const life = ['red', 'blue', 'green'];
      for (final id in ['gold', 'red', 'tribe']) {
        expect(
            closedThisLife(_patrons[id]!,
                patronsThisLife: life, patrons: _patrons),
            isFalse,
            reason: id);
      }
      final met = {
        for (var seed = 0; seed < 300; seed++)
          _offer(patronsThisLife: life, seed: seed)!.patronId,
      };
      expect(met, contains('gold'));
    });

    test('the Choir and the Pit shut each other out for the life', () {
      expect(
          closedThisLife(_patrons[pitPatronId]!,
              patronsThisLife: const [choirPatronId], patrons: _patrons),
          isTrue);
      expect(
          closedThisLife(_patrons[choirPatronId]!,
              patronsThisLife: const ['red', pitPatronId], patrons: _patrons),
          isTrue);
      expect(
          otherworldClaimOf(const ['red', pitPatronId], _patrons), pitPatronId);
      for (var seed = 0; seed < 300; seed++) {
        expect(
            _offer(
                    alignment: -20,
                    patronsThisLife: const [choirPatronId],
                    seed: seed)!
                .patronId,
            isNot(pitPatronId));
      }
    });

    test('a patron that gave returns 60% of the time; tribes weigh half', () {
      var returning = 0;
      for (var seed = 0; seed < 4000; seed++) {
        if (_offer(patronsThisLife: const ['red'], seed: seed)!.patronId ==
            'red') {
          returning++;
        }
      }
      expect(returning / 4000, closeTo(returningPatronChance, 0.03));

      var clan = 0;
      for (var seed = 0; seed < 4000; seed++) {
        final offer = _offer(
            patrons: _only(['red', 'tribe']),
            flags: const ['met_tribe'],
            seed: seed)!;
        if (offer.patronId == 'red') clan++;
      }
      expect(clan / 4000, closeTo(1 / (1 + tribeOfferWeight), 0.03));
    });

    test('the first offer opens with the intro; the offer keeps', () {
      final first = _offer(patrons: _only(['red']), seed: 3)!;
      expect(first.firstMeeting, isTrue);
      final again =
          _offer(patrons: _only(['red']), patronsMet: const ['red'], seed: 3)!;
      expect(again.firstMeeting, isFalse);
      expect(again.greetingIndex, lessThan(3));
      expect(SignOffer.tryParse(first.toJson()), first);
      expect(SignOffer.tryParse(null), isNull);
      expect(
          SignOffer.tryParse(const {'patronId': 'red', 'cards': []}), isNull);
    });
  });

  group('slots, vows and pacts', () {
    test('one sign a slot: the new one keeps the level and the better rarity',
        () {
      var held = <HeldSign>[];
      held =
          takeSign(held, _signs['red_strike']!, SignRarity.epic, _signs).held;
      held = raiseSign(held, 'red_strike')!;
      expect(held.single.level, 2);

      final swap =
          takeSign(held, _signs['blue_strike']!, SignRarity.rare, _signs);
      expect(swap.replaced, 'red_strike');
      expect(swap.held.single,
          _held('blue_strike', rarity: SignRarity.epic, level: 2));
      final better =
          takeSign(held, _signs['blue_strike']!, SignRarity.heroic, _signs);
      expect(better.held.single.rarity, SignRarity.heroic);

      // Passives pile up.
      var passives = <HeldSign>[];
      for (final id in ['red_health', 'blue_health', 'red_armor']) {
        final taken =
            takeSign(passives, _signs[id]!, SignRarity.common, _signs);
        expect(taken.replaced, isNull);
        passives = taken.held;
      }
      expect(passives, hasLength(3));
    });

    test('Titan\'s Blood raises a held sign up to level 5', () {
      var held = [_held('red_guard', level: 4)];
      held = raiseSign(held, 'red_guard')!;
      expect(held.single.level, maxSignLevel);
      expect(raiseSign(held, 'red_guard'), isNull);
      expect(raiseSign(held, 'blue_guard'), isNull);
    });

    test('a Choir vow holds at 0 and above, and falls silent below', () {
      final vow = [_held('${choirPatronId}_guard')];
      final kept = signEffectsFor(vow, _signs, alignment: 0);
      expect(kept.guardFlat, 2);
      expect(kept.silentVows, 0);
      final silent = signEffectsFor(vow, _signs, alignment: -1);
      expect(silent.guardFlat, 0);
      expect(silent.silentVows, 1);
      expect(alignmentShiftFor(_signs['${choirPatronId}_guard']!),
          otherworldAlignmentShift);
      expect(alignmentShiftFor(_signs['${pitPatronId}_guard']!),
          -otherworldAlignmentShift);
      expect(alignmentShiftFor(_signs['red_guard']!), 0);
    });

    test('a pact: the curse for three fights, then the gift for good', () {
      var held = takeSign(const [], _signs['${pitPatronId}_strike']!,
              SignRarity.common, _signs)
          .held;
      expect(held.single.pactFightsLeft, defaultPactFights);
      for (var fight = 0; fight < defaultPactFights; fight++) {
        final cursed = signEffectsFor(held, _signs, alignment: -20);
        expect(cursed.enemyDamagePercent, 20);
        expect(cursed.strikeFlat, 0, reason: 'no gift while cursed');
        expect(cursed.pactsRunning, 1);
        held = countDownPacts(held);
      }
      final paid = signEffectsFor(held, _signs, alignment: -20);
      expect(paid.enemyDamagePercent, 0);
      expect(paid.strikeFlat, 2);
      expect(countDownPacts(held), held);
    });

    test('the simulator takes an empty slot first, then the rarest', () {
      const offer = SignOffer(patronId: 'red', cards: [
        SignCard(signId: 'red_strike', rarity: SignRarity.heroic),
        SignCard(signId: 'red_guard', rarity: SignRarity.common),
        SignCard(signId: 'red_health', rarity: SignRarity.rare),
      ]);
      final held = [_held('blue_strike'), _held('blue_guard')];
      expect(preferredSignCard(offer, held, _signs)!.signId, 'red_health');
      expect(preferredSignCard(offer, const [], _signs)!.signId, 'red_strike');
    });

    test('held signs survive the save file', () {
      const held = HeldSign(
          signId: 'pit_strike',
          rarity: SignRarity.epic,
          level: 3,
          pactFightsLeft: 2);
      expect(HeldSign.fromJson(held.toJson()), held);
      expect(HeldSign.fromJson(const {'signId': 'x', 'level': 12}).level,
          maxSignLevel);
    });
  });

  group('what they add up to', () {
    test('every gift at its rarity and level, summed', () {
      final effects = signEffectsFor([
        _held('red_strike', rarity: SignRarity.rare, level: 2),
        _held('red_health', rarity: SignRarity.epic),
        _held('blue_health'),
        _held('red_armor'),
        _held('ghost_sign'),
      ], _signs, alignment: 0);
      expect(effects.strikeFlat, 5, reason: '2 x 1.5 x 1.5 = 4.5, rounded');
      expect(effects.maxHealth, 30);
      expect(effects.armor, 1);
      expect(signEffectsFor(const [], _signs, alignment: 0).isEmpty, isTrue);
    });

    test('every kind, curse, rarity, slot and status has its words', () {
      final keys = [
        for (final kind in SignEffectKind.values) signEffectKey(kind),
        for (final curse in PactCurse.values) pactCurseKey(curse),
        for (final rarity in SignRarity.values) signRarityKey(rarity),
        for (final slot in SignSlot.values) signSlotKey(slot),
        for (final type in StatusEffectType.values) 'sign_status_${type.name}',
        for (final kind in PatronKind.values) 'patron_kind_${kind.name}',
      ];
      for (final key in keys) {
        for (final lang in AppLanguage.values) {
          expect(trFor(lang, key), isNot(key), reason: '$key ($lang)');
        }
      }
    });

    test('a sign\'s lines are written from its numbers', () {
      const sign = SignDef(
        id: 's',
        patronId: 'red',
        slot: SignSlot.strike,
        name: 'S',
        effects: [
          SignEffect(kind: SignEffectKind.strikeDamagePercent, value: 10),
          SignEffect(
            kind: SignEffectKind.strikeStatus,
            status: StatusEffectType.poison,
            chance: 20,
            duration: 2,
            magnitude: 3,
          ),
        ],
      );
      expect(signEffectLines(sign, SignRarity.rare, 1, AppLanguage.en), [
        'Attack faces deal +15% damage.',
        'Attack faces: 30% chance to inflict poison (3 a turn for 2 turns).',
      ]);
      final fr = signEffectLines(sign, SignRarity.rare, 1, AppLanguage.fr);
      expect(fr.first, 'Les faces Attaque infligent +15 % de dégâts.');
      expect(fr.last, contains('Faces Attaque : 30 %'));
      const pact = SignPact(curse: PactCurse.goldPercentLoss, value: 40);
      expect(pactCurseText(pact, AppLanguage.en, fights: 2),
          'Pact: the next 2 fights pay 40% less, then the gift.');
    });
  });
}
