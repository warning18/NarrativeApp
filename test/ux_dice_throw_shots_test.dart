// PICTURES (UX_SHOTS=<folder>): the throw of a single d6 on the real Tower fight
// board at 412 wide, a frame every 40 ms, in each style (today, dropped, dropped
// with a stronger bounce).
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
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_dice.dart';
import 'package:narrative_data_app/screens/tower/tower_backdrop.dart'
    show towerFightScene;
import 'package:narrative_data_app/screens/tower/tower_look.dart';
import 'package:narrative_data_app/utils/face_style.dart';
import 'package:narrative_data_app/widgets/dice_ground.dart';
import 'package:narrative_data_app/combat/field_anomaly.dart' show FightStage;
import 'package:narrative_data_app/widgets/fight_board.dart';
import 'package:narrative_data_app/widgets/dice_throw.dart';
import 'package:narrative_data_app/widgets/die_3d.dart';

import 'support/fonts.dart';

/// The real app on a Tower fight at 412 wide: the app's container.
Future<ProviderContainer> _bootFight(WidgetTester tester, GlobalKey key,
    {int seed = 5, int? floor, int events = 0, double width = 412}) async {
  await tester.runAsync(loadAppFonts);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  final data = towerDataFromAssets();
  var run = towerStart(
      seed: seed, raceId: 'human', professionId: 'warrior', data: data);
  if (floor != null) run = run.copyWith(floor: floor, events: events, crest: 0);
  SharedPreferences.setMockInitialValues({
    towerRunPrefsKey: jsonEncode(run.toJson()),
    'tutorial_enabled': false,
  });
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 860);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
      RepaintBoundary(key: key, child: const ProviderScope(child: MyApp())));
  Future<void> settle([int n = 8]) async {
    for (var i = 0; i < n; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tapKey(String k) async {
    final f = find.byKey(Key(k));
    await tester.ensureVisible(f.first);
    await tester.pump();
    await tester.tap(f.first);
    await settle(10);
  }

  await settle(12);
  final c = ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  await tester.runAsync(
      () => c.read(appLanguageProvider.notifier).setLanguage(AppLanguage.en));
  await settle(4);
  await tapKey('menu_tower');
  await tapKey('tower_continue');
  await tapKey('tower_fight');
  await settle(12);
  final enter = find.text('Enter Battle');
  if (enter.evaluate().isNotEmpty) {
    await tester.ensureVisible(enter);
    await tester.pump();
    await tester.tap(enter);
    await settle(14);
  }
  return c;
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });
  tearDown(() => diceThrowStyle.value = DiceThrowStyle.today);

  for (final style in [DiceThrowStyle.drop, DiceThrowStyle.dropStrong]) {
    testWidgets('a d6 thrown, ${style.name}', skip: shots == null,
        (tester) async {
      diceThrowStyle.value = style;
      final key = GlobalKey();
      await _bootFight(tester, key, floor: 1);
      final dir = '$shots/throw-${style.name}';
      Directory(dir).createSync(recursive: true);
      await tester.tap(find.byIcon(Icons.casino));
      await tester.pump(const Duration(milliseconds: 1));
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        await tester.runAsync(() async {
          final render =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$dir/${(i * 40).toString().padLeft(4, '0')}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
      expect(tester.takeException(), isNull);
    });
  }

  // Three dice thrown together on the Tower's stone floor (the same plan, shadow,
  // dust and dice as the board, laid out here because the Tower fight has one
  // die): a scatter, not a stack.
  for (final style in [DiceThrowStyle.drop, DiceThrowStyle.dropStrong]) {
    testWidgets('three dice thrown, ${style.name}', skip: shots == null,
        (tester) async {
      await tester.runAsync(loadAppFonts);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(412, 330);
      addTearDown(tester.view.reset);
      const board = Size(412, 330);
      final seats = [
        const DiceThrowSeat(Offset(120, 210), 22),
        const DiceThrowSeat(Offset(214, 150), 22),
        const DiceThrowSeat(Offset(300, 220), 22),
      ];
      final plan = DiceThrowPlan.drop(
          seats: seats,
          board: board,
          seed: 7,
          strong: style == DiceThrowStyle.dropStrong);
      final controller = AnimationController(
          vsync: tester, duration: const Duration(milliseconds: diceDropMs));
      addTearDown(controller.dispose);
      final key = GlobalKey();
      final kinds = [FaceKind.attack, FaceKind.defend, FaceKind.attack];
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: TowerPanelStyle(
          child: RepaintBoundary(
            key: key,
            child: SizedBox.fromSize(
              size: board,
              child: FightBoardSurface(
                stage: FightStage.hall,
                plate: towerFightScene(1),
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final u = controller.value;
                    return Stack(clipBehavior: Clip.none, children: [
                      Positioned.fill(
                          child:
                              CustomPaint(painter: DiceGroundPainter(plan, u))),
                      for (var k = 0; k < 3; k++)
                        Positioned(
                          left: plan.position(k, u).dx - 30,
                          top: plan.position(k, u).dy - plan.lift(k, u) - 30,
                          width: 60,
                          height: 60,
                          child: Center(
                            child: Die3D(
                              faces: [
                                for (var f = 0; f < 6; f++)
                                  DieCubeFace(
                                      glyph: Icon(kinds[k].icon,
                                          size: 20, color: kinds[k].color),
                                      color: kinds[k].color)
                              ],
                              accent: const Color(0xFFB7C0C4),
                              size: 40,
                              roll: CurvedAnimation(
                                  parent: controller, curve: plan.turnCurve(k)),
                              rolling: u < 1,
                              fx: DieFx.strike,
                              skin: inkDieSkin,
                            ),
                          ),
                        ),
                    ]);
                  },
                ),
              ),
            ),
          ),
        ),
      ));
      final dir = '$shots/throw3-${style.name}';
      Directory(dir).createSync(recursive: true);
      controller.forward(from: 0);
      for (var i = 0; i < 36; i++) {
        await tester.pump(const Duration(milliseconds: 40));
        await tester.runAsync(() async {
          final render =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$dir/${(i * 40).toString().padLeft(4, '0')}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
      expect(tester.takeException(), isNull);
    });
  }
}
