# Card combinations: what exists, what wins, what nobody sees

The user's request (via the manager): "focus on the different combinations
of cards for playing, detail their strengths, and evaluate their interest or
complexity and occurrences". This is a report for Core. It changes no rule,
number or code.

**What a card is.** The player's cards are the faces of the die in play.
Each face does one of these:
- a basic action (Attack, Defend, Heal, Mana, with a number);
- the die's own skill;
- a skill the player sets on an open face.

A skill set on a basic face casts at 70% (`channeledPower`,
`lib/combat/combat_engine.dart`). A skill's hit is
`(baseDamage + damageMod) x damageMultiplier`, times its `strikes`.
On top of the faces sit the profession's core, the specialisations, signs,
gear and the companions' own dice.

## Sources

| Tag | What | Version | Runs |
|---|---|---|---|
| **B976** | My batch: `simulatePlaythroughs`, typical (T) and competent (C) policies, seeds 1..100, the 25 race x profession pairs x 4 goals (the set of `difficulty-review-1.914/`). It reads the run summaries (offers, specs, die, merges) and the build at fights 3200 and 7810. The harness was a throwaway test, now deleted. Numbers are in `combinations-review.csv`. | v1.976.0 (9d524bae) | 100 + 100 |
| **TP933** | `typical-player.md` | v1.933 | 100 x 3 policies |
| **SP** | `specialisations.md`: 200 runs per line, seed 11 | before the spec retune (see note) | 200 per line |
| **SD759** | `starter-die.md` | v1.759 | 50 |
| **Static** | My reading of the gamedata at v1.976: skill power at base damage 10, counts | v1.976 | no runs |

Caveats that apply everywhere:
- The simulator does **not** play party combos (Flank, Volley, Shelter,
  Shield Wall, Wellspring) or duo techniques. Nothing under `lib/data/sim*`
  references them.
- It rolls **one die per run**. The fight setup screen lets a player swap
  dice per fight and stars the die that hits a known weakness
  (`fight_quick.dart`). The simulator never does.
- So anything built on those three is "estimated" below, not measured.
- **Fight win %** in B976 is fights won over fights fought across a whole
  run, retries counted. It is not TP933's encounter rate.
- The SP figures are older than the current constants. For example,
  `briarReflectShare` is 0.8 in code but "a quarter" in SP, and
  `burdenFullWellMultiplier` is 1.4 in code but "x2" in SP. Treat SP as
  direction only.

## 1. Inventory

### Building blocks

| Block | Count (static) | How it is gained | Rules a player must know |
|---|---|---|---|
| Player skills | 139 (85 tree, 10 sub-clan, 10 ascension, 10 fusion, 6 merge, 4 reputation, 14 other or secret) | Clan offers (three suitors per level, boss or chapter) | set on a face; 70% on a basic face |
| Skill trees | 27 branches: 3 to 4 per profession plus extras, 5 heritage | A branch's skills come in order; depth is gated by standing (Unknown/Known/Trusted/Sworn = index 0/1/2/3) | branch order, mastery (+1 tier) |
| Merges | 6 recipes (`skill_merges.json`), legendary, eat both inputs | Skillwright shop | recipe, where the shop is |
| Fusions | 10, epic | Offer from either clan, both parents known, **Trusted with both clans** | two clans, two parents |
| Ascensions | 10, epic | Offer, the parent known, Friend with one clan | one parent |
| Dice | 36: 6 clan dice, 6 companion-only dice, 24 others | Shops (22 dice sold in 14 shops), clan gift at Trusted, start | faces, element, size (4 to 12 faces) |
| Profession cores | 5: Fury, Watchfire, Ash Well, Flurry, Trail | Always on | one each |
| Specialisations | 15 main + 8 weak-link, plus sub-clan variants and rank II | Clan gift from Friend; they stack | one rule each, often two |
| Signs | 80 in 5 slots (strike 15, guard 10, mend 8, spell 11, passive 36) | Clan offers | slot; passives stack |
| Item sets | 2 (Harbourwatch, Hollow Court), 3 pieces each | Shops; the Hollow Court seal also drops | 2 or 3 pieces |
| Face smithing | hone, temper (element), inscribe (cleave, pierce, growth, echo, pain, steady), recast | Hammersmith | 6 keywords |
| Elements | 9; an enemy's weakness is **x3**, a resistance x0.5 (`enemy_intent.dart`) | Die faces, skills, tempering | weak/resist icons |
| Element reactions | 6 pairs: Conduct, Shatter, Firestorm, Freeze, Sandblast, Eclipse (+100%) | Two partner elements on one foe within 2 rounds | the pairs and the order |
| Party combos | 5: Flank (2 strikes x1.15), Volley (3+ strikes, splash), Shelter, Shield Wall, Wellspring | Matching kept faces of 2+ members | matching roles |
| Duo techniques | 9 pairs | Both companions seated at friendly approval, both keeping a signature face | which pairs |
| Parry | Defend set on a foe's blow: x1.5, counter 50% | Each round | telegraphs |
| Clan die resonance | faces of 1 to 3 are worth +1 | Friend with the clan, which must be your main clan | standing |

