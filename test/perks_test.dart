// Perks (v1.163; since v1.194 the Wayfarer's gift in the clans' offers):
// what each rank adds, taking one from the Wayfarer, and the save file.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/gear_effects.dart';
import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/perks.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/perk_list.dart';

import 'player_session_provider_test.dart' show baseSession;

Future<PlayerSessionNotifier> _notifierWith(PlayerSession session) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(session);
  return notifier;
}

/// [session] with the Wayfarer on the table offering a rank of [perk].
PlayerSession _wayfarerOffers(PlayerSession session, String perk) =>
    session.copyWith(
      pendingOffers: const [OfferTicket(source: OfferSource.level)],
      clanOffer: ClanOffer(
        ticket: const OfferTicket(source: OfferSource.level),
        suitors: [
          Suitor(
              factionId: wayfarerId,
              gift: OfferGift(kind: GiftKind.perk, id: perk)),
        ],
      ),
    );

const OfferTables _tables = OfferTables(data: ClanData.empty);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the rules', () {
    test('each rank adds the same again, up to the cap', () {
      final effects = perkEffectsFor(const {
        'keenEye': 2,
        'heavyHand': 3,
        'plunderer': 1,
        'steadyHands': 1,
        'battleRhythm': 1,
        'lastStand': 1,
        'ironHide': 9, // capped at 3
      });
      expect(effects.critChance, 10);
      expect(effects.attackDamage, 6);
      expect(effects.armor, 6);
      expect(effects.extraRolls, 1);
      expect(effects.momentumDrop, 1);
      expect(effects.secondWind, isTrue);
      expect(effects.scaleGold(100), 110);
      expect(effects.scaleXp(100), 100);
      expect(PerkEffects.none.scaleAllyDamage(20), 20);
    });

    test('gear-like perks lay over the gear', () {
      const gear = GearEffects(attackDamage: 3, critChance: 5, thorns: 2);
      final over =
          perkEffectsFor(const {'heavyHand': 1, 'keenEye': 1}).over(gear);
      expect(over.attackDamage, 5);
      expect(over.critChance, 10);
      expect(over.thorns, 2);
      expect(over.secondWind, isFalse);
    });

    test('the offer is three different perks still open', () {
      for (var seed = 0; seed < 30; seed++) {
        final offer =
            rollPerkOffer(const {'steadyHands': 1, 'vigor': 3}, Random(seed));
        expect(offer, hasLength(perkOfferSize));
        expect(offer.toSet(), hasLength(perkOfferSize));
        expect(offer, isNot(contains(Perk.steadyHands)));
        expect(offer, isNot(contains(Perk.vigor)));
      }
      final everything = {
        for (final perk in Perk.values) perk.name: perkInfo[perk]!.maxRank,
      };
      expect(rollPerkOffer(everything, Random(1)), isEmpty);
    });

    test('one pick every second level', () {
      expect(perkPicksFor(1, 2), 1);
      expect(perkPicksFor(2, 3), 0);
      expect(perkPicksFor(3, 5), 1);
      expect(perkPicksFor(1, 7), 3);
      expect(perkPicksFor(4, 4), 0);
    });

    test('every perk has a name and a description in both languages', () {
      for (final perk in Perk.values) {
        for (final lang in AppLanguage.values) {
          expect(trFor(lang, perkNameKey(perk)), isNot(perkNameKey(perk)));
          expect(trFor(lang, perkDescKey(perk)), isNot(perkDescKey(perk)));
        }
      }
    });
  });

  group('the session', () {
    test('the Wayfarer\'s perk takes a rank, and moves no standing', () async {
      final notifier =
          await _notifierWith(_wayfarerOffers(baseSession(), 'keenEye'));
      expect(await notifier.acceptSuitor('nobody', tables: _tables), isFalse);
      expect(await notifier.acceptSuitor(wayfarerId, tables: _tables), isTrue);
      expect(notifier.state.perkRanks, {'keenEye': 1});
      expect(notifier.state.pendingOffers, isEmpty);
      expect(notifier.state.clanOffer, isNull);
      expect(notifier.state.politics.isEmpty, isTrue);
      expect(notifier.state.alignmentScore, 0);
    });

    test('Vigor adds its health at once; Deep Well raises max mana', () async {
      final notifier = await _notifierWith(_wayfarerOffers(
          baseSession(maxHealth: 100, currentHealth: 60), 'vigor'));
      expect(await notifier.acceptSuitor(wayfarerId, tables: _tables), isTrue);
      expect(notifier.state.maxHealth, 100 + vigorHealthPerRank);
      expect(notifier.state.currentHealth, 60 + vigorHealthPerRank);

      final base = maxManaFor(
          intelligence: notifier.state.intelligence,
          wisdom: notifier.state.wisdom);
      await notifier.loadSession(_wayfarerOffers(notifier.state, 'deepWell'));
      expect(await notifier.acceptSuitor(wayfarerId, tables: _tables), isTrue);
      expect(notifier.state.maxMana, base + manaPerRank);
    });

    test('perks survive the save file; an old save has none', () {
      final session = baseSession().copyWith(perkRanks: {'keenEye': 2});
      final back = PlayerSession.fromJson(session.toJson());
      expect(back.perkRanks, {'keenEye': 2});
      final old = session.toJson()..remove('perkRanks');
      final fromOld = PlayerSession.fromJson(old);
      expect(fromOld.perkRanks, isEmpty);
    });
  });

  testWidgets('the perks taken are listed with their ranks', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(playerSessionProvider.notifier);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(baseSession().copyWith(perkRanks: {'keenEye': 2})));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: PerkList())),
      ),
    ));
    await tester.pump();
    expect(find.byKey(const Key('perk_owned_keenEye')), findsOneWidget);
    expect(find.text('Keen Eye'), findsOneWidget);
    expect(find.byKey(const Key('perk_owned_vigor')), findsNothing);
  });
}
