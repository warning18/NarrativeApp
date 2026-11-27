// PICTURE (UX_SHOTS=<folder>): the built oath moment in the real app.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_hero.dart';
import 'package:narrative_data_app/data/tower/tower_rewards.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_tables.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';

import 'support/fonts.dart';

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });

  testWidgets('the oath moment in the real app', skip: shots == null,
      (tester) async {
    WidgetsApp.debugAllowBannerOverride = false;
    await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    final data = towerDataFromAssets();
    final at = towerStart(
        seed: 5, raceId: 'human', professionId: 'warrior', data: data);
    var run = at.copyWith(
        status: TowerStatus.choosing,
        table: TowerTableKind.oath,
        floor: 3,
        offer: [const TowerReward(TowerRewardKind.clanOath, id: 'mire')]);
    while (towerPendingPicks(run) > 0) {
      final picks = towerStatPickOffer(run, data, hero: towerHeroOf(run, data));
      if (picks.isEmpty) break;
      run = towerTakeStatPick(run, data, 0, offer: picks);
    }
    SharedPreferences.setMockInitialValues({
      towerRunPrefsKey: jsonEncode(run.toJson()),
      'tutorial_enabled': false,
      'app_language': 'en',
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 860);
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(
        ProviderScope(child: RepaintBoundary(key: key, child: const MyApp())));
    Future<void> settle([int n = 8]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await settle(12);
    for (final k in ['menu_tower', 'tower_continue']) {
      final f = find.byKey(Key(k));
      await tester.ensureVisible(f.first);
      await tester.pump();
      await tester.tap(f.first);
      await settle(10);
    }
    await settle(18);
    expect(find.byKey(const Key('tower_oath_title_mire')), findsOneWidget);
    await tester.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await b.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/oath-real-412.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
