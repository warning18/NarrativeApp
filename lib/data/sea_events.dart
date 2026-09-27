import 'dart:math';

/// What can happen on one day at sea between two ports. A voyage (see
/// [buildVoyage]) is a short chain of these, drawn once when the Rusty
/// Eel casts off; VoyageScreen walks them in order.
enum SeaEventKind { calm, storm, raider, derelict, sighting }

class SeaEvent {
  const SeaEvent({
    required this.kind,
    required this.description,
    required this.descriptionFr,
    required this.choiceText,
    required this.choiceTextFr,
    this.enemyShipId,
    this.gold = 0,
    this.hullDelta = 0,
  });

  final SeaEventKind kind;
  final String description;
  final String descriptionFr;
  final String choiceText;
  final String choiceTextFr;

  /// A [SeaEventKind.raider] event's enemy_ships.json id.
  final String? enemyShipId;

  /// Gold found on a derelict.
  final int gold;

  /// Hull lost to a storm (negative) or recovered on a calm day.
  final int hullDelta;

  String descriptionFor(bool fr) =>
      fr && descriptionFr.isNotEmpty ? descriptionFr : description;
  String choiceTextFor(bool fr) =>
      fr && choiceTextFr.isNotEmpty ? choiceTextFr : choiceText;

  /// What the crew can do about it (v1.163), the usual answer first.
  List<SeaChoice> get choices => seaChoicesFor(kind);
}

/// What the crew does with a day at sea (v1.163). Each event kind offers a
/// few (see [seaChoicesFor]): fight a raider or pay it off or run, ride a
/// storm out or push through it or shelter, salvage a derelict or board
/// it or leave it, spend a calm day on the hull or on the crew.
enum SeaAction {
  fight,
  payOff,
  outrun,
  rideOut,
  pushThrough,
  shelter,
  salvage,
  board,
  passBy,
  repair,
  rest,
  sailOn,
}

class SeaChoice {
  const SeaChoice(this.action, this.text, this.textFr, {this.checkAbility});

  final SeaAction action;
  final String text;
  final String textFr;

  /// The ability the choice rolls against [seaCheckDc] (see
  /// ability_check.dart), or null for a sure thing.
  final String? checkAbility;

  String textFor(bool fr) => fr && textFr.isNotEmpty ? textFr : text;
}

List<SeaChoice> seaChoicesFor(SeaEventKind kind) => switch (kind) {
      SeaEventKind.raider => const [
          SeaChoice(
              SeaAction.fight, 'Beat to quarters', 'Branle-bas de combat'),
          SeaChoice(SeaAction.payOff, 'Pay them to sheer off',
              'Les payer pour qu’ils s’écartent'),
          SeaChoice(
              SeaAction.outrun, 'Try to outrun them', 'Tenter de les distancer',
              checkAbility: 'dexterity'),
        ],
      SeaEventKind.storm => const [
          SeaChoice(SeaAction.rideOut, 'Ride it out', 'Tenir bon'),
          SeaChoice(SeaAction.pushThrough, 'Push through under full sail',
              'Forcer le passage toutes voiles dehors',
              checkAbility: 'strength'),
          SeaChoice(SeaAction.shelter, 'Shelter in a cove and lose a day',
              'S’abriter dans une crique et perdre un jour'),
        ],
      SeaEventKind.derelict => const [
          SeaChoice(SeaAction.salvage, 'Salvage what floats',
              'Récupérer ce qui flotte'),
          SeaChoice(SeaAction.board, 'Board her and search the hold',
              'Monter à bord et fouiller la cale',
              checkAbility: 'perception'),
          SeaChoice(
              SeaAction.passBy, 'Leave her to the sea', 'La laisser à la mer'),
        ],
      SeaEventKind.calm => const [
          SeaChoice(SeaAction.repair, 'Make repairs', 'Faire des réparations'),
          SeaChoice(SeaAction.rest, 'Let the crew rest',
              'Laisser l’équipage se reposer'),
        ],
      SeaEventKind.sighting => const [
          SeaChoice(SeaAction.sailOn, 'Sail on', 'Poursuivre'),
        ],
    };

/// The DC of a check at sea in [chapter] (the same as a detour's).
int seaCheckDc(int chapter) => 9 + max(1, chapter);

/// What a raider takes to sheer off: twice what it would have paid out.
int tributeFor(Map<String, dynamic>? ship) =>
    2 * ((ship?['goldReward'] as num?)?.toInt() ?? 30);

