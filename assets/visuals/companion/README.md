# Walking companion sprite frames

`lib/widgets/walking_companion_strip.dart` plays whatever frames it finds
at `assets/visuals/companion/dog_companion_animations/Walking/west/`
(`frame_000.png`, `frame_001.png`, ...) as the companion crosses the
screen. If that folder is empty, it falls back to a hand-drawn dog.

`east/`, `north/`, and `south/` frame sets are also present alongside
`west/` but currently unused — only the westward walk (matching the
screen's right-to-left crossing) is wired up. Register a folder in
`pubspec.yaml` under `flutter: assets:` before referencing it — Flutter
asset directories aren't recursive, so each leaf folder needs its own
entry.
