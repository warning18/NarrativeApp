// The travel map page (v1.276): the party's travels drawn on the story world,
// a tap on a ringed place offering the journey, on a place heard of saying it
// cannot be reached yet, and the Journey's header opening the page.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/travel_history.dart';
import 'package:narrative_data_app/providers/travel_history_provider.dart';
import 'package:narrative_data_app/screens/travel_map_screen.dart';
import 'package:narrative_data_app/theme/stitched_ink.dart';
import 'package:narrative_data_app/widgets/travel_map_view.dart';

void main() {
  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  // The wreck of the Lark, the Sleeper's Face, the White Wells.
  final travels = travelHistoryOf(
    history: const ['965', '1100', '1120', '1130'],
    currentNodeId: '1200',
  );
  final withTarget = TravelHistory(
    stops: travels.stops,
    legs: travels.legs,
    visited: travels.visited,
    heardOf: travels.heardOf,
    currentId: travels.currentId,
    travelTargets: const {'sleeper': 'no_such_scene'},
  );

  Future<void> open(WidgetTester tester, TravelHistory history) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [travelHistoryProvider.overrideWithValue(history)],
      child: MaterialApp(
        theme: buildAppTheme(ColorScheme.fromSeed(
            seedColor: Colors.amber, brightness: Brightness.dark)),
        home: const TravelMapScreen(),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
  }

  void tapPlace(WidgetTester tester, String id, TravelPlaceState state) {
    tester
        .widget<TravelMapView>(find.byKey(const Key('travel_map')))
        .onTapPlace!(id, state);
  }

  testWidgets('the page draws the travels, the order being each visit',
      (tester) async {
    await open(tester, travels);
    final view =
        tester.widget<TravelMapView>(find.byKey(const Key('travel_map')));
    expect(view.visited.first, 'crash');
    expect(view.visited.toSet(), travels.visited);
    expect(view.known, travels.heardOf);
    expect(view.here, travels.currentId);
  });

  testWidgets('a tap on a place to travel to offers the journey',
      (tester) async {
    await open(tester, withTarget);
    tapPlace(tester, 'sleeper', TravelPlaceState.visited);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('travel_offer')), findsOneWidget);
    expect(find.byKey(const Key('travel_go')), findsOneWidget);
  });

  testWidgets('a tap on a place only heard of says it cannot be reached',
      (tester) async {
    await open(tester, travels);
    final heard = travels.heardOf.first;
    tapPlace(tester, heard, TravelPlaceState.known);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('travel_place_info')), findsOneWidget);
    expect(find.textContaining('only heard of'), findsOneWidget);
    expect(find.byKey(const Key('travel_go')), findsNothing);
  });

  testWidgets('a visited place that is no way to travel tells what it is',
      (tester) async {
    await open(tester, travels);
    tapPlace(tester, 'wells', TravelPlaceState.visited);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('travel_place_info')), findsOneWidget);
    expect(find.byKey(const Key('travel_go')), findsNothing);
  });

  testWidgets('closing the map removes the map page, not what is over it',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final key = GlobalKey<NavigatorState>();
    late Route<dynamic> mapRoute;
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      home: const Scaffold(body: Text('journey')),
    ));
    mapRoute = MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('map')));
    key.currentState!.push(mapRoute);
    await tester.pumpAndSettle();
    // A notice (a route here) lands over the map.
    key.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('walked to X'))));
    await tester.pumpAndSettle();

    closeMapRoute(key.currentState!, mapRoute);
    await tester.pumpAndSettle();
    expect(find.text('walked to X'), findsOneWidget,
        reason: 'the notice stays');
    key.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('map'), findsNothing,
        reason: 'the map is gone: popping the notice lands on the journey');
    expect(find.text('journey'), findsOneWidget);
    // Closing a route that is gone is harmless.
    closeMapRoute(key.currentState!, mapRoute);
  });
}
