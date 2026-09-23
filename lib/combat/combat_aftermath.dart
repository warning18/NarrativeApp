import 'dart:math';

/// What a fight left behind, for the story to react to -- published by
/// FightScreen (see `lastFightOutcomeProvider`) and turned into one
/// paragraph by [aftermathLineFor], which the next scene opens with.
class FightOutcome {
  const FightOutcome({
    required this.won,
    required this.enemyNames,
    this.isElite = false,
    this.isHunt = false,
    this.isBoss = false,
    this.phasesCrossed = 0,
    this.knockedOutAllyName,
    this.flawless = false,
    this.rounds = 1,
    this.chapter = 1,
  });

  final bool won;

  /// Display names, the first being the fight's headline enemy.
  final List<String> enemyNames;
  final bool isElite;
  final bool isHunt;
  final bool isBoss;
  final int phasesCrossed;

  /// The companion knocked out during the fight (the last one, if
  /// several), or null.
  final String? knockedOutAllyName;

  /// No potion drunk, nobody knocked out.
  final bool flawless;
  final int rounds;
  final int chapter;

  String get enemyName => enemyNames.isEmpty ? '' : enemyNames.first;
}

class _Pool {
  const _Pool(this.en, this.fr);

  final List<String> en;
  final List<String> fr;

  String pick(bool french, int seed) {
    final list = french ? fr : en;
    return list[seed.abs() % list.length];
  }
}

const _lost = _Pool([
  'I came to on the stones with {enemy} already gone and the taste of my own '
      'blood in my mouth, which was, at least, familiar. Whatever I had '
      'intended to prove, I had proved the opposite.',
  'It was not a retreat so much as a decision, made on my behalf by my '
      'legs, that {enemy} could keep the ground. I let them keep it.',
  'The world went sideways, then dark, then back again with {enemy} '
      'nowhere in sight and my pockets exactly as light as before. Some '
      'lessons are cheap. This one was merely survivable.',
], [
  'Je revins à moi sur les pierres, {enemy} déjà parti et le goût de mon '
      "propre sang dans la bouche, ce qui, au moins, m'était familier. Quoi "
      "que j'aie voulu prouver, j'avais prouvé le contraire.",
  "Ce ne fut pas tant une retraite qu'une décision, prise en mon nom par "
      'mes jambes, de laisser le terrain à {enemy}. Je le lui laissai.',
  'Le monde bascula, puis noircit, puis revint, {enemy} disparu et mes '
      "poches exactement aussi légères qu'avant. Certaines leçons sont bon "
      "marché. Celle-ci n'était que survivable.",
]);

const _boss = _Pool([
  '{enemy} changed twice before the end, and each time I thought I had '
      "learned the shape of the thing it became something else. When it "
      'finally stopped moving I stood over it for a long moment, not '
      'trusting the stillness, and then trusted it, because there was '
      'nothing else left to do.',
  'It took everything I had brought and some things I had not known I '
      'was carrying, but {enemy} lay still at the end of it, and the '
      'silence that followed had the particular weight of a debt paid.',
  'I do not remember the last blow, only the one before it, and the way '
      '{enemy} looked at me as if I were the surprise. Perhaps I was.',
], [
  '{enemy} changea deux fois avant la fin, et chaque fois que je croyais '
      "avoir compris sa forme, elle devenait autre chose. Quand elle cessa "
      "enfin de bouger, je restai longtemps au-dessus d'elle, sans me fier "
      "à l'immobilité, puis m'y fiai, faute de quoi que ce soit d'autre à faire.",
  "Cela prit tout ce que j'avais apporté et quelques choses que je ne "
      'savais pas porter, mais {enemy} gisait immobile à la fin, et le '
      "silence qui suivit avait le poids particulier d'une dette réglée.",
  'Je ne me souviens pas du dernier coup, seulement de celui d\'avant, et de '
      "la façon dont {enemy} me regarda comme si j'étais la surprise. "
      "Peut-être l'étais-je.",
]);

