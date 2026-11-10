# UX ideas, round 4 (UX-2)

New items only, on how things look, move and read. Removing, simplifying and
optimizing first. Nothing is built; every count below was taken from `main`
(v1.875) with `grep`, and I re-read the lines before writing a claim (round 3
had two wrong counts, both corrected). Not repeated: rounds 1 to 3, what is
merged (fonts, motion, spoils, panels, dialogs, sheets), and what is held or
in hand (the tag chip, the shared palette file, 11 px text, QA's 360 px
nightly, PixelLab). Ranked, my recommendation first.

| # | Idea | Removes | Size | Risk | The user notices |
|---|---|---|---|---|---|
| 1 | One loading state | 34 identical spinner blocks | S | low | the same, in the game's colours, everywhere |
| 2 | One icon language | 359 Material glyphs, 4 of them 40% of the uses | M | low | locks, arrows and ticks match the pixel art |
| 3 | Motion tokens | 50 hand-picked durations | M | low-med | the app moves at one pace |
| 4 | Long lists build their rows lazily | 80 eager lists (measure first) | M | med | long tabs open faster |
| 5 | A spacing scale | ~260 off-scale gaps | M | med | nothing, but screens line up |

---

## 1. One loading state (recommended)

**What.** `Center(child: CircularProgressIndicator())` is written out **34
times** (32 of them `const`, character for character the same), 49 spinners in
33 files in all. It is the stock Material ring in the theme's primary colour,
the one part of the screen that is not Stitched Ink. Proposal: `InkLoading()`
(`lib/widgets/ink_loading.dart`), a ring in `ink.gold` on the page colour with
a short line under it for the slow ones ("Reading the map..."). The 34 become one
call; the 15 spinners inside buttons and rows stay as they are.

**Why.** Every screen that waits on game data shows it first. One place to
restyle, and a word of reassurance when the wait is long.

**Size / risk.** S (a sed for the 34, one widget). Low: pictures at 412 EN
and 360 FR of three screens' loading frames.

**Sketch.**
```
today  [         ]        after  [         ]
       [   (o)   ]  grey ring    [   (o)   ]  gold ring, the page's own ground
       [         ]               [ Reading...]  only when it takes > 1 s
```

---

## 2. One icon language

**What.** The game draws its own pixel icons (62 `PixelIcon` uses and 38 item
icons), yet the interface is held together by **446 Material icon uses in 359
different glyphs**, thin outlines in a different style: `chevron_right` 42,
`lock_outline` 36, `auto_awesome` 20, `local_fire_department_outlined` 18,
`check_circle` 18, `check` 17, `casino_outlined` 17, `flag_outlined` 15. Those
eight are about 190 uses (43%). Proposal: draw the eight as 16 x 16 pixel
glyphs with the existing generators (`tool/gen_*.py`, `png8.py`), in one
`InkIcon.chevron/lock/check/...` widget with the colour taken from the text; the
rest stay Material until they are asked for.

**Why.** The pad lock on a shut way, the chevron on every row and the tick on
every done thing are the most seen marks; they are the ones that look
borrowed.

**Size / risk.** M (eight glyphs, one widget, a codemod for the 190 uses). Low,
but a look change on every screen: pictures first, per family, and it needs the
art I draw (8 small PNGs).

**Sketch.**
```
today  Skills   >      Wolves' Pass  (lock)  ✓ done      thin outline marks
after  Skills   ▸      Wolves' Pass  [pixel lock]  [pixel tick]   the pixel set
```

---

## 3. Motion tokens

**What.** The code names **50 different millisecond values** for UI durations
(200 ms 9 times, 700 ms 8, 300 ms 8, 320 ms 7, 220 ms 7, 420 ms 6, 600 ms 5, 400
ms 5, 250 ms 5, 160 ms 5, plus 40 more used once or twice). Most are a
transition or a fade someone tuned alone, so two things that mean the same ("a
card arrives") take 220 and 320 ms. Proposal: four tokens in
`lib/theme/motion.dart` (`fast` 150, `base` 250, `slow` 420, `ambient` for
loops) and two curves; move the UI transitions to them (not the painters'
timelines and the fight's choreography, which are timed to the art).

**Why.** One pace; and a single place to slow everything for the user who finds
it quick (and to zero them with the platform setting).

**Size / risk.** M. Low to medium: a duration moved by 30 ms is felt, so each
family is checked by hand on the phone; no pictures change.

**Sketch.** None: same screens.

---

## 4. Long lists build their rows lazily (measure first)

**What.** There are **80 `ListView(` with their children built in a list** in
screens and widgets, against **4** `ListView.builder`/`.separated` in the whole
tree. A long list built eagerly creates every row (each a card with an icon
and a few texts) on opening, visible or not. Candidates to measure first:
the journal, the inventory, the bestiary, the clans' standing list, the codex
and the editor lists. Proposal: a timeline capture of those on the phone the
user plays on; convert only a list whose build shows up, to `ListView.builder`
with the same rows.

**Why.** Opening a long tab at the end of a game is where a hitch would show.

**Size / risk.** S for the capture, M for the conversions. Medium: lists that
share a scroll controller, expanding rows or keys need care; one list per PR.

**Sketch.** None: same screens.

---

## 5. A spacing scale

**What.** Gaps between things are literal: `SizedBox(height: ...)` 8 (253 times),
4 (134), 12 (122), 6 (117), 10 (66), 16 (63), 2 (45), 14 (30); `EdgeInsets.all`
16, 12, 10, 24, 8, 6. Four steps (4, 8, 12, 16, 24) cover most; the **6, 10, 14
and 2 px gaps (about 260 of them) are the off-scale ones**. Proposal: name the
steps (`Gap.s`, `Gap.m`...) and move the off-scale ones to the nearest step, a
file at a time, with pictures to see what moved.

**Why.** Rows and cards line up from screen to screen; a gap changes in one
place.

**Size / risk.** M (a codemod and many pictures). Medium: a 2 px shift is
rarely seen but moves a layout that is tight at 320 px; any screen the QA 360 px
checks must stay whole.

**Sketch.**
```
today  card 12 | 10 | card 14 | 6 | card      gaps 12, 10, 14, 6
after  card 12 | 12 | card 12 | 8 | card      steps 8 and 12 only
```

---

## Order I would do them in

1 (an hour, no risk, the stock blue-grey ring goes), then 3 (no pictures, one
afternoon of hand-checking), then 2 (the one the user will see most, with art),
then 4 once the capture says which list, and 5 last (the most pictures for the
least visible gain). Idea 2 touches `tool/gen_*.py` and `assets/icons/` (mine);
nothing here needs another session's files except the list conversions in 4,
which I would send to the owner of each screen.
