import 'package:flutter/material.dart';

/// One line of a tour: what the guide says (`tut_<topic>_<n>` in
/// app_strings.dart) and, when [target] is set, the part of the screen it
/// lights up while it says it (see TutorialTarget). A step whose target
/// isn't on screen is still said, with nothing lit.
class TutorialStep {
  const TutorialStep(this.textKey, {this.target});

  final String textKey;
  final String? target;
}

/// A feature with a tour of its own. Its tour plays the first time the
/// player reaches it (see TutorialTrigger) and can be played again from
/// the Tutorials list in the Other tab.
enum TutorialTopic {
  story(Icons.menu_book, homeTab: 0, steps: [
    TutorialStep('tut_story_1'),
    TutorialStep('tut_story_2', target: 'home.chapter'),
    TutorialStep('tut_story_3', target: 'story.stats'),
    TutorialStep('tut_story_4', target: 'story.text'),
    TutorialStep('tut_story_5', target: 'story.choices'),
    TutorialStep('tut_story_6', target: 'story.companion'),
    TutorialStep('tut_story_7', target: 'home.map'),
    TutorialStep('tut_story_8', target: 'home.nav'),
  ]),
  character(Icons.person_outline, homeTab: 1, steps: [
    TutorialStep('tut_character_1', target: 'character.header'),
    TutorialStep('tut_character_2', target: 'character.alignment'),
    TutorialStep('tut_character_3', target: 'character.abilities'),
    TutorialStep('tut_character_4', target: 'character.pages'),
  ]),
  camp(Icons.local_fire_department_outlined, homeTab: 2, steps: [
    TutorialStep('tut_camp_1', target: 'camp.town'),
    TutorialStep('tut_camp_2', target: 'camp.tray'),
    TutorialStep('tut_camp_3', target: 'camp.boat'),
    TutorialStep('tut_camp_4', target: 'camp.roster'),
    TutorialStep('tut_camp_5', target: 'camp.sail'),
  ]),
  other(Icons.more_horiz, homeTab: 3, steps: [
    TutorialStep('tut_other_1', target: 'other.saves'),
    TutorialStep('tut_other_2', target: 'other.achievements'),
    TutorialStep('tut_other_3', target: 'other.sections'),
    TutorialStep('tut_other_4', target: 'other.tutorials'),
  ]),
  map(Icons.map_outlined, steps: [
    TutorialStep('tut_map_1', target: 'map.chart'),
    TutorialStep('tut_map_2', target: 'map.controls'),
    TutorialStep('tut_map_3', target: 'map.chapters'),
  ]),
  skills(Icons.auto_awesome, steps: [
    TutorialStep('tut_skills_1', target: 'skills.points'),
    TutorialStep('tut_skills_5', target: 'skills.views'),
    TutorialStep('tut_skills_2', target: 'skills.list'),
    TutorialStep('tut_skills_3', target: 'skills.craft'),
    TutorialStep('tut_skills_4', target: 'skills.compare'),
  ]),
  dice(Icons.casino_outlined, steps: [
    TutorialStep('tut_dice_1', target: 'dice.choice'),
    TutorialStep('tut_dice_2', target: 'dice.faces'),
    TutorialStep('tut_dice_3', target: 'dice.skills'),
  ]),
  inventory(Icons.backpack_outlined, steps: [
    TutorialStep('tut_inventory_1', target: 'inventory.body'),
    TutorialStep('tut_inventory_2', target: 'inventory.compare'),
  ]),
  levelUp(Icons.trending_up, steps: [
    TutorialStep('tut_levelUp_1', target: 'levelUp.points'),
    TutorialStep('tut_levelUp_2', target: 'levelUp.stats'),
  ]),
  fight(Icons.sports_martial_arts, steps: [
    TutorialStep('tut_fight_1'),
    TutorialStep('tut_fight_2', target: 'fight.dice'),
    TutorialStep('tut_fight_3', target: 'fight.enemies'),
    TutorialStep('tut_fight_4', target: 'fight.party'),
    TutorialStep('tut_fight_5', target: 'fight.actions'),
    TutorialStep('tut_fight_6', target: 'fight.top'),
  ]),
  skillChallenge(Icons.casino, steps: [
    TutorialStep('tut_skillChallenge_1', target: 'challenge.die'),
    TutorialStep('tut_skillChallenge_2', target: 'challenge.track'),
  ]),
  // The Harbour, where the Rusty Eel is refitted.
  boat(Icons.anchor, steps: [
    TutorialStep('tut_boat_1'),
    TutorialStep('tut_boat_2'),
  ]),
  voyage(Icons.directions_boat_outlined, steps: [
    TutorialStep('tut_voyage_1'),
    TutorialStep('tut_voyage_2'),
  ]),
  expedition(Icons.explore_outlined, steps: [
    TutorialStep('tut_expedition_1'),
    TutorialStep('tut_expedition_2'),
  ]),
  town(Icons.cottage_outlined, steps: [
    TutorialStep('tut_town_1'),
  ]),
  shop(Icons.storefront_outlined, steps: [
    TutorialStep('tut_shop_1'),
    TutorialStep('tut_shop_2'),
  ]),
  journal(Icons.auto_stories_outlined, steps: [
    TutorialStep('tut_journal_1'),
  ]),
  achievements(Icons.emoji_events_outlined, steps: [
    TutorialStep('tut_achievements_1'),
  ]);

  const TutorialTopic(this.icon, {required this.steps, this.homeTab});

  final IconData icon;
  final List<TutorialStep> steps;

  /// The play-mode tab the feature lives on, when it is one.
  final int? homeTab;

  /// The feature's name in the Tutorials list (`tut_<topic>_title`).
  String get titleKey => 'tut_${name}_title';
}
