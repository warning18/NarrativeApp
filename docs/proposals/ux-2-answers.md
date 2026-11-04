# UX-2: answers to the user's questions on the first list (A to J)

Pictures: `docs/ux-shots/fight-tiles/tiles-today.png` (D) and `docs/ux-shots/frame-meter/frame-meter-mock.png` (J).
Where the user's answer meets work that already shipped, I say so first: the Manager's relay was written before it.

## Where each item stands

| # | Item | State |
|---|---|---|
| A | the fight's ground layer repainted every frame | **already merged**: #691, v1.710 |
| B | the slow fight tests at dice speed 4× | **already merged**: with #691, v1.710 (the fight tests throw the dice at 4×) |
| C | the `UX_SHOTS` picture-generator tests | **already merged**: #718 and #720 (34 of the 38 files; the other files assert real behaviour) |
| D | one status-tile widget | **already merged**: #708, v1.736 |
| E, F | one log UI, the weather tile | not built, waiting for the user |
| G | the 320 px / French overflow sweep | **the guard is merged**: #709 (`test/ux_phone_sweep_test.dart`); it found nothing to fix. More screens wait for the answer on the second list's item 2 |
| H | `FightAimLine` measures after every build | **skipped** (the Manager agreed): it only calls `setState` when a point moved; measuring on change only would leave the line stale when a card moves. Nothing to picture: no pixel would change |
| I | Settings and shop `build`s into section widgets | not built; no pixel changes either, so no picture: the proof would be the unchanged widget tests. I can list the sections as text if the user wants to see the plan |
| J | a frame-time capture | waiting; see below |

## A: why (3 lines to pass on)
A fight used to redraw its ground (the stage, the night veil, the lamps) 60 times a second for as long as it lasted, even when nothing on it moved; since v1.710 it draws once and again only when rain, an anomaly or a light really changes.
The player gets a cooler phone and a longer battery in every fight, with no visible change; the saving is the biggest of the fight's idle frames, because it was one full-screen scene per frame.
How big in milliseconds I cannot say: no device here, the tests prove the ticker no longer runs, not the cost; the capture of J would put a number on it. (A is already shipped, nothing left to build.)

