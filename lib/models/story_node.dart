class StoryChoice {
  const StoryChoice({required this.text, required this.nextId});

  factory StoryChoice.fromJson(Map<String, dynamic> json) {
    return StoryChoice(
      text: json['text'] as String? ?? '',
      nextId: json['next_id'] as String? ?? '',
    );
  }

  final String text;
  final String nextId;

  static const List<String> _endMarkers = ['EXIT', 'END'];

  bool get isEnding => _endMarkers.contains(nextId);
}

class StoryNode {
  const StoryNode({
    required this.id,
    required this.description,
    required this.choices,
  });

  factory StoryNode.fromJson(String id, Map<String, dynamic> json) {
    final choicesJson = json['choices'] as List<dynamic>? ?? const [];
    return StoryNode(
      id: id,
      description: json['description'] as String? ?? '',
      choices: choicesJson
          .map((c) => StoryChoice.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String description;
  final List<StoryChoice> choices;
}
