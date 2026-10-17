# Clan power that moves: story choices and upheavals (Narrative, wave 15)

Two of the three options the user picked: **(a)** story choices that raise or lower a clan's power, and **(c)** upheaval events in chapters 5 and 7. The third (bigger war swings) is numbers only and Core's. This is a proposal: no data changes yet.

## What exists

- A choice's `politics` block already accepts `power` (`{"power": {"crows": 5}}`) and `control` (`{"control": {"<place>": "<clan>"}}`); `story_politics.dart` reads both. **No scene uses them yet**, so every number below is new use of an existing field.
- Politics events take `effects.power`, `effects.control` and a `trigger.power` condition (`{"faction": "dominion", "minPower": 50}`).
- `standing` is how a clan sees the player; `power` is how strong it is. The rule I follow: **a choice moves power when it changes what the clan can do in the world** (a ship lost or saved, a vote carried, a person given up, a hammer returned), not when it only pleases or annoys.
- Sizes use the scale in `clan_power.dart` (a gift +2, a quest +5, a fight at a seat 5 to 10). I keep choice swings at **3 to 8**. Core owns the final numbers; these are my suggestion.

## (a) Candidate choices, 15

All are existing scenes; I would add `power` next to the `standing` they already carry. "Dir." is the direction for the named clan.

| # | Scene (choice) | Clan | Dir. | Size | Why it moves the clan |
|---|---|---|---|---|---|
| 1 | `2015_house_keyholders` (Sell the key to an Inquisition patrol) | Crows | down | 4 | A Keyholder is delivered to the patrol |
| 2 | `2015_house_keyholders` (same choice) | Dominion | up | 3 | The Inquisition gets a key and a name |
| 3 | `3005_clan_vigil_1` / `_breach` (hold the rubble, hunt it through the ash) | Vigil | up | 3 | The wall holds one more night |
| 4 | `3005_wall_fight` (Return to the outer district) | Dominion | down | 4 | A wall breached in front of the city |
| 5 | `4999_standard` (Cut it free while he lives) | Dominion | down | 6 | The Lantern-Bearer's standard is taken from him |
| 6 | `5004_altar` (Wake them first) | Penitents | up | 4 | The Court dies as itself: a people the clan can claim |
| 7 | `5100_vote` (Row the vote out, seal unbroken) | Dominion | up | 6 | The Tribunal's vote reaches the envoy |
| 8 | `5100_vote` (Refuse: the Tribunal hanged four hundred) | Compact / Penitents | up | 3 each | They stand against the Tribunal; Dominion down 4 |
| 9 | `5100_clan_crows_1` (Bribe her purser / Outsail her) | Crows | up | 4 | A cargo gets through |
| 10 | `6010_clan_dominion_2` (Tell the truth: he was fighting it) | Vigil | up | 4 | A Vigil spear is cleared before witnesses; Dominion down 3 |
| 11 | `6010_clan_compact_3_hammer` (Give it back: let the Row stand with you) | Compact | up | 8 | The master hammer returns; the Row has a head again |
| 12 | `6100_clan_mire_2_found` (Hold the doorway) | Mire | up | 5 | The fen keeps the child; Dominion down 2 |
| 13 | `6100_clan_mire_2_found` (Step out of the doorway) | Mire | down | 6 | The Courts lose a child and the road |
| 14 | `6100_clan_penitents_2` (Break it here, with the bell for a witness) | Penitents | up | 5 | One relic unmade for good |
| 15 | `6100_debt_rising` (Warn the Keyholders) / (carry their list) | Crows | up 3 / down 4 | | Keyholders saved or named |

