// QA: the player's own screens on a phone, with the app's own fonts (the full
// review, docs/qa/full-review.md): 412 x 892, 360 x 740 and 320 x 568,
// English and French, no overflow (qa_smoke_harness.dart; SMOKE_SHOTS=<dir>
// for the pictures). The ones with their own smoke files (the story, the
// fight, the Journey's tints, the camp's town) are not repeated here.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/chapter_loop_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/achievements_screen.dart';
import 'package:narrative_data_app/screens/camp_screen.dart';
import 'package:narrative_data_app/screens/character_screen.dart';
import 'package:narrative_data_app/screens/clans_politics_screen.dart';
import 'package:narrative_data_app/screens/harbor_screen.dart';
import 'package:narrative_data_app/screens/journal_screen.dart';
import 'package:narrative_data_app/screens/main_menu_screen.dart';
import 'package:narrative_data_app/screens/main_story_screen.dart';
import 'package:narrative_data_app/screens/npc_detail_screen.dart';
import 'package:narrative_data_app/screens/settings_screen.dart';
import 'package:narrative_data_app/screens/ship_screen.dart';
import 'package:narrative_data_app/screens/shop_detail_screen.dart';

import 'qa_smoke_harness.dart';

const _phones = [Size(412, 892), Size(360, 740), Size(320, 568)];

Future<void> _load(ProviderContainer container) async {
  for (final schema in [
    factionsSchema,
    subclansSchema,
    housesSchema,
    diceSchema,
    skillsSchema,
    skillTreesSchema,
    shopsSchema,
    racesSchema,
    professionsSchema,
    enemiesSchema,
    itemsSchema,
    zonesSchema,
    questsSchema,
    npcsSchema,
    achievementsSchema,
    companionsSchema,
    shipsSchema,
  ]) {
    await container.read(gameDbProvider(schema).notifier).whenLoaded();
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  Map<String, dynamic> table(String n) =>
      jsonDecode(File('assets/gamedata/$n.json').readAsStringSync())
          as Map<String, dynamic>;
  final npcs = table('npcs');
  final shops = table('shops');

  PlayerSession save([Map<String, dynamic> extra = const {}]) =>
      PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'level': 9,
        'gold': 320,
        'ownedDiceIds': ['starter_die', 'iron_die'],
        'equippedDiceId': 'starter_die',
        'recruitedAllies': [
          {'companionId': 'kelda', 'currentHealth': 1 << 30},
        ],
        'activeAllyIds': ['kelda'],
        ...extra,
      });

  SmokeCase screen(String name, Widget w, {Map<String, dynamic>? more}) =>
      SmokeCase(name, w,
          session: save(more ?? const {}), prepare: _load, bare: true);

  testWidgets('the player\'s screens read on a phone, EN and FR',
      (tester) async {
    await runSmoke(
      tester,
      [
        screen('main_menu', const MainMenuScreen()),
        screen('settings', const SettingsScreen()),
        screen('achievements', const AchievementsScreen()),
        screen('journal', const JournalScreen()),
        screen('character', const CharacterScreen()),
        screen('camp', const CampScreen()),
        screen('clans_politics', const ClansPoliticsScreen()),
        screen('harbor', const HarborScreen()),
        screen('ship', const ShipScreen()),
        screen('main_story', const MainStoryScreen()),
        screen(
            'npc_detail',
            NpcDetailScreen(
                npcId: 'aurel_vane',
                npc: npcs['aurel_vane'] as Map<String, dynamic>)),
        screen(
            'shop_detail',
            ShopDetailScreen(
                shopId: shops.keys.first,
                shop: shops[shops.keys.first] as Map<String, dynamic>)),
      ],
      overrides: [reachedChapterProvider.overrideWithValue(5)],
      sizes: _phones,
    );
  }, timeout: const Timeout(Duration(minutes: 15)));
}