Skill power at base damage 10 (static, median of the damaging skills):
- tree 14.3;
- sub-clan 15.6;
- fusion 18.0;
- ascension 22.1;
- merge 23.4;
- `heavy_attack`, the default skill face, 15.4.

The outliers:
- `mage_stormcaller`: 39.6 (3 strikes plus splash);
- `rogue_gale_cut`: 26.4 (2 strikes, though it is only "rare").

### The archetypes that exist in the data

| # | Archetype | Core of it |
|---|---|---|
| A1 | **Starter-die slotter** (warrior, ranger) | The starter die's 3 open faces filled with the best offered skills. Fury or Trail on top. |
| A2 | **Headsman bruiser** (any, mostly casters) | `headsman_die`: 4 faces, A2 A2 Heavy D2. No dead face. |
| A3 | **Shadow Flurry rogue** | `shadow_die` (Void) with Flurry's double strikes and crit specs (Relicbreaker, Ledger Knife, Fever Blade). |
| A4 | **Watchfire cleric** | Heal faces that burn the foe. Long Vigil and Ashen Hand. Holy or tide die. |
| A5 | **Ash Well mage** | Mana faces and spells. Censer, Burden-Bearer, Tempest Toll. Arcane, court or apprentice die. |
| A6 | **Fury warrior** | Iron die. Berserker (pain), Briar Guard (block to Fury), Lantern Vanguard (Fire, pierce heavy). |
| A7 | **Clan-die loyalist** | A clan's gift die with resonance (lantern, court, vigil, cinder, ossuary, tally). |
| A8 | **Element hunter** | Swap to the die that hits the foe's weakness (x3). Pair elements for reactions. |
| A9 | **Skill crafter** | Merges, fusions and ascensions: the legendary and epic skills. |
| A10 | **Party player** | Companions' dice, party combos, duos and parry. |
| A11 | **Set wearer** | Hollow Court (thorns, then lifesteal) or Harbourwatch (dodge, then crit). |

## 2. Strength, interest, complexity, occurrence

Tags: **DOM** dominant, **DEAD** offered but weak or never used,
**HID** strong but almost never offered or used, **UNM** unmeasured by the
simulator.

