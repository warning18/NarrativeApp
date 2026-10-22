# The land-crossing events, in full (Narrative, for wave 16 item 3)

30 new events in `assets/gamedata/land_events.json`, EN and FR, in the shape the desert events use (`choices` with `check` and `dc`, a `fight`, or a sure `outcome`; `success`, `fail` and `outcome` with `healthPct`, `gold`, `days`, `note`, `note_fr`). Second person, as the existing events. No route uses them yet.

## Ruler events (18)
One event for each main clan and each standing band: `ruler_<clan>_<friend|neutral|hostile>`. Each carries two extra keys, **`ruler`** (the clan id: `dominion`, `vigil`, `compact`, `mire`, `crows`, `penitents`) and **`band`** (`friend` for Friend and up, `neutral`, `hostile` for Hostile and down). `LandEvent.fromJson` ignores keys it does not know, so they load as they are; the route's draw is Core's: pick the ruler's three-band set by `ruler`, then the event whose `band` matches the standing. Premises are those of `wave16-ruler-events.md`: the Writ toll (Dominion), the Watch checkpoint (Vigil), the forge-cart (Compact), the reed guide (Mire), the marked crate (Crows), the name wall (Penitents).

## Biome events (12)
Frost (`frost_cairn`, `frost_rime_fall`, `frost_hound_track`, `frost_bell`), fen (`fen_lantern`, `fen_mud`, `fen_cart`, `fen_child`) and sea cliffs (`cliff_wrecker_lamp`, `cliff_salt_wind`, `cliff_gulls`, `cliff_tide_stair`). Plain and weighted by the route's `events` map like the desert's. Chapter 7's route should draw only `cliff_salt_wind` and `cliff_tide_stair`, which both have a free way round; none of the 12 costs more than 14% health at a failed check.

## Numbers are drafts
`healthPct`, `gold`, `days` and `dc` follow the existing events' range (DC 11 to 13, health -2 to -14%, gold up to 30); Core sets them against the chapter. A fight uses `street_bandit` (Crows hostile) and `plague_hound` (frost hound track), both existing enemies. Tests: land_crossing, french_data_lint and qa_harbour_crossing pass with the events in the file.
