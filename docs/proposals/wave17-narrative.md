# Wave 17: story items (Narrative, for the user to choose)

Docs only. Nothing is written until the user picks. Sizes are for Narrative's
part: **S** = under a session, **M** = about one session, **L** = more.
Each item says what it needs from Core or UX. Items 1 and 2 are small and
ready; 3 to 5 are the larger story pieces that were parked.

| # | Item | Size | Needs |
|---|---|---|---|
| 1 | Text pass on what wards, crossings and clan power added | S | nothing |
| 2 | The sea remarks move in | S | UX's sea item shipped |
| 3 | Companion loyalty scenes (8) | M | Core: two flags |
| 4 | The Lantern-Bearer's Will (intrigue 9) | M | Core: outcome numbers |
| 5 | The Taken's Names (intrigue 10) and The Host's Price (intrigue 11) | L | Core: numbers; UX: none |

## 1. Text pass on the new systems (S)

One data-and-strings PR, no mechanics. It covers the wording the last waves
added that nobody has read as a whole:

- the `ward_set_nemesis` reword (already agreed with Core; it rides this PR if
  #467 did not carry it);
- a read-through of the 30 land events against the routes that now draw
  them (chapters 4, 5 and 7), fixing any line that does not fit its road;
- the news lines of the 28 politics events (the two upheaval events included), now
  that they fire in the game and the simulator: tense, "Hostile" versus
  "War" wording, and the seat-fall lines for the Mire and Emberwick;
- French lint sweep of the same files.

Needs: nothing. It keeps every number as it is.

## 2. The sea remarks move in (S)

`docs/proposals/sea-remarks.json` (branch `claude/narrative-sea-lines`) holds
8 records, one `<companion>_atSea` each, 3 lines in EN and FR. When UX's sea
item ships, they move into `companion_remarks.json` as a data-only PR.

Needs: UX's sea item merged (the `atSea` kind is already in the game).

## 3. Companion loyalty scenes (M)

Eight short camp scenes, one per companion, shown once the companion is
**Devoted**; each ends in a small choice that writes a flag a later remark
or epilogue reads. The outline is `docs/proposals/companion-loyalty.md`
(scene titles, choices and flags are there). About 200 words per scene in
EN and FR.

Needs from **Core**: (a) a flag `devoted_<companionId>` set once when
approval first reaches `devotedApproval`; (b) a way to tell a companion is
still in the party (`ally_<companionId>`, or a `showIfAlly` field on a
choice); optionally (c) a reward hook and (d) a simulator route to Devoted
so `sim_coverage_test` can reach the scenes. Needs nothing from UX: the scenes
are ordinary camp-node choices.

## 4. The Lantern-Bearer's Will (M)

A ninth intrigue. A sealed will, left before the Lantern-Bearer failed, names
an heir who is neither Vane, Morrow nor Tallis. It surfaces in the Lantern
Hall (`7520_*`) and decides what the Houses do if the claimant dies. Three
outcomes: read it, hide it, give it to the claimant you beat. It builds on
`dying_lantern_bearer`, so it only appears for a player who followed that
intrigue. Six stages, chapters 5 to 8, in the same shape as the eight
existing intrigues; the scenes use `politics.intrigue` steps, no new
mechanic.

Needs from **Core**: the outcome numbers (standing, power, House relations)
and the check that the new intrigue is reachable in the simulator. Needs
nothing from UX.

## 5. The Taken's Names and The Host's Price (L)

Two late intrigues, written together because they share chapters 7 and 8
and the Host flags (`host_giants`, `host_oni`, `host_tidekin`,
`host_kindly`):

- **The Taken's Names:** the throne is carved with the names of the people
  the tear took; a clerk in Candlehold has been copying them. Outcomes: read
  them aloud, burn the list, carry it unread across the tear (this gives the
  `7003` ending line "Cut the taken's names from the throne first" a
  reason).
- **The Host's Price:** each power that joins the Host asks for something
  after the crossing (the giants their quarry face, the Tide-Kin a drowned
  island, the oni the bells, the Kindly Ones a bargain honoured to the
  minute). Outcomes: pay all, pay some and break one, pay none.

About 12 scenes in all, EN and FR, plus the two intrigue records.

Needs from **Core**: outcome numbers, and a decision on whether the Host's
price can change the final battle's odds (otherwise the outcomes are story
and epilogue lines only). Needs nothing from UX unless the user wants a
card for the crossing.

## Order I would suggest

1 and 2 first (small, no dependency). Then 3 (the user asked for it earlier
and it is the only item that gives the companions a late payoff), then 4,
then 5. Items 3 to 5 each ship as a separate PR; each needs a version from
the manager when it opens.
