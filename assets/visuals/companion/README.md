# Walking companion sprite frames

Drop your walk-cycle PNG frames in this folder, named in order:

```
walk_01.png
walk_02.png
walk_03.png
...
```

Any number of frames works — just keep them zero-padded and sequential
starting at `walk_01.png`. The character should face **left** in the
source art, since the in-app animation walks right-to-left (east to
west) across the screen.

Once frames are added here, `lib/widgets/walking_companion_strip.dart`
is wired up to cycle through them instead of the hand-drawn placeholder
dog.
