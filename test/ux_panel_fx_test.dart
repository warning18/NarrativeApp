// PICTURES (UX_SHOTS=<folder>): the Tower fight's two fighter panels (the
// foe's and "You") in six manga-style shapes, on the real app at 412 wide:
// today, cut corners, a slanted gutter, offset with the foe breaking out of
// its frame, a burst edge (wardens and bosses: floor 5) and a brush-ink
// border. Names, HP, the Heat chip and the info buttons stay where they are.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/status_effect.dart'
    show StatusEffectType;
import 'package:narrative_data_app/providers/combat_settings_provider.dart';
import 'package:narrative_data_app/data/tower/tower_bot.dart';
import 'package:narrative_data_app/data/tower/tower_run.dart';
import 'package:narrative_data_app/data/tower/tower_save.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/main.dart';
import 'package:narrative_data_app/providers/fight_events_provider.dart';
import 'package:narrative_data_app/screens/fight/fight_panel_fx.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_kit.dart'
    show InkSlantPanel;
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';

import 'support/fonts.dart';

/// The real app on a Tower fight at 412 wide: the app's container.
Future<ProviderContainer> _bootFight(WidgetTester tester, GlobalKey key,
    {int seed = 5, int? floor, int events = 0}) async {
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
  tester.view.physicalSize = const Size(412, 860);
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
  tearDown(panelFx.clear);

  // The Tower fight on the real app at 412 wide; the test publishes the fight's
  // own events and the screen plays them, and with UX_SHOTS it also saves
  // dense frames (every 20 ms) of each effect from a frozen clock.
  testWidgets('the fight screen plays the fight events on its panels',
      (tester) async {
    final key = GlobalKey();
    final c = await _bootFight(tester, key);
    expect(tester.takeException(), isNull);

    // The fight's events play on the panel they landed on.
    final events = c.read(fightEventsProvider);
    FightHitEvent hit(
            {String element = 'None',
            bool crit = false,
            FightTarget? target,
            FightHitKind kind = FightHitKind.strike,
            String? skillId}) =>
        FightHitEvent(
          kind: kind,
          target: target ?? const FightTarget(FightSide.foe, 0, 'enemy_0'),
          amount: 9,
          power: crit ? 1.6 : 1.0,
          crit: crit,
          element: element,
          skillId: skillId,
          round: 1,
        );
    panelFx.clear();
    events.hit(hit());
    expect(panelFx.active.last.skill, PanelFxSkill.basic);
    expect(panelFx.active.last.onFoe, isTrue);
    expect(panelFx.active.last.strong, isFalse);
    events.hit(hit(crit: true));
    expect(panelFx.active.last.crit, isTrue);
    expect(panelFx.active.last.strong, isTrue);
    events.hit(hit(element: 'Fire', kind: FightHitKind.spell));
    expect(panelFx.active.last.skill, PanelFxSkill.fire);
    events.hit(hit(
        kind: FightHitKind.foeMove,
        target: const FightTarget(FightSide.party, 0, 'player')));
    expect(panelFx.active.last.onFoe, isFalse);
    expect(panelFx.active.last.skill, PanelFxSkill.basic);
    events.tick(const FightStatusTickEvent(
        target: FightTarget(FightSide.foe, 0, 'enemy_0'),
        amount: 3,
        status: StatusEffectType.poison,
        round: 1));
    expect(panelFx.active.last.kind, PanelFxKind.tick);
    expect(panelFx.active.length, 5);
    // The panel shifts a pixel or two at most, and a big hit shakes the screen.
    panelFx.clear();
    panelFx.frozenMs = 0;
    panelFx.play(
        skill: PanelFxSkill.fire,
        onFoe: true,
        index: 0,
        count: 1,
        strong: true);
    for (var ms = 0.0; ms < 1200; ms += 10) {
      panelFx.frozenMs = ms;
      expect(panelFx.panelOffset(true).dx.abs(), lessThanOrEqualTo(2));
      expect(panelFx.screenOffset().dx.abs(), lessThanOrEqualTo(3));
    }
    expect(panelFx.panelOffset(false), Offset.zero);
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);

    if (shots == null) return;
    // (skill, strong, crit, text, ms to show)
    final lengths = {
      PanelFxSkill.basic: 600,
      PanelFxSkill.fire: 1200,
      PanelFxSkill.poison: 2000,
    };
    for (final skill in PanelFxSkill.values) {
      for (final strong in [false, true]) {
        final dir = '$shots/${skill.name}-${strong ? 'strong' : 'subtle'}';
        Directory(dir).createSync(recursive: true);
        for (var ms = 0; ms <= lengths[skill]!; ms += 20) {
          panelFx.clear();
          panelFx.frozenMs = ms.toDouble();
          panelFx.play(
              skill: skill,
              onFoe: true,
              index: 0,
              count: 1,
              strong: strong,
              crit: skill == PanelFxSkill.basic && strong,
              text:
                  '-${skill == PanelFxSkill.basic ? (strong ? 27 : 12) : 14}');
          if (skill == PanelFxSkill.poison) {
            panelFx.previewPoison.add(0);
            for (final at in const [900.0, 1800.0]) {
              panelFx.play(
                  skill: PanelFxSkill.poison,
                  kind: PanelFxKind.tick,
                  onFoe: true,
                  index: 0,
                  count: 1,
                  text: '-3',
                  delayMs: at);
            }
          }
          await tester.pump(const Duration(milliseconds: 1));
          await tester.runAsync(() async {
            final render =
                key.currentContext!.findRenderObject() as RenderRepaintBoundary;
            final image = await render.toImage(pixelRatio: 1);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            File('$dir/${ms.toString().padLeft(4, '0')}.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
          });
        }
      }
    }
    panelFx.clear();
  });

  testWidgets('a real rival floor stands the two fighters side by side',
      (tester) async {
    final key = GlobalKey();
    // Seed 1, floor 2: the floor's event is a rival's.
    await _bootFight(tester, key, seed: 1, floor: 2, events: 3);
    expect(tester.takeException(), isNull);
    final panels = tester
        .widgetList<InkSlantPanel>(find.byType(InkSlantPanel))
        .map((p) => p.size)
        .toList();
    expect(panels.length, 2);
    expect(panels[0].height, panels[1].height);
    expect(panels[0].height, greaterThan(200));
    if (shots != null) {
      Directory(shots).createSync(recursive: true);
      await tester.runAsync(() async {
        final render =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/rival-real-412.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    }
  });

  testWidgets('with tremble off or reduce-motion on, no panel moves',
      (tester) async {
    panelFx.frozenMs = 120;
    panelFx.play(
        skill: PanelFxSkill.basic,
        onFoe: true,
        index: 0,
        count: 1,
        strong: true);
    Offset shown(WidgetTester t) {
      final box = t.renderObject<RenderBox>(find.byKey(const Key('probe')));
      return box.localToGlobal(Offset.zero);
    }

    Widget app({required bool tremble, bool reduce = false}) => ProviderScope(
          key: UniqueKey(),
          overrides: [
            trembleEnabledProvider.overrideWith(
                (ref) => PersistedFlagNotifier('t', defaultValue: tremble)),
          ],
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: reduce),
            child: const Directionality(
              textDirection: TextDirection.ltr,
              child: Align(
                alignment: Alignment.topLeft,
                child: PanelFxShake(
                    foe: true,
                    child: SizedBox(key: Key('probe'), width: 4, height: 4)),
              ),
            ),
          ),
        );
    await tester.pumpWidget(app(tremble: true));
    final moved = shown(tester);
    expect(moved.dx, isNot(0), reason: 'a strong blow moves the panel');
    await tester.pumpWidget(app(tremble: false));
    expect(shown(tester), Offset.zero);
    await tester.pumpWidget(app(tremble: true, reduce: true));
    expect(shown(tester), Offset.zero);
  });
}
