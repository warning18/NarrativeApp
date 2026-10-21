# Clan power that moves: the data draft (Narrative, branch only, no PR)

The draft of `clan-power-story.md`, written to Core's answers. Not for merge until the user picks the levers.

- **19 choice blocks** (`politics.power`, 15 candidate rows; rows with two clans or two choices count each) in `Cleaned_Narrative_DAG.json`. Sizes 3 to 8; the four loud ones are `4999_standard` (Dominion -6), `5100_vote` (Dominion +6), `6010_clan_compact_3_hammer` (Compact +8) and `6100_clan_mire_2_found` "Step out" (Mire -6).
- **Two events** in `politics_events.json`:
  - `wrack_vote_result`: fires at the chapter 5 turn. The vote itself is in chapter 4 ("The Hollow Court", ids 5xxx), so its result lands as chapter 5 opens. `vote_carried` gives Cinder Row to the Dominion (and `vote_read` adds Crows +4); `vote_refused` gives the Spire Stair to the Compact.
  - `conclave_counts`: fires on any of `way_quiet`, `way_force`, `way_friends`, `way_hard`. With `way_force`, the Lantern Hall passes from the Dominion to the claimed clan (one variant per claim: Vigil, Compact, Mire, Crows, Penitents, Open Hand; the Open Hand has no power, so it gets the Hall and the Dominion loses 8).
- **Changed from the note:** no half-size fallback with `anyPowerAtLeast`; the swings are fixed. If Core wants the gate, I split `conclave_counts` in two. The loud-choice news lines are not written: a choice has no `news`, only an event does.
- Tests run locally: politics_events, clan_power, politics_session, story_rules, story_graph_integrity, french_data_lint, qa_clan_power_50.

## Status (after v1.488)
Main merged in; the draft still passes politics_events, clan_power, politics_session, qa_clan_power_50, story_rules, story_graph_integrity, french_data_lint and party_trail. The only open piece is the half-size gate on `conclave_counts` (`anyPowerAtLeast`), which Core has not added yet; the swings are fixed until it exists. Nothing else waits on the user's lever choice except the go-ahead to open the PR (it needs a version number).
