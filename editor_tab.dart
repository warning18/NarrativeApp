class NarrativeChoice {
  final String text;
  final String nextId;

  NarrativeChoice({required this.text, required this.nextId});

  factory NarrativeChoice.fromJson(Map<String, dynamic> json) {
    return NarrativeChoice(
      text: json['text'] as String,
      nextId: json['next_id'] as String,
    );
  }
}

class NarrativeNode {
  final String id;
  final String description;
  final List<NarrativeChoice> choices;

  NarrativeNode({
    required this.id,
    required this.description,
    required this.choices,
  });

  factory NarrativeNode.fromJson(Map<String, dynamic> json) {
    var list = json['choices'] as List? ?? [];
    List<NarrativeChoice> choicesList = list.map((i) => NarrativeChoice.fromJson(i)).toList();

    return NarrativeNode(
      id: json['id'] as String,
      description: json['description'] as String,
      choices: choicesList,
    );
  }
}