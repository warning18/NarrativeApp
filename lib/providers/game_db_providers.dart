import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/description_text.dart';
import '../data/forge_roll.dart' show withForgedVariants;
import '../gamedata/db_schema.dart';
import '../gamedata/game_db_repository.dart';
import '../l10n/app_locale.dart';

final gameDbRepositoryProvider =
    Provider.family<GameDbRepository, DbSchema>((ref, schema) {
  return GameDbRepository(schema);
});

/// [records] as [schema]'s table is read: the items table resolves forged
/// variants (`<baseId>@fine`, forge_roll.dart's ForgedItems); [french] when
/// its English fields already hold the French text. Other tables as they
/// are.
Map<String, dynamic> _readableTable(
        DbSchema schema, Map<String, dynamic> records, {bool french = false}) =>
    schema.id == itemsSchema.id
        ? withForgedVariants(records, french: french)
        : records;

class _GameDbNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  _GameDbNotifier(this._repository) : super(const AsyncValue.loading()) {
    _load();
  }

  final GameDbRepository _repository;
  Completer<Map<String, dynamic>> _loaded = Completer();

  Future<void> _load() async {
    state = const AsyncValue.loading();
    if (_loaded.isCompleted) _loaded = Completer();
    final loaded = _loaded;
    try {
      final records =
          _readableTable(_repository.schema, await _repository.loadRecords());
      state = AsyncValue.data(records);
      if (!loaded.isCompleted) loaded.complete(records);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      if (!loaded.isCompleted) loaded.complete(const {});
    }
  }

  /// The table as soon as it has loaded -- right away when it already has
  /// (an empty table when loading failed). For code that acts on data it
  /// may be the first to ask for, like a story choice launching a zone
  /// after a cold start, where reading the not-yet-loaded state would find
  /// nothing and silently skip.
  Future<Map<String, dynamic>> whenLoaded() {
    final value = state.value;
    if (value != null) return Future.value(value);
    return _loaded.future;
  }

  Future<void> upsertRecord(String key, Map<String, dynamic> record) async {
    final current =
        Map<String, dynamic>.from(state.value ?? <String, dynamic>{});
    current[key] = record;
    await _repository.saveRecords(current);
    state = AsyncValue.data(_readableTable(_repository.schema, current));
  }

  Future<void> deleteRecord(String key) async {
    final current =
        Map<String, dynamic>.from(state.value ?? <String, dynamic>{});
    current.remove(key);
    await _repository.saveRecords(current);
    state = AsyncValue.data(_readableTable(_repository.schema, current));
  }

  Future<void> replaceAll(Map<String, dynamic> records) async {
    await _repository.saveRecords(records);
    state = AsyncValue.data(_readableTable(_repository.schema, records));
  }

  Future<void> resetToDefaults() async {
    await _repository.resetToDefaults();
    await _load();
  }
}

final gameDbProvider = StateNotifierProvider.family<_GameDbNotifier,
    AsyncValue<Map<String, dynamic>>, DbSchema>(
  (ref, schema) {
    final repository = ref.watch(gameDbRepositoryProvider(schema));
    return _GameDbNotifier(repository);
  },
);

/// [_GameDbNotifier.whenLoaded] for [schema]'s table.
Future<Map<String, dynamic>> loadedGameDb(
    WidgetRef ref, DbSchema schema) async {
  final records = withResolvedPlaceholders(
      schema.id, await ref.read(gameDbProvider(schema).notifier).whenLoaded());
  return ref.read(appLanguageProvider) == AppLanguage.fr
      ? _readableTable(schema, frenchOverlay(records), french: true)
      : _readableTable(schema, records);
}

/// A copy of [records] with every French field laid over its English
/// one: `name_fr` (or the older `nameFr`) replaces `name` wherever it is
/// filled in, in nested maps and lists too. The originals are untouched.
Map<String, dynamic> frenchOverlay(Map<String, dynamic> records) => {
      for (final entry in records.entries) entry.key: _overlaid(entry.value),
    };

dynamic _overlaid(dynamic value) {
  if (value is List) return [for (final element in value) _overlaid(element)];
  if (value is! Map) return value;
  final out = <String, dynamic>{
    for (final entry in value.entries)
      entry.key.toString(): _overlaid(entry.value),
  };
  for (final entry in value.entries) {
    final key = entry.key.toString();
    final base = key.endsWith('_fr')
        ? key.substring(0, key.length - 3)
        : key.endsWith('Fr')
            ? key.substring(0, key.length - 2)
            : null;
    if (base == null || base.isEmpty) continue;
    final french = entry.value;
    final filled = (french is String && french.trim().isNotEmpty) ||
        (french is List && french.isNotEmpty);
    if (filled) out[base] = _overlaid(french);
  }
  return out;
}

/// The game data as the reader sees it: [gameDbProvider]'s records, with
/// their French text laid over the English when the app is in French
/// (see [frenchOverlay]), and the numbers their descriptions name filled
/// in (see [withResolvedPlaceholders]). For showing data; the data editor
/// keeps reading and saving [gameDbProvider] itself, so a French reader
/// never writes French into an English field, nor a number into a
/// placeholder.
final localizedDbProvider =
    Provider.family<AsyncValue<Map<String, dynamic>>, DbSchema>((ref, schema) {
  final raw = ref.watch(gameDbProvider(schema)).whenData((records) =>
      _readableTable(schema, withResolvedPlaceholders(schema.id, records)));
  if (ref.watch(appLanguageProvider) != AppLanguage.fr) return raw;
  return raw.whenData((records) =>
      _readableTable(schema, frenchOverlay(records), french: true));
});