/// Hull a failed run costs: they close and rake the Eel before the fight.
const int outrunFailHullLoss = 8;

/// A failed push through a storm costs this many times the storm's toll.
const int pushThroughFailMultiplier = 2;

/// Boarding a derelict pays this many times its salvage, when the eyes
/// catch the rot in time. (2.5 made boarding the answer every time the
/// check was even odds: the playthrough simulator boarded 740 wrecks in
/// 50 runs and salvaged 349.)
const double boardGoldMultiplier = 2;

/// A boarding gone wrong: the hulk rolls against the Eel as she's
/// grappled and stoves in her side, for this much hull and nothing found.
/// (A wound used to be the price, and it healed before it mattered.)
const int boardFailHullLoss = 12;

/// A calm day spent resting heals this share of the player's max health.
const int restHealPercent = 25;

const _calm = [
  'A flat grey sea and a steady wind. The crew patches what the last leg broke.',
  'Fog lifts by noon onto water so still the Eel seems to be sailing on glass.',
  'A day of nothing at all, which at sea is the best kind of day there is.',
  'Gulls follow the wake. Someone finds tar enough to seal the worst of the seams.',
];
const _calmFr = [
  'Une mer plate et grise, un vent régulier. L\'équipage répare ce que la dernière étape a cassé.',
  'La brume se lève à midi sur une eau si calme que l\'Eel semble voguer sur du verre.',
  'Une journée sans rien du tout, ce qui, en mer, est la meilleure sorte de journée.',
  'Des mouettes suivent le sillage. Quelqu\'un trouve assez de goudron pour colmater les pires jointures.',
];
const _storm = [
  'The sky goes the color of a bruise and the sea follows. The Eel takes green water over the bow all night.',
  'A squall out of nowhere. The patched sail holds; the hull complains in a voice I did not like.',
  'Lightning walks the horizon. Something below decks tears loose and takes a plank with it.',
  'Rain like flung gravel, and a swell that lifts the Eel and drops her onto her own keel.',
];
const _stormFr = [
  'Le ciel prend la couleur d\'une ecchymose et la mer suit. L\'Eel embarque des paquets de mer toute la nuit.',
  'Un grain sorti de nulle part. La voile rapiécée tient ; la coque proteste d\'une voix qui ne me plaît pas.',
  'La foudre arpente l\'horizon. Quelque chose se détache sous le pont et emporte une planche avec lui.',
  'Une pluie comme du gravier jeté, et une houle qui soulève l\'Eel et la laisse retomber sur sa propre quille.',
];
const _raider = [
  'A sail on the horizon, then two, then the second one is a lot closer than it ought to be.',
  'A low hull slides out of the fog with no lantern lit and every deck crowded.',
  'They come up from leeward under oars, which is how you know they mean it.',
  'A grapnel thuds into the rail before anyone has seen where it came from.',
];
const _raiderFr = [
  'Une voile à l\'horizon, puis deux, puis la seconde est bien plus proche qu\'elle ne devrait l\'être.',
  'Une coque basse glisse hors de la brume sans lanterne allumée et le pont bondé.',
  'Ils remontent sous le vent à la rame, et c\'est à cela qu\'on sait qu\'ils sont sérieux.',
  'Un grappin cogne le bastingage avant que quiconque ait vu d\'où il venait.',
];
const _derelict = [
  'A hulk drifts past, masts gone, nobody aboard who still needs what is in her hold.',
  'A fishing boat wallows half-swamped. Its owner is long gone; his strongbox is not.',
  'Wreckage on the tide, and among it a sealed cask that turns out not to hold water.',
  'A raft of lashed barrels, one of them still holding coin someone meant to come back for.',
];
const _derelictFr = [
  'Une épave dérive, mâts arrachés, sans personne à bord qui ait encore besoin de ce que contient sa cale.',
  'Une barque de pêche tangue à demi submergée. Son propriétaire est parti depuis longtemps ; son coffre-fort, non.',
  'Des débris sur la marée, et parmi eux un tonnelet scellé qui ne contient pas de l\'eau.',
  'Un radeau de tonneaux liés ensemble, dont l\'un renferme encore des pièces que quelqu\'un comptait venir rechercher.',
];
const _sighting = [
  'Something very large passes beneath the keel and does not come back up.',
  'A light on the water, far off, keeping exact pace with us until dawn.',
  'Inquisition sails to the north. They do not turn. Nobody breathes until they are gone.',
  'A coastline that is not on any chart. By morning it is gone, and so is the chart.',
];
const _sightingFr = [
  'Quelque chose de très grand passe sous la quille et ne remonte pas.',
  'Une lumière sur l\'eau, très loin, qui garde exactement notre allure jusqu\'à l\'aube.',
  'Des voiles de l\'Inquisition au nord. Elles ne virent pas. Personne ne respire avant qu\'elles aient disparu.',
  'Une côte qui ne figure sur aucune carte. Au matin, elle a disparu, et la carte aussi.',
];

