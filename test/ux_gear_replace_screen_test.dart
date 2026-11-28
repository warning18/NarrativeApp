// The gear card's one step on the floor screen (v2.10.46): a gear card taken
// asks to replace the worn piece (Replace / Keep mine / Change), or to equip
// into an empty slot (Equip / Leave them); the floor rail stays. With
// UX_SHOTS=<folder> it saves the pictures.
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
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';
import 'package:narrative_data_app/screens/tower/tower_floor_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';

import 'support/fonts.dart';

Future<void> settle(WidgetTester tester, [int n = 10]) async {
  for (var i = 0; i < n; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The weakest weapon: the piece worn in the pictures (an old friend's gift).
String _worn(TowerData data) {
  final weapons = [
    for (final MapEntry(:key, :value) in data.items.entries)
      if ((value as Map)['equipSlot'] == 'Weapon') key,
  ]..sort((a, b) => towerGearScore(a, data).compareTo(towerGearScore(b, data)));
  return weapons.first;
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  final shotKey = GlobalKey();
  final data = towerDataFromAssets();
  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });

  /// A loot table (rules 4) whose card 0 is the gear [id].
  TowerRun table(String id) {
    final start = towerStart(
        seed: 3,
        raceId: 'human',
        professionId: 'warrior',
        rules: 4,
        data: data);
    final hero = towerHeroOf(start, data);
    final run = towerAfterFight(start, data,
        won: true,
        healthLeft: hero.currentHealth,
        potionsLeft: start.potions,
        maxHealthBefore: hero.maxHealth);
    expect(run.table, TowerTableKind.loot);
    final withOffer = run.copyWith(offer: [
      TowerReward(TowerRewardKind.gear, id: id),
      ...run.offer.skip(1),
    ]);
    // The worn piece: an old friend's gift, read back from the saved run.
    final json =
        jsonDecode(jsonEncode(withOffer.toJson())) as Map<String, dynamic>;
    json['startGear'] =
        TowerReward(TowerRewardKind.gear, id: _worn(data)).toJson();
    return TowerRun.fromJson(json);
  }

  Future<ProviderContainer> boot(
      WidgetTester tester, TowerRun run, double w, String lang) async {
    await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({
      'app_language': lang,
      towerRunPrefsKey: jsonEncode(run.toJson()),
      'tutorial_enabled': false,
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(w, 860);
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

  Future<void> shot(WidgetTester tester, String name) async {
    if (shots == null) return;
    await tester.runAsync(() async {
      final b =
          shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  String weaponAbove() {
    final score = towerGearScore(_worn(data), data);
    return [
      for (final MapEntry(:key, :value) in data.items.entries)
        if ((value as Map)['equipSlot'] == 'Weapon' &&
            towerGearScore(key, data) > score)
          key
    ].first;
  }

  testWidgets('a better weapon: the replace question, Change, then Replace',
      (tester) async {
    final c = await boot(tester, table(weaponAbove()), 412, 'en');
    await tester.tap(find.byKey(const Key('tower_card_0')));
    await settle(tester, 4);
    await tester.ensureVisible(find.byKey(const Key('tower_take')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tower_take')));
    await settle(tester, 8);
    expect(find.byKey(const Key('tower_gear_replace')), findsOneWidget);
    expect(find.byKey(const Key('tower_gear_replace_change')), findsOneWidget);
    expect(find.textContaining('Replace your'), findsOneWidget);
    await shot(tester, 'gear-replace-412');
    // Change goes back to the cards.
    await tester.tap(find.byKey(const Key('tower_gear_replace_change')));
    await settle(tester, 8);
    expect(find.byKey(const Key('tower_gear_replace')), findsNothing);
    expect(find.byKey(const Key('tower_card_0')), findsOneWidget);
    // Replace: the piece is worn.
    await tester.tap(find.byKey(const Key('tower_card_0')));
    await settle(tester, 4);
    await tester.ensureVisible(find.byKey(const Key('tower_take')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tower_take')));
    await settle(tester, 8);
    await tester.tap(find.byKey(const Key('tower_gear_replace_yes')));
    await settle(tester, 12);
    final after = c.read(towerProvider).value!.run!;
    expect(after.pendingGear, isNull);
    expect(towerHeroOf(after, data).equippedItemIds, contains(weaponAbove()));
  });

  testWidgets('Keep mine: the worn piece stays', (tester) async {
    final c = await boot(tester, table(weaponAbove()), 360, 'fr');
    final c0 = tester.getRect(find.byKey(const Key('tower_card_0')));
    await tester.tapAt(Offset(c0.left + 6, c0.center.dy));
    await settle(tester, 4);
    await tester.ensureVisible(find.byKey(const Key('tower_take')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tower_take')));
    await settle(tester, 8);
    expect(find.byKey(const Key('tower_gear_replace')), findsOneWidget);
    await shot(tester, 'gear-replace-fr-360');
    await tester.tap(find.byKey(const Key('tower_gear_replace_keep')));
    await settle(tester, 12);
    final after = c.read(towerProvider).value!.run!;
    expect(after.pendingGear, isNull);
    expect(towerHeroOf(after, data).equippedItemIds,
        isNot(contains(weaponAbove())));
  });

  testWidgets('an empty slot: Equip / Leave them', (tester) async {
    String? foot;
    for (final MapEntry(:key, :value) in data.items.entries) {
      if ((value as Map)['equipSlot'] == 'Foot' &&
          towerHeroOf(table(weaponAbove()), data).equippedBySlot['Foot'] ==
              null) {
        foot = key;
        break;
      }
    }
    expect(foot, isNotNull);
    await boot(tester, table(foot!), 412, 'en');
    await tester.tap(find.byKey(const Key('tower_card_0')));
    await settle(tester, 4);
    await tester.ensureVisible(find.byKey(const Key('tower_take')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tower_take')));
    await settle(tester, 8);
    expect(find.textContaining('Equip the'), findsOneWidget);
    expect(find.text('Leave them'), findsOneWidget);
    await shot(tester, 'gear-equip-empty-412');
  });
}
