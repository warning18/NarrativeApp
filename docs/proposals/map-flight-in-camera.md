# The map's flight and the crossing as one camera travel (UX-2, v1.846 provisional)

The user said yes to "the road trip on the map and the crossing become one
camera travel" (the piece parked in step 3e of `scene-transitions.md`). This
note is the storyboard and the plan, before any code.

Picture: `docs/ux-shots/transitions/map-flight-storyboard.png` (today above,
proposed below; frames 1 to 4 of today are real captures of the Dune Sea road
from the Sleeper's Face to the White Wells, made by
`test/ux_flight_shots_test.dart` with `UX_SHOTS=<folder>`; frame 3 of the
proposal is a mock made of two real frames).

## What happens today

A road between two places with a long walk (`landRouteId`, 18 choices in the
story data) is shown twice:

1. the party leaves the place view: the map zooms out to the world chart and
   the party flies along the road (`_flight`, `journey_screen.dart` `walkTo`,
   1.9 s up to 4.5 s, or `worldMoveDuration` on a world leg);
2. the flight ends at the far place, then the choice is taken and
   `runLandCrossing` pushes `LandCrossingScreen` as a `MaterialPageRoute`
   (180 ms fade and rise): the same trip again, day by day, starting from the
   first day.

So the party arrives on the chart, and then sets out again on a new screen.

## The new flow

The chart flight becomes the **setting out**, and the crossing is the rest of
the same trip; the hand-off is a route transition, not a new screen starting
cold.

1. **Tap Go**: as today (the walk out of the place, the map zooming out).
2. **The chart flight**: the same flight, but it stops when the party leaves
   its district (the road's first stretch), not at the far place: the arrival
   is the crossing's, not the chart's. Shorter, about 1.2 s.
3. **The rise**: `LandCrossingScreen` comes in with a new route
   (`PageRouteBuilder`): the scene strip slides down from the top over about
   420 ms while the chart is still under it, the day card and the choices
   fade in under the scene. The party mark on the chart is where the crossing's
   party figure stands (same x on screen).
4. **The camera travels** (today's crossing: `WorldCamera`, days, events).
5. **Going back** (turn back, or a lost road): the route pops the same way in
   reverse and the map is under it, with the party where it set out
   (`walkBack` as today).
6. **A fight on the way**: unchanged (the crossing pushes the fight; the jolt
   and the entrance are row 6 of the transitions table).
7. **Reduced motion**: no flight, no rise: the crossing opens at once, as the
   other reduced-motion cuts do.

## What it changes in code (small, one revert)

- `journey_screen.dart`: the flight's stop point, and passing the party's screen
  position to the crossing. A few lines in `walkTo`; nothing else of the 5897.
- `land_crossing_screen.dart`: the new route in `runLandCrossing`
  (`CrossingRiseRoute`, a new file next to it) and an optional start frame.
- No change to the crossing's days, events, fights, rewards or to Core's data.
- New strings: none.

## Perf

The rise paints the crossing's scene strip (the same kit layers as today's
crossing) over a chart that is already on screen; measured with the same
frame-recording harness as the kits (Dart time to record a frame, debug VM,
not the GPU): before and after numbers go in the PR, plus the slow-frames
meter of a phone if the user sends it.

## Hand-test list (goes in the PR)

1. A short road (a one-day crossing).
2. A long road (the Dune Sea road, 2 days; the sea cliffs' road, the longest).
3. A road with a fight on the way (flee, win, lose).
4. Turn back on day 1: the map is under it and the party is where it set out.
5. Reduced motion on: no flight, no rise.
6. Going back to the map from the crossing and tapping Go again.
7. A road that starts in a town or from a place with no strip x (the old walk
   and push, unchanged).

## Risks

- This is the biggest change of the camera plan: two screens' timing. It is
  kept to one route class and a few lines in `walkTo`, so it reverts alone.
- `journey_screen.dart` and the map files had no open PR when this was written
  (#829 and #830 are docs only); Core's engine (v1.845) does not touch them.
