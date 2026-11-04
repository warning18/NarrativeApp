// A batch of simulated runs as a card, cut out of
// playthrough_simulator_screen.dart with no change (wave 4a).
part of '../playthrough_simulator_screen.dart';

class _BatchCard extends ConsumerStatefulWidget {
  const _BatchCard({
    super.key,
    required this.batch,
    required this.shops,
    required this.quests,
    required this.companions,
    required this.professions,
    required this.spells,
    this.initiallyExpanded = true,
  });

  final _SimBatch batch;
  final Map<String, dynamic> shops;
  final Map<String, dynamic> quests;
  final Map<String, dynamic> companions;
  final Map<String, dynamic> professions;
  final Map<String, SpellSpec> spells;

  /// Older batches start collapsed to their header line so a page of past
  /// runs doesn't bury the newest one — only the most recent batch (index
  /// 0 in the reversed list) opens expanded by default.
  final bool initiallyExpanded;

  @override
  ConsumerState<_BatchCard> createState() => _BatchCardState();
}

class _BatchCardState extends ConsumerState<_BatchCard> {
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
      if (_endingFilter != null && r.endingSummary != _endingFilter) {
        return false;
      }
      if (_minChapterFilter != null &&
          (r.furthestChapter ?? 0) < _minChapterFilter!) {
        return false;
      }
      return true;
    }).toList();
  }

  bool get _filterActive =>
      _endingFilter != null || _onlyStepCapFilter || _minChapterFilter != null;

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
            professions: widget.professions,
            spells: widget.spells,
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
                                spells: widget.spells,
                              ),
                            ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.ios_share_outlined),
                    tooltip: tr(ref, 'export_all_runs_button'),
                    enabled: results.isNotEmpty,
                    onSelected: (format) {
                      final strategyLabel =
                          tr(ref, _strategyLabelKey(batch.strategy));
                      switch (format) {
                        case 'txt':
                          _exportToFile(
                            context,
                            ref,
                            _fullBatchTranscript(strategyLabel, results,
                                spells: widget.spells),
                            'playthrough_batch_${batch.id}.txt',
                          );
                        case 'csv':
                          _exportToFile(
                            context,
                            ref,
                            _batchResultsCsv(results),
                            'playthrough_batch_${batch.id}.csv',
                          );
                        case 'json':
                          _exportToFile(
                            context,
                            ref,
                            _batchResultsJson(strategyLabel, results),
                            'playthrough_batch_${batch.id}.json',
                          );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                          value: 'txt', child: Text(tr(ref, 'export_as_text'))),
                      PopupMenuItem(
                          value: 'csv', child: Text(tr(ref, 'export_as_csv'))),
                      PopupMenuItem(
                          value: 'json',
                          child: Text(tr(ref, 'export_as_json'))),
                    ],
                  ),
                  IconButton(
                    icon:
                        Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                    tooltip: tr(
                        ref,
                        _expanded
                            ? 'collapse_batch_label'
                            : 'expand_batch_label'),
                    onPressed: () => setState(() => _expanded = !_expanded),
                  ),
                ],
              ),
            ),
            if (_expanded) ...[
              if (batch.runCount > 1) ...[
                const SizedBox(height: 8),
                Text(tr(ref, 'filter_runs_label'),
                    style: Theme.of(context).textTheme.labelLarge),
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
                        DropdownMenuItem(
                            value: null,
                            child: Text(tr(ref, 'ending_filter_all'))),
                        for (final e in endingOptions)
                          DropdownMenuItem(value: e, child: Text(e)),
                      ],
                      onChanged: (v) => setState(() => _endingFilter = v),
                    ),
                    if (hasChapterData)
                      DropdownButton<int?>(
                        value: _minChapterFilter,
                        hint: Text(tr(ref, 'min_chapter_filter_label')),
                        items: [
                          DropdownMenuItem(
                              value: null, child: Text(tr(ref, 'any_label'))),
                          for (var c = 1; c <= 5; c++)
                            DropdownMenuItem(
                                value: c,
                                child: Text(
                                    '${tr(ref, 'min_chapter_filter_label')} $c')),
                        ],
                        onChanged: (v) => setState(() => _minChapterFilter = v),
                      ),
                    if (batch.stepCapCount > 0)
                      FilterChip(
                        label: Text(tr(ref, 'stuck_only_filter')),
                        selected: _onlyStepCapFilter,
                        onSelected: (v) =>
                            setState(() => _onlyStepCapFilter = v),
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
                Builder(builder: (context) {
                  final avgAlignment =
                      _avg(results.map((r) => r.finalAlignment));
                  final alignmentColor = avgAlignment > 0.5
                      ? Colors.blue
                      : (avgAlignment < -0.5
                          ? Colors.deepOrange
                          : Colors.blueGrey);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatLine(
                        icon: Icons.route,
                        color: Colors.blueGrey,
                        text:
                            '${tr(ref, 'nodes_visited_label')}: ${_oneDecimal(_avg(results.map((r) => r.steps.length)))}',
                      ),
                      _StatLine(
                        icon: Icons.paid,
                        color: Colors.amber.shade800,
                        text:
                            '${tr(ref, 'final_gold_label')}: ${_oneDecimal(_avg(results.map((r) => r.finalGold)))}',
                      ),
                      _StatLine(
                        icon: Icons.balance,
                        color: alignmentColor,
                        text:
                            '${tr(ref, 'final_alignment_label')}: ${_oneDecimal(avgAlignment)}',
                      ),
                      _StatLine(
                        icon: Icons.sports_martial_arts,
                        color: Colors.red.shade400,
                        text:
                            '${tr(ref, 'combat_encounters_label')}: ${_oneDecimal(_avg(results.map((r) => r.combatEncounters)))}',
                      ),
                      if (results.any((r) => r.hasCharacter)) ...[
                        _StatLine(
                          icon: Icons.emoji_events_outlined,
                          color: Colors.green.shade700,
                          text:
                              '${tr(ref, 'sim_fights_label')}: ${_oneDecimal(_avg(results.map((r) => r.fightsWon)))} / '
                              '${_oneDecimal(_avg(results.map((r) => r.fightsLost)))}',
                        ),
                        _StatLine(
                          icon: manaIcon,
                          color: manaColor,
                          text:
                              '${tr(ref, 'sim_spells_cast_label')}: ${_oneDecimal(_avg(results.map((r) => r.totalCasts)))} '
                              '(${tr(ref, 'sim_mana_from_dice_label').toLowerCase()} ${_oneDecimal(_avg(results.map((r) => r.manaGained)))})',
                        ),
                      ],
                    ],
                  );
                }),
                if (results.where((r) => r.reachedStepCap).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${results.where((r) => r.reachedStepCap).length}/${results.length} '
                      '${tr(ref, 'exceeded_step_cap_label')}',
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(tr(ref, 'endings_label'),
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                for (final entry in _endingCounts(results).entries)
                  Text('${entry.value}× ${entry.key}',
                      style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                Text(tr(ref, 'companions_encountered_label'),
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Builder(builder: (context) {
                  final counts =
                      _companionEncounterCounts(results, widget.quests);
                  if (counts.isEmpty) {
                    return Text(
                      tr(ref, 'none_label'),
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  }
                  return Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final entry in counts.entries)
                        Chip(
                          avatar: CircleAvatar(
                            backgroundColor: _companionColor(entry.key, counts),
                          ),
                          label: Text(
                            '${widget.companions[entry.key]?['companionName']?.toString() ?? entry.key} '
                            '· ${entry.value}/${results.length}',
                          ),
                        ),
                    ],
                  );
                }),
                if (results.any((r) => r.hasCharacter)) ...[
                  const SizedBox(height: 12),
                  Text(tr(ref, 'sim_spells_cast_label'),
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Builder(builder: (context) {
                    final totals = _spellCastTotals(results);
                    if (totals.isEmpty) {
                      return Text(
                        tr(ref, 'sim_no_spells_cast'),
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    }
                    final runsCasting = _runsCastingCounts(results);
                    final lang = ref.watch(appLanguageProvider);
                    return Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final entry in totals.entries)
                          Tooltip(
                            message:
                                '${runsCasting[entry.key] ?? 0}/${results.length} ${tr(ref, 'sim_runs_casting_label')}',
                            child: Chip(
                              avatar: Icon(
                                widget.spells[entry.key] == null
                                    ? manaIcon
                                    : spellEffectIcon(
                                        widget.spells[entry.key]!.effect),
                                size: 16,
                                color: widget.spells[entry.key] == null
                                    ? manaColor
                                    : spellEffectColor(
                                        widget.spells[entry.key]!.effect),
                              ),
                              label: Text(
                                '${_spellDisplayName(entry.key, widget.spells, lang)} '
                                '· ${entry.value}',
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                  const SizedBox(height: 12),
                  Text(tr(ref, 'sim_by_profession_label'),
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  for (final entry in _professionTotals(results).entries)
                    Text(
                      '${_professionDisplayName(entry.key, widget.professions)}: '
                      '${entry.value.runs} ${entry.value.runs == 1 ? 'run' : 'runs'} · '
                      '${tr(ref, 'sim_fights_label').toLowerCase()} ${entry.value.won} / ${entry.value.lost} · '
                      '${tr(ref, 'sim_spells_cast_label').toLowerCase()} ${entry.value.casts}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    tr(ref, 'sim_combat_model_note'),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
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
                                if (g.fightsLost > 0)
                                  '${g.fightsLost} ${tr(ref, 'sim_fight_lost_label')}',
                                if (g.spellCasts > 0)
                                  '${g.spellCasts} ${tr(ref, 'sim_spells_cast_label').toLowerCase()}',
                                if (g.goldDelta != 0) 'gold Δ${g.goldDelta}',
                                if (g.alignmentDelta != 0)
                                  'align Δ${g.alignmentDelta}',
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
                            Expanded(
                                child: Text(g.label,
                                    style:
                                        Theme.of(context).textTheme.bodySmall)),
                            Text(
                              '${g.nodeCount}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
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
                            Expanded(
                                child: Text(g.label,
                                    style:
                                        Theme.of(context).textTheme.bodySmall)),
                            Text(
                              '${g.nodeCount}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (single != null) ...[
                  const Divider(height: 24),
                  _SingleRunDetail(
                    result: single,
                    shops: widget.shops,
                    quests: widget.quests,
                    professions: widget.professions,
                    spells: widget.spells,
                    strategyLabel: tr(ref, _strategyLabelKey(batch.strategy)),
                  ),
                ] else ...[
                  const Divider(height: 24),
                  Text(tr(ref, 'individual_runs_label'),
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  for (var i = 0;
                      i <
                          (_showAllRuns
                              ? results.length
                              : results.length.clamp(0, _runListPreviewCount));
                      i++)
                    InkWell(
                      onTap: () => _viewRun(
                          results[i], batch.results.indexOf(results[i])),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '#${batch.results.indexOf(results[i]) + 1}: ${results[i].finalGold}g, '
                                '${tr(ref, 'final_alignment_label')} ${results[i].finalAlignment}, '
                                '${results[i].steps.length} ${tr(ref, 'nodes_visited_label')}'
                                '${results[i].hasCharacter ? ' · ${_professionDisplayName(results[i].professionId, widget.professions)} L${results[i].finalLevel} · ${results[i].totalCasts} ${tr(ref, 'sim_spells_cast_label').toLowerCase()}' : ''}',
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
                      onPressed: () =>
                          setState(() => _showAllRuns = !_showAllRuns),
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
