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
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    final raw = saved ?? await rootBundle.loadString(assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;

    final nodes = <String, StoryNode>{};
    decoded.forEach((id, value) {
      nodes[id] = StoryNode.fromJson(id, value as Map<String, dynamic>);
    });

    return StoryData(nodes);
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
