import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../data/chapter_spine.dart';
import '../data/story_graph_integrity.dart';
import '../data/story_repository.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/game_db_providers.dart';
import '../providers/settings_providers.dart';
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

/// One node visited during a simulated run: the node itself (with the text
/// the player would actually have seen) plus the choice taken from it, so a
/// run can be rendered or exported as a readable transcript.
class _SimStep {
  const _SimStep({
    required this.nodeId,
    required this.chapter,
    required this.mood,
    required this.uiTheme,
    required this.description,
    this.choiceText,
    this.enemyId,
    this.goldMod = 0,
    this.alignmentMod = 0,
  });

  final String nodeId;

  /// The chapter this step counts toward. For a main-beat node this is
  /// [chapterForNode]'s own answer; for a side/optional node (which has no
  /// chapter of its own) it's carried forward from the most recent main
  /// beat, so side content is grouped with the chapter it actually
  /// occurred in rather than dumped in one undifferentiated bucket. Null
  /// only for steps before the first main beat.
  final int? chapter;

  final String? mood;
  final String? uiTheme;
  final String description;

  /// The choice text taken from this node, or null for a run's final step
  /// (an ending, a dead end, or a broken link — nothing left to choose).
  final String? choiceText;
  final String? enemyId;
  final int goldMod;
  final int alignmentMod;
}