| # | Strength | Interest | Complexity | Occurrence | Flag |
|---|---|---|---|---|---|
| A1 | Starter die at the end: T 96.5% fight win over 25 runs, C 96.9% over 23 (B976). | Low. The die never changes; only the 3 skills do. | Low | Final die in T 25/100 and C 23/100. Warrior 13/20 T, ranger 12/20 T (B976). SD759 fixed this for the competent player only. | **DOM** by inertia |
| A2 | T 95.0% (15 runs); C 99.8% (6 runs), the best of any die with 5 or more runs (B976). | Low. Two plain A2 faces beat every rich die. | Very low | Final die for T clerics 11/20 and T mages 4/20. 16 of 100 T runs at Tear Herald (B976). Sold at 180 gold. | **DOM** |
| A3 | Rogue fight win: T 93.0%, C 91.7% (B976). The ch8 bosses (Tear Herald, Void Sovereign, Void Archon) and void hounds **resist Void** (static). | Medium: crit chains. | Medium | `shadow_die` is the final die of **20/20** T rogues and 16/20 C rogues (B976). | DOM in picks, weak where it matters |
| A4 | Cleric T 95.4%. Long Vigil holders 96.7% vs 93.4% without (13 vs 7 runs, noise about ±3) (B976). | Medium: overheal into a fire. | Medium | Long Vigil and Ashen Hand each held in 13/20 T cleric runs. Beacon in 3/20 (B976). Clerics mostly end on headsman, not a heal die. | ok; the heal die loses to A2 |
| A5 | Mage is the weakest profession for T: 86.0% fight win (B976), the only one under 93%. Burden-Bearer holders 77.6% vs 88.4% (5 vs 15 runs, noisy). | High: fill the Well, then spend. | High: Well, spell costs, overflow | Censer 4/20, Burden 5/20, Tempest 7/20 (T, B976). SP: the autoplay casts at once, so Censer and Burden are undervalued. | Censer and Burden **UNM**-ish |
| A6 | Warrior T 94.8%, C 99.0% (B976). C Berserker 99.5% (16 runs). | Medium | Medium | Briar Guard 17/20 T warriors; Berserker 4/20 T but 16/20 C; Lantern Vanguard 3/20 T, 2/20 C (B976). | Vanguard near **DEAD** |
| A7 | Few runs to judge: lantern 6, vigil 2 to 5, court 4 to 15 (B976). | Medium: standing makes a die stronger. | Medium | Clan dice are **taken but not rolled**. T took cinder 63 times, vigil 59, ossuary 37, tally 21. At the run's end it rolled cinder 0, ossuary 0, tally 0, vigil 2 (B976). C: tally offered 283 times, taken 25, rolled 0. | cinder, ossuary, tally **DEAD** |
| A8 | Estimated, not measured. Most ch8 fights are against Light-weak foes: Light faces deal x3, against x0.5 for Void. A lantern die (4 of 6 faces Light) against Tear Herald is about x2.3 the die's damage (estimate: 4/6 faces x3). 26 of 78 enemy types are weak to Light, 21 to Electricity (static). | High: read the foe, pick the die. | Medium: the setup screen stars the right die. | 69/100 T runs own a Light die at Tear Herald and roll it in 5 (B976). The simulator never swaps. | **HID**, likely **DOM** live (estimated) |
| A8b | Reactions: Eclipse +100%, Shatter +60%, Conduct +50% (static). | High | High: 6 pairs and an order | The commonest parties bring Fire (Maren) plus None (Kelda), or Fire plus Void (Sable). No reaction is possible without a Wind, Ice or Light hero die (static, from the B976 parties). | **HID** |
| A9a | Merges: legendary, median 23.4 vs tree 14.3 (static). | Medium | Medium: a recipe, a shop | **0/100 T, 5/100 C** crafted (B976). | **HID** |
| A9b | Fusions: epic, median 18.0 (static). `rogue_viper_kiss` (18) uses the same inputs as the merge `venomous_ambush` (25.2). | Medium | High: two clans at Trusted | Offered 24 times in 100 T runs and 8 in 100 C. **7 of 10 fusions were never offered in 200 runs**. Pack Ambush is 2/3 of the takes (B976). | **HID** / **DEAD** |
| A9c | Ascensions: median 22.1, the best skills a run actually meets (static). | Medium: upgrade a skill you use. | Low | Offered 172 and taken 85 (T); 87 and 16 (C) (B976). | ok; the best value now |
| A9d | Deep tree skills: `mage_stormcaller` 39.6, `rogue_gale_cut` 26.4 (static). | n/a | Low | Both offered **0 times in 200 runs**. Stormcaller sits at branch index 3 (Sworn); Gale Cut at index 1 of `rogue_gale` (B976). | **HID** |
| A10a | Party combos: **UNM**. Flank x1.15 on 2 strikes. With 3 fighters a round, one triggers most rounds (estimated: 2 of 3 members keep a strike on most rolls). | High: keep or reroll. | Medium: 5 patterns | Every live fight with a companion. The simulator ignores it, so the live fight is easier than measured. | **UNM** |
| A10b | Duo techniques: **UNM**. | High | Medium | The two commonest pairs, Kelda+Maren (43 T, 54 C) and Maren+Sable (22 T, 10 C), **have no duo**. Pairs with a duo: 14/100 T, 11/100 C at Tear Herald, before the approval check (B976). | **HID** |
| A10c | Companions as a whole: naive to stubborn takes encounters won within 3 tries from 76.9% to 94.7% (TP933). | Low: the story seats them. | Low | Maren is in about 75% of parties (B976). | **DOM**, the biggest single lever |
| A11 | Hollow Court 3 pieces: +2 attack and 10% lifesteal. | Medium | Low | Never complete in 200 runs. 2 pieces in 12/100 C runs; 1 piece (the seal) in 100/100 T. Harbourwatch: 0 pieces worn in 200 runs (B976). | **DEAD** |
| Signs | Many small passives: block chance 8%, thorns 10%, +2 CON (static). | Low each | Low | 10 to 16 held at Tear Herald (T). Compact and Open Hand passives are the most held (B976). | filler, fine |

Taken over offered, all skill cards: T 1053/3858, C 412/7303 (B976).
Once the open faces are full, a new skill adds little. The competent
player takes signs instead (4271 of 6578 picks).

