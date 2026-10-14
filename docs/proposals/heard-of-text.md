# Places only heard of (H): the reasons and the warning

Narrative, for Core and UX. Final wording for the five "Mark as goal" reasons
and the Set-out warning of [heard-of-places.md](heard-of-places.md) (on
`claude/core`). Suggested keys: `heard_reason_<reason>` and `heard_setout_warning`.
`{n}` is the chapter number and `{zone}` the expedition's `zoneName`.

| `HeardOfReason` | EN | FR |
|---|---|---|
| `storyOnly` | The story will take you there. | L’histoire vous y mènera. |
| `noCamp` | Not while the story leads the way. | Pas tant que l’histoire ouvre la route. |
| `laterChapter` | Not yet: chapter {n}. | Pas encore : chapitre {n}. |
| `needsHarbour` | The Eel must sail: build the harbour first. | Le Rusty Eel doit prendre la mer : bâtissez d’abord le port. |
| `needsExpedition` | First: {zone}. | D’abord : {zone}. |

| Warning | EN | FR |
|---|---|---|
| Set out (straight there) | You have only heard of this place. The road may hold anything. | Vous n’avez fait qu’en entendre parler. La route peut réserver n’importe quoi. |

Notes:

- ` ` is a non-breaking space in the Dart string; apostrophes are curly.
- The lines are short enough for the sheet's one-line reason; none repeats the
  button's own word ("Mark as goal").
- `needsExpedition` reads as an instruction, not an excuse: it names what to do
  ("First: the Cinder Row.").
- "Not while the story leads the way" is deliberately plain for the early
  chapters, before the camp exists: the player is not yet free to choose a
  destination, and the line should not suggest they could be.
