# Building screen (G): category names and blurbs

Narrative, for Core and UX. Text for the four categories of
[building-screen.md](building-screen.md) (on `claude/core`), English and French,
ready to paste into `app_strings.dart` under whatever keys UX picks (suggested:
`works_category_<category>` for the name and `works_category_<category>_blurb`
for the line). Names are short enough for a section header; the blurb is one
line under the header.

| `category` | Houses | Name (EN) | Name (FR) |
|---|---|---|---|
| `sea` | the Harbor | The Sea | La Mer |
| `company` | Barracks Annex, Kelda's Hall | The Company | La Compagnie |
| `workshops` | Hammersmith, Academy, Needle House, Smugglers' Cellar | The Workshops | Les Ateliers |
| `greatWorks` | Hearth-Hall, Banner Loft, Shroud Shrine | The Great Works | Les Grands Ouvrages |

| `category` | Blurb (EN) | Blurb (FR) |
|---|---|---|
| `sea` | What the Rusty Eel needs to put out: a quay, a yard, a berth. | Ce qu’il faut au Rusty Eel pour reprendre la mer : un quai, un chantier, un poste d’amarrage. |
| `company` | Roofs for the people who follow you, and a home for some of them. | Des toits pour ceux qui vous suivent, et un foyer pour certains d’entre eux. |
| `workshops` | Four houses that sell the camp what the road does not give. | Quatre maisons qui vendent au camp ce que la route ne donne pas. |
| `greatWorks` | What is built to outlast you: the hearth, the banner, the shrine. | Ce qu’on bâtit pour vous survivre : le foyer, la bannière, le sanctuaire. |

Notes for whoever pastes them:

- French typography: the space before `:` in the `sea` blurb is a non-breaking
  space (` `) in the string, and apostrophes are curly (`’`).
- "The Sea" is a deliberate plain name for a one-house category; if UX prefers
  the house's own name as the header ("The Harbor"), the blurb still works.
- If a category can be empty for a save (no companion recruited, so no
  company house yet), the header can hide; the blurb is written to stand
  alone either way.
