// Offers (v1.194) on a 360-px phone: the offer dialog -- three suitors
// stacked, each with their colour, "The Emberwives of the Cinder
// Compact", their first words, the gift (its kind, name, rarity and what
// it does) and the standing it would move by the real relations; a
// suitor taken with a confirm (the gift, the standing and its ripple, the
// voice a friend), the next offer drawn, "Later" keeping it -- in English
// and in French, with the Character tab's titles.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/offer_dialog.dart';
import 'package:narrative_data_app/widgets/title_widgets.dart';

import 'player_session_provider_test.dart' show baseSession;

const OfferTicket _level = OfferTicket(source: OfferSource.level);

/// The Emberwives (Compact) with a skill, the Ember Sisters (Penitents)
/// with a strike sign, and the Wayfarer with a perk rank.
const ClanOffer _offer = ClanOffer(ticket: _level, suitors: [
  Suitor(
    factionId: 'compact',
    subclanId: 'emberwives',
    firstMeeting: true,
    gift: OfferGift(
        kind: GiftKind.skill,
        id: 'warrior_iron_stance',
        rarity: SignRarity.rare),
  ),
  Suitor(
    factionId: 'penitents',
    subclanId: 'ember_sisters',
    greetingIndex: 1,
    gift: OfferGift(
        kind: GiftKind.sign,
        id: 'lettered_strike_spark_letter',
        rarity: SignRarity.rare),
  ),
  Suitor(
    factionId: wayfarerId,
    gift: OfferGift(kind: GiftKind.perk, id: 'keenEye'),
  ),
]);

Future<ProviderContainer> _open(WidgetTester tester,
    {required bool french}) async {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({if (french) 'app_language': 'fr'});
  final container = ProviderContainer();
  addTearDown(container.dispose);
  final notifier = container.read(playerSessionProvider.notifier);
  container.read(appLanguageProvider);
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
  await tester.runAsync(() async {
    for (final schema in [
      factionsSchema,
      subclansSchema,
      relationsSchema,
      titlesSchema,
      intriguesSchema,
      signsSchema,
      skillsSchema,
      skillTreesSchema,
      itemsSchema,
      spellsSchema,
    ]) {
      await container.read(gameDbProvider(schema).notifier).whenLoaded();
    }
  });
  await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
        ...baseSession().toJson(),
        'raceId': 'human',
        'professionId': 'warrior',
        'unlockedSkillIds': ['warrior_shield_bash', 'bulwark_stance'],
      }).copyWith(
        heldSigns: const [HeldSign(signId: 'inked_strike_ember')],
        pendingOffers: const [_level, _level],
        clanOffer: _offer,
        heldTitleIds: const ['coal_guard', 'the_marked'],
        activeTitleId: 'coal_guard',
        // The Inquisition's foe: "the Marked" holds.
        politics: const PoliticsState(marks: {'inquisition': SubclanMark.foe}),
      )));

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) => ListView(
            children: [
              ElevatedButton(
                key: const Key('open'),
                onPressed: () => showOfferIfWaiting(context, ref),
                child: const Text('Open'),
              ),
              const TitlesSection(),
            ],
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.byKey(const Key('open')));
  for (var i = 0; i < 3; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
  }
  return container;
}

