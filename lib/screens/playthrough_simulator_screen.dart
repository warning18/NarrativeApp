import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../data/ability_check.dart' show checkPasses;

import '../combat/combat_engine.dart'
    show
        chapterRewardMultiplier,
        isBossEnemy,
        lostFightXpShare,
        scaledReward,
        zoneBossEnemyIds;
import '../combat/clan_dice.dart' show Resonance, resonanceOf, resonantFaces;
import '../combat/context_rules.dart' show ContextRule, Reinforcement;
import '../combat/gear_effects.dart';
import '../combat/spec_variants.dart' show SpecVariantInfo, specVariantsFrom;
import '../combat/specialisations.dart' show SpecInfo, specInfosFrom;
import '../combat/spells.dart';
import '../data/autoplay_engine.dart';
import '../data/autoplay_summary.dart';
import '../data/camp_errands.dart' show storyChoiceTarget;
import '../data/camp_works.dart';
import '../data/chapter_loop.dart';
import '../data/hunter_mercy.dart';
import '../data/patron_stats.dart' show statPatron;
import '../data/camp_rolls.dart' show rollPowerOf;
import '../data/risky_gifts.dart' show riskyGiftsOpen;
import '../data/sim_rolls.dart';
import '../data/rival_hunters.dart' show maybeRivalHunter;
import '../data/road_wards.dart' show wardTargets;
import '../data/alignment_events.dart'
    show hunterCooldownRolls, isHunterAmbushChain, maybeAlignmentEvent;
import '../data/camp_state.dart' show landingPortIdFor;
import '../data/chapter_spine.dart';
import '../data/detour_pacing.dart';
import '../data/detour_scenes.dart';
import '../data/journey_rules.dart' show walkWatches;
import '../data/recurring_encounters.dart'
    show markerFor, recurringBeatsOpen, recurringChance;
import '../data/feature_unlocks.dart' show trainerGuardFlag, trainerStrikeFlag;
import '../data/factions.dart';
import '../data/expedition_steps.dart';
import '../data/perks.dart';
import '../data/politics_events.dart'
    show
        PoliticsEvent,
        choicePoliticsKey,
        enterPoliticsKey,
        parsePoliticsEvents;
import '../data/materials.dart';
import '../data/settlements.dart' show campFoundedFlag;
import '../data/signs.dart';
import '../data/sim_combat.dart';
import '../data/sim_companions.dart';
import '../data/story_companions.dart';
import '../data/story_prices.dart';
import '../data/sim_growth.dart';
import '../data/sim_policy.dart';
import '../data/skill_craft.dart' show skillCraftOpen;
import '../data/sim_quests.dart';
import '../data/temple.dart';
import '../data/town_rulers.dart' show townRulers;
import '../data/story_graph_integrity.dart';
import '../data/story_repository.dart';
import '../data/sub_node_engine.dart';
import '../data/training.dart' show TrainingPath, trainingPathsFrom;
import '../data/zone_gating.dart' show meetsRequiredFlags, zoneIsMain;
import '../data/clan_power.dart' show TerritoryChange;
import '../data/city_districts.dart' show districtOfNode;
import '../data/geography.dart';
import '../data/nemesis.dart'
    show
        breakNemesis,
        championIdOf,
        championMinChapter,
        championRecordFor,
        championRoadChance,
        championWays,
        trailFlagOf;
import '../data/land_crossing.dart';
import '../data/road_events.dart';
import '../gamedata/db_schema.dart';
import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import '../models/story_node.dart';
import '../providers/game_config_provider.dart';
import '../providers/game_db_providers.dart';
import '../providers/geography_provider.dart';
import '../providers/app_mode_provider.dart';
import '../providers/home_tab_provider.dart';
import '../providers/place_pools_provider.dart';
import '../providers/training_provider.dart';
import '../providers/story_providers.dart';
import '../providers/clans_provider.dart' show loadClanData;
import '../providers/player_session_provider.dart' show playerSessionProvider;
import 'autoplay_summary_dialog.dart';
import '../utils/game_icons.dart';

part 'playthrough_simulator/sim_engine.dart';
part 'playthrough_simulator/sim_stats.dart';
part 'playthrough_simulator/sim_export.dart';
part 'playthrough_simulator/sim_batch_card.dart';
part 'playthrough_simulator/sim_run_detail.dart';

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
    state = [
      ...state,
      _SimBatch(id: _nextId++, strategy: strategy, results: results)
    ];
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
  ConsumerState<PlaythroughSimulatorScreen> createState() =>
      _PlaythroughSimulatorScreenState();
}

