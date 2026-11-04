# UX-2: a second round of improvements (a list, no code)

Only new items: nothing from `ux-2-improvements.md` or `ux-waves-3b-4-5.md`, merged or held. Ranked by value over effort.
Everything below was measured or read in the code on main at v1.751 (the numbers are given), not guessed. Nothing is built
until the Manager releases an item.

## The list

### 1. The fight is unplayable in landscape: the dice board is 1 px tall (S to lock, L to lay out)
- **What**: the app has no orientation lock (`setPreferredOrientations` is not called anywhere), and a phone turned sideways
  (640 x 360) gets a fight whose dice board is **1 px** tall (measured with the same setup as the #688 guard,
  `test/qa_fight_320_test.dart`, at 640 x 360). #688 fixed the portrait 320 x 568 case; a landscape phone has less height
  still. The shell has a landscape check (`qa_real_font_layout_test`: the bar and the tablet rail), the fight has none.
- **Options**: (a) keep the fight in portrait on phones while it is open (`SystemChrome.setPreferredOrientations` on the
  fight route, restored on exit; tablets, width at least 600, stay free): **S**, risk low (the restore on every exit path,
  one test); the user notices that turning the phone mid-fight no longer breaks it, and that the fight stays portrait.
  (b) a real landscape layout (the party on the left, the board in the middle, the foes on the right): **L**, risk medium,
  it is the screen with the most state. I recommend (a) now and (b) only if the user plays sideways.
- **Question for the Manager**: is landscape a supported way to play (the shell has a landscape rail), or only the
  tablet's? The answer picks (a) or (b). Not measured, to check the same way: the Journey and the reading page at 640 x 360.

### 2. Real-font 320 px / French / landscape checks for the screens that have none (S each, M for the set)
- **What**: `docs/qa/smoke-coverage.md` lists the screens with no real-font layout check: main menu, the shop screens, the
  port and the voyage screen, the Camp's other tabs, the bounty board, the Journey's step list and place sheets, the
  fight screen itself beyond its tips. #688 was found by QA's L3 on one of them, by hand. I add the UX-owned ones to
  `test/ux_phone_sweep_test.dart` (the harness is QA's), each at 360 x 740, 320 x 568 and 640 x 360, English and French,
  and fix what does not fit in the same PR (a layout-only fix, no text or number changes).
- **Why**: the cheapest way to find the next #688 before the user does. **Risk** low (a test, plus layout fixes that show
  up as failures). **The user notices**: nothing, until a small phone stops showing a clipped screen.
- QA owns the `qa_smoke_*` files; I would only touch my `ux_` one and tell QA which screens are covered.

