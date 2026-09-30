/// The formative memories: six moments from before the story, at ages 6 to
/// 16, shown once right after the character is named.
///
/// Each memory is a short scene in the slums the story opens in, with
/// three answers. An answer leans the character's alignment (+4 good, -4
/// evil, 0 neutral), teaches one ability (+1), and leaves a flag
/// (`origin_<memory>_<answer>`, plus `origin_<memory>` for any answer)
/// that the story's early scenes answer with an echo: the tavern named for
/// the blind beggar, old Hesk next door, the loose board over the Bundle.
///
/// The second memory depends on the character's race and the fourth on
/// the profession; later memories open with a line recalling an earlier
/// answer, or the name the character has made on the street by then.
library;

/// One answer to a memory.
class OriginAnswer {
  const OriginAnswer({
    required this.id,
    required this.en,
    required this.fr,
    required this.alignmentMod,
    required this.ability,
    required this.outcomeEn,
    required this.outcomeFr,
  });

  /// 'good', 'neutral' or 'evil' (the flag's suffix).
  final String id;
  final String en;
  final String fr;
  final int alignmentMod;

  /// The ability the answer teaches (one of abilityScoreKeys), +1.
  final String ability;

  /// What came of it, and what it taught.
  final String outcomeEn;
  final String outcomeFr;

  String textFor(bool french) => french ? fr : en;
  String outcomeFor(bool french) => french ? outcomeFr : outcomeEn;
}

/// A line opening a memory because of an earlier answer ([flag]) or of
/// the alignment the earlier answers add up to ([minTotal]/[maxTotal]).
class OriginRecall {
  const OriginRecall({
    this.flag,
    this.minTotal,
    this.maxTotal,
    required this.en,
    required this.fr,
  });

  final String? flag;
  final int? minTotal;
  final int? maxTotal;
  final String en;
  final String fr;

  bool appliesTo(Set<String> flags, int total) =>
      (flag == null || flags.contains(flag)) &&
      (minTotal == null || total >= minTotal!) &&
      (maxTotal == null || total <= maxTotal!);

  String textFor(bool french) => french ? fr : en;
}

class OriginMemory {
  const OriginMemory({
    required this.id,
    required this.age,
    required this.titleEn,
    required this.titleFr,
    required this.sceneEn,
    required this.sceneFr,
    required this.answers,
    this.recalls = const [],
  });

  /// The flag stem (`origin_<id>`).
  final String id;
  final int age;
  final String titleEn;
  final String titleFr;
  final String sceneEn;
  final String sceneFr;
  final List<OriginAnswer> answers;

  /// The first that applies opens the memory.
  final List<OriginRecall> recalls;

  bool get isChildhood => age <= 10;

  String titleFor(bool french) => french ? titleFr : titleEn;
  String sceneFor(bool french) => french ? sceneFr : sceneEn;

  /// The flag any answer leaves.
  String get flag => 'origin_$id';

  /// The flag [answer] leaves.
  String flagFor(OriginAnswer answer) => 'origin_${id}_${answer.id}';

  /// The recall line for the earlier answers' [flags] and alignment
  /// [total], or null.
  OriginRecall? recallFor(Set<String> flags, int total) {
    for (final recall in recalls) {
      if (recall.appliesTo(flags, total)) return recall;
    }
    return null;
  }
}

const _sparrow = OriginMemory(
  id: 'sparrow',
  age: 6,
  titleEn: 'The Sparrow',
  titleFr: 'Le moineau',
  sceneEn:
      'You were six, and the gutter behind the rope-walk was the whole world. '
      'A sparrow lay in it with one wing bent the wrong way, beating at the '
      'water with the other. The bigger children had seen it too, and were '
      'coming over.',
  sceneFr:
      'Vous aviez six ans, et le caniveau derrière la corderie était le monde '
      'entier. Un moineau y gisait, une aile tordue dans le mauvais sens, '
      'battant l’eau de l’autre. Les grands l’avaient vu aussi, et ils '
      'approchaient.',
  answers: [
    OriginAnswer(
      id: 'good',
      en: 'Cup it in your hands and carry it home',
      fr: 'Le prendre dans vos mains et le ramener à la maison',
      alignmentMod: 4,
      ability: 'wisdom',
      outcomeEn: 'It lived eleven days in a bread basket by the fire. You '
          'learned that caring for a thing takes longer than saving it.',
      outcomeFr: 'Il vécut onze jours dans une corbeille à pain, près du feu. '
          'Vous avez appris que prendre soin d’une chose dure plus longtemps '
          'que la sauver.',
    ),
    OriginAnswer(
      id: 'neutral',
      en: 'Wring its neck, quickly; it is kinder',
      fr: 'Lui tordre le cou, vite : c’est plus doux',
      alignmentMod: 0,
      ability: 'constitution',
      outcomeEn: 'Your hands shook afterwards, and then they stopped. You '
          'learned you could do the hard thing and still eat your supper.',
      outcomeFr: 'Vos mains ont tremblé après, puis elles ont cessé. Vous avez '
          'appris qu’on peut faire la chose dure et manger quand même son '
          'souper.',
    ),
    OriginAnswer(
      id: 'evil',
      en: 'Sell it to the bigger children for a copper',
      fr: 'Le vendre aux grands pour un sou',
      alignmentMod: -4,
      ability: 'charisma',
      outcomeEn: 'They paid, and you did not stay to watch what they did with '
          'it. You learned that anything can be sold, if you do the talking '
          'first.',
      outcomeFr: 'Ils ont payé, et vous n’avez pas regardé ce qu’ils en ont '
          'fait. Vous avez appris que tout se vend, si l’on parle le premier.',
    ),
  ],
);

