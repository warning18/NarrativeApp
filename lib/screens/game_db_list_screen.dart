import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../gamedata/field_schema.dart';
import '../gamedata/quest_validation.dart';
import '../providers/game_db_providers.dart';
import 'game_db_record_editor_screen.dart';

class GameDbListScreen extends ConsumerStatefulWidget {
  const GameDbListScreen({super.key, required this.schema});

  final DbSchema schema;

  @override
  ConsumerState<GameDbListScreen> createState() => _GameDbListScreenState();
}

class _GameDbListScreenState extends ConsumerState<GameDbListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  String? _filterValue;
  late final FieldSchema? _filterField = _findEnumField(widget.schema);

  DbSchema get schema => widget.schema;

  static FieldSchema? _findEnumField(DbSchema schema) {
    for (final field in schema.fields) {
      if (field.type == FieldType.enumeration &&
          field.enumOptions.isNotEmpty) {
        return field;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          var keys = records.keys.toList()..sort();
          if (_search.isNotEmpty) {
            final query = _search.toLowerCase();
            keys = keys.where((key) {
              final record = records[key] as Map<String, dynamic>;
              final title = schema.titleField != null
                  ? record[schema.titleField]?.toString() ?? ''
                  : '';
              return key.toLowerCase().contains(query) ||
                  title.toLowerCase().contains(query);
            }).toList();
          }
          final filterField = _filterField;
          if (filterField != null && _filterValue != null) {
            keys = keys.where((key) {
              final record = records[key] as Map<String, dynamic>;
              return record[filterField.key]?.toString() == _filterValue;
            }).toList();
          }

          final issues = schema.id == 'quests'
              ? validateQuestChapters(records)
              : const <String>[];

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) => setState(() => _search = value),
                      ),
                    ),
                    if (filterField != null) ...[
                      const SizedBox(width: 8),
                      DropdownButton<String?>(
                        value: _filterValue,
                        hint: Text(filterField.label),
                        items: [
                          const DropdownMenuItem<String?>(
                              value: null, child: Text('All')),
                          ...filterField.enumOptions.map(
                            (option) => DropdownMenuItem<String?>(
                              value: option,
                              child: Text(option),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _filterValue = value),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: keys.isEmpty
                    ? const Center(child: Text('No matching records.'))
                    : ListView.builder(
                        itemCount: keys.length + (issues.isEmpty ? 0 : 1),
                        itemBuilder: (context, index) {
                          if (issues.isNotEmpty && index == 0) {
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Chapter structure issues',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onErrorContainer,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...issues.map(
                                    (issue) => Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        '• $issue',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          final key = keys[index - (issues.isEmpty ? 0 : 1)];
                          final record = records[key] as Map<String, dynamic>;
                          final subtitleValue = schema.titleField != null
                              ? record[schema.titleField]?.toString() ?? ''
                              : '';
                          return ListTile(
                            title: Text(key),
                            subtitle: subtitleValue.isNotEmpty
                                ? Text(subtitleValue)
                                : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Delete',
                              onPressed: () =>
                                  _confirmDelete(context, ref, key),
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
                      ),
              ),
            ],
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

  Future<void> _copyJson(
      BuildContext context, Map<String, dynamic>? records) async {
    if (records == null) return;
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(records)),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('JSON copied to clipboard.')),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this entry?'),
        content: Text('This permanently removes "$key" from ${schema.label}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(gameDbProvider(schema).notifier).deleteRecord(key);
    }
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
                final decoded =
                    json.decode(controller.text) as Map<String, dynamic>;
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
    controller.dispose();
    if (imported != null) {
      await ref.read(gameDbProvider(schema).notifier).replaceAll(imported);
    }
  }
}
