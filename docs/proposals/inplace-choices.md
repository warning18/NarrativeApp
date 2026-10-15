# Choices that keep you in place: four designs

Mockups only, nothing built. The brief is `docs/proposals/inplace-choices-brief.md` on the manager's branch (`ccr-76229db7-131ulj`), with the user's three screenshots. The problem in one line: on the Journey map every choice is a pin, and 62% of choices don't move the player, so the labels pile on the marker and on each other.

![The four designs, on both screens](images/inplace-overview.png)

## What the mockups show

Two scenes, English, phone size (411 × 890), in the app's own look (Stitched Ink fonts, the walker sprite, the foes' icons). The map is drawn to look like the District zoom; it is not the real map painter.

**The rule they follow (Core's #315, `choice_shape.dart`).** A choice is `here` when it is acted out where you stand (a fight, a payment, a check, a decision), even when its aftermath moves you. That is 848 of the 1,061 choices (80%). Only the plain `go` choices (213) are real pins. So in every design the `here` choices sit **at the marker** (list, panel, ring or bubbles), with a small "→ destination" line when the aftermath moves you, and **pins (or edge arrows) are kept for plain `go` choices only**.

| | The Stone Bridge (node 260) | Your family's house (node 400) |
|---|---|---|
| **Pay the toll** | pay, tag `30 gold` (the price comes from the next scene's `reqGold`; you have 127) | |
| **Refuse and fight** | fight the slum thug, → Your Family's House afterwards | |
| **Charge him** | | fight Aurel Vane |
| **Kneel and beg him to spare her** | | decision, `Good +2`, → The Black Hold afterwards |
| **Run, and come back for her later** | | decision, `Evil −2`, → The Black Hold afterwards |

Neither scene has a plain `go` choice, so **neither map has a pin**: only "You are here". That is the point, but it also means these two screens do not show what a `go` choice looks like. In each design it is the same thing it is today: a pin at its destination with its path, and in design 4 an arrow at the map's edge. (Say if you want a third screen with a `go` choice.)

**Tags.** Each choice carries one tag at the right: a cost (`30 gold`), a kind (`Fight`) or an alignment shift (`Good +2`), and the "→ destination" goes on its own line under the text when there is one. They come from what the choice already has (the next scene's `reqGold`, `triggerEnemyId`, `alignmentMod`, the next scene's location). Action icons follow Core's action list: fight, pay, talk, sneak, attempt, evade, go, decide.

**Stand-ins.** There is no art for Aurel Vane, so the mockups borrow the Inquisition Warden's icon. Foes have 128 px front-facing icons only, not side-view sprites; design 4 needs those (see below).

## 1. Choice list under the map

![](images/inplace-1-list-bridge.png) ![](images/inplace-1-list-house.png)

The map keeps only the plain `go` choices, as pins at their destination (none on these two screens). Under it, every `here` choice is a card: action icon in its colour, the text, a note line (what you have, who you fight, → where it leads on) and a tag at the right. The first card starts selected. Tapping a card highlights its path on the map, or pulses the marker when it stays; tapping it again, or Go, does it.

- **For:** the smallest change. Nothing overlaps because text lives in a list and never on the map. Reads the same for 1, 2, 5 or 8 choices. Works at 320 px and in French (the text wraps in the card, not on a pin). The tap-twice rule stays as it is today.
- **Against:** reads as a menu, not as a place. The map is a long way from the choices when the list is long.
- **Build:** new `ChoiceList` widget in `lib/widgets/`; the map's pin layer keeps only `go` choices (`!here`); the pin and the card share one selection state. No new art.

## 2. Scene panel

![](images/inplace-2-panel-bridge.png) ![](images/inplace-2-panel-house.png)

When the step's choices are `here` choices, the map dims and a panel slides up: a small vignette (you, the one you face, the place's name), the line the scene ends on, and the choices as large buttons. The map comes back after. A plain `go` choice still shows its pin on the dimmed map.

- **For:** it says "you are in a moment, answer it". The vignette gives the other person a face. Big buttons are easy to hit.
- **Against:** it covers most of the screen, so a 5-choice scene scrolls inside the panel. It hides the map exactly when the player may want to see where "Run" goes. Two kinds of step now look different, so the rule for which one you get has to be exact (every choice `here` → panel, otherwise → list?).
- **Build:** a bottom sheet (like the reward card), a `SceneVignette` that needs the foe's picture (icon today), and the "line the scene ends on", which is the last sentence of the node's text or a new `prompt` field from Narrative.

## 3. Ring around the marker

![](images/inplace-3-ring-bridge.png) ![](images/inplace-3-ring-house.png)

The `here` choices are 2 to 4 small action icons on a ring around "You are here", each with a number. The list under the map has the same numbers, so the labels never sit on the map. A plain `go` choice stays a pin with its path.

- **For:** it keeps the choices *on* the map, the closest to what the game does today, and shows at a glance that these are things you do here.
- **Against:** icons alone mean nothing the first time, so the list is not optional, and the ring has to be learnt. More than 4 choices don't fit a ring (the brief says 2 to 4; Core's data has scenes with 5 or more). On the District zoom the ring covers the building under the marker. The icon set must be good enough to tell *fight* from *attempt* from *decide* at 38 px.
- **Build:** a ring layer on the marker, the same list as design 1 (so this is design 1 plus a ring), and a rule for more than 4 (fall back to the plain list).

