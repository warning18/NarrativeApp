// Signs (v1.192) on a 360-px phone: the offer dialog -- the patron's
// header and first words, three cards with what each does in numbers,
// what it replaces, a duo's badge and a pact's price; a card taken, the
// next offer drawn, and "Later" keeping it for another time -- and, in
// French, the Character tab's signs with Titan's Blood spent, and the
// Clans codex (the Patrons' until v1.193: the patrons are the factions).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/clan_widgets.dart';
import 'package:narrative_data_app/widgets/sign_offer_dialog.dart';
import 'package:narrative_data_app/widgets/sign_widgets.dart';

import 'player_session_provider_test.dart' show baseSession;

/// The shipped factions: the names and words the dialog shows.
final Map<String, Faction> _factions = parseFactions(
    jsonDecode(File('assets/gamedata/factions.json').readAsStringSync())
        as Map<String, dynamic>);

void main() {
  testWidgets('the offer shows its cards, takes one and keeps the next',
      (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(playerSessionProvider.notifier);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.runAsync(() async {
      await container
          .read(gameDbProvider(factionsSchema).notifier)
          .whenLoaded();
      await container.read(gameDbProvider(signsSchema).notifier).whenLoaded();
    });
    await tester.runAsync(() => notifier.loadSession(baseSession().copyWith(
          alignmentScore: -12,
          heldSigns: const [
            HeldSign(signId: 'painted_strike_gale', level: 2),
            HeldSign(signId: 'lettered_passive_night_reading'),
            HeldSign(signId: 'pit_passive_red_thirst'),
          ],
          signPatronsThisLife: const ['mire', 'penitents', pitPatronId],
          pendingSignPicks: 2,
          signOffer: const SignOffer(
            patronId: 'crows',
            firstMeeting: true,
            cards: [
              SignCard(signId: 'inked_strike_ember', rarity: SignRarity.rare),
              SignCard(
                  signId: 'inked_spell_burning_script',
                  rarity: SignRarity.epic),
              SignCard(
                  signId: 'pit_passive_blood_debt', rarity: SignRarity.rare),
            ],
          ),
        )));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => Center(
              child: ElevatedButton(
                key: const Key('open'),
                onPressed: () => showSignOfferIfWaiting(context, ref),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('open')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    // The faction, and their first words.
    final crows = _factions['crows']!;
    expect(find.text(crows.nameFor(AppLanguage.en)), findsOneWidget);
    expect(find.text(crows.introFor(AppLanguage.en)), findsOneWidget);
    // Three cards, each with its numbers.
    expect(find.text('Ember Knuckles'), findsOneWidget);
    expect(find.text('Burning Script'), findsOneWidget);
    expect(find.text('Blood Debt'), findsOneWidget);
    // Rare: Fire 1 x 1.5 = 2, at the Gale's level 2 it replaces (x1.5).
    expect(
        find.text('Attack faces strike with Fire, +2 damage.'), findsOneWidget);
    expect(find.text('Replaces: Gale Sigil'), findsOneWidget);
    expect(find.text('Duo'), findsNWidgets(2));
    expect(find.textContaining('Pact: the next 3 fights pay 40% less'),
        findsOneWidget);
    expect(find.textContaining('Epic'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    // Nothing is taken before a card is chosen.
    final take = find.byKey(const Key('sign_take_button'));
    expect(tester.widget<FilledButton>(take).onPressed, isNull);
    await tester.tap(find.byKey(const Key('sign_offer_inked_strike_ember')));
    await tester.pump();
    await tester.tap(take);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    var session = container.read(playerSessionProvider);
    final ember =
        session.heldSigns.firstWhere((h) => h.signId == 'inked_strike_ember');
    expect(ember.level, 2, reason: 'the Gale\'s level stays');
    expect(ember.rarity, SignRarity.rare);
    expect(session.heldSigns.map((h) => h.signId),
        isNot(contains('painted_strike_gale')));
    expect(session.patronFavour, {'crows': 1});
    expect(session.pendingSignPicks, 1);
    // The next offer is on the table, and the dialog with it.
    final next = session.signOffer;
    expect(next, isNotNull);
    expect(find.byType(SignOfferDialog), findsOneWidget);
    expect(tester.takeException(), isNull);

    // "Later" closes it and keeps the offer.
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.byType(SignOfferDialog), findsNothing);
    session = container.read(playerSessionProvider);
    expect(session.pendingSignPicks, 1);
    expect(session.signOffer, next);
  });

  testWidgets('the Character tab\'s signs and the codex, in French',
      (tester) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'app_language': 'fr'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(playerSessionProvider.notifier);
    container.read(appLanguageProvider);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.runAsync(() async {
      await container
          .read(gameDbProvider(factionsSchema).notifier)
          .whenLoaded();
      await container.read(gameDbProvider(signsSchema).notifier).whenLoaded();
    });
    await tester.runAsync(() => notifier.loadSession(baseSession().copyWith(
          alignmentScore: -12,
          heldSigns: const [
            HeldSign(signId: 'inked_strike_ember', rarity: SignRarity.rare),
            HeldSign(signId: 'choir_passive_last_light'),
            HeldSign(signId: 'pit_passive_red_thirst', pactFightsLeft: 2),
          ],
          titanBlood: 1,
          pendingSignPicks: 1,
          patronFavour: const {'crows': 4, choirPatronId: 1},
          patronsMet: const ['crows', choirPatronId],
          signPatronsThisLife: const ['crows', pitPatronId],
        )));

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(children: [SignsSection(), ClansCodex()]),
          ),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Sang de Titan\u00a0: 1'), findsOneWidget);
    expect(find.text('Poings de braise'), findsOneWidget);
    // Rare: Fire 1 x 1.5 = 2 (rounded).
    expect(
        find.text('Les faces Attaque prennent l’élément Feu, +2\u00a0dégâts.'),
        findsOneWidget);
    // The vow is silent at -12; the pact counts its fights down.
    expect(find.text('Silencieux\u00a0: votre alignement est sous 0.'),
        findsOneWidget);
    expect(find.textContaining('les 2\u00a0prochains combats'), findsOneWidget);
    // The codex: the factions met, their favour, and the Choir closed off.
    expect(
        find.text(_factions['crows']!.nameFor(AppLanguage.fr)), findsOneWidget);
    expect(find.text('Clan · Faveur 4 · niveau 1'), findsOneWidget);
    expect(find.text('Fermé pour vous dans cette vie'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    // A tap on a sign, confirmed, spends the blood on it.
    await tester.tap(find.byKey(const Key('sign_held_inked_strike_ember')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('titan_blood_raise')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    final session = container.read(playerSessionProvider);
    expect(session.titanBlood, 0);
    expect(session.heldSigns.first.level, 2);
    expect(find.text('Rare · Niv.\u00a02'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