## 3. Improvements, ranked by value for cost

| # | Change (file) | Expected effect | Cost | Other sessions |
|---|---|---|---|---|
| 1 | **Let the simulator swap dice per fight**, as the setup screen does: the owned die with the best `simDieValue` against the foe's `weakTo` (`lib/data/sim_growth.dart`, `sim_policy.dart`, typical and competent only). | Measures A8, today the biggest unknown. Estimated: large gains in ch8, where 69% of T runs own a Light die. It may show that x3 is too strong once players swap. | small | none |
| 2 | **Add duos for Kelda+Maren and Maren+Sable** (`lib/combat/duo_techniques.dart`). | Parties with a duo go from about 14% to about 79% (B976 pair counts). Estimated effect on wins: unknown until the simulator plays duos (see #6). | medium | Narrative (names and lines), UX (label, VFX) |
| 3 | **Fusions at Friend with both clans, not Trusted** (`_fusionMinTier`, `lib/data/offers.dart`). Give `rogue_viper_kiss` its own parents, for example backstab + tar snare (`skills.json` `fusionOf`). | Estimated: about as often offered as ascensions, which are at Friend: 172 against 24 per 100 T runs. Ends the merge/fusion clash on one pair. | small | Narrative if the viper text changes |
| 4 | **Clan dice: open skill faces, or resonance on every face** (`dice.json` `cinder_die`, `ossuary_die`, `tally_die`; `clan_dice.dart`). Tally has 12 plain faces and no skill slot. | Turns 121 dead clan-die takes (T: cinder, ossuary, tally) into dice that get rolled. Measure with the same batch. | small | Art if a face changes picture; UX for face labels |
| 5 | **Headsman: 6 faces, or one Defend slot changed** (`dice.json`). Today it has 4 faces, A2 A2 Heavy D2. | Ends the "plain beats rich" result for casters (T clerics 11/20 end on it). Re-check that the cleric's win stays at 93% or more. | small | none |
| 6 | **The simulator plays party combos and duos** (`lib/data/sim_combat/sim_fight_party_turn.dart`, reusing `party_combos.dart` and `duo_techniques.dart`). | Turns A10a and A10b from UNM into numbers. Expected: the bands rise for every companion run, because the simulator underrates the live fight today. | medium | QA (the bands move) |
| 7 | **Hint a ready merge**: when both inputs are known, the Skillwright appears on the travel list or a clan suitor brings the recipe (`offers.dart`, a new gift kind). | Merges go from 0/100 T runs to an estimated 30 to 50 (`wrath_of_dawn` inputs are offered 44 times per 100 T runs). | medium | UX (hint), Narrative (suitor line) |
| 8 | **Stormcaller and Gale Cut** are never offered: move them up a branch tier, or cut Stormcaller to 2 strikes (`skill_trees.json`, `skills.json`). | Brings two signature skills into reach. Today they are never seen, so balance them before moving them. | small | none |
| 9 | **Sets**: drop Harbourwatch into loot, or fold both sets into clan gifts (`items.json`, `enemies.json` loot, `item_sets.json`). | 0 sets complete today. Estimated small strength change; a new choice in the gear slot. | small | Narrative (where it drops), Art if new icons |
| 10 | **Rogue against the ch8 bosses**: give `shadow_die` one Light or open face, or soften Void resistance on the bosses (`dice.json`, `enemies.json`). | Only if #1 shows rogues lose more in ch8. They roll Void into Void resistance today. | small | none |

Two text fixes for Narrative, found on the way:
- The Ledger Knife gift says a critical "hits for double". The code says
  x1.75 (`_ledgerCriticalMultiplier`).
- `specialisations.md` (SP) quotes older numbers: Briar 25%, Rot 40%,
  Burden x2, Long Vigil 5%. The code says 0.8, 0.2, 1.4 and 0.15. SP should
  be rerun.

## 4. Questions only the user can answer

1. Should the player be pushed to swap dice per fight (element hunting),
   or should one die mostly carry a run? This decides whether the x3
   weakness stays.
2. Should rare combinations (merges, fusions, deep skills) stay rare
   secrets, or should a normal run meet at least one?
3. Should a plain die like Headsman be allowed to beat the richer dice, as
   a "simple is strong" choice?
4. Should the two companion pairs most players have (Kelda+Maren,
   Maren+Sable) get duo techniques, or are duos a reward for unusual
   parties?
5. Clan dice: should a gift die be better than a bought one, or is it a
   keepsake?
6. Gear sets: keep them, expand them, or remove them?
