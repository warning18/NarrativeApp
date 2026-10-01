// Offers (v1.194), the rules: three suitors from different factions (who
// may come, the Choir/Pit lockout, the Wayfarer's place), the gifts each
// may bring by standing (skills by sponsored branch and depth, objects by
// tier, titles, the Sworn boon), what taking one does (standing and its
// ripple, the friend mark, the alignment), the titles standing earns, and
// the save's shapes.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/signs.dart';

Map<String, dynamic> _clan({
  int start = 0,
  int lean = 0,
  List<String> subclans = const [],
  List<String> sponsors = const [],
  List<Map<String, dynamic>> objects = const [],
  Map<String, dynamic>? sworn,
}) =>
    {
      'kind': 'clan',
      'name': 'N',
      'startStanding': start,
      'lean': lean,
      'subclans': subclans,
      'sponsors': sponsors,
      'objects': objects,
      if (sworn != null) 'sworn': sworn,
      'greetings': ['Hail.'],
    };

/// Red (warrior and human sponsor, two sub-clans, objects, a Sworn boon)
/// allied with blue (mage sponsor), rival of gold; green starts Hostile;
/// a tribe behind a flag; the Choir and the Pit.
final ClanData _data = ClanData.fromTables(
  factions: {
    'red': _clan(
      lean: 1,
      subclans: ['red_a', 'red_b'],
      sponsors: ['warrior_a', 'heritage_human'],
      objects: [
        {'itemId': 'blade', 'minTier': 'unknown'},
        {'itemId': 'plate', 'minTier': 'trusted'},
      ],
      sworn: {
        'name': 'Writ',
        'effects': [
          {'kind': 'writFace', 'value': 1},
        ],
      },
    ),
    'blue': _clan(sponsors: ['mage_a']),
    'green': _clan(start: -40),
    'gold': _clan(lean: -1),
    'tribe': {'kind': 'tribe', 'name': 'T', 'unlockFlag': 'found_tribe'},
    'choir': {'kind': 'otherworld', 'name': 'C', 'minAlignment': 10},
    'pit': {'kind': 'otherworld', 'name': 'P', 'maxAlignment': -10},
  },
  subclans: {
    'red_a': {'clan': 'red', 'name': 'A', 'lean': -1},
    'red_b': {'clan': 'red', 'name': 'B'},
  },
  relations: {
    'pairs': [
      {'a': 'red', 'b': 'blue', 'step': 7},
      {'a': 'red', 'b': 'gold', 'step': 2},
    ],
  },
  titles: {
    'red_offer': {'name': 'Red Friend', 'faction': 'red', 'source': 'offer'},
    'red_known': {
      'name': 'Known',
      'faction': 'red',
      'source': 'tier:known',
      'effects': [
        {'kind': 'armor', 'value': 1},
      ],
    },
    'marked': {
      'name': 'Marked',
      'faction': 'red',
      'source': 'mark:foe:red_a',
      'negative': true,
      'effects': [
        {'kind': 'goldPercent', 'value': -10},
      ],
    },
  },
);

const Map<String, dynamic> _trees = {
  'warrior_a': {
    'professionId': 'warrior',
    'skillIds': ['s1', 's2', 's3', 's4'],
  },
  'mage_a': {
    'professionId': 'mage',
    'skillIds': ['m1', 'm2'],
  },
  'heritage_human': {
    'raceId': 'human',
    'skillIds': ['h1', 'h2', 'h3'],
  },
};

const Map<String, dynamic> _skills = {
  's1': {'rarity': 'common'},
  's2': {'rarity': 'uncommon'},
  's3': {'rarity': 'rare', 'requiredSkillID': 'h1'},
  's4': {'rarity': 'legendary'},
  'm1': {'rarity': 'common'},
  'm2': {'rarity': 'common'},
  'h1': {'rarity': 'common'},
  'h2': {'rarity': 'common'},
  'h3': {'rarity': 'epic'},
};

const Map<String, dynamic> _items = {
  'blade': {'itemType': 'Weapon', 'rarity': 'Common'},
  'plate': {'itemType': 'Armor', 'rarity': 'Rare'},
  'potion_minor': {'itemType': 'Potion', 'rarity': 'Common'},
  'scroll': {'itemType': 'Scroll', 'rarity': 'Common'},
};

