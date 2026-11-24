// The simulator's exports: the file and clipboard helpers, the run
// transcript, the batch summary, CSV and JSON, cut out of
// playthrough_simulator_screen.dart with no change (wave 4a).
part of '../playthrough_simulator_screen.dart';

/// Writes [content] to a temp .txt file and hands it to the OS (share
/// sheet / a text viewer), for a real "export" rather than just a
/// clipboard copy. Falls back to telling the user what went wrong — some
/// devices have nothing registered to open a bare .txt file.
Future<void> _exportToFile(BuildContext context, WidgetRef ref, String content,
    String filename) async {
  try {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    await OpenFilex.open(file.path);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              '${trFor(ref.read(appLanguageProvider), 'export_failed_prefix')}: $e')),
    );
  }
}

Future<void> _copyToClipboard(
    BuildContext context, WidgetRef ref, String content) async {
  await Clipboard.setData(ClipboardData(text: content));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(tr(ref, 'transcript_copied_message'))),
  );
}

/// Renders one run as a plain-text transcript: its summary stats, then
/// every node visited with its narrative text and the choice taken from
/// it — the "node and text" export the QA workflow needs.
String _runTranscript(_SimResult result, String strategyLabel,
    {int? runNumber, Map<String, SpellSpec> spells = const {}}) {
  String spellName(String id) => spells[id]?.name ?? id;
  String casts(Map<String, int> m) => m.isEmpty
      ? 'none'
      : (m.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
          .map((e) => '${spellName(e.key)} x${e.value}')
          .join(', ');
  final b = StringBuffer();
  b.writeln(
      '=== Playthrough Transcript${runNumber != null ? ' — Run #$runNumber' : ''} ===');
  b.writeln('Strategy: $strategyLabel');
  b.writeln('Ending: ${result.endingSummary}');
  b.writeln(
    'Final gold: ${result.finalGold} | Final alignment: ${result.finalAlignment} | '
    'Nodes visited: ${result.steps.length} (unique: ${result.uniqueNodesVisited})',
  );
  b.writeln(
      'Shops discovered: ${result.shopsDiscovered.isEmpty ? 'none' : result.shopsDiscovered.join(', ')}');
  b.writeln(
      'Quests discovered: ${result.questsDiscovered.isEmpty ? 'none' : result.questsDiscovered.join(', ')}');
  b.writeln(
      'Flags collected: ${result.flags.isEmpty ? 'none' : result.flags.join(', ')}');
  if (result.hasCharacter) {
    b.writeln(
        'Character: ${result.raceId} ${result.professionId}, level ${result.finalLevel} | '
        'Fights won/lost: ${result.fightsWon}/${result.fightsLost} | '
        'Potions used: ${result.potionsUsed}');
    b.writeln(
        'Spells cast: ${casts(result.spellsCast)} | Mana from dice: ${result.manaGained}'
        '${result.spellbooksBought.isEmpty ? '' : ' | Spellbooks bought: ${result.spellbooksBought.map(spellName).join(', ')}'}');
    b.writeln(
        'Offers taken: ${result.offersTaken} | Skills learned: ${result.skillsLearned} | '
        'Signs taken: ${result.signsTaken.isEmpty ? 'none' : result.signsTaken.join(', ')}');
    b.writeln(
        'Gear worn: ${result.gear.isEmpty ? 'none' : (result.gear.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((e) => '${e.key} ${e.value}').join(', ')}'
        '${result.die.isEmpty ? '' : ' | Die: ${result.die}'}'
        '${result.merged.isEmpty ? '' : ' | Crafted: ${result.merged.join(', ')}'}');
    if (result.offerPicks.isNotEmpty) {
      b.writeln();
      b.writeln('--- Clan offers (banners offered -> taken, why) ---');
      for (final pick in result.offerPicks) {
        b.writeln(pick.line);
      }
    }
    if (result.companionLog.isNotEmpty) {
      b.writeln();
      b.writeln('--- Companions (recruits, picks, swaps, losses, why) ---');
      for (final event in result.companionLog) {
        b.writeln(event.line);
      }
      b.writeln('Party at the end: '
          '${result.companions.isEmpty ? 'none' : result.companions.join(', ')}'
          '${result.companionKnockouts.isEmpty ? '' : ' | Knock-outs: ${result.companionKnockouts.entries.map((e) => '${e.key} ${e.value}').join(', ')}'}');
    }
  }
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
      final fight = s.fightWon == null
          ? ''
          : ' — ${s.fightWon! ? 'won' : 'lost'}'
              '${s.fightAttempts > 1 ? ' (${s.fightAttempts} attempts)' : ''}';
      b.writeln(
          '→ Chose: "${s.choiceText}"${s.enemyId != null ? ' [combat: ${s.enemyId}$fight]' : ''}');
      if (s.spellsCast.isNotEmpty) {
        b.writeln('  Spells cast: ${casts(s.spellsCast)}');
      }
    }
  }
  return b.toString();
}

