// Signs (v1.192) in the session, given in the clans' offers since v1.194:
// a boss's offer and a hunt's Titan's Blood, taking a sign (favour, the
// life's patrons, a vow's or a pact's alignment), Titan's Blood, what a
// death and a new life take and keep, the save file and the Character
// tab's badge.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/tab_badges_provider.dart';

import 'player_session_provider_test.dart' show baseSession;

Future<PlayerSessionNotifier> _notifierWith(PlayerSession session) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(session);
  return notifier;
}

const Map<String, Patron> _patrons = {
  'red': Patron(id: 'red', name: 'Red', kind: PatronKind.clan),
  choirPatronId: Patron(
      id: choirPatronId,
      name: 'Choir',
      kind: PatronKind.otherworld,
      minAlignment: 10),
  pitPatronId: Patron(
      id: pitPatronId,
      name: 'Pit',
      kind: PatronKind.otherworld,
      maxAlignment: -10),
};

const _health = SignEffect(kind: SignEffectKind.maxHealth, value: 10);

final Map<String, SignDef> _signs = {
  for (final patron in _patrons.keys)
    for (final slot in [SignSlot.strike, SignSlot.guard, SignSlot.passive])
      '${patron}_${slot.name}': SignDef(
        id: '${patron}_${slot.name}',
        patronId: patron,
        slot: slot,
        name: '$patron ${slot.name}',
        effects: const [_health],
        pact: patron == pitPatronId
            ? const SignPact(curse: PactCurse.goldPercentLoss, value: 50)
            : null,
      ),
};

OfferTables get _tables => OfferTables(
      data: ClanData(factions: {
        for (final p in _patrons.values) p.id: Faction(patron: p),
      }),
      signs: _signs,
    );

