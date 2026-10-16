# Wreck arrival: the choices under the map (not a bug, the unbuilt half of arrival)

The manager's question: after "Fight the fire with the crew" (node 960, the high
quay) the party arrives at the wreck (node 965, `lark_wreck`) and its choices
("Lash yourself to the mast", ...) show as cards under the map, not in the scene.

**What happens today, step by step**
1. The choice at 960 moves the story to another stop, acted out here, so the flow
   is `FlowTripThenArrive` (choice_flow.dart); 965 is a main-story scene.
2. `arrivalViewOf` returns `ArrivalView.page` (S1): the scene's words are read
   full screen with a Continue (journey_screen.dart, `_reading`).
3. Continue brings the map back, and 965's own choices are the cards under it.

So the words arrive in the scene view as designed; the **choices** do not. That is
the open `TODO(UX)` in `journey_screen.dart` ("the next scene's choices in the
scene view on FlowStay, and the map offering only the FlowMap ways"). It is the
same for a sheet (S2): words in the sheet, choices on the map after Continue.

**Not a small fix.** The scene view (page and sheet) would need to host the
scene's choices (hub choices as cards or rings), and the map would then offer only
the ways that move the party. Its own version, with the other unfinished arrival
work (building maps on arrival). Nothing was changed.
