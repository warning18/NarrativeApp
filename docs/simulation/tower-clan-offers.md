# Tower: clan offers, then the oath (plan, Core, no build)

The user's ask: "In the tower use the clan skill proposition as in the story but keep the oath once the user reached a certain level with a clan."
This plan replaces the bare oath card (`towerOfferFor`, `TowerRewardKind.clanOath`, `towerOathChance`) with the story's three-suitor offer (`offers.dart`: `ClanOffer`, `Suitor`, `OfferGift`). Each gift taken raises standing with its clan for the rest of the run, and the oath comes only once standing reaches 6.
UX's pictures (branch `claude/ux-2-tower-clans`, `docs/ux-shots/tower-clans/`) fit the plan, with four changes listed in §7.
All numbers come from the live bot, measured on main at v2.2.0 (see §6).

## 1. The rules

| | Proposal |
|---|---|
| **Clans that can come** | The run's pool (`TowerRun.clanPool`, from `TowerProgress.clans`) out of the six in `towerClans`: `dominion`, `vigil`, `compact`, `mire`, `crows`, `penitents`. The start pool is `dominion`, `mire` and `penitents`. Ash Marks unlock `crows` (10), then `vigil` (20), then `compact` (30). **Narrative:** every one of these six needs its toast, banner and oath line. The draft on `claude/narrative-drafts` has only three of them (crows, vigil, compact). |
| **When** | On the floors where today's oath can come, and only those: the first floor won always, then `towerOathChance` (0.35) of the other non-boon floors, on today's oath stream. Boon floors keep their skill, die and spell cards. |
| **The cards** | Up to 3 suitors from different clans of the pool, drawn on the offer stream, one gift each. As in the story you take one: Accept on the card in hand, or Not now. |
| **What a gift is** | A **skill**. It is the clan's next skill on a branch it sponsors for the hero's calling or race (`faction.sponsors` × `skillBranchesFor`). Branches open in order, and the depth follows the run's standing: steps 0–1 open the first skill, 2–3 the second, 4–5 the third and 6 the fourth (the story's `_skillIndexCapFor`). A clan with no such branch left teaches a skill from the Tower's pool at the floor's rarity (`towerRarityStep`). That happened for **55–59 %** of gifts: each calling has 3 branches, each sponsored by a single clan. |
| **Refuse for a mark** | Kept. Not now on every card gives +1 mark (`towerMarksPerRefusal`) and moves no standing, as today's refusal does. |
| **What moves standing** | Only a gift taken. Fights, floors and events do not move it (see §7). The gift's clan gets **+2**. Its allies (relations.json step ≥ 6) get **+1**, and its rivals (step ≤ 3) get **−1**. This is the story's ripple: +6, +¼ and −½ there, scaled to whole steps here. Standing is clamped to 0..6. It belongs to the run and starts at 0. |
| **The oath** | When a clan reaches **6**, its oath card is dealt on the next non-boon floor won: alone, or beside that floor's clan cards. The oath is a card of its own, so it is a **fourth card** and replaces none of the three. Swear or Not now. A clan's oath declined comes back on each later non-boon floor until it is sworn. |
| **What the oath gives** | Today's oath, unchanged: the clan's die (`dice.json` `clan`, one per clan, never given as a gift), the clan held at Friend in fights (`towerPoliticsOf`), the main clan's die resonating, a free pass at the parley of its guardian, and half price at its merchant. Several oaths are allowed and the first is the main one, as today. UX drew "one oath a run"; the user decides (§8). Swearing also opens the clan's 4th branch skill (step 6). |

Pairs among the six (relations.json): allies are dominion–crows, vigil–compact, vigil–penitents and compact–mire. Rivals are dominion–vigil, dominion–mire, dominion–penitents, vigil–crows, compact–penitents and mire–penitents.
**The three start clans are rivals of each other.** With no unlocks, a gift to one costs the other two a step each, so only one oath per run is realistic (0 % of runs swore twice).

