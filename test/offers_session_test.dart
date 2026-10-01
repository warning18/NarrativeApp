// Offers (v1.194) in the session, with the shipped data: where offers come
// from (a level, a boss, a chapter's start once, a Tome of Mastery, a
// new character's starting points, the hook for quests), what an old save
// is owed, drawing and taking one (the gift applied, standing with its
// ripple, the voice a friend, the alignment), the titles standing earns,
// and what a death takes.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

import 'player_session_provider_test.dart' show baseSession;

Map<String, dynamic> _data(String name) =>
    json.decode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

final OfferTables _tables = OfferTables(
  data: ClanData.fromTables(
    factions: _data('factions'),
    subclans: _data('subclans'),
    relations: _data('relations'),
    titles: _data('titles'),
    intrigues: _data('intrigues'),
  ),
  signs: parseSigns(_data('signs')),
  skills: _data('skills'),
  skillTrees: _data('skill_trees'),
  items: _data('items'),
  spells: parseSpells(_data('spells')),
);

ClanData get _clans => _tables.data;

Future<PlayerSessionNotifier> _notifierWith(PlayerSession session) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(session);
  return notifier;
}

PlayerSession _warrior({int alignment = 0}) => PlayerSession.fromJson({
      ...baseSession().toJson(),
      'raceId': 'human',
      'professionId': 'warrior',
      'alignmentScore': alignment,
      'unlockedSkillIds': ['warrior_shield_bash', 'human_resolve'],
    });

/// [session] with [suitor] alone on the table for [ticket].
PlayerSession _offered(PlayerSession session, Suitor suitor,
        [OfferTicket ticket = const OfferTicket(source: OfferSource.level)]) =>
    session.copyWith(
      pendingOffers: [ticket],
      clanOffer: ClanOffer(ticket: ticket, suitors: [suitor]),
    );

