import 'dart:math';

import '../models/story_node.dart';

/// Familiar faces on the road: three travellers met again and again, each
/// in three beats spread over the chapters, and each beat written for what
/// the party did at the one before. Wren the mapmaker, Brother Oswin the
/// defrocked monk and Mira the treasure hunter remember a kindness, a
/// hard bargain or a cold shoulder, and pay it back in kind.
///
/// A beat is met as a detour (see [maybeRecurringEncounter]): one scene,
/// its choices setting `met_<who>_<beat>` and what the party chose, which
/// the next beat reads.
const double recurringChance = 0.25;

class _Beat {
  const _Beat({
    required this.who,
    required this.stage,
    required this.minChapter,
    required this.build,
    this.needsAny = const [],
  });

  final String who;
  final int stage;
  final int minChapter;

  /// The beat is met only once the party holds one of these (besides the
  /// previous beat's marker).
  final List<String> needsAny;

  /// The scene, for the party's [flags] in [chapter] ([enemyId]: a foe of
  /// the chapter, for a beat that can come to blows).
  final StoryNode Function(Set<String> flags, int chapter, String? enemyId)
      build;

  String get marker => markerFor(who, stage);
}

/// The flag marking that the party met [who]'s beat [stage].
String markerFor(String who, int stage) => 'met_${who}_$stage';

const String _metNoteEn = 'Someone you have met on the road before.';
const String _metNoteFr = 'Quelqu’un que vous avez déjà croisé en chemin.';
const String _newNoteEn = 'A traveller on the same road as you.';
const String _newNoteFr = 'Un voyageur sur la même route que vous.';

StoryNode _scene(String id, String en, String fr, List<StoryChoice> choices,
        {bool known = true}) =>
    StoryNode(
      id: 'familiar_$id',
      description: en,
      descriptionFr: fr,
      contextNote: known ? _metNoteEn : _newNoteEn,
      contextNoteFr: known ? _metNoteFr : _newNoteFr,
      choices: choices,
    );

StoryChoice _go(String en, String fr, List<String> flags,
        {int gold = 0, int heal = 0, int alignment = 0, String? enemyId}) =>
    StoryChoice(
      text: en,
      textFr: fr,
      nextId: '',
      flagsToAdd: flags,
      goldMod: gold,
      healAmount: heal,
      alignmentMod: alignment,
      triggerEnemyId: enemyId,
    );

int _c(int chapter) => max(2, chapter);

