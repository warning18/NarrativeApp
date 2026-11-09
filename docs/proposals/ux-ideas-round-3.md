# UX ideas, round 3 (UX-2)

New items only, on how things look, move and read. Removing, simplifying and
optimizing first. Nothing here is built; every count below was taken from
`main` (v1.863) with `grep`/`wc`, so the Manager can check it. Not repeated:
the held items (shared palette file, 11 px text, QA 360 px nightly, PixelLab)
and what is merged. Ranked, my recommendation first.

| # | Idea | Removes | Size | Risk | The user notices |
|---|---|---|---|---|---|
| 1 | Cut the fonts to the letters the game uses | ~600 KB of 816 KB | S | low | faster in-app update, nothing else |
| 2 | One panel, one tag | ~500 lines, 3 identical `_Tag`s | M | low | tags and cards share corners and padding |
| 3 | One pick-one frame | 4 hand-built "one of three" views | M | med | the offers read the same everywhere |
| 4 | The spoils chest has one list | ~110 lines | S | low | tap a drop once, in one place |
| 5 | One dialog frame, one sheet frame | 44 dialogs, 56 sheets built by hand | M | low | same buttons, same spacing |
| 6 | "Remove animations" honoured everywhere | corrected: 4 small gaps, not 16 files (built, 1.870) | S | low | calmer screens |
| 7 | No fractional `Opacity` in lists | 89 `Opacity(` widgets, measured first | S | low | smoother scroll on the oldest phone |

---

## 1. Cut the fonts to the letters the game uses (recommended)

**What.** `assets/fonts/` is 816 KB: Spectral (Regular, Medium, Italic) 509 KB,
IM Fell English SC 184 KB, Pixelify Sans (two weights) 100 KB. They ship whole,
with Cyrillic, Greek, Vietnamese and thousands of symbols. The game's text is
English and French. A scan of all gamedata, the story DAG and
`app_strings.dart` finds only **11 characters above Latin-1** (`’ “ ” œ — … −
Œ ‘ – →`). Subset each font to Latin-1 plus Latin Extended-A plus that
punctuation (a player-typed name keeps its accents), with `pyftsubset`
(fonttools), run by a small `tool/subset_fonts.py` so it can be redone.

**Why.** Every release the in-app updater downloads the whole APK; the fonts
are about 600 KB of it for glyphs that are never drawn. It is also the safest
change in this list: no layout, no widget.

**Size / risk.** S. Low: the risk is a missing glyph, which a test closes: draw
every distinct character of the gamedata and the strings in each family and
fail if one falls back to the system font. fonttools is not installed in this
container (`pip install fonttools`, registries are reachable).

**Sketch.** None: no screen changes.

---

## 2. One panel, one tag

**What.** There is no shared panel. `ink.seam` borders are hand-built **97
times in 43 files**; corner radii in screens and widgets are 2, 3, 4, 6, 8, 9,
10, 12, 14 and 16 px (counts: 8 px 78x, 10 px 66x, 4 px 64x, 6 px 48x, 12 px
39x). Chips and tags are about **27 classes** (`InkTag`, `ChoiceTagChip`,
`TierChip`, `SignRarityChip`, `PriceChip`, `_PixelChip`, `_Badge`, `_BonusChip`,
`_SkillChip`...), and three private **`_Tag`** classes do the same thing three
ways (offer_dialog: padding 6x1, radius 8, filled; harbor_screen: 7x1, radius
8, outline only; origin_stories: 10x4, radius 20, icon). My own
`TowerPanel`/`TowerLabel` (v1.847) is a fourth copy of the panel.

Proposal: `InkPanel(lit, dim, onTap, padding)` in `lib/widgets/` (surface, seam,
one radius, gold edge when lit: today's `TowerPanel`, promoted) and one `InkTag`
with three looks (outline, filled, icon). Radii become three: 4, 8, 12. Migrate
screen by screen, the three `_Tag`s and `TowerPanel` first (they are
identical), picture-tested.

**Why.** Less code to read and to keep in step; a card edited in one place
changes everywhere. Two cards on one screen no longer have different corners.

**Size / risk.** M (a dozen files first, the rest over later PRs). Low: a
corner of 2 px is hard to see; the pictures show any real change.

**Sketch.**
```
today   [ Boon ]  ( Gold )  < Skill >  [E] Mage          four shapes, four paddings
after   ( Boon )  ( Gold )  ( Skill )  ( Mage )          one tag, three looks
today   card r=10 | card r=8 | sheet r=12 | chip r=20    corners disagree
after   card r=8 everywhere, sheet r=12, tag r=4
```

---

## 3. One pick-one frame

**What.** "Take one of N" is built by hand at least four times: the story's
offer dialog (`_OfferBanner` + `_OfferHall`, 1,393-line file), the Level Up's
stat pick (`stat_pick_picker.dart`, its own private `_OfferBanner`), the fight's
`FightPickCard`, and the Tower's boon cards (`tower_offer_view.dart`, mine).
Each draws the card, the ring on the one in hand, the dim on the others, the
Take button and the "leave" link its own way. Proposal: one `PickOne` (cards,
held index, Take, optional leave line) that the four feed; each keeps its own
card body. The Tower's boon cards move first (they were the last to be built,
and I own them), then the Level Up, then the story offers.

