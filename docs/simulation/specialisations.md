# The clans' specialisations (v5.2, steps 2a to 3c)

> **Re-run on v2.10.0 (date 2026-11-25).** Every figure below was measured again on `main` at v2.10.0 with the same commands, seeds and run counts (the old figures dated from before v1.915). What moved notably:
> - **The cores fell and drew together:** fights won with the core alone are now 50.7% (warrior) to 54.7% (cleric), where they were 51.9% to 71.7%. Mage −18.4, ranger −16.3, rogue −10.2, warrior −9.6; cleric +2.8. The cleric's fights are shorter (11.9 rounds, was 14.5). This is the sum of the balance passes since v1.915 (the late-game chapter goals and weakness goal of v2.5.0–2.6.1 among them), not one change.
> - **Most specialisations now read below the +3 to +6 target:** only Berserker, Long Vigil, Censer Mage and Ledger Knife are in range (nine were). Down by more than 3 points: Briar Guard (+5.0 → +1.5), Beacon (+3.5 → +0.1), Tempest Toll (+5.2 → +1.3), Fever Blade (+6.5 → +2.3), Corsair's Eye (+5.8 → +1.5), Trapwright (+6.6 → +0.4), Fen Guide (+5.3 → +1.4). Up: Censer Mage (+1.9 → +5.7).
> - **Step 2b:** the gifts that read +4 to +7 now read −1 to +3 (Boarding Heart, Hand-Signed Wall, Briar Guard II, Debt Forgiven, One Witness, Once, Counted Breath); Relicbreaker II rose to +4.1.
> - **Step 3c:** the four weak links that read 0 now move by −1 to +1 (noise at 60 runs); Second Broadside +2.9 and Pitch Hand +3.4 sit at the top of their target.
> - **Step 3b:** rival hunters 0.77 a run (was 0.96), alignment hunters 2.80 (was 1.83). Step 3's loyalty table is unchanged.
> - The "Taken in a run" figures had no committed harness; they were measured again with a throwaway one (see there).

The design is in `docs/proposals/profession-clan-mechanics.md`; the words are Narrative's (`docs/proposals/specialisation-texts.md`).
- Each profession's core (`lib/combat/profession_cores.dart`) is bent by its three main clans.
- A clan offers its specialisation as a gift once you are its **Friend** (19+). It comes once, stays for the run, and several stack.
- The rules and numbers are in `lib/combat/specialisations.dart`; the words, profession and clan in `assets/gamedata/specialisations.json`.
- The live fight and the simulator play the same rules.

## The fifteen

