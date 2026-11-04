// One simulated run in detail, cut out of
// playthrough_simulator_screen.dart with no change (wave 4a).
part of '../playthrough_simulator_screen.dart';

/// " — won (2 attempts)" / " — lost" for a step's fight, or '' when the
/// walk didn't play it out.
String _fightTag(_SimStep step, WidgetRef ref) {
  final won = step.fightWon;
  if (won == null) return '';
  final outcome =
      won ? tr(ref, 'sim_fight_won_label') : tr(ref, 'sim_fight_lost_label');
  final attempts = step.fightAttempts > 1
      ? ' (${step.fightAttempts} ${tr(ref, 'sim_attempts_label')})'
      : '';
  return ' — $outcome$attempts';
}

class _SingleRunDetail extends ConsumerStatefulWidget {
  const _SingleRunDetail({
    required this.result,
    required this.shops,
    required this.quests,
    required this.professions,
    required this.spells,
    required this.strategyLabel,
    this.runNumber,
    this.scrollController,
  });

  final _SimResult result;
  final Map<String, dynamic> shops;
  final Map<String, dynamic> quests;
  final Map<String, dynamic> professions;
  final Map<String, SpellSpec> spells;
  final String strategyLabel;
  final int? runNumber;
  final ScrollController? scrollController;

  @override
  ConsumerState<_SingleRunDetail> createState() => _SingleRunDetailState();
}

class _SingleRunDetailState extends ConsumerState<_SingleRunDetail> {
  int?
      _chapterFilter; // null = show all chapters. Use -1 as the "Prologue" sentinel.

  String _namesFor(
      Set<String> ids, Map<String, dynamic> records, String nameField) {
    if (ids.isEmpty) return '—';
    return ids
        .map((id) =>
            (records[id] as Map<String, dynamic>?)?[nameField]?.toString() ??
            id)
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final chapters = result.steps.map((s) => s.chapter ?? -1).toSet().toList()
      ..sort();
    final filteredSteps = _chapterFilter == null
        ? result.steps
        : result.steps
            .where((s) => (s.chapter ?? -1) == _chapterFilter)
            .toList();

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
              _runTranscript(result, widget.strategyLabel,
                  runNumber: widget.runNumber, spells: widget.spells),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: tr(ref, 'export_button'),
            onPressed: () => _exportToFile(
              context,
              ref,
              _runTranscript(result, widget.strategyLabel,
                  runNumber: widget.runNumber, spells: widget.spells),
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
      Text(
          '${tr(ref, 'shops_discovered_label')}: ${_namesFor(result.shopsDiscovered, widget.shops, 'shopName')}'),
      Text(
        '${tr(ref, 'quests_discovered_label')}: ${_namesFor(result.questsDiscovered, widget.quests, 'questName')}',
      ),
      Text(
        '${tr(ref, 'flags_collected_label')}: ${result.flags.isEmpty ? '—' : result.flags.join(', ')}',
      ),
      if (result.hasCharacter) ...[
        const SizedBox(height: 8),
        Text(
          '${tr(ref, 'sim_character_label')}: '
          '${_professionDisplayName(result.professionId, widget.professions)} '
          '(${result.raceId}) · ${tr(ref, 'level_abbrev')} ${result.finalLevel}',
        ),
        Text(
            '${tr(ref, 'sim_fights_label')}: ${result.fightsWon} / ${result.fightsLost}'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2, right: 4),
              child: Icon(manaIcon, size: 16, color: manaColor),
            ),
            Expanded(
              child: Text(
                '${tr(ref, 'sim_spells_cast_label')}: '
                '${_castsSummary(result.spellsCast, widget.spells, ref.watch(appLanguageProvider)) ?? tr(ref, 'sim_no_spells_cast')}'
                ' · ${tr(ref, 'sim_mana_from_dice_label').toLowerCase()} ${result.manaGained}',
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: 12),
      Text(tr(ref, 'path_summary_label'),
          style: Theme.of(context).textTheme.titleSmall),
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
                      '${entry.value.enemyId != null ? '  [combat: ${entry.value.enemyId}${_fightTag(entry.value, ref)}]' : ''}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    if (entry.value.spellsCast.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${tr(ref, 'sim_spells_cast_label')}: '
                          '${_castsSummary(entry.value.spellsCast, widget.spells, ref.watch(appLanguageProvider))}',
                          style:
                              const TextStyle(color: manaColor, fontSize: 12),
                        ),
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
