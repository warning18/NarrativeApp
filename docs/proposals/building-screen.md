# Proposal: a readable building screen (G)

Core, for the manager and UX. Prep only: the data side is prototyped on
`claude/core` (`lib/data/camp_works.dart`, tested), and the PR follows the
weekly reset.

## Today

The Town tab lists the camp's 10 houses in one row of cards, ranked
buildable first, then short of gold, then locked, then built. A house is
shown once its ally is recruited (`houseDiscovered`). It can be built when
its `requiredFlags`, gold and materials are there (v1.281). Nothing says
when a house will come, or where its materials are found.

## Categories

A new field, `category` in houses.json, editable in the database editor.
When it is missing, it is worked out from the record the same way:

| category | houses | what they give |
|---|---|---|
| `sea` | the Harbor | the Eel's refit; sailing from the camp (v1.283) |
| `company` | Barracks Annex, Kelda's Hall | room in the party, a companion's home |
| `workshops` | Hammersmith, Academy, the Needle House, Smugglers' Cellar | a shop each |
| `greatWorks` | Hearth-Hall, Banner Loft, Shroud Shrine | the party's lasting bonuses |

## Unlocking over time

As agreed in the materials note, a house comes with **its tier's chapter**.
Its tier is that of its highest material (`materialTiers`), and the tier's
first chapter is when it shows:

| tier | first chapter | houses |
|---|---|---|
| 1 | 1 (so, the camp: 3) | Harbor, Barracks Annex, Kelda's Hall, Smugglers' Cellar |
| 2 | 3 | Hammersmith, Academy, the Needle House, Hearth-Hall |
| 3 | 5 | Banner Loft, Shroud Shrine |

The camp opens in chapter 3, so tiers 1 and 2 both show from the start, and
tier 3 adds the last two great works in chapter 5. Tier 4 materials have no
house yet; a late great work can use them later.

## States

Each house is in one state, with **what's missing** listed:

- **`locked`:** its tier's chapter is not reached, or its companion is not
  recruited. UX can show it as a silhouette with "Chapter 5" or "When Kelda
  joins", or hide it.
- **`shown`:** it can be seen, but something is still missing: a flag (the
  expedition that opens it), gold, or materials.
- **`buildable`:** everything is there.
- **`built`:** it stands.

Each missing thing is a `WorkNeed`:

| kind | id | have / need | sources |
|---|---|---|---|
| `chapter` | the chapter number | reached / needed | — |
| `ally` | the companion id | — | — |
| `flag` | the flag | — | the zones that set it (`rewardFlag`) |
| `gold` | — | purse / cost | — |
| `material` | the item id | in the pack / cost | the zones that pay it (`rewardMaterials`), then the shops that stock it |

The sources are ids. UX names them: a zone by its `zoneName`, a shop by its
name. A rare never has a shop, and its zones are where it drops.

## The provider UX lists from

```dart
enum WorkCategory { sea, company, workshops, greatWorks }
enum WorkState { locked, shown, buildable, built }

class WorkNeed {
  final WorkNeedKind kind;   // chapter, ally, flag, gold, material
  final String id;
  final int have, need;
  final List<String> zoneIds, shopIds;   // where to get it
}

class CampWork {
  final String houseId;
  final WorkCategory category;
  final int tier, chapter;   // its tier, and the chapter it shows from
  final WorkState state;
  final List<WorkNeed> needs;   // empty when buildable or built
}

// lib/data/camp_works.dart (pure, tested)
Map<WorkCategory, List<CampWork>> campWorksOf({...});
// lib/providers/camp_works_provider.dart
final campWorksProvider = Provider<Map<WorkCategory, List<CampWork>>>(...);
```

Within a category, houses are in tier order, then by gold cost. The
categories come in the enum's order.

## The PR after the reset

- **Core:**
  - `category` in houses.json and its schema;
  - `campWorksProvider`;
  - `buildHouse` refusing a house still `locked` (today only the flags,
    gold and materials stop it);
  - tests.
- **UX:** the Town tab's build screen, read from the provider: four
  sections, cards by state, the missing list with its sources.
- **Narrative:** the four category names and their one-line blurbs, in
  English and French.
- **Save impact:** none. Built houses stay built; a built house is never
  `locked`.
- **QA:** L1.
