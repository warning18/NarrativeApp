import 'dart:convert';

import 'package:flutter/foundation.dart'
    show ErrorDescription, FlutterError, FlutterErrorDetails, compute;
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

  /// The story, read off the main thread (v1.741): its 1.5 MB took about
  /// 65 ms to decode and build there.
  Future<StoryData> load() async => compute(_storyFrom, await _rawText());

  /// The story's raw node records, exactly as stored: the local edits when
  /// there are any, the bundled asset otherwise. Every field, in both
  /// languages (see the Edit Mode export on the map).
  Future<Map<String, dynamic>> loadRaw() async =>
      json.decode(await _rawText()) as Map<String, dynamic>;

  Future<String> _rawText() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      try {
        // Checked here, so a broken edit falls back before the parse is
        // handed off the main thread. Only an edited story pays for it.
        if (json.decode(saved) is Map<String, dynamic>) return saved;
        throw const FormatException('the edited story is not a map of nodes');
      } catch (error, stack) {
        // A broken edited story is reported, and the bundled one read in
        // its place (issue #696).
        FlutterError.reportError(FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'story',
            context: ErrorDescription(
                'reading the edited story; the bundled one is used')));
      }
    }
    return rootBundle.loadString(assetPath);
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

StoryData _storyFrom(String raw) => StoryData({
      for (final entry in (json.decode(raw) as Map<String, dynamic>).entries)
        entry.key:
            StoryNode.fromJson(entry.key, entry.value as Map<String, dynamic>),
    });

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
