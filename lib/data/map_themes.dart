/// A "map" here is not an alternate narrative — the 5 fixed main story
/// beats per chapter (see chapter_spine.dart) stay identical across every
/// theme. What changes is the flavor of the procedurally generated
/// excursion nodes [SubNodeEngine] inserts between those beats: the same
/// shop/enemy/quest/generic excursion *mechanics*, described with a
/// different setting and mood.
enum MapTheme { ashenStreets, saltRoads, hollowReaches, wildsBeyond }

const MapTheme defaultMapTheme = MapTheme.ashenStreets;

String mapThemeLabelKey(MapTheme theme) {
  switch (theme) {
    case MapTheme.ashenStreets:
      return 'map_theme_ashen_streets';
    case MapTheme.saltRoads:
      return 'map_theme_salt_roads';
    case MapTheme.hollowReaches:
      return 'map_theme_hollow_reaches';
    case MapTheme.wildsBeyond:
      return 'map_theme_wilds_beyond';
  }
}

class ExcursionFlavor {
  const ExcursionFlavor({
    required this.shop,
    required this.enemy,
    required this.quest,
    required this.generic,
  });

  final List<String> shop;
  final List<String> enemy;
  final List<String> quest;
  final List<String> generic;
}

ExcursionFlavor flavorFor(MapTheme theme) {
  switch (theme) {
    case MapTheme.ashenStreets:
      return _ashenStreets;
    case MapTheme.saltRoads:
      return _saltRoads;
    case MapTheme.hollowReaches:
      return _hollowReaches;
    case MapTheme.wildsBeyond:
      return _wildsBeyond;
  }
}

const _ashenStreets = ExcursionFlavor(
  shop: [
    'A stall has been set up in a doorway, its owner watching the street more than the goods.',
    'Someone has laid out wares on a cart, calling out to anyone who passes.',
    'A shopfront, half-boarded, is still somehow open for business.',
    'Lantern light spills from a half-hidden storefront tucked between the ruins.',
  ],
  enemy: [
    'Something moves in the shadows ahead, blocking the only clear path.',
    'A figure steps out, weapon already drawn.',
    'A low growl rises from the debris just off the path.',
    'Footsteps close in fast from behind — there is no time to think.',
  ],
  quest: [
    'Someone catches your sleeve, desperate and low-voiced, with a job that needs doing.',
    'A notice is nailed to a post, offering coin for a task nobody else wants.',
    'A stranger falls into step beside you, explaining what they need before you can refuse.',
    'A voice from an alley asks — carefully — if you are willing to help.',
  ],
  generic: [
    'The path continues, quiet for now.',
    'Nothing moves here but the wind through broken shutters.',
    'A moment of stillness before the road presses on.',
    'The street is empty, save for the echo of your own footsteps.',
  ],
);

const _saltRoads = ExcursionFlavor(
  shop: [
    'A dockside vendor has strung nets full of trinkets between two mooring posts.',
    'Barrels of salted goods sit stacked outside a low, sea-worn shopfront.',
    'A trader calls out over the creak of rope and tide, wares spread on a tarp.',
    'Lantern-lit stalls line the pier, smelling of brine and old rope.',
  ],
  enemy: [
    'A shape lurches out from behind stacked crates, blade already drawn.',
    'The tide brings something ashore that should not be moving.',
    "A gull's cry cuts short as something larger moves beneath the pier.",
    'Footsteps on wet planks close in from the fog.',
  ],
  quest: [
    'A weathered sailor grabs your arm, muttering about a debt owed and a job to settle it.',
    'A notice, half-soaked, is pinned to a mooring post offering coin for passage-work.',
    'A dockhand sizes you up before asking if you are free for hire.',
    'Someone in oilskins steps from the fog with a task too urgent to explain twice.',
  ],
  generic: [
    'The boards underfoot creak with the pull of the tide.',
    'Salt air and gull cries are the only company on this stretch.',
    'The road runs along the waterline, quiet but for lapping waves.',
    'Fog rolls in off the water, swallowing the road ahead and behind.',
  ],
);

const _hollowReaches = ExcursionFlavor(
  shop: [
    'A hunched figure trades wares from a cart wedged between two crumbling tombs.',
    "Candlelight flickers over a merchant's blanket spread across cold stone.",
    'A peddler has set up shop beneath a cracked archway, goods laid on old bones.',
    'Someone has strung a lantern over a stall built from salvaged coffin wood.',
  ],
  enemy: [
    'Something shifts among the shattered urns, dragging itself toward the light.',
    'A low moan echoes from deeper in the passage, drawing closer.',
    'Cold hands close around nothing, then everything, in the space ahead.',
    'The candle gutters as something unseen closes the distance fast.',
  ],
  quest: [
    'A cloaked figure whispers from an alcove, offering coin for silence and a task.',
    'A scrap of parchment is nailed to a coffin lid, offering payment for grim work.',
    'Someone in mourning black steps from the shadows with an urgent, quiet plea.',
    "A gravekeeper's voice carries from the dark, asking for help nobody else will give.",
  ],
  generic: [
    'The passage narrows, and the air grows colder still.',
    'Somewhere unseen, water drips against stone in a slow, patient rhythm.',
    'Candle-stubs line the walls, most of them long since burned out.',
    'The silence here presses close, broken only by your own footsteps.',
  ],
);

const _wildsBeyond = ExcursionFlavor(
  shop: [
    'A traveling peddler has parked a cart beneath the trees, wares hung from the branches.',
    "A trapper's camp doubles as a stall, furs and tools spread on a fallen log.",
    'Smoke curls from a small clearing where a merchant has set up for the day.',
    'A hand-painted sign points toward a stall tucked just off the trail.',
  ],
  enemy: [
    'The undergrowth shudders, and something far too large steps into view.',
    'A snarl rises from the treeline before its owner is even seen.',
    'Branches snap somewhere close, closing the distance fast.',
    'Eyes catch the light from the shadows between the trees.',
  ],
  quest: [
    'A ranger flags you down, asking for help before you can walk on.',
    'A carved marker points to a message begging for aid, signed only with a name.',
    'A traveler falls into step alongside you, explaining a task with obvious relief.',
    'Smoke on the horizon turns out to be someone in need of exactly your kind of help.',
  ],
  generic: [
    'The trail winds on, birdsong the only sound for a while.',
    'Sunlight breaks through the canopy in shifting patches.',
    'The path is quiet here, the wilds holding their breath.',
    'Wind moves through the leaves, and the road continues.',
  ],
);
