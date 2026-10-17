# Camp buildings that bend the rolls (Core, proposal, wave 15)

Design only: nothing here is in the game yet.

What the user approved:
- **Reroll** the choices on the table, up to 4.
- **Banish** a choice for 5 to 15 draws: it is not offered again for that many draws.
- **Raise** a proposed choice's rarity: one charge every 15, up to 5 charges.

This note fixes the open parts: per what, every 15 *what*, costs, where it sits, save fields.

## 1. What it is

The camp can house people who read the bones. Build the Bone-Caster's Hut and you may throw back a hand you don't like and draw again. Build the Warding Cairn and you may turn a choice away: it won't come back for a while. Build the Star Well and, now and then, you may make one choice better than fate gave it. Each works on the two choices you make most often: the stat pick of a level, and the clans' offer. Each has a few charges that come back as you grow.

## 2. The three buildings

**Recommended: three buildings, not one building with three tiers.**
- A house in `houses.json` is one record, built once (`CampWork.limit` is "1 of 1"). There is no upgrade mechanism. Three records reuse everything: `builtHouseIds`, `category`, the building screen, `townOrder`.
- The material tier already staggers them by chapter (`workTierOf`, `tierFirstChapter`), so no prerequisite field is needed.
- One new field in `houses.json`: `rollPower`, one of `"reroll"`, `"banish"`, `"raise"` (Core adds it to `housesSchema` in `db_schema.dart`). `workCategoryOf` falls back to `workshops` for it, as for `unlocksRiskyGifts`; the records also carry an explicit `category`.

Costs, against today's houses:
- Workshops cost 230 to 350 gold with 4 to 6 commons (the Parley Tent, PR #411: 250, 2 timber, 2 cut stone).
- Great works cost 1 000 to 2 000 gold with 7 to 9 materials.

| id | Name EN / FR (draft, Narrative polishes) | category | gold | materials | tier → shows from | power |
|---|---|---|---|---|---|---|
| `bone_casters_hut` | Bone-Caster's Hut / La Hutte du jeteur d'os | `workshops` | 240 | 2 `material_timber`, 2 `material_cut_stone` | 1 → chapter 3 (the camp) | Reroll |
| `warding_cairn` | Warding Cairn / Le Cairn de garde | `workshops` | 300 | 2 `material_cut_stone`, 2 `material_slag_glass` | 2 → chapter 3 | Banish |
| `star_well` | Star Well / Le Puits aux étoiles | `greatWorks` | 1 200 | 3 `material_rime_crystal`, 2 `material_tear_glass` | 3 → chapter 5 | Raise |

- `requiredFlags: []` for all three, `partyCapacityBonus: 0`.
- The Star Well is a great work: it is the strongest of the three, and it comes late. No rare material, as in the materials rule (a rare only for a tier's top building, which the Banner Loft already is).
- Slag glass is earned in chapters 3 and 4, so the Cairn usually goes up a little after the Hut.

### Reroll (Bone-Caster's Hut)
- **Charges:** up to 4 (`rerollMaxCharges`). Full when built. **+1 per level gained**, never above 4.
- **Use:** 1 charge redraws the whole set on the table. Several rerolls on the same set are allowed, while charges last.
- **Stat pick:** `drawStatPick` again, with a new seed. **The tier is kept**: the pick's rarity was drawn once (`drawStatPickTier`), and the reroll changes *which* paths, not *how good*. Without this, 4 rerolls lift a Rare-or-better pick from 10% to about 41% (Luck 0), which is Raise's job.
- **Offer:** `drawOffer` again for the same `OfferTicket`. The ticket's faction and the home seat are still guaranteed (`drawOffer` does it). A risky card is drawn anew, with a new die.

### Banish (Warding Cairn)
- **Charges:** up to 3 (`banishMaxCharges`). Full when built. **+1 per level gained**, never above 3.
- **Length, chosen by the player:** 5, 10 or 15 draws (`banishLengths`), costing 1, 2 or 3 charges.
- **What is banished:**
  - on a stat pick, the card's training path (`StatPickOffer.pathId`);
  - on an offer, the card's gift (`GiftKind` + id: a skill, sign, object, title, spec, or the Wayfarer's perk). Not the clan: a clan still comes, with something else.
- **The card is replaced at once**, in its slot only:
  - stat pick: another path not shown and not banished, same tier (the `_drawThree` fallback: "another path instead");
  - offer: the same clan's `drawSuitor` without the banished gift; if the clan has nothing else, another faction from the pool, drawn as the offer's "other places" are.
- **Draws:** a ban counts down on each *fresh* draw of its own kind (stat picks for a path, offers for a gift). Rerolls and banish replacements are not fresh draws.
- **Can't be banished:** the Sworn boon (it comes once) and the ticket's own faction's card (a quest's clan always comes).

