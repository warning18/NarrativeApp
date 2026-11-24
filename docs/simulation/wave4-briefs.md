# Wave 4: six late-game briefs

One page per proposal from the engagement review (branch
`claude/core-engagement`, `docs/simulation/engagement-review.md`), so the user
can decide each one quickly. **Nothing here is built.** No rule, number or
data changes until the user chooses.

## Summary

| # | Proposal | Effect (estimate) | Risk | Size | Recommendation |
|---|---|---|---|---|---|
| 1 | Late skill cards rank up a skill | build changes in ch5 to ch8: about 3.5 now, about 7 to 9 (typical player) | medium: late power rises | M | **Rank up only** (option A) |
| 2 | A late gold sink with a choice | gold at ch8: about 6,200 now, about 1,500 to 2,500 | low (medium if it buys power) | M | **A fourth camp tier** (option B) |
| 3 | Chapter goals with a chest | up to 7 better chests a run; win rate unchanged | low | M | **A separate chapter chest** (option B) |
| 4 | One difference per clone skill | 15 groups, 34 skills: a quarter of all skill cards offered | medium: each change re-checked | M | **Change one member per group** (option A) |
| 5 | The Void Banner gets its own slot | whole set worn: 0 now, 13 of 100 careful runs; win rate up about 2 points | low to medium | S to M | **Own slot** (option A), with a check of the ch8 bosses |
| 6 | Chapter 7 pacing | 2.6 fights now; Core measures before Narrative writes | low | S for Core | **Measure first, then ask Narrative** (option B) |

## Sources

