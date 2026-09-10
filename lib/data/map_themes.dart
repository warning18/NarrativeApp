/// A "map" here is not an alternate narrative — the 5 fixed main story
/// beats per chapter (see chapter_spine.dart) stay identical across every
/// theme. What changes is the flavor of the procedurally generated
/// excursion nodes [SubNodeEngine] inserts between those beats: the same
/// shop/enemy/quest/treasure/rest/generic excursion *mechanics*, described
/// with a different setting and mood.
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
    required this.treasure,
    required this.rest,
    required this.generic,
  });

  final List<String> shop;
  final List<String> enemy;
  final List<String> quest;
  final List<String> treasure;
  final List<String> rest;
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
    'Someone has swept a doorway clear and set out goods atop an old crate.',
    'A one-armed trader still manages to keep a brisk trade going from a cart.',
    "A hand-lettered sign reads 'OPEN' above a door that barely still hangs.",
  ],
  enemy: [
    'Something moves in the shadows ahead, blocking the only clear path.',
    'A figure steps out, weapon already drawn.',
    'A low growl rises from the debris just off the path.',
    'Footsteps close in fast from behind — there is no time to think.',
    'Rubble shifts underfoot, and something beneath it does not like being disturbed.',
    'A pair of eyes catch torchlight from a collapsed doorway.',
    'The alley ahead goes suddenly, unnaturally quiet.',
  ],
  quest: [
    'Someone catches your sleeve, desperate and low-voiced, with a job that needs doing.',
    'A notice is nailed to a post, offering coin for a task nobody else wants.',
    'A stranger falls into step beside you, explaining what they need before you can refuse.',
    'A voice from an alley asks — carefully — if you are willing to help.',
    'A child tugs at your coat, pointing urgently down a side street.',
    'Someone leaves a folded note in your hand without breaking stride.',
    'A voice calls down from a broken balcony, offering coin for a favor.',
  ],
  treasure: [
    'Something glints beneath a fallen beam, half-buried in ash.',
    "A loose stone in the wall hides a small stash, forgotten by whoever left it.",
    "A dead man's pocket, picked over once already, still holds a few coins.",
    "Tucked behind a chimney, a tin box rattles with something inside.",
    'A crushed strongbox has spilled part of its contents across the cobbles.',
    "Something catches the light at the bottom of a dry well.",
    "A loose floorboard creaks, hinting at what's hidden beneath it.",
  ],
  rest: [
    'A sheltered doorway, out of the wind, offers a moment to catch your breath.',
    'An abandoned hearth, long cold, still makes for a decent place to sit.',
    'A quiet rooftop, reached by a half-collapsed stair, is worth the climb.',
    'The ruins of a chapel offer silence enough to rest, if not comfort.',
    'A stretch of unbroken wall blocks the wind long enough to recover.',
    'An overturned cart makes an unlikely but serviceable windbreak.',
    'The husk of a bathhouse still holds a little warmth in its stones.',
  ],
  generic: [
    'The path continues, quiet for now.',
    'Nothing moves here but the wind through broken shutters.',
    'A moment of stillness before the road presses on.',
    'The street is empty, save for the echo of your own footsteps.',
    'Ash drifts down like slow snow, settling on everything it touches.',
    'A cracked bell somewhere tolls once, then falls silent.',
    'The road forks briefly before rejoining itself further on.',
  ],
);

