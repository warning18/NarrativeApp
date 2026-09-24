import 'package:flutter/material.dart';

import '../game_icons.dart';
import 'enemy_icons.dart';
import 'item_icons.dart';
import 'pixel_icon.dart';
import 'shop_icons.dart';
import 'skill_icons.dart';

/// An item's pixel-art icon, keyed off its own id -- falls back to the
/// generic Material [itemIcon] glyph for an id with no generated asset
/// (a future item added before its icon is regenerated) or no id at all
/// (an empty equipment slot).
class ItemPixelIcon extends StatelessWidget {
  const ItemPixelIcon(this.itemId, this.itemType, {super.key, this.size = 32});

  final String? itemId;
  final String? itemType;
  final double size;

  @override
  Widget build(BuildContext context) {
    final id = itemId;
    if (id != null && ItemIcons.allIds.contains(id)) {
      return PixelIcon(ItemIcons.pathFor(id), size: size);
    }
    return Icon(itemIcon(itemId, itemType), size: size);
  }
}

/// A skill's pixel-art icon, keyed off its own id -- falls back to a
/// generic sparkle glyph for an id with no generated asset.
class SkillPixelIcon extends StatelessWidget {
  const SkillPixelIcon(this.skillId, {super.key, this.size = 32});

  final String skillId;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (SkillIcons.allIds.contains(skillId)) {
      return PixelIcon(SkillIcons.pathFor(skillId), size: size);
    }
    return Icon(Icons.auto_awesome, size: size);
  }
}

/// An enemy's pixel-art portrait, keyed off its own id -- falls back to
/// the generic Material [enemyIcon] glyph for an id with no generated
/// asset.
class EnemyPixelIcon extends StatelessWidget {
  const EnemyPixelIcon(this.enemyId, {super.key, this.size = 32});

  final String enemyId;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (EnemyIcons.allIds.contains(enemyId)) {
      return PixelIcon(EnemyIcons.pathFor(enemyId), size: size);
    }
    return Icon(enemyIcon, size: size);
  }
}

/// A shop's pixel-art storefront, keyed off its own id -- falls back to
/// the generic Material [shopIcon] glyph for an id with no generated
/// asset.
class ShopPixelIcon extends StatelessWidget {
  const ShopPixelIcon(this.shopId, {super.key, this.size = 32});

  final String shopId;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (ShopIcons.allIds.contains(shopId)) {
      return PixelIcon(ShopIcons.pathFor(shopId), size: size);
    }
    return Icon(shopIcon, size: size);
  }
}
