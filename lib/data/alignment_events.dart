import 'dart:math';

import '../models/story_node.dart';

/// The alignment layer of the excursion system: a Good character is
/// stalked by demons, an Evil one by angels, and a Neutral one is courted
/// by both -- small temptation scenes that nudge the score one way or the
/// other, two of which open a proper quest ("hunt the other side's
/// creature") that in turn lets the hunted side come looking. All rolled
/// on the same story-transition hook as an ordinary excursion (see
/// [maybeAlignmentEvent]) and drawn from enemies.json's own
/// `hunterAlignment`/`hunterTier` fields, so a new hunter is a data row,
/// not code.
const double hunterBaseChance = 0.10;
const double hunterChancePerAlignmentPoint = 0.002;
const double hunterChanceCap = 0.22;
const double temptationChance = 0.10;

/// Alignment magnitude at which the label stops being Neutral (mirrors
/// PlayerSession.alignmentLabel's thresholds).
const int alignmentThreshold = 20;

const String lightQuestId = 'q_temptation_light';
const String darkQuestId = 'q_temptation_dark';

/// The hunter side that is after this character right now, if any:
/// 'Good' hunters (demons) come for a Good character or one who took the
/// angel's charge; 'Evil' hunters (angels) come for an Evil character or
/// one who struck the demon's bargain. Null when nobody is hunting.
String? huntedSideFor({
  required int alignmentScore,
  required List<String> activeQuestIds,
}) {
  if (alignmentScore >= alignmentThreshold ||
      activeQuestIds.contains(lightQuestId)) {
    return 'Good';
  }
  if (alignmentScore <= -alignmentThreshold ||
      activeQuestIds.contains(darkQuestId)) {
    return 'Evil';
  }
  return null;
}

/// Odds a hunter ambushes this transition -- rises with how far the score
/// sits past the threshold, capped.
double hunterChanceFor(int alignmentScore) {
  final past = max(0, alignmentScore.abs() - alignmentThreshold);
  return min(
      hunterChanceCap, hunterBaseChance + past * hunterChancePerAlignmentPoint);
}

/// Every hunter enemy id in [enemies] that hunts [side] and fits
/// [chapter]: tier-1 hunters through chapter 2, either tier from chapter
/// 3 on.
List<String> hunterPoolFor({
  required Map<String, dynamic> enemies,
  required String side,
  required int chapter,
}) {
  final pool = <String>[];
  for (final entry in enemies.entries) {
    final enemy = entry.value as Map<String, dynamic>;
    if (enemy['hunterAlignment']?.toString() != side) continue;
    final tier = (enemy['hunterTier'] as num?)?.toInt() ?? 1;
    if (chapter <= 2 && tier > 1) continue;
    pool.add(entry.key);
  }
  return pool;
}

/// True for an enemy that only ever appears as an alignment hunter, so the
/// ordinary excursion/expedition pools leave it out.
bool isHunterEnemy(Map<String, dynamic>? enemy) =>
    (enemy?['hunterAlignment']?.toString() ?? '').isNotEmpty;

const List<String> _angelAmbushEn = [
  'The air goes white and still. A figure in burning armor descends the '
      'street as if it were a stair, and its eyes, when they find you, hold '
      'no mercy at all. "Your ledger is known to us," it says.',
  'Bells that no church is ringing. A shape of light steps out of the '
      'glare with a blade like a shard of noon, and speaks your name as a '
      'sentence already passed.',
];
const List<String> _angelAmbushFr = [
  "L'air devient blanc et immobile. Une silhouette en armure de flammes "
      "descend la rue comme un escalier, et ses yeux, lorsqu'ils vous "
      'trouvent, ne portent aucune pitié. « Votre registre nous est connu », '
      'dit-elle.',
  "Des cloches qu'aucune église ne fait sonner. Une forme de lumière sort "
      "de l'éblouissement, une lame comme un éclat de midi à la main, et "
      'prononce votre nom comme une sentence déjà rendue.',
];
const List<String> _demonAmbushEn = [
  'The shadows at the edge of the road peel up like burnt paper. Something '
      'with too many joints unfolds from them, grinning. "The good ones," it '
      'purrs, "always taste of regret."',
  'A smell of hot iron, then laughter from nowhere. The thing that steps '
      'out wears a face it clearly stole, and it has been waiting for you '
      'specifically.',
];
const List<String> _demonAmbushFr = [
  'Les ombres au bord de la route se décollent comme du papier brûlé. '
      "Quelque chose aux articulations trop nombreuses s'en déplie, "
      'souriant. « Les justes, ronronne-t-il, ont toujours un goût de '
      'regret. »',
  'Une odeur de fer chaud, puis un rire venu de nulle part. La chose qui '
      "s'avance porte un visage manifestement volé, et c'est vous, "
      "précisément, qu'elle attendait.",
];

