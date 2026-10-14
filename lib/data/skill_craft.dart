// Crafting a skill (Wave 7): two known skills fused into a third, by a
// skill_merges.json recipe, done at the camp's Skillwright and nowhere
// else. What the craft screen shows comes from here, with the skills' names
// in the player's language (never their ids).
import '../combat/dice_faces.dart' show skillDisplayName;
import '../l10n/app_locale.dart';

/// The camp house where skills are crafted (houses.json).
const String skillwrightHouseId = 'skillwright';

/// Whether skills can be crafted: the Skillwright stands at the camp.
bool skillCraftOpen(Iterable<String> builtHouseIds) =>
    builtHouseIds.contains(skillwrightHouseId);

/// A skill as the craft screen names it.
typedef CraftSkill = ({String id, String name});

/// One recipe as the craft screen shows it.
class CraftRecipe {
  const CraftRecipe({
    required this.id,
    required this.inputs,
    required this.result,
    required this.missing,
    required this.crafted,
  });

  final String id;

  /// The skills it fuses, in the recipe's order.
  final List<CraftSkill> inputs;

  /// The skill it makes.
  final CraftSkill result;

  /// The inputs the character has not learned yet.
  final List<CraftSkill> missing;

  /// Whether the result is already known.
  final bool crafted;

  /// Whether it can be crafted now (given the Skillwright stands).
  bool get ready => !crafted && missing.isEmpty;
}

/// Every recipe of [merges] (skill_merges.json) for a character knowing
/// [unlockedSkillIds], its skills named in [language]: ready ones first,
/// then those still missing an input, then those already crafted; each
/// group in the file's order.
List<CraftRecipe> craftRecipesFor({
  required Map<String, dynamic> merges,
  required Iterable<String> unlockedSkillIds,
  required AppLanguage language,
}) {
  final known = unlockedSkillIds.toSet();
  CraftSkill named(String id) =>
      (id: id, name: skillDisplayName(id, language: language));
  final recipes = [
    for (final MapEntry(:key, :value) in merges.entries)
      if (value is Map)
        () {
          final inputs = [
            for (final id in (value['inputSkillIDs'] as List? ?? const []))
              id.toString(),
          ];
          final result = value['resultSkillID']?.toString() ?? key;
          return CraftRecipe(
            id: key,
            inputs: [for (final id in inputs) named(id)],
            result: named(result),
            missing: [
              for (final id in inputs)
                if (!known.contains(id)) named(id),
            ],
            crafted: known.contains(result),
          );
        }(),
  ];
  int rank(CraftRecipe r) => r.ready
      ? 0
      : r.crafted
          ? 2
          : 1;
  final order = {for (final (i, r) in recipes.indexed) r.id: i};
  recipes.sort((a, b) {
    final c = rank(a).compareTo(rank(b));
    return c != 0 ? c : order[a.id]!.compareTo(order[b.id]!);
  });
  return recipes;
}