## C: why (3 lines to pass on)
34 test files (22,230 lines) only drew pictures when asked (none had a single assertion); every CI shard still compiled and loaded them on every PR: about 55 s of work per PR for the 38 gated files on one machine, spread over the 4 runners (QA's next suite profile will give the real number).
Lost: redrawing those old storyboards with one command (the pictures stay in `docs/ux-shots/`, the files stay in git history).
Kept: the 8 tests that assert real behaviour (arrival, town, story room, fight info, folds, polish, sweep, intro animation) plus the new phone sweep. (Already merged, nothing left to build.)

## D: the example (picture: `docs/ux-shots/fight-tiles/tiles-today.png`)
The picture shows the two tiles as they are today, at the sizes the fight uses (22 px on a fighter's card, 32 px in the top strip), as drawn and enlarged, and what they share: the tinted square (the colour at 20 %), the 1 px border (65 %) and the corner badge. Before v1.736 each copy drew these itself (about 48 lines twice); now both use one private `_EffectTile`, with the content (a pixel bitmap or a Material icon), the size and the corner radius (6 or 8) as parameters. That is the "one FightTile", pixel-identical by construction; the two public widgets stay because their taps differ (the chip's is optional).

## J: what the capture is for, and the easiest way for someone with only a phone
**Purpose (3 lines)**: to turn three guesses into yes or no with numbers: (1) is the rest of the fight's per-frame repaint work (rain, anomaly, VFX) worth cutting, as A was; (2) is the Journey's reading page or the Camp slow at all; (3) is a `RepaintBoundary` around the VFX, sea and guide layers worth adding. Without a capture each stays a guess; with it each is "2 ms, leave it" or "20 ms, fix it".
**No code at all**: I have no route I can vouch for. Android's *Profile HWUI rendering* bars measure the system's own views, and Flutter draws on its own surface, so I do not know that they show Flutter's frames; I would not ask the user to try it on my word.
**The easiest I can vouch for, a small thing to build** (picture: `docs/ux-shots/frame-meter/frame-meter-mock.png`, a mock with made-up numbers): a Settings switch "Show slow frames", off by default; when on, the app counts frames that took over 17 ms per screen (Flutter's frame timings, which work in the release APK), shows a small counter while playing, and "Copy report" copies the per-screen numbers to paste to the team. About 150 lines, mostly in a new widget plus one Settings tile; it costs nothing when off. Nothing is built: the user's word first.

## Option C: one tap on a fighter's effect icons lists all its effects

Pictures at 320 x 568, French (`docs/ux-shots/effects-row/`):
- `today-one-effect.png`: tapping the poison icon opens a pop-in about poison only; to read the stun you close it and tap the next 27 px icon.
- `proposal-all-effects.png`: one tap on the row opens one pop-in, "Voleur des taudis · 3 effets", with each effect's icon, name and rule. The pop-in is the same card (same colours, same width 296 px, same "Touchez ailleurs pour fermer."), only taller (about 340 px for 3 effects; it scrolls beyond 4).
What changes: a tap on any icon of the row shows all of them (the icon you hit first). Nothing on the cards moves. Mock-up only, not built.

## Raising the tiny text to 11 px: the fight, 320 px, French

`docs/ux-shots/text-11px/fight-320-fr-before-after.png`: left today, right with the 16 fight places at 8-10 px set to 11 px (fight files, `fight_effect_icons`, `fight_markers`; render of the real fight board, seed 7, real fonts, no overflow). The changes are small: the intent chip's label ("Intention i…" becomes "Intention …": one letter fewer fits, the chip is already cut off today), the telegraph/badge digits, the HP and shield numbers and the round counters grow by 1-3 px. Nothing wraps or moves. The cost: text that is already cut off gets cut one letter earlier. The 25 places outside the fight (clan compass, ship yard, bounty board...) are not in this picture; ask before I build them.

## Prices as a chip (31 choice labels with a price in the text)

`docs/ux-shots/price-chip/price-chip-320-fr.png`, 320 px, French, the real choice button, the longest priced labels. Left: today ("... (40 or)" inside the sentence). Middle (A, recommended): the price in a chip at the right of the button, vertically centred, the same chip the Journey's ways already carry (`ChoiceCard`'s tag): gold "−40 or" for a cost, green "+100 or" for a gain. The sentence keeps the room left and wraps one line earlier at worst. Right (B): the chip under the sentence, on its own line; every priced button grows by one line.
How it would be built: the story buttons read the chip's amount and sign from the choice's `goldMod` (it holds -40 / +100 on the labels checked), so no price is typed twice; Narrative then takes "(40 gold)" out of the 31 labels. Until a label is edited, a button would show the price twice, so the order is: chip first, hidden until Narrative's edit lands in the same release, or Narrative edits first and the chip follows (both in one release is safest). Mock-up only, not built.

## "How it is ruled" on the clan page (picture first)

`docs/ux-shots/clan-ruled/clan-ruled-320-fr.png`: the clan card (`ClanDetailsCard`, the long-press / offer (i) card) of the Corneilles de Sel at 320 px, French: left today, right with a new block "COMMENT IL EST GOUVERNÉ" ("HOW IT IS RULED") after "Leur histoire", using the clan's `ruling_fr` text from `factions.json` (nothing new worded; it is in the data for the 6 clans, 499 to 589 characters, not read anywhere today). Same heading style and body text as the backstory. The card grows by about 230 px at 320 px (it already scrolls inside the dialog). Mock-up only; the heading's two strings would be new keys (Narrative to word). Not built.

## N11 check (Core's note, branch claude/core-n11-note): the Journey's first frames

`docs/ux-shots/n11/n11-frames.png`, Alster (a city), 4 panels: (1) today, the first frames of a visit while `city_plans.json` decodes: the procedural streets (`CityPlanPainter`); (2) then the stored chart replaces them (the jump); (3) after N11, those first frames: the generic place picture (`PlacePlanPainter`: a ring of buildings, a few spokes) and then the stored chart; (4) the Cove Camp's stored chart, which exists but is never drawn (a camp gets no procedural plan, so the record branch never runs).
Findings: today's first frames show a plan that is not the real one and then jumps; after N11 they would show a generic picture that is not the real one and then jumps; both jump, neither is the city. I see no loss in removing the procedural plan: the only visible change is in those few frames (one generic picture instead of one made-up city), and I would prefer showing nothing but the ground colour for those frames (no jump of streets at all), which I can do in the same change. Cove Camp: drawing its stored chart is a real addition (a picture of the camp as a place), the user decides.
