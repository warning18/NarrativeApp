// Ship customisation (v1.226): the shipwright's parts in versions, from
// the plain to the rare and each from its chapter on, a sounder hull
// (hullBonus), and the looks the Eel can wear (paint, cloth, figurehead,
// flag) with the parts she carries drawn on her.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/ship_combat.dart';
import 'package:narrative_data_app/data/ship_looks.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/chapter_loop_provider.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/harbor_screen.dart';
import 'package:narrative_data_app/widgets/sea_battlefield.dart';
import 'package:narrative_data_app/widgets/ship_dress.dart';
import 'package:narrative_data_app/widgets/ship_widgets.dart';

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

/// Lets a purchase finish and its notice come and go.
Future<void> _drain(WidgetTester tester) async {
  await tester
      .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  final parts = _data('ship_parts');
  final looks = _data('ship_looks');
  final ships = _data('ships');
  final enemyShips = _data('enemy_ships');
  final eel = ships['rusty_eel'] as Map<String, dynamic>;
  final all = shipLooksFrom(looks);

  group('the shipwright\'s parts', () {
    test('every slot offers at least a dozen parts, in versions of a family',
        () {
      final bySlot = <String, int>{};
      for (final entry in parts.entries) {
        final part = entry.value as Map<String, dynamic>;
        bySlot[part['slotType'] as String] =
            (bySlot[part['slotType'] as String] ?? 0) + 1;
        expect(part['family']?.toString() ?? '', isNotEmpty, reason: entry.key);
        expect((part['tier'] as num).toInt(), greaterThanOrEqualTo(1),
            reason: entry.key);
        expect(shipPartRarityOptions, contains(part['rarity']),
            reason: entry.key);
        final chapter = (part['unlockChapter'] as num?)?.toInt() ?? 0;
        expect(chapter, inInclusiveRange(0, 6), reason: entry.key);
        expect(part['description_fr']?.toString() ?? '', isNotEmpty,
            reason: entry.key);
      }
      for (final slot in slotTypeOptions) {
        expect(bySlot[slot], greaterThanOrEqualTo(12), reason: slot);
      }
    });

    test('a better version of a family costs more and comes no earlier', () {
      final byFamily = <String, List<Map<String, dynamic>>>{};
      for (final part in parts.values) {
        final record = part as Map<String, dynamic>;
        // Trophies cost nothing and beast gear has its own door.
        if ((record['trophyOf']?.toString() ?? '').isNotEmpty) continue;
        (byFamily[record['family'] as String] ??= []).add(record);
      }
      for (final entry in byFamily.entries) {
        final versions = entry.value
          ..sort((a, b) =>
              (a['tier'] as num).toInt().compareTo((b['tier'] as num).toInt()));
        for (var i = 1; i < versions.length; i++) {
          final lower = versions[i - 1], higher = versions[i];
          if (lower['slotType'] == 'Sail') continue;
          if ((lower['tier'] as num).toInt() ==
              (higher['tier'] as num).toInt()) {
            continue;
          }
          expect((higher['cost'] as num).toInt(),
              greaterThanOrEqualTo((lower['cost'] as num).toInt()),
              reason: '${entry.key}: ${higher['partID']} after '
                  '${lower['partID']}');
          expect(
              (higher['unlockChapter'] as num? ?? 0).toInt(),
              greaterThanOrEqualTo(
                  (lower['unlockChapter'] as num? ?? 0).toInt()),
              reason: '${entry.key}: ${higher['partID']} chapter');
        }
      }
    });

    test('no weapon out-damages its charge: damage a turn stays in reach', () {
      for (final entry in parts.entries) {
        final part = entry.value as Map<String, dynamic>;
        final damage = (part['damageAmount'] as num?)?.toInt() ?? 0;
        if (damage == 0) continue;
        final charge = (part['chargeTurns'] as num).toInt();
        // The plain ballista does 12 a turn; no gun does more than half
        // as much again.
        expect(damage / charge, lessThanOrEqualTo(18), reason: entry.key);
        expect(damage / charge, greaterThanOrEqualTo(5), reason: entry.key);
      }
    });

    test('a hull part adds hull, but only within the ship\'s slots', () {
      ShipState fit(List<String> ids) => buildPlayerShip(
          ship: eel, parts: parts, installedPartIds: ids, currentHull: -1);
      final bare = fit(['ballista']);
      expect(bare.maxHull, 100);
      expect(fit(['ballista', 'oak_planking']).maxHull, 112);
      expect(fit(['ballista', 'oak_planking', 'reinforced_keel']).maxHull,
          112 + 28);
      // One utility slot: the second of them stays in the hold.
      expect(fit(['ballista', 'oakum_stores', 'reinforced_keel']).maxHull, 110);
      // The ship's sign lifts the whole hull, parts included.
      expect(
          buildPlayerShip(
                  ship: eel,
                  parts: parts,
                  installedPartIds: const ['ballista', 'oak_planking'],
                  currentHull: -1,
                  hullPercent: 10)
              .maxHull,
          123);
      expect(hullBonusOf(parts, ['aegis_of_the_deep', 'ballista']), 25);
    });

    test('a version\'s own numbers are what the ship fires with', () {
      final ship = buildPlayerShip(
          ship: eel,
          parts: parts,
          installedPartIds: const ['siege_ballista', 'dragonfire_cannon'],
          currentHull: -1);
      final siege = ship.weapons.firstWhere((w) => w.id == 'siege_ballista');
      expect(siege.damage, 34);
      expect(siege.roomDamage, 2);
      expect(siege.reaches(ShipRange.close), isFalse);
      expect(siege.reaches(ShipRange.long), isTrue);
      final dragon =
          ship.weapons.firstWhere((w) => w.id == 'dragonfire_cannon');
      expect(dragon.ammo, ShipAmmo.heated);
      expect(dragon.roomDamage, 2);
    });

    test('a shield version adds the pips its words say', () {
      ShipState fit(String id) => buildPlayerShip(
          ship: eel,
          parts: parts,
          installedPartIds: ['ballista', id],
          currentHull: -1);
      expect(fit('blackiron_plating').room(ShipRoom.bulwark).level, 3);
      expect(fit('dwarven_bulwark').room(ShipRoom.bulwark).level, 4);
      final screens = fit('shuttered_gunports');
      expect(screens.room(ShipRoom.bulwark).level, 2);
      expect(screens.room(ShipRoom.guns).level, 2);
      // Bracing is hull alone.
      expect(fit('ironwood_bracing').room(ShipRoom.bulwark).level, 1);
      expect(fit('ironwood_bracing').maxHull, 124);
    });

    test('the Harbor sells a part from its chapter on', () {
      final session = PlayerSession.fromJson(
          {'raceId': 'human', 'professionId': 'warrior'});
      final dragon = parts['dragonfire_cannon'] as Map<String, dynamic>;
      expect(HarborScreen.partUnlocked('dragonfire_cannon', dragon, session, 5),
          isFalse);
      expect(HarborScreen.partUnlocked('dragonfire_cannon', dragon, session, 6),
          isTrue);
      // One already won stays unlocked.
      final owned = PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'storedShipPartIds': ['dragonfire_cannon'],
      });
      expect(HarborScreen.partUnlocked('dragonfire_cannon', dragon, owned, 1),
          isTrue);
      // The first versions are there from the start.
      final ballista = parts['ballista'] as Map<String, dynamic>;
      expect(
          HarborScreen.partUnlocked('ballista', ballista, session, 0), isTrue);
    });

    test('trying a part shows it on the ship, in place of the weakest gun', () {
      final installed = ['ballista', 'harpoon_rack'];
      final tried = fittedWith(
          ship: eel,
          parts: parts,
          installed: installed,
          partId: 'siege_ballista');
      // Both gun slots are full: the plain ballista (12) goes, not the
      // harpoon rack (22).
      expect(tried, ['harpoon_rack', 'siege_ballista']);
      // A free slot just takes it.
      expect(
          fittedWith(
              ship: eel,
              parts: parts,
              installed: installed,
              partId: 'oak_planking'),
          [...installed, 'oak_planking']);
      // One already aboard is as it was.
      expect(
          fittedWith(
              ship: eel,
              parts: parts,
              installed: installed,
              partId: 'ballista'),
          installed);
      // A painted sail replaces the sigil on the canvas.
      expect(
          fittedWith(
              ship: eel,
              parts: parts,
              installed: ['ballista', 'sail_wind_knot'],
              partId: 'sail_cooks_knot'),
          ['ballista', 'sail_cooks_knot']);
    });
  });

  group('the looks', () {
    test('four categories, one free default each, every record complete', () {
      for (final category in shipLookCategories) {
        final inCategory = all.values.where((l) => l.category == category);
        expect(inCategory.length, greaterThanOrEqualTo(8), reason: category);
        final defaults = inCategory.where((l) => l.isDefault).toList();
        expect(defaults.length, 1, reason: category);
        expect(defaults.single.cost, 0, reason: category);
      }
      for (final entry in looks.entries) {
        final look = entry.value as Map<String, dynamic>;
        expect(look['lookID'], entry.key);
        expect(look['lookName_fr']?.toString() ?? '', isNotEmpty,
            reason: entry.key);
        expect(look['description']?.toString() ?? '', isNotEmpty);
        expect(look['description_fr']?.toString() ?? '', isNotEmpty);
        expect(shipPartRarityOptions, contains(look['rarity']));
        final record = all[entry.key]!;
        expect(shipLookPatterns[record.category], contains(record.pattern),
            reason: '${entry.key} pattern ${record.pattern}');
        // Colours are real "#RRGGBB" or empty (a flag in the ship's trim).
        for (final field in ['color', 'color2', 'color3']) {
          final text = look[field]?.toString() ?? '';
          if (text.isNotEmpty) {
            expect(hexColor(text), isNotNull, reason: '${entry.key} $field');
          }
        }
        if (record.category == 'hull') {
          expect(record.color, isNotNull);
          expect(record.color2, isNotNull);
          expect(record.color3, isNotNull);
        }
        if (record.trophyOf.isNotEmpty) {
          expect(enemyShips, contains(record.trophyOf), reason: entry.key);
          expect(record.cost, 0, reason: 'a trophy is free');
          expect(record.category, 'figurehead');
        }
      }
    });

    test('a look is worn when chosen and owned, else the default is', () {
      expect(wornLook(all, 'hull', const {}, const [])!.id, 'hull_tarred_oak');
      expect(wornLook(all, 'hull', {'hull': 'hull_oxblood'}, const [])!.id,
          'hull_tarred_oak',
          reason: 'not owned');
      expect(
          wornLook(all, 'hull', {'hull': 'hull_oxblood'}, ['hull_oxblood'])!.id,
          'hull_oxblood');
      // A look of another category is no choice.
      expect(wornLook(all, 'hull', {'hull': 'fig_gull'}, ['fig_gull'])!.id,
          'hull_tarred_oak');
      expect(wornLook(all, 'sail', const {}, const [])!.id, 'cloth_undyed');
    });

    test('a look is on offer from its chapter, a trophy once its beast falls',
        () {
      final oxblood = all['hull_oxblood']!;
      bool offered(ShipLook look, int chapter,
              {Set<String> slain = const {}, List<String> owned = const []}) =>
          lookOffered(look, chapter: chapter, slain: slain, owned: owned);
      expect(offered(oxblood, 1), isFalse);
      expect(offered(oxblood, 2), isTrue);
      expect(offered(all['hull_tarred_oak']!, 0), isTrue);
      final maw = all['fig_brinejaw']!;
      expect(offered(maw, 7), isFalse);
      expect(offered(maw, 0, slain: {'brinejaw'}), isTrue);
      expect(offered(maw, 0, owned: ['fig_brinejaw']), isTrue);
    });

    test('the session keeps its looks and the gold they cost', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(playerSessionProvider.notifier);
      await notifier.loadSession(PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'gold': 100,
      }));
      expect(await notifier.wearShipLook('hull', 'hull_oxblood', 90), isTrue);
      var session = container.read(playerSessionProvider);
      expect(session.gold, 10);
      expect(session.shipLooks['hull'], 'hull_oxblood');
      expect(session.ownedShipLooks, ['hull_oxblood']);
      // Back to the default and again: owned looks are free.
      expect(await notifier.wearShipLook('hull', 'hull_tarred_oak', 0), isTrue);
      expect(await notifier.wearShipLook('hull', 'hull_oxblood', 90), isTrue);
      session = container.read(playerSessionProvider);
      expect(session.gold, 10);
      expect(session.shipLooks['hull'], 'hull_oxblood');
      // Too dear: nothing changes.
      expect(await notifier.wearShipLook('sail', 'cloth_black', 220), isFalse);
      session = container.read(playerSessionProvider);
      expect(session.gold, 10);
      expect(session.shipLooks.containsKey('sail'), isFalse);
      // And it all survives a save.
      final again = PlayerSession.fromJson(session.toJson());
      expect(again.shipLooks, session.shipLooks);
      expect(again.ownedShipLooks, session.ownedShipLooks);
    });
  });

  group('the Eel\'s dress', () {
    ShipDress dress(List<String> installed, [Map<String, String>? chosen]) =>
        buildShipDress(
          ship: eel,
          parts: parts,
          installed: installed,
          lookRecords: looks,
          chosen: chosen ?? const {},
          owned: (chosen ?? const {}).values,
        );

    test('her guns, plating, gear and sigil are the parts aboard', () {
      final d = dress([
        'siege_ballista',
        'dragonfire_cannon',
        'dwarven_bulwark',
        'admirals_standard',
        'sail_tarred_void',
      ]);
      expect(d.mounts.map((m) => m.family), ['ballista', 'carronade']);
      expect(d.mounts.last.ammo, 'heated');
      expect(d.plating!.family, 'plating');
      expect(d.plating!.tier, 6);
      expect(d.gear, 'command');
      expect(d.sigil!.power.name, 'voidmark');
      expect(d.sigil!.color, sailMediumColors['orc']);
      // A third gun has no slot, so no mount.
      expect(dress(['ballista', 'culverin', 'chain_swivel']).mounts.length, 2);
    });

    test('an Eel with no parts shows empty ports and no sigil', () {
      final d = dress(const []);
      expect(d.mounts, isEmpty);
      expect(d.plating, isNull);
      expect(d.gear, isNull);
      expect(d.sigil, isNull);
    });

    test('the looks worn are the paint, cloth, carving and flag', () {
      final d = dress(const [
        'ballista'
      ], {
        'hull': 'hull_gilded',
        'sail': 'cloth_striped',
        'figurehead': 'fig_dragon',
        'ensign': 'ensign_gold_crown',
      });
      expect(d.hull, hexColor('#5B4220'));
      expect(d.trim, hexColor('#F2C14E'));
      expect(d.clothPattern, 'stripes');
      expect(d.figurehead, 'dragon');
      expect(d.ensign, 'crown');
      // Her look takes the paint and the cloth.
      final look = TopShipLook.rustyEel.dressed(d);
      expect(look.hull, hexColor('#5B4220'));
      expect(look.sail, hexColor('#D8C8A2'));
      expect(TopShipLook.rustyEel.dressed(null), same(TopShipLook.rustyEel));
      // The default dress leaves her as she was.
      final plain = TopShipLook.rustyEel.dressed(dress(const ['ballista']));
      expect(plain.hull, TopShipLook.rustyEel.hull);
      expect(plain.deck, TopShipLook.rustyEel.deck);
      expect(plain.trim, TopShipLook.rustyEel.trim);
    });

    test('every look and every gun paints without a fault', () {
      void paintDress(ShipDress d, {bool flip = false, bool battered = false}) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final look = TopShipLook.rustyEel.dressed(d);
        TopShipPainter(
          look: look,
          flip: flip,
          facingDown: flip,
          t: 1.7,
          layers: 1,
          maxLayers: 2,
          battered: battered,
          down: const {},
          burning: const {ShipRoom.guns},
          water: 0.5,
          shield: Colors.cyan,
          foam: Colors.white,
          roomColors: {for (final r in ShipRoom.values) r: Colors.grey},
          refit: 2,
          dress: d,
        ).paint(canvas, const Size(380, 190));
        recorder.endRecording().dispose();
      }

      for (final look in all.values) {
        paintDress(dress(const ['ballista'], {look.category: look.id}));
      }
      for (final entry in parts.entries) {
        paintDress(dress(['ballista', entry.key]));
        paintDress(dress([entry.key]), flip: true, battered: true);
      }
      // Every part at once, as the editor's test fights may have them.
      paintDress(dress(parts.keys.toList()));
    });
  });

  group('the Harbor', () {
    setUp(rootBundle.clear);

    Future<ProviderContainer> pumpHarbor(
      WidgetTester tester, {
      required int chapter,
      int gold = 900,
      List<String> shipPartIds = const ['ballista', 'harpoon_rack'],
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
          })));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HarborScreen()),
      ));
      await _pumpUntil(tester,
          () => find.byKey(const Key('yard_card')).evaluate().isNotEmpty);
      return container;
    }

    testWidgets('the yard shows the Eel, a look is tried, bought and worn',
        (tester) async {
      final container = await pumpHarbor(tester, chapter: 2);
      expect(find.byKey(const Key('yard_preview')), findsOneWidget);
      // The flag shelf: a flag from chapter 1 is bought and worn.
      await tester.tap(find.byKey(const Key('look_tab_ensign')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('look_ensign_black_jack')));
      await tester.pump();
      // Trying it spends nothing.
      expect(container.read(playerSessionProvider).gold, 900);
      expect(container.read(playerSessionProvider).shipLooks, isEmpty);
      await tester.tap(find.byKey(const Key('wear_ensign_black_jack')));
      await _pumpUntil(
          tester,
          () => container
              .read(playerSessionProvider)
              .shipLooks
              .containsKey('ensign'));
      final session = container.read(playerSessionProvider);
      expect(session.shipLooks['ensign'], 'ensign_black_jack');
      expect(session.gold, 900 - 120);
      expect(session.ownedShipLooks, ['ensign_black_jack']);
      await _drain(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a look for a later chapter is told so and cannot be bought',
        (tester) async {
      await pumpHarbor(tester, chapter: 2);
      await tester.tap(find.byKey(const Key('look_tab_ensign')));
      await tester.pump();
      expect(find.text('From chapter 5'), findsWidgets);
      await tester.tap(find.byKey(const Key('look_ensign_void_banner')));
      await tester.pump();
      final button = tester.widget<ElevatedButton>(
          find.byKey(const Key('wear_ensign_void_banner')));
      expect(button.onPressed, isNull);
    });

    testWidgets('a part of a later chapter takes a line and can still be tried',
        (tester) async {
      await pumpHarbor(tester, chapter: 2);
      await tester.scrollUntilVisible(
          find.byKey(const Key('part_card_dragonfire_cannon')), 600);
      // Locked: no install or swap, and a try button.
      expect(find.byKey(const Key('install_dragonfire_cannon')), findsNothing);
      expect(find.byKey(const Key('swap_dragonfire_cannon')), findsNothing);
      expect(find.byKey(const Key('try_dragonfire_cannon')), findsOneWidget);
      expect(find.text('Epic · Version III · From chapter 6'), findsOneWidget);
    });

    testWidgets('a part is tried on the ship before it is bought',
        (tester) async {
      final container = await pumpHarbor(tester, chapter: 4);
      await tester.scrollUntilVisible(
          find.byKey(const Key('try_siege_ballista')), 600);
      await tester.tap(find.byKey(const Key('try_siege_ballista')));
      await tester.pump();
      await tester.scrollUntilVisible(
          find.byKey(const Key('yard_trying')), -600);
      expect(find.byKey(const Key('yard_trying')), findsOneWidget);
      expect(find.textContaining('Siege Ballista'), findsWidgets);
      // Nothing is bought or fitted by trying.
      final session = container.read(playerSessionProvider);
      expect(session.gold, 900);
      expect(session.shipPartIds, ['ballista', 'harpoon_rack']);
      await tester.ensureVisible(find.byKey(const Key('yard_clear_try')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('yard_clear_try')));
      await tester.pump();
      expect(find.byKey(const Key('yard_trying')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a hull part is bought and the hull grows', (tester) async {
      final container = await pumpHarbor(tester, chapter: 4);
      await tester.scrollUntilVisible(
          find.byKey(const Key('install_reinforced_keel')), 600);
      // The one utility slot is free on this Eel.
      await tester.tap(find.byKey(const Key('install_reinforced_keel')));
      await _pumpUntil(
          tester,
          () => container
              .read(playerSessionProvider)
              .shipPartIds
              .contains('reinforced_keel'));
      final session = container.read(playerSessionProvider);
      expect(session.gold, 900 - 360);
      final built = buildPlayerShip(
          ship: eel,
          parts: parts,
          installedPartIds: session.shipPartIds,
          currentHull: -1);
      expect(built.maxHull, 128);
      await _drain(tester);
    });
  });

  group('ships are drawn from above', () {
    testWidgets('the Eel at sea is the top-down ship, not a side cutaway',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(420, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final ship = ShipState(
        hull: 40,
        maxHull: 100,
        layers: 0,
        rooms: {for (final r in ShipRoom.values) r: const RoomState(level: 1)},
        weapons: const [],
      );
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ShipAtSea(
                ship: ship, beside: const Icon(Icons.storm, size: 40)),
          ),
        ),
      ));
      await tester.pump();
      final at = find.byKey(const Key('ship_at_sea'));
      expect(at, findsOneWidget);
      // No sprite: a painter draws her, battered below half her hull.
      expect(
          find.descendant(of: at, matching: find.byType(Image)), findsNothing);
      final painters = tester
          .widgetList<CustomPaint>(
              find.descendant(of: at, matching: find.byType(CustomPaint)))
          .map((c) => c.painter)
          .whereType<TopShipPainter>()
          .toList();
      expect(painters, hasLength(1));
      expect(painters.single.battered, isTrue);
      expect(painters.single.flip, isFalse);
    });
  });
}