class _PlaythroughSimulatorScreenState
    extends ConsumerState<PlaythroughSimulatorScreen> {
  bool _running = false;
  SimStrategy _strategy = SimStrategy.random;
  int _runCount = 1;

  /// Real-session counterpart to [_run] -- rather than an isolated
  /// statistics-only walk, [_playToChapter] plays [_strategy]-weighted
  /// choices forward against the actual player session and lands them
  /// back in live Story view once [_targetChapter] is reached. `null`
  /// means "not chosen yet" (the button stays disabled).
  int? _targetChapter;
  bool _autoplayRunning = false;

  /// The attempt [_playToChapter] is on: a run that falls short is undone
  /// and played again until it reaches the chapter.
  int _autoplayAttempt = 0;

  /// [_playToChapter]'s options: a fresh game first, with this race and
  /// profession (null: random), and a seed (null: random).
  bool _autoplayNewGame = false;
  String? _autoplayRaceId;
  String? _autoplayProfessionId;
  int? _autoplaySeed;
  Map<String, dynamic> _raceRecords = const {};
  Map<String, dynamic> _professionRecords = const {};

  /// Whether the strategy/runs/simulate controls are shown in full. They
  /// collapse to a compact bar on a tap (or a new result to look at), and
  /// come back on a tap or once the compact view's results are scrolled
  /// back to the top.
  bool _controlsExpanded = true;
  final ScrollController _resultsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _resultsScrollController.addListener(_onResultsScroll);
    _loadCharacterRecords();
  }

  /// The races and professions [_playToChapter]'s pickers offer.
  Future<void> _loadCharacterRecords() async {
    final races =
        await ref.read(gameDbRepositoryProvider(racesSchema)).loadRecords();
    final professions = await ref
        .read(gameDbRepositoryProvider(professionsSchema))
        .loadRecords();
    if (!mounted) return;
    setState(() {
      _raceRecords = races;
      _professionRecords = professions;
    });
  }

  @override
  void dispose() {
    _resultsScrollController.removeListener(_onResultsScroll);
    _resultsScrollController.dispose();
    super.dispose();
  }

  void _onResultsScroll() {
    // Only the compact view's results use this controller: back at the top,
    // the full controls come back. (The full view scrolls the controls away
    // with the rest, so scrolling down must not collapse it.)
    if (_resultsScrollController.offset <= 4 && !_controlsExpanded) {
      setState(() => _controlsExpanded = true);
    }
  }

  /// Plays [_strategy]-weighted real choices forward against the actual
  /// player session until [_targetChapter] (via [autoplayToChapter]),
  /// applying true effects at every step, then lands the player back in
  /// live Story view to keep going manually -- unlike [_run], which only
  /// ever produces disposable statistics.
  Future<void> _playToChapter() async {
    final target = _targetChapter;
    if (target == null) return;
    final lang = ref.read(appLanguageProvider);
    String t(String key) => trFor(lang, key);

    setState(() => _autoplayRunning = true);
    final story = await ref.read(storyDataProvider.future);
    final dice =
        await ref.read(gameDbRepositoryProvider(diceSchema)).loadRecords();
    final skills =
        await ref.read(gameDbRepositoryProvider(skillsSchema)).loadRecords();
    final items =
        await ref.read(gameDbRepositoryProvider(itemsSchema)).loadRecords();
    final enemies =
        await ref.read(gameDbRepositoryProvider(enemiesSchema)).loadRecords();
    final races =
        await ref.read(gameDbRepositoryProvider(racesSchema)).loadRecords();
    final professions = await ref
        .read(gameDbRepositoryProvider(professionsSchema))
        .loadRecords();
    final zones = await loadZonesWithWrittenCounts(ref);

    // A fresh game first, when asked: the pickers' race and profession are
    // a new character's.
    if (_autoplayNewGame) {
      await ref.read(playerSessionProvider.notifier).resetSession();
      ref.read(storyPlayProvider.notifier).restart(StoryRepository.startNodeId);
    }
    final before = ref.read(playerSessionProvider);
    final log = AutoplayLog();
    final result = await autoplayToChapter(
      ref,
      story: story,
      targetChapter: target,
      strategy: _toAutoplayStrategy(_strategy),
      dice: dice,
      skills: skills,
      items: items,
      enemies: enemies,
      races: races,
      professions: professions,
      zones: zones,
      raceId: _autoplayRaceId,
      professionId: _autoplayProfessionId,
      seed: _autoplaySeed,
      log: log,
      onAttempt: (attempt) {
        if (mounted) setState(() => _autoplayAttempt = attempt);
      },
    );

    if (!mounted) return;
    setState(() {
      _autoplayRunning = false;
      _autoplayAttempt = 0;
    });

    final message = switch (result.status) {
      AutoplayStatus.alreadyThere => t('autoplay_already_there'),
      AutoplayStatus.noPathFound => t('autoplay_no_path'),
      AutoplayStatus.stuckInCombat => '${t('autoplay_stuck_prefix')} '
          '${result.stuckEnemyName} (${result.stepsApplied} ${t('autoplay_steps_suffix')})',
      AutoplayStatus.reachedTarget =>
        '${t('autoplay_reached_prefix')} (${result.stepsApplied} ${t('autoplay_steps_suffix')}'
            '${result.attempts > 1 ? ', ${t('autoplay_attempt_label')} ${result.attempts}' : ''}'
            '${result.forcedWins > 0 ? ', ${result.forcedWins} ${t('autoplay_forced_suffix')}' : ''})',
      AutoplayStatus.stepCapReached => t('autoplay_step_cap_reached'),
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

    // What the walk did, tab by tab, before the player takes over.
    if (result.stepsApplied > 0) {
      final clans = await loadClanData(ref);
      final companions = await ref
          .read(gameDbRepositoryProvider(companionsSchema))
          .loadRecords();
      if (!mounted) return;
      final after = ref.read(playerSessionProvider);
      final nodeId = ref.read(storyPlayProvider).currentNodeId;
      await showAutoplaySummary(
        context,
        summary: autoplaySummaryOf(
          before: before,
          after: after,
          log: log,
          data: clans,
          chapter: chapterForNode(nodeId) ?? target,
          nodeId: nodeId,
        ),
        clans: clans,
        itemName: (id) => (items[id] as Map?)?['itemName']?.toString() ?? id,
        companionName: (id) =>
            (companions[id] as Map?)?['companionName']?.toString() ?? id,
      );
      if (!mounted) return;
    }

    // Land the player on the Story tab, ready to keep going manually from
    // wherever the walk ended up -- the whole point of this feature. This
    // screen is reached via two pushed routes (Settings, then here), so
    // switching the tab alone leaves it invisible underneath both until
    // they're popped back to the root.
    if (result.stepsApplied > 0) {
      ref.read(homeTabIndexProvider.notifier).state =
          storyTabIndex(ref.read(appModeProvider));
      Navigator.of(context).popUntil(isGameRoute);
    }
  }

  Future<void> _run() async {
    setState(() => _running = true);
    final story = await ref.read(storyDataProvider.future);
    final enemies =
        await ref.read(gameDbRepositoryProvider(enemiesSchema)).loadRecords();
    Future<Map<String, dynamic>> load(DbSchema schema) =>
        ref.read(gameDbRepositoryProvider(schema)).loadRecords();
    final sim = _SimContext(
      dice: await load(diceSchema),
      skills: await load(skillsSchema),
      items: await load(itemsSchema),
      shops: await load(shopsSchema),
      races: await load(racesSchema),
      professions: await load(professionsSchema),
      spells: parseSpells(await load(spellsSchema)),
      gameConfig: await ref.read(gameConfigProvider.future),
      itemSets: parseItemSets(await load(itemSetsSchema)),
      zones: await loadZonesWithWrittenCounts(ref),
      patrons: parsePatrons(await load(factionsSchema)),
      signs: parseSigns(await load(signsSchema)),
      clans: ClanData.fromTables(
        factions: await load(factionsSchema),
        subclans: await load(subclansSchema),
        relations: await load(relationsSchema),
        titles: await load(titlesSchema),
      ),
      skillTrees: await load(skillTreesSchema),
      geography: await loadGeography(ref),
      landRoutes: await load(landRoutesSchema),
      landEvents: landEventsFrom(await load(landEventsSchema)),
      houses: await load(housesSchema),
      writtenSteps: await loadWrittenSteps(ref),
      trainingPaths: await ref.read(trainingPathsProvider.future),
      politicsEvents: parsePoliticsEvents(await load(politicsEventsSchema)),
      // The screen plays as a real player would (sim_policy.dart); the CI
      // bands keep the naive player.
      policy: SimPolicy.competent,
      merges: await load(skillMergesSchema),
      // Its companions come with their quests (sim_companions.dart).
      companions: await load(companionsSchema),
      quests: await load(questsSchema),
      npcs: await load(npcsSchema),
    );
    final french = ref.read(appLanguageProvider) == AppLanguage.fr;
    final random = Random();
    final results = [
      for (var i = 0; i < _runCount; i++)
        _simulate(story, random,
            enemies: enemies, strategy: _strategy, french: french, sim: sim),
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
    final report = checkStoryGraphIntegrity(story.nodes,
        startNodeId: StoryRepository.startNodeId);
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
              Text(
                  '${tr(ref, 'structural_audit_endings_label')}: ${report.reachableEndingCount}'),
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
        Text(tr(ref, 'strategy_label'),
            style: Theme.of(context).textTheme.labelLarge),
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
        Text(tr(ref, 'runs_label'),
            style: Theme.of(context).textTheme.labelLarge),
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
                label: Text(_running
                    ? tr(ref, 'simulating_label')
                    : tr(ref, 'auto_playthrough_button')),
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
        const Divider(height: 32),
        Text(tr(ref, 'play_to_chapter_title'),
            style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          tr(ref, 'play_to_chapter_subtitle'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var chapter = 0; chapter <= _maxChapter; chapter++)
              if (firstNodeIdForChapter(chapter,
                      prologueNodeId: StoryRepository.startNodeId) !=
                  null)
                ChoiceChip(
                  label: Text(chapter == 0
                      ? tr(ref, 'chapter_band_prologue')
                      : '$chapter'),
                  selected: _targetChapter == chapter,
                  onSelected: (_) => setState(() => _targetChapter = chapter),
                ),
          ],
        ),
        const SizedBox(height: 12),
        _playToChapterOptions(context),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: (_autoplayRunning || _targetChapter == null)
              ? null
              : _playToChapter,
          icon: _autoplayRunning
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.fast_forward),
          label: Text(_autoplayRunning
              ? (_autoplayAttempt > 1
                  ? '${tr(ref, 'autoplay_running')} '
                      '${tr(ref, 'autoplay_attempt_label')} $_autoplayAttempt'
                  : tr(ref, 'autoplay_running'))
              : tr(ref, 'play_to_chapter_button')),
        ),
      ],
    );
  }

  /// [_playToChapter]'s pickers: a new game, its race and profession, the
  /// player's style (the strategy chips above) and a seed.
  Widget _playToChapterOptions(BuildContext context) {
    String nameOf(Map<String, dynamic> records, String id, String field) =>
        (records[id] as Map?)?[field]?.toString() ?? id;
    DropdownButton<String?> picker(
      Map<String, dynamic> records,
      String field,
      String? value,
      void Function(String?) onChanged,
    ) =>
        DropdownButton<String?>(
          value: records.containsKey(value) ? value : null,
          hint: Text(tr(ref, 'ptc_random')),
          items: [
            DropdownMenuItem(value: null, child: Text(tr(ref, 'ptc_random'))),
            for (final id in records.keys)
              DropdownMenuItem(
                  value: id, child: Text(nameOf(records, id, field))),
          ],
          onChanged: _autoplayNewGame ? onChanged : null,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(tr(ref, 'ptc_new_game')),
          subtitle: Text(tr(ref, 'ptc_new_game_hint')),
          value: _autoplayNewGame,
          onChanged: (v) => setState(() => _autoplayNewGame = v),
        ),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(tr(ref, 'race_label')),
            picker(_raceRecords, 'raceName', _autoplayRaceId,
                (v) => setState(() => _autoplayRaceId = v)),
            Text(tr(ref, 'profession_label')),
            picker(_professionRecords, 'professionName', _autoplayProfessionId,
                (v) => setState(() => _autoplayProfessionId = v)),
          ],
        ),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: tr(ref, 'ptc_seed_label')),
          onChanged: (v) => setState(() => _autoplaySeed = int.tryParse(v)),
        ),
      ],
    );
  }

  int get _maxChapter => chapterSpines.isEmpty
      ? 0
      : chapterSpines.map((s) => s.chapter).reduce((a, b) => a > b ? a : b);

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
              Icon(Icons.tune,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
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
              Icon(Icons.expand_more,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
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
    final professions =
        ref.watch(gameDbProvider(professionsSchema)).value ?? const {};
    final spells =
        parseSpells(ref.watch(gameDbProvider(spellsSchema)).value ?? const {});
    final companions =
        ref.watch(gameDbProvider(companionsSchema)).value ?? const {};
    final batches = ref.watch(_simulatorBatchesProvider);
    final showFullControls = batches.isEmpty || _controlsExpanded;
    final reversedBatches = batches.reversed.toList();
    List<Widget> resultCards() => [
          for (var i = 0; i < reversedBatches.length; i++)
            _BatchCard(
              key: ValueKey(reversedBatches[i].id),
              batch: reversedBatches[i],
              shops: shops,
              quests: quests,
              companions: companions,
              professions: professions,
              spells: spells,
              initiallyExpanded: i == 0,
            ),
        ];

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
      // The full controls are taller than a phone, so they scroll with the
      // results (a plain Column ran the last button off the screen). The app
      // already keeps clear of the system bars in main.dart; the SafeArea
      // here keeps the screen right wherever it is shown without that.
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: showFullControls
              ? ListView(
                  key: const Key('sim_scroll_full'),
                  children: [
                    _fullControls(context, batches),
                    const SizedBox(height: 12),
                    if (batches.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                            child: Text(tr(ref, 'no_batches_yet_message'))),
                      )
                    else
                      ...resultCards(),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _compactControlsBar(context),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        key: const Key('sim_scroll_compact'),
                        controller: _resultsScrollController,
                        children: resultCards(),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
