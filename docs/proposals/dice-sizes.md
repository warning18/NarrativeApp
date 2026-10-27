# More dice sizes (Core, proposal)

Design only. Written on v1.567. This note covers sizes, odds and data. UX proposes the styles and the roll animations, and the manager puts the two together.

## 1. Today

- **How a die works.** A die is a list of faces in `dice.json`. Each face has a type (Attack, Defend, Heal, Mana, Skill), a value and a `weight`, and a roll picks one face by weight. So a die's **size** is its face count, and its odds come from the weights.
- **Skill faces.** A Skill face holds a skill (`linkedSkillID`). The skill tree places the hero's skills on the die's Skill faces.
- **Crits.** No die has a crit or fumble range. Crits come from Luck (1.5% a point, capped at 35%), and Perception for a ranger or rogue.
- **One die in play.** The hero rolls one die (`equippedDiceId`). It can be swapped for another owned die before a fight.

| Size | Dice | Where they come from | Price |
|---|---|---|---|
| 4 | `void_die` (2 Skill, 1 Heal, 1 Attack) | shop | 120 |
| 6 | `starter_die` | the start of the game | 0 |
| 6 | the profession dice: iron, flame, tide, storm, shadow, holy, arcane, huntsman, bulwark, twinfang, apprentice, sage | shops | 60–150 |
| 6 | the open dice: stone, berserker, gambler, frost, pilgrim, tempest | shops | 85–125 |
| 6 | the companion signature dice: liora, vess, grosh, tobin, malrik | the companion joins | (100–120) |
| 6 | the late dice: greenwood, chorus, headsman, ossuary, tearglass | late shops | 140–290 |
| 7 | `vigil_die` (3 Skill, 1 each of Attack, Defend, Heal, Mana) | late shop | 250 |

That is 31 dice: 29 with six faces, one with four and one with seven. Most six-sided dice have 2–4 Skill faces.

**What the competent simulator rolls** (v1.564, 10 runs): non-casters kept their starting die, because no die they may roll beats it. 3 of 4 casters bought a better one (tearglass twice, ossuary once).

## 2. Sizes worth adding

Here a d*N* means a die with *N* faces. A smaller die repeats its faces more often, so it is steady. A bigger die holds more skills, but each one comes up less often.

| Size | Chance of one face (equal weights) | Skill faces it holds | Feel and build | How it is obtained | Price |
|---|---|---|---|---|---|
| **d4** | 25% | 1–2 | Steady: one strong skill comes up every 4th roll. For a single-skill build (Berserker, Heavy Blow). | Shop, clan gift (Sign/Object) | 90–140 |
| **d6** (today) | ~17% | 2–4 | The all-rounder. | As today | 0–290 |
| **d8** | 12.5% | 3–5 | Versatile: room for a second skill line or an element. For a hybrid: a cleric healer and striker, a spellblade. | Forge (v1.562 roll), merge, clan gift | 160–220 |
| **d10** | 10% | 4–6 | A deep kit, each skill rarer. For a caster with many spells and Mana faces. | Quest reward or merge only (one per chapter at most) | n/a |
| **d12** | ~8% | 5–7 | The legendary die: many skills, but none can be relied on. Its weights must stay tight. | One per run: a boss or the chapter 7 throne | n/a |
| coin (d2) | 50% | 0–1 | Not a fight die. A **Fate coin** for checks outside fights (camp fate, crossings, the forge reroll), heads or tails. | Camp house or a consumable | 30 |
| d3 | 33% | 1 | Too close to the d4. Not worth a size of its own. | — | — |
| d20 | 5% | — | Already used as the *check* die (crossings, the forge, ability checks). Keep it for checks, not fights. | — | — |

**Crit and fumble.** I would keep crits on Luck, as today, so that every size reads the same. The one exception I'd suggest: a d12's top face could crit on its own. That needs a test before deciding.

## 3. Balance risk (for the simulator to measure)

| Size | What can go wrong | Bands it could move |
|---|---|---|
| d4 | One strong skill every 4th roll could make a boss trivial. | `boss_balance` (most likely the High Warden and void_manifestation), `clash_balance` |
| d8 | More skills on one die raises the skill rate, and most of all a caster's damage. | `boss_balance` profession floor (60), `clash_balance` chapter 3–6 |
| d10 | Late power creep. | `boss_balance` late cases, `nemesis_quests` (champions floor 0.38) |
| d12 | A legendary late die makes chapters 7–8 easy. The competent player already wins 0.87–0.90 there. | `boss_balance`, the chapter 7–8 win rate |
| coin | Cheap rerolls on checks could flatten the crossings' health loss. | `land_rulers` crossing loss (about 1.5–3.5%) |

Each size could be measured with the competent simulator (about 10 runs) against today before it is built.

## 4. What is worth the screen space

The user wants fewer, better dice. My pick is **four sizes and about eight dice in all**:

| Keep | Why |
|---|---|
| **d6** (today's, trimmed) | The base. Merge look-alikes: stone, storm, liora and grosh have the same 1/1/3/1 shape. |
| **d4** × 2 (one blade, one ward) | A clear "steady" choice, and very readable on screen. |
| **d8** × 2 (one per hybrid: martial and arcane) | The "build" choice, earned at the forge or by a merge. |
| **d12** × 1 | The rare trophy: one per run, from a boss. |
| **Fate coin** | Outside fights only. It gives the forge and the crossings a small, clear roll. |

I'd drop the d10 (it sits between the d8 and d12 with no clear role) and the d3. Profession dice could then shrink to one d6 per profession, with the companion dice kept as they are, since they are characters.

## Open questions for the user

1. **Trim the d6s?** 29 six-sided dice could become about 10 (one per profession, the companions', two open).
2. **d12 crit:** should the d12's top face crit on its own, or should crits stay on Luck only?
3. **Fate coin:** a camp house, or a consumable bought in towns?
