# Race and profession: choosing who you are (UX mock, nothing built)

The user: "Improve the race and profession choices. The user should understand that their choices align
with specific clans and mainly what ways of playing they are choosing." Pictures only: no build, no
version. The intro flow (the burning Shroud, the die, the title, the fade to this screen) is untouched.
Mock test: `test/ux_race_mock_test.dart` (parts in `test/ux_race_mock_parts.dart`).

| Picture | What it is |
|---|---|
| `docs/ux-shots/race-today.png` | The real screen at 320 and 412 px, nothing picked and a Dwarf Warrior picked. |
| `docs/ux-shots/race-after-412.png` | The proposal at 412 px: the people step empty, a Dwarf opened, a Warrior opened, both picked. |
| `docs/ux-shots/race-after-320.png` | At 320 px: the people step empty, a Warrior opened, Compare, both picked. |

## What the real screen does today (from the capture)
- A radar and four numbers stay on top (a good answer to "what do I add up to"), then two rails of
  five icons with one word each ("Sturdy", "Bulwark"), then one detail card with the lore's first
  sentence, three bonus chips and the starting skill. At 320 px "Skirmisher" is cut.
- Nothing says how a choice plays, which clans stand behind it, or what it opens (the skill branches,
  the power medium). The five peoples and five callings read as five icons each.
- The clans appear only later, once the game is on.

## The proposal
Two steps (People, Calling), each a list of cards; the radar block gives way to the cards, since each
card now says what matters in words.
- **Each card, before any detail:** the mark, the name and the tag, **one line on how it plays**, **three
  or four stat chips** (the strongest bonuses, green or red), and **the clans behind it as small discs**
  with their count ("2 clans"). No paragraph.
- **Opening a choice** shows "These clans will court you": each clan with its disc and why (a people's
  clans sponsor its heritage branch; a calling's clans each offer one of its three branches), a tap on
  a clan will open what it offers; and "It unlocks": a people's heritage branch, its power medium and
  its starting skill; a calling's three branches, what its gear scales with, a die and spells for the
  casters. The other choices fold to one line each.
- **Compare:** a button on each step opens two choices side by side (way of playing, chips, branches,
  clans), each with a "Pick" button.
- **After both picks:** one summary card, "You will play as a Dwarf Warrior", how it plays, and the
  clans that will come first: the clans behind both choices lead (a Dwarf Warrior: the Cinder Compact
  and the Lantern Dominion back both; the Grey Vigil backs the Warlord branch).
- A slim bar at the foot says what is missing ("Pick a people", "Now pick a calling") and becomes
  Start new game.

## What it needs
- **Narrative:** done: `playstyle` / `playstyle_fr` on every race and profession (PR #566, v1.598,
  at most 60 characters). The mock shows those real lines ("Front line: soaks hits, stuns with the
  shield"); the cards read the record's own `playstyle`.
- **Core:** nothing. Everything else is already data: `clansOfRace` / `clansOfProfession`
  (clan_affinity.dart), `tag`, `powerMedium`, `standardSkillID`, `preferredScalingStat`,
  `startingSpellIds`, the skill trees and each faction's `sponsors`. "Come first" is a UX ordering (a
  clan behind both choices, then by how many branches it offers); Core can own it if it should match
  the real offers.
- The clan tap ("what each clan offers") reads the faction's own text (`standsFor`, `motto`), which
  exists; a gift line per clan could be Narrative's later.

## Questions for the user
1. Cards in two steps (People, then Calling), or both lists on one screen?
2. Keep the radar block above the cards, or only the summary card at the end?
3. Is Compare worth a button on each step, or is the one-line way of playing enough?