**Why.** The user has just been through the Tower's creation, spoils and Level
Up; the same choice looks different in each place. One frame = one habit.

**Size / risk.** M. Medium: the story offer dialog is the oldest and the most
used file; do it last and behind the pictures.

**Sketch.**
```
+--------------------------------+      one frame:
| Floor 5 cleared                |      title
| Choose one reward              |      hint
| [*Last Watch Stand   Skill  *] |      held card: gold ring + Take
| [ Gambler Die          Die   ] |      others dimmed
| [ Rally the Line      Spell  ] |
|        Leave them all          |      optional leave line
+--------------------------------+
```

---

## 4. The spoils chest has one list

**What.** After a fight the chest dialog first lets the player flip the face-down
slots; while some are still down it shows a list of the drops with their own
Equip/Drink switches (`_buildSpoilsList`, `_buildSpoilsRow`, `_showDetails`,
~110 lines, `spoils_chest_dialog.dart`). Once all are up it switches to the full
`LootSheet`, which shows the same drops with the same switches. The one call site
(`fight_rewards.dart:206`) always passes the sheet. So the use-now logic lives
twice (`_actionFor`, `_toggleEquip`, `_toggleDrink` feed both). Proposal: slots
flip as today, the list under them goes, tapping a flipped slot only shows its
name and picture; Equip/Drink exist only on the sheet.

**Why.** Fewer places for the same rule; the sheet is the one the user has been
shown and tested; the flip stays the fun part.

**Size / risk.** S. Low: `spoils_chest_test.dart` and `loot_sheet_wiring_test.dart` cover the
dialog; the ones that tap the in-between list move to the sheet, none is
weakened.

**Sketch.**
```
today   chest -> flip slots -> [ list with switches ] -> sheet with switches
after   chest -> flip slots ----------------------------> sheet with switches
```

---

## 5. One dialog frame, one sheet frame

**What.** `AlertDialog(` is written 44 times, `showModalBottomSheet` 56 times,
`TextButton(` 83 times, with the Cancel/OK pair built by hand in about 22 of
them. Proposal: `showInkConfirm(context, title, body, yes, danger)` and a
`showInkSheet(context, child)` (handle, padding, scroll, safe area). The
`LootSheet` I just gave a `showHandle` flag is the first user.

**Why.** Same spacing and button order everywhere; a destructive confirm (leave
the Tower, abandon a run) looks dangerous in one way. A few confirms that
protect nothing could become an Undo snackbar, for the Manager to choose
screen by screen.

**Size / risk.** M, in slices of five dialogs per PR. Low.

**Sketch.**
```
today   Leave the Tower?            today   Leave the Tower?
        [Cancel]        [Leave]             [Leave]        [Cancel]   (order differs per screen)
after   Leave the Tower?   (Cancel left, the act right, red when it destroys)
```

---

## 6. "Remove animations" honoured everywhere (corrected, built as 1.870)

**Correction.** This note first said 16 of 41 animated files ignore the
platform setting. That count was wrong: the grep missed
`MediaQuery.maybeDisableAnimationsOf`, the `still:` parameters the parents pass
and the `reduceMotion` fields. About 60 places read the setting, the page
transitions among them. The real gaps were four small spots (the city chart's
breath and zooms, the map sky's fade-in, a stat's pulse, the story cards'
stagger), fixed in 1.870 with one 25-line helper (`lib/widgets/motion.dart`)
and a test. The aim sweep and the timed choice's countdown are play, not
decoration, and keep running. A "Calm" switch in Settings is not needed.

---

## 7. No fractional `Opacity` in lists (measure first)

**What.** `Opacity(` appears **89 times**. A value between 0 and 1 makes the
framework draw the child into an offscreen layer. Where it is a "dim" or
"locked" state of a card in a list (my `TowerPanel(dim)`, the locked
`ChoiceCard` of the Tower creation, skill nodes), a scroll repeats that layer
for each such card. Proposal: first capture a timeline of the Skills tree and
the creation list on the oldest phone the user has; if a frame cost shows,
replace the dim with a colour alpha (`color.withValues(alpha)`) on the text and
surface, no layer.

**Why.** Smoother scroll for the same picture; nothing is removed unless the
timeline says it matters, which is why it is last.

**Size / risk.** S for the capture, S per widget. Low.

**Sketch.** None: same picture.

---

## Order I would do them in

1 (a quick win, no look change), then 4 (small, removes duplicate logic), then 2
(the base 3 and 5 stand on), then 3, 5; 6 is done (and smaller than said); 7 only after a measured frame.
Nothing here needs another session's files except 3's story offer dialog and
4's `fight_rewards.dart` call site (Core owns the fight screens): I would send
Core a note before touching those two.
