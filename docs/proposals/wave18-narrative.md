# Wave 18: locked districts and clan districts (Narrative, proposal)

Proposal only. No numbers (Core's), no code. Text for every scene below is EN and FR to come.

## 1. Districts that stay locked until a side quest opens them

A locked district shows on the town page as a door with one line of why ("The Tide-Kin have not let you over the footbridge"). The side quest that opens it ends in a short scene at the door; the district's own scenes follow.

| Town | District | Opened by | Why it is shut |
|---|---|---|---|
| Saltmouth | Lantern Alleys | *The Informant's Tip* | the buyers' lamps go out for strangers |
| Saltmouth | Tern Row | *Tern's Toll* | the Tide-Kin quarter over a footbridge; the toll is a favour, not coin |
| Ashen Quarter | Cinder Row | *The Unpaid Scaffold* | the forges are cold until the Scaffolders trust you |
| Drowned Cloister | the Ossuary | *Brother Tobin's Vigil* | the choir keeps it shut for the dead |
| Black Reliquary | the Chapels of the Chair | *The Candle Count* | the Candlebearers show the inner chapels only to someone who has counted |
| White Anchorage | the Hull Town | *Salvage Rights* | the Admiralty's impound; the wreck-wrights open it for a friend |

Never locked: the district a chapter's main quest needs (Landward Gate, Wharf, Yard, Lantern Hall).

## 2. Districts held by a clan

Each big town has districts with a holder. Doing the holder's district quests builds its influence there; enough influence beside a rival's district lets it flip.

| Town | District (holder) | Two or three district quests |
|---|---|---|
| Saltmouth | Card Row (Crows) | the short count of crates; a marked deck; a dockhand's debt that a Crow wants collected twice |
| Saltmouth | Tern Row (Tide-Kin) | a paper boat lit for a drowned child; the lantern-maker's price; a rival buyer who lights a boat for the wrong name |
| Ashen Quarter | Cinder Row (Compact) | first coal for the cold forges; a smith's charter page; the quarry cart that is not what it says |
| Ashen Quarter | Spire Stair (Dominion) | the archive cellar's lost sentence; a Tribunal clerk who wants to stop signing; a queue that must not be seen |
| Black Reliquary | the Chapels (Penitents' claim) | the unburied saint; a confession read to the wrong person |
| White Anchorage | Anchor Quay (Order) | the last company's watch; a flag raised too early |

**A flip says** (one line at the town page, one in the news): *"The Crows' black pennant came down from Card Row at dawn; the Dominion's blue went up in its place."* It shows as the district card's colour and banner, the holder's doorman, and the shop prices Core already ties to holders. The district's NPCs greet you differently (see ideas).

**An attack says:** a rival clan's riders come at night. The town page shows a red notice ("Card Row is under attack") for a day or two. You may defend (a short fight scene), join the attackers (a scene on the other side), or let it play out; each leaves a flag and a news line. An unanswered attack resolves by the clans' relations.

## 3. What I would need from Core

- A flag or condition a scene can read: `held_<district>_<clan>` (or `heldBy(district)` in `showIfFlags`).
- A `locked` field on a district with an `unlockQuestId` (and a one-line reason in EN/FR).
- Quests that carry a `district` and a `faction`, so a quest done adds influence to that district's holder or challenger.
- A flip event: place, old holder, new holder, with a news line that fills `{district}` and `{clan}`.
- An attack event: place, attacker, a window of days, and flags for defended / joined / ignored.
- A camp-errand-style entry for "under attack", so the alert is not a hub choice.

## 4. Five ideas of my own

- **Story:** an epilogue map that tells every district's final holder in one line each.
- **Quests:** a "clan road" chain per clan that visits its districts in every town, so influence feels like one campaign.
- **Characters:** one named doorman or stall-keeper per held district, who changes face and manner when the district flips.
- **Dialogue:** district barks that change with holder and standing, so the same street speaks differently under the Crows and under the Dominion.
- **Companions:** remarks that react to a flip or an attack (Kelda holds a gate, Sable counts the cut).
