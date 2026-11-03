// The realm, at the end (v1.638): the real world chart with each town in its
// holder's colour, the clans' roads and the seven big towns numbered over it,
// a chip for each clan with its towns, a line for each big town (Narrative's
// where it has one) and, where districts are held by others, a tag that opens
// their list. Real data (geography, the chart, the land routes) over a
// session whose clans hold some towns and districts.
//   UX_SHOTS=docs/ux-shots flutter test test/epilogue_map_screen_test.dart
// also takes the screen at 412 and 320 px (epilogue-map-built-*.png).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/epilogue.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/providers/geography_provider.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/epilogue_map_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'support/fonts.dart';
import 'support/pump.dart';

Future<void> _settle(WidgetTester tester, {int n = 5}) async {
  for (var i = 0; i < n; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final shots = Platform.environment['UX_SHOTS'];

  // One test, so the real data loads once for the file.
  testWidgets('the realm at the end: chart, chips, seven towns, districts',
      (tester) async {
    if (shots != null && shots.isNotEmpty) await tester.runAsync(loadAppFonts);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(412, 2200));

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final theme =
        buildAppTheme(AppPalette.stitchedInk.schemeFor(Brightness.light));
    final key = GlobalKey();
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: const EpilogueMapScreen(),
        ),
      ),
    ));
    await _settle(tester);

    // The clans take towns and districts as a long game would leave them.
    final geography = container.read(geographyProvider);
    expect(geography.isEmpty, isFalse);
    String firstDistrict(String town) => [
          for (final c in geography.childrenOf(town))
            if (c.level == GeoLevel.district) c.id,
        ].first;
    await tester.runAsync(() => container
        .read(playerSessionProvider.notifier)
        .loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'politics': {
            'control': {
              'alster': 'dominion',
              'saltmouth': 'crows',
              'drowned_cloister': 'mire',
              'black_reliquary': 'penitents',
              'white_anchorage': 'vigil',
              // The cove camp, so the Dominion holds both ends of the road
              // from the camp to Candlehold: a clan road.
              geography.placeOfLandmark('camp')?.id ?? 'camp': 'dominion',
              firstDistrict('saltmouth'): 'mire',
              firstDistrict('alster'): 'compact',
            },
          },
        })));
    await _settle(tester);

    // The chart is the real one, and the seven big towns are listed in order.
    expect(find.byKey(const Key('epilogue_map')), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    for (final id in epilogueBigTowns) {
      expect(find.byKey(Key('epilogue_town_$id')), findsOneWidget, reason: id);
    }
    expect(find.byKey(const Key('epilogue_town_candlehold')), findsOneWidget);

    // A chip for the holders, with how many towns each has.
    expect(find.byKey(const Key('epilogue_holder_dominion')), findsOneWidget);
    expect(find.byKey(const Key('epilogue_holder_crows')), findsOneWidget);

    // Saltmouth: Narrative's line, and the tag for its districts held by
    // others (the Mire's among them).
    expect(find.textContaining('Saltmouth'), findsWidgets);
    expect(find.byKey(const Key('epilogue_differ_saltmouth')), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('epilogue_differ_saltmouth')),
            matching: find.textContaining('differ')),
        findsOneWidget);

    // A tap on the tag opens the town's districts, the Mire's among them.
    await tester
        .ensureVisible(find.byKey(const Key('epilogue_differ_saltmouth')));
    await tester.tap(find.byKey(const Key('epilogue_differ_saltmouth')));
    await _settle(tester);
    expect(find.byKey(const Key('epilogue_districts')), findsOneWidget);
    expect(find.text('Like the town'), findsWidgets);
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.byKey(const Key('epilogue_districts'))))
        .pop();
    await _settle(tester);

    // The words stay in the list, not on the chart: no overflow at 320 px.
    tester.view.physicalSize = const Size(320, 2600);
    await _settle(tester);
    expect(tester.takeException(), isNull);

    if (shots != null && shots.isNotEmpty) {
      for (final w in [412.0, 320.0]) {
        tester.view.physicalSize = Size(w, 1100);
        await _settle(tester);
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1.5);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$shots/epilogue-map-built-${w.round()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
    }
  });
}
