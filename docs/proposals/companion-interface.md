# The camp's Companion interface: a review and two versions (UX, nothing built)

The user: "Could you review the UX of the Companion interface in the camp?" Context: a guide dog (the
sprite of the tutorial) becomes a normal, replaceable companion earned through a quest in the second
big town, so the roster and the seat swap matter more. Seats today: two; a third with the Barracks
Annex. Pictures only: no build, no version. Mock test: `test/ux_companion_mock_test.dart` (parts in
`test/ux_companion_mock_parts.dart`).

| Picture | What it is |
|---|---|
| `docs/ux-shots/companion-today.png` | The real Party tab of the camp at 320 and 412 px, the top and the end (four companions: devoted, friendly, neutral, wary; two seated, two benched). |
| `docs/ux-shots/companion-a.png` | A: the same list, calmer, with a seat strip and a one-tap swap. |
| `docs/ux-shots/companion-b.png` | B: a different shape: the party as a formation, a page for each companion, who is not (or no longer) with you; the guide dog's page. |

## What is hard, ranked by how much it hurts the player
1. **Changing a seat is slow and silent.** With the seats full, every benched card shows a disabled
   chip and the line "Active party is full"; nothing says how to swap. To swap you bench one companion
   (a tap on a chip, in one card), scroll, then seat the other (a tap in another card). Two taps on two
   cards, with a scroll between, for the action the page exists for.
2. **The seats themselves are not shown.** "Active Party: 2 / 2" sits at the right of the heading; the
   party as it will fight (who, their health) must be read off the cards. The roster is in id order
   (Grosh, Kelda, Maren, Sable), so seated and benched are mixed.
3. **The "Benched" chip cannot be read.** It is disabled when the party is full, and its text is
   white-ish on light (the capture shows an empty pill). The most important state of a companion is the
   least legible.
4. **Approval: the effect is told, the cause is not.** A card has a word, a bar, an effect line and a
   likes line: "Wary · −10% damage in fights; leaves if pushed further", "Likes: kindness".
   Nothing says how far "further" is (it is −12), where the next tier is, or that **benched
   companions do not see your choices** (approval.dart), which is the reason to bench a Devoted one.
5. **A card is 330 px tall and repeats itself.** Four companions are about 1300 px; each card has the
   same disabled "Share a drink (320 gold)" row and the same "Active party is full". At 320 px the
   name, class and health wrap to three lines.
6. **Nothing says what a companion has.** Their die, their skills, the points waiting to be spent and
   their gear are behind three text buttons (Gear, Skills, Dice); the card shows none of it. A skill
   point waiting is invisible.
7. **Who is not here does not exist.** A companion not yet met, one locked behind a building (Kelda
   needs her Hall, told only on a recruited card), and one who left or was lost have no trace on the
   page. The dog, earned in the second town, will have no "to find" either. The third seat is not
   hinted.
8. **Health is a number** ("22 / 48 HP"), no bar; a hurt companion looks like a healthy one.

## A. The same list, calmer (`companion-a.png`)
- A **seat strip** on top: the party as it fights (portrait, health bar), the third seat locked with
  its building. Seated companions first; the bench under its own heading ("they miss your choices").
- **One tap to swap:** "Swap in" on a benched companion; with the seats full a sheet asks "Who steps
  out?" (one more tap). The "Benched" chip becomes a readable button.
- **A row says more in less:** the tier as a chip, health as a bar, the die by name, skills known and
  "N to learn", Gear / Skills / Dice as three small buttons with a gold dot when a point waits. "Share
  a drink" appears only when it can be done.
- Cost: UX only (`camp_screen.dart`'s `_AllyCard`, Core's file for behaviour: the seat and drink logic
  is kept, `_setAllyInParty`, `_joinState`).

## B. A formation and a page each (`companion-b.png`)
- **The party screen:** the seats as large portraits with health and tier; the bench as a small grid
  (tap to open); below, **"Not with you"**: a "???" with the quest to find them (from
  `recruitQuestId`), and who left.
- **A companion's page:** their portrait, health, the seat button; approval as a **meter with its
  thresholds named** (leaves at −12, wary at −5, friendly at 5, devoted at 12), what the tier
  does, likes and dislikes as chips, and the line that benched companions do not see your choices; then
  their die (look and name, a tap opens the ring), skills, gear.
- **The guide dog's page** (last frame): Wick, his sprite from the tutorial, "Guide dog · found in
  Saltmouth", a seat, a bench, the Hound Die. His numbers and die are Core's (#568), his quest (Wick's
  Walk) Narrative's (#569); his likes and dislikes are not set yet.
- Cost: a new page and a rebuilt Party tab: about two days of UX, more than A.

## What each needs from Core
- **A:** nothing.
- **B:** nothing for the screens. The dog is in Core's note (#568: no race, class ranger, `hound_die`,
  about 42 health at level 8) and Narrative's (#569: Wick's Walk, Saltmouth); what is still open for
  Core is his likes and dislikes (approval weights) and whether his page shows a class at all (the
  picture shows none, only "Guide dog"). For "Not with you": whether to show a companion not yet met as a "???" (a spoiler
  question for the story) and a record of who left (today `loseAlly` drops them; a list of the lost,
  with the reason, would feed the "left" row).
- **UX:** a portrait per companion. Today only the class mark exists; the dog has its sprite.

## Recommendation
Ship **A** first (small, fixes 1 to 3, 5, 6 and 8), then **B**'s page for a companion as the place the
approval meter, the die and the dog live (fixes 4 and 7).

## Questions for the user
1. A, B, or A now and B's page later?
2. Should companions not yet met show as a "???" with their quest, or stay hidden until found?
3. Should a lost companion stay on the page (greyed, with why)?