| Profession (core) | Clan | Specialisation | What it does |
|---|---|---|---|
| Warrior (Fury) | Crows | **Berserker** | Attack faces are Pain strikes (double, 8% of max health). The life paid adds 1 Fury. |
| | Compact | **Briar Guard** | A blow the block and armour stop adds 1 Fury, and a quarter of what they stopped goes back. You can't dodge. |
| | Dominion | **Lantern Vanguard** | The heavy blow is ×2.85 (Fury's own is ×2.5), Fire, and Pierces. Against an Evil foe (one weak to Light: the void, the dead, demons) it heals a fifth of its damage. |
| Cleric (the Watchfire) | Vigil | **Long Vigil** | Above half health, 5% of max health mended each round. |
| | Penitents | **Ashen Hand** | Whenever the fire burns (a heal's burn or the round's): 1 mana, the burn's amount mended, one affliction lifted. |
| | Dominion | **Beacon** | The fire holds up to your whole max health. Every burn strikes every enemy, in Light, ×1.5. |
| Mage (the Ash Well) | Dominion | **Censer Mage** | Mana past full burns the enemy for 3× your strike per point. |
| | Penitents | **Burden-Bearer** | A spell cast from a full Well hits ×2. |
| | Crows | **Tempest Toll** | Spells heal 6% of their damage, and the Crows offer Teleport Strike. |
| Rogue (Flurry) | Mire | **Fever Blade** | Each critical hit adds the Rot: a poison of 40% of the hit that stacks and lasts the fight. |
| | Crows | **Ledger Knife** | Each hit that isn't critical adds 8 points to the next one's chance. A critical resets it and hits ×1.75 instead of ×1.5. |
| | Penitents | **Relicbreaker** | Each critical hit gives 1 mana. At 3 mana, the next strike is a sure critical and spends it. |
| Ranger (the Trail) | Crows | **Corsair's Eye** | The Verdict (the last face of a run) counts ×1.6 and Pierces. |
| | Compact | **Trapwright** | The Verdict also stuns its target for a turn. |
| | Mire | **Fen Guide** | The first face of each run poisons its target: half the blow, for 3 turns. |

## Measured

- **Setup:** 200 seeded runs per line (seed 11), random strategy, one profession. The specialisation is held from the start and set against the core alone, with the fight-length rules and the Tide on.
- **Command:** `SPECS_RUNS=200 flutter test test/specialisations_test.dart`. `SPECS_ONLY=id,id` limits it to some.
- **Target:** +3 to +6 points of fights won over the core.

| Profession | Specialisation | Won: core → with it | Over the core | Rounds |
|---|---|---|---|---|
| Warrior | Berserker | 50.7% → 55.1% | **+4.4** | 7.3 |
| | Briar Guard | 50.7% → 52.2% | +1.5 | 7.9 |
| | Lantern Vanguard | 50.7% → 52.9% | +2.2 | 8.0 |
| Cleric | Long Vigil | 54.7% → 59.8% | **+5.1** | 11.9 |
| | Ashen Hand | 54.7% → 54.5% | −0.3 | 11.6 |
| | Beacon | 54.7% → 54.8% | +0.1 | 11.5 |
| Mage | Censer Mage | 53.3% → 59.1% | **+5.7** | 6.8 |
| | Burden-Bearer | 53.3% → 55.7% | +2.3 | 6.9 |
| | Tempest Toll | 53.3% → 54.6% | +1.3 | 7.0 |
| Rogue | Fever Blade | 53.0% → 55.3% | +2.3 | 8.5 |
| | Ledger Knife | 53.0% → 56.6% | **+3.7** | 8.4 |
| | Relicbreaker | 53.0% → 55.4% | +2.4 | 8.6 |
| Ranger | Corsair's Eye | 52.2% → 53.7% | +1.5 | 9.8 |
| | Trapwright | 52.2% → 52.6% | +0.4 | 10.2 |
| | Fen Guide | 52.2% → 53.6% | +1.4 | 9.9 |

**How sure:** runs of 40 and 100 put the same line up to 2.5 points apart, so a figure here is ±2.

**In range (+3 to +6):** four specialisations (Berserker, Long Vigil, Censer Mage, Ledger Knife). None is above. Lantern Vanguard, Burden-Bearer, Fever Blade and Relicbreaker (+2.2 to +2.4) sit within the noise of the range's floor.

**Below range, and why:**
- **Ashen Hand** gives the cleric mana, whose pool is mostly full already in the simulator. The mend from the burn is what it measures.
- **Beacon, Briar Guard, Tempest Toll and the ranger's three** read +0 to +2 on v2.10.0, where they read +3.5 to +6.6 before v1.915. Their rules have not changed; the cores they are set against have (see the note at the top). Why each fell is not measured here.
- **Censer Mage**, which read +1.9 for want of overflowing mana, now reads +5.7: the mage's fights changed under it, not its rule. Burden-Bearer still rewards a mage who casts from a full Well, which the autoplay seldom does.

**Taken in a run** (100 runs of the four strategies, offers on):
- The harness that gave the old figures is not in the repository (the doc came in a squashed commit), and its seed is not recorded. On v2.10.0 a throwaway test (`simulatePlaythroughs`, `SimStrategy.values[i % 4]`, random race and profession, counting the ids of `specialisations.json` in each run's `specs`) gave, at seeds 17 and 11:
- 95 and 96 of 100 runs took at least one specialisation (was 95).
- On average a run took 1.4–1.7 (mage) to 1.8–2.1 (rogue); the cleric 1.5–1.6, the ranger 1.5, the warrior 1.9–2.0 (was 1.4, warrior, to 2.6, ranger). About 20 runs a profession, so a figure is ±0.3.
- The boss curve (boss_balance_test) was not re-run here.

## Changes to Narrative's texts

`specialisations.json` was generated from Narrative's doc. Five gifts changed where the rule moved. Narrative may reword them; the figures are Core's.

| Specialisation | Change |
|---|---|
| Corsair's Eye | "the last face of a run": the Trail deals five faces a run, not six |
| Relicbreaker | adds "At 3, your next strike is sure to be critical": a rogue has no spell to spend mana on |
| Ashen Hand | adds "mends you a little" |
| Lantern Vanguard | adds "strikes harder" |
| Beacon | adds "harder" |

## Step 2b: the sub-clans' variants and upgrades, and rank II

- A specialisation held, each of its two sub-clans offers its gift from **Trusted** (rare). A *variant* changes how the specialisation works; an *upgrade* raises its number. The sub-clan voices it.
- At **Sworn** the main clan offers **rank II** (heroic): half again the specialisation's number, or the specific bump below.
- The words are in `assets/gamedata/spec_variants.json` (Narrative's §3 of `specialisation-texts.md`); the numbers in `SpecMods` (`lib/combat/spec_variants.dart`). The live fight and the simulator play the same rules.
- **Measured:** `VARIANTS_RUNS=60 flutter test test/spec_variants_test.dart`, each gift with its specialisation set against the specialisation alone. `VARIANTS_ONLY=id,id` limits it. At 60 runs a line is ±3–4.

| Read | Gifts (over the specialisation alone) |
|---|---|
| In or near +3 to +6 | Relicbreaker II +4.1, Wading Step +3.3, Corsair's Eye II +3.0, Trapwright II +3.0, Bleeding Hull +2.8, Broken Sword, Open Hand +2.8 |
| Small or within the noise | Berserker II +2.2, Fever Blade II +2.2, A Song Sung Over It +2.3, Fen Guide II +2.0, Tapped Sap +1.5, Ledger Knife II +1.5, Twice the Spoil +1.5, Long Vigil II +1.4, Censer Mage II +1.3, Spear at the Wall +1.2, Boarding Heart +1.0, Burden-Bearer II +1.0, Tempest Toll II +1.0, The Accusing Smoke +0.8, Paid in the Deep +0.7, Briar Guard II +0.6, Lantern Vanguard II +0.4, Fallen Knight’s Fire +0.4, Honest Fire +0.3, Keep the Light +0.2, Hand-Signed Wall +0.1, The Name Sung 0.0, Ashen Hand II −0.1, Debt Forgiven −0.1, Name on the List −0.3, Warm Hands −0.3, One Witness, Once −0.5, Counted Breath −1.3, Beacon II −1.3, Take It Down −1.9, Bell-Voiced −1.9 |
| Not seen by fights won | A Letter Opened +0.9, Entered in Full +0.5 (gold), Broadside 0.0 (the ship's guns), Seen From the Other Side +0.6 (two faces ahead), Cut Stone 0.0, Stone Trap +2.0 (guard breaks, rare in the simulator), One More Bed +1.5, One Door +1.5 (the Ash Well already brings most spells to 1 mana): all within the noise |

On v2.10.0 the gifts that read +4 to +7 before v1.915 (Boarding Heart +6.7, Briar Guard II +6.6, Debt Forgiven +6.2, Hand-Signed Wall +5.9, One Witness, Once +5.2, Berserker II +4.7, Counted Breath +3.9) read −1.3 to +2.2. One Witness, Once was +13.2 when it refilled the whole Well from round 2.

**Why so many read small:** the mage's and cleric's gifts build on rules the autoplay seldom reaches (a full Well, an overflow, mana spent), as in 2a. Rank II on a specialisation worth +3 to +5 adds half of that, which is inside the noise at 60 runs; on v2.10.0 most specialisations themselves read under +3 (step 2a), so their gifts have less to add to. None of them makes fights longer. The boss curve (boss_balance_test) was not re-run here.

### Changes to Narrative's texts (2b)

| Gift | Change |
|---|---|
| One Witness, Once (Tribunal) | "Once per fight, from the fourth round, an empty Well refills by a third." (the doc's "refill the Well in full" won +13) |
| Fallen Knight’s Fire (Order) | "heals you more of its damage" |
| One Door (Keyholders) | "Your spells cost 1 less again." (the main Tempest Toll already offers Teleport Strike) |
| The fifteen rank IIs | a generic line, "Rank II: the specialisation grows by half again." Narrative may write each one |

## Step 3: the price of loyalty

**A held specialisation follows its clan's standing** (`specsByStanding`, `lib/combat/specialisations.dart`):
- **Wary or Unfriendly:** it plays as given.
- **Resented or Hostile:** it plays every other round (the odd ones), and its sub-clan gifts and rank II go quiet.
- **Hunted:** it sleeps, gifts and all, until the clan is won back.
- The fight log says so as the fight begins. The simulator plays the same rule.

**Each new chapter, the patron's favour cools its rivals** (`applyLoyaltyDrift`, `lib/data/factions.dart`):
- The patron is the sworn clan, or else the clan stood highest with at Trusted or above.
- **Trusted:** its rivals (relation steps 1–3) lose 2.
- **Sworn:** its rivals lose 4, its tense neighbours (step 4) lose 2, and its allies (steps 6–7) gain 1.
- It comes with the chapter's offer, once a chapter, with no ripple. It is logged as "Loyalty's price · <patron>".
- There is no combat penalty: the cost is the shops, the offers, and the specialisations above.

**What a loyal run's rivals end at** (Trusted in chapter 3, Sworn in chapter 5, eight chapters; `LOYALTY_REPORT=1 flutter test test/loyalty_test.dart`). The drift adds −20 to each rival by the end, on top of the ripple and the swearing's cost. Re-run on v2.10.0: every figure is the same.

| Patron | Hunted by the end | The others |
|---|---|---|
| Dominion | Vigil −80, Mire −80, Penitents −80 | Compact −8 (Wary), Crows +24 (Friend) |
| Penitents | Dominion −85, Compact −75, Mire −75 | Vigil +22, Crows 0 |
| Vigil | Dominion −85, Crows −75 | Compact +22, Penitents +22, Mire 0 |
| Mire | Dominion −85, Penitents −75 | Compact +22, Vigil 0, Crows 0 |
| Compact | Penitents −75 | Dominion −18 (Unfriendly), Vigil +22, Mire +22, Crows 0 |
| Crows | Vigil −75 | Dominion +12, Compact 0, Mire 0, Penitents 0 |

The relations map makes the patron a choice of enemies too: a Dominion loyalist closes three clans, a Crows loyalist one.

## Step 3c: the weak links' gifts

A clan only weakly tied to a profession (● in the proposal's affinity table) offers one smaller twist:
- from **Friend**, like a main specialisation;
- **half as often** (the gift kind's weight halved when it is all a clan has);
- **rare**;
- with no sub-clan gifts and no rank II.

The words are Narrative's (`docs/proposals/specialisation-texts-2.md` §1). The rules are in `lib/combat/specialisations.dart`, and the live fight and the simulator play them alike.

| Gift | Clan, profession | Rule | Won over the core (60 runs) |
|---|---|---|---|
| Standfast | Vigil, warrior | A Defend face adds 1 Fury | −1.1 (was +2.3) |
| Burning Penance | Penitents, warrior | A Mana face adds 1 Fury | +0.5 (was 0: the autoplay's warrior die has no Mana face) |
| Brimming Draught | Mire, cleric | A potion's healing past full feeds the Watchfire | +1.1 (was 0: the autoplay drinks below 40% health) |
| Double Kindling | Compact, mage | A Fire spell's reaction counts twice | −0.7 (was 0: the autoplay's spells seldom meet another element) |
| Lingering Hex | Mire, mage | A spell's status lasts 1 turn more | +0.4 (was 0: the autoplay seldom casts a status spell) |
| Stitch-Thrust | Vigil, rogue | Healing past full strikes the first foe for as much | +0.6 (was −1.0; noise: a rogue seldom heals past full) |
| Pitch Hand | Compact, rogue | Flurry's second hit slows its target (Weaken 15%, 1 turn) | +3.4 (was +1.6; +6.4 with the Vanguard's 25%, 2-turn Weaken, so lightened) |
| Second Broadside | Dominion, ranger | Once a fight, a drawn face that would not strike goes back, and the Trail draws again | +2.9 (was +1.7) |

Measured on v2.10.0 with `SPECS_RUNS=60 SPECS_ONLY=<the eight ids> flutter test test/specialisations_test.dart` (seed 11, random strategy); at 60 runs a line is ±3–4.

**Target:** about half a main specialisation (+1 to +3). The four that read 0 before now read −0.7 to +1.1, which is the noise at 60 runs, not a sign they fire. They are real for a player who builds for them: a warrior with a Mana die, a cleric drinking at full, a mage mixing elements or casting hexes.

**Changed from Narrative's text:** Second Broadside plays itself, with no button: "Once a fight, a face that would not strike goes back to the bottom of the run, and you draw again."

## Step 3b: the rivals' hunters

Sworn to a clan, its rivals may send hunters onto the roads (`lib/data/rival_hunters.dart`):
- **4%** a road at rest for each rival you stand Hostile with, **8%** for each that hunts you, up to **15%** (the alignment hunters' cap).
- They share the alignment hunters' cooldown (5 roads) and their settings toggle, so a road holds one ambush at most.
- **The fighters:** each clan has a line fighter (tier 1, from chapter 2) and a captain (tier 2, from chapter 3), in `enemies.json` (`hunterClan`, `hunterTier`).
  - **Vigil, Compact, Mire:** Narrative's six (`docs/proposals/rival-hunters.md`), with their battle cries. They are hunters only (`hunterOnly`), never an ordinary draw.
  - **Dominion, Crows, Penitents:** fighters already on the roads (the Inquisition Soldier and High Warden; the Smuggler Captain and Brine Jack; the Masked and Inquisition Penitents). They have no cry yet, so they use a generic line.
- **The ambush:** "{name} bars the road. {cry}", with the reason "{clan}: your oath to {sworn} is not forgiven." Narrative may reword it (the words are in `rival_hunters.dart`).
- **In the simulator** (`RIVALS_RUNS=100 flutter test test/rival_hunters_test.dart`, four strategies, seed 17): 0.77 rival hunters a run, in 52 of 100 runs, beside 2.80 alignment hunters a run (v2.10.0; was 0.96 in 55 runs, beside 1.83).
- **Not in this step:** sparing or talking a hunter down (Narrative's suggestion for the Vigil and Compact hunters). They fight.

## Not yet

- Sparing or talking down a rival's hunter (Narrative's suggestion for the Vigil and Compact hunters).
