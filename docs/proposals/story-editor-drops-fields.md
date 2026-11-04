# The story editor drops six fields of a scene when it saves

Core, 2026-11-04. Docs only, nothing changed. Found while adding
`callback_cap` and `revisit_description` (#796).

## What is lost, and when

In Edit Mode, the scene editor (`lib/screens/story_node_editor_screen.dart`,
opened from the story player's pencil and from the story graph) saves a scene
by building a new `StoryNode` field by field (`_save`, then `saveStoryNode`).
It does not pass six of the scene's fields, so **saving any scene in the
editor removes them from that scene**, even if the writer changed nothing
there:

| Field in the story file | Read as | What it does |
|---|---|---|
| `campErrand` | `campErrand`, `campErrandKind` | the scene is a camp errand (and its kind) |
| `showIfFlags` | `showIfFlags` | the errand shows only with these flags |
| `hideIfFlags` | `hideIfFlags` | the errand hides with these flags |
| `campErrandText` | `campErrandText` | the errand's line in the camp |
| `campErrandText_fr` | `campErrandTextFr` | its French |

Today 20 scenes carry all five keys: the companions' loyalty errands
(`loyal_kelda`, `loyal_sable`, `loyal_maren`, `loyal_liora`, `loyal_vess`,
`loyal_grosh` and 14 more). Saving one of them in the editor turns it into a
plain scene: the errand leaves the camp, and its flag gates are gone. The
saved story is kept on the device as the local edits
(`story_nodes_override`), so the loss persists until "Reset to the bundled
story". An export from Edit Mode carries it into the file sent back.

(`contextNote`/`contextNoteFr` are not passed either, by design: they are
never written to the story file.)

## The smallest fix

One place, `_save` in `story_node_editor_screen.dart`, passes the six fields
through as it already does for `flagCallbacks`, `scene` or `spot`:

```dart
campErrand: widget.node.campErrand,
campErrandKind: widget.node.campErrandKind,
showIfFlags: widget.node.showIfFlags,
hideIfFlags: widget.node.hideIfFlags,
campErrandText: widget.node.campErrandText,
campErrandTextFr: widget.node.campErrandTextFr,
```

Six lines, and one test so it can't come back: build the editor's node for
every scene of the story file without editing anything, and check its
`toJson()` equals the scene's own `toJson()`. That test would also catch the
next field someone adds to `StoryNode` and forgets in the editor.

The editor file is a shared screen file; the fix is Core's logic. About 30
minutes with the test, a version bump, no data change.