/// The second memory, by race: the first time the world told the child
/// what they were.
const Map<String, OriginMemory> _markByRace = {
  'human': OriginMemory(
    id: 'mark_human',
    age: 8,
    titleEn: 'The White Ribbon',
    titleFr: 'Le ruban blanc',
    sceneEn: 'You were eight. On a feast day, a Crusade priest in a porcelain '
        'mask gave a white ribbon to every slum child who knelt, and your '
        'mother pulled you out of the line. “We have our own,” she said, and '
        'would say no more. That evening, in the alley, a boy with a new '
        'ribbon was beating a painted girl, because the priest had called her '
        'kind unclean.',
    sceneFr:
        'Vous aviez huit ans. Un jour de fête, un prêtre de la Croisade au '
        'masque de porcelaine donna un ruban blanc à chaque enfant des taudis '
        'qui s’agenouillait, et votre mère vous tira hors du rang. « Nous '
        'avons le nôtre », dit-elle, sans rien ajouter. Le soir même, dans la '
        'ruelle, un garçon au ruban tout neuf frappait une petite fille '
        'peinte, parce que le prêtre avait dit les siens impurs.',
    answers: [
      OriginAnswer(
        id: 'good',
        en: 'Pull the boy off her',
        fr: 'Tirer le garçon loin d’elle',
        alignmentMod: 4,
        ability: 'strength',
        outcomeEn: 'He was bigger, and you lost, but he stopped. She painted a '
            'small mark on your wrist that washed off in a week. You learned '
            'that you do not have to win to stop a thing.',
        outcomeFr: 'Il était plus grand, et vous avez perdu, mais il a arrêté. '
            'Elle peignit sur votre poignet une petite marque, partie en une '
            'semaine. Vous avez appris qu’il n’est pas nécessaire de gagner '
            'pour arrêter une chose.',
      ),
      OriginAnswer(
        id: 'neutral',
        en: 'Go home and ask what “our own” meant',
        fr: 'Rentrer demander ce que voulait dire « le nôtre »',
        alignmentMod: 0,
        ability: 'intelligence',
        outcomeEn: 'Your mother lifted a floorboard and showed you a grey '
            'bundle in oilcloth, and would not unwrap it. You learned that '
            'some things are kept without being understood.',
        outcomeFr: 'Votre mère souleva une latte du plancher et vous montra un '
            'ballot gris dans une toile huilée, sans vouloir le défaire. Vous '
            'avez appris qu’on garde certaines choses sans les comprendre.',
      ),
      OriginAnswer(
        id: 'evil',
        en: 'Help him, and ask for his ribbon',
        fr: 'L’aider, et lui demander son ruban',
        alignmentMod: -4,
        ability: 'charisma',
        outcomeEn: 'He gave it to you afterwards. You wore it for a year, and '
            'it never once made you one of them. You learned to say what the '
            'stronger side wanted to hear.',
        outcomeFr: 'Il vous le donna ensuite. Vous l’avez porté un an, et '
            'jamais il ne vous a fait entrer parmi eux. Vous avez appris à dire '
            'ce que le plus fort voulait entendre.',
      ),
    ],
  ),
  'elf': OriginMemory(
    id: 'mark_elf',
    age: 8,
    titleEn: 'The Wet Paint',
    titleFr: 'La peinture fraîche',
    sceneEn: 'You were eight when your grandmother painted your first sigil '
        'on your forearm and told you to keep it from water for three days. '
        'On the second day, rain came down on the market. The only awning had '
        'room for one, and a tanner’s boy with no coat had got there first.',
    sceneFr: 'Vous aviez huit ans quand votre grand-mère peignit votre premier '
        'sigil sur votre avant-bras, en vous disant de le garder de l’eau '
        'trois jours. Le deuxième jour, la pluie tomba sur le marché. Le seul '
        'auvent n’abritait qu’une personne, et un fils de tanneur sans manteau '
        'y était déjà.',
    answers: [
      OriginAnswer(
        id: 'good',
        en: 'Leave him the awning and let the paint run',
        fr: 'Lui laisser l’auvent et laisser couler la peinture',
        alignmentMod: 4,
        ability: 'constitution',
        outcomeEn: 'The sigil ran down your arm in a grey smear, and you '
            'shivered all the way home. Your grandmother painted it again '
            'without a word, and you learned she was prouder of the smear.',
        outcomeFr: 'Le sigil coula le long de votre bras en une traînée grise, '
            'et vous grelottiez tout le long du chemin. Votre grand-mère le '
            'repeignit sans un mot, et vous avez compris qu’elle était plus '
            'fière de la traînée.',
      ),
      OriginAnswer(
        id: 'neutral',
        en: 'Run home with your arm held high',
        fr: 'Courir jusqu’à la maison, le bras levé',
        alignmentMod: 0,
        ability: 'dexterity',
        outcomeEn: 'You ducked every drip on the way, and not a drop touched '
            'it. You learned to keep what is yours dry, whatever the weather '
            'does to anyone else.',
        outcomeFr: 'Vous avez esquivé chaque gouttière du chemin, et pas une '
            'goutte ne l’a touché. Vous avez appris à garder au sec ce qui est '
            'à vous, quoi que le temps fasse aux autres.',
      ),
      OriginAnswer(
        id: 'evil',
        en: 'Shove him out from under it',
        fr: 'Le pousser hors de l’abri',
        alignmentMod: -4,
        ability: 'strength',
        outcomeEn: 'He went out into the rain without a word. Your paint '
            'stayed perfect. You learned that shelter goes to whoever takes '
            'it.',
        outcomeFr: 'Il sortit sous la pluie sans un mot. Votre peinture resta '
            'parfaite. Vous avez appris que l’abri revient à qui le prend.',
      ),
    ],
  ),
  'dwarf': OriginMemory(
    id: 'mark_dwarf',
    age: 8,
    titleEn: 'The Crooked Mark',
    titleFr: 'La marque de travers',
    sceneEn: 'You were eight, the age stone-marked children cut their first '
        'mark. Yours went into a whetstone crooked, and the smith’s boy '
        'laughed, so everyone laughed. That evening you found him behind the '
        'forge, crying, his father’s belt marks across his back.',
    sceneFr: 'Vous aviez huit ans, l’âge où les enfants marqués de pierre '
        'taillent leur première marque. La vôtre partit de travers dans une '
        'pierre à aiguiser ; le fils du forgeron éclata de rire, et tout le '
        'monde avec lui. Le soir, vous l’avez trouvé derrière la forge, en '
        'larmes, le dos zébré par la ceinture de son père.',
    answers: [
      OriginAnswer(
        id: 'good',
        en: 'Sit with him until he stops',
        fr: 'Vous asseoir près de lui jusqu’à ce qu’il se calme',
        alignmentMod: 4,
        ability: 'wisdom',
        outcomeEn: 'Neither of you said a word. He never laughed at your mark '
            'again, and at fourteen he re-cut it straight for you without '
            'being asked. You learned that a kindness can take years to come '
            'back.',
        outcomeFr: 'Aucun de vous deux ne parla. Il ne se moqua plus jamais de '
            'votre marque, et à quatorze ans il la retailla droite pour vous, '
            'sans qu’on lui demande. Vous avez appris qu’une bonté peut mettre '
            'des années à revenir.',
      ),
      OriginAnswer(
        id: 'neutral',
        en: 'Walk past; he laughed first',
        fr: 'Passer votre chemin : il a ri le premier',
        alignmentMod: 0,
        ability: 'constitution',
        outcomeEn: 'You kept the whetstone, crooked mark and all. You learned '
            'to carry a slight a long way without setting it down.',
        outcomeFr:
            'Vous avez gardé la pierre, marque de travers comprise. Vous '
            'avez appris à porter une offense longtemps sans la poser.',
      ),
      OriginAnswer(
        id: 'evil',
        en: 'Laugh at him, loud enough for the others',
        fr: 'Rire de lui, assez fort pour les autres',
        alignmentMod: -4,
        ability: 'charisma',
        outcomeEn: 'They came running and laughed too. You learned that a '
            'crowd goes wherever the loudest voice is.',
        outcomeFr: 'Les autres accoururent et rirent aussi. Vous avez appris '
            'qu’une foule va toujours vers la voix la plus forte.',
      ),
    ],
  ),
  'orc': OriginMemory(
    id: 'mark_orc',
    age: 8,
    titleEn: 'The First Ink',
    titleFr: 'La première encre',
    sceneEn: 'You were eight when your aunt cut your first ink under the skin '
        'of your shoulder and told you to show no one until it scarred. That '
        'week a Crusade orphan-taker came down the street, checking '
        'children’s arms. The baby next door had been inked the same night as '
        'you.',
    sceneFr: 'Vous aviez huit ans quand votre tante glissa votre première '
        'encre sous la peau de votre épaule, en vous disant de ne la montrer à '
        'personne avant la cicatrice. Cette semaine-là, un preneur '
        'd’orphelins de la Croisade descendit la rue en inspectant les bras '
        'des enfants. Le bébé d’à côté avait reçu son encre la même nuit que '
        'vous.',
    answers: [
      OriginAnswer(
        id: 'good',
        en: 'Hide the baby in the coal cellar with you',
        fr: 'Cacher le bébé avec vous dans la cave à charbon',
        alignmentMod: 4,
        ability: 'constitution',
        outcomeEn: 'She cried once, and you covered her mouth gently until the '
            'boots went by. You learned how long you could hold your breath '
            'for someone else.',
        outcomeFr: 'Elle pleura une fois, et votre main couvrit doucement sa '
            'bouche jusqu’à ce que les bottes s’éloignent. Vous avez appris '
            'combien de temps vous pouviez retenir votre souffle pour quelqu’un '
            'd’autre.',
      ),
      OriginAnswer(
        id: 'neutral',
        en: 'Hide in the coal cellar and watch',
        fr: 'Vous cacher dans la cave à charbon et guetter',
        alignmentMod: 0,
        ability: 'perception',
        outcomeEn: 'You watched his boots through a crack in the boards for an '
            'hour, and never knew, after, what he found next door. You learned '
            'to wait, and to see everything from the dark.',
        outcomeFr: 'Vous avez observé ses bottes par une fente des planches '
            'pendant une heure, sans jamais savoir ce qu’il avait trouvé à '
            'côté. Vous avez appris à attendre, et à tout voir depuis l’ombre.',
      ),
      OriginAnswer(
        id: 'evil',
        en: 'Point him at the baby so he stops looking',
        fr: 'Lui désigner le bébé pour qu’il cesse de chercher',
        alignmentMod: -4,
        ability: 'charisma',
        outcomeEn: 'He took her, and he stopped looking. You learned that a '
            'bargain can be struck with anyone, and slept badly for a year.',
        outcomeFr: 'Il l’emporta, et il cessa de chercher. Vous avez appris '
            'qu’on peut marchander avec n’importe qui, et vous avez mal dormi '
            'pendant un an.',
      ),
    ],
  ),
  'voidkin': OriginMemory(
    id: 'mark_voidkin',
    age: 8,
    titleEn: 'The Frozen Well',
    titleFr: 'Le puits gelé',
    sceneEn: 'You were eight when the thing in you froze the well-bucket '
        'solid in July, in front of the whole street. After that the other '
        'children threw stones. One day the boldest of them leaned out over '
        'the well to throw, and slipped in.',
    sceneFr: 'Vous aviez huit ans quand la chose en vous gela le seau du puits '
        'en plein juillet, devant toute la rue. Après cela, les autres enfants '
        'vous jetèrent des pierres. Un jour, le plus hardi se pencha au-dessus '
        'du puits pour lancer, et tomba dedans.',
    answers: [
      OriginAnswer(
        id: 'good',
        en: 'Pull him out, cold hands and all',
        fr: 'Le sortir de là, mains glacées ou non',
        alignmentMod: 4,
        ability: 'strength',
        outcomeEn: 'He screamed when you touched him, and lived. He never '
            'threw another stone, and never thanked you. You learned that '
            'saving someone does not make them like you.',
        outcomeFr: 'Il hurla quand vos mains le touchèrent, et il vécut. Il ne '
            'jeta plus jamais de pierre, et ne dit jamais merci. Vous avez '
            'appris que sauver quelqu’un ne le pousse pas à vous aimer.',
      ),
      OriginAnswer(
        id: 'neutral',
        en: 'Shout for the grown-ups, hands to yourself',
        fr: 'Appeler les adultes, sans le toucher',
        alignmentMod: 0,
        ability: 'perception',
        outcomeEn: 'They got him out. Nobody asked why you had not helped. You '
            'learned that nobody expected you to, and to notice what people '
            'expect.',
        outcomeFr: 'Ils le sortirent. Personne ne demanda pourquoi vous '
            'n’aviez pas aidé. Vous avez appris que personne ne l’attendait de '
            'vous, et à remarquer ce que les gens attendent.',
      ),
      OriginAnswer(
        id: 'evil',
        en: 'Let the cold in you reach down the rope',
        fr: 'Laisser le froid en vous descendre la corde',
        alignmentMod: -4,
        ability: 'intelligence',
        outcomeEn: 'The water skinned over with ice around him. They pulled '
            'him out blue and alive, and the whole street knew what you had '
            'done without being able to say how. You learned what the cold was '
            'for.',
        outcomeFr: 'L’eau se couvrit de glace autour de lui. On le sortit bleu '
            'et vivant, et toute la rue sut ce que vous aviez fait sans pouvoir '
            'dire comment. Vous avez appris à quoi servait le froid.',
      ),
    ],
  ),
};

