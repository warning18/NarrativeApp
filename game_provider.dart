import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';

class GameState extends StateNotifier<NarrativeNode?> {
  // 1. We need to declare the private map here:
  Map<String, NarrativeNode> _allNodes = {};

  // 2. This allows other tabs to safely read the map:
  Map<String, NarrativeNode> getAllNodes() => _allNodes;

  GameState() : super(null) {
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    // Make sure you add Cleaned_Narrative_DAG.json to an 'assets' folder and update pubspec.yaml
    final String response = await rootBundle.loadString('assets/Cleaned_Narrative_DAG.json');
    final Map<String, dynamic> data = json.decode(response);
    
    _allNodes = data.map((key, value) => MapEntry(key, NarrativeNode.fromJson(value)));
    
    // Start at Node 100
    state = _allNodes['100']; 
  }

  void makeChoice(String nextId) {
    if (_allNodes.containsKey(nextId)) {
      state = _allNodes[nextId];
    } else {
      // Handle END or EXIT states
      state = NarrativeNode(id: nextId, description: "Game Over", choices: []);
    }
  }
}

final gameStateProvider = StateNotifierProvider<GameState, NarrativeNode?>((ref) {
  return GameState();
});