const _saltRoads = ExcursionFlavor(
  shop: [
    'A dockside vendor has strung nets full of trinkets between two mooring posts.',
    'Barrels of salted goods sit stacked outside a low, sea-worn shopfront.',
    'A trader calls out over the creak of rope and tide, wares spread on a tarp.',
    'Lantern-lit stalls line the pier, smelling of brine and old rope.',
    'A one-eyed trader hawks salvage from a sun-bleached table.',
    'Rope-strung shelves sway with the wind, hung with trinkets and tools.',
    'A weathered sign nailed to a post points toward a floating market stall.',
  ],
  enemy: [
    'A shape lurches out from behind stacked crates, blade already drawn.',
    'The tide brings something ashore that should not be moving.',
    "A gull's cry cuts short as something larger moves beneath the pier.",
    'Footsteps on wet planks close in from the fog.',
    'Something surfaces just past the breakers, watching before it moves.',
    'A shape detaches itself from the shadow of a beached hull.',
    'The creak of rigging masks footsteps closing in from the dark.',
  ],
  quest: [
    'A weathered sailor grabs your arm, muttering about a debt owed and a job to settle it.',
    'A notice, half-soaked, is pinned to a mooring post offering coin for passage-work.',
    'A dockhand sizes you up before asking if you are free for hire.',
    'Someone in oilskins steps from the fog with a task too urgent to explain twice.',
    'A harbor child presses a folded scrap of paper into your hand and runs.',
    'An old captain waves you over, a job already half-explained before you arrive.',
    'Someone at the tideline calls out, offering coin for an errand along the coast.',
  ],
  treasure: [
    'A half-buried chest, waterlogged but intact, pokes out of the sand.',
    'Something metallic winks from a tide pool.',
    "A washed-up crate has split open, spilling part of its cargo.",
    "A diver's cache, long forgotten, sits wedged beneath a piling.",
    "A gull picks at something shiny it clearly can't eat.",
    "An old ship's strongbox lies wedged between the rocks.",
    "A fisherman's net has hauled up more than fish this time.",
  ],
  rest: [
    'A sheltered cove, out of the wind, is a good place to sit a while.',
    'An upturned boat hull offers shade and a moment\'s rest.',
    'A quiet stretch of pier, away from the noise, invites a pause.',
    'A driftwood fire, still smoldering, warms a spot on the sand.',
    'A sun-warmed rock offers a comfortable place to rest tired feet.',
    "A fisherman's shack, empty for now, is dry enough to shelter in.",
    'The lee side of a dune blocks the worst of the wind.',
  ],
  generic: [
    'The boards underfoot creak with the pull of the tide.',
    'Salt air and gull cries are the only company on this stretch.',
    'The road runs along the waterline, quiet but for lapping waves.',
    'Fog rolls in off the water, swallowing the road ahead and behind.',
    'Gulls wheel overhead, indifferent to the road below.',
    'The tide has left a line of debris marking how far it once reached.',
    'A buoy bell rings somewhere out past the breakers, slow and steady.',
  ],
);

const _hollowReaches = ExcursionFlavor(
  shop: [
    'A hunched figure trades wares from a cart wedged between two crumbling tombs.',
    "Candlelight flickers over a merchant's blanket spread across cold stone.",
    'A peddler has set up shop beneath a cracked archway, goods laid on old bones.',
    'Someone has strung a lantern over a stall built from salvaged coffin wood.',
    'A pale trader works by candlelight, goods arranged on a slab of stone.',
    'A cart, wheels wrapped in cloth to muffle the sound, offers wares in near silence.',
    'Someone has hung a lantern from a rib of stone to mark their stall.',
  ],
  enemy: [
    'Something shifts among the shattered urns, dragging itself toward the light.',
    'A low moan echoes from deeper in the passage, drawing closer.',
    'Cold hands close around nothing, then everything, in the space ahead.',
    'The candle gutters as something unseen closes the distance fast.',
    'The candle gutters twice before something answers the sudden dark.',
    'A skittering sound circles just beyond the edge of the light.',
    'Something drags itself closer, patient in a way nothing living should be.',
  ],
  quest: [
    'A cloaked figure whispers from an alcove, offering coin for silence and a task.',
    'A scrap of parchment is nailed to a coffin lid, offering payment for grim work.',
    'Someone in mourning black steps from the shadows with an urgent, quiet plea.',
    "A gravekeeper's voice carries from the dark, asking for help nobody else will give.",
    'A hand, cold but insistent, catches your sleeve from a side passage.',
    'A message is scratched into the wall, ending in a plea for help.',
    "Someone in the dark offers a bargain before you can even see their face.",
  ],
  treasure: [
    'A funerary offering, untouched for generations, glints in the candlelight.',
    'A sealed niche, cracked open by time, reveals more than bones.',
    'Something is tucked inside a hollow eye socket of an old statue.',
    'A collapsed shrine has scattered its offerings across the floor.',
    "An old reliquary, its lock long rusted through, sits within reach.",
    'Coins, tarnished black, are scattered around a toppled urn.',
    'A loose stone slab hides a small cache beneath it.',
  ],
  rest: [
    'A dry alcove, sheltered from the damp, offers a place to sit.',
    'An old pew, somehow still intact, is enough to rest on.',
    'A pocket of warmer air marks a place worth pausing in.',
    'A carved bench, worn smooth by centuries, waits in the quiet.',
    'A niche just large enough to sit in blocks the worst of the cold.',
    'The stillness here, however unsettling, is at least a chance to rest.',
    'A forgotten hearth, long unlit, still shelters from the draft.',
  ],
  generic: [
    'The passage narrows, and the air grows colder still.',
    'Somewhere unseen, water drips against stone in a slow, patient rhythm.',
    'Candle-stubs line the walls, most of them long since burned out.',
    'The silence here presses close, broken only by your own footsteps.',
    'Dust falls from the ceiling with each distant tremor.',
    'The dark here has a weight to it, pressing in from every side.',
    'Something long dead is carved into the wall, worn smooth by countless hands.',
  ],
);