final Map<String, SignDef> _signs = parseSigns({
  for (final patron in ['red', 'blue', 'gold', 'tribe', 'choir', 'pit'])
    for (var i = 0; i < 3; i++)
      '${patron}_$i': {
        'patron': patron,
        'slot': 'passive',
        'name': '$patron $i',
        'effects': [
          {'kind': 'armor', 'value': 1},
        ],
      },
});

OfferContext _ctx({
  PoliticsState politics = PoliticsState.empty,
  Set<String> known = const {},
  int alignment = 0,
  List<String> flags = const [],
  List<String> thisLife = const [],
  List<String> titles = const [],
  List<String> boons = const [],
  Map<String, int> perks = const {},
  List<String> owned = const [],
  String profession = 'warrior',
  String race = 'human',
}) =>
    OfferContext(
      data: _data,
      politics: politics,
      signs: _signs,
      skills: _skills,
      skillTrees: _trees,
      items: _items,
      raceId: race,
      professionId: profession,
      knownSkillIds: known,
      ownedItemIds: owned,
      flags: flags,
      alignment: alignment,
      patronsThisLife: thisLife,
      heldTitleIds: titles,
      swornBoonIds: boons,
      perkRanks: perks,
    );

PoliticsState _at(Map<String, num> values) {
  var state = PoliticsState.empty;
  values.forEach((id, v) {
    state = setStandingValue(state, id, v, 'edit', data: _data).state;
  });
  return state;
}

const OfferTicket _level = OfferTicket(source: OfferSource.level);

