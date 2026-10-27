# More dice sizes (Core, proposal)

Design only. Written on v1.567, revised after the user's answer: "The 12-faced die should have 12 faces to equip and a dedicated art". This note covers sizes, odds and data; UX proposes the art and the roll animations.

## The rule

**A die has as many faces as its size, and every face can be equipped.** A d4 has 4 slots, a d6 has 6, a d8 has 8, a d12 has 12, and the coin has 2. Each slot holds one face, either a plain number (Attack, Defend, Heal, Mana) or a skill. There is no cap on skill faces below the face count.

On the equipping screen, the die shows as *n* slots in a ring, one per face. The player drops a skill or a numbered face into each slot. A roll picks one slot, by the face weights as today.

## Today

- **Faces.** A die is a list of weighted faces in `dice.json`. Only the faces marked Skill take a skill today. The others are fixed numbers.
- **Crits** come from Luck, not from the die. Only one die is in play at a time.
- **The 31 existing dice:**
  - 29 have six faces;
  - `void_die` has four;
  - `vigil_die` has seven.
- **Where they come from:**
  - `starter_die` from the start;
  - shops, 60–290 gold;
  - five companion dice, given when the companion joins.

**How they map to the new rule.** Every existing die keeps its faces, weights and skill faces as they are. Its non-skill faces simply become slots the player may re-equip too. The new dice start with plain numbered faces in every slot.

## The sizes

| Size | Slots | Chance per face (equal weights) | What a full die feels like | How it is obtained | Price |
|---|---|---|---|---|---|
| Coin | 2 | 50% | Outside fights only: heads or tails for a check | One-use consumable, bought or found | 30 |
| **d4** | 4 | 25% | Few slots, so each one comes up often. Easy to fill, very steady. | Shop | 90–140 |
| **d6** (today) | 6 | ~17% | The all-rounder | As today | 0–290 |
| **d8** | 8 | 12.5% | Room for a full build: two skill lines and the numbers they need | Forge, merge, clan gift | 160–220 |
| **d12** | 12 | ~8% | The largest kit, but any one face comes up rarely | Built (see below) | — |

**Odds and average.** With every face equippable, the average of a die is the average of what the player puts on it.
- A bigger die isn't stronger on its own. It holds more different things, and each one comes up less often.
- A small die filled with the best faces is the most reliable.
- A big die is the most varied, and the strongest once it has many good faces to fill it with.

**The d12: built, not a boss drop.** The player earns its 12 slots over the run.
- **Where the first one comes from:** a chapter 5 quest reward, or a merge of two d8s at the Skillwright.
- **How it fills:** it starts with plain numbered faces, and skills are placed as they are unlocked.

This fits "12 faces to equip" better than a trophy that arrives already filled.

## Balance risk (for the simulator to measure before any build)

| Change | What can go wrong | Tests it could move |
|---|---|---|
| Every face equippable (all sizes) | A die filled with nothing but its best skill: many more skill outcomes, fewer plain numbers | `boss_balance` (profession floor 60, the boss means), `clash_balance` |
| d4 | Four copies of one strong skill comes up every roll | `boss_balance` (most likely the High Warden and void_manifestation) |
| d8 | More skill faces per die, most of all for casters | `clash_balance` chapters 3–6 |
| d12 | Late power once it is full; the competent player already wins 0.87–0.90 in chapters 7–8 | `boss_balance` late cases, `nemesis_quests` |
| Coin | Cheap rerolls on checks | `land_rulers` crossing health loss (about 1.5–3.5%) |

**One guard to test first:** at most one copy of the same skill per die, or per four slots. That limits the "same skill on every face" risk without capping how many skill faces a die can hold.

## What is worth the screen space

Four fight sizes (d4, d6, d8, d12) and the coin. Each new size needs only a couple of dice to start: one or two d4s, two d8s, and the d12 the player builds.

## Calls (the user can reverse these)

1. **All 29 six-sided dice stay.** None is merged or removed. Those that share a face shape get their own look instead (UX), because players already own them and each one belongs to a profession or a companion.
2. **The d12 has no crit bonus of its own; crits stay on Luck.** That way every die reads the same, and a crit always means the hero's Luck, not the die.
3. **The fate coin is a one-use consumable,** bought or found, not a permanent camp upgrade. A coin that is spent stays a small, rare choice, not a free reroll every time.