### Raise (Star Well)
- **Charges:** up to 5 (`raiseMaxCharges`). **1 when built**, then **+1 every 15 fresh draws** (`raiseChargeEvery`), stat picks and offers counted together, from the day it is built.
- A run sees about 41 draws: 29.4 offers (`report-100-runs.md`) and one pick a level (`levelStatPicks`, end level 12.8). The Well goes up in chapter 5, with about 15 to 20 draws left: **2 to 3 raises a run**. The cap of 5 only matters for a player who saves them.
- **Use:** 1 charge, on the selected card. **One raise per card** (`raised` flag).
- **Stat pick card:** its tier one step up. Its gains are rebuilt with `statPickGains` at the new tier, the second ability drawn from its path (seeded). Common +1 → Rare +2; Epic +3 → Heroic +4. The other two cards keep their tier. **A Heroic card can't be raised.**
- **Offer card:**
  - a sign: the same sign, one rarity up, still capped by the clan's power (`maxSignRarityFor`);
  - any other gift: the clan's `better` draw (`drawSuitor(id, c, random, better: true)`, as a quest's suitor): one rarity up, one skill deeper on the branch (`skillIndexCapFor` + 1). It may be a different skill or object.
  - The raise is **only offered when it shows a real step up**, as for risky gifts. The result is drawn when the button is checked and kept (`raisePreview`), so the button never lies.