const _beggar = OriginMemory(
  id: 'beggar',
  age: 10,
  titleEn: 'The Blind Beggar',
  titleFr: 'Le mendiant aveugle',
  sceneEn: 'You were ten. An old blind man begged at the door of the tavern '
      'on Tallow Street, and people had started calling the place the Blind '
      'Beggar after him. One winter evening, as you passed with the last loaf '
      'of the day still warm, he caught your sleeve.',
  sceneFr: 'Vous aviez dix ans. Un vieil aveugle mendiait à la porte de la '
      'taverne de la rue du Suif, et les gens s’étaient mis à appeler '
      'l’endroit le Mendiant Aveugle, d’après lui. Un soir d’hiver, comme vous '
      'passiez avec le dernier pain du jour encore chaud, il saisit votre '
      'manche.',
  recalls: [
    OriginRecall(
      flag: 'origin_sparrow_good',
      en: 'Since the sparrow, you had never been able to walk past a hurt '
          'thing without looking.',
      fr: 'Depuis le moineau, vous n’aviez jamais pu passer devant une chose '
          'blessée sans regarder.',
    ),
    OriginRecall(
      flag: 'origin_sparrow_neutral',
      en: 'Since the sparrow, you had known you could do a hard thing quickly '
          'and not look back.',
      fr: 'Depuis le moineau, vous saviez faire vite une chose dure, sans vous '
          'retourner.',
    ),
    OriginRecall(
      flag: 'origin_sparrow_evil',
      en: 'Since the sparrow, you had known that even pity had a price.',
      fr: 'Depuis le moineau, vous saviez que même la pitié avait un prix.',
    ),
  ],
  answers: [
    OriginAnswer(
      id: 'good',
      en: 'Give him the loaf',
      fr: 'Lui donner le pain',
      alignmentMod: 4,
      ability: 'luck',
      outcomeEn: 'He tore it in two and pressed half back into your hands. '
          '“You’ll come to a bad end,” he said, “but a lucky one.” You learned '
          'that what you give away has a way of coming back.',
      outcomeFr: 'Il le rompit en deux et vous en rendit la moitié. « Vous '
          'finirez mal, dit-il, mais avec de la chance. » Vous avez appris que '
          'ce qu’on donne a une façon de revenir.',
    ),
    OriginAnswer(
      id: 'neutral',
      en: 'Pull free and keep walking',
      fr: 'Vous dégager et continuer votre chemin',
      alignmentMod: 0,
      ability: 'perception',
      outcomeEn:
          'His grip was weaker than it looked. You learned to see a hand '
          'coming before it reached you, and to be gone when it arrived.',
      outcomeFr: 'Sa prise était plus faible qu’elle n’en avait l’air. Vous '
          'avez appris à voir venir une main avant qu’elle n’arrive, et à ne '
          'plus être là quand elle arrive.',
    ),
    OriginAnswer(
      id: 'evil',
      en: 'Let him hold your sleeve while you empty his cup',
      fr: 'Le laisser tenir votre manche pendant que vous videz sa sébile',
      alignmentMod: -4,
      ability: 'dexterity',
      outcomeEn: 'Four coppers and a button. He never knew. You learned that '
          'your hands were quicker than a blind man’s ears, and for a day you '
          'thought it something to be proud of.',
      outcomeFr: 'Quatre sous et un bouton. Il n’en sut jamais rien. Vous avez '
          'appris que vos mains étaient plus vives que les oreilles d’un '
          'aveugle, et pendant un jour, cela vous a semblé une fierté.',
    ),
  ],
);

