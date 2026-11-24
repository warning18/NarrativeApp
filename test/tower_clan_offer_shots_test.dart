// The clans' offer as built (v2.6.0, docs/simulation/tower-clan-offers.md):
// three clans' gifts on the cards (each its clan, what it moves and the
// standing), and, with a clan at the oath's step, its oath. English at
// 412 px, French at 360 px, with no overflow; pictures with
// UX_SHOTS=<folder>. UX restyles the cards; this is the look as built.
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
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final data = towerDataFromAssets();
  final start =
      towerStart(seed: 5, raceId: 'human', professionId: 'warrior', data: data);
  final shots = Platform.environment['UX_SHOTS'];

  // The gifts of the three start clans; and a run whose Mire stands at the
  // oath's step (three of its gifts taken), its oath on the table.
  final gifts = start.copyWith(status: TowerStatus.choosing, offer: const [
    TowerReward(TowerRewardKind.skill, id: 'second_wind', clan: 'mire'),
    TowerReward(TowerRewardKind.skill, id: 'shadow_step', clan: 'dominion'),
    TowerReward(TowerRewardKind.skill, id: 'void_blast', clan: 'penitents'),
  ]);
  final oath = start.copyWith(
    floor: 4,
    status: TowerStatus.choosing,
    taken: {
      ...start.taken,
      for (var f = 1; f <= 3; f++)
        f: const TowerReward(TowerRewardKind.skill,
            id: 'human_resolve', clan: 'mire'),
    },
    offer: const [
      TowerReward(TowerRewardKind.clanOath, id: 'mire'),
      TowerReward(TowerRewardKind.skill, id: 'shadow_step', clan: 'dominion'),
    ],
  );

  testWidgets('the clans\' offer and the oath, English and French',
      (tester) async {
    await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    for (final (lang, width) in [
      (AppLanguage.en, 412.0),
      (AppLanguage.fr, 360.0)
    ]) {
      for (final (name, run) in [('gifts', gifts), ('oath', oath)]) {
        SharedPreferences.setMockInitialValues({
          'app_language': lang.name,
          'tower_run_v1': jsonEncode(run.toJson()),
          'tutorial_enabled': false,
        });
        usePhone(tester, Size(width, 900));
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container.read(appLanguageProvider.notifier).setLanguage(lang);
        final key = GlobalKey();
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
                key: UniqueKey(),
                theme: buildAppTheme(container
                    .read(appPaletteProvider)
                    .schemeFor(Brightness.light)),
                home: const TowerFloorScreen()),
          ),
        ));
        Future<void> settle([int n = 30]) async {
          for (var i = 0; i < n; i++) {
            await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 20)));
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        await settle();
        for (var i = 0;
            i < 20 && find.byKey(const Key('tower_card_0')).evaluate().isEmpty;
            i++) {
          final level = find.byType(LevelUpScreen);
          if (level.evaluate().isNotEmpty) {
            Navigator.of(tester.element(level)).pop();
          }
          final take = find.byKey(const Key('loot_sheet_take'));
          if (take.evaluate().isNotEmpty) await tester.tap(take);
          await settle(5);
        }
        final error = tester.takeException();
        if (shots != null) {
          Directory(shots).createSync(recursive: true);
          await tester.runAsync(() async {
            final b = key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            final image = await b.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            File('$shots/tower-clans-$name-${lang.name}-${width.toInt()}.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
          });
        }
        expect(error, isNull, reason: '$name ${lang.name}');
        expect(find.byKey(const Key('tower_card_0')), findsOneWidget,
            reason: '$name ${lang.name}');
        final fr = lang == AppLanguage.fr;
        if (name == 'gifts') {
          expect(find.byKey(const Key('tower_offer_frame')), findsOneWidget);
          expect(find.textContaining('+$towerGiftStanding'), findsWidgets);
        } else {
          expect(find.textContaining('$towerOathStep/$towerOathStep'),
              findsWidgets);
        }
        expect(find.byKey(const Key('tower_refuse')), findsOneWidget,
            reason: fr ? 'Plus tard' : 'Not now');
      }
    }
  });
}
