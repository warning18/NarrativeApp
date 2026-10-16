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
