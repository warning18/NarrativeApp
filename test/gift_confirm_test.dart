// The body of a gift's confirmation (v1.553): whole numbers, "a little" under
// one, the step word only when a relation crosses a step, in both languages.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/factions.dart';
import 'package:narrative_data_app/l10n/app_locale.dart';
import 'package:narrative_data_app/widgets/gift_confirm.dart';

ClanChange _change(String id, double delta, StandingTier a, StandingTier b) =>
    ClanChange(factionId: id, name: id, delta: delta, before: a, after: b);

Widget _body(List<ClanChange> changes, AppLanguage lang) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: GiftConfirmBody(
            effect: 'Brace like a wall of iron.',
            changes: changes,
            lang: lang,
            noStanding: 'No faction: standing doesn’t move.',
          ),
        ),
      ),
    );

void main() {
  test('changes read in whole numbers, never with a decimal', () {
    expect(changeText(6, AppLanguage.en), '+6');
    expect(changeText(1.5, AppLanguage.en), '+2');
    expect(changeText(-3, AppLanguage.en), '−3');
    expect(changeText(-2.4, AppLanguage.en), '−2');
    expect(changeText(0.4, AppLanguage.en), 'a little');
    expect(changeText(-0.4, AppLanguage.fr), 'un peu');
  });

  test('a change crosses a step only when its tier changes', () {
    expect(
        _change('dominion', -3, StandingTier.resented, StandingTier.hostile)
            .crossesStep,
        isTrue);
    expect(
        _change('vigil', 1, StandingTier.unfriendly, StandingTier.unfriendly)
            .crossesStep,
        isFalse);
    expect(
        _change('vigil', 1, StandingTier.unfriendly, StandingTier.unfriendly)
            .up,
        isTrue);
  });

  testWidgets(
      'closer and further groups, a chip each, the step word where '
      'a step is crossed', (tester) async {
    await tester.pumpWidget(_body([
      _change('compact', 6, StandingTier.unfriendly, StandingTier.friendly),
      _change('vigil', 1.5, StandingTier.unfriendly, StandingTier.unfriendly),
      _change('dominion', -3, StandingTier.resented, StandingTier.hostile),
    ], AppLanguage.en));
    expect(find.byKey(const Key('gift_effect_line')), findsOneWidget);
    expect(find.text('CLOSER'), findsOneWidget);
    expect(find.text('FURTHER'), findsOneWidget);
    for (final id in ['compact', 'vigil', 'dominion']) {
      expect(find.byKey(Key('gift_change_$id')), findsOneWidget);
    }
    String text(String id) =>
        tester.widget<Text>(find.byKey(Key('gift_change_text_$id'))).data!;
    expect(text('compact'), '+6');
    expect(text('vigil'), '+2');
    expect(text('dominion'), '−3');
    expect(find.byKey(const Key('gift_step_compact')), findsOneWidget);
    expect(find.byKey(const Key('gift_step_dominion')), findsOneWidget);
    expect(find.byKey(const Key('gift_step_vigil')), findsNothing,
        reason: 'no step crossed, no step word');
  });

  testWidgets('no clan moves: the line says so, in French too', (tester) async {
    await tester.pumpWidget(_body(const [], AppLanguage.fr));
    expect(find.text('No faction: standing doesn’t move.'), findsOneWidget);
    expect(find.byKey(const Key('offer_confirm_closer')), findsNothing);
  });

  testWidgets('French group labels', (tester) async {
    await tester.pumpWidget(_body([
      _change('compact', 2, StandingTier.unfriendly, StandingTier.unfriendly),
      _change('dominion', -2, StandingTier.unfriendly, StandingTier.unfriendly),
    ], AppLanguage.fr));
    expect(find.text('PLUS PROCHES'), findsOneWidget);
    expect(find.text('PLUS ÉLOIGNÉS'), findsOneWidget);
  });
}
