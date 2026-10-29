# The guide dog as a companion (Core's part)

> **Superseded in part by §6 (the user's change).** Vica is now the
> companion every hero gets, from the story, not a quest. §1–§5 below are
> kept for the record; §6 says what changes.

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

## 6. Update: Vica is the companion every hero gets

The user's change: Vica, the tutorial's guide dog, joins every hero
automatically, just before the city after the desert. Narrative pins the
scene. Difficulty is then tuned for "hero plus Vica", even for a player who
finds no other companion. Other companions replace her in the party later.

### Where and when

- **When she joins:** the city after the desert is Saltmouth. The crossing
  runs from the wreck of the Lark (`1100`) to the White Wells (`1200`), and
  Saltmouth starts at `2000`. So she joins at the end of the chapter 1 → 2
  road, at about **level 2–3**. Narrative picks the scene; anywhere between
  `1200` and `2000` changes nothing below.
- **Her numbers there:** the §2 table.
  - Level 3: 29 health, 2 damage.
  - Level 9: 45 health, 3 damage.
  - Level 16: 64 health, 4 damage.
  - `hound_die` as in §2.

### Her entry, changed from §1

| Field | Value |
|---|---|
| `companionID` | `vica` |
| `companionName` | Vica (Narrative's lines, already written on `claude/narrative-dog`) |
| `raceId` / `professionId` / `signatureDiceId` | `""` / `ranger` / `hound_die` (unchanged) |
| `recruitQuestId` | `""`: no quest, and no Good or Evil gate |
| `storyRecruit` (new) | `true`. The scene Narrative picks carries `recruitAllyId: "vica"` on its way on, and the session recruits her there. This is the quest's `rewardAllyId`, put on a choice. |
| `permanent` (new) | `true`. She never leaves at low approval, and `loseAllyId` skips her. A knock-out in a fight lasts only for that fight, as for everyone. |
| approval | 1 / −1 / 0. Her approval still moves her lines and her devoted/wary tier (±10% health and damage). |

### The rules Core adds

1. **Recruit from the story.** A choice field `recruitAllyId` calls the same
   `recruitAlly` a quest uses. The simulator's walk does the same.
2. **Always seated when the party would be empty.** After a recruit,
   departure, loss or bench, if no companion is seated and Vica is
   recruited, she takes a seat.
   - In the camp, the player can bench her only by seating someone else. UX
     greys the "bench" control when she is the last one seated; Core gives
     them `canBench(id)`.
3. **She never leaves.** The leave line at −12 approval and `loseAllyId`
   skip a `permanent` companion.
4. **Old saves.** A save already past the join scene gets her on load: Core
   checks the scene's flag, or the furthest chapter ≥ 2. Without that,
   today's players would never meet her.
5. **The duo with Liora** (The Hunt / La Battue), as in §1.

### A face that changes with the hero's profession: still no, but measured

Because she is guaranteed, I measured the cheaper option from §3: her
"Distracted" face (empty) becomes a face that depends on the hero's
profession:

- warrior: Lick wounds, heal 2;
- rogue: Lick wounds, heal 2;
- mage: Shield, Defend 3;
- ranger: Shield, Defend 3;
- cleric: Harry, Attack 3.

**How it was measured:** one human hero per profession, no gear, at each
chapter's usual level, with Vica, against six foes of chapters 3–6, 60
fights each.

| Hero + Vica, won | Warrior | Mage | Rogue | Cleric | Ranger | All |
|---|---|---|---|---|---|---|
| Her plain die | 0.31 | 0.48 | 0.40 | 0.28 | 0.20 | 0.34 |
| With the profession face | 0.34 | 0.48 | 0.34 | 0.31 | 0.20 | 0.34 |

**It changes almost nothing.** It does not close the gap it was meant to
close:

- the ranger stays the weakest, at 0.20;
- the rogue loses with a heal in place of a chance at nothing.

A face is one sixth of her rolls, and her damage is small, so no single face
covers a hero's weakness. Compensating the hero's weakness would need her
whole build to change with the hero, which is the five-variant cost of §3.
**My call: plain Vica.** If the user wants her to feel tailored, her lines
can follow the hero's profession at no balance cost. That is Narrative's
part.

### The simulator: every profile has her

The naive profile becomes "hero + Vica, little gear, the starter die".
That is the baseline the user asked to tune for. The competent and stubborn
profiles get her too and may bench her for stronger recruits. The pick rule
already benches the weakest seat.

**What moves:**

| Test | Today (naive = no companion) | With Vica | Re-pin |
|---|---|---|---|
| `boss_balance` boss curve (11 bosses, the claimants pooled, the mean, professions within 8 points) | targets 0.75 → 0.35 | everyone wins more from chapter 2 on | **Keep the targets** (they are the design). Raise the foes so hero + Vica meets them: regular health floors for chapters 2–8, the boss floor, and per-boss health where one strays. Aurel Vane (chapter 1) does not move. |
| `nemesis_quests` champions' curve (about 0.5) | 0.53 | higher | the champions' health, as at v1.597 |
| `clash_balance` (a gap between two rule sets) | both sides naive | both sides move together | run once; expected to hold |
| `chapter_one_fights` | chapter 1 | before Vica joins | unchanged |
| `sim_competent_test`, `sim_companions_test` (the pinned naive run: numbers and choices hash) | pinned | moves | re-pin both, once |
| `sim_quest_politics_test`, `stat_*`, `character_start` | logic | | unchanged |
| new: `vica_test` | | | she joins at the scene, is seated when the party is empty, never leaves, an old save gets her, and the sim seats her for every profile |

All of this is one build PR (the entry, the rules, the simulator, the
re-sizing), running only these band tests. No broad batch.

## 7. Built (v1.601)

The user approved §6, and Narrative's story PR follows mine.

**Data**
- **`companions.json` `vica`:**
  - `raceId ""`, `professionId ranger`, `hound_die`, approval 1 / −1 / 0.
  - `storyRecruit`, `permanent`, `joinNodeIds: ["1150_vica", "1200"]`.
  - The lines are Narrative's, from their note.
- **`hound_die`**, a d6:

  | Face | Effect |
  |---|---|
  | Bite | Attack 2 |
  | Snap | Attack 1 |
  | Guard | Defend 2 |
  | Stand Fast | Defend 1 |
  | Instinct | Skill `ranger_beast_bond`, her signature face for duos |
  | Lick Wounds | Heal 1 |

  - The planned empty "Distracted" face became Lick Wounds. The dice rules allow no Empty face, and every face must take a skill.
  - Lunge became Instinct, because a duo needs a signature face that isn't `heavy_attack`.
- **The duo `the_hunt`** (Liora and Vica): a stun blow.
- **Her remark lines** in `companion_remarks.json`: the lines of Narrative's note, plus a second line for each moment, because the remark test wants two. Narrative may reword them.

**Rules** (`lib/data/story_companions.dart`)
- **When she joins:** at the first join scene the story reaches. In the game, `storyRecruitsProvider` watches the visited scenes. A save already past the White Wells gets her at once, or at its next step.
- **She can't leave:**
  - she never falls to −12 approval (she stays wary at worst);
  - `loseAllyId` skips her, and `*` takes the first other companion seated.
- **She keeps the party from going empty:**
  - when a bench would empty the party, she sits down in it;
  - `canBench(id)` refuses to bench her when she is the last one seated.
- **The simulator** gives her to every policy at the same scenes. The naive player recruits no one else.

**Balance**
All bands are sized for "hero + Vica"; their targets are kept. `difficulty-pass.md` §9 has the numbers.
