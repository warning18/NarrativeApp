# Companion remarks for the land walk (Narrative)

`walk-remarks.json` holds 4 short lines (EN and FR) for each of the 8 companions, ready to paste into `assets/gamedata/companion_remarks.json`. Each record is `<companion>_walk` with the new trigger `walk`, in the same shape as the other records.

**Not merged into the live file yet.** `test/companion_remarks_test.dart` requires every record's trigger to be in `remarkTriggerOptions` (the `RemarkKind` names plus `choice`), so adding `walk` to the data before the code knows it would fail that test. Core needs to add `RemarkKind.walk` (and decide when it fires: a few lines per picked companion while walking, with the usual cooldown). Once that lands I move the records in, a data-only change.

The lines do not name places, people or the chapter, so they work anywhere on a road. Voices follow each companion's existing remarks (Grosh in the third person, Sable's "love", Vess's whispers).