List<OfferSource> _sources(PlayerSessionNotifier n) =>
    [for (final t in n.state.pendingOffers) t.source];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('where offers come from', () {
    test('each level reached brings one; stat points and health stay',
        () async {
      final notifier = await _notifierWith(_warrior());
      await notifier.applyCombatResult(hpAfter: 100, xpGain: 100 + 200);
      expect(notifier.state.level, 3);
      expect(_sources(notifier), [OfferSource.level, OfferSource.level]);
      expect(notifier.state.statPoints, 10);
      expect(notifier.state.maxHealth, 140);
    });

    test('a quest that levels brings them too; a boss and a tome one each',
        () async {
      final notifier =
          await _notifierWith(_warrior().copyWith(activeQuestIds: const ['q']));
      await notifier.completeQuest('q', rewardXP: 100);
      expect(_sources(notifier), [OfferSource.level]);
      await notifier.applyCombatResult(
        hpAfter: 100,
        bossOffers: 1,
        itemsGained: const ['tome_of_mastery'],
        items: const {
          'tome_of_mastery': {'itemType': 'Tome'},
        },
      );
      expect(_sources(notifier),
          [OfferSource.level, OfferSource.boss, OfferSource.tome]);
    });

    test('a chapter\'s start brings one, once; the first chapter none',
        () async {
      final notifier = await _notifierWith(_warrior());
      expect(await notifier.grantChapterOffer(1), isFalse);
      expect(await notifier.grantChapterOffer(2), isTrue);
      expect(await notifier.grantChapterOffer(2), isFalse);
      expect(await notifier.grantChapterOffer(3), isTrue);
      expect(notifier.state.pendingOffers.map((t) => t.detail), ['2', '3']);
      expect(notifier.state.chapterOffersThrough, 3);
      // Coming back to an earlier chapter brings nothing.
      expect(await notifier.grantChapterOffer(2), isFalse);
    });

    test('the hook for quests and intrigues names its faction', () async {
      final notifier = await _notifierWith(_warrior());
      await notifier.grantOffer(OfferSource.quest,
          factionId: 'vigil', detail: 'wall_1');
      final ticket = notifier.state.pendingOffers.single;
      expect(ticket.factionId, 'vigil');
      expect(ticket.better, isTrue);
      final offer = await notifier.ensureOffer(_tables, random: Random(1));
      expect(offer!.suitorOf('vigil'), isNotNull);
    });

    test('a new character\'s starting skill points are offers', () async {
      final notifier = await _notifierWith(_warrior());
      await notifier.startNewGame(
        raceId: 'elf',
        race: const {},
        professionId: 'mage',
        profession: const {'startingSkillPoints': 1},
      );
      expect(_sources(notifier), [OfferSource.start]);
    });
  });

  group('an old save', () {
    test('its unspent points and picks become offers; the rest stays', () {
      final old = {
        ..._warrior().toJson(),
        'skillPoints': 3,
        'pendingPerkPicks': 1,
        'pendingSignPicks': 2,
        'perkRanks': {'vigor': 2},
        'heldSigns': [
          {'signId': 'inked_strike_ember', 'rarity': 'rare', 'level': 2},
        ],
        'signOffer': {
          'patronId': 'crows',
          'cards': [
            {'signId': 'inked_mend_red_ink', 'rarity': 'common'},
          ],
        },
        'clockChapter': 4,
      }
        ..remove('pendingOffers')
        ..remove('clanOffer')
        ..remove('chapterOffersThrough')
        ..['saveVersion'] = 2;
      final session = PlayerSession.fromJson(old);
      expect(session.pendingOffers, hasLength(3 + 1 + 2));
      expect(
          session.pendingOffers.every((t) => t.source == OfferSource.migrated),
          isTrue);
      expect(session.clanOffer, isNull, reason: 'a sign offer is redrawn');
      expect(
          session.unlockedSkillIds, ['warrior_shield_bash', 'human_resolve']);
      expect(session.perkRanks, {'vigor': 2});
      expect(session.heldSigns.single.level, 2);
      // The chapter it is in brought no offer: from the next one on.
      expect(session.chapterOffersThrough, 4);
      final saved = session.toJson();
      expect(saved['saveVersion'], playerSessionSaveVersion);
      expect(saved.containsKey('skillPoints'), isFalse);
    });

    test('a save from now round-trips its offers, titles and boons', () {
      const offer = ClanOffer(
        ticket: OfferTicket(source: OfferSource.chapter, detail: '3'),
        suitors: [
          Suitor(
              factionId: 'mire',
              subclanId: 'returned',
              gift: OfferGift(kind: GiftKind.object, id: 'antidote')),
        ],
      );
      final session = _warrior().copyWith(
        pendingOffers: const [
          OfferTicket(source: OfferSource.chapter, detail: '3'),
          OfferTicket(source: OfferSource.boss),
        ],
        clanOffer: offer,
        heldTitleIds: const ['terms_kept'],
        activeTitleId: 'terms_kept',
        swornBoonIds: const ['mire'],
        chapterOffersThrough: 3,
      );
      final back = PlayerSession.fromJson(session.toJson());
      expect(back.pendingOffers, session.pendingOffers);
      expect(back.clanOffer, offer);
      expect(back.heldTitleIds, ['terms_kept']);
      expect(back.activeTitleId, 'terms_kept');
      expect(back.swornBoonIds, ['mire']);
      expect(back.chapterOffersThrough, 3);
      // Nothing owed: an empty list is not an old save.
      expect(
          PlayerSession.fromJson(
                  _warrior().copyWith(pendingOffers: const []).toJson())
              .pendingOffers,
          isEmpty);
    });
  });

  group('drawing and taking', () {
    test('drawn once and kept; nothing waits, nothing is drawn', () async {
      final notifier = await _notifierWith(_warrior());
      expect(await notifier.ensureOffer(_tables), isNull);
      await notifier.grantOffer(OfferSource.level);
      final offer = await notifier.ensureOffer(_tables, random: Random(2));
      expect(offer!.suitors, hasLength(3));
      expect(await notifier.ensureOffer(_tables, random: Random(99)), offer);
      expect(notifier.state.patronsMet,
          containsAll([for (final s in offer.suitors) s.factionId]));
    });

    test('a skill: learned, standing and its ripple, the voice a friend',
        () async {
      final notifier = await _notifierWith(_offered(
          _warrior(),
          const Suitor(
              factionId: 'dominion',
              subclanId: 'inquisition',
              gift: OfferGift(kind: GiftKind.skill, id: 'power_strike'))));
      expect(await notifier.acceptSuitor('dominion', tables: _tables), isTrue);
      final s = notifier.state;
      expect(s.unlockedSkillIds, contains('power_strike'));
      // The Dominion starts at -10: -4 after +6; the Crows (Trade) +1.5;
      // the Vigil, the Mire, the Penitents (rivals) -3.
      expect(s.politics.standingOf('dominion', _clans), -4);
      expect(s.politics.standingOf('crows', _clans), 1.5);
      expect(s.politics.standingOf('vigil', _clans), -3);
      expect(s.politics.markOf('inquisition'), SubclanMark.friend);
      // The Inquisition leans down, whatever the Dominion's lean.
      expect(s.alignmentScore, -1);
      expect(s.pendingOffers, isEmpty);
      expect(s.clanOffer, isNull);
    });

    test('an object: a potion as charges, gear to the pack', () async {
      final notifier = await _notifierWith(_offered(
          _warrior(),
          const Suitor(
              factionId: 'mire',
              subclanId: 'returned',
              gift: OfferGift(kind: GiftKind.object, id: 'potion_major')),
          const OfferTicket(source: OfferSource.chapter, detail: '2')));
      final potions = notifier.state.potionCount;
      await notifier.acceptSuitor('mire', tables: _tables);
      expect(notifier.state.potionCount, potions + 2);
      // A chapter's offer is worth +10.
      expect(notifier.state.politics.standingOf('mire', _clans), 10);
      expect(notifier.state.politics.standingLog.first.cause, 'chapter:2');

      await notifier.loadSession(_offered(
          notifier.state,
          const Suitor(
              factionId: 'compact',
              gift: OfferGift(kind: GiftKind.object, id: 'helm_iron_cap'))));
      await notifier.acceptSuitor('compact', tables: _tables);
      expect(notifier.state.inventoryItemIds, contains('helm_iron_cap'));
    });

    test('a title held and worn; a Sworn boon taken once', () async {
      final notifier = await _notifierWith(_offered(
          _warrior(),
          const Suitor(
              factionId: 'crows',
              subclanId: 'keyholders',
              gift: OfferGift(kind: GiftKind.title, id: 'paid_in_full'))));
      await notifier.acceptSuitor('crows', tables: _tables);
      // +6 reaches Known with the Crows: its tier title comes too, the
      // one given stays worn.
      expect(notifier.state.heldTitleIds, ['paid_in_full', 'good_for_it']);
      expect(notifier.state.activeTitleId, 'paid_in_full');

      await notifier.loadSession(_offered(
          notifier.state,
          const Suitor(
              factionId: 'crows',
              gift: OfferGift(kind: GiftKind.sworn, id: 'crows'))));
      await notifier.acceptSuitor('crows', tables: _tables);
      expect(notifier.state.swornBoonIds, ['crows']);
    });

    test('the Choir\'s sign moves the alignment by 3 and shuts the Pit out',
        () async {
      final notifier = await _notifierWith(_offered(
          _warrior(alignment: 12),
          const Suitor(
              factionId: 'choir',
              gift: OfferGift(
                  kind: GiftKind.sign,
                  id: 'choir_passive_last_light',
                  rarity: SignRarity.rare))));
      await notifier.acceptSuitor('choir', tables: _tables);
      expect(notifier.state.alignmentScore, 15);
      expect(notifier.state.signPatronsThisLife, contains('choir'));
      // Even fallen far, this life no longer hears the Pit.
      await notifier.loadSession(notifier.state.copyWith(alignmentScore: -30));
      expect(eligibleSuitors(notifier.offerContextFor(_tables)),
          isNot(contains('pit')));
    });
  });

  group('titles standing earns', () {
    test('a tier reached earns its title, worn when none is', () async {
      final notifier = await _notifierWith(_warrior());
      await notifier.changeStanding('compact', 10,
          data: _clans, cause: 'quest:forge');
      expect(notifier.state.heldTitleIds, ['friend_of_the_row']);
      expect(notifier.state.activeTitleId, 'friend_of_the_row');
      // Kept when standing falls back.
      await notifier.changeStanding('compact', -20,
          data: _clans, cause: 'story');
      expect(notifier.state.heldTitleIds, ['friend_of_the_row']);
    });

    test('the Marked while the Inquisition is a foe, never worn', () async {
      final notifier = await _notifierWith(_warrior());
      await notifier.setSubclanMark('inquisition', SubclanMark.foe,
          data: _clans, cause: 'story');
      expect(notifier.state.heldTitleIds, ['the_marked']);
      expect(notifier.state.activeTitleId, '');
      await notifier.setActiveTitle('the_marked');
      await notifier.setSubclanMark('inquisition', SubclanMark.none,
          data: _clans, cause: 'story');
      expect(notifier.state.heldTitleIds, isEmpty);
    });

    test('a death takes the titles, the boons and the offers waiting',
        () async {
      final notifier = await _notifierWith(_warrior().copyWith(
        heldTitleIds: const ['paid_in_full'],
        activeTitleId: 'paid_in_full',
        swornBoonIds: const ['crows'],
        pendingOffers: const [OfferTicket(source: OfferSource.level)],
        perkRanks: const {'vigor': 1},
      ));
      await notifier.applyPermadeath(race: const {}, profession: const {});
      final s = notifier.state;
      expect(s.heldTitleIds, isEmpty);
      expect(s.activeTitleId, '');
      expect(s.swornBoonIds, isEmpty);
      expect(s.pendingOffers, isEmpty);
      expect(s.perkRanks, {'vigor': 1}, reason: 'perks outlast a life');
    });
  });
}
