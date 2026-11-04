// The session notifier's dice, buying and selling, retreat, crafting, the forge, smithing, tomes and equipping (4f, see player_session_provider.dart).
part of 'player_session_provider.dart';

mixin _ShopForgeActions on _SessionNotifierBase {
  Future<void> buyDice(String diceId, int cost) async {
    if (state.gold < cost || state.ownedDiceIds.contains(diceId)) return;
    state = state.copyWith(
      gold: state.gold - cost,
      ownedDiceIds: [...state.ownedDiceIds, diceId],
    );
    await _persist();
  }

  Future<void> equipDice(String diceId) async {
    if (!state.ownedDiceIds.contains(diceId) ||
        state.equippedDiceId == diceId) {
      return;
    }
    state = state.copyWith(equippedDiceId: diceId);
    await _persist();
  }

  /// Recuts [first] and [second], two d8s the player owns, into the tally
  /// die at the Skillwright (dice_weave.dart): both are spent, their face
  /// picks with them, and the Hammersmith's work on them is paid back
  /// (smithingRefundFor). The tally die is equipped when one of the two
  /// was. False, and nothing done, when [canWeaveDice] says no.
  Future<bool> weaveDice(String first, String second,
      {required Map<String, dynamic> dice}) async {
    if (!canWeaveDice(first, second,
        owned: state.ownedDiceIds,
        builtHouseIds: state.builtHouseIds,
        dice: dice)) {
      return false;
    }
    final spent = {first, second};
    var gold = state.gold;
    final inventory = [...state.inventoryItemIds];
    for (final id in spent) {
      for (final work in (state.diceUpgrades[id] ?? const {}).values) {
        final refund = smithingRefundFor(work);
        gold += refund.gold;
        for (var i = 0; i < refund.iron; i++) {
          inventory.add(ironOreId);
        }
        for (var i = 0; i < refund.trophies; i++) {
          inventory.add(eliteTrophyId);
        }
      }
    }
    state = state.copyWith(
      gold: gold,
      inventoryItemIds: inventory,
      ownedDiceIds: [
        for (final id in state.ownedDiceIds)
          if (!spent.contains(id)) id,
        tallyDieId,
      ],
      equippedDiceId: spent.contains(state.equippedDiceId) ? tallyDieId : null,
      diceSkillAssignments: {
        for (final entry in state.diceSkillAssignments.entries)
          if (!spent.contains(entry.key)) entry.key: entry.value,
      },
      diceUpgrades: {
        for (final entry in state.diceUpgrades.entries)
          if (!spent.contains(entry.key)) entry.key: entry.value,
      },
    );
    await _persist();
    return true;
  }

  /// Spends one fate coin from the pack (fate_coin.dart), for a check
  /// rolled again. False when the pack holds none.
  Future<bool> spendFateCoin() async {
    final left = withFateCoinSpent(state.inventoryItemIds);
    if (left == null) return false;
    state = state.copyWith(inventoryItemIds: left);
    await _persist();
    return true;
  }

  /// Buys [itemId] from [shopId]. Shops have a fixed stock per item
  /// ([stockLimit], from the shop's stockQuantities data) that this tracks
  /// via [PlayerSession.shopPurchaseCounts]: gear never replenishes, and
  /// potions and scrolls restock each chapter (their [stockKey] carries the
  /// chapter, see stockKeyFor).
  Future<void> buyItem(
    String shopId,
    String itemId,
    int cost,
    int stockLimit, {
    Map<String, dynamic>? item,
    String? stockKey,
    ItemOrigin? origin,
  }) async {
    // A restocking consumable is counted per chapter (see stockKeyFor).
    final key = stockKey ?? '$shopId::$itemId';
    final purchased = state.shopPurchaseCounts[key] ?? 0;
    if (state.gold < cost || purchased >= stockLimit) return;
    // A spellbook is read on the spot: the spell joins [knownSpellIds] and
    // the book never enters the inventory. One the player already knows
    // is refused outright (the shop screen also greys it out).
    final taughtSpellId = spellbookSpellIdFor(item);
    if (taughtSpellId != null) {
      if (state.knownSpellIds.contains(taughtSpellId)) return;
      state = state.copyWith(
        gold: state.gold - cost,
        knownSpellIds: [...state.knownSpellIds, taughtSpellId],
        shopPurchaseCounts: {...state.shopPurchaseCounts, key: purchased + 1},
      );
      await _persist();
      return;
    }
    // A tome is read on the spot, as a looted one is: its points are the
    // purchase, and nothing enters the pack.
    final tome = PlayerSessionNotifier.tomeGrantFor(itemId, item);
    if (tome != null) {
      state = state.copyWith(
        gold: state.gold - cost,
        statPoints: state.statPoints + tome.statPoints,
        tomePicks: PlayerSessionNotifier._withTomePicks(
            state.tomePicks, itemId, tome.statPoints),
        pendingOffers: [...state.pendingOffers, ...tome.offers],
        shopPurchaseCounts: {...state.shopPurchaseCounts, key: purchased + 1},
      );
      await _persist();
      return;
    }
    final charges = PlayerSessionNotifier.consumableChargesFor(itemId, item);
    state = state.copyWith(
      gold: state.gold - cost,
      inventoryItemIds: charges == null
          ? [...state.inventoryItemIds, itemId]
          : state.inventoryItemIds,
      itemOrigins: charges == null
          ? withItemOrigins(state.itemOrigins, [itemId], origin)
          : state.itemOrigins,
      potionCount: state.potionCount + (charges?.potions ?? 0),
      antidoteCount: state.antidoteCount + (charges?.antidotes ?? 0),
      shopPurchaseCounts: {...state.shopPurchaseCounts, key: purchased + 1},
    );
    await _persist();
  }

  /// Sells one copy of [itemId] for [price]. Only a copy nobody wears can
  /// go; one sold where it is stocked goes back on that shop's shelf
  /// ([shopId]). Returns false when there is no free copy to sell.
  Future<bool> sellItem(String itemId,
      {required int price, String? shopId}) async {
    if (state.freeCopiesOf(itemId, wearerId: '') <= 0) return false;
    final remaining = [...state.inventoryItemIds]..remove(itemId);
    final counts = {...state.shopPurchaseCounts};
    if (shopId != null) {
      final key = '$shopId::$itemId';
      final bought = counts[key] ?? 0;
      if (bought > 0) counts[key] = bought - 1;
    }
    state = state.copyWith(
      inventoryItemIds: remaining,
      gold: state.gold + max(0, price),
      shopPurchaseCounts: counts,
    );
    await _persist();
    return true;
  }

  /// Getting away from a fight: [goldLost] spills and the wounds stay --
  /// the player's health is saved as it stands (at least 1), with the
  /// mana left. No loss is recorded and nothing is won.
  Future<void> applyRetreat({
    required int hpAfter,
    required int goldLost,
    int? manaAfter,
    bool dropPotion = false,
  }) async {
    state = state.copyWith(
      gold: max(0, state.gold - goldLost),
      potionCount: dropPotion ? max(0, state.potionCount - 1) : null,
      currentHealth: max(1, min(state.maxHealth, hpAfter)),
      mana: manaAfter ?? state.mana,
    );
    await _persist();
  }

  /// Whether the pack holds what forging [item] takes: its `craftGold` and
  /// every `craftMaterials` count (see [craftMaterialsFor]).
  bool canCraft(Map<String, dynamic>? item) {
    if (item == null) return false;
    final gold = (item['craftGold'] as num?)?.toInt() ?? 0;
    if (state.gold < gold) return false;
    return craftMaterialsFor(item).entries.every((m) =>
        state.inventoryItemIds.where((id) => id == m.key).length >= m.value);
  }

  /// Forges [itemId] from [item]'s recipe (docs/proposals/forge-roll.md):
  /// its gold and materials leave the pack, the forge rolls its d20 on
  /// [random] with [modifiers] (forgeModifiersProvider's; a dwarf's +2
  /// alone when null), and the piece enters the pack under the tier's id
  /// (forgedVariantId: `<itemId>@fine`, the plain id for Sound). A flawed
  /// roll costs nothing more. Returns the roll, or null if something is
  /// missing.
  Future<ForgeRoll?> craftItem(String itemId, Map<String, dynamic>? item,
      {ItemOrigin? origin,
      Random? random,
      List<ForgeModifier>? modifiers}) async {
    if (!canCraft(item)) return null;
    final roll = rollForge(
      random: random ?? Random(),
      modifiers: modifiers ?? forgeModifiersFor(raceId: state.raceId),
    );
    final pieceId = forgedVariantId(baseItemIdOf(itemId), roll.tier);
    final remaining = [...state.inventoryItemIds];
    for (final m in craftMaterialsFor(item).entries) {
      for (var i = 0; i < m.value; i++) {
        remaining.remove(m.key);
      }
    }
    state = state.copyWith(
      gold: state.gold - ((item!['craftGold'] as num?)?.toInt() ?? 0),
      inventoryItemIds: [...remaining, pieceId],
      itemOrigins: withItemOrigins(state.itemOrigins, [pieceId], origin),
    );
    await _persist();
    return roll;
  }

  /// Flips a fate coin on the forge [roll] that made [pieceId] (a Flawed
  /// one, fate_coin.dart): the coin is spent, the forge's d20 rolls once
  /// more on [random] with the same modifiers, and the piece in the pack
  /// takes the new tier's id. Returns the new roll, or null when the pack
  /// holds no coin or no such piece.
  Future<ForgeRoll?> reforgeWithFateCoin(String pieceId, ForgeRoll roll,
      {Random? random}) async {
    final left = withFateCoinSpent(state.inventoryItemIds);
    if (left == null || !left.contains(pieceId)) return null;
    final again = reforgedRoll(roll, random ?? Random());
    state = _withPieceReforged(
        state.copyWith(inventoryItemIds: left), pieceId, again.tier);
    await _persist();
    return again;
  }

  /// Whether a camp house can roll the forge again now: the Bone-Caster's
  /// Hut stands and has a Reroll charge (camp_rolls.dart).
  bool get canRerollForge => _has(RollPower.reroll, state.rerollCharges);

  /// The Bone-Caster's Hut's Reroll on the forge [roll] that made [pieceId]
  /// (docs/proposals/forge-roll.md, "the camp's roll houses"): one charge
  /// spent, the forge's d20 rolled once more on [random] with the same
  /// modifiers, and the piece in the pack takes the new tier's id. Returns
  /// the new roll, or null with no charge or no such piece.
  Future<ForgeRoll?> rerollForge(String pieceId, ForgeRoll roll,
      {Random? random}) async {
    if (!canRerollForge || !state.inventoryItemIds.contains(pieceId)) {
      return null;
    }
    final again = rerolledForge(roll, random ?? Random());
    state = _withPieceReforged(
        state.copyWith(rerollCharges: state.rerollCharges - 1),
        pieceId,
        again.tier);
    await _persist();
    return again;
  }

  /// [s] with the piece [pieceId] in its pack swapped for the same base
  /// forged at [tier] (its origin kept).
  PlayerSession _withPieceReforged(
      PlayerSession s, String pieceId, ForgeTier tier) {
    final pack = [...s.inventoryItemIds];
    final newId = forgedVariantId(baseItemIdOf(pieceId), tier);
    pack[pack.indexOf(pieceId)] = newId;
    return s.copyWith(
      inventoryItemIds: pack,
      itemOrigins:
          withItemOrigins(s.itemOrigins, [newId], s.itemOrigins[pieceId]),
    );
  }

  /// Whether the pack and purse cover [cost] (see face_smithing.dart).
  bool canPaySmithing(SmithingCost cost) {
    int carried(String id) =>
        state.inventoryItemIds.where((i) => i == id).length;
    final trophies = trophyItemIds.fold<int>(0, (n, id) => n + carried(id));
    return state.gold >= cost.gold &&
        carried(ironOreId) >= cost.iron &&
        trophies >= cost.trophies;
  }

  /// The Hammersmith works face [faceIndex] of die [dieId] (whose dice.json
  /// faces are [faces]), the player's own or [companionId]'s signature die:
  /// [work] is paid for (gold, iron ore, a trophy -- an Elite Mark first)
  /// and kept on that die (see [PlayerSession.upgradesOfDie]). A Temper
  /// takes [element], an inscription [keyword], a Recast [recastType].
  /// Returns false when the work doesn't fit the face or can't be paid for.
  Future<bool> smithFace({
    required String dieId,
    required int faceIndex,
    required List<Map<String, dynamic>> faces,
    required SmithingWork work,
    String? companionId,
    String? element,
    FaceKeyword? keyword,
    String? recastType,
  }) async {
    if (faceIndex < 0 || faceIndex >= faces.length) return false;
    final dieUpgrades = state.upgradesOfDie(dieId, companionId: companionId) ??
        const <String, FaceUpgrade>{};
    final current = dieUpgrades[faceIndex.toString()] ?? FaceUpgrade.none;
    final face = faces[faceIndex];
    if (!canSmith(work, face, current)) return false;
    final FaceUpgrade next;
    switch (work) {
      case SmithingWork.hone:
        next = current.copyWith(hones: current.hones + 1);
      case SmithingWork.temper:
        if (element == null ||
            !temperableElements(face, current).contains(element)) {
          return false;
        }
        next = current.copyWith(element: element);
      case SmithingWork.inscribe:
        if (keyword == null ||
            !inscribableKeywords(face, current).contains(keyword)) {
          return false;
        }
        next = current.copyWith(keyword: keyword);
      case SmithingWork.recast:
        final baseType = face['type']?.toString() ?? '';
        final from = current.recastType ?? baseType;
        if (recastType == null ||
            !smithableBasicTypes.contains(recastType) ||
            recastType == from) {
          return false;
        }
        // Back to what the die made it clears the Recast; a Temper only
        // stays on an Attack face.
        next = FaceUpgrade(
          hones: current.hones,
          element: recastType == 'Attack' ? current.element : null,
          keyword: current.keyword,
          recastType: recastType == baseType ? null : recastType,
        );
    }
    final cost = smithingCostFor(work, current);
    if (!canPaySmithing(cost)) return false;
    final remaining = [...state.inventoryItemIds];
    for (var i = 0; i < cost.iron; i++) {
      remaining.remove(ironOreId);
    }
    var trophiesLeft = cost.trophies;
    for (final id in trophyItemIds) {
      while (trophiesLeft > 0 && remaining.remove(id)) {
        trophiesLeft--;
      }
    }
    // A companion's work an older save kept under the die's id alone (on a
    // die the player doesn't own) moves under their own key with this.
    final movesOver =
        companionId != null && !state.ownedDiceIds.contains(dieId);
    state = state.copyWith(
      gold: state.gold - cost.gold,
      inventoryItemIds: remaining,
      diceUpgrades: {
        for (final entry in state.diceUpgrades.entries)
          if (!movesOver || entry.key != dieId) entry.key: entry.value,
        dieUpgradesKey(dieId, companionId: companionId): {
          ...dieUpgrades,
          faceIndex.toString(): next,
        },
      },
    );
    await _persist();
    return true;
  }

  /// Reads one carried copy of the tome [itemId] -- for a tome that reached
  /// the pack before tomes were read on the spot. No-op for anything that
  /// isn't a carried tome.
  Future<void> readTome(String itemId, Map<String, dynamic>? item) async {
    final tome = PlayerSessionNotifier.tomeGrantFor(itemId, item);
    if (tome == null || !state.inventoryItemIds.contains(itemId)) return;
    final remaining = [...state.inventoryItemIds]..remove(itemId);
    state = state.copyWith(
      inventoryItemIds: remaining,
      statPoints: state.statPoints + tome.statPoints,
      tomePicks: PlayerSessionNotifier._withTomePicks(
          state.tomePicks, itemId, tome.statPoints),
      pendingOffers: [...state.pendingOffers, ...tome.offers],
    );
    await _persist();
  }

  /// Equips [itemId]. When [slot] is given, any other equipped item sharing
  /// that slot (per [items], a map of itemId -> item record) is unequipped
  /// first, so only one item per slot is ever equipped at once.
  Future<void> equipItem(
    String itemId, {
    String? slot,
    Map<String, dynamic>? items,
  }) async {
    if (state.equippedItemIds.contains(itemId)) return;
    // No copy left that someone else isn't already wearing.
    if (state.freeCopiesOf(itemId, wearerId: playerWearerId) <= 0) return;
    var newEquipped = state.equippedItemIds;
    if (slot != null && slot.isNotEmpty && items != null) {
      newEquipped = state.equippedItemIds.where((id) {
        final other = items[id] as Map<String, dynamic>?;
        return (other?['equipSlot']?.toString() ?? '') != slot;
      }).toList();
    }
    state = state.copyWith(equippedItemIds: [...newEquipped, itemId]);
    await _persist();
  }

  Future<void> unequipItem(String itemId) async {
    if (!state.equippedItemIds.contains(itemId)) return;
    state = state.copyWith(
      equippedItemIds:
          state.equippedItemIds.where((id) => id != itemId).toList(),
    );
    await _persist();
  }

  // --- Companions (allies) & houses -------------------------------------
}
