import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/chapter_spine.dart';
import '../gamedata/balance_validation.dart';
import '../gamedata/db_schema.dart';
import '../gamedata/quest_validation.dart';
import '../providers/game_db_providers.dart';
import '../providers/story_providers.dart';
import '../utils/game_icons.dart';

class DataSummaryScreen extends ConsumerWidget {
  const DataSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsBySchema = <DbSchema, Map<String, dynamic>?>{};
    var totalRecords = 0;
    var visualTotal = 0;
    var visualFilled = 0;

    for (final schema in gameDbSchemas) {
      final records = ref.watch(gameDbProvider(schema)).value;
      recordsBySchema[schema] = records;
      if (records == null) continue;
      totalRecords += records.length;
      final visualField = schema.visualAssetField;
      if (visualField != null) {
        visualTotal += records.length;
        visualFilled += records.values.where((r) {
          final map = r as Map<String, dynamic>;
          return (map[visualField]?.toString() ?? '').isNotEmpty;
        }).length;
      }
    }

    final quests = recordsBySchema[questsSchema];
    final questIssues =
        quests != null ? validateQuestChapters(quests).length : 0;
    final visualCoverage = visualTotal == 0 ? 0.0 : visualFilled / visualTotal;
    final colorScheme = Theme.of(context).colorScheme;

    final story = ref.watch(storyDataProvider).value;
    final skills = recordsBySchema[skillsSchema];
    final shops = recordsBySchema[shopsSchema];
    final enemies = recordsBySchema[enemiesSchema];
    final balanceIssues =
        (story != null && skills != null && shops != null && enemies != null)
            ? validateBalance(
                story: story, skills: skills, shops: shops, enemies: enemies)
            : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Data Summary')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _KpiCard(
                icon: Icons.table_chart_outlined,
                label: 'Collections',
                value: '${gameDbSchemas.length}',
              ),
              _KpiCard(
                icon: Icons.storage_outlined,
                label: 'Total Records',
                value: '$totalRecords',
              ),
              _KpiCard(
                icon: Icons.map_outlined,
                label: 'Chapters',
                value: '${chapterSpines.length}',
              ),
              _KpiCard(
                icon: Icons.image_outlined,
                label: 'Visual Coverage',
                value:
                    '${(visualCoverage * 100).round()}% ($visualFilled/$visualTotal)',
              ),
              _KpiCard(
                icon: questIssues == 0
                    ? Icons.check_circle_outline
                    : Icons.error_outline,
                label: 'Quest Chapter Issues',
                value: '$questIssues',
                warning: questIssues > 0,
              ),
              _KpiCard(
                icon: balanceIssues == null
                    ? Icons.hourglass_empty
                    : balanceIssues.isEmpty
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                label: 'Reachability Issues',
                value: balanceIssues == null ? '…' : '${balanceIssues.length}',
                warning: (balanceIssues?.isNotEmpty ?? false),
              ),
            ],
          ),
          if (balanceIssues != null && balanceIssues.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Reachability & Balance',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Mandatory fights with no shop access first, dead-end skill chains, '
              'and story requirements that can never be satisfied.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colorScheme.outline),
            ),
            const SizedBox(height: 8),
            Card(
              color: colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: balanceIssues
                      .map(
                        (issue) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '• $issue',
                            style:
                                TextStyle(color: colorScheme.onErrorContainer),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text('Collections', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Record counts and how many entries have a visual asset assigned.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colorScheme.outline),
          ),
          const SizedBox(height: 8),
          ...gameDbSchemas.map(
            (schema) => _CollectionRow(
                schema: schema, records: recordsBySchema[schema]),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    this.warning = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = warning ? colorScheme.error : colorScheme.primary;
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accent),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: accent, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({required this.schema, required this.records});

  final DbSchema schema;
  final Map<String, dynamic>? records;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final count = records?.length ?? 0;
    final visualField = schema.visualAssetField;
    int? withVisual;
    if (records != null && visualField != null) {
      withVisual = records!.values.where((r) {
        final map = r as Map<String, dynamic>;
        return (map[visualField]?.toString() ?? '').isNotEmpty;
      }).length;
    }
    final progress =
        (withVisual != null && count > 0) ? withVisual / count : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(gameDbIcon(schema.id), color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(schema.label,
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    records == null ? 'Loading…' : '$count records',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$withVisual / $count have a visual asset',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colorScheme.outline),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
