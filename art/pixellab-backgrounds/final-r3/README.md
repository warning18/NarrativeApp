# Backgrounds round 3: the user's picks, staged for UX-2 (180x320, palette PNG8, 24 colours, no figures, no text)
Nothing wired. File = pick (`picks.json` has the seeds).
## Tower (`lib/screens/tower/tower_backdrop.dart`: today one picture a band; add one for the special floors)
| File | Where |
|---|---|
| `tower_boss10.png` | floor 10's floor screen and its fight (the Inquisition legate) |
| `tower_boss20.png` | floor 20 (the claimant, Morrow) |
| `tower_boss30.png` | floor 30 (the void sovereign) |
| `tower_ward5.png` | warden floor 5 (floor screen and fight) |
| `tower_ward15.png` | warden floor 15 |
| `tower_ward25.png` | warden floor 25 |
| `tower_win.png` | `tower_end_screen.dart`, a won run |
| `tower_lose.png` | `tower_end_screen.dart`, a lost run |
Ordinary floors keep `assets/visuals/tower/tower_band1..3.png`. Draw cover-fit, nearest neighbour, with the page veil as `TowerBackdrop` does today (the plates are mostly dark in the middle for the UI text).
## Fight stages (`FightStage` in `lib/combat/field_anomaly.dart`, drawn by `lib/widgets/fight_pixel_stage.dart`)
| File | FightStage | How |
|---|---|---|
| `fight_fields.png` | `fields` (and the temperate pool's open country) | art from the horizon down; the code keeps the sky (sun, moon, stars, hour tint) above it |
| `fight_ford.png` | `ford` | full-bleed or art below the horizon, as the stage's code does |
| `fight_burnt.png` | `burntFields` | art from the horizon down, code sky |
| `fight_cliffs.png` | `cliffs` | art from the horizon down, code sky |
| `fight_terraces.png` | `terraces` | full-bleed |
| `fight_reeds.png` | `reeds` | full-bleed, the hour veil over it |
| `fight_hall.png` | `hall` | full-bleed (inside a building), the hour veil over it |
The fight area is the lower 45%: the ground in each plate is empty. As with the first five (`art/pixellab-backgrounds/fight/picks.json`), weather, anomalies and stars stay code over the picture.
