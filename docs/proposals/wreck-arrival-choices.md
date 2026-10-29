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

## Built (v1.465.0)

The scene view holds the scene's own choices, and the map keeps only the ways that carry the party.

- **S1 page and S2 sheet:** the words, then the choices acted out here under them (cards; a hub's more than four become a chip for each kind that opens its list). The page's button reads "Back to the map" when it has choices.
- **The map:** pins for the ways that move the party, nothing else. Under the header, a button with a count (key `journey_open_choices`, next to Read) opens the scene view for the choices. The rings on the marker are gone with the cards.
- **A written detour** has no map, so its cards stay under its scene as before.
- **Not built:** building maps on arrival. It does not fit this change (it is a new picture, not a place for choices), so it keeps its own version.