/// [session] with [patronId] on the table offering [signId] at [rarity].
PlayerSession _signOffered(
        PlayerSession session, String patronId, String signId,
        [SignRarity rarity = SignRarity.common]) =>
    session.copyWith(
      pendingOffers: const [OfferTicket(source: OfferSource.level)],
      clanOffer: ClanOffer(
        ticket: const OfferTicket(source: OfferSource.level),
        suitors: [
          Suitor(
              factionId: patronId,
              gift: OfferGift(kind: GiftKind.sign, id: signId, rarity: rarity)),
        ],
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a boss brings an offer, a hunt Titan\'s Blood, a fight runs a pact',
      () async {
    final notifier = await _notifierWith(baseSession().copyWith(heldSigns: [
      const HeldSign(signId: 'pit_strike', pactFightsLeft: 3),
      const HeldSign(signId: 'red_guard'),
    ]));
    await notifier.applyCombatResult(
        hpAfter: 100, bossOffers: 1, titanBlood: 1, pactFight: true);
    expect(notifier.state.pendingOffers.single.source, OfferSource.boss);
    expect(notifier.state.titanBlood, 1);
    expect(notifier.state.heldSigns.first.pactFightsLeft, 2);
    // A fight that isn't one (a test fight) leaves the pact as it is.
    await notifier.applyCombatResult(hpAfter: 100);
    expect(notifier.state.heldSigns.first.pactFightsLeft, 2);
    await notifier.grantTitanBlood(1);
    expect(notifier.state.titanBlood, 2);
  });

  group('a sign taken from an offer', () {
    test('drawn on, with the patron\'s favour and this life', () async {
      final notifier = await _notifierWith(
          _signOffered(baseSession(), 'red', 'red_strike', SignRarity.epic));
      expect(await notifier.acceptSuitor('red', tables: _tables), isTrue);
      final s = notifier.state;
      expect(s.heldSigns.single.signId, 'red_strike');
      expect(s.heldSigns.single.rarity, SignRarity.epic);
      expect(s.pendingOffers, isEmpty);
      expect(s.clanOffer, isNull);
      expect(s.patronFavour, {'red': 1});
      expect(s.signPatronsThisLife, ['red']);
      // A sign for a filled slot replaces the one there.
      await notifier.loadSession(_signOffered(s, 'red', 'red_strike'));
      expect(await notifier.acceptSuitor('red', tables: _tables), isTrue);
      expect(notifier.state.heldSigns.single.rarity, SignRarity.epic,
          reason: 'the better rarity stays');
    });

    test('a vow lifts the alignment, a pact lowers it and starts counting',
        () async {
      final notifier = await _notifierWith(_signOffered(
          baseSession().copyWith(alignmentScore: 12),
          choirPatronId,
          'choir_passive',
          SignRarity.rare));
      await notifier.acceptSuitor(choirPatronId, tables: _tables);
      expect(notifier.state.alignmentScore, 12 + otherworldAlignmentShift);
      expect(notifier.state.signPatronsThisLife, [choirPatronId]);

      // Another life, on the other side.
      await notifier.loadSession(_signOffered(
          notifier.state
              .copyWith(alignmentScore: -12, signPatronsThisLife: const []),
          pitPatronId,
          'pit_passive'));
      await notifier.acceptSuitor(pitPatronId, tables: _tables);
      expect(notifier.state.alignmentScore, -12 - otherworldAlignmentShift);
      expect(
          notifier.state.heldSigns
              .firstWhere((h) => h.signId == 'pit_passive')
              .pactFightsLeft,
          defaultPactFights);
    });
  });

  test('Titan\'s Blood raises a held sign, and waits for one', () async {
    final notifier = await _notifierWith(baseSession().copyWith(titanBlood: 2));
    expect(await notifier.spendTitanBlood('red_guard'), isFalse);
    expect(notifier.state.titanBlood, 2);
    await notifier.loadSession(notifier.state.copyWith(heldSigns: const [
      HeldSign(signId: 'red_guard', level: maxSignLevel - 1),
    ]));
    expect(await notifier.spendTitanBlood('red_guard'), isTrue);
    expect(notifier.state.heldSigns.single.level, maxSignLevel);
    expect(notifier.state.titanBlood, 1);
    expect(await notifier.spendTitanBlood('red_guard'), isFalse,
        reason: 'already at its highest');
    expect(notifier.state.titanBlood, 1);
  });

  group('lives', () {
    PlayerSession signed() => _signOffered(
                baseSession(level: 6), 'red', 'red_strike', SignRarity.rare)
            .copyWith(
          heldSigns: const [HeldSign(signId: 'red_guard', level: 2)],
          titanBlood: 2,
          patronFavour: const {'red': 4},
          signPatronsThisLife: const ['red', choirPatronId],
          patronsMet: const ['red', choirPatronId],
        );

    test('a permadeath takes the signs; the patrons remember', () async {
      final notifier = await _notifierWith(signed());
      final result =
          await notifier.applyPermadeath(race: const {}, profession: const {});
      expect(result.signsLost, 1);
      final s = notifier.state;
      expect(s.heldSigns, isEmpty);
      expect(s.pendingOffers, isEmpty, reason: 'a warrior starts with none');
      expect(s.clanOffer, isNull);
      expect(s.titanBlood, 0);
      expect(s.signPatronsThisLife, isEmpty);
      expect(s.patronFavour, {'red': 4});
      expect(s.patronsMet, ['red', choirPatronId]);
      expect(s.level, 6);
    });

    test('a defeat that isn\'t a death keeps them', () async {
      final notifier = await _notifierWith(signed());
      await notifier.applyCombatResult(hpAfter: 100, pactFight: true);
      expect(notifier.state.heldSigns, hasLength(1));
      expect(notifier.state.titanBlood, 2);
    });

    test('New Game+ starts with no signs and keeps the favour', () async {
      final notifier = await _notifierWith(signed());
      await notifier.beginNewGamePlus();
      await notifier.resetSession();
      expect(notifier.state.heldSigns, isEmpty);
      expect(notifier.state.pendingOffers, isEmpty);
      expect(notifier.state.patronFavour, {'red': 4});
      await notifier.startNewGame(
        raceId: 'human',
        race: const {},
        professionId: 'warrior',
        profession: const {},
      );
      expect(notifier.state.heldSigns, isEmpty);
      expect(notifier.state.signPatronsThisLife, isEmpty);
      expect(notifier.state.patronFavour, {'red': 4});
      expect(notifier.state.patronsMet, ['red', choirPatronId]);
      await notifier.resetSession(keepLegacy: false);
      expect(notifier.state.patronFavour, isEmpty);
      expect(notifier.state.patronsMet, isEmpty);
    });
  });

  test('signs survive the save file; an old save has none', () {
    final session = baseSession().copyWith(
      heldSigns: const [
        HeldSign(
            signId: 'pit_strike',
            rarity: SignRarity.epic,
            level: 2,
            pactFightsLeft: 1),
      ],
      titanBlood: 3,
      patronFavour: const {'red': 5},
      signPatronsThisLife: const ['red'],
      patronsMet: const ['red', 'pit'],
    );
    final back = PlayerSession.fromJson(session.toJson());
    expect(back.heldSigns, session.heldSigns);
    expect(back.titanBlood, 3);
    expect(back.patronFavour, {'red': 5});
    expect(back.signPatronsThisLife, ['red']);
    expect(back.patronsMet, ['red', 'pit']);

    final old = session.toJson();
    for (final key in [
      'heldSigns',
      'titanBlood',
      'patronFavour',
      'signPatronsThisLife',
      'patronsMet',
    ]) {
      old.remove(key);
    }
    final fromOld = PlayerSession.fromJson(old);
    expect(fromOld.heldSigns, isEmpty);
    expect(fromOld.titanBlood, 0);
    expect(fromOld.patronFavour, isEmpty);
  });

  test('the Character tab\'s badge: blood to spend on a sign', () {
    bool waiting(PlayerSession s) => hasSignWaiting(s);
    expect(waiting(baseSession()), isFalse);
    expect(waiting(baseSession().copyWith(titanBlood: 1)), isFalse,
        reason: 'no sign to raise');
    expect(
        waiting(baseSession().copyWith(
            titanBlood: 1, heldSigns: const [HeldSign(signId: 'red_guard')])),
        isTrue);
    expect(
        waiting(baseSession().copyWith(titanBlood: 1, heldSigns: const [
          HeldSign(signId: 'red_guard', level: maxSignLevel)
        ])),
        isFalse);
  });
}
