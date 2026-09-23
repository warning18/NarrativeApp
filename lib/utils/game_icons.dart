import 'package:flutter/material.dart';

IconData itemTypeIcon(String? itemType) {
  switch (itemType) {
    case 'Weapon':
      return Icons.gavel;
    case 'Armor':
      return Icons.shield;
    case 'Potion':
      return Icons.local_drink;
    case 'Scroll':
      return Icons.description;
    case 'Ship':
      return Icons.rocket_launch;
    case 'Material':
      return Icons.layers;
    case 'Quest':
      return Icons.flag;
    case 'Artifact':
      return Icons.auto_awesome;
    case 'Charm':
      return Icons.token;
    case 'Tome':
      return Icons.menu_book;
    case 'Spellbook':
      return Icons.auto_stories;
    default:
      return Icons.inventory_2;
  }
}

/// A specific item's icon — sharper than [itemTypeIcon] for the "Weapon"
/// category, where sword/dagger/spear/staff/shield items would otherwise
/// all render as the same gavel glyph. Falls back to [itemTypeIcon] for
/// every other type, and for a weapon id that doesn't match a known prefix.
IconData itemIcon(String? id, String? itemType) {
  if (itemType == 'Weapon' && id != null) {
    if (id.startsWith('dagger')) return Icons.content_cut;
    if (id.startsWith('spear')) return Icons.double_arrow;
    if (id.startsWith('staff')) return Icons.auto_fix_high;
    if (id.startsWith('shield')) return Icons.security;
  }
  return itemTypeIcon(itemType);
}

IconData elementIcon(String? element) {
  switch (element) {
    case 'Fire':
      return Icons.local_fire_department;
    case 'Wind':
      return Icons.air;
    case 'Earth':
      return Icons.terrain;
    case 'Water':
      return Icons.water_drop;
    case 'Electricity':
      return Icons.bolt;
    case 'Void':
      return Icons.blur_on;
    default:
      return Icons.circle_outlined;
  }
}

IconData questCategoryIcon(String? category) {
  switch (category) {
    case 'Main':
      return Icons.star;
    case 'Side':
      return Icons.explore;
    case 'Daily':
      return Icons.today;
    case 'Event':
      return Icons.celebration;
    default:
      return Icons.assignment;
  }
}

/// A quest's icon, keyed off what its first objective actually asks the
/// player to do — sharper than [questCategoryIcon] alone, which otherwise
/// gives every "Main" quest the same star regardless of whether it's a
/// fight, a fetch, or a conversation. Falls back to [questCategoryIcon] for
/// an objective type this doesn't recognize (or a quest with none).
IconData questIcon(String? category, String? firstObjectiveType) {
  switch (firstObjectiveType) {
    case 'Kill':
      return Icons.sports_martial_arts;
    case 'Fetch':
      return Icons.backpack;
    case 'Talk':
      return Icons.chat_bubble_outline;
    default:
      return questCategoryIcon(category);
  }
}

IconData adventureNodeCategoryIcon(String? category) {
  switch (category) {
    case 'Combat':
      return Icons.sports_martial_arts;
    case 'Event':
      return Icons.celebration;
    case 'Shop':
      return Icons.storefront;
    case 'Rest':
      return Icons.hotel;
    case 'Treasure':
      return Icons.diamond;
    case 'Puzzle':
      return Icons.extension;
    case 'Travel':
      return Icons.explore;
    default:
      return Icons.place;
  }
}

IconData gameDbIcon(String schemaId) {
  switch (schemaId) {
    case 'items':
      return Icons.inventory_2;
    case 'skills':
      return Icons.auto_awesome;
    case 'dice':
      return Icons.casino;
    case 'enemies':
      return Icons.pest_control;
    case 'enemy_ships':
      return Icons.rocket_launch;
    case 'ships':
      return Icons.directions_boat;
    case 'ship_parts':
      return Icons.build;
    case 'quests':
      return Icons.assignment;
    case 'shops':
      return Icons.storefront;
    case 'gates':
      return Icons.door_front_door;
    case 'adventure_nodes':
      return Icons.map;
    case 'races':
      return Icons.diversity_3;
    case 'professions':
      return Icons.work;
    default:
      return Icons.table_chart;
  }
}

const IconData enemyIcon = Icons.pest_control;
const IconData shopIcon = Icons.storefront;
const IconData raceIcon = Icons.diversity_3;
const IconData professionIcon = Icons.work;
