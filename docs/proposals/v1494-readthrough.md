# Read-through of the temple and roll-house texts in v1.494 (Narrative)

Read from `docs/qa/smoke/` (temple sheets EN/FR, camp cards, roll power row, risky offer reward).

## Reads well, no change
- The temple sheet rows: price, then the description or the grants line, then "+1 standing, once a chapter". The line break join works; no stray full stops.
- The neutral temple (FR and EN): the plain blessing line, and the town shrine's name.
- "Already mended today. A night's rest opens it again." above the Mending description when greyed out.
- The roll power row ("Relancer (3)", "Écarter (2)", "Hausser (1)"), greyed when no charge is left.
- The risky reward after a bad die ("The price is paid in blood: −40 health.") and its "Risky" tag.

## Wording I would change (all small; none needed before a release)
1. **The keeper's line is never shown.** `templeLine` (each clan's offer, EN/FR) is written but the sheet only shows the temple's name, the prices and the grants. Showing it as one italic line under the name would give each temple a voice; the Hunted refusal already uses `templeLineHunted`. Core/UX call.
2. **The blessing has no name on the sheet.** The row says "Blessing" / "Bénédiction", while `blessingName` ("The Ledger's cover", "La couverture du Registre") exists. Showing it as the row's title when a clan rules the town, and "Blessing" at a neutral temple, would make the clans' temples feel different. Same call as 1.
3. **Star Well card in the smoke picture reads "Le puits aux étoiles".** The data already says "Le Puits aux étoiles" (v1.491), so the picture predates it; re-take it when convenient. The same goes for "La tente de pourparlers", "La hutte du jeteur d’os" and "Le cairn de garde".
4. **"Déjà guéri aujourd’hui"** is the one French line that agrees with a masculine party; I would leave it (the party is a group, so the masculine is the neutral form).
