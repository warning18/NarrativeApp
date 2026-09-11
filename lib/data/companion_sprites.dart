/// Shared helpers for building companion sprite-frame paths from
/// assets/visuals/companion/dog_companion_animations/ — see that folder's
/// README for the full set of uploaded animations (Walking, Fight -
/// Attack/Bark, Sitting_down, plus a couple of unused cosmetic variants).
library;

const String companionAssetsRoot = 'assets/visuals/companion/dog_companion_animations';

/// Builds `count` sequential frame paths named frame_000.png, frame_001.png,
/// ... under [relativeDir] (relative to [companionAssetsRoot]).
List<String> companionFrames(String relativeDir, int count) => List<String>.generate(
      count,
      (i) => '$companionAssetsRoot/$relativeDir/frame_${i.toString().padLeft(3, '0')}.png',
    );
