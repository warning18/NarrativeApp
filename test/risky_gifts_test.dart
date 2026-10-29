// Risky gifts (docs/proposals/risky-gifts.md): who may offer one (uneasy
// or of the opposite alignment, never Hostile, Hunted or the nemesis), the
// Parley Tent that opens them, the draw (30%, one card at most, never the
// Wayfarer, the ticket's own faction or the home seat, one rarity better or
// not at all), the d20 + Luck bands, the penalties and their fallbacks
// ("nothing" never happens), the curse's two levels, standing rising
// whatever the die says, the odds and result lines, and the save.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/camp_works.dart'
    show WorkCategory, workCategoryOf;
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/risky_gifts.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/data/stat_ledger.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

import 'player_session_provider_test.dart' show baseSession;

Map<String, dynamic> _json(String name) =>
    json.decode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

// --- A small world for the draw ---------------------------------------------

Map<String, dynamic> _clan({
  int lean = 0,
  String riskStat = '',
  List<String> sponsors = const [],
  List<Map<String, dynamic>> objects = const [],
  Map<String, dynamic>? sworn,
}) =>
    {
      'kind': 'clan',
      'name': 'N',
      'lean': lean,
      if (riskStat.isNotEmpty) 'riskStat': riskStat,
      'sponsors': sponsors,
      'objects': objects,
      if (sworn != null) 'sworn': sworn,
      'greetings': ['Hail.'],
    };

/// Red sponsors the warrior's branch (the home seat) and has a Sworn boon;
/// gold and blue bring a Common object each; grey has no curse stat.
final ClanData _data = ClanData.fromTables(
  factions: {
    'red': _clan(
      lean: 1,
      riskStat: 'charisma',
      sponsors: ['warrior_a'],
      sworn: {
        'name': 'Writ',
        'effects': [
          {'kind': 'writFace', 'value': 1},
        ],
      },
    ),
    'gold': _clan(lean: -1, riskStat: 'strength', objects: [
      {'itemId': 'blade', 'minTier': 'resented'},
    ]),
    'blue': _clan(riskStat: 'wisdom', objects: [
      {'itemId': 'dagger', 'minTier': 'resented'},
    ]),
    'grey': _clan(objects: [
      {'itemId': 'club', 'minTier': 'resented'},
    ]),
    'choir': {'kind': 'otherworld', 'name': 'C', 'minAlignment': 10},
  },
);

const Map<String, dynamic> _trees = {
  'warrior_a': {
    'professionId': 'warrior',
    'skillIds': ['s1', 's2'],
  },
};

const Map<String, dynamic> _skills = {
  's1': {'rarity': 'common'},
  's2': {'rarity': 'uncommon'},
};

const Map<String, dynamic> _items = {
  'blade': {'itemType': 'Weapon', 'rarity': 'Common'},
  'dagger': {'itemType': 'Weapon', 'rarity': 'Common'},
  'club': {'itemType': 'Weapon', 'rarity': 'Common'},
  'potion_minor': {'itemType': 'Potion', 'rarity': 'Common'},
};

PoliticsState _at(Map<String, num> values) {
  var state = PoliticsState.empty;
  values.forEach((id, v) {
    state = setStandingValue(state, id, v, 'edit', data: _data).state;
  });
  return state;
}

OfferContext _ctx({
  PoliticsState politics = PoliticsState.empty,
  int alignment = 0,
  bool risky = true,
  String profession = 'warrior',
}) =>
    OfferContext(
      data: _data,
      politics: politics,
      skills: _skills,
      skillTrees: _trees,
      items: _items,
      raceId: 'human',
      professionId: profession,
      alignment: alignment,
      riskyGifts: risky,
    );

const OfferTicket _level = OfferTicket(source: OfferSource.level);

// --- The shipped data, for the session --------------------------------------

final OfferTables _tables = OfferTables(
  data: ClanData.fromTables(
    factions: _json('factions'),
    subclans: _json('subclans'),
    relations: _json('relations'),
    titles: _json('titles'),
    intrigues: _json('intrigues'),
  ),
  signs: parseSigns(_json('signs')),
  skills: _json('skills'),
  skillTrees: _json('skill_trees'),
  items: _json('items'),
  spells: parseSpells(_json('spells')),
);

Future<PlayerSessionNotifier> _notifierWith(PlayerSession session) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(session);
  return notifier;
}

PlayerSession _warrior({int gold = 500, int? health}) =>
    PlayerSession.fromJson({
      ...baseSession(gold: gold, currentHealth: health).toJson(),
      'raceId': 'human',
      'professionId': 'warrior',
      'unlockedSkillIds': ['warrior_shield_bash', 'human_resolve'],
    });

