import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/item_origin.dart';
import '../providers/chapter_loop_provider.dart';
import '../providers/geography_provider.dart';
import '../providers/story_providers.dart';

/// Where the story stands now, for an item entering the pack (v1.204, see
/// item_origin.dart): the current scene's `location` (a geography.json
/// place; '' when the scene has none, or names a place the geography
/// does not know) and the chapter reached. Every caller of an adding
/// method on PlayerSessionNotifier passes it as `origin`.
ItemOrigin itemOriginHere(WidgetRef ref) {
  final play = ref.read(storyPlayProvider);
  final story = ref.read(storyDataProvider).value;
  final geography = ref.read(geographyProvider);
  final location = story?.nodeFor(play.currentNodeId)?.location ?? '';
  final known = location.isNotEmpty &&
      (geography.isEmpty || geography.place(location) != null);
  return ItemOrigin(
    placeId: known ? location : '',
    chapter: ref.read(reachedChapterProvider),
  );
}
