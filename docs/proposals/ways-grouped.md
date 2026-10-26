# The Journey's list of ways, grouped by pin (UX proposal, for the user to approve)

Nothing is built. The mock is `docs/ux-shots/ways-grouped-mock.png` on this branch (`claude/ux-ways-group-mock`), made by `test/ux_ways_group_mock_test.dart` with `UX_SHOTS=<folder>`. It shows scene 891's ways three times: today (one row each), one row per pin, and the pin opened.

## The plan, in one paragraph

Today every way under the map is a row (`_CityDistrictView`'s rows in `lib/screens/journey_screen.dart`), so a pin that holds several choices ("Whistle for the hound", with "Bind your wounds", "Snatch a blade" and "Pull a buckler") spreads over four rows and the list stops looking like the map. I would group the rows the way the map groups its pins: one row per pin, with the pin's name (the banner or disc the map draws, and the name of the way the pin stands for) and a count chip, a chevron showing that it opens; a tap opens it in place to its choices, each as the row it is today, indented, with its own small banner or disc, and a second tap on a choice does what a row's tap does today (the way's sheet). A pin with one way stays a plain row, exactly as now. Only one pin is open at a time (opening another closes the first), the open pin is tinted, the pin picked on the map opens its row and scrolls it into view, and the header line says "2 pins · 5 ways". The grouping is a pure function from the steps to pins (new, in a UX-owned file, with a test), the rows move into a small widget in `lib/widgets/`, and `journey_screen.dart` is touched only where the rows are built. Reduced motion: the row opens at once. It needs nothing from Core or Narrative.

## What it reuses

- `BannerPin` and the kind discs of the rows, the seam-ruled row, the count chip of the choice groups (`ChoiceGroupChip` looks).
- The way's sheet (`_openWay`) for a choice's tap.

## Questions for the user

- What names a pin when its ways have different names: the way that leaves the place (as in the mock), or the building's name? The mock uses the first.
- The data does not say which choices "belong to a pin" outside the map; I would group by the pin the map draws them at (the same building or spot). Is that the grouping you mean?
