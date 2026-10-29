// The district view as places (v1.586) on the Journey, at the Landward Gate
// (scene 2015_informant: the party's own place and a building's): the map
// alone with its handle, the arrival's ease, a pin's card, the list rising at
// full zoom, a place's ways, the way back.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/providers/city_provider.dart';
import 'package:narrative_data_app/providers/home_tab_provider.dart';
import 'package:narrative_data_app/providers/story_providers.dart';
import 'package:narrative_data_app/screens/journey_screen.dart';
import 'package:narrative_data_app/widgets/city_chart/city_chart_view.dart';

import 'district_places_steps.dart';
import 'support/pump.dart';
import 'support/open_game.dart';

final _list = find.byKey(const ValueKey('journey_city_list'));
final _ways = find.byWidgetPredicate((w) =>
    w.key is ValueKey<String> &&
    (w.key as ValueKey<String>).value.startsWith('journey_city_row_'));

void main() {
  testWidgets('the map first, the places one tap away, a place\'s ways',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({'tutorial_enabled': false});
    usePhone(tester, const Size(400, 860));

    final container = await openGame(tester);
    container.read(storyPlayProvider.notifier).jumpTo('2015_informant');
    await settleApp(tester);
    await tester.tap(find.text('Journey'));
    await settleApp(tester);
    await tester.pump(const Duration(seconds: 6));
    for (var i = 0; i < 3; i++) {
      Navigator.of(tester.element(find.byType(JourneyScreen)))
          .popUntil(isGameRoute);
      await tester.pump(const Duration(seconds: 1));
    }
    expect(container.read(currentCityProvider), 'saltmouth');

    // The map has the room: no list, no words on the pins, the handle says
    // how many places there are, and the arrival eased the camera in.
    final view = tester.widget<CityChartView>(find.byType(CityChartView));
    expect(_list, findsNothing);
    expect(placeRows, findsNothing);
    expect(view.buildingNames, isFalse);
    final places = container.read(districtPlacesProvider);
    expect(places.length, greaterThan(1));
    final handle = find.textContaining('Places · ');
    expect(handle, findsOneWidget);
    final count = int.parse(
        RegExp(r'\d+').firstMatch(tester.widget<Text>(handle).data!)![0]!);
    expect(count, greaterThan(0));
    expect(view.camera!.shots, greaterThan(0));
    expect(view.camera!.shot!.zoom, 1.25);

    // A way's pin in the party's own district.
    final district = container.read(partyDistrictProvider);
    final pin = view.chart.ways
        .firstWhere((w) => view.chart.districts[w.district].id == district);
    // A tap on a pin shows its place's card, and does not open the scene.
    final node = container.read(storyPlayProvider).currentNodeId;
    view.onPick!(pin);
    await tester.pump();
    expect(find.byKey(const Key('place_card')), findsOneWidget);
    expect(container.read(storyPlayProvider).currentNodeId, node);
    // A second tap on it folds it.
    view.onPick!(pin);
    await tester.pump();
    expect(find.byKey(const Key('place_card')), findsNothing);

    // The handle: the map goes to its full zoom and the list rises, one row
    // per place (the way texts are not rows of it); the handle reads Map.
    await raisePlaces(tester);
    expect(_list, findsOneWidget);
    expect(placeRows, findsNWidgets(count));
    expect(_ways, findsNothing);
    expect(find.text('Map'), findsOneWidget);
    // Map folds the list back.
    await tester.tap(find.text('Map'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(_list, findsNothing);
    expect(find.text('Places · $count'), findsOneWidget);

    // A card's Go takes the party to the place: its ways show, with a way
    // back to the list; nothing was taken yet.
    view.onPick!(pin);
    await tester.pump();
    await tester.tap(find.byKey(const Key('place_card_go')));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(container.read(partyPlaceProvider), isNotNull);
    expect(_ways, findsWidgets);
    expect(find.byKey(const Key('place_back')), findsOneWidget);
    expect(find.byKey(const Key('places_handle')), findsNothing);
    expect(container.read(storyPlayProvider).currentNodeId, node);

    // Back to the list of places.
    await tester.tap(find.byKey(const Key('place_back')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(partyPlaceProvider), isNull);
    expect(_ways, findsNothing);
    final error = tester.takeException();
    expect(error, isNull,
        reason: error is FlutterError ? error.toStringDeep() : '$error');
  });
}
