import '../data/chapter_spine.dart';
import '../data/story_repository.dart';
import '../models/story_node.dart';

/// Cross-checks the story graph against skills/shops/enemies data for
/// reachability and balance problems the game-database editor can't catch
/// on its own: mandatory fights a player could hit without ever having had
/// a chance to visit a shop first in that chapter, skill prerequisite
/// chains that can never be completed, and story requirements that can
/// never be satisfied by anything in the story.
///
/// This only reasons about the authored story graph (StoryData.nodes) —
/// the procedural excursions SubNodeEngine inserts at runtime are random,
/// not guaranteed, so they're deliberately excluded: a shop that only
/// *might* appear doesn't count as a real opportunity to gear up.
List<String> validateBalance({
  required StoryData story,
  required Map<String, dynamic> skills,
  required Map<String, dynamic> shops,
  required Map<String, dynamic> enemies,
}) {
  return [
    ..._validateMandatoryCombat(story),
    ..._validateSkillChains(skills),
    ..._validateUnreachableFlags(story),
    ..._validateDanglingReferences(story, shops, enemies),
  ];
}

/// For each pair of consecutive main beats within a chapter, finds combat
/// choices that are unavoidable (removing that single choice would cut off
/// the next beat from the previous one) and flags any such fight that has
/// no shop-unlock choice anywhere on the paths leading up to it.
///
/// The search is bounded to nodes that belong to this chapter or to no
/// chapter at all (side/excursion content) — without that bound, the story
/// graph's cross-chapter convergence points (multiple chapters eventually
/// funnel through shared later nodes) make almost every node "reachable"
/// from almost every other, which would make a bridge-edge check useless.
List<String> _validateMandatoryCombat(StoryData story) {
  final issues = <String>[];

  final forward = <String, List<StoryChoice>>{};
  final reverse = <String, List<String>>{};
  for (final entry in story.nodes.entries) {
    for (final choice in entry.value.choices) {
      if (choice.isEnding) continue;
      if (!story.nodes.containsKey(choice.nextId)) continue;
      forward.putIfAbsent(entry.key, () => []).add(choice);
      reverse.putIfAbsent(choice.nextId, () => []).add(entry.key);
    }
  }

  Set<String> bfsForward(Set<String> starts, Set<String> allowed,
      {StoryChoice? excludeChoice}) {
    final visited = <String>{...starts};
    final queue = [...starts];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final choice in forward[current] ?? const <StoryChoice>[]) {
        if (identical(choice, excludeChoice)) continue;
        if (!allowed.contains(choice.nextId)) continue;
        if (visited.add(choice.nextId)) queue.add(choice.nextId);
      }
    }
    return visited;
  }

  Set<String> bfsBackward(Set<String> starts, Set<String> allowed) {
    final visited = <String>{...starts};
    final queue = [...starts];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final from in reverse[current] ?? const <String>[]) {
        if (!allowed.contains(from)) continue;
        if (visited.add(from)) queue.add(from);
      }
    }
    return visited;
  }

  for (final spine in chapterSpines) {
    final allowed = story.nodes.keys
        .where((id) =>
            chapterForNode(id) == null || chapterForNode(id) == spine.chapter)
        .toSet();

    for (var i = 0; i < spine.beats.length - 1; i++) {
      final beatFrom = spine.beats[i];
      final beatTo = spine.beats[i + 1];
      final reachable = bfsForward(beatFrom, allowed);

      for (final nodeId in reachable) {
        if (beatTo.contains(nodeId)) continue;
        final node = story.nodeFor(nodeId);
        if (node == null) continue;

        for (final choice in node.choices) {
          if (!choice.triggersCombat) continue;
          if (!allowed.contains(choice.nextId)) continue;

          final withoutThisFight =
              bfsForward(beatFrom, allowed, excludeChoice: choice);
          final stillReachesNextBeat = beatTo.any(withoutThisFight.contains);
          if (stillReachesNextBeat) {
            continue; // there's another route — avoidable
          }

          final ancestors =
              reachable.intersection(bfsBackward({nodeId}, allowed));
          final hasShopOpportunity = ancestors.any((id) {
            final ancestor = story.nodeFor(id);
            if (ancestor == null) return false;
            return ancestor.choices
                .any((c) => (c.unlockShopId ?? '').isNotEmpty);
          });

          if (!hasShopOpportunity) {
            issues.add(
              'Chapter ${spine.chapter} (beat ${i + 1} → ${i + 2}): node $nodeId forces '
              'combat with "${choice.triggerEnemyId}" with no shop visit possible first.',
            );
          }
        }
      }
    }
  }

  return issues;
}

