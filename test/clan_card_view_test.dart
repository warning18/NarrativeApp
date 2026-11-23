// The offer card's art zone: a clan with a backdrop of its own wears it, a clan
// without one (or an id with no file) keeps the tier's backdrop under its tint,
// and the effect line shows in gold under the tags.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/widgets/clan_offer_gifts.dart';

Widget _card({String? backdropId, String? effect}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: ClanCardView(
            tier: CardTier.rare,
            color: const Color(0xFF2F62B5),
            flag: const SizedBox(width: 64, height: 128),
            icon: const SizedBox(width: 48, height: 48),
            name: 'Fireball',
            tags: const [Text('Skill')],
            greeting: 'Kneel to the flame.',
            clanName: 'The Lantern Dominion',
            effect: effect,
            backdropId: backdropId,
            standing: '+6 Dominion',
          ),
        ),
      ),
    );

void main() {
  testWidgets('a clan with no backdrop file keeps the tier backdrop',
      (tester) async {
    await tester.pumpWidget(_card(backdropId: 'no_such_clan'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Fireball'), findsOneWidget);
  });

  testWidgets('no clan id keeps the tier backdrop too', (tester) async {
    await tester.pumpWidget(_card());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the effect line shows when the gift has one', (tester) async {
    await tester.pumpWidget(_card(effect: '+1 damage · ×1.2'));
    expect(find.byKey(const Key('offer_card_effect')), findsOneWidget);
    expect(find.text('+1 damage · ×1.2'), findsOneWidget);
    await tester.pumpWidget(_card());
    expect(find.byKey(const Key('offer_card_effect')), findsNothing);
  });
}