- **Can't be raised:** a Heroic gift, the Sworn boon, the Wayfarer's perk (no rarity), a risky card (its better rarity is already the risk's prize).

## 3. Which draws, and interactions

**They apply to the "banner choice" draws only:**
- the stat pick (`ensureStatPick` → `drawStatPick`, `PlayerSession.statPickOffer`), tome picks included;
- the clans' offer (`ensureOffer` → `drawOffer`, `PlayerSession.clanOffer`).

Why these two:
- They are three cards, take one, and they stay on the table until one is taken. A reroll or a ban has a clear meaning, and the result is saved.
- Together they are about 41 draws a run, so charges that refill by level matter all run long.
- Not the others: ability checks and combat dice (a reroll there is a different feature), the sign rarity inside a gift (part of the offer), loot, the risky die alone (a reroll redraws the whole offer, die included; the die is revealed only on accept, so a reroll never dodges a known loss).

**Interactions:**
- **Reroll after a raise or a banish:** the redraw replaces everything; the spent charges are not refunded. UX warns once ("The raised card goes too").
- **Bans and rerolls:** a reroll never brings back a banished path or gift.
- **Empty pools:** a ban is ignored for a draw that would otherwise fail: `drawStatPick` needs 3 paths with gains (10 exist), and a clan with no other gift kind keeps its banned one. The ban still counts that draw. Banning the home seat's last skill is allowed: the seat goes to another clan, as the player chose.
- **Heroic cap:** Raise never goes past Heroic (`_better` already clamps); the button hides.
- **Risky gifts (PR #411):** a risky card can be rerolled (with the offer) and banished, never raised. A raise on another card leaves the risky card as it is.
- **Luck:** untouched. Raise is a step on top of the Luck-shifted odds (`statPickOdds`).
- **Feature ladder:** offers wait for the clans (`GameFeature.clans`); the powers only act on a set that is on the table.

**Seeds.** `ensureStatPick` seeds from `level * 7919 + statPoints * 131 + takenTotal`, so a plain redraw would give the same cards. A new counter `rollNonce` (+1 per reroll, banish or raise) is mixed in: `+ rollNonce * 104729`. `ensureOffer` uses `Random()` in the app today; the new calls take an optional `random` like it. Tests always pass a seeded `Random(n)` (`qa_seeded_rolls_test`).

## 4. Where it sits in the camp

- **Building screen:** the Hut and the Cairn under The Workshops, the Well under The Great Works. They show by tier as every house does (`campWorksOf`).
- **Cliff town:** footprints in `houseFootprints` (UX): Hut 1×1, Cairn 1×1, Well 1×2 (a stone well-house with a sighting tower). They take their place in `townOrder` when built.
- **Where they are used:** not at the camp. On the cards, wherever they are drawn:
  - the stat pick: `lib/widgets/stat_pick_picker.dart` (level-up dialog and screen);
  - the offer: `lib/widgets/offer_dialog.dart` (the banner choice sheet).
- **Look (UX):** a row of up to three buttons under the cards, only for the powers built: "Reroll (3)", "Banish (2)", "Raise (1)". Banish and Raise act on the selected card; Banish opens a 5 / 10 / 15 chooser with its cost. A banished path or gift could show a small "warded, N draws" list (optional).

**API for UX** (on `PlayerSessionNotifier`; pure helpers in a new `lib/data/camp_rolls.dart`):

```dart
// What is built and what is left (null when the building isn't up).
CampRolls campRolls(Map<String, dynamic> houses); // reroll/banish/raise charges, bans
// Stat pick
Future<List<StatPickOffer>> rerollStatPick(Map<String, TrainingPath> paths, {Random? random});
Future<List<StatPickOffer>> banishStatPickOffer(int index, int draws, Map<String, TrainingPath> paths, {Random? random});
bool canRaiseStatPickOffer(int index);
Future<List<StatPickOffer>> raiseStatPickOffer(int index, Map<String, TrainingPath> paths, {Random? random});
// Offer
Future<ClanOffer?> rerollOffer(OfferTables tables, {Random? random, String placeHolder = ''});
Future<ClanOffer?> banishSuitor(String factionId, int draws, OfferTables tables, {Random? random, String placeHolder = ''});
Suitor? raisePreview(String factionId, OfferTables tables); // null: no step up
Future<ClanOffer?> raiseSuitor(String factionId, OfferTables tables);
```

Each returns the new set (or the old one, unchanged, when no charge is left), spends the charge and persists.

**As built (v1.479 code):** the names above, plus:
- `campRollsProvider` (a `Provider<CampRolls>`) and `campRollsOf(session)` for the charges without a houses table; `CampRolls.reroll/banish/raise` are null while the house isn't up, `bans` the running `RollBan`s (`on`, `id`, `left`).
- `suitorBanishable(suitor, offer)` and `suitorRaisable(suitor)` (camp_rolls.dart) for the buttons' state; `raisePreview` is seeded from `rollNonce`, so it matches `raiseSuitor` until a power is used.
- Core's minimal row is `lib/widgets/roll_power_row.dart` (`RollPowerRow`), placed in `stat_pick_picker.dart` and `offer_dialog.dart` above the take button; keys `stat_pick_roll_reroll|banish|raise`, `offer_roll_…`, the Banish chooser's `…_roll_banish_5|10|15`. UX restyles it freely.
- Strings: Narrative's keys (`roll_reroll`, `roll_banish`, `roll_raise` with `{left}`; `roll_banish_length` with `{draws}`, `{cost}`; `roll_banish_done`, `roll_raise_done`, `roll_reroll_done`, `roll_reroll_warning`, `roll_warded`, `roll_no_charge`). The row uses the first four and the warning.
- `workCategoryOf` falls back to workshops for Reroll and Banish only; a `raise` house without `category` reads as a great work, like the Star Well's own field.

**Strings** (EN + FR drafted in the code PR, next to the offer and stat pick strings): `roll_reroll`, `roll_banish`, `roll_raise`, `roll_banish_length`, `roll_reroll_warning`, `roll_warded`. Narrative: the three houses' names and descriptions.

## 5. Save fields

On `PlayerSession`, each written only when not its default, read with a default:

| field | type | default | meaning |
|---|---|---|---|
| `rerollCharges` | int | 0 | Reroll charges left |
| `banishCharges` | int | 0 | Banish charges left |
| `raiseCharges` | int | 0 | Raise charges left |
| `raiseProgress` | int | 0 | fresh draws toward the next Raise charge (0–14) |
| `rollBans` | list of `{on: "pick"\|"offer", id, left}` | [] | `id` a path id, or `kind:id` for a gift |
| `rollNonce` | int | 0 | mixed into the stat pick seed |

- `StatPickOffer.toJson` and `Suitor.toJson` gain `raised: true` (left out when false).
- `buildHouse` gains `rollPower` and fills the charges when the house goes up (4, 3, 1).
- One helper, `_countFreshDraw(kind)`, runs where `ensureStatPick` and `ensureOffer` draw anew: it counts bans down and moves `raiseProgress`.
- Level-up (`_levelOffers`'s two callers) adds +1 Reroll and +1 Banish per level gained, if built.
- **Old saves:** none of the three houses is built, so every field is at its default. `saveVersion` doesn't change.

## 6. Simulator and tests

**Building:** the simulator's `buildHouses` (`playthrough_simulator_screen.dart`) already builds any buildable house, cheapest first, from its own purse. The three join it with no change (`sim_houses_test`).

**Autoplay policy** (one `Random` of its own for the powers, like `riskyRandom`, so the rest of the run draws as it would without them):
- **Reroll, stat pick:** when `statPickFor` finds no card raising the build's stat or `statPickPriority` and falls back to the calling.
- **Reroll, offer:** when `preferredSuitor`'s choice fills no empty die face and is Common, keeping 1 charge in hand.
- **Banish:** stat picks only. A card whose ability is not the build's stat nor in `statPickPriority`, for 5 draws, while 2 or more charges are left. Never on offers (keeps the clan model of the sim untouched).
- **Raise:** at once, on the card autoplay takes: a sign or a skill that fills an empty face first, else a stat pick for the build's stat.
- **Sim JSON:** `campRolls: {rerolls, bans, raises}` per run.

**Expected effect (modest):**
- Rerolls make the build's stat show on about 9 picks in 10 instead of 2 in 3, from chapter 3: about +2 points to it by the end.
- Raises: 2 to 3 a run, about +1 point each on a pick, or a sign from ×1.5 to ×2.0.
- So about +3 to +4 points on the main stat at level 13 (it holds 20 to 30), and one better sign.
- I expect the 400-run attempt win rate (seeds 11 and 23) to move **by 1 to 2 points**. More than 3 points means the refill is too fast: I'd move Reroll and Banish to +1 every 2 levels.

**Tests** (all seeded):
- `camp_rolls_test` (new): charge caps and refills (Reroll and Banish per level, Raise every 15 draws, cap 5, 1 at build); banish costs 1/2/3 for 5/10/15; bans count down only on fresh draws of their kind; the empty-pool rule; a stat pick reroll keeps the tier and changes the cards; Raise's gains at each tier; Heroic not raisable.
- `offers_test`: a banned gift is never drawn; the ticket's faction still comes; a sign raise respects `maxSignRarityFor`; a `better` raise only when rarer; a risky card is not raisable; the Sworn boon is not banishable.
- `offers_session_test`, `stat_picks_test`: each call spends one charge and persists; `rollNonce` changes the draw; reopening never redraws; save round-trip; an old save loads with the defaults.
- `camp_works_test`: the three houses in their categories, showing at chapters 3, 3 and 5.
- `sim_houses_test`: the three are built in a seeded run.
- UX: `stat_pick_picker_test`, `offer_dialog_test` for the button row.

**Order:** the code PR follows PR #411 (risky gifts), which also touches `drawOffer`, `Suitor` and `offer_dialog.dart`.

## 7. Open questions for the user

1. **How Reroll and Banish refill.** Recommended: +1 per level gained. Alternative: full again at each new chapter (bigger bursts, fewer refills).
2. **What Banish removes from an offer.** Recommended: the gift (that skill or sign), so the clan can still come. Alternative: the whole clan for N offers, which is stronger and also starves its standing.
3. **Raise on a skill or object gift.** Recommended: the clan's better draw, which may change the skill to a deeper one on the branch. Alternative: Raise works on signs and stat picks only, and is greyed on other gifts.
