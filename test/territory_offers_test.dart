// Offers and the throne by power and territory (v5.2 step 6, PR 4): a
// clan's power caps the signs it gives, the holder of the place comes more
// often, a fallen clan sends no one but to those who stayed of it, nor
// comes to the Host unpledged; and the crisis paid in timber and stone.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/clan_crisis.dart';
import 'package:narrative_data_app/data/clan_power.dart';
import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/data/geography.dart';
import 'package:narrative_data_app/data/offers.dart';
import 'package:narrative_data_app/data/signs.dart';
import 'package:narrative_data_app/data/throne.dart';
import 'package:narrative_data_app/models/story_node.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'player_session_provider_test.dart' show baseSession;

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final data = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
  );
  PoliticsState at(Map<String, num> standings, [PoliticsState? from]) {
    var state = from ?? PoliticsState.empty;
    for (final e in standings.entries) {
      state = setStandingValue(state, e.key, e.value, 'edit', data: data).state;
    }
    return state;
  }

  test('a clan\'s power caps the signs it gives', () {
    expect(maxSignRarityFor(PowerTier.minor), SignRarity.epic);
    expect(maxSignRarityFor(PowerTier.rising), SignRarity.heroic);
    expect(maxSignRarityFor(PowerTier.dominant), SignRarity.heroic);
    const heroic =
        OfferGift(kind: GiftKind.sign, id: 'x', rarity: SignRarity.heroic);
    Suitor? suitor(int power) => drawSuitor(
        'mire',
        OfferContext(
            data: data,
            politics: PoliticsState.empty.copyWith(power: {'mire': power})),
        Random(1),
        gift: heroic);
    expect(suitor(10)!.gift.rarity, SignRarity.epic);
    expect(suitor(30)!.gift.rarity, SignRarity.heroic);
    expect(suitor(60)!.gift.rarity, SignRarity.heroic);
    // A skill keeps its own rarity.
    final skill = drawSuitor(
        'mire',
        OfferContext(
            data: data,
            politics: PoliticsState.empty.copyWith(power: {'mire': 10})),
        Random(1),
        gift: const OfferGift(
            kind: GiftKind.skill, id: 'y', rarity: SignRarity.heroic));
    expect(skill!.gift.rarity, SignRarity.heroic);
    expect(heldPlaceSuitorWeight, greaterThan(1));
  });

  test('a fallen clan sends no one, but to those who stayed of it', () {
    final crows = data.faction('crows')!;
    final fallen = PoliticsState.empty.copyWith(fallen: ['crows']);
    expect(
        suitorOpen(crows, OfferContext(data: data, politics: fallen)), isFalse);
    expect(
        suitorOpen(
            crows,
            OfferContext(
                data: data, politics: fallen.copyWith(fallenOf: 'crows'))),
        isTrue);
    expect(
        suitorOpen(
            crows, OfferContext(data: data, politics: PoliticsState.empty)),
        isTrue);
  });

  test('a fallen clan comes to the Host only pledged', () {
    final trusted = at({'compact': 40});
    expect(hostFor(politics: trusted, data: data).allies, contains('compact'));
    final fallen = trusted.copyWith(fallen: ['compact']);
    expect(hostFor(politics: fallen, data: data).allies,
        isNot(contains('compact')));
    expect(
        hostFor(politics: fallen.copyWith(pledged: ['compact']), data: data)
            .allies,
        contains('compact'));
  });

  test('the crisis paid in timber and stone', () {
    final geography = Geography.parse(
        geography: _table('geography'), biomes: _table('biomes'));
    final state = PoliticsState.empty.copyWith(crisis: {
      'clan': 'compact',
      'attacker': 'dominion',
      'place': 'emberwick'
    });
    StoryNode node(Map<String, int> materials) => buildCrisisNode(state,
        data: data,
        geography: geography,
        enemies: _table('enemies'),
        chapter: 4,
        gold: 0,
        random: Random(1),
        materials: materials)!;
    expect(node(const {}).choices.map((c) => c.text),
        isNot(contains('Send timber and stone')));
    final paid = node(const {'material_timber': 3, 'material_cut_stone': 2})
        .choices
        .singleWhere((c) => c.text == 'Send timber and stone');
    expect(
        paid.grantMaterials, {'material_timber': -3, 'material_cut_stone': -2});
    expect(paid.spendsMaterials, isTrue);
    expect(paid.hasEffects, isTrue);
    expect(paid.politics!.settleCrisis, 'paid');
  });

  test('the session spends the materials from the pack', () async {
    SharedPreferences.setMockInitialValues({});
    final notifier = PlayerSessionNotifier();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await notifier.loadSession(baseSession().copyWith(inventoryItemIds: [
      'material_timber',
      'material_timber',
      'material_timber',
      'material_timber',
      'material_cut_stone',
      'material_cut_stone',
      'potion_minor',
    ]));
    await notifier.applyChoiceEffects(
        materials: {'material_timber': -3, 'material_cut_stone': -2});
    expect(
        notifier.state.inventoryItemIds, ['material_timber', 'potion_minor']);
  });
}
