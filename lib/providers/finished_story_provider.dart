import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'player_session_provider.dart';

const String finishedStoryPrefsKey = 'finished_story';

/// The stories seen through to an ending: how many, and the last finished
/// run itself, which New Game+ from the main menu banks as the next
/// cycle's legacy (see PlayerSessionNotifier.beginNewGamePlus) even after
/// a new game has replaced it as the current session.
class FinishedStory {
  const FinishedStory({
    this.count = 0,
    this.lastRun,
    this.lastKey = '',
    this.loaded = false,
  });

  final int count;
  final PlayerSession? lastRun;

  /// Which run and ending [lastRun] is (see [FinishedStoryNotifier.record]).
  final String lastKey;

  /// Whether the record on disk has been read yet.
  final bool loaded;

  bool get any => count > 0 && lastRun != null;
}

class FinishedStoryNotifier extends StateNotifier<FinishedStory> {
  FinishedStoryNotifier() : super(const FinishedStory()) {
    ready = _load();
  }

  /// Completes once the record on disk has been read (or found missing).
  late final Future<void> ready;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(finishedStoryPrefsKey);
    if (raw == null) {
      state = const FinishedStory(loaded: true);
      return;
    }
    try {
      final data = json.decode(raw) as Map<String, dynamic>;
      final run = data['lastRun'];
      state = FinishedStory(
        count: (data['count'] as num?)?.toInt() ?? 0,
        lastRun:
            run is Map<String, dynamic> ? PlayerSession.fromJson(run) : null,
        lastKey: data['lastKey']?.toString() ?? '',
        loaded: true,
      );
    } catch (_) {
      // An unreadable record only hides New Game+ until the next ending.
      state = const FinishedStory(loaded: true);
    }
  }

  /// A story finished before this record was kept (before 1.134): [run],
  /// standing at [endingNodeId], counts when nothing is recorded yet.
  Future<void> backfill(PlayerSession run, String endingNodeId) async {
    await ready;
    if (state.any) return;
    await record(run, endingNodeId);
  }

  /// Records [run] as finished at [endingNodeId]. The same run standing at
  /// the same ending again (the app reopened there, a heal on the ending
  /// screen) refreshes the snapshot without counting another story.
  Future<void> record(PlayerSession run, String endingNodeId) async {
    await ready;
    final key = '${run.newGamePlusCycle}|${run.characterName}|'
        '${run.raceId}|${run.professionId}|$endingNodeId';
    final encoded = json.encode(run.toJson());
    if (key == state.lastKey &&
        state.lastRun != null &&
        json.encode(state.lastRun!.toJson()) == encoded) {
      return;
    }
    state = FinishedStory(
      count: key == state.lastKey ? state.count : state.count + 1,
      lastRun: run,
      lastKey: key,
      loaded: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      finishedStoryPrefsKey,
      json.encode({
        'count': state.count,
        'lastRun': run.toJson(),
        'lastKey': key,
      }),
    );
  }
}

final finishedStoryProvider =
    StateNotifierProvider<FinishedStoryNotifier, FinishedStory>(
        (ref) => FinishedStoryNotifier());
