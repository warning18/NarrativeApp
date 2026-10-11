// The Eel's hulls (v1.228): ten sea hulls and four flying boats in
// ships.json, each with its outline and rig, rebuilt at the Harbor (parts
// that lose their slot wait in the store), several painted sails at once,
// the lift of a flying hull, and the ship drawn as pixel art.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/data/sail_powers.dart';
import 'package:narrative_data_app/data/sea_events.dart';
import 'package:narrative_data_app/data/ship_forms.dart';
import 'package:narrative_data_app/providers/chapter_loop_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/harbor_screen.dart';
import 'package:narrative_data_app/screens/voyage_screen.dart';
import 'package:narrative_data_app/widgets/sea_battlefield.dart';
import 'package:narrative_data_app/widgets/ship_dress.dart';

Map<String, dynamic> _data(String name) =>
    json.decode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

Future<void> _pumpUntil(WidgetTester tester, bool Function() done) async {
  for (var i = 0; i < 40 && !done(); i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final ships = _data('ships');
  final parts = _data('ship_parts');
  final looks = _data('ship_looks');
  Map<String, dynamic> hull(String id) => ships[id] as Map<String, dynamic>;

  group('the hulls on file', () {
    test('ten sea hulls and four flying boats, the Eel\'s own the sloop', () {
      expect(ships.length, 14);
      expect(ships.values.where((h) => (h as Map)['flying'] == true).length, 4);
      final eel = hull('rusty_eel');
      expect(eel['hullName'], 'Sloop');
      expect(eel['baseMaxHull'], 100);
      expect(eel['weaponSlots'], 2);
      expect(eel['shieldSlots'], 1);
      expect(eel['utilitySlots'], 1);
      expect(eel['sailSlots'], 1);
      expect(eel['hullCost'], 0);
      for (final entry in ships.entries) {
        final h = entry.value as Map<String, dynamic>;
        expect(h['shipID'], entry.key);
        expect(h['hullName']?.toString() ?? '', isNotEmpty, reason: entry.key);
        expect(h['hullName_fr']?.toString() ?? '', isNotEmpty,
            reason: entry.key);
        expect(h['description_fr']?.toString() ?? '', isNotEmpty,
            reason: entry.key);
        expect((h['baseMaxHull'] as num).toInt(), greaterThan(0));
        // Every hull keeps all four rooms: a battle stations a hand in each.
        final rooms = h['rooms'] as Map<String, dynamic>;
        for (final room in ShipRoom.values) {
          expect((rooms[room.name] as num).toInt(), greaterThanOrEqualTo(1),
              reason: '${entry.key} ${room.name}');
        }
        expect(HullKind.values.map((k) => k.name), contains(h['kind']));
        expect((h['unlockChapter'] as num).toInt(), inInclusiveRange(0, 6));
        expect((h['hullCost'] as num).toInt(), greaterThanOrEqualTo(0));
      }
      // Hull names are told apart, in both languages.
      expect({for (final h in ships.values) (h as Map)['hullName']}.length, 14);
      expect(
          {for (final h in ships.values) (h as Map)['hullName_fr']}.length, 14);
    });

    test('a sail slot is a mast to paint, and the hulls climb in price', () {
      for (final entry in ships.entries) {
        final h = entry.value as Map<String, dynamic>;
        final form = ShipForm.fromRecord(entry.key, h);
        expect((h['sailSlots'] as num).toInt(),
            lessThanOrEqualTo(form.masts.length),
            reason: '${entry.key} has a sail slot with no mast to paint');
        // Painted sigils need sails: a hull with none has no sail slot.
        if (form.masts.isEmpty) {
          expect(h['sailSlots'], 0, reason: entry.key);
        }
      }
      // Bigger and later hulls cost more, within the sea hulls and within
      // the flying ones.
      for (final flying in [false, true]) {
        final ids = hullIdsInOrder(ships)
            .where((id) => (hull(id)['flying'] == true) == flying)
            .toList();
        for (var i = 1; i < ids.length; i++) {
          expect(
              (hull(ids[i])['hullCost'] as num).toInt(),
              greaterThanOrEqualTo(
                  (hull(ids[i - 1])['hullCost'] as num).toInt()));
        }
      }
      expect(hullIdsInOrder(ships).first, 'rusty_eel');
      expect(hull(hullIdsInOrder(ships).last)['flying'], true);
    });

    test(
        'an outline is a hull: widest where it says, never wider than the beam',
        () {
      for (final entry in ships.entries) {
        final form =
            ShipForm.fromRecord(entry.key, entry.value as Map<String, dynamic>);
        for (var i = 0; i <= 20; i++) {
          final w = form.widthAt(i / 20);
          expect(w, inInclusiveRange(0, 1.0001), reason: '${entry.key} @$i');
        }
        expect(form.widthAt(form.u0), closeTo(1, 0.001));
        final box = form.outline(0, 0, 100, 40).getBounds();
        expect(box.left, closeTo(0, 0.01));
        expect(box.right, closeTo(100, 0.01));
        expect(box.height, lessThanOrEqualTo(40.01));
      }
    });

    test('a hull is the ship the battle is built from', () {
      for (final entry in ships.entries) {
        final h = entry.value as Map<String, dynamic>;
        final built = buildPlayerShip(
            ship: h,
            parts: parts,
            installedPartIds: const ['ballista'],
            currentHull: -1);
        expect(built.maxHull, h['baseMaxHull'], reason: entry.key);
        expect(built.room(ShipRoom.helm).level, (h['rooms'] as Map)['helm'],
            reason: entry.key);
        expect(built.weapons, hasLength(1));
      }
    });

    test('the parts that lose their slot on a new hull are the ones past it',
        () {
      final installed = [
        'ballista',
        'harpoon_rack',
        'iron_plating',
        'tar_sealed_hull',
        'sail_wind_knot',
      ];
      List<String> beyond(String id) => partsBeyondSlots(
          ship: hull(id), parts: parts, installedPartIds: installed);
      expect(beyond('rusty_eel'), isEmpty);
      // The longboat has one gun slot, no shield slot.
      expect(beyond('longboat'), ['harpoon_rack', 'iron_plating']);
      expect(beyond('galleon'), isEmpty);
      // The ironclad has no sail to paint.
      expect(beyond('ironclad'), ['sail_wind_knot']);
    });

    test('the Harbor builds a hull from its chapter on, or when built before',
        () {
      expect(hullUnlocked(hull('brig'), 2, false), isFalse);
      expect(hullUnlocked(hull('brig'), 3, false), isTrue);
      expect(hullUnlocked(hull('galleon'), 1, true), isTrue);
      expect(hullUnlocked(hull('rusty_eel'), 0, false), isTrue);
      expect(hullRecordOf(ships, 'nope'), same(ships['rusty_eel']));
      expect(hullRecordOf(ships, 'galleon'), same(ships['galleon']));
    });
  });

  group('rebuilding', () {
    test('a hull is paid for once; the parts with no slot go to the store',
        () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(playerSessionProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await notifier.loadSession(PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'gold': 500,
        'shipHull': 60,
        'shipPartIds': ['ballista', 'harpoon_rack', 'iron_plating'],
      }));
      // Too dear.
      expect(await notifier.rebuildHull('galleon', 1800), isFalse);
      // Longboat: 60 gold, with a gun and the plating left out.
      expect(
          await notifier.rebuildHull('longboat', 60,
              toStore: const ['harpoon_rack', 'iron_plating'], hull: 30),
          isTrue);
      var session = container.read(playerSessionProvider);
      expect(session.shipHullId, 'longboat');
      expect(session.gold, 440);
      expect(session.ownedHullIds, ['rusty_eel', 'longboat']);
      expect(session.shipPartIds, ['ballista']);
      expect(session.storedShipPartIds, ['harpoon_rack', 'iron_plating']);
      expect(session.shipHull, 30);
      // Not again on the hull she is on.
      expect(await notifier.rebuildHull('longboat', 60), isFalse);
      // Back to the sloop for nothing: she was built on it before.
      expect(await notifier.rebuildHull('rusty_eel', 999), isTrue);
      session = container.read(playerSessionProvider);
      expect(session.gold, 440);
      expect(session.shipHullId, 'rusty_eel');
      // And it all survives a save.
      final again = PlayerSession.fromJson(session.toJson());
      expect(again.shipHullId, 'rusty_eel');
      expect(again.ownedHullIds, session.ownedHullIds);
      expect(again.storedShipPartIds, session.storedShipPartIds);
      // An old save has the sloop.
      final old = PlayerSession.fromJson(
          {'raceId': 'human', 'professionId': 'warrior'});
      expect(old.shipHullId, 'rusty_eel');
      expect(old.ownedHullIds, ['rusty_eel']);
    });
  });

  group('several painted sails', () {
    test('one of each power counts, in the order they were fitted', () {
      final sails = installedSails(parts, [
        'ballista',
        'sail_wind_knot',
        'sail_tide_ink', // wind-knot again: it does not count
        'sail_orchard_eye',
        'sail_ember_ink',
      ]);
      expect(sails.map((s) => s.power), [
        SailPower.windknot,
        SailPower.foresight,
        SailPower.hearth,
      ]);
      expect(installedSail(parts, ['ballista']), isNull);
    });

    test('a battle takes foresight, wind-knot and the void volley from them',
        () {
      final all = battleSailsOf(parts,
          ['sail_krakens_eye', 'sail_wind_knot', 'sail_void_mark'], 'human');
      expect(all.foresight, isTrue);
      expect(all.windKnot, isTrue);
      expect(all.voidPartId, 'sail_void_mark');
      // Painted in her own people's way, the volley holds twice as strong.
      expect(all.voidStrength, 1);
      expect(
          battleSailsOf(parts, ['sail_void_mark'], 'voidkin').voidStrength, 2);
      final none = battleSailsOf(parts, ['ballista'], 'human');
      expect(none.foresight, isFalse);
      expect(none.voidPartId, isNull);
    });

    test('a bigger hull carries a sigil on each of its sails', () {
      final dress = buildShipDress(
        ship: hull('brigantine'),
        parts: parts,
        installed: const [
          'ballista',
          'sail_wind_knot',
          'sail_orchard_eye',
          'sail_ember_ink',
        ],
        lookRecords: looks,
      );
      // The brigantine has two sail slots: the third sail stays in the hold.
      expect(dress.sigils.map((s) => s.power),
          [SailPower.windknot, SailPower.foresight]);
      // The sloop has one.
      expect(
          buildShipDress(
                  ship: hull('rusty_eel'),
                  parts: parts,
                  installed: const [
                    'ballista',
                    'sail_wind_knot',
                    'sail_orchard_eye'
                  ],
                  lookRecords: looks)
              .sigils,
          hasLength(1));
    });

    test('trying a sail of a power already aboard paints over it', () {
      expect(
          fittedWith(
              ship: hull('galleon'),
              parts: parts,
              installed: ['ballista', 'sail_wind_knot', 'sail_orchard_eye'],
              partId: 'sail_tide_ink'),
          ['ballista', 'sail_orchard_eye', 'sail_tide_ink']);
    });
  });

  group('drawn as pixel art', () {
    test('every hull paints, flipped, battered and smooth, without a fault',
        () {
      final dressParts = [
        'siege_ballista',
        'dragonfire_cannon',
        'dwarven_bulwark',
        'admirals_standard',
        'sail_wind_knot',
        'sail_orchard_eye',
        'sail_cooks_knot',
        'sail_void_mark',
      ];
      for (final entry in ships.entries) {
        final h = entry.value as Map<String, dynamic>;
        final dress = buildShipDress(
            ship: h, parts: parts, installed: dressParts, lookRecords: looks);
        final look = TopShipLook.player(ShipForm.fromRecord(entry.key, h))
            .dressed(dress);
        for (final pixel in [0.0, 3.0]) {
          for (final flip in [false, true]) {
            final recorder = ui.PictureRecorder();
            TopShipPainter(
              look: look,
              flip: flip,
              facingDown: flip,
              t: 2.2,
              layers: 2,
              maxLayers: 3,
              battered: flip,
              down: const {ShipRoom.hold},
              burning: const {ShipRoom.guns},
              water: 0.6,
              shield: Colors.cyan,
              foam: Colors.white,
              roomColors: {for (final r in ShipRoom.values) r: Colors.grey},
              refit: 2,
              dress: dress,
              pixel: pixel,
            ).paint(Canvas(recorder), const Size(380, 190));
            recorder.endRecording().dispose();
          }
        }
      }
    });

    testWidgets('the ship is drawn on a grid of art pixels by default',
        (tester) async {
      final look = TopShipLook.rustyEel;
      final painter = TopShipPainter(
        look: look,
        flip: false,
        facingDown: false,
        t: 0,
        layers: 0,
        maxLayers: 0,
        battered: false,
        down: const {},
        burning: const {},
        water: 0,
        shield: Colors.cyan,
        foam: Colors.white,
        roomColors: {for (final r in ShipRoom.values) r: Colors.grey},
      );
      expect(painter.pixel, 3);
      // A beast is a sprite, drawn as it is.
      expect(TopShipLook.forEnemy('brinejaw', _anyShip()).beast, isNotNull);
    });
  });

  group('the Harbor rebuilds her', () {
    setUp(rootBundle.clear);

    Future<ProviderContainer> pumpHarbor(
      WidgetTester tester, {
      int chapter = 3,
      int gold = 2000,
      List<String> shipPartIds = const ['ballista', 'harpoon_rack'],
      List<String> ownedHullIds = const ['rusty_eel'],
    }) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(420, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final container = ProviderContainer(
          overrides: [reachedChapterProvider.overrideWithValue(chapter)]);
      addTearDown(container.dispose);
      final notifier = container.read(playerSessionProvider.notifier);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
            'raceId': 'human',
            'professionId': 'warrior',
            'gold': gold,
            'currentPortId': 'port_ashen_landing',
            'shipPartIds': shipPartIds,
            'ownedHullIds': ownedHullIds,
          })));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HarborScreen()),
      ));
      await _pumpUntil(tester,
          () => find.byKey(const Key('hull_section')).evaluate().isNotEmpty);
      return container;
    }

    Future<void> drain(WidgetTester tester) async {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('every hull is on the shelf, the later ones locked',
        (tester) async {
      await pumpHarbor(tester, chapter: 3);
      await tester.scrollUntilVisible(
          find.byKey(const Key('hull_card_brig')), 400);
      expect(find.byKey(const Key('rebuild_brig')), findsOneWidget);
      await tester.scrollUntilVisible(
          find.byKey(const Key('hull_card_galleon')), 400);
      // Chapter 6: locked, with its chapter, and a try button but no build.
      expect(find.byKey(const Key('rebuild_galleon')), findsNothing);
      expect(find.byKey(const Key('try_hull_galleon')), findsOneWidget);
      expect(find.text('From chapter 6'), findsWidgets);
      await tester.scrollUntilVisible(
          find.byKey(const Key('hull_card_void_carrack')), 400);
      expect(find.byKey(const Key('rebuild_void_carrack')), findsNothing);
      expect(find.textContaining('Flies'), findsWidgets);
    });

    testWidgets('trying a hull shows her on it, and costs nothing',
        (tester) async {
      final container = await pumpHarbor(tester);
      await tester.scrollUntilVisible(
          find.byKey(const Key('try_hull_brig')), 400);
      await tester.ensureVisible(find.byKey(const Key('try_hull_brig')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('try_hull_brig')));
      await tester.pump();
      await tester.scrollUntilVisible(
          find.byKey(const Key('yard_trying_hull')), -400);
      expect(find.textContaining('Brig hull'), findsWidgets);
      final yard = find.descendant(
          of: find.byKey(const Key('yard_preview')),
          matching: find.byType(CustomPaint));
      final painters = tester
          .widgetList<CustomPaint>(yard)
          .map((c) => c.painter)
          .whereType<TopShipPainter>()
          .toList();
      expect(painters.single.look.form!.id, 'brig');
      final session = container.read(playerSessionProvider);
      expect(session.shipHullId, 'rusty_eel');
      expect(session.gold, 2000);
    });

    testWidgets('rebuilding names the parts that lose their slot, then does it',
        (tester) async {
      final container = await pumpHarbor(
        tester,
        shipPartIds: const ['ballista', 'harpoon_rack', 'iron_plating'],
      );
      // The longboat: one gun, no shield slot.
      await tester.scrollUntilVisible(
          find.byKey(const Key('rebuild_longboat')), 400);
      await tester.ensureVisible(find.byKey(const Key('rebuild_longboat')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('rebuild_longboat')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('rebuild_confirm')), findsOneWidget);
      expect(find.textContaining('Harpoon Rack'), findsWidgets);
      expect(find.textContaining('Iron Plating'), findsWidgets);
      await tester.tap(find.byKey(const Key('rebuild_confirm_yes')));
      await _pumpUntil(tester,
          () => container.read(playerSessionProvider).shipHullId == 'longboat');
      final session = container.read(playerSessionProvider);
      expect(session.shipHullId, 'longboat');
      expect(session.gold, 2000 - 60);
      expect(session.shipPartIds, ['ballista']);
      expect(session.storedShipPartIds, ['harpoon_rack', 'iron_plating']);
      await drain(tester);
    });

    testWidgets('a hull that was built before is a free way back',
        (tester) async {
      final container = await pumpHarbor(
        tester,
        ownedHullIds: const ['rusty_eel', 'cutter'],
      );
      await tester.scrollUntilVisible(
          find.byKey(const Key('rebuild_cutter')), 400);
      expect(
          find.text('Built before: back on her for nothing.'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('rebuild_cutter')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('rebuild_cutter')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('rebuild_confirm_yes')));
      await _pumpUntil(tester,
          () => container.read(playerSessionProvider).shipHullId == 'cutter');
      expect(container.read(playerSessionProvider).gold, 2000);
      await drain(tester);
    });
  });

  group('a flying boat', () {
    setUp(rootBundle.clear);

    testWidgets('lets the storms and raiders of a voyage pass beneath her',
        (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              const MethodChannel('flutter_tts'), (call) async => 1);
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(420, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final ports = _data('ports');
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(playerSessionProvider.notifier);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.runAsync(() => notifier.loadSession(PlayerSession.fromJson({
            'raceId': 'human',
            'professionId': 'warrior',
            'shipHullId': 'sky_sloop',
            'ownedHullIds': ['rusty_eel', 'sky_sloop'],
          })));
      const storm = SeaEvent(
        kind: SeaEventKind.storm,
        description: 'A storm.',
        descriptionFr: 'Une tempête.',
        choiceText: 'Ride it out',
        choiceTextFr: 'Tenir bon',
        hullDelta: -15,
      );
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
            debugEvents: const [storm, wreck, storm],
          ),
        ),
      ));
      await _pumpUntil(
          tester,
          () => find
              .byKey(const Key('sea_choice_salvage'))
              .evaluate()
              .isNotEmpty);
      // Three days of weather and wreck, two of them storms: one day left.
      expect(find.byKey(const Key('route_day_0')), findsOneWidget);
      expect(find.byKey(const Key('route_day_1')), findsNothing);
      expect(find.byKey(const Key('sea_choice_salvage')), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });
  });
}

ShipState _anyShip() => ShipState(
      hull: 80,
      maxHull: 80,
      layers: 0,
      rooms: {for (final r in ShipRoom.values) r: const RoomState(level: 1)},
      weapons: const [],
    );
