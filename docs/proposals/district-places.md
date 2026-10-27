# The district view as places, not choices (UX mock, nothing built)

Picture: `docs/ux-shots/places-mock.png`. Mock test: `test/ux_places_mock_test.dart`.
The header and the map are the real screen at the High Quay (`docs/ux-shots/places-today.png`,
scene 891); the pins, rows and the street view are drawn with the app's own widgets
(`BannerPin`, `StreetViewScene`), the pins hand-placed for the mock.

## The user's call
"The player chose first to go to the location and once clicked go see the choices. So
remove the choices from the list below and add the location instead of the node itself,
since for now it doesn't match."

## What the mock shows
1. **The district as places.** The pins and the rows are the same places in the same order.
   A row: the place's name, a small count of the things to do there, a flag where the story
   goes on (the Lark's gangway), and a padlock (greyed, with its reason) for a place you
   cannot enter yet. No choice text anywhere in the list.
2. **The tap.** The party's mark walks to the pin along a dotted path (0.6 to 1.2 s, as the
   walk already does); the row lights and says where it is going; a tap skips the walk.
3. **The arrival.** The street view opens on the place with its choices as pins in the
   street and the scene's words in a band over the sky (the answers in
   `ux-presentation-answers.md`); a tap on the band opens the sheet; an arrow goes back to
   the district.
4. **A way with no place of its own** (see the table).

## The High Quay, as the data stands (scene 891)
The hub has five ways. Four of them loop back to 891 (heal with sailcloth, take a blade from
the looted armory, take a buckler from the shieldwright's cart, whistle for the hound) and
one leads to 895 (the mate at the gangway, the main story). The four are acted out where the
party stands, so today they are cards, and only the plan decides which building a pin stands
on (`buildingOfWay`: the scene's anchor, else a building picked by the scene's id). The
places in the mock are read off the ways' own words; nothing in the data names them yet.

| A way that has... | Proposed |
|---|---|
| a place (a building, a spot) | a row and a pin, counted with the place's other things |
| a road, a gate, a way out | a row under WAYS OUT with where it leads and how; the pin on the district's edge (what the walk-to-a-neighbour rows already are) |
| a thing done where you stand, no building ("Whistle for the hound") | a thing of HERE, the first entry (the party's own place), opened as the sheet over the map, no walk |
| a fight, a check or a payment | always a thing of HERE, counted there; its street pin carries a small crossed-blades badge |
| a place you cannot enter yet | greyed row and pin with a padlock and the reason; not counted |
| only a stand-in building (about 329 ways today are hashed to a random one) | HERE, never a wrong place, until it gets a real one |

## Core's rules (§6 of `presentation-contract.md`), which the mock follows
- One entry per place, with its name (the plan's `names`, else the geography building's) and a count.
- **HERE is one entry, first:** the party's own place, holding the on-the-spot choices.
- **The main mark** goes to an entry holding a way to a spine beat or a main-story scene; main entries sort first after HERE, the rest by distance; a locked one greyed last.
- **Leaving the city:** one entry per district gate or road, at the district's edge, never on a building.
- **The 329 hashed ways go to HERE** until they get a real place.
- **Flow:** tap an entry, the party walks there (the existing city walk), that place's ways show (street pins or cards), taking one opens the next scene in its own view. On Core's side it is a view state (the place the party stands at), not saved.

Caveat the mock states: at the High Quay all five ways of scene 891 lead back to the building the party stands at (254 ways are "here" choices like this), so with today's data they would all sit under HERE. The places in the picture (the sailcloth rigging, the looted armory, the shieldwright's cart) exist only once Narrative names a place for each choice.

## What it needs
- **Core:** a name for each way's place (a place id on the way, or derive it from the anchor
  and Narrative's `names` of the buildings), whether a way carries the party or stays, and the
  count per place. The grouping already exists for the pins (`groupWaysByPin`, v1.561).
- **Narrative:** names for the places that have none (the sailcloth rigging, the shieldwright's
  cart are my words, read off the choices).
- **UX (this PR's build, if approved):** the place rows and the sections, the pin labels, the
  tap-to-walk-then-arrive flow. About a day and a half, after Core's field.

Consistent with `presentation-contract.md` (Core) and `ux-presentation-answers.md` (#535).