const _elite = _Pool([
  '{enemy} had been bigger and meaner than its kind had any business '
      'being, and it went down harder, and I took the trophy off it with '
      'the specific satisfaction of a man who has been owed something for '
      'some time.',
  'Whatever had made {enemy} what it was, it had not made it clever. It '
      'lay where it fell, larger than the story I would tell about it, '
      'which is rarely the case.',
], [
  "{enemy} avait été plus gros et plus méchant que son espèce n'en a le "
      'droit, et il tomba plus durement, et je lui pris son trophée avec la '
      "satisfaction précise d'un homme à qui l'on doit quelque chose depuis "
      'un moment.',
  "Quoi qui ait fait de {enemy} ce qu'il était, cela ne l'avait pas rendu "
      "malin. Il gisait là où il était tombé, plus grand que l'histoire que "
      "j'en ferais, ce qui est rarement le cas.",
]);

const _hunt = _Pool([
  'The trail ended where trails like it always end, and {enemy} with it. I '
      'left the lair to whatever came next and took only what it had '
      'taken from others.',
  'It had a name by the end, because things that run and are followed '
      'earn one. {enemy} will not be earning anything else.',
], [
  'La piste finissait là où finissent toujours les pistes de ce genre, et '
      "{enemy} avec elle. Je laissai le repaire à ce qui viendrait ensuite "
      "et ne pris que ce qu'il avait pris aux autres.",
  "Il avait un nom à la fin, parce que ce qui fuit et que l'on suit en "
      "mérite un. {enemy} n'en méritera pas d'autre.",
]);

const _allyDown = _Pool([
  '{ally} went down before the end of it and stayed down long enough that '
      'I stopped counting the seconds and started counting what I would '
      'say. Then {ally} coughed, and swore, and I did not have to say '
      'anything at all.',
  'We won, if that is the word for a fight that ended with {ally} face '
      'down in the dirt and me pulling them up by the collar. They will '
      'not thank me for the collar. They rarely do.',
], [
  '{ally} tomba avant la fin et resta à terre assez longtemps pour que je '
      "cesse de compter les secondes et commence à compter ce que je "
      "dirais. Puis {ally} toussa, jura, et je n'eus rien à dire du tout.",
  "Nous avons gagné, si c'est le mot pour un combat qui se termine avec "
      "{ally} face contre terre et moi le relevant par le col. On ne me "
      'remerciera pas pour le col. On le fait rarement.',
]);

const _flawless = _Pool([
  '{enemy} never landed a blow worth the name. I would like to say it was '
      'skill. It was mostly that I had learned, at last, to stop standing '
      'where the blade was going to be.',
  'It was over quickly and cleanly, which is how I prefer things to be '
      'over and how they so rarely are. {enemy} had not expected the '
      'competence. Neither, frankly, had I.',
], [
  "{enemy} ne plaça jamais un coup digne de ce nom. J'aimerais dire que "
      "c'était du talent. C'était surtout que j'avais enfin appris à ne plus "
      'me tenir là où la lame allait passer.',
  'Ce fut vite fait et proprement, ce qui est ma façon préférée que les '
      "choses se terminent et celle qu'elles adoptent si rarement. {enemy} "
      "ne s'attendait pas à tant de compétence. Moi non plus, franchement.",
]);

const _won = _Pool([
  '{enemy} was down and I was not, which is the whole of what a fight is '
      'for, and I moved on before either of us could reconsider.',
  'It cost me some blood and most of my patience, but {enemy} would not '
      'be troubling the road again, and the road had plenty of trouble '
      'left without it.',
  'I put {enemy} down the way one puts down anything that will not listen '
      'to reason: thoroughly, and without much hope of being thanked.',
  'The fight went the way fights go when you have stopped expecting them '
      'to be fair. {enemy} fell. I checked my pockets, and my ribs, and '
      'went on.',
], [
  "{enemy} était à terre et moi non, ce qui est tout ce à quoi sert un "
      "combat, et je repris ma route avant que l'un de nous ne se ravise.",
  "Cela me coûta un peu de sang et l'essentiel de ma patience, mais "
      "{enemy} n'importunerait plus la route, et la route avait bien assez "
      "d'ennuis sans lui.",
  "J'abattis {enemy} comme on abat tout ce qui n'entend pas raison : "
      "consciencieusement, et sans grand espoir d'être remercié.",
  'Le combat se déroula comme se déroulent les combats quand on a cessé '
      "de les espérer loyaux. {enemy} tomba. Je vérifiai mes poches, puis "
      'mes côtes, et poursuivis.',
]);

