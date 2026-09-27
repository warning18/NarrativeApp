import 'approval.dart';

/// Companion remarks (v1.167): a companion in the party says something
/// about what the player just did, in their own voice, and the next scene
/// opens with it.
///
/// Two kinds of deed get a remark:
///
/// - One the party has an opinion on (see approval.dart): a kind or cruel
///   choice, one that fills the purse, or a scene's own reaction. The
///   companion who took it hardest speaks, every time; when someone took
///   it the other way, they answer (v1.168).
/// - One that only shows what the player can do: an ability check passed
///   or failed, a fight slipped past. Someone speaks at most once every
///   [remarkCooldownChoices] choices, so the party doesn't narrate every
///   step.
///
/// The heaviest choices of the story have lines written for them (v1.168,
/// see [deedRemarkKeys]): a companion with such a line says it rather than
/// one of their general ones.
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

  /// A drink shared at the camp (v1.168).
  drink,
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

/// One companion's remark: who, about what, and which of their lines --
/// one of their general lines for [kind], or, with a [deedKey], the line
/// written for that very choice. The words are looked up when shown
/// ([lineFor]), so the remark follows a change of language.
class CompanionRemark {
  const CompanionRemark({
    required this.companionId,
    required this.kind,
    this.index = 0,
    this.deedKey,
  });

  final String companionId;
  final RemarkKind kind;
  final int index;
  final String? deedKey;

  String lineFor({required bool french}) {
    final key = deedKey;
    if (key != null) {
      final line = deedRemarkFor(key, companionId, french: french);
      if (line != null) return line;
    }
    final lines = remarkLinesFor(companionId, kind, french: french);
    return lines.isEmpty ? '' : lines[index % lines.length];
  }

  @override
  bool operator ==(Object other) =>
      other is CompanionRemark &&
      other.companionId == companionId &&
      other.kind == kind &&
      other.index == index &&
      other.deedKey == deedKey;

