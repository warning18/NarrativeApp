// The clans' compass (clan_compass.dart): friends side by side, blood feuds
// across the ring; on the Clans screen each crest wears the character's
// standing and a tap names the clan's friends and foes. UX_SHOTS (a folder)
// writes a picture.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/clans_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/clan_compass.dart';
import 'package:narrative_data_app/widgets/clan_compass_card.dart';

import 'player_session_provider_test.dart' show baseSession;

final _shotKey = GlobalKey();

Future<void> _loadFonts() async {
  for (final (family, files) in [
    (
      InkFonts.system,
      ['PixelifySans-Regular.ttf', 'PixelifySans-SemiBold.ttf']
    ),
    (
      InkFonts.prose,
      ['Spectral-Regular.ttf', 'Spectral-Medium.ttf', 'Spectral-Italic.ttf']
    ),
    (InkFonts.display, ['IMFellEnglishSC-Regular.ttf']),
  ]) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(Future.value(
          ByteData.sublistView(File('assets/fonts/$file').readAsBytesSync())));
    }
    await loader.load();
  }
  final icons = File('/tmp/flutter/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

Future<void> _shot(WidgetTester tester, String name) async {
  final dir = Platform.environment['UX_SHOTS'];
  if (dir == null) return;
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump();
  await tester.runAsync(() async {
    final boundary =
        _shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$dir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (Platform.environment['UX_SHOTS'] != null) await _loadFonts();
  });

  Future<ProviderContainer> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(appLanguageProvider);
    final notifier = container.read(playerSessionProvider.notifier);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.runAsync(() async {
      for (final schema in [
        factionsSchema,
        subclansSchema,
        relationsSchema,
        signsSchema,
      ]) {
        await container.read(gameDbProvider(schema).notifier).whenLoaded();
      }
    });
    await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
          ...baseSession().toJson(),
          'raceId': 'human',
          'professionId': 'warrior',
        }).copyWith(
          politics:
              const PoliticsState(standings: {'vigil': 28, 'compact': -12}),
        )));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(const ColorScheme.dark()),
        builder: (context, child) =>
            RepaintBoundary(key: _shotKey, child: child),
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(12),
            child: ClanCompassCard(),
          ),
        ),
      ),
    ));
    await tester.pump();
    return container;
  }

  testWidgets('the ring keeps friends together and feuds apart',
      (tester) async {
    final container = await open(tester);
    final data = container.read(clanDataProvider);
    final politics = container.read(playerSessionProvider).politics;
    final ids = [for (final c in data.clans) c.patron.id];
    expect(ids.length, 6);
    int step(String a, String b) => politics.relationStep(a, b, data) ?? 4;
    final order = compassOrder(ids, step);
    expect(order.first, ids.first, reason: 'the first stays on top');
    expect(order.toSet(), ids.toSet());
    for (var i = 0; i < order.length; i++) {
      final a = order[i];
      final b = order[(i + 1) % order.length];
      expect(step(a, b), greaterThanOrEqualTo(3),
          reason: '$a and $b are neighbours: not at war');
    }
    // Where each sits: the first at the top centre, all apart.
    final at = compassPositions(const Size(300, 200), order.length);
    expect(at.first.dx, closeTo(150, 0.001));
    expect(at.first.dy, lessThan(at.last.dy));
    expect(at.toSet().length, order.length);
  });

  testWidgets('each crest wears the standing; a tap names friends and foes',
      (tester) async {
    await open(tester);
    expect(find.byKey(const Key('clans_compass_card')), findsOneWidget);
    for (final id in [
      'dominion',
      'vigil',
      'compact',
      'mire',
      'crows',
      'penitents'
    ]) {
      expect(find.byKey(Key('compass_$id')), findsOneWidget, reason: id);
    }
    expect(
        find.descendant(
            of: find.byKey(const Key('compass_vigil')),
            matching: find.text('28')),
        findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('compass_compact')),
            matching: find.text('-12')),
        findsOneWidget);
    expect(find.byKey(const Key('clans_compass_focus')), findsNothing);
    await tester.tap(find.byKey(const Key('compass_vigil')));
    await tester.pump();
    expect(find.byKey(const Key('clans_compass_focus')), findsOneWidget);
    expect(find.textContaining('Friends'), findsWidgets);
    expect(find.byKey(const Key('clan_radar_vigil')), findsOneWidget);
    await _shot(tester, 'clan_compass_card');
    // The same crest again lets go.
    await tester.tap(find.byKey(const Key('compass_vigil')));
    await tester.pump();
    expect(find.byKey(const Key('clans_compass_focus')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
