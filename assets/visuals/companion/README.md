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

The `rotations` folders of `Sitting_down`, `Make_it_with_angel_w` and
`Make_it_with_demon_w` ship only `south.png` (the one pose the game reads),
and `Fight_-_Attack/` is source art for `tool/gen_fight_heads.py` (Vica's
head), not shipped; the rest stays here in case a pose is wanted later.
`pubspec.yaml` lists the single files, and `test/qa_assets_declared_test.dart`
names the folders that are source only.
