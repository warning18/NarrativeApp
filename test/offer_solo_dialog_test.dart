// A gift offered alone on the phone (Wave 1, UX's one-card sheet): a
// specialisation and a Sworn boon, English and French, at 360 x 740 and
// 320 x 568 (the banner at half size when the screen is short), with no
// overflow; "Not now" brings the usual three cards without that gift,
// "Accept" takes it. Pictures with UX_SHOTS=<folder>.
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
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/offer_dialog.dart';

import 'player_session_provider_test.dart' show baseSession;
import 'support/fonts.dart';

const OfferTicket _level = OfferTicket(source: OfferSource.level);

const Suitor _spec = Suitor(
  factionId: 'dominion',
  gift: OfferGift(
      kind: GiftKind.spec, id: 'lantern_vanguard', rarity: SignRarity.epic),
);

const Suitor _boon = Suitor(
  factionId: 'dominion',
  greetingIndex: 1,
  gift: OfferGift(
      kind: GiftKind.sworn, id: 'dominion', rarity: SignRarity.heroic),
);

final _shotKey = GlobalKey();

Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) return;
  Directory(dir).createSync(recursive: true);
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<ProviderContainer> _open(WidgetTester tester, Suitor alone,
    {required bool french, required Size size}) async {
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
  // Sworn to the Dominion: its boon is due, and so is its specialisation.
  final base = PlayerSession.fromJson({
    ...baseSession().toJson(),
    'raceId': 'human',
    'professionId': 'warrior',
    'unlockedSkillIds': ['warrior_shield_bash', 'bulwark_stance'],
  });
  final data = ClanData.fromTables(
    factions: container.read(gameDbProvider(factionsSchema)).value!,
    subclans: container.read(gameDbProvider(subclansSchema)).value!,
    relations: container.read(gameDbProvider(relationsSchema)).value!,
  );
  final politics =
      setStandingValue(base.politics, 'dominion', 70, 'edit', data: data).state;
  await tester.runAsync(() => notifier.loadSession(base.copyWith(
        politics: politics,
        pendingOffers: const [_level],
        clanOffer: ClanOffer(ticket: _level, suitors: [alone], solo: true),
      )));

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.light)),
      builder: (context, child) => RepaintBoundary(key: _shotKey, child: child),
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) => Center(
            child: ElevatedButton(
              key: const Key('open'),
              onPressed: () => showOfferIfWaiting(context, ref),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.byKey(const Key('open')));
  for (var i = 0; i < 3; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 200));
  }
  return container;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (Platform.environment['UX_SHOTS'] != null) await loadAppFonts();
  });

  for (final size in const [Size(360, 740), Size(320, 568)]) {
    for (final french in [false, true]) {
      for (final (kind, alone) in [('spec', _spec), ('boon', _boon)]) {
        final lang = french ? 'fr' : 'en';
        final w = size.width.toInt();
        testWidgets('alone: $kind, $lang, $w x ${size.height.toInt()}',
            (tester) async {
          await _open(tester, alone, french: french, size: size);
          expect(tester.takeException(), isNull);
          expect(find.byKey(const Key('offer_solo')), findsOneWidget);
          expect(find.byKey(const Key('offer_take_button')), findsNothing);
          expect(find.text(french ? 'Accepter' : 'Accept'), findsOneWidget);
          expect(find.text(french ? 'Plus tard' : 'Not now'), findsOneWidget);
          expect(
              find.byKey(Key(size.height < 640
                  ? 'offer_solo_banner_half'
                  : 'offer_solo_banner_full')),
              findsOneWidget);
          // Both buttons on screen, not scrolled away.
          for (final key in ['offer_solo_accept', 'offer_solo_decline']) {
            final box = tester.getRect(find.byKey(Key(key)));
            expect(box.bottom, lessThanOrEqualTo(size.height), reason: key);
          }
          await _shot(tester, 'solo-$kind-$lang-$w');
        });
      }
    }
  }

  testWidgets('"Not now" brings the usual three cards, without the gift',
      (tester) async {
    final container =
        await _open(tester, _boon, french: false, size: const Size(360, 740));
    await tester.tap(find.byKey(const Key('offer_solo_decline')));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
    final offer = container.read(playerSessionProvider).clanOffer!;
    expect(offer.solo, isFalse);
    expect(offer.suitors, hasLength(3));
    expect(
        offer.suitors.where(
            (s) => s.gift.kind == GiftKind.sworn && s.gift.id == 'dominion'),
        isEmpty);
    expect(find.byKey(const Key('offer_solo')), findsNothing);
    expect(find.byKey(const Key('offer_take_button')), findsOneWidget);
    expect(container.read(playerSessionProvider).pendingOffers, [_level]);
  });

  testWidgets('"Accept" takes the specialisation; the offer is spent',
      (tester) async {
    final container =
        await _open(tester, _spec, french: false, size: const Size(360, 740));
    await tester.tap(find.byKey(const Key('offer_solo_accept')));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    final session = container.read(playerSessionProvider);
    expect(session.specIds, contains('lantern_vanguard'));
    expect(session.pendingOffers, isEmpty);
  });
}
