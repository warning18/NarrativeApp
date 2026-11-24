// v2.3 (UX-2): a tarot card's clean slots really are clean: a footer (a price,
// a standing) sits whole inside the card, and the card without one is as tall
// as before.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:narrative_data_app/screens/tower/tower_tarot_card.dart';

Widget _card({Widget? footer, Widget? tag}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: TowerTarotCard(
            width: 100,
            kind: 'Skill',
            name: 'Steady Aim',
            text: 'Take the extra second to make it count.',
            vignette: 'assets/visuals/tower_cards/skill_none.png',
            icon: const SizedBox(width: 22, height: 22),
            rarity: 2,
            footer: footer,
            tag: tag,
          ),
        ),
      ),
    );

void main() {
  testWidgets('a footer sits whole inside the card', (tester) async {
    await tester.pumpWidget(_card());
    final plain = tester.getSize(find.byType(TowerTarotCard)).height;
    await tester
        .pumpWidget(_card(footer: const Text('+6 Crows', key: Key('footer'))));
    final card = tester.getRect(find.byType(TowerTarotCard));
    final footer = tester.getRect(find.byKey(const Key('footer')));
    expect(card.height, greaterThan(plain), reason: 'the card makes room');
    expect(footer.bottom, lessThanOrEqualTo(card.bottom - 6),
        reason: 'above the frame: $footer in $card');
    expect(footer.left, greaterThanOrEqualTo(card.left));
    expect(footer.right, lessThanOrEqualTo(card.right));
  });

  testWidgets('a card with no footer is as tall as before', (tester) async {
    await tester.pumpWidget(_card());
    expect(tester.getSize(find.byType(TowerTarotCard)).height, 100 * 1.75);
  });
}
