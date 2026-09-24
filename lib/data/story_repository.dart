import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/story_node.dart';

class StoryData {
  const StoryData(this.nodes);

  final Map<String, StoryNode> nodes;

  StoryNode? nodeFor(String id) => nodes[id];
}

class StoryRepository {
  static const String assetPath = 'assets/Cleaned_Narrative_DAG.json';
  static const String startNodeId = '0';
  static const String _prefsKey = 'story_nodes_override';

  Future<StoryData> load() async {
    final decoded = await loadRaw();
    final nodes = <String, StoryNode>{};
    decoded.forEach((id, value) {
      nodes[id] = StoryNode.fromJson(id, value as Map<String, dynamic>);
    });

    return StoryData(nodes);
  }

  /// The story's raw node records, exactly as stored: the local edits when
  /// there are any, the bundled asset otherwise. Every field, in both
  /// languages (see the Edit Mode export on the map).
  Future<Map<String, dynamic>> loadRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    final raw = saved ?? await rootBundle.loadString(assetPath);
    return json.decode(raw) as Map<String, dynamic>;
  }

  /// Persists an edited set of raw node records as a local override, so
  /// [load] returns the edited story instead of the bundled asset.
  Future<void> saveNodes(Map<String, dynamic> rawNodes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, json.encode(rawNodes));
  }

  /// Discards the local override, reverting to the bundled story.
  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

/// The first scene after character creation: where the story picks up when
/// the same character starts over (permadeath), skipping the creation step
/// that would replace them. The start node itself when it has no creation
/// choice.
String firstSceneAfterCreation(StoryData story) {
  final start = story.nodeFor(StoryRepository.startNodeId);
  for (final choice in start?.choices ?? const <StoryChoice>[]) {
    if (choice.opensCharacterCreation && !choice.isEnding) {
      return choice.nextId;
    }
  }
  return StoryRepository.startNodeId;
}
