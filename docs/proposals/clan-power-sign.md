# The clan power sign, three other ways (UX, pictures only, nothing built)

The user: "Propose other ways to show a clan's power; the banner filling itself, its meaning is
not clear in game." Today's sign is the power cloth of v1.576 (`clan_glance.dart`). Mock test:
`test/ux_clan_power_mock_test.dart` (parts: `ux_clan_power_parts.dart`, `ux_clan_power_scenes.dart`).
Strengths are sample numbers (the clans' starting powers moved a little); the real banners and the
real standing discs are drawn.

Pictures, in `docs/ux-shots/clan-power/`: `compare.png`, `idea-a-ranking.png`,
`idea-b-torches.png`, `idea-c-skyline.png`. Each idea picture shows the four places where a clan's
power shows, at 412 and 320 px: the clan list, a clan's page (Crows), the banner chip (an offer's
giver, a line of news) and the district view (six districts washed in their holder's colour).

## Today's cloth, and what is unclear (`compare.png`)
The banner is black cloth with cream marks; the cloth hides everything above the clan's tier (a
quarter for each of Minor, Rising, Dominant, Ascendant) and a gold hairline marks the level.
- It reads as a loading bar or as damage, not as strength; nothing on it says "power".
- Four steps only: 26 and 49 look the same, so do 0 and 24. It cannot say rising or falling.
- A weak clan loses its sign: a Minor clan shows only its foot, so the clans the player must still
  recognise (Kindly Ones, Oni) become unreadable, most of all at 34 px.
- A clan with no power (Choir, Pit, Open Hand) keeps a whole banner, so it looks the strongest.
- It cannot be compared (open every clan to rank them) and nothing marks the 10 power a clan
  needs to attack.
- Two gauges on one banner, the cloth and the standing disc, both read as "how full": strength
  gets mixed up with how the clan likes you.

## What each idea answers
All three keep the banner whole and its corner for the standing disc, use neutral gold and a cold
blue-grey (never the standing's green and red), and mark the 10 power a clan needs to attack and
the tier lines (25, 50, 75).

| | How strong | Against the others | Rising or falling | Attack line |
|---|---|---|---|---|
| **A. Ranking** | the number and the rank | the rank, and a page of bars of every clan | an arrow and the change | dashed line on the bars |
| **B. Torches** | torches lit (4, one per 25) | the torches of the other rows | an arrow beside them | an ember instead of a flame under 10 |
| **C. Skyline** | height | all clans stand in one row, strongest first | gold edge up, dashed outline down | dashed line across the skyline |

### A. Ranking: a place in the line, and an arrow
Every clan wears a small dark plate with its rank and an arrow ("#2 ▲"); the list shows the rank,
the power and the change; a clan's page ranks all ten clans in bars, this clan's row framed, with
the tiers and the attack line marked; the chip is the plate; a district's seat wears it.
Exact and the best for comparing; it has to be read, and a rank says nothing about how far ahead.

### B. Torches: how many are lit
Four torches beside the banner, one for each 25 power, each lit as far as the power has reached it
(a part flame for the part); under 10 power the first is only an ember. The page says the tier,
the change, whether the clan can attack, its rank and when the next torch is full. Reads at once
and fits any chip (14 px); it compares only by looking from row to row.

### C. Skyline: the stronger, the taller
Banners stand on one ground line as tall as the clan is strong, strongest first. The list opens
with the skyline of all the clans; the page shows it with this clan underlined; the chip carries
ten tiny bars with the clan's in gold; in a district the banner planted at the seat is as tall as
its clan. A gold edge is what a clan gained since the last chapter, a dashed outline what it lost.
The only one that compares, shows the gap and the change at once; at 320 px the tallest banner is
limited by the width of ten slots (56 px) and the bars of a chip are tiny.

My read: **C** answers the three questions in one picture and is the one the player will
understand without a legend; **A** is the exact and safe one (and its page of bars could join C);
**B** is the friendliest for a chip. A and C can be combined (the skyline in the list, the plate
and bars on the page).

## What each needs
- **Core, for the arrows and the gold edge/outline**: the power of each clan at the previous
  chapter's turn (one number a clan, e.g. `powerAtTurn`), set at the same moment the chapter's
  powers move. Everything else (rank, tiers, the attack line `>= 10`) comes from today's numbers.
- A legend: one line on the clan page (drawn in each picture); nothing else.
- Retire the cloth (`PowerCloth`, `ClanCloth`, `ClanMarks.cloth`) when one of these is built.
