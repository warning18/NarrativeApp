import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../providers/game_db_providers.dart';
import 'game_db_record_editor_screen.dart';

class GameDbListScreen extends ConsumerWidget {
  const GameDbListScreen({super.key, required this.schema});

  final DbSchema schema;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(gameDbProvider(schema));

    return Scaffold(
      appBar: AppBar(
        title: Text(schema.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy JSON',
            onPressed: () => _copyJson(context, recordsAsync.value),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Import JSON',
            onPressed: () => _showImportDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to bundled defaults',
            onPressed: () => _confirmReset(context, ref),
          ),
        ],
      ),
      body: recordsAsync.when(
        data: (records) {
          final keys = records.keys.toList()..sort();
          if (keys.isEmpty) {
            return const Center(child: Text('No records yet. Tap + to add one.'));
          }
          return ListView.builder(
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final record = records[key] as Map<String, dynamic>;
              final subtitleValue =
                  schema.titleField != null ? record[schema.titleField]?.toString() ?? '' : '';
              return ListTile(
                title: Text(key),
                subtitle: subtitleValue.isNotEmpty ? Text(subtitleValue) : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ref.read(gameDbProvider(schema).notifier).deleteRecord(key),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GameDbRecordEditorScreen(
                        schema: schema,
                        recordKey: key,
                        initialRecord: record,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load: $error'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add entry',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GameDbRecordEditorScreen(schema: schema),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _copyJson(BuildContext context, Map<String, dynamic>? records) async {
    if (records == null) return;
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(records)),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('JSON copied to clipboard.')),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset to defaults?'),
        content: Text(
          'This discards your edits to ${schema.label} and reloads the bundled data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(gameDbProvider(schema).notifier).resetToDefaults();
    }
  }

  Future<void> _showImportDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final imported = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Import ${schema.label} JSON'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            minLines: 6,
            maxLines: 12,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'Paste a JSON object of id -> record',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              try {
                final decoded = json.decode(controller.text) as Map<String, dynamic>;
                Navigator.pop(dialogContext, decoded);
              } catch (_) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Invalid JSON.')),
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (imported != null) {
      await ref.read(gameDbProvider(schema).notifier).replaceAll(imported);
    }
  }
}
