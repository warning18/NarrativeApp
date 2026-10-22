// The sea as the land (wave 16, UX): the party stands on the Eel's deck in
// side view (the hero at the helm, the companions behind, on every hull's
// rail), what she meets sails in from the right edge, and a companion may
// speak up as a voyage casts off (Core's speakUpAtSea), as a bubble over
// their figure. UX_SHOTS=<folder> takes a picture of the deck.
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

import 'package:narrative_data_app/data/companion_remarks.dart';
import 'package:narrative_data_app/data/sea_events.dart';
import 'package:narrative_data_app/data/ship_forms.dart';
import 'package:narrative_data_app/models/ally_state.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/remark_provider.dart';
import 'package:narrative_data_app/providers/walking_party_provider.dart';
import 'package:narrative_data_app/screens/voyage_screen.dart';
import 'package:narrative_data_app/widgets/sea_battlefield.dart';
import 'package:narrative_data_app/widgets/side_view/deck_crew.dart';
import 'package:narrative_data_app/widgets/side_view/sea_kit.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

const _party = [
  WalkingPartyMember(id: 'hero', spriteKey: 'hero'),
  WalkingPartyMember(id: 'maren', spriteKey: 'companion_maren'),
  WalkingPartyMember(id: 'tobias', spriteKey: 'companion_tobias'),
];

void main() {
  test('the crew is the party: the hero in red, each companion in their own',
      () {
    final crew = deckCrewOf(_party);
    expect(crew.map((c) => c.id), ['hero', 'maren', 'tobias']);
    expect(crew.first.isHero, isTrue);
    expect(crew.first.cloak, const Color(0xFFC0392B));
    expect(crew[1].cloak, isNot(crew[2].cloak));
    // The same colours the next time.
    expect(deckCrewOf(_party), crew);
  });

  test('the hero stands nearest the helm, the others behind, all aboard', () {
    final at = deckCrewAt(3);
    expect(at[0], greaterThan(at[1]));
    expect(at[1], greaterThan(at[2]));
    expect(at.every((f) => f > 0.1 && f < 0.9), isTrue);
    // On the scene's grid the hero is on the hull whatever the hull.
    for (final len in [30.0, 36.0, 60.0]) {
      final x = deckCrewX(0, 3, len, 160);
      expect(x, greaterThan(seaShipX(len, 160)));
      expect(x, lessThan(seaShipX(len, 160) + len));
    }
  });

  final ships = _table('ships');
  for (final entry in ships.entries) {
    final record = entry.value;
    if (record is! Map<String, dynamic>) continue;
    testWidgets('the crew stands on the ${entry.key}', (tester) async {
      final form = ShipForm.fromRecord(entry.key, record);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SeaSideScene(
            waters: SeaWaters.open,
            ship: form,
            crew: deckCrewOf(_party),
          ),
        ),
      ));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('what she meets sails in, and stands at once without motion',
      (tester) async {
    Widget scene({bool reduced = false}) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: const Scaffold(
              body: SeaSideScene(
                waters: SeaWaters.open,
                meeting: SeaMeeting(SeaMeetingKind.raider, id: 'raider_skiff'),
                crew: [DeckCrew('hero', Color(0xFFC0392B))],
              ),
            ),
          ),
        );
    await tester.pumpWidget(scene());
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    await tester.pump(seaArrivalTime);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(scene(reduced: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a companion speaks up as the voyage casts off, once',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(420, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final ports = _table('ports');
    final book = RemarkBook({
      'maren_atSea': {
        'companionID': 'maren',
        'trigger': 'atSea',
        'lines': ['The water is kind today.'],
        'lines_fr': ['L’eau est douce aujourd’hui.'],
      },
    });
    final container = ProviderContainer(
        overrides: [remarkBookProvider.overrideWith((ref) => book)]);
    addTearDown(container.dispose);
    final notifier = container.read(playerSessionProvider.notifier);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
          'raceId': 'human',
          'professionId': 'warrior',
          'gold': 100,
          'recruitedAllies': [
            AllyState(
                    companionId: 'maren',
                    currentHealth: AllyState.fullHealthSentinel)
                .toJson(),
          ],
          'activeAllyIds': ['maren'],
        })));

    const wreck = SeaEvent(
      kind: SeaEventKind.derelict,
      description: 'A wreck.',
      descriptionFr: 'Une épave.',
      choiceText: 'Salvage what floats',
      choiceTextFr: 'Récupérer ce qui flotte',
      gold: 40,
    );
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: VoyageScreen(
          fromPortId: 'port_ashen_landing',
          toPortId: 'port_smugglers_wharf',
          toPort: ports['port_smugglers_wharf'] as Map<String, dynamic>,
          // A natural 1 or 20 settles a check: seeded, so no run differs.
          debugRandom: Random(1),
          debugEvents: const [wreck, wreck],
        ),
      ),
    ));
    for (var i = 0;
        i < 40 && find.byKey(const Key('sea_bubble')).evaluate().isEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const Key('voyage_scene')), findsOneWidget);
    expect(find.byKey(const Key('sea_bubble')), findsOneWidget);
    expect(find.text('The water is kind today.'), findsOneWidget);
    // The chapter's turn is spent: the bubble goes by itself.
    expect(
        container.read(playerSessionProvider).seaRemarkChapter, greaterThan(0));
    await tester.pump(const Duration(seconds: 8));
    expect(find.byKey(const Key('sea_bubble')), findsNothing);
  });

  testWidgets('pictures of the deck (UX_SHOTS=<folder>)', (tester) async {
    final dir = Platform.environment['UX_SHOTS'];
    if (dir == null) return;
    tester.view.physicalSize = const Size(720, 1500);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    final forms = [
      for (final id in ['rusty_eel', 'galleon', 'ironclad', 'twin_hull'])
        if (ships[id] is Map<String, dynamic>)
          ShipForm.fromRecord(id, ships[id] as Map<String, dynamic>),
    ];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RepaintBoundary(
          key: key,
          child: Column(children: [
            for (final form in [null, ...forms])
              SeaSideScene(
                waters: SeaWaters.open,
                ship: form,
                crew: deckCrewOf(_party),
                moving: false,
                meeting: const SeaMeeting(SeaMeetingKind.derelict),
                height: 110,
              ),
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
      File('$dir/sea-crew-on-deck.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
