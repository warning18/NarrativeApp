import 'approval.dart';

/// Companion remarks (v1.167): a companion in the party says something
/// about what the player just did, in their own voice, and the next scene
/// opens with it.
///
/// Two kinds of deed get a remark:
///
/// - One the party has an opinion on (see approval.dart): a kind or cruel
///   choice, one that fills the purse, or a scene's own reaction. The
///   companion who took it hardest speaks, every time.
/// - One that only shows what the player can do: an ability check passed
///   or failed, a fight slipped past. Someone speaks at most once every
///   [remarkCooldownChoices] choices, so the party doesn't narrate every
///   step.
///
/// Companions take turns (the one who spoke least recently goes first)
/// and go through their lines before repeating one.
enum RemarkKind {
  kindApproved,
  kindDisapproved,
  cruelApproved,
  cruelDisapproved,
  profitApproved,
  profitDisapproved,

  /// A scene's own reaction (`approvalMods`), neither kind, cruel nor
  /// profitable.
  approved,
  disapproved,
  checkPassed,
  checkFailed,

  /// A check that took the party round a fight (`avoidFightOnSuccess`).
  sneakedPast,
}

/// A remark about a check or a sneak waits this many choices after the
/// last remark. Remarks about a deed the party cares about never wait.
const int remarkCooldownChoices = 3;

/// What the player did, as the party weighs it: the same numbers
/// applyChoiceEffects and reactToDeed react to.
class RemarkDeed {
  const RemarkDeed({
    this.alignmentMod = 0,
    this.goldMod = 0,
    this.approvalMods = const {},
  });

  final int alignmentMod;

  /// Gold that counts as profit (loot picked up on the road doesn't).
  final int goldMod;
  final Map<String, int> approvalMods;
}

/// One companion's remark: who, about what, and which of their lines.
/// The words are looked up when shown ([lineFor]), so the remark follows
/// a change of language.
class CompanionRemark {
  const CompanionRemark({
    required this.companionId,
    required this.kind,
    required this.index,
  });

  final String companionId;
  final RemarkKind kind;
  final int index;

  String lineFor({required bool french}) {
    final lines = remarkLinesFor(companionId, kind, french: french);
    return lines.isEmpty ? '' : lines[index % lines.length];
  }

  @override
  bool operator ==(Object other) =>
      other is CompanionRemark &&
      other.companionId == companionId &&
      other.kind == kind &&
      other.index == index;

  @override
  int get hashCode => Object.hash(companionId, kind, index);
}

/// Who spoke when, and which lines have been used: kept for the session,
/// so companions take turns and lines don't repeat back to back.
class RemarkMemory {
  const RemarkMemory({
    this.seed = 0,
    this.choices = 0,
    this.lastRemarkAt,
    this.lastSpokeAt = const {},
    this.used = const {},
  });

  /// Where each companion starts in their lines, so two runs don't open
  /// on the same ones.
  final int seed;

  /// Choices made so far.
  final int choices;

  /// The choice the last remark was made on; null before the first.
  final int? lastRemarkAt;
  final Map<String, int> lastSpokeAt;

  /// Lines used, by `companionId/kind`.
  final Map<String, int> used;
}

