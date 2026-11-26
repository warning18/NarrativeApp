> **PARKED FOR LATER (the user, 26 November 2026: "keep these for later").** The cut-paper Tower set described here (the 14 plates, snapped | raw) is not rejected and not in the game for now: today's `tower_ink` backgrounds (B) stay. Keep all files.

# Hand-off to UX: Tower plates, tarot vignettes, heads (Art, 25 November 2026)

All three are approved by the user. Files only; nothing in the game was changed. Copy them in; the names match what the code already looks for.

## 1. The 14 Tower plates (cut paper)
`art/pixellab-cutpaper/tower/handoff/tower_<id>.png` -> `assets/visuals/tower/tower_<id>.png` (replace). Ids: band1, band2, band3, bargain, boss10, boss20, boss30, lose, parley, shop, ward5, ward15, ward25, win. **180 x 320, PNG8**, as today's plates.
Palette (exactly five colours): ink 090A14, dark 28283A, paper shadow C9C2A6, paper E7E1CD, deep red A53030 (banners, pools, a lantern glow, a sigil). No orange, no gold, no text. Sheet: `docs/art/boards/cutpaper-tower-plates-text.png`.

## 2. The 14 tarot vignettes (cut paper)
`art/pixellab-cutpaper/tarot/handoff/<name>.png` -> `assets/visuals/tower_cards/` (the folder is declared in `pubspec.yaml`), keys of `towerCardArt`: `skill:Fire` skill_fire, `skill:Earth` skill_earth, `skill:Wind` skill_wind, `skill:Water` skill_water, `skill:Ice` skill_ice, `skill:Light` skill_light, `skill:Electricity` skill_electricity, `skill:Void` skill_void, `skill:None` skill_none, `die` die, `spell:Damage` spell_damage, `spell:Ward` spell_ward, `spell:Heal` spell_heal, `spell:Hex` spell_hex. **96 x 64, PNG8**, same five colours as the plates. Sheet: `docs/art/boards/cutpaper-tarot-final.png`. (The earlier ink set is in `art/pixellab-tarot/final/tower_cards/`; the seals, the frame and the stamp are there too and are still the ones to use.)

## 3. The 11 heads, cropped from full characters
`art/pixellab-heads-crops/handoff/<id>.png` -> `assets/visuals/heads/<id>.png` (replace the hat blob): cultist_acolyte, dock_overseer, hollow_reflection, inquisition_auxiliary, inquisition_soldier, slum_thug, hollow_court_zealot (7, cropped from the PixelLab characters' west frames, the top 36 %), and inquisition_warden, iron_golem, street_bandit, void_sovereign (4, cropped from the fighter sprites). Native pixels, PNG8 with transparency, **13 to 28 px wide**: scale them as the current heads are (the current ones are 2x of a native crop, so draw these at 2x as well). Sheet: `docs/art/boards/heads-from-characters.png`. The other 7 faceless heads (horn_taker, frost_kept_giant, smuggler_captain, strand_colossus, void_wisp, void_stalker, void_manifestation) keep their hat blob: there is no full character for them yet.

## Not in this hand-off
The icons (ink + one spot, 32 px) are still a test: `docs/art/boards/icons-ink-spot-test2.png`; the dice and banners in cut paper are staged but not approved for wiring.
