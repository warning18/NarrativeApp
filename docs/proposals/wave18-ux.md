# Wave 18 on the look side: locked districts, districts held by clans (UX, for the user to choose)

Docs only. Nothing is built until the user picks. The ask: districts stay **locked until a side quest unlocks them**, and in the big towns the districts are **held by clans**, whose **influence** is built by quests, whose hold **flips**, and which **rival clans attack**. This is how it reads on the Town view (the whole-town plan, `CityChartView`, with the district rows under it). Sizes: **S** one PR under a day, **M** two or three days, **L** a design board first.

| # | Item | Size | Needs |
|---|---|---|---|
| 1 | A locked district's look, and the way to open it | S | Core: which side quest unlocks which district, and "is it open" per district |
| 2 | Who holds a district: its colour and crest | S | nothing (the ruler colours and flags exist) |
| 3 | Influence: how far each clan has got | M | Core: influence per district per clan, and the flip thresholds |
| 4 | An attack, shown on the plan and in words | M | Core: attacks as data (who, where, when, result) |

## 1. A locked district (S)

Today a district not yet found lies under fog and is "walked into". A district that needs a quest is a different thing from one not yet seen, so it looks different: the block stays drawn (the player can see it exists) but **shuttered**: a diagonal hatch over its blocks, a dashed outline, a padlock on its marker, and its colour drained to the plan's grey. Its name is shown (a rumour is more tempting than "?") with the line "Closed: finish *The Widow's Debt*" in the row under the plan, and a tap on it opens the sheet of that side quest (title, who gives it, "Show on the map"). The side quest's own pin carries a small key mark. When the quest is done, the shutters lift: the hatch wipes away left to right and the district's colour comes back (reduced motion: at once); the handover toast says "The Ash-Market is open".

## 2. Who holds a district (S)

The Town view already tints districts by their ruler (wave 15, `townRulersProvider`) and says it in words under the plan. In the big towns each district gets its **crest**: the holding clan's little flag (`ClanFlag`) at the district's marker, over the name, in the clan's colour with its accent outline. A district held by no one is the plain tint. A contested district (see 3) shows two thin stripes of the two clans' colours along its outline. The row for a district reads "Held by the Compact" with the flag, as the town's ruler line does.

## 3. Influence (M)

Influence is a number per clan per district, so it needs a shape the player can read at a glance and at 320 px:
- **On the plan:** a thin ring round the district's marker, filled clockwise in the holder's colour in proportion to its hold, with a tick where the hold would flip; a rival's pressure is a second, shorter arc in its colour on the same ring.
- **In the row:** a two-colour bar (holder left, strongest rival right) with the numbers, "Compact 62 · Crows 31", and a small up or down arrow for the trend since the last look.
- **Tap a district:** a sheet with a ledger: each clan's flag, a bar, its influence, and "what raises it" (the quests that give it, as rows that open the quest). The quest that would tip the district is marked with the key mark.
- **A quest that moves it** says so on its card ("+8 Compact in the Ash-Market"), in the effect-chip style of the expedition mock.

## 4. An attack (M)

A rival attack is something that happens on the plan, so it is drawn there and said in words:
- **Before:** a pulsing arrow in the attacker's colour from its nearest district to the target, a crossed-swords mark on the shared border, and the target's row says "Under attack by the Crows: 2 days".
- **While:** the target's ring flickers; the Town tab carries a red dot (as the Camp tab does for what waits) so it is seen from elsewhere.
- **After:** the result is a short sequence: the block colour wipes to the winner's, the crest swaps, and a toast says who took what; the handover list (v1.521) gains the line with the old and new flag. A defended attack shows a shield mark for a day.
- It is also a **Journal entry** and a **Journey banner** on the district's pin, so the player who is on the road knows.

## What I need from Core and Narrative

Core: the data for 1, 3 and 4 (an `open` flag and the unlocking side quest per district; influence per district per clan with the flip thresholds; attacks with attacker, target, day due and result). Narrative: the rumour lines of the locked districts and the wording of the attack notices and toasts (EN/FR), with the keys I name.

## Order I would suggest

2 first (it needs nothing), then 1 (it needs a flag), then 3 and 4 together, since the ring and the attack arrow share the district marker.

## Other ideas (one line each)

- A **"What changed" strip** over the Town view after a flip or a quest, as the world map has, so a returning player sees it first.
- **Districts as a ladder in the sheet:** one list with crest, influence bar and lock state, as the pins' list is grouped.
- A **clans' legend** on the town plan (flag, colour, share of districts) that doubles as a filter ("show only the Compact's districts").
- **Night and attack together:** an attack at night lights its border in the attacker's colour.
- The **ward marks** (v1.52x) on a district's crest when the hero is warded there.
- **A district's history** under its sheet: who held it and when, as a small timeline of flags.
- **Companions remark** on a flip they care about, as the speech bubble over the party does at sea.
- **A quest tracker bar over the plan** showing the side quest that opens the nearest locked district.