/// A one-node ambush chain for a hunter of [side] ('Good' hunters are
/// demons; 'Evil' hunters are angels), or null if [enemies] holds no such
/// hunter for [chapter].
StoryNode? buildHunterAmbushNode({
  required Map<String, dynamic> enemies,
  required String side,
  required int chapter,
  required Random random,
}) {
  final pool = hunterPoolFor(enemies: enemies, side: side, chapter: chapter);
  if (pool.isEmpty) return null;
  final enemyId = pool[random.nextInt(pool.length)];
  final isAngel = side == 'Evil';
  final en = isAngel ? _angelAmbushEn : _demonAmbushEn;
  final fr = isAngel ? _angelAmbushFr : _demonAmbushFr;
  final idx = random.nextInt(en.length);
  return StoryNode(
    id: 'hunter_${enemyId}_${random.nextInt(1 << 30)}',
    description: en[idx],
    descriptionFr: fr[idx],
    choices: [
      StoryChoice(
        text: 'Stand and fight',
        textFr: 'Faire face',
        nextId: '',
        triggerEnemyId: enemyId,
        isHunterAmbush: true,
      ),
    ],
  );
}

class _Temptation {
  const _Temptation({
    required this.en,
    required this.fr,
    required this.acceptEn,
    required this.acceptFr,
    required this.refuseEn,
    required this.refuseFr,
    this.acceptAlignment = 0,
    this.acceptGold = 0,
    this.refuseAlignment = 0,
    this.refuseGold = 0,
    this.acceptQuestId,
    this.isAngelic = true,
  });

  final String en;
  final String fr;
  final String acceptEn;
  final String acceptFr;
  final String refuseEn;
  final String refuseFr;
  final int acceptAlignment;
  final int acceptGold;
  final int refuseAlignment;
  final int refuseGold;
  final String? acceptQuestId;
  final bool isAngelic;
}

const List<_Temptation> _temptations = [
  _Temptation(
    en: 'A woman in white kneels beside a beggar whose hands have been '
        'broken for stealing. When she looks up at you her eyes are far too '
        'bright to be a woman\'s. "Give what you can," she says. "It will '
        'be remembered."',
    fr: 'Une femme en blanc est agenouillée près d\'un mendiant dont on a '
        'brisé les mains pour vol. Lorsqu\'elle lève les yeux vers vous, ils '
        'sont bien trop lumineux pour être ceux d\'une femme. « Donnez ce '
        'que vous pouvez, dit-elle. On s\'en souviendra. »',
    acceptEn: 'Give him 25 gold',
    acceptFr: 'Lui donner 25 or',
    refuseEn: 'Walk on',
    refuseFr: 'Passer son chemin',
    acceptAlignment: 8,
    acceptGold: -25,
    refuseAlignment: -2,
  ),
  _Temptation(
    en: 'A child\'s satchel lies in the mud, split open, coins scattered '
        'across the cobbles. Somewhere behind you a very soft voice '
        'observes that nobody is watching. Somewhere ahead, a fainter one '
        'says the child will come back for it.',
    fr: 'La besace d\'un enfant gît dans la boue, éventrée, des pièces '
        'éparpillées sur les pavés. Derrière vous, une voix très douce fait '
        'remarquer que personne ne regarde. Devant, une voix plus ténue dit '
        'que l\'enfant reviendra la chercher.',
    acceptEn: 'Gather the coins back into the satchel and leave it',
    acceptFr: 'Remettre les pièces dans la besace et la laisser',
    refuseEn: 'Pocket the coins (+30 gold)',
    refuseFr: 'Empocher les pièces (+30 or)',
    acceptAlignment: 8,
    refuseAlignment: -6,
    refuseGold: 30,
  ),
  _Temptation(
    en: 'A drunk snores against a wall, his purse hanging open on his belt. '
        'The shadow beside him is longer than the lamplight allows, and it '
        'chuckles. "He\'d only drink it," it says, reasonably.',
    fr: 'Un ivrogne ronfle contre un mur, sa bourse béante à la ceinture. '
        'L\'ombre à côté de lui est plus longue que la lanterne ne le '
        'permet, et elle ricane. « Il ne ferait que le boire », dit-elle, '
        'raisonnablement.',
    acceptEn: 'Take the purse (+45 gold)',
    acceptFr: 'Prendre la bourse (+45 or)',
    refuseEn: 'Leave him be',
    refuseFr: 'Le laisser tranquille',
    acceptAlignment: -8,
    acceptGold: 45,
    refuseAlignment: 3,
    isAngelic: false,
  ),
  _Temptation(
    en: 'A merchant\'s ledger sits open on an unattended counter, and a '
        'voice like warm smoke points out how easily one figure could '
        'become another. "Nobody checks these," it says. "Nobody ever '
        'checks."',
    fr: 'Le registre d\'un marchand est resté ouvert sur un comptoir '
        'désert, et une voix comme une fumée tiède fait remarquer combien '
        'un chiffre pourrait aisément en devenir un autre. « Personne ne '
        'vérifie ces choses-là, dit-elle. Personne, jamais. »',
    acceptEn: 'Alter the sum in your favor (+60 gold)',
    acceptFr: 'Modifier la somme à votre avantage (+60 or)',
    refuseEn: 'Close the ledger',
    refuseFr: 'Refermer le registre',
    acceptAlignment: -10,
    acceptGold: 60,
    refuseAlignment: 3,
    isAngelic: false,
  ),
  _Temptation(
    en: 'A figure in plain grey with a soldier\'s bearing falls into step '
        'beside you. "A creature of the pit walks these streets wearing a '
        'stolen face," it says. "Hunt it down, and you will be counted '
        'among the just." It does not wait for an answer before it is '
        'gone.',
    fr: 'Une silhouette en gris, au port de soldat, se met à marcher à '
        'votre hauteur. « Une créature de la fosse arpente ces rues sous un '
        'visage volé, dit-elle. Traquez-la, et vous serez compté parmi les '
        'justes. » Elle n\'attend pas de réponse avant de disparaître.',
    acceptEn: 'Take up the charge',
    acceptFr: 'Accepter la mission',
    refuseEn: 'Let it pass',
    refuseFr: 'Ne pas relever',
    acceptQuestId: lightQuestId,
  ),
  _Temptation(
    en: 'Something sits on a wall above you with its legs crossed, idly '
        'juggling three coins that catch no light. "Their sentinel sniffs '
        'at your heels," it says. "Put it down for me, and I will pay in '
        'gold and in secrets. I am very generous with both."',
    fr: 'Quelque chose est assis sur un mur au-dessus de vous, jambes '
        'croisées, jonglant distraitement avec trois pièces qui ne '
        'reflètent aucune lumière. « Leur sentinelle renifle vos talons, '
        'dit-il. Abattez-la pour moi, et je paierai en or et en secrets. Je '
        'suis très généreux des deux. »',
    acceptEn: 'Strike the bargain',
    acceptFr: 'Conclure le marché',
    refuseEn: 'Refuse',
    refuseFr: 'Refuser',
    refuseAlignment: 2,
    acceptQuestId: darkQuestId,
    isAngelic: false,
  ),
];

