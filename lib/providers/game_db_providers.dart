import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../gamedata/db_schema.dart';
import '../gamedata/game_db_repository.dart';

final gameDbRepositoryProvider =
    Provider.family<GameDbRepository, DbSchema>((ref, schema) {
  return GameDbRepository(schema);
});

class GameDbNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  GameDbNotifier(this._repository) : super(const AsyncValue.loading()) {
    _load();
  }

  final GameDbRepository _repository;
  Completer<Map<String, dynamic>> _loaded = Completer();

  Future<void> _load() async {
    state = const AsyncValue.loading();
    if (_loaded.isCompleted) _loaded = Completer();
    final loaded = _loaded;
    try {
      final records = await _repository.loadRecords();
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
    state = AsyncValue.data(current);
  }

  Future<void> deleteRecord(String key) async {
    final current =
        Map<String, dynamic>.from(state.value ?? <String, dynamic>{});
    current.remove(key);
    await _repository.saveRecords(current);
    state = AsyncValue.data(current);
  }

  Future<void> replaceAll(Map<String, dynamic> records) async {
    await _repository.saveRecords(records);
    state = AsyncValue.data(records);
  }

  Future<void> resetToDefaults() async {
    await _repository.resetToDefaults();
    await _load();
  }
}

final gameDbProvider = StateNotifierProvider.family<GameDbNotifier,
    AsyncValue<Map<String, dynamic>>, DbSchema>(
  (ref, schema) {
    final repository = ref.watch(gameDbRepositoryProvider(schema));
    return GameDbNotifier(repository);
  },
);

/// [GameDbNotifier.whenLoaded] for [schema]'s table.
Future<Map<String, dynamic>> loadedGameDb(WidgetRef ref, DbSchema schema) =>
    ref.read(gameDbProvider(schema).notifier).whenLoaded();
