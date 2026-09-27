/// A check's outcome in the story's own words (v1.168): one sentence for a
/// check that has no scene of its own to tell it -- a detour's "search
/// further", "scavenge" or "slip past", or a story check whose failure
/// carries on to the same scene -- so a roll never passes as if nothing
/// happened. The next scene opens with it.
///
/// First person, like the narrator; the French agrees with nothing about
/// the player's gender.
library;

class _Lines {
  const _Lines(this.en, this.fr);

  final List<String> en;
  final List<String> fr;
}

const _passed = <String, _Lines>{
  'perception': _Lines([
    'It was there, where the ground had been turned and patted flat again by '
        'someone in a hurry.',
    'A second look found what the first had walked past: a loose stone, and '
        'under it, the rest.',
    'I saw the scratch-mark before I saw the cache, and the cache was exactly '
        'where the scratch-mark said.',
  ], [
    "C'était là, où la terre avait été retournée puis tassée par quelqu'un de "
        'pressé.',
    'Un second regard trouva ce que le premier avait manqué : une pierre '
        'descellée, et dessous, le reste.',
    'Je vis la marque de griffure avant la cachette, et la cachette était '
        "exactement là où la marque l'annonçait.",
  ]),
  'luck': _Lines([
    'The coin fell my way, for once, and I did not ask it why.',
    'The first thing I turned over paid for the rest of the afternoon.',
    'Someone had dropped a purse there, and the world, briefly, remembered I '
        'existed.',
  ], [
    'La chance tomba de mon côté, pour une fois, et je ne lui demandai pas '
        'pourquoi.',
    "La première chose que je retournai paya le reste de l'après-midi.",
    "Quelqu'un avait laissé tomber une bourse là, et le monde, un instant, se "
        'souvint de mon existence.',
  ]),
  'dexterity': _Lines([
    'I went by close enough to hear them breathe, and not one of them turned '
        'its head.',
    'A shadow, a gap, a held breath, and the road ran behind them instead of '
        'through them.',
    'Nobody saw a thing, which is the whole of the art and most of its '
        'pleasure.',
  ], [
    'Je passai assez près pour les entendre respirer, et pas un ne tourna la '
        'tête.',
    'Une ombre, une brèche, un souffle retenu, et la route passait derrière '
        "eux plutôt qu'à travers eux.",
    "Personne ne vit rien, ce qui est tout l'art de la chose et l'essentiel "
        'de son plaisir.',
  ]),
  'strength': _Lines([
    'It gave, eventually, with a sound like an opinion being changed.',
    'I put my back into it, and for once my back agreed.',
  ], [
    "Cela céda, finalement, avec le bruit d'une opinion qui change.",
    "J'y mis toute ma force, et pour une fois mon dos fut d'accord.",
  ]),
  'constitution': _Lines([
    'I breathed through it, and it passed, and I was still there at the end.',
    'It was the kind of thing a body is not meant to take. Mine took it '
        'anyway.',
  ], [
    "Je respirai à travers, et cela passa, et j'étais toujours là à la fin.",
    "C'était le genre de chose qu'un corps n'est pas fait pour encaisser. Le "
        "mien l'encaissa quand même.",
  ]),
  'intelligence': _Lines([
    'The pieces went together the way pieces do once you stop forcing them.',
    'It made sense, suddenly and completely, the way the worst things often '
        'do.',
  ], [
    "Les morceaux s'assemblèrent comme ils le font dès qu'on cesse de les "
        'forcer.',
    "Tout prit sens, soudain et entièrement, comme c'est souvent le cas des "
        'pires choses.',
  ]),
  'wisdom': _Lines([
    'I listened past what was said to what was meant, and what was meant was '
        'plain.',
    'Something in me said wait, and for once I did, and it was right.',
  ], [
    "J'écoutai au-delà de ce qui était dit, jusqu'à ce qui était voulu, et ce "
        'qui était voulu était clair.',
    "Quelque chose en moi dit d'attendre, et pour une fois j'attendis, et ce "
        'quelque chose avait raison.',
  ]),
  'charisma': _Lines([
    'I said the right thing in the right voice, and watched it land.',
    'They wanted to be persuaded. I only had to give them a reason.',
  ], [
    'Je dis la bonne chose, du bon ton, et la regardai porter.',
    "Ils voulaient être convaincus. Je n'eus qu'à leur donner une raison.",
  ]),
};

