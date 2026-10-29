// Offers (v1.194) on a 360-px phone: the offer dialog -- three banners on
// top, the clans' compass, then the picked suitor's words (charter, gift),
// each with their colour, "The Emberwives of the Cinder
// Compact", their first words, the gift (its kind, name, rarity and what
// it does) and the standing it would move by the real relations; a
// suitor taken with a confirm (the gift, the standing and its ripple, the
// voice a friend), the next offer drawn, never left for later -- in English
// and in French, with the Character tab's titles.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/clan_peek.dart';
import 'package:narrative_data_app/widgets/offer_dialog.dart';
import 'package:narrative_data_app/widgets/title_widgets.dart';

import 'player_session_provider_test.dart' show baseSession;
import 'support/fonts.dart';

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

final _shotKey = GlobalKey();

Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) return;
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<ProviderContainer> _open(WidgetTester tester,
    {required bool french, Size size = const Size(360, 740)}) async {
  tester.view.physicalSize = size;
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
      specialisationsSchema,
      specVariantsSchema,
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
      theme: buildAppTheme(const ColorScheme.dark()),
      builder: (context, child) => RepaintBoundary(key: _shotKey, child: child),
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

/// A selected flag's banner waves for ever, so `pumpAndSettle` never ends
/// once one is picked: pump a bounded second instead.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (Platform.environment['UX_SHOTS'] != null) await loadAppFonts();
  });

  testWidgets('between offers the last card stays, dimmed, with a spinner',
      (tester) async {
    final container = await _open(tester, french: false);
    expect(find.byKey(const Key('offer_drawing')), findsNothing);
    expect(find.byKey(const Key('offer_title')), findsOneWidget);
    // The next offer is being drawn: no offer on the table for a moment.
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson(baseSession().toJson())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('offer_drawing')), findsOneWidget);
    expect(find.byKey(const Key('offer_title')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a long press on a banner or a crest shows the clan\u2019s details',
      (tester) async {
    await _open(tester, french: false);
    // The banner row: held, the card shows the clan; let go, it stays (v1.555).
    final hold = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('offer_banner_compact'))));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('clan_details_compact')), findsOneWidget);
    expect(find.byKey(const Key('clan_peek_alignment')), findsOneWidget);
    expect(find.byKey(const Key('clan_peek_subclans')), findsOneWidget);
    expect(find.byKey(const Key('clan_peek_intro_compact')), findsOneWidget);
    expect(
        tester
            .widget<Text>(find.byKey(const Key('clan_peek_stands_compact')))
            .textSpan!
            .toPlainText(),
        contains('Craft, restraint, blades by invitation'));
    expect(find.byKey(const Key('clan_radar_compact')), findsOneWidget);
    await _shot(tester, 'clan_details');
    await hold.up();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('clan_details_compact')), findsOneWidget,
        reason: 'it stays open when the finger lifts');
    // No "let go" line: a tap outside, or the close button, closes it.
    expect(find.textContaining('Let go'), findsNothing);
    await tester.tapAt(const Offset(4, 4));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('clan_details_compact')), findsNothing);
    // The long press did not pick the banner.
    expect(find.byKey(const Key('offer_select_hint')), findsOneWidget);

    // A crest on the ring does the same, for any clan.
    final crest = await tester
        .startGesture(tester.getCenter(find.byKey(const Key('compass_mire'))));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('clan_details_mire')), findsOneWidget);
    await crest.up();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('clan_details_mire')), findsOneWidget);
    // The close button closes it, as does the back gesture.
    await tester.tap(find.byKey(const Key('clan_details_close')));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('clan_details_mire')), findsNothing);

    // The Wayfarer is no clan: nothing opens.
    final flag = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('offer_suitor_wayfarer'))));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(ClanDetailsCard), findsNothing);
    await flag.up();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a tap outside, or the back gesture, closes the clan\u2019s details',
      (tester) async {
    await _open(tester, french: false);
    final hold = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('offer_banner_penitents'))));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byKey(const Key('clan_details_penitents')), findsOneWidget);
    await hold.up();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('clan_details_penitents')), findsOneWidget);
    // A tap on the card does not close it (it scrolls).
    await tester.tap(find.byKey(const Key('clan_details_penitents')),
        warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('clan_details_penitents')), findsOneWidget);
    // A tap outside closes it.
    await tester.tapAt(const Offset(4, 4));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('clan_details_penitents')), findsNothing);

    // Opened again: the back gesture closes it.
    final again = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('offer_banner_penitents'))));
    await tester.pump(const Duration(milliseconds: 700));
    await again.up();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('clan_details_penitents')), findsOneWidget);
    await tester.binding.handlePopRoute();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('clan_details_penitents')), findsNothing);
  });

  testWidgets('three suitors stacked at 360 px; one taken, the next kept',
      (tester) async {
    final container = await _open(tester, french: false);

    expect(find.byType(OfferDialog), findsOneWidget);
    expect(find.text('The clans come to you'), findsOneWidget);
    expect(find.textContaining('2 waiting'), findsOneWidget);
    // Three banners on top, each with what it gives and nothing more: the
    // gift's kind and name and the first standing it moves.
    for (final id in ['compact', 'penitents', 'wayfarer']) {
      expect(find.byKey(Key('offer_suitor_$id')), findsOneWidget);
    }
    expect(find.text('Skill'), findsOneWidget);
    expect(find.text('Iron Stance'), findsOneWidget);
    expect(find.text('Sign'), findsOneWidget);
    expect(find.text('Spark Letter'), findsOneWidget);
    expect(find.text('Perk'), findsOneWidget);
    expect(find.text('Keen Eye'), findsOneWidget);
    expect(find.text('+6\u00a0Compact'), findsOneWidget);
    expect(find.text('+6\u00a0Penitents'), findsOneWidget);
    // The rest is told under the compass, once a banner is picked: before,
    // only the compass and a hint.
    expect(find.text('The Emberwives of the Cinder Compact'), findsNothing);
    expect(find.textContaining('broke every hammer in the Row'), findsNothing);
    expect(find.byKey(const Key('offer_select_hint')), findsOneWidget);
    expect(find.byKey(const Key('clan_compass')), findsOneWidget);
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('offer_take_button')))
            .onPressed,
        isNull,
        reason: 'nothing is taken before a banner is picked');
    final zone = tester.getSize(find.byKey(const Key('offer_detail_zone')));

    await tester.ensureVisible(find.byKey(const Key('offer_suitor_compact')));
    await tester.tap(find.byKey(const Key('offer_suitor_compact')));
    await _settle(tester);
    expect(find.text('The Emberwives of the Cinder Compact'), findsOneWidget);
    expect(find.byKey(const Key('offer_clan_block')), findsOneWidget,
        reason: 'one block under the ring');
    expect(find.byKey(const Key('offer_standing_chip')), findsOneWidget);
    expect(find.byKey(const Key('offer_gift_icon_warrior_iron_stance')),
        findsOneWidget,
        reason: 'the gift sits in the clan block, with its icon');
    // The gift on the left of the block, the radar on the right.
    expect(
        tester.getTopLeft(find.byKey(const Key('offer_gift_block_compact'))).dx,
        lessThan(
            tester.getTopLeft(find.byKey(const Key('clan_radar_compact'))).dx));
    // The clan's words are behind the (i) button, not in the popup: it opens
    // the same card a long press shows, with what the clan says to you.
    expect(find.byKey(const Key('clan_details_compact')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('offer_charter_open')));
    await tester.tap(find.byKey(const Key('offer_charter_open')));
    await _settle(tester);
    expect(find.byKey(const Key('clan_details_compact')), findsOneWidget);
    expect(find.byKey(const Key('clan_peek_greeting_compact')), findsOneWidget,
        reason: 'the Compact\'s first words, the first time');
    expect(
        tester
            .widget<Text>(find.byKey(const Key('clan_peek_stands_compact')))
            .textSpan!
            .toPlainText(),
        contains('Craft, restraint, blades by invitation'),
        reason: 'what it stands for (Narrative\'s line)');
    await tester.tapAt(const Offset(10, 10));
    await _settle(tester);
    expect(find.byKey(const Key('clan_details_compact')), findsNothing);
    expect(tester.getSize(find.byKey(const Key('offer_banner_compact'))),
        const Size(88, 128));
    expect(tester.getSize(find.byKey(const Key('offer_banner_penitents'))),
        const Size(88, 128),
        reason: 'every banner is one size, picked or not');
    // The politics of the pick, by the relations as they stand, on the
    // crests: +6 for the Compact, +1.5 for its friends, -3 for its foe.
    Finder badge(String id, String text) => find.descendant(
        of: find.byKey(Key('compass_$id')), matching: find.text(text));
    expect(badge('compact', '+6'), findsOneWidget);
    expect(badge('vigil', '+1.5'), findsOneWidget);
    expect(badge('mire', '+1.5'), findsOneWidget);
    expect(badge('penitents', '−3'), findsOneWidget);
    expect(find.text('Alignment · no change'), findsOneWidget,
        reason: 'the alignment as a word');
    expect(find.byKey(const Key('clan_radar_compact')), findsOneWidget,
        reason: 'the clan\'s orientation, five axes');
    expect(find.byKey(const Key('offer_select_hint')), findsNothing);
    expect(tester.getSize(find.byKey(const Key('offer_detail_zone'))).width,
        zone.width);
    await _shot(tester, 'gift_compact');
    // Another row: its hall takes the same place.
    await tester.ensureVisible(find.byKey(const Key('offer_suitor_penitents')));
    await tester.tap(find.byKey(const Key('offer_suitor_penitents')));
    await _settle(tester);
    expect(find.text('The Emberwives of the Cinder Compact'), findsNothing);
    expect(
        find.text('The Ember Sisters of the Ashen Penitents'), findsOneWidget);
    // The Spark Letter, rare: its strike share 16% x 1.5.
    expect(find.textContaining('+24% damage'), findsOneWidget);
    expect(find.text('Replaces: Ember Knuckles'), findsOneWidget);
    expect(badge('penitents', '+6'), findsOneWidget);
    expect(badge('dominion', '−3'), findsOneWidget);
    expect(find.text('Alignment · toward Good'), findsOneWidget);
    await _shot(tester, 'gift_penitents');
    // The Wayfarer moves no standing.
    await tester.ensureVisible(find.byKey(const Key('offer_suitor_wayfarer')));
    await tester.tap(find.byKey(const Key('offer_suitor_wayfarer')));
    await _settle(tester);
    expect(find.text('The Wayfarer'), findsNWidgets(2),
        reason: 'the row and the hall');
    expect(find.text('No faction: standing doesn’t move.'), findsOneWidget);
    await _shot(tester, 'gift_wayfarer');
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    // Nothing is taken before a suitor is chosen, and then confirmed.
    final take = find.byKey(const Key('offer_take_button'));
    await tester.ensureVisible(find.byKey(const Key('offer_suitor_compact')));
    await tester.tap(find.byKey(const Key('offer_suitor_compact')));
    await tester.pump();
    await tester.ensureVisible(take);
    await tester.tap(take);
    await _settle(tester);
    expect(find.text('Take Iron Stance?'), findsOneWidget);
    expect(find.text('Offered by: The Emberwives of the Cinder Compact'),
        findsOneWidget);
    await tester.tap(find.byKey(const Key('offer_confirm_accept')));
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 400));
    }
    // The gift is told on a reward card first, with the standing it moved.
    expect(find.byKey(const Key('reward_card')), findsOneWidget);
    expect(find.text('A clan\u2019s gift'.toUpperCase()), findsOneWidget);
    expect(find.byKey(const Key('reward_gift_warrior_iron_stance')),
        findsOneWidget);
    expect(find.textContaining('Standing:'), findsOneWidget);
    await _shot(tester, 'gift_reward_card');
    await tester.tap(find.byKey(const Key('reward_button')));
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

    // An offer is never left for later (Wave 6): no "Later", and going
    // back leaves it open, the offer kept.
    expect(find.text('Later'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(OfferDialog), findsOneWidget);
    session = container.read(playerSessionProvider);
    expect(session.clanOffer, next);
    expect(session.pendingOffers, hasLength(1));
  });

  testWidgets('in French, with the titles worn', (tester) async {
    final container = await _open(tester, french: true);

    expect(find.text('Les clans viennent à vous'), findsOneWidget);
    expect(find.text('Compétence'), findsOneWidget);
    expect(find.text('Signe'), findsOneWidget);
    expect(find.text('Atout'), findsOneWidget);
    expect(find.text('Œil perçant'), findsOneWidget);
    expect(find.text('+6\u00a0Pacte'), findsOneWidget);
    expect(
        find.text('Choisissez un clan ci-dessous pour voir sa bannière et son '
            'don.'),
        findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('offer_suitor_compact')));
    await tester.tap(find.byKey(const Key('offer_suitor_compact')));
    await _settle(tester);
    expect(find.text('Les Charbonnières du Pacte des Cendres'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('compass_compact')),
            matching: find.text('+6')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('compass_vigil')),
            matching: find.text('+1,5')),
        findsOneWidget);
    expect(find.text('Alignement · inchangé'), findsOneWidget);
    await _shot(tester, 'gift_compact_fr');
    await tester.ensureVisible(find.byKey(const Key('offer_suitor_penitents')));
    await tester.tap(find.byKey(const Key('offer_suitor_penitents')));
    await _settle(tester);
    expect(find.text('Les Sœurs de Braise des Pénitents de Cendre'),
        findsOneWidget);
    expect(find.text('Remplace\u00a0: Poings de braise'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('offer_suitor_wayfarer')));
    await tester.tap(find.byKey(const Key('offer_suitor_wayfarer')));
    await _settle(tester);
    expect(find.text('Le Voyageur'), findsNWidgets(2));
    expect(find.text('Sans faction\u00a0: la réputation ne bouge pas.'),
        findsOneWidget);
    expect(find.text('Prendre ce don'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'fits 360 px');

    await tester.ensureVisible(find.byKey(const Key('offer_suitor_wayfarer')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('offer_suitor_wayfarer')));
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
      await tester.pump(const Duration(milliseconds: 400));
    }
    // The gift on its card, in French; the card's button goes on.
    expect(find.text('Continuer'), findsOneWidget);
    await tester.tap(find.byKey(const Key('reward_button')));
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
    // The next offer waits (it is never left for later); the test closes
    // the dialog itself to read the titles behind it.
    expect(find.text('Plus tard'), findsNothing);
    Navigator.of(tester.element(find.byType(OfferDialog))).pop();
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

  testWidgets('a tall phone shows the banners, compass and words together',
      (tester) async {
    await _open(tester, french: false, size: const Size(412, 900));
    await tester.ensureVisible(find.byKey(const Key('offer_suitor_compact')));
    await tester.tap(find.byKey(const Key('offer_suitor_compact')));
    await _settle(tester);
    expect(find.byKey(const Key('clan_compass')), findsOneWidget);
    expect(find.text('Iron Stance'), findsNWidgets(2));
    await _shot(tester, 'gift_tall');
    expect(tester.takeException(), isNull);
  });
}
