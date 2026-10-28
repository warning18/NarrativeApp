# The guide dog as a companion (Core's part)

The user decided that the guide dog of the tutorial becomes a normal
companion. It is earned by a quest in the second big town and can be swapped
out like the others. Narrative proposes the quest. This note covers what the
dog's entry needs, its numbers, whether it should change with the hero's
profession, and the risks for the simulator. This is docs only; nothing is
built yet.

**The second big town is Saltmouth (chapter 2).** Alster is the first (nodes
0–960); Saltmouth holds nodes 2000–2900. A party reaches Saltmouth at about
level 2–3 and leaves it at about 4. Kelda, Sable and Liora are recruited in
chapter 2 too, so the dog competes with them for the two seats.

## 1. Its entry in companions.json

Same fields as the other eight:

| Field | Value | Who |
|---|---|---|
| `companionID` | `guide_dog` (or the name Narrative gives it) | Narrative |
| `companionName`, `_fr` | Narrative | Narrative |
| `raceId` | `""`: no race. The game falls back to no race bonus everywhere it reads one (fight, simulator, camp, inventory, expedition). A "hound" race would show up in character creation. | Core |
| `professionId` | `ranger` | Core |
| `signatureDiceId` | `hound_die` (new) | Core |
| `recruitQuestId` | the Saltmouth quest | Narrative (Core sets its numbers) |
| `requiredHouseId` | `""` | — |
| `approvesGood` / `approvesEvil` / `approvesProfit` | a dog doesn't judge much: 1 / −1 / 0, so it rarely leaves | Narrative proposes, Core checks |
| the remark lines | every line field the others have | Narrative |

**Why `ranger`:**

- It gives +3 health, +2 Dexterity (dodge), +2 Wisdom and +1 Perception. The
  Perception sharpens the whole party's read of the foe's next move: the dog
  smells it coming.
- It does not out-tank Kelda or Grosh, and does not out-hit anyone.

**Other data the dog needs:**

- **A duo technique** in `lib/combat/duo_techniques.dart`. A test wants every
  companion to have one, and the test that expects exactly 8 duos goes to 9.
  The pair could be with Liora, the ranger ("the hunt"). Core builds it;
  Narrative names it.
- **Its lines** in `companion_remarks.json` and its walk lines, as for the
  others (Narrative).

## 2. Its numbers

These are the same rules as any companion. Health and damage grow from the
profession's base with the hero's level (+12% and +8% a level), and change
with approval.

| Party level | Health | Damage |
|---|---|---|
| 3, joining at Saltmouth | 29 | 2 |
| 9, chapter 4 | 45 | 3 |
| 16, chapter 6 | 64 | 4 |

The base is 20 + 3 = 23 health and 2 damage. For comparison, Kelda (dwarf
warrior) starts at 33 health and has 41 at level 3; Sable (human rogue) has
32.

**`hound_die`, a d6 (new):**

| Face | Effect |
|---|---|
| Bite | Attack 2 |
| Snap | Attack 1 |
| Guard | Defend 2. The largest block draws the blows, so a guarding dog takes a hit for the hero. |
| Stand fast | Defend 1 |
| Lunge | Skill: `heavy_attack` |
| Empty | Nothing. The dog gets distracted. |

It carries no element, so it never takes a foe's weakness away from the hero.
On the simulator's worth scale, `simCompanionValue` reads it below Kelda,
Liora and Sable. The pick rule therefore benches it once a stronger companion
joins, which is what "replaceable" should mean.

## 3. A build that matches the hero's profession? Not worth it now

The idea: five variants of the dog, one picked from the hero's profession
when it joins. For example, a guard dog for a mage and a hunting dog for a
warrior.

**Why not:**

- **About 12 places read a companion's profession or die straight from
  `companions.json`:**
  - the fight setup;
  - the simulator (twice);
  - the skills screen and skill sheet (the companion's skill tree comes from
    its profession);
  - the dice loadout;
  - the camp, the inventory and the expedition screen;
  - the ship battle panel;
  - the save's dice sizes;
  - clan affinity.

  A variant means a new field on the save (or a helper every one of those
  places calls instead), half of them UX's files. If even one place misses
  it, the dog shows one profession and fights as another.
- **Five dice and five builds to balance and test, for one companion.**
- **The gain is small.** Two seats and nine companions already let a player
  build around their hero. The dog's Perception (the party's read of the
  foe) helps every profession the same.

**If the user wants a little of it later,** one face of the hound die could
change with the hero's profession, decided in one place (the die's
resolution, used by both the fight and the simulator). For example:

- a mage's dog guards: Defend 3;
- a warrior's dog harries: the foe −1 damage this round;
- a cleric's dog stays close: heals the hero 2.

That touches two files and no save field. It is a later step if the user
asks.

## 4. Risks for the simulator

- **The competent profile will seek the quest.** It already takes the way
  that offers a companion's quest when it can. The dog then joins most
  competent runs in chapter 2 and takes a seat until Kelda's Hall or a
  stronger recruit benches it.
  - The competent and stubborn profiles win a little more in chapters 2–3.
  - The naive profile has no companions and is unchanged, so the CI bands
    (`boss_balance`, `clash_balance`, the champions) do not move.
- **Tests that move:**
  - `dice_rules_test` (8 duos → 9);
  - the tests that walk every companion's lines (`companion_remarks_test`,
    `approval_test`), which pass once Narrative's lines are in;
  - `sim_companions_test`, whose numbers compare profiles rather than pin
    them. The naive run there is pinned and does not move.
- **The difficulty question (§7 of `difficulty-pass.md`) gets one more
  companion to weigh.** A dog in chapter 2 makes the early party
  stronger, so the stubborn profile wins more there. I will measure the dog
  in when it is built, before the user is asked about §7 again.
- **The tutorial dog and the companion dog are the same animal.** If the
  guide still shows during the tutorial and the dog later walks with the
  party (`walking_companion_strip.dart`), UX decides how the guide hands over
  to the companion (sprite, name). That is not Core's part.

## 5. What Core builds once Narrative's quest is in

1. The `companions.json` entry: the race, profession, die and approval
   numbers above, with Narrative's text.
2. `hound_die` in `dice.json`.
3. The duo in `duo_techniques.dart`.
4. The quest's reward numbers (gold, XP, `rewardAllyId: guide_dog`).
5. A 10-run measure of the competent and stubborn profiles with the dog,
   added to `difficulty-pass.md`.
6. The tests above re-pinned.