const _failed = <String, _Lines>{
  'perception': _Lines([
    'I looked, and looked again, and the ground kept whatever it had been '
        'keeping.',
    'Whatever was hidden there had been hidden by someone better at it than I '
        'was at finding.',
    'An hour on my knees bought me dirt under the nails and nothing else.',
  ], [
    'Je cherchai, puis cherchai encore, et la terre garda ce qu’elle gardait.',
    "Ce qui était caché là l'avait été par quelqu'un de plus doué pour cacher "
        'que moi pour trouver.',
    'Une heure à genoux ne me valut que de la terre sous les ongles.',
  ]),
  'luck': _Lines([
    'Whatever luck I had that day was spoken for elsewhere.',
    'Every stone I turned had been turned before me, by someone luckier.',
    'I came away with a bruised thumb and a lesson I have been refusing to '
        'learn for years.',
  ], [
    'Ce jour-là, ma chance avait à faire ailleurs.',
    "Chaque pierre que je retournai l'avait déjà été, par quelqu'un de plus "
        'chanceux.',
    "Je repartis avec un pouce meurtri et une leçon que je refuse d'apprendre "
        'depuis des années.',
  ]),
  'dexterity': _Lines([
    'My foot found the one loose board on the whole of the coast.',
    'My hands were quick. Not quick enough, which is the only measure that '
        'counts.',
  ], [
    'Mon pied trouva la seule planche branlante de toute la côte.',
    "Mes mains furent rapides. Pas assez, et c'est la seule mesure qui "
        'compte.',
  ]),
  'strength': _Lines([
    'It did not move. I moved, eventually, away from it, with my pride.',
    'My shoulders lost the argument, and will be reminding me of it for days.',
  ], [
    "Cela ne bougea pas. C'est moi qui bougeai, au bout du compte, avec ma "
        'fierté sous le bras.',
    'Mes épaules perdirent la dispute, et me le rappelleront pendant des '
        'jours.',
  ]),
  'constitution': _Lines([
    'My body made its position very clear, and I had to respect it.',
    'I lasted longer than I expected and less long than I needed.',
  ], [
    'Mon corps fit connaître sa position très clairement, et je dus la '
        'respecter.',
    'Je tins plus longtemps que prévu, et moins longtemps que nécessaire.',
  ]),
  'intelligence': _Lines([
    'I turned it over until it stopped meaning anything, which did not take '
        'long.',
    'The answer was there. I could feel it being there. It did not care.',
  ], [
    "Je le retournai dans ma tête jusqu'à ce qu'il ne veuille plus rien dire, "
        'ce qui ne prit pas longtemps.',
    'La réponse était là. Je la sentais là. Elle s’en moquait.',
  ]),
  'wisdom': _Lines([
    'I read it wrong, confidently, which is the worst way to read anything.',
    'The signs were all there. I was looking at something else.',
  ], [
    'Je le lus de travers, avec assurance, ce qui est la pire manière de lire '
        'quoi que ce soit.',
    'Les signes étaient tous là. Je regardais ailleurs.',
  ]),
  'charisma': _Lines([
    'My words went out and came back unopened.',
    'I talked, and they listened, and neither of us enjoyed it.',
  ], [
    'Mes mots partirent et revinrent sans avoir été ouverts.',
    'Je parlai, ils écoutèrent, et personne n’y prit plaisir.',
  ]),
};

/// The sentence for a check of [ability] that [success]ed or not, picked
/// by [seed]; null for an ability with no lines.
String? checkOutcomeLineFor(
  String ability, {
  required bool success,
  required bool french,
  required int seed,
}) {
  final lines = (success ? _passed : _failed)[ability];
  if (lines == null) return null;
  final list = french ? lines.fr : lines.en;
  return list[seed.abs() % list.length];
}

/// Whether a check needs its outcome told in words: one on a detour or an
/// expedition (their scenes go on either way), or a story check whose
/// failure has no scene of its own. A sneak that fails starts its fight,
/// and the fight's aftermath tells that.
bool checkOutcomeNeedsTelling({
  required bool success,
  required bool onTheRoad,
  required bool hasFailScene,
  required bool isSneak,
}) {
  if (!success && isSneak) return false;
  if (onTheRoad) return true;
  return !success && !hasFailScene;
}

/// Every ability's lines, for tests.
List<({String ability, bool success, List<String> en, List<String> fr})>
    get checkOutcomeLinesForTest => [
          for (final entry in _passed.entries)
            (
              ability: entry.key,
              success: true,
              en: entry.value.en,
              fr: entry.value.fr
            ),
          for (final entry in _failed.entries)
            (
              ability: entry.key,
              success: false,
              en: entry.value.en,
              fr: entry.value.fr
            ),
        ];
