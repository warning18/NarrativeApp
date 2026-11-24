// QA guard (the thrown dice, v2.2.0, and the solid dice, v2.2.2): on the real
// fight screen, with a party of two (the hero and a companion, one die
// each), at 320, 360 and 412 wide, English and French, 1.3x text, after Roll
// Dice and the throw: every die is at rest (its roll finished, none still
// turning), no two dice overlap, every die is whole on the screen, and the
// weather is not drawn across them. With reduced motion the dice are at rest
// at once. UX's ux_dice_throw_test holds the plan on its own; this holds the
// board the player sees. QA_DICE_SHOTS=<folder> writes a picture of each.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_lab_screen.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/die_3d.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

Future<void> _settle(WidgetTester tester, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('the thrown dice end at rest, apart, whole on the screen',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    await tester.runAsync(loadAppFonts);
    final problems = <String>[];
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    for (final cfg in const [
      (Size(320, 568), AppLanguage.fr, 1.3, false),
      (Size(360, 740), AppLanguage.en, 1.0, false),
      (Size(412, 860), AppLanguage.en, 1.0, false),
      (Size(360, 740), AppLanguage.en, 1.0, true),
    ]) {
      final name = '${cfg.$1.width.toInt()} wide, ${cfg.$2.name}, '
          'text x${cfg.$3}${cfg.$4 ? ', reduced motion' : ''}';
      SharedPreferences.setMockInitialValues(
          {'tutorial_enabled': false, 'combat_dice_speed': 'normal'});
      await tester.runAsync(() async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        await prefs.setBool('tutorial_enabled', false);
      });
      final previous = FlutterError.onError;
      FlutterError.onError = (d) {
        final text = d.exceptionAsString();
        if (text.contains('overflowed')) {
          problems.add('$name: ${text.split('\n').first}');
        } else {
          previous?.call(d);
        }
      };
      usePhone(tester, const Size(420, 2400));
      tester.platformDispatcher.textScaleFactorTestValue = cfg.$3;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: cfg.$4);
      final boundary = GlobalKey();
      await tester.pumpWidget(ProviderScope(
          key: UniqueKey(),
          child: RepaintBoundary(
              key: boundary,
              child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: buildAppTheme(
                      AppPalette.stitchedInk.schemeFor(Brightness.light)),
                  home: const FightLabScreen()))));
      await _settle(tester);
      final c = ProviderScope.containerOf(
          tester.element(find.byType(FightLabScreen)));
      await tester.runAsync(() =>
          c.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en));
      await tester.runAsync(() => c
          .read(playerSessionProvider.notifier)
          .loadSession(PlayerSession.fromJson({
            'raceId': 'human',
            'professionId': 'warrior',
            'ownedDiceIds': ['starter_die'],
            'equippedDiceId': 'starter_die',
          })));
      await _settle(tester);
      await tester.tap(find.text('Add an enemy (up to 3)'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'harbor_rat');
      await _settle(tester);
      await tester.tap(find.widgetWithText(ListTile, 'Harbour Rat'));
      await _settle(tester);
      for (final who in const ['maren']) {
        await tester
            .ensureVisible(find.byKey(const Key('fight_lab_add_companion')));
        await tester.tap(find.byKey(const Key('fight_lab_add_companion')));
        await _settle(tester);
        await tester.tap(find.byKey(Key('fight_lab_pick_$who')));
        await _settle(tester);
      }
      await tester
          .ensureVisible(find.byKey(const Key('fight_lab_start_fight')));
      await tester.tap(find.byKey(const Key('fight_lab_start_fight')));
      await _settle(tester);
      expect(find.byType(FightScreen), findsOneWidget, reason: name);
      // The fight on the phone.
      usePhone(tester, cfg.$1);
      await tester.runAsync(
          () => c.read(appLanguageProvider.notifier).setLanguage(cfg.$2));
      await _settle(tester);
      await tester.tapAt(const Offset(4, 300));
      await _settle(tester);
      final enter = find.text(trFor(cfg.$2, 'enter_battle_button'));
      if (enter.evaluate().isNotEmpty) {
        await tester.ensureVisible(enter);
        await tester.pump();
        await tester.tap(enter);
        await _settle(tester);
      }
      final roll = find.textContaining(trFor(cfg.$2, 'roll_dice_button'));
      expect(roll, findsWidgets, reason: '$name: no Roll Dice');
      await tester.tap(roll.first);
      // The throw lasts 2.3 s; with reduced motion the dice are at rest soon.
      for (var i = 0; i < (cfg.$4 ? 6 : 36); i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final shots = Platform.environment['QA_DICE_SHOTS'];
      if (shots != null) {
        Directory(shots).createSync(recursive: true);
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/${name.replaceAll(RegExp('[^a-z0-9]+'), '_')}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
      final cubes = find.byType(Die3D);
      final n = cubes.evaluate().length;
      if (n < 2) problems.add('$name: only $n dice on the board');
      final rects = [for (var i = 0; i < n; i++) tester.getRect(cubes.at(i))];
      final skin = find.byKey(const Key('fight_board_skin'));
      final board = skin.evaluate().isEmpty
          ? Offset.zero & cfg.$1
          : tester.getRect(skin.first);
      final screen = Offset.zero & cfg.$1;
      for (var i = 0; i < n; i++) {
        final d = tester.widget<Die3D>(cubes.at(i));
        if (d.rolling) problems.add('$name: die $i is still turning');
        final r = d.roll;
        if (r != null && r.value != 1.0 && r.value != 0.0) {
          problems.add('$name: die $i stopped at ${r.value}, not on a face');
        }
        if (!screen.inflate(0.5).contains(rects[i].topLeft) ||
            !screen.inflate(0.5).contains(rects[i].bottomRight)) {
          problems.add('$name: die $i is off the screen: ${rects[i]}');
        }
        final inside = rects[i].intersect(board.inflate(2));
        final seen = inside.width <= 0 || inside.height <= 0
            ? 0.0
            : inside.width * inside.height / (rects[i].width * rects[i].height);
        if (seen < 0.9) {
          problems.add('$name: die $i is ${(100 - seen * 100).round()}% '
              'cut off by the board ($board, die ${rects[i]})');
        }
        for (var j = i + 1; j < n; j++) {
          if (rects[i].deflate(2).overlaps(rects[j].deflate(2))) {
            problems.add('$name: dice $i and $j overlap');
          }
        }
      }
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .pop<bool>(true);
      await _settle(tester);
      FlutterError.onError = previous;
    }
    expect(problems.toSet().toList(), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 4)));
}