/// Flags skills whose `requiredSkillID` points at a skill that doesn't
/// exist, forms a cycle (so neither skill can ever be unlocked), or is
/// race/profession-restricted while the dependent skill itself claims to
/// have no restriction (so it's secretly gated too).
List<String> _validateSkillChains(Map<String, dynamic> skills) {
  final issues = <String>[];

  for (final entry in skills.entries) {
    final skill = entry.value as Map<String, dynamic>;
    final requiredId = skill['requiredSkillID']?.toString() ?? '';
    if (requiredId.isNotEmpty && !skills.containsKey(requiredId)) {
      issues.add(
        'Skill "${entry.key}" requires unknown skill "$requiredId" — it can never be unlocked.',
      );
    }
  }

  final reportedInCycle = <String>{};
  for (final startId in skills.keys) {
    if (reportedInCycle.contains(startId)) continue;
    final seen = <String>{};
    var current = startId;
    while (true) {
      final skill = skills[current] as Map<String, dynamic>?;
      final next = skill?['requiredSkillID']?.toString() ?? '';
      if (next.isEmpty || !skills.containsKey(next)) break;
      if (!seen.add(current)) break;
      if (next == startId) {
        issues.add(
          'Skill prerequisite cycle involving "$startId" — none of these skills can ever be unlocked.',
        );
        reportedInCycle.addAll(seen);
        break;
      }
      current = next;
    }
  }

  for (final entry in skills.entries) {
    final skill = entry.value as Map<String, dynamic>;
    final requiredId = skill['requiredSkillID']?.toString() ?? '';
    if (requiredId.isEmpty || !skills.containsKey(requiredId)) continue;
    final ownRace = skill['restrictedRaceID']?.toString() ?? '';
    final ownProfession = skill['restrictedProfessionID']?.toString() ?? '';
    final required = skills[requiredId] as Map<String, dynamic>;
    final reqRace = required['restrictedRaceID']?.toString() ?? '';
    final reqProfession = required['restrictedProfessionID']?.toString() ?? '';
    final leaksRace = reqRace.isNotEmpty && reqRace != ownRace;
    final leaksProfession =
        reqProfession.isNotEmpty && reqProfession != ownProfession;
    if (leaksRace || leaksProfession) {
      issues.add(
        'Skill "${entry.key}" has no restriction of its own, but requires "$requiredId" '
        'which is restricted — so it is secretly only reachable by that same race/profession.',
      );
    }
  }

  return issues;
}

/// Flags any node whose `reqFlags` names a flag that no choice in the
/// entire story ever adds — such a node can never be reached.
List<String> _validateUnreachableFlags(StoryData story) {
  final everSetFlags = <String>{};
  for (final node in story.nodes.values) {
    for (final choice in node.choices) {
      everSetFlags.addAll(choice.flagsToAdd);
    }
  }

  final issues = <String>[];
  for (final node in story.nodes.values) {
    for (final flag in node.reqFlags) {
      if (!everSetFlags.contains(flag)) {
        issues.add(
          'Node ${node.id} requires flag "$flag", which no choice in the story ever sets '
          '— this node can never be reached.',
        );
      }
    }
  }
  return issues;
}

/// Flags story choices that trigger combat or unlock a shop that doesn't
/// exist in the enemies/shops data.
List<String> _validateDanglingReferences(
  StoryData story,
  Map<String, dynamic> shops,
  Map<String, dynamic> enemies,
) {
  final issues = <String>[];
  for (final node in story.nodes.values) {
    for (final choice in node.choices) {
      final enemyId = choice.triggerEnemyId;
      if (enemyId != null &&
          enemyId.isNotEmpty &&
          !enemies.containsKey(enemyId)) {
        issues.add('Node ${node.id} triggers unknown enemy "$enemyId".');
      }
      final shopId = choice.unlockShopId;
      if (shopId != null && shopId.isNotEmpty && !shops.containsKey(shopId)) {
        issues.add('Node ${node.id} unlocks unknown shop "$shopId".');
      }
    }
  }
  return issues;
}