### 3. Tap areas under 40 dp on the fight's icon tiles (S)
- **What**: from the code, the effect icon on a fighter's card (`FightEffectChip`) is a 22 px square with 5 px and 3 px
  of padding: a **27 x 25** tap area; the top strip's status tile (`FightStatusTile`) is 32 px plus padding: **38 x 37**.
  Material asks 48. The user's top-strip feedback was about space, and I made the tiles small; the cost is a tap that
  misses. Keep the look, widen the hit area only (a transparent `Padding` or `HitTestBehavior.opaque` box inside the
  neighbour's gap), at least 44 dp where the row's spacing allows, and pin it with a size test.
- **Risk** low (adjacent tiles overlap by a few px; the last one painted wins, which is what the eye expects).
  **The user notices**: a tap on the little icons lands the first time. **Size** S.

### 4. Tiny text: 41 places draw at 8 to 10 px (S to M)
- **What**: `grep` finds 41 `fontSize: 8/9/10` in `lib/`: 16 in the fight (`lib/screens/fight/`: the status badges, the
  card captions), 3 each in the clan compass, the ship battle panel and the politics screen, and a few in the city chart
  painter (UX main's, left out). The user's feedback has been about density. Raise each to 11 where the layout has room
  (a badge number may stay at 9 on its tile: a corner count is not prose) and say which stay and why; the 320 px /
  French sweep of item 2 is the guard.
- **Risk** medium (a longer label overflows: that is exactly what the sweep finds first). **The user notices**: the
  captions on the fight cards and the compass read without squinting. **Size** S for the fight, M for the rest.

### 5. A `RepaintBoundary` around the layers that repaint every frame (S, needs a capture to prove)
- **What**: 84 `CustomPaint` and 62 `AnimationController` in `lib/`, and only **7** `RepaintBoundary`
  (the Journey 3, the chart weather, the fight backdrop, the fight board, the side view). Not wrapped, and drawn on a
  clock: the combat VFX layer (`CombatVfxLayer`), the sea of the ship battle and the voyage (`sea_battlefield.dart`),
  the guide tour's overlay, the prologue's animation. Without a boundary, a layer that repaints each frame makes its
  whole parent repaint with it: during a fight's effects, the cards behind them.
- **Why not sure**: only a frame-time capture shows whether it matters on a cheap phone (it is item J of the first list;
  I still cannot run a device here). It changes no pixel, which a golden-free test can show (the same widget tree plus a
  boundary). **Risk** low. **The user notices** (if it matters): fewer dropped frames in a heavy fight or a sea battle.
  **Size** S. Do it with the capture, or on its own if the Manager prefers the safe default.

### 6. Splits, round 2: the five next-biggest files UX owns (S each, value low)
- `clans_politics_screen.dart` (1,705 lines), `offer_dialog.dart` (1,393), `race_profession_screen.dart` (1,289),
  `dice_loadout_screen.dart` (1,267), `expedition_screen.dart` (1,256); `voyage_screen.dart` and `sea_battlefield.dart`
  once #702 has merged (it touches `sea_battlefield.dart`). The same pure cut as #724 / #727 / #729, proven by the
  compiler and by the unchanged lines. **The user notices**: nothing. It is last because the first five splits already
  took the files that blocked other sessions; the rest are for reading and merging comfort only.
  Shared files (`dice_loadout_screen`, `expedition_screen`) need the usual check for an open PR first.

## Checked and dropped (so nobody checks again)
- **Image decode sizes** (`cacheWidth` on `Image.asset`): 16 sites, none with it, but every one is a small pixel sprite or
  icon; the only big assets are the sea beasts' pictures, which #702 turns into WebP. Nothing to gain.
- **Fonts**: 9 files, about 0.8 MB, every family and weight declared is used (`InkFonts`). Nothing to remove.
- **`saltmouth_stub.json`** (185 KB): looks unused, but `city_chart_screen.dart` and seven tests load it. It is UX main's
  chart area anyway.
- **Dev tools in Settings** (the simulator button): shown only in edit mode. Players do not see it.
- **`_OfferBanner` defined twice** (`offer_dialog.dart` and `stat_pick_picker.dart`): different fields and looks, not a
  duplicate. `_Tag` (3 copies) was settled in the first list (3b-1: not duplicates).
- **`.repeat()` and reduced motion**: already item 5-2 of `ux-waves-3b-4-5.md`.

## Summary for the Manager
1. **Landscape fight: the dice board is 1 px at 640 x 360** (measured). Lock the fight to portrait on phones (S) or lay it
   out sideways (L): your call on whether landscape is a way to play.
2. 320 / French / landscape checks for the screens with no real-font check (main menu, shops, port, voyage, Camp tabs,
   bounty board, Journey steps, the whole fight screen), fixing what does not fit: finds the next #688 before the user.
3. Tap areas: the fight's effect icons are 27 x 25 and its status tiles 38 x 37; widen the hit area only (S).
4. 41 places draw text at 8 to 10 px, 16 of them in the fight; raise to 11 where it fits (S to M, paired with item 2).
5. `RepaintBoundary` on the layers that repaint every frame (7 boundaries for 84 painters; VFX, sea, guide tour): S, but it
   wants the capture of the first list's J to prove it matters. Splits round 2 is last: value low.
