// QA: the screens and widgets that changed between the 1.501 L3 and the 1.654
// one, on a phone with the app's own fonts: 412 x 892, 360 x 740 and
// 320 x 568, English and French, no overflow (qa_smoke_harness.dart;
// SMOKE_SHOTS=<folder> for the pictures).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/dice_loadout_screen.dart';
import 'package:narrative_data_app/screens/epilogue_map_screen.dart';
import 'package:narrative_data_app/screens/skills/dice_weave_card.dart';
import 'package:narrative_data_app/screens/skills/skills_screen.dart';
import 'package:narrative_data_app/widgets/character_die_badge.dart';
import 'package:narrative_data_app/widgets/clan_rank_plate.dart';
import 'package:narrative_data_app/widgets/fight_entrance.dart';
import 'package:narrative_data_app/widgets/handover_list.dart';
import 'package:narrative_data_app/widgets/poly_die.dart';
import 'package:narrative_data_app/widgets/prologue_opening.dart';
import 'package:narrative_data_app/widgets/standing_sign.dart';
import 'package:narrative_data_app/widgets/ward_sheet.dart';

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
  ]) {
    await container.read(gameDbProvider(schema).notifier).whenLoaded();
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  final graph =
      jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
          as Map<String, dynamic>;
  final dice = (jsonDecode(File('assets/gamedata/dice.json').readAsStringSync())
          as Map<String, dynamic>)
      .keys
      .toList();

  PlayerSession save([Map<String, dynamic> extra = const {}]) =>
      PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'level': 12,
        'gold': 420,
        'ownedDiceIds': ['starter_die', ...dice.take(8)],
        'equippedDiceId': 'starter_die',
        ...extra,
      });

  testWidgets('the screens changed since 1.501 read on a phone, EN and FR',
      (tester) async {
    await runSmoke(
      tester,
      [
        SmokeCase('epilogue_map', const EpilogueMapScreen(),
            session: save(), prepare: _load, bare: true),
        SmokeCase(
          'clan_rank_plates',
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final id in const [
              'dominion',
              'crows',
              'vigil',
              'compact',
              'mire',
              'penitents',
            ])
              ClanRankPlate(clanId: id, size: 14),
          ]),
          session: save(),
          prepare: _load,
        ),
        SmokeCase(
          'standing_signs',
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in StandingTier.values) StandingSign(t, size: 44),
          ]),
        ),
        SmokeCase(
          'dice_shapes',
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final s in DieShape.values) ...[
              PolyDie(shape: s, size: 40, label: '20'),
              PolyDie(shape: s, size: 96, label: '12'),
            ],
          ]),
        ),
        SmokeCase('dice_loadout', const DiceLoadoutScreen(),
            session: save(), prepare: _load, bare: true),
        SmokeCase('dice_weave_card', const DiceWeaveCard(),
            session: save(), prepare: _load),
        SmokeCase('character_die_badge', const CharacterDieBadge(),
            session: save(), prepare: _load),
        SmokeCase('skills_star_chart', const SkillsScreen(),
            session: save({'skillEssence': 6}), prepare: _load, bare: true),
        SmokeCase(
          'prologue_opening',
          PrologueOpening(
            text: (graph['0'] as Map)['description_fr'] as String,
            choices: const SizedBox(height: 80),
          ),
          session: save(),
          prepare: _load,
          // The whole telling, not its first words.
          act: (tester) async {
            for (var i = 0; i < 12; i++) {
              await tester.pump(const Duration(seconds: 5));
            }
          },
          bare: true,
        ),
        SmokeCase('ward_sheet', const WardSheet(),
            session: save(), prepare: _load),
        SmokeCase('handover_list', const HandoverList(),
            session: save(), prepare: _load),
        SmokeCase(
          'fight_entrance',
          const SizedBox(
              height: 420,
              child: FightEntrance(
                enemyId: 'slum_thug',
                name: 'The Inquisition High Warden of the Ashen Quarter',
                line: 'He keeps the third piece at the bottom of the Drowned '
                    'Stair, and he has not slept since the burning.',
                boss: true,
                child: SizedBox(height: 120),
              )),
          session: save(),
          prepare: _load,
        ),
      ],
      sizes: _phones,
    );
  }, timeout: const Timeout(Duration(minutes: 15)));
}
