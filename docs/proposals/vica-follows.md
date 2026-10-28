# Vica follows the hero's sprite in the scenes (UX mock, nothing built)

Picture: [vica-follows.png](../ux-shots/vica-follows.png). Mock test:
`test/ux_vica_follow_mock_test.dart`. The scenes are the real ones (the street at the door, the
land walk's side view, the story page's strip); only the follower layer is drawn in, from the
dog's own frames (`assets/visuals/companion/dog_companion_animations`: 8 walking frames, the
sitting pose, the bark). The user's rule, as the manager relayed it: the dog is **Vica**, the same
dog as in the tutorial; she follows the hero once she is seated in the party (Saltmouth, chapter 2),
none before. Pictures only.

## Which components draw the hero today

| Scene | What draws the hero | The hero's art |
|---|---|---|
| **Street** (journey door scene; intro memories draw it with `party: false`) | `streetParty` in `lib/widgets/street_view/street_view.dart`, the actors layer of `StreetViewScene`: a 6x9 pixel figure with the red cloak and pale hat, beside the door. | procedural pixels |
| **Land walk** (desert, cliffs, fen, frost, ruins kits) | `desertActors` and the other kits' actors layers; the ronin is `SideSprites.paint` (`side_sprite.dart`, `assets/visuals/walker`). | the user's ronin sprite |
| **Ship deck** | `deck_crew.dart`: cloaked figures, the hero with a pale hat. | procedural pixels |
| **Story page** | no hero. `WalkingCompanionStrip` (`lib/widgets/walking_companion_strip.dart`, in `story_player_screen.dart`) draws **the dog alone**, sitting at the left edge, walking off and back on each page. | the dog's frames |
| **Rooms** | a plan (`RoomPlanPainter`), no figures. | none |

## What it takes

1. **One follower layer** (a new `lib/widgets/side_view/side_follower.dart`, UX): loads the dog's
   frames once, as `SideSprites` does, and paints a pose at a scene pixel (x, feet): sit, trot (8
   walking frames), alert (bark). The same scale factor for every pose, as the page strip does, so
   she keeps one size.
2. **Street**: one call in `streetParty` (or the layer next to it) places her beside the hero.
3. **Land walk**: the walking party already seats companions behind the hero
   (`walkingPartyOf`, `walkingPartyXs`). A companion with no sprite is drawn as a cloaked
   placeholder with a human face chosen from the id (`partyLookFor`), which is what Vica would
   get today (left picture of the road row). `hasWalkSprite('companion_vica')` returns true and
   the follower layer replaces the placeholder in each kit's actors layer.
4. **Deck**: the same layer in `deck_crew.dart` if she should stand on the Eel's deck.
5. **Story page**: see the question below.
6. **Assets**: the walking frames exist for east, west, north and south; only east is used. A west
   cycle would let her face the hero when the walk turns back. Each leaf folder needs its entry in
   `pubspec.yaml`.
7. **Gate**: show her only when `activeAllyIds` holds her id and she is not lost or departed
   (the same test as `walkingPartyOf`); the Settings toggle for the page strip stays an off switch.

No logic or data is needed from Core beyond her companion id (`vica` once Narrative renames the
dog). Size: one new file, about 80 lines, and one line in each scene.

## Question: the story page strip

Today the strip shows the dog from the first page of the game, because it is the tutorial's guide
and the Settings toggle is on by default. The rule says none before Saltmouth. Options:

- **A**: keep the strip as the tutorial dog until the tutorial ends, then hide it until Vica is
  seated; then show her with the hero beside her (right picture of the page row).
- **B**: leave the strip as it is (the dog is the page's mascot, not Vica) and let Vica follow only
  in the street and the walk.

I lean to A: one dog, one story.

## Rooms

There is nothing to follow in a room plan. A paw mark by the hero's marker is the only way; not
drawn.
