import 'package:flutter_riverpod/legacy.dart';

import '../data/choice_flow.dart';
import '../models/story_node.dart';

import '../combat/combat_aftermath.dart';
import '../data/scene_flow.dart';

/// The most recent fight's outcome, published by FightScreen right before
/// it pops -- the story player reads it to write the fight's aftermath
/// into the next scene (see [pendingAftermathProvider]). Null until the
/// first fight of the session.
final lastFightOutcomeProvider = StateProvider<FightOutcome?>((ref) => null);

/// The one-paragraph aftermath the next story node opens with, set after
/// a fight resolves and cleared as soon as the player moves on from that
/// node.
final pendingAftermathProvider = StateProvider<String?>((ref) => null);

/// Set by FightScreen when the party got away instead of finishing the
/// fight (its route pops with null, as a permadeath loss does): the story
/// then leaves a detour, and an expedition ends as a retreat rather than
/// a defeat. Whoever reads it clears it.
final lastFightRetreatedProvider = StateProvider<bool>((ref) => false);

/// A check's outcome in words (see check_outcomes.dart), for a check with
/// no scene of its own to tell it: the next scene opens with it, and the
/// next choice retires it.
final pendingCheckOutcomeProvider = StateProvider<String?>((ref) => null);

/// The plain scenes read on the way to this one (see scene_flow.dart):
/// they open it, above its own text, and the next choice retires them.
final pendingPreludeProvider =
    StateProvider<List<ScenePrelude>>((ref) => const []);

/// What the last step on the road cost (a day gone, hunger, rations
/// running low; see journey_rules.dart): the next scene opens with it, and
/// the next choice retires it.
final pendingRoadNoteProvider = StateProvider<String?>((ref) => null);

/// The step just taken inside one place (a card of the scene whose way leads
/// to the next scene at the same stop): its own words and where the party
/// still stands. The scene opens with them (a "taken" line and a "still in"
/// line, see journey_panels.dart); a move, a hub's return and the next choice
/// retire them.
typedef TakenStep = ({StoryChoice choice, String placeId});
final pendingTakenProvider = StateProvider<TakenStep?>((ref) => null);

/// What [pendingTakenProvider] holds after [choice] was taken with [flow]: the
/// step and the place only for a step that stayed at the same stop and
/// opened another scene ([sceneChanged]), off a detour; null after a move, a
/// carried trip, a hub's return, the step that opens the character's making
/// or a step that left the scene as it was.
TakenStep? takenStepAfter({
  required StoryChoice choice,
  required ChoiceFlow flow,
  required bool inExcursion,
  required bool sceneChanged,
  required String? placeId,
}) =>
    flow is FlowStay &&
            !inExcursion &&
            sceneChanged &&
            !choice.opensCharacterCreation &&
            placeId != null
        ? (choice: choice, placeId: placeId)
        : null;
