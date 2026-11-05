// What each reward of a loot changes (loot_changes.dart, v1.830, the
// spoils sheet of design C): every 'after' is what taking the loot leaves
// in the session, the way the fight takes it (applyCombatResult, then a
// potion drunk from the chest spent with consumePotion).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/combat/fight_numbers.dart';
import 'package:narrative_data_app/data/loot_changes.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

import 'player_session_provider_test.dart' show baseSession;

final Map<String, dynamic> _items =
    jsonDecode(File('assets/gamedata/items.json').readAsStringSync())
        as Map<String, dynamic>;

/// [session] after taking the loot as the fight does.
Future<PlayerSession> _take(
  PlayerSession session, {
  int gold = 0,
  List<String> itemIds = const [],
  List<String> drinks = const [],
  int potionBonus = 0,
  bool keepWounds = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 50));
  await notifier.loadSession(session);
  final drunk = keepWounds ? 0 : drinks.length;
  await notifier.applyCombatResult(
    hpAfter: healthAfterDrinks(
        health: session.currentHealth,
        maxHealth: session.maxHealth,
        drinks: drunk,
        potionBonus: potionBonus),
    keepWounds: keepWounds,
    goldGain: gold,
    itemsGained: itemIds,
    items: _items,
  );
  for (var i = 0; i < drunk; i++) {
    await notifier.consumePotion();
  }
  return notifier.state;
}

/// The last 'after' of every line of [rewards], by kind and subject.
Map<String, int> _finals(List<LootRewardChanges> rewards) => {
      for (final r in rewards)
        for (final c in r.changes)
          if (c.kind != LootChangeKind.nothing)
            '${c.kind.name}:${c.subjectId ?? ''}': c.after,
    };

int _valueOf(PlayerSession s, String key) {
  final [kind, subject] = key.split(':');
  return switch (LootChangeKind.values.byName(kind)) {
    LootChangeKind.gold => s.gold,
    LootChangeKind.potions => s.potionCount,
    LootChangeKind.antidotes => s.antidoteCount,
    LootChangeKind.bagItem =>
      s.inventoryItemIds.where((id) => id == subject).length,
    LootChangeKind.health => s.currentHealth,
    LootChangeKind.spell => s.knownSpellIds.contains(subject) ? 1 : 0,
    LootChangeKind.statPoints => s.statPoints,
    LootChangeKind.offers => s.pendingOffers.length,
    // A charm's rolls are the next fight's, read from the bag: the rule's
    // rolls and one more per Knucklebone armed.
    LootChangeKind.rollsPerRound => rollsPerRoundOf(s) +
        charmExtraRolls('charm_fourth_roll') *
            (s.inventoryItemIds.contains('charm_fourth_roll') ? 1 : 0),
    LootChangeKind.nothing => 0,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final start = baseSession(gold: 126, currentHealth: 50).copyWith(
    antidoteCount: 1,
    potionCount: 2,
    inventoryItemIds: const ['charm_fourth_roll'],
    knownSpellIds: const ['spell_war_shout'],
  );

  test('the sheet of design C: gold 126 -> 144, Antidote x1 -> x2', () {
    final rewards = lootChanges(start,
        gold: 18, itemIds: const ['antidote'], items: _items);
    expect(rewards.map((r) => r.id), [goldRewardId, 'antidote']);
    expect(rewards.first.changes.single,
        const LootChange(kind: LootChangeKind.gold, before: 126, after: 144));
    expect(rewards.last.changes.single,
        const LootChange(kind: LootChangeKind.antidotes, before: 1, after: 2));
  });

  test('every kind of reward: the after is what taking it leaves', () async {
    const loot = [
      'antidote',
      'antidote',
      'potion_minor',
      'potion_major',
      'potion_major',
      'tome_of_insight',
      'tome_of_mastery',
      'spellbook_frost_bind',
      'spellbook_war_shout',
      'spellbook_frost_bind',
      'charm_fourth_roll',
      'charm_lucky_coin',
      'elite_trophy',
      'artifact_moon_shard',
    ];
    const drinks = ['potion_minor', 'potion_major'];
    final rewards = lootChanges(start,
        gold: 18,
        itemIds: loot,
        items: _items,
        drinkItemIds: drinks,
        potionBonus: 2);
    final after = await _take(start,
        gold: 18, itemIds: loot, drinks: drinks, potionBonus: 2);
    final finals = _finals(rewards);
    for (final MapEntry(:key, :value) in finals.entries) {
      expect(_valueOf(after, key), value, reason: key);
    }
    // Every kind the loot holds has its line.
    expect(
        finals.keys.map((k) => k.split(':').first).toSet(),
        containsAll([
          for (final k in LootChangeKind.values)
            if (k != LootChangeKind.nothing) k.name,
        ]));

    LootRewardChanges at(int i) => rewards[i + 1];
    // Two antidotes: x1 -> x2, then x2 -> x3.
    expect(at(0).changes.single.before, 1);
    expect(
        at(1).changes.single,
        isA<LootChange>()
            .having((c) => c.before, 'before', 2)
            .having((c) => c.after, 'after', 3));
    // A Minor potion drunk heals 8 (+2 of the bonus), its charge spent.
    expect(at(2).changes.single,
        const LootChange(kind: LootChangeKind.health, before: 50, after: 60));
    // A Major one drunk heals once and leaves one of its two charges.
    expect(at(3).changes, const [
      LootChange(kind: LootChangeKind.health, before: 60, after: 70),
      LootChange(kind: LootChangeKind.potions, before: 2, after: 3),
    ]);
    // Kept, both its charges.
    expect(at(4).changes.single,
        const LootChange(kind: LootChangeKind.potions, before: 3, after: 5));
    expect(
        at(7).changes.single,
        const LootChange(
            kind: LootChangeKind.spell,
            subjectId: 'spell_frost_bind',
            before: 0,
            after: 1));
    // A spell already known, or learnt from the book before it: nothing.
    expect(at(8).visible, isFalse);
    expect(at(9).visible, isFalse);
    expect(at(10).changes, [
      const LootChange(
          kind: LootChangeKind.bagItem,
          subjectId: 'charm_fourth_roll',
          before: 1,
          after: 2),
      const LootChange(
          kind: LootChangeKind.rollsPerRound,
          before: maxRollsPerTurn,
          after: maxRollsPerTurn + 1),
    ]);
    // Gear goes in the bag to wear: nothing to count.
    expect(at(13).visible, isFalse);
    expect(after.inventoryItemIds, contains('artifact_moon_shard'));
  });

  test('in a chain with no healing a potion picked to drink is kept', () async {
    final rewards = lootChanges(start,
        itemIds: const ['potion_minor'],
        items: _items,
        drinkItemIds: const ['potion_minor'],
        keepWounds: true);
    expect(rewards.single.changes.single,
        const LootChange(kind: LootChangeKind.potions, before: 2, after: 3));
    final after = await _take(start,
        itemIds: const ['potion_minor'],
        drinks: const ['potion_minor'],
        keepWounds: true);
    expect(after.potionCount, 3);
    expect(after.currentHealth, 50);
  });

  test('a heal stops at the hero\'s health, and no gold is no gold line', () {
    final full = start.copyWith(currentHealth: 98);
    final rewards = lootChanges(full,
        itemIds: const ['potion_minor'],
        items: _items,
        drinkItemIds: const ['potion_minor']);
    expect(rewards.single.changes.single,
        const LootChange(kind: LootChangeKind.health, before: 98, after: 100));
    expect(lootChanges(start), isEmpty);
  });
}
