import 'dart:math';

import '../l10n/app_locale.dart';
import '../l10n/app_strings.dart';
import 'signs.dart';

part 'factions/standing.dart';
part 'factions/records.dart';
part 'factions/relations.dart';
part 'factions/intrigues.dart';
part 'factions/clan_data.dart';
part 'factions/session_records.dart';
part 'factions/politics_state.dart';
part 'factions/standing_rules.dart';
part 'factions/mark_relation_rules.dart';
part 'factions/words.dart';

/// Clans, standing and politics (v1.193): the Grey Shroud's Lantern
/// Dominion and the five clans of the coast, their 29 sub-clans, the
/// Choir and the Pit, and the tribes met on the way -- all of them
/// *factions* (assets/gamedata/factions.json). The character stands
/// somewhere with each one, from -100 (Hunted) to +100 (Sworn); each
/// sub-clan keeps a mark (friend, none or foe); and every pair of clans
/// sits on one step of a seven-step scale, from Blood feud to Allies,
/// which moves with the story.
///
/// Everything here is pure, like signs.dart: the data files parse into a
/// [ClanData]; the session keeps a [PoliticsState]; and the rules --
/// [applyStandingChange] (with its ripple and the Sworn banner),
/// [setSubclanMark], [shiftRelation], [setStandingValue] -- take a state
/// and return the next one, with what they log.
///
/// For the code that calls this (offers, quests, intrigues):
/// - **faction lookup:** [ClanData.faction], [ClanData.clans],
///   [ClanData.subclansOf], [ClanData.subclan], [ClanData.titlesFor];
/// - **standing:** [PoliticsState.standingOf], [PoliticsState.tierOf],
///   [applyStandingChange] (and [standingPreview] for its numbers alone);
/// - **tiers:** [standingTierFor], [StandingTier.isAtLeast],
///   [tierPriceFactor];
/// - **marks:** [PoliticsState.markOf], [setSubclanMark];
/// - **relations:** [alliesOf], [rivalsOf], [PoliticsState.relationStep],
///   [shiftRelation], [relationsAtChapter];
/// - **the log:** [PoliticsState.standingLog] and
///   [PoliticsState.relationsLog], each entry dated by chapter and day,
///   its cause read with [standingCauseLabel].

/// A faction's place in the world: one of the clans (the Dominion
/// included), a tribe met on the way, or the Choir or the Pit. The same
/// kinds Signs knows its patrons by: every faction is a patron.
typedef FactionKind = PatronKind;
