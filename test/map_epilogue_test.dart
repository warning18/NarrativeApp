// The epilogue map reads on a phone (wave 3 of the Maps review): the chart
// wears the page's light look and no names; the big towns' numbers do not
// sit on each other; a tap on a number brings its line into view.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/providers/geography_provider.dart';
import 'package:narrative_data_app/providers/palette_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/epilogue_map_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/data/map_charts.dart';
import 'package:narrative_data_app/data/world_map.dart';
import 'package:narrative_data_app/widgets/chart_map_painter.dart';
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

  test('a number on a disc is in the ink that reads on its colour', () {
    double contrast(Color a, Color b) {
      final la = a.computeLuminance(), lb = b.computeLuminance();
      return (la > lb ? la + 0.05 : lb + 0.05) /
          (la > lb ? lb + 0.05 : la + 0.05);
    }

    // The six main clans' hues (factions.json, v2.9.5) and two extremes.
    for (final hex in [
      0xFF2F6FE0, 0xFFE0479E, 0xFFE8782A, 0xFF3FB06A, 0xFFE8C21A, //
      0xFF9B5DE5, 0xFF000000, 0xFFFFFFFF,
    ]) {
      final fill = Color(hex);
      expect(contrast(discInk(fill), fill), greaterThanOrEqualTo(4.4),
          reason: hex.toRadixString(16));
    }
    expect(discInk(const Color(0xFFE8C21A)), discDarkInk);
    expect(discInk(const Color(0xFF2F6FE0)), Colors.white);
    expect(discInkShadows(const Color(0xFFE8C21A)), isNull);
  });

  test('numbers that would sit on each other are pushed apart', () {
    const towns = [
      Offset(100, 100),
      Offset(104, 108), // on the first
      Offset(110, 96), // and on both
      Offset(300, 200), // alone
    ];
    final at = spreadMarks(towns);
    for (var i = 0; i < at.length; i++) {
      for (var j = i + 1; j < at.length; j++) {
        expect((at[i] - at[j]).distance, greaterThanOrEqualTo(26.9),
            reason: '$i and $j');
      }
    }
    // A number alone stays on its town; the crowded ones stay near theirs.
    expect(at[3], towns[3]);
    for (var i = 0; i < 3; i++) {
      expect((at[i] - towns[i]).distance, lessThan(30), reason: '$i');
    }
    // Nothing to do, nothing moved.
    expect(spreadMarks(const [Offset.zero, Offset(50, 0)]),
        const [Offset.zero, Offset(50, 0)]);
  });

  testWidgets(
      'the page look, no names on the chart, a number leads to its line',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    usePhone(tester, const Size(360, 640));

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

    // On a light page the chart is Parchment, whatever look is chosen, and
    // it draws no names.
    final chart = tester
        .widgetList<CustomPaint>(find.descendant(
            of: find.byKey(const Key('epilogue_map')),
            matching: find.byType(CustomPaint)))
        .map((c) => c.painter)
        .whereType<ChartMapPainter>()
        .single;
    expect(chart.palette.land, ChartPalette.of(MapLook.parchment).land);
    expect(chart.names, isFalse);

    // The seventh town's line is below the fold of a 360 x 640 phone; a tap
    // on its number on the chart brings it into view.
    final over = find
        .descendant(
            of: find.byKey(const Key('epilogue_map')),
            matching: find.byType(CustomPaint))
        .evaluate()
        .where((e) =>
            (e.widget as CustomPaint).painter.runtimeType.toString() ==
            '_OverPainter')
        .single;
    final marks =
        ((over.widget as CustomPaint).painter as dynamic).marks as List<Offset>;
    expect(marks, hasLength(7));
    final origin = (over.renderObject! as RenderBox).localToGlobal(Offset.zero);
    // (Off screen it is built but not on stage: the finder must not skip it.)
    final row =
        find.byKey(const Key('epilogue_town_candlehold'), skipOffstage: false);
    final view = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(tester.getRect(row).top, greaterThan(view),
        reason: 'the line starts below the fold');
    await tester.tapAt(origin + marks[6]);
    await _settle(tester);
    expect(tester.getRect(row).bottom, lessThanOrEqualTo(view));
    expect(tester.getRect(row).top, greaterThanOrEqualTo(0));
    expect(tester.takeException(), isNull);
  });
}