void main() {
  testWidgets('three suitors stacked at 360 px; one taken, the next kept',
      (tester) async {
    final container = await _open(tester, french: false);

    expect(find.byType(OfferDialog), findsOneWidget);
    expect(find.text('The clans come to you'), findsOneWidget);
    expect(find.textContaining('2 waiting'), findsOneWidget);
    // The suitors, their voices and their first words.
    expect(find.text('The Emberwives of the Cinder Compact'), findsOneWidget);
    expect(
        find.text('The Ember Sisters of the Ashen Penitents'), findsOneWidget);
    expect(find.text('The Wayfarer'), findsOneWidget);
    expect(find.textContaining('broke every hammer in the Row'), findsOneWidget,
        reason: 'the Compact\'s intro, the first time');
    // The gifts: kind, name, rarity, what they do.
    expect(find.text('Skill'), findsOneWidget);
    expect(find.text('Iron Stance'), findsOneWidget);
    expect(find.text('Sign'), findsOneWidget);
    expect(find.text('Spark Letter'), findsOneWidget);
    expect(find.textContaining('+3 damage'), findsOneWidget);
    expect(find.text('Replaces: Ember Knuckles'), findsOneWidget);
    expect(find.text('Perk'), findsOneWidget);
    expect(find.text('Keen Eye'), findsOneWidget);
    // The politics of the pick, by the relations as they stand.
    expect(
        find.text('+6\u00a0Compact · +1.5\u00a0Vigil · +1.5\u00a0Mire · '
            '−3\u00a0Penitents'),
        findsOneWidget);
    expect(
        find.text('+6\u00a0Penitents · +1.5\u00a0Vigil · −3\u00a0Dominion · '
            '−3\u00a0Compact · −3\u00a0Mire · alignment\u00a0+1'),
        findsOneWidget);
    expect(find.text('No faction: standing doesn’t move.'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    // Nothing is taken before a suitor is chosen, and then confirmed.
    final take = find.byKey(const Key('offer_take_button'));
    expect(tester.widget<FilledButton>(take).onPressed, isNull);
    await tester.tap(find.byKey(const Key('offer_suitor_compact')));
    await tester.pump();
    await tester.ensureVisible(take);
    await tester.tap(take);
    await tester.pumpAndSettle();
    expect(find.text('Take Iron Stance?'), findsOneWidget);
    expect(find.text('Offered by: The Emberwives of the Cinder Compact'),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('offer_confirm_accept')));
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
    }

    var session = container.read(playerSessionProvider);
    expect(session.unlockedSkillIds, contains('warrior_iron_stance'));
    final clans = ClanData.fromTables(
      factions: container.read(gameDbProvider(factionsSchema)).value!,
      relations: container.read(gameDbProvider(relationsSchema)).value!,
    );
    expect(session.politics.standingOf('compact', clans), 6);
    expect(session.politics.standingOf('mire', clans), 1.5);
    expect(session.politics.standingOf('vigil', clans), 1.5);
    expect(session.politics.standingOf('penitents', clans), -3);
    expect(session.politics.markOf('emberwives'), SubclanMark.friend);
    expect(
        session.politics.standingLog.first.cause, 'offer:warrior_iron_stance');
    // The next offer is drawn, and the dialog stays with it; its suitors
    // are met.
    expect(session.pendingOffers, hasLength(1));
    final next = session.clanOffer;
    expect(next, isNotNull);
    expect(next, isNot(_offer));
    expect(session.patronsMet,
        containsAll([for (final s in next!.suitors) s.factionId]));
    expect(find.byType(OfferDialog), findsOneWidget);
    expect(tester.takeException(), isNull);

    // "Later" closes it and keeps the offer.
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.byType(OfferDialog), findsNothing);
    session = container.read(playerSessionProvider);
    expect(session.clanOffer, next);
    expect(session.pendingOffers, hasLength(1));
  });

  testWidgets('in French, with the titles worn', (tester) async {
    final container = await _open(tester, french: true);

    expect(find.text('Les clans viennent à vous'), findsOneWidget);
    expect(find.text('Les Charbonnières du Pacte des Cendres'), findsOneWidget);
    expect(find.text('Les Sœurs de Braise des Pénitents de Cendre'),
        findsOneWidget);
    expect(find.text('Le Voyageur'), findsOneWidget);
    expect(find.text('Compétence'), findsOneWidget);
    expect(find.text('Signe'), findsOneWidget);
    expect(find.text('Atout'), findsOneWidget);
    expect(find.text('Œil perçant'), findsOneWidget);
    expect(find.text('Remplace : Poings de braise'), findsOneWidget);
    expect(
        find.text('+6\u00a0Pacte · +1,5\u00a0Veille · +1,5\u00a0Marais · '
            '−3\u00a0Pénitents'),
        findsOneWidget);
    expect(find.text('Sans faction : la réputation ne bouge pas.'),
        findsOneWidget);
    expect(find.text('Prendre ce don'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    await tester.ensureVisible(find.byKey(const Key('offer_suitor_wayfarer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('offer_suitor_wayfarer')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('offer_take_button')));
    await tester.tap(find.byKey(const Key('offer_take_button')));
    await tester.pumpAndSettle();
    expect(find.text('Prendre Œil perçant ?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('offer_confirm_accept')));
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();
    }
    final session = container.read(playerSessionProvider);
    expect(session.perkRanks, {'keenEye': 1});
    expect(session.politics.standingLog, isEmpty,
        reason: 'the Wayfarer moves no standing');
    expect(session.heldTitleIds, ['coal_guard', 'the_marked']);
    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();

    // The titles: the one worn, and the brand that counts regardless.
    expect(find.text('Garde du charbon · Pacte'), findsOneWidget);
    expect(find.text('Porté'), findsOneWidget);
    expect(find.text('Sous la Marque · Dominion'), findsOneWidget);
    expect(
        find.text('Une marque : elle compte, portée ou non.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('title_coal_guard')));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(container.read(playerSessionProvider).activeTitleId, '');
    expect(tester.takeException(), isNull);
  });
}
