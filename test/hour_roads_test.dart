// The hour on the roads and at sea (wave 17, UX, item 1): a wash and stars
// over a side-view scene by the part of the day (nothing by day), the hero's
// lantern on the Eel's deck after dark, and the crossing and the voyage
// reading the world clock. UX_SHOTS=<folder> takes a picture of each hour.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/journey_rules.dart' show DayPhase;
import 'package:narrative_data_app/data/land_crossing.dart';
import 'package:narrative_data_app/providers/day_phase_provider.dart';
import 'package:narrative_data_app/screens/land_crossing_screen.dart';
import 'package:narrative_data_app/widgets/sea_battlefield.dart';
import 'package:narrative_data_app/widgets/side_view/deck_crew.dart';
import 'package:narrative_data_app/widgets/side_view/kit_hour.dart';
import 'package:narrative_data_app/widgets/side_view/sea_kit.dart';
import 'package:narrative_data_app/widgets/side_view/side_view.dart';

const _crew = [
  DeckCrew('hero', Color(0xFFC0392B)),
  DeckCrew('maren', Color(0xFF3E7CB1)),
];

final Map<String, LandEvent> _events = landEventsFrom({
  'fen_mud': {
    'name': 'Mud',
    'name_fr': 'Boue',
    'text': 'Mud.',
    'text_fr': 'Boue.',
    'choices': [
      {
        'id': 'go',
        'text': 'Go',
        'text_fr': 'Aller',
        'outcome': {'healthPct': -2, 'note': 'n', 'note_fr': 'n'},
      },
    ],
  },
});

const LandRoute _fen = LandRoute(
  id: 'fen',
  name: 'Fen',
  from: 'cloister',
  to: 'court',
  days: 1,
  terrain: 'fen',
  events: {'fen_mud': 1},
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('nothing by day; a deeper wash and more stars as the night comes', () {
    expect(hourWash(DayPhase.day), isNull);
    expect(hourWashColour(DayPhase.day), isNull);
    final dawn = hourWashColour(DayPhase.dawn)!;
    final dusk = hourWashColour(DayPhase.dusk)!;
    final night = hourWashColour(DayPhase.night)!;
    expect(dawn.a, lessThan(dusk.a));
    expect(dusk.a, lessThan(night.a));
    expect(hourStarCount(DayPhase.day), 0);
    expect(hourStarCount(DayPhase.dawn), 0);
    expect(
        hourStarCount(DayPhase.dusk), lessThan(hourStarCount(DayPhase.night)));
  });

  test('the stars sit right behind the sky, and the day is left as it is', () {
    final layers = [
      for (var i = 0; i < 4; i++) SideLayer(0, (a, b, c, d, e) {})
    ];
    expect(withHourStars(layers, DayPhase.day), same(layers));
    final night = withHourStars(layers, DayPhase.night);
    expect(night.length, 5);
    expect(night.first, same(layers.first));
    expect(night[2], same(layers[1]));
  });

  for (final phase in DayPhase.values) {
    testWidgets('the sea at ${phase.name} paints, with the lantern after dark',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SeaSideScene(
            waters: SeaWaters.open,
            crew: _crew,
            phase: phase,
            meeting: const SeaMeeting(SeaMeetingKind.derelict),
          ),
        ),
      ));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('every kit at ${phase.name} paints', (tester) async {
      for (final terrain in ['desert', 'ruins', 'frost', 'fen', 'sea_cliffs']) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: SideViewScene(
              layers: withHourStars(crossingLayers(terrain, 0.5), phase),
              overlay: hourWash(phase),
              moving: false,
            ),
          ),
        ));
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull, reason: terrain);
      }
    });
  }

  testWidgets('the crossing reads the world clock', (tester) async {
    tester.view.physicalSize = const Size(480, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final phase in [DayPhase.day, DayPhase.night]) {
      await tester.pumpWidget(ProviderScope(
        overrides: [dayPhaseProvider.overrideWithValue(phase)],
        child: MaterialApp(
          home: LandCrossingScreen(
              route: _fen, events: _events, random: Random(1)),
        ),
      ));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('crossing_scene')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('pictures of the hours (UX_SHOTS=<folder>)', (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    Widget column(Widget Function(DayPhase) scene) => Expanded(
          child: Column(children: [for (final p in DayPhase.values) scene(p)]),
        );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RepaintBoundary(
          key: key,
          child: Row(children: [
            column((p) => Expanded(
                  child: SideViewScene(
                    layers: withHourStars(crossingLayers('fen', 0.6), p),
                    overlay: hourWash(p),
                    moving: false,
                    height: 220,
                  ),
                )),
            column((p) => Expanded(
                  child: SeaSideScene(
                    waters: SeaWaters.open,
                    crew: _crew,
                    phase: p,
                    moving: false,
                    height: 220,
                  ),
                )),
          ]),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/hour-on-roads-and-sea.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
