import 'dart:collection';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../combat/combat_engine.dart';
import '../models/ally_state.dart' show equipmentBonusFor;
import '../models/story_node.dart';
import '../providers/player_session_provider.dart';
import '../providers/story_providers.dart';
import 'story_repository.dart';

/// How an [autoplayToNode] run ended.
enum AutoplayStatus { reachedTarget, alreadyThere, noPathFound, stuckInCombat }

class AutoplayResult {
  const AutoplayResult({
    required this.status,
    required this.stepsApplied,
    this.stuckEnemyName,
  });

  final AutoplayStatus status;

  /// How many choice-steps were actually applied before stopping — nonzero
  /// even on [AutoplayStatus.stuckInCombat], since everything earned before
  /// the fight it couldn't clear is still real, persisted progress.
  final int stepsApplied;

  /// Set only for [AutoplayStatus.stuckInCombat] — the enemy the simulated
  /// player couldn't beat after every retry.
  final String? stuckEnemyName;
}

/// The shortest forward path of (nodeId the choice starts from, the choice
/// itself) hops from [fromNodeId] to [toNodeId], following every non-ending
/// choice edge in the whole graph — unlike the map's own layout BFS
/// (`chapter_grid_layout.dart`), this isn't restricted to same-chapter
/// edges, since autoplay needs to be able to cross chapter boundaries.
/// Returns null if [toNodeId] isn't reachable going forward from here (the
/// player may already be past it, or it may be genuinely unreachable).
List<MapEntry<String, StoryChoice>>? _findChoicePath(
  StoryData story, {
  required String fromNodeId,
  required String toNodeId,
}) {
  if (fromNodeId == toNodeId) return const [];
  final cameFrom = <String, MapEntry<String, StoryChoice>>{};
  final visited = <String>{fromNodeId};
  final queue = Queue<String>()..add(fromNodeId);
  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    final node = story.nodeFor(current);
    if (node == null) continue;
    for (final choice in node.choices) {
      if (choice.isEnding) continue;
      final nextId = choice.nextId;
      if (!story.nodes.containsKey(nextId) || visited.contains(nextId))
        continue;
      visited.add(nextId);
      cameFrom[nextId] = MapEntry(current, choice);
      if (nextId == toNodeId) {
        final path = <MapEntry<String, StoryChoice>>[];
        var id = toNodeId;
        while (cameFrom.containsKey(id)) {
          final entry = cameFrom[id]!;
          path.add(MapEntry(entry.key, entry.value));
          id = entry.key;
        }
        return path.reversed.toList();
      }
      queue.add(nextId);
    }
  }
  return null;
}

