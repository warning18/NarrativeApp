# More dice sizes (Core, proposal)

Design only. Written on v1.567, revised twice after the user's answers:
- "The 12-faced die should have 12 faces to equip and a dedicated art."
- "Propose variety of dices first… Keep the number of faces logical, to still have a dice."

This note covers sizes, odds and data. UX draws the art for each die once the table below is approved.

## 1. The 31 dice: proposed sizes

Only real dice sizes are used: 4, 6, 8, 10, 12 and 20 faces (the coin is 2). The proposal is a spread, not a rule:

| Size | Dice |
|---|---|
| d6 | 10 |
| d4 | 6 |
| d8 | 7 |
| d10 | 4 |
| d12 | 3 |
| d20 | 1 |

| Die | Faces now → proposed | Why (the die's identity) | Obtained today |
|---|---|---|---|
| starter_die | 6 → **6** | The plain first die everyone knows | Start of the game |
| apprentice_die | 6 → **6** | A beginner caster's die, kept simple | Shop, 60 |
| iron_die | 6 → **6** | The warrior's steady die; also a companion's signature | Shop, 90 |
| holy_die | 6 → **6** | A cleric's balanced prayer die; also a companion's | Shop, 105 |
| bulwark_die | 6 → **6** | A warrior's even defence die | Shop, 100 |
| pilgrim_die | 6 → **6** | The traveller's all-rounder | Shop, 95 |
| liora_die | 6 → **6** | Companion signature: keeps its known shape | Liora joins |
| grosh_die | 6 → **6** | Companion signature | Grosh joins |
| tobin_die | 6 → **6** | Companion signature | Tobin joins |
| malrik_die | 6 → **6** | Companion signature | Malrik joins |
| void_die | 4 → **4** | Already narrow: a few dark, sharp faces | Shop, 120 |
| stone_die | 6 → **4** | Heavy stone: few, big faces | Shop, 95 |
| berserker_die | 6 → **4** | All-in: little to choose, hits hard | Shop, 100 |
| shadow_die | 6 → **4** | A rogue's narrow die (also Sable's) | Shop, 115 |
| twinfang_die | 6 → **4** | Two fangs, tight and fast | Shop, 105 |
| headsman_die | 6 → **4** | The executioner: few faces, each heavy | Late shop, 180 |
| flame_die | 6 → **8** | A caster's die is wide: room for spells | Shop, 110 |
| tide_die | 6 → **8** | A cleric's flowing die: heals and spells | Shop, 110 |
| huntsman_die | 6 → **8** | A ranger's kit: traps, shots, tracks | Quest reward |
| vess_die | 6 → **8** | Companion signature, a mage: wide | Vess joins |
| frost_die | 6 → **8** | Layered cold effects | Shop, 115 |
| greenwood_die | 6 → **8** | The forest's many small gifts | Shop, 140 |
| vigil_die | 7 → **8** | A d7 isn't a real die. One plain face makes it a d8 and keeps all seven of its faces. | Late shop, 250 |
| storm_die | 6 → **10** | A storm has many varied faces | Shop, 100 |
| arcane_die | 6 → **10** | The mage's widest die | Shop, 130 |
| sage_die | 6 → **10** | Knowledge: many answers | Shop, 150 |
| ossuary_die | 6 → **10** | Bones: many small rattling faces | Late shop, 220 |
| tempest_die | 6 → **12** | The great storm: the largest kit for a builder | Shop, 125 |
| chorus_die | 6 → **12** | Many voices, one die | Late shop, 160 |
| tearglass_die | 6 → **12** | The rarest late die, a boss-sized kit | Late shop, 290 |
| gambler_die | 6 → **20** | The one d20 in a fight: any face might come up | Shop, 85 → **200**, rarer |

### How the faces change
- **A die that grows** (d6 → d8, d10 or d12) keeps all its faces and their weights. The new faces are plain numbered faces to equip (Attack, Defend or Heal, weight 1.0). Each one is set to the die's own average plain value, so the die's average doesn't change until the player fills it.
- **A die that shrinks** (d6 → d4) keeps its Skill faces and its strongest plain faces, and drops its two weakest plain faces. Its average rises a little, so its price stays the same and its weights are re-checked by the simulator.
- **gambler_die (d20)** keeps its six faces, and 14 plain faces spread its numbers widely. It becomes rarer (200 gold, late shop) because its swings are big.

