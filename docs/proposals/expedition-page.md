# The expedition as a page (UX proposal, for the user to approve)

Nothing is built. The mock is `docs/ux-shots/expedition-page-mock.png` on this branch (`claude/ux-expedition-scene`), made by `test/ux_expedition_mock_test.dart` with `UX_SHOTS=<folder>`. It shows The Drowned Stair's real title and intro, a step rail (four events and a boss crown), one scene card and two choice cards with effect chips; the scene and choice text is sample text.

## The plan, in one paragraph

Today an expedition event is `ExpeditionScreen._buildEvent` in `lib/screens/expedition_screen.dart`: a progress bar, a "Stage n / N" label, a goal line, the event's text in a scroll, plain buttons for the choices and a Retreat button. The backstory page ("A Life Before This One", `origin_stories_screen.dart`) has the look the user wants. I would give `_buildEvent` that look through a new `lib/widgets/expedition_scene_page.dart`: the zone title and a short intro (today's goal line), a step rail (the backstory's `_AgeTimeline` moved to a shared widget and labelled with stage numbers, the boss as a crown), the event in one bordered scene card (aftermath, check result and kind note above it), choice cards whose effect chips come from the choice's own data (gold, heal, alignment, the check's ability and DC, a fight or an item it triggers; nothing for outcomes the data does not state), a fade between steps, and Retreat as a text button. All logic in `_advance` and `_resolveChoice`, the escort and delivery gauges, and the locked-choice rule stay as they are. Core owns the screen, so I would touch `expedition_screen.dart` only in `_buildEvent` and list the lines in the PR; the backstory file loses its private timeline to the shared widget. It needs nothing from Core or Narrative.

## What it reuses

- `_AgeTimeline` (origin_stories_screen.dart): the rail, made public and labelled.
- `AbilityPill` (ability_visuals.dart): the effect chips.
- The scene card and the answer card shapes of the backstory page, and its fade between steps.

## Questions for the user

- Should the escort's cargo bar and the delivery's day count sit under the rail (my plan) or on the choice cards?
- Chips for a choice's hidden outcomes (a roll's reward, a trap) show nothing: is that right, or should the card say "unknown"?
- A zone has 3 or 4 events and a boss (the backstory has six memories): the rail has 4 or 5 dots, not six. Fine?