| Tag | What | Version |
|---|---|---|
| **EG992** | the engagement review's batch: typical (T) and competent (C) players, seeds 1..100, one run per seed | v1.992 |
| **GS989** | `gear-sets.md` | v1.989 |
| **W4** | my batch for this note: `simulatePlaythroughs`, policies `typical` and `competent`, seeds 1..100, one run per seed, the 25 race x profession pairs x 4 goals (the plan of `difficulty-review-1.914/story_runs_test.dart.txt`). Two worlds: **base** (the game as it is) and **banner** (the Void Banner's `equipSlot` set to a sixth slot, `Banner`, in the in-memory tables only). `onFight` read the save before each encounter; `onFightDie` read each try. 4 batches of 100 runs, 25 to 60 s each. Throwaway harness `test/zz_wave4_test.dart`, deleted, never committed. | v1.1009.0 (`ce64ede6`) |

W4 base matches EG992 closely (encounters per chapter within 0.3, gold at
ch8 6,182 vs 6,203), so the two can be read together.

"T" is the typical player (takes what looks bigger), "C" the competent one
(weighs every choice). The simulator plays no Hammersmith work, rolls no
chests and spends no skill essence on skill tiers: where a brief depends on
those, it says so.

---

## 1. Late cards that change the build

**For the player.** Late in the game, a skill card you cannot use (every
open face of your die already holds a skill) becomes "**Rank up** X": one of
the skills on your die gets one tier stronger. You always get something you
can feel in the next fight.

**Numbers today.**
- Open skill faces are full in every fight from chapter 2 (T) and chapter 4
  (C). The die in play has a median of **1** open skill face (W4).
- Chapters 5 to 8, per run (W4 base): T sees 34 offers, 9.7 with a skill
  card, and takes a skill 0.9 times; C sees 34 offers, 28.7 with a skill
  card, takes 1.7. So **8.8 (T) and 26.8 (C) offers a run carry a skill card
  nobody wants**.
- Big changes in ch5 to ch8: T 3.5, C 5.1 a run (EG992 CSV).

**Estimate.** A quick calculation, not a run (the simulator has no skill
tiers yet). A skill has tiers 0 to 3; each tier gives +25% to its flat
number and +0.1 to its multiplier (`applySkillTier`). With 2 to 3 skills on
the die, a run can take about 6 to 9 rank-ups before every skill is at the
top. T takes a card it can use in 30 to 60% of offers, so about 3 to 5
rank-ups; C hits the cap. **Big changes in ch5 to ch8: T from 3.5 to about
7 to 9, C from 5.1 to about 10.** A face at tier 3 hits about 40 to 60%
harder; skill faces are 1 to 3 of 6, so late damage rises roughly 5 to 15%.

**Risk.**
- Balance: medium. Late fights get easier; the ch8 bosses (83% first try
  for T in W4) and `boss_balance_test` must be re-checked.
- Saves: none. Tiers are already saved (`skillTiers`).
- Other sessions: UX (the card's label and what it shows), Narrative (one
  line per card kind, English and French).
- Core work: the offer rule in `lib/data/offers.dart`, and skill tiers in
  the simulator (`sim_growth.dart`), which it lacks today.

**Size.** M.

**Decision.** When a skill card cannot go on the die, what should it be?
- **A. "Rank up X", a free tier for a skill on the die. (Recommended:** a
  real change, uses a rule that exists, no save change.)
- B. "Swap into face N": the card says which skill it would replace. This is
  a label only (the swap exists today), so it changes no numbers and adds no
  new choice.
- C. Both: rank up, or swap.

---

## 2. A late gold sink with a decision

**For the player.** From chapter 5 there is something worth saving for, and
not enough gold to buy it all. You pick what matters to your hero.

**Numbers today.**
- Median gold at the first fight of each chapter (T, W4 base): ch5 2,359,
  ch6 4,024, ch7 5,778, **ch8 6,182**; at the end 7,108. C: ch8 6,251.
- The simulator already builds most of the camp (all 15 houses cost 8,130
  gold). The two great works that are often missing are gated by materials
  and story flags, not by gold: Banner Loft (1,600 gold) in 56 T runs,
  Shroud Shrine (2,000) in 32.
- The Hammersmith's face work already costs gold: a Hone 80, 160, 240; a
  Temper 150; an Inscription 250 and a trophy; a Recast 120
  (`face_smithing.dart`). The simulator never uses it, so real players
  likely hold less gold than the simulator says.

**Estimate.** Arithmetic: gold at ch8 goes down by what the sink takes. A
sink priced at 4,000 to 5,000 gold across ch5 to ch8 brings **median ch8
gold from about 6,200 to about 1,500 to 2,500**. If what it buys is power,
expect about +1 to +3 points of late win rate (compare brief 5: one extra
gear slot gave about +2).

**Risk.**
- Balance: low if the sink buys comfort or choice, medium if it buys power.
- Saves: a new house or tier is a new id; old saves simply do not have it.
- Other sessions: UX (a row in the camp or forge screen), Narrative (names
  and lines), Art if a new house needs a picture.

**Size.** M (option A needs the simulator to learn smithing first; option B
uses the camp, which the simulator already plays).

**Decision.** What should late gold buy?
- A. Hammersmith work at rising prices: each further work on the same die
  costs more (for example x1.5 each time).
- **B. A fourth camp tier: three late upgrades of about 2,000 gold each;
  most runs can afford two. (Recommended:** a clear choice, measurable in
  the simulator today, reuses the camp screen.)
- C. Leave gold plentiful: a settled, rich late game is the reward.

---

## 3. Chapter goals with a chest tier, no clock

**For the player.** Each chapter shows three optional goals, such as "win a
fight in two rounds" or "beat the boss with no one knocked out". Each goal
you meet makes the chapter's reward chest better. Miss them and you lose
nothing. No timer, no streak.

**Numbers today.**
- A boss chest is never below Gold already (`loot_box.dart`, the boss
  floor). Above Gold there is only Void. So "+1 tier per goal" on the boss
  chest can add **one step at most**.
- How often a goal would be met, share of runs with at least one such win
  in the chapter (T, W4 base):

| Goal | ch4 | ch5 | ch6 | ch7 | ch8 |
|---|---|---|---|---|---|
| a win in 2 rounds or fewer | 17% | 11% | 7% | 1% | 1% |
| a win while owning a die that hits a foe's weakness | 94% | 92% | 99% | 35% | 73% |

- "Flawless" (no knock-out, no potion) is not measured: the simulator's
  hooks do not see it.

**Estimate.** A calculation; the simulator rolls no chests. At most one
better chest per chapter: up to 7 a run. A Void chest holds 3 slots, the
first a rare piece or a tome; a Gold chest 2 to 3. **No change to win rates
is expected** (a rare piece late rarely beats what is worn: 0.05 to 0.1 gear
changes per encounter in ch5 to ch8, EG992). The value is a target to aim
at. Goals must be picked per chapter so each is met in 30 to 70% of runs:
the table shows "swift" is out of reach late and "weakness" is free
mid-game.

**Risk.**
- Balance: low.
- Saves: a small new field (goals met this chapter); old saves start with
  none met.
- Other sessions: UX (a goal card), Narrative (goal lines).

**Size.** M.

**Decision.** Where should the goals' reward go?
- A. On the boss chest: Gold to Void, plus one slot per extra goal.
- **B. A separate chapter chest at the chapter's end, Wooden to Gold by
  goals met. (Recommended:** each goal counts, the boss chest stays as
  tuned, the existing chest floor rule does the work.)
- C. Not now.

---

## 4. One difference for each clone-skill group

**For the player.** Skills with different names and texts today do exactly
the same thing in a fight. After this, each does what its text says: a war
cry frightens, a mending touch stops poison.

**Numbers today.** Recomputed from `assets/gamedata/skills.json` (v1.1009):
skills whose fight fields are all equal (element, cost, damage, multiplier,
heal, status and every extra), ignoring text, rarity and who may learn it.
**15 groups, 34 skills.** In W4 base, these skills are **25% of all skill
cards offered** (922 of 3,638, T) and a third of the skills T takes; 99 of
100 T runs learn at least one.

| # | Group (shared numbers) | Proposed difference | Stays as is |
|---|---|---|---|
| 1 | `second_wind`, `mage_mana_shield` (heal 4) | `mage_mana_shield`: heal 2 and a 2-point shield (`blockAmount`), "a shell" | `second_wind` |
| 2 | `human_resolve`, `iron_will` (heal 3) | `human_resolve`: also clears Poison (`cleanse`), "shrug off pain" | `iron_will` (a fusion input) |
| 3 | `human_quick_study`, `guard_break` (+1, x1.2) | `guard_break`: ignores armour (`pierces`), "through defences" | `human_quick_study` |
| 4 | `human_diplomacy`, `power_strike` (+1, x1.0) | `human_diplomacy`: Weaken 2 turns (15%), flat damage +1 to 0, "a sharp word" | `power_strike` (a fusion input) |
| 5 | `orc_berserk_rage`, `mage_emberwife_coal`, `cleric_scorched_hymn` (Fire +2, x1.5) | `orc_berserk_rage`: builds momentum (`chargesMomentum`); `cleric_scorched_hymn`: Weaken 2 turns (15%) | `mage_emberwife_coal` |
| 6 | `voidkin_starless_gaze`, `mage_teleport_strike` (Void +2, x1.4) | `mage_teleport_strike`: ignores armour (`pierces`), "behind your foe" | `voidkin_starless_gaze` |
| 7 | `warrior_iron_stance`, `ranger_beast_bond`, `bulwark_stance`, `stone_resolve` (Earth heal 3) | `bulwark_stance`: a 3-point shield, no heal, "absorb the next hit"; `ranger_beast_bond`: heal 2 for the whole party (`healAll`); `stone_resolve`: clears Stun (`cleanse`), "refuse to be moved" | `warrior_iron_stance` |
| 8 | `rogue_poison_blade`, `ranger_moss_dirge` (Earth, Poison) | `ranger_moss_dirge`: poisons every foe (`statusAll`), x1.3 to x1.1, "the marsh against the hunted" | `rogue_poison_blade` |
| 9 | `rogue_shadow_clone`, `ranger_multi_shot` (Wind +2, x1.4) | `ranger_multi_shot`: half damage to a second foe (`splashShare`), "fan out" | `rogue_shadow_clone` |
| 10 | `cleric_revive_prayer`, `cleric_hallowed_sanctuary` (heal 6) | `cleric_hallowed_sanctuary` (an ascension): heals the whole party, "rises around you" | `cleric_revive_prayer` |
| 11 | `ranger_trap_set`, `rogue_tar_snare`, `warrior_rockfall` (Earth +2, x1.3, Stun) | `rogue_tar_snare`: Weaken 2 turns instead of Stun, "then their luck"; `warrior_rockfall`: 30% splash, "the ceiling gives way" | `ranger_trap_set` |
| 12 | `quick_heal`, `mending_touch` (Water heal 3) | `mending_touch`: also clears Poison, "the bleeding slows" | `quick_heal` |
| 13 | `warcry`, `inner_fire` (Fire +1, x1.3) | `warcry`: Weaken 2 turns (15%), flat damage +1 to 0, "unsettles foes" | `inner_fire` |
| 14 | `glass_reflection`, `shroud_reflection` (enemy only, mirror) | `shroud_reflection` (the final boss): also Weakens 1 turn | `glass_reflection` |
| 15 | `warrior_writ_banner`, `cleric_sentinel_verdict` (fusions, Fire +2, x1.5, heal 2) | `warrior_writ_banner`: its heal goes to the whole party, "steadies the line" | `cleric_sentinel_verdict` |

Every difference uses a keyword that exists in `skills.json` today. Where a
keyword adds power, a small cut pays for it (shown in the table).

**Estimate.** Each change is meant to be power-neutral, so **no win-rate
change is expected**. That has to be checked after the change, by
re-running the skill-power table of `combinations-review.md` (B976); not
done here.

**Risk.**
- Balance: medium; group 14 is a boss move (re-run `boss_balance_test`).
- Saves: none (same ids).
- Other sessions: Narrative (check each text matches the new effect, both
  languages), UX (the card already shows keywords), Art only if an icon
  must change.
- Groups 2, 4 and 13 hold fusion inputs: the fusion results do not change.

**Size.** M (data only, plus re-checks).

**Decision.** Should skills that read differently also play differently?
- **A. Yes: one difference per group, one member changed (the table).
  (Recommended:** text and fight agree, and the effect on power stays
  small.)
- B. Only the skills anyone can learn that differ in text alone (groups 12
  and 13, and `bulwark_stance` / `stone_resolve` in group 7); keep the race
  and profession versions as "the same move, in our way".
- C. Leave them alike.

---

## 5. The Void Banner gets its own slot

**For the player.** The Void Banner, the heirloom from chapter 1, stops
taking the body slot. You can wear the banner and a full gear set at once,
and the set bonus finally appears.

**Numbers today.**
- Runs owning a whole set: 18 T, 26 C (GS989). Runs **wearing** one: 0 of
  200 (GS989), 0 of 200 in W4 base.
- Every run wears the banner from chapter 1 to the end (W4: 100 of 100).
  Both sets have a body piece; the banner (attack 2, armour 2, +1 to every
  element) beats each of them.

**Estimate.** W4 banner world (the banner moved to a sixth slot in the
tables only):

| | T base | T banner | C base | C banner |
|---|---|---|---|---|
| Runs wearing a whole set | 0 | 0 | 0 | **13** |
| Fight tries won | 92.2% | 94.0% | 94.5% | 96.0% |
| Ch8 first-try wins | 83.0% | 85.1% | 84.7% | 88.2% |
| Boss tries won | 90.0% | 91.3% | 89.8% | 94.2% |
| Median gold at ch8 | 6,182 | 5,598 | 6,251 | 5,969 |

- The careful player wears a whole set in **13 runs** (Hollow Court 9,
  Harbourwatch 4). The typical player still does not: it wears a piece only
  when its plain attack plus armour is bigger, and the set pieces are small.
- Everyone gains one more worn piece: **about +2 points of win rate, +2 to
  +4 on chapter 8**. Noise on ch8 first try is about ±1.5 points.

**Risk.**
- Balance: low to medium (a free extra slot for every hero). The ch8 bosses
  get easier; check `boss_balance_test`.
- Saves: low. Worn gear is saved as a list of ids, and the slot comes from
  the item, so old saves load with the banner in its new slot and the body
  slot empty.
- Other sessions: UX (a sixth slot on the character sheet and inventory),
  Art (a slot glyph, maybe).
- Core: the slot list (`db_schema.dart`) and every rule that walks the five
  slots.

**Size.** S to M.

**Decision.** How should a set become wearable?
- **A. The banner gets its own slot. (Recommended:** the only option that
  lets the measured 13% of careful runs wear a set; the power rise is small
  and can be paid back on the banner's numbers if the bosses get too easy.)
- B. Move each set's body piece to another slot (legs or feet): no new slot,
  but the pieces then compete there.
- C. Leave it: sets are worn in pairs.

---

## 6. Chapter 7 pacing

**For the player.** Chapter 7 (the Lantern Throne) passes in two or three
fights, between a long chapter 6 and the finale. The climb to the end can
feel like it skips a step.

**Numbers today.**
- Encounters a run: ch6 10.2, **ch7 2.6**, ch8 6.3 (EG992). W4: ch7 2.9 T,
  2.6 C.
- Spread (T, W4): 1 fight in 5 runs, **2 in 50**, 3 in 23, 5 or more in 16
  (the side quests).
- Where the fights are (T, W4, per 100 runs): `7400` (the cove) 111, the
  Lantern Hall duel `7520_tallis` 72 (`_morrow` 17, `_vane` 11), the Houses
  `7510_*` about 76 in all.
- Ch7 brings 1.1 level-ups (EG992); heroes enter ch7 at level 20.5 and ch8 at
  21.5 (W4 medians). Ch7 first-try wins 93%; ch8 83% (W4 T).
- The roadmap calls chapter 7 a story campaign with one main quest and a
  quest goal of 1 (`docs/chapter-flow-roadmap.md`): it may be short on
  purpose.

**What Core would measure.** Narrative owns the story graph; Core measures,
before and after any change Narrative makes:
1. Encounters, level-ups and gold in ch7, by path (which House, which
   claimant).
2. Level and gear at the first ch8 fight.
3. Ch8 first-try wins and the boss bands. A level makes enemies grow too
   (16% health a level, against 12% for heroes), so **more ch7 fights do not
   surely make ch8 easier**; it has to be run.
4. Big changes per encounter in ch7 (0.08 today).

**Estimate.** At one level every 3.2 encounters (EG992), 3 more ch7 fights
would add about 1 level before ch8. Its effect on ch8 cannot be guessed (see
point 3); Core would run W4 again on Narrative's branch.

**Risk.** Low for Core. The story work is Narrative's (new scenes in
`Cleaned_Narrative_DAG.json`, English and French); a new fight needs a foe
from Core.

**Size.** S for Core (a batch and a page); M for Narrative.

**Decision.** Is chapter 7 meant to be short?
- A. Yes: leave it, the throne story is the draw.
- **B. Measure first: Core runs the four checks above, then the user and
  Narrative decide on one or two more fights. (Recommended:** cheap, and it
  shows whether a longer ch7 helps ch8 at all.)
- C. Add a road champion on the sail to Candlehold now.

---

## What could not be measured

- **Skill tiers** (brief 1): the simulator spends no essence and has no
  tiers; the rank-up effect is a calculation.
- **Hammersmith work** (brief 2): the simulator never smiths, so real late
  gold is probably lower than the 6,200 it reports.
- **Chests and "flawless"** (brief 3): the simulator rolls no chests and its
  hooks do not see knock-outs or potions per fight.
- **Clone-skill power** (brief 4): needs B976's skill-power table re-run
  after the change.
- **The banner slot** (brief 5) was tried as a sixth slot in the
  simulator's tables only; the game's screens and slot list were not
  changed.