/// A risky Dominion card (a sign) with [roll], alone on the table.
PlayerSession _offeredRisky(PlayerSession session, int roll) {
  final suitor = const Suitor(
    factionId: 'dominion',
    gift: OfferGift(
        kind: GiftKind.title, id: 'no_such_title', rarity: SignRarity.epic),
  ).asRisky(roll);
  return session.copyWith(
    pendingOffers: const [_level],
    clanOffer: ClanOffer(ticket: _level, suitors: [suitor]),
  );
}

/// The first roll that lands in [band] at [luck].
int _rollFor(RiskyOutcome band, int luck) => [for (var r = 1; r <= 20; r++) r]
    .firstWhere((r) => riskyBandFor(r, luck) == band);

Future<void> _levelUp(PlayerSessionNotifier n) => n.applyCombatResult(
    hpAfter: n.state.currentHealth,
    xpGain: n.state.level * 100 - n.state.currentXP);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('who may offer one', () {
    final gold = _data.faction('gold')!;
    final red = _data.faction('red')!;
    final grey = _data.faction('grey')!;

    test('the uneasy tiers do; Unknown, Hostile and Hunted do not', () {
      for (final tier in [
        StandingTier.wary,
        StandingTier.unfriendly,
        StandingTier.resented,
      ]) {
        expect(riskyEligible(gold, tier: tier, alignment: 0), isTrue,
            reason: '$tier');
      }
      for (final tier in [
        StandingTier.unknown,
        StandingTier.known,
        StandingTier.hostile,
        StandingTier.hunted,
      ]) {
        expect(riskyEligible(gold, tier: tier, alignment: 0), isFalse,
            reason: '$tier');
      }
    });

    test('the nemesis never does, even uneasy or opposite', () {
      expect(
          riskyEligible(gold,
              tier: StandingTier.resented, alignment: 50, nemesis: 'gold'),
          isFalse);
    });

    test('the opposite alignment does; a Neutral character never', () {
      // Red leans good: an Evil character, even a friend.
      expect(riskyEligible(red, tier: StandingTier.friend, alignment: -20),
          isTrue);
      expect(riskyEligible(red, tier: StandingTier.friend, alignment: 19),
          isFalse);
      expect(
          riskyEligible(red, tier: StandingTier.known, alignment: 40), isFalse);
      // Gold leans evil: a Good character.
      expect(
          riskyEligible(gold, tier: StandingTier.known, alignment: 20), isTrue);
      expect(riskyEligible(gold, tier: StandingTier.known, alignment: -40),
          isFalse);
      // Hostile stays out, opposite or not.
      expect(riskyEligible(red, tier: StandingTier.hostile, alignment: -50),
          isFalse);
    });

    test('a faction with no curse stat never does', () {
      expect(
          riskyEligible(grey, tier: StandingTier.wary, alignment: 0), isFalse);
    });

    test(
        'the shipped data: the eleven clans and tribes have a stat and a '
        'line; the Choir and the Pit none', () {
      final factions = _tables.data.factions;
      final risky = {
        for (final f in factions.values)
          if (f.riskStat.isNotEmpty) f.id,
      };
      expect(risky, {
        'dominion', 'vigil', 'compact', 'mire', 'crows', 'penitents', //
        'giants', 'oni', 'tidekin', 'kindly', 'open_hand',
      });
      for (final id in risky) {
        final f = factions[id]!;
        expect(f.riskyOfferFor(AppLanguage.en), isNotEmpty, reason: id);
        expect(f.riskyOfferFor(AppLanguage.fr), isNotEmpty, reason: id);
        expect(riskyEligible(f, tier: StandingTier.wary, alignment: 0), isTrue,
            reason: id);
      }
      for (final id in ['choir', 'pit']) {
        expect(
            riskyEligible(factions[id]!, tier: StandingTier.wary, alignment: 0),
            isFalse);
      }
    });
  });

  group('the Parley Tent', () {
    test('is a workshop at 250 gold, 2 timber and 2 cut stone', () {
      final tent = _json('houses')[parleyTentHouseId] as Map<String, dynamic>;
      expect(tent['buildCost'], 250);
      expect(tent['materialCost'],
          {'material_timber': 2, 'material_cut_stone': 2});
      expect(tent['requiredFlags'], isEmpty);
      expect(workCategoryOf(parleyTentHouseId, tent), WorkCategory.workshops);
      expect(tent['houseName_fr'], isNotEmpty);
      expect(tent['description_fr'], isNotEmpty);
    });

    test('opens risky gifts once built, in the session\'s draw too', () async {
      expect(riskyGiftsOpen(const []), isFalse);
      expect(riskyGiftsOpen(const [parleyTentHouseId]), isTrue);
      final closed = await _notifierWith(_warrior());
      expect(closed.offerContextFor(_tables).riskyGifts, isFalse);
      final open = await _notifierWith(
          _warrior().copyWith(builtHouseIds: const [parleyTentHouseId]));
      expect(open.offerContextFor(_tables).riskyGifts, isTrue);
    });
  });

  group('the draw', () {
    final uneasy = _at({'red': -8, 'gold': -8, 'blue': -15, 'grey': -8});

    test('none without the tent', () {
      final random = Random(1);
      for (var i = 0; i < 400; i++) {
        final offer =
            drawOffer(_level, _ctx(politics: uneasy, risky: false), random)!;
        expect(offer.suitors.where((s) => s.risky), isEmpty);
      }
    });

    test(
        'about 30% of the offers, one card at most, never the Wayfarer or '
        'the home seat, one rarity better', () {
      final random = Random(2);
      var risky = 0;
      const n = 1000;
      for (var i = 0; i < n; i++) {
        final offer = drawOffer(_level, _ctx(politics: uneasy), random)!;
        final cards = offer.suitors.where((s) => s.risky).toList();
        expect(cards.length, lessThanOrEqualTo(1));
        if (cards.isEmpty) continue;
        risky++;
        final card = cards.single;
        expect(card.isWayfarer, isFalse);
        // Red is the home seat (it sponsors the warrior's branch).
        expect(card.factionId, isNot('red'));
        expect(card.factionId, isNot('grey'));
        expect(card.riskRoll, inInclusiveRange(1, 20));
        // A Common object made Rare.
        expect(card.gift.rarity, SignRarity.rare);
      }
      // Gold or blue is nearly always there: close to the 30%.
      expect(risky / n, inInclusiveRange(0.2, 0.33));
    });

    test('never the ticket\'s own faction', () {
      final random = Random(3);
      const quest = OfferTicket(source: OfferSource.quest, factionId: 'gold');
      for (var i = 0; i < 400; i++) {
        final offer = drawOffer(quest, _ctx(politics: uneasy), random)!;
        expect(offer.suitorOf('gold')!.risky, isFalse);
      }
    });

    test('never when the better draw is no rarer (the Sworn boon)', () {
      // Sworn to red, Evil: red is opposite; a rogue has no home seat.
      final sworn = _at({'red': 70});
      final random = Random(4);
      var redSeen = 0;
      for (var i = 0; i < 400; i++) {
        final offer = drawOffer(
            _level,
            _ctx(politics: sworn, alignment: -40, profession: 'rogue'),
            random)!;
        final red = offer.suitorOf('red');
        if (red == null) continue;
        redSeen++;
        expect(red.gift.kind, GiftKind.sworn);
        expect(red.risky, isFalse);
      }
      expect(redSeen, greaterThan(0));
    });

    test('seeded: the same seed draws the same risky card', () {
      ClanOffer draw() => drawOffer(_level, _ctx(politics: uneasy), Random(9))!;
      expect(draw(), draw());
    });
  });

  group('the roll', () {
    test('the bands and the odds at each Luck', () {
      expect([
        for (var r = 1; r <= 6; r++) riskyBandFor(r, 0)
      ], [
        RiskyOutcome.health,
        RiskyOutcome.health,
        RiskyOutcome.gold,
        RiskyOutcome.gold,
        RiskyOutcome.curse,
        RiskyOutcome.gift,
      ]);
      expect(riskyOddsFor(0), (gift: 75, price: 25));
      expect(riskyOddsFor(4), (gift: 75, price: 25));
      expect(riskyOddsFor(5), (gift: 80, price: 20));
      expect(riskyOddsFor(9), (gift: 80, price: 20));
      expect(riskyOddsFor(10), (gift: 85, price: 15));
      expect(riskyOddsFor(30), (gift: 85, price: 15));
    });

    test('a natural 1 is always the health penalty', () {
      for (final luck in [0, 5, 10, 40]) {
        expect(riskyBandFor(1, luck), RiskyOutcome.health);
      }
      expect(riskyBandFor(2, 10), RiskyOutcome.gold);
    });

    RiskyResult result(int roll,
            {int gold = 400, int health = 30, int max = 30}) =>
        riskyResultFor(
            roll: roll,
            luck: 0,
            gold: gold,
            chapter: 3,
            maxHealth: max,
            currentHealth: health,
            curseStat: 'charisma');

    test('each result', () {
      expect(result(20), const RiskyResult(RiskyOutcome.gift));
      // 40% of 30 max health.
      expect(result(1), const RiskyResult(RiskyOutcome.health, amount: 12));
      // 25% of the purse, at least 10 a chapter.
      expect(result(3), const RiskyResult(RiskyOutcome.gold, amount: 100));
      expect(result(3, gold: 40),
          const RiskyResult(RiskyOutcome.gold, amount: 30));
      expect(result(3, gold: 20),
          const RiskyResult(RiskyOutcome.gold, amount: 20));
      expect(
          result(5),
          const RiskyResult(RiskyOutcome.curse,
              amount: riskyCurseAmount, stat: 'charisma'));
      // Never below 1 health.
      expect(result(1, health: 5),
          const RiskyResult(RiskyOutcome.health, amount: 4));
    });

    test('the fallbacks: never nothing', () {
      // An empty purse: the health penalty.
      expect(result(3, gold: 0),
          const RiskyResult(RiskyOutcome.health, amount: 12));
      // At 1 health: the curse.
      expect(result(1, health: 1).outcome, RiskyOutcome.curse);
      // Both: the curse.
      expect(result(3, gold: 0, health: 1).outcome, RiskyOutcome.curse);
      for (var roll = 1; roll <= 20; roll++) {
        final r = result(roll, gold: 0, health: 1);
        expect(r.won || r.amount > 0, isTrue, reason: '$roll');
      }
    });

    test('the curse never falls on the damage stat or Constitution', () {
      final f = _data.faction('gold')!; // strength
      expect(riskyCurseStatFor(f, 'warrior'), 'luck');
      expect(riskyCurseStatFor(f, 'mage'), 'strength');
      expect(riskyCurseStatFor(_data.faction('blue'), 'mage'), 'wisdom');
      expect(riskyCurseStatFor(null, 'mage'), 'luck');
    });
  });

  group('what the player reads', () {
    final data = _tables.data;

    test('the odds line', () {
      expect(riskyOddsText(5, AppLanguage.en), 'Gift 80% · Price 20%');
      expect(riskyOddsText(0, AppLanguage.fr), 'Don 75 % · Prix 25 %');
    });

    test('the result lines', () {
      final vigil = data.faction('vigil');
      final dominion = data.faction('dominion');
      expect(
          riskyResultText(
              const RiskyResult(RiskyOutcome.gift), vigil, AppLanguage.en),
          'The die is kind. The Grey Vigil keeps its word.');
      expect(
          riskyResultText(
              const RiskyResult(RiskyOutcome.gift), vigil, AppLanguage.fr),
          'Le dé est clément. Parole tenue par la Veille Grise.');
      const curse =
          RiskyResult(RiskyOutcome.curse, amount: 2, stat: 'charisma');
      expect(riskyResultText(curse, dominion, AppLanguage.en),
          'The curse of the Lantern Dominion: −2 Charisma for two levels.');
      expect(
          riskyResultText(curse, dominion, AppLanguage.fr),
          'Malédiction du Dominion de la Lanterne : −2 Charisme pendant '
          'deux niveaux.');
      expect(
          riskyResultText(const RiskyResult(RiskyOutcome.gold, amount: 40),
              dominion, AppLanguage.en),
          'The price is paid in coin: −40 gold.');
      expect(
          riskyResultText(const RiskyResult(RiskyOutcome.health, amount: 9),
              dominion, AppLanguage.en),
          'The price is paid in blood: −9 health.');
    });
  });

  group('in the session', () {
    test('a won roll gives the gift; standing rises', () async {
      final n = await _notifierWith(_warrior());
      final luck = n.riskyLuck(_tables);
      final roll = _rollFor(RiskyOutcome.gift, luck);
      await n.loadSession(_offeredRisky(n.state, roll));
      final before = n.state.politics.standingOf('dominion', _tables.data);
      final gold = n.state.gold;
      final health = n.state.currentHealth;
      expect(await n.acceptSuitor('dominion', tables: _tables), isTrue);
      expect(n.state.politics.standingOf('dominion', _tables.data),
          greaterThan(before));
      expect(n.state.gold, gold);
      expect(n.state.currentHealth, health);
      expect(n.state.riskCurses, isEmpty);
      expect(n.state.clanOffer, isNull);
    });

    test('each price, and standing rises every time', () async {
      for (final band in [
        RiskyOutcome.health,
        RiskyOutcome.gold,
        RiskyOutcome.curse,
      ]) {
        final n = await _notifierWith(_warrior(gold: 400));
        final roll = _rollFor(band, n.riskyLuck(_tables));
        await n.loadSession(_offeredRisky(n.state, roll));
        final s = n.state;
        final before = s.politics.standingOf('dominion', _tables.data);
        final risk = n.riskyResultOf(s.clanOffer!.suitors.single, _tables)!;
        expect(risk.outcome, band);
        await n.acceptSuitor('dominion', tables: _tables);
        final after = n.state;
        expect(after.politics.standingOf('dominion', _tables.data),
            greaterThan(before),
            reason: '$band');
        switch (band) {
          case RiskyOutcome.health:
            expect(after.currentHealth, s.currentHealth - risk.amount);
            expect(risk.amount, (s.maxHealth * 0.4).round());
          case RiskyOutcome.gold:
            expect(after.gold, 300);
          case RiskyOutcome.curse:
            // The Dominion's stat, Charisma, for a warrior.
            expect(after.charisma, s.charisma - 2);
            expect(after.riskCurses.single.stat, 'charisma');
            expect(after.statSources[ledgerKey(ledgerCurse, 'dominion')],
                {'charisma': -2});
          case RiskyOutcome.gift:
            break;
        }
      }
    });

    test('the fallbacks: an empty purse costs health, 1 health the curse',
        () async {
      final broke = await _notifierWith(_warrior(gold: 0));
      await broke.loadSession(_offeredRisky(
          broke.state, _rollFor(RiskyOutcome.gold, broke.riskyLuck(_tables))));
      final health = broke.state.currentHealth;
      await broke.acceptSuitor('dominion', tables: _tables);
      expect(broke.state.currentHealth, lessThan(health));

      final faint = await _notifierWith(_warrior(gold: 0, health: 1));
      await faint.loadSession(_offeredRisky(faint.state, 1));
      await faint.acceptSuitor('dominion', tables: _tables);
      expect(faint.state.currentHealth, 1);
      expect(faint.state.riskCurses, hasLength(1));
    });

    test('the curse ends at the second level-up; a second restarts it',
        () async {
      final n = await _notifierWith(_warrior());
      final charisma = n.state.charisma;
      final curseRoll = _rollFor(RiskyOutcome.curse, n.riskyLuck(_tables));
      await n.loadSession(_offeredRisky(n.state, curseRoll));
      await n.acceptSuitor('dominion', tables: _tables);
      final level = n.state.level;
      expect(n.state.riskCurses.single.untilLevel, level + 2);
      await _levelUp(n);
      expect(n.state.charisma, charisma - 2);
      // A second curse from the Dominion: the count starts again, no stack.
      await n.loadSession(_offeredRisky(n.state, curseRoll));
      await n.acceptSuitor('dominion', tables: _tables);
      expect(n.state.charisma, charisma - 2);
      expect(n.state.riskCurses.single.untilLevel, level + 3);
      await _levelUp(n);
      expect(n.state.charisma, charisma - 2);
      await _levelUp(n);
      expect(n.state.charisma, charisma);
      expect(n.state.riskCurses, isEmpty);
      expect(
          n.state.statSources.containsKey(ledgerKey(ledgerCurse, 'dominion')),
          isFalse);
    });
  });

  group('the save', () {
    test('a risky card round-trips; an old card is a normal one', () {
      final card = const Suitor(
        factionId: 'gold',
        gift: OfferGift(kind: GiftKind.object, id: 'blade'),
      ).asRisky(7);
      expect(Suitor.tryParse(jsonDecode(jsonEncode(card.toJson()))), card);
      final old = Suitor.tryParse({
        'faction': 'gold',
        'gift': {'kind': 'object', 'id': 'blade'},
      })!;
      expect(old.risky, isFalse);
      expect(old.riskRoll, 0);
      // A roll out of range: a normal card.
      expect(
          Suitor.tryParse({...card.toJson(), 'riskRoll': 0})!.risky, isFalse);
    });

    test(
        'the curses and the risky card on the table round-trip; an old '
        'save has none', () {
      final s = _offeredRisky(_warrior(), 4).withCurse('dominion', 'luck', 2);
      final back = PlayerSession.fromJson(
          jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
      expect(back.riskCurses, s.riskCurses);
      expect(back.clanOffer, s.clanOffer);
      expect(back.clanOffer!.suitors.single.riskRoll, 4);
      expect(back.statSources, s.statSources);

      final json = _warrior().toJson();
      expect(json.containsKey('riskCurses'), isFalse);
      expect(PlayerSession.fromJson(json).riskCurses, isEmpty);
    });
  });
}
