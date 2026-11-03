// What a story choice does on the map: whether it moves the party, and what
// kind of action it is -- for the journey map, which draws a pin only for a
// choice that goes somewhere and lists the rest as actions where the party
// stands. Derived from the story and the geography, with no data of its
// own: the place a scene happens at (Geography.placeOfNode), a journey
// between locations (Geography.travelsBetween), and the choice's fields.
//
// Measured on the story (v1.390): of 1,061 choices, 62% stay where they
// are, 32% walk to another place of the same location, 6% travel; of the
// scenes with more than one choice, 61% hold only choices that stay.
import '../models/story_node.dart';
import 'geography.dart';
import 'story_repository.dart';

/// Where a choice takes the party.
enum ChoiceMove {
  /// The next scene happens where this one does.
  stay,

  /// Another place of the same location (a district of the same city).
  walk,

  /// Another location (a road, a voyage, a [StoryChoice.travelPlaceId]).
  travel,

  /// One end happens nowhere the world knows (the prologue, the making of
  /// the character).
  unknown,
}

/// What kind of action a choice is.
enum ChoiceAction {
  /// It starts a fight (an enemy, a hunt, a ship battle, an ambush).
  fight,

  /// It costs gold.
  pay,

  /// A Charisma check.
  talk,

  /// A Dexterity check.
  sneak,

  /// Another ability check.
  attempt,

  /// A check that, passed, avoids the fight it carries.
  evade,

  /// It goes somewhere, and is none of the above.
  go,

  /// A decision where the party stands.
  decide,
}

/// A choice's shape: where it takes the party ([to]: the place, when the
/// world knows it), what it is, and whether it is acted out [here], where
/// the party stands. A fight, a payment, a check or a decision happens
/// here even when its aftermath takes the party elsewhere ("Refuse and
/// fight" at the Stone Bridge, then the lower town); only a [ChoiceAction.go]
/// is a way somewhere, except the making of the character.
typedef ChoiceShape = ({
  ChoiceMove move,
  ChoiceAction action,
  GeoPlace? to,
  bool here,
});

/// The shape of [choice], taken in scene [from] of [story].
ChoiceShape choiceShape(
  StoryNode from,
  StoryChoice choice, {
  required StoryData story,
  required Geography geography,
}) {
  final travelId = choice.travelPlaceId ?? '';
  final next = story.nodeFor(choice.nextId);
  final here = geography.placeOfNode(from);
  final there = travelId.isNotEmpty
      ? geography.placeOfNode(story.nodeFor(travelId)) ??
          geography.placeOfNode(next)
      : geography.placeOfNode(next);
  final ChoiceMove move;
  if (travelId.isNotEmpty) {
    move = ChoiceMove.travel;
  } else if (here == null || there == null) {
    move = ChoiceMove.unknown;
  } else if (here.id == there.id) {
    move = ChoiceMove.stay;
  } else {
    move = geography.travelsBetween(story, from.id, choice.nextId)
        ? ChoiceMove.travel
        : ChoiceMove.walk;
  }
  final action = _actionOf(choice, move, next);
  return (
    move: move,
    action: action,
    to: there,
    // The prologue's way on (making the character) is acted out on the
    // first scene's page: a new game shows no map before the story moves.
    here: action != ChoiceAction.go || choice.opensCharacterCreation,
  );
}

ChoiceAction _actionOf(StoryChoice c, ChoiceMove move, StoryNode? next) {
  final fight = (c.triggerEnemyId ?? '').isNotEmpty ||
      c.triggerEnemyIds.isNotEmpty ||
      (c.huntName ?? '').isNotEmpty ||
      (c.shipBattleId ?? '').isNotEmpty ||
      c.isHunterAmbush;
  final check = c.checkAbility ?? '';
  if (fight && c.avoidFightOnSuccess && check.isNotEmpty) {
    return ChoiceAction.evade;
  }
  if (fight) return ChoiceAction.fight;
  // A price is the choice's own, or the next scene's gold requirement
  // (the Stone Bridge's toll).
  if (c.pays || c.goldMod < 0 || (next?.reqGold ?? 0) > 0) {
    return ChoiceAction.pay;
  }
  if (check.isNotEmpty) {
    return switch (check.toLowerCase()) {
      'charisma' => ChoiceAction.talk,
      'dexterity' => ChoiceAction.sneak,
      _ => ChoiceAction.attempt,
    };
  }
  // A move that weighs on the conscience or the companions (an alignment
  // or an approval change: "Kneel and beg him", "Run, and come back for
  // her") is a decision made here, whose aftermath takes the party away.
  final weighs = c.alignmentMod != 0 || c.approvalMods.isNotEmpty;
  return (move == ChoiceMove.walk || move == ChoiceMove.travel) && !weighs
      ? ChoiceAction.go
      : ChoiceAction.decide;
}

// --- A choice's tags and its ring (the in-place choices, v1.4xx) ---------
//
// UX's in-place choices (docs/proposals/inplace-choices.md) draw each
// choice as a card with its tags, and group the ones acted out here into
// rings by kind: fight; talk and decide; checks and pay; and the ways.

/// The ring a choice sits in.
enum ChoiceGroup {
  /// A fight (an evasion that carries one too).
  fight,

  /// A Charisma check, or a decision.
  talkDecide,

  /// Another check, or a payment.
  checksPay,

  /// A way somewhere (a pin on the map, not a ring).
  go,
}

/// The ring of [action].
ChoiceGroup _choiceGroupOf(ChoiceAction action) => switch (action) {
      ChoiceAction.fight || ChoiceAction.evade => ChoiceGroup.fight,
      ChoiceAction.talk || ChoiceAction.decide => ChoiceGroup.talkDecide,
      ChoiceAction.pay ||
      ChoiceAction.sneak ||
      ChoiceAction.attempt =>
        ChoiceGroup.checksPay,
      ChoiceAction.go => ChoiceGroup.go,
    };

/// What a choice's card says beside its text: its [cost] in gold (its own
/// price, or the next scene's gold requirement, a toll's; 0 for none), its
/// [alignment] shift, and where its aftermath takes the party
/// ([destination], null when it stays or the world doesn't know).
typedef ChoiceTags = ({
  int cost,
  int alignment,
  GeoPlace? destination,
  ChoiceGroup group,
});

/// [choice]'s tags, taken in scene [from] of [story] ([shape]: its
/// [choiceShape], when the caller has it).
ChoiceTags choiceTags(
  StoryNode from,
  StoryChoice choice, {
  required StoryData story,
  required Geography geography,
  ChoiceShape? shape,
}) {
  final s =
      shape ?? choiceShape(from, choice, story: story, geography: geography);
  final next = story.nodeFor(choice.nextId);
  final own = choice.goldMod < 0 ? -choice.goldMod : 0;
  final toll = next?.reqGold ?? 0;
  return (
    cost: own > toll ? own : toll,
    alignment: choice.alignmentMod,
    destination:
        s.move == ChoiceMove.walk || s.move == ChoiceMove.travel ? s.to : null,
    group: _choiceGroupOf(s.action),
  );
}
