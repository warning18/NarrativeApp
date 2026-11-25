// PICTURES (UX_SHOTS=<folder>): the proposed snow on the real Tower fight at 412
// wide: flakes falling, drifts building on the top edges of the panels and
// buttons, chunks breaking off. A frame every 100 ms of an 18 s run, for the
// normal fall and a light one, and the reduced-motion dusting.
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
import 'package:narrative_data_app/screens/fight/fight_panel_fx.dart'
    show towerFoePanelKey, towerPartyPanelKey;
import 'package:narrative_data_app/screens/tower/ink/ink_snowfall.dart';
import 'package:narrative_data_app/screens/tower/ink/ink_sprites.dart';
import 'package:narrative_data_app/widgets/fight_effect_icons.dart'
    show FightStatusTile;
import 'package:narrative_data_app/screens/tower/ink/ink_weather.dart'
    show InkWeatherPiece;

import 'support/fonts.dart';

/// The real app on a Tower fight at 412 wide: the app's container.
Future<ProviderContainer> _bootFight(WidgetTester tester, GlobalKey key,
    {int seed = 5,
    int? floor,
    int events = 0,
    double width = 412,
    double height = 860,
    required ValueNotifier<List<SnowEdge>> edges,
    required ValueNotifier<double> time,
    bool light = false,
    bool reduce = false}) async {
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
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: RepaintBoundary(
        key: key,
        child: Stack(children: [
          const ProviderScope(child: MyApp()),
          Positioned.fill(
              child: InkSnowfall(
                  edges: edges,
                  time: time,
                  light: light,
                  reduceMotion: reduce)),
        ])),
  ));
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

List<SnowEdge> _edgesOf(WidgetTester tester) {
  final out = <SnowEdge>[];
  var id = 1;
  Rect rectOf(Element e) {
    final box = e.renderObject! as RenderBox;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  for (final e in [
    ...find.byType(InkWeatherPiece).evaluate(),
    ...find.bySubtype<ButtonStyleButton>().evaluate(),
    ...find.byType(FightStatusTile).evaluate(),
    ...find.byType(InkWell).evaluate().where((e) {
      final sz = (e.renderObject! as RenderBox).size;
      return sz.width >= 28 &&
          sz.width <= 430 &&
          sz.height >= 26 &&
          sz.height <= 64;
    }),
  ]) {
    final r = rectOf(e);
    if (r.width < 28 || r.top < 60) continue;
    if (out.any(
        (o) => (o.a.dx - r.left - 2).abs() < 3 && (o.a.dy - r.top).abs() < 3)) {
      continue;
    }
    out.add(
        SnowEdge(id++, Offset(r.left + 2, r.top), Offset(r.right - 2, r.top)));
  }
  for (final (key, foe) in [
    (towerFoePanelKey, true),
    (towerPartyPanelKey, false)
  ]) {
    final ctx = key.currentContext;
    if (ctx == null) continue;
    final box = ctx.findRenderObject()! as RenderBox;
    final r = box.localToGlobal(Offset.zero) & box.size;
    // The panels' own slanted top (foes) or flat top (party), as drawn.
    out.add(SnowEdge(id++, Offset(r.left + 6, r.top + (foe ? 14 : 6)),
        Offset(r.right - 6, r.top + 6)));
  }
  return out;
}

void main() {
  final shots = Platform.environment['UX_SHOTS'];
  setUp(() {
    rootBundle.clear();
    InkSprites.reset();
  });

  for (final (name, light, reduce) in [
    ('normal', false, false),
    ('light', true, false),
    ('reduced', false, true),
  ]) {
    testWidgets('snow, $name', skip: shots == null, (tester) async {
      final edges = ValueNotifier<List<SnowEdge>>(const []);
      final time = ValueNotifier<double>(0);
      final key = GlobalKey();
      await _bootFight(tester, key,
          floor: 1, edges: edges, time: time, light: light, reduce: reduce);
      edges.value = _edgesOf(tester);
      // ignore: avoid_print
      print('edges: ${edges.value.length}');
      final dir = '$shots/snow-$name';
      Directory(dir).createSync(recursive: true);
      final frames = reduce ? 1 : 180;
      for (var i = 0; i < frames; i++) {
        time.value = i * 0.1;
        await tester.pump(const Duration(milliseconds: 1));
        await tester.runAsync(() async {
          final render =
              key.currentContext!.findRenderObject() as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$dir/${i.toString().padLeft(4, '0')}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
      expect(tester.takeException(), isNull);
    });
  }
}
