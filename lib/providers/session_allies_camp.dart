// The session notifier's recruiting and the bench, houses, town additions, zones, ships and ports, the companions' kit and healing (4f, see player_session_provider.dart).
part of 'player_session_provider.dart';

mixin _AlliesCampActions on _SessionNotifierBase {
  /// Grants a companion permanently once their recruit quest completes — see
  /// the `rewardAllyId` handling at the Quests tab's completion call site.
  /// No-ops if already recruited (recruiting is a one-time story reward).
  /// [race]/[profession] are the companion's own race/profession records
  /// (looked up via their companions.json entry), used only to seed their
  /// starting unlocked skills exactly like [startNewGame] does for the
  /// player — an ally's actual combat stats are always derived live, never
  /// stored (see [AllyState]'s class doc).
  Future<void> recruitAlly(
    String companionId, {
    Map<String, dynamic>? race,
    Map<String, dynamic>? profession,
    Map<String, dynamic>? companion,
    Map<String, dynamic> dice = const {},
    Map<String, dynamic> houses = const {},
    String? requiredHouseId,
  }) async {
    if (state.recruitedAllies.any((a) => a.companionId == companionId)) return;
    if (state.lostAllyIds.contains(companionId)) return;
    if (state.departedAllyIds.contains(companionId)) return;
    final starterUnlocked = companionStarterSkillIds(
      race: race,
      profession: profession,
      companion: companion,
      dice: dice,
    );
    // A freshly recruited companion joins the fight immediately, up to
    // capacity -- Camp is where the roster is *managed*, not a
    // precondition for a new ally actually helping in combat (and Camp
    // itself may not even be unlocked yet when an early companion is
    // recruited).
    final houseBuilt = requiredHouseId == null ||
        requiredHouseId.isEmpty ||
        state.builtHouseIds.contains(requiredHouseId);
    final autoActivate = houseBuilt &&
        state.activeAllyIds.length <
            partyCapacityFor(state.builtHouseIds, houses);
    state = state.copyWith(
      recruitedAllies: [
        ...state.recruitedAllies,
        AllyState(
          companionId: companionId,
          currentHealth: AllyState.fullHealthSentinel,
          unlockedSkillIds: starterUnlocked,
        ),
      ],
      activeAllyIds: autoActivate
          ? [...state.activeAllyIds, companionId]
          : state.activeAllyIds,
    );
    await _persist();
  }

  /// Whether the camp may bench [companionId] ([companions]: the
  /// companions.json table): not Vica when she is the last one seated.
  bool canBench(String companionId, Map<String, dynamic> companions) =>
      canBenchCompanion(companionId,
          active: state.activeAllyIds, companions: companions);

  /// Recruits the story's companions (story_companions.dart) the story has
  /// reached: one of their join scenes is in [visited]. A save already past
  /// Vica's scene gets her this way too, on load. [races], [professions],
  /// [dice] and [houses] as for [recruitAlly]. Returns who joined.
  Future<List<String>> recruitStoryCompanions(
    Iterable<String> visited, {
    required Map<String, dynamic> companions,
    Map<String, dynamic> races = const {},
    Map<String, dynamic> professions = const {},
    Map<String, dynamic> dice = const {},
    Map<String, dynamic> houses = const {},
  }) async {
    final due = storyRecruitsDue(companions,
        visited: visited,
        recruited: [for (final a in state.recruitedAllies) a.companionId],
        gone: [...state.lostAllyIds, ...state.departedAllyIds]);
    for (final id in due) {
      final companion = companions[id] as Map<String, dynamic>?;
      await recruitAlly(
        id,
        race: races[companion?['raceId']?.toString() ?? '']
            as Map<String, dynamic>?,
        profession: professions[companion?['professionId']?.toString() ?? '']
            as Map<String, dynamic>?,
        companion: companion,
        dice: dice,
        houses: houses,
        requiredHouseId: companion?['requiredHouseId']?.toString(),
      );
    }
    return due;
  }

  /// Adds or removes [companionId] from the active fight party.
  /// [partyCapacity] and [requiredHouseId] (that companion's own gate, if
  /// any, from companions.json) are enforced here as well as in the Camp
  /// UI, matching how e.g. [buyItem] re-checks affordability itself.
  Future<void> setAllyActive(
    String companionId,
    bool active, {
    required int partyCapacity,
    String? requiredHouseId,
    Map<String, dynamic> companions = const {},
  }) async {
    if (!state.recruitedAllies.any((a) => a.companionId == companionId)) return;
    if (!active) {
      if (!state.activeAllyIds.contains(companionId)) return;
      // Vica is benched only by seating someone else; anyone else benched
      // to an empty party leaves her seat to her (story_companions.dart).
      if (!canBench(companionId, companions)) return;
      state = state.copyWith(
        activeAllyIds: withPermanentSeated(
          state.activeAllyIds.where((id) => id != companionId).toList(),
          recruited: [
            for (final a in state.recruitedAllies)
              if (a.companionId != companionId) a.companionId,
          ],
          companions: companions,
        ),
      );
      await _persist();
      return;
    }
    if (state.activeAllyIds.contains(companionId)) return;
    // Never more than three fighters (v1.664), whatever the caller passed.
    if (state.activeAllyIds.length >= min(partyCapacity, basePartyCapacity)) {
      return;
    }
    if (requiredHouseId != null &&
        requiredHouseId.isNotEmpty &&
        !state.builtHouseIds.contains(requiredHouseId)) {
      return;
    }
    state =
        state.copyWith(activeAllyIds: [...state.activeAllyIds, companionId]);
    await _persist();
  }

  /// Spends gold to build a camp house. No-ops if already built or
  /// unaffordable. [unlocksShopId] (the house's own `unlocksShopId` field,
  /// e.g. Hammersmith opening its Forge) is passed through to
  /// [unlockContent] so building the house and gaining access to its shop
  /// are one atomic action, exactly like [recruitAlly]'s starter-skill
  /// unlock is one action rather than two.
  /// Spends [cost] and marks [houseId] built, unlocking [unlocksShopId] if
  /// any. A no-op if unaffordable (gold, or the [materialCost] in the pack,
  /// see materials.dart), already built, or any of [requiredFlags]
  /// (houses.json) is still unset -- the camp's late workshops wait on the
  /// zones that supply them -- unless one of [unlockedByFlags] is set.
  ///
  /// A house still locked (see camp_works.dart) is refused too: one whose
  /// tier comes in a chapter after [chapter] ([fromChapter], the tier's
  /// first), or whose companion ([requiredAllyId]) is not recruited.
  Future<void> buildHouse(String houseId, int cost,
      {String? unlocksShopId,
      List<String> requiredFlags = const [],
      List<String> unlockedByFlags = const [],
      Map<String, int> materialCost = const {},
      int fromChapter = 1,
      int? chapter,
      String? requiredAllyId,
      String? rollPower}) async {
    if (state.gold < cost || state.builtHouseIds.contains(houseId)) return;
    if (chapter != null && chapter < fromChapter) return;
    if ((requiredAllyId ?? '').isNotEmpty &&
        !state.recruitedAllies.any((a) => a.companionId == requiredAllyId)) {
      return;
    }
    if (!unlockedByFlags.any(state.flags.contains) &&
        requiredFlags.any((flag) => !state.flags.contains(flag))) {
      return;
    }
    if (missingMaterials(state.inventoryItemIds, materialCost).isNotEmpty) {
      return;
    }
    // The story reads the camp's buildings back through a flag per house
    // (see houseFlag).
    final flag = houseFlag(houseId);
    state = state.copyWith(
      gold: state.gold - cost,
      inventoryItemIds: withoutMaterials(state.inventoryItemIds, materialCost),
      builtHouseIds: [...state.builtHouseIds, houseId],
      flags: state.flags.contains(flag) ? state.flags : [...state.flags, flag],
      townOrder: [...state.townPieces, houseId],
    );
    // A roll house (camp_rolls.dart) comes with its charges.
    switch (rollPowerNamed(rollPower) ?? rollPowerHouses[houseId]) {
      case RollPower.reroll:
        state =
            state.copyWith(rerollCharges: chargesWhenBuilt(RollPower.reroll));
      case RollPower.banish:
        state =
            state.copyWith(banishCharges: chargesWhenBuilt(RollPower.banish));
      case RollPower.raise:
        state = state.copyWith(raiseCharges: chargesWhenBuilt(RollPower.raise));
      case null:
        break;
    }
    await _persist();
    if (unlocksShopId != null && unlocksShopId.isNotEmpty) {
      await unlockContent(shopId: unlocksShopId);
    }
  }

  /// Spends [cost] on a town addition ([type], one of
  /// `cliff_town.dart`'s additions) and raises it on the cliff. Additions
  /// are the town's own: they add rooms and lights, no bonuses. A no-op
  /// if unaffordable, or when the town already holds as many as it may
  /// (see townAdditionLimit).
  Future<void> buildTownAddition(String type, int cost) async {
    if (state.gold < cost) return;
    final limit = townAdditionLimitOf(type,
        pieces: state.townPieces, houseCount: state.builtHouseIds.length);
    if (limit.atLimit) return;
    state = state.copyWith(
      gold: state.gold - cost,
      townOrder: [...state.townPieces, type],
    );
    await _persist();
  }

  // --- Expedition zones ----------------------------------------------------

  /// Banks a zone's completion reward — the payoff for clearing every
  /// expedition in [zoneId] in one run without retreating (see
  /// [ExpeditionScreen]). No-ops if already banked (a zone pays out once).
  /// Ally rewards aren't handled here, mirroring [completeQuest]'s own
  /// `rewardAllyId` convention: the caller looks up the companion's
  /// race/profession and calls [recruitAlly] itself.
  Future<void> completeZone(
    String zoneId, {
    int rewardGold = 0,
    String? rewardItemId,
    String? rewardDiceId,
    String? rewardFlag,
    Map<String, int> rewardMaterials = const {},
    ItemOrigin? origin,
  }) async {
    if (state.completedZoneIds.contains(zoneId)) return;
    final newInventory = [
      ...state.inventoryItemIds,
      // The zone's materials (zones.json rewardMaterials).
      for (final e in rewardMaterials.entries)
        for (var i = 0; i < e.value; i++) e.key,
    ];
    var newOrigins = state.itemOrigins;
    if (rewardItemId != null && rewardItemId.isNotEmpty) {
      newInventory.add(rewardItemId);
      newOrigins = withItemOrigins(newOrigins, [rewardItemId], origin);
    }
    var newOwnedDice = state.ownedDiceIds;
    if (rewardDiceId != null &&
        rewardDiceId.isNotEmpty &&
        !newOwnedDice.contains(rewardDiceId)) {
      newOwnedDice = [...newOwnedDice, rewardDiceId];
    }
    var newFlags = state.flags;
    if (rewardFlag != null &&
        rewardFlag.isNotEmpty &&
        !newFlags.contains(rewardFlag)) {
      newFlags = [...newFlags, rewardFlag];
    }
    state = state.copyWith(
      gold: state.gold + rewardGold,
      inventoryItemIds: newInventory,
      itemOrigins: newOrigins,
      ownedDiceIds: newOwnedDice,
      flags: newFlags,
      completedZoneIds: [...state.completedZoneIds, zoneId],
    );
    await _persist();
  }

  /// Stores the Rusty Eel's hull after a voyage event or ship battle
  /// (-1 = full).
  Future<void> setShipHull(int hull) async {
    state = state.copyWith(shipHull: hull);
    await _persist();
  }

  /// Buys and fits a ship part; false (and nothing spent) if it is already
  /// aboard or unaffordable. Slot room is the caller's check (see
  /// ship_combat.dart's canInstallPart); [replacing] come off to make it,
  /// and wait at the Harbor (see [storedShipPartIds]). A stored part goes
  /// back on for nothing, whatever [cost] says.
  Future<bool> installShipPart(String partId, int cost,
      {List<String> replacing = const []}) async {
    final stored = state.storedShipPartIds.contains(partId);
    final price = stored ? 0 : cost;
    if (state.shipPartIds.contains(partId) || state.gold < price) return false;
    final removed = [
      for (final id in state.shipPartIds)
        if (replacing.contains(id)) id,
    ];
    state = state.copyWith(
      gold: state.gold - price,
      // Repainting the sail takes the old sigil off (see sail_powers.dart).
      shipPartIds: [
        ...state.shipPartIds.where((id) => !replacing.contains(id)),
        partId,
      ],
      storedShipPartIds: [
        for (final id in state.storedShipPartIds)
          if (id != partId) id,
        ...removed,
      ],
    );
    await _persist();
    return true;
  }

  /// Writes what the crew knows of the sea beast [beastId] (see
  /// sea_beasts.dart), from [update] of what they knew.
  Future<void> updateSeaBeast(
      String beastId, BeastState Function(BeastState beast) update) async {
    state = state.copyWith(seaBeasts: {
      ...state.seaBeasts,
      beastId: update(state.seaBeasts[beastId] ?? const BeastState()),
    });
    await _persist();
  }

  /// Puts a part won at sea in the Harbor's store (no room aboard for it
  /// now): it goes on later for nothing (see [installShipPart]).
  Future<void> storeShipPart(String partId) async {
    if (state.shipPartIds.contains(partId) ||
        state.storedShipPartIds.contains(partId)) {
      return;
    }
    state =
        state.copyWith(storedShipPartIds: [...state.storedShipPartIds, partId]);
    await _persist();
  }

  /// Rebuilds the Eel on the hull [hullId] (see ship_forms.dart), paying
  /// [cost] unless she has been built on it before; false (and nothing
  /// changed) if it is her hull already or unaffordable. [toStore] are the
  /// parts the new hull has no slot for: they wait at the Harbor (see
  /// [storedShipPartIds]). [hull] is the hull she is rebuilt with, -1 for
  /// full.
  Future<bool> rebuildHull(String hullId, int cost,
      {List<String> toStore = const [], int hull = -1}) async {
    if (state.shipHullId == hullId) return false;
    final owned = state.ownedHullIds.contains(hullId);
    final price = owned ? 0 : cost;
    if (state.gold < price) return false;
    state = state.copyWith(
      gold: state.gold - price,
      shipHullId: hullId,
      ownedHullIds:
          owned ? state.ownedHullIds : [...state.ownedHullIds, hullId],
      shipPartIds: [
        for (final id in state.shipPartIds)
          if (!toStore.contains(id)) id,
      ],
      storedShipPartIds: [
        ...state.storedShipPartIds,
        for (final id in toStore)
          if (!state.storedShipPartIds.contains(id)) id,
      ],
      shipHull: hull,
    );
    await _persist();
    return true;
  }

  /// Wears the look [lookId] in its [category], buying it first for [cost]
  /// when it is not yet owned; false (and nothing changed) if it cannot be
  /// afforded. A default look is always owned, so [cost] 0 is the caller's
  /// way to wear one.
  Future<bool> wearShipLook(String category, String lookId, int cost) async {
    final owned = state.ownedShipLooks.contains(lookId);
    final price = owned ? 0 : cost;
    if (state.gold < price) return false;
    state = state.copyWith(
      gold: state.gold - price,
      shipLooks: {...state.shipLooks, category: lookId},
      ownedShipLooks:
          owned ? state.ownedShipLooks : [...state.ownedShipLooks, lookId],
    );
    await _persist();
    return true;
  }

  /// Pays [cost] to restore the hull to full; false if unaffordable.
  Future<bool> repairShip(int cost) async {
    if (state.gold < cost) return false;
    state = state.copyWith(gold: state.gold - cost, shipHull: -1);
    await _persist();
    return true;
  }

  /// Landfall: the boat is now moored at [portId].
  Future<void> arriveAtPort(String portId) async {
    state = state.copyWith(
      currentPortId: portId,
      visitedPortIds: state.visitedPortIds.contains(portId)
          ? state.visitedPortIds
          : [...state.visitedPortIds, portId],
    );
    await _persist();
  }

  /// Runs [update] against the named ally's current [AllyState] and writes
  /// the result back into [recruitedAllies] — the shared plumbing every
  /// per-ally mutator below uses, since an ally lives inside a list rather
  /// than getting its own top-level provider.
  Future<void> _updateAlly(
    String companionId,
    AllyState Function(AllyState ally) update,
  ) async {
    final index =
        state.recruitedAllies.indexWhere((a) => a.companionId == companionId);
    if (index == -1) return;
    final newAllies = [...state.recruitedAllies];
    newAllies[index] = update(newAllies[index]);
    state = state.copyWith(recruitedAllies: newAllies);
    await _persist();
  }

  /// Equips [itemId] onto ally [companionId] — the ally equivalent of
  /// [equipItem]. Items are drawn from the same shared [inventoryItemIds]
  /// pool the player equips from (this game has one inventory, not one per
  /// character); equipping doesn't remove the item from that pool, matching
  /// [equipItem]'s own existing behavior.
  Future<void> equipAllyItem(
    String companionId,
    String itemId, {
    String? slot,
    Map<String, dynamic>? items,
  }) async {
    if (state.freeCopiesOf(itemId, wearerId: companionId) <= 0) return;
    await _updateAlly(companionId, (ally) {
      if (ally.equippedItemIds.contains(itemId)) return ally;
      var newEquipped = ally.equippedItemIds;
      if (slot != null && slot.isNotEmpty && items != null) {
        newEquipped = ally.equippedItemIds.where((id) {
          final other = items[id] as Map<String, dynamic>?;
          return (other?['equipSlot']?.toString() ?? '') != slot;
        }).toList();
      }
      return ally.copyWith(equippedItemIds: [...newEquipped, itemId]);
    });
  }

  Future<void> unequipAllyItem(String companionId, String itemId) async {
    await _updateAlly(
      companionId,
      (ally) => ally.copyWith(
        equippedItemIds:
            ally.equippedItemIds.where((id) => id != itemId).toList(),
      ),
    );
  }

  /// The ally equivalent of [unlockSkill] — spends one of the ally's own
  /// [AllyState.skillPoints].
  Future<void> unlockAllySkill(String companionId, String skillId) async {
    await _updateAlly(companionId, (ally) {
      if (ally.skillPoints <= 0 || ally.unlockedSkillIds.contains(skillId)) {
        return ally;
      }
      return ally.copyWith(
        skillPoints: ally.skillPoints - 1,
        unlockedSkillIds: [...ally.unlockedSkillIds, skillId],
      );
    });
  }

  /// The ally equivalent of [assignSkillToDiceFace]/[clearDiceFaceSkill] —
  /// flat by faceIndex rather than dice-keyed, since an ally only ever has
  /// their one fixed signature die (see [AllyState.diceSkillAssignments]).
  Future<void> assignSkillToAllyDiceFace(
      String companionId, int faceIndex, String skillId) async {
    await _updateAlly(companionId, (ally) {
      final updated = Map<String, String>.from(ally.diceSkillAssignments);
      updated[faceIndex.toString()] = skillId;
      return ally.copyWith(diceSkillAssignments: updated);
    });
  }

  Future<void> clearAllyDiceFaceSkill(String companionId, int faceIndex) async {
    await _updateAlly(companionId, (ally) {
      if (!ally.diceSkillAssignments.containsKey(faceIndex.toString())) {
        return ally;
      }
      final updated = Map<String, String>.from(ally.diceSkillAssignments)
        ..remove(faceIndex.toString());
      return ally.copyWith(diceSkillAssignments: updated);
    });
  }

  /// Persists an ally's health at the end of a fight (see [FightScreen]) —
  /// unlike the player, a lost fight simply doesn't call this, so an ally's
  /// mid-fight damage is never persisted on a loss (mirrors the player not
  /// being HP-punished on a loss either, via the existing full-heal-on-loss
  /// behavior in [applyCombatResult]).
  Future<void> applyAllyCombatResult(String companionId,
      {required int hpAfter}) async {
    await _updateAlly(
      companionId,
      (ally) => ally.copyWith(currentHealth: hpAfter < 0 ? 0 : hpAfter),
    );
  }

  /// Heals the player and every recruited ally (active or benched) to full
  /// — the Camp screen's Rest action.
  @override
  Future<void> healPartyToFull() async {
    state = state.copyWith(
      currentHealth: state.maxHealth,
      mana: state.maxMana,
      recruitedAllies: [
        for (final ally in state.recruitedAllies)
          ally.copyWith(currentHealth: AllyState.fullHealthSentinel),
      ],
    );
    await _persist();
  }

  // --- The world clock ---------------------------------------------------
}
