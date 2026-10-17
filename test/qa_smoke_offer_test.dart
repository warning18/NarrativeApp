// QA: the clans' offer hall with a risky gift (v1.477) on a phone, with the
// app's own fonts: the banner picked (the risky badge, the clan's words, the
// odds), the confirm (the odds again), and the reward card after the die went
// badly and well. 360 x 740 and 320 x 568, English and French, no overflow
// (qa_smoke_harness.dart; SMOKE_SHOTS=<folder> for the pictures).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/offer_dialog.dart';

import 'player_session_provider_test.dart' show baseSession;
import 'qa_smoke_harness.dart';

const OfferTicket _level = OfferTicket(source: OfferSource.level);

/// A risky gift whose die went [roll] (1 is the worst, 20 the best).
ClanOffer _offer(int roll) => ClanOffer(ticket: _level, suitors: [
      const Suitor(
        factionId: 'compact',
        subclanId: 'emberwives',
        gift: OfferGift(
            kind: GiftKind.skill,
            id: 'warrior_iron_stance',
            rarity: SignRarity.rare),
      ),
      const Suitor(
        factionId: 'penitents',
        subclanId: 'ember_sisters',
        gift: OfferGift(
            kind: GiftKind.sign,
            id: 'lettered_strike_spark_letter',
            rarity: SignRarity.epic),
      ).asRisky(roll),
      const Suitor(
        factionId: wayfarerId,
        gift: OfferGift(kind: GiftKind.perk, id: 'keenEye'),
      ),
    ]);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  testWidgets('the offer hall with a risky gift reads on a phone, EN and FR',
      (tester) async {
    final shots = Platform.environment['SMOKE_SHOTS'];
    final overflows = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('overflowed')) {
        overflows.add(details.exceptionAsString().split('\n').first);
      } else {
        previous?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = previous);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(appLanguageProvider);
    container.read(playerSessionProvider);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    final key = GlobalKey();
    tester.view.physicalSize = smokeSizes.first;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(ColorScheme.fromSeed(
            seedColor: Colors.amber, brightness: Brightness.dark)),
        builder: (context, child) => RepaintBoundary(key: key, child: child),
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => ElevatedButton(
              key: const Key('open'),
              onPressed: () => showOfferIfWaiting(context, ref),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));
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

    Future<void> pumpFor(int ms) async {
      for (var i = 0; i < ms ~/ 100; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> check(String label) async {
      expect(overflows, isEmpty, reason: '$label: ${overflows.join('; ')}');
      if (shots == null) return;
      final bytes = await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        return image.toByteData(format: ui.ImageByteFormat.png);
      });
      Directory(shots).createSync(recursive: true);
      File('$shots/offer_$label.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    }

    for (final size in smokeSizes) {
      tester.view.physicalSize = size;
      for (final french in [false, true]) {
        for (final roll in [1, 20]) {
          final label = '${size.width.toInt()}_${french ? 'fr' : 'en'}'
              '_roll$roll';
          overflows.clear();
          await tester.runAsync(() => container
              .read(appLanguageProvider.notifier)
              .setLanguage(french ? AppLanguage.fr : AppLanguage.en));
          await tester.runAsync(() => container
              .read(playerSessionProvider.notifier)
              .loadSession(PlayerSession.fromJson({
                ...baseSession().toJson(),
                'raceId': 'human',
                'professionId': 'warrior',
              }).copyWith(
                pendingOffers: const [_level],
                clanOffer: _offer(roll),
              )));
          await tester.tap(find.byKey(const Key('open')));
          for (var i = 0; i < 3; i++) {
            await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 50)));
            await tester.pumpAndSettle();
          }
          expect(
              find.byKey(const Key('offer_suitor_penitents')), findsOneWidget,
              reason: label);
          await tester
              .ensureVisible(find.byKey(const Key('offer_suitor_penitents')));
          await tester.tap(find.byKey(const Key('offer_suitor_penitents')));
          await pumpFor(1000);
          expect(find.byKey(const Key('offer_risky_badge')), findsOneWidget,
              reason: '$label: the risky badge');
          await check('${label}_picked');

          await tester.tap(find.byKey(const Key('offer_take_button')));
          await pumpFor(600);
          expect(
              find.byKey(const Key('offer_confirm_risky_odds')), findsOneWidget,
              reason: '$label: the odds in the confirm');
          await check('${label}_confirm');

          await tester.tap(find.byKey(const Key('offer_confirm_accept')));
          await pumpFor(1500);
          await check('${label}_reward');

          // The reward card closed, back to the first screen.
          await tester.tap(find.text(french ? 'Continuer' : 'Continue'));
          await pumpFor(800);
        }
      }
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
