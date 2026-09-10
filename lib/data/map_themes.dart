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

/// Each category holds two parallel lists — English and French — picked
/// together by the same random index so a given excursion's description
/// is consistent regardless of the active app language.
class ExcursionFlavor {
  const ExcursionFlavor({
    required this.shop,
    required this.shopFr,
    required this.enemy,
    required this.enemyFr,
    required this.quest,
    required this.questFr,
    required this.treasure,
    required this.treasureFr,
    required this.rest,
    required this.restFr,
    required this.generic,
    required this.genericFr,
  });

  final List<String> shop;
  final List<String> shopFr;
  final List<String> enemy;
  final List<String> enemyFr;
  final List<String> quest;
  final List<String> questFr;
  final List<String> treasure;
  final List<String> treasureFr;
  final List<String> rest;
  final List<String> restFr;
  final List<String> generic;
  final List<String> genericFr;
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
  shopFr: [
    'Un étal a été installé dans une embrasure de porte, son propriétaire surveillant la rue plus que la marchandise.',
    "Quelqu'un a étalé des marchandises sur une charrette, hélant tous les passants.",
    'Une devanture à moitié condamnée reste, contre toute attente, ouverte au commerce.',
    "La lumière d'une lanterne filtre d'une boutique à demi cachée entre les ruines.",
    "Quelqu'un a dégagé une porte et disposé des marchandises sur une vieille caisse.",
    'Un marchand manchot parvient malgré tout à mener bon train ses affaires depuis une charrette.',
    "Une pancarte tracée à la main indique « OUVERT » au-dessus d'une porte qui tient à peine sur ses gonds.",
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
  enemyFr: [
    'Quelque chose bouge dans les ombres devant vous, bloquant le seul passage dégagé.',
    'Une silhouette surgit, arme déjà à la main.',
    "Un grognement sourd monte des décombres, juste à l'écart du chemin.",
    'Des pas se rapprochent vite derrière vous — pas le temps de réfléchir.',
    "Les gravats bougent sous vos pieds, et ce qui se trouve en dessous n'apprécie pas d'être dérangé.",
    "Une paire d'yeux capte la lueur d'une torche depuis une porte effondrée.",
    'La ruelle devant vous sombre soudain dans un silence contre nature.',
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
  questFr: [
    "Quelqu'un vous agrippe la manche, désespéré et à voix basse, avec une tâche à accomplir.",
    "Un avis est cloué à un poteau, promettant de l'or pour une tâche dont personne d'autre ne veut.",
    "Un inconnu se met à marcher à vos côtés, expliquant ce qu'il lui faut avant que vous ne puissiez refuser.",
    "Une voix venue d'une ruelle demande, prudemment, si vous êtes prêt à aider.",
    'Un enfant tire sur votre manteau, désignant avec urgence une rue adjacente.',
    "Quelqu'un glisse un billet plié dans votre main sans ralentir le pas.",
    "Une voix vous hèle depuis un balcon brisé, offrant de l'or pour un service.",
  ],
  treasure: [
    'Something glints beneath a fallen beam, half-buried in ash.',
    'A loose stone in the wall hides a small stash, forgotten by whoever left it.',
    "A dead man's pocket, picked over once already, still holds a few coins.",
    'Tucked behind a chimney, a tin box rattles with something inside.',
    'A crushed strongbox has spilled part of its contents across the cobbles.',
    'Something catches the light at the bottom of a dry well.',
    "A loose floorboard creaks, hinting at what's hidden beneath it.",
  ],
  treasureFr: [
    'Quelque chose scintille sous une poutre effondrée, à moitié enseveli dans la cendre.',
    "Une pierre descellée dans le mur cache un petit magot, oublié par celui qui l'y a laissé.",
    "La poche d'un cadavre, déjà fouillée une fois, contient encore quelques pièces.",
    "Cachée derrière une cheminée, une boîte en fer-blanc cliquette, quelque chose à l'intérieur.",
    'Un coffre-fort défoncé a répandu une partie de son contenu sur les pavés.',
    "Quelque chose accroche la lumière au fond d'un puits asséché.",
    'Une latte de plancher descellée craque, trahissant ce qui se cache dessous.',
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
  restFr: [
    "Une porte à l'abri du vent offre un instant pour reprendre son souffle.",
    "Un foyer abandonné, froid depuis longtemps, reste un endroit convenable où s'asseoir.",
    "Un toit paisible, accessible par un escalier à moitié effondré, mérite l'ascension.",
    "Les ruines d'une chapelle offrent assez de silence pour se reposer, sinon du confort.",
    'Un pan de mur intact coupe le vent assez longtemps pour reprendre des forces.',
    'Une charrette renversée fait un brise-vent improbable mais efficace.',
    "La carcasse d'un bain public garde encore un peu de chaleur dans ses pierres.",
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
  genericFr: [
    "Le chemin continue, calme pour l'instant.",
    'Rien ne bouge ici, sinon le vent dans les volets brisés.',
    "Un instant d'immobilité avant que la route ne reprenne.",
    "La rue est vide, hormis l'écho de vos propres pas.",
    "La cendre tombe comme une neige lente, se déposant sur tout ce qu'elle touche.",
    'Une cloche fêlée sonne une fois quelque part, puis se tait.',
    'La route se divise un instant avant de se rejoindre plus loin.',
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
  shopFr: [
    "Un vendeur du port a tendu des filets pleins de babioles entre deux bornes d'amarrage.",
    "Des tonneaux de salaisons s'empilent devant une devanture basse, usée par les embruns.",
    'Un marchand crie par-dessus le grincement des cordages et de la marée, marchandises étalées sur une bâche.',
    'Des étals éclairés à la lanterne bordent la jetée, sentant la saumure et le vieux cordage.',
    'Un marchand borgne vante des épaves récupérées depuis une table blanchie par le soleil.',
    "Des étagères suspendues par des cordes se balancent au vent, chargées de babioles et d'outils.",
    'Une pancarte usée clouée à un poteau indique un étal de marché flottant.',
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
  enemyFr: [
    'Une silhouette surgit de derrière des caisses empilées, lame déjà tirée.',
    'La marée dépose sur le rivage quelque chose qui ne devrait pas bouger.',
    "Le cri d'une mouette s'interrompt net tandis que quelque chose de plus gros bouge sous la jetée.",
    'Des pas sur des planches mouillées se rapprochent depuis le brouillard.',
    'Quelque chose émerge juste au-delà des brisants, observant avant de bouger.',
    "Une forme se détache de l'ombre d'une coque échouée.",
    "Le grincement du gréement masque des pas qui approchent depuis l'obscurité.",
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
  questFr: [
    "Un marin usé par les années vous agrippe le bras, marmonnant à propos d'une dette et d'un travail pour la régler.",
    "Un avis à moitié trempé est épinglé à une borne d'amarrage, offrant de l'or pour un travail de passage.",
    'Un docker vous jauge du regard avant de demander si vous êtes disponible.',
    "Quelqu'un en ciré surgit du brouillard avec une tâche trop urgente pour s'expliquer deux fois.",
    "Un enfant du port glisse un bout de papier plié dans votre main et s'enfuit en courant.",
    "Un vieux capitaine vous fait signe, un travail déjà à moitié expliqué avant même que vous n'arriviez.",
    "Quelqu'un sur la laisse de mer vous hèle, offrant de l'or pour une course le long de la côte.",
  ],
  treasure: [
    'A half-buried chest, waterlogged but intact, pokes out of the sand.',
    'Something metallic winks from a tide pool.',
    'A washed-up crate has split open, spilling part of its cargo.',
    "A diver's cache, long forgotten, sits wedged beneath a piling.",
    "A gull picks at something shiny it clearly can't eat.",
    "An old ship's strongbox lies wedged between the rocks.",
    "A fisherman's net has hauled up more than fish this time.",
  ],
  treasureFr: [
    "Un coffre à moitié enseveli, gorgé d'eau mais intact, dépasse du sable.",
    'Quelque chose de métallique scintille dans une flaque laissée par la marée.',
    "Une caisse échouée s'est fendue, répandant une partie de sa cargaison.",
    "La cache d'un plongeur, oubliée depuis longtemps, est coincée sous un pilotis.",
    "Une mouette picore quelque chose de brillant qu'elle ne peut visiblement pas manger.",
    "Le coffre-fort d'un vieux navire est coincé entre les rochers.",
    "Le filet d'un pêcheur a remonté plus que du poisson, cette fois.",
  ],
  rest: [
    'A sheltered cove, out of the wind, is a good place to sit a while.',
    "An upturned boat hull offers shade and a moment's rest.",
    'A quiet stretch of pier, away from the noise, invites a pause.',
    'A driftwood fire, still smoldering, warms a spot on the sand.',
    'A sun-warmed rock offers a comfortable place to rest tired feet.',
    "A fisherman's shack, empty for now, is dry enough to shelter in.",
    'The lee side of a dune blocks the worst of the wind.',
  ],
  restFr: [
    "Une crique abritée du vent est un bon endroit pour s'asseoir un moment.",
    "Une coque de bateau renversée offre de l'ombre et un instant de répit.",
    'Un tronçon paisible de la jetée, loin du bruit, invite à une pause.',
    'Un feu de bois flotté, encore fumant, réchauffe un coin de sable.',
    'Un rocher chauffé par le soleil offre un endroit confortable pour reposer des pieds fatigués.',
    "Une cabane de pêcheur, vide pour l'instant, est assez sèche pour s'y abriter.",
    "Le côté sous le vent d'une dune coupe le plus gros des rafales.",
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
  genericFr: [
    'Les planches craquent sous vos pieds au rythme de la marée.',
    "L'air salé et les cris des mouettes sont la seule compagnie sur ce tronçon.",
    'La route longe le rivage, silencieuse hormis le clapotis des vagues.',
    "Le brouillard monte de l'eau, engloutissant la route devant et derrière vous.",
    'Des mouettes tournoient au-dessus, indifférentes à la route en contrebas.',
    "La marée a laissé une ligne de débris marquant jusqu'où elle est jadis montée.",
    "La cloche d'une bouée sonne quelque part au-delà des brisants, lente et régulière.",
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
  shopFr: [
    'Une silhouette voûtée fait commerce depuis une charrette coincée entre deux tombeaux en ruine.',
    "La lueur d'une bougie vacille sur la couverture d'un marchand étalée sur la pierre froide.",
    'Un colporteur a installé son étal sous une arche fissurée, marchandises posées sur de vieux ossements.',
    "Quelqu'un a suspendu une lanterne au-dessus d'un étal fait de bois de cercueil récupéré.",
    "Un marchand blafard travaille à la lueur d'une bougie, marchandises disposées sur une dalle de pierre.",
    'Une charrette, roues enveloppées de tissu pour étouffer le bruit, propose ses marchandises dans un silence presque total.',
    "Quelqu'un a accroché une lanterne à une nervure de pierre pour signaler son étal.",
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
  enemyFr: [
    'Quelque chose bouge parmi les urnes brisées, se traînant vers la lumière.',
    'Une plainte sourde résonne depuis les profondeurs du passage, se rapprochant.',
    "Des mains froides se referment sur le vide, puis sur tout, dans l'espace devant vous.",
    "La bougie vacille tandis que quelque chose d'invisible réduit vite la distance.",
    "La bougie vacille deux fois avant que quelque chose ne réponde à l'obscurité soudaine.",
    'Un bruit de griffures tourne en cercle juste au-delà de la lumière.',
    "Quelque chose se traîne plus près, patient d'une manière qu'aucun être vivant ne devrait être.",
  ],
  quest: [
    'A cloaked figure whispers from an alcove, offering coin for silence and a task.',
    'A scrap of parchment is nailed to a coffin lid, offering payment for grim work.',
    'Someone in mourning black steps from the shadows with an urgent, quiet plea.',
    "A gravekeeper's voice carries from the dark, asking for help nobody else will give.",
    'A hand, cold but insistent, catches your sleeve from a side passage.',
    'A message is scratched into the wall, ending in a plea for help.',
    'Someone in the dark offers a bargain before you can even see their face.',
  ],
  questFr: [
    "Une silhouette encapuchonnée chuchote depuis une alcôve, offrant de l'or pour du silence et une tâche.",
    'Un bout de parchemin est cloué sur un couvercle de cercueil, promettant paiement pour une besogne macabre.',
    "Quelqu'un vêtu de noir de deuil sort des ombres avec une supplique urgente et discrète.",
    "La voix d'un gardien de cimetière porte depuis l'obscurité, réclamant une aide que personne d'autre ne veut apporter.",
    'Une main, froide mais insistante, agrippe votre manche depuis un passage latéral.',
    "Un message est gravé dans le mur, se terminant par un appel à l'aide.",
    "Quelqu'un dans le noir propose un marché avant même que vous ne puissiez voir son visage.",
  ],
  treasure: [
    'A funerary offering, untouched for generations, glints in the candlelight.',
    'A sealed niche, cracked open by time, reveals more than bones.',
    'Something is tucked inside a hollow eye socket of an old statue.',
    'A collapsed shrine has scattered its offerings across the floor.',
    'An old reliquary, its lock long rusted through, sits within reach.',
    'Coins, tarnished black, are scattered around a toppled urn.',
    'A loose stone slab hides a small cache beneath it.',
  ],
  treasureFr: [
    'Une offrande funéraire, intacte depuis des générations, scintille à la lueur de la bougie.',
    'Une niche scellée, fendue par le temps, révèle plus que des ossements.',
    "Quelque chose est glissé dans l'orbite creuse d'une vieille statue.",
    'Un sanctuaire effondré a répandu ses offrandes sur le sol.',
    'Un vieux reliquaire, sa serrure rongée par la rouille depuis longtemps, se trouve à portée de main.',
    "Des pièces, noircies par le temps, sont éparpillées autour d'une urne renversée.",
    'Une dalle de pierre descellée cache une petite cache en dessous.',
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
  restFr: [
    "Une alcôve sèche, à l'abri de l'humidité, offre un endroit où s'asseoir.",
    "Un vieux banc d'église, resté intact contre toute attente, suffit pour se reposer.",
    "Une poche d'air plus chaud signale un endroit où il vaut la peine de s'arrêter.",
    'Un banc sculpté, poli par les siècles, attend dans le silence.',
    "Une niche tout juste assez grande pour s'y asseoir coupe le plus gros du froid.",
    'Le calme de cet endroit, aussi troublant soit-il, offre au moins une chance de se reposer.',
    "Un foyer oublié, éteint depuis longtemps, protège encore des courants d'air.",
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
  genericFr: [
    "Le passage se resserre, et l'air devient encore plus froid.",
    "Quelque part, invisible, de l'eau goutte sur la pierre selon un rythme lent et patient.",
    'Des bouts de bougies bordent les murs, la plupart éteintes depuis longtemps.',
    'Le silence ici pèse de près, brisé seulement par vos propres pas.',
    'De la poussière tombe du plafond à chaque tremblement lointain.',
    "L'obscurité ici a un poids, pressant de tous côtés.",
    "Quelque chose de mort depuis longtemps est gravé dans le mur, poli par d'innombrables mains.",
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
  shopFr: [
    'Un colporteur itinérant a garé sa charrette sous les arbres, marchandises suspendues aux branches.',
    "Le campement d'un trappeur fait aussi office d'étal, fourrures et outils étalés sur un tronc abattu.",
    "De la fumée s'élève d'une petite clairière où un marchand s'est installé pour la journée.",
    "Une pancarte peinte à la main indique un étal niché juste à l'écart du sentier.",
    'Un trappeur usé par les années a étalé sa marchandise sur une peau tendue.',
    'Une roue de charrette grince à proximité, son propriétaire hélant depuis les arbres.',
    'Une étagère de marchandises suspendue par des cordes pend entre deux branches robustes.',
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
  enemyFr: [
    'Les fourrés frémissent, et quelque chose de bien trop grand surgit à découvert.',
    "Un grognement monte de la lisière avant même qu'on n'en voie l'auteur.",
    'Des branches craquent tout près, réduisant vite la distance.',
    'Des yeux captent la lumière depuis les ombres entre les arbres.',
    'Quelque chose de grand se déplace parallèlement au sentier, invisible mais indéniable.',
    "Des griffes lacèrent l'écorce tout près, marquant un territoire ou un avertissement.",
    "Le chant des oiseaux s'arrête d'un coup, et le silence qui suit est pire encore.",
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
  questFr: [
    "Un ranger vous fait signe de vous arrêter, demandant de l'aide avant que vous ne puissiez continuer.",
    "Une borne gravée indique un message implorant de l'aide, signé d'un simple nom.",
    'Un voyageur se met à marcher à vos côtés, expliquant une tâche avec un soulagement évident.',
    "La fumée à l'horizon se révèle être quelqu'un ayant besoin exactement de votre genre d'aide.",
    "Un chasseur vous fait signe, énumérant déjà ce qu'il y a à faire.",
    "Un billet épinglé à un arbre avec un couteau demande de l'aide, signé d'une simple marque.",
    "Quelqu'un sort des broussailles, soulagé de voir âme qui vive.",
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
  treasureFr: [
    "Quelque chose scintille dans un tronc creux juste à l'écart du sentier.",
    'Une cache, enterrée et à moitié oubliée, a été mise au jour par la pluie.',
    'Un vieux sac de voyageur, abandonné depuis longtemps, contient encore quelques objets de valeur.',
    "Le nid d'une pie contient plus d'éclat que de plumes.",
    "Une branche tombée a accroché quelque chose qui mérite qu'on s'arrête.",
    "Le lit peu profond d'un ruisseau scintille de plus que de l'eau.",
    "Quelque chose est coincé dans les racines d'un vieil arbre déraciné.",
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
  restFr: [
    'Un tapis de mousse douce, sec et ombragé, est trop tentant pour être ignoré.',
    "Un tronc abattu fait un endroit convenable pour s'asseoir un moment.",
    'Une clairière, réchauffée par le soleil, invite à une courte pause.',
    "L'ombre d'un large arbre offre un répit contre la chaleur.",
    "Un vallon paisible, à l'abri du vent, mérite une pause.",
    'Une pierre plate près du sentier fait un bel endroit pour se reposer.',
    "Le doux murmure d'un ruisseau voisin invite à un repos facile.",
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
  genericFr: [
    'Le sentier serpente, le chant des oiseaux pour seule compagnie un moment.',
    'La lumière du soleil perce la canopée en taches mouvantes.',
    'Le chemin est calme ici, comme si les terres sauvages retenaient leur souffle.',
    'Le vent passe à travers les feuilles, et la route continue.',
    "La canopée s'éclaircit un instant, laissant apparaître le ciel.",
    'Une piste de cerf croise le chemin puis disparaît de nouveau dans la verdure.',
    "Le vent tourne, portant l'odeur d'une pluie pas encore arrivée.",
  ],
);
