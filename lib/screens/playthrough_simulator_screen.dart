import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chapter_spine.dart';
import '../data/story_repository.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/game_db_providers.dart';
import '../providers/story_providers.dart';

/// How the simulator picks among a node's valid (non-locked) choices. Lets
/// the user compare "what if the player always chased gold" against "what
/// if they always leaned good/evil" instead of only pure-random runs.
enum SimStrategy { random, favorGood, favorEvil, maximizeGold }

String _strategyLabelKey(SimStrategy strategy) {
  switch (strategy) {
    case SimStrategy.random:
      return 'sim_strategy_random';
    case SimStrategy.favorGood:
      return 'sim_strategy_favor_good';
    case SimStrategy.favorEvil:
      return 'sim_strategy_favor_evil';
    case SimStrategy.maximizeGold:
      return 'sim_strategy_maximize_gold';
  }
}

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
    required this.furthestChapter,
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
  final int? furthestChapter;

  int get uniqueNodesVisited => path.toSet().length;

  /// A short, always-non-empty label for grouping/displaying this run's
  /// outcome, since [endingText] is blank when the step cap was hit.
  String get endingSummary {
    if (reachedStepCap) return '(did not reach an ending)';
    if (endingText.trim().isEmpty) return '(unnamed ending)';
    final oneLine = endingText.replaceAll('\n', ' ').trim();
    return oneLine.length > 80 ? '${oneLine.substring(0, 80)}…' : oneLine;
  }
}

/// Auto-plays the story graph making choices (picked per [strategy]) until
/// an ending is reached, for QA / previewing a full run without clicking
/// through it by hand. This is a read-only simulation over a local
/// gold/alignment/flags model — it never touches the real player's saved
/// session.
_SimResult _simulate(
  StoryData story,
  Random random, {
  SimStrategy strategy = SimStrategy.random,
  int maxSteps = 200,
}) {
  var currentId = StoryRepository.startNodeId;
  var gold = 0;
  var alignment = 0;
  final flags = <String>{};
  final shops = <String>{};
  final quests = <String>{};
  var combatCount = 0;
  var furthestChapter = chapterForNode(currentId);
  final path = <String>[];

  StoryChoice pickChoice(List<StoryChoice> pool) {
    if (strategy == SimStrategy.random || pool.length == 1) {
      return pool[random.nextInt(pool.length)];
    }
    int score(StoryChoice c) {
      switch (strategy) {
        case SimStrategy.favorGood:
          return c.alignmentMod;
        case SimStrategy.favorEvil:
          return -c.alignmentMod;
        case SimStrategy.maximizeGold:
          return c.goldMod;
        case SimStrategy.random:
          return 0;
      }
    }

    final best = pool.map(score).reduce(max);
    final tied = pool.where((c) => score(c) == best).toList();
    return tied[random.nextInt(tied.length)];
  }

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
        furthestChapter: furthestChapter,
      );
    }
    path.add(currentId);
    furthestChapter = max(furthestChapter ?? 0, chapterForNode(currentId) ?? 0);
    if (furthestChapter == 0) furthestChapter = null;

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
        furthestChapter: furthestChapter,
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
    final choice = pickChoice(pool);

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
        furthestChapter: furthestChapter,
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
    furthestChapter: furthestChapter,
  );
}

/// One "Run" button press worth of simulations — 1 to N runs, all using the
/// same [strategy], kept together so different batches can be compared.
class _SimBatch {
  _SimBatch({required this.strategy, required this.results});

  final SimStrategy strategy;
  final List<_SimResult> results;

  int get runCount => results.length;
  double get avgGold => results.map((r) => r.finalGold).reduce((a, b) => a + b) / runCount;
  double get avgAlignment =>
      results.map((r) => r.finalAlignment).reduce((a, b) => a + b) / runCount;
  double get avgSteps => results.map((r) => r.path.length).reduce((a, b) => a + b) / runCount;
  double get avgCombat =>
      results.map((r) => r.combatEncounters).reduce((a, b) => a + b) / runCount;
  int get stepCapCount => results.where((r) => r.reachedStepCap).length;

  /// Ending summary -> how many of this batch's runs landed there, most
  /// common first.
  Map<String, int> get endingCounts {
    final counts = <String, int>{};
    for (final r in results) {
      counts[r.endingSummary] = (counts[r.endingSummary] ?? 0) + 1;
    }
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }
}

class PlaythroughSimulatorScreen extends ConsumerStatefulWidget {
  const PlaythroughSimulatorScreen({super.key});

  @override
  ConsumerState<PlaythroughSimulatorScreen> createState() => _PlaythroughSimulatorScreenState();
}

class _PlaythroughSimulatorScreenState extends ConsumerState<PlaythroughSimulatorScreen> {
  bool _running = false;
  SimStrategy _strategy = SimStrategy.random;
  int _runCount = 1;
  final List<_SimBatch> _batches = [];

