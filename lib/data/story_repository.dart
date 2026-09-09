import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/story_node.dart';

class StoryData {
  const StoryData(this.nodes);

  final Map<String, StoryNode> nodes;

  StoryNode? nodeFor(String id) => nodes[id];
}

class StoryRepository {
  static const String assetPath = 'assets/Cleaned_Narrative_DAG.json';
  static const String startNodeId = '100';

  Future<StoryData> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;

    final nodes = <String, StoryNode>{};
    decoded.forEach((id, value) {
      nodes[id] = StoryNode.fromJson(id, value as Map<String, dynamic>);
    });

    return StoryData(nodes);
  }
}
