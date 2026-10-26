# "A Life Before This One" as scene pages (UX proposal, for the user to approve)

Nothing is built. The mock is `docs/ux-shots/life-scenes-mock.png` on this branch (`claude/ux-life-scene-mock`), made by `test/ux_life_scene_mock_test.dart` with `UX_SHOTS=<folder>`. It shows two memories with their real words: The Sparrow (age 6, the first page, with the street kit behind it: the rope-walk's front in the rain) and The Frozen Well (age 8, mid-way through the writing-out, with the frost kit behind it).

## The plan, in one paragraph

Keep the feature exactly: six memories from age 6 to 16, the age rail, each answer's +1 stat chip, "Choose my whole life at random", "Choose again at random", the recall line, the outcome and the summary, with the same text and the same logic. Change only the presentation of `_buildMemory` and `_Outcome` in `lib/screens/origin_stories_screen.dart`: each memory becomes a scene page like the story reader's. A side-view backdrop of the memory's place (the street kit of v1.544 for the gutter behind the rope-walk and the Blind Beggar's door, the frost kit for the frozen well, and the sea, fen, cliffs, desert and ruins kits for the others; a small table from memory id to kit, hour and weather, in a UX-owned file) fades into the page, with the age and stage and the title over its foot; the rail stays, small, under it; the scene's words are set in the reader's prose, no card, and write themselves out with `StoryText` (a tap finishes them; with reduced motion they are there at once); the answers, as choice cards with their stat chip, come when the text has been written, as in the reader; after an answer the outcome is written out on the same page, with the lean chip, and "Next memory" under it. The recall line stays as an italic line over the scene. The summary page is unchanged. Core's screen is touched in two methods; the backdrop table and the page widget are new files in `lib/widgets/`; the existing test keys (`origin_random_all`, `origin_answer_selected` and the rest) are kept. It needs nothing from Core or Narrative.

## What it reuses

- The side-view engine and its kits, and the street kit (v1.544) with its weather and hour.
- `StoryText` (the typewriter), `storyTextDoneProvider` (the answers wait for the text), `AbilityPill` (the chip), the age rail (shrunk).

## Notes for the user

- The data has **three** answers per memory (good, neutral, evil), not two; the mock shows three.
- Fourteen memories exist (six are played: the race decides the age-8 one, the profession the age-12 one). Each needs a backdrop, so the table has fourteen rows; I would pick them by reading each memory's place and send the list for Narrative to check against their wording.
- The street kit has six fronts, so a memory in a house, a tavern or a warehouse is easy; "the frozen well", "the net-mender's" (the sea or the cliffs) and "the sleeper under the altar" (a temple front) are the ones to look at in a first build.