final List<_Beat> _beats = [
  // Wren, the cartographer's apprentice.
  _Beat(
    who: 'wren',
    stage: 1,
    minChapter: 2,
    build: (flags, chapter, _) => _scene(
      'wren_1',
      'A young woman sits on a milestone with a map spread over her knees, soaked through and running with ink. “Wren,” she says, before you can ask. “Apprentice to the harbour’s cartographer. Former apprentice, if I go back without this road.”',
      'Une jeune femme est assise sur une borne, une carte étalée sur les genoux, trempée et dégoulinante d’encre. « Wren, dit-elle avant que vous ne demandiez. Apprentie du cartographe du port. Ancienne apprentie, si je rentre sans cette route. »',
      known: false,
      [
        _go('Copy your route onto her map', 'Recopier votre route sur sa carte',
            ['met_wren_1', 'wren_helped'],
            alignment: 2),
        _go(
            'Sell her the route (+${5 + 5 * _c(chapter)} gold)',
            'Lui vendre la route (+${5 + 5 * _c(chapter)} or)',
            ['met_wren_1', 'wren_sold'],
            gold: 5 + 5 * _c(chapter)),
        _go('Leave her to it', 'La laisser se débrouiller',
            ['met_wren_1', 'wren_left']),
      ],
    ),
  ),
  _Beat(
    who: 'wren',
    stage: 2,
    minChapter: 3,
    build: (flags, chapter, _) {
      if (flags.contains('wren_helped')) {
        return _scene(
          'wren_2',
          'Wren waves from a cart stacked with rolled maps. “The road you gave me sold forty copies. I owe you.” She presses a folded sheet into your hand: a cache, marked with a careful cross, a morning’s walk off the road.',
          'Wren vous fait signe depuis une charrette chargée de cartes roulées. « La route que vous m’avez donnée s’est vendue à quarante exemplaires. Je vous dois bien ça. » Elle vous glisse une feuille pliée : une cachette, marquée d’une croix soignée, à une matinée de marche de la route.',
          [
            _go('Follow her cross', 'Suivre sa croix', ['met_wren_2'],
                gold: 40 * _c(chapter)),
          ],
        );
      }
      if (flags.contains('wren_sold')) {
        return _scene(
          'wren_2',
          'Wren again, in a better coat and with a sharper eye. “I paid for a road once. Now I sell them.” She holds up a sheet with a cache marked on it. “Same price you asked me. Plus what I learned from you.”',
          'Encore Wren, avec un meilleur manteau et un regard plus aiguisé. « J’ai payé une route, un jour. Maintenant, c’est moi qui les vends. » Elle brandit une feuille où une cachette est marquée. « Le prix que vous m’avez demandé. Plus ce que vous m’avez appris. »',
          [
            _go('Pay her price and dig', 'Payer son prix et creuser',
                ['met_wren_2'],
                gold: 25 * _c(chapter)),
            _go('Keep your coin', 'Garder votre argent', ['met_wren_2']),
          ],
        );
      }
      return _scene(
        'wren_2',
        'A mapmaker’s cart passes you on the road. The young woman driving it looks at you a moment too long, then away. Wren does not stop, and the ink on her new maps is dry.',
        'Une charrette de cartographe vous dépasse sur la route. La jeune femme qui la conduit vous regarde un instant de trop, puis détourne les yeux. Wren ne s’arrête pas, et l’encre de ses nouvelles cartes est sèche.',
        [
          _go('Watch her go', 'La regarder partir', ['met_wren_2']),
        ],
      );
    },
  ),
  _Beat(
    who: 'wren',
    stage: 3,
    minChapter: 5,
    needsAny: const ['wren_helped', 'wren_sold'],
    build: (flags, chapter, _) {
      if (flags.contains('wren_helped')) {
        return _scene(
          'wren_3',
          'Wren is waiting where the road forks, a guild seal on her satchel now. “Nobody has mapped what lies ahead. I will, and your name goes in the corner.” She marks the one dry path for you and walks it with you as far as the first ridge.',
          'Wren vous attend à la fourche, un sceau de guilde sur sa sacoche désormais. « Personne n’a cartographié ce qui nous attend. Moi, je le ferai, et votre nom sera dans le coin. » Elle vous marque le seul chemin au sec et le parcourt avec vous jusqu’à la première crête.',
          [
            _go('Take the dry path', 'Prendre le chemin au sec', ['met_wren_3'],
                heal: 30 + 10 * _c(chapter)),
          ],
        );
      }
      return _scene(
        'wren_3',
        'Wren’s map of the road ahead is the only one there is, and she knows it. “For you,” she says, “the price I learned from you.” It is not a small price.',
        'La carte de Wren pour la route à venir est la seule qui existe, et elle le sait. « Pour vous, dit-elle, le prix que vous m’avez appris. » Ce n’est pas un petit prix.',
        [
          _go('Buy the map (${20 * _c(chapter)} gold)',
              'Acheter la carte (${20 * _c(chapter)} or)', ['met_wren_3'],
              gold: -20 * _c(chapter), heal: 40 + 10 * _c(chapter)),
          _go('Find your own way', 'Trouver votre propre chemin',
              ['met_wren_3']),
        ],
      );
    },
  ),

  // Brother Oswin, a monk without a robe.
  _Beat(
    who: 'oswin',
    stage: 1,
    minChapter: 2,
    build: (flags, chapter, _) => _scene(
      'oswin_1',
      'A monk without a cowl kneels by the road beside a body under sackcloth. “Brother Oswin. I was, anyway. The Church took the robe and left me the habit of burying people. This one needs a grave, and I need a spade, or the coin for someone else’s.”',
      'Un moine sans capuchon est agenouillé au bord de la route, près d’un corps sous une toile de sac. « Frère Oswin. Je l’étais, du moins. L’Église m’a pris la robe et m’a laissé l’habitude d’enterrer les gens. Celui-ci a besoin d’une tombe, et moi d’une pelle, ou de quoi payer celle d’un autre. »',
      known: false,
      [
        _go(
            'Pay for the burial (${5 + 5 * _c(chapter)} gold)',
            'Payer l’enterrement (${5 + 5 * _c(chapter)} or)',
            ['met_oswin_1', 'oswin_paid'],
            gold: -(5 + 5 * _c(chapter)),
            alignment: 3),
        _go('Dig the grave with him', 'Creuser la tombe avec lui',
            ['met_oswin_1', 'oswin_dug'],
            alignment: 2),
        _go('Leave him to it', 'Le laisser à sa tâche',
            ['met_oswin_1', 'oswin_refused']),
      ],
    ),
  ),
  _Beat(
    who: 'oswin',
    stage: 2,
    minChapter: 3,
    build: (flags, chapter, _) {
      if (flags.contains('oswin_refused')) {
        return _scene(
          'oswin_2',
          'Oswin again, tending a hospice of three cots under a tarp. He knows you and does not say so. He sees to your wounds all the same, and asks exactly what you gave the dead man: nothing.',
          'Encore Oswin, qui tient un hospice de trois lits de camp sous une bâche. Il vous reconnaît et n’en dit rien. Il soigne vos blessures tout de même, et vous demande exactement ce que vous avez donné au mort : rien.',
          [
            _go('Let him work', 'Le laisser faire', ['met_oswin_2'],
                heal: 20 + 5 * _c(chapter)),
          ],
        );
      }
      return _scene(
        'oswin_2',
        'The smoke you follow is Oswin’s: a hospice of three cots under a tarp, and a pot that smells better than it has any right to. “Sit. You saw a stranger into his grave; the least I can do is keep you out of yours.”',
        'La fumée que vous suivez est celle d’Oswin : un hospice de trois lits de camp sous une bâche, et une marmite qui sent bien meilleur qu’elle ne le devrait. « Asseyez-vous. Vous avez mis un inconnu en terre ; le moins que je puisse faire, c’est vous garder hors de la vôtre. »',
        [
          _go('Rest by his fire', 'Vous reposer près de son feu',
              ['met_oswin_2'],
              heal: 40 + 10 * _c(chapter)),
        ],
      );
    },
  ),
  _Beat(
    who: 'oswin',
    stage: 3,
    minChapter: 5,
    build: (flags, chapter, enemyId) {
      final kind = !flags.contains('oswin_refused');
      return _scene(
        'oswin_3',
        kind
            ? 'Inquisition men have Oswin on his knees in the road, his hospice burning behind him. “Heretic’s charity,” their sergeant says. Oswin sees you and shakes his head, very slightly: do not.'
            : 'Inquisition men have Oswin on his knees in the road, his hospice burning behind him. “Heretic’s charity,” their sergeant says. Oswin sees you and looks away, as you once did.',
        kind
            ? 'Des hommes de l’Inquisition tiennent Oswin à genoux sur la route, son hospice en flammes derrière lui. « La charité d’un hérétique », dit leur sergent. Oswin vous voit et secoue très légèrement la tête : non.'
            : 'Des hommes de l’Inquisition tiennent Oswin à genoux sur la route, son hospice en flammes derrière lui. « La charité d’un hérétique », dit leur sergent. Oswin vous voit et détourne les yeux, comme vous l’avez fait jadis.',
        [
          if (enemyId != null)
            _go('Stand between them', 'Vous interposer',
                ['met_oswin_3', 'oswin_saved'],
                alignment: 3, enemyId: enemyId),
          _go(
              'Pay his fine (${30 * _c(chapter)} gold)',
              'Payer son amende (${30 * _c(chapter)} or)',
              ['met_oswin_3', 'oswin_saved'],
              gold: -30 * _c(chapter),
              alignment: 1),
          _go('Keep your head down', 'Baisser la tête',
              ['met_oswin_3', 'oswin_taken'],
              alignment: -2),
        ],
      );
    },
  ),

  // Mira, who got there first.
  _Beat(
    who: 'mira',
    stage: 1,
    minChapter: 3,
    build: (flags, chapter, _) => _scene(
      'mira_1',
      'Someone has found the cairn first: a woman with a lantern and a pry-bar, halfway into a smuggler’s cache. “Mira,” she says, without stopping. “Finders keepers is a rule for whoever got here second. There’s enough for two, if you’re the sharing kind.”',
      'Quelqu’un a trouvé le cairn avant vous : une femme avec une lanterne et un pied-de-biche, à moitié plongée dans une cache de contrebandiers. « Mira, dit-elle sans s’arrêter. “Qui trouve garde”, c’est une règle pour ceux qui arrivent en second. Il y en a assez pour deux, si vous êtes du genre à partager. »',
      known: false,
      [
        _go('Split it with her', 'Partager avec elle',
            ['met_mira_1', 'mira_split'],
            gold: 15 * _c(chapter)),
        _go('Take it all', 'Tout prendre', ['met_mira_1', 'mira_cheated'],
            gold: 30 * _c(chapter), alignment: -2),
        _go('Let her keep it', 'La laisser tout garder',
            ['met_mira_1', 'mira_yielded'],
            alignment: 1),
      ],
    ),
  ),
  _Beat(
    who: 'mira',
    stage: 2,
    minChapter: 4,
    build: (flags, chapter, enemyId) {
      if (flags.contains('mira_cheated')) {
        return _scene(
          'mira_2',
          'The men at the bend are waiting for you in particular. Behind them, on a rock, Mira is eating an apple. “You took all of it, last time. I’ve hired someone to take it back.”',
          'Les hommes au tournant vous attendent, vous précisément. Derrière eux, assise sur un rocher, Mira croque une pomme. « La dernière fois, vous avez tout pris. J’ai engagé quelqu’un pour le reprendre. »',
          [
            if (enemyId != null)
              _go('Fight your way past', 'Vous frayer un passage',
                  ['met_mira_2'],
                  enemyId: enemyId),
            _go(
                'Pay her back (${30 * _c(chapter)} gold)',
                'La rembourser (${30 * _c(chapter)} or)',
                ['met_mira_2', 'mira_squared'],
                gold: -30 * _c(chapter),
                alignment: 1),
          ],
        );
      }
      if (flags.contains('mira_yielded')) {
        return _scene(
          'mira_2',
          'Mira again, richer, and in a hurry as ever. “You left me a whole cache once. I don’t like owing.” She tosses you a purse heavier than your share would have been.',
          'Encore Mira, plus riche, et toujours pressée. « Vous m’avez laissé toute une cache, un jour. Je n’aime pas devoir. » Elle vous lance une bourse plus lourde que ne l’aurait été votre part.',
          [
            _go('Take the purse', 'Prendre la bourse', ['met_mira_2'],
                gold: 25 * _c(chapter)),
          ],
        );
      }
      return _scene(
        'mira_2',
        'Mira falls into step beside you as if you had arranged it. “Men waiting at the next bend. Not for you, for whoever comes along. Come round by the gully with me, and we split what they were guarding.”',
        'Mira se met à marcher à côté de vous comme si c’était convenu. « Des hommes attendent au prochain tournant. Pas vous : le premier venu. Passez par la ravine avec moi, et on partage ce qu’ils gardaient. »',
        [
          _go('Go round by the gully', 'Passer par la ravine', ['met_mira_2'],
              gold: 15 * _c(chapter)),
        ],
      );
    },
  ),
  _Beat(
    who: 'mira',
    stage: 3,
    minChapter: 6,
    needsAny: const ['mira_split', 'mira_yielded', 'mira_squared'],
    build: (flags, chapter, _) => _scene(
      'mira_3',
      'On this shore, of all places, Mira, with her lantern and her pry-bar and a chest half out of the sand. “Last dig,” she says. “Then I’m out of this trade. Help me with the lid, and we’re square for good.”',
      'Sur ce rivage, entre tous, Mira, avec sa lanterne, son pied-de-biche et un coffre à moitié sorti du sable. « Dernière fouille, dit-elle. Après, j’arrête le métier. Aidez-moi avec le couvercle, et nous serons quittes pour de bon. »',
      [
        _go('Lift the lid with her', 'Soulever le couvercle avec elle',
            ['met_mira_3'],
            gold: 40 * _c(chapter)),
      ],
    ),
  ),
];

