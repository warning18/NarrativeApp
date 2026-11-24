// Pictures only (UX_SHOTS=<folder>): the story fight's dice thrown, the real
// app at 360 with the player and two companions (three dice), a frame every
// 50 ms from the tap on Roll Dice to Confirm.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/battlefield_condition.dart';
import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';

import 'skill_fight_harness.dart' show gamedata, pumpUntil, settle, shows;
import 'support/fonts.dart';
import 'support/pump.dart';
import 'package:narrative_data_app/models/ally_state.dart';

final _key = GlobalKey();

Future<void> _enter(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({
    // The dice thrown at 4x: the tests wait a quarter of the throw (the
    // default speed is proven by dice_speed_test).
    'combat_dice_speed': 'quad',
    'gamedb_dice': jsonEncode({
      ...gamedata('dice.json'),
      'board_die': {
        'diceName': 'board_die',
        'numberOfFaces': 1,
        'faces': [
          {
            'faceName': 'Strike',
            'type': 'Attack',
            'value': 4,
            'element': 'None'
          },
        ],
      },
    }),
  });
  usePhone(tester, const Size(360, 780));
  await tester.pumpWidget(RepaintBoundary(
      key: _key,
      child: ProviderScope(
          overrides: [fightRandomProvider.overrideWithValue(() => Random(7))],
          child: const MyApp())));
  await settle(tester);
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .loadSession(PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'ownedDiceIds': ['board_die'],
        'equippedDiceId': 'board_die',
        'maxHealth': 400,
        'currentHealth': 400,
        'recruitedAllies': [
          for (final id in ['sable', 'liora'])
            AllyState(
                    companionId: id,
                    currentHealth: AllyState.fullHealthSentinel)
                .toJson(),
        ],
        'activeAllyIds': ['sable', 'liora'],
      })));
  final thug = {
    ...gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
    'maxHealth': 900,
    'skillMoves': <dynamic>[],
  };
  tester
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(MaterialPageRoute<bool>(
          builder: (_) => FightScreen(
                enemyId: 'slum_thug',
                enemy: thug,
                modifiers: const EncounterModifiers(
                    forcedCondition: BattlefieldCondition.highGround,
                    forcedGoal: FightGoal.slay),
              )));
  await settle(tester);
  await tester.tap(find.text('Enter Battle'));
  await settle(tester);
  await pumpUntil(tester, () => shows('Roll Dice'));
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  testWidgets('the story fight, three dice thrown', skip: shots == null,
      (tester) async {
    await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    final dir = Directory('$shots/story')..createSync(recursive: true);
    await _enter(tester);
    Future<void> shoot(String name) async {
      await tester.runAsync(() async {
        final render =
            _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${dir.path}/$name.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }

    await shoot('f000');
    await tester.tap(find.textContaining('Roll Dice').first);
    final times = <double>[];
    for (var i = 1; i < 120; i++) {
      final sw = Stopwatch()..start();
      await tester.pump(const Duration(milliseconds: 50));
      times.add(sw.elapsedMicroseconds / 1000);
      await shoot('f${i.toString().padLeft(3, '0')}');
      if (find.textContaining('Confirm').evaluate().isNotEmpty && i > 8) {
        for (var k = 0; k < 6; k++) {
          await tester.pump(const Duration(milliseconds: 50));
          await shoot('f${(i + k + 1).toString().padLeft(3, '0')}');
        }
        break;
      }
    }
    File('${dir.path}/frames_in_order.txt')
        .writeAsStringSync(times.map((t) => t.toStringAsFixed(1)).join(' '));
    times.sort();
    File('${dir.path}/frame_ms.txt').writeAsStringSync(
        'median ${times[times.length ~/ 2].toStringAsFixed(2)} ms, '
        'p95 ${times[(times.length * 0.95).floor()].toStringAsFixed(2)} ms, '
        'max ${times.last.toStringAsFixed(2)} ms over ${times.length} frames '
        '(build+layout+paint of the whole screen, no raster, this machine)\n');
    final dice = find.byWidgetPredicate((w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('die_tile_'));
    File('${dir.path}/dice_count.txt')
        .writeAsStringSync('${dice.evaluate().length}\n');
  });
}