/// The remark for the choice the player just made, if any, and the
/// memory after it. [reactions] are the party's reactions to [deed] (what
/// applyChoiceEffects or reactToDeed returned); [companions] is the raw
/// companions table, for their weights. [action] is what the choice showed
/// of the player besides: a check passed or failed, a fight slipped past.
/// [activeAllyIds] is the party once the choice is done: whoever walked
/// out says their piece in the approval notice instead.
({CompanionRemark? remark, RemarkMemory memory}) pickRemark({
  required RemarkMemory memory,
  required List<String> activeAllyIds,
  List<ApprovalChange> reactions = const [],
  RemarkDeed deed = const RemarkDeed(),
  Map<String, dynamic> companions = const {},
  RemarkKind? action,
}) {
  final choice = memory.choices + 1;
  final counted = RemarkMemory(
    seed: memory.seed,
    choices: choice,
    lastRemarkAt: memory.lastRemarkAt,
    lastSpokeAt: memory.lastSpokeAt,
    used: memory.used,
  );
  int lastSpoke(String id) => memory.lastSpokeAt[id] ?? -1;
  int partyPlace(String id) => activeAllyIds.indexOf(id);

  // A deed the party cares about: whoever took it hardest. One who just
  // came to trust the player completely, started losing patience or
  // walked out says so in the approval notice, in words of their own.
  final moved = [
    for (final reaction in reactions)
      if (!reaction.hasOwnWords && activeAllyIds.contains(reaction.companionId))
        (
          reaction: reaction,
          kind: remarkKindFor(
            reaction,
            companions[reaction.companionId] as Map<String, dynamic>?,
            deed,
          ),
        ),
  ]..removeWhere((m) => remarkLinesFor(m.reaction.companionId, m.kind).isEmpty);
  if (moved.isNotEmpty) {
    moved.sort((a, b) {
      final byWeight = b.reaction.delta.abs().compareTo(a.reaction.delta.abs());
      if (byWeight != 0) return byWeight;
      final byTurn = lastSpoke(a.reaction.companionId)
          .compareTo(lastSpoke(b.reaction.companionId));
      if (byTurn != 0) return byTurn;
      return partyPlace(a.reaction.companionId)
          .compareTo(partyPlace(b.reaction.companionId));
    });
    final speaker = moved.first;
    return _spoken(counted, speaker.reaction.companionId, speaker.kind);
  }

  // A check or a sneak: someone speaks up, now and then.
  final last = memory.lastRemarkAt;
  if (action == null ||
      (last != null && choice - last < remarkCooldownChoices)) {
    return (remark: null, memory: counted);
  }
  final speakers = [
    for (final id in activeAllyIds)
      if (remarkLinesFor(id, action).isNotEmpty) id,
  ]..sort((a, b) {
      final byTurn = lastSpoke(a).compareTo(lastSpoke(b));
      return byTurn != 0 ? byTurn : partyPlace(a).compareTo(partyPlace(b));
    });
  if (speakers.isEmpty) return (remark: null, memory: counted);
  return _spoken(counted, speakers.first, action);
}

({CompanionRemark? remark, RemarkMemory memory}) _spoken(
    RemarkMemory memory, String companionId, RemarkKind kind) {
  final key = '$companionId/${kind.name}';
  final count = memory.used[key] ?? 0;
  final lines = remarkLinesFor(companionId, kind);
  final start = (memory.seed + _stableHash(key)) % lines.length;
  return (
    remark: CompanionRemark(
      companionId: companionId,
      kind: kind,
      index: (start + count) % lines.length,
    ),
    memory: RemarkMemory(
      seed: memory.seed,
      choices: memory.choices,
      lastRemarkAt: memory.choices,
      lastSpokeAt: {...memory.lastSpokeAt, companionId: memory.choices},
      used: {...memory.used, key: count + 1},
    ),
  );
}

/// The same number for the same text on every platform and every run
/// (String.hashCode promises neither).
int _stableHash(String text) {
  var hash = 17;
  for (final unit in text.codeUnits) {
    hash = (hash * 31 + unit) & 0x3fffffff;
  }
  return hash;
}

/// What [reaction] was about, for [companion] (a companions.json record):
/// the part of [deed] that moved them most in the direction they moved
/// -- the kindness or cruelty of it, the gold, or the scene's own
/// reaction.
RemarkKind remarkKindFor(
  ApprovalChange reaction,
  Map<String, dynamic>? companion,
  RemarkDeed deed,
) {
  final alignment =
      approvalDeltaFor(companion, alignmentMod: deed.alignmentMod);
  final profit = approvalDeltaFor(companion, goldMod: deed.goldMod);
  final explicit = explicitApprovalFor(deed.approvalMods, reaction.companionId);
  final up = reaction.delta > 0;
  final parts = [
    (weight: alignment, kind: _alignmentKind(deed.alignmentMod, alignment)),
    (
      weight: profit,
      kind:
          profit > 0 ? RemarkKind.profitApproved : RemarkKind.profitDisapproved
    ),
    (
      weight: explicit,
      kind: explicit > 0 ? RemarkKind.approved : RemarkKind.disapproved
    ),
  ].where((part) => part.weight != 0 && (part.weight > 0) == up).toList();
  if (parts.isEmpty) {
    return up ? RemarkKind.approved : RemarkKind.disapproved;
  }
  // The heaviest part; the first listed on a tie.
  var heaviest = parts.first;
  for (final part in parts.skip(1)) {
    if (part.weight.abs() > heaviest.weight.abs()) heaviest = part;
  }
  return heaviest.kind;
}

RemarkKind _alignmentKind(int alignmentMod, int weight) {
  if (alignmentMod > 0) {
    return weight > 0 ? RemarkKind.kindApproved : RemarkKind.kindDisapproved;
  }
  return weight > 0 ? RemarkKind.cruelApproved : RemarkKind.cruelDisapproved;
}

