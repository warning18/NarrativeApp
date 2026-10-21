// Camp buildings that bend the rolls (docs/proposals/camp-roll-buildings.md):
// the three houses, Reroll (up to 4, full when built, +1 a level, the whole
// set again, a stat pick's tier kept), Banish (up to 3, full when built, +1
// a level, 5/10/15 draws for 1/2/3 charges, the card replaced at once, the
// ban counting down on fresh draws of its own kind only) and Raise (1 when
// built, +1 every 15 fresh draws, up to 5, once a card, never past Heroic,
// never a risky card), and the save.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/camp_rolls.dart';
import 'package:narrative_data_app/data/camp_works.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/materials.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/perks.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/data/sim_rolls.dart';
import 'package:narrative_data_app/data/training.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

import 'player_session_provider_test.dart' show baseSession;

Map<String, dynamic> _json(String name) =>
    json.decode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

final Map<String, dynamic> _houses = _json('houses');
final Map<String, TrainingPath> _paths =
    trainingPathsFrom(_json('training_paths'));

// --- A small world for the offers --------------------------------------------

Map<String, dynamic> _clan(List<String> objects, {Map? sworn}) => {
      'kind': 'clan',
      'name': 'N',
      'sponsors': const [],
      'objects': [
        for (final o in objects) {'itemId': o, 'minTier': 'resented'},
      ],
      if (sworn != null) 'sworn': sworn,
      'greetings': ['Hail.'],
    };

final ClanData _data = ClanData.fromTables(factions: {
  'gold': _clan(['blade', 'axe']),
  'blue': _clan(['dagger']),
  'grey': _clan(['club']),
  'green': _clan(['mace']),
});

const Map<String, dynamic> _items = {
  'blade': {'itemType': 'Weapon', 'rarity': 'Common'},
  'axe': {'itemType': 'Weapon', 'rarity': 'Common'},
  'dagger': {'itemType': 'Weapon', 'rarity': 'Common'},
  'club': {'itemType': 'Weapon', 'rarity': 'Common'},
  'mace': {'itemType': 'Weapon', 'rarity': 'Common'},
};

OfferContext _ctx({Set<String> bans = const {}}) => OfferContext(
      data: _data,
      politics: PoliticsState.empty,
      items: _items,
      raceId: 'human',
      professionId: 'warrior',
      // No perk left, no Wayfarer object: the factions only.
      perkRanks: {for (final p in Perk.values) p.name: 99},
      bannedGifts: bans,
    );

const OfferTicket _level = OfferTicket(source: OfferSource.level);

// --- The shipped data, for the session ---------------------------------------

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

PlayerSession _warrior({
  List<String> built = const [],
  int statPoints = 0,
  Map<String, dynamic> extra = const {},
}) =>
    PlayerSession.fromJson({
      ...baseSession(statPoints: statPoints, builtHouseIds: built).toJson(),
      'raceId': 'human',
      'professionId': 'warrior',
      'unlockedSkillIds': ['warrior_shield_bash', 'human_resolve'],
      ...extra,
    });

