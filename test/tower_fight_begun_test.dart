// A Tower fight begun and never finished (the app closed mid-fight) counts
// as lost: the run saves a marker at the fight's first round
// (TowerRun.fightBegun), towerAfterFight clears it, and a run loaded with it
// set ends on that floor as a defeat, its end screen shown once with a line
// saying why. English at 412 px, French at 360 px; pictures with
// UX_SHOTS=<folder> (docs/simulation/tower-fight-begun/).
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
import 'package:narrative_data_app/data/tower/tower_progress.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/screens/tower/tower_end_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';
import 'package:narrative_data_app/screens/tower/tower_start_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final data = towerDataFromAssets();
  final start =
      towerStart(seed: 5, raceId: 'human', professionId: 'warrior', data: data);
  // Floor 4, hurt, a store open on the landing: what a defeat clears.
  final climbing = start.copyWith(floor: 4, health: 9, store: 4);

  Future<TowerController> opened() async {
    final controller = TowerController();
    for (var i = 0; i < 50 && controller.state.value == null; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return controller;
  }

  test('the marker survives JSON; an old save reads as not begun', () {
    final begun = towerBeginFight(climbing);
    expect(begun.fightBegun, isTrue);
    expect(begun.toJson()['fighting'], isTrue);
    expect(TowerRun.fromJson(jsonDecode(jsonEncode(begun.toJson()))).fightBegun,
        isTrue);
    // A save without the field (every save before it) is not begun, and a
    // run not begun writes nothing new.
    expect(climbing.toJson().containsKey('fighting'), isFalse);
    expect(TowerRun.fromJson(climbing.toJson()).fightBegun, isFalse);
    // Only a climbing run begins a fight.
    final choosing = climbing.copyWith(status: TowerStatus.choosing);
    expect(identical(towerBeginFight(choosing), choosing), isTrue);
  });

  test('a fight finished normally clears the marker', () {
    final begun = towerBeginFight(climbing);
    final won = towerAfterFight(begun, data, won: true, healthLeft: 5);
    expect(won.fightBegun, isFalse);
    expect(won.toJson().containsKey('fighting'), isFalse);
    expect(towerAfterFight(begun, data, won: false, healthLeft: 0).fightBegun,
        isFalse);
    // The same win as one never marked.
    expect(won.toJson(),
        towerAfterFight(climbing, data, won: true, healthLeft: 5).toJson());
  });

  test('a fight left is the same state as a normal defeat', () {
    final defeat = towerAfterFight(climbing, data, won: false, healthLeft: 3);
    final left = towerFightLost(towerBeginFight(climbing));
    expect(left.toJson(), defeat.toJson());
    expect(left.status, TowerStatus.dead);
    expect(left.health, 0);
    expect(left.store, isNull);
    expect(left.floor, 4);
  });

  test('the controller saves the marker and a begun run loads as lost',
      () async {
    SharedPreferences.setMockInitialValues(
        {towerRunPrefsKey: jsonEncode(climbing.toJson())});
    final first = await opened();
    expect(first.state.value!.run!.fightBegun, isFalse);
    await first.beginFight();
    final prefs = await SharedPreferences.getInstance();
    final saved = jsonDecode(prefs.getString(towerRunPrefsKey)!) as Map;
    expect(saved['fighting'], isTrue);

    // The app closed mid-fight: the next launch finds the marker.
    final relaunch = await opened();
    final state = relaunch.state.value!;
    expect(state.run, isNull);
    final defeat = towerAfterFight(climbing, data, won: false, healthLeft: 0);
    expect(state.fightLeft!.toJson(), defeat.toJson());
    // Its marks banked as a defeat's, the run's key cleared.
    expect(state.progress.toJson(),
        const TowerProgress().afterRun(defeat).toJson());
    expect(prefs.getString(towerRunPrefsKey), isNull);
    relaunch.fightLeftSeen();
    expect(relaunch.state.value!.fightLeft, isNull);
    expect(relaunch.state.value!.progress.toJson(), state.progress.toJson());

    // A run not begun loads as it was.
    SharedPreferences.setMockInitialValues(
        {towerRunPrefsKey: jsonEncode(climbing.toJson())});
    final plain = await opened();
    expect(plain.state.value!.run!.toJson(), climbing.toJson());
    expect(plain.state.value!.fightLeft, isNull);
    first.dispose();
    relaunch.dispose();
    plain.dispose();
  });

  testWidgets('relaunched after a fight left: the end screen, as a loss',
      (tester) async {
    await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    final shots = Platform.environment['UX_SHOTS'];
    for (final (lang, width) in [
      (AppLanguage.en, 412.0),
      (AppLanguage.fr, 360.0)
    ]) {
      SharedPreferences.setMockInitialValues({
        'app_language': lang.name,
        towerRunPrefsKey: jsonEncode(towerBeginFight(climbing).toJson()),
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
              home: const TowerStartScreen()),
        ),
      ));
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      final error = tester.takeException();
      if (shots != null) {
        Directory(shots).createSync(recursive: true);
        await tester.runAsync(() async {
          final b =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await b.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/tower-fight-left-${lang.name}-${width.toInt()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
      expect(error, isNull, reason: lang.name);
      expect(find.byType(TowerEndScreen), findsOneWidget, reason: lang.name);
      expect(find.byType(TowerStartScreen), findsNothing, reason: lang.name);
      expect(find.text(trFor(lang, 'tower_fight_left')), findsOneWidget);
      expect(find.text(trFor(lang, 'tower_death').replaceAll('{n}', '4')),
          findsOneWidget);
      expect(container.read(towerProvider).value!.fightLeft, isNull);
      expect(container.read(towerProvider).value!.run, isNull);
    }
  });
}
