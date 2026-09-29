import 'dart:math';

import '../models/story_node.dart';
import 'sub_node_engine.dart';

/// What an expedition asks of the party (zones.json `kind`):
///
/// * [clear]: walk the zone's random events, then beat its boss (the
///   original expeditions);
/// * [escort]: bring a merchant's wagons through the zone's stages. The
///   wagons have a load (see [escortCargoFull]) that ambushes, broken
///   axles and swollen fords eat into; the pay is the share that arrives,
///   and the wagons lost ends the expedition;
/// * [delivery]: carry a parcel to the zone's destination within its
///   deadline (`deadlineDays`). Every stage takes a day, and the slow, safe
///   road takes another; a parcel delivered late is paid half.
///
/// An escort's or a delivery's stages are drawn from their own scenes
/// (see [buildKindStep]), never from the random events of a [clear]
/// zone; the zone's boss still waits at the end.
enum ExpeditionKind { clear, escort, delivery }

ExpeditionKind expeditionKindOf(Map<String, dynamic> zone) =>
    switch (zone['kind']?.toString()) {
      'escort' => ExpeditionKind.escort,
      'delivery' => ExpeditionKind.delivery,
      _ => ExpeditionKind.clear,
    };

/// An escort's wagons set out with their whole load, in percent.
const int escortCargoFull = 100;

/// The share of the load that must arrive for the merchant's extra
/// thanks (the zone's `rewardItemId`).
const int escortItemCargo = 50;

/// What an escort pays for [cargo] percent of the load arriving: that
/// share of the zone's [rewardGold].
int escortPayFor(int rewardGold, int cargo) =>
    (rewardGold * cargo.clamp(0, escortCargoFull) / escortCargoFull).round();

/// Whether enough of the load arrived for the zone's item.
bool escortKeepsItem(int cargo) => cargo >= escortItemCargo;

/// A delivery's deadline in days: the zone's `deadlineDays`, else two
/// spare days over its stages (in the simulator, a careful party is on
/// time about 85% of the time with two, 45% with one).
int deliveryDeadlineOf(Map<String, dynamic> zone) =>
    (zone['deadlineDays'] as num?)?.toInt() ??
    ((zone['expeditionCount'] as num?)?.toInt() ?? 3) + 2;

/// Whether a parcel [daysUsed] days on the road beat its [deadline].
bool deliveryOnTime({required int daysUsed, required int deadline}) =>
    daysUsed <= deadline;

/// What a delivery pays: the zone's [rewardGold] on time, half late.
int deliveryPayFor(int rewardGold,
        {required int daysUsed, required int deadline}) =>
    deliveryOnTime(daysUsed: daysUsed, deadline: deadline)
        ? rewardGold
        : (rewardGold / 2).round();

/// What one choice of an escort's or a delivery's stage does besides its
/// own effects (gold, alignment, a roll, a fight): to the load, to the
/// days, and to the party's leader.
class StepOutcome {
  const StepOutcome({
    this.cargo = 0,
    this.failCargo = 0,
    this.fightCargo = 0,
    this.days = 0,
    this.failDays = 0,
    this.hurtOnFail = 0,
  });

  /// Load gained or (negative) lost whatever happens, in percent.
  final int cargo;

  /// Load lost besides when the choice's roll fails.
  final int failCargo;

  /// Load lost besides when a fight is fought (the choice's own, or a
  /// sneak that failed).
  final int fightCargo;

  /// Days besides the stage's own (negative: a day saved).
  final int days;

  /// Days lost besides when the choice's roll fails.
  final int failDays;

  /// Share of the leader's maximum health lost when the roll fails, in
  /// percent.
  final int hurtOnFail;

  /// The load change, extra days and hurt for a choice whose roll
  /// [failed] and in which the party [fought].
  ({int cargo, int days, int hurt}) resolve(
          {required bool failed, required bool fought}) =>
      (
        cargo: cargo + (failed ? failCargo : 0) + (fought ? fightCargo : 0),
        days: days + (failed ? failDays : 0),
        hurt: failed ? hurtOnFail : 0,
      );
}

