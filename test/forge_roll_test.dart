// Forging rolls for its result (docs/proposals/forge-roll.md): the d20 and
// its tiers, the dwarf's and the holder's modifiers, the forged variants
// the items table resolves, craftItem's roll, and the Forge button's
// notice.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/forge_roll.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/forge_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/shop_trade_sheets.dart';

/// A d20 that always lands on [face].
class _Face implements Random {
  _Face(this.face);
  final int face;
  @override
  int nextInt(int max) => (face - 1) % max;
  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
}

final Map<String, dynamic> _items =
    jsonDecode(File('assets/gamedata/items.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> get _boots =>
    _items['boots_iron_shod'] as Map<String, dynamic>;

Future<PlayerSessionNotifier> _notifierWith(Map<String, dynamic> json) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(PlayerSession.fromJson(json));
  return notifier;
}

Map<String, dynamic> _forgerJson({String raceId = 'human'}) => {
      'raceId': raceId,
      'gold': 100,
      'inventoryItemIds': List.filled(4, 'material_iron_ore'),
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('tiers', () {
    test('the table and its edges', () {
      expect(forgeTierFor(-1), ForgeTier.flawed);
      expect(forgeTierFor(1), ForgeTier.flawed);
      expect(forgeTierFor(4), ForgeTier.flawed);
      expect(forgeTierFor(5), ForgeTier.sound);
      expect(forgeTierFor(14), ForgeTier.sound);
      expect(forgeTierFor(15), ForgeTier.fine);
      expect(forgeTierFor(19), ForgeTier.fine);
      expect(forgeTierFor(20), ForgeTier.masterwork);
      expect(forgeTierFor(22), ForgeTier.masterwork);
    });

    test('the odds with no modifier and with +2', () {
      expect(forgeOdds(0), {
        ForgeTier.flawed: 0.20,
        ForgeTier.sound: 0.50,
        ForgeTier.fine: 0.25,
        ForgeTier.masterwork: 0.05,
      });
      expect(forgeOdds(2), {
        ForgeTier.flawed: 0.10,
        ForgeTier.sound: 0.50,
        ForgeTier.fine: 0.25,
        ForgeTier.masterwork: 0.15,
      });
      expect(forgeOdds(-1).values.fold<double>(0, (a, b) => a + b),
          closeTo(1, 1e-9));
    });

    test('a roll adds its modifiers to the face', () {
      final roll = rollForge(
          random: _Face(13), modifiers: forgeModifiersFor(raceId: 'dwarf'));
      expect(roll.face, 13);
      expect(roll.modifierTotal, 2);
      expect(roll.total, 15);
      expect(roll.tier, ForgeTier.fine);
      expect(roll.odds, forgeOdds(2));
      // A seeded roll stays on the d20.
      final seeded = rollForge(random: Random(3));
      expect(seeded.face, inInclusiveRange(1, 20));
    });
  });

  group('modifiers', () {
    test('a dwarf hero adds 2, anyone else nothing', () {
      expect(forgeModifiersFor(raceId: 'dwarf'), [
        const ForgeModifier(
            source: 'dwarf', labelKey: 'forge_mod_dwarf', value: 2),
      ]);
      expect(forgeModifiersFor(raceId: 'human'), isEmpty);
      expect(forgeModifiersFor(raceId: 'dwarf').first.labelFor(AppLanguage.en),
          'Dwarf');
    });

    test('standing with the holder: Friendly +1, neutral 0, Unfriendly -1', () {
      List<int> values(StandingTier tier) => [
            for (final m
                in forgeModifiersFor(holderId: 'compact', holderTier: tier))
              m.value,
          ];
      expect(values(StandingTier.friendly), [1]);
      expect(values(StandingTier.sworn), [1]);
      expect(values(StandingTier.known), isEmpty);
      expect(values(StandingTier.unknown), isEmpty);
      expect(values(StandingTier.wary), isEmpty);
      expect(values(StandingTier.unfriendly), [-1]);
      expect(values(StandingTier.hunted), [-1]);
    });

    test('no holder, no standing modifier', () {
      expect(forgeModifiersFor(holderId: '', holderTier: StandingTier.sworn),
          isEmpty);
    });

    test('the holder of the forge\'s place is read with holderOf', () {
      final geo = Geography.parse(geography: {
        'town': {'level': 'location', 'name': 'Town'},
        'town_smiths': {
          'level': 'district',
          'parent': 'town',
          'controller': 'compact',
          'name': 'Smiths',
        },
        'town_free': {'level': 'district', 'parent': 'town', 'name': 'Free'},
      });
      final politics = const PoliticsState(standings: {'compact': 14.0});
      const clans = ClanData();
      List<ForgeModifier> at(String placeId) {
        final holder = holderOf(placeId, geo, politics);
        return forgeModifiersFor(
            holderId: holder,
            holderTier: holder.isEmpty ? null : politics.tierOf(holder, clans));
      }

      expect(at('town_smiths').single.value, 1);
      expect(at('town_smiths').single.clanId, 'compact');
      expect(at('town_free'), isEmpty);
    });

    test('the labels name the clan', () {
      final clans = ClanData(factions: {
        for (final e in (jsonDecode(
                    File('assets/gamedata/factions.json').readAsStringSync())
                as Map<String, dynamic>)
            .entries)
          if (e.value is Map && e.key == 'compact')
            e.key: Faction.fromJson(e.key, e.value as Map<String, dynamic>),
      });
      final friends = forgeModifiersFor(
              holderId: 'compact', holderTier: StandingTier.friend)
          .single;
      expect(friends.labelFor(AppLanguage.en, clans: clans),
          'Friends of the Cinder Compact');
      expect(friends.labelFor(AppLanguage.fr, clans: clans),
          'Amis du Pacte des Cendres');
      final distrust = forgeModifiersFor(
              holderId: 'compact', holderTier: StandingTier.hostile)
          .single;
      expect(distrust.labelFor(AppLanguage.en, clans: clans),
          'The Cinder Compact distrusts you');
    });
  });

  group('variants', () {
    final table = withForgedVariants(_items);

    test('ids: Sound keeps the base id, the others take a tier', () {
      expect(forgedVariantId('boots_iron_shod', ForgeTier.sound),
          'boots_iron_shod');
      expect(forgedVariantId('boots_iron_shod', ForgeTier.fine),
          'boots_iron_shod@fine');
      expect(parseForgedId('boots_iron_shod@masterwork'),
          (baseId: 'boots_iron_shod', tier: ForgeTier.masterwork));
      expect(parseForgedId('boots_iron_shod@shiny'), isNull);
      expect(baseItemIdOf('boots_iron_shod@flawed'), 'boots_iron_shod');
      expect(baseItemIdOf('sword_t1'), 'sword_t1');
    });

    test('the table resolves a variant to its base, changed by the tier', () {
      expect(table.containsKey('boots_iron_shod@fine'), isTrue);
      expect(table.containsKey('boots_iron_shod@shiny'), isFalse);
      expect(table['nothing@fine'], isNull);
      // A walk over the table sees the base items only.
      expect(table.keys.any((k) => k.contains('@')), isFalse);
      expect(table.length, _items.length);

      final armor = (_boots['armor'] as num).toInt();
      int armorOf(String id) =>
          ((table[id] as Map<String, dynamic>)['armor'] as num).toInt();
      expect(armorOf('boots_iron_shod@flawed'), max(0, armor - 1));
      expect(armorOf('boots_iron_shod@fine'), armor + 1);
      expect(armorOf('boots_iron_shod@masterwork'), armor + 2);
      final fine = table['boots_iron_shod@fine'] as Map<String, dynamic>;
      expect(fine['equipSlot'], _boots['equipSlot']);
      expect(fine['id'], 'boots_iron_shod@fine');
      expect(fine.containsKey('craftedAt'), isFalse);
    });

    test('flawed never drops below 0, and a weapon moves its damage', () {
      final bare = forgedVariantOf(
          'x', {'itemType': 'Armor', 'armor': 0, 'cost': 10}, ForgeTier.flawed);
      expect(bare['armor'], 0);
      final sword = forgedVariantOf(
          'sword',
          {'itemType': 'Weapon', 'attackDamage': 3, 'armor': 0, 'cost': 10},
          ForgeTier.masterwork);
      expect(sword['attackDamage'], 5);
      expect(sword['armor'], 0);
      // A shield's main number is its armour.
      expect(
          forgeMainStatOf(
              {'itemType': 'Weapon', 'attackDamage': 0, 'armor': 2}),
          'armor');
    });

    test('the name, in English and in French', () {
      final fine = table['boots_iron_shod@fine'] as Map<String, dynamic>;
      expect(fine['itemName'], 'Fine Iron-Shod Boots');
      expect(fine['itemName_fr'], 'Bottes ferrées (belle facture)');
      expect((table['boots_iron_shod@flawed'] as Map)['itemName'],
          'Flawed Iron-Shod Boots');
      expect((table['boots_iron_shod@masterwork'] as Map)['itemName_fr'],
          'Bottes ferrées de maître');
      // A French table (its French text laid over the English) names it
      // in French.
      final fr = withForgedVariants(frenchOverlay(_items), french: true);
      expect((fr['boots_iron_shod@fine'] as Map)['itemName'],
          'Bottes ferrées (belle facture)');
    });

    test('resale: Flawed -25%, Fine +25%, Masterwork +50%', () {
      final base = sellPriceFor(_boots);
      int resale(String id) => sellPriceFor(table[id] as Map<String, dynamic>);
      expect(resale('boots_iron_shod@flawed'), (base * 0.75).round());
      expect(resale('boots_iron_shod@fine'), (base * 1.25).round());
      expect(resale('boots_iron_shod@masterwork'), (base * 1.5).round());
    });

    test('before and after, for the sheet', () {
      final change = forgedPieceBeforeAfter(_boots, ForgeTier.masterwork);
      final armor = (_boots['armor'] as num).toInt();
      expect(change.stat, 'armor');
      expect(change.before, armor);
      expect(change.after, armor + 2);
      expect(change.resaleBefore, sellPriceFor(_boots));
      expect(change.resaleAfter, (sellPriceFor(_boots) * 1.5).round());
      final sound = forgedPieceBeforeAfter(_boots, ForgeTier.sound);
      expect(sound.after, sound.before);
      expect(sound.resaleAfter, sound.resaleBefore);
    });
  });

  group('craftItem', () {
    test('a roll of 16 forges a Fine piece, gold and ore spent', () async {
      final notifier = await _notifierWith(_forgerJson());
      final roll = await notifier.craftItem('boots_iron_shod', _boots,
          random: _Face(16), modifiers: const []);
      expect(roll, isNotNull);
      expect(roll!.tier, ForgeTier.fine);
      expect(notifier.state.gold, 100 - (_boots['craftGold'] as num).toInt());
      expect(notifier.state.inventoryItemIds,
          ['material_iron_ore', 'boots_iron_shod@fine']);
    });

    test('a Sound piece keeps the base id', () async {
      final notifier = await _notifierWith(_forgerJson());
      await notifier.craftItem('boots_iron_shod', _boots,
          random: _Face(10), modifiers: const []);
      expect(notifier.state.inventoryItemIds.last, 'boots_iron_shod');
    });

    test('a flawed roll costs nothing more than any other', () async {
      final notifier = await _notifierWith(_forgerJson());
      final roll = await notifier.craftItem('boots_iron_shod', _boots,
          random: _Face(2), modifiers: const []);
      expect(roll!.tier, ForgeTier.flawed);
      expect(notifier.state.gold, 100 - (_boots['craftGold'] as num).toInt());
      expect(notifier.state.inventoryItemIds,
          ['material_iron_ore', 'boots_iron_shod@flawed']);
    });

    test('without modifiers given, a dwarf still gets the +2', () async {
      final notifier = await _notifierWith(_forgerJson(raceId: 'dwarf'));
      final roll = await notifier.craftItem('boots_iron_shod', _boots,
          random: _Face(18));
      expect(roll!.total, 20);
      expect(
          notifier.state.inventoryItemIds.last, 'boots_iron_shod@masterwork');
    });

    test('nothing to forge with, no roll', () async {
      final notifier = await _notifierWith({'gold': 0, 'raceId': 'human'});
      expect(await notifier.craftItem('boots_iron_shod', _boots), isNull);
    });

    test('a save keeps the variant', () async {
      final notifier = await _notifierWith(_forgerJson());
      await notifier.craftItem('boots_iron_shod', _boots,
          random: _Face(20), modifiers: const []);
      final saved = PlayerSession.fromJson(
          jsonDecode(jsonEncode(notifier.state.toJson()))
              as Map<String, dynamic>);
      expect(saved.inventoryItemIds, contains('boots_iron_shod@masterwork'));
    });
  });

  testWidgets('the Forge button names the tier and the piece', (tester) async {
    final notifier = await tester.runAsync(() => _notifierWith(_forgerJson()));
    final items = {
      'boots_iron_shod': _boots,
      'material_iron_ore': _items['material_iron_ore'],
    };
    await tester.pumpWidget(ProviderScope(
      overrides: [
        playerSessionProvider.overrideWith((ref) => notifier!),
        localizedDbProvider(itemsSchema)
            .overrideWithValue(AsyncValue.data(withForgedVariants(items))),
        forgeModifiersProvider.overrideWithValue(const []),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showForgeSheet(context, shopId: 'hammersmith_forge'),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(FilledButton, 'Forge'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
        find.textContaining(
            RegExp(r'^Forged: (Flawed |Fine |Masterwork )?Iron-Shod Boots$')),
        findsOneWidget);
    expect(
        notifier!.state.inventoryItemIds.last, startsWith('boots_iron_shod'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
