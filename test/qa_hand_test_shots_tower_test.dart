// QA: real pictures of the Tower for the hand test of 1.863
// (docs/qa/hand-test-1.863/). Drawn only with QA_SHOTS=<folder>; without it
// the file holds one empty test.
//
//   QA_SHOTS=docs/qa/hand-test-1.863 flutter test test/qa_hand_test_shots_tower_test.dart
//
// The real app at 412 x 860, the app's own fonts, English, the main menu's
// Tower card. The fights of the floors are not played: the launcher is given
// a fake that wins each floor with the health it began (the Tower's own
// provider is made for that: towerFightLauncherProvider), so the floors, the
// spoils, the offers, the Level Up and the end are the real screens on the
// real engine. It never edits lib/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_providers.dart';

import 'support/fonts.dart';
import 'support/open_game.dart' show storedCityPlans;

void main() {
  final out = Platform.environment['QA_SHOTS'];
  if (out == null || out.isEmpty) {
    test('the Tower pictures are drawn only with QA_SHOTS', () {});
    return;
  }

  testWidgets('the Tower pictures', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    await tester.runAsync(loadAppFonts);
    SharedPreferences.setMockInitialValues({
      'tutorial_enabled': false,
      'combat_dice_speed': 'quad',
    });
    addTearDown(tester.view.reset);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(412, 860);
    Directory(out).createSync(recursive: true);
    final boundary = GlobalKey();
    await tester.pumpWidget(ProviderScope(overrides: [
      storedCityPlans,
      towerFightLauncherProvider.overrideWithValue((context, run, data) async =>
          TowerFightResult(won: true, healthLeft: run.health)),
    ], child: RepaintBoundary(key: boundary, child: const MyApp())));
    Future<void> settle([int n = 6]) async {
      for (var i = 0; i < n; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 40)));
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    // The run is dealt from a random seed, so the file draws every step and
    // keeps these pictures (the README names what each shows).
    const keep = {
      'tower-1-main-menu-card',
      'tower-2-start-screen',
      'tower-3-creation-race',
      'tower-3-creation-callings-padlocked',
      'tower-3-creation-picked',
      'tower-4-floor-1',
      'tower-7-spoils-floor-1-with-items',
      'tower-7-after-spoils-floor-1',
      'tower-7-after-spoils-floor-5',
      'tower-6-floor-5-step-1',
      'tower-8-level-up-after-floor-1',
      'tower-8-level-up-picked',
      'tower-9-leave-dialog',
      'tower-9-end-screen',
      'tower-9-marks-screen',
    };
    Future<void> shot(String name) async {
      if (!keep.contains(name)) return;
      await tester.pump(const Duration(milliseconds: 300));
      final bytes = await tester.runAsync(() async {
        final object = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await object.toImage();
        return image.toByteData(format: ui.ImageByteFormat.png);
      });
      File('$out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    }

    Future<void> tapKey(String k) async {
      final f = find.byKey(Key(k));
      await tester.ensureVisible(f.first);
      await tester.tap(f.first);
      await settle();
    }

    String visible() => [
          for (final e in find.byType(Text).evaluate())
            if ((e.widget as Text).data case final String t when t.isNotEmpty) t
        ].take(40).join(' | ');

    await settle();
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    await settle();

    await tester.ensureVisible(find.byKey(const Key('menu_tower')));
    await settle();
    await shot('tower-1-main-menu-card');
    await tapKey('menu_tower');
    await shot('tower-2-start-screen');
    await tapKey('tower_climb');
    await shot('tower-3-creation-race');
    await tapKey('choice_card_human');
    await tapKey('rp_next');
    await shot('tower-3-creation-callings-padlocked');
    await tapKey('choice_card_warrior');
    await shot('tower-3-creation-picked');
    await tapKey('rp_start');
    await settle(10);
    await shot('tower-4-floor-1');
    debugPrint('FLOOR1 ${visible()}');

    var levelUps = 0;
    for (var floor = 1; floor <= 7; floor++) {
      await tapKey('tower_fight');
      await settle(10);
      var guard = 0;
      while (find.byType(LevelUpScreen).evaluate().isNotEmpty && guard++ < 4) {
        levelUps++;
        if (levelUps == 1) await shot('tower-8-level-up-after-floor-$floor');
        if (find.text('Take this pick').evaluate().isNotEmpty) {
          // The three gains are dealt at random: take whichever is first.
          final gain = find.textContaining(RegExp(
              r'^(Constitution|Strength|Dexterity|Intelligence|Wisdom|Perception|Luck|Charisma)$'));
          await tester.tap(gain.first);
          await settle();
          if (levelUps == 1) await shot('tower-8-level-up-picked');
          await tester.tap(find.text('Take this pick'));
          await settle(10);
          if (levelUps == 1) await shot('tower-8-level-up-after-pick');
        }
        if (find.byType(LevelUpScreen).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.arrow_back).first);
          await settle(10);
        }
        debugPrint('LEVELUP $floor.$guard ${visible()}');
      }
      debugPrint('FLOOR $floor after: ${visible()}');
      await shot('tower-5-floor-$floor-won');
      for (var i = 0; i < 4; i++) {
        if (find.text('What the spoils change').evaluate().isNotEmpty) {
          final empty = find.text('The floor gave nothing this time.');
          await shot('tower-7-spoils-floor-$floor'
              '${empty.evaluate().isEmpty ? '-with-items' : '-nothing'}');
          await tester.tap(find.text('Take'));
          await settle(10);
          debugPrint('SPOILS TAKEN $floor ${visible()}');
          await shot('tower-7-after-spoils-floor-$floor');
          continue;
        }
        final take = find.byKey(const Key('tower_take'));
        final refuse = find.byKey(const Key('tower_refuse'));
        if (take.evaluate().isEmpty && refuse.evaluate().isEmpty) break;
        if (take.evaluate().isEmpty) {
          await tapKey('tower_refuse');
        } else {
          await tapKey('tower_take');
        }
        await settle(10);
        debugPrint('STEP $floor.$i ${visible()}');
        await shot('tower-6-floor-$floor-step-$i');
      }
    }
    // Leave the run: the end screen, then the marks.
    await tapKey('tower_leave');
    await tester.pump(const Duration(milliseconds: 300));
    await shot('tower-9-leave-dialog');
    await tapKey('tower_leave_yes');
    await settle(10);
    await shot('tower-9-end-screen');
    debugPrint('END ${visible()}');
    await tapKey('tower_end_marks');
    await settle(10);
    await shot('tower-9-marks-screen');
    debugPrint('MARKS ${visible()}');
    await tester.pump(const Duration(seconds: 3));
  });
}