/// What the blind man's memory left, recalled when the calling comes.
const List<OriginRecall> _callingRecalls = [
  OriginRecall(
    flag: 'origin_beggar_good',
    en: 'The blind man still called you “the lucky one” when you passed his '
        'door.',
    fr: 'L’aveugle vous appelait encore « porte-bonheur » quand vous passiez '
        'devant sa porte.',
  ),
  OriginRecall(
    flag: 'origin_beggar_neutral',
    en: 'By twelve, nobody on Tallow Street could catch your sleeve any more.',
    fr: 'À douze ans, plus personne rue du Suif ne pouvait saisir votre '
        'manche.',
  ),
  OriginRecall(
    flag: 'origin_beggar_evil',
    en: 'The coppers from the blind man’s cup were long spent. The habit was '
        'not.',
    fr: 'Les sous de la sébile de l’aveugle étaient dépensés depuis longtemps. '
        'L’habitude, non.',
  ),
];

/// The fourth memory, by profession: the first time the calling showed.
const Map<String, OriginMemory> _callingByProfession = {
  'warrior': OriginMemory(
    id: 'calling_warrior',
    age: 12,
    titleEn: 'The Net-Mender’s Daughter',
    titleFr: 'La fille du ravaudeur',
    sceneEn: 'You were twelve and hauled nets on the docks for a copper a day. '
        'A drunk sailor twice your size shoved the net-mender’s daughter off '
        'the pier for being slow, and stood at the edge laughing while she '
        'floundered in the harbor.',
    sceneFr:
        'Vous aviez douze ans et vous haliez des filets sur les quais pour '
        'un sou par jour. Un marin ivre, deux fois plus large que vous, poussa '
        'la fille du ravaudeur du haut de la jetée parce qu’elle était trop '
        'lente, et resta au bord à rire pendant qu’elle se débattait dans le '
        'port.',
    recalls: _callingRecalls,
    answers: [
      OriginAnswer(
        id: 'good',
        en: 'Pull her out, then stand between them',
        fr: 'La sortir de l’eau, puis vous mettre entre eux',
        alignmentMod: 4,
        ability: 'constitution',
        outcomeEn: 'He hit you twice. The third time, he looked at your face '
            'and walked away. You learned you could take a blow and stay '
            'standing.',
        outcomeFr: 'Il frappa deux fois. À la troisième, il regarda votre '
            'visage et s’en alla. Vous avez appris à encaisser un coup sans '
            'tomber.',
      ),
      OriginAnswer(
        id: 'neutral',
        en: 'Throw her a line and get back to work',
        fr: 'Lui lancer une corde et retourner au travail',
        alignmentMod: 0,
        ability: 'strength',
        outcomeEn: 'She came up the line hand over hand, and you hauled her '
            'nets as well as yours until the tide turned. You learned what '
            'your back was worth.',
        outcomeFr: 'Elle remonta la corde main après main, et vous avez halé '
            'ses filets en plus des vôtres jusqu’à la marée. Vous avez appris '
            'ce que valait votre dos.',
      ),
      OriginAnswer(
        id: 'evil',
        en: 'Laugh along, and catch the coin he flips you',
        fr: 'Rire avec lui, et attraper la pièce qu’il vous lance',
        alignmentMod: -4,
        ability: 'charisma',
        outcomeEn: 'It was a whole silver. She got out on her own. You learned '
            'that the strong pay well for an audience.',
        outcomeFr: 'C’était une pièce d’argent entière. Elle sortit de l’eau '
            'par ses propres moyens. Vous avez appris que les forts paient bien '
            'leur public.',
      ),
    ],
  ),
  'mage': OriginMemory(
    id: 'calling_mage',
    age: 12,
    titleEn: 'The Leaning Flame',
    titleFr: 'La flamme qui penche',
    sceneEn: 'You were twelve when you found that a candle flame leaned toward '
        'you if you wanted it to, and the chandler’s apprentice saw you do it. '
        'That same week, the Crusade’s criers stood in the square, paying '
        'silver for word of “unclean gifts”.',
    sceneFr: 'Vous aviez douze ans quand vous avez découvert qu’une flamme de '
        'chandelle penchait vers vous si vous le vouliez, et l’apprenti du '
        'chandelier vous vit faire. La même semaine, sur la place, les crieurs '
        'de la Croisade payaient en argent toute dénonciation de « dons '
        'impurs ».',
    recalls: _callingRecalls,
    answers: [
      OriginAnswer(
        id: 'good',
        en: 'Teach him the trick, so the secret is his too',
        fr: 'Lui apprendre le tour, pour que le secret soit aussi le sien',
        alignmentMod: 4,
        ability: 'wisdom',
        outcomeEn: 'He never managed it, but he never told either. You learned '
            'that a secret shared is a secret guarded.',
        outcomeFr: 'Il n’y arriva jamais, mais il ne parla jamais non plus. '
            'Vous avez appris qu’un secret partagé est un secret gardé.',
      ),
      OriginAnswer(
        id: 'neutral',
        en: 'Never do it again where anyone can see',
        fr: 'Ne plus jamais le faire devant quiconque',
        alignmentMod: 0,
        ability: 'intelligence',
        outcomeEn: 'You practised in the dark for four years instead, and '
            'learned more about fire without light than most learn with it.',
        outcomeFr: 'Pendant quatre ans, vous vous exerciez dans le noir, et '
            'vous avez appris sur le feu, sans lumière, plus que la plupart '
            'n’en apprennent avec.',
      ),
      OriginAnswer(
        id: 'evil',
        en: 'Tell the criers about him before he talks',
        fr: 'Le dénoncer aux crieurs avant qu’il ne parle',
        alignmentMod: -4,
        ability: 'charisma',
        outcomeEn: 'They took him, not you. You never learned what he told '
            'them. You learned that the first story told is the one believed.',
        outcomeFr: 'Ils l’emmenèrent, lui, et pas vous. Vous n’avez jamais su '
            'ce qu’il leur avait dit. Vous avez appris que la première histoire '
            'racontée est celle qu’on croit.',
      ),
    ],
  ),
  'rogue': OriginMemory(
    id: 'calling_rogue',
    age: 12,
    titleEn: 'The Rigged Table',
    titleFr: 'La table truquée',
    sceneEn: 'You were twelve when an old card-sharp in the back alleys made '
        'you his shill: you sat, you won loudly, and the next mark sat down to '
        'lose. Tonight’s mark was a dock porter with a week’s wages and a sick '
        'wife he would not stop mentioning.',
    sceneFr: 'Vous aviez douze ans quand un vieux tricheur des ruelles fit de '
        'vous son appât : vous vous asseyiez, vous gagniez bruyamment, et le '
        'pigeon suivant s’asseyait pour perdre. Ce soir, le pigeon était un '
        'porteur des quais, une semaine de paie en poche, et une femme malade '
        'dont il ne cessait de parler.',
    recalls: [
      OriginRecall(
        flag: 'origin_beggar_evil',
        en: 'The card-sharp had watched you empty a blind man’s cup two '
            'winters before. That was why he chose you.',
        fr: 'Le tricheur avait regardé votre main vider la sébile d’un aveugle, '
            'deux hivers plus tôt. C’est pour cela que son choix s’était porté '
            'sur vous.',
      ),
      ..._callingRecalls,
    ],
    answers: [
      OriginAnswer(
        id: 'good',
        en: 'Warn the porter before he sits',
        fr: 'Prévenir le porteur avant qu’il s’assoie',
        alignmentMod: 4,
        ability: 'perception',
        outcomeEn:
            'The sharp never used you again, and the porter bought you a '
            'pie. You learned to read a table before you sit at it.',
        outcomeFr: 'Le tricheur ne fit plus jamais appel à vous, et le porteur '
            'vous offrit une tourte. Vous avez appris à lire une table avant de '
            'vous y asseoir.',
      ),
      OriginAnswer(
        id: 'neutral',
        en: 'Get up and walk away from the table',
        fr: 'Vous lever et quitter la table',
        alignmentMod: 0,
        ability: 'wisdom',
        outcomeEn: 'The sharp found another shill by morning. You learned that '
            'the only sure win is the game you do not play.',
        outcomeFr: 'Le tricheur trouva un autre appât dès le matin. Vous avez '
            'appris que la seule partie gagnée d’avance est celle qu’on ne joue '
            'pas.',
      ),
      OriginAnswer(
        id: 'evil',
        en: 'Play your part and take your cut',
        fr: 'Jouer votre rôle et prendre votre part',
        alignmentMod: -4,
        ability: 'dexterity',
        outcomeEn: 'The porter lost everything, and you lost count of your '
            'share. You learned that your hands were quicker than an honest '
            'man’s eyes.',
        outcomeFr: 'Le porteur perdit tout, et vous avez perdu le compte de '
            'votre part. Vous avez appris que vos mains allaient plus vite que '
            'les yeux d’un honnête homme.',
      ),
    ],
  ),
  'cleric': OriginMemory(
    id: 'calling_cleric',
    age: 12,
    titleEn: 'The Sleeper Under the Altar',
    titleFr: 'La dormeuse sous l’autel',
    sceneEn: 'You were twelve and swept the little shrine of the Drowned Saint '
        'by the fish market, for a bowl of soup a day. A sick woman crept in '
        'one night to sleep under the altar, and the shrine-keeper told you to '
        'put her out before the morning prayers.',
    sceneFr: 'Vous aviez douze ans et vous balayiez le petit sanctuaire du '
        'Saint Noyé, près du marché aux poissons, pour un bol de soupe par '
        'jour. Une nuit, une femme malade s’y glissa pour dormir sous l’autel, '
        'et le gardien vous ordonna de la mettre dehors avant les prières du '
        'matin.',
    recalls: _callingRecalls,
    answers: [
      OriginAnswer(
        id: 'good',
        en: 'Let her sleep, and take the broom for it',
        fr: 'La laisser dormir, et recevoir le balai à sa place',
        alignmentMod: 4,
        ability: 'wisdom',
        outcomeEn:
            'He beat you with the broom handle, and she woke well enough '
            'to walk. You learned that a shrine is for whoever needs the roof.',
        outcomeFr: 'Le manche du balai s’abattit sur votre dos, et elle se '
            'réveilla assez bien pour marcher. Vous avez appris qu’un '
            'sanctuaire est à qui a besoin du toit.',
      ),
      OriginAnswer(
        id: 'neutral',
        en: 'Wake her gently and walk her to the door',
        fr: 'La réveiller doucement et la raccompagner à la porte',
        alignmentMod: 0,
        ability: 'charisma',
        outcomeEn: 'She went without a fuss, because you asked her like a '
            'person. You learned how much a kind voice can carry out of a door.',
        outcomeFr: 'Elle partit sans histoire, parce que vous lui aviez parlé '
            'comme à quelqu’un. Vous avez appris tout ce qu’une voix douce peut '
            'faire passer par une porte.',
      ),
      OriginAnswer(
        id: 'evil',
        en: 'Put her out, and eat her share of the soup',
        fr: 'La mettre dehors, et manger sa part de soupe',
        alignmentMod: -4,
        ability: 'constitution',
        outcomeEn: 'It was good soup. You learned that a full stomach quiets '
            'most things, and went on learning it all winter.',
        outcomeFr:
            'C’était une bonne soupe. Vous avez appris qu’un ventre plein '
            'fait taire presque tout, et vous l’avez réappris tout l’hiver.',
      ),
    ],
  ),
  'ranger': OriginMemory(
    id: 'calling_ranger',
    age: 12,
    titleEn: 'The Vixen',
    titleFr: 'La renarde',
    sceneEn: 'You were twelve and set snares in the marsh past the tanneries, '
        'and you were good at it. One morning a snare held a vixen, her cubs '
        'crying in the reeds, and a fox pelt fetched a week’s bread.',
    sceneFr: 'Vous aviez douze ans et vous posiez des collets dans le marais, '
        'après les tanneries, avec un vrai talent. Un matin, un collet tenait '
        'une renarde, ses petits pleurant dans les roseaux, et une peau de '
        'renard valait une semaine de pain.',
    recalls: _callingRecalls,
    answers: [
      OriginAnswer(
        id: 'good',
        en: 'Cut her loose',
        fr: 'La libérer',
        alignmentMod: 4,
        ability: 'wisdom',
        outcomeEn: 'She bit your hand on the way out, and you let her. You '
            'learned that the marsh keeps its own accounts.',
        outcomeFr: 'Elle mordit votre main en s’échappant, et vous l’avez '
            'laissée faire. Vous avez appris que le marais tient ses propres '
            'comptes.',
      ),
      OriginAnswer(
        id: 'neutral',
        en: 'Take the pelt; a week’s bread is bread',
        fr: 'Prendre la peau : une semaine de pain reste du pain',
        alignmentMod: 0,
        ability: 'dexterity',
        outcomeEn: 'You did it cleanly, the way the old trapper had shown you. '
            'You learned to do the necessary thing, and to do it well.',
        outcomeFr: 'Le geste fut net, comme le vieux trappeur l’avait montré. '
            'Vous avez appris à faire le nécessaire, et à bien le faire.',
      ),
      OriginAnswer(
        id: 'evil',
        en: 'Take her, and come back for the cubs',
        fr: 'La prendre, et revenir pour les petits',
        alignmentMod: -4,
        ability: 'perception',
        outcomeEn: 'Four pelts are worth more than one. You learned to see the '
            'whole of a thing, and to take all of it.',
        outcomeFr: 'Quatre peaux valent mieux qu’une. Vous avez appris à voir '
            'une chose en entier, et à la prendre tout entière.',
      ),
    ],
  ),
};

