import 'package:flutter_riverpod/legacy.dart';

import 'app_mode_provider.dart';

/// Index into [HomeShell]'s bottom navigation tabs: Journey, Character,
/// Camp, Other in play (the Story reader, index 0, is Edit Mode's and the
/// ending's); Story, Play, Generate, Data in Edit Mode. Lets other screens
/// -- like a quest/shop call-to-action in the story reader --
/// programmatically switch tabs.
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

/// The Journey tab's index among the play-mode tabs (after Story,
/// Character, Camp and Other, so theirs stay as they were).
const int journeyTabIndex = 4;

/// The tab the story is followed on: the Journey in play (v1.201: the
/// Story tab is gone from the game), the Story reader in Edit Mode.
int storyTabIndex(AppMode mode) => mode == AppMode.edit ? 0 : journeyTabIndex;

/// The tab holding the quests, shops, bestiary and saves: Other in play,
/// Play in Edit Mode.
int questsTabIndex(AppMode mode) => mode == AppMode.edit ? 1 : 3;

/// The route name of the game itself (HomeShell), under the main menu:
/// flows that return "to the game" pop back to it, never past it.
const String gameRouteName = '/game';

/// True for the game's route, or the root when the game is the root (a
/// test pumping HomeShell directly).
bool isGameRoute(dynamic route) =>
    route.settings.name == gameRouteName || route.isFirst == true;
