// The Forge sheet with tabs and the forging moment (v1.593,
// lib/widgets/forge_sheet.dart, forge_moment.dart): a tab for each slot a
// recipe is for, a gold dot where something can be forged now, one line for
// the roll and its odds behind a tap, a card for each piece that says what it
// lacks on its button, and the four beats of the forging.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:narrative_data_app/data/forge_roll.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/l10n/app_strings.dart';
import 'package:narrative_data_app/providers/player_session_provider.dart';
import 'package:narrative_data_app/widgets/forge_sheet.dart';
import 'support/pump.dart';

/// A random whose first `nextInt(20)` is [face] - 1, so the d20 lands on it.
class _Face implements Random {
  _Face(this.face);
  final int face;
  @override
  int nextInt(int max) => face - 1;
  @override
  double nextDouble() => 0.5;
  @override
  bool nextBool() => true;
}

/// A random that lands the d20 on each of [faces] in turn.
class _Faces extends _Face {
  _Faces(this.faces) : super(0);
  final List<int> faces;
  int _next = 0;
  @override
  int nextInt(int max) => faces[_next++ % faces.length] - 1;
}

Future<void> _settle(WidgetTester tester, {int n = 4}) async {
  for (var i = 0; i < n; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Takes the piece; the dialog's own exit needs a frame to start and one to run.
Future<void> _takeIt(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('forge_take_it')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<ProviderContainer> _open(
  WidgetTester tester, {
  int ore = 3,
  int gold = 112,
  String race = 'dwarf',
  bool reduced = false,
  AppLanguage language = AppLanguage.en,
  Map<String, dynamic> extra = const {},
}) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'), (call) async => 1);
  SharedPreferences.setMockInitialValues({});
  usePhone(tester, const Size(400, 800));
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: child!,
      ),
      home: const Scaffold(body: ForgeSheetView(shopId: 'hammersmith_forge')),
    ),
  ));
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  container.read(playerSessionProvider);
  await _settle(tester);
  await tester.runAsync(
      () => container.read(appLanguageProvider.notifier).setLanguage(language));
  await tester.runAsync(() => container
      .read(playerSessionProvider.notifier)
      .loadSession(PlayerSession.fromJson({
        'raceId': race,
        'professionId': 'warrior',
        'gold': gold,
        'inventoryItemIds': [for (var i = 0; i < ore; i++) 'material_iron_ore'],
        ...extra,
      })));
  await _settle(tester);
  return container;
}

