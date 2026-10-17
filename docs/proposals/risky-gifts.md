# Risky gifts (Core, proposal, wave 15)

Design only: nothing here is in the game yet.

What the user decided:
- Only a clan the player is **uneasy** with, or whose **alignment is opposite** the player's, can offer a risky gift. Hostile and nemesis clans never do.
- A risky gift is a **perk the player unlocks**. It is off by default.
- Once unlocked, the risky gift is **one rarity better** than its roll.
- **The die decides**: the gift, a malus (a stat curse), or a gold or health penalty. "Nothing" is never a result.

## 1. What it is

Some clans don't trust you, or don't share your beliefs. Once you have built a parley tent at camp, they may still send someone with a better gift than they would normally give: one rarity higher. But they set a condition. Take it, and the die decides. Most of the time you get the gift. Otherwise you lose some health or gold, or the clan leaves you cursed for a while.

## 2. Who can offer one

There is no "uneasy" tier in `StandingTier` (`lib/data/factions.dart`). I map it to the three tiers between Unknown and Hostile:

| Tier | Standing |
|---|---|
| Wary | −11 to −6 |
| Unfriendly | −18 to −12 |
| Resented | −25 to −19 |

**The rule.** A suitor's card may be risky when all of these hold:
- the clan is already a suitor in the offer (`suitorOpen`, which keeps Hostile and Hunted out today);
- its tier is Resented, Unfriendly or Wary, **or** its alignment is opposite the player's;
- it is not the nemesis (`politics.nemesis`). A nemesis stays one until it climbs back to Wary (`nemesisEnds`), so this has to be checked separately;
- it is not the Wayfarer, the ticket's forced faction (a quest's suitor is already one rarity better), or the home seat (`drawHomeSuitor`: growth never depends on luck).

**Opposite alignment**, from the data:
- A clan's alignment is its `lean` in `factions.json` (−1, 0 or +1).
- The player's alignment is `alignmentLabel`: Good at `alignmentScore` ≥ 20, Evil at ≤ −20, Neutral otherwise.
- Opposite means a lean +1 clan and an Evil player, or a lean −1 clan and a Good player. A Neutral player or a lean 0 clan is never opposite.
- In practice the lean +1 clans are the Grey Vigil, the Ashen Penitents and the Open Hand, and the only lean −1 clan is the Salt Crows. The Choir and the Pit can never qualify: their `minAlignment` 10 and `maxAlignment` −10 already shut them out for an opposite player.

Examples:
- An Evil character who stands Friend with the Vigil: risky (opposite alignment).
- A Neutral character at Wary with the Compact: risky (uneasy).
- A Good character at Known with the Crows: risky (opposite alignment).
- The Dominion at Hostile (−30): never a suitor. As the nemesis at −20: never risky.

**How often.** When the offer is drawn (`drawOffer`), if at least one suitor qualifies, there is a **30%** chance (`riskyGiftChance`) that one of them is picked at random and its card becomes risky. It replaces that suitor's normal gift. An offer never has more than one risky card.

Why 30%: a run sees about 34 offers (`report-100-runs.md`). Uneasy clans rarely get a seat (`standingWeightFor` favours friends), so I expect a qualifying suitor in about half of the offers. That gives about one risky card every 6 or 7 offers, or **4 to 6 per run** once the tent is up. That is enough to matter without crowding out the clans you are courting. The simulator will report the real count, and I'll tune the 30% to it.

**The gift.** A risky gift is drawn exactly like a quest's suitor: `drawSuitor(id, c, random, better: true)`. That gives one rarity better through `_better`, and for skills, one skill deeper on the branch than the standing allows (`skillIndexCapFor` + 1). The sign power cap (`maxSignRarityFor`) still applies.

**Already at the top.** If the better draw comes out no rarer than a normal draw (a Heroic sign, a Heroic spec rank, a capped sign, or the Sworn boon), the card stays normal. A risky card always shows a real step up.

## 3. The unlock

**Recommended: a camp building, the Parley Tent** (`parley_tent` in `houses.json`).
- Category `workshops`.
- Costs 250 gold, 2 `material_timber` and 2 `material_cut_stone`, in line with the other workshops (230 to 270).
- No `requiredFlags`.
- The perk is on once `builtHouseIds` contains `parley_tent`. No new unlock state is needed.

Why this one:
- The player chooses it and pays for it, so it reads as "I opened my camp to dangerous company".
- It is visible in the cliff town.
- Gold is plentiful (a median run ends with about 4 000 unspent), so the gold cost is fair.
- Narrative writes its name and description, and UX draws its town footprint (`cliff_town.dart`).

Alternatives:
- **A title**, "Go-Between", held while two clans stand at Wary or worse (a `while:` source). Rejected: you can wear only one title (`activeTitleId`), so the perk would fight the other titles.
- **A Wayfarer perk rank** in `perks.dart` (`Perk.longOdds`, max rank 1). Rejected: the Wayfarer comes at 20% (`wayfarerChance`), so the player can't work toward it.

## 4. The roll

**A d20 plus a Luck bonus.** The bonus is +1 at Luck 5 and +2 at Luck 10 or more: `min(2, luck ~/ 5)`. A **natural 1 is always the health penalty**, as a natural 1 always fails a check (`checkPasses`).

| d20 + Luck bonus | Result | Odds at Luck 0–4 | at Luck 5–9 | at Luck 10+ |
|---|---|---|---|---|
| natural 1, or 2 | Health penalty | 10% | 5% | 5% |
| 3–4 | Gold penalty | 10% | 10% | 5% |
| 5 | Malus | 5% | 5% | 5% |
| 6+ | **The gift** | **75%** | **80%** | **85%** |

**The die is rolled when the offer is drawn**, not when you accept. The roll is saved with the card, so reopening or reloading never rerolls it. Luck is read at accept time.

