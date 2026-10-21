# Companion remarks for the wave 15 moments (Narrative)

`wave15-remarks.json` holds 88 records (11 moments × 8 companions), each with 2 lines in English and French, in the shape of `companion_remarks.json`. They are **not** in that file: none of the moments has a `RemarkKind` on main, and `test/companion_remarks_test.dart` rejects any record whose trigger is not in `remarkTriggerOptions`. The existing kinds (`kindApproved`, `approved`, `checkPassed`, `drink`, `walk`...) fit none of them.

## Kinds the moments need (for Core to add)

| Trigger (record `trigger`) | When it fires |
|---|---|
| `builtParleyTent` | the Parley Tent has just been built |
| `builtBoneCastersHut` | the Bone-Caster's Hut has just been built |
| `builtWardingCairn` | the Warding Cairn has just been built |
| `builtStarWell` | the Star Well has just been built |
| `riskyTaken` | the player accepts a risky gift (before the die is shown) |
| `riskyWon` | the die gives the gift |
| `riskyLostHealth` | the die takes health |
| `riskyLostGold` | the die takes gold |
| `riskyLostCurse` | the die lays the stat curse (malus) |
| `templeMended` | Mending at a temple |
| `templeBlessed` | a Blessing at a temple |

If four `built...` kinds are too many, one `houseBuilt` kind with the house id as a key (the way a story choice's `choiceKey` works) is equivalent: tell me and I rename the four records to `houseBuilt` with `houseKey` `parley_tent`, `bone_casters_hut`, `warding_cairn`, `star_well`.

The lines carry no numbers and no clan or place names, so they stay true if prices or odds change. Voices follow each companion's existing remarks (Grosh in the third person, Sable's "love", Vess's whispers, Malrik pricing everything). Once the kinds exist I move the records into `companion_remarks.json` as a data-only change and run companion_remarks, story_rules and french_data_lint.
