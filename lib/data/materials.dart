/// The building economy's materials (v1.281.0, docs/proposals/
/// building-materials.md): Material items in four tiers, one per stage of
/// the story, each with a common one (it stacks, sells, a shop or two stocks
/// it) and, from tier 2, a rare one no shop sells. The camp's buildings cost
/// them beside gold (houses.json `materialCost`); expeditions pay them
/// (zones.json `rewardMaterials`), ordinary foes drop the commons, and the
/// sea gives them too (a derelict's salvage, a won ship battle's rare).
library;

/// The tier's chapters: tier 1 is chapters 1-2, tier 2 chapters 3-4,
/// tier 3 chapters 5-6, tier 4 chapters 7-8.
int materialTierForChapter(int chapter) => (chapter.clamp(1, 8) + 1) ~/ 2;

/// Each tier's common material (the first) and its rare one (none for
/// tier 1).
const Map<int, ({List<String> commons, String? rare})> materialTiers = {
  1: (commons: ['material_timber', 'material_cut_stone'], rare: null),
  2: (
    commons: ['material_iron_ore', 'material_slag_glass'],
    rare: 'material_ash_steel'
  ),
  3: (
    commons: ['material_rime_crystal', 'material_tear_glass'],
    rare: 'material_shroud_thread'
  ),
  4: (commons: ['material_lantern_brass'], rare: 'material_white_fleet_oak'),
};

/// A `{itemId: count}` field of [record] ([key]: houses.json
/// `materialCost`, zones.json `rewardMaterials`, items.json
/// `craftMaterials`), counts above zero only; empty when there is none.
Map<String, int> materialCountsOf(Map<String, dynamic>? record, String key) {
  final raw = record?[key];
  if (raw is! Map) return const {};
  return {
    for (final e in raw.entries)
      if (((e.value as num?)?.toInt() ?? 0) > 0)
        e.key.toString(): (e.value as num).toInt(),
  };
}

/// How many of [cost]'s materials [inventory] lacks, by item (empty when it
/// holds them all). The pack is a list with one entry a copy.
Map<String, int> missingMaterials(
    Iterable<String> inventory, Map<String, int> cost) {
  final held = <String, int>{};
  for (final id in inventory) {
    held[id] = (held[id] ?? 0) + 1;
  }
  return {
    for (final e in cost.entries)
      if ((held[e.key] ?? 0) < e.value) e.key: e.value - (held[e.key] ?? 0),
  };
}

/// [inventory] with [cost] taken out of it, one entry a copy (the caller
/// checks [missingMaterials] first).
List<String> withoutMaterials(List<String> inventory, Map<String, int> cost) {
  final left = [...inventory];
  for (final e in cost.entries) {
    for (var i = 0; i < e.value; i++) {
      left.remove(e.key);
    }
  }
  return left;
}

/// What a derelict's salvage yields at sea in [chapter]: the chapter's
/// first common material.
String salvageMaterialFor(int chapter) =>
    materialTiers[materialTierForChapter(chapter)]!.commons.first;

/// What a won ship battle adds in [chapter]: the chapter's rare material,
/// from tier 2 on (null before).
String? shipBattleMaterialFor(int chapter) =>
    materialTiers[materialTierForChapter(chapter)]!.rare;

/// The save version from which saves know materials (see
/// [legacyMaterialGrant]).
const int materialsSaveVersion = 4;

/// What a save made before materials existed (save version below
/// [materialsSaveVersion]) is given once on loading: one rare material of
/// each tier the story has already passed, read from the chapter its clock
/// counts in ([clockChapter], 0 when the clock never ran). A save already in
/// chapter 5 has passed tier 2; one in chapter 7, tier 3 too. The buildings
/// those tiers gate stay within reach without replaying their expeditions.
List<String> legacyMaterialGrant(int clockChapter) => [
      for (var tier = 2; tier <= 3; tier++)
        if (clockChapter > tier * 2) materialTiers[tier]!.rare!,
    ];
