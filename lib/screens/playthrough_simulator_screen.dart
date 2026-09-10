import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/story_repository.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/story_providers.dart';

class _SimResult {
  const _SimResult({
    required this.path,
    required this.finalGold,
    required this.finalAlignment,
    required this.flags,
    required this.shopsDiscovered,
    required this.questsDiscovered,
    required this.combatEncounters,
    required this.endingText,
    required this.reachedStepCap,
  });

  final List<String> path;
  final int finalGold;
  final int finalAlignment;
  final Set<String> flags;
  final Set<String> shopsDiscovered;
  final Set<String> questsDiscovered;
  final int combatEncounters;
  final String endingText;
  final bool reachedStepCap;
}

/// Auto-plays the story graph making valid (non-locked, given the simulated
/// state) random choices until an ending is reached, for QA / previewing a
/// full run without clicking through it by hand. This is a read-only
/// simulation over a local gold/alignment/flags model — it never touches
/// the real player's saved session.
_SimResult _simulate(StoryData story, Random random, {int maxSteps = 200}) {
  var currentId = StoryRepository.startNodeId;
  var gold = 0;
  var alignment = 0;
  final flags = <String>{};
  final shops = <String>{};
  final quests = <String>{};
  var combatCount = 0;
  final path = <String>[];

  for (var step = 0; step < maxSteps; step++) {
    final node = story.nodeFor(currentId);
    if (node == null) {
      return _SimResult(
        path: path,
        finalGold: gold,
        finalAlignment: alignment,
        flags: flags,
        shopsDiscovered: shops,
        questsDiscovered: quests,
        combatEncounters: combatCount,
        endingText: 'Broken link: node $currentId does not exist.',
        reachedStepCap: false,
      );
    }
    path.add(currentId);

    if (node.choices.isEmpty) {
      return _SimResult(
        path: path,
        finalGold: gold,
        finalAlignment: alignment,
        flags: flags,
        shopsDiscovered: shops,
        questsDiscovered: quests,
        combatEncounters: combatCount,
        endingText: node.description,
        reachedStepCap: false,
      );
    }

    bool meetsTarget(StoryChoice c) {
      if (c.isEnding) return true;
      final target = story.nodeFor(c.nextId);
      if (target == null || !target.hasRequirements) return true;
      if (gold < target.reqGold) return false;
      if (target.reqAlignmentScore != null && alignment < target.reqAlignmentScore!) return false;
      if (target.reqAlignmentMax != null && alignment > target.reqAlignmentMax!) return false;
      return target.reqFlags.every(flags.contains);
    }

    final available = node.choices.where(meetsTarget).toList();
    final pool = available.isNotEmpty ? available : node.choices;
    final choice = pool[random.nextInt(pool.length)];

    gold = (gold + choice.goldMod).clamp(0, 1 << 30).toInt();
    alignment += choice.alignmentMod;
    flags.addAll(choice.flagsToAdd);
    if ((choice.unlockShopId ?? '').isNotEmpty) shops.add(choice.unlockShopId!);
    if ((choice.unlockQuestId ?? '').isNotEmpty) quests.add(choice.unlockQuestId!);
    if (choice.triggersCombat) combatCount++;

    if (choice.isEnding) {
      return _SimResult(
        path: path,
        finalGold: gold,
        finalAlignment: alignment,
        flags: flags,
        shopsDiscovered: shops,
        questsDiscovered: quests,
        combatEncounters: combatCount,
        endingText: choice.text,
        reachedStepCap: false,
      );
    }
    currentId = choice.nextId;
  }

  return _SimResult(
    path: path,
    finalGold: gold,
    finalAlignment: alignment,
    flags: flags,
    shopsDiscovered: shops,
    questsDiscovered: quests,
    combatEncounters: combatCount,
    endingText: '',
    reachedStepCap: true,
  );
}

class PlaythroughSimulatorScreen extends ConsumerStatefulWidget {
  const PlaythroughSimulatorScreen({super.key});

  @override
  ConsumerState<PlaythroughSimulatorScreen> createState() => _PlaythroughSimulatorScreenState();
}

class _PlaythroughSimulatorScreenState extends ConsumerState<PlaythroughSimulatorScreen> {
  bool _running = false;
  _SimResult? _result;

  Future<void> _run() async {
    setState(() {
      _running = true;
      _result = null;
    });
    final story = await ref.read(storyDataProvider.future);
    final result = _simulate(story, Random());
    if (!mounted) return;
    setState(() {
      _running = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: Text(tr(ref, 'auto_playthrough_button'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _running ? null : _run,
              icon: _running
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_circle_outline),
              label: Text(_running ? tr(ref, 'simulating_label') : tr(ref, 'auto_playthrough_button')),
            ),
            const SizedBox(height: 16),
            if (result != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr(ref, 'playthrough_recap_title'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            result.reachedStepCap
                                ? '${tr(ref, 'ending_reached_label')}: —'
                                : '${tr(ref, 'ending_reached_label')}: ${result.endingText}',
                          ),
                          const SizedBox(height: 8),
                          Text('${tr(ref, 'nodes_visited_label')}: ${result.path.length}'),
                          Text('${tr(ref, 'final_gold_label')}: ${result.finalGold}'),
                          Text('${tr(ref, 'final_alignment_label')}: ${result.finalAlignment}'),
                          Text(
                            '${tr(ref, 'shops_discovered_label')}: ${result.shopsDiscovered.length}',
                          ),
                          Text(
                            '${tr(ref, 'quests_discovered_label')}: ${result.questsDiscovered.length}',
                          ),
                          Text(
                            '${tr(ref, 'combat_encounters_label')}: ${result.combatEncounters}',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tr(ref, 'path_summary_label'),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.path.join(' → '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
