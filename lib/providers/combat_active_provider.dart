import 'package:flutter_riverpod/legacy.dart';

/// True while a FightScreen is on top of the navigation stack, so the
/// walking companion can switch to its fighting stance instead of idling.
/// Set/cleared by whoever pushes FightScreen (story_player_screen.dart,
/// play_screen.dart) around the push — not by FightScreen itself, so no
/// changes are needed there.
final combatActiveProvider = StateProvider<bool>((ref) => false);
