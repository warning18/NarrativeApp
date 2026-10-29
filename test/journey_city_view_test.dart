// The Journey in a city with a stored plan (v1.355, board 15): the district
// is the city chart framed on it, a numbered pin on the building of each way
// and the ways as rows under the map; the town is the
// whole city with its districts as rows; the three tabs and the − / + move
// between district, town and world.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/city_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/widgets/journey_world_map.dart';
import 'support/pump.dart';
import 'support/open_game.dart';

/// The way rows under the map (keyed by the step they take).
final _rows = find.byWidgetPredicate((w) =>
    w.key is ValueKey<String> &&
    (w.key as ValueKey<String>).value.startsWith('journey_city_row_'));

void main() {
  testWidgets('the district, the town and the world, as board 15 draws them',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(400, 860));

    final container = await openGame(tester);
    final play = container.read(storyPlayProvider.notifier);
    play.jumpTo('2005');
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 6));
    // What arriving somewhere opens over the game (a new place's card) is
    // closed.
    for (var i = 0; i < 3; i++) {
      Navigator.of(tester.element(find.byType(JourneyScreen)))
          .popUntil(isGameRoute);
      await tester.pump(const Duration(seconds: 1));
    }
    expect(container.read(currentCityProvider), 'saltmouth');

    // The district: the chart, its places as rows (one for each pin),
    // under the three tabs.
    expect(find.byKey(const ValueKey('journey_city_chart')), findsOneWidget);
    expect(_rows, findsOneWidget);
    expect(find.textContaining('PLACES HERE'), findsOneWidget);
    // No "Walk on" chips: the other districts are the chart's and the
    // Town tab's to open.
    expect(find.textContaining('WALK ON'), findsNothing);
    expect(find.byKey(const Key('journey_level_tabs')), findsOneWidget);
    expect(find.byKey(const ValueKey('journey_step_0')), findsNothing);

    // A row opens the way's sheet, with Go and Not now.
    await tester.tap(_rows);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('journey_city_not_now')), findsOneWidget);
    await tester
        .ensureVisible(find.byKey(const ValueKey('journey_city_not_now')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('journey_city_not_now')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('journey_city_not_now')), findsNothing);

    // − looks out at the whole town: its districts as rows, here marked.
    await tester.tap(find.byKey(const Key('journey_place_zoom_out')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining('THE DISTRICTS'), findsOneWidget);
    expect(find.text('You are here'), findsOneWidget);
    expect(find.byKey(const Key('journey_town_zoom_in')), findsOneWidget);
    expect(_rows, findsNothing);

    // The District tab goes back in; the World tab out to the sphere.
    await tester.tap(find.byKey(const Key('journey_tab_district')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(_rows, findsOneWidget);
    await tester.tap(find.byKey(const Key('journey_tab_world')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(JourneyWorldMap), findsOneWidget);

    // From the world the Town tab comes back to the whole town.
    await tester.tap(find.byKey(const Key('journey_tab_town')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(JourneyWorldMap), findsNothing);
    expect(find.textContaining('THE DISTRICTS'), findsOneWidget);
    final error = tester.takeException();
    expect(error, isNull,
        reason: error is FlutterError ? error.toStringDeep() : '$error');
  });
}