/// The next beat the party can meet in [chapter] with [flags]: each
/// traveller's first beat not yet met, once the one before it is, its
/// chapter is reached and whatever it needs was chosen. Empty when none.
List<({String who, int stage})> recurringBeatsOpen({
  required Set<String> flags,
  required int chapter,
}) =>
    [
      for (final beat in _beats)
        if (!flags.contains(beat.marker) &&
            chapter >= beat.minChapter &&
            (beat.stage == 1 ||
                flags.contains(markerFor(beat.who, beat.stage - 1))) &&
            (beat.needsAny.isEmpty || beat.needsAny.any(flags.contains)))
          (who: beat.who, stage: beat.stage),
    ];

/// The scene of [who]'s beat [stage] for [flags] in [chapter] ([enemyId]:
/// a foe of the chapter for a beat that can come to blows).
StoryNode recurringBeatScene(
  String who,
  int stage, {
  required Set<String> flags,
  required int chapter,
  String? enemyId,
}) =>
    _beats
        .firstWhere((b) => b.who == who && b.stage == stage)
        .build(flags, chapter, enemyId);

/// Sometimes ([chance]), a familiar face on the road: one of the beats
/// open (see [recurringBeatsOpen]) as a one-scene detour; null otherwise.
/// [enemyPool] gives a beat that can come to blows its foe.
List<StoryNode>? maybeRecurringEncounter({
  required Set<String> flags,
  required int chapter,
  required Random random,
  required List<String> enemyPool,
  double chance = recurringChance,
}) {
  final open = recurringBeatsOpen(flags: flags, chapter: chapter);
  if (open.isEmpty || random.nextDouble() >= chance) return null;
  final pick = open[random.nextInt(open.length)];
  return [
    recurringBeatScene(
      pick.who,
      pick.stage,
      flags: flags,
      chapter: chapter,
      enemyId: enemyPool.isEmpty
          ? null
          : enemyPool[random.nextInt(enemyPool.length)],
    ),
  ];
}
