// A choice card wears its weight (lib/data/story_plates.dart): a plain card is
// the card it was, a weighty one the clan's accent in the quiet frame, a major
// one the rich metal (gold for a banner piece), a shut one stays plain.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:narrative_data_app/data/story_plates.dart';
import 'package:narrative_data_app/widgets/choice_card.dart';
import 'package:narrative_data_app/widgets/clan_offer_gifts.dart' show CardTier;
import 'package:narrative_data_app/widgets/story_panel.dart';

Widget _card({
  ChoiceWeight weight = ChoiceWeight.plain,
  CardTier rich = CardTier.epic,
  bool locked = false,
  bool selected = false,
}) =>
    MaterialApp(
      home: Scaffold(
        body: ChoiceCard(
          icon: Icons.chat_bubble_outline,
          color: Colors.blue,
          text: 'Swear that he let it through',
          goLabel: 'Go',
          weight: weight,
          clanColor: const Color(0xFF2F62B5),
          richTier: rich,
          locked: locked,
          selected: selected,
          tag: const ChoiceTag('Alignment −3', Colors.purple),
        ),
      ),
    );

void main() {
  testWidgets('plain is the card as it was; weighty and major are framed',
      (tester) async {
    await tester.runAsync(StoryFrames.instance.preload);
    await tester.pumpWidget(_card());
    expect(find.byType(StoryFrame), findsNothing);
    expect(find.text('Swear that he let it through'), findsOneWidget);

    await tester.pumpWidget(_card(weight: ChoiceWeight.weighty));
    expect(tester.widget<StoryFrame>(find.byType(StoryFrame)).tier,
        CardTier.common);

    await tester.pumpWidget(_card(weight: ChoiceWeight.major));
    expect(
        tester.widget<StoryFrame>(find.byType(StoryFrame)).tier, CardTier.epic);

    await tester.pumpWidget(
        _card(weight: ChoiceWeight.major, rich: CardTier.legendary));
    expect(tester.widget<StoryFrame>(find.byType(StoryFrame)).tier,
        CardTier.legendary);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a shut way stays plain, and a picked framed card shows Go',
      (tester) async {
    await tester.runAsync(StoryFrames.instance.preload);
    await tester.pumpWidget(_card(weight: ChoiceWeight.major, locked: true));
    expect(find.byType(StoryFrame), findsNothing);
    await tester
        .pumpWidget(_card(weight: ChoiceWeight.weighty, selected: true));
    expect(find.text('Go'), findsOneWidget);
    expect(find.text('Alignment −3'), findsNothing,
        reason: 'the picked card shows Go in place of its tag');
    expect(tester.takeException(), isNull);
  });
}
