// Arriving at a place (v1.442, docs/proposals/scene-vs-map-flow.md): the
// scene of a place the party walked to opens in a sheet over the map (S2),
// the main story keeps the full page (S1), and an errand's one-tap return to
// its hub says "You came back to ...".
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/choice_flow.dart';
import 'package:narrative_data_app/data/geography.dart' show Geography;
import 'package:narrative_data_app/providers/choice_flow_provider.dart';
import 'package:narrative_data_app/providers/geography_provider.dart';
import 'package:narrative_data_app/widgets/arrival_sheet.dart';
import 'package:narrative_data_app/widgets/return_notice.dart';

void main() {
  testWidgets('the arrival sheet: a place, its words, Continue',
      (tester) async {
    var continued = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(children: [
          const Center(child: Text('the map')),
          Positioned.fill(
            child: ArrivalSheet(
              title: 'Card Row',
              continueLabel: 'Continue',
              closeTip: 'Continue',
              onContinue: () => continued++,
              child: const Text('A cold lamp swings over the tables.'),
            ),
          ),
        ]),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('journey_arrival_title')), findsOneWidget);
    expect(find.text('Card Row'), findsOneWidget);
    expect(find.text('A cold lamp swings over the tables.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('journey_continue')));
    expect(continued, 1);
    // The dimmed map is Continue too.
    await tester.tapAt(const Offset(40, 40));
    expect(continued, 2);
  });

  testWidgets('the return notice names the hub, fades, and clears itself',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(ProviderScope(
      // The world is not loaded: a stop it does not name.
      overrides: [geographyProvider.overrideWithValue(Geography.empty)],
      child: const MaterialApp(
        home: Scaffold(body: ReturnNoticeHost(child: SizedBox.expand())),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    expect(find.byKey(const Key('return_notice')), findsNothing);
    container.read(lastReturnProvider.notifier).state =
        (hubNodeId: '2015', hubStop: 'unknown_stop', fromNodeId: '2015_bazaar');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('return_notice')), findsOneWidget);
    // A stop the geography doesn't name: the notice says it plainly.
    expect(find.text('You came back'), findsOneWidget);
    await tester.pump(returnNoticeStay + const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('return_notice')), findsNothing);
    expect(container.read(lastReturnProvider), isNull);
  });

  test('which view a scene opens in', () {
    ArrivalView view(ChoiceFlow flow,
            {bool main = false, bool detour = false}) =>
        arrivalViewOf(flow, mainStory: main, inExcursion: detour);
    // A place's scene rises as a sheet, whether the party stayed, walked or
    // was carried.
    expect(view(const FlowStay()), ArrivalView.sheet);
    expect(view(const FlowMap('saltmouth_card_row')), ArrivalView.sheet);
    expect(view(const FlowTripThenArrive('saltmouth_yard')), ArrivalView.sheet);
    // The main story is read as a full page, and so is a detour's scene.
    expect(view(const FlowStay(), main: true), ArrivalView.page);
    expect(
        view(const FlowMap('saltmouth_wharf'), main: true), ArrivalView.page);
    expect(view(const FlowStay(), detour: true), ArrivalView.page);
    // A one-tap return to a hub opens nothing: it has its notice.
    expect(view(const FlowReturnToHub('saltmouth_wharf', '2015')),
        ArrivalView.none);
    expect(view(const FlowReturnToHub('saltmouth_wharf', '2015'), main: true),
        ArrivalView.none);
  });
}
