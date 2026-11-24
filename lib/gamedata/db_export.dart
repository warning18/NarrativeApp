import 'dart:convert';

import 'db_schema.dart';

/// The game data as files to take away from the Data tab (Edit Mode): a
/// collection's records as JSON or as a CSV table, every collection at
/// once, and every text of the game with its French beside it.
///
/// CSV here is comma-separated, one line per row (CRLF), every cell quoted,
/// and starts with a UTF-8 byte order mark so spreadsheets read the French
/// accents right. A cell holding a list or a map carries it as JSON.

const String _bom = '﻿';

/// [records] as they are stored, keyed by id, indented.
String recordsJson(Map<String, dynamic> records) =>
    const JsonEncoder.withIndent('  ').convert(records);

/// Every collection in one JSON object: collection id -> its records.
String allRecordsJson(Map<String, Map<String, dynamic>> collections) =>
    const JsonEncoder.withIndent('  ').convert(collections);

/// [records] as a table: one row per record, an `id` column (the record's
/// key) and one column per field, in [schema]'s order and then any other
/// field a record carries.
String recordsCsv(DbSchema schema, Map<String, dynamic> records) {
  final columns = <String>[];
  final seen = <String>{};
  void add(String key) {
    if (seen.add(key)) columns.add(key);
  }

  final present = <String>{
    for (final record in records.values)
      if (record is Map)
        for (final key in record.keys) key.toString(),
  };
  for (final field in schema.fields) {
    if (present.contains(field.key)) add(field.key);
  }
  for (final record in records.values) {
    if (record is Map) {
      for (final key in record.keys) {
        add(key.toString());
      }
    }
  }
  final out = StringBuffer(_bom)..write(_row(['id', ...columns]));
  for (final entry in records.entries) {
    final record = entry.value is Map ? entry.value as Map : const {};
    out.write(_row([
      entry.key,
      for (final column in columns) _cell(record[column]),
    ]));
  }
  return out.toString();
}

/// Every field of every record of every collection, one row each
/// (collection, id, field, value): the whole database in one table.
String allRecordsCsv(Map<String, Map<String, dynamic>> collections) {
  final out = StringBuffer(_bom)
    ..write(_row(['collection', 'id', 'field', 'value']));
  for (final collection in collections.entries) {
    for (final record in collection.value.entries) {
      final fields = record.value is Map ? record.value as Map : const {};
      for (final field in fields.entries) {
        out.write(_row([
          collection.key,
          record.key,
          field.key.toString(),
          _cell(field.value),
        ]));
      }
    }
  }
  return out.toString();
}

/// One piece of text in a record: where it sits (`description`,
/// `weapons[1].weaponName`, `encounterText[2]`), in English and French.
class RecordText {
  const RecordText(this.path, this.english, this.french);

  final String path;
  final String english;
  final String french;
}

/// Every text in [record]: each field with a French twin (`name` and
/// `name_fr`, or the older `nameFr`), nested ones included (a ship's
/// weapon names), lists line by line; and a field named like a text
/// (`faceName`, `lockedText`, see [_textKey]) that has no French yet,
/// English only. Ids, flags and numbers stay out. [schemaKeys] are the
/// collection's field keys, so a text whose French is not written yet
/// still shows.
List<RecordText> recordTexts(Map record, {Set<String> schemaKeys = const {}}) {
  final texts = <RecordText>[];
  _collectTexts(record, '', schemaKeys, texts);
  return texts;
}

/// A field name that holds words for the player to read, French or not:
/// `…Name`, `…Text`, `…Line(s)`, `…Title`, `…Label`, `…Message`,
/// `…Description`, `…Hint`, `…Dialogue`.
final RegExp _textKey = RegExp(
    r'(name|text|lines?|title|label|message|description|hint|dialogue)$',
    caseSensitive: false);

bool _isWords(Object? value) =>
    value is String || (value is List && value.every((e) => e is String));

void _collectTexts(
    Map map, String prefix, Set<String> schemaKeys, List<RecordText> out) {
  final keys = [for (final key in map.keys) key.toString()];
  bool known(String key) => map.containsKey(key) || schemaKeys.contains(key);
  String? twinOf(String key) {
    for (final twin in ['${key}_fr', '${key}Fr']) {
      if (known(twin)) return twin;
    }
    return null;
  }

  String? baseOf(String key) {
    if (key.endsWith('_fr') && key.length > 3) {
      return key.substring(0, key.length - 3);
    }
    if (key.endsWith('Fr') && key.length > 2) {
      final base = key.substring(0, key.length - 2);
      if (known(base)) return base;
    }
    return null;
  }

  void emit(String path, Object? english, Object? french) {
    if (english is List || french is List) {
      final en = english is List ? english : const [];
      final fr = french is List ? french : const [];
      for (var i = 0; i < en.length || i < fr.length; i++) {
        emit('$path[$i]', i < en.length ? en[i] : null,
            i < fr.length ? fr[i] : null);
      }
      return;
    }
    final en = english is String ? english : '';
    final fr = french is String ? french : '';
    if (en.trim().isEmpty && fr.trim().isEmpty) return;
    out.add(RecordText(path, en, fr));
  }

  for (final key in keys) {
    final value = map[key];
    final path = '$prefix$key';
    final base = baseOf(key);
    if (base != null) {
      // A French text is written out beside its English; one with no
      // English field at all still shows, French only.
      if (!map.containsKey(base)) emit('$prefix$base', null, value);
      continue;
    }
    final twin = twinOf(key);
    if (twin != null) {
      emit(path, value, map[twin]);
      continue;
    }
    if (_textKey.hasMatch(key) && _isWords(value)) {
      emit(path, value, null);
      continue;
    }
    if (value is Map) {
      _collectTexts(value, '$path.', const {}, out);
    } else if (value is List) {
      for (var i = 0; i < value.length; i++) {
        final element = value[i];
        if (element is Map) {
          _collectTexts(element, '$path[$i].', const {}, out);
        }
      }
    }
  }
}

/// Every text of every collection in [collections] (schema and records), one
/// row each: collection, id, field, English, French.
String textsCsv(List<(DbSchema, Map<String, dynamic>)> collections) {
  final out = StringBuffer(_bom)
    ..write(_row(['collection', 'id', 'field', 'english', 'french']));
  for (final (schema, records) in collections) {
    final keys = {for (final field in schema.fields) field.key};
    for (final record in records.entries) {
      if (record.value is! Map) continue;
      for (final text in recordTexts(record.value as Map, schemaKeys: keys)) {
        out.write(_row(
            [schema.id, record.key, text.path, text.english, text.french]));
      }
    }
  }
  return out.toString();
}

/// A value as a CSV cell's text: nothing for null, lists and maps as JSON.
String _cell(Object? value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is Map || value is List) return jsonEncode(value);
  return value.toString();
}

String _row(List<String> cells) =>
    '${cells.map((cell) => '"${cell.replaceAll('"', '""')}"').join(',')}\r\n';
