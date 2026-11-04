# Pictures in docs/: what nothing references, and what can be quantized (Cleanup session)

Measured on main `bcf73433` (v1.751, after #707 quantized 132 PNGs from 56.6 MB to 20.3 MB). Docs only. **Nothing is deleted by this note**: the deletions wait for UX's keep/drop answer on `docs/ux-shots`. `docs/feedback` and `docs/qa` are not touched or counted.

> **Status (UX main answered, `ux-answers-to-manager.md`):** of the 115 unnamed `docs/ux-shots` pictures, **103 were dropped** (9.1 MB; git keeps them) and **12 kept** (about 1.5 MB): the five `backdrops-*` pictures, `sea-beasts-png-vs-webp.png` and `sea-beasts-png-64-colours-rejected.png`, `clan-power-card.png`, `clan-power-nemesis-fr.png`, `clan-details-360.png`, `poi-sphere-1-world.png` and `poi-flat-3-district.png`, because open or recent work still points at them. `docs/ux-shots/map/`, `icons-8x-vs-native.png` and `spectral-medium-weights.png` were not touched. The lists below are the state before the drop.

## How "referenced" was measured

```
python3 docimg.py   # every png/jpg/gif/svg/webp under docs/ except feedback/ and qa/;
                    # a picture is "referenced" when its file name appears in any tracked text file
                    # (md, dart, py, yml, json, csv, txt), other than itself
```

A file name that appears nowhere is the only thing called unreferenced. A generic name found elsewhere counts as referenced, so the count errs on the side of keeping. A folder that a document names as a whole (`docs/ux-shots/fight-fixed/` in a proposal) is shown below as "named", because that document may mean all its pictures.

## The numbers

| Where | Pictures | Size | Unreferenced by name |
|---|---|---|---|
| `docs/ux-shots` (all sub-folders) | 199 | 26.5 MB | **115 files, 10.6 MB** |
| `docs/proposals/images` | 60 | 12.9 MB | 8 files, 3.5 MB (see 2) |
| `docs/maps` | 17 | 9.5 MB | 9 files, 3.1 MB (see 2) |
| other `docs/` | 0 | 0 | |
| **Total (without feedback/ and qa/)** | **276** | **48.9 MB** | **132 files, 17.3 MB** |

## 1. `docs/ux-shots`: for UX (session_01Y8cU3zPWWudNpnZGCrkKEc) to answer keep or drop

These are build-time screenshots of features that shipped. Their folders are mostly named by a CHANGELOG line or a proposal, but not one picture by file name. Proposed rule: **drop what no document links by name, keep what one does**; or drop the whole folder where the document that names it is a closed proposal. Per folder:

| Folder | Files | KB | Named by |
|---|---|---|---|
| `ux-shots/` (top level) | 69 | 6,621 | CHANGELOG and 32 more files name the folder, none a picture |
| `fight-built/` | 7 | 816 | CHANGELOG, `docs/proposals/fight-fixed-sizes.md` |
| `inventory-build/` | 8 | 798 | nothing |
| `fight-fixed/` | 7 | 780 | `docs/proposals/fight-fixed-sizes.md` |
| `journey-fix/` | 8 | 672 | CHANGELOG, `docs/qa/chapter1-ux.md` |
| `intro-build/` | 8 | 522 | CHANGELOG, `docs/proposals/intro-animation-d.md` |
| `forge-build/` | 6 | 231 | nothing |
| `dice-built/` | 1 | 158 | CHANGELOG |
| `fixes-611/` | 1 | 37 | CHANGELOG |

Questions for UX: (a) may the 115 files go (10.6 MB), or which folders do you want kept? (b) `inventory-build/` and `forge-build/` are named by no document at all: delete both? The history (git) keeps every deleted picture.

The full list of the 115 files:

### `docs/ux-shots/` — 69 files, 6621 KB

`arrival-sheet-notice-dark.png` (58 KB), `arrival-sheet-notice-light.png` (58 KB), `backdrops-crossing-desert-versions.png` (72 KB), `backdrops-fight-dunes.png` (54 KB), `backdrops-fight-quay.png` (62 KB), `backdrops-fight-ruins.png` (55 KB), `backdrops-fight-woods.png` (65 KB), `banner-choice-360.png` (108 KB), `banner-choice-fr-360.png` (100 KB), `banner-choice-tall.png` (112 KB), `chapter-art-sheet.png` (15 KB), `choice-cards-bridge-fr-320.png` (85 KB), `choice-cards-bridge-picked.png` (125 KB), `choice-cards-bridge.png` (127 KB), `choice-cards-hub.png` (149 KB), `choice-rings-hub-open.png` (141 KB), `choice-rings-hub.png` (150 KB), `city-plans-sheet.png` (115 KB), `clan-details-360.png` (72 KB), `clan-power-card.png` (69 KB), `clan-power-nemesis-fr.png` (94 KB), `encounter-from-left.png` (37 KB), `epilogue-map-built-320.png` (98 KB), `epilogue-map-built-412.png` (127 KB), `fight-enemy-tall.png` (140 KB), `fight-hero-small.png` (77 KB), `fight-hero-tall.png` (135 KB), `fight-incoming-estimate.png` (136 KB), `hunter-champion-icons.png` (5 KB), `level-up-patron-line.png` (67 KB), `mercy-dialog-plain.png` (42 KB), `mercy-dialog-read.png` (55 KB), `places-build-1-map.png` (137 KB), `places-build-2-card.png` (138 KB), `places-build-3-list.png` (95 KB), `places-build-4-at-place.png` (130 KB), `poi-flat-3-district.png` (266 KB), `poi-sphere-1-world.png` (193 KB), `poi-sphere-3-district.png` (224 KB), `poi-sphere-4-closest.png` (167 KB), `regent-icon.png` (1 KB), `reward-clan-gift.png` (65 KB), `reward-quest-banner.png` (87 KB), `reward-quest-card.png` (54 KB), `rival-hunters-icons.png` (3 KB), `roll-powers-en.png` (14 KB), `roll-powers-fr-320.png` (15 KB), `scene-band-hub-sheet.png` (50 KB), `scene-band-hub.png` (76 KB), `scene-band-street-sheet.png` (149 KB), `scene-band-street.png` (54 KB), `scene-choices-en.png` (263 KB), `scene-choices-fr-320.png` (118 KB), `sea-beasts-png-64-colours-rejected.png` (233 KB), `sea-beasts-png-vs-webp.png` (294 KB), `signpost-en.png` (13 KB), `signpost-fr-320.png` (15 KB), `skills-ideas-compare-320.png` (149 KB), `stat-pick-heroic-fr-320.png` (70 KB), `stat-pick-none-fr-320.png` (37 KB), `stat-pick-rare-en.png` (47 KB), `stat-pick-tiers-en.png` (104 KB), `story-text-writing-done.png` (86 KB), `town-tints-city.png` (101 KB), `town-view-1.png` (93 KB), `town-view-2.png` (76 KB), `walk-bubble.png` (48 KB), `zone-cleared-card-en.png` (59 KB), `zone-cleared-card-fr-320.png` (60 KB)


### `docs/ux-shots/dice-built/` — 1 files, 158 KB

`dice-loadout-built.png` (158 KB)


### `docs/ux-shots/fight-built/` — 7 files, 816 KB

`a1-pack3-412.png` (127 KB), `a3-pack3-320.png` (106 KB), `a3-pack3-412.png` (148 KB), `a3-soldier-412.png` (132 KB), `solo-warden-412.png` (99 KB), `stage-boss-412.png` (106 KB), `stage-soldier-320.png` (95 KB)


### `docs/ux-shots/fight-fixed/` — 7 files, 780 KB

`a0-thug.png` (97 KB), `a1-pack3.png` (131 KB), `a3-pack3.png` (148 KB), `a3-soldier.png` (127 KB), `s-a3-soldier.png` (96 KB), `s-solo-warden.png` (79 KB), `solo-warden.png` (100 KB)


### `docs/ux-shots/fixes-611/` — 1 files, 37 KB

`inventory-tabs-320-fr-after.png` (37 KB)


### `docs/ux-shots/forge-build/` — 6 files, 231 KB

`forge-build-1-feet.png` (36 KB), `forge-build-2-legs-odds.png` (66 KB), `forge-build-3-strike.png` (40 KB), `forge-build-4-lands.png` (31 KB), `forge-build-5-tier.png` (30 KB), `forge-build-6-piece.png` (26 KB)


### `docs/ux-shots/intro-build/` — 8 files, 522 KB

`intro-build-1.png` (48 KB), `intro-build-2.png` (55 KB), `intro-build-3.png` (36 KB), `intro-build-4.png` (59 KB), `intro-build-5.png` (84 KB), `intro-build-6.png` (79 KB), `intro-build-7.png` (89 KB), `intro-build-8.png` (69 KB)


### `docs/ux-shots/inventory-build/` — 8 files, 798 KB

`inventory-build-1-all-320-dark.png` (106 KB), `inventory-build-1-all-412.png` (112 KB), `inventory-build-2-gear-320-dark.png` (88 KB), `inventory-build-2-gear-412.png` (95 KB), `inventory-build-3-dice-320-dark.png` (83 KB), `inventory-build-3-dice-412.png` (86 KB), `inventory-build-4-detail-320-dark.png` (113 KB), `inventory-build-4-detail-412.png` (112 KB)


### `docs/ux-shots/journey-fix/` — 8 files, 672 KB

`journey-after-high-quay-320.png` (51 KB), `journey-after-high-quay-412.png` (57 KB), `journey-after-white-wells-320.png` (109 KB), `journey-after-white-wells-412.png` (130 KB), `journey-before-high-quay-320.png` (60 KB), `journey-before-high-quay-412.png` (70 KB), `journey-before-white-wells-320.png` (135 KB), `journey-before-white-wells-412.png` (57 KB)


## 2. Outside ux-shots: nothing is safe to delete

- `docs/maps/fmg-chart/` has 9 files no document names by file name (`story-globe-north.jpg` ... `sphere-views.png`, 3.1 MB). They are **referenced**: `STORY-WORLD.md` lists them by suffix (`story-globe-whole.jpg`, then "views turned toward each part: `-north`, `-south`, `-west`, `-east`, `-crossing`, `-polar-south`") and the `-turn-parchment.gif` as "a turn of the sphere". Deleting them would leave the document describing pictures that are gone. Kept.
- `docs/proposals/images/feedback-*.jpg` (8 files, 3.5 MB, named by no document): the user's own feedback screenshots, added to the repo by the Manager (#682). Kept; candidates for the re-encode below instead.

## 3. Quantize the rest (done in this branch, approved by the user through the Manager)

The two GIFs and nine JPEGs that are neither one of the nine unnamed `fmg-chart` images nor a `feedback-*.jpg` (both kept as they were, as asked) were re-encoded in place, same file names:

| What | Before | After | How |
|---|---|---|---|
| `ux-shots/intro-anim.gif`, `maps/fmg-chart/story-globe-turn.gif` | 5.6 MB | 3.6 MB (-36%) | `ffmpeg`: 10 fps, 75% size, 64-colour palette |
| 9 JPEGs (`proposals/images/banner-choice-final`, `inplace-today-*` (3), `maps/fmg-chart/story-night`, `story-parchment`, `story-globe-whole`, `compare-night`, `compare-parchment`) | 4.1 MB | 2.1 MB (-49%) | `convert -quality 80 -strip` |
| 132 PNGs of #707 | done before | | |

Total 9.7 MB to 5.9 MB (3.7 MB saved). A screenshot with small text (`inplace-today-bridge-town.jpg`) was read after the re-encode: still clear. Left as they were: `story-globe-turn-parchment.gif` (one of the nine unnamed `fmg-chart` files), `dice-roll-anim.gif` (485 KB, not in the list the Manager approved), every `feedback-*.jpg`, `docs/feedback/`, `docs/qa/`. The 115 unnamed `ux-shots` files wait for UX's answer (section 1).