const _lamp = OriginMemory(
  id: 'lamp',
  age: 14,
  titleEn: 'Old Hesk’s Lamp',
  titleFr: 'La lampe du vieux Hesk',
  sceneEn: 'You were fourteen. Old Hesk next door owned one good thing: a '
      'blue glass lamp from over the sea, lit every evening in his window '
      'while Mother Hesk sold eggs at the door and overcharged for them. A '
      'stone you threw at a gull went straight through it.',
  sceneFr: 'Vous aviez quatorze ans. Le vieux Hesk, le voisin, possédait une '
      'seule belle chose : une lampe de verre bleu venue d’outre-mer, allumée '
      'chaque soir à sa fenêtre pendant que la mère Hesk vendait ses œufs sur '
      'le pas de la porte, trop cher. Une pierre lancée sur une mouette passa '
      'droit au travers.',
  // The name the first four answers have made on the street.
  recalls: [
    OriginRecall(
      minTotal: 8,
      en: 'By fourteen, people on the street had started to call you soft, '
          'and to come to you when something was broken.',
      fr: 'À quatorze ans, les gens de la rue disaient que vous aviez le cœur '
          'tendre, et venaient vous trouver quand quelque chose était cassé.',
    ),
    OriginRecall(
      maxTotal: -8,
      en: 'By fourteen, mothers on the street called their children in when '
          'you went by.',
      fr: 'À quatorze ans, les mères de la rue rappelaient leurs enfants quand '
          'vous passiez.',
    ),
    OriginRecall(
      en: 'By fourteen, you had a name on the street for minding your own '
          'business.',
      fr: 'À quatorze ans, on vous connaissait dans la rue pour ne vous mêler '
          'que de vos affaires.',
    ),
  ],
  answers: [
    OriginAnswer(
      id: 'good',
      en: 'Knock on his door and own up',
      fr: 'Frapper à sa porte et avouer',
      alignmentMod: 4,
      ability: 'intelligence',
      outcomeEn: 'He made you carry his water every morning for a summer, and '
          'talked about the sea the whole way. By autumn you had learned more '
          'about ships than anyone in the slums knew.',
      outcomeFr: 'Il vous fit porter son eau chaque matin tout un été, en '
          'parlant de la mer tout le long du chemin. À l’automne, vous en '
          'aviez appris plus sur les navires que quiconque dans les taudis.',
    ),
    OriginAnswer(
      id: 'neutral',
      en: 'Say nothing, and never aim at his window again',
      fr: 'Ne rien dire, et ne plus jamais viser sa fenêtre',
      alignmentMod: 0,
      ability: 'constitution',
      outcomeEn: 'He never lit a window again. You learned to keep a secret, '
          'which is to say, to carry one.',
      outcomeFr:
          'Il n’alluma plus jamais de fenêtre. Vous avez appris à garder '
          'un secret, c’est-à-dire à le porter.',
    ),
    OriginAnswer(
      id: 'evil',
      en: 'Tell him the smith’s boy did it',
      fr: 'Lui dire que c’était le fils du forgeron',
      alignmentMod: -4,
      ability: 'charisma',
      outcomeEn:
          'The smith’s boy got the belt, and Mother Hesk gave you an egg '
          'for your honesty. You learned how cheap a lie is, and how well it '
          'pays.',
      outcomeFr: 'Le fils du forgeron reçut la ceinture, et la mère Hesk vous '
          'donna un œuf pour votre honnêteté. Vous avez appris combien un '
          'mensonge coûte peu, et combien il rapporte.',
    ),
  ],
);