### What a face-count change touches
| What | How |
|---|---|
| **Saves**: the equipped die and its placed skills | The equipped die is saved by id (`equippedDiceId`), so it doesn't change. Placed skills and Hammersmith work are kept per face index (`upgradesOfDie`). New faces are added after the old ones, so every old index stays where it was. On a shrink, the dropped faces are the last plain ones. A skill placed on one goes back to the hero's skill list to be placed again, and Hammersmith work on it is refunded. |
| **Prices** (`dice.json` `cost`) | Unchanged, except gambler_die at 200 |
| **Shops** (`shops.json`) | They list dice by id, so they don't change. gambler_die moves to a late shop. |
| **skill_merges.json** | Merges name skills, not dice, so they don't change |
| **Competent simulator** | It rolls the best die it owns by expected value. Re-check which die each profession picks. |
| **Tests that pin faces** | `skill_fight_harness`, `fight_markers_harness`, `fight_hero_harness`, `clash_test`, `qa_seeded_rolls_test` and `spells_data_test` read face counts or indexes. Update them to the new sizes; they keep checking the same things. |

## 2. The rule for every die

**A die has as many faces as its size, and every face can be equipped.** A d4 has 4 slots, a d6 has 6, a d8 has 8, a d12 has 12, and the coin has 2. Each slot holds one face, either a plain number (Attack, Defend, Heal, Mana) or a skill. There is no cap on skill faces below the face count.

On the equipping screen, the die shows as *n* slots in a ring, one per face. The player drops a skill or a numbered face into each slot. A roll picks one slot, by the face weights as today.

## 3. The sizes

| Size | Slots | Chance per face (equal weights) | What a full die feels like | How it is obtained | Price |
|---|---|---|---|---|---|
| Coin | 2 | 50% | Outside fights only: heads or tails for a check | One-use consumable, bought or found | 30 |
| **d4** | 4 | 25% | Few slots, so each one comes up often. Easy to fill, very steady. | Shop (6 dice) | 95–180 |
| **d6** (today) | 6 | ~17% | The all-rounder | As today | 0–290 |
| **d8** | 8 | 12.5% | Room for a full build: two skill lines and the numbers they need | Shop, quest, companion (7 dice) | 100–250 |
| **d10** | 10 | 10% | Wide: many skills, each less often | Shop (4 dice) | 100–220 |
| **d12** | 12 | ~8% | The largest kit, but any one face comes up rarely | 3 late dice (tempest, chorus, tearglass), or built (see below) | 125–290 |
| **d20** | 20 | 5% | The gambler's die: anything can come up. The check die (crossings, the forge) stays a d20 too. | gambler_die, rare | 200 |

**Odds and average.** With every face equippable, the average of a die is the average of what the player puts on it.
- A bigger die isn't stronger on its own. It holds more different things, and each one comes up less often.
- A small die filled with the best faces is the most reliable.
- A big die is the most varied, and the strongest once it has many good faces to fill it with.

**A built d12, beside the three late ones.** The player earns its 12 slots over the run.
- **Where the first one comes from:** a chapter 5 quest reward, or a merge of two d8s at the Skillwright.
- **How it fills:** it starts with plain numbered faces, and skills are placed as they are unlocked.

This fits "12 faces to equip" better than a trophy that arrives already filled.

## 4. Balance risk (for the simulator to measure before any build)

| Change | What can go wrong | Tests it could move |
|---|---|---|
| Every face equippable (all sizes) | A die filled with nothing but its best skill: many more skill outcomes, fewer plain numbers | `boss_balance` (profession floor 60, the boss means), `clash_balance` |
| d4 | Four copies of one strong skill comes up every roll | `boss_balance` (most likely the High Warden and void_manifestation) |
| d8 | More skill faces per die, most of all for casters | `clash_balance` chapters 3–6 |
| d12 | Late power once it is full; the competent player already wins 0.87–0.90 in chapters 7–8 | `boss_balance` late cases, `nemesis_quests` |
| Coin | Cheap rerolls on checks | `land_rulers` crossing health loss (about 1.5–3.5%) |

**One guard to test first:** at most one copy of the same skill per die, or per four slots. That limits the "same skill on every face" risk without capping how many skill faces a die can hold.

## 5. What is worth the screen space

Six sizes, mostly coming from the 31 dice that already exist (table in §1). Only the coin and a built d12 are new.

## 6. Calls (the user can reverse these)

1. **No die is removed,** but most change size (§1). The user wants variety, and the dice are the centre of the game. Each die keeps its name and its faces.
2. **The d12 has no crit bonus of its own; crits stay on Luck.** That way every die reads the same, and a crit always means the hero's Luck, not the die.
3. **The fate coin is a one-use consumable,** bought or found, not a permanent camp upgrade. A coin that is spent stays a small, rare choice, not a free reroll every time.