/// Enemy ships that may sail against the player at [chapter]
/// (enemy_ships.json `minChapter`).
List<String> raiderPoolFor(Map<String, dynamic> enemyShips, int chapter) =>
    enemyShips.entries
        .where((e) =>
            (((e.value as Map<String, dynamic>)['minChapter'] as num?)
                    ?.toInt() ??
                1) <=
            chapter)
        .map((e) => e.key)
        .toList()
      ..sort();

/// A day's odds of raiders on waters the Rusty Eel has not sailed yet.
const double raiderChance = 0.35;

/// A day's odds of raiders on waters she has sailed before (a port she has
/// put in at, or the way home): the party knows the route, and meets one
/// raider a crossing at most there. The open chapters send the party back
/// and forth between the camp and its places; the first crossing stays
/// the dangerous one.
const double knownWatersRaiderChance = 0.15;

/// Draws a voyage of [length] days. Roughly a third of days bring a raider
/// (when any ship may sail at [chapter]; fewer on [knownWaters]), a fifth a
/// storm, a fifth a derelict, the rest calm water or a sighting.
List<SeaEvent> buildVoyage({
  required Random random,
  required int length,
  required Map<String, dynamic> enemyShips,
  required int chapter,
  bool knownWaters = false,
}) {
  final raiders = raiderPoolFor(enemyShips, chapter);
  final chance = knownWaters ? knownWatersRaiderChance : raiderChance;
  final events = <SeaEvent>[];
  var raided = false;
  for (var i = 0; i < max(1, length); i++) {
    var roll = random.nextDouble();
    final canRaid = raiders.isNotEmpty && !(knownWaters && raided);
    if (roll < raiderChance && (!canRaid || roll >= chance)) {
      roll = raiderChance + roll; // no raider today
    }
    final SeaEventKind kind;
    if (roll < raiderChance) {
      raided = true;
      kind = SeaEventKind.raider;
    } else if (roll < 0.55) {
      kind = SeaEventKind.storm;
    } else if (roll < 0.75) {
      kind = SeaEventKind.derelict;
    } else if (roll < 0.9) {
      kind = SeaEventKind.calm;
    } else {
      kind = SeaEventKind.sighting;
    }
    final idx = random.nextInt(4);
    switch (kind) {
      case SeaEventKind.raider:
        events.add(SeaEvent(
          kind: kind,
          description: _raider[idx],
          descriptionFr: _raiderFr[idx],
          choiceText: 'Beat to quarters',
          choiceTextFr: 'Branle-bas de combat',
          enemyShipId: raiders[random.nextInt(raiders.length)],
        ));
      case SeaEventKind.storm:
        events.add(SeaEvent(
          kind: kind,
          description: _storm[idx],
          descriptionFr: _stormFr[idx],
          choiceText: 'Ride it out',
          choiceTextFr: 'Tenir bon',
          hullDelta: -(8 + random.nextInt(9)),
        ));
      case SeaEventKind.derelict:
        events.add(SeaEvent(
          kind: kind,
          description: _derelict[idx],
          descriptionFr: _derelictFr[idx],
          choiceText: 'Salvage what floats',
          choiceTextFr: 'Récupérer ce qui flotte',
          gold: 20 + random.nextInt(26) + 10 * (max(1, chapter) - 1),
        ));
      case SeaEventKind.calm:
        events.add(SeaEvent(
          kind: kind,
          description: _calm[idx],
          descriptionFr: _calmFr[idx],
          choiceText: 'Make repairs',
          choiceTextFr: 'Faire des réparations',
          hullDelta: 12,
        ));
      case SeaEventKind.sighting:
        events.add(SeaEvent(
          kind: kind,
          description: _sighting[idx],
          descriptionFr: _sightingFr[idx],
          choiceText: 'Sail on',
          choiceTextFr: 'Poursuivre',
        ));
    }
  }
  return events;
}