  @override
  int get hashCode => Object.hash(companionId, kind, index, deedKey);
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

/// What the party says about the choice the player just made -- nothing,
/// one remark, or a remark and an answer -- and the memory after it.
/// [reactions] are the party's reactions to [deed] (what
/// applyChoiceEffects or reactToDeed returned); [companions] is the raw
/// companions table, for their weights. [deedKeys] name the choice for its
/// written lines (see [deedKeysFor]). [action] is what the choice showed of
/// the player besides: a check passed or failed, a fight slipped past.
/// [activeAllyIds] is the party once the choice is done: whoever walked
/// out says their piece in the approval notice instead.
({List<CompanionRemark> remarks, RemarkMemory memory}) pickRemark({
  required RemarkMemory memory,
  required List<String> activeAllyIds,
  List<ApprovalChange> reactions = const [],
  RemarkDeed deed = const RemarkDeed(),
  Map<String, dynamic> companions = const {},
  List<String> deedKeys = const [],
  RemarkKind? action,
}) {
  final choice = memory.choices + 1;
  var current = RemarkMemory(
    seed: memory.seed,
    choices: choice,
    lastRemarkAt: memory.lastRemarkAt,
    lastSpokeAt: memory.lastSpokeAt,
    used: memory.used,
  );
  int lastSpoke(String id) => memory.lastSpokeAt[id] ?? -1;
  int partyPlace(String id) => activeAllyIds.indexOf(id);
  final deedKey = deedKeys.where(_deedLinesEn.containsKey).firstOrNull;
  bool hasDeedLine(String id) =>
      deedKey != null && deedRemarkFor(deedKey, id, french: false) != null;

  // A deed the party cares about: whoever took it hardest. One who just
  // came to trust the player completely, started losing patience or
  // walked out says so in the approval notice, in words of their own.
  final moved = <String, ({int delta, RemarkKind kind})>{
    for (final reaction in reactions)
      if (!reaction.hasOwnWords && activeAllyIds.contains(reaction.companionId))
        reaction.companionId: (
          delta: reaction.delta,
          kind: remarkKindFor(
            reaction,
            companions[reaction.companionId] as Map<String, dynamic>?,
            deed,
          ),
        ),
  }..removeWhere(
      (id, m) => !hasDeedLine(id) && remarkLinesFor(id, m.kind).isEmpty);
  // Who has something to say: whoever was moved, and whoever has a line
  // written for this choice. A written line comes first, then the
  // strongest feeling, then whoever spoke least recently.
  final candidates = {
    ...moved.keys,
    for (final id in activeAllyIds)
      if (hasDeedLine(id)) id,
  }.toList();
  int byTurns(String a, String b) {
    final byTurn = lastSpoke(a).compareTo(lastSpoke(b));
    return byTurn != 0 ? byTurn : partyPlace(a).compareTo(partyPlace(b));
  }

  int weight(String id) => moved[id]?.delta.abs() ?? 0;
  if (candidates.isNotEmpty) {
    candidates.sort((a, b) {
      final byLine = (hasDeedLine(b) ? 1 : 0) - (hasDeedLine(a) ? 1 : 0);
      if (byLine != 0) return byLine;
      final byWeight = weight(b).compareTo(weight(a));
      return byWeight != 0 ? byWeight : byTurns(a, b);
    });
    final first = candidates.first;
    final remarks = <CompanionRemark>[];
    CompanionRemark say(String id) {
      final RemarkKind kind = moved[id]?.kind ?? RemarkKind.approved;
      if (hasDeedLine(id)) {
        current = _noted(current, id);
        return CompanionRemark(companionId: id, kind: kind, deedKey: deedKey);
      }
      final spoken = _spoken(current, id, kind);
      current = spoken.memory;
      return spoken.remark;
    }

    remarks.add(say(first));
    // Someone who took it the other way answers.
    final firstDelta = moved[first]?.delta ?? 0;
    final answerers = [
      for (final entry in moved.entries)
        if (entry.key != first &&
            firstDelta != 0 &&
            entry.value.delta.sign == -firstDelta.sign)
          entry.key,
    ]..sort((a, b) {
        final byWeight = weight(b).compareTo(weight(a));
        return byWeight != 0 ? byWeight : byTurns(a, b);
      });
    if (answerers.isNotEmpty) remarks.add(say(answerers.first));
    return (remarks: remarks, memory: current);
  }

  // A check or a sneak: someone speaks up, now and then.
  final last = memory.lastRemarkAt;
  if (action == null ||
      (last != null && choice - last < remarkCooldownChoices)) {
    return (remarks: const [], memory: current);
  }
  final speakers = [
    for (final id in activeAllyIds)
      if (remarkLinesFor(id, action).isNotEmpty) id,
  ]..sort(byTurns);
  if (speakers.isEmpty) return (remarks: const [], memory: current);
  final spoken = _spoken(current, speakers.first, action);
  return (remarks: [spoken.remark], memory: spoken.memory);
}

/// [companionId]'s word to the player on a drink shared at the camp, and
/// the memory after it; nothing when they have no such line.
({CompanionRemark? remark, RemarkMemory memory}) drinkRemark(
    RemarkMemory memory, String companionId) {
  if (remarkLinesFor(companionId, RemarkKind.drink).isEmpty) {
    return (remark: null, memory: memory);
  }
  final spoken = _spoken(memory, companionId, RemarkKind.drink);
  return (remark: spoken.remark, memory: spoken.memory);
}

/// [memory] with [companionId] having just spoken.
RemarkMemory _noted(RemarkMemory memory, String companionId) => RemarkMemory(
      seed: memory.seed,
      choices: memory.choices,
      lastRemarkAt: memory.choices,
      lastSpokeAt: {...memory.lastSpokeAt, companionId: memory.choices},
      used: memory.used,
    );

({CompanionRemark remark, RemarkMemory memory}) _spoken(
    RemarkMemory memory, String companionId, RemarkKind kind) {
  final key = '$companionId/${kind.name}';
  final count = memory.used[key] ?? 0;
  final lines = remarkLinesFor(companionId, kind);
  final start = (memory.seed + _stableHash(key)) % lines.length;
  final noted = _noted(memory, companionId);
  return (
    remark: CompanionRemark(
      companionId: companionId,
      kind: kind,
      index: (start + count) % lines.length,
    ),
    memory: RemarkMemory(
      seed: noted.seed,
      choices: noted.choices,
      lastRemarkAt: noted.lastRemarkAt,
      lastSpokeAt: noted.lastSpokeAt,
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

/// The names a story choice goes by for its written lines: the flags it
/// sets, then `nodeId#index`, its place among [choices] in [nodeId]'s
/// scene (for a choice with no flag of its own).
List<String> deedKeysFor<T>(
        String nodeId, List<T> choices, T choice, List<String> flags) =>
    [
      ...flags,
      if (choices.contains(choice)) '$nodeId#${choices.indexOf(choice)}',
    ];

/// The line [companionId] has for the choice named [deedKey], if any.
String? deedRemarkFor(String deedKey, String companionId,
        {required bool french}) =>
    (french ? _deedLinesFr : _deedLinesEn)[deedKey]?[companionId] ??
    (french ? _deedLinesEn : _deedLinesFr)[deedKey]?[companionId];

/// Every choice with written lines, for tests.
Iterable<String> get deedRemarkKeys => _deedLinesEn.keys;

/// Every companion's lines for [deedKey], in English or French, for tests.
Map<String, String> deedRemarksOf(String deedKey, {required bool french}) =>
    (french ? _deedLinesFr : _deedLinesEn)[deedKey] ?? const {};

// Lines written for the story's heaviest choices, by the choice's flag (or
// `nodeId#index`), then by companion. Only companions who can be in the
// party by then have one.
const _deedLinesEn = <String, Map<String, String>>{
  // The Inquisitor on the pier, beaten.
  '960#1': {
    'vess': "You could have made him scream. He'd have deserved it. I'm glad "
        "you didn't want to.",
  },
  '960#2': {
    'vess': 'The dark taught me that too. Making them pay. It never once felt '
        'like being paid back.',
  },
  // The wharf: a boat for twenty, a hundred waiting.
  'refugees_aboard': {
    'kelda': "A hundred on a boat built for twenty, and the stores over the "
        "side. That's a gate held. I'll bail if I have to.",
    'sable': "There go three weeks of food, for a hundred mouths that'll eat "
        "for three days. I'll be hungry and right, love. There are worse "
        'things to be.',
    'liora': "I counted them up the gangway. All of them. I'll count them off "
        'again on the other side.',
    'vess': "The children didn't look at me like I was the dark. I think it's "
        'because you let me carry one.',
  },
  'refugees_left': {
    'kelda': "Twenty who can fight. I'd have picked the same twenty. I'll hate "
        'it the same, too.',
    'sable': "Hard sum. Right sum. Don't look back at the wharf; it doesn't "
        'change the numbers.',
    'liora': "I can still see their lanterns from up here. I'm going to watch "
        "them until I can't.",
    'vess': 'They will remember who chose. I remember every door that closed '
        'on me.',
  },
  'sailed_alone': {
    'kelda': 'A hundred people on that wharf, and the Eel sails light. I held '
        'a gate once so nobody would ever have to watch that.',
    'sable': "Light, fast and full. I'd have said it myself. I didn't think "
        "you would.",
    'liora': "I watched the three orphans until the smoke took the wharf. I'm "
        'still watching them.',
    'vess': "The Void does this. Leaves people on a shore. I didn't think you "
        'would.',
  },
  // The storm: the tow-line to the refugees' skiff.
  'skiff_cut': {
    'kelda': "There were people in that skiff. I heard them over the storm. "
        "I'll hear them for a while.",
    'sable': "Them or us, and you chose us. I'll drink to that. I won't enjoy "
        'the drink.',
    'liora': "I had that rope in my sights. I could have held it. You didn't "
        'ask.',
    'vess': 'The sea took them the way the dark takes things. Quickly, and '
        'without asking whose they were.',
  },
  // Tern Row: the toll-man talked down.
  'tern_row_spared': {
    'kelda': "No blood on the Row, and the toll-man walked off thinking it was "
        "his idea. That's how a gate should be held.",
    'sable': "You talked a tyrant out of his toll and came away paid. I'm "
        'almost proud. Almost.',
    'liora': "Nadira's lanterns are still lit. I checked from the roof.",
  },
  // The Reckoning Wall: the auxiliary out-argued.
  'reckoning_wall_saved': {
    'maren': "You quoted the Code at him. I once wrote notes in the margins of "
        "those procedures. I never thought I'd hear them save a wall of "
        'names.',
    'grosh': 'Grosh wanted to break the oil man. Words worked. Grosh is... '
        'surprised.',
    'liora': 'The names stay on the wall. Good. Somebody has to keep counting '
        'them.',
  },
  // The standard, stitched into a living man.
  'standard_cut_living': {
    'maren': 'He was still breathing. I have watched the Inquisition take '
        'cloth from the living. I never thought I would watch you do it.',
    'grosh': 'Quick. The fire was coming. Grosh would have done the same.',
    'kelda': "The camp needed us back. I know. I also know what I heard in "
        'that sanctum.',
  },
  '4999_standard#2': {
    'maren': 'The blade first. It was the only kindness left in that room, and '
        'you found it.',
    'kelda': 'Clean and quick, the way a soldier would want it. He was one, '
        'once.',
  },
  // The Court's sleepers in the Shroud's twin.
  'court_woken': {
    'malrik': "Waking them cost us a quarter hour we didn't have. Nothing "
        "personal, but I'd have let them sleep. Lucky for them you're not me.",
    'tobin': "They knew their own names at the end. I've sung over worse "
        'deaths than that. Not many.',
    'maren': 'They died as themselves. That is more than the Inquisition ever '
        'gave anyone it wrapped in cloth.',
  },
  'court_never_woke': {
    'malrik':
        "Efficient. The Court kept them asleep because asleep is cheaper. "
            "You've learned the ledger.",
    'tobin': "Two of those faces had names you knew. I'll say them tonight, "
        "since they didn't get to.",
    'maren': 'They never woke. I keep telling myself that is a mercy. I keep '
        'not believing it.',
  },
  // The Hollow Shore: the legate's pact.
  'inquisition_pact': {
    'maren': 'A white pole above a white cathedral. I carried that pole once. '
        'I swore I never would again, and now I am walking behind it.',
    'tobin': 'The Ashen Quarter burned under that saint. You took its purse.',
    'malrik': 'A crown and a purse from the people who burned your city. '
        'Nothing personal: best deal on the table.',
    'grosh': 'Heavy purse. Grosh does not like the rowers. Grosh will watch '
        'them.',
  },
  'pact_refused': {
    'maren': 'You sent the white sail back. I have waited half my life to see '
        'someone do that.',
    'tobin': 'No crown from them. Good. Let the tide have their saint.',
    'malrik': "Three hundred gold, rowing away. I'll mourn it in private.",
    'kelda': "Good. I've held gates against that sail. I wasn't about to start "
        'holding them for it.',
  },
  // The tear's price.
  'sovereign_took_companion': {
    'kelda': "It took one of us, and you held out the hand. I've buried "
        "soldiers. I'd never seen one sold.",
    'sable': "Everyone has a price. I didn't think you'd pay yours in people.",
    'maren': 'I will say their name every morning. Someone should, now.',
    'malrik': "Nothing personal. That's what I told myself the first time I "
        'sold someone. It stopped working.',
  },
  'legate_given': {
    'malrik': "The legate. Now that's a price I can respect. He'd have sold us "
        'for less.',
    'maren': 'He was a bad man. It was still a man you gave to that thing.',
    'grosh': 'Good. Nobody liked the legate. Not even the rowers.',
  },
  'sovereign_blood': {
    'maren': 'Your own blood, and not ours. I will pray over the crossing. '
        'Over you first.',
    'kelda': "You paid it yourself. That's the whole of being in charge, and "
        'you knew it.',
    'grosh': 'Grosh would have given Grosh blood. You did not ask. Grosh... '
        'remembers that.',
    'liora': "I'll watch your back on the crossing. Closer than usual.",
  },
  'camp_given': {
    'kelda': "I built half those walls. Let the coast burn, you said. I'll be "
        'a while forgiving that.',
    'tobin': 'There were candles in that camp. I lit most of them.',
    'sable': 'All that coin in timber and rope, gone for a door. At least '
        "it's a big door.",
    'vess': "Places burn. I know. It was the first place that ever let me "
        'stay.',
  },
  // The flagship's sail, the fifth piece.
  'flagship_burned': {
    'sable': "Burn the ship, keep the sail, sell the brass. I've taught you "
        'well.',
    'tobin': "There were sailors still below. The fire didn't ask which ones "
        'were living.',
    'kelda': "Fastest way to a sail. Not the way I'll tell it, later.",
  },
  'sail_bought': {
    'malrik': 'A hundred and fifty to riggers, for a job a torch would have '
        'done. My heart.',
    'tobin': "The Anchorage eats this winter. That's worth more than the "
        'sail.',
    'maren': "You paid people for honest work. It seems small. It isn't.",
  },
  // Greyhithe's eldest and the Court's page.
  'greyhithe_names_read': {
    'maren': "You read her daughter's name aloud. That is what a ledger is "
        'for, in the end.',
    'tobin': "I'll sing for the daughter tonight, now that I know her name.",
    'liora': "She held your hands while you read. I've never seen anyone hold "
        'on that hard.',
  },
  '7200_elder_later#1': {
    'maren': 'You lied to spare her. I have told that lie. It never spared '
        'anyone for long.',
    'malrik': "A kind lie. Cheap, too. I'd have charged her for the truth.",
    'tobin': "She'll go on waiting now. That's the price of the lie, and she "
        'pays it, not you.',
  },
  // The wreckers' false lamps.
  'false_lamps_out': {
    'grosh': 'Grosh does not understand paying a man to stop. But the lamps '
        'are out. Good.',
    'sable': 'Paying a wrecker to stop wrecking. Charming. Ruinous, but '
        'charming.',
    'tobin': "No more ships on those rocks. I'll light a candle for the ones "
        'already there.',
    'liora': 'I watched the last lamp go out from the headland. Clean dark. '
        'Good dark.',
  },
};

const _deedLinesFr = <String, Map<String, String>>{
  '960#1': {
    'vess': "Vous auriez pu le faire hurler. Il l'aurait mérité. Je suis "
        "contente que vous n'en ayez pas eu envie.",
  },
  '960#2': {
    'vess': "Le noir m'a appris ça aussi. Leur faire payer. Ça n'a jamais "
        "ressemblé à une dette qu'on me rendait.",
  },
  'refugees_aboard': {
    'kelda': 'Cent personnes sur un bateau fait pour vingt, et les vivres '
        "par-dessus bord. Ça, c'est une porte tenue. J'écoperai s'il le faut.",
    'sable': 'Voilà trois semaines de vivres jetées pour cent bouches qui '
        "mangeront trois jours. J'aurai faim et raison, mon chou. Il y a pire.",
    'liora': 'Je les ai comptés sur la passerelle. Tous. Je les recompterai de '
        "l'autre côté.",
    'vess': "Les enfants ne m'ont pas regardée comme si j'étais le noir. Je "
        "crois que c'est parce que vous m'avez laissée en porter un.",
  },
  'refugees_left': {
    'kelda': "Vingt qui savent se battre. J'aurais choisi les mêmes. Et je "
        'détesterai ça tout autant.',
    'sable': 'Calcul dur. Calcul juste. Ne regardez pas le quai ; ça ne change '
        'pas les chiffres.',
    'liora': "Je vois encore leurs lanternes d'ici. Je vais les regarder "
        "jusqu'à ce que je ne puisse plus.",
    'vess': 'Ils se souviendront de qui a choisi. Je me souviens de chaque '
        "porte qui s'est fermée devant moi.",
  },
  'sailed_alone': {
    'kelda': "Cent personnes sur ce quai, et l'Eel navigue légère. J'ai tenu "
        "une porte, autrefois, pour que personne n'ait jamais à voir ça.",
    'sable': "Légère, rapide et pleine. Je l'aurais dit moi-même. Je ne "
        'pensais pas que vous le feriez.',
    'liora': "J'ai regardé les trois orphelins jusqu'à ce que la fumée avale "
        'le quai. Je les regarde encore.',
    'vess': 'Le Vide fait ça. Il laisse les gens sur un rivage. Je ne pensais '
        'pas que vous le feriez.',
  },
  'skiff_cut': {
    'kelda': 'Il y avait des gens dans cette barque. Je les ai entendus '
        'par-dessus la tempête. Je les entendrai encore un moment.',
    'sable': "Eux ou nous, et vous avez choisi nous. J'y boirai. Sans y "
        'prendre plaisir.',
    'liora': "J'avais cette corde en vue. J'aurais pu la tenir. Vous ne m'avez "
        'rien demandé.',
    'vess': 'La mer les a pris comme le noir prend les choses. Vite, et sans '
        'demander à qui elles étaient.',
  },
  'tern_row_spared': {
    'kelda': "Pas de sang dans Tern Row, et l'homme du péage est parti en "
        "croyant que c'était son idée. C'est comme ça qu'on tient une porte.",
    'sable': 'Vous avez fait renoncer un petit tyran à son péage, avec une '
        'récompense en prime. Je suis presque fière. Presque.',
    'liora': "Les lanternes de Nadira sont encore allumées. J'ai vérifié "
        'depuis le toit.',
  },
  'reckoning_wall_saved': {
    'maren': "Vous lui avez cité le Code. J'ai annoté ces procédures, "
        "autrefois. Je n'aurais jamais cru les entendre sauver un mur de "
        'noms.',
    'grosh': "Grosh voulait casser l'homme à l'huile. Les mots ont marché. "
        'Grosh est... surpris.',
    'liora': "Les noms restent sur le mur. Bien. Il faut bien que quelqu'un "
        'continue à les compter.',
  },
  'standard_cut_living': {
    'maren': "Il respirait encore. J'ai vu l'Inquisition arracher du tissu à "
        'des vivants. Je ne pensais pas vous voir le faire.',
    'grosh': 'Vite fait. Le feu arrivait. Grosh aurait fait pareil.',
    'kelda': "Le camp avait besoin de nous. Je sais. Je sais aussi ce que j'ai "
        'entendu dans ce sanctuaire.',
  },
  '4999_standard#2': {
    'maren': "La lame d'abord. C'était la seule bonté qui restait dans cette "
        "pièce, et vous l'avez trouvée.",
    'kelda': "Net et rapide, comme un soldat l'aurait voulu. Il en était un, "
        'autrefois.',
  },
  'court_woken': {
    'malrik': 'Les réveiller nous a coûté un quart d’heure que nous '
        "n'avions pas. Rien de personnel, mais je les aurais laissés dormir. "
        "Heureusement pour eux, vous n'êtes pas moi.",
    'tobin': "Ils connaissaient leur propre nom, à la fin. J'ai chanté sur de "
        'pires morts. Pas beaucoup.',
    'maren': "Ils sont morts en étant eux-mêmes. C'est plus que l'Inquisition "
        "n'a jamais accordé à ceux qu'elle enveloppait de tissu.",
  },
  'court_never_woke': {
    'malrik': "Efficace. La Cour les gardait endormis parce que c'est moins "
        'cher. Vous avez appris le registre.',
    'tobin': 'Deux de ces visages avaient des noms que vous connaissiez. Je '
        "les dirai ce soir, puisqu'ils n'ont pas pu.",
    'maren': "Ils ne se sont jamais réveillés. Je me répète que c'est une "
        "miséricorde. Je n'arrive pas à le croire.",
  },
  'inquisition_pact': {
    'maren': "Un mât blanc au-dessus d'une cathédrale blanche. J'ai porté ce "
        "mât, autrefois. J'avais juré de ne jamais recommencer, et me voilà "
        'qui marche derrière.',
    'tobin': 'Le Quartier des Cendres a brûlé sous ce saint. Vous avez pris sa '
        'bourse.',
    'malrik': 'Une couronne et une bourse offertes par ceux qui ont brûlé '
        'votre ville. Rien de personnel : la meilleure affaire sur la table.',
    'grosh': "Grosse bourse. Grosh n'aime pas les rameurs. Grosh va les "
        'surveiller.',
  },
  'pact_refused': {
    'maren': "Vous avez renvoyé la voile blanche. J'ai attendu la moitié de "
        'ma vie de voir quelqu’un faire ça.',
    'tobin': "Pas de couronne venue d'eux. Bien. Que la marée garde leur "
        'saint.',
    'malrik': "Trois cents pièces d'or qui s'éloignent à la rame. Je les "
        'pleurerai en privé.',
    'kelda': "Bien. J'ai tenu des portes contre cette voile. Pas question de "
        'commencer à les tenir pour elle.',
  },
  'sovereign_took_companion': {
    'kelda': "Il a pris quelqu'un d'entre nous, et c'est vous qui avez tendu "
        "la main. J'ai enterré des soldats. Je n'en avais jamais vu vendre.",
    'sable': 'Tout le monde a un prix. Je ne pensais pas que vous paieriez le '
        'vôtre en gens.',
    'maren': 'Je dirai son nom chaque matin. Il faut bien que quelqu’un le '
        'fasse, désormais.',
    'malrik': "Rien de personnel. C'est ce que je me suis dit la première fois "
        "que j'ai vendu quelqu'un. Ça a cessé de marcher.",
  },
  'legate_given': {
    'malrik': 'Le légat. Voilà un prix que je respecte. Il nous aurait vendus '
        'pour moins que ça.',
    'maren': "C'était un homme mauvais. C'était quand même un homme que vous "
        'avez livré à cette chose.',
    'grosh': "Bien. Personne n'aimait le légat. Pas même les rameurs.",
  },
  'sovereign_blood': {
    'maren': 'Votre propre sang, et pas le nôtre. Je prierai sur la '
        "traversée. Sur vous d'abord.",
    'kelda': "Vous avez payé vous-même. C'est tout ce que veut dire "
        'commander, et vous le saviez.',
    'grosh': "Grosh aurait donné le sang de Grosh. Vous n'avez pas demandé. "
        "Grosh... s'en souvient.",
    'liora': 'Je surveillerai vos arrières pendant la traversée. De plus près '
        "que d'habitude.",
  },
  'camp_given': {
    'kelda': "J'ai monté la moitié de ces murs. Que la côte brûle, avez-vous "
        'dit. Il me faudra du temps pour vous le pardonner.',
    'tobin': "Il y avait des chandelles dans ce camp. J'en ai allumé la "
        'plupart.',
    'sable': 'Tout cet argent en bois et en cordage, parti pour une porte. Au '
        "moins, c'est une grande porte.",
    'vess': "Les lieux brûlent. Je sais. C'était le premier endroit qui "
        "m'ait laissée rester.",
  },
  'flagship_burned': {
    'sable': 'Brûler le navire, garder la voile, vendre le cuivre. Je vous ai '
        'bien appris.',
    'tobin': "Il restait des marins en bas. Le feu n'a pas demandé lesquels "
        'vivaient encore.',
    'kelda': 'Le chemin le plus court vers une voile. Pas celui que je '
        'raconterai, plus tard.',
  },
  'sail_bought': {
    'malrik': "Cent cinquante pièces à des gréeurs, pour un travail qu'une "
        'torche aurait fait. Mon cœur.',
    'tobin': 'Le Mouillage mangera cet hiver. Ça vaut plus que la voile.',
    'maren': "Vous avez payé des gens pour un travail honnête. Ça semble peu "
        "de chose. Ça ne l'est pas.",
  },
  'greyhithe_names_read': {
    'maren': "Vous avez lu à voix haute le nom de sa fille. C'est à ça que "
        'sert un registre, au bout du compte.',
    'tobin': 'Je chanterai pour la fille ce soir, maintenant que je connais '
        'son nom.',
    'liora': "Elle vous a tenu les mains pendant que vous lisiez. Je n'ai "
        "jamais vu personne s'accrocher aussi fort.",
  },
  '7200_elder_later#1': {
    'maren': "Vous avez menti pour l'épargner. J'ai dit ce mensonge-là. Il "
        "n'a jamais épargné personne longtemps.",
    'malrik': 'Un mensonge gentil. Et bon marché. Moi, je lui aurais fait '
        'payer la vérité.',
    'tobin': "Elle va continuer d'attendre, maintenant. C'est le prix du "
        "mensonge, et c'est elle qui le paie, pas vous.",
  },
  'false_lamps_out': {
    'grosh': "Grosh ne comprend pas qu'on paie un homme pour qu'il arrête. "
        'Mais les lampes sont éteintes. Bien.',
    'sable': "Payer un naufrageur pour qu'il cesse. Charmant. Ruineux, mais "
        'charmant.',
    'tobin': "Plus de navires sur ces rochers. J'allumerai une chandelle pour "
        'ceux qui y sont déjà.',
    'liora': "J'ai regardé la dernière lampe s'éteindre depuis le cap. Un noir "
        'propre. Un bon noir.',
  },
};

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
    RemarkKind.drink: [
      "To the gate, and whoever's behind it. Your round, I see.",
      "Dwarven ale's better. Don't tell the barkeep. Thank you.",
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
    RemarkKind.drink: [
      "Buying the drinks. You're learning how to keep a partner, love.",
      "I'll pretend I don't know what this costs. Cheers.",
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
    RemarkKind.drink: [
      "I took a vow against this, once. Tomorrow I'll take another.",
      "Thank you. It's been a long time since anyone poured for me.",
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
    RemarkKind.drink: [
      "Up on the roof, then. Better view, and nobody hears us toast.",
      "One cup. I'm still on watch. I'm always on watch.",
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
    RemarkKind.drink: [
      "Nobody drank with me in the dark. It was very quiet. This is better.",
      "The whispers go quiet when I'm warm. Thank you.",
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
    RemarkKind.drink: [
      "DRINK! Grosh likes you more now. This is how it works.",
      "Grosh will drink yours too, if you are slow.",
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
    RemarkKind.drink: [
      "The brothers brewed better, but they never shared it. Your health.",
      "I'll sing after the second cup. You've been warned.",
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
    RemarkKind.drink: [
      "A drink on your coin. I'll book it as a gift, not a debt. Rare, for me.",
      "To profit. And, fine, to you.",
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
    RemarkKind.drink: [
      "À la porte, et à ceux qui sont derrière. C'est votre tournée, à ce que je vois.",
      "La bière naine est meilleure. Ne le dites pas au tavernier. Merci.",
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
    RemarkKind.drink: [
      "Vous payez la tournée. Vous apprenez à garder une associée, mon chou.",
      "Je vais faire comme si je ne savais pas ce que ça coûte. Santé.",
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
    RemarkKind.drink: [
      "J'ai fait vœu de ne pas boire, autrefois. Demain, j'en ferai un autre.",
      "Merci. Il y a longtemps que personne ne m'avait servie.",
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
    RemarkKind.drink: [
      "Sur le toit, alors. Meilleure vue, et personne ne nous entend trinquer.",
      "Une coupe. Je suis encore de garde. Je suis toujours de garde.",
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
    RemarkKind.drink: [
      "Personne ne buvait avec moi, dans le noir. C'était très calme. C'est mieux ainsi.",
      "Les murmures se taisent quand j'ai chaud. Merci.",
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
    RemarkKind.drink: [
      "À BOIRE ! Grosh vous aime davantage maintenant. C'est comme ça que ça marche.",
      "Grosh boira aussi le vôtre, si vous traînez.",
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
    RemarkKind.drink: [
      "Les frères brassaient mieux, mais ils ne partageaient jamais. À votre santé.",
      "Je chanterai après la deuxième coupe. C'est dit.",
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
    RemarkKind.drink: [
      "Un verre à vos frais. Je le note comme un cadeau, pas une dette. C'est rare, chez moi.",
      "Au profit. Et, bon, à vous.",
    ],
  },
};