/// One stage of an escort or a delivery: the scene, and what each of its
/// choices does to the load and the days ([outcomes], one per choice).
class ExpeditionStep {
  const ExpeditionStep({
    required this.key,
    required this.node,
    required this.outcomes,
  });

  /// Which scene this is (see [buildKindStep]'s `used`).
  final String key;
  final StoryNode node;
  final List<StepOutcome> outcomes;

  StepOutcome outcomeFor(int choiceIndex) =>
      choiceIndex >= 0 && choiceIndex < outcomes.length
          ? outcomes[choiceIndex]
          : const StepOutcome();
}

/// What a wagon loses in its escort's final fight, the zone's boss.
const StepOutcome escortBossOutcome = StepOutcome(fightCargo: -10);

/// A stage of a [kind] expedition in [chapter]: a scene not yet in [used]
/// (every scene again once all are), its foes drawn from [enemyPool] (a
/// pair from [packPool] now and then, from chapter 3). [clear] has no
/// stages of its own.
ExpeditionStep buildKindStep(
  ExpeditionKind kind, {
  required int chapter,
  required Random random,
  required Set<String> used,
  required List<String> enemyPool,
  List<String> packPool = const [],
}) {
  assert(kind != ExpeditionKind.clear);
  final scenes =
      kind == ExpeditionKind.escort ? _escortScenes : _deliveryScenes;
  final ch = max(1, chapter);
  List<String> foes() {
    if (ch >= 3 && packPool.isNotEmpty && random.nextDouble() < 0.4) {
      final id = packPool[random.nextInt(packPool.length)];
      return [id, id];
    }
    if (enemyPool.isEmpty) return const [];
    return [enemyPool[random.nextInt(enemyPool.length)]];
  }

  // Scenes not met yet this expedition first, in a random order; a scene
  // whose every choice needs a foe is passed over when none can be drawn.
  final fresh = [
    for (final s in scenes)
      if (!used.contains(s.key)) s,
  ]..shuffle(random);
  final seen = [
    for (final s in scenes)
      if (used.contains(s.key)) s,
  ]..shuffle(random);
  for (final scene in [...fresh, ...seen]) {
    final built = <(StoryChoice, StepOutcome)>[
      for (final option in scene.options)
        if (option.build(ch, foes) case final choice?) (choice, option.outcome),
    ];
    if (built.isEmpty) continue;
    final line = random.nextInt(scene.en.length);
    return ExpeditionStep(
      key: scene.key,
      node: StoryNode(
        id: '${kind.name}_${scene.key}_${random.nextInt(1 << 30)}',
        description: scene.en[line],
        descriptionFr: scene.fr[line],
        choices: [for (final b in built) b.$1],
      ),
      outcomes: [for (final b in built) b.$2],
    );
  }
  throw StateError('no ${kind.name} scene can be built');
}

/// The roll a stage's choice asks for in [chapter]: an ordinary one, or
/// [harder].
int _dc(int chapter, {bool harder = false}) =>
    SubNodeEngine.detourCheckDc(chapter) + (harder ? 2 : 0);

class _Option {
  const _Option(this.build, [this.outcome = const StepOutcome()]);

  /// The choice in a chapter, given a way to draw its foes; null when it
  /// needs foes and none can be drawn.
  final StoryChoice? Function(int chapter, List<String> Function() foes) build;
  final StepOutcome outcome;
}

class _Scene {
  const _Scene(this.key, this.en, this.fr, this.options);

  final String key;
  final List<String> en;
  final List<String> fr;
  final List<_Option> options;
}

StoryChoice? _fight(String text, String textFr, List<String> foes) =>
    foes.isEmpty
        ? null
        : StoryChoice(
            text: text,
            textFr: textFr,
            nextId: '',
            triggerEnemyIds: foes.length > 1 ? foes : const [],
            triggerEnemyId: foes.first,
          );

StoryChoice? _sneak(String text, String textFr, String ability, int dc,
        List<String> foes) =>
    foes.isEmpty
        ? null
        : StoryChoice(
            text: text,
            textFr: textFr,
            nextId: '',
            triggerEnemyIds: foes.length > 1 ? foes : const [],
            triggerEnemyId: foes.first,
            checkAbility: ability,
            checkDC: dc,
            avoidFightOnSuccess: true,
          );

