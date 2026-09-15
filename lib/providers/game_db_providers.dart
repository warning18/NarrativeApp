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

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final records = await _repository.loadRecords();
      state = AsyncValue.data(records);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
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