Notes:
- Items 2, 8, 10, 12 name a **second clan** that moves the other way; that is deliberate, so power stays a zero-sum feel rather than inflating.
- Rows 5, 7, 11, 13 are the four I would call the **loud ones**: the player should see the news line afterwards (a `news` text in the same words as the clan cards use). I would write that line for each (EN/FR) in the same PR as the data.
- Three of the 15 sit in chapters 1 to 3 on purpose, so the map starts moving before chapter 5.
- Nothing here needs new flags. Where a later scene should react (the Compact hammer, the Mire child) the existing flags `clan_compact_step_3`, `mire_child_given` already say what happened.

## (c) Two upheaval events

Both are politics events (the same shape as `the_throne_filled`): a `trigger`, `once`, `variants` by flag, `effects.power` / `control`, and a news text (EN/FR).

### Chapter 5, "The Wrack's End vote": Dominion against the Row

**Trigger:** the chapter 5 turn, after `vote_carried` or `vote_refused` is set (the choice in `5100_vote`).

**Scene:** a short news piece plus one scene at the Wrack's End quay (new node, `5100_vote_after`) where the result lands: the envoy's cutter back, or the empty seal.

| Variant (flags) | Outcome |
|---|---|
| `vote_carried` | The Tribunal's writ is read in Candlehold. **Dominion +8**, Compact -4. The Row's forge-charter lapses; the Compact loses a forge place (`control` of one Compact-held forge place to Dominion, Core picks the place). News: *the Hammer's Row was told to hand over its charter.* |
| `vote_carried` + `vote_read` | As above, but the Crows sold the contents first: Crows +4. News names the leak, not the player. |
| `vote_refused` | The writ fails. **Dominion -8**, Compact +4, Penitents +4. The Dominion's weakest place on that coast goes to the Compact (`control`, Core picks). News: *four hundred names were read at the Row's door.* |

Why chapter 5: it is the first chapter where the player does something the clans can see and answer. Why this one: it already has a clean binary (`vote_carried` / `vote_refused`) and three clans' standing attached.

### Chapter 7, "The Conclave counts": the Lantern Throne

**Trigger:** chapter 7 reached, before the throne scenes (`7510_*`). Power-gated: it fires at full size only if the strongest clan is **Dominant or Ascendant** (`trigger.power`, `minPower` 50); below that it fires small (half).

**Scene:** the Conclave counts votes and the gate it chose to open sets who holds the Hall. The player's chosen way up the cliff (`way_quiet`, `way_force`, `way_friends`; the clan arrivals `7510_vigil` … `7510_penitents`) decides the swing.

| Variant (flags) | Outcome |
|---|---|
| `way_quiet` (speak before the Houses) | Dominion +5, no place moves. The Houses are persuaded, not beaten. |
| `way_force` (take the stair) | Dominion -8; the clan behind the gate the player used (Vigil, Compact, Mire, Crows or Penitents) **+8** and takes **Candlehold's Lantern Hall** (`control` of `candlehold_lantern_hall`; this is the big map change of the run). |
| `way_friends` (the Wickwardens light the way) | Dominion +3, Vigil +3: a modest rise for the lamps. |

The result then feeds the existing `throne_winner_*` flags in chapter 7's end: a clan that took the Hall in this event is the natural first claimant at `7590_*`; nothing in `7590_*` text changes.

Why chapter 7: it is where power matters most (`throne.dart` already uses power to break the tie), so a swing here should be felt in the ending.

## What I need from Core

1. Confirm the choice sizes (3 to 8) and that a choice may carry `power` and `control` without a new field.
2. The place ids for the three `control` moves (Compact forge, Dominion's weakest place on that coast, `candlehold_lantern_hall` is already in geography.json).
3. That `trigger.power` is usable on a chapter-7 event with a half-size fallback, or else I split it into two events.
4. Whether the simulator can print each clan's power per chapter before and after, so I can check the swings are felt without collapsing a clan (Core's note aims at 2 to 6 place changes a run).

## What I would write after the answer

The `power` blocks on the 15 choices; the two events (with their news lines, EN/FR); one new scene `5100_vote_after`; and a one-line news text for each of the four loud choices. French follows the usual rules.
