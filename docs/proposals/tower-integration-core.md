# The Tower in the story: Core's part (phase 1)

The user: "Optimize all sessions to work in common: for narrative I would
like propositions of how we could integrate the towers in the system."
Narrative leads with three propositions. This note is Core's input: what
the systems allow, what Narrative must respect, how the earlier options map
onto a story integration, and the cost. Measured on main at v1.901.
Proposal only: no code, no numbers changed.

## 1. What the systems allow today

**The Tower is a separate mode.** It starts from the main menu
(`TowerStartScreen`). It builds its own hero from the run (`towerHeroOf`)
and keeps its own two saves in preferences: `tower_run_v1`, the climb in
progress, and `tower_marks_v1`, the profile's `TowerProgress`. Nothing
outside `lib/data/tower/` and `lib/screens/tower/` reads either save, and
the Tower reads nothing from a story save.

**What the Tower already measures.** Its progress is marks (floor 1, warden
2, boss 5, top 15, a refusal 1) and ten unlocks bought with them:

| Kind | Unlocks |
|---|---|
| dice | flame, tide, tearglass |
| clans | the Crows, the Vigil, the Compact |
| start items | `shield_t5`, `sword_t4` |
| professions | cleric, ranger |

The bands run at both extremes: no unlocks, and all unlocks. **Anything
that only changes how fast a profile reaches its unlocks stays inside what
the bot and QA already measure.**

**Hooks the story can offer without touching the Tower's balance.**

| Hook | Today | What it could carry to the Tower |
|---|---|---|
| Story flags (`StoryChoice.flagsToAdd`) | every choice can set one | "this profile has done X", read by the Tower start screen |
| Quests (`quests.json`, quest log) | rewards are gold, XP, items, flags | a flag, as above |
| Clan standing (politics) | per story save | which clan's oath the Tower offers first: flavour, not power |
| Achievements (`achievements.json`, 19) | profile-wide, no effects | a natural two-way bridge: cosmetic |
| Journey and the world map | places, landmarks, the place view | a Tower landmark that opens the Tower mode |

**Hooks the Tower can offer the story.** The Tower's marks, best floor,
runs and wins, read by a story condition: a scene line, an achievement, a
flag that opens a scene. **Not titles:** `titles.json` titles carry effects
(for example `voyageCalm`), so a title is power in the story.

## 2. Constraints Narrative must respect

1. **Two heroes.**
   - The Tower hero is built fresh from the climb.
   - The story hero is the save's `PlayerSession`, with its level, gear,
     companions and clan specs.
   - Bringing the story hero into the Tower makes the Tower's difficulty
     depend on the story's power, so its bands would mean nothing.
   - Bringing Tower power (items, gold, stats) into the story is power the
     story's balance never measured.
2. **Rewards crossing saves.**
   - There are several story saves but one Tower progress.
   - A story event that grants Tower marks must say whether it pays once
     per profile or once per save. Per save could be farmed by replaying a
     chapter, so I recommend once per profile, keyed by the event.
   - A Tower milestone read by the story is the same for every save.
3. **The simulator.**
   - The story simulator doesn't climb, and the Tower bot doesn't play the
     story.
   - **Story → Tower** is safe if it only grants marks or unlocks (inside
     the all-unlocks band).
   - **Tower → story** is safe if it is cosmetic: text, an achievement, a
     flag that opens a scene with no reward.
   - Any power across, in either direction, needs a new measure in both
     simulators.
4. **Chapter difficulty.**
   - The Tower's 30 floors climb through chapter bands 1 to 8 on their own
     curve.
   - The story's fights scale by the story's chapter (and, since v1.896,
     the boss damage by chapter).
   - A tower placed in a chapter of the story doesn't inherit that
     chapter's difficulty unless we build a new curve (option B).
5. **Rules already in the Tower stay as they are:**
   - the bag cap of 5;
   - the hero copy and its cache (#878);
   - oaths on 35% of floors;
   - boons on floors 5 to 25;
   - spoils from the chest;
   - the migration of old saves (#871).

## 3. The earlier options, seen as story integration

From `tower-in-each-town.md`, which the user parked:

| | As story integration | Verdict |
|---|---|---|
| **A** one Tower mode, a door per town on the sphere | the story's world gives the Tower its places; no hero or reward crosses | safe; integration by geography only |
| **B** short towers inside the story, climbed by the story hero | the deepest: a tower is a story place, its floors story fights, its rewards story rewards | the only one that is truly "in" the story; also the costliest and riskiest (§2.1, §2.3) |
| **C** A plus each town's place view opening its tower | the journey links to the Tower | safe |

**A fourth option, D: light links both ways, no power across.**

- **D1, story → Tower:**
  - story events grant Tower marks once per profile: a quest done, a
    chapter's boss, a clan sworn;
  - a story clan sworn opens that clan's Tower unlock early (the Crows,
    the Vigil or the Compact).
  - Both stay inside the Tower's measured envelope.
- **D2, Tower → story:**
  - Tower milestones (floor 10, 20, the top) unlock achievements;
  - companions or NPCs remark on them (Narrative's remark table);
  - a milestone sets a flag that can open a story scene, with text only
    and no reward.
- **D3, clan flavour:**
  - the story's highest-standing clan is the Tower's first oath;
  - the Tower's oath cards could quote that clan's story line.

D gives the feeling of one world (what you do in one shows in the other)
without either balance depending on the other. It combines with A or C.

**The Tower as the place of the story** is Narrative's to propose, and it
fits B or a lore-only variant of A: the Tower stands in the world, and its
floors and wardens are named from the story. Lore-only costs Narrative's
text and no rules.

## 4. Rough size

| Option | Core | Others | Risk |
|---|---|---|---|
| D1 (marks and unlocks from story events) | 1 PR: a `towerGrant` effect on choices and quests, once per profile, written to `TowerProgress` | Narrative 1 (which events), UX small (a toast) | low |
| D2 (milestones to achievements, remarks, flags) | 1 PR: the story reads `TowerProgress` in its conditions | Narrative 1 | low |
| D3 (clan flavour) | small, inside D1's PR | Narrative text | low |
| A | 2 PRs (sites, saves per tower, bot per tower) | UX 1–2, Narrative 1 | low |
| C | A + 1 small PR | UX | low |
| B | 5–7 PRs: a new fight path for the story hero, story save fields, the simulator climbing, a new chapter curve | UX and Narrative several | high |

**My reading:**

- D is the cheapest way to make the Tower feel part of the story, and it
  is safe by construction.
- A + C add the places.
- B is a different game loop. I'd only do it if the user wants the story
  hero to climb and accepts re-measuring the story's balance.