String _batchSummaryText(String strategyLabel, List<_SimResult> results,
    {Map<String, SpellSpec> spells = const {}}) {
  final b = StringBuffer();
  b.writeln('=== Batch Summary ===');
  b.writeln('Strategy: $strategyLabel');
  b.writeln('Runs: ${results.length}');
  b.writeln(
      'Average nodes visited: ${_avg(results.map((r) => r.steps.length)).toStringAsFixed(1)}');
  b.writeln(
      'Average final gold: ${_avg(results.map((r) => r.finalGold)).toStringAsFixed(1)}');
  b.writeln(
      'Average final alignment: ${_avg(results.map((r) => r.finalAlignment)).toStringAsFixed(1)}');
  b.writeln(
      'Average combat encounters: ${_avg(results.map((r) => r.combatEncounters)).toStringAsFixed(1)}');
  if (results.any((r) => r.hasCharacter)) {
    b.writeln(
        'Average fights won / lost: ${_avg(results.map((r) => r.fightsWon)).toStringAsFixed(1)} / '
        '${_avg(results.map((r) => r.fightsLost)).toStringAsFixed(1)}');
    b.writeln(
        'Average offers taken: ${_avg(results.map((r) => r.offersTaken)).toStringAsFixed(1)} '
        '(skills ${_avg(results.map((r) => r.skillsLearned)).toStringAsFixed(1)}, '
        'signs ${_avg(results.map((r) => r.signsTaken.length)).toStringAsFixed(1)})');
    b.writeln(
        'Average spells cast: ${_avg(results.map((r) => r.totalCasts)).toStringAsFixed(1)} '
        '(mana from dice ${_avg(results.map((r) => r.manaGained)).toStringAsFixed(1)})');
    final totals = _spellCastTotals(results);
    if (totals.isNotEmpty) {
      b.writeln(
          'Casts by spell: ${totals.entries.map((e) => '${spells[e.key]?.name ?? e.key} x${e.value}').join(', ')}');
    }
    for (final entry in _professionTotals(results).entries) {
      b.writeln(
          '- ${entry.key}: ${entry.value.runs} runs, fights won/lost ${entry.value.won}/${entry.value.lost}, ${entry.value.casts} casts');
    }
  }
  final stepCap = results.where((r) => r.reachedStepCap).length;
  if (stepCap > 0) {
    b.writeln(
        '$stepCap/${results.length} runs never reached an ending (hit the step cap).');
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
      '${g.combatCount} combats (${g.fightsLost} lost, ${g.spellCasts} spells), gold Δ${g.goldDelta}, alignment Δ${g.alignmentDelta}',
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
String _fullBatchTranscript(String strategyLabel, List<_SimResult> results,
    {Map<String, SpellSpec> spells = const {}}) {
  final b = StringBuffer()
    ..writeln(_batchSummaryText(strategyLabel, results, spells: spells));
  for (var i = 0; i < results.length; i++) {
    b
      ..writeln()
      ..writeln(_runTranscript(results[i], strategyLabel,
          runNumber: i + 1, spells: spells));
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
    'Profession',
    'Level',
    'Fights Won',
    'Fights Lost',
    'Spells Cast',
    'Casts By Spell',
    'Mana From Dice',
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
      r.professionId,
      '${r.finalLevel}',
      '${r.fightsWon}',
      '${r.fightsLost}',
      '${r.totalCasts}',
      r.spellsCast.entries.map((e) => '${e.key} x${e.value}').join('; '),
      '${r.manaGained}',
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
          'raceId': results[i].raceId,
          'professionId': results[i].professionId,
          'finalLevel': results[i].finalLevel,
          'fightsWon': results[i].fightsWon,
          'fightsLost': results[i].fightsLost,
          'spellsCast': results[i].spellsCast,
          'manaGained': results[i].manaGained,
          'potionsUsed': results[i].potionsUsed,
          'spellbooksBought': results[i].spellbooksBought,
          'signsTaken': results[i].signsTaken,
          'path': results[i].path,
        },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(data);
}
