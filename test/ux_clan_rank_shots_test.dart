// The clan power sign as built (option A, ranking): the Clans list with the
// rank plate on each row and the clan's card with the ranked bars, at 412 and
// 320 px, from the real widgets over sample strengths. Drawn only with
// UX_SHOTS (a folder):
//   UX_SHOTS=docs/ux-shots flutter test test/ux_clan_rank_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart' show PoliticsState;
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/clans_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/clan_peek.dart';
import 'package:narrative_data_app/widgets/clan_widgets.dart';

import 'player_session_provider_test.dart' show baseSession;

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final shots = Platform.environment['UX_SHOTS'];
  if (shots == null || shots.isEmpty) {
    test('the clan rank pictures are drawn only with UX_SHOTS', () {});
    return;
  }

  testWidgets('the Clans list and a clan card, ranked', (tester) async {
    await tester.runAsync(_loadFonts);
    SharedPreferences.setMockInitialValues(
        {'app_language': 'en', 'tutorial_enabled': false});
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(playerSessionProvider.notifier);
    await tester.runAsync(() async {
      for (final schema in [
        factionsSchema,
        subclansSchema,
        relationsSchema,
        titlesSchema,
        intriguesSchema,
        geographySchema,
        biomesSchema,
      ]) {
        await container.read(gameDbProvider(schema).notifier).whenLoaded();
      }
    });
    // The Crows overtook the Compact since the last turn, the Vigil fell
    // below the Mire, the Dominion held, the Kindly Ones lost a little.
    await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
          ...baseSession().toJson(),
          'raceId': 'human',
          'professionId': 'warrior',
        }).copyWith(
            politics: const PoliticsState(
          power: {
            'dominion': 60,
            'crows': 45,
            'compact': 40,
            'vigil': 22,
            'kindly': 8,
          },
          powerAtTurn: {
            'dominion': 60,
            'crows': 38,
            'compact': 40,
            'vigil': 34,
            'kindly': 11,
          },
        ))));
    final data = container.read(clanDataProvider);

    for (final w in [412.0, 320.0]) {
      tester.view.physicalSize = Size(w, 1500);
      final key = GlobalKey();
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(const ColorScheme.dark()),
          home: RepaintBoundary(
            key: key,
            child: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (final id in const [
                    'dominion',
                    'crows',
                    'compact',
                    'vigil',
                    'kindly',
                  ])
                    FactionStandingCard(faction: data.faction(id)!),
                  const SizedBox(height: 12),
                  const ClanDetailsCard(factionId: 'crows'),
                ],
              ),
            ),
          ),
        ),
      ));
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 150)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await b.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$shots/clan-rank-built-${w.round()}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
      expect(tester.takeException(), isNull, reason: '$w');
    }
  });
}
