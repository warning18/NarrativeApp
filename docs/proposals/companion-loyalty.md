# Outline: companion loyalty scenes (parked, for a pitch)

Narrative, for the manager. **Outline only**: nothing is written, and the user
has parked this ("later, needs a Core trigger"). This page says what each scene
would be and exactly what Core would have to provide, so it can be pitched in
one read.

## The idea in one line

When a companion reaches **Devoted** (approval 12 or more, `devotedApproval`),
the camp offers one scene about *them*: the thing behind their `warnLine` and
`leaveLine`, told from the player's side. Eight companions, eight scenes.
Each ends in a small choice that records how the player answered, so the
companion's later remarks and the epilogues can read it.

## What exists today

- `approval` per recruited ally, tiers `estranged` (≤ −12), `wary`, `neutral`,
  `friendly` (5), `devoted` (12); a devoted line, a warning line and a leave
  line per companion (`companions.json`), and reactions to deeds
  (`companion_remarks.json`).
- Story choices can be shown or hidden by **flags** only (`showIfFlags`,
  `hideIfFlags`). No choice can ask "is this companion devoted?" or "is this
  companion in the roster?".

So the scenes need two small things from Core, below. Everything else is
Narrative's own files.

## What Core would provide (the triggers)

| # | Need | Shape | Why |
|---|---|---|---|
| 1 | **A flag when a companion first becomes Devoted** | `devoted_<companionId>`, set once, in the same place `approvalAfter` crosses `devotedApproval` (`approval.dart` / `applyChoiceEffects`). | the camp scene hangs off it with `showIfFlags` (no engine change for the story) |
| 2 | **A flag for "this companion is still with the party"** | `ally_<companionId>` set on recruit, cleared on leave or loss (`loseAlly`); or a choice field `showIfAlly: "kelda"`. | a companion who left must not get a scene they can't be in |
| 3 | **(optional) a small reward hook** | a choice can add `approvalMods` to its own companion (it already can, `approvalMods`) and name a title or a die face to unlock (Core's call). | the scene should pay off, not only read well |
| 4 | **(for QA) a way for the simulator to reach Devoted** | the autoplay policy chooses deeds a companion likes until a flag is set, or Edit Mode can set `devoted_*`. | `sim_coverage_test` fails a scene nobody can reach |

With 1 and 2, each scene is an ordinary story node and one ordinary choice on
the camp node (the camp page already lists a camp node's non-main choices, as
`7800` does). Nothing else in the engine changes.

## The eight scenes

Each is a short scene (about 200 words in English and French) with two or
three choices of 55 characters or fewer. The narrator is the player, in the
first person, as everywhere. The *flags* written are the ones later scenes or
remarks read.

| Companion | Scene (working title) | What it is | The choice is about | Flag written |
|---|---|---|---|---|
| **Kelda** (dwarf, warrior) | "The gate she did not hold" | her unit's last seal reaches the camp; she asks to bury the tags at the palisade | whether to hold the camp's gate with her the next night | `kelda_gate_held` / `kelda_gate_left` |
| **Sable** (human, rogue) | "The last marker" | she lays her unpaid debts on the table and bets one on you | accept the wager, or tear the marker up | `sable_marker_kept` / `sable_marker_torn` |
| **Maren** (human, cleric) | "Penance, counted" | she finds her own name on an Inquisition roll | read the names aloud with her, or burn the page | `maren_names_read` / `maren_roll_burned` |
| **Liora** (elf, ranger) | "The long watch" | a night on the camp's roof-post; she teaches you to see what she sees | stay up with her, or sleep and trust her | `liora_watch_shared` / `liora_watch_left` |
| **Vess** (voidkin, mage) | "The quiet" | the Void speaks your name through her in the dark | answer it, or hold her hand until it stops | `vess_voice_answered` / `vess_voice_stilled` |
| **Grosh** (orc, warrior) | "What the coin is for" | he finally says what he is saving for | pay what he lacks, or tell him to keep it | `grosh_debt_paid` / `grosh_debt_kept` |
| **Tobin** (dwarf, cleric) | "The last candle" | a letter from the choir he left; he is asked to come home | send him with your blessing, or ask him to stay | `tobin_letter_sent` / `tobin_stays` |
| **Malrik** (orc, rogue) | "The cut" | he hands over his private account book, "an investment report" | read it, and what you do with the line about you | `malrik_book_read` / `malrik_book_shut` |

The two flags per scene are read once each (a companion remark, an epilogue
line, or a gate on the camp tour), so nothing is set unread (the story rules
require it).

## Writing rules to keep

- Choices of 55 characters or fewer; every flag set is read somewhere.
- Both languages for every string; French in the plain «vous»; typography
  as the lint expects (curly apostrophes, NBSP before `: ; ! ?`).
- Each scene is on a camp node (`cove_camp`), with the mood tags that fit the
  scene (`tender`, `mournful`, `uncanny`, `bitter` and so on).
- The companions' voices stay as written in `companions.json`; the scene
  explains the lines, it does not contradict them.

## Cost and risks

- **Narrative:** 8 scenes × 2 languages, the eight pairs of flag reads, and
  eight lines in the camp node's choices. About one session of writing.
- **Core:** triggers 1 and 2 are a few lines each, plus the simulator hook (4).
- **QA:** L2 (a gate on save data, new scenes on a shared camp node); old
  saves: a companion already Devoted when the update arrives would get the
  flag on the next approval change, or Core sets it on load.
- **Risk:** a companion reaching Devoted late (chapter 7 or 8) would meet a
  scene about a past that has been quiet for a long time; the scenes are
  written to stand outside the chapter order for that reason.

## Questions for the user when this is unparked

1. All eight, or the four that join earliest (Kelda, Sable, Liora, Vess) first?
2. Should a scene be replayable? (A flag hides it after the first time.)
3. A reward for the first answer (a title, a die face), or the scene is the reward?