## 4. Stage mode

![](images/inplace-4-stage-bridge.png) ![](images/inplace-4-stage-house.png)

The map dims and zooms to the District; your sprite and the other character face each other on the ground line, the choices come out above your head as speech bubbles (icon, text, tag), and their line sits under them. A plain `go` choice is an arrow at the map's edge, pointing the way and naming the destination (not on these two screens).

- **For:** the most like a game and the most readable: nothing overlaps because the choices are above the heads, and who you face is on screen. It is also the one that works for dialogue and fights alike.
- **Against:** the most work. It needs a standing side-view sprite for every foe and NPC who can be faced (we have the hero's walker and 128 px front-facing foe icons, so every one of them is new art, in the style of the side-view kit). A long choice text wraps to 2 or 3 lines in a bubble. It takes the whole top of the screen, and a scene with 5 choices needs a scrolling stack.
- **Build:** a `StageScene` widget on the side-view painter engine, a facing sprite per foe or NPC (or a portrait fallback for those without one), bubbles from the same list as design 1, and edge arrows (a new small widget). The biggest of the four.

## Side by side

| | 1 List | 2 Panel | 3 Ring | 4 Stage |
|---|---|---|---|---|
| Fixes the overlap | yes | yes | yes | yes |
| Keeps the map in view | yes | dimmed | yes | dimmed |
| Many choices (5+) | yes | scrolls | needs the list | scrolls |
| French and 320 px | yes | yes | yes | tight in bubbles |
| New art | none | a vignette | icon set | a sprite per foe and NPC |
| Cost | small | medium | medium | large |

## Recommendation

Build **1 now**: it fixes the problem alone, for every screen, and its list is the backbone of the others (3 is 1 plus a ring; 4's bubbles are 1's cards re-dressed). Then, if the user likes the feel of 4, grow it as a **scene layer** for the set pieces only (a fight at the bridge, the house), where a facing sprite is worth drawing, with the list as the fallback for every scene that has no sprite yet. 2 and 3 are less worth building: 2 hides the map when the map matters and 3 can't hold more than 4.

## What I need

- **Core:** per choice, its tag data (cost, alignment shift, the aftermath's destination name) next to `choiceShape`'s move, action and `here`; the price of a toll-style choice comes from the next scene's `reqGold`, so `choiceShape` or a sibling should expose it.
- **Narrative:** for design 2 and 4, a short `prompt` line for each choice node (today the last sentence of the text is quoted), and a "who you face" per node (an enemy or NPC id).
- **User:** which design to build, and whether the list may sit under the map on a phone where the map takes the top half.

The files for the mockups: `docs/proposals/images/inplace-{1-list,2-panel,3-ring,4-stage}-{bridge,house}.png` and `inplace-overview.png`.
