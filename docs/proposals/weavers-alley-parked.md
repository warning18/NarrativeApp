# The Weaver’s Alley (scene 270): parked, v1.620

The user asked to take the alley out of chapter 1 because it slows the opening. **270 stays in the story file, unreachable**, with its text, its three ways and its origin callbacks. Nothing points at it.

What changed with it in v1.620:
- `250` offers one way on, the Stone Bridge (`260`); the quest unlock `q_retrieve_banner` and `feat_quests` stay on that choice.
- `270` no longer sets `companion_hound` or `hound_left`. The lantern thread went with it: `820` and `891` lost their "Raise the lantern" choice, `823` its `hound_wardens` callback, `891` its `hub_891_hound` callback, `300` its `companion_hound` and `hound_left` callbacks.
- The scene keeps its gold (+15, "Strip the bearer’s gear") and alignment (+2 "Cut it free", −3 "Strip") numbers; they are simply not reachable.

## Where it should land later

A **Lantern Alleys** street scene in Saltmouth (`saltmouth_wharf`, the district hung with lanterns for buyers who would rather not be seen buying). A dead Inquisition signaller with his shuttered lantern still burning fits the Dominion’s landward gate. It needs:
- a hub row on the Saltmouth hub (`2015`) behind a flag, within the five-open-entries rule;
- its location changed from `alster_lower_town` to the Lantern Alleys district, and "Alster" and the razor wire kept or lightly reworded;
- if the lantern thread returns, the three flags above and the two "Raise the lantern" choices (`820`, `891`) come back with it; they are in git history (v1.610, #588 and earlier).

A separate PR when the user asks.

## Update, v1.637

The scene came back as `2015_signaller` in the Lantern Alleys (hub `2015`, shown after the Arcane Bazaar). `270` itself stays parked; the Alster tests still see it as before. The lantern thread did not return, and the new scene sets no lantern flag.