class _SimResult {
  const _SimResult({
    required this.steps,
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

  final List<_SimStep> steps;
  final int finalGold;
  final int finalAlignment;
  final Set<String> flags;
  final Set<String> shopsDiscovered;
  final Set<String> questsDiscovered;
  final int combatEncounters;
  final String endingText;
  final bool reachedStepCap;
  final int? furthestChapter;

  List<String> get path => steps.map((s) => s.nodeId).toList();
  int get uniqueNodesVisited => steps.map((s) => s.nodeId).toSet().length;

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
  Map<String, dynamic> enemies = const {},
  SimStrategy strategy = SimStrategy.random,
  int maxSteps = 200,
  bool french = false,
}) {
  int combatGoldReward(StoryChoice c) {
    if (!c.triggersCombat) return 0;
    final enemy = enemies[c.triggerEnemyId] as Map<String, dynamic>?;
    return (enemy?['goldReward'] as num?)?.toInt() ?? 0;
  }

  var currentId = StoryRepository.startNodeId;
  var gold = 0;
  var alignment = 0;
  final flags = <String>{};
  final shops = <String>{};
  final quests = <String>{};
  var combatCount = 0;
  int? furthestChapter = chapterForNode(currentId);
  int? lastKnownChapter = furthestChapter;
  final steps = <_SimStep>[];

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
          return c.goldMod + combatGoldReward(c);
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
      steps.add(_SimStep(
        nodeId: currentId,
        chapter: lastKnownChapter,
        mood: null,
        uiTheme: null,
        description: 'Broken link: node $currentId does not exist.',
      ));
      return _SimResult(
        steps: steps,
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

    final mainChapter = chapterForNode(currentId);
    if (mainChapter != null) lastKnownChapter = mainChapter;
    furthestChapter = max(furthestChapter ?? 0, mainChapter ?? 0);
    if (furthestChapter == 0) furthestChapter = null;

    if (node.choices.isEmpty) {
      steps.add(_SimStep(
        nodeId: currentId,
        chapter: lastKnownChapter,
        mood: node.mood,
        uiTheme: node.uiTheme,
        description: node.descriptionFor(french),
      ));
      return _SimResult(
        steps: steps,
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

    // A won fight pays out the enemy's goldReward just like a real playthrough
    // (see FightScreen._finishFight) — folded into this step's goldMod so the
    // chapter breakdown and CSV/JSON exports stay consistent with finalGold.
    final effectiveGoldMod = choice.goldMod + combatGoldReward(choice);

    steps.add(_SimStep(
      nodeId: currentId,
      chapter: lastKnownChapter,
      mood: node.mood,
      uiTheme: node.uiTheme,
      description: node.descriptionFor(french),
      choiceText: choice.textFor(french),
      enemyId: choice.triggerEnemyId,
      goldMod: effectiveGoldMod,
      alignmentMod: choice.alignmentMod,
    ));

    gold = (gold + effectiveGoldMod).clamp(0, 1 << 30).toInt();
    alignment += choice.alignmentMod;
    flags.addAll(choice.flagsToAdd);
    if ((choice.unlockShopId ?? '').isNotEmpty) shops.add(choice.unlockShopId!);
    if ((choice.unlockQuestId ?? '').isNotEmpty) quests.add(choice.unlockQuestId!);
    if (choice.triggersCombat) combatCount++;

    if (choice.isEnding) {
      return _SimResult(
        steps: steps,
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
    steps: steps,
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

double _avg(Iterable<num> values) {
  final list = values.toList();
  if (list.isEmpty) return 0;
  return list.reduce((a, b) => a + b) / list.length;
}

Map<String, int> _endingCounts(List<_SimResult> results) {
  final counts = <String, int>{};
  for (final r in results) {
    counts[r.endingSummary] = (counts[r.endingSummary] ?? 0) + 1;
  }
  final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(entries);
}

/// A grouping bucket (a chapter, a location, or a mood) with the tallies
/// needed to summarize how a batch of runs spent their time in it.
class _GroupStat {
  _GroupStat(this.label);

  final String label;
  int nodeCount = 0;
  int combatCount = 0;
  int goldDelta = 0;
  int alignmentDelta = 0;
  int runsReaching = 0;
}

String _chapterLabel(int? chapter) => chapter == null ? 'Prologue' : 'Chapter $chapter';

/// Buckets every step of every run by the chapter it counts toward,
/// tracking node/combat counts, gold & alignment swing, and how many runs
/// reached that chapter at all — the breakdown this screen's chapter view
/// is built from.
List<_GroupStat> _chapterBreakdown(List<_SimResult> results) {
  final map = <String, _GroupStat>{};
  for (final r in results) {
    final seenThisRun = <String>{};
    for (final s in r.steps) {
      final key = _chapterLabel(s.chapter);
      final stat = map.putIfAbsent(key, () => _GroupStat(key));
      stat.nodeCount++;
      if (s.enemyId != null) stat.combatCount++;
      stat.goldDelta += s.goldMod;
      stat.alignmentDelta += s.alignmentMod;
      seenThisRun.add(key);
    }
    for (final key in seenThisRun) {
      map[key]!.runsReaching++;
    }
  }
  final keys = map.keys.toList()
    ..sort((a, b) {
      if (a == 'Prologue') return -1;
      if (b == 'Prologue') return 1;
      final na = int.tryParse(a.replaceFirst('Chapter ', '')) ?? 0;
      final nb = int.tryParse(b.replaceFirst('Chapter ', '')) ?? 0;
      return na.compareTo(nb);
    });
  return [for (final k in keys) map[k]!];
}

/// A simple node-count distribution over some per-step attribute (mood or
/// location), most-visited first — how much of the story, on average,
/// reads as "grim" vs "tense", or plays out on the "docks" vs "cathedral".
List<_GroupStat> _distributionBy(List<_SimResult> results, String? Function(_SimStep) keyOf) {
  final map = <String, _GroupStat>{};
  for (final r in results) {
    for (final s in r.steps) {
      final key = keyOf(s) ?? '(untagged)';
      map.putIfAbsent(key, () => _GroupStat(key)).nodeCount++;
    }
  }
  final entries = map.values.toList()..sort((a, b) => b.nodeCount.compareTo(a.nodeCount));
  return entries;
}

/// One "Run" button press worth of simulations — 1 to N runs, all using the
/// same [strategy], kept together so different batches can be compared.
class _SimBatch {
  _SimBatch({required this.id, required this.strategy, required this.results});

  /// Stable identity for this batch (a monotonic counter, not a list
  /// index), used as the _BatchCard's key so each card's own analysis
  /// state stays attached to the right batch as new ones are prepended.
  final int id;
  final SimStrategy strategy;
  final List<_SimResult> results;

  int get runCount => results.length;
  int get stepCapCount => results.where((r) => r.reachedStepCap).length;
}

/// Holds every completed simulation batch for the lifetime of the app
/// (i.e. as long as the ProviderScope lives), not just this screen's own
/// widget lifetime. The screen itself is reached via Navigator.push, so
/// without this a State field would reset to empty every time the player
/// backed out and reopened it. Cleared only by the screen's own "clear
/// all" action.
class _SimulatorBatchesNotifier extends StateNotifier<List<_SimBatch>> {
  _SimulatorBatchesNotifier() : super(const []);

  int _nextId = 0;

  void addBatch(SimStrategy strategy, List<_SimResult> results) {
    state = [...state, _SimBatch(id: _nextId++, strategy: strategy, results: results)];
  }

  void clear() {
    state = const [];
    _nextId = 0;
  }
}

final _simulatorBatchesProvider =
    StateNotifierProvider<_SimulatorBatchesNotifier, List<_SimBatch>>(
  (ref) => _SimulatorBatchesNotifier(),
);

class PlaythroughSimulatorScreen extends ConsumerStatefulWidget {
  const PlaythroughSimulatorScreen({super.key});

  @override
  ConsumerState<PlaythroughSimulatorScreen> createState() => _PlaythroughSimulatorScreenState();
}

class _PlaythroughSimulatorScreenState extends ConsumerState<PlaythroughSimulatorScreen> {
  bool _running = false;
  SimStrategy _strategy = SimStrategy.random;
  int _runCount = 1;

  /// Whether the strategy/runs/simulate controls are shown in full. They
  /// collapse to a compact bar the moment there's a result to look at, so
  /// results don't start halfway down a small screen — and re-expand
  /// automatically once the results list is scrolled back to the top, and
  /// collapse again the moment the user scrolls down into the results, or
  /// on a manual tap.
  bool _controlsExpanded = true;
  final ScrollController _resultsScrollController = ScrollController();
  double _lastResultsScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _resultsScrollController.addListener(_onResultsScroll);
  }

  @override
  void dispose() {
    _resultsScrollController.removeListener(_onResultsScroll);
    _resultsScrollController.dispose();
    super.dispose();
  }

  void _onResultsScroll() {
    final offset = _resultsScrollController.offset;
    if (offset <= 4) {
      if (!_controlsExpanded) setState(() => _controlsExpanded = true);
    } else if (offset > _lastResultsScrollOffset && _controlsExpanded) {
      setState(() => _controlsExpanded = false);
    }
    _lastResultsScrollOffset = offset;
  }

  Future<void> _run() async {
    setState(() => _running = true);
    final story = await ref.read(storyDataProvider.future);
    final enemies = await ref.read(gameDbRepositoryProvider(enemiesSchema)).loadRecords();
    final french = ref.read(appLanguageProvider) == AppLanguage.fr;
    final random = Random();
    final results = [
      for (var i = 0; i < _runCount; i++)
        _simulate(story, random, enemies: enemies, strategy: _strategy, french: french),
    ];
    if (!mounted) return;
    ref.read(_simulatorBatchesProvider.notifier).addBatch(_strategy, results);
    setState(() {
      _running = false;
      _controlsExpanded = false;
    });
  }

  /// Runs the exhaustive, gating-blind graph walk (see
  /// story_graph_integrity.dart) and shows what it finds — the same audit
  /// this project has otherwise relied on someone remembering to run by
  /// hand after a content pass.
  Future<void> _runStructuralAudit() async {
    final story = await ref.read(storyDataProvider.future);
    final report = checkStoryGraphIntegrity(story.nodes, startNodeId: StoryRepository.startNodeId);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          report.isClean
              ? tr(ref, 'structural_audit_clean_title')
              : tr(ref, 'structural_audit_issues_title'),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${tr(ref, 'structural_audit_endings_label')}: ${report.reachableEndingCount}'),
              if (report.unreachableNodeIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${tr(ref, 'structural_audit_unreachable_label')}: ${report.unreachableNodeIds.join(', ')}',
                ),
              ],
              if (report.deadEndNodeIds.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '${tr(ref, 'structural_audit_dead_ends_label')}: ${report.deadEndNodeIds.join(', ')}',
                ),
              ],
              if (report.brokenReferences.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${tr(ref, 'structural_audit_broken_links_label')}:'),
                for (final link in report.brokenReferences) Text('• $link'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _fullControls(BuildContext context, List<_SimBatch> batches) {
    return Column(
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
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _running ? null : _run,
                icon: _running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_outline),
                label:
                    Text(_running ? tr(ref, 'simulating_label') : tr(ref, 'auto_playthrough_button')),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.fact_check_outlined),
              tooltip: tr(ref, 'structural_audit_button'),
              onPressed: _runStructuralAudit,
            ),
            if (batches.isNotEmpty) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.expand_less),
                tooltip: tr(ref, 'hide_options_tooltip'),
                onPressed: () => setState(() => _controlsExpanded = false),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _compactControlsBar(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _controlsExpanded = true),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.tune, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${tr(ref, _strategyLabelKey(_strategy))} × $_runCount',
                  style: Theme.of(context).textTheme.titleSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: _running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.replay, size: 20),
                tooltip: tr(ref, 'auto_playthrough_button'),
                onPressed: _running ? null : _run,
              ),
              Icon(Icons.expand_more, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shops = ref.watch(gameDbProvider(shopsSchema)).value ?? const {};
    final quests = ref.watch(gameDbProvider(questsSchema)).value ?? const {};
    final batches = ref.watch(_simulatorBatchesProvider);
    final showFullControls = batches.isEmpty || _controlsExpanded;
    final reversedBatches = batches.reversed.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr(ref, 'auto_playthrough_button')),
        actions: [
          if (batches.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: tr(ref, 'clear_all_button'),
              onPressed: () {
                ref.read(_simulatorBatchesProvider.notifier).clear();
                setState(() => _controlsExpanded = true);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: showFullControls
                  ? _fullControls(context, batches)
                  : _compactControlsBar(context),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: batches.isEmpty
                  ? Center(child: Text(tr(ref, 'no_batches_yet_message')))
                  : ListView(
                      controller: _resultsScrollController,
                      children: [
                        for (var i = 0; i < reversedBatches.length; i++)
                          _BatchCard(
                            key: ValueKey(reversedBatches[i].id),
                            batch: reversedBatches[i],
                            shops: shops,
                            quests: quests,
                            initiallyExpanded: i == 0,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Writes [content] to a temp .txt file and hands it to the OS (share
/// sheet / a text viewer), for a real "export" rather than just a
/// clipboard copy. Falls back to telling the user what went wrong — some
/// devices have nothing registered to open a bare .txt file.
Future<void> _exportToFile(BuildContext context, WidgetRef ref, String content, String filename) async {
  try {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    await OpenFilex.open(file.path);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${trFor(ref.read(appLanguageProvider), 'export_failed_prefix')}: $e')),
    );
  }
}

Future<void> _copyToClipboard(BuildContext context, WidgetRef ref, String content) async {
  await Clipboard.setData(ClipboardData(text: content));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(tr(ref, 'transcript_copied_message'))),
  );
}

/// Renders one run as a plain-text transcript: its summary stats, then
/// every node visited with its narrative text and the choice taken from
/// it — the "node and text" export the QA workflow needs.
String _runTranscript(_SimResult result, String strategyLabel, {int? runNumber}) {
  final b = StringBuffer();
  b.writeln('=== Playthrough Transcript${runNumber != null ? ' — Run #$runNumber' : ''} ===');
  b.writeln('Strategy: $strategyLabel');
  b.writeln('Ending: ${result.endingSummary}');
  b.writeln(
    'Final gold: ${result.finalGold} | Final alignment: ${result.finalAlignment} | '
    'Nodes visited: ${result.steps.length} (unique: ${result.uniqueNodesVisited})',
  );
  b.writeln('Shops discovered: ${result.shopsDiscovered.isEmpty ? 'none' : result.shopsDiscovered.join(', ')}');
  b.writeln('Quests discovered: ${result.questsDiscovered.isEmpty ? 'none' : result.questsDiscovered.join(', ')}');
  b.writeln('Flags collected: ${result.flags.isEmpty ? 'none' : result.flags.join(', ')}');
  b.writeln();
  b.writeln('--- Steps ---');
  for (final s in result.steps) {
    final tags = [
      _chapterLabel(s.chapter),
      if (s.uiTheme != null) s.uiTheme,
      if (s.mood != null) s.mood,
    ].join(' / ');
    b.writeln();
    b.writeln('[Node ${s.nodeId}] ($tags)');
    b.writeln(s.description);
    if (s.choiceText != null) {
      b.writeln('→ Chose: "${s.choiceText}"${s.enemyId != null ? ' [combat: ${s.enemyId}]' : ''}');
    }
  }
  return b.toString();
}

String _batchSummaryText(String strategyLabel, List<_SimResult> results) {
  final b = StringBuffer();
  b.writeln('=== Batch Summary ===');
  b.writeln('Strategy: $strategyLabel');
  b.writeln('Runs: ${results.length}');
  b.writeln('Average nodes visited: ${_avg(results.map((r) => r.steps.length)).toStringAsFixed(1)}');
  b.writeln('Average final gold: ${_avg(results.map((r) => r.finalGold)).toStringAsFixed(1)}');
  b.writeln('Average final alignment: ${_avg(results.map((r) => r.finalAlignment)).toStringAsFixed(1)}');
  b.writeln('Average combat encounters: ${_avg(results.map((r) => r.combatEncounters)).toStringAsFixed(1)}');
  final stepCap = results.where((r) => r.reachedStepCap).length;
  if (stepCap > 0) {
    b.writeln('$stepCap/${results.length} runs never reached an ending (hit the step cap).');
  }
  b.writeln();
  b.writeln('Ending distribution:');
  for (final entry in _endingCounts(results).entries) {
    b.writeln('- ${entry.value}x: ${entry.key}');
  }
  b.writeln();
  b.writeln('By chapter:');
  for (final g in _chapterBreakdown(results)) {
    b.writeln(
      '- ${g.label}: ${g.runsReaching}/${results.length} runs reached it, '
      '${(g.nodeCount / g.runsReaching).toStringAsFixed(1)} nodes avg, '
      '${g.combatCount} combats, gold Δ${g.goldDelta}, alignment Δ${g.alignmentDelta}',
    );
  }
  b.writeln();
  b.writeln('By location:');
  for (final g in _distributionBy(results, (s) => s.uiTheme)) {
    b.writeln('- ${g.label}: ${g.nodeCount} nodes');
  }
  b.writeln();
  b.writeln('By mood:');
  for (final g in _distributionBy(results, (s) => s.mood)) {
    b.writeln('- ${g.label}: ${g.nodeCount} nodes');
  }
  return b.toString();
}

/// The batch summary followed by every run's full transcript, in one
/// document — shared by both the "Copy" and "Export as text" actions so
/// they always produce identical content.
String _fullBatchTranscript(String strategyLabel, List<_SimResult> results) {
  final b = StringBuffer()..writeln(_batchSummaryText(strategyLabel, results));
  for (var i = 0; i < results.length; i++) {
    b
      ..writeln()
      ..writeln(_runTranscript(results[i], strategyLabel, runNumber: i + 1));
  }
  return b.toString();
}

/// Quotes a CSV field per RFC 4180 whenever it contains a comma, quote, or
/// newline (every field here can: run text, joined tag lists).
String _csvField(String value) {
  if (value.contains(RegExp('[,"\n]'))) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// One row per run — final stats side by side, ready to drop into a
/// spreadsheet for sorting/charting across a batch.
String _batchResultsCsv(List<_SimResult> results) {
  final b = StringBuffer();
  b.writeln([
    'Run',
    'Ending',
    'Final Gold',
    'Final Alignment',
    'Nodes Visited',
    'Combat Encounters',
    'Furthest Chapter',
    'Reached Step Cap',
    'Shops Discovered',
    'Quests Discovered',
    'Flags',
  ].map(_csvField).join(','));
  for (var i = 0; i < results.length; i++) {
    final r = results[i];
    b.writeln([
      '${i + 1}',
      r.endingSummary,
      '${r.finalGold}',
      '${r.finalAlignment}',
      '${r.uniqueNodesVisited}',
      '${r.combatEncounters}',
      '${r.furthestChapter ?? ''}',
      r.reachedStepCap ? 'yes' : 'no',
      r.shopsDiscovered.join('; '),
      r.questsDiscovered.join('; '),
      r.flags.join('; '),
    ].map(_csvField).join(','));
  }
  return b.toString();
}

/// The same per-run data as [_batchResultsCsv], structured for
/// programmatic reprocessing rather than spreadsheet import.
String _batchResultsJson(String strategyLabel, List<_SimResult> results) {
  final data = {
    'strategy': strategyLabel,
    'runCount': results.length,
    'runs': [
      for (var i = 0; i < results.length; i++)
        {
          'run': i + 1,
          'ending': results[i].endingSummary,
          'finalGold': results[i].finalGold,
          'finalAlignment': results[i].finalAlignment,
          'nodesVisited': results[i].uniqueNodesVisited,
          'combatEncounters': results[i].combatEncounters,
          'furthestChapter': results[i].furthestChapter,
          'reachedStepCap': results[i].reachedStepCap,
          'shopsDiscovered': results[i].shopsDiscovered.toList(),
          'questsDiscovered': results[i].questsDiscovered.toList(),
          'flags': results[i].flags.toList(),
          'path': results[i].path,
        },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(data);
}

class _BatchCard extends ConsumerStatefulWidget {
  const _BatchCard({
    super.key,
    required this.batch,
    required this.shops,
    required this.quests,
    this.initiallyExpanded = true,
  });

  final _SimBatch batch;
  final Map<String, dynamic> shops;
  final Map<String, dynamic> quests;

  /// Older batches start collapsed to their header line so a page of past
  /// runs doesn't bury the newest one — only the most recent batch (index
  /// 0 in the reversed list) opens expanded by default.
  final bool initiallyExpanded;

  @override
  ConsumerState<_BatchCard> createState() => _BatchCardState();
}

class _BatchCardState extends ConsumerState<_BatchCard> {
  bool _analyzing = false;
  String? _analysisText;
  String? _analysisError;
  late bool _expanded = widget.initiallyExpanded;
  bool _showAllRuns = false;

  static const int _runListPreviewCount = 5;

  // Filters applied to which runs count toward the stats/list/export below.
  String? _endingFilter;
  bool _onlyStepCapFilter = false;
  int? _minChapterFilter;

  String _oneDecimal(double v) => v.toStringAsFixed(1);

  List<_SimResult> get _filteredResults {
    return widget.batch.results.where((r) {
      if (_onlyStepCapFilter && !r.reachedStepCap) return false;
      if (_endingFilter != null && r.endingSummary != _endingFilter) return false;
      if (_minChapterFilter != null && (r.furthestChapter ?? 0) < _minChapterFilter!) return false;
      return true;
    }).toList();
  }

  bool get _filterActive =>
      _endingFilter != null || _onlyStepCapFilter || _minChapterFilter != null;

  /// Compiles this batch's stats into a plain-text summary Gemini can
  /// reason over — the same numbers already shown in the card (respecting
  /// the current filter), plus the full transcript for a single run.
  String _buildPrompt(AppLanguage lang, List<_SimResult> results) {
    final strategyLabel = trFor(lang, _strategyLabelKey(widget.batch.strategy));
    final b = StringBuffer()
      ..writeln(
        'You are a narrative game designer reviewing simulated playthroughs of a dark-fantasy '
        'interactive-fiction app. Below is aggregate data from an automated simulator that plays '
        'the story graph choosing among valid choices per a fixed strategy.',
      )
      ..writeln()
      ..writeln(_batchSummaryText(strategyLabel, results));
    final single = results.length == 1 ? results.single : null;
    if (single != null) {
      b
        ..writeln()
        ..writeln('Full node path for this run: ${single.path.join(' -> ')}');
    }
    b
      ..writeln()
      ..writeln(
        'Based on this data, provide: (1) a short summary of what this run reveals about the '
        'player\'s experience, (2) any issues you notice (repetitive endings, dead ends, '
        'pacing or balance problems, a strategy that trivially dominates, a chapter that\'s '
        'thin or overloaded compared to the others), and (3) concrete, specific suggestions '
        'for updates to particular story nodes to improve the story. Be concise.',
      );
    return b.toString();
  }

  Future<void> _analyze() async {
    final apiKey = ref.read(apiKeyProvider);
    final lang = ref.read(appLanguageProvider);
    if (apiKey == null || apiKey.isEmpty) {
      setState(() => _analysisError = trFor(lang, 'add_api_key_first'));
      return;
    }
    final results = _filteredResults;
    if (results.isEmpty) return;
    setState(() {
      _analyzing = true;
      _analysisError = null;
      _analysisText = null;
    });
    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      final response = await model.generateContent([Content.text(_buildPrompt(lang, results))]);
      if (!mounted) return;
      setState(() => _analysisText = response.text ?? trFor(lang, 'no_response_generated'));
    } catch (e) {
      if (!mounted) return;
      setState(() => _analysisError = '${trFor(lang, 'generation_failed_prefix')}: $e');
    } finally {
      if (mounted) setState(() => _analyzing = false);
    }
  }

  Future<void> _viewRun(_SimResult result, int index) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: _SingleRunDetail(
            result: result,
            shops: widget.shops,
            quests: widget.quests,
            strategyLabel: tr(ref, _strategyLabelKey(widget.batch.strategy)),
            runNumber: index + 1,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    final results = _filteredResults;
    final single = results.length == 1 ? results.single : null;
    final endingOptions = _endingCounts(batch.results).keys.toList();
    final hasChapterData = batch.results.any((r) => r.furthestChapter != null);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${tr(ref, _strategyLabelKey(batch.strategy))} × ${batch.runCount}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (!_expanded)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${_oneDecimal(_avg(batch.results.map((r) => r.finalGold)))}g · '
                              '${tr(ref, 'final_alignment_label')} '
                              '${_oneDecimal(_avg(batch.results.map((r) => r.finalAlignment)))} · '
                              '${_endingCounts(batch.results).entries.map((e) => '${e.value}× ${e.key}').join(', ')}',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined),
                    tooltip: tr(ref, 'copy_button'),
                    onPressed: results.isEmpty
                        ? null
                        : () => _copyToClipboard(
                              context,
                              ref,
                              _fullBatchTranscript(
                                tr(ref, _strategyLabelKey(batch.strategy)),
                                results,
                              ),
                            ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.ios_share_outlined),
                    tooltip: tr(ref, 'export_all_runs_button'),
                    enabled: results.isNotEmpty,
                    onSelected: (format) {
                      final strategyLabel = tr(ref, _strategyLabelKey(batch.strategy));
                      switch (format) {
                        case 'txt':
                          _exportToFile(
                            context,
                            ref,
                            _fullBatchTranscript(strategyLabel, results),
                            'playthrough_batch_${batch.id}.txt',
                          );
                          break;
                        case 'csv':
                          _exportToFile(
                            context,
                            ref,
                            _batchResultsCsv(results),
                            'playthrough_batch_${batch.id}.csv',
                          );
                          break;
                        case 'json':
                          _exportToFile(
                            context,
                            ref,
                            _batchResultsJson(strategyLabel, results),
                            'playthrough_batch_${batch.id}.json',
                          );
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'txt', child: Text(tr(ref, 'export_as_text'))),
                      PopupMenuItem(value: 'csv', child: Text(tr(ref, 'export_as_csv'))),
                      PopupMenuItem(value: 'json', child: Text(tr(ref, 'export_as_json'))),
                    ],
                  ),
                  IconButton(
                    icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                    tooltip: tr(ref, _expanded ? 'collapse_batch_label' : 'expand_batch_label'),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              if (batch.runCount > 1) ...[
              const SizedBox(height: 8),
              Text(tr(ref, 'filter_runs_label'), style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  DropdownButton<String?>(
                    value: _endingFilter,
                    hint: Text(tr(ref, 'ending_filter_all')),
                    items: [
                      DropdownMenuItem(value: null, child: Text(tr(ref, 'ending_filter_all'))),
                      for (final e in endingOptions) DropdownMenuItem(value: e, child: Text(e)),
                    ],
                    onChanged: (v) => setState(() => _endingFilter = v),
                  ),
                  if (hasChapterData)
                    DropdownButton<int?>(
                      value: _minChapterFilter,
                      hint: Text(tr(ref, 'min_chapter_filter_label')),
                      items: [
                        DropdownMenuItem(value: null, child: Text(tr(ref, 'any_label'))),
                        for (var c = 1; c <= 5; c++)
                          DropdownMenuItem(value: c, child: Text('${tr(ref, 'min_chapter_filter_label')} $c')),
                      ],
                      onChanged: (v) => setState(() => _minChapterFilter = v),
                    ),
                  if (batch.stepCapCount > 0)
                    FilterChip(
                      label: Text(tr(ref, 'stuck_only_filter')),
                      selected: _onlyStepCapFilter,
                      onSelected: (v) => setState(() => _onlyStepCapFilter = v),
                    ),
                  if (_filterActive)
                    TextButton(
                      onPressed: () => setState(() {
                        _endingFilter = null;
                        _onlyStepCapFilter = false;
                        _minChapterFilter = null;
                      }),
                      child: Text(tr(ref, 'clear_all_button')),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (results.isEmpty)
              Text(tr(ref, 'no_runs_match_filter'))
            else ...[
              Text(
                '${tr(ref, 'nodes_visited_label')}: ${_oneDecimal(_avg(results.map((r) => r.steps.length)))}',
              ),
              Text('${tr(ref, 'final_gold_label')}: ${_oneDecimal(_avg(results.map((r) => r.finalGold)))}'),
              Text(
                '${tr(ref, 'final_alignment_label')}: ${_oneDecimal(_avg(results.map((r) => r.finalAlignment)))}',
              ),
              Text(
                '${tr(ref, 'combat_encounters_label')}: ${_oneDecimal(_avg(results.map((r) => r.combatEncounters)))}',
              ),
              if (results.where((r) => r.reachedStepCap).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${results.where((r) => r.reachedStepCap).length}/${results.length} '
                    '${tr(ref, 'exceeded_step_cap_label')}',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const SizedBox(height: 12),
              Text(tr(ref, 'endings_label'), style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final entry in _endingCounts(results).entries)
                Text('${entry.value}× ${entry.key}', style: Theme.of(context).textTheme.bodySmall),
              const Divider(height: 24),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(tr(ref, 'chapter_breakdown_label')),
                initiallyExpanded: hasChapterData,
                children: [
                  for (final g in _chapterBreakdown(results))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${g.label} · ${g.runsReaching}/${results.length}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            [
                              '${(g.nodeCount / g.runsReaching).toStringAsFixed(1)} '
                                  '${tr(ref, 'nodes_visited_label').toLowerCase()}',
                              if (g.combatCount > 0)
                                '${g.combatCount} ${tr(ref, 'combat_encounters_label').toLowerCase()}',
                              if (g.goldDelta != 0) 'gold Δ${g.goldDelta}',
                              if (g.alignmentDelta != 0) 'align Δ${g.alignmentDelta}',
                            ].join(' • '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(tr(ref, 'by_location_label')),
                children: [
                  for (final g in _distributionBy(results, (s) => s.uiTheme))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text(g.label, style: Theme.of(context).textTheme.bodySmall)),
                          Text(
                            '${g.nodeCount}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(tr(ref, 'by_mood_label')),
                children: [
                  for (final g in _distributionBy(results, (s) => s.mood))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(child: Text(g.label, style: Theme.of(context).textTheme.bodySmall)),
                          Text(
                            '${g.nodeCount}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _analyzing ? null : _analyze,
                      icon: _analyzing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        _analyzing
                            ? tr(ref, 'analyzing_label')
                            : tr(ref, 'analyze_with_gemini_button'),
                      ),
                    ),
                  ),
                  if (_analysisText != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy_outlined),
                      tooltip: tr(ref, 'copy_button'),
                      onPressed: () => _copyToClipboard(context, ref, _analysisText!),
                    ),
                  ],
                ],
              ),
              if (_analysisError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _analysisError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              if (_analysisText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(_analysisText!),
                  ),
                ),
              if (single != null) ...[
                const Divider(height: 24),
                _SingleRunDetail(
                  result: single,
                  shops: widget.shops,
                  quests: widget.quests,
                  strategyLabel: tr(ref, _strategyLabelKey(batch.strategy)),
                ),
              ] else ...[
                const Divider(height: 24),
                Text(tr(ref, 'individual_runs_label'), style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                for (var i = 0; i < (_showAllRuns ? results.length : results.length.clamp(0, _runListPreviewCount)); i++)
                  InkWell(
                    onTap: () => _viewRun(results[i], batch.results.indexOf(results[i])),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '#${batch.results.indexOf(results[i]) + 1}: ${results[i].finalGold}g, '
                              '${tr(ref, 'final_alignment_label')} ${results[i].finalAlignment}, '
                              '${results[i].steps.length} ${tr(ref, 'nodes_visited_label')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18),
                        ],
                      ),
                    ),
                  ),
                if (results.length > _runListPreviewCount)
                  TextButton(
                    onPressed: () => setState(() => _showAllRuns = !_showAllRuns),
                    child: Text(
                      _showAllRuns
                          ? tr(ref, 'show_less_label')
                          : '${tr(ref, 'show_all_runs_label')} (${results.length})',
                    ),
                  ),
              ],
            ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SingleRunDetail extends ConsumerStatefulWidget {
  const _SingleRunDetail({
    required this.result,
    required this.shops,
    required this.quests,
    required this.strategyLabel,
    this.runNumber,
    this.scrollController,
  });

  final _SimResult result;
  final Map<String, dynamic> shops;
  final Map<String, dynamic> quests;
  final String strategyLabel;
  final int? runNumber;
  final ScrollController? scrollController;

  @override
  ConsumerState<_SingleRunDetail> createState() => _SingleRunDetailState();
}

class _SingleRunDetailState extends ConsumerState<_SingleRunDetail> {
  int? _chapterFilter; // null = show all chapters. Use -1 as the "Prologue" sentinel.

  String _namesFor(Set<String> ids, Map<String, dynamic> records, String nameField) {
    if (ids.isEmpty) return '—';
    return ids
        .map((id) => (records[id] as Map<String, dynamic>?)?[nameField]?.toString() ?? id)
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final chapters = result.steps.map((s) => s.chapter ?? -1).toSet().toList()..sort();
    final filteredSteps = _chapterFilter == null
        ? result.steps
        : result.steps.where((s) => (s.chapter ?? -1) == _chapterFilter).toList();

    final content = <Widget>[
      Row(
        children: [
          Expanded(
            child: Text(
              widget.runNumber != null
                  ? '${tr(ref, 'playthrough_recap_title')} — #${widget.runNumber}'
                  : tr(ref, 'playthrough_recap_title'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: tr(ref, 'copy_button'),
            onPressed: () => _copyToClipboard(
              context,
              ref,
              _runTranscript(result, widget.strategyLabel, runNumber: widget.runNumber),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: tr(ref, 'export_button'),
            onPressed: () => _exportToFile(
              context,
              ref,
              _runTranscript(result, widget.strategyLabel, runNumber: widget.runNumber),
              'playthrough_run_${widget.runNumber ?? 1}.txt',
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text('${tr(ref, 'ending_reached_label')}: ${result.endingSummary}'),
      if (result.furthestChapter != null)
        Text('${tr(ref, 'furthest_chapter_label')}: ${result.furthestChapter}'),
      Text(
        '${tr(ref, 'unique_nodes_visited_label')}: ${result.uniqueNodesVisited} '
        '(${result.steps.length} ${tr(ref, 'total_steps_label')})',
      ),
      Text('${tr(ref, 'shops_discovered_label')}: ${_namesFor(result.shopsDiscovered, widget.shops, 'shopName')}'),
      Text(
        '${tr(ref, 'quests_discovered_label')}: ${_namesFor(result.questsDiscovered, widget.quests, 'questName')}',
      ),
      Text(
        '${tr(ref, 'flags_collected_label')}: ${result.flags.isEmpty ? '—' : result.flags.join(', ')}',
      ),
      const SizedBox(height: 12),
      Text(tr(ref, 'path_summary_label'), style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          ChoiceChip(
            label: Text(tr(ref, 'chapter_filter_all_label')),
            selected: _chapterFilter == null,
            onSelected: (_) => setState(() => _chapterFilter = null),
          ),
          for (final c in chapters)
            ChoiceChip(
              label: Text(c == -1 ? tr(ref, 'prologue_label') : 'Ch. $c'),
              selected: _chapterFilter == c,
              onSelected: (_) => setState(() => _chapterFilter = c),
            ),
        ],
      ),
      const SizedBox(height: 8),
    ];

    final stepTiles = [
      for (final entry in filteredSteps.asMap().entries)
        ExpansionTile(
          key: ValueKey('${entry.value.nodeId}_${entry.key}'),
          tilePadding: EdgeInsets.zero,
          title: Text(
            'Node ${entry.value.nodeId} · ${_chapterLabel(entry.value.chapter)}'
            '${entry.value.uiTheme != null ? ' · ${entry.value.uiTheme}' : ''}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          subtitle: Text(
            entry.value.description.length > 70
                ? '${entry.value.description.substring(0, 70)}…'
                : entry.value.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.value.description),
                  if (entry.value.choiceText != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '→ "${entry.value.choiceText}"'
                      '${entry.value.enemyId != null ? '  [combat: ${entry.value.enemyId}]' : ''}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
    ];

    if (widget.scrollController != null) {
      // Rendered inside a DraggableScrollableSheet -- one scroll view for
      // the whole thing, driven by the sheet's own controller.
      return ListView(
        controller: widget.scrollController,
        children: [...content, ...stepTiles],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [...content, ...stepTiles],
    );
  }
}
