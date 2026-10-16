import 'dart:math';

import '../models/story_politics.dart';
import '../providers/player_session_provider.dart';
import 'politics_events.dart' show questTurnInPoliticsKey;
import 'quest_objectives.dart';
import 'sub_node_engine.dart';
import 'turn_in_choices.dart';

/// What a simulated quest came to: when it was taken, when (if ever) it was
/// handed in, and what it paid.
class SimQuestRecord {
  SimQuestRecord(this.questId, {required this.acceptedAtStep});

  final String questId;
  final int acceptedAtStep;
  int? completedAtStep;
  int gold = 0;
  int xp = 0;
  String itemId = '';
  String turnIn = '';
}

/// A quest handed in: the caller applies what it pays to the character.
class SimQuestPayout {
  const SimQuestPayout({
    required this.questId,
    required this.name,
    required this.gold,
    required this.xp,
    required this.alignment,
    required this.itemId,
    required this.flag,
    required this.nextQuestId,
    required this.turnIn,
    this.politics,
    this.politicsKey = '',
  });

  final String questId;
  final String name;
  final int gold;
  final int xp;
  final int alignment;
  final String itemId;
  final String flag;
  final String nextQuestId;

  /// The turn-in choice taken (its text), '' for a quest that simply pays.
  final String turnIn;

  /// What the turn-in choice taken moves among the clans (see
  /// TurnInChoice.politics), null when it moves nothing (v1.463): the
  /// caller applies it as the app does, once under [politicsKey]
  /// (questTurnInPoliticsKey) and logged `quest:<questId>`.
  final StoryPolitics? politics;
  final String politicsKey;
}

/// Which way the simulated player settles a quest that offers a choice.
enum SimTurnInBias { any, good, evil, gold }

/// The quests of a simulated playthrough (v1.230): taken when a scene offers
/// them (if the character qualifies as the game asks), counted from the
/// kills made, the flags set and the pack's items, handed in as soon as
/// every objective is met, paying gold, XP, an item, an alignment and a
/// follow-up quest, with the turn-in choice the player's bias picks. The
/// objectives are read by the game's own [objectiveStatusesFor].
class SimQuestLog {
  SimQuestLog(this.quests, {this.npcs = const {}});

  /// quests.json and npcs.json.
  final Map<String, dynamic> quests;
  final Map<String, dynamic> npcs;

  final List<String> active = [];
  final Set<String> completed = {};
  final Map<String, SimQuestRecord> records = {};
  final Map<String, int> kills = {};
  final Map<String, Map<String, int>> baselines = {};
  final Set<String> talked = {};
  final Set<String> inventory = {};

  Map<String, dynamic>? quest(String id) => quests[id] as Map<String, dynamic>?;

  /// Whether a character with these [flags], [gold] and [alignmentLabel] may
  /// take [questId] on (the game's own checks: not taken or done, its
  /// required flags and gold, its alignment).
  bool canTake(String questId,
      {required Set<String> flags,
      required int gold,
      required String alignmentLabel}) {
    final q = quest(questId);
    if (q == null || active.contains(questId) || completed.contains(questId)) {
      return false;
    }
    if (((q['requiredFlags'] as List?) ?? const [])
        .any((f) => !flags.contains(f.toString()))) {
      return false;
    }
    if (((q['requiredGold'] as num?)?.toInt() ?? 0) > gold) return false;
    return SubNodeEngine.questMeetsAlignment(q, alignmentLabel);
  }

  /// Takes [questId] on if the character qualifies. A bounty counts the
  /// kills made after: [killsBefore] when the offer came with the fight
  /// that offers it, else the kills so far.
  bool accept(String questId,
      {required int step,
      required Set<String> flags,
      required int gold,
      required String alignmentLabel,
      Map<String, int>? killsBefore}) {
    if (!canTake(questId,
        flags: flags, gold: gold, alignmentLabel: alignmentLabel)) {
      return false;
    }
    final base = killsBefore ?? kills;
    baselines[questId] = {
      for (final objective in (quest(questId)!['objectives'] as List? ?? []))
        if (objective is Map<String, dynamic> &&
            objective['type'] == 'Kill' &&
            objective['countFromAccept'] == true)
          for (final id in killTargetsOf(objective)) id: base[id] ?? 0,
    };
    active.add(questId);
    records[questId] = SimQuestRecord(questId, acceptedAtStep: step);
    return true;
  }

  void recordKills(Iterable<String> enemyIds) {
    for (final id in enemyIds) {
      kills[id] = (kills[id] ?? 0) + 1;
    }
  }

  /// The player talks to every person an active quest asks to see, once the
  /// story has reached their chapter.
  void talkToAvailable(int chapter) {
    for (final id in active) {
      for (final objective in (quest(id)!['objectives'] as List? ?? [])) {
        if (objective is! Map<String, dynamic> || objective['type'] != 'Talk') {
          continue;
        }
        final npcId = objective['targetNPCID']?.toString() ?? '';
        if (npcId.isEmpty) continue;
        final npc = npcs[npcId];
        final from = npc is Map ? (npc['chapter'] as num?)?.toInt() ?? 1 : 1;
        if (from <= chapter) talked.add(npcId);
      }
    }
  }

