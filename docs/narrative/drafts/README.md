# Drafts for the story review's held proposals

Written by the Narrative session for P3 and P4 of `docs/narrative/story-review.md`.
**Nothing here is wired.** Each draft is a scene or a text change ready to paste, with the
node id, where it slots in, what it reads and sets, and the French. When the user approves,
Narrative pastes the DAG and NPC changes in one text PR; Core adds the scene ids to the camp
list and confirms the gates.

Files:
- `p4-mire-and-vigil.md`: two short scenes and two NPC moves, so the Mire Courts and the Grey Vigil have a face before their intrigues begin.
- `p3-companion-second-beats.md`: one camp scene per companion for chapter 7 (eight), plus Vica's follow-up and loyalty scenes.

## How a camp scene is wired (checked in the data)

The eight `loyal_*` scenes are the model (`assets/Cleaned_Narrative_DAG.json`):

- `campErrand: true` and `campErrandText` / `campErrandText_fr` (the button's label in the camp).
- `showIfFlags` lists flags that must **all** be held; `hideIfFlags` hides the scene once **any** is held (the scene's own outcome flags).
- `location` is `cove_camp`; the scene's choices return to the camp with `next_id` `4999_camp` (chapter 4) or the camp node of the chapter.
- The scene id must be in the Cove Camp landmark's `scenes` list in `lib/data/world_map.dart` (Core), next to `loyal_kelda` and the rest.
- A choice's `flagsToAdd` is where the outcome is recorded; `flag_callbacks` on a later node reads it.

Two conventions the drafts use:
- **One flag for "the loyalty scene is done".** The loyalty choices today set one of two flags (`kelda_gate_held` / `kelda_gate_left`), and `showIfFlags` is AND. Each second beat needs "either", so the draft adds `<companion>_loyal_done` to **both** choices of the loyalty scene (a one-line edit each, listed with the draft).
- **The second beat opens in chapter 7.** It is gated on `banner_five` (set when the fifth piece is taken, `7300`), so it appears at the chapter 7 camp (`7400`) and not before.

French typography is applied in the drafts (no-break space before `:`, `;`, `!`, `?` and inside « »), so the text can be pasted as it stands.
