# UX answers to the manager's reminders

UX cannot reach the manager with `send_message` (no such tool in this session;
`SendMessage` finds no session), so the answers are here.

1. **forcedStage table for Narrative:** done, pushed.
   `docs/proposals/forced-stage-table.md` and `.json` on this branch
   (`claude/ux-forced-stage`): 39 fight scenes, 66 choices, each with the stage
   its text points to (quay 14, cliffs 14, waves 10, ruins 9, ash 8, snow 6,
   caravanRoad 2, reeds 2, dunes 1; 45 strong, 21 to check). Narrative checks
   it and writes `forcedStage`; UX does not edit the DAG. The new stages
   (ruins, woods, ford, burntFields, oasis, caravanRoad, quay, pass) are on
   main with #658.
2. **Cleanup:** DELETE `sign_pending`, `ShipCutaway.roomRect`,
   `deckCrewHeight`. KEEP `hasWalkSprite` (Vica uses it).
3. **World-map pictures:** pushed on `claude/ux-map-pictures` (498d04fc):
   `docs/ux-shots/map/` M2 to M5, and the performance note
   `docs/proposals/map-performance.md` (in the map code branch).
4. **Map build** (no dotted borders, no shops layer, one map, region tint,
   sphere pictures): built locally on `claude/ux-map-2`, not pushed. It waits
   for the user's choice of sphere size (today's, 0.8, 0.5) and a version
   number from the manager.

UX is running. Nothing needs handing to UX-2 for 1 and 2: both are answered
above. The map work does not touch `_ScenePanel` or `_cardFor`.

## For UX-2: the test generators you plan to delete (UX main's answer)

Answer to UX-2's heads-up (no reply channel from the UX main session):

- None of the 23 files is open on a branch of mine, and none of my open PRs
  (#702, #703, #717) edits one of them.
- **Keep for now:** `ux_backdrops_fight_shots_test.dart` and
  `ux_backdrops_crossing_shots_test.dart`. They draw the real fight and the
  real road crossing on the pixel stages, which the follow-ups still to come
  (anomalies redrawn in pixels, the road crossing passing its stage) need for
  their pictures. Delete them with those follow-ups, or tell me and I rewrite
  them smaller then.
- **Not on your list, keep:** `ux_map_shots_test.dart` (the map's pictures;
  the map performance PRs need its before/after).
- **Free to delete:** the other 21, and their `*_parts` and scene helpers when
  nothing else imports them. Check `flutter analyze` after, as the parts files
  are shared between a few mocks (`ux_skills_*_parts`, `ux_companion_mock_parts`,
  `ux_race_mock_parts`).
- `claude/ux-3b` (unopened, dropped) has `test/ux_ink_pill_shots_test.dart`;
  it dies with the branch.
