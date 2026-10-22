// The sea fight's entrance (wave 17, UX, item 2): a beast, the void barge
// and any ship the data marks `entranceCard` is announced by a card before
// the fight, with the hull or the beast sailing in over the water, its name
// and the first line of its story (Core's shipHasEntranceCard); the common
// raider has none. UX_SHOTS=<folder> takes a picture of the card.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/combat_engine.dart';
import 'package:narrative_data_app/data/sea_events.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/voyage_screen.dart';
import 'package:narrative_data_app/widgets/fight_entrance.dart';
import 'package:narrative_data_app/widgets/sea_battlefield.dart';
import 'package:narrative_data_app/widgets/side_view/sea_kit.dart';

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 40 && !done(); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Map<String, dynamic> _data(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

const _quiet = SeaEvent(
  kind: SeaEventKind.sighting,
  description: 'Nothing on the water.',
  descriptionFr: 'Rien sur l\'eau.',
  choiceText: 'Sail on',
  choiceTextFr: 'Poursuivre',
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('who gets a card: the beasts, the barge, the marked; not the skiff', () {
    final ships = _data('enemy_ships');
    expect(shipHasEntranceCard('brinejaw', ships['brinejaw']), isTrue);
    expect(shipHasEntranceCard('raider_skiff', ships['raider_skiff']), isFalse);
    expect(shipHasEntranceCard('void_barge', ships['void_barge']), isTrue);
    expect(shipHasEntranceCard('x', const {'entranceCard': true}), isTrue);
    expect(shipHasEntranceCard('x', null), isFalse);
  });

  testWidgets('the card shows only what she meets, not the Eel',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: FightEntrance(
          enemyId: 'brinejaw',
          name: 'The Brinejaw',
          line: 'A long pale back.',
          boss: true,
          art: SizedBox(
            width: 240,
            child: SeaSideScene(
              waters: SeaWaters.open,
              meeting: SeaMeeting(SeaMeetingKind.beast, id: 'brinejaw'),
              showShip: false,
              height: 100,
            ),
          ),
          child: SizedBox.expand(),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('fight_entrance_card')), findsOneWidget);
    expect(find.text('The Brinejaw'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pump(fightEntranceTime);
    await tester.pump(seaArrivalTime);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a beast fight opens on its card, over the water',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    tester.view.physicalSize = const Size(420, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final ports = _data('ports');
    final brinejaw = _data('enemy_ships')['brinejaw'] as Map<String, dynamic>;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(playerSessionProvider.notifier);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'gold': 100,
        })));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: VoyageScreen(
          fromPortId: 'port_ashen_landing',
          toPortId: 'port_smugglers_wharf',
          toPort: ports['port_smugglers_wharf'] as Map<String, dynamic>,
          debugRandom: Random(1),
          debugEvents:
              withBeastDay(const [_quiet, _quiet], 1, 'brinejaw', brinejaw),
        ),
      ),
    ));
    final sailOn = find.byKey(const Key('sea_choice_sailOn'));
    await _pumpUntil(tester, () => sailOn.evaluate().isNotEmpty);
    await tester.tap(sailOn);
    final fight = find.byKey(const Key('sea_choice_fight'));
    await _pumpUntil(tester, () => fight.evaluate().isNotEmpty);
    await tester.tap(fight);
    await _pumpUntil(
        tester,
        () =>
            find.byKey(const Key('fight_entrance_card')).evaluate().isNotEmpty);
    expect(find.byKey(const Key('fight_entrance_card')), findsOneWidget);
    expect(find.byKey(const Key('fight_entrance_name')), findsOneWidget);
    // It goes by itself (the fight may restart its key once as it sets up).
    await tester.pump(fightEntranceTime);
    await tester.pump(fightEntranceTime);
    await tester.pump();
    expect(find.byKey(const Key('fight_entrance_card')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pictures of the card (UX_SHOTS=<folder>)', (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(1080, 700);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    Widget card(String id, String name, String line, bool beast) => Expanded(
          child: FightEntrance(
            enemyId: id,
            name: name,
            line: line,
            boss: beast,
            art: SizedBox(
              width: 240,
              child: SeaSideScene(
                waters: SeaWaters.open,
                meeting: SeaMeeting(
                    beast ? SeaMeetingKind.beast : SeaMeetingKind.raider,
                    id: id),
                showShip: false,
                moving: false,
                height: 100,
              ),
            ),
            child: const SizedBox.expand(),
          ),
        );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RepaintBoundary(
          key: key,
          child: Row(children: [
            card('brinejaw', 'The Brinejaw',
                'A long pale back that rises where the fish have gone.', true),
            card('corsair_brig', 'The Corsair Brig',
                'A brig under black sail, and a captain who counts.', false),
          ]),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$dir/sea-fight-entrance.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    await tester.pump(const Duration(seconds: 3));
  });
}