const _wildsBeyond = ExcursionFlavor(
  shop: [
    'A traveling peddler has parked a cart beneath the trees, wares hung from the branches.',
    "A trapper's camp doubles as a stall, furs and tools spread on a fallen log.",
    'Smoke curls from a small clearing where a merchant has set up for the day.',
    'A hand-painted sign points toward a stall tucked just off the trail.',
    'A weathered trapper has laid out goods on a stretched hide.',
    'A cart wheel creaks nearby, its owner calling out from beneath the trees.',
    'A rope-strung shelf of wares hangs between two sturdy branches.',
  ],
  enemy: [
    'The undergrowth shudders, and something far too large steps into view.',
    'A snarl rises from the treeline before its owner is even seen.',
    'Branches snap somewhere close, closing the distance fast.',
    'Eyes catch the light from the shadows between the trees.',
    'Something large moves parallel to the trail, unseen but unmistakable.',
    'Claws rake bark somewhere close, marking territory or a warning.',
    'The birdsong stops all at once, and the silence that follows is worse.',
  ],
  quest: [
    'A ranger flags you down, asking for help before you can walk on.',
    'A carved marker points to a message begging for aid, signed only with a name.',
    'A traveler falls into step alongside you, explaining a task with obvious relief.',
    'Smoke on the horizon turns out to be someone in need of exactly your kind of help.',
    'A hunter waves you down, already listing what needs doing.',
    'A note pinned to a tree with a knife asks for help, signed only with a mark.',
    'Someone steps from the brush, relieved to see anyone at all.',
  ],
  treasure: [
    'Something glints in a hollow log just off the trail.',
    'A cache, buried and half-forgotten, has been exposed by rain.',
    "An old traveler's pack, long abandoned, still holds a few valuables.",
    "A magpie's nest holds more shine than feathers.",
    'A fallen branch has snagged something worth stopping for.',
    'A shallow stream bed glints with more than just water.',
    'Something is wedged in the roots of an old, fallen tree.',
  ],
  rest: [
    'A patch of soft moss, dry and shaded, is too good to pass up.',
    'A fallen log makes for a decent place to sit a while.',
    'A clearing, warmed by sun, invites a short rest.',
    'The shade of a wide tree offers a break from the heat.',
    'A quiet hollow, sheltered from the wind, is worth a pause.',
    'A flat stone by the trail makes a fine resting spot.',
    'The gentle sound of a nearby stream makes for an easy rest.',
  ],
  generic: [
    'The trail winds on, birdsong the only sound for a while.',
    'Sunlight breaks through the canopy in shifting patches.',
    'The path is quiet here, the wilds holding their breath.',
    'Wind moves through the leaves, and the road continues.',
    'The canopy thins briefly, letting the sky show through.',
    'A deer trail crosses the path and vanishes back into the green.',
    'The wind shifts, carrying the smell of rain not yet arrived.',
  ],
);
