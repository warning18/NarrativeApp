import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_export.dart';
import '../gamedata/db_schema.dart';
import '../providers/game_db_providers.dart';
import '../utils/game_icons.dart';
import '../widgets/data_export_sheet.dart';
import 'data_summary_screen.dart';
import 'game_config_screen.dart';
import 'game_db_list_screen.dart';
import 'main_story_screen.dart';
import 'story_comments_review_screen.dart';

class GameDataHomeScreen extends ConsumerWidget {
  const GameDataHomeScreen({super.key});

  /// Every collection's records, each once it has loaded.
  static Future<Map<String, Map<String, dynamic>>> _allRecords(
      WidgetRef ref) async {
    return {
      for (final schema in gameDbSchemas)
        schema.id: await ref.read(gameDbProvider(schema).notifier).whenLoaded(),
    };
  }

  Future<void> _downloadAll(BuildContext context, WidgetRef ref) {
    return showDataExportSheet(
      context,
      ref,
      title: 'Download all data (${gameDbSchemas.length} collections)',
      options: [
        DataExportOption(
          icon: Icons.data_object,
          title: 'All records (JSON)',
          subtitle: 'Every collection in one file, every field of every record',
          filename: 'game_data.json',
          build: () async => allRecordsJson(await _allRecords(ref)),
        ),
        DataExportOption(
          icon: Icons.table_chart_outlined,
          title: 'All records (CSV)',
          subtitle: 'One row per field: collection, id, field, value',
          filename: 'game_data.csv',
          build: () async => allRecordsCsv(await _allRecords(ref)),
        ),
        DataExportOption(
          icon: Icons.translate,
          title: 'All texts (CSV)',
          subtitle:
              'Every text of the game, one row each: English and French side by side',
          filename: 'game_texts.csv',
          build: () async {
            final all = await _allRecords(ref);
            return textsCsv([
              for (final schema in gameDbSchemas) (schema, all[schema.id]!),
            ]);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: ListTile(
            key: const Key('data_download_all'),
            leading: const Icon(Icons.download_outlined),
            title: const Text('Download all data'),
            subtitle: const Text(
                'Every collection as JSON or CSV, or every text in English and French'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _downloadAll(context, ref),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.insights_outlined),
            title: const Text('Data Summary'),
            subtitle: const Text(
                'KPIs across all collections: record counts, visual coverage, issues'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DataSummaryScreen()),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('New Game Defaults'),
            subtitle: const Text('Starting stats for a new player save'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GameConfigScreen()),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Main Story'),
            subtitle: const Text(
                'The fixed chapter beats every playthrough passes through'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MainStoryScreen()),
              );
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.comment_outlined),
            title: const Text('Review Comments'),
            subtitle: const Text(
                'Every story node with a reviewer note left in Edit Mode'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const StoryCommentsReviewScreen()),
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(),
        ),
        ...gameDbSchemas.map(
          (schema) => Card(
            child: ListTile(
              leading: Icon(gameDbIcon(schema.id)),
              title: Text(schema.label),
              subtitle: Text(
                  'key: ${schema.primaryKeyField} · ${schema.fields.length} fields'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => GameDbListScreen(schema: schema)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
