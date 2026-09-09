import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../gamedata/field_schema.dart';
import '../providers/game_db_providers.dart';
import '../providers/story_providers.dart';

class GameDbRecordEditorScreen extends ConsumerStatefulWidget {
  const GameDbRecordEditorScreen({
    super.key,
    required this.schema,
    this.recordKey,
    this.initialRecord,
  });

  final DbSchema schema;
  final String? recordKey;
  final Map<String, dynamic>? initialRecord;

  @override
  ConsumerState<GameDbRecordEditorScreen> createState() => _GameDbRecordEditorScreenState();
}

class _GameDbRecordEditorScreenState extends ConsumerState<GameDbRecordEditorScreen> {
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, bool> _boolValues = {};
  final Map<String, String> _enumValues = {};
  final Map<String, List<String>> _multiSelectValues = {};
  String? _error;

  bool get _isNew => widget.initialRecord == null;

  @override
  void initState() {
    super.initState();
    final record = widget.initialRecord ?? <String, dynamic>{};
    for (final field in widget.schema.fields) {
      final value = record[field.key];
      switch (field.type) {
        case FieldType.boolean:
          _boolValues[field.key] = value as bool? ?? (field.defaultValue as bool? ?? false);
          break;
        case FieldType.enumeration:
        case FieldType.reference:
          _enumValues[field.key] = (value as String?) ??
              (field.defaultValue as String?) ??
              (field.type == FieldType.enumeration && field.enumOptions.isNotEmpty
                  ? field.enumOptions.first
                  : '');
          break;
        case FieldType.stringList:
          final list = (value as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
          _textControllers[field.key] = TextEditingController(text: list.join(', '));
          break;
        case FieldType.referenceList:
        case FieldType.multiEnum:
          _multiSelectValues[field.key] =
              (value as List?)?.map((e) => e.toString()).toList() ?? <String>[];
          break;
        case FieldType.json:
          final encoded =
              value == null ? '[]' : const JsonEncoder.withIndent('  ').convert(value);
          _textControllers[field.key] = TextEditingController(text: encoded);
          break;
        case FieldType.text:
        case FieldType.multilineText:
        case FieldType.image:
          _textControllers[field.key] = TextEditingController(
            text: value?.toString() ?? (field.defaultValue?.toString() ?? ''),
          );
          break;
        case FieldType.integer:
        case FieldType.decimal:
          _textControllers[field.key] = TextEditingController(
            text: value != null
                ? value.toString()
                : (field.defaultValue != null ? field.defaultValue.toString() : ''),
          );
          break;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    final result = <String, dynamic>{};
    for (final field in widget.schema.fields) {
      switch (field.type) {
        case FieldType.boolean:
          result[field.key] = _boolValues[field.key] ?? false;
          break;
        case FieldType.enumeration:
        case FieldType.reference:
          result[field.key] = _enumValues[field.key] ?? '';
          break;
        case FieldType.stringList:
          final raw = _textControllers[field.key]!.text;
          result[field.key] =
              raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          break;
        case FieldType.referenceList:
        case FieldType.multiEnum:
          result[field.key] = _multiSelectValues[field.key] ?? <String>[];
          break;
        case FieldType.json:
          final raw = _textControllers[field.key]!.text.trim();
          try {
            result[field.key] = raw.isEmpty ? <dynamic>[] : json.decode(raw);
          } catch (_) {
            setState(() => _error = 'Invalid JSON in "${field.label}".');
            return;
          }
          break;
        case FieldType.integer:
          final raw = _textControllers[field.key]!.text.trim();
          result[field.key] = int.tryParse(raw) ?? 0;
          break;
        case FieldType.decimal:
          final raw = _textControllers[field.key]!.text.trim();
          result[field.key] = double.tryParse(raw) ?? 0.0;
          break;
        case FieldType.text:
        case FieldType.multilineText:
        case FieldType.image:
          result[field.key] = _textControllers[field.key]!.text;
          break;
      }
    }

    final newKey = (result[widget.schema.primaryKeyField]?.toString() ?? '').trim();
    if (newKey.isEmpty) {
      setState(() => _error = 'The "${widget.schema.primaryKeyField}" field cannot be empty.');
      return;
    }

    setState(() => _error = null);

    final notifier = ref.read(gameDbProvider(widget.schema).notifier);
    if (!_isNew && widget.recordKey != null && widget.recordKey != newKey) {
      notifier.deleteRecord(widget.recordKey!);
    }
    notifier.upsertRecord(newKey, result);
    Navigator.of(context).pop();
  }

  List<String> _referenceOptions(String referenceSchemaId) {
    if (referenceSchemaId == storyEventsReferenceId) {
      final storyAsync = ref.watch(storyDataProvider);
      return storyAsync.maybeWhen(
        data: (story) => story.nodes.keys.toList()..sort(),
        orElse: () => const <String>[],
      );
    }
    DbSchema? targetSchema;
    for (final schema in gameDbSchemas) {
      if (schema.id == referenceSchemaId) {
        targetSchema = schema;
        break;
      }
    }
    if (targetSchema == null) return const <String>[];
    final recordsAsync = ref.watch(gameDbProvider(targetSchema));
    return recordsAsync.maybeWhen(
      data: (records) => records.keys.toList()..sort(),
      orElse: () => const <String>[],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New ${widget.schema.label} entry' : (widget.recordKey ?? '')),
        actions: [
          IconButton(icon: const Icon(Icons.check), tooltip: 'Save', onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ...widget.schema.fields.map(_buildField),
        ],
      ),
    );
  }

  Widget _buildField(FieldSchema field) {
    switch (field.type) {
      case FieldType.boolean:
        return SwitchListTile(
          title: Text(field.label),
          value: _boolValues[field.key] ?? false,
          onChanged: (value) => setState(() => _boolValues[field.key] = value),
        );
      case FieldType.enumeration:
        final options = field.enumOptions;
        final current = _enumValues[field.key];
        final dropdownValue =
            options.contains(current) ? current : (options.isNotEmpty ? options.first : null);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            value: dropdownValue,
            decoration: InputDecoration(labelText: field.label, border: const OutlineInputBorder()),
            items: options
                .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                .toList(),
            onChanged: (value) => setState(() => _enumValues[field.key] = value ?? ''),
          ),
        );
      case FieldType.reference:
        final options = _referenceOptions(field.referenceSchemaId ?? '');
        final current = _enumValues[field.key] ?? '';
        final dropdownValue = current.isEmpty || options.contains(current) ? current : '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            value: dropdownValue,
            decoration: InputDecoration(labelText: field.label, border: const OutlineInputBorder()),
            items: [
              const DropdownMenuItem(value: '', child: Text('(none)')),
              ...options.map((option) => DropdownMenuItem(value: option, child: Text(option))),
            ],
            onChanged: (value) => setState(() => _enumValues[field.key] = value ?? ''),
          ),
        );
      case FieldType.referenceList:
        return _buildMultiSelect(field, _referenceOptions(field.referenceSchemaId ?? ''));
      case FieldType.multiEnum:
        return _buildMultiSelect(field, field.enumOptions);
      case FieldType.stringList:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _textControllers[field.key],
            decoration: InputDecoration(
              labelText: '${field.label} (comma-separated)',
              border: const OutlineInputBorder(),
            ),
          ),
        );
      case FieldType.json:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _textControllers[field.key],
            minLines: 4,
            maxLines: 14,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            decoration: InputDecoration(
              labelText: field.label,
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
        );
      case FieldType.multilineText:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _textControllers[field.key],
            minLines: 2,
            maxLines: 6,
            decoration: InputDecoration(labelText: field.label, border: const OutlineInputBorder()),
          ),
        );
      case FieldType.integer:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _textControllers[field.key],
            keyboardType: const TextInputType.numberWithOptions(signed: true),
            decoration: InputDecoration(labelText: field.label, border: const OutlineInputBorder()),
          ),
        );
      case FieldType.decimal:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _textControllers[field.key],
            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
            decoration: InputDecoration(labelText: field.label, border: const OutlineInputBorder()),
          ),
        );
      case FieldType.text:
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _textControllers[field.key],
            decoration: InputDecoration(labelText: field.label, border: const OutlineInputBorder()),
          ),
        );
      case FieldType.image:
        final controller = _textControllers[field.key]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: field.label,
                    hintText: 'e.g. sword_iron.png',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) =>
                    _ImagePreview(schema: widget.schema, filename: value.text),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildMultiSelect(FieldSchema field, List<String> availableOptions) {
    final selected = _multiSelectValues[field.key] ?? const <String>[];
    final addable = availableOptions.where((o) => !selected.contains(o)).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(labelText: field.label, border: const OutlineInputBorder()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: selected
                    .map(
                      (value) => Chip(
                        label: Text(value),
                        onDeleted: () => setState(() {
                          _multiSelectValues[field.key] =
                              selected.where((v) => v != value).toList();
                        }),
                      ),
                    )
                    .toList(),
              ),
            if (selected.isNotEmpty) const SizedBox(height: 8),
            if (addable.isEmpty)
              Text(
                selected.isEmpty ? 'Nothing available to add yet.' : 'All options added.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Add...'),
                value: null,
                items: addable
                    .map((option) => DropdownMenuItem(value: option, child: Text(option)))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _multiSelectValues[field.key] = [...selected, value];
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.schema, required this.filename});

  final DbSchema schema;
  final String filename;

  @override
  Widget build(BuildContext context) {
    final path = filename.trim().isEmpty ? null : '${visualAssetFolder(schema)}${filename.trim()}';
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: path == null
          ? Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.outline)
          : Image.asset(
              path,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.image_not_supported_outlined,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
    );
  }
}