void main() {
  setUp(() {
    rootBundle.clear();
    forgeRandomForTest = null;
  });
  tearDown(() => forgeRandomForTest = null);

  testWidgets('a tab for each slot, a dot where something can be forged',
      (tester) async {
    await _open(tester);
    for (final slot in ['Head', 'Top', 'Bottom', 'Foot']) {
      expect(find.byKey(ValueKey('forge_tab_$slot')), findsOneWidget,
          reason: slot);
    }
    // Three ore and 112 gold: the cap (2 ore) and the boots (3) can be
    // forged, the coat (5) and the greaves (4) cannot.
    expect(find.byKey(const ValueKey('forge_tab_dot_Head')), findsOneWidget);
    expect(find.byKey(const ValueKey('forge_tab_dot_Foot')), findsOneWidget);
    expect(find.byKey(const ValueKey('forge_tab_dot_Top')), findsNothing);
    expect(find.byKey(const ValueKey('forge_tab_dot_Bottom')), findsNothing);
    // The sheet opens on the first tab with something to forge.
    expect(
        find.byKey(const ValueKey('forge_card_helm_iron_cap')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('forge_card_boots_iron_shod')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('forge_tab_Foot')));
    await tester.pump();
    expect(find.byKey(const ValueKey('forge_card_boots_iron_shod')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('forge_card_helm_iron_cap')), findsNothing);
  });

  testWidgets('a piece that cannot be forged says what it lacks on its button',
      (tester) async {
    await _open(tester);
    await tester.tap(find.byKey(const ValueKey('forge_tab_Bottom')));
    await tester.pump();
    final button = find.byKey(const ValueKey('forge_go_greaves_iron'));
    expect(button, findsOneWidget);
    expect(
        find.descendant(of: button, matching: find.text('Short of 1 iron ore')),
        findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(button).onPressed, isNull);
    // What it has and needs, said plainly.
    expect(find.textContaining('Iron Ore have 3 · need 4'), findsOneWidget);
  });

  testWidgets('the roll is one line; its odds and modifiers are behind a tap',
      (tester) async {
    await _open(tester);
    expect(find.text('Roll d20 + 2'), findsOneWidget);
    expect(find.byKey(const Key('forge_odds')), findsNothing);
    await tester.tap(find.byKey(const Key('forge_odds_toggle')));
    await tester.pump();
    expect(find.byKey(const Key('forge_odds')), findsOneWidget);
    expect(find.textContaining('Dwarf +2'), findsOneWidget);
    // d20 + 2: flawed 1-2 (10%), sound 3-12 (50%), fine 13-17 (25%) and
    // masterwork 18-20 (15%).
    for (final t in ForgeTier.values) {
      expect(find.byKey(ValueKey('forge_bar_${t.name}')), findsOneWidget);
    }
    expect(find.text('10%'), findsOneWidget);
    expect(find.text('15%'), findsOneWidget);
    await tester.tap(find.byKey(const Key('forge_odds_toggle')));
    await tester.pump();
    expect(find.byKey(const Key('forge_odds')), findsNothing);
  });

  testWidgets('the ore hint is behind the (i)', (tester) async {
    await _open(tester);
    expect(find.byKey(const Key('forge_hint')), findsNothing);
    await tester.tap(find.byKey(const Key('forge_hint_button')));
    await tester.pump();
    expect(find.byKey(const Key('forge_hint')), findsOneWidget);
    expect(find.textContaining('Iron ore comes off'), findsOneWidget);
  });

  testWidgets('Dagny speaks first, in one line', (tester) async {
    await _open(tester);
    final line =
        tester.widget<Text>(find.byKey(const Key('forge_keeper_line'))).data!;
    expect(line, contains('Too heavy for the Weaponsmith, so it came to me.'));
    expect(line, contains('Dagny'));
    expect(line, isNot(contains('Lift it')));
  });

  testWidgets('forging plays the four beats and the piece is in the pack',
      (tester) async {
    // 13 + the dwarf's 2 = 15: Fine.
    forgeRandomForTest = () => _Face(13);
    final container = await _open(tester);
    await tester.tap(find.byKey(const ValueKey('forge_tab_Foot')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('forge_go_boots_iron_shod')));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
    // Beat 1: the strike, the d20 cast.
    expect(find.byKey(const Key('forge_moment')), findsOneWidget);
    expect(find.byKey(const ValueKey('forge_beat_landing')), findsOneWidget);
    expect(find.text('The forge rolls its own d20…'), findsOneWidget);
    // Beat 2: it lands; each modifier, the total.
    await tester.pump(const Duration(milliseconds: 1900));
    expect(find.text('Die'), findsOneWidget);
    expect(find.textContaining('Dwarf'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    // Beat 3: the tier is read.
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.byKey(const ValueKey('forge_beat_tier')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('forge_tier_word'))).data,
        'FINE');
    expect(find.text('15–19 · +1 to the main number'), findsOneWidget);
    // Beat 4: the piece, before and after.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('forge_beat_piece')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('forge_piece_name'))).data,
        'Fine Iron-Shod Boots');
    expect(find.textContaining('Spent: 3 iron ore · 60 gold'), findsOneWidget);
    await _takeIt(tester);
    expect(find.byKey(const Key('forge_moment')), findsNothing);
    final session = container.read(playerSessionProvider);
    expect(session.inventoryItemIds, contains('boots_iron_shod@fine'));
    expect(session.inventoryItemIds, isNot(contains('material_iron_ore')));
    expect(session.gold, 52);
  });

  testWidgets('a tap goes to the last beat', (tester) async {
    forgeRandomForTest = () => _Face(3);
    await _open(tester);
    await tester.tap(find.byKey(const ValueKey('forge_tab_Foot')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('forge_go_boots_iron_shod')));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('forge_beat_piece')), findsNothing);
    await tester.tap(find.byKey(const Key('forge_moment')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('forge_beat_piece')), findsOneWidget);
    // 3 + 2 = 5: Sound, the piece as listed.
    expect(tester.widget<Text>(find.byKey(const Key('forge_piece_name'))).data,
        'Iron-Shod Boots');
    await _takeIt(tester);
  });

  testWidgets('with reduced motion only the last beat shows, the roll written',
      (tester) async {
    forgeRandomForTest = () => _Face(13);
    await _open(tester, reduced: true);
    await tester.tap(find.byKey(const ValueKey('forge_tab_Foot')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('forge_go_boots_iron_shod')));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('forge_beat_landing')), findsNothing);
    expect(find.byKey(const ValueKey('forge_beat_piece')), findsOneWidget);
    expect(
        tester.widget<Text>(find.byKey(const Key('forge_roll_written'))).data,
        '13 + 2 = 15, Fine');
    await _takeIt(tester);
  });

  testWidgets('Forge another forges again while the pack allows it',
      (tester) async {
    forgeRandomForTest = () => _Face(10);
    final container = await _open(tester, ore: 4, gold: 200, reduced: true);
    await tester.tap(find.byKey(const ValueKey('forge_tab_Head')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('forge_go_helm_iron_cap')));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('forge_another')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 300));
    // Four ore, two caps of 2 each: both forged, and then no more.
    expect(find.byKey(const Key('forge_moment')), findsOneWidget);
    expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('forge_another')))
            .onPressed,
        isNull);
    await _takeIt(tester);
    expect(
        container
            .read(playerSessionProvider)
            .inventoryItemIds
            .where((i) => i == 'helm_iron_cap')
            .length,
        2);
  });

  test('the new strings exist in both languages', () {
    for (final k in [
      'forge_slot_Head',
      'forge_slot_Top',
      'forge_slot_Bottom',
      'forge_slot_Foot',
      'forge_roll_line',
      'forge_odds_open',
      'forge_odds_close',
      'forge_odds_note',
      'forge_hint_tip',
      'forge_have_need',
      'forge_short_of',
      'forge_short_gold',
      'forge_cast',
      'forge_die',
      'forge_total',
      'forge_effect_flawed',
      'forge_effect_sound',
      'forge_effect_fine',
      'forge_effect_masterwork',
      'forge_flaw_note',
      'forge_sells_for',
      'forge_spent',
      'forge_take_it',
      'forge_another',
    ]) {
      expect(trFor(AppLanguage.en, k), isNot(k), reason: k);
      expect(trFor(AppLanguage.fr, k), isNot(k), reason: k);
    }
  });

  testWidgets('in French the tabs and the button say it', (tester) async {
    await _open(tester, language: AppLanguage.fr);
    expect(find.text('Tête'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('forge_tab_Bottom')));
    await tester.pump();
    expect(find.textContaining('Il manque 1'), findsOneWidget);
  });

  group('the Bone-Caster\'s Hut on a flawed piece', () {
    const hut = {
      'builtHouseIds': ['bone_casters_hut'],
      'rerollCharges': 1,
    };

    Future<void> forgeBoots(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('forge_tab_Foot')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('forge_go_boots_iron_shod')));
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('it offers a reroll; a charge rolls the forge again',
        (tester) async {
      // 1 + 2 = 3: Flawed; the hut's roll, 18 + 2 = 20: Masterwork.
      forgeRandomForTest = () => _Faces([1, 18]);
      final container = await _open(tester, extra: hut);
      await forgeBoots(tester);
      expect(find.byKey(const Key('forge_hut_offer')), findsOneWidget);
      await tester.tap(find.byKey(const Key('forge_hut_reroll')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const Key('forge_moment')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
          tester.widget<Text>(find.byKey(const Key('forge_piece_name'))).data,
          'Masterwork Iron-Shod Boots');
      await _takeIt(tester);
      final session = container.read(playerSessionProvider);
      expect(session.rerollCharges, 0);
      expect(session.inventoryItemIds, contains('boots_iron_shod@masterwork'));
    });

    testWidgets('letting it stand keeps the flawed piece and the charge',
        (tester) async {
      forgeRandomForTest = () => _Faces([1, 18]);
      final container = await _open(tester, extra: hut);
      await forgeBoots(tester);
      await tester.tap(find.byKey(const Key('forge_hut_keep')));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byKey(const Key('forge_moment')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
          tester.widget<Text>(find.byKey(const Key('forge_piece_name'))).data,
          'Flawed Iron-Shod Boots');
      await _takeIt(tester);
      final session = container.read(playerSessionProvider);
      expect(session.rerollCharges, 1);
      expect(session.inventoryItemIds, contains('boots_iron_shod@flawed'));
    });

    testWidgets('no hut, or no charge: no offer', (tester) async {
      forgeRandomForTest = () => _Face(1);
      await _open(tester);
      await forgeBoots(tester);
      expect(find.byKey(const Key('forge_hut_offer')), findsNothing);
      expect(find.byKey(const Key('forge_moment')), findsOneWidget);
      await tester.tap(find.byKey(const Key('forge_moment')));
      await tester.pump(const Duration(milliseconds: 300));
      await _takeIt(tester);
    });
  });
}
