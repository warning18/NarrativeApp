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
/// The lines are game data (v1.169): the Companion Remarks table
/// (assets/gamedata/companion_remarks.json, editable in the Data tab),
/// read through a [RemarkBook]. Each record is one companion's lines for
/// one [RemarkKind] -- or, with the trigger [choiceRemarkTrigger], for one
/// story choice, named by a flag it sets or `nodeId#index` (see
/// [deedKeysFor]); a companion with a line for the choice just made says
/// it rather than one of their general ones.
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

/// The trigger of a Companion Remarks record written for one story choice
/// (its `choiceKey` names the choice).
const String choiceRemarkTrigger = 'choice';

/// Every trigger a Companion Remarks record can have: a [RemarkKind]'s
/// name, or [choiceRemarkTrigger].
final List<String> remarkTriggerOptions = [
  for (final kind in RemarkKind.values) kind.name,
  choiceRemarkTrigger,
];

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
/// one of their general lines for [kind], or, with a [deedKey], one
/// written for that very choice. The words are looked up in the
/// [RemarkBook] when shown ([lineFor]), so the remark follows a change of
/// language.
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

  String lineFor(RemarkBook book, {required bool french}) {
    final key = deedKey;
    final lines = key != null
        ? book.choiceLinesFor(key, companionId, french: french)
        : book.linesFor(companionId, kind, french: french);
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
/// [book] holds the lines. [reactions] are the party's reactions to [deed] (what
/// applyChoiceEffects or reactToDeed returned); [companions] is the raw
/// companions table, for their weights. [deedKeys] name the choice for its
/// written lines (see [deedKeysFor]). [action] is what the choice showed of
/// the player besides: a check passed or failed, a fight slipped past.
/// [activeAllyIds] is the party once the choice is done: whoever walked
/// out says their piece in the approval notice instead.
({List<CompanionRemark> remarks, RemarkMemory memory}) pickRemark({
  required RemarkBook book,
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
  final deedKey = deedKeys.where(book.hasChoice).firstOrNull;
  bool hasDeedLine(String id) =>
      deedKey != null && book.choiceLinesFor(deedKey, id).isNotEmpty;

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
      (id, m) => !hasDeedLine(id) && book.linesFor(id, m.kind).isEmpty);
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
      final written = hasDeedLine(id) ? deedKey : null;
      final spoken = _spoken(current, id, kind,
          lineCount: written != null
              ? book.choiceLinesFor(written, id).length
              : book.linesFor(id, kind).length,
          deedKey: written);
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
      if (book.linesFor(id, action).isNotEmpty) id,
  ]..sort(byTurns);
  if (speakers.isEmpty) return (remarks: const [], memory: current);
  final spoken = _spoken(current, speakers.first, action,
      lineCount: book.linesFor(speakers.first, action).length);
  return (remarks: [spoken.remark], memory: spoken.memory);
}

/// [companionId]'s word to the player on a drink shared at the camp, and
/// the memory after it; nothing when they have no such line.
({CompanionRemark? remark, RemarkMemory memory}) drinkRemark(
    RemarkBook book, RemarkMemory memory, String companionId) {
  final lines = book.linesFor(companionId, RemarkKind.drink);
  if (lines.isEmpty) return (remark: null, memory: memory);
  final spoken =
      _spoken(memory, companionId, RemarkKind.drink, lineCount: lines.length);
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

/// [companionId] says the next of their [lineCount] lines for [kind] (or
/// for the choice [deedKey]): which one, and the memory after it.
({CompanionRemark remark, RemarkMemory memory}) _spoken(
  RemarkMemory memory,
  String companionId,
  RemarkKind kind, {
  required int lineCount,
  String? deedKey,
}) {
  final key = deedKey == null
      ? '$companionId/${kind.name}'
      : '$companionId/$choiceRemarkTrigger:$deedKey';
  final count = memory.used[key] ?? 0;
  final lines = lineCount < 1 ? 1 : lineCount;
  final start = (memory.seed + _stableHash(key)) % lines;
  final noted = _noted(memory, companionId);
  return (
    remark: CompanionRemark(
      companionId: companionId,
      kind: kind,
      index: (start + count) % lines,
      deedKey: deedKey,
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

/// The names a story choice goes by for its written lines: the flags it
/// sets, then `nodeId#index`, its place among [choices] in [nodeId]'s
/// scene (for a choice with no flag of its own).
List<String> deedKeysFor<T>(
        String nodeId, List<T> choices, T choice, List<String> flags) =>
    [
      ...flags,
      if (choices.contains(choice)) '$nodeId#${choices.indexOf(choice)}',
    ];

/// The companions' remark lines, as the Companion Remarks table has them
/// (see the top of this file): one record per companion and trigger, its
/// `lines` in English and `lines_fr` in French. Two records for the same
/// companion and trigger add up. A French list left empty falls back to
/// the English.
class RemarkBook {
  RemarkBook(Map<String, dynamic> records) {
    for (final record in records.values) {
      if (record is! Map) continue;
      final companionId = record['companionID']?.toString().trim() ?? '';
      final trigger = record['trigger']?.toString().trim() ?? '';
      final en = _linesOf(record['lines']);
      final fr = _linesOf(record['lines_fr']);
      if (companionId.isEmpty || (en.isEmpty && fr.isEmpty)) continue;
      _Lines? slot;
      if (trigger == choiceRemarkTrigger) {
        final key = record['choiceKey']?.toString().trim() ?? '';
        if (key.isEmpty) continue;
        slot = _choice
            .putIfAbsent(key, () => {})
            .putIfAbsent(companionId, _Lines.new);
      } else {
        final kind = RemarkKind.values.asNameMap()[trigger];
        if (kind == null) continue;
        slot = _general
            .putIfAbsent(companionId, () => {})
            .putIfAbsent(kind, _Lines.new);
      }
      slot.en.addAll(en);
      slot.fr.addAll(fr);
    }
  }

  /// No lines at all (the table not loaded yet): nobody remarks.
  static final RemarkBook empty = RemarkBook(const {});

  final Map<String, Map<RemarkKind, _Lines>> _general = {};
  final Map<String, Map<String, _Lines>> _choice = {};

  /// [companionId]'s lines for [kind]; empty when they have none.
  List<String> linesFor(String companionId, RemarkKind kind,
          {bool french = false}) =>
      _general[companionId]?[kind]?.pick(french) ?? const [];

  /// [companionId]'s lines for the story choice named [choiceKey].
  List<String> choiceLinesFor(String choiceKey, String companionId,
          {bool french = false}) =>
      _choice[choiceKey]?[companionId]?.pick(french) ?? const [];

  /// Whether some companion has a line for the choice named [choiceKey].
  bool hasChoice(String choiceKey) => _choice.containsKey(choiceKey);

  /// Every companion with general lines.
  Iterable<String> get companions => _general.keys;

  /// Every choice with lines written for it.
  Iterable<String> get choiceKeys => _choice.keys;

  /// Every companion's lines for [choiceKey].
  Map<String, List<String>> choiceLinesOf(String choiceKey,
          {bool french = false}) =>
      {
        for (final id in _choice[choiceKey]?.keys ?? const <String>[])
          id: choiceLinesFor(choiceKey, id, french: french),
      };

  static List<String> _linesOf(Object? value) => [
        if (value is List)
          for (final line in value)
            if (line.toString().trim().isNotEmpty) line.toString().trim(),
      ];
}

class _Lines {
  final List<String> en = [];
  final List<String> fr = [];

  List<String> pick(bool french) =>
      french && fr.isNotEmpty ? fr : (en.isNotEmpty ? en : fr);
}
