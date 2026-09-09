import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/story_repository.dart';
import '../models/story_node.dart';

final storyRepositoryProvider = Provider<StoryRepository>((ref) {
  return StoryRepository();
});

final storyDataProvider = FutureProvider<StoryData>((ref) {
  return ref.watch(storyRepositoryProvider).load();
});

class StoryPlayState {
  const StoryPlayState({
    required this.currentNodeId,
    required this.history,
    this.activeExcursionNode,
    this.excursionQueue = const [],
    this.resumeNodeId,
  });

  final String currentNodeId;
  final List<String> history;

  /// The procedurally generated node currently being shown, if the player
  /// is mid-excursion (a detour inserted between two main story beats).
  final StoryNode? activeExcursionNode;

  /// Remaining generated nodes to show after [activeExcursionNode].
  final List<StoryNode> excursionQueue;

  /// The real story node to resume once the excursion queue is exhausted.
  final String? resumeNodeId;

  bool get isInExcursion => activeExcursionNode != null;
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

  /// Inserts a procedurally generated chain of nodes before the player
  /// reaches [resumeNodeId], the real node they were about to move to.
  void startExcursion(List<StoryNode> chain, String resumeNodeId) {
    if (chain.isEmpty) return;
    state = StoryPlayState(
      currentNodeId: state.currentNodeId,
      history: state.history,
      activeExcursionNode: chain.first,
      excursionQueue: chain.skip(1).toList(),
      resumeNodeId: resumeNodeId,
    );
  }

  /// Advances past the current excursion node, either to the next generated
  /// node in the queue or, once it's empty, back to the real story.
  void advanceExcursion() {
    if (state.excursionQueue.isEmpty) {
      final resume = state.resumeNodeId;
      if (resume != null) choose(resume);
      return;
    }
    state = StoryPlayState(
      currentNodeId: state.currentNodeId,
      history: state.history,
      activeExcursionNode: state.excursionQueue.first,
      excursionQueue: state.excursionQueue.skip(1).toList(),
      resumeNodeId: state.resumeNodeId,
    );
  }
}

final storyPlayProvider =
    StateNotifierProvider<StoryPlayNotifier, StoryPlayState>((ref) {
  return StoryPlayNotifier(StoryRepository.startNodeId);
});
