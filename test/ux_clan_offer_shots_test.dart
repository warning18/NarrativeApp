// Pictures of the clan offer (UX_SHOTS=<folder>), nothing asserted: the hand,
// the rows, a mixed offer, 360 and 412 wide.
//
// (the offer on a 360-px phone: the offer dialog -- three banners on
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
import 'package:narrative_data_app/widgets/offer_dialog.dart';

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
    {required ClanOffer offer,
    required bool french,
    Size size = const Size(360, 860),
    bool nested = false}) async {
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
        clanOffer: offer,
        heldTitleIds: const ['coal_guard', 'the_marked'],
        activeTitleId: 'coal_guard',
        // The Inquisition's foe: "the Marked" holds.
        politics: const PoliticsState(marks: {'inquisition': SubclanMark.foe}),
      )));

  final home = Scaffold(
    body: Consumer(
      builder: (context, ref, _) => ListView(
        children: [
          ElevatedButton(
            key: const Key('open'),
            onPressed: () => showOfferIfWaiting(context, ref),
            child: const Text('Open'),
          ),
        ],
      ),
    ),
  );
  // [nested]: the hero with the offer is held by a scope below the app's
  // (as the Tower's detached session is); the app's own hero has none.
  final root = nested
      ? ProviderContainer(overrides: [
          playerSessionProvider.overrideWith((ref) =>
              PlayerSessionNotifier.detached(
                  PlayerSession.fromJson(baseSession().toJson()))),
        ])
      : container;
  if (nested) addTearDown(root.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: root,
    child: MaterialApp(
      theme: buildAppTheme(const ColorScheme.dark()),
      builder: (context, child) => RepaintBoundary(key: _shotKey, child: child),
      home: nested
          ? UncontrolledProviderScope(container: container, child: home)
          : home,
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

const ClanOffer _hand = ClanOffer(ticket: _level, suitors: [
  Suitor(
    factionId: 'compact',
    subclanId: 'emberwives',
    gift: OfferGift(
        kind: GiftKind.skill,
        id: 'warrior_iron_stance',
        rarity: SignRarity.rare),
  ),
  Suitor(
    factionId: 'penitents',
    subclanId: 'ember_sisters',
    gift: OfferGift(
        kind: GiftKind.sign,
        id: 'lettered_strike_spark_letter',
        rarity: SignRarity.epic),
  ),
  Suitor(
    factionId: 'vigil',
    gift: OfferGift(
        kind: GiftKind.sign,
        id: 'lettered_strike_spark_letter',
        rarity: SignRarity.heroic),
  ),
]);

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (shots != null) await loadAppFonts();
  });

  Future<void> run(WidgetTester tester, String name, ClanOffer offer,
      {required double width, List<String> taps = const []}) async {
    await _open(tester, offer: offer, french: false, size: Size(width, 900));
    await _shot(tester, '$name-rest');
    for (final id in taps) {
      await tester.ensureVisible(find.byKey(Key('offer_suitor_$id')));
      final f = find.byKey(Key('offer_suitor_$id'));
      if (id == 'wayfarer') {
        await tester.tap(f); // a row
      } else {
        // A card in a fan: its left strip is the part nothing covers.
        await tester.tapAt(tester.getTopLeft(f) + const Offset(22, 110));
      }
      await _settle(tester);
      await _shot(tester, '$name-$id');
    }
  }

  for (final width in [360.0, 412.0]) {
    testWidgets('mixed $width', skip: shots == null, (tester) async {
      await run(tester, 'mixed-${width.toInt()}', _offer,
          width: width, taps: ['compact', 'wayfarer']);
    });
    testWidgets('tiers $width', skip: shots == null, (tester) async {
      await run(tester, 'tiers-${width.toInt()}', _hand,
          width: width, taps: ['penitents']);
    });
  }
}
