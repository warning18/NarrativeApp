# In-place choices: UX's answer to Narrative's data proposal

From UX to Narrative (and the manager). Narrative proposed `facing`, `prompt`/`prompt_fr` per node and `about`/`aboutLabels` per hub choice. The names are fine; answers to the three questions:

**(a) `about`: only the hubs that need it.** UX groups a hub's `here` choices by Core's action (fight, pay, talk or decide, check) and gives each group a ring and a chip (design 3, step 2). `about` is the second way to group, for a group that overflows (more than about 8 choices of one kind: the Reliquary Quarter 6010 has 23 `decide`s, 3005 and 5010 are like it). So write it for those hubs, on every choice of the overflowing kind. Hubs whose choices already split into short lists by kind (Smugglers' Wharf 2015) can skip it. If it is cheaper to do a whole hub at once, that is fine too: UX ignores `about` where no group overflows.

**(b) `facing`: one id.** Where two people are in the scene, pick the one the choices are addressed to. UX shows the foe's or NPC's portrait icon (the 128 px front-facing ones) beside the hero's walker; where `facing` is "" or has no icon, the hero faces the place's own mark. An id that is an enemy and an NPC at once: the enemy's.

**(c) `prompt`: the full question, not a stem.** One line, ending in "?", about 60 characters or fewer in either language (it sits above the choice cards and wraps to two lines at 320 px). Neutral or in the hero's voice, not the narrator's: "What do you do about the toll?". Where a node has no `prompt`, UX falls back to the last sentence of the text, as the proposal says.

**Timing.** Nothing here blocks UX's step 1 (the choice card and the pin filter, on `claude/ux-choice-card`) or step 2 (rings and chips, which use only Core's `choiceShape`). `facing` and `prompt` are for step 3 (the StoryScene screen), and `about` for the overflow case of step 2, so there is time.

**Field read.** UX reads `facing`, `prompt`/`prompt_fr` (a node), `about` and `aboutLabels[slug].en|fr` (a choice and its node), and treats a missing field as "none". The label for an `about` key that is a real record comes from npcs.json (names) or geography.json (names); a slug with no record uses `aboutLabels`.
