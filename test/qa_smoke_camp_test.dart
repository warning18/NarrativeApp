// QA: the camp's building tray and works list, and the skill tree with its
// clan flags (v1.480), on a phone with the app's own fonts. 360 x 740 and
// 320 x 568, English and French, no overflow (qa_smoke_harness.dart;
// SMOKE_SHOTS=<folder> for the pictures).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/screens/skills/skills_screen.dart';
import 'package:narrative_data_app/widgets/camp_town_section.dart';

import 'qa_smoke_harness.dart';

Future<void> _loadTables(ProviderContainer container) async {
  for (final schema in [
    housesSchema,
    shopsSchema,
    zonesSchema,
    achievementsSchema,
    factionsSchema,
    subclansSchema,
    skillsSchema,
    skillTreesSchema,
  ]) {
    await container.read(gameDbProvider(schema).notifier).whenLoaded();
  }
}

/// The town section as the camp screen builds it.
class _Town extends ConsumerWidget {
  const _Town();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Map<String, dynamic> table(DbSchema schema) =>
        ref.watch(localizedDbProvider(schema)).value ??
        const <String, dynamic>{};
    return CampTownSection(
      houses: table(housesSchema),
      shops: table(shopsSchema),
      zones: table(zonesSchema),
      achievements: table(achievementsSchema),
    );
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  PlayerSession camp(Map<String, dynamic> more) => PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'ownedDiceIds': ['starter_die'],
        'equippedDiceId': 'starter_die',
        ...more,
      });

  testWidgets('the camp tray and the skill tree read on a phone, EN and FR',
      (tester) async {
    await runSmoke(tester, [
      SmokeCase(
        'camp_town_poor',
        const _Town(),
        session: camp({'gold': 40}),
        prepare: _loadTables,
      ),
      SmokeCase(
        'camp_town_rich',
        const _Town(),
        session: camp({
          'gold': 900,
          'inventoryItemIds': ['material_timber', 'material_timber'],
          'recruitedAllies': [
            {'companionId': 'kelda'},
          ],
          'builtHouseIds': ['harbor', 'parley_tent', 'hearth_hall'],
        }),
        prepare: _loadTables,
      ),
      SmokeCase(
        'skill_tree_warrior',
        const SkillsScreen(),
        session: camp({'level': 8, 'skillEssence': 6}),
        prepare: _loadTables,
        bare: true,
      ),
      SmokeCase(
        'skill_tree_mage_elf',
        const SkillsScreen(),
        session: PlayerSession.fromJson({
          'raceId': 'elf',
          'professionId': 'mage',
          'level': 12,
          'ownedDiceIds': ['starter_die'],
          'equippedDiceId': 'starter_die',
        }),
        prepare: _loadTables,
        bare: true,
      ),
    ]);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
