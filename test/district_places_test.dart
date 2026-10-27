// The district as places on the Journey's view (v1.582,
// lib/widgets/district_places.dart): Core's entries matched to the steps
// that are drawn, the rows, the pin card and the handle.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/city_camera.dart';
import 'package:narrative_data_app/data/way_places.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/widgets/district_places.dart';

StoryChoice _c(String id) => StoryChoice(text: id, nextId: id);

void main() {
  // A scene of four choices, the second hidden by a gate (so the Journey
  // draws three steps from them).
  final choices = [_c('a'), _c('b'), _c('c'), _c('d')];
  final steps = [choices[0], choices[2], choices[3]];
  const here = WayPlace.here();
  const quay = WayPlace.building('b1');
  const gate = WayPlace.wayOut('road');

  List<PlaceInfo>? infos(
    List<WayPlaceEntry> entries, {
    List<bool> locked = const [false, false, false],
    Iterable<int> shown = const [0, 1, 2],
  }) =>
      placeInfosOf(
        entries: entries,
        nodeChoices: choices,
        stepChoices: steps,
        stepLocked: locked,
        stepLabels: const ['do a', 'do c', 'do d'],
        shown: shown,
        nameOf: (p) => p.isHere ? 'Here' : p.id,
      );

  group('placeInfosOf', () {
    test('maps the scene\'s ways to the steps left after the hidden ones', () {
      final list = infos(const [
        WayPlaceEntry(place: here, ways: [0, 1], openCount: 2),
        WayPlaceEntry(place: quay, ways: [2], main: true, openCount: 1),
        WayPlaceEntry(place: gate, ways: [3], openCount: 1),
      ])!;
      // Way 1 is hidden: the here place holds step 0 only.
      expect(list[0].steps, [0]);
      expect(list[1].steps, [1]);
      expect(list[2].steps, [2]);
      expect(list.map((p) => p.here), [true, false, false]);
      expect(list.map((p) => p.wayOut), [false, false, true]);
      expect(list[1].main, isTrue);
      expect(list[0].name, 'Here');
      expect(list[1].name, 'building:b1');
      // What there is to do here is its note.
      expect(list[0].note, 'do a');
    });

    test('counts what is open, and a place with nothing open is shut', () {
      final list = infos(const [
        WayPlaceEntry(place: here, ways: [0, 2], openCount: 2),
        WayPlaceEntry(place: quay, ways: [3], main: true, openCount: 1),
      ], locked: const [
        false,
        false,
        true
      ])!;
      expect(list[0].count, 2);
      expect(list[1].locked, isTrue);
      expect(list[1].count, 0);
      // A shut place says why (its way's own text, the reason) and is no
      // longer where the story goes on.
      expect(list[1].note, 'do d');
      expect(list[1].main, isFalse);
    });

    test('only the steps of the district in view', () {
      final list = infos(const [
        WayPlaceEntry(place: here, ways: [0, 2], openCount: 2),
        WayPlaceEntry(place: quay, ways: [3], openCount: 1),
      ], shown: const [
        0,
        1
      ])!;
      // The quay's way (step 2) is in another district: no entry for it.
      expect(list.map((p) => p.steps), [
        [0, 1],
      ]);
    });

    test('null when a step is in no place: the Journey keeps its list', () {
      expect(
          infos(const [
            WayPlaceEntry(place: here, ways: [0], openCount: 1),
          ]),
          isNull);
    });

    test('a scene read from another node (an excursion) matches nothing', () {
      final list = placeInfosOf(
        entries: const [
          WayPlaceEntry(place: here, ways: [0, 1], openCount: 2),
        ],
        nodeChoices: [_c('x'), _c('y')],
        stepChoices: steps,
        stepLocked: const [false, false, false],
        stepLabels: const ['a', 'c', 'd'],
        shown: const [0, 1, 2],
        nameOf: (p) => p.id,
      );
      expect(list, isNull);
    });
  });

  group('the pieces', () {
    Widget host(Widget child) => MaterialApp(
          home: Scaffold(body: Center(child: child)),
        );
    const named = PlaceInfo(
        id: 'building:b1',
        name: 'The harbor master’s office',
        steps: [1],
        count: 2,
        main: true);
    const unnamed =
        PlaceInfo(id: 'building:b2', name: '', steps: [2], count: 1);
    const shut = PlaceInfo(
        id: 'building:b3',
        name: 'The bounty door',
        steps: [3],
        count: 0,
        locked: true,
        note: 'Opens after the Crows’ toll');

    testWidgets('a row: name, the flag where the story goes on, the count',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(PlaceRow(
          info: named,
          noName: '(no name yet)',
          goesOn: 'The story goes on here',
          onTap: () => taps++)));
      expect(find.text('The harbor master’s office'), findsOneWidget);
      expect(find.text('The story goes on here'), findsOneWidget);
      expect(find.byIcon(Icons.flag), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('place_row_building:b1')));
      expect(taps, 1);
    });

    testWidgets('a place with no name says so; a shut one gives its reason',
        (tester) async {
      await tester.pumpWidget(host(Column(children: [
        PlaceRow(
            info: unnamed, noName: '(no name yet)', goesOn: '', onTap: () {}),
        PlaceRow(info: shut, noName: '(no name yet)', goesOn: '', onTap: () {}),
      ])));
      expect(find.text('(no name yet)'), findsOneWidget);
      expect(find.text('Opens after the Crows’ toll'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsWidgets);
      // A shut place has no count.
      expect(find.text('0'), findsNothing);
    });

    testWidgets('the card: the name, how many things, Go', (tester) async {
      var went = 0;
      await tester.pumpWidget(host(PlaceCard(
          info: named,
          noName: '(no name yet)',
          things: '2 things to do',
          go: 'Go',
          onGo: () => went++)));
      expect(find.text('The harbor master’s office'), findsOneWidget);
      expect(find.text('2 things to do'), findsOneWidget);
      await tester.tap(find.byKey(const Key('place_card_go')));
      expect(went, 1);
    });

    testWidgets('the handle: how many places, or Map once open',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(PlacesHandle(
          open: false, label: 'Places · 10', onTap: () => taps++)));
      expect(find.text('Places · 10'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      await tester.tap(find.text('Places · 10'));
      expect(taps, 1);
      await tester.pumpWidget(
          host(PlacesHandle(open: true, label: 'Map', onTap: () {})));
      expect(find.text('Map'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });
  });

  test('a camera shot waits for a chart and is not replayed to the next', () {
    final camera = CityChartCamera();
    expect(camera.pending, isFalse);
    camera.show(const CityCameraShot.arrival('d'));
    expect(camera.pending, isTrue);
    // A chart took it: one built later does not take it again.
    camera.taken();
    expect(camera.pending, isFalse);
    camera.show(const CityCameraShot.full('d'));
    expect(camera.pending, isTrue);
    camera.dispose();
  });
}
