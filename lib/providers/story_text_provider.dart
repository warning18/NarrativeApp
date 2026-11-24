import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/story_markup.dart';
import '../data/story_names.dart';
import '../gamedata/db_schema.dart';
import 'game_db_providers.dart';
import 'geography_provider.dart';

/// The names the story text colours, for [french] or English text (see
/// story_names.dart). Raw tables: a table still loading reads as empty, and
/// the names come in once it has loaded.
final storyNameMatcherProvider =
    Provider.family<StoryNameMatcher, bool>((ref, french) {
  Map<String, dynamic> table(DbSchema schema) =>
      ref.watch(gameDbProvider(schema)).value ?? const {};
  return buildStoryNames(
    npcs: table(npcsSchema),
    companions: table(companionsSchema),
    factions: table(factionsSchema),
    subclans: table(subclansSchema),
    geography: ref.watch(geographyProvider),
    french: french,
  );
});

/// The scenes (by their reveal key) whose text has been written out in full:
/// a scene is typed once, and what is read again is shown at once. Kept to
/// the last 40.
final storyTextDoneProvider = StateProvider<Set<String>>((ref) => const {});

/// A tap that is meant for the text being written (a Continue button pressed
/// too early) bumps this: the text shows all it has, and the next tap
/// continues.
final storyTextSkipProvider = StateProvider<int>((ref) => 0);