const _board = OriginMemory(
  id: 'board',
  age: 16,
  titleEn: 'The Loose Board',
  titleFr: 'La latte branlante',
  sceneEn: 'You were sixteen, the winter your parents went out one night and '
      'did not come home. A week later you found a starving girl in the hovel, '
      'her hand already under the loose floorboard where they had kept the '
      'grey bundle. She was younger than you, and the watch was hanging '
      'thieves that year.',
  sceneFr: 'Vous aviez seize ans, l’hiver où vos parents sortirent un soir '
      'pour ne jamais revenir. Une semaine plus tard, vous avez trouvé dans la '
      'masure une fille affamée, la main déjà sous la latte branlante où ils '
      'gardaient le ballot gris. Elle était plus jeune que vous, et cette '
      'année-là, le guet pendait les voleurs.',
  recalls: [
    OriginRecall(
      flag: 'origin_beggar_good',
      en: 'She had the blind man’s way of tilting her head: his granddaughter, '
          'you learned later. She knew your face.',
      fr: 'Elle penchait la tête comme l’aveugle : sa petite-fille, vous l’avez '
          'su plus tard. Elle connaissait votre visage.',
    ),
    OriginRecall(
      flag: 'origin_beggar_evil',
      en: 'She had the blind man’s way of tilting her head: his '
          'granddaughter. Later, you wondered what four coppers and a button '
          'would have bought her.',
      fr: 'Elle penchait la tête comme l’aveugle : sa petite-fille. Plus tard, '
          'une question vous revenait : ce que quatre sous et un bouton lui '
          'auraient acheté.',
    ),
    OriginRecall(
      flag: 'origin_mark_human_neutral',
      en: 'Your mother had shown you that bundle once, and never unwrapped it. '
          'Now there was nobody left to ask.',
      fr: 'Votre mère vous avait montré ce ballot une fois, sans jamais le '
          'défaire. Il ne restait plus personne à qui demander.',
    ),
  ],
  answers: [
    OriginAnswer(
      id: 'good',
      en: 'Give her the bread and let her go',
      fr: 'Lui donner le pain et la laisser partir',
      alignmentMod: 4,
      ability: 'charisma',
      outcomeEn: 'She ran with the bread and left the bundle. You moved it two '
          'boards over that night, and left it there. You learned that a loaf '
          'and a kind word can end a fight before it starts.',
      outcomeFr: 'Elle s’enfuit avec le pain et laissa le ballot. Cette '
          'nuit-là, vous l’avez déplacé deux lattes plus loin, et il n’en a '
          'plus bougé. Vous avez appris qu’un pain et un mot doux peuvent '
          'finir une bagarre avant qu’elle commence.',
    ),
    OriginAnswer(
      id: 'neutral',
      en: 'Take the bundle back and show her the door',
      fr: 'Reprendre le ballot et lui montrer la porte',
      alignmentMod: 0,
      ability: 'strength',
      outcomeEn: 'She did not argue with your grip. You moved the bundle two '
          'boards over that night, and left it there. You learned to hold on '
          'to what is yours.',
      outcomeFr: 'Elle ne discuta pas votre poigne. Cette nuit-là, vous avez '
          'déplacé le ballot deux lattes plus loin, et il n’en a plus bougé. '
          'Vous avez appris à tenir ce qui est à vous.',
    ),
    OriginAnswer(
      id: 'evil',
      en: 'Hold her there and shout for the watch',
      fr: 'La retenir et appeler le guet',
      alignmentMod: -4,
      ability: 'perception',
      outcomeEn: 'They came. You did not go to the hanging. You moved the '
          'bundle two boards over that night, and learned to hear every step '
          'on the stair.',
      outcomeFr: 'Ils vinrent. Vous n’avez pas assisté à la pendaison. Cette '
          'nuit-là, vous avez déplacé le ballot deux lattes plus loin, et '
          'appris à entendre chaque pas dans l’escalier.',
    ),
  ],
);