StoryChoice _roll(String text, String textFr, String ability, int dc,
        {int goldMod = 0}) =>
    StoryChoice(
      text: text,
      textFr: textFr,
      nextId: '',
      checkAbility: ability,
      checkDC: dc,
      goldMod: goldMod,
    );

StoryChoice _plain(String text, String textFr,
        {int goldMod = 0, int alignmentMod = 0}) =>
    StoryChoice(
      text: text,
      textFr: textFr,
      nextId: '',
      goldMod: goldMod,
      alignmentMod: alignmentMod,
    );

/// A toll or a bribe in [chapter].
int tollFor(int chapter) => 15 * max(1, chapter);

/// A guide's price in [chapter].
int guideFeeFor(int chapter) => 10 * max(1, chapter);

/// What a thief's cache holds in [chapter].
int thiefCacheFor(int chapter) => 20 * max(1, chapter);

final List<_Scene> _escortScenes = [
  _Scene(
    'ambush',
    const [
      'Raiders pour out of the ditch with hooks and torches, going for the mules first. The drivers look to you.',
      'Arrows thud into the lead wagon from the trees. By the time the drivers are under the carts, the raiders are already running in.',
    ],
    const [
      'Des pillards jaillissent du fossé avec des crochets et des torches, et s’en prennent d’abord aux mules. Les conducteurs se tournent vers vous.',
      'Des flèches se plantent dans le premier chariot depuis les arbres. Le temps que les conducteurs se glissent sous les charrettes, les pillards accourent déjà.',
    ],
    [
      _Option(
          (ch, foes) => _fight('Hold the line at the wagons',
              'Tenir la ligne aux chariots', foes()),
          const StepOutcome(fightCargo: -10)),
      _Option(
          (ch, foes) => _sneak(
              'Whip the mules to a gallop (Dexterity)',
              'Lancer les mules au galop (Dextérité)',
              'dexterity',
              _dc(ch),
              foes()),
          const StepOutcome(cargo: -5, fightCargo: -10)),
    ],
  ),
  _Scene(
    'axle',
    const [
      'A crack like a musket shot: the lead wagon’s axle has split, and the load leans out over the ditch.',
    ],
    const [
      'Un craquement de coup de feu : l’essieu du premier chariot s’est fendu, et le chargement penche au-dessus du fossé.',
    ],
    [
      _Option(
          (ch, foes) => _roll('Lift it and splint the axle (Strength)',
              'Soulever et éclisser l’essieu (Force)', 'strength', _dc(ch)),
          const StepOutcome(failCargo: -15)),
      _Option(
          (ch, foes) => _plain('Unload and mend it properly (a day)',
              'Décharger et réparer pour de bon (un jour)'),
          const StepOutcome(days: 1)),
    ],
  ),
  _Scene(
    'ford',
    const [
      'The ford is running high and brown after the rain. The drivers argue about where the bottom is, and none of them wants to find out first.',
    ],
    const [
      'Le gué est haut et brun après la pluie. Les conducteurs se disputent pour savoir où est le fond, et aucun ne veut le découvrir le premier.',
    ],
    [
      _Option(
          (ch, foes) => _roll('Find the shallows (Wisdom)',
              'Trouver les hauts-fonds (Sagesse)', 'wisdom', _dc(ch)),
          const StepOutcome(failCargo: -20)),
      _Option(
          (ch, foes) => _plain('Wait for the water to fall (a day)',
              'Attendre la décrue (un jour)'),
          const StepOutcome(days: 1)),
    ],
  ),
  _Scene(
    'toll',
    const [
      'A chain across the road, a hut, and four men who have decided the road is theirs. They name a price for each wagon.',
    ],
    const [
      'Une chaîne en travers de la route, une cabane, et quatre hommes qui ont décidé que la route était à eux. Ils fixent un prix par chariot.',
    ],
    [
      _Option((ch, foes) => _plain('Pay the toll (${tollFor(ch)} gold)',
          'Payer le péage (${tollFor(ch)} or)',
          goldMod: -tollFor(ch))),
      _Option(
          (ch, foes) => _sneak('Talk them out of it (Charisma)',
              'Les en dissuader (Charisme)', 'charisma', _dc(ch), foes()),
          const StepOutcome(fightCargo: -10)),
      _Option(
          (ch, foes) => _fight('Break the chain', 'Briser la chaîne', foes()),
          const StepOutcome(fightCargo: -10)),
    ],
  ),
  _Scene(
    'thieves',
    const [
      'In the dark before dawn, a knife is working at the wagon ropes. Whoever holds it has not seen you yet.',
    ],
    const [
      'Dans le noir d’avant l’aube, un couteau s’attaque aux cordes des chariots. Qui que ce soit, on ne vous a pas encore vu.',
    ],
    [
      _Option(
          (ch, foes) => _roll(
              'Follow them to their camp (Perception)',
              'Les suivre jusqu’à leur camp (Perception)',
              'perception',
              _dc(ch),
              goldMod: thiefCacheFor(ch)),
          const StepOutcome(failCargo: -15)),
      _Option((ch, foes) => _plain('Raise the alarm', 'Donner l’alarme'),
          const StepOutcome(cargo: -5)),
    ],
  ),
  _Scene(
    'mules',
    const [
      'Something howls in the hills and the mules bolt, dragging a wagon off the road and into the scrub.',
    ],
    const [
      'Quelque chose hurle dans les collines et les mules s’emballent, entraînant un chariot hors de la route, dans les broussailles.',
    ],
    [
      _Option(
          (ch, foes) => _roll(
              'Run them down on foot (Constitution)',
              'Les rattraper à la course (Constitution)',
              'constitution',
              _dc(ch)),
          const StepOutcome(failCargo: -15, hurtOnFail: 10)),
      _Option(
          (ch, foes) => _plain('Let them tire, then follow (a day)',
              'Les laisser s’épuiser, puis suivre (un jour)'),
          const StepOutcome(days: 1)),
    ],
  ),
  _Scene(
    'stragglers',
    const [
      'A family walks the verge with everything they own on their backs. The father asks if the little ones might ride on the wagons, just as far as the next village.',
    ],
    const [
      'Une famille marche sur le bas-côté avec tout ce qu’elle possède sur le dos. Le père demande si les petits pourraient monter sur les chariots, juste jusqu’au prochain village.',
    ],
    [
      _Option(
          (ch, foes) => _plain('Make room for them (a crate left)',
              'Leur faire de la place (une caisse laissée)',
              alignmentMod: 2),
          const StepOutcome(cargo: -5)),
      _Option((ch, foes) => _plain(
          'Keep the wagons moving', 'Garder le convoi en marche',
          alignmentMod: -1)),
    ],
  ),
];