void main() {
  group('who comes', () {
    test('three suitors, each from a different faction', () {
      final random = Random(1);
      for (var i = 0; i < 200; i++) {
        final offer = drawOffer(_level, _ctx(), random)!;
        expect(offer.suitors, hasLength(offerSuitorCount));
        final ids = offer.suitors.map((s) => s.factionId).toList();
        expect(ids.toSet(), hasLength(ids.length), reason: '$ids');
      }
    });

    test('a Hostile clan never comes; a tribe only once found', () {
      final random = Random(2);
      final seen = <String>{};
      for (var i = 0; i < 300; i++) {
        for (final s in drawOffer(_level, _ctx(), random)!.suitors) {
          seen.add(s.factionId);
        }
      }
      expect(seen, isNot(contains('green')));
      expect(seen, isNot(contains('tribe')));
      expect(seen, containsAll(['red', 'blue', 'gold', wayfarerId]));
      expect(eligibleSuitors(_ctx(flags: ['found_tribe'])), contains('tribe'));
    });

    test(
        'the Choir at 10 and up, the Pit at -10 and down, one shuts the '
        'other out', () {
      expect(eligibleSuitors(_ctx()), isNot(contains('choir')));
      expect(eligibleSuitors(_ctx(alignment: 10)), contains('choir'));
      expect(eligibleSuitors(_ctx(alignment: 10)), isNot(contains('pit')));
      expect(eligibleSuitors(_ctx(alignment: -10)), contains('pit'));
      expect(eligibleSuitors(_ctx(alignment: 40, thisLife: ['pit'])),
          isNot(contains('choir')));
    });

    test('the Wayfarer fills in when fewer than three factions can come', () {
      // Red and blue alone: gold Hostile, green Hostile.
      final politics = _at({'gold': -50});
      final offer = drawOffer(_level, _ctx(politics: politics), Random(3))!;
      expect(offer.suitors.map((s) => s.factionId),
          unorderedEquals(['red', 'blue', wayfarerId]));
      final wayfarer = offer.suitorOf(wayfarerId)!;
      expect(wayfarer.subclanId, isEmpty);
      expect([GiftKind.perk, GiftKind.object], contains(wayfarer.gift.kind));
    });

    test('the Wayfarer takes a place about one time in five', () {
      final random = Random(4);
      var comes = 0;
      const n = 1000;
      for (var i = 0; i < n; i++) {
        final offer = drawOffer(_level, _ctx(), random)!;
        if (offer.suitorOf(wayfarerId) != null) comes++;
      }
      expect(comes / n, inInclusiveRange(0.15, 0.25));
    });

    test('one place leans to the factions the character stands well with', () {
      final random = Random(5);
      final politics = _at({'red': 55});
      var red = 0;
      var gold = 0;
      for (var i = 0; i < 400; i++) {
        final ids =
            drawOffer(_level, _ctx(politics: politics), random)!.suitors.map(
                  (s) => s.factionId,
                );
        if (ids.contains('red')) red++;
        if (ids.contains('gold')) gold++;
      }
      expect(red, greaterThan(gold));
    });

    test('a clan suitor is voiced by one of its sub-clans', () {
      final random = Random(6);
      final voices = <String>{};
      for (var i = 0; i < 100; i++) {
        final red = drawSuitor('red', _ctx(), random)!;
        voices.add(red.subclanId);
      }
      expect(voices, {'red_a', 'red_b'});
      expect(drawSuitor('blue', _ctx(), random)!.subclanId, isEmpty);
    });

    test(
        'a quest\'s clan always comes, one rarity better; a chapter brings '
        'the Choir when the alignment leans', () {
      final random = Random(7);
      const quest = OfferTicket(
          source: OfferSource.quest, detail: 'q1', factionId: 'gold');
      for (var i = 0; i < 50; i++) {
        final offer = drawOffer(quest, _ctx(), random)!;
        expect(offer.suitorOf('gold'), isNotNull);
        expect(offer.suitorOf('gold')!.gift.rarity.index,
            greaterThanOrEqualTo(SignRarity.rare.index));
      }
      const chapter = OfferTicket(source: OfferSource.chapter, detail: '3');
      for (var i = 0; i < 50; i++) {
        final offer = drawOffer(chapter, _ctx(alignment: 12), random)!;
        expect(offer.suitorOf('choir'), isNotNull);
        expect(offer.suitorOf('pit'), isNull);
      }
    });
  });

  group('the gifts', () {
    test('a clan offers deeper skills as standing grows', () {
      // Unknown: the branch's first only (and the heritage's).
      expect(offerableSkillsFor('red', _ctx()), ['s1', 'h1']);
      // Known with s1 known: up to the second.
      expect(
          offerableSkillsFor(
              'red', _ctx(politics: _at({'red': 10}), known: {'s1'})),
          ['s2', 'h1']);
      // Unknown with s1 known: s2 waits for Known.
      expect(offerableSkillsFor('red', _ctx(known: {'s1'})), ['h1']);
      // Trusted: s3 also needs h1 (its requiredSkillID).
      final trusted = _at({'red': 30});
      expect(
          offerableSkillsFor(
              'red', _ctx(politics: trusted, known: {'s1', 's2'})),
          ['h1']);
      expect(
          offerableSkillsFor(
              'red', _ctx(politics: trusted, known: {'s1', 's2', 'h1'})),
          ['s3', 'h2']);
      // The fourth at Sworn only (or a quest's suitor at Trusted).
      final known = {'s1', 's2', 's3', 'h1', 'h2'};
      expect(offerableSkillsFor('red', _ctx(politics: trusted, known: known)),
          ['h3']);
      expect(
          offerableSkillsFor('red', _ctx(politics: trusted, known: known),
              tierBonus: 1),
          ['s4', 'h3']);
      expect(
          offerableSkillsFor(
              'red', _ctx(politics: _at({'red': 70}), known: known)),
          ['s4', 'h3']);
    });

    test('a branch is sponsored for the character\'s profession and race', () {
      expect(offerableSkillsFor('blue', _ctx()), isEmpty);
      expect(offerableSkillsFor('blue', _ctx(profession: 'mage')), ['m1']);
      expect(offerableSkillsFor('red', _ctx(race: 'elf')), ['s1']);
      expect(
          sponsorsOfSkill('s2',
              data: _data,
              skillTrees: _trees,
              raceId: 'human',
              professionId: 'warrior'),
          ['red']);
    });

    test('objects by tier, titles not held, the Sworn boon once', () {
      expect(offerableObjectsFor('red', _ctx()), ['blade']);
      expect(offerableObjectsFor('red', _ctx(owned: ['blade'])), isEmpty);
      expect(offerableObjectsFor('red', _ctx(politics: _at({'red': 30}))),
          ['blade', 'plate']);
      expect(offerableTitlesFor('red', _ctx()), ['red_offer']);
      expect(offerableTitlesFor('red', _ctx(titles: ['red_offer'])), isEmpty);
      final sworn = _at({'red': 70});
      expect(swornBoonDue('red', _ctx()), isFalse);
      expect(swornBoonDue('red', _ctx(politics: sworn)), isTrue);
      expect(
          swornBoonDue('red', _ctx(politics: sworn, boons: ['red'])), isFalse);
      // Sworn, the clan brings its boon first.
      final gift = drawGift('red', _ctx(politics: sworn), Random(1))!;
      expect(gift.kind, GiftKind.sworn);
      expect(gift.id, 'red');
    });

    test('the four kinds come at their weights among those a clan has', () {
      final random = Random(8);
      final counts = <GiftKind, int>{};
      for (var i = 0; i < 2000; i++) {
        final kind = drawGift('red', _ctx(), random)!.kind;
        counts[kind] = (counts[kind] ?? 0) + 1;
      }
      expect(counts.keys,
          containsAll([GiftKind.skill, GiftKind.sign, GiftKind.object]));
      expect(counts[GiftKind.skill]!, greaterThan(counts[GiftKind.object]!));
      expect(counts[GiftKind.object]!, greaterThan(counts[GiftKind.title]!));
    });

    test('the Choir and the Pit give signs only, at least Rare', () {
      final random = Random(9);
      for (var i = 0; i < 100; i++) {
        final gift = drawGift('choir', _ctx(alignment: 20), random)!;
        expect(gift.kind, GiftKind.sign);
        expect(gift.rarity.index, greaterThanOrEqualTo(SignRarity.rare.index));
        expect(_signs[gift.id]!.patronId, 'choir');
      }
    });

    test('the Wayfarer gives a perk rank or a common object', () {
      final random = Random(10);
      final kinds = <GiftKind>{};
      for (var i = 0; i < 100; i++) {
        final gift = drawWayfarerGift(_ctx(), random)!;
        kinds.add(gift.kind);
        if (gift.kind == GiftKind.object) {
          expect(['potion_minor', 'scroll'], contains(gift.id));
        }
      }
      expect(kinds, {GiftKind.perk, GiftKind.object});
    });
  });

  group('taking a suitor', () {
    test('+6 with the ripple, the voice a friend, the sub-clan\'s lean', () {
      const suitor = Suitor(
          factionId: 'red',
          subclanId: 'red_a',
          gift: OfferGift(kind: GiftKind.skill, id: 's1'));
      final preview = suitorPreview(suitor, _level,
          politics: PoliticsState.empty, data: _data);
      expect(preview, {'red': 6, 'blue': 1.5, 'gold': -3});
      final taken = acceptPolitics(suitor, _level,
          politics: PoliticsState.empty, data: _data, chapter: 2, day: 7);
      expect(taken.politics.standingOf('red', _data), 6);
      expect(taken.politics.standingOf('blue', _data), 1.5);
      expect(taken.politics.standingOf('gold', _data), -3);
      expect(taken.politics.markOf('red_a'), SubclanMark.friend);
      // The Inquisition-like sub-clan leans down, whatever the clan's lean.
      expect(taken.alignment, -1);
      expect(taken.politics.standingLog.first.cause, 'offer:s1');
      expect(taken.politics.standingLog.last.subclanId, 'red_a');
      // A sub-clan with no lean of its own: the clan's.
      expect(
          leanOf(
              const Suitor(
                  factionId: 'red',
                  subclanId: 'red_b',
                  gift: OfferGift(kind: GiftKind.skill, id: 's1')),
              _data),
          1);
    });

    test('a quest or a chapter\'s end is worth +10, logged as such', () {
      const suitor = Suitor(
          factionId: 'gold', gift: OfferGift(kind: GiftKind.sign, id: 'g'));
      const chapter = OfferTicket(source: OfferSource.chapter, detail: '4');
      final taken = acceptPolitics(suitor, chapter,
          politics: PoliticsState.empty, data: _data);
      expect(taken.politics.standingOf('gold', _data), 10);
      expect(taken.politics.standingOf('red', _data), -5);
      expect(taken.politics.standingLog.single.cause, 'chapter:4');
      expect(taken.alignment, -1);
      expect(
          offerCause(const OfferTicket(source: OfferSource.quest, detail: 'q9'),
              suitor.gift),
          'quest:q9');
    });

    test('the Wayfarer moves nothing; the Choir only by its sign', () {
      const wayfarer = Suitor(
          factionId: wayfarerId,
          gift: OfferGift(kind: GiftKind.perk, id: 'vigor'));
      final taken = acceptPolitics(wayfarer, _level,
          politics: PoliticsState.empty, data: _data);
      expect(taken.politics.isEmpty, isTrue);
      expect(taken.alignment, 0);
      expect(
          suitorPreview(wayfarer, _level,
              politics: PoliticsState.empty, data: _data),
          isEmpty);
      expect(
          leanOf(
              const Suitor(
                  factionId: 'choir',
                  gift: OfferGift(kind: GiftKind.sign, id: 'choir_0')),
              _data),
          0);
    });
  });

  group('titles', () {
    test(
        'a tier title is earned once reached and kept; the Marked comes and '
        'goes with the mark', () {
      var politics = _at({'red': 10});
      var titles = titlesEarned(const [], politics, _data);
      expect(titles.held, ['red_known']);
      expect(titles.gained, ['red_known']);
      politics =
          setStandingValue(politics, 'red', -10, 'edit', data: _data).state;
      politics = setSubclanMark(politics, 'red_a', SubclanMark.foe, 'story',
              data: _data)
          .state;
      titles = titlesEarned(titles.held, politics, _data);
      expect(titles.held, ['red_known', 'marked']);
      politics = setSubclanMark(politics, 'red_a', SubclanMark.none, 'story',
              data: _data)
          .state;
      titles = titlesEarned(titles.held, politics, _data);
      expect(titles.held, ['red_known']);
      expect(titles.lost, ['marked']);
    });

    test('the worn title and every bad one count, and the boon while sworn',
        () {
      expect(activeTitleAfter('', ['marked', 'red_known'], ['marked'], _data),
          'red_known');
      expect(activeTitleAfter('red_offer', ['red_offer'], const [], _data),
          'red_offer');
      expect(activeTitleAfter('gone', const [], const [], _data), '');
      final effects = clanEffectsFor(
        activeTitleId: 'red_known',
        heldTitleIds: ['red_known', 'red_offer', 'marked'],
        swornBoonIds: ['red'],
        swornFactionId: 'red',
        data: _data,
      );
      expect(effects.map((e) => e.kind), [
        SignEffectKind.armor,
        SignEffectKind.goldPercent,
        SignEffectKind.writFace,
      ]);
      final summed =
          signEffectsFor(const [], const {}, alignment: 0, extra: effects);
      expect(summed.armor, 1);
      expect(summed.goldPercent, -10);
      expect(summed.writFace, 1);
      // No longer sworn: the boon falls silent.
      expect(
          clanEffectsFor(
            activeTitleId: '',
            heldTitleIds: const [],
            swornBoonIds: ['red'],
            swornFactionId: '',
            data: _data,
          ),
          isEmpty);
    });
  });

  group('the save', () {
    test('an offer and its tickets round-trip', () {
      final offer = drawOffer(
          const OfferTicket(
              source: OfferSource.quest, detail: 'q', factionId: 'red'),
          _ctx(),
          Random(11))!;
      final back = ClanOffer.tryParse(offer.toJson());
      expect(back, offer);
      expect(ClanOffer.tryParse(null), isNull);
      expect(ClanOffer.tryParse({'suitors': []}), isNull);
    });

    test('an old save\'s points and picks become offers', () {
      expect(migratedOffers(skillPoints: 2, perkPicks: 1, signPicks: 1),
          hasLength(4));
      expect(migratedOffers().isEmpty, isTrue);
      expect(
          migratedOffers(skillPoints: 1).single.source, OfferSource.migrated);
    });
  });
}