**Health penalty.** Lose 40% of max health from current health, never below 1. A rest heals it as usual. At the ÷5 scale, a level 5 character with about 30 health loses 12.

**Gold penalty.** Lose 25% of the purse, but at least 10 × chapter, and never more than the purse. Retreat costs 20% (`retreatGoldShare`), so this is a little harsher.

**Malus.** −2 to the clan's stat, for **two levels**.
- Each clan's stat is a new field in `factions.json`, `riskStat`. Where a clan has a `while:resented` mark title, its stat follows that title:
  - Dominion: charisma
  - Vigil: perception
  - Compact: strength
  - Mire: wisdom
  - Crows: luck
  - Penitents: wisdom
  - Giants: strength
  - Oni: perception
  - Tide-Kin: dexterity
  - Kindly Ones: luck
  - Open Hand: wisdom
- Never the character's damage stat or Constitution, which would cut damage or health at this scale. If the clan's stat is one of those, the malus falls on Luck instead.
- −2 is about two Common picks.
- It is written in the stat ledger, so the stat breakdown shows it.
- It ends at the second level-up after it is taken.
- A second malus from the same clan restarts the count instead of stacking.

**Nothing never happens.** If the gold penalty would take 0 gold (an empty purse), it becomes the health penalty. If the health penalty would take nothing (already at 1 health), it becomes the malus.

**Standing.** Whatever the die says, accepting works as it does today: +6 standing with that clan (+10 for a major ticket) with the ripple, and the `lean` nudge. You sat at their table. This also makes a risky gift a way to mend an uneasy clan.

**Is it worth it?** Value each rarity by its sign multiplier (1.0 / 1.5 / 2.0 / 2.5):
- A Common gift made Rare is worth 0.75 × 1.5 = **1.13** at Luck 0, and 1.28 at Luck 10, against 1.0 for the safe card.
- Higher up it is roughly even (Rare to Epic: 1.0).
- The real edge is reach. A Wary clan normally offers only the first skill of a branch, and the risky card offers the second.
- The losses are short-lived: health comes back at rest, gold is plentiful, and the malus lasts two levels.
- So the risky card is a good bet that sometimes stings, and the player can always take one of the other two cards instead.

## 5. What the player sees

- **The card**: the gift at its better rarity, a "Risky" mark, and one line: "Their price: let the die decide." The odds are shown ("3 in 4"). UX draws the mark in `offer_dialog.dart` and the reward card.
- **On accept**: a d20 roll (UX, reusing the check die), then one line for the result:
  - Gift: "The die is kind. {clan} keeps its word."
  - Health: "The price is paid in blood: −{n} health."
  - Gold: "The price is paid in coin: −{n} gold."
  - Malus: "{clan}'s curse: −{n} {stat} for two levels."
- **Character screen**: the malus shows in the stat breakdown as a "Curse" row, with the levels left.
- **Strings** (EN and FR drafted in the code PR, then polished by Narrative), added next to the offer strings in `app_strings.dart`: `offer_risky_badge`, `offer_risky_hint`, `offer_risky_odds`, `offer_risky_gift`, `offer_risky_health`, `offer_risky_gold`, `offer_risky_curse`, `ledger_curse`.
- **Narrative**: the Parley Tent's name and description.

## 6. Save fields

- `Suitor` in `offers.dart` gets `risky` (bool) and `riskRoll` (int, 1–20), saved in `clanOffer` as `risky` and `riskRoll`. An old save has neither, so the card is normal.
- `PlayerSession` gets `riskCurses`, a list of `{clan, stat, amount, untilLevel}`. It is left out of the save when empty, so an old save starts with no curses.
- A new ledger kind in `stat_ledger.dart`, `ledgerCurse = 'curse'`, is added to `ledgerKinds`. The malus is written with `withSourcedGains(ledgerCurse, clanId, {stat: -2})`. When it ends, the same call with +2 cancels it, and `ledgerWith` drops the empty row.
- The unlock is the existing `builtHouseIds`. `saveVersion` doesn't change.

## 7. Simulator and tests

**Simulator and autoplay**:
- Build the tent with the other workshops (`sim_houses_test`).
- In `preferredSuitor`, take a risky card only when its gift would win at its *normal* rarity, and the character is above half health. Otherwise score it as usual minus 5. That keeps the simulator from chasing risk.
- The sim JSON counts risky cards seen and taken, and the outcomes (`riskyOutcomes`).
- I'll compare the 400-run win rate before and after. It should move by less than a point.

**Tests**:
- `offers_test`:
  - Wary, Unfriendly and Resented clans qualify; Hostile, Hunted and the nemesis never do.
  - Opposite alignment qualifies, Neutral never does.
  - There is never more than one risky card in an offer.
  - Never the Wayfarer, the forced faction or the home seat.
  - Never when the better draw is no rarer.
  - The bands and the Luck bonus give the odds above (natural 1 is always the health penalty).
- `offers_session_test`:
  - Each result is applied.
  - The fallbacks: an empty purse goes to health, 1 health goes to the malus.
  - Standing rises in every case.
  - The malus ends after two levels, and a second one restarts the count.
  - Saves round-trip, and an old save loads with the defaults.
- `stat_breakdown` test: the Curse row.
- `offer_dialog_test`: the risky card and the reveal (UX).

## 8. Open questions for the user

1. **Show the odds on the card?** Recommended: yes ("3 in 4"). A gamble you can read is a choice; a hidden one feels unfair.
2. **Can a malus be lifted early?** Recommended: not in v1, since two levels is short. A later option is raising that clan back to Unknown.
3. **Should a lost roll still raise standing?** Recommended: yes. It makes the risky gift a way back to an uneasy clan, and the losses stay small.