final List<_Scene> _deliveryScenes = [
  _Scene(
    'crossroads',
    const [
      'The high road winds the long way round the hills. The marsh path cuts straight across them, if you can keep your feet.',
    ],
    const [
      'La grand-route contourne les collines par le long chemin. Le sentier du marais coupe tout droit à travers, si vous tenez debout.',
    ],
    [
      _Option(
          (ch, foes) => _roll(
              'Take the marsh path (Constitution)',
              'Prendre le sentier du marais (Constitution)',
              'constitution',
              _dc(ch)),
          const StepOutcome(failDays: 1, hurtOnFail: 5)),
      _Option(
          (ch, foes) => _plain('Keep to the high road (a day)',
              'Rester sur la grand-route (un jour)'),
          const StepOutcome(days: 1)),
    ],
  ),
  _Scene(
    'checkpoint',
    const [
      'Soldiers are searching every pack at the bridge, slowly, the way people search when they are paid by the hour.',
    ],
    const [
      'Des soldats fouillent chaque sac au pont, lentement, comme on fouille quand on est payé à l’heure.',
    ],
    [
      _Option(
          (ch, foes) => _roll('Talk your way through (Charisma)',
              'Passer au bagout (Charisme)', 'charisma', _dc(ch)),
          const StepOutcome(failDays: 1)),
      _Option((ch, foes) => _plain(
          'Pay them to look away (${tollFor(ch)} gold)',
          'Les payer pour qu’ils regardent ailleurs (${tollFor(ch)} or)',
          goldMod: -tollFor(ch))),
      _Option(
          (ch, foes) =>
              _plain('Wait your turn (a day)', 'Attendre votre tour (un jour)'),
          const StepOutcome(days: 1)),
    ],
  ),
  _Scene(
    'pursuers',
    const [
      'Someone has kept the same distance behind you since dawn. Now the road narrows between two banks, and they are closing in.',
    ],
    const [
      'Quelqu’un garde la même distance derrière vous depuis l’aube. Maintenant la route se resserre entre deux talus, et ils se rapprochent.',
    ],
    [
      _Option((ch, foes) => _fight(
          'Turn and face them', 'Vous retourner et les affronter', foes())),
      _Option((ch, foes) => _sneak('Lose them in the woods (Dexterity)',
          'Les semer dans les bois (Dextérité)', 'dexterity', _dc(ch), foes())),
    ],
  ),
  _Scene(
    'bridge',
    const [
      'The bridge is gone, and the river below is loud with the melt. The mill downstream has one, a day’s walk round.',
    ],
    const [
      'Le pont a disparu, et la rivière en contrebas gronde de la fonte des neiges. Le moulin en aval en a un, à une journée de marche.',
    ],
    [
      _Option(
          (ch, foes) => _roll(
              'Climb down and across (Strength)',
              'Descendre et traverser (Force)',
              'strength',
              _dc(ch, harder: true)),
          const StepOutcome(failDays: 1, hurtOnFail: 10)),
      _Option(
          (ch, foes) => _plain('Go round by the mill (a day)',
              'Faire le détour par le moulin (un jour)'),
          const StepOutcome(days: 1)),
    ],
  ),
  _Scene(
    'guide',
    const [
      'A shepherd leaning on a milestone knows a goat track that saves a day, says so, and names a price.',
    ],
    const [
      'Un berger appuyé contre une borne connaît un sentier de chèvres qui fait gagner une journée, le dit, et fixe un prix.',
    ],
    [
      _Option(
          (ch, foes) => _plain(
              'Pay the guide (${guideFeeFor(ch)} gold, saves a day)',
              'Payer le guide (${guideFeeFor(ch)} or, un jour gagné)',
              goldMod: -guideFeeFor(ch)),
          const StepOutcome(days: -1)),
      _Option((ch, foes) =>
          _plain('Find your own way', 'Trouver votre propre chemin')),
    ],
  ),
  _Scene(
    'storm',
    const [
      'The sky over the pass turns the colour of a bruise. The wind is already carrying hail, and the next shelter is behind you.',
    ],
    const [
      'Le ciel au-dessus du col prend la couleur d’un hématome. Le vent porte déjà de la grêle, et le prochain abri est derrière vous.',
    ],
    [
      _Option(
          (ch, foes) => _roll('Read the weather and push on (Wisdom)',
              'Lire le ciel et continuer (Sagesse)', 'wisdom', _dc(ch)),
          const StepOutcome(failDays: 1, hurtOnFail: 10)),
      _Option(
          (ch, foes) => _plain('Shelter until it passes (a day)',
              'Vous abriter jusqu’à ce qu’il passe (un jour)'),
          const StepOutcome(days: 1)),
    ],
  ),
  _Scene(
    'letter',
    const [
      'At a burned farm, an old man asks you to carry a letter to his daughter. Her village is off your road, but not by much.',
    ],
    const [
      'Dans une ferme brûlée, un vieil homme vous demande de porter une lettre à sa fille. Son village n’est pas sur votre route, mais pas loin.',
    ],
    [
      _Option(
          (ch, foes) => _plain(
              'Carry it for him (a day)', 'La porter pour lui (un jour)',
              alignmentMod: 2),
          const StepOutcome(days: 1)),
      _Option((ch, foes) => _plain(
          'Tell him you cannot', 'Lui dire que vous ne pouvez pas',
          alignmentMod: -1)),
    ],
  ),
];

/// Every scene key of [kind] (for tests and tools).
List<String> kindSceneKeys(ExpeditionKind kind) => [
      for (final s in kind == ExpeditionKind.escort
          ? _escortScenes
          : kind == ExpeditionKind.delivery
              ? _deliveryScenes
              : const <_Scene>[])
        s.key,
    ];
