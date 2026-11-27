// Rules 4's screens: the gamble card (face down, "No turning back", the
// reveal), the stat-pick card and its stat choice, the pedlar's button and the
// Hex mark on the floor.
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
import 'package:narrative_data_app/data/tower/tower_coins.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_rules4.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';
import 'package:narrative_data_app/screens/tower/tower_styled_card.dart';

import 'support/fonts.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final shotKey = GlobalKey();
  Future<void> shot(WidgetTester tester, String name) async {
    if (shots == null) return;
    await tester.runAsync(() async {
      final b =
          shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  final data = towerDataFromAssets();
  TowerRun base({List<String> perks = const []}) => towerStart(
      seed: 5,
      raceId: 'human',
      professionId: 'warrior',
      perks: perks,
      rules: 4,
      data: data);

  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });

  Future<ProviderContainer> boot(WidgetTester tester, TowerRun run) async {
    await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({
      'app_language': 'en',
      towerRunPrefsKey: jsonEncode(run.toJson()),
      'tutorial_enabled': false,
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
        child: RepaintBoundary(
            key: shotKey,
            child: const MaterialApp(
                debugShowCheckedModeBanner: false, home: TowerFloorScreen()))));
    await settle(tester, 30);
    return ProviderScope.containerOf(
        tester.element(find.byType(TowerFloorScreen)));
  }

  testWidgets('the pedlar sells a potion for 4 coins on a landing',
      (tester) async {
    final run = base(perks: const [towerPerkPurse]);
    final c = await boot(tester, run);
    expect(run.coins, greaterThanOrEqualTo(towerPedlarPrice));
    expect(find.byKey(const Key('tower_buy_potion')), findsOneWidget);
    expect(find.text('Buy a potion (4 coins)'), findsOneWidget);
    final coins = c.read(towerProvider).value!.run!.coins;
    final potions = c.read(towerProvider).value!.run!.potions;
    await tester.tap(find.byKey(const Key('tower_buy_potion')));
    await settle(tester, 6);
    final after = c.read(towerProvider).value!.run!;
    expect(after.coins, coins - towerPedlarPrice);
    expect(after.potions, potions + 1);
  });

  testWidgets('no pedlar without the Purse perk', (tester) async {
    await boot(tester, base());
    expect(find.byKey(const Key('tower_buy_potion')), findsNothing);
  });

  testWidgets('a hexed floor wears the Hex mark', (tester) async {
    final run = base().copyWith(floor: 2, gambles: {
      1: [towerHexMark]
    });
    await boot(tester, run);
    expect(find.text('Hex: foes x1.15'), findsOneWidget);
  });

  testWidgets('the gamble card: No turning back, then the reveal',
      (tester) async {
    final run = base().copyWith(
        status: TowerStatus.choosing,
        table: TowerTableKind.loot,
        gambleOutcome: TowerGambleOutcome.dud,
        offer: const [
          TowerReward(TowerRewardKind.purse, amount: 3),
          TowerReward(TowerRewardKind.gamble),
        ]);
    await boot(tester, run);
    // Its face is down: a real card back, no words, never what it is.
    expect(find.byType(TowerCardBack), findsOneWidget);
    expect(find.text('Dud'), findsNothing);
    await shot(tester, 'r4-gamble-table');
    await tester.tap(find.byKey(const Key('tower_card_1')));
    await settle(tester, 4);
    // Held, its words under the fan: a hero who reads nothing gets the plain line.
    expect(find.text('A card laid face down'), findsWidgets);
    await tester.tap(find.byKey(const Key('tower_take')));
    await settle(tester, 6);
    expect(find.byKey(const Key('tower_pick_confirm')), findsOneWidget);
    await shot(tester, 'r4-gamble-confirm');
    expect(find.text('No turning back'), findsOneWidget);
    expect(find.text('Take it'), findsOneWidget);
    expect(find.text('Look again'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tower_confirm')));
    // The card turns over: its back, edge-on, then the outcome card.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await shot(tester, 'r4-gamble-flip');
    await settle(tester, 10);
    await shot(tester, 'r4-gamble-reveal');
    expect(find.byKey(const Key('tower_gamble_reveal')), findsOneWidget);
    expect(find.text('Dud'), findsOneWidget);
  });

  testWidgets('an elf (Perception 5) reads what the card is', (tester) async {
    final elf = towerStart(
        seed: 5, raceId: 'elf', professionId: 'warrior', rules: 4, data: data);
    final run = elf.copyWith(
        status: TowerStatus.choosing,
        table: TowerTableKind.loot,
        gambleOutcome: TowerGambleOutcome.wound,
        offer: const [
          TowerReward(TowerRewardKind.purse, amount: 3),
          TowerReward(TowerRewardKind.gamble),
        ]);
    expect(
        towerGambleHintOf(run, towerHeroOf(run, data)), TowerGambleHint.kind);
    await boot(tester, run);
    await shot(tester, 'r4-gamble-read');
    // Its name on a plate at the foot, a red band at the top (bad).
    expect(find.byType(TowerCardBack), findsOneWidget);
    expect(
        tester.widget<TowerCardBack>(find.byType(TowerCardBack)).name, 'Wound');
    expect(find.text('Wound'), findsWidgets);
  });

  testWidgets('the stat-pick card: take it, choose a stat, confirm',
      (tester) async {
    final run = base().copyWith(
        status: TowerStatus.choosing,
        table: TowerTableKind.levelUp,
        offer: const [
          TowerReward(TowerRewardKind.statPick),
          TowerReward(TowerRewardKind.skill, id: 'fireball'),
        ]);
    final c = await boot(tester, run);
    final before = towerHeroOf(run, data).dexterity;
    await shot(tester, 'r4-statpick-table');
    await tester.tap(find.byKey(const Key('tower_card_0')));
    await settle(tester, 4);
    await tester.tap(find.byKey(const Key('tower_take')));
    await settle(tester, 6);
    expect(find.byKey(const Key('tower_stat_choice')), findsOneWidget);
    expect(find.text('Choose a stat'.toUpperCase()), findsOneWidget);
    // Confirm waits for a stat.
    final confirm = tester
        .widget<FilledButton>(find.byKey(const Key('tower_stat_confirm')));
    expect(confirm.onPressed, isNull);
    await tester.tap(find.byKey(const Key('tower_stat_dexterity')));
    await settle(tester, 4);
    await shot(tester, 'r4-statpick-choice');
    expect(find.byKey(const Key('tower_stat_preview')), findsOneWidget);
    await tester.tap(find.byKey(const Key('tower_stat_confirm')));
    await settle(tester, 8);
    final after = c.read(towerProvider).value!.run!;
    expect(find.byKey(const Key('tower_stat_choice')), findsNothing);
    expect(towerHeroOf(after, data).dexterity, before + 1);
  });

  testWidgets('Change on the stat choice goes back to the cards',
      (tester) async {
    final run = base().copyWith(
        status: TowerStatus.choosing,
        table: TowerTableKind.levelUp,
        offer: const [
          TowerReward(TowerRewardKind.statPick),
          TowerReward(TowerRewardKind.skill, id: 'fireball'),
        ]);
    await boot(tester, run);
    await tester.tap(find.byKey(const Key('tower_card_0')));
    await settle(tester, 4);
    await tester.tap(find.byKey(const Key('tower_take')));
    await settle(tester, 6);
    await tester.tap(find.byKey(const Key('tower_change')));
    await settle(tester, 6);
    expect(find.byKey(const Key('tower_stat_choice')), findsNothing);
    expect(find.byKey(const Key('tower_card_0')), findsOneWidget);
  });
}

Future<void> settle(WidgetTester tester, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}
