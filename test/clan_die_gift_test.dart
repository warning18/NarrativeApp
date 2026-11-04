// A clan's die in the dice bag (v1.684, clan-dice-gifts.md section 5): the
// clan's flag, "<Clan>'s gift" and how the Resonance stands -- lit, or asleep
// with its reason -- in English and French; nothing for an ordinary die.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/providers/clans_provider.dart';
import 'package:narrative_data_app/widgets/pixel_banner.dart';
import 'package:narrative_data_app/widgets/clan_die_gift.dart';

Map<String, dynamic> _table(String name) =>
    jsonDecode(File('assets/gamedata/$name.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final dice = _table('dice');
  final data = ClanData.fromTables(
    factions: _table('factions'),
    subclans: _table('subclans'),
    relations: _table('relations'),
    titles: _table('titles'),
  );
  PoliticsState standing(String clan, num value, {String sworn = ''}) =>
      setStandingValue(PoliticsState.empty, clan, value, 'edit', data: data)
          .state
          .copyWith(swornFactionId: sworn);

  Future<void> show(WidgetTester tester, String dieId, PoliticsState politics,
      {AppLanguage language = AppLanguage.en}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        clanDataProvider.overrideWithValue(data),
        politicsProvider.overrideWithValue(politics),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ClanDieGift(
              dieId: dieId, die: dice[dieId] as Map<String, dynamic>),
        ),
      ),
    ));
    if (language != AppLanguage.en) {
      ProviderScope.containerOf(tester.element(find.byType(Scaffold)))
          .read(appLanguageProvider.notifier)
          .state = language;
      await tester.pump();
    }
  }

  String shown(WidgetTester tester) => tester
      .widgetList<Text>(find.descendant(
          of: find.byKey(const Key('clan_die_gift_court_die')),
          matching: find.byType(Text)))
      .map((t) => t.data)
      .join(' | ');

  testWidgets('lit: the clan, its gift and the +1 to faces up to 3',
      (tester) async {
    await show(tester, 'court_die', standing('mire', 60, sworn: 'mire'));
    expect(find.byKey(const Key('clan_die_resonance_lit')), findsOneWidget);
    expect(shown(tester), contains('gift'));
    expect(shown(tester), contains('Resonance: +1 to faces up to 3'));
    expect(find.byType(ClanFlag), findsOneWidget);
  });

  testWidgets('asleep: another main clan, or standing too low', (tester) async {
    await show(tester, 'court_die', standing('mire', 60, sworn: 'vigil'));
    expect(find.byKey(const Key('clan_die_resonance_notMainClan')),
        findsOneWidget);
    expect(shown(tester), contains('is not your main clan'));

    await show(tester, 'court_die', standing('mire', -20, sworn: 'mire'));
    expect(find.byKey(const Key('clan_die_resonance_standingLow')),
        findsOneWidget);
    expect(shown(tester), contains('Friend or better'));
  });

  testWidgets('in French', (tester) async {
    await show(tester, 'court_die', standing('mire', 60, sworn: 'mire'),
        language: AppLanguage.fr);
    expect(shown(tester), contains('Don'));
    expect(shown(tester), contains("Résonance : +1 aux faces jusqu'à 3"));
  });

  testWidgets('an ordinary die has no gift line', (tester) async {
    await show(tester, 'starter_die', PoliticsState.empty);
    expect(find.byType(ClanFlag), findsNothing);
    expect(find.byType(Text), findsNothing);
  });
}
