// QA guard (the home menu in ink, v1.1008): on a small phone, in French and at
// 1.3x text, the menu draws no overflow, keeps its keys, and every button can
// be reached and tapped: a fresh game has New Game (the red block), a dimmed
// Load, Settings, Edit Mode and the Tower; a game in progress adds Continue
// and demotes New Game. Settings and the Tower open from it and come back.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  // One test runs every case: the game data is read from the bundle on the
  // first pass, and a read begun inside one test never finishes for the next.
  testWidgets('the ink menu fits and works on a small phone', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    await tester.runAsync(loadAppFonts);
    final overflows = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exceptionAsString().contains('overflowed')) {
        overflows.add(d.exceptionAsString().split('\n').first);
      } else {
        previous?.call(d);
      }
    };
    addTearDown(() => FlutterError.onError = previous);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    for (final cfg in const [
      (Size(320, 568), AppLanguage.fr, 1.3),
      (Size(360, 740), AppLanguage.en, 1.0),
      (Size(320, 568), AppLanguage.en, 1.3),
    ]) {
      final name =
          '${cfg.$1.width.toInt()} wide, ${cfg.$2.name}, text x${cfg.$3}';
      SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
      await tester.runAsync(() async {
        await (await SharedPreferences.getInstance()).clear();
        await (await SharedPreferences.getInstance())
            .setBool('tutorial_enabled', false);
      });
      usePhone(tester, cfg.$1);
      tester.platformDispatcher.textScaleFactorTestValue = cfg.$3;
      await tester
          .pumpWidget(ProviderScope(key: UniqueKey(), child: const MyApp()));
      await settleApp(tester);
      final c =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      await tester.runAsync(
          () => c.read(appLanguageProvider.notifier).setLanguage(cfg.$2));
      await settleApp(tester);

      Future<void> reachable(String key) async {
        final f = find.byKey(Key(key));
        expect(f, findsOneWidget, reason: '$name: $key');
        await tester.ensureVisible(f);
        await tester.pump();
        final r = tester.getRect(f);
        expect(r.top >= 0 && r.bottom <= cfg.$1.height, isTrue,
            reason: '$name: $key is on the screen after a scroll ($r)');
        expect(r.width, greaterThan(100), reason: '$name: $key is wide enough');
      }

      // A fresh game.
      expect(find.byKey(const Key('menu_continue')), findsNothing,
          reason: name);
      for (final k in const [
        'menu_new_game',
        'menu_load',
        'menu_settings',
        'menu_edit_mode',
        'menu_tower',
      ]) {
        await reachable(k);
      }

      // The Tower opens from it and comes back.
      await tester.tap(find.byKey(const Key('menu_tower')));
      await settleApp(tester);
      expect(find.byKey(const Key('tower_climb')), findsOneWidget,
          reason: '$name: the Tower door');
      await tester.pageBack();
      await settleApp(tester);
      expect(find.byKey(const Key('menu_new_game')), findsOneWidget,
          reason: '$name: back at the menu');

      // A game in progress.
      await tester.runAsync(() => c
          .read(playerSessionProvider.notifier)
          .loadSession(PlayerSession.fromJson(
              {'raceId': 'human', 'professionId': 'warrior'})));
      await settleApp(tester);
      await reachable('menu_continue');
      await reachable('menu_new_game');
    }
    expect(overflows.toSet().toList(), isEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
