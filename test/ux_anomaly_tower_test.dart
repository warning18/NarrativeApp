// The Tower's ink: the anomaly's atmosphere stops above the face row and the
// action bar (v2.10.40). With UX_SHOTS=<folder> it also saves the families.
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

import 'package:narrative_data_app/combat/encounter.dart';
import 'package:narrative_data_app/combat/field_anomaly.dart';
import 'package:narrative_data_app/combat/fight_goal.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_random_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/fight_screen.dart';
import 'package:narrative_data_app/screens/tower/tower_look.dart'
    show TowerNight;
import 'package:narrative_data_app/widgets/fight_plates.dart'
    show FightPlateOverride;
import 'support/fonts.dart';
import 'support/pump.dart';

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Map<String, dynamic> _gamedata(String name) =>
    jsonDecode(File('assets/gamedata/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  // In the Tower's ink: the veil stops above the face row, which is under the
  // board (v2.10.40). With UX_SHOTS=<folder> it also saves the six families.
  final shots = Platform.environment['UX_SHOTS'];
  for (final (id, omen) in [
    ('eclipse', false),
    ('eclipse', true),
    ('thunderstorm', false),
    ('whiteout', false),
    ('blaze', false),
    ('flash_flood', false),
    ('earth_break', false),
  ]) {
    if (shots == null && !(id == 'eclipse' && !omen)) continue;
    testWidgets('the Tower: $id${omen ? ' (omen)' : ''}', (tester) async {
      await tester.runAsync(loadAppFonts);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      SharedPreferences.setMockInitialValues({'app_language': 'en'});
      usePhone(tester, const Size(412, 860));
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: ProviderScope(overrides: [
            fightRandomProvider.overrideWithValue(() => Random(7))
          ], child: const MyApp())));
      await _settle(tester);
      final container =
          ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
      await tester.runAsync(() => container
          .read(playerSessionProvider.notifier)
          .loadSession(PlayerSession.fromJson({
            'raceId': 'human',
            'professionId': 'warrior',
            'ownedDiceIds': ['starter_die'],
            'equippedDiceId': 'starter_die',
            'maxHealth': 400,
            'currentHealth': 400,
          })));
      final thug = {
        ..._gamedata('enemies.json')['slum_thug'] as Map<String, dynamic>,
        'maxHealth': 900,
        'skillMoves': [
          {'skillID': 'brace', 'condition': 'Always', 'priority': 1},
        ],
      };
      final plan = FieldAnomalyPlan(
          anomaly: fieldAnomalies.firstWhere((a) => a.id == id),
          side: AnomalySide.both,
          onset: omen ? 2 : 1,
          rounds: 3);
      final navigator =
          tester.state<NavigatorState>(find.byType(Navigator).first);
      navigator.push(MaterialPageRoute<bool>(
          builder: (_) => TowerNight(
              floor: 5,
              frames: false,
              child: FightPlateOverride(
                  asset: 'assets/visuals/tower_ink/tower_ward5.png',
                  boardStage: FightStage.hall,
                  floor: 5,
                  child: FightScreen(
                      enemyId: 'slum_thug',
                      enemy: thug,
                      modifiers: EncounterModifiers(
                          forcedStage: FightStage.hall,
                          forcedGoal: FightGoal.slay,
                          forcedAnomaly: plan))))));
      await _settle(tester);
      await tester.tap(find.text('Enter Battle'));
      for (var i = 0; i < 12; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byKey(const Key('anomaly_atmosphere')), findsOneWidget);
      final layer = tester.getRect(find.byKey(const Key('anomaly_atmosphere')));
      final clip = tester.widget<ClipRect>(find
          .ancestor(
              of: find.byKey(const Key('anomaly_atmosphere')),
              matching: find.byType(ClipRect))
          .first);
      final cut = layer.top + clip.clipper!.getClip(layer.size).bottom;
      // The veil stops above the face row and the action bar.
      expect(
          cut, lessThanOrEqualTo(tester.getTopLeft(find.text('Roll Dice')).dy));
      expect(cut, greaterThan(layer.top + layer.height * 0.5));
      expect(tester.takeException(), isNull);
      if (shots != null) {
        await tester.runAsync(() async {
          final render =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 1.5);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/fx-$id${omen ? '-omen' : ''}.png')
            ..createSync(recursive: true)
            ..writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
      await tester.pump(const Duration(seconds: 3));
    });
  }
}
