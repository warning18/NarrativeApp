// Level-up perks (v1.162): what each rank adds, the offer, picking one,
// the picks a level brings, and the save file.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/gear_effects.dart';
import 'package:narrative_data_app/combat/spells.dart';
import 'package:narrative_data_app/data/perks.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/perk_picker.dart';

import 'player_session_provider_test.dart' show baseSession;

Future<PlayerSessionNotifier> _notifierWith(PlayerSession session) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(session);
  return notifier;
}

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

    test('one pick per level reached from the second', () {
      expect(perkPicksFor(1, 2), 1);
      expect(perkPicksFor(3, 5), 2);
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
    test('a level-up brings a pick; choosing takes a rank', () async {
      final notifier = await _notifierWith(baseSession(level: 1));
      await notifier.applyCombatResult(hpAfter: 100, xpGain: 100);
      expect(notifier.state.level, 2);
      expect(notifier.state.pendingPerkPicks, 1);

      final offer = await notifier.ensurePerkOffer(random: Random(3));
      expect(offer, hasLength(perkOfferSize));
      // The same offer until something is chosen.
      expect(await notifier.ensurePerkOffer(random: Random(99)), offer);
      expect(await notifier.choosePerk('notAPerk'), isFalse);

      expect(await notifier.choosePerk(offer.first), isTrue);
      expect(notifier.state.perkRanks[offer.first], 1);
      expect(notifier.state.pendingPerkPicks, 0);
      expect(notifier.state.perkOffer, isEmpty);
      expect(await notifier.ensurePerkOffer(), isEmpty);
    });

    test('Vigor adds its health at once; Deep Well raises max mana', () async {
      final notifier = await _notifierWith(
          baseSession(maxHealth: 100, currentHealth: 60).copyWith(
              pendingPerkPicks: 2, perkOffer: ['vigor', 'deepWell', 'leader']));
      expect(await notifier.choosePerk('vigor'), isTrue);
      expect(notifier.state.maxHealth, 100 + vigorHealthPerRank);
      expect(notifier.state.currentHealth, 60 + vigorHealthPerRank);

      final base = maxManaFor(
          intelligence: notifier.state.intelligence,
          wisdom: notifier.state.wisdom);
      await notifier.loadSession(notifier.state
          .copyWith(perkOffer: ['deepWell', 'leader', 'keenEye']));
      expect(await notifier.choosePerk('deepWell'), isTrue);
      expect(notifier.state.maxMana, base + manaPerRank);
    });

    test('a quest that levels brings its picks too', () async {
      final notifier = await _notifierWith(
          baseSession(level: 1, activeQuestIds: const ['q']));
      await notifier.completeQuest('q', rewardXP: 100 + 200);
      expect(notifier.state.level, 3);
      expect(notifier.state.pendingPerkPicks, 2);
    });

    test('perks survive the save file; an old save has none', () {
      final session = baseSession().copyWith(
        perkRanks: {'keenEye': 2},
        pendingPerkPicks: 1,
        perkOffer: ['vigor', 'leader', 'apothecary'],
      );
      final back = PlayerSession.fromJson(session.toJson());
      expect(back.perkRanks, {'keenEye': 2});
      expect(back.pendingPerkPicks, 1);
      expect(back.perkOffer, ['vigor', 'leader', 'apothecary']);
      final old = session.toJson()
        ..remove('perkRanks')
        ..remove('pendingPerkPicks')
        ..remove('perkOffer');
      final fromOld = PlayerSession.fromJson(old);
      expect(fromOld.perkRanks, isEmpty);
      expect(fromOld.pendingPerkPicks, 0);
    });
  });

  testWidgets('the picker offers three and takes the one tapped',
      (tester) async {
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
        .loadSession(baseSession().copyWith(
            pendingPerkPicks: 1,
            perkOffer: ['keenEye', 'vigor', 'plunderer'])));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(children: [PerkPicker(), PerkList()]),
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(find.text('Keen Eye'), findsOneWidget);
    expect(find.text('Vigor'), findsOneWidget);
    expect(find.text('Plunderer'), findsOneWidget);

    await tester.tap(find.byKey(const Key('perk_offer_keenEye')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    final session = container.read(playerSessionProvider);
    expect(session.perkRanks, {'keenEye': 1});
    expect(session.pendingPerkPicks, 0);
    // The picker is gone; the list shows the perk taken.
    expect(find.byKey(const Key('perk_offer_vigor')), findsNothing);
    expect(find.byKey(const Key('perk_owned_keenEye')), findsOneWidget);
  });
}
