// PICTURES ONLY (UX_SHOTS=<folder>): the story fight as it is today (the
// story's colours) and the same fight wearing the Tower's ink (TowerNight),
// with a party of three (the hero and two companions) against two foes, at
// 360 and 320, English and French, before the throw and after it. These are
// the bases the new combat direction is drawn from.
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
import 'package:narrative_data_app/screens/tower/tower_look.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
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
  final shots = Platform.environment['UX_SHOTS'];
  testWidgets('the story fight, today and in ink', skip: shots == null,
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    await tester.runAsync(loadAppFonts);
    Directory(shots!).createSync(recursive: true);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    for (final cfg in const [
      (Size(360, 740), AppLanguage.en, 1.0, false),
      (Size(360, 740), AppLanguage.en, 1.0, true),
      (Size(360, 740), AppLanguage.en, 1.0, null),
    ]) {
      final ink = cfg.$4 == true;
      final mixed = cfg.$4 == null;
      final name =
          '${ink ? 'ink' : mixed ? 'mixed' : 'story'}-${cfg.$1.width.toInt()}-${cfg.$2.name}';
      SharedPreferences.setMockInitialValues(
          {'tutorial_enabled': false, 'combat_dice_speed': 'normal'});
      usePhone(tester, const Size(420, 2400));
      tester.platformDispatcher.textScaleFactorTestValue = cfg.$3;
      final boundary = GlobalKey();
      await tester.pumpWidget(ProviderScope(
          key: UniqueKey(),
          child: RepaintBoundary(
              key: boundary,
              child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: buildAppTheme(
                      AppPalette.stitchedInk.schemeFor(Brightness.light)),
                  builder: ink
                      ? (c, child) => TowerNight(frames: false, child: child!)
                      : null,
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
      for (final id in ['harbor_rat', 'harbor_rat']) {
        await tester.tap(find.text('Add an enemy (up to 3)'));
        await _settle(tester);
        await tester.enterText(find.byType(TextField), id);
        await _settle(tester);
        await tester.tap(find.widgetWithText(ListTile, 'Harbour Rat').first);
        await _settle(tester);
      }
      for (final who in const ['maren', 'kelda']) {
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
      Future<void> shoot(String suffix) async {
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/$name-$suffix.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }

      await shoot('before');
      final roll = find.textContaining(trFor(cfg.$2, 'roll_dice_button'));
      if (roll.evaluate().isNotEmpty) {
        await tester.tap(roll.first);
        for (var i = 0; i < 36; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await shoot('after');
      }
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .pop<bool>(true);
      await _settle(tester);
    }
  });
}
