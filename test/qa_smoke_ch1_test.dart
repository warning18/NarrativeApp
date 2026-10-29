// QA: the chapter 1 screens on a phone, with the app's own fonts: the intro,
// the race and profession screen, Vica's page, the Party formation with her
// beside Kelda, and the inventory with its Dice tab. 412 x 892, 360 x 740 and
// 320 x 568, English and French, no overflow (qa_smoke_harness.dart;
// SMOKE_SHOTS=<folder> for the pictures).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/companion_page.dart';
import 'package:narrative_data_app/screens/intro_screen.dart';
import 'package:narrative_data_app/screens/inventory_screen.dart';
import 'package:narrative_data_app/screens/race_profession_screen.dart';
import 'package:narrative_data_app/widgets/party_formation.dart';

import 'qa_smoke_harness.dart';

const _phones = [Size(412, 892), Size(360, 740), Size(320, 568)];

Future<void> _loadTables(ProviderContainer container) async {
  for (final schema in [
    companionsSchema,
    racesSchema,
    professionsSchema,
    housesSchema,
    diceSchema,
    itemsSchema,
    enemiesSchema,
    skillsSchema,
  ]) {
    await container.read(gameDbProvider(schema).notifier).whenLoaded();
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  final houses =
      jsonDecode(File('assets/gamedata/houses.json').readAsStringSync())
          as Map<String, dynamic>;

  PlayerSession save(Map<String, dynamic> extra) => PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'ownedDiceIds': ['starter_die'],
        'equippedDiceId': 'starter_die',
        ...extra,
      });

  testWidgets('the chapter 1 screens read on a phone, EN and FR',
      (tester) async {
    await runSmoke(
      tester,
      [
        const SmokeCase('intro', IntroScreen(),
            bare: true, prepare: _loadTables),
        const SmokeCase('race_profession', RaceProfessionScreen(),
            bare: true, prepare: _loadTables),
        SmokeCase(
          'vica_page',
          const CompanionPage(companionId: 'vica'),
          session: save({
            'recruitedAllies': [
              {'companionId': 'vica'},
            ],
            'activeAllyIds': ['vica'],
          }),
          prepare: _loadTables,
          bare: true,
        ),
        SmokeCase(
          'party_formation',
          PartyFormation(houses: houses),
          prepare: _loadTables,
          session: save({
            'recruitedAllies': [
              {'companionId': 'vica'},
              {'companionId': 'kelda'},
            ],
            'activeAllyIds': ['vica', 'kelda'],
          }),
        ),
        SmokeCase(
          'inventory_dice_tab',
          const InventoryScreen(),
          prepare: _loadTables,
          session: save({
            'ownedDiceIds': ['starter_die', 'hound_die'],
            'inventoryItemIds': ['potion_minor', 'sword_001'],
          }),
          bare: true,
        ),
      ],
      sizes: _phones,
    );
  }, timeout: const Timeout(Duration(minutes: 10)));
}