/// A one-node temptation scene for a Neutral character, or null when
/// every temptation is spent (both quests already taken or done, and the
/// plain scenes are always eligible, so in practice only the quest offers
/// ever drop out).
StoryNode? buildTemptationNode({
  required List<String> activeQuestIds,
  required List<String> completedQuestIds,
  required Random random,
}) {
  final pool = _temptations.where((t) {
    final questId = t.acceptQuestId;
    if (questId == null) return true;
    return !activeQuestIds.contains(questId) &&
        !completedQuestIds.contains(questId);
  }).toList();
  if (pool.isEmpty) return null;
  final t = pool[random.nextInt(pool.length)];
  return StoryNode(
    id: 'temptation_${random.nextInt(1 << 30)}',
    description: t.en,
    descriptionFr: t.fr,
    choices: [
      StoryChoice(
        text: t.acceptEn,
        textFr: t.acceptFr,
        nextId: '',
        alignmentMod: t.acceptAlignment,
        goldMod: t.acceptGold,
        questIDToProgress: t.acceptQuestId,
      ),
      StoryChoice(
        text: t.refuseEn,
        textFr: t.refuseFr,
        nextId: '',
        alignmentMod: t.refuseAlignment,
        goldMod: t.refuseGold,
      ),
    ],
  );
}

/// Rolls this transition's alignment event, if any: a hunter ambush for a
/// hunted character, a temptation for a Neutral one. Returns a one-node
/// chain to play as an excursion, or null (the common case). [enabled] is
/// the player's settings toggle.
List<StoryNode>? maybeAlignmentEvent({
  required int alignmentScore,
  required List<String> activeQuestIds,
  required List<String> completedQuestIds,
  required Map<String, dynamic> enemies,
  required int chapter,
  required Random random,
  bool enabled = true,
}) {
  if (!enabled) return null;
  final side = huntedSideFor(
      alignmentScore: alignmentScore, activeQuestIds: activeQuestIds);
  if (side != null) {
    if (random.nextDouble() >= hunterChanceFor(alignmentScore)) return null;
    final node = buildHunterAmbushNode(
        enemies: enemies, side: side, chapter: chapter, random: random);
    return node == null ? null : [node];
  }
  if (random.nextDouble() >= temptationChance) return null;
  final node = buildTemptationNode(
    activeQuestIds: activeQuestIds,
    completedQuestIds: completedQuestIds,
    random: random,
  );
  return node == null ? null : [node];
}
