# Clan dice as gifts (proposal)

The user's decision: a clan-marked die is a clan's **gift**. This note says which clan gives which die, when, what the mark does, where the data lives, how it shows, and what it does to balance. The user decides from it. Docs only, no version.

## 1. One die per main clan

Each die follows its clan's identity (what it `stands_for` in factions.json) and the stats its patron grants (patron_stats.dart). Faces are counted like today's shop dice of the same tier (about 100 to 150 gold of value). Three reuse a die that already exists.

| Clan | Die | Faces | Leans on | Note |
|---|---|---|---|---|
| Lantern Dominion ("law, one flame") | **Lantern die**, d6 | Light attacks, one Heavy Blow, one Defend | Strength, Charisma | new |
| Grey Vigil ("the long watch") | **Vigil die**, d8 | Light, Defend 3, Heal 5, Second Chance | Constitution, Perception | **reuses `vigil_die`** (today a 250-gold shop die) |
| Cinder Compact ("craft, restraint") | **Cinder die**, d6 | Fire attacks, a `steady` Defend, one forge face (Tempered) | Constitution, Strength | new |
| Mire Courts ("secrets kept") | **Court die**, d8 | Dexterity attacks, Poison, one free-reroll face | Dexterity, Luck | new |
| Salt Crows ("coin, the long game") | **Ledger die**, d12 | even Strike/Guard/Mend, one face paying 2 gold on a hit | Strength, Dexterity | **reuses `tally_die`** (today a quest reward; the quest keeps it) |
| Ashen Penitents ("burdens carried") | **Ash die**, d10 | Earth, heavier faces that cost 1 health | Wisdom, Intelligence | **reuses `ossuary_die`** (today a 220-gold shop die) |

Lost clans and the otherworld (the Choir, the Pit) give none.

## 2. When it comes: on the banner card, at Friend, once

- The die comes **through the banner offer** (the clan offer card), not as a separate gift. Specialisations already work this way (GiftKind `spec`: from Friend, once).
- A new gift kind, `die`: a clan standing **Friend or better** may put its die on its card, **once per game**. It takes the place a skill or object would have had, at the card's rarity rules. Two dice at most in a chapter, so a lucky draw doesn't flood the bag.
- Why Friend: it is a mid-game reward (usually chapter 3 or 4), after the first banner and the clan's first quest step. It isn't something you buy, which is what makes it a gift.
- A die in the shop that is also a clan's gift (`vigil_die`, `ossuary_die`) leaves the shop.

## 3. The mark: a style, and one small rule

I'd use **style plus one small rule**, so that the gift stays worth having later:

- **Style:** the die is drawn with its clan's colours and sign (UX).
- **Rule, "Resonance":** while the die's clan is your **main clan** (sworn, else your patron) **and** you stand Friend or better with it, its faces of value 1 to 3 count **+1**. Below Friend, or once you change main clan, the die still works, but without the +1.
  - It ties the gift to staying loyal, which is the point of a clan.
  - It's easy to read: the mark lights up when resonance holds.
  - +1 on a d6 to d12 die is about +10–20% on that die's numbers, in line with today's tier steps.
- I'd rule out larger effects (an extra face, a clan power): they would overlap the specialisations.

## 4. Data: a `clan` field on the die

- **`dice.json`: `"clan": "<faction id>"`** on each clan die (for example `"clan": "vigil"`). An empty or missing value means no clan. UX reads this field to draw the mark; I'll tell UX the name now so the art can go ahead.
- No other data changes: the gift rule reads `clan` to know which die a clan gives.

## 5. In the dice bag

- Clan dice show with their clan's sign and colours (UX). A short line under the die says "<Clan>'s gift" and either "Resonance: +1 to faces up to 3" or, without it, "Resonance asleep: <reason>".
- Equipping works as for any die. The Resonance state is shown in the fight's die tray (a lit or unlit mark).

## 6. Balance

- **Expected:** one die at Friend, from chapter 3 or 4. With Resonance it is a little stronger than a shop die of the same tier, which is the intended gift edge. The boss curve's late bands (chapters 6–8) should move by 1 to 3 points, inside their bands. The early bands don't move, since a clan die comes after them.
- **Measured when built:** before the build PR, I'll run `boss_balance_test`, `clash_balance_test` and the profession spread on the competent simulator, with and without the dice (no full batch). If a band moves out, I'll lower Resonance to "+1 on faces of value 1–2 only" or move the die to Trusted, and report the numbers.

## Questions for the user

1. Is Friend the right step, or should it be Trusted (later, rarer)?
2. Style plus the +1 Resonance rule, or style only?
3. Do the three existing dice (Vigil, Tally, Ossuary) become the clan gifts, or should every clan get a new die?
