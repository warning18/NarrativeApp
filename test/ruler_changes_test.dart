// The crossing's ruler and the towns that changed hands (wave 17, UX,
// finishing two wave 16 pieces): a crossing on land a clan holds wears the
// clan's colour under its title and says who holds the road; the layers
// sheet lists the towns that changed hands since the player last looked.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/land_crossing.dart';
import 'package:narrative_data_app/providers/clans_provider.dart';
import 'package:narrative_data_app/providers/geography_provider.dart';
import 'package:narrative_data_app/screens/land_crossing_screen.dart';
import 'package:narrative_data_app/widgets/handover_list.dart';
import 'package:narrative_data_app/widgets/town_handover.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

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

  test(
      'a town named again replaces its old entry, newest first, and the '
      'list keeps no more than eight', () {
    const a = TownHandover('candlehold', 'compact', 'dominion');
    const b = TownHandover('ashen_landing', '', 'vigil');
    final first = withRecentHandovers(const [], [a]);
    expect(first, [a]);
    final second = withRecentHandovers(first, [b]);
    expect(second, [b, a]);
    const back = TownHandover('candlehold', 'dominion', 'compact');
    expect(withRecentHandovers(second, [back]), [back, b]);
    final many = [
      for (var i = 0; i < 12; i++) TownHandover('t$i', 'compact', 'dominion'),
    ];
    expect(withRecentHandovers(const [], many).length, 8);
  });

  testWidgets('the list names the town and both rulers; empty draws nothing',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      final subs = [
        container.listen(factionsProvider, (_, __) {}),
        container.listen(geographyProvider, (_, __) {}),
      ];
      addTearDown(() {
        for (final s in subs) {
          s.close();
        }
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
    });
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: HandoverList())),
    ));
    expect(find.byKey(const Key('handover_list')), findsNothing);

    container.read(recentHandoversProvider.notifier).state = const [
      TownHandover('candlehold', 'compact', 'dominion'),
      TownHandover('ashen_landing', '', 'vigil'),
    ];
    await tester.pump();
    expect(find.byKey(const Key('handover_list')), findsOneWidget);
    expect(find.byKey(const Key('handover_candlehold')), findsOneWidget);
    expect(find.textContaining('Candlehold'), findsOneWidget);
    expect(find.text('no one'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  Future<void> crossing(WidgetTester tester, String ruler) async {
    tester.view.physicalSize = const Size(480, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      final sub = container.listen(factionsProvider, (_, __) {});
      addTearDown(sub.close);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: LandCrossingScreen(
            route: _fen, events: _events, ruler: ruler, random: Random(1)),
      ),
    ));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 200));
  }

  testWidgets('a crossing on a clan\'s land wears its colour and says so',
      (tester) async {
    final factions = parseFactions(_json('assets/gamedata/factions.json'));
    expect(factions['mire'], isNotNull);
    await crossing(tester, 'mire');
    expect(find.byKey(const Key('crossing_ruler')), findsOneWidget);
    expect(find.textContaining('Held by'), findsOneWidget);
    final band =
        tester.widget<ColoredBox>(find.byKey(const Key('crossing_ruler_band')));
    expect(band.color, Color(factions['mire']!.patron.color));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a road no one holds has neither band nor line', (tester) async {
    await crossing(tester, '');
    expect(find.byKey(const Key('crossing_ruler')), findsNothing);
    expect(find.byKey(const Key('crossing_ruler_band')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pictures of the crossing and the list (UX_SHOTS=<folder>)',
      (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(960, 1400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() async {
      final subs = [
        container.listen(factionsProvider, (_, __) {}),
        container.listen(geographyProvider, (_, __) {}),
      ];
      addTearDown(() {
        for (final s in subs) {
          s.close();
        }
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
    });
    container.read(recentHandoversProvider.notifier).state = const [
      TownHandover('candlehold', 'compact', 'dominion'),
      TownHandover('ashen_landing', '', 'vigil'),
    ];
    final key = GlobalKey();
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: Column(children: [
            SizedBox(
              height: 560,
              child: LandCrossingScreen(
                  route: _fen,
                  events: _events,
                  ruler: 'mire',
                  random: Random(1)),
            ),
            const Material(child: HandoverList()),
          ]),
        ),
      ),
    ));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/ruler-and-changes.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
