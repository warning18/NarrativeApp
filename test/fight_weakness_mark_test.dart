// The weakness mark on a foe's nameplate (v1.995, the user's pick "B"): a ×3
// with the element's icon, from the start of the fight, never met or not.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/enemy_affix.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'support/pump.dart';

Map<String, dynamic> _enemy(String id) => Map<String, dynamic>.from(
    (jsonDecode(File('assets/gamedata/enemies.json').readAsStringSync())
        as Map<String, dynamic>)[id] as Map);

void main() {
  testWidgets('a foe never met wears its weakness mark on the nameplate',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(390, 844));
    final boundary = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: boundary,
        child: ProviderScope(
            overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
            child: const MyApp())));
    await settleApp(tester);
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() => container
        .read(appLanguageProvider.notifier)
        .setLanguage(AppLanguage.en));
    // No kill of its kind, and the starting Perception: before v1.994 the
    // weakness stayed hidden until a hit found it.
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'ownedDiceIds': ['starter_die', 'flame_die'],
          'equippedDiceId': 'starter_die',
        })));
    final rat = {
      ..._enemy('harbor_rat'),
      'weakTo': ['Fire'],
      'skillMoves': <dynamic>[],
    };
    tester
        .state<NavigatorState>(find.byType(Navigator).first)
        .push(MaterialPageRoute<bool>(
            builder: (_) => FightScreen(
                  enemyId: 'harbor_rat',
                  enemy: rat,
                  modifiers: const EncounterModifiers(
                      forcedCondition: BattlefieldCondition.highGround,
                      forcedGoal: FightGoal.slay,
                      forcedAffixes: [EnemyAffix.packLeader]),
                )));
    await settleApp(tester);
    // Past the loadout picker, the board's nameplate carries the mark.
    await tester.tap(find.text('Enter Battle'));
    await settleApp(tester);
    final marks = find.byWidgetPredicate(
        (w) => w.key.toString().contains('fight_mark_weak_×3_'));
    expect(marks, findsOneWidget);
    final shots = Platform.environment['UX_SHOTS'];
    if (shots != null) {
      await tester.runAsync(() async {
        final render = boundary.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory(shots).createSync(recursive: true);
        File('$shots/fight-board.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }
    expect(tester.takeException(), isNull);
  });
}