const _death = _Pool([
  'There is a moment, I am told, when the body understands before the '
      'mind does. Mine understood on the ground, with {enemy} standing '
      'over it and the sky doing something unimportant overhead. The '
      'story, it turned out, was not mine to finish. Someone else will '
      'carry it from here, and will carry it with what I learned.',
  'The last thing I saw was {enemy}, and the last thing I thought was '
      'that I had meant to do this better. Whoever picks up the road after '
      'me will know at least that much: where it goes, and what it costs.',
  'I had survived worse. That was the trouble with surviving worse: it '
      'teaches you that you always will, right up until {enemy} proves the '
      'lesson wrong. The road does not end here. Only I do.',
  'No last words worth keeping. {enemy}, the cold, and then a quiet so '
      'complete it felt like a kindness. The Banner, the ledger, the camp '
      'below the Spire: all of it passes to whoever comes next.',
], [
  "Il y a un moment, m'a-t-on dit, où le corps comprend avant l'esprit. "
      "Le mien comprit au sol, {enemy} debout au-dessus de lui et le ciel "
      "occupé à quelque chose sans importance. L'histoire, en fin de compte, "
      "n'était pas à moi de la finir. Quelqu'un d'autre la portera d'ici, et "
      "la portera avec ce que j'ai appris.",
  'La dernière chose que je vis fut {enemy}, et la dernière chose que je '
      "pensai fut que j'avais voulu faire mieux. Qui reprendra la route "
      "après moi saura au moins cela : où elle mène, et ce qu'elle coûte.",
  "J'avais survécu à pire. C'était l'ennui, avec le fait de survivre à "
      "pire : cela vous apprend que vous survivrez toujours, jusqu'à ce que "
      "{enemy} démente la leçon. La route ne s'arrête pas ici. Moi seul.",
  'Pas de dernières paroles dignes d\'être gardées. {enemy}, le froid, puis '
      'un silence si complet qu\'il ressemblait à une bonté. La Bannière, le '
      'registre, le camp sous la Flèche : tout cela passe à qui viendra ensuite.',
]);

/// The paragraph the next scene opens with after [outcome], picked by
/// [seed] (a fight-scoped random number, so two fights in a row rarely
/// read the same) -- a loss first, then a boss that changed stance, an
/// Elite, a hunt's quarry, a companion knocked out, a flawless fight, and
/// a plain win.
String aftermathLineFor(FightOutcome outcome,
    {required bool french, required int seed}) {
  final _Pool pool;
  if (!outcome.won) {
    pool = _lost;
  } else if (outcome.isBoss && outcome.phasesCrossed > 0) {
    pool = _boss;
  } else if (outcome.isElite) {
    pool = _elite;
  } else if (outcome.isHunt) {
    pool = _hunt;
  } else if (outcome.knockedOutAllyName != null &&
      outcome.knockedOutAllyName!.isNotEmpty) {
    pool = _allyDown;
  } else if (outcome.flawless && outcome.rounds <= 3) {
    pool = _flawless;
  } else {
    pool = _won;
  }
  final enemy = outcome.enemyName.isEmpty
      ? (french ? "l'ennemi" : 'the enemy')
      : outcome.enemyName;
  return pool
      .pick(french, seed)
      .replaceAll('{enemy}', enemy)
      .replaceAll('{ally}', outcome.knockedOutAllyName ?? '');
}

/// A written death for the permadeath screen.
String deathNarrationFor(String enemyName,
    {required bool french, required int seed}) {
  final enemy =
      enemyName.isEmpty ? (french ? "l'ennemi" : 'the enemy') : enemyName;
  return _death.pick(french, seed).replaceAll('{enemy}', enemy);
}

/// Exposed for tests: every pool's English and French lists.
List<({List<String> en, List<String> fr})> get aftermathPoolsForTest => [
      for (final pool in [
        _lost,
        _boss,
        _elite,
        _hunt,
        _allyDown,
        _flawless,
        _won,
        _death
      ])
        (en: pool.en, fr: pool.fr),
    ];

/// A fight-scoped seed for [aftermathLineFor].
int aftermathSeed(Random random) => random.nextInt(1 << 20);