  Future<void> _run() async {
    setState(() => _running = true);
    final story = await ref.read(storyDataProvider.future);
    final random = Random();
    final results = [
      for (var i = 0; i < _runCount; i++) _simulate(story, random, strategy: _strategy),
    ];
    if (!mounted) return;
    setState(() {
      _running = false;
      _batches.add(_SimBatch(strategy: _strategy, results: results));
    });
  }

  @override
  Widget build(BuildContext context) {
    final shops = ref.watch(gameDbProvider(shopsSchema)).value ?? const {};
    final quests = ref.watch(gameDbProvider(questsSchema)).value ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'auto_playthrough_button')),
        actions: [
          if (_batches.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: tr(ref, 'clear_all_button'),
              onPressed: () => setState(_batches.clear),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr(ref, 'strategy_label'), style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SimStrategy.values.map((strategy) {
                return ChoiceChip(
                  label: Text(tr(ref, _strategyLabelKey(strategy))),
                  selected: _strategy == strategy,
                  onSelected: (_) => setState(() => _strategy = strategy),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(tr(ref, 'runs_label'), style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [1, 5, 10, 20].map((count) {
                return ChoiceChip(
                  label: Text('$count'),
                  selected: _runCount == count,
                  onSelected: (_) => setState(() => _runCount = count),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
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
            Expanded(
              child: _batches.isEmpty
                  ? Center(child: Text(tr(ref, 'no_batches_yet_message')))
                  : ListView(
                      children: [
                        for (final batch in _batches.reversed)
                          _BatchCard(batch: batch, shops: shops, quests: quests),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BatchCard extends ConsumerWidget {
  const _BatchCard({required this.batch, required this.shops, required this.quests});

  final _SimBatch batch;
  final Map<String, dynamic> shops;
  final Map<String, dynamic> quests;

  String _oneDecimal(double v) => v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final single = batch.runCount == 1 ? batch.results.single : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${tr(ref, _strategyLabelKey(batch.strategy))} × ${batch.runCount}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text('${tr(ref, 'nodes_visited_label')}: ${_oneDecimal(batch.avgSteps)}'),
            Text('${tr(ref, 'final_gold_label')}: ${_oneDecimal(batch.avgGold)}'),
            Text('${tr(ref, 'final_alignment_label')}: ${_oneDecimal(batch.avgAlignment)}'),
            Text('${tr(ref, 'combat_encounters_label')}: ${_oneDecimal(batch.avgCombat)}'),
            if (batch.stepCapCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${batch.stepCapCount}/${batch.runCount} ${tr(ref, 'exceeded_step_cap_label')}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 12),
            Text(tr(ref, 'endings_label'), style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final entry in batch.endingCounts.entries)
              Text(
                '${entry.value}× ${entry.key}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (single != null) ...[
              const Divider(height: 24),
              _SingleRunDetail(result: single, shops: shops, quests: quests),
            ] else ...[
              const Divider(height: 24),
              Text(tr(ref, 'individual_runs_label'), style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              for (var i = 0; i < batch.results.length; i++)
                Text(
                  '#${i + 1}: ${batch.results[i].finalGold}g, '
                  '${tr(ref, 'final_alignment_label')} ${batch.results[i].finalAlignment}, '
                  '${batch.results[i].path.length} ${tr(ref, 'nodes_visited_label')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SingleRunDetail extends ConsumerWidget {
  const _SingleRunDetail({required this.result, required this.shops, required this.quests});

  final _SimResult result;
  final Map<String, dynamic> shops;
  final Map<String, dynamic> quests;

  String _namesFor(Set<String> ids, Map<String, dynamic> records, String nameField) {
    if (ids.isEmpty) return '—';
    return ids
        .map((id) => (records[id] as Map<String, dynamic>?)?[nameField]?.toString() ?? id)
        .join(', ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(ref, 'playthrough_recap_title'),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text('${tr(ref, 'ending_reached_label')}: ${result.endingSummary}'),
        if (result.furthestChapter != null)
          Text('${tr(ref, 'furthest_chapter_label')}: ${result.furthestChapter}'),
        Text(
          '${tr(ref, 'unique_nodes_visited_label')}: ${result.uniqueNodesVisited} '
          '(${result.path.length} ${tr(ref, 'total_steps_label')})',
        ),
        Text('${tr(ref, 'shops_discovered_label')}: ${_namesFor(result.shopsDiscovered, shops, 'shopName')}'),
        Text(
          '${tr(ref, 'quests_discovered_label')}: ${_namesFor(result.questsDiscovered, quests, 'questName')}',
        ),
        Text(
          '${tr(ref, 'flags_collected_label')}: ${result.flags.isEmpty ? '—' : result.flags.join(', ')}',
        ),
        const SizedBox(height: 12),
        Text(tr(ref, 'path_summary_label'), style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(result.path.join(' → '), style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