/// The six memories for a character of [raceId] and [professionId], in
/// order of age. An unknown race or profession gets the human's and the
/// warrior's.
List<OriginMemory> originMemoriesFor({String? raceId, String? professionId}) =>
    [
      _sparrow,
      _markByRace[raceId] ?? _markByRace['human']!,
      _beggar,
      _callingByProfession[professionId] ?? _callingByProfession['warrior']!,
      _lamp,
      _board,
    ];

/// Every memory, every race's and profession's variant included (for
/// tests and tools).
List<OriginMemory> get allOriginMemories => [
      _sparrow,
      ..._markByRace.values,
      _beggar,
      ..._callingByProfession.values,
      _lamp,
      _board,
    ];

/// The race keys with their own second memory.
Iterable<String> get originMarkRaces => _markByRace.keys;

/// The profession keys with their own fourth memory.
Iterable<String> get originCallingProfessions => _callingByProfession.keys;

/// The memory and answer that leave [flag] (`origin_<memory>_<answer>`),
/// or null.
({OriginMemory memory, OriginAnswer answer})? originAnswerForFlag(String flag) {
  if (!flag.startsWith('origin_')) return null;
  for (final memory in allOriginMemories) {
    for (final answer in memory.answers) {
      if (memory.flagFor(answer) == flag) {
        return (memory: memory, answer: answer);
      }
    }
  }
  return null;
}

