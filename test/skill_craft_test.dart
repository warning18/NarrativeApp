// Crafting a skill (Wave 7, skill_craft.dart): only at the camp's
// Skillwright, and the recipes named for the player, never by their ids.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/camp_works.dart';
import 'package:narrative_data_app/data/skill_craft.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final merges = _table('skill_merges');

  test('the Skillwright is a workshop at the camp, and opens the craft', () {
    final house = _table('houses')[skillwrightHouseId] as Map<String, dynamic>;
    expect(house['unlocksCraft'], isTrue);
    expect(workCategoryOf(skillwrightHouseId, house), WorkCategory.workshops);
    // Its own field matches what it gives.
    expect(workCategoryOf(skillwrightHouseId, {...house}..remove('category')),
        WorkCategory.workshops);
    expect(skillCraftOpen(const []), isFalse);
    expect(skillCraftOpen(const [skillwrightHouseId]), isTrue);
  });

  test('a recipe reads by the skills\' names, ready ones first', () {
    final recipes = craftRecipesFor(
      merges: merges,
      unlockedSkillIds: const ['fireball', 'shadow_step'],
      language: AppLanguage.en,
    );
    expect(recipes, hasLength(merges.length));
    final blazing = recipes.first;
    expect(blazing.ready, isTrue);
    expect(blazing.inputs.map((s) => s.name), ['Fireball', 'Shadow Step']);
    expect(blazing.result.name, isNot(contains('_')));
    for (final r in recipes.skip(1)) {
      expect(r.ready, isFalse);
      for (final s in [...r.inputs, ...r.missing, r.result]) {
        expect(s.name, isNot(contains('_')), reason: s.id);
      }
    }
    // In French, the French names.
    final fr = craftRecipesFor(
      merges: merges,
      unlockedSkillIds: const [],
      language: AppLanguage.fr,
    );
    expect(fr.first.missing, hasLength(fr.first.inputs.length));
  });
}
