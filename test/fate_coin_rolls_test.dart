// The fate coin on the camp's fate check and on the forge (fate_coin.dart):
// a failed check at the fire or a Flawed piece at the anvil offers the
// coin when the pack holds one; flipped, it is spent and the roll is made
// once more.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/camp_fate.dart';
import 'package:narrative_data_app/data/fate_coin.dart';
import 'package:narrative_data_app/data/forge_roll.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/camp_fate_dialog.dart';

/// Dice that land on [faces] in turn (a d20's face, 1 to 20), the last one
/// again once they run out.
class _Faces implements Random {
  _Faces(this.faces);
  final List<int> faces;
  var _at = 0;
  @override
  int nextInt(int max) {
    final face = faces[min(_at, faces.length - 1)];
    _at++;
    return (face - 1) % max;
  }

  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => true;
}

final Map<String, dynamic> _items =
    jsonDecode(File('assets/gamedata/items.json').readAsStringSync())
        as Map<String, dynamic>;

Future<PlayerSessionNotifier> _notifierWith(Map<String, dynamic> json) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(PlayerSession.fromJson(json));
  return notifier;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the forge', () {
    test('only a Flawed piece is worth the coin', () {
      for (final (face, worth) in [(2, true), (10, false), (17, false)]) {
        expect(fateCoinWorthFlippingForge(ForgeRoll(face: face)), worth,
            reason: 'd20 $face');
      }
    });

    test('forged once more: a new d20, the same modifiers', () {
      const dwarf =
          ForgeModifier(source: 'dwarf', labelKey: 'forge_mod_dwarf', value: 2);
      final again =
          reforgedRoll(ForgeRoll(face: 1, modifiers: [dwarf]), _Faces([15]));
      expect(again.face, 15);
      expect(again.modifiers, [dwarf]);
      expect(again.tier, ForgeTier.fine);
    });

    test('the coin is spent and the piece takes the new tier', () async {
      final notifier = await _notifierWith({
        'raceId': 'human',
        'gold': 100,
        'inventoryItemIds': [
          ...List.filled(4, 'material_iron_ore'),
          fateCoinId,
        ],
      });
      final boots = _items['boots_iron_shod'] as Map<String, dynamic>;
      final roll = await notifier.craftItem('boots_iron_shod', boots,
          random: _Faces([2]), modifiers: const []);
      expect(roll!.tier, ForgeTier.flawed);
      final again = await notifier.reforgeWithFateCoin(
          'boots_iron_shod@flawed', roll,
          random: _Faces([20]));
      expect(again!.tier, ForgeTier.masterwork);
      expect(notifier.state.inventoryItemIds,
          ['material_iron_ore', 'boots_iron_shod@masterwork']);
      // No coin left: no second chance.
      expect(
          await notifier.reforgeWithFateCoin(
              'boots_iron_shod@masterwork', again),
          isNull);
      expect(
          notifier.state.inventoryItemIds.last, 'boots_iron_shod@masterwork');
    });
  });

  testWidgets('a thief slips by; the coin rolls the Perception once more',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const camp = FateContext(
      chapter: 4,
      gold: 500,
      provisions: 8,
      provisionsMax: 8,
      companionIds: [],
      rumorPlaceIds: [],
    );
    const roll = FateRoll(faceIndex: 4, face: FateFace.theft);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => CampFateDialog(
                  fateContext: camp,
                  roll: roll,
                  // The first check lands a 1, the coin's a 20.
                  random: _Faces([1, 20]),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() async {
      final notifier = container.read(playerSessionProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await notifier.loadSession(PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'gold': 500,
        'provisions': 8,
        'inventoryItemIds': [fateCoinId],
      }));
    });

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fate_roll_button')));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fate_coin_offer')), findsOneWidget);
    await tester.tap(find.byKey(const Key('fate_coin_flip')));
    for (var i = 0;
        i < 20 && find.textContaining('thin hand').evaluate().isEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('The coin lands'), findsOneWidget);
    expect(find.textContaining('thin hand'), findsOneWidget);
    final session = container.read(playerSessionProvider);
    expect(session.inventoryItemIds, isNot(contains(fateCoinId)));
    expect(session.gold, 500);
  });

  testWidgets('without a coin, the thief gets away as before', (tester) async {
    SharedPreferences.setMockInitialValues({});
    const camp = FateContext(
      chapter: 4,
      gold: 500,
      provisions: 8,
      provisionsMax: 8,
      companionIds: [],
      rumorPlaceIds: [],
    );
    const roll = FateRoll(faceIndex: 4, face: FateFace.theft);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => CampFateDialog(
                  fateContext: camp,
                  roll: roll,
                  random: _Faces([1]),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    final container =
        ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
    await tester.runAsync(() async {
      final notifier = container.read(playerSessionProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await notifier.loadSession(PlayerSession.fromJson({
        'raceId': 'human',
        'professionId': 'warrior',
        'gold': 500,
        'provisions': 8,
      }));
    });
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fate_roll_button')));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fate_coin_offer')), findsNothing);
    for (var i = 0;
        i < 20 && find.textContaining('long gone').evaluate().isEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('long gone'), findsOneWidget);
  });
}
