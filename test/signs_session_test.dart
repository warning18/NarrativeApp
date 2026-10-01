// Signs (v1.192) in the session: the picks levels, bosses and hunts bring,
// the offer drawn once and kept, taking a sign (favour, the life's
// patrons, a vow's or a pact's alignment), Titan's Blood, what a death and
// a new life take and keep, the save file and the Character tab's badge.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the picks', () {
    test('odd levels bring a sign, even levels a perk', () async {
      final notifier = await _notifierWith(baseSession(level: 1));
      await notifier.applyCombatResult(hpAfter: 100, xpGain: 100 + 200);
      expect(notifier.state.level, 3);
      expect(notifier.state.pendingSignPicks, 1);
      expect(notifier.state.pendingPerkPicks, 1);
    });

    test('a quest that levels brings its signs too', () async {
      final notifier = await _notifierWith(
          baseSession(level: 1, activeQuestIds: const ['q']));
      await notifier.completeQuest('q', rewardXP: 100 + 200 + 300 + 400);
      expect(notifier.state.level, 5);
      expect(notifier.state.pendingSignPicks, 2, reason: 'levels 3 and 5');
    });

    test('a boss brings a sign, a hunt Titan\'s Blood, a fight runs a pact',
        () async {
      final notifier = await _notifierWith(baseSession().copyWith(heldSigns: [
        const HeldSign(signId: 'pit_strike', pactFightsLeft: 3),
        const HeldSign(signId: 'red_guard'),
      ]));
      await notifier.applyCombatResult(
          hpAfter: 100, signPicks: 1, titanBlood: 1, pactFight: true);
      expect(notifier.state.pendingSignPicks, 1);
      expect(notifier.state.titanBlood, 1);
      expect(notifier.state.heldSigns.first.pactFightsLeft, 2);
      // A fight that isn't one (a test fight) leaves the pact as it is.
      await notifier.applyCombatResult(hpAfter: 100);
      expect(notifier.state.heldSigns.first.pactFightsLeft, 2);
      await notifier.grantSignPicks(2);
      await notifier.grantTitanBlood(1);
      expect(notifier.state.pendingSignPicks, 3);
      expect(notifier.state.titanBlood, 2);
    });
  });

  group('the offer', () {
    test('drawn once and kept until a sign is taken', () async {
      final notifier = await _notifierWith(baseSession());
      expect(await notifier.ensureSignOffer(patrons: _patrons, signs: _signs),
          isNull,
          reason: 'no pick waits');
      await notifier.grantSignPicks(2);
      final offer = await notifier.ensureSignOffer(
          patrons: _patrons, signs: _signs, random: Random(4));
      expect(offer!.patronId, 'red', reason: 'the only one open at 0');
      expect(offer.cards, hasLength(3));
      expect(offer.firstMeeting, isTrue);
      expect(notifier.state.patronsMet, ['red']);
      expect(
          await notifier.ensureSignOffer(
              patrons: _patrons, signs: _signs, random: Random(99)),
          offer);

      expect(await notifier.chooseSign('choir_guard', signs: _signs), isFalse,
          reason: 'not on the table');
      final taken = offer.cards.first;
      expect(await notifier.chooseSign(taken.signId, signs: _signs), isTrue);
      final s = notifier.state;
      expect(s.heldSigns.single.signId, taken.signId);
      expect(s.heldSigns.single.rarity, taken.rarity);
      expect(s.pendingSignPicks, 1);
      expect(s.signOffer, isNull);
      expect(s.patronFavour, {'red': 1});
      expect(s.signPatronsThisLife, ['red']);
      expect(s.alignmentScore, 0);
    });

    test('a vow lifts the alignment, a pact lowers it and starts counting',
        () async {
      final notifier = await _notifierWith(baseSession().copyWith(
        alignmentScore: 12,
        pendingSignPicks: 1,
        signOffer: const SignOffer(patronId: choirPatronId, cards: [
          SignCard(signId: 'choir_passive', rarity: SignRarity.rare),
        ]),
      ));
      await notifier.chooseSign('choir_passive', signs: _signs);
      expect(notifier.state.alignmentScore, 12 + otherworldAlignmentShift);
      expect(notifier.state.signPatronsThisLife, [choirPatronId]);

      // Another life, on the other side.
      await notifier.loadSession(notifier.state.copyWith(
        alignmentScore: -12,
        signPatronsThisLife: const [],
        pendingSignPicks: 1,
        signOffer: const SignOffer(patronId: pitPatronId, cards: [
          SignCard(signId: 'pit_passive', rarity: SignRarity.common),
        ]),
      ));
      await notifier.chooseSign('pit_passive', signs: _signs);
      expect(notifier.state.alignmentScore, -12 - otherworldAlignmentShift);
      expect(
          notifier.state.heldSigns
              .firstWhere((h) => h.signId == 'pit_passive')
              .pactFightsLeft,
          defaultPactFights);
    });

    test('no patron with anything left: the pick waits', () async {
      final notifier = await _notifierWith(baseSession().copyWith(
        pendingSignPicks: 1,
        heldSigns: [
          for (final id in ['red_strike', 'red_guard', 'red_passive'])
            HeldSign(signId: id),
        ],
      ));
      expect(await notifier.ensureSignOffer(patrons: _patrons, signs: _signs),
          isNull);
      expect(notifier.state.pendingSignPicks, 1);
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
    PlayerSession signed() => baseSession(level: 6).copyWith(
          heldSigns: const [HeldSign(signId: 'red_guard', level: 2)],
          pendingSignPicks: 1,
          signOffer: const SignOffer(
              patronId: 'red',
              cards: [SignCard(signId: 'red_strike', rarity: SignRarity.rare)]),
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
      expect(s.pendingSignPicks, 0);
      expect(s.signOffer, isNull);
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
      expect(notifier.state.pendingSignPicks, 0);
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
      pendingSignPicks: 2,
      signOffer: const SignOffer(
        patronId: 'red',
        cards: [SignCard(signId: 'red_strike', rarity: SignRarity.heroic)],
        firstMeeting: true,
        greetingIndex: 2,
      ),
      titanBlood: 3,
      patronFavour: const {'red': 5},
      signPatronsThisLife: const ['red'],
      patronsMet: const ['red', 'pit'],
    );
    final back = PlayerSession.fromJson(session.toJson());
    expect(back.heldSigns, session.heldSigns);
    expect(back.pendingSignPicks, 2);
    expect(back.signOffer, session.signOffer);
    expect(back.titanBlood, 3);
    expect(back.patronFavour, {'red': 5});
    expect(back.signPatronsThisLife, ['red']);
    expect(back.patronsMet, ['red', 'pit']);

    final old = session.toJson();
    for (final key in [
      'heldSigns',
      'pendingSignPicks',
      'signOffer',
      'titanBlood',
      'patronFavour',
      'signPatronsThisLife',
      'patronsMet',
    ]) {
      old.remove(key);
    }
    final fromOld = PlayerSession.fromJson(old);
    expect(fromOld.heldSigns, isEmpty);
    expect(fromOld.pendingSignPicks, 0);
    expect(fromOld.signOffer, isNull);
    expect(fromOld.titanBlood, 0);
    expect(fromOld.patronFavour, isEmpty);
  });

  test('the Character tab\'s badge: an offer to make, or blood to spend', () {
    bool waiting(PlayerSession s) =>
        hasSignWaiting(s, patrons: _patrons, signs: _signs);
    expect(waiting(baseSession()), isFalse);
    expect(waiting(baseSession().copyWith(pendingSignPicks: 1)), isTrue);
    // A pick nobody can answer yet stays quiet.
    expect(
        waiting(baseSession().copyWith(pendingSignPicks: 1, heldSigns: [
          for (final id in ['red_strike', 'red_guard', 'red_passive'])
            HeldSign(signId: id),
        ])),
        isFalse);
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
