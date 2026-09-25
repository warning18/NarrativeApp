import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/home_tab_provider.dart';
import '../providers/tutorial_provider.dart';
import '../screens/achievements_screen.dart';
import '../screens/dice_loadout_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/journal_screen.dart';
import '../screens/level_up_screen.dart';
import '../screens/skills_screen.dart';
import '../screens/world_map_screen.dart';
import 'guide_tour.dart';
import 'tutorial_topics.dart';

/// Plays [topic]'s tour again, from the Tutorials list: on its own tab or
/// page when it has one (opened for it, so the guide can point at the real
/// thing), else right here, the guide telling it without pointing.
void playTutorial(BuildContext context, WidgetRef ref, TutorialTopic topic) {
  final Widget? page = switch (topic) {
    TutorialTopic.map => const WorldMapPage(),
    TutorialTopic.skills => const SkillsScreen(),
    TutorialTopic.dice => const DiceLoadoutScreen(),
    TutorialTopic.inventory => const InventoryScreen(),
    TutorialTopic.levelUp => const LevelUpScreen(),
    TutorialTopic.journal => const JournalScreen(),
    TutorialTopic.achievements => const AchievementsScreen(),
    _ => null,
  };
  final tab = topic.homeTab;
  if (tab == null && page == null) {
    showGuideTour(context, ref, topic);
    return;
  }
  ref.read(pendingTourProvider.notifier).state = topic;
  if (tab != null) {
    ref.read(homeTabIndexProvider.notifier).state = tab;
  } else {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page!));
  }
  // A page that can't take the tour yet (the Camp before chapter 3) never
  // picks it up: the guide tells it here instead.
  Timer(const Duration(milliseconds: 1600), () {
    if (ref.read(pendingTourProvider) != topic) return;
    ref.read(pendingTourProvider.notifier).state = null;
    if (context.mounted) showGuideTour(context, ref, topic);
  });
}
