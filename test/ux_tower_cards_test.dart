// v2.3 (UX-2): the Tower's cards as tarot cards (the user's pick B), in the
// real app: floor 5 won (a boon floor: a skill, a die and a spell), the
// spoils taken, then the offer. No overflow at 320 and 360, EN and FR, text
// x1.3 (the rows are the fallback), a pick round trip, and pictures with
// UX_SHOTS=<folder>.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';
import 'package:narrative_data_app/screens/tower/tower_tarot_card.dart';

import 'support/fonts.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });

  for (final cfg in [
    // (size, language, text, tarot when the cards open, tarot once the rail
    // has given its room)
    (const Size(360, 780), AppLanguage.en, 1.0, true, true),
    (const Size(412, 860), AppLanguage.en, 1.0, true, true),
    (const Size(320, 640), AppLanguage.en, 1.0, false, true),
    (const Size(360, 780), AppLanguage.fr, 1.3, false, false),
    (const Size(320, 640), AppLanguage.fr, 1.3, false, false),
  ]) {
    final name = '${cfg.$1.width.toInt()}-${cfg.$2.name}-x${cfg.$3}';
    testWidgets(
        'the Tower cards $name: ${cfg.$4 ? 'tarot' : 'rows'}, then '
        '${cfg.$5 ? 'tarot' : 'rows'}', (tester) async {
      await tester.runAsync(loadAppFonts);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      final data = towerDataFromAssets();
      final at = towerStart(
              seed: 5, raceId: 'human', professionId: 'warrior', data: data)
          .copyWith(floor: 5);
      final offer = towerOfferFor(
        seed: at.seed,
        floor: 5,
        hero: towerHeroView(at, towerHeroOf(at, data)),
        clanPool: at.oathsLeft,
        items: data.items,
        dice: data.dice,
        skills: data.skills,
        spells: data.spells,
      );
      var run = at.copyWith(status: TowerStatus.choosing, offer: offer);
      while (towerPendingPicks(run) > 0) {
        final picks =
            towerStatPickOffer(run, data, hero: towerHeroOf(run, data));
        if (picks.isEmpty) break;
        run = towerTakeStatPick(run, data, 0, offer: picks);
      }
      SharedPreferences.setMockInitialValues({
        towerRunPrefsKey: jsonEncode(run.toJson()),
        'tutorial_enabled': false,
      });
      final key = GlobalKey();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = cfg.$1;
      tester.platformDispatcher.textScaleFactorTestValue = cfg.$3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(RepaintBoundary(
          key: key, child: const ProviderScope(child: MyApp())));

      Future<void> settle([int n = 8]) async {
        for (var i = 0; i < n; i++) {
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 40)));
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      Future<void> shoot(String file) async {
        if (shots == null) return;
        Directory(shots).createSync(recursive: true);
        await tester.runAsync(() async {
          final render =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/$file-$name.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }

      Future<void> tapKey(String k) async {
        final f = find.byKey(Key(k));
        await tester.ensureVisible(f.first);
        await tester.pump();
        await tester.tap(f.first);
        await settle(10);
      }

      await settle(10);
      final c =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      await tester.runAsync(
          () => c.read(appLanguageProvider.notifier).setLanguage(cfg.$2));
      await settle(6);
      await tapKey('menu_tower');
      await tapKey('tower_continue');
      await tapKey('loot_sheet_take');
      expect(find.byKey(const Key('tower_card_0')), findsOneWidget);
      void kinds(bool tarot, String when) {
        expect(find.byType(TowerTarotCard),
            tarot ? findsNWidgets(offer.length) : findsNothing,
            reason: '$name $when: ${tarot ? 'tarot' : 'the rows'}');
        expect(find.byType(TowerRowCard),
            tarot ? findsNothing : findsNWidgets(offer.length),
            reason: '$name $when');
        expect(tester.takeException(), isNull,
            reason: 'no overflow: $name $when');
      }

      kinds(cfg.$4, 'as the cards open');
      await shoot('cards-open');
      // The head has walked: the rail gives its room to the cards.
      await settle(18);
      kinds(cfg.$5, 'with the rail gone');
      await shoot('cards');
      // A pick round trip: hold the second card, take it: the cards go and
      // the run moves on.
      await tester.tap(find.byKey(const Key('tower_card_1')));
      await settle(4);
      expect(tester.takeException(), isNull);
      await shoot('cards-held');
      await tapKey('tower_take');
      expect(find.byKey(const Key('tower_card_0')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
