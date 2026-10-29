# Page turns: scenes told in two pages (Narrative)

The user's idea: where a scene has a calm moment and then a shock, show the calm on its own page with a Continue, and give the choices only on the page of the shock. No engine change: the first page is a node with one choice, Continue, that leads to the original scene. The original node keeps its id, choices, rewards, flags and callbacks.

## Done in the pilot (v1.577)

| Scene | Page 1 (new node) | Page 2 (the original node) |
|---|---|---|
| **100** the Blind Beggar | `100_dice`: the tavern, the losing evening, the bone die rolled for luck | "It came up six. Then the wall came in…" and the three choices |
| **400** the family house | `400_hold`: a new short lead-in (a few steps left, lamps behind the shutters) | "I never reached the door. Something passed over the street…" and the three choices |
| **960** leaving on the Lark | `960_lift`: the third bell, the Lark lets go of the world | "For the length of a breath Alster lay under us like a map someone had set fire to. Then the guns on the harbor walls found us…" and the three choices |

Incoming links now point to the new page (0 → `100_dice`, 300 → `400_hold`, 895 and the three failed boardings → `960_lift`). Saves that stopped on 100, 400 or 960 load the original node, on page 2.

## Candidates for more (the real turning points, chapters 1 to 3)

Only where the next paragraph is a real shock. Not added yet; the user decides.

| Scene | Where the page turns |
|---|---|
| **965** the storm | After the sign begins to gutter. Page 2: "The mate shouted… Then the lightning came, and I saw the sign go out altogether." |
| **470** the trapdoor | After the cloth unfolds in the oilcloth ("Who could want such an old piece of cloth?"). Page 2: "Then the light came up, and I saw what was on it." |
| **3100_new_moon** Emberwick | After the kilns bank down for the new moon. Page 2: "Something came along it. I do not mean a traveller." |
| **450** after the fight | After the fight is won. Page 2: Vane looks at the two of them like "two halves of something". (Weakest: it already reads as a beat.) |
| **2050** the storm drain | Not checked in full. Possibly the climb into the drain, then the grate. |
| **890_trainer** the quay drill | Not recommended: it is an ordinary scene with three ways. |

Rules I would keep, so the story does not slow down:
- at most six to eight page turns in chapters 1 to 3;
- the first page is always the calm, never a bare "Continue" over one line (400's lead-in is the shortest);
- the choices, rewards and flags stay on the shock page;
- a page turn keeps its scene's place (a test checks it).

## What the tests had to learn

- `chapter_one_test`: 51 scenes (was 48); the three Lark boardings now lead to `960_lift`; a one-choice node may be a page turn (named in `_pageTurns`, checked to be one Continue, in the same place).
- `story_rules_test`: the same allowance for page turns.
- `first_journey_test`: `400_hold` and `960_lift` are main-story pages, so they have no way back to the map, like the scenes they belong to.
- `autoplay_engine_test`: the walk past node 0 now lands on `100_dice`.
- `sim_competent_test`, `sim_companions_test`: the naive warrior's run for seed 7 changed because the extra nodes move the dice (level 19 / 2808 gold / 21 won, was 24 / 5142 / 54); the pins and the choices hash are re-pinned.

## For Core

New node ids: `100_dice`, `400_hold`, `960_lift`. Registered: the world map's Alster scenes, the Alster plan's `anchors` (same buildings as the originals), and the doorstep list of the family house for `400_hold`. The presentation contract's `scene` block does not need them yet: they take the view of their scene (a page for the main story).
