// QA guard (L3 1.992 read-through of v1.993-1.996): the real fight screen,
// with the real foes whose names are longest and whose marks are most, at
// 320 and 360 wide, English and French, at normal and 1.3x text, draws no
// overflow. The UX pictures (ux_marks_fit_test) draw the nameplate alone;
// this one goes through FightScreen with the data of enemies.json.
// (The 1 px die-tile overflow at 1.3x, #1100, was fixed in v1.997.)
// QA_L3_FIGHT=<folder> also writes a picture of each.
import 'dart:convert';
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
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

void main() {
  final shots = Platform.environment['QA_L3_FIGHT'];
  testWidgets('the longest foes with the most marks fit', (tester) async {
    await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    final all =
        jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
            as Map<String, dynamic>;
    final foes = <String, Map<String, dynamic>>{};
    all.forEach((k, v) {
      if (v is Map && v['enemyName'] != null) {
        foes[k] = Map<String, dynamic>.from(v);
      }
    });
    int len(MapEntry<String, Map<String, dynamic>> e) {
      final n = '${e.value['enemyName']}'.length;
      final f = '${e.value['enemyName_fr'] ?? ''}'.length;
      return n > f ? n : f;
    }

    int marks(Map<String, dynamic> v) =>
        ((v['weakTo'] as List?)?.length ?? 0) +
        ((v['resists'] as List?)?.length ?? 0);
    final ranked = foes.entries.toList()
      ..sort((a, b) {
        final m = marks(b.value) - marks(a.value);
        return m != 0 ? m : len(b) - len(a);
      });
    final pick = ranked.take(2).toList()
      ..addAll(
          (foes.entries.toList()..sort((a, b) => len(b) - len(a))).take(2));
    final problems = <String>[];

    for (final cfg in const [
      (320.0, 568.0, AppLanguage.fr, 1.3),
      (360.0, 740.0, AppLanguage.en, 1.3),
      (320.0, 568.0, AppLanguage.en, 1.0),
    ]) {
      SharedPreferences.setMockInitialValues({});
      usePhone(tester, Size(cfg.$1, cfg.$2));
      tester.platformDispatcher.textScaleFactorTestValue = cfg.$4;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: key, child: const ProviderScope(child: MyApp())));
      await settleApp(tester);
      final c =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      await tester.runAsync(
          () => c.read(appLanguageProvider.notifier).setLanguage(cfg.$3));
      await tester.runAsync(() => c
          .read(playerSessionProvider.notifier)
          .loadSession(PlayerSession.fromJson({
            'raceId': 'human',
            'professionId': 'warrior',
            'ownedDiceIds': ['starter_die', 'flame_die'],
            'equippedDiceId': 'starter_die',
          })));
      for (final e in pick) {
        final errors = <String>[];
        final old = FlutterError.onError;
        FlutterError.onError = (d) => errors.add(d
            .toString()
            .split('\n')
            .where((l) =>
                l.contains('overflowed') ||
                l.contains('error-causing') ||
                l.contains('creator') ||
                l.contains('file:'))
            .take(2)
            .join(' | '));
        tester
            .state<NavigatorState>(find.byType(Navigator).first)
            .push(MaterialPageRoute<bool>(
                builder: (_) => FightScreen(enemyId: e.key, enemy: {
                      ...(cfg.$3 == AppLanguage.fr
                          ? frenchOverlay({e.key: e.value})[e.key]
                              as Map<String, dynamic>
                          : e.value),
                      'skillMoves': const <dynamic>[],
                    })));
        await settleApp(tester);
        // The foe's card stands over the screen first: tap outside it.
        await tester.tapAt(const Offset(4, 300));
        await settleApp(tester);
        // The nameplate with its marks stands on the battle screen.
        final enter = find.text(
            cfg.$3 == AppLanguage.fr ? 'Entrer au combat' : 'Enter Battle');
        if (enter.evaluate().isNotEmpty) {
          await tester.ensureVisible(enter);
          await tester.pump();
          await tester.tap(enter);
          await settleApp(tester);
        } else {
          problems.add('${e.key}: no Enter Battle button');
        }
        if (shots != null) {
          Directory(shots).createSync(recursive: true);
          await tester.runAsync(() async {
            final render =
                key.currentContext!.findRenderObject() as RenderRepaintBoundary;
            final img = await render.toImage();
            final b = await img.toByteData(format: ui.ImageByteFormat.png);
            File('$shots/${cfg.$1.toInt()}_${cfg.$3.name}_${cfg.$4}_${e.key}.png')
                .writeAsBytesSync(b!.buffer.asUint8List());
          });
        }
        FlutterError.onError = old;
        tester.takeException();
        for (final m in errors.where((m) => m.contains('overflowed'))) {
          problems
              .add('${cfg.$1.toInt()} ${cfg.$3.name} x${cfg.$4} ${e.key}: $m');
        }
        tester.state<NavigatorState>(find.byType(Navigator).first).pop();
        await settleApp(tester);
      }
    }
    expect(problems, isEmpty);
  });
}
