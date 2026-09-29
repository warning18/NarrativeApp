import 'package:flutter_riverpod/legacy.dart';

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