const _all = ['bone_casters_hut', 'warding_cairn', 'star_well'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the houses', () {
    test('three records with their power, category, cost and tier', () {
      final want = {
        'bone_casters_hut': (
          RollPower.reroll,
          WorkCategory.workshops,
          240,
          1,
          'timber'
        ),
        'warding_cairn': (
          RollPower.banish,
          WorkCategory.workshops,
          300,
          2,
          'slag_glass'
        ),
        'star_well': (
          RollPower.raise,
          WorkCategory.greatWorks,
          1200,
          3,
          'tear_glass'
        ),
      };
      for (final MapEntry(key: id, value: w) in want.entries) {
        final house = _houses[id] as Map<String, dynamic>;
        expect(rollPowerOf(house), w.$1, reason: id);
        expect(rollPowerHouses[id], w.$1, reason: id);
        expect(workCategoryOf(id, house), w.$2, reason: id);
        expect(house['buildCost'], w.$3, reason: id);
        expect(workTierOf(house), w.$4, reason: id);
        expect(materialCountsOf(house, 'materialCost').keys,
            contains('material_${w.$5}'),
            reason: id);
        expect(house['requiredFlags'], isEmpty, reason: id);
        expect(house['partyCapacityBonus'], 0, reason: id);
        for (final field in [
          'houseName',
          'houseName_fr',
          'description',
          'description_fr'
        ]) {
          expect((house[field] as String?) ?? '', isNotEmpty,
              reason: '$id $field');
        }
      }
      // Only these three carry a power; the Well shows from chapter 5.
      expect(rollPowersBuilt(_houses.keys, _houses), RollPower.values.toSet());
      expect({
        for (final e in _houses.entries)
          if (rollPowerOf(e.value as Map<String, dynamic>) != null) e.key
      }, rollPowerHouses.keys.toSet());
      expect(tierFirstChapter(workTierOf(_houses['star_well'])), 5);
      // A house without `category` reads the same: the Well a great work.
      expect(
          workCategoryOf('x', {'rollPower': 'banish'}), WorkCategory.workshops);
      expect(
          workCategoryOf('x', {'rollPower': 'raise'}), WorkCategory.greatWorks);
    });
  });

  group('charges and bans', () {
    test('what a house gives when built, and the banish costs', () {
      expect(chargesWhenBuilt(RollPower.reroll), 4);
      expect(chargesWhenBuilt(RollPower.banish), 3);
      expect(chargesWhenBuilt(RollPower.raise), 1);
      expect([for (final d in banishLengths) banishCostOf(d)], [1, 2, 3]);
      expect(banishCostOf(7), 0);
    });

    test('a ban counts down on fresh draws of its own kind only', () {
      var bans = [
        const RollBan(on: RollBanOn.pick, id: 'p', left: 2),
        const RollBan(on: RollBanOn.offer, id: 'skill:s', left: 1),
      ];
      var next = afterFreshDraw(
          on: RollBanOn.pick,
          bans: bans,
          raiseBuilt: false,
          raise: 0,
          raiseProgress: 0);
      expect(next.bans, [
        const RollBan(on: RollBanOn.pick, id: 'p', left: 1),
        bans[1],
      ]);
      bans = next.bans;
      next = afterFreshDraw(
          on: RollBanOn.offer,
          bans: bans,
          raiseBuilt: false,
          raise: 0,
          raiseProgress: 0);
      expect(next.bans, [const RollBan(on: RollBanOn.pick, id: 'p', left: 1)]);
      // A ban on the same thing keeps the longer.
      expect(
          withRollBan(
              next.bans, const RollBan(on: RollBanOn.pick, id: 'p', left: 10)),
          [const RollBan(on: RollBanOn.pick, id: 'p', left: 10)]);
    });

    test('Raise: +1 every 15 fresh draws, never above 5', () {
      var raise = 1;
      var progress = 0;
      for (var i = 0; i < 15 * 10; i++) {
        final next = afterFreshDraw(
            on: i.isEven ? RollBanOn.pick : RollBanOn.offer,
            bans: const [],
            raiseBuilt: true,
            raise: raise,
            raiseProgress: progress);
        raise = next.raise;
        progress = next.raiseProgress;
        if (i == 13) expect(raise, 1);
        if (i == 14) expect(raise, 2);
      }
      expect(raise, raiseMaxCharges);
      // Without the Well, nothing moves.
      expect(
          afterFreshDraw(
                  on: RollBanOn.pick,
                  bans: const [],
                  raiseBuilt: false,
                  raise: 0,
                  raiseProgress: 0)
              .raise,
          0);
    });
  });

  group('stat picks', () {
    test('a kept tier and the warded paths shape the draw', () {
      for (var seed = 0; seed < 40; seed++) {
        final offer = drawStatPick(
            paths: _paths,
            random: Random(seed),
            professionId: 'warrior',
            tier: SignRarity.epic,
            bannedPaths: {_paths.keys.first, _paths.keys.elementAt(1)});
        expect(offer, hasLength(3));
        expect(offer.every((o) => o.tier == SignRarity.epic), isTrue);
        expect(
            offer.map((o) => o.pathId),
            isNot(anyOf(contains(_paths.keys.first),
                contains(_paths.keys.elementAt(1)))));
      }
      // Too many warded to draw three: the bans are ignored.
      final all = _paths.keys.toSet();
      expect(
          drawStatPick(
              paths: _paths,
              random: Random(1),
              professionId: 'warrior',
              bannedPaths: all),
          hasLength(3));
    });

    test('a banished card is replaced at once, same tier, a new path', () {
      final offer = drawStatPick(
          paths: _paths,
          random: Random(5),
          professionId: 'warrior',
          tier: SignRarity.rare);
      final banned = {offer[1].pathId};
      final card = replaceStatPickOffer(
          offer: offer,
          index: 1,
          paths: _paths,
          random: Random(6),
          bannedPaths: banned)!;
      expect(card.tier, SignRarity.rare);
      expect(card.pathId, isNot(anyOf(offer.map((o) => o.pathId).toList())));
      expect(offer.map((o) => o.stat).toList()..removeAt(1),
          isNot(contains(card.stat)));
    });

    test('Raise: one tier up, gains rebuilt, once, never past Heroic', () {
      final path = _paths.values.firstWhere((p) => p.gains.length > 1);
      final stat = path.gains.keys.first;
      for (final (from, points) in [
        (SignRarity.common, 2),
        (SignRarity.rare, 3),
        (SignRarity.epic, 4),
      ]) {
        final card = StatPickOffer(
            pathId: path.id, gains: statPickGains(stat, from), tier: from);
        final raised = raisedStatPickOffer(card, _paths, Random(3))!;
        expect(raised.tier.index, from.index + 1);
        expect(raised.points, points);
        expect(raised.stat, stat);
        expect(raised.raised, isTrue);
        expect(raisedStatPickOffer(raised, _paths, Random(3)), isNull);
      }
      expect(
          raisedStatPickOffer(
              StatPickOffer(
                  pathId: path.id,
                  gains: statPickGains(stat, SignRarity.heroic),
                  tier: SignRarity.heroic),
              _paths,
              Random(3)),
          isNull);
      // The flag is saved, and left out when false.
      final raised = StatPickOffer(
          pathId: path.id,
          gains: {stat: 2},
          tier: SignRarity.rare,
          raised: true);
      expect(StatPickOffer.fromJson(raised.toJson()), raised);
      expect(const StatPickOffer(pathId: 'p', gains: {'luck': 1}).toJson(),
          isNot(contains('raised')));
    });
  });

  group('offers', () {
    test('a warded gift is never drawn while the clan has another', () {
      final c = _ctx(bans: {'object:blade'});
      for (var seed = 0; seed < 40; seed++) {
        final s = drawSuitor('gold', c, Random(seed))!;
        expect(s.gift.id, 'axe');
        final offer = drawOffer(_level, c, Random(seed))!;
        expect(offer.suitors.map((s) => s.gift.id), isNot(contains('blade')));
      }
      // Nothing else to give: the ban is ignored for that clan.
      final only = _ctx(bans: {'object:dagger'});
      expect(drawSuitor('blue', only, Random(1))!.gift.id, 'dagger');
      expect(giftsLeftAfterBans('blue', only), isFalse);
      expect(eligibleSuitors(only), contains('blue'));
    });

    test('a banished card: the same clan with another gift, else another', () {
      final offer = ClanOffer(ticket: _level, suitors: [
        const Suitor(
            factionId: 'gold',
            gift: OfferGift(kind: GiftKind.object, id: 'blade'),
            greetingIndex: 2),
        const Suitor(
            factionId: 'blue',
            gift: OfferGift(kind: GiftKind.object, id: 'dagger')),
      ]);
      final same = replacementSuitor(
          offer, 'gold', _ctx(bans: {'object:blade'}), Random(1))!;
      expect(same.factionId, 'gold');
      expect(same.gift.id, 'axe');
      expect(same.greetingIndex, 2);
      final other = replacementSuitor(
          offer, 'blue', _ctx(bans: {'object:dagger'}), Random(1))!;
      expect(other.factionId, isIn(['grey', 'green']));
    });

    test('never the Sworn boon nor the ticket\'s own faction', () {
      const quest = OfferTicket(source: OfferSource.quest, factionId: 'gold');
      const gold = Suitor(
          factionId: 'gold',
          gift: OfferGift(kind: GiftKind.object, id: 'blade'));
      const sworn = Suitor(
          factionId: 'blue',
          gift: OfferGift(
              kind: GiftKind.sworn, id: 'blue', rarity: SignRarity.heroic));
      final offer = ClanOffer(ticket: quest, suitors: const [gold, sworn]);
      expect(suitorBanishable(gold, offer), isFalse);
      expect(suitorBanishable(sworn, offer), isFalse);
      expect(
          suitorBanishable(
              gold, const ClanOffer(ticket: _level, suitors: [gold])),
          isTrue);
    });

    test('Raise: a sign one step up; never risky, raised, Heroic or perks', () {
      final signs = _tables.signs;
      final sign = signs.values.firstWhere((s) => !s.isDuo);
      final c = OfferContext(
          data: _data, politics: PoliticsState.empty, signs: signs);
      final card = Suitor(
          factionId: 'blue',
          gift: OfferGift(
              kind: GiftKind.sign, id: sign.id, rarity: SignRarity.rare));
      final raised = raisedSuitor(card, c, Random(1))!;
      expect(raised.gift.id, sign.id);
      expect(raised.gift.rarity, SignRarity.epic);
      expect(raised.raised, isTrue);
      expect(raisedSuitor(raised, c, Random(1)), isNull);
      expect(raisedSuitor(card.asRisky(10), c, Random(1)), isNull);
      expect(
          raisedSuitor(
              Suitor(
                  factionId: 'blue',
                  gift: OfferGift(
                      kind: GiftKind.sign,
                      id: sign.id,
                      rarity: SignRarity.heroic)),
              c,
              Random(1)),
          isNull);
      expect(
          suitorRaisable(const Suitor(
              factionId: wayfarerId,
              gift: OfferGift(kind: GiftKind.perk, id: 'vigor'))),
          isFalse);
      // Saved, and read back.
      expect(Suitor.tryParse(raised.toJson()), raised);
      expect(card.toJson(), isNot(contains('raised')));
    });

    test('Raise on another gift: the clan\'s better draw, one rarity up', () {
      const card = Suitor(
          factionId: 'gold',
          gift: OfferGift(kind: GiftKind.object, id: 'blade'));
      final raised = raisedSuitor(card, _ctx(), Random(1))!;
      expect(raised.factionId, 'gold');
      expect(raised.gift.kind, GiftKind.object);
      expect(raised.gift.rarity, SignRarity.rare);
      expect(raised.raised, isTrue);
      // The same seed draws the same card (the preview never lies).
      expect(raisedSuitor(card, _ctx(), Random(1)), raised);
    });

    test('Raise: a sign is capped by its clan\'s power', () {
      final data = _tables.data;
      final minor = [
        for (final f in data.factions.values)
          if (hasPower(f.id, data) &&
              maxSignRarityFor(
                      powerTierFor(powerOf(PoliticsState.empty, f.id, data))) ==
                  SignRarity.epic)
            f.id,
      ];
      if (minor.isEmpty) return;
      final sign = _tables.signs.values.firstWhere((s) => !s.isDuo);
      final c = OfferContext(
          data: data, politics: PoliticsState.empty, signs: _tables.signs);
      expect(
          raisedSuitor(
              Suitor(
                  factionId: minor.first,
                  gift: OfferGift(
                      kind: GiftKind.sign,
                      id: sign.id,
                      rarity: SignRarity.epic)),
              c,
              Random(1)),
          isNull);
    });
  });

  group('the session', () {
    test('building fills the charges; levels refill Reroll and Banish',
        () async {
      final n = await _notifierWith(
          _warrior().copyWith(gold: 5000, flags: const ['camp_founded']));
      for (final id in _all) {
        await n.buildHouse(id, 10, rollPower: _houses[id]['rollPower']);
      }
      expect(n.state.rerollCharges, 4);
      expect(n.state.banishCharges, 3);
      expect(n.state.raiseCharges, 1);
      expect(n.campRolls(_houses).reroll, 4);
      await n.loadSession(n.state.copyWith(rerollCharges: 1, banishCharges: 0));
      // Two levels: +2 each, Reroll capped at 4 only past it.
      await n.completeQuest('q', rewardGold: 0, rewardXP: 300);
      expect(n.state.level, greaterThanOrEqualTo(3));
      expect(n.state.rerollCharges, min(4, 1 + n.state.level - 1));
      expect(n.state.banishCharges, min(3, n.state.level - 1));
      expect(n.state.raiseCharges, 1);
      // Without the houses, nothing comes.
      final bare = await _notifierWith(_warrior());
      await bare.completeQuest('q', rewardGold: 0, rewardXP: 300);
      expect(bare.state.rerollCharges, 0);
      expect(campRollsOf(bare.state).any, isFalse);
    });

    test('Reroll on a stat pick: one charge, the tier kept, saved', () async {
      final n = await _notifierWith(_warrior(
          built: _all,
          statPoints: 2,
          extra: {'rerollCharges': 2, 'raiseCharges': 0}));
      final first = await n.ensureStatPick(_paths, random: Random(4));
      final again = await n.rerollStatPick(_paths, random: Random(99));
      expect(n.state.rerollCharges, 1);
      expect(n.state.rollNonce, 1);
      expect(again.every((o) => o.tier == first.first.tier), isTrue);
      expect(n.state.statPickOffer, again);
      // Reopening never redraws.
      expect(await n.ensureStatPick(_paths), again);
      await n.rerollStatPick(_paths, random: Random(98));
      final spent = n.state.statPickOffer;
      expect(await n.rerollStatPick(_paths, random: Random(97)), spent);
      expect(n.state.rerollCharges, 0);
      // The seed reads the nonce: the default draw differs.
      expect(PlayerSession.fromJson(n.state.toJson()).rollNonce, 2);
    });

    test('Banish on a stat pick: costs, replacement, count-down', () async {
      final n = await _notifierWith(
          _warrior(built: _all, statPoints: 3, extra: {'banishCharges': 3}));
      final offer = await n.ensureStatPick(_paths, random: Random(4));
      // Not enough charges for 15 draws after a 10.
      final next =
          await n.banishStatPickOffer(0, 10, _paths, random: Random(1));
      expect(n.state.banishCharges, 1);
      expect(next[0].pathId, isNot(offer[0].pathId));
      expect(next[0].tier, offer[0].tier);
      expect(n.state.rollBans,
          [RollBan(on: RollBanOn.pick, id: offer[0].pathId, left: 10)]);
      expect(await n.banishStatPickOffer(1, 15, _paths), next);
      expect(await n.banishStatPickOffer(1, 7, _paths), next);
      // A replacement is no fresh draw; a new pick is.
      expect(n.state.rollBans.single.left, 10);
      await n.takeStatPick(0);
      final fresh = await n.ensureStatPick(_paths);
      expect(n.state.rollBans.single.left, 9);
      expect(fresh.map((o) => o.pathId), isNot(contains(offer[0].pathId)));
      // An offer's draw leaves a pick's ban alone.
      await n.loadSession(n.state.copyWith(pendingOffers: const [
        _level
      ], flags: const [], rollBans: [
        ...n.state.rollBans,
        const RollBan(on: RollBanOn.offer, id: 'skill:x', left: 2),
      ]));
      await n.ensureOffer(_tables, random: Random(1));
      expect(n.state.rollBans, [
        RollBan(on: RollBanOn.pick, id: offer[0].pathId, left: 9),
        const RollBan(on: RollBanOn.offer, id: 'skill:x', left: 1),
      ]);
    });

    test('Raise on a stat pick: once per card; the Well counts draws',
        () async {
      final n = await _notifierWith(
          _warrior(built: _all, statPoints: 20, extra: {'raiseCharges': 2}));
      final offer = await n.ensureStatPick(_paths, random: Random(4));
      expect(n.state.raiseProgress, 1);
      if (offer[0].tier == SignRarity.heroic) return;
      expect(n.canRaiseStatPickOffer(0), isTrue);
      final raised = await n.raiseStatPickOffer(0, _paths, random: Random(1));
      expect(raised[0].tier.index, offer[0].tier.index + 1);
      expect(raised[1], offer[1]);
      expect(n.state.raiseCharges, 1);
      expect(n.canRaiseStatPickOffer(0), isFalse);
      expect(await n.raiseStatPickOffer(0, _paths), raised);
      expect(n.state.raiseCharges, 1);
      // 14 more fresh picks: a charge.
      for (var i = 0; i < 14; i++) {
        await n.takeStatPick(0);
        await n.ensureStatPick(_paths);
      }
      expect(n.state.raiseCharges, 2);
      expect(n.state.raiseProgress, 0);
    });

    test('the offer: reroll, banish and raise spend and persist', () async {
      final n = await _notifierWith(_warrior(built: _all, extra: {
        'rerollCharges': 1,
        'banishCharges': 3,
        'raiseCharges': 5,
        'pendingOffers': [_level.toJson(), _level.toJson()],
      }));
      final offer = (await n.ensureOffer(_tables, random: Random(2)))!;
      final rerolled = await n.rerollOffer(_tables, random: Random(3));
      expect(n.state.rerollCharges, 0);
      expect(n.state.clanOffer, rerolled);
      expect(rerolled!.ticket, offer.ticket);
      expect(await n.rerollOffer(_tables, random: Random(4)), rerolled);
      // Banish a card that may be.
      final target =
          rerolled.suitors.firstWhere((s) => suitorBanishable(s, rerolled));
      final banished = (await n.banishSuitor(target.factionId, 5, _tables,
          random: Random(5)))!;
      expect(n.state.banishCharges, 2);
      expect(n.state.rollBans.single.id, giftBanId(target.gift));
      expect(banished.suitors, hasLength(rerolled.suitors.length));
      expect(
          banished.suitors.any(
              (s) => s.factionId == target.factionId && s.gift == target.gift),
          isFalse);
      // Raise: the preview is what the raise gives.
      for (final s in banished.suitors) {
        final preview = n.raisePreview(s.factionId, _tables);
        if (preview == null) continue;
        expect(preview.gift.rarity.index, greaterThan(s.gift.rarity.index));
        final after = (await n.raiseSuitor(s.factionId, _tables))!;
        expect(after.suitorOf(s.factionId), preview);
        expect(n.state.raiseCharges, 4);
        expect(n.raisePreview(s.factionId, _tables), isNull);
        break;
      }
      // Saved.
      final back = PlayerSession.fromJson(
          json.decode(json.encode(n.state.toJson())) as Map<String, dynamic>);
      expect(back.clanOffer, n.state.clanOffer);
      expect(back.rollBans, n.state.rollBans);
      expect(back.banishCharges, 2);
      expect(back.rollNonce, n.state.rollNonce);
    });

    test('an old save reads every field at its default', () {
      final old = baseSession().toJson()
        ..removeWhere((k, _) => k.startsWith('roll') || k.contains('Charges'));
      final s = PlayerSession.fromJson(old);
      expect(s.rerollCharges, 0);
      expect(s.banishCharges, 0);
      expect(s.raiseCharges, 0);
      expect(s.raiseProgress, 0);
      expect(s.rollBans, isEmpty);
      expect(s.rollNonce, 0);
      // And the defaults are left out of the save.
      for (final key in [
        'rerollCharges',
        'banishCharges',
        'raiseCharges',
        'raiseProgress',
        'rollBans',
        'rollNonce'
      ]) {
        expect(baseSession().toJson(), isNot(contains(key)));
      }
      final full = baseSession().copyWith(
          rerollCharges: 2,
          banishCharges: 1,
          raiseCharges: 3,
          raiseProgress: 7,
          rollBans: const [RollBan(on: RollBanOn.pick, id: 'p', left: 4)],
          rollNonce: 5);
      final back = PlayerSession.fromJson(
          json.decode(json.encode(full.toJson())) as Map<String, dynamic>);
      expect([
        back.rerollCharges,
        back.banishCharges,
        back.raiseCharges,
        back.raiseProgress,
        back.rollNonce
      ], [
        2,
        1,
        3,
        7,
        5
      ]);
      expect(back.rollBans, full.rollBans);
    });
  });

  group('the simulator\'s policy', () {
    test('rerolls a pick the build has no use for, raises its main stat', () {
      final rolls = SimRolls(Random(1))
        ..build(RollPower.reroll)
        ..build(RollPower.raise);
      final useless = drawStatPick(
          paths: _paths, random: Random(1), tier: SignRarity.common);
      final wanted = {for (final o in useless) o.stat};
      final main = _paths.values
          .expand((p) => p.gains.keys)
          .firstWhere((s) => !wanted.contains(s));
      final cards = rolls.workStatPick(useless,
          wanted: {main},
          mainStat: main,
          paths: _paths,
          choose: (o) => o.indexWhere((c) => c.stat == main),
          redraw: (tier) =>
              drawStatPick(paths: _paths, random: rolls.random, tier: tier));
      expect(rolls.used['rerolls'], greaterThan(0));
      expect(
          cards.every((c) => c.tier.index >= SignRarity.common.index), isTrue);
      if (cards.any((c) => c.stat == main)) {
        expect(rolls.used['raises'], 1);
        expect(cards.firstWhere((c) => c.stat == main).raised, isTrue);
      } else {
        expect(rolls.reroll, 0);
      }
    });
  });
}
