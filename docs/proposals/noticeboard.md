# The notice board, improved (UX proposal, for the user to approve)

Nothing is built. The mock is `docs/ux-shots/noticeboard-mock.png` on this branch (`claude/ux-noticeboard-mock`), made by `test/ux_noticeboard_mock_test.dart` with `UX_SHOTS=<folder>`. Left: today's pin and page, and the proposed pin. Right: the proposed board.

## What is weak today

The pin on the district map is a plain assignment icon, the same weight as every service; it says nothing about whether anything waits there. It opens a sheet (`town_service_sheet.dart`) with one row, "Bounty board", which opens a page of three grey cards (`bounty_board.dart`): a generic icon, a bar, a tonal Claim button that looks the same shut or open. The goal, the progress and the pay are all small; nothing makes a met contract look like something to collect.

## The plan, in one paragraph

Make it a board you read. The pin becomes a small wooden board with notes on it, with a count that says what waits (red when a contract can be claimed). A tap opens the board directly (no one-row sheet): a wooden background with the contracts pinned on as parchment notes, slightly tilted; each note has a stamp-ring icon for its kind, the goal in the book's own type at a readable size, the progress as pips (●●○) with "2 of 3" in the pixel type, the pay as two chips (gold, essence), and a wax seal that is the Claim: grey and flat while the note is open, red and glowing when it is met. A claimed note gets "PAID" stamped over it and drops off the board; a new board's notes pin up one after another. The header says the chapter and how many wait ("Chapter 2 · 1 to claim"), and the last line says when new notices go up. The data, the claim logic and the posting (`contracts.dart`, `BountyBoard._claim`) do not change. The sheet, the board page and the pin art are UX's files (`lib/widgets/`), with `town_service_sheet.dart` calling the board straight for the notice-board kind. Reduced motion: no pin-up or drop-off, the stamp appears at once. It needs nothing from Core or Narrative; the camp's own bounty board (`BountyBoard` is shared with the camp screen) would get the same look.

## Questions for the user

- Should the pin's count show contracts to claim only, or all open notices?
- Is "quests list" meant to include side quests as notices too (a quest offered by the board), or only the contracts? The mock draws contracts; side quests would be another note kind with a quill stamp, if so.
