import '../models/story_node.dart';

// Camp errands (companion loyalty errands): a story node marked
// `campErrand` is offered at every chapter camp, after the camp's own
// choices, while its `showIfFlags` / `hideIfFlags` let it show. It sits in
// no camp's choices (so it never counts toward a hub's choice limit), and
// its last beat goes home with a `returnToCamp` choice: the camp of the
// chapter the party is in, whichever camp it left from. These are the pure
// readers; the camp screen lists [campErrandChoices] with its own.

/// The camp's way into [node], a camp errand: a plain choice that goes to
/// it, labelled with its `campErrandText` (else the scene's first line), and
/// shown under the node's own flags (see StoryChoice.isHiddenFor).
StoryChoice campErrandChoice(StoryNode node) {
  String firstLine(String text) => text
      .split('\n')
      .map((line) => line.trim())
      .firstWhere((line) => line.isNotEmpty, orElse: () => node.id);
  final label = (node.campErrandText ?? '').trim();
  final labelFr = (node.campErrandTextFr ?? '').trim();
  return StoryChoice(
    text: label.isNotEmpty ? label : firstLine(node.description),
    textFr: labelFr.isNotEmpty
        ? labelFr
        : (node.descriptionFr ?? '').trim().isNotEmpty
            ? firstLine(node.descriptionFr!)
            : null,
    nextId: node.id,
    showIfFlags: node.showIfFlags,
    hideIfFlags: node.hideIfFlags,
  );
}

/// Every camp errand among [nodes], in their order, as the camp's way into
/// each (see [campErrandChoice]), shown or not.
List<StoryChoice> campErrandChoices(Iterable<StoryNode> nodes) => [
      for (final node in nodes)
        if (node.campErrand) campErrandChoice(node),
    ];

/// The camp errands a camp offers a party holding [flags]: those whose
/// flags let them show, in [nodes]' order.
List<StoryChoice> campErrandsFor(
        Iterable<StoryNode> nodes, Iterable<String> flags) =>
    [
      for (final choice in campErrandChoices(nodes))
        if (!choice.isHiddenFor(flags)) choice,
    ];

/// Where taking [choice] leads: for a `returnToCamp` choice, the current
/// camp ([campNodeId], see currentCampNodeId) when there is one; else the
/// choice's own next_id.
String storyChoiceTarget(StoryChoice choice, {String? campNodeId}) =>
    choice.returnToCamp && (campNodeId ?? '').isNotEmpty
        ? campNodeId!
        : choice.nextId;
