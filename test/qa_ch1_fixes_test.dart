// QA: guards for the two bugs the chapter 1 review found (docs/qa/chapter1-review.md).
//  #582: the race and profession screen read the starting skills' names from
//        their ids, so French players saw "Resolve" and "Shield Bash".
//  #583: the forced boarding prices (896_failed, 897_failed) were not enforced
//        for a purse too short to pay them.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/story_prices.dart';
import 'package:narrative_data_app/gamedata/db_schema.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/game_db_providers.dart';
import 'package:narrative_data_app/screens/race_profession_screen.dart';

import 'qa_smoke_harness.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadSmokeFonts();
  });

  test('#583: a price after a failed check is a forced price, wounds and all',
      () {
    final graph =
        jsonDecode(File('assets/Cleaned_Narrative_DAG.json').readAsStringSync())
            as Map<String, dynamic>;
    final unmarked = <String>[];
    var seen = 0;
    for (final entry in graph.entries) {
      if (!entry.key.endsWith('_failed')) continue;
      for (final c in (entry.value as Map)['choices'] as List) {
        final cost = ((c as Map)['goldMod'] as num?) ?? 0;
        if (cost >= 0) continue;
        seen++;
        if (c['shortfallWounds'] != true && c['pays'] != true) {
          unmarked.add('${entry.key} "${c['text']}"');
        }
      }
    }
    expect(seen, greaterThanOrEqualTo(2), reason: '896_failed, 897_failed');
    expect(unmarked, isEmpty,
        reason: 'a price on the way on after a failed check takes what the '
            'purse holds (`shortfallWounds`), or is a `pays` choice shut to a '
            'short purse:\n${unmarked.join('\n')}');
  });

  test('#583: the wound is the gold missing, never more', () {
    expect(shortfallWound(gold: 10, goldMod: -40), -30);
    expect(shortfallWound(gold: 0, goldMod: -25), -25);
    expect(shortfallWound(gold: 40, goldMod: -40), 0);
    expect(shortfallWound(gold: 500, goldMod: -40), 0);
    expect(shortfallWound(gold: 5, goldMod: 12), 0);
  });

  testWidgets('#582: the race screen names the starting skills in French',
      (tester) async {
    final skills =
        jsonDecode(File('assets/gamedata/skills.json').readAsStringSync())
            as Map<String, dynamic>;
    final french = <String>[];
    for (final id in const ['human_resolve', 'warrior_shield_bash']) {
      french.add(skills[id]['name_fr'] as String);
    }
    await runSmoke(
      tester,
      [
        SmokeCase(
          'race_skill_names',
          const RaceProfessionScreen(),
          bare: true,
          prepare: (container) async {
            await container
                .read(gameDbProvider(skillsSchema).notifier)
                .whenLoaded();
            await container
                .read(gameDbProvider(racesSchema).notifier)
                .whenLoaded();
            await container
                .read(gameDbProvider(professionsSchema).notifier)
                .whenLoaded();
          },
          act: (tester) async {
            final container = ProviderScope.containerOf(
                tester.element(find.byType(RaceProfessionScreen)));
            final isFrench =
                container.read(appLanguageProvider) == AppLanguage.fr;
            if (isFrench) {
              for (final name in french) {
                expect(find.text(name), findsWidgets,
                    reason: 'French shows "$name"');
              }
              for (final id in const ['Resolve', 'Shield Bash']) {
                expect(find.text(id), findsNothing,
                    reason: 'the id-built English name "$id" is gone');
              }
            }
          },
        ),
      ],
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