  PlayerSession _session(Set<String> flags) => PlayerSession.fromJson({
        'flags': flags.toList(),
        'enemyKillCounts': kills,
        'questKillBaselines': baselines,
        'inventoryItemIds': inventory.toList(),
        'talkedToNpcIds': talked.toList(),
      });

  /// The active quests whose objectives are all met.
  List<String> ready(Set<String> flags) {
    if (active.isEmpty) return const [];
    final session = _session(flags);
    return [
      for (final id in active)
        if (allObjectivesMet(id, quest(id)!, session)) id,
    ];
  }

  /// The story flags an active quest is waiting on, and the foes it still
  /// wants killed: what a thorough player steers towards.
  ({Set<String> flags, Set<String> foes}) wanted(Set<String> flags) {
    final wantedFlags = <String>{}, wantedFoes = <String>{};
    if (active.isEmpty) return (flags: wantedFlags, foes: wantedFoes);
    final session = _session(flags);
    for (final id in active) {
      final objectives = (quest(id)!['objectives'] as List?) ?? const [];
      final statuses = objectiveStatusesFor(id, quest(id)!, session);
      for (var i = 0; i < objectives.length; i++) {
        final objective = objectives[i];
        if (statuses[i].met || objective is! Map<String, dynamic>) continue;
        if (objective['type'] == 'Flag') {
          wantedFlags.add(objective['targetFlag']?.toString() ?? '');
        } else if (objective['type'] == 'Kill') {
          wantedFoes.addAll(killTargetsOf(objective));
        }
      }
    }
    return (flags: wantedFlags, foes: wantedFoes);
  }

  /// What is still undone on each active quest: the type and description of
  /// every objective not met.
  Map<String, List<String>> unmet(Set<String> flags) {
    final session = _session(flags);
    return {
      for (final id in active)
        id: [
          for (final (i, status)
              in objectiveStatusesFor(id, quest(id)!, session).indexed)
            if (!status.met)
              '${((quest(id)!['objectives'] as List)[i] as Map)['type']}: '
                  '${status.description}',
        ],
    };
  }

  /// Hands [questId] in: it leaves the active list, and the payout (the
  /// quest's own, or the turn-in choice the [bias] picks) is returned.
  /// The choice is the one paying the most good (good), the most evil
  /// (evil) or the most gold (gold, the first on a tie), else one at
  /// random; its politics come with the payout for the caller to apply
  /// (v1.463, as quest_turn_in.dart does in the app).
  SimQuestPayout complete(String questId,
      {required int step,
      required SimTurnInBias bias,
      required Random random}) {
    final q = quest(questId)!;
    active.remove(questId);
    completed.add(questId);
    baselines.remove(questId);
    final gold0 = (q['rewardGold'] as num?)?.toInt() ?? 0;
    final align0 = (q['alignmentChange'] as num?)?.toInt() ?? 0;
    final choices = turnInChoicesOf(q);
    TurnInChoice? picked;
    if (choices.isNotEmpty) {
      picked = switch (bias) {
        SimTurnInBias.good => choices.reduce(
            (a, b) => b.alignmentFor(align0) > a.alignmentFor(align0) ? b : a),
        SimTurnInBias.evil => choices.reduce(
            (a, b) => b.alignmentFor(align0) < a.alignmentFor(align0) ? b : a),
        SimTurnInBias.gold =>
          choices.reduce((a, b) => b.goldFor(gold0) > a.goldFor(gold0) ? b : a),
        SimTurnInBias.any => choices[random.nextInt(choices.length)],
      };
    }
    final payout = SimQuestPayout(
      questId: questId,
      name: q['questName']?.toString() ?? questId,
      gold: picked?.goldFor(gold0) ?? gold0,
      xp: (q['rewardXP'] as num?)?.toInt() ?? 0,
      alignment: picked?.alignmentFor(align0) ?? align0,
      itemId: q['rewardItemID']?.toString() ?? '',
      flag: picked?.flag ?? '',
      nextQuestId: q['nextQuestID']?.toString() ?? '',
      turnIn: picked?.text ?? '',
      politics: picked != null && picked.hasPolitics ? picked.politics : null,
      politicsKey: picked == null
          ? ''
          : questTurnInPoliticsKey(questId, choices.indexOf(picked)),
    );
    records[questId]
      ?..completedAtStep = step
      ..gold = payout.gold
      ..xp = payout.xp
      ..itemId = payout.itemId
      ..turnIn = payout.turnIn;
    if (payout.itemId.isNotEmpty) inventory.add(payout.itemId);
    return payout;
  }
}
