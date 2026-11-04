// UX: the screens with no real-font layout check, on a phone with the app's own
// fonts (see docs/qa/smoke-coverage.md): 360 x 740 and 320 x 568, English and
// French, no overflow. qa_smoke_harness.dart; SMOKE_SHOTS=<folder> writes a
// picture of each.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/screens/achievements_screen.dart';
import 'package:narrative_data_app/screens/camp_screen.dart';
import 'package:narrative_data_app/screens/character_screen.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/screens/clans_politics_screen.dart';
import 'package:narrative_data_app/screens/companion_page.dart';
import 'package:narrative_data_app/screens/death_screen.dart';
import 'package:narrative_data_app/screens/port_screen.dart';
import 'package:narrative_data_app/screens/shop_detail_screen.dart';
import 'package:narrative_data_app/screens/harbor_screen.dart';
import 'package:narrative_data_app/screens/inventory_screen.dart';
import 'package:narrative_data_app/screens/journal_screen.dart';
import 'package:narrative_data_app/screens/level_up_screen.dart';
import 'package:narrative_data_app/screens/main_menu_screen.dart';
import 'package:narrative_data_app/screens/ship_screen.dart';

import 'package:narrative_data_app/providers/player_session_provider.dart';

import 'qa_smoke_harness.dart';

/// A save with something in it: level 12, a full purse, and the items with
/// the longest names (French) in the bag, the boots worn.
PlayerSession _rich() => PlayerSession.fromJson({
      'raceId': 'human',
      'professionId': 'warrior',
      'level': 12,
      'gold': 48250,
      'ownedDiceIds': ['starter_die'],
      'equippedDiceId': 'starter_die',
      'inventoryItemIds': [
        'boots_tearwalker',
        'spellbook_sundering_roar',
        'void_banner',
        'spellbook_venom_hex',
        'quest_sealed_letter',
        'spellbook_smite_the_wicked',
      ],
      'equippedItemIds': ['boots_tearwalker'],
    });

Iterable<String> _ids(String table) =>
    (jsonDecode(File('assets/gamedata/$table.json').readAsStringSync())
            as Map<String, dynamic>)
        .keys;

Future<void> _loadTables(ProviderContainer container) async {
  for (final schema in [shopsSchema, itemsSchema, diceSchema]) {
    await container.read(gameDbProvider(schema).notifier).whenLoaded();
  }
}

void main() {
  setUpAll(loadSmokeFonts);

  testWidgets('the screens with no real-font check read on a phone',
      (tester) async {
    await runSmoke(tester, [
      const SmokeCase('main_menu', MainMenuScreen(), bare: true),
      SmokeCase('camp', const CampScreen(), session: _rich(), bare: true),
      SmokeCase('character', const CharacterScreen(),
          session: _rich(), bare: true),
      SmokeCase('harbor', const HarborScreen(), session: _rich(), bare: true),
      SmokeCase('ship', const ShipScreen(), session: _rich(), bare: true),
      SmokeCase('journal', const JournalScreen(), session: _rich(), bare: true),
      SmokeCase('achievements', const AchievementsScreen(),
          session: _rich(), bare: true),
      SmokeCase('inventory', const InventoryScreen(),
          session: _rich(), bare: true),
      SmokeCase('clans_politics', const ClansPoliticsScreen(play: true),
          session: _rich(), bare: true),
      SmokeCase('level_up', const LevelUpScreen(),
          session: _rich(), bare: true),
    ]);
    // A shop's page, every shop; a port, every port; every companion: on the
    // smallest phone, where it is tightest.
    await runSmoke(tester, [
      for (final id in _ids('shops'))
        SmokeCase(
          'shop_$id',
          Consumer(builder: (context, ref, _) {
            final shops = ref.watch(localizedDbProvider(shopsSchema)).value;
            final shop = shops?[id];
            return shop is Map<String, dynamic>
                ? ShopDetailScreen(shopId: id, shop: shop)
                : const SizedBox.shrink();
          }),
          session: _rich(),
          prepare: _loadTables,
          bare: true,
        ),
      for (final id in _ids('ports'))
        SmokeCase('port_$id', PortScreen(portId: id),
            session: _rich(), prepare: _loadTables, bare: true),
      for (final id in _ids('companions'))
        SmokeCase('companion_$id', CompanionPage(companionId: id),
            session: _rich(), bare: true),
      SmokeCase(
        'death',
        const DeathScreen(
          lostItemIds: [
            'boots_tearwalker',
            'spellbook_sundering_roar',
            'void_banner',
          ],
          xpEarned: 12840,
          nodesVisited: 312,
          skillsLost: 4,
          signsLost: 2,
          killerName: 'The Inquisition High Warden of the Ashen Quarter',
        ),
        session: _rich(),
        prepare: _loadTables,
        bare: true,
      ),
    ], sizes: const [
      Size(320, 568)
    ]);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