/// Plays out one simulated fight against [enemy] for the player alone (an
/// active ally's presence doesn't change this — a testing-tool
/// simplification, not something a real fight would do), using the exact
/// same combat_engine.dart functions and scaling a live fight uses: the
/// player's equipped die, one rolled face per turn (no reroll-up-to-3 —
/// another deliberate simplification, since autoplay isn't trying to model
/// optimal play), and the enemy's own skill moves. Returns true and applies
/// the real win rewards via [PlayerSessionNotifier.applyCombatResult] the
/// moment the player wins; returns false without touching session state at
/// all on a loss, so the caller can just retry — mirroring how a real lost
/// fight doesn't persist anything either (full-heal-on-loss is a no-op to
/// skip replicating here).
Future<bool> _simulateFight({
  required WidgetRef ref,
  required Map<String, dynamic> enemy,
  required Map<String, dynamic> dice,
  required Map<String, dynamic> skills,
  required Map<String, dynamic> items,
  required Random random,
}) async {
  final session = ref.read(playerSessionProvider);
  final diceFaces = (dice[session.equippedDiceId]?['faces'] as List?)
          ?.cast<Map<String, dynamic>>() ??
      const [];
  if (diceFaces.isEmpty) return false;

  final playerDamage = session.baseDamage +
      equipmentBonusFor(session.equippedItemIds, items, 'attackDamage');
  final playerArmor = session.baseArmor +
      equipmentBonusFor(session.equippedItemIds, items, 'armor');
  final assignments = session.diceSkillAssignments[session.equippedDiceId] ??
      const <String, String>{};

  var enemyHealth = scaledMaxHealth(
      (enemy['maxHealth'] as num?)?.toInt() ?? 1, session.level);
  final enemyMaxHealth = enemyHealth;
  final enemyDamage =
      scaledDamage((enemy['damage'] as num?)?.toInt() ?? 0, session.level);
  var playerHealth =
      session.currentHealth > 0 ? session.currentHealth : session.maxHealth;

  // A real fight can't run forever either (the player or the enemy always
  // eventually hits 0); this is just a safety valve against a pathological
  // stat combination stalemating the loop.
  for (var turn = 0; turn < 60; turn++) {
    var face = rollDie(diceFaces, random);
    if (face.type == 'Skill') {
      final assigned = assignments[face.faceIndex.toString()];
      if (assigned != null && assigned.isNotEmpty) {
        face = face.withLinkedSkillID(assigned);
      }
    }
    final result = resolvePlayerFace(face, skills, playerDamage);
    enemyHealth = max(0, enemyHealth - result.damageDealt);
    playerHealth = min(session.maxHealth, playerHealth + result.healingDone);
    if (enemyHealth <= 0) break;

    final move = resolveEnemyMove(
      enemy: {...enemy, 'damage': enemyDamage},
      skills: skills,
      enemyCurrentHealth: enemyHealth,
      enemyMaxHealth: enemyMaxHealth,
      random: random,
    );
    final damageTaken = max(0, move.damage - result.blockAmount - playerArmor);
    playerHealth = max(0, playerHealth - damageTaken);
    if (playerHealth <= 0) return false;
  }
  if (enemyHealth > 0) return false;

  final goldGain =
      scaledReward((enemy['goldReward'] as num?)?.toInt() ?? 0, session.level);
  final xpGain =
      scaledReward((enemy['xpReward'] as num?)?.toInt() ?? 0, session.level);
  final loot = <String>[];
  final lootTable =
      (enemy['lootTable'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  for (final entry in lootTable) {
    final dropRate = (entry['dropRate'] as num?)?.toDouble() ?? 0;
    if (random.nextDouble() * 100 <= dropRate) {
      final itemId = entry['itemID']?.toString();
      if (itemId != null && itemId.isNotEmpty) loot.add(itemId);
    }
  }
  await ref.read(playerSessionProvider.notifier).applyCombatResult(
        hpAfter: playerHealth,
        goldGain: goldGain,
        xpGain: xpGain,
        itemsGained: loot,
      );
  return true;
}

/// Walks the shortest choice-path from the player's current story position
/// to [targetNodeId], applying each step's real effects — gold/alignment/
/// heal/flags/quest-progress, shop/quest unlocks, achievement checks, and a
/// genuine simulated combat for any triggered fight — via the exact same
/// [PlayerSessionNotifier] methods a live choice tap calls (see
/// `_ChoiceButton` in story_player_screen.dart). Deliberately skips
/// procedural excursions (`SubNodeEngine`) for determinism: this is a
/// testing tool for reaching a target with a real earned state quickly, not
/// a faithful re-play of everything a human could have seen along the way.
Future<AutoplayResult> autoplayToNode(
  WidgetRef ref, {
  required StoryData story,
  required String targetNodeId,
  required Map<String, dynamic> dice,
  required Map<String, dynamic> skills,
  required Map<String, dynamic> items,
  required Map<String, dynamic> enemies,
  int maxCombatRetries = 8,
}) async {
  final playState = ref.read(storyPlayProvider);
  if (playState.currentNodeId == targetNodeId) {
    return const AutoplayResult(
        status: AutoplayStatus.alreadyThere, stepsApplied: 0);
  }
  final path = _findChoicePath(story,
      fromNodeId: playState.currentNodeId, toNodeId: targetNodeId);
  if (path == null) {
    return const AutoplayResult(
        status: AutoplayStatus.noPathFound, stepsApplied: 0);
  }

  final sessionNotifier = ref.read(playerSessionProvider.notifier);
  final playNotifier = ref.read(storyPlayProvider.notifier);
  final random = Random();
  var stepsApplied = 0;

  for (final step in path) {
    final fromNodeId = step.key;
    final choice = step.value;

    if (choice.triggersCombat) {
      final enemy = enemies[choice.triggerEnemyId] as Map<String, dynamic>?;
      if (enemy != null) {
        var won = false;
        for (var attempt = 0; attempt < maxCombatRetries && !won; attempt++) {
          won = await _simulateFight(
            ref: ref,
            enemy: enemy,
            dice: dice,
            skills: skills,
            items: items,
            random: random,
          );
        }
        if (!won) {
          return AutoplayResult(
            status: AutoplayStatus.stuckInCombat,
            stepsApplied: stepsApplied,
            stuckEnemyName:
                enemy['enemyName']?.toString() ?? choice.triggerEnemyId,
          );
        }
      }
    }

    if (choice.hasEffects) {
      await sessionNotifier.applyChoiceEffects(
        goldMod: choice.goldMod,
        alignmentMod: choice.alignmentMod,
        healAmount: choice.healAmount,
        flagsToAdd: choice.flagsToAdd,
        questIDToProgress: choice.questIDToProgress,
      );
    }
    if (choice.hasUnlocks) {
      await sessionNotifier.unlockContent(
        shopId: choice.unlockShopId,
        questId: choice.unlockQuestId,
        enemyId: choice.triggerEnemyId,
        shopUnlockNodeId: fromNodeId,
      );
      if ((choice.unlockShopId ?? '').isNotEmpty) {
        await sessionNotifier.checkAchievements();
      }
    }

    playNotifier.choose(choice.nextId);
    stepsApplied += 1;
  }

  return AutoplayResult(
      status: AutoplayStatus.reachedTarget, stepsApplied: stepsApplied);
}