/// What a set of answers adds up to: the alignment, the abilities taught
/// and the flags left. [answers] go with [memories], in order; a null
/// answer counts for nothing.
class OriginResult {
  const OriginResult({
    required this.alignment,
    required this.abilities,
    required this.flags,
  });

  final int alignment;

  /// Ability -> points, in the order first taught.
  final Map<String, int> abilities;
  final List<String> flags;
}

OriginResult originResultOf(
    List<OriginMemory> memories, List<OriginAnswer?> answers) {
  var alignment = 0;
  final abilities = <String, int>{};
  final flags = <String>[];
  for (var i = 0; i < memories.length && i < answers.length; i++) {
    final answer = answers[i];
    if (answer == null) continue;
    alignment += answer.alignmentMod;
    abilities.update(answer.ability, (n) => n + 1, ifAbsent: () => 1);
    flags
      ..add(memories[i].flag)
      ..add(memories[i].flagFor(answer));
  }
  return OriginResult(alignment: alignment, abilities: abilities, flags: flags);
}

/// The one-line portrait of who the answers made: 'good', 'evil' or
/// 'neutral' when four or more of six lean that way, else 'mixed'.
String originPortraitOf(Iterable<OriginAnswer?> answers) {
  final counts = <String, int>{};
  for (final answer in answers) {
    if (answer == null) continue;
    counts.update(answer.id, (n) => n + 1, ifAbsent: () => 1);
  }
  for (final id in ['good', 'evil', 'neutral']) {
    if ((counts[id] ?? 0) >= 4) return id;
  }
  return 'mixed';
}
