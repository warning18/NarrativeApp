// PICTURES (UX_SHOTS=<folder>): Art's cut-paper set on the real Tower
// screens at 412 and 360 wide: a band floor, a warden floor, a boss floor, the
// shop, the clan offer and a boon's reward cards (the tarot vignettes).
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
import 'package:narrative_data_app/data/tower/tower_events.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final data = towerDataFromAssets();
  final start =
      towerStart(seed: 5, raceId: 'human', professionId: 'warrior', data: data);

  final gifts = start.copyWith(status: TowerStatus.choosing, offer: const [
    TowerReward(TowerRewardKind.skill, id: 'second_wind', clan: 'mire'),
    TowerReward(TowerRewardKind.skill, id: 'shadow_step', clan: 'dominion'),
    TowerReward(TowerRewardKind.skill, id: 'void_blast', clan: 'penitents'),
  ]);
  final boon =
      start.copyWith(floor: 6, status: TowerStatus.choosing, offer: const [
    TowerReward(TowerRewardKind.skill, id: 'fireball'),
    TowerReward(TowerRewardKind.die, id: 'flame_die'),
    TowerReward(TowerRewardKind.spell, id: 'spell_ember_wave'),
  ]);
  final boon2 =
      start.copyWith(floor: 7, status: TowerStatus.choosing, offer: const [
    TowerReward(TowerRewardKind.skill, id: 'mage_frost_nova'),
    TowerReward(TowerRewardKind.skill, id: 'radiant_judgment'),
    TowerReward(TowerRewardKind.spell, id: 'spell_mending_light'),
  ]);

  TowerRun? stall;
  for (var seed = 1; seed < 400 && stall == null; seed++) {
    final run = towerStart(
        seed: seed,
        raceId: 'human',
        professionId: 'warrior',
        events: towerEventsLive,
        data: data);
    final on =
        run.copyWith(floor: 10, health: 40, status: TowerStatus.climbing);
    final landing = towerPick(
        towerAfterFight(on, data, won: true, healthLeft: 40), data, null);
    if (towerStoreKindOf(landing) == TowerEventKind.merchant) {
      stall = landing.copyWith(coins: 30, health: 5);
    }
  }

  final scenes = <(String, TowerRun?)>[
    ('band1-floor', start),
    ('band2-floor', start.copyWith(floor: 13)),
    ('ward-floor', start.copyWith(floor: 5)),
    ('boss-floor', start.copyWith(floor: 10)),
    ('shop', stall),
    ('clan-offer', gifts),
    ('boon-reward', boon),
    ('boon-reward-2', boon2),
  ];

  for (final width in (Platform.environment['UX_WIDTHS'] ?? '412,360')
      .split(',')
      .map(double.parse)) {
    testWidgets('cut-paper screens at ${width.toInt()}', skip: shots == null,
        (tester) async {
      await tester.runAsync(loadAppFonts);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      for (final (name, run) in scenes) {
        if (run == null) continue;
        final only = Platform.environment['UX_SCENES'];
        if (only != null && !only.split(',').contains(name)) continue;
        SharedPreferences.setMockInitialValues({
          'app_language': 'en',
          'tower_run_v1': jsonEncode(run.toJson()),
          'tutorial_enabled': false,
        });
        usePhone(tester, Size(width, 900));
        final container = ProviderContainer();
        addTearDown(container.dispose);
        await container
            .read(appLanguageProvider.notifier)
            .setLanguage(AppLanguage.en);
        final key = GlobalKey();
        await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: RepaintBoundary(
            key: key,
            child: MaterialApp(
                key: UniqueKey(),
                debugShowCheckedModeBanner: false,
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
        for (var i = 0; i < 6; i++) {
          final level = find.byType(LevelUpScreen);
          if (level.evaluate().isNotEmpty) {
            Navigator.of(tester.element(level)).pop();
          }
          final take = find.byKey(const Key('loot_sheet_take'));
          if (take.evaluate().isNotEmpty) await tester.tap(take);
          await settle(5);
        }
        if (name.contains('reward') || name == 'clan-offer') {
          for (var i = 0;
              i < 40 &&
                  find.byKey(const Key('tower_card_1')).evaluate().isEmpty;
              i++) {
            await settle(3);
          }
          final card = find.byKey(const Key('tower_card_1'));
          if (card.evaluate().isNotEmpty) {
            await tester.tap(card);
            await settle(5);
          }
        }
        await tester.runAsync(() async {
          final b =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await b.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory(shots!).createSync(recursive: true);
          File('$shots/$name-${width.toInt()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
        expect(tester.takeException(), isNull, reason: name);
      }
    }, timeout: const Timeout(Duration(minutes: 6)));
  }
}