/// [companionId]'s lines for [kind]; empty when they have none (their
/// weights never lead there, or they're not a companion with a voice
/// written here).
List<String> remarkLinesFor(String companionId, RemarkKind kind,
        {bool french = false}) =>
    (french ? _remarksFr : _remarksEn)[companionId]?[kind] ??
    (french ? _remarksEn : _remarksFr)[companionId]?[kind] ??
    const [];

/// Every companion with lines, for tests.
Iterable<String> get companionsWithRemarks => _remarksEn.keys;

// The lines. French addresses the player as « vous », with nothing that
// agrees with the player's gender.

const _remarksEn = <String, Map<RemarkKind, List<String>>>{
  'kelda': {
    RemarkKind.kindApproved: [
      "That's the job. Not the pay. The job.",
      'You stood between them and harm. I know what that costs. Well done.',
      "My old sergeant would have bought you a drink for that. He'd have "
          "hated it, but he'd have bought it.",
    ],
    RemarkKind.cruelDisapproved: [
      "We held gates so people wouldn't do things like that.",
      "Hm. I'll remember that. Not fondly.",
      "There was no need for it. There's never a need for it.",
    ],
    RemarkKind.approved: [
      "Good call. I'd have made it slower.",
      "That'll do. That'll do nicely.",
    ],
    RemarkKind.disapproved: [
      "Not what I'd have done. Not my call, either.",
      "I've seen that choice made before. It didn't end well then.",
    ],
    RemarkKind.checkPassed: [
      "Clean work. I'd have used a shoulder, but clean.",
      'See? Steady hands, steady feet. Nothing to it.',
      "Hah. Didn't even need me.",
    ],
    RemarkKind.checkFailed: [
      'Up you get. Everyone misses a step.',
      "Shake it off. The wall doesn't care, and neither should you.",
      "Next time let me go first. I'm shorter; I fall less far.",
    ],
    RemarkKind.sneakedPast: [
      'Walking round a fight. Not my style, but nobody bled.',
      'Quietly done. My shield thanks you.',
    ],
  },
  'sable': {
    RemarkKind.kindDisapproved: [
      'Generous. Expensive, but generous.',
      "Charity doesn't pay out, love. I've checked the odds.",
      'Lovely gesture. Remind me never to let you hold the purse.',
    ],
    RemarkKind.cruelApproved: [
      "Cold. I didn't know you had it in you.",
      "Hard hands win hard games. Not that I'm keeping score.",
      "Nobody's going to write a song about that. Good. Songs are evidence.",
    ],
    RemarkKind.profitApproved: [
      "Now that's a hand worth playing.",
      'Coin in the pocket. The only argument that never loses.',
      "Let me count it. You've got an honest face, and honest faces "
          'miscount.',
    ],
    RemarkKind.approved: [
      'Nicely played.',
      "I'd have bet on that. I'd have won, too.",
    ],
    RemarkKind.disapproved: [
      "Bad bet. I'm just saying.",
      "I'd have folded. But it's your table.",
    ],
    RemarkKind.checkPassed: [
      "Beginner's luck. Keep it up and I'll start calling it skill.",
      'Smooth. Almost as smooth as me.',
      "The dice like you today. Don't tell them I said so.",
    ],
    RemarkKind.checkFailed: [
      'Ooh. The house takes that one.',
      'Everyone busts sometimes, love. Some of us just do it quieter.',
      "I'd have tried that too. Then pretended I hadn't.",
    ],
    RemarkKind.sneakedPast: [
      "Now you're thinking like me. The best fight is the one they never "
          'knew about.',
      'Quiet feet. I could make something of you yet.',
    ],
  },
  'maren': {
    RemarkKind.kindApproved: [
      "You didn't have to. That is why it mattered.",
      'The Light keeps its own accounts. Today it wrote your name kindly.',
      'I have seen a great deal of cruelty done in the Light\'s name. It is '
          'good to see the other thing.',
    ],
    RemarkKind.cruelDisapproved: [
      'I will pray for them. And, if you will let me, for you.',
      'I stood beside people who did that, once. I told myself it was '
          'necessary. It never was.',
      'Please. Not like that. Not again.',
    ],
    RemarkKind.approved: [
      'Well chosen. The Light will not need to forgive that one.',
      'Thank you. I mean it.',
    ],
    RemarkKind.disapproved: [
      'I cannot bless that. I am sorry.',
      'I will carry it with the rest. My load is already heavy.',
    ],
    RemarkKind.checkPassed: [
      'Someone is still watching over us both.',
      'Steady. The Light likes a steady hand.',
      'Well done. I held my breath the whole time.',
    ],
    RemarkKind.checkFailed: [
      'Nothing broken? Then it was only pride, and pride mends.',
      'Failing is a kind of prayer. It reminds us we need one.',
      "Let me look at that. No, don't argue.",
    ],
    RemarkKind.sneakedPast: [
      'No one died. I will take that, every time.',
      'Mercy is sometimes only a quiet step. That one was well placed.',
    ],
  },
  'liora': {
    RemarkKind.kindApproved: [
      "Good. One less person I'll watch fall from up there.",
      "I count the ones we save, too. That's another.",
      "That's why I came down off the roofs.",
    ],
    RemarkKind.cruelDisapproved: [
      'I saw that. I see everything. Remember it.',
      "That's the kind of thing I used to shoot at.",
      "Don't. Don't make me count those too.",
    ],
    RemarkKind.approved: [
      'Clean choice.',
      "I'd have done the same. Slower, from higher up.",
    ],
    RemarkKind.disapproved: [
      'Hm. Wrong angle.',
      "I'd have called that differently.",
    ],
    RemarkKind.checkPassed: [
      "Good line. I'd have taken the same one.",
      'Nicely judged.',
      'Three steps, none wasted. I counted.',
    ],
    RemarkKind.checkFailed: [
      'Wind shifted. It happens.',
      'Too quick. Breathe out before, not after.',
      'I had you covered. Try again when you are ready.',
    ],
    RemarkKind.sneakedPast: [
      'Nobody looked up. Nobody ever looks up.',
      'Quiet. Good. I had an arrow ready anyway.',
    ],
  },
  'vess': {
    RemarkKind.kindApproved: [
      "The Void went quiet just then. It doesn't like that sort of thing.",
      "Nobody did that for me when I came out of the dark. I'm glad someone "
          'does it.',
      "That was a human thing to do. I'm still learning those.",
    ],
    RemarkKind.cruelDisapproved: [
      'It liked that. The thing in the dark. I felt it smile.',
      "You don't need the Void to be cruel. That's what frightens me.",
      "Please don't do that again where I can hear it.",
    ],
    RemarkKind.approved: [
      'Good. The whispers had nothing to say about that.',
      "I think that was right. I'm not always sure what right is.",
    ],
    RemarkKind.disapproved: [
      "The whispers laughed. I didn't.",
      "I don't like that. I don't know why yet.",
    ],
    RemarkKind.checkPassed: [
      "The Void said you'd fall. It lies.",
      'Elegant. For someone with no void in them.',
      "I didn't help. I want that noted.",
    ],
    RemarkKind.checkFailed: [
      "The dark wanted that to happen. Don't give it more.",
      "I could have caught you. I wasn't sure you'd want me to.",
      "Failing isn't the worst thing. I've done worse than fail.",
    ],
    RemarkKind.sneakedPast: [
      "Shadows are easier when you're not afraid of them.",
      "Not a sound. Like the dark. I'd know.",
    ],
  },
  'grosh': {
    RemarkKind.kindDisapproved: [
      'Grosh does not understand. Grosh does not have to.',
      'Nice. Nice does not pay. Grosh is just saying.',
      'Saints get buried poor. Grosh has seen it.',
    ],
    RemarkKind.cruelApproved: [
      'Ha! Hard. Grosh likes hard.',
      'No sermon. Just done. Good.',
      'They will remember that. Fear is cheaper than guards.',
    ],
    RemarkKind.profitApproved: [
      'COIN! Grosh hears coin!',
      'Now we eat well tonight.',
      'Good. Heavy purse, light heart.',
    ],
    RemarkKind.approved: [
      'Grosh approves. Grosh says so.',
      'Good. Simple. Grosh likes simple.',
    ],
    RemarkKind.disapproved: [
      'Hmph. Grosh thinks that was stupid. Quietly.',
      'Grosh will not say it. Grosh is thinking it very loud.',
    ],
    RemarkKind.checkPassed: [
      'Ha! Strong! Almost Grosh-strong!',
      'Grosh would have broken it. This is also fine.',
      'Good! Now Grosh does not have to carry you.',
    ],
    RemarkKind.checkFailed: [
      'Ha! Grosh saw that. Grosh will tell everyone.',
      'Next time, hit it harder.',
      'Grosh falls too, sometimes. Mostly on enemies.',
    ],
    RemarkKind.sneakedPast: [
      'Grosh wanted to smash. Grosh will smash later.',
      'Sneaking. Hmph. Faster than fighting, Grosh admits.',
    ],
  },
  'tobin': {
    RemarkKind.kindApproved: [
      "There. That's a candle lit. The dark is a little smaller for it.",
      'The choir sang about that sort of thing. You just did it.',
      "I'll hum something for them tonight. And for you.",
    ],
    RemarkKind.cruelDisapproved: [
      "I've buried what deeds like that leave behind.",
      'The Ashen Quarter started with one choice like that.',
      "I'll not sing tonight.",
    ],
    RemarkKind.profitDisapproved: [
      "Coin is heavy. Mind it doesn't pull you under.",
      "Every purse on this coast was somebody's once.",
      'The choir took coin too. It never sang any better for it.',
    ],
    RemarkKind.approved: [
      "Well done. I'll put that in my prayers, on the grateful side.",
      "That was right. I don't say it lightly.",
    ],
    RemarkKind.disapproved: [
      "I'll not argue. I'll only say I'd have done otherwise.",
      'Hm. The hymn for that one is in a minor key.',
    ],
    RemarkKind.checkPassed: [
      'Steady as a cloister wall. Good.',
      'Well done. My knees thank you for not making me try.',
      "The Light doesn't miss. Neither, today, did you.",
    ],
    RemarkKind.checkFailed: [
      "No harm that won't mend. Come, let me see.",
      'The brothers dropped the censer at every feast. The feast went on.',
      "Not your hour for it. There'll be another.",
    ],
    RemarkKind.sneakedPast: [
      "Nobody hurt. That's a hymn I know by heart.",
      'Good. Let them live to change their minds.',
    ],
  },
  'malrik': {
    RemarkKind.kindDisapproved: [
      'Mercy. Charming. Unbillable.',
      'Nothing personal, but that was a loss on the books.',
      "The Court would have laughed. I'm trying not to.",
    ],
    RemarkKind.cruelApproved: [
      "Nothing personal. That's how it's done.",
      'Efficient. The Court would have offered you a seat.',
      "You're learning. I'll send you my rates for the lessons.",
    ],
    RemarkKind.profitApproved: [
      "Now that's a return on investment.",
      'Profit. My favourite kind of ending.',
      "I'll keep the ledger. You keep doing that.",
    ],
    RemarkKind.approved: [
      "Sound decision. I'd have charged for it.",
      "Good. I'm revising my estimate of you upward.",
    ],
    RemarkKind.disapproved: [
      'Nothing personal. But no.',
      "That will cost us. I've already done the sum.",
    ],
    RemarkKind.checkPassed: [
      "Competent work. Almost disappointing; I'd wagered against you.",
      "Well done. I'll pretend I never doubted it.",
      "See? Risk, managed. There's some Court in you yet.",
    ],
    RemarkKind.checkFailed: [
      "Ah. I'll file that under losses.",
      'Nothing personal, but that was painful to watch.',
      "Everyone fails. The clever ones fail where no one's looking.",
    ],
    RemarkKind.sneakedPast: [
      'No fight, no cost, no witnesses. Perfect.',
      'Stealth. The cheapest kind of victory.',
    ],
  },
};

