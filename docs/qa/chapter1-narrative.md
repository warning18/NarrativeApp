# Chapter 1 — narrative review (Narrative session)

Read as a player, EN and FR, from the intro lines through Alster, the Lark,
the Waste, `1150_vica`, the White Wells and the origin endings (`1000`–`1002`).
52 chapter-1 scenes, version 1.606. Nothing is fixed in this note; the user
ranks the findings first. Severity: **B** blocks play, **C** contradiction,
**W** wording, **K** cleanup. Fix size: S (one string or flag), M (a scene),
L (several scenes).

## Clean

- No dog, hound, whistle or rabid in any chapter-1 text, flag, remark or
  narration. The lantern reads the same in 270, 300, 820, 823, 891.
- Every flag set in chapter 1 is read somewhere; no orphans.
- EN/FR parity on all 52 scenes, every choice and callback. FR typography
  (non-breaking space before `: ; ! ?`, inside « », curly apostrophes) is clean.
- No scene offers more than 4 choices; the 5-open-quests rule holds at the
  Alster hub.
- Vess is chapter 2 only; no chapter-1 line promises her.

## Findings

| # | Scene | Sev | Size | What the player sees |
|---|---|---|---|---|
| 1 | `0` → `100_dice` | W | S | Two single-"Continue" pages in a row: the long prologue, then the dice page. Pacing drags before the first real choice. Merge or give `0` a real choice. |
| 2 | `896_failed`, `897_failed`, `898_failed` → `960_lift` | W | S | Each failure page ends on a lone Continue into `960_lift`, which is itself a lone-Continue page turn. Two in a row. |
| 3 | `0` choice | W | S | EN "Choose who you are..." uses three dots; the rest of the game uses "…". |
| 4 | `1150_vica` | C | S | No `lysa_survived` callback, though Lysa walks with the hero through 1100–1130 and `1200` has her. She vanishes for one scene. |
| 5 | `1150_vica` | W | S | `ui_theme: docks`; the other desert scenes use `desert`. Wrong palette for the arrival. |
| 6 | Tutorial `tut_story_1` vs `1150_vica` | C | M | Alster's tutorial guide already says "Woof! I'm Vica" (`tut_guide_default_name`), but the story only names her at 1150. A player who renamed the guide meets a different name later. Decide which one introduces her. |
| 7 | Intro `intro_line_4` vs scene `0` | W | S | The intro ends "decide who you are", then the long prologue comes before any choice. The promise lands late. |
| 8 | `260` / `261` | W | S | "Pay the toll (30 gold)" has no `goldMod`; the 30 gold is taken one page later at "Cross the bridge". The label says one thing and the wallet changes on the next card. |
| 9 | codex `biomes.json`, temperate fauna "Warhound / Chien de guerre" | C | S | "Bred by Inquisition dog-handlers; since the burning, a few run loose in the alleys." Contradicts the dog-free Alster and Vica's story. Text only; Core's file, Narrative's wording. |
| 10 | flags `hound_*` | K | S | Ids are misleading now that the dog is Vica (`vica_follow`, `vica_shared`, `vica_paid` exist). Only a rename of ids, no player impact. |

## For Core (numbers, not changed here)

- Gold curve: scene `110` pays +110, while `115` and `125` cost 30–40; the
  first hour feels rich, then flat. Worth a look against the shop prices.
- `260`/`261` split (finding 8) is a data shape question: put `goldMod` on the
  choice the label names.

## Suggested order

1. 4, 5, 3, 8 — one pass, all S, about ten lines.
2. 1, 2 — page-turn tidy, S, touches the sim pins.
3. 6, 7 — a decision for the user first (who names the dog, when).
4. 9, 10 — cleanup, any time.
