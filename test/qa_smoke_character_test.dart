// QA: the character screen's newer widgets on a phone, with the app's own
// fonts: a clan's card, its power and radar, the clans' compass, the level's
// stat pick, the level signpost, the face skill sheet, an item's and a
// title's details. 360 x 740 and 320 x 568, English and French, no overflow
// (qa_smoke_harness.dart; SMOKE_SHOTS=<folder> for the pictures).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/chapter_loop.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/signs.dart' show SignRarity;
import 'package:narrative_data_app/data/training.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/chapter_loop_provider.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/providers/training_provider.dart';
import 'package:narrative_data_app/widgets/clan_compass_card.dart';
import 'package:narrative_data_app/widgets/clan_peek.dart';
import 'package:narrative_data_app/widgets/clan_power_block.dart';
import 'package:narrative_data_app/widgets/clan_radar_chart.dart';
import 'package:narrative_data_app/widgets/face_skill_sheet.dart';
import 'package:narrative_data_app/widgets/item_detail_view.dart';
import 'package:narrative_data_app/widgets/level_signpost.dart';
import 'package:narrative_data_app/widgets/stat_pick_picker.dart';
import 'package:narrative_data_app/widgets/title_detail_view.dart';

import 'qa_smoke_harness.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

/// The clans' tables, loaded (a card reads them through the providers).
Future<void> _loadClans(ProviderContainer container) async {
  for (final schema in [
    factionsSchema,
    subclansSchema,
    relationsSchema,
    titlesSchema,
    intriguesSchema,
    geographySchema,
    biomesSchema,
  ]) {
    await container.read(gameDbProvider(schema).notifier).whenLoaded();
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  final paths = trainingPathsFrom(_table('training_paths'));
  final clans = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
  );
  final items = _table('items');
  PlayerSession withPolitics(PoliticsState politics) =>
      smokeSession().copyWith(politics: politics);

  PlayerSession pickOffer(SignRarity tier, int points) =>
      PlayerSession.fromJson({
        'statPoints': 3,
        'professionId': 'ranger',
        'strength': 8,
        'dexterity': 12,
        'perception': 11,
        'statPickOffer': [
          for (final (path, stat) in [
            ('duelist', 'dexterity'),
            ('bruiser', 'constitution'),
            ('hunter', 'perception'),
          ])
            {
              'path': path,
              'gains': {stat: points},
              if (tier != SignRarity.common) 'tier': tier.name,
            },
        ],
      });

  FaceSkillOption option(String id, String name, FaceChange change,
          {bool allowed = true, String limit = ''}) =>
      FaceSkillOption(
        id: id,
        name: name,
        icon: Icons.bolt,
        iconColour: Colors.red,
        rarityLabel: 'Rare',
        rarityColour: Colors.blue,
        change: change,
        limitLine: limit,
        allowed: allowed,
      );

  testWidgets('the character widgets read on a phone, EN and FR',
      (tester) async {
    await runSmoke(
      tester,
      [
        SmokeCase(
          'clan_card_crows',
          const ClanDetailsCard(factionId: 'crows'),
          session: withPolitics(const PoliticsState(power: {'crows': 62})),
          prepare: _loadClans,
        ),
        SmokeCase(
          'clan_card_dominion_nemesis',
          const ClanDetailsCard(
              factionId: 'dominion',
              greeting: 'You walk a long way for a coin.'),
          session: withPolitics(const PoliticsState(
              nemesis: 'dominion', power: {'dominion': 80})),
          prepare: _loadClans,
        ),
        SmokeCase(
          'clan_card_penitents',
          const ClanDetailsCard(factionId: 'penitents'),
          session: withPolitics(const PoliticsState(power: {'penitents': 8})),
          prepare: _loadClans,
        ),
        SmokeCase(
          'clan_power_block',
          const ClanPowerBlock(factionId: 'compact', color: Colors.teal),
          session: withPolitics(const PoliticsState(power: {'compact': 51})),
          prepare: _loadClans,
        ),
        SmokeCase(
          'clan_radar',
          const ClanRadarChart(factionId: 'vigil', color: Colors.indigo),
          prepare: _loadClans,
        ),
        SmokeCase('clan_compass_card', const ClanCompassCard(),
            prepare: _loadClans),
        SmokeCase('stat_pick_rare', const StatPickPicker(),
            session: pickOffer(SignRarity.rare, 2)),
        SmokeCase('stat_pick_heroic', const StatPickPicker(),
            session: pickOffer(SignRarity.heroic, 4)),
        SmokeCase(
          'level_signpost',
          Consumer(
            builder: (_, __, ___) => const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [LevelSignpostRow()],
            ),
          ),
        ),
        SmokeCase(
          'face_skill_sheet',
          FaceSkillSheet(
            nowLine: 'Face 3 · now: Attack 5',
            note: 'The 70% rule.',
            currentId: 'b',
            options: [
              option(
                  'a',
                  'Frappe du bouclier de la garde du port',
                  const FaceChange(
                      before: 'Attack 5',
                      after: 'Attack 7 · Water',
                      kind: FaceChangeKind.gain,
                      delta: 2)),
              option(
                  'b',
                  'Skill b',
                  const FaceChange(
                      before: 'Attack 5',
                      after: 'Mana +2 · Light',
                      kind: FaceChangeKind.kind)),
              option(
                  'c',
                  'Skill c',
                  const FaceChange(
                      before: 'Attack 5',
                      after: 'Attack 12 · Fire',
                      kind: FaceChangeKind.gain,
                      delta: 7),
                  allowed: false,
                  limit: 'already on 1 faces of this die'),
            ],
            onSet: (_) {},
            onClear: () {},
            clearSubtitle: 'Back to a plain Attack',
          ),
          bare: true,
        ),
        SmokeCase(
          'item_phoenix_sigil',
          Consumer(
            builder: (context, ref, _) => ItemDetailView(
              itemId: 'phoenix_sigil',
              item: items['phoenix_sigil'] as Map<String, dynamic>,
              language: ref.watch(appLanguageProvider),
              priceLine: 'Cost: 120',
              unmetRequirement: 'Requires level 12',
              equipped: items['harborwatch_cutlass'] as Map<String, dynamic>,
              equippedId: 'harborwatch_cutlass',
              equippedName: 'Harborwatch Cutlass',
              extraNote: 'Found at the Black Hold.',
              originLine: 'Chapter 3, the Lantern Hall',
              count: 2,
            ),
          ),
        ),
        SmokeCase(
          'item_void_banner',
          Consumer(
            builder: (context, ref, _) => ItemDetailView(
              itemId: 'void_banner',
              item: items['void_banner'] as Map<String, dynamic>,
              language: ref.watch(appLanguageProvider),
              isWorn: true,
              wornBy: 'Sable',
            ),
          ),
        ),
        SmokeCase(
          'title_cliff_light',
          Consumer(
            builder: (context, ref, _) => TitleDetailView(
              title: clans.titles['cliff_light']!,
              faction: clans.factions['dominion'],
              language: ref.watch(appLanguageProvider),
              worn: true,
            ),
          ),
        ),
      ],
      overrides: [
        trainingPathsProvider.overrideWith((ref) async => paths),
        nextChapterLevelAdviceProvider.overrideWithValue(
            const ChapterLevelAdvice(
                chapter: 4,
                recommendedLevel: 9,
                playerLevel: 6,
                note: 'The Shroud Road is no place for a party of six.')),
      ],
    );
  }, timeout: const Timeout(Duration(minutes: 10)));
}