const _remarksFr = <String, Map<RemarkKind, List<String>>>{
  'kelda': {
    RemarkKind.kindApproved: [
      "C'est ça, le métier. Pas la paie : le métier.",
      'Vous avez fait rempart entre eux et le danger. Je sais ce que ça '
          'coûte. Bien joué.',
      'Mon vieux sergent vous aurait payé à boire pour ça. Il aurait '
          'détesté ça, mais il aurait payé.',
    ],
    RemarkKind.cruelDisapproved: [
      'On tenait des portes pour que personne ne fasse ce genre de chose.',
      'Hum. Je m\'en souviendrai. Pas avec tendresse.',
      "Rien ne l'exigeait. Rien ne l'exige jamais.",
    ],
    RemarkKind.approved: [
      "Bonne décision. Je l'aurais prise moins vite.",
      'Ça ira. Ça ira même très bien.',
    ],
    RemarkKind.disapproved: [
      "Ce n'est pas ce que j'aurais fait. Mais ce n'est pas moi qui décide.",
      "J'ai déjà vu faire ce choix. Ça n'avait pas bien fini.",
    ],
    RemarkKind.checkPassed: [
      "Du travail propre. J'aurais mis un coup d'épaule, mais c'est propre.",
      'Vous voyez ? Mains sûres, pieds sûrs. Rien de plus.',
      "Ha. Vous n'aviez même pas besoin de moi.",
    ],
    RemarkKind.checkFailed: [
      'Allez, on se relève. Tout le monde rate une marche.',
      'Oubliez ça. Le mur s\'en fiche, faites pareil.',
      'La prochaine fois, laissez-moi passer devant. Je suis plus petite, '
          'je tombe de moins haut.',
    ],
    RemarkKind.sneakedPast: [
      "Contourner un combat, ce n'est pas mon genre. Mais personne n'a "
          'saigné.',
      'Proprement fait. Mon bouclier vous remercie.',
    ],
  },
  'sable': {
    RemarkKind.kindDisapproved: [
      "C'est généreux. Coûteux, mais généreux.",
      "La charité ne rapporte rien, mon chou. J'ai vérifié les cotes.",
      'Joli geste. Rappelez-moi de ne jamais vous confier la bourse.',
    ],
    RemarkKind.cruelApproved: [
      'Froid. Je ne vous savais pas capable de ça.',
      'Les mains dures gagnent les parties dures. Non que je compte les '
          'points.',
      "Personne n'en fera une chanson. Tant mieux. Les chansons, ce sont "
          'des preuves.',
    ],
    RemarkKind.profitApproved: [
      'Voilà une main qui vaut la peine d\'être jouée.',
      "De l'argent en poche. Le seul argument qui ne perd jamais.",
      'Laissez-moi compter. Vous avez une tête honnête, et les têtes '
          'honnêtes comptent mal.',
    ],
    RemarkKind.approved: [
      'Joliment joué.',
      "J'aurais parié là-dessus. Et j'aurais gagné.",
    ],
    RemarkKind.disapproved: [
      'Mauvais pari. Je dis ça comme ça.',
      "Moi, je me serais couchée. Mais c'est votre table.",
    ],
    RemarkKind.checkPassed: [
      "La chance du débutant. Continuez et j'appellerai ça du talent.",
      'En douceur. Presque autant que moi.',
      "Les dés vous aiment, aujourd'hui. Ne leur dites pas que je l'ai dit.",
    ],
    RemarkKind.checkFailed: [
      "Aïe. Celle-là, c'est pour la maison.",
      'Tout le monde perd parfois, mon chou. Certains plus discrètement.',
      "J'aurais tenté ça aussi. Puis j'aurais fait comme si de rien n'était.",
    ],
    RemarkKind.sneakedPast: [
      "Là, vous pensez comme moi. Le meilleur combat, c'est celui dont ils "
          "n'ont jamais rien su.",
      'Des pas discrets. Je finirai peut-être par faire quelque chose de '
          'vous.',
    ],
  },
  'maren': {
    RemarkKind.kindApproved: [
      "Rien ne vous y obligeait. C'est pour cela que ça comptait.",
      "La Lumière tient ses propres comptes. Aujourd'hui, elle a écrit votre "
          'nom avec douceur.',
      "J'ai vu beaucoup de cruauté commise au nom de la Lumière. Cela fait "
          "du bien de voir l'inverse.",
    ],
    RemarkKind.cruelDisapproved: [
      'Je prierai pour eux. Et, si vous le permettez, pour vous.',
      "J'ai côtoyé des gens qui faisaient cela, autrefois. Je me disais que "
          "c'était nécessaire. Ça ne l'a jamais été.",
      'Je vous en prie. Pas comme ça. Plus jamais.',
    ],
    RemarkKind.approved: [
      "Bien choisi. La Lumière n'aura pas à pardonner celui-là.",
      'Merci. Je le pense vraiment.',
    ],
    RemarkKind.disapproved: [
      'Je ne peux pas bénir cela. Je suis désolée.',
      'Je le porterai avec le reste. Mon fardeau est déjà lourd.',
    ],
    RemarkKind.checkPassed: [
      "Quelqu'un veille encore sur nous deux.",
      'Posément. La Lumière aime les mains sûres.',
      "Bien joué. J'ai retenu mon souffle tout du long.",
    ],
    RemarkKind.checkFailed: [
      "Rien de cassé ? Alors ce n'était que l'orgueil, et l'orgueil guérit.",
      "Échouer est une sorte de prière. Cela nous rappelle qu'il en faut "
          'une.',
      'Laissez-moi regarder ça. Non, ne discutez pas.',
    ],
    RemarkKind.sneakedPast: [
      "Personne n'est mort. Je prendrai toujours ça.",
      'La miséricorde tient parfois à un pas silencieux. Celui-ci était '
          'bien placé.',
    ],
  },
  'liora': {
    RemarkKind.kindApproved: [
      'Bien. Une personne de moins que je verrai tomber, de là-haut.',
      "Je compte aussi ceux qu'on sauve. Un de plus.",
      "C'est pour ça que je suis descendue des toits.",
    ],
    RemarkKind.cruelDisapproved: [
      "J'ai vu ça. Je vois tout. Souvenez-vous-en.",
      "C'est le genre de chose sur laquelle je tirais, avant.",
      'Non. Ne m\'obligez pas à compter ceux-là aussi.',
    ],
    RemarkKind.approved: [
      'Choix net.',
      "J'aurais fait pareil. Plus lentement, et de plus haut.",
    ],
    RemarkKind.disapproved: [
      'Hum. Mauvais angle.',
      "J'aurais visé autrement.",
    ],
    RemarkKind.checkPassed: [
      "Bonne trajectoire. J'aurais pris la même.",
      'Bien jugé.',
      "Trois pas, aucun de trop. J'ai compté.",
    ],
    RemarkKind.checkFailed: [
      'Le vent a tourné. Ça arrive.',
      'Trop vite. Il faut expirer avant, pas après.',
      'Je vous couvrais. Recommencez quand vous voudrez.',
    ],
    RemarkKind.sneakedPast: [
      "Personne n'a levé les yeux. Personne ne lève jamais les yeux.",
      "Silence. Bien. J'avais une flèche prête, au cas où.",
    ],
  },
  'vess': {
    RemarkKind.kindApproved: [
      "Le Vide s'est tu, à l'instant. Il n'aime pas ce genre de chose.",
      "Personne n'a fait ça pour moi, quand je suis sortie du noir. Je suis "
          "contente que quelqu'un le fasse.",
      "C'était humain, ce que vous avez fait. J'apprends encore ce genre de "
          'chose.',
    ],
    RemarkKind.cruelDisapproved: [
      "Ça lui a plu. À la chose dans le noir. Je l'ai sentie sourire.",
      "Pas besoin du Vide pour faire preuve de cruauté. C'est ce qui "
          "m'effraie.",
      "S'il vous plaît, ne refaites pas ça là où je peux l'entendre.",
    ],
    RemarkKind.approved: [
      "Bien. Les murmures n'avaient rien à redire.",
      "Je crois que c'était juste. Je ne sais pas toujours ce qui l'est.",
    ],
    RemarkKind.disapproved: [
      'Les murmures ont ri. Pas moi.',
      "Je n'aime pas ça. Je ne sais pas encore pourquoi.",
    ],
    RemarkKind.checkPassed: [
      'Le Vide disait que vous tomberiez. Il ment.',
      'Élégant. Pour quelqu\'un sans néant en soi.',
      "Je n'ai pas aidé. Je tiens à ce que ce soit noté.",
    ],
    RemarkKind.checkFailed: [
      'Le noir voulait que ça arrive. Ne lui donnez rien de plus.',
      "J'aurais pu vous rattraper. Je n'étais pas sûre que vous le vouliez.",
      "Échouer n'est pas le pire. J'ai fait pire qu'échouer.",
    ],
    RemarkKind.sneakedPast: [
      "Les ombres sont plus faciles quand on n'en a pas peur.",
      "Pas un bruit. Comme dans le noir. Je m'y connais.",
    ],
  },
  'grosh': {
    RemarkKind.kindDisapproved: [
      "Grosh ne comprend pas. Grosh n'a pas besoin de comprendre.",
      'Gentil. Gentil, ça ne paie pas. Grosh dit ça comme ça.',
      'Les saints finissent enterrés pauvres. Grosh l\'a vu.',
    ],
    RemarkKind.cruelApproved: [
      'Ha ! Dur. Grosh aime quand c\'est dur.',
      "Pas de sermon. C'est fait. Bien.",
      'Ils s\'en souviendront. La peur coûte moins cher que des gardes.',
    ],
    RemarkKind.profitApproved: [
      "DE L'ARGENT ! Grosh entend de l'argent !",
      'Ce soir, on mange bien.',
      'Bien. Bourse lourde, cœur léger.',
    ],
    RemarkKind.approved: [
      'Grosh approuve. Grosh le dit.',
      'Bien. Simple. Grosh aime ce qui est simple.',
    ],
    RemarkKind.disapproved: [
      'Hmpf. Grosh trouve ça bête. En silence.',
      'Grosh ne le dira pas. Mais Grosh le pense très fort.',
    ],
    RemarkKind.checkPassed: [
      'Ha ! De la force ! Presque autant que Grosh !',
      "Grosh l'aurait cassé. Comme ça, c'est bien aussi.",
      "Bien ! Grosh n'aura pas à vous porter.",
    ],
    RemarkKind.checkFailed: [
      'Ha ! Grosh a vu ça. Grosh le racontera à tout le monde.',
      'La prochaine fois, frappez plus fort.',
      'Grosh tombe aussi, parfois. Surtout sur les ennemis.',
    ],
    RemarkKind.sneakedPast: [
      'Grosh voulait frapper. Grosh frappera plus tard.',
      "Se faufiler. Hmpf. Plus rapide que se battre, Grosh l'admet.",
    ],
  },
  'tobin': {
    RemarkKind.kindApproved: [
      'Voilà. Une chandelle d\'allumée. Le noir en est un peu plus petit.',
      'Le chœur chantait ce genre de chose. Vous, vous l\'avez fait.',
      'Je fredonnerai quelque chose pour eux ce soir. Et pour vous.',
    ],
    RemarkKind.cruelDisapproved: [
      "J'ai enterré ce que des actes pareils laissent derrière eux.",
      'Le Quartier des Cendres a commencé par un choix comme celui-là.',
      'Je ne chanterai pas ce soir.',
    ],
    RemarkKind.profitDisapproved: [
      "L'argent pèse. Prenez garde qu'il ne vous entraîne au fond.",
      "Chaque bourse de cette côte a été celle de quelqu'un.",
      "Le chœur prenait l'argent, lui aussi. Il n'en chantait pas mieux.",
    ],
    RemarkKind.approved: [
      'Bien fait. Je mettrai ça dans mes prières, du côté des '
          'remerciements.',
      "C'était juste. Je ne le dis pas à la légère.",
    ],
    RemarkKind.disapproved: [
      "Je ne discuterai pas. Je dirai seulement que j'aurais fait "
          'autrement.',
      "Hum. L'hymne pour celui-là est en mineur.",
    ],
    RemarkKind.checkPassed: [
      'Solide comme un mur de cloître. Bien.',
      "Bien joué. Mes genoux vous remercient de ne pas m'avoir fait "
          'essayer.',
      "La Lumière ne rate pas. Vous non plus, aujourd'hui.",
    ],
    RemarkKind.checkFailed: [
      'Rien qui ne se répare. Venez, laissez-moi voir.',
      "Les frères laissaient tomber l'encensoir à chaque fête. La fête "
          'continuait.',
      "Ce n'était pas votre heure. Il y en aura une autre.",
    ],
    RemarkKind.sneakedPast: [
      "Personne de blessé. C'est un hymne que je connais par cœur.",
      "Bien. Qu'ils vivent assez pour changer d'avis.",
    ],
  },
  'malrik': {
    RemarkKind.kindDisapproved: [
      'La pitié. Charmant. Impossible à facturer.',
      "Rien de personnel, mais c'est une perte, dans les comptes.",
      "La Cour aurait ri. J'essaie de m'en abstenir.",
    ],
    RemarkKind.cruelApproved: [
      "Rien de personnel. C'est comme ça qu'on fait.",
      'Efficace. La Cour vous aurait offert un siège.',
      'Vous apprenez. Je vous enverrai mes tarifs pour les leçons.',
    ],
    RemarkKind.profitApproved: [
      'Voilà un bon retour sur investissement.',
      'Du profit. Ma fin préférée.',
      'Je tiens le registre. Vous, continuez comme ça.',
    ],
    RemarkKind.approved: [
      "Décision saine. Je l'aurais facturée.",
      'Bien. Je révise mon estimation à la hausse.',
    ],
    RemarkKind.disapproved: [
      'Rien de personnel. Mais non.',
      "Ça va nous coûter. J'ai déjà fait le calcul.",
    ],
    RemarkKind.checkPassed: [
      "Du travail compétent. Presque décevant : j'avais parié contre vous.",
      'Bien joué. Je ferai comme si je n\'avais jamais douté.',
      'Vous voyez ? Le risque, maîtrisé. Il y a encore de la Cour en vous.',
    ],
    RemarkKind.checkFailed: [
      'Ah. Je range ça dans les pertes.',
      "Rien de personnel, mais c'était pénible à regarder.",
      'Tout le monde échoue. Les plus malins échouent là où personne ne '
          'regarde.',
    ],
    RemarkKind.sneakedPast: [
      'Pas de combat, pas de frais, pas de témoins. Parfait.',
      'La discrétion. La victoire la moins chère.',
    ],
  },
};
