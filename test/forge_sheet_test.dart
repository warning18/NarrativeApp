// What the forge's sheet reads (v1.592, forge_roll.dart): the modifiers with
// their values and labels, the odds of each tier on the d20 with them, the
// piece before and after each tier, the tier a face gives; and the camp's
// Bone-Caster's Hut rolling the forge once more for a charge.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/forge_roll.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';

/// A d20 that lands on [face].
class _Face implements Random {
  _Face(this.face);
  final int face;
  @override
  int nextInt(int max) => (face - 1) % max;
  @override
  double nextDouble() => 0;
  @override
  bool nextBool() => false;
}

final Map<String, dynamic> _items =
    jsonDecode(File('assets/gamedata/items.json').readAsStringSync())
        as Map<String, dynamic>;

Map<String, dynamic> get _boots =>
    _items['boots_iron_shod'] as Map<String, dynamic>;

Future<PlayerSessionNotifier> _notifierWith(Map<String, dynamic> json) async {
  SharedPreferences.setMockInitialValues({});
  final notifier = PlayerSessionNotifier();
  await Future<void>.delayed(const Duration(milliseconds: 200));
  await notifier.loadSession(PlayerSession.fromJson(json));
  return notifier;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the sheet', () {
    test('no modifier: the plain odds, the piece at each tier', () {
      final sheet = forgeSheetFor(_boots);
      expect(sheet.modifierTotal, 0);
      expect(sheet.modifiers, isEmpty);
      expect(sheet.odds[ForgeTier.flawed], closeTo(0.20, 1e-9));
      expect(sheet.odds[ForgeTier.sound], closeTo(0.50, 1e-9));
      expect(sheet.odds[ForgeTier.fine], closeTo(0.25, 1e-9));
      expect(sheet.odds[ForgeTier.masterwork], closeTo(0.05, 1e-9));
      final sound = sheet.pieceAt[ForgeTier.sound]!;
      expect(sound.after, sound.before);
      expect(sound.resaleAfter, sound.resaleBefore);
      expect(sheet.pieceAt[ForgeTier.fine]!.after, sound.before + 1);
      expect(sheet.pieceAt[ForgeTier.masterwork]!.after, sound.before + 2);
      expect(sheet.pieceAt[ForgeTier.flawed]!.after, max(0, sound.before - 1));
      expect(sheet.pieceAt[ForgeTier.fine]!.resaleAfter,
          greaterThan(sound.resaleBefore));
      expect(sheet.tierOf(10), ForgeTier.sound);
    });

    test('a dwarf with friends at the forge: +3, and the odds follow', () {
      final mods = forgeModifiersFor(
          raceId: 'dwarf', holderId: 'compact', holderTier: null);
      expect(mods.map((m) => (m.source, m.value)), [('dwarf', 2)]);
      final sheet = forgeSheetFor(_boots, modifiers: [
        ...mods,
        const ForgeModifier(
            source: 'standing',
            labelKey: 'forge_mod_friends',
            value: friendlyForgeBonus,
            clanId: 'compact'),
      ]);
      expect(sheet.modifierTotal, 3);
      expect(sheet.odds, forgeOdds(3));
      expect(sheet.odds.values.fold(0.0, (a, b) => a + b), closeTo(1, 1e-9));
      expect(sheet.tierOf(17), ForgeTier.masterwork);
      expect(sheet.tierOf(1), ForgeTier.flawed);
      // A roll's own reading matches the sheet's.
      final roll = ForgeRoll(face: 13, modifiers: sheet.modifiers);
      expect(roll.total, 16);
      expect(roll.tier, sheet.tierOf(13));
    });
  });

  group('the Bone-Caster\'s Hut on the forge', () {
    Map<String, dynamic> forger({bool hut = true, int charges = 1}) => {
          'raceId': 'human',
          'gold': 100,
          'inventoryItemIds': List.filled(4, 'material_iron_ore'),
          if (hut) 'builtHouseIds': ['bone_casters_hut'],
          'rerollCharges': charges,
        };

    test('a charge rolls the forge again; the piece takes the new tier',
        () async {
      final notifier = await _notifierWith(forger());
      final roll = await notifier.craftItem('boots_iron_shod', _boots,
          random: _Face(2), modifiers: const []);
      expect(roll!.tier, ForgeTier.flawed);
      expect(notifier.canRerollForge, isTrue);
      final again = await notifier.rerollForge('boots_iron_shod@flawed', roll,
          random: _Face(18));
      expect(again!.tier, ForgeTier.fine);
      expect(notifier.state.rerollCharges, 0);
      expect(notifier.state.inventoryItemIds.last, 'boots_iron_shod@fine');
      // The charge is spent: no second reroll.
      expect(notifier.canRerollForge, isFalse);
      expect(await notifier.rerollForge('boots_iron_shod@fine', again), isNull);
    });

    test('no hut, or no such piece: nothing happens', () async {
      final noHut = await _notifierWith(forger(hut: false, charges: 2));
      expect(noHut.canRerollForge, isFalse);
      final roll = ForgeRoll(face: 2);
      expect(await noHut.rerollForge('boots_iron_shod@flawed', roll), isNull);
      final hut = await _notifierWith(forger());
      expect(await hut.rerollForge('boots_iron_shod@flawed', roll), isNull);
      expect(hut.state.rerollCharges, 1);
    });
  });
}
