# PixelLab originals

Sprites the user made on pixellab.ai, kept here as exported. They are not bundled
with the app; UX crops or converts what the game uses into `assets/visuals/`.

Each character folder holds:
- `rotations/<direction>.png`: one 48 x 48 standing frame for each of 8 directions
  (low top-down view).
- `animations/Walking/<direction>/frame_000..007.png`: the walk cycle.
- `metadata.json`: PixelLab's export notes (prompt, size, frame list). Its paths use
  PixelLab's folder names, not the ids below.

## dominion/ (the Lantern Dominion's Inquisition)

| Folder | PixelLab name | Enemy id |
|---|---|---|
| `aurel_vane` | Inquisitor-General Aurel Vane | `aurel_vane` (chapter 1) |
| `inquisition_warden` | Inquisition Warden | `inquisition_warden` |
| `white_soldier` | White Soldier | `white_soldier` (east walk only) |
| `inquisition_soldier_02` | Inquisition Soldier_02 | `inquisition_soldier` or another rank |
| `inquisition_soldier_03` | Inquisition Soldier_03 | `inquisition_soldier` or another rank |

`inquisition_soldier_02` came with two walk sets: `Walking` (east) and a second
`walking` (east and west), renamed `Walking_2` so the folders don't collide on
case-insensitive disks.

## sewer/ (the Alster undercroft's vermin, "Big rat monster")

One PixelLab character group with three states, exported as one zip. Unlike the
dominion folders these are 60 x 60 px frames and a side view (not 48 x 48 low
top-down). `metadata.json` is the group's export note.

| Folder | PixelLab state | Enemy id | Notes |
|---|---|---|---|
| `rat` | Idle (the base rat) | `harbor_rat` (to confirm) | 8 directions, `Walking` east and west (8 frames) |
| `rat_matriarch` | A rat matriarch grown huge | `rat_matriarch` | 8 directions, `Walking` east and west; the body runs to the frame edges and is clipped there, see below |
| `plague_hound` | Plague Hound | `plague_hound` | 8 directions, no animation yet |

Not yet bundled: UX crops or converts what the game uses into `assets/visuals/`
(`lib/widgets/fight_sprites.dart` hard-codes 48 x 48 frames for enemies today, so
a 60 x 60 set needs a frame size per sprite). The matriarch needs a larger canvas
in PixelLab (set_canvas_size, free) before it is used.

## More enemies and people (PixelLab groups, one folder per group, one subfolder per state)

All 48 x 48, side view, 8 directions; some states carry a `Walking` set. Raw, not
bundled; UX crops the west idle into `assets/visuals/fighters/` when an enemy is wired.

| Folder | PixelLab group | Candidate enemy ids (state to confirm with a picture) |
|---|---|---|
| `wreck_scavenger` | City Wreck scavenger (4 states) | `wreck_scavenger` |
| `noble_bouncer` | The Noble Bouncer (3 states: Idle, "A looter who got to...", "Thiner man, no beard") | `den_bouncer`, `den_looter` |
| `sedge_returned` | Sedge of the Returned (2 states) | `mire_returned_sedge` (NPC `sedge_returned`) |
| `low_demon` | A low level demon | `demon_imp` |
| `low_angel` | A low level angel with blond hairs | `angel_sentinel` |
| `desert_bandit` | Bandit from the desert (6 clothes states, one a woman) | `street_bandit` and other bandits |
