import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/story_repository.dart';

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepository();
});

final storyDataProvider = FutureProvider<StoryData>((ref) {
  return ref.watch(storyRepositoryProvider).load();
});

class StoryPlayState {
  const StoryPlayState({required this.currentNodeId, required this.history});

  final String currentNodeId;
  final List<String> history;
}

class StoryPlayNotifier extends StateNotifier<StoryPlayState> {
  StoryPlayNotifier(String startId)
      : super(StoryPlayState(currentNodeId: startId, history: const []));

  void choose(String nextId) {
    state = StoryPlayState(
      currentNodeId: nextId,
      history: [...state.history, state.currentNodeId],
    );
  }

  void jumpTo(String nodeId) => choose(nodeId);

  void goBack() {
    if (state.history.isEmpty) return;
    final newHistory = List<String>.from(state.history);
    final previousId = newHistory.removeLast();
    state = StoryPlayState(currentNodeId: previousId, history: newHistory);
  }

  void restart(String startId) {
    state = StoryPlayState(currentNodeId: startId, history: const []);
  }
}

final storyPlayProvider =
    StateNotifierProvider<StoryPlayNotifier, StoryPlayState>((ref) {
  return StoryPlayNotifier(StoryRepository.startNodeId);
});
