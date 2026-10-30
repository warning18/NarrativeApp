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