## 2. Story gift kinds that carry over

| Story gift (`GiftKind`) | Tower |
|---|---|
| skill (sponsored branch) | **yes**: the gift |
| die (the clan's own) | **yes, through the oath only**: one die per clan, kept for the oath |
| sign, title, object, perk (Wayfarer), spec, Sworn boon | **no**: the Tower plays none of them. Gear comes from the spoils, and v1.867 removed item cards. No Wayfarer card. |
| spell | the story has no spell gift. Spells stay boon cards. |
| fusion, ascension, risky gift, Star Well raise, "Your own hand" | **no** (later, if wanted) |

## 3. With briefs 2 and 3 (v2.4.0, PR #1134, not on main yet)

- On the **boon floors** `{5,10,13,15,20,23,25,28}`: the boon, no clan cards, and no oath dealt there. The oath waits for the next floor that is not a boon floor.
- **A clan skill that would sit on no face becomes a rank-up**: the same `towerRankUpFor` that brief 2 adds for boon skill cards. The card keeps its clan and its standing gain ("Rank up · +2 Crows").
- More boon floors leave fewer non-boon floors: about 0.35 × 21 ≈ 7.4 clan offers a run instead of ≈ 8.1. The measurements below were taken **without** PR #1134 and must be re-run once it merges.

## 4. Save and Ash Marks

- **Save**: `TowerReward` gains an optional `clan` field (json `'clan'`, written only when set) for a clan gift. Standing is **not stored**: it is replayed from `TowerRun.taken`, the same way `towerHeroOf` rebuilds the hero. No new field goes on `TowerRun`.
  - An old run halfway up has skill cards with no clan, so its standing reads 0 everywhere. Its sworn oaths stay sworn (`clanIds` reads the `clanOath` cards as today). An oath card already on the table stays and can still be taken.
  - Old saves need no migration.
- **Ash Marks**: no change in price or payout. A `TowerUnlockKind.clan` unlock now means "this clan can come to you". Unlocking clans spreads the gifts over six clans and **delays the first oath** (median floor 8 with no unlocks, 12 with all). The player may not expect that (§8).

## 5. Data for UX

- **Offer card** `TowerClanCard`: `clanId`, `subclanId` (`''` for the Tower), `kind` (`skill` \| `rankUp` \| `oath`), `id` (skill id, or the clan for an oath), `rarity` (`SignRarity` scale), `fromBranch` (bool: false for a pool skill), `standing: Map<clanId,int>` (the ripple preview, e.g. `{crows:+2, dominion:+1, vigil:-1}`), `standingBefore` (0..6), `dieId` (oath only).
- **Per-clan standing** `towerStandingOf(run) → Map<clanId,int>` over the pool, with `towerOathStep = 6` and `towerOathDue(run) → List<clanId>` (clans at 6 not yet sworn).
- **Toast**: it fires when the cards close (`towerPick` with a clan card), not after the fight. It names each clan whose step changed (`before → after`). The ally and rival steps go in one line, or are left out (UX's call). A clan reaching 6 gets the banner instead of the toast, before the next cards.

## 6. Measured (live bot, 2,000 seeds, floor events v2)

**Method.** Two temporary hooks in `towerAfterFight` and in the shortcut landing replaced the offer with the proposed one. The bot's policy: swear any oath on the table, otherwise take the gift of the clan it already stands best with. The hooks were reverted before the commit.
**Sensitivity** variants: the bot picks a card at random, and the oath at 4 instead of 6.

**How many runs have reached the oath step with at least one clan, by floor.** The first figure counts all runs. The figure after the slash counts only the runs still climbing at that floor.

| Rule, unlocks | by 5 | 10 | 15 | 20 | 25 | 30 | first oath, median floor |
|---|---|---|---|---|---|---|---|
| **Proposal (6), none** | 25 % / 25 | 70 / 73 | 84 / 92 | 87 / 98 | 88 / 99 | 88 / 100 | 8 |
| **Proposal (6), all** | 8 / 8 | 40 / 41 | 66 / 70 | 78 / 88 | 82 / 95 | 84 / 98 | 12 |
| random picks (6), none | 3 / 3 | 14 / 15 | 23 / 27 | 30 / 41 | 34 / 50 | 37 / 61 | 14 |
| random picks (6), all | 1 / 1 | 9 / 10 | 22 / 25 | 34 / 42 | 44 / 60 | 49 / 72 | 17 |
| oath at 4, none | 69 / 69 | 92 / 94 | 96 / 99 | 96 / 100 | 96 / 100 | 96 / 100 | 4 |
| oath at 4, all | 45 / 45 | 80 / 81 | 92 / 94 | 95 / 98 | 96 / 100 | 96 / 100 | 7 |
| today (oath on floor 1) | 100 at floor 1 | | | | | | 1 |

**Win rates.**

| Unlocks | Top today → proposal | Median floor | Floor 20 | 2+ oaths | Gifts a run |
|---|---|---|---|---|---|
| none | **14.5 % → 17.8 %** | 19 → 20 | 48.2 → 51.1 % | 96 → 0 % | 5.4 |
| all | **26.8 % → 31.9 %** | 22 → 25 | 63.4 → 67.8 % | 98 → 56 % | 6.1 |

**What the win rates show.**
- The run gets **stronger, not weaker**, even though the oath comes later. The 5–6 extra skills outweigh it.
- The oath's timing barely matters: random picks reach the oath in only 37 % of runs and still win the top 18.1 % (none) and 30.0 % (all).
- Per calling, with no unlocks: mage 14 → 16 %, rogue 15 → 18 %, warrior 14 → 20 %. With all unlocks the cleric moves 13 → 19 %.
- Both results stay inside QA's guard bands (top 7–20 % with no unlocks, 23–37 % with all). They sit at the high end, and above brief 1's target (5–12 % and 15–25 %).

**Not measured.**
- PR #1134 (rank-up, boon floors, the climb ×1.08 and ×1.06): not on main.
- A player's real choices, and refusing for marks. The bot never refuses.
- The value of standing alone in fights. Standing here does nothing until the oath.
- "One oath a run".
- The screens.

## 7. Where the plan departs from UX's pictures

- The card reads **"+2 Crows"**, not "+6": the bar has 6 steps and a gift is worth 2. The ripple line ("Crows +2 · Dominion +1 · Vigil −1") follows the real relations; UX's samples were made up.
- The gifts are **skills** (the clan's branch, or the pool's), not perks like "Open Door". The Tower has no perk system.
- The toast comes **after the cards**, not after the fight. Nothing in a fight moves standing. A fight could if the user wants, for example +1 for beating a clan's rival (§8).
- The oath is a **fourth card** with its banner first, matching picture c. A floor that deals no clan offer deals the oath alone.

## 8. Risks and decisions left to the user

1. **Oath step 6 (recommended) or 4.** At 6 the oath is earned around floor 8 to 12, and about 9 runs in 10 that reach floor 20 have it. At 4 it is almost automatic by floor 5, close to today's.
2. **Balance.** The extra skills raise the top by 3 to 5 points. To compensate, either deal clan offers on fewer floors (0.25) or give back brief 1's climb scale. Re-measure after PR #1134 in either case.
3. **Unlocking clans delays the oath.** Option: draw suitors weighted toward the clans you stand best with, as the story does (`_standingWeightFor`).
4. **Several oaths (today's rule) or one a run (UX's picture).** With no unlocks, the rival triangle already allows only one.
5. **Whether fights or the clan events move standing**, for example +1 for buying from a clan's merchant or winning its guardian's parley.
6. Over half the gifts are pool skills dressed as a clan's, because the hero's calling has no branch sponsored by that clan. The alternative is to deal only clans with a branch for the hero, which means fewer suitors.
