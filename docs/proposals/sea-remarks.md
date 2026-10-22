# Companion remarks at sea (Narrative)

`sea-remarks.json`: 3 lines (EN and FR) for each of the 8 companions, trigger `atSea` (the kind in Core's hooks PR #465), one record `<companion>_atSea` each, in the shape of `companion_remarks.json`. Not in that file yet: the kind is not on main until #465 merges, and `companion_remarks_test` rejects unknown triggers. Once it is, I move them in as a data-only PR (version from the manager), opened after UX's sea item. The lines name no place or number, so they fit any voyage; French addresses the player as « vous » (none addresses them at all).